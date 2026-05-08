local SOURCE_URL = "https://raw.githubusercontent.com/h4nxxlmao/singularity-ui-lua/refs/heads/main/src/SingularityUI.lua" -- Optional: paste your raw SingularityUI.lua URL here.

local function loadSingularity()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local module = ReplicatedStorage:FindFirstChild("SingularityUI")

    if module and module:IsA("ModuleScript") then
        return require(module)
    end

    assert(SOURCE_URL ~= "", "Put SingularityUI.lua in ReplicatedStorage as a ModuleScript named SingularityUI, or set SOURCE_URL to a raw hosted URL.")
    assert(loadstring, "loadstring is not available in this environment. Use the ModuleScript require setup instead.")

    local ok, source = pcall(function()
        return game:HttpGet(SOURCE_URL)
    end)

    assert(ok and type(source) == "string" and source ~= "", "Failed to download SingularityUI.lua from SOURCE_URL.")

    local chunk, compileError = loadstring(source)
    assert(chunk, "Downloaded source did not compile. Check SOURCE_URL. Error: " .. tostring(compileError))

    return chunk()
end

local Singularity = loadSingularity()

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Subtitle = "Singularity - Dark",
    Theme = "Singularity",
    LogoText = "S",
    NavigationTitle = "Combat",
    FooterTitle = "Singularity - Dark",
    FooterText = "RightShift to toggle",
    Size = UDim2.fromOffset(760, 480),
    Scale = 0.94,
    ToggleKey = Enum.KeyCode.RightShift
})

local Page = Window:Tab({
    Title = "Page",
    Icon = "page",
    Segments = { "Combat", "Weapon", "FoV" }
})

local Settings = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

local Aimbot = Page:Group({
    Title = "Aimbot",
    Icon = "aimbot",
    Height = 310
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

Settings:Section("Personalize")

Settings:Input({
    Title = "Username",
    Placeholder = "Name",
    Default = "Singularity",
    Flag = "Username",
    Callback = function(value)
        print("Username:", value)
    end
})

Settings:Keybind({
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

Settings:Colorpicker({
    Title = "Accent Preview",
    Default = Color3.fromRGB(91, 141, 255),
    Callback = function(color)
        print("Color:", color)
    end
})
