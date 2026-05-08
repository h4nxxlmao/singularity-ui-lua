# Singularity UI Lua

A custom Roblox Luau UI library inspired by WindUI's layout style: draggable window, sidebar tabs, cards, controls, flags, themes, keybinds, and notifications.

## Files

- `src/SingularityUI.lua` - the self-contained UI library.
- `examples/example.client.lua` - a drop-in Roblox client example.

## Quick Start

```lua
local Singularity = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-username/singularity-ui-lua/main/src/SingularityUI.lua"))()

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Subtitle = "Custom Lua UI",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift
})

local Main = Window:Tab({ Title = "Main", Icon = "M" })

Main:Button({
    Title = "Click Me",
    Callback = function()
        Window:Notify({
            Title = "Singularity",
            Content = "Hello from the UI."
        })
    end
})
```

Replace `your-username` with the account or raw URL where you host `src/SingularityUI.lua`. You can also put the file in a ModuleScript and use `require(...)`.

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

## Themes

Built-in themes:

- `Dark`
- `Light`
- `Obsidian`

You can pass a custom theme table into `CreateWindow({ Theme = { ... } })` using the same color keys found in `Singularity.Themes.Dark`.
