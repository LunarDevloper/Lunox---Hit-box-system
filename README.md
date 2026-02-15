
# Lunox Hitbox System


<img width="1024" height="1024" alt="20260215_1157_Image Generation_remix_01khgwvbfxfmq854st5cr7481h" src="https://github.com/user-attachments/assets/8f4ce4f9-5dec-4be0-ad7e-a4f0017f8aa4" />


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

[Download LunoxHit.lua](https://raw.githubusercontent.com/LunarDevloper/Lunox---Hit-box-system/main/LunoxHit.rbxm)

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

<img width="440" height="253" alt="image" src="https://github.com/user-attachments/assets/6cb74847-44ac-454b-8ca7-f121a92bcb0e" />


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


