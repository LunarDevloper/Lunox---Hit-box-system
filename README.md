
# Lunox Hitbox System

A lightweight and easy-to-use hitbox detection system for Roblox Studio, designed for real-time combat, skills, and interaction mechanics.

---

## Features

- Circular hitboxes (radius-based)
- Box hitboxes (Vector3 size)
- Real-time collision detection
- Optional humanoid-only filtering
- Custom lightweight signal/event system
- Attach hitboxes to moving parts
- Debug hitbox visualization
- OverlapParams support

---

## Installation

1. Download or clone this repository.
2. Place the `LunoxHit` module inside **ServerScriptService**.
3. Inside the module, create an `ObjectValue` named `SimulatedHitBoxFolder`.
4. Set its value to a `Folder` inside **Workspace**.

Example:
```

Workspace
└── HitboxDebugFolder

````

---

## Usage

### Create a Hitbox

```lua
local Hitbox = Lunox.new(
    "Circle", -- Shape: "Circle" or "Box"
    6,        -- Radius (number) or Size (Vector3)
    Character.HumanoidRootPart.CFrame,
    2,        -- Duration (reserved)
    true,     -- Filter humanoids
    OverlapParams.new()
)
````

### Attach to a Part

```lua
Hitbox:AttachInstance(Character.HumanoidRootPart)
```

### Detect Hits

```lua
Hitbox.Touched:Connect(function(Humanoid, Model)
    print("Hit:", Model.Name)
end)
```

### Start the Hitbox

```lua
Hitbox:StartHitBox(true)
```

### Debug Visualization

```lua
Hitbox:SimulateHitBox()
```

### Stop the Hitbox

```lua
Hitbox:EndHitBox()
```

---

## Events

### `Hitbox.Touched`

Triggered when an object enters the hitbox.

* With humanoid filtering:

```lua
Touched(Humanoid, Model)
```

* Without filtering:

```lua
Touched(BasePart)
```

---

## How It Works

* Uses `Workspace:GetPartBoundsInRadius` and `GetPartBoundsInBox`
* Updates on `RunService.Heartbeat`
* Lightweight internal signal system
* Supports attachment with optional offset

---

## Best Practices

* Always call `EndHitBox()` after use
* Use `OverlapParams` to limit collision scope
* Avoid unnecessary simultaneous hitboxes
* Use debug visualization only during development

---

## License

MIT License

---

## Author

Lunar


