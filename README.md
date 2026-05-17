# Singularity UI Lua

A custom Roblox Luau UI library with a tight white Singularity style: draggable/resizable responsive window, logo brand rail, desktop search, mobile-friendly compact navigation, segmented page tabs, grouped controls, slider toggles, flags, keybinds, animations, and minimalist toast notifications.

## Files

- `src/SingularityUI.lua` - the self-contained UI library.
- `src/icons/defaulticons.lua` - small built-in-style asset icon map.
- `src/icons/lucideIcons.lua` - optional Lucide asset icon map.
- `src/icons/solarIcons.lua` - optional Solar asset icon map.
- `examples/example.client.lua` - a drop-in Roblox client example.

## Quick Start

```lua
local Singularity = require(game:GetService("ReplicatedStorage"):WaitForChild("SingularityUI"))

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Theme = "singularity-dark",
    Logo = 73636428262287,
    Game = "Universal",
    SearchPlaceholder = "Search modules",
    Profile = {
        Enabled = true
    },
    Size = UDim2.fromOffset(680, 410),
    MinimizedWidth = 104,
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

String icons first check registered icon maps, then use Footagesus/Icons Lucide spritesheets when `loadstring` + `HttpGet` are available. If the icon loader cannot fetch, Singularity falls back to small built-in line icons for common names. Roblox image and decal asset ids such as `123456789` / `"rbxassetid://123456789"` also work. Decal ids are resolved through their real `Texture` value before being assigned to an `ImageLabel`. The default logo is `73636428262287`; pass `Logo = false` to use the text fallback instead.

Optional no-network icon packs:

```lua
Singularity:RegisterIcons("lucide", require(script.Parent.icons.lucideIcons))
Singularity:RegisterIcons("solar", require(script.Parent.icons.solarIcons))

Window:Tab({
    Title = "Combat",
    Icon = "lucide:crosshair"
})
```

To disable external Lucide loading:

```lua
Singularity.UseLucide = false
```

The sidebar profile card loads the local Roblox profile by default when `Profile.Enabled` is not `false`: DisplayName, `@username`, and headshot avatar.

Touch devices use a smaller automatic scale by default. Override it with `MobileScale = 0.74`, or pass `Scale = 0.86` to force one scale everywhere.

The top search box filters the active page by group/control title, description, flag, and placeholder text.

## Themes

The default theme is `singularity-dark`. The built-in UI settings tab also includes a theme dropdown for `singularity-dark` and `singularity-light`.

Universal config helpers are built in: `Window:SaveConfig(name)`, `Window:LoadConfig(name)`, `Window:ExportConfig()`, and `Window:ImportConfig(data)`. Executors with `writefile`/`readfile` support save to `SingularityUI/<name>.json` or a flat fallback file.

You can still pass a custom theme table into `CreateWindow({ Theme = { ... } })` if you want to override the defaults.
