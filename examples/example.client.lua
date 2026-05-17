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
    Theme = "singularity-dark",
    Logo = 73636428262287,
    Game = "Universal",
    NavigationTitle = "Pages",
    SearchPlaceholder = "Search modules",
    Profile = {
        Enabled = true
    },
    Instructions = "This page is built in. Use the sample pages to test every control type.",
    Size = UDim2.fromOffset(700, 430),
    ToggleKey = Enum.KeyCode.RightShift
})

local Main = Window:Tab({
    Title = "Main",
    Icon = "layout-dashboard",
    Segments = { "Combat", "Movement", "Visuals" }
})

local Config = Window:Tab({
    Title = "Config",
    Icon = "settings",
    Segments = { "Profiles", "Keys", "Info" }
})

local Misc = Window:Tab({
    Title = "Misc",
    Icon = "star",
    Segments = { "Utility", "Colors", "Text" }
})

local Combat = Main:Group({
    Title = "Combat",
    Icon = "crosshair",
    Height = 265,
    Segment = "Combat"
})

Combat:Paragraph({
    Title = "Paragraph",
    Content = "Developer instructions or module notes can live here."
})

Combat:Toggle({
    Title = "Enabled",
    Default = true,
    Flag = "combat_enabled",
    Callback = function(value)
        print("combat_enabled", value)
    end
})

Combat:Slider({
    Title = "Aim Strength",
    Min = 0,
    Max = 100,
    Default = 45,
    Suffix = "%",
    Flag = "aim_strength"
})

Combat:Dropdown({
    Title = "Target Mode",
    Values = { "Closest", "Lowest HP", "Mouse" },
    Default = "Closest",
    Flag = "target_mode"
})

Combat:Button({
    Title = "Test Notify",
    Callback = function()
        Window:Notify({
            Title = "Singularity",
            Content = "Button callback works.",
            Duration = 2
        })
    end
})

local Movement = Main:Group({
    Title = "Movement",
    Icon = "gamepad",
    Height = 210,
    Segment = "Movement"
})

Movement:Toggle({
    Title = "Sprint",
    Default = false,
    Flag = "sprint"
})

Movement:Slider({
    Title = "Walkspeed",
    Min = 16,
    Max = 100,
    Default = 24,
    Flag = "walkspeed"
})

Movement:Keybind({
    Title = "Dash Key",
    Default = Enum.KeyCode.Q,
    Flag = "dash_key",
    Callback = function()
        print("dash")
    end
})

local Visuals = Main:Group({
    Title = "Visuals",
    Icon = "eyes",
    Height = 210,
    Segment = "Visuals"
})

Visuals:Toggle({
    Title = "ESP",
    Default = true,
    Flag = "esp"
})

Visuals:Colorpicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "esp_color"
})

local Profiles = Config:Group({
    Title = "Profiles",
    Icon = "folder",
    Height = 230,
    Segment = "Profiles"
})

Profiles:Input({
    Title = "Config Name",
    Placeholder = "Default",
    Default = "Default",
    Flag = "config_name"
})

Profiles:Button({
    Title = "Save Config",
    Callback = function()
        Window:SaveConfig(Window:GetFlag("config_name") or "Default")
    end
})

Profiles:Button({
    Title = "Load Config",
    Callback = function()
        Window:LoadConfig(Window:GetFlag("config_name") or "Default")
    end
})

local Keys = Config:Group({
    Title = "Keys",
    Icon = "settings",
    Height = 170,
    Segment = "Keys"
})

Keys:Keybind({
    Title = "Open UI",
    Default = Enum.KeyCode.RightShift,
    Flag = "open_ui_key"
})

Keys:Keybind({
    Title = "Action",
    Default = Enum.KeyCode.F,
    Flag = "action_key"
})

local Info = Config:Group({
    Title = "Info",
    Icon = "question",
    Height = 170,
    Segment = "Info"
})

Info:Paragraph({
    Title = "Universal Config",
    Content = "The library has built-in static UI settings and config save/load helpers."
})

local Utility = Misc:Group({
    Title = "Utility",
    Icon = "plug",
    Height = 200,
    Segment = "Utility"
})

Utility:Dropdown({
    Title = "Multi Dropdown",
    Multi = true,
    Values = { "A", "B", "C" },
    Default = { "A", "C" },
    Flag = "multi_dropdown"
})

Utility:Button({
    Title = "Minimize",
    Callback = function()
        Window:SetMinimized(true)
    end
})

local Colors = Misc:Group({
    Title = "Colors",
    Icon = "palette",
    Height = 150,
    Segment = "Colors"
})

Colors:Colorpicker({
    Title = "Accent Preview",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "accent_preview"
})

local Text = Misc:Group({
    Title = "Text",
    Icon = "page",
    Height = 180,
    Segment = "Text"
})

Text:Input({
    Title = "Input",
    Placeholder = "Type here",
    Default = "Hello",
    Flag = "sample_input"
})

Text:Paragraph({
    Title = "Long Paragraph",
    Content = "Paragraph controls wrap text and are intended for developer instructions, warnings, or notes."
})
