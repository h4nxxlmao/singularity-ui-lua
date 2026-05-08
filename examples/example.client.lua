local Singularity = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-username/singularity-ui-lua/main/src/SingularityUI.lua"))()

local Window = Singularity:CreateWindow({
    Title = "Singularity",
    Subtitle = "WindUI-style base",
    Theme = "Dark",
    Size = UDim2.fromOffset(660, 460),
    ToggleKey = Enum.KeyCode.RightShift
})

local Main = Window:Tab({
    Title = "Main",
    Icon = "M"
})

local Settings = Window:Tab({
    Title = "Settings",
    Icon = "S"
})

Main:Section("General")

Main:Paragraph({
    Title = "Singularity UI",
    Content = "A custom interface shell with tabs, controls, flags, and notifications."
})

Main:Button({
    Title = "Show Notification",
    Desc = "Runs a simple callback",
    Callback = function()
        Window:Notify({
            Title = "Singularity",
            Content = "Button callback fired.",
            Duration = 3
        })
    end
})

Main:Toggle({
    Title = "Example Toggle",
    Desc = "Stores its state in Window.Flags.Enabled",
    Default = false,
    Flag = "Enabled",
    Callback = function(value)
        print("Toggle:", value)
    end
})

Main:Slider({
    Title = "Walk Speed",
    Desc = "Example numeric value",
    Min = 16,
    Max = 100,
    Default = 24,
    Step = 1,
    Flag = "WalkSpeed",
    Callback = function(value)
        print("WalkSpeed:", value)
    end
})

Main:Dropdown({
    Title = "Mode",
    Values = { "Legit", "Rage", "Utility" },
    Default = "Legit",
    Flag = "Mode",
    Callback = function(value)
        print("Mode:", value)
    end
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
