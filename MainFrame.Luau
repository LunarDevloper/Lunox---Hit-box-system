--- LunoxHit Module
--- A Roblox hitbox detection system supporting circular and box-shaped hitboxes
--- Provides real-time collision detection with optional humanoid filtering
---
--- TODO: Implement duration-based automatic cleanup
--- TODO: Add support for custom collision filters
--- TODO: Add performance profiling and optimization
---
--- @class LunoxHit

local path = script:GetFullName();
path = string.gsub(path, "%.", "/");

local RS = game:GetService(`RunService`);
local WS = game:GetService(`Workspace`);

-- Folder where simulated hitbox parts will be placed for visualization
local SimulatedFolder = script.SimulatedHitBoxFolder.Value;
assert(typeof(SimulatedFolder) == `Instance`, `[{path}] : You will not be able to simulate any hit boxes until you define a location for them to be placed in the workspace.`)

--- Main Lunox class for hitbox management
--- @class Lunox
local Lunox = {};
Lunox.__index = Lunox;

--- LunoxSignals class - Custom signal/event system for hitbox callbacks
--- @class LunoxSignals
local LunoxSignals = {};
LunoxSignals.__index = LunoxSignals;

--- Creates a new signal instance
--- @return LunoxSignal
function LunoxSignals.new()
	return setmetatable({
		_functions = {};
	},LunoxSignals);
end;

--- @field AttachInstance fun(self: LunoxHitBox, Obj: Instance?, Offset: CFrame?)
--- @field StartHitBox fun(self: LunoxHitBox, OneFirePerPart: boolean?)
--- @field SimulateHitBox fun(self: LunoxHitBox)
--- @field EndHitBox fun(self: LunoxHitBox)
--- @field Touched LunoxSignal
export type LunoxHitBox = {
	AttachInstance: (self: LunoxHitBox, Obj: Instance?, Offset: CFrame?) -> (),
	StartHitBox: (self: LunoxHitBox, OneFirePerPart: boolean?) -> (),
	SimulateHitBox: (self: LunoxHitBox) -> (),
	EndHitBox: (self: LunoxHitBox) -> (),

	Touched: LunoxSignal
}

--- @field _functions {any: (any) -> any}
--- @field Connect fun(self: LunoxSignal, Function: (...any) -> ())
--- @field Fire fun(self: LunoxSignal, ...any)
--- @field Destroy fun(self: LunoxSignal)
export type LunoxSignal = {
	_functions: {any: (...any) -> any},

	Connect: (self: LunoxSignal, Function: (...any) -> ()) -> (),
	Fire: (self: LunoxSignal, ...any) -> (),
	Destroy: (self: LunoxSignal) -> ()
}

--- @field new fun(Shape: Shapes, RadiusOrSize: number | Vector3, Position: CFrame?, Duration: number?, FilterHumanoids: boolean, OverleapP: OverlapParams): LunoxHitBox?
export type ModuleType = {
	new: (Shape: Shapes, RadiusOrSize: number | Vector3, Position: CFrame?, Duration: number?, FilterHumanoids: boolean, OverleapP: OverlapParams) -> LunoxHitBox?
}
--- Connects a callback function to the signal
--- @param Func The function to connect
function LunoxSignals:Connect(Func:(...any) -> any)
	if not getmetatable(self) then return end;
	if not Func or typeof(Func) ~= `function` then return end;

	local _functions = self._functions;
	if not _functions or typeof(_functions) ~= `table` then return end;

	table.insert(_functions,Func);
end

--- Fires the signal, calling all connected functions asynchronously
--- @param ... The arguments to pass to connected functions
function LunoxSignals:Fire(...)
	if not getmetatable(self) then return end;

	local _functions = self._functions;
	if not _functions or typeof(_functions) ~= `table` then return end;

	for a,b in pairs(_functions) do
		if typeof(b) == `function` then
			task.spawn(b,...);
		end;
	end;
end;

-- Destroys the signal and disconnects any connections
function LunoxSignals:Destroy()
	if not getmetatable(self) then return end;

	if typeof(self._rs) == `RBXScriptConnection` then
		self._rs:Disconnect();
	end;

	setmetatable(self,nil);
end;
-- Supported hitbox shapes
export type Shapes = "Circle"|"Box";

-- Creates a new hitbox instance
-- @param Shape: "Circle" or "Box" - the shape of the hitbox
-- @param RadiusOrSize: number for Circle, Vector3 for Box - size of the hitbox
-- @param Position: CFrame - initial position of the hitbox
-- @param Duration: number - how long the hitbox should last (unused in current implementation)
-- @param FilterHumanoids: boolean - whether to filter results to only humanoids
-- @param OverleapP: OverlapParams - collision detection parameters
function Lunox.new(Shape:Shapes,RadiusOrSize: number|Vector3,Position:CFrame?,Duration:number?,FilterHumanoids:boolean,OverleapP:OverlapParams)  : LunoxHitBox?
	assert(Shape and typeof(Shape) == `string`, `[{path}] : Invalid Shape, type : {typeof(Shape)}`);
	assert(Duration and typeof(Duration) == `number` and Duration >= 0, `[{path}] : Invalid duration, type : {typeof(Duration)} {if typeof(Duration) == `number` then `duration < 0 : {Duration < 0}` else ``} `);
	assert(Position and typeof(Position) == `CFrame`, `[{path}] : Invalid position, type : {typeof(Position)}`);
	
	if not OverleapP then
		OverleapP = OverlapParams.new();
	end;
	
	if Shape == `Circle` then
		if not RadiusOrSize or typeof(RadiusOrSize) ~= `number` then return nil end;

		return setmetatable({
			Radius = RadiusOrSize,
			Shape = Shape,
			Duration = Duration,
			FilterHumanoids = FilterHumanoids,
			OverleapP = OverleapP;
			Position = Position,

			Touched = LunoxSignals.new();
			_simulatedstorage = {};
		},Lunox);
	elseif Shape == `Box` then
		if not RadiusOrSize or typeof(RadiusOrSize) ~= `Vector3` then return nil end;

		return setmetatable({
			Size = RadiusOrSize,
			Shape = Shape,
			Duration = Duration,
			FilterHumanoids = FilterHumanoids,
			OverleapP = OverleapP,
			Position = Position,

			Touched = LunoxSignals.new();
			_simulatedstorage = {};
		},Lunox);
	end;

	assert(false, `[{path}] : Invalid shape : {Shape}`);
	return nil;
end;

--- Attaches the hitbox to a BasePart, making it follow the part's position
--- @param Obj BasePart to attach to
--- @param Offset Optional CFrame offset from the attached part
function Lunox:AttachInstance(Obj:Instance?,Offset:CFrame?)
	if not Obj or typeof(Obj) ~= `Instance` then return end;
	if not getmetatable(self) then return end;
	if not Obj:IsA(`BasePart`) then return end;

	self._attach = Obj;
	self._attachoffset = Offset
end;

--- Checks if an Instance is part of a humanoid model
--- Traverses up the hierarchy (1-2 levels) to find a Model with a Humanoid
--- @param Obj Instance to check (usually a BasePart)
--- @return Humanoid?, Model? The humanoid and model if found, nil otherwise
function Lunox.CheckHumanoid(Obj:Instance?): (Humanoid?, Model?)
	if not Obj or typeof(Obj) ~= `Instance` then return end;

	local Parent1 = Obj.Parent;
	if not Parent1 or typeof(Parent1) ~= `Instance` then return end;

	local HumCheck1 = Parent1:FindFirstChild(`Humanoid`)
	if Parent1:IsA(`Model`) and HumCheck1 then
		return HumCheck1,Parent1;
	end;

	local Parent2 = Parent1.Parent;
	if not Parent2 or typeof(Parent2) ~= `Instance` then return end;

	local HumCheck2 = Parent2:FindFirstChild(`Humanoid`)
	if Parent2:IsA(`Model`) and HumCheck2 then
		return HumCheck2,Parent2;
	end;

	return nil, nil;
end;


--- Starts the hitbox detection system
--- Connects to Heartbeat and continuously checks for overlapping parts
--- @param OneFirePerPart If true, each part will only trigger the event once
function Lunox:StartHitBox(OneFirePerPart:boolean?)
	if not getmetatable(self) then return end;

	local Params = self.OverleapP;
	if not Params or typeof(Params) ~= `OverlapParams` then return end;

	local SizeOrRadius = self.Shape == `Circle` and self.Radius or self.Size;
	if typeof(SizeOrRadius) ~= (`Vector3` or `number`) then return end;

	local Position = self.Position;
	if not Position or typeof(Position) ~= `CFrame` then return end;

	local Touched = self.Touched;
	if not getmetatable(Touched) then return end;

	local List = {}; -- Tracks already processed parts/models
	local cd = os.clock();
	self._rs = RS.Heartbeat:Connect(function()
		if not getmetatable(self) then return end;
		if os.clock() - cd < .02 then return end;
		cd = os.clock();
		
		if self._attach then	
			local Obj = self._attach;
			self.Position = Obj.CFrame * (if typeof(self._attachoffset) == `CFrame` then self._attachoffset else CFrame.new(0,0,0));
		end;
		
		local Position = self.Position;
		if not Position or typeof(Position) ~= `CFrame` then return end;
		
		
		local Result = nil;
		if self.Shape ==`Circle` then
			Result = WS:GetPartBoundsInRadius(Position.Position,SizeOrRadius,Params);
		else
			Result = WS:GetPartBoundsInBox(Position,SizeOrRadius,Params);
		end;
		
		for _,Part in pairs(Result) do
			if OneFirePerPart and List[Part] then continue end;
			List[Part] = true;
			
			if self.FilterHumanoids then
				local Hum,Parent = Lunox.CheckHumanoid(Part);
				if Hum and Parent then
					print(Hum,Parent)
					if OneFirePerPart and List[Parent] then continue end;
					List[Parent] = true;
					
					Touched:Fire(Hum,Parent);
					continue;
				end;
			end;
			
			Touched:Fire(Part);
		end;
	end);
end;

--- Creates a visual representation of the hitbox for debugging
--- Places a semi-transparent red part in the SimulatedFolder
--- @return nil
function Lunox:SimulateHitBox()
	if not getmetatable(self) then return end;

	if not SimulatedFolder or typeof(SimulatedFolder) ~= `Instance` then return end;
	if not self._simulatedstorage or typeof(self._simulatedstorage) ~= `table` then return end;

	local Shape = self.Shape;
	if not Shape or typeof(Shape) ~= `string` then return end;

	local Part = nil;
	if Shape == `Circle` then
		if not self.Radius or typeof(self.Radius) ~= `number` then return end;
		
		local New = Instance.new(`Part`);
		New.Shape = Enum.PartType.Ball;
		New.Size = Vector3.new(self.Radius,self.Radius,self.Radius);
		New.CFrame = self.Position
		New.Color = Color3.new(1, 0, 0);
		New.Transparency = .5;
		New.Parent = SimulatedFolder;
		New.Anchored = true;
		New.CanCollide = false;
		
		Part = New;
		
		table.insert(self._simulatedstorage,New);
	elseif Shape == `Box` then
		if not self.Size or typeof(self.Size) ~= `Vector3` then return end;

		local New = Instance.new(`Part`);
		New.Shape = Enum.PartType.Block;
		New.Size = self.Size
		New.CFrame = self.Position
		New.Color = Color3.new(1, 0, 0);
		New.Transparency = .5;
		New.Parent = SimulatedFolder;
		New.Anchored = true;
		New.CanCollide = false;

		Part = New;
		table.insert(self._simulatedstorage,New);
	end;
	
	local cd = os.clock();
	table.insert(self._simulatedstorage,RS.Heartbeat:Connect(function()
		if os.clock() - cd < .05 then return end;
		cd = os.clock();

		if not Part or typeof(Part) ~= `Instance` or not Part:IsA(`BasePart`) then return end;

		local att = self._attach;
		if att and typeof(att) == `Instance` and att:IsA(`BasePart`) then
			Part.CFrame = att.CFrame * (if typeof(self._attachoffset) == `CFrame` then self._attachoffset else CFrame.new(0,0,0));
		end;
	end))
	
	
end;
--- Stops the hitbox and cleans up all resources
--- Disconnects signals, destroys simulated parts, and invalidates the instance
--- @return nil
function Lunox:EndHitBox()
	if not getmetatable(self) then return end;

	local Touched = self.Touched;
	if getmetatable(Touched) then
		Touched:Destroy();
	end;

	local RSCnn = self._rs;
	if RSCnn or typeof(RSCnn) == `RBXScriptConnection` then
		RSCnn:Disconnect();
	end

	local SimulatedStorage = self._simulatedstorage;
	if SimulatedStorage and typeof(SimulatedStorage) == `table` then
		for _,unk in pairs(SimulatedStorage) do
			if typeof(unk) == `RBXScriptConnection` then
				unk:Disconnect();
			elseif typeof(unk) == `Instance` then
				unk:Destroy();
			end;
		end;
	end;

	setmetatable(self,nil);

end;


return Lunox
