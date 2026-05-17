local SOURCE_URL = "https://raw.githubusercontent.com/h4nxxlmao/singularity-ui-lua/refs/heads/main/src/SingularityUI.lua"

local function loadSingularity()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local module = ReplicatedStorage:FindFirstChild("SingularityUI")

    if module and module:IsA("ModuleScript") then
        return require(module)
    end

    assert(SOURCE_URL ~= "", "set SOURCE_URL to a raw hosted URL.")
    assert(loadstring, "loadstring is not available in this environment.")

    local ok, source = pcall(function()
        return game:HttpGet(SOURCE_URL)
    end)

    assert(ok and type(source) == "string" and source ~= "", "Failed to get SingularityUI.lua from SOURCE_URL.")

    local chunk, compileError = loadstring(source)
    assert(chunk, "Downloaded source did not compile. Check SOURCE_URL. Error: " .. tostring(compileError))

    return chunk()
end

local Singularity = loadSingularity()
Singularity.UseLucide = true

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Subtitle = "v0.0.1",
    Theme = "Singularity",
    Logo = 73636428262287,
    NavigationTitle = "Combat",
    SearchPlaceholder = "Search modules",
    Profile = {
        Enabled = true
    },
    Size = UDim2.fromOffset(700, 430),
    MinimizedWidth = 104,
    ToggleKey = Enum.KeyCode.RightShift
})

local Page = Window:Tab({
    Title = "Page",
    Icon = "layout-dashboard",
    Segments = { "Combat", "Weapon", "FoV" }
})

local Settings = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Segments = { "Config", "Theme", "Profile" }
})

local Aimbot = Page:Group({
    Title = "Aimbot",
    Icon = "crosshair",
    Height = 260,
    Segment = "Combat"
})

Aimbot:Toggle({
    Title = "Toggle",
    Default = false,
    Flag = "Enabled",
    Callback = function(value)
        print("Toggle:", value)
    end
})

Aimbot:Button({
    Title = "Click Me",
    Callback = function()
        Window:Notify({
            Title = "Singularity",
            Content = "Button callback fired.",
            Duration = 3
        })
    end
})

Aimbot:Slider({
    Title = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
    Suffix = "%",
    Flag = "Slider",
    Callback = function(value)
        print("Slider:", value)
    end
})

Aimbot:Dropdown({
    Title = "Dropdown",
    Values = { "Option 1", "Option 2", "Option 3" },
    Default = "Option 2",
    Flag = "Dropdown",
    Callback = function(value)
        print("Dropdown:", value)
    end
})

Aimbot:Toggle({
    Title = "Label",
    Default = true,
    Flag = "LabelToggle"
})

Aimbot:Keybind({
    Title = "Label",
    Default = Enum.KeyCode.E,
    Flag = "LabelKey"
})

Aimbot:Input({
    Title = "Text",
    Default = "Text",
    Flag = "Text"
})

local Weapon = Page:Group({
    Title = "Weapon",
    Icon = "weapon",
    Height = 180,
    Segment = "Weapon"
})

Weapon:Dropdown({
    Title = "Weapon Mode",
    Values = { "Primary", "Secondary", "Auto" },
    Default = "Auto",
    Flag = "WeaponMode"
})

Weapon:Slider({
    Title = "Recoil",
    Min = 0,
    Max = 100,
    Default = 25,
    Suffix = "%",
    Flag = "Recoil"
})

Weapon:Toggle({
    Title = "Auto Reload",
    Default = true,
    Flag = "AutoReload"
})

local Fov = Page:Group({
    Title = "FoV",
    Icon = "scan",
    Height = 150,
    Segment = "FoV"
})

Fov:Slider({
    Title = "Radius",
    Min = 20,
    Max = 300,
    Default = 120,
    Flag = "FovRadius"
})

Fov:Toggle({
    Title = "Draw Circle",
    Default = true,
    Flag = "DrawFov"
})

local Config = Settings:Group({
    Title = "Config",
    Icon = "settings",
    Height = 260,
    Segment = "Config"
})

Config:Input({
    Title = "Username",
    Placeholder = "Name",
    Default = "Singularity",
    Flag = "Username",
    Callback = function(value)
        print("Username:", value)
    end
})

Config:Dropdown({
    Title = "Preset",
    Values = { "Default", "Legit", "Rage" },
    Default = "Default",
    Flag = "Preset"
})

Config:Keybind({
    Title = "Action Key",
    Default = Enum.KeyCode.F,
    Callback = function()
        Window:Notify({
            Title = "Keybind",
            Content = "Action key pressed.",
            Duration = 2
        })
    end
})

Config:Toggle({
    Title = "Notifications",
    Default = true,
    Flag = "Notifications"
})

Config:Button({
    Title = "Save Config",
    Callback = function()
        Window:Notify({
            Title = "Saved",
            Content = "Config values stored in flags.",
            Duration = 2
        })
    end
})

local ThemeGroup = Settings:Group({
    Title = "Theme",
    Icon = "palette",
    Height = 110,
    Segment = "Theme"
})

ThemeGroup:Slider({
    Title = "Scale",
    Min = 80,
    Max = 110,
    Default = 94,
    Suffix = "%",
    Flag = "Scale"
})

local ProfileGroup = Settings:Group({
    Title = "Profile",
    Icon = "user",
    Height = 150,
    Segment = "Profile"
})

ProfileGroup:Paragraph({
    Title = "Roblox Profile",
    Content = "The sidebar card automatically uses your DisplayName, username, and headshot."
})

ProfileGroup:Button({
    Title = "Show Profile Toast",
    Callback = function()
        Window:Notify({
            Title = "Profile",
            Content = "Roblox profile loaded.",
            Duration = 2
        })
    end
})
