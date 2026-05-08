# Singularity UI Lua

A custom Roblox Luau UI library with a compact black-and-white Singularity Dark style: draggable/resizable window, identity sidebar, segmented page tabs, grouped controls, flags, keybinds, animations, and minimalist toast notifications.

## Files

- `src/SingularityUI.lua` - the self-contained UI library.
- `examples/example.client.lua` - a drop-in Roblox client example.

## Quick Start

```lua
local Singularity = require(game:GetService("ReplicatedStorage"):WaitForChild("SingularityUI"))

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Subtitle = "Singularity - Dark",
    Theme = "Singularity",
    LogoText = "S",
    Size = UDim2.fromOffset(760, 480),
    Scale = 0.94,
    ToggleKey = Enum.KeyCode.RightShift
})

local Main = Window:Tab({
    Title = "Page",
    Icon = "page",
    Segments = { "Combat", "Weapon", "FoV" }
})

local Aimbot = Main:Group({
    Title = "Aimbot",
    Icon = "aimbot"
})

Aimbot:Button({
    Title = "Click Me",
    Callback = function()
        Window:Notify({
            Title = "Singularity",
            Content = "Hello from the UI."
        })
    end
})
```

For Studio, put `src/SingularityUI.lua` into `ReplicatedStorage` as a ModuleScript named `SingularityUI`, then run `examples/example.client.lua` from a LocalScript.

For a loadstring executor, host `src/SingularityUI.lua` somewhere raw first, then use:

```lua
local url = "https://raw.githubusercontent.com/your-username/singularity-ui-lua/main/src/SingularityUI.lua"
local source = game:HttpGet(url)
assert(loadstring, "loadstring is not available here")
local chunk, compileError = loadstring(source)
local Singularity = assert(chunk, compileError)()
```

## API

Window:

- `Singularity:CreateWindow(options)`
- `Window:Tab(options)` or `Window:CreateTab(options)`
- `Window:Notify(options)`
- `Window:GetFlag(name)`
- `Window:SetFlag(name, value)`
- `Window:SetMinimized(boolean)`
- `Window:Destroy()`

Tab controls:

- `Tab:Section(title)`
- `Tab:Group(options)`
- `Tab:Paragraph(options)`
- `Tab:Button(options)`
- `Tab:Toggle(options)`
- `Tab:Slider(options)`
- `Tab:Input(options)`
- `Tab:Dropdown(options)`
- `Tab:Keybind(options)`
- `Tab:Colorpicker(options)`

Most controls accept:

```lua
{
    Title = "Control title",
    Desc = "Optional description",
    Default = value,
    Flag = "FlagName",
    Callback = function(value)
        print(value)
    end
}
```

Icons can be simple names like `"page"`, `"settings"`, `"aimbot"`, `"combat"`, `"weapon"`, or a Roblox image asset id such as `123456789` / `"rbxassetid://123456789"`.

## Themes

The library is designed around one theme: `Singularity - Dark`. Use `Theme = "Singularity"` or omit the theme option.

You can still pass a custom theme table into `CreateWindow({ Theme = { ... } })` if you want to override the black-and-white defaults.
