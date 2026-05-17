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
    NavigationTitle = "Modules",
    SearchPlaceholder = "Search modules",
    Profile = {
        Enabled = true
    },
    Instructions = "Universal config and UI size controls are built in. This example is a realistic multi-page script layout.",
    Size = UDim2.fromOffset(720, 440),
    ToggleKey = Enum.KeyCode.RightShift
})

local function notify(title, content)
    Window:Notify({
        Title = title,
        Content = content,
        Duration = 2
    })
end

local Combat = Window:Tab({
    Title = "Combat",
    Icon = "crosshair",
    Segments = { "Aimbot", "Silent", "Weapon" }
})

local Visuals = Window:Tab({
    Title = "Visuals",
    Icon = "eyes",
    Segments = { "ESP", "World", "Camera" }
})

local Movement = Window:Tab({
    Title = "Movement",
    Icon = "gamepad",
    Segments = { "Player", "Flight", "Teleport" }
})

local Utility = Window:Tab({
    Title = "Utility",
    Icon = "plug",
    Segments = { "Automation", "Server", "Safety" }
})

local Config = Window:Tab({
    Title = "Config",
    Icon = "settings",
    Segments = { "Profiles", "Keybinds", "About" }
})

local Aimbot = Combat:Group({
    Title = "Aimbot",
    Icon = "crosshair",
    Height = 315,
    Segment = "Aimbot"
})

Aimbot:Paragraph({
    Title = "Targeting",
    Content = "Main combat page with common aimbot controls for testing toggles, sliders, dropdowns, keybinds, and paragraphs."
})

Aimbot:Toggle({
    Title = "Enable Aimbot",
    Desc = "Locks camera toward the selected target mode.",
    Default = false,
    Flag = "aimbot_enabled",
    Callback = function(value)
        notify("Aimbot", value and "Enabled" or "Disabled")
    end
})

Aimbot:Slider({
    Title = "Accuracy",
    Min = 1,
    Max = 100,
    Default = 72,
    Suffix = "%",
    Flag = "aimbot_accuracy"
})

Aimbot:Slider({
    Title = "Smoothness",
    Min = 1,
    Max = 25,
    Default = 8,
    Flag = "aimbot_smoothness"
})

Aimbot:Slider({
    Title = "FOV Radius",
    Min = 30,
    Max = 450,
    Default = 160,
    Flag = "aimbot_fov"
})

Aimbot:Dropdown({
    Title = "Hit Part",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "Closest Part" },
    Default = "Head",
    Flag = "aimbot_hitpart"
})

Aimbot:Dropdown({
    Title = "Target Priority",
    Values = { "Closest Cursor", "Closest Distance", "Lowest Health", "Random" },
    Default = "Closest Cursor",
    Flag = "aimbot_priority"
})

Aimbot:Keybind({
    Title = "Aim Key",
    Default = Enum.KeyCode.E,
    Flag = "aimbot_key",
    Callback = function()
        notify("Aimbot", "Aim key pressed")
    end
})

local Silent = Combat:Group({
    Title = "Silent Aim",
    Icon = "scan",
    Height = 260,
    Segment = "Silent"
})

Silent:Toggle({
    Title = "Enable Silent Aim",
    Default = false,
    Flag = "silent_enabled"
})

Silent:Slider({
    Title = "Hit Chance",
    Min = 1,
    Max = 100,
    Default = 65,
    Suffix = "%",
    Flag = "silent_hitchance"
})

Silent:Toggle({
    Title = "Wall Check",
    Default = true,
    Flag = "silent_wallcheck"
})

Silent:Toggle({
    Title = "Team Check",
    Default = true,
    Flag = "silent_teamcheck"
})

Silent:Dropdown({
    Title = "Resolver",
    Values = { "Off", "Basic", "Velocity", "Prediction" },
    Default = "Basic",
    Flag = "silent_resolver"
})

local Weapon = Combat:Group({
    Title = "Weapon",
    Icon = "bag",
    Height = 260,
    Segment = "Weapon"
})

Weapon:Toggle({
    Title = "No Recoil",
    Default = true,
    Flag = "weapon_no_recoil"
})

Weapon:Toggle({
    Title = "No Spread",
    Default = false,
    Flag = "weapon_no_spread"
})

Weapon:Slider({
    Title = "Fire Rate",
    Min = 1,
    Max = 10,
    Default = 3,
    Suffix = "x",
    Flag = "weapon_fire_rate"
})

Weapon:Dropdown({
    Title = "Reload Mode",
    Values = { "Normal", "Instant", "Auto Reload" },
    Default = "Normal",
    Flag = "weapon_reload_mode"
})

local Esp = Visuals:Group({
    Title = "ESP",
    Icon = "player",
    Height = 320,
    Segment = "ESP"
})

Esp:Toggle({
    Title = "Enable ESP",
    Default = true,
    Flag = "esp_enabled"
})

Esp:Dropdown({
    Title = "ESP Parts",
    Multi = true,
    Values = { "Boxes", "Names", "Health", "Distance", "Tracers" },
    Default = { "Boxes", "Names", "Health" },
    Flag = "esp_parts"
})

Esp:Colorpicker({
    Title = "Enemy Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "esp_enemy_color"
})

Esp:Colorpicker({
    Title = "Team Color",
    Default = Color3.fromRGB(180, 180, 180),
    Flag = "esp_team_color"
})

Esp:Slider({
    Title = "Max Distance",
    Min = 100,
    Max = 5000,
    Default = 1500,
    Flag = "esp_distance"
})

local World = Visuals:Group({
    Title = "World",
    Icon = "gps",
    Height = 245,
    Segment = "World"
})

World:Toggle({
    Title = "Fullbright",
    Default = false,
    Flag = "world_fullbright"
})

World:Toggle({
    Title = "No Fog",
    Default = true,
    Flag = "world_no_fog"
})

World:Slider({
    Title = "Clock Time",
    Min = 0,
    Max = 24,
    Default = 14,
    Flag = "world_time"
})

World:Colorpicker({
    Title = "Ambient",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "world_ambient"
})

local Camera = Visuals:Group({
    Title = "Camera",
    Icon = "scan",
    Height = 230,
    Segment = "Camera"
})

Camera:Slider({
    Title = "Field Of View",
    Min = 60,
    Max = 120,
    Default = 80,
    Flag = "camera_fov"
})

Camera:Toggle({
    Title = "Third Person",
    Default = false,
    Flag = "camera_third_person"
})

Camera:Slider({
    Title = "Camera Distance",
    Min = 4,
    Max = 30,
    Default = 12,
    Flag = "camera_distance"
})

local Player = Movement:Group({
    Title = "Player",
    Icon = "player",
    Height = 300,
    Segment = "Player"
})

Player:Toggle({
    Title = "Speed Enabled",
    Default = false,
    Flag = "speed_enabled"
})

Player:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = 32,
    Flag = "walkspeed"
})

Player:Toggle({
    Title = "Jump Enabled",
    Default = false,
    Flag = "jump_enabled"
})

Player:Slider({
    Title = "JumpPower",
    Min = 50,
    Max = 250,
    Default = 85,
    Flag = "jumppower"
})

Player:Keybind({
    Title = "Speed Key",
    Default = Enum.KeyCode.LeftShift,
    Flag = "speed_key"
})

local Flight = Movement:Group({
    Title = "Flight",
    Icon = "next",
    Height = 245,
    Segment = "Flight"
})

Flight:Toggle({
    Title = "Enable Fly",
    Default = false,
    Flag = "fly_enabled"
})

Flight:Slider({
    Title = "Fly Speed",
    Min = 1,
    Max = 10,
    Default = 3,
    Flag = "fly_speed"
})

Flight:Keybind({
    Title = "Fly Toggle",
    Default = Enum.KeyCode.X,
    Flag = "fly_key"
})

local Teleport = Movement:Group({
    Title = "Teleport",
    Icon = "gps",
    Height = 245,
    Segment = "Teleport"
})

Teleport:Dropdown({
    Title = "Location",
    Values = { "Spawn", "Shop", "Safe Zone", "Objective", "Random Player" },
    Default = "Spawn",
    Flag = "teleport_location"
})

Teleport:Button({
    Title = "Teleport",
    Callback = function()
        notify("Teleport", "Teleport button pressed")
    end
})

Teleport:Button({
    Title = "Bring Nearest Player",
    Callback = function()
        notify("Teleport", "Bring nearest player pressed")
    end
})

local Automation = Utility:Group({
    Title = "Automation",
    Icon = "loop",
    Height = 275,
    Segment = "Automation"
})

Automation:Toggle({
    Title = "Auto Farm",
    Default = false,
    Flag = "auto_farm"
})

Automation:Dropdown({
    Title = "Farm Mode",
    Values = { "Legit", "Fast", "Safe", "Quest" },
    Default = "Legit",
    Flag = "farm_mode"
})

Automation:Slider({
    Title = "Farm Delay",
    Min = 0,
    Max = 5,
    Default = 1,
    Suffix = "s",
    Flag = "farm_delay"
})

Automation:Toggle({
    Title = "Auto Collect Drops",
    Default = true,
    Flag = "auto_collect"
})

local Server = Utility:Group({
    Title = "Server",
    Icon = "notify",
    Height = 235,
    Segment = "Server"
})

Server:Button({
    Title = "Server Hop",
    Callback = function()
        notify("Server", "Server hop pressed")
    end
})

Server:Button({
    Title = "Rejoin",
    Callback = function()
        notify("Server", "Rejoin pressed")
    end
})

Server:Toggle({
    Title = "Low Player Servers",
    Default = true,
    Flag = "low_player_servers"
})

local Safety = Utility:Group({
    Title = "Safety",
    Icon = "alert",
    Height = 235,
    Segment = "Safety"
})

Safety:Toggle({
    Title = "Panic Mode",
    Default = false,
    Flag = "panic_mode"
})

Safety:Keybind({
    Title = "Panic Key",
    Default = Enum.KeyCode.P,
    Flag = "panic_key",
    Callback = function()
        Window:SetMinimized(true)
    end
})

Safety:Button({
    Title = "Unload UI",
    Callback = function()
        Window:Destroy()
    end
})

local Profiles = Config:Group({
    Title = "Profiles",
    Icon = "folder",
    Height = 275,
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
        local ok = Window:SaveConfig(Window:GetFlag("config_name") or "Default")
        notify("Config", ok and "Saved config" or "Executor does not support writefile")
    end
})

Profiles:Button({
    Title = "Load Config",
    Callback = function()
        local ok = Window:LoadConfig(Window:GetFlag("config_name") or "Default")
        notify("Config", ok and "Loaded config" or "Config not found")
    end
})

Profiles:Button({
    Title = "Export Config",
    Callback = function()
        local data = Window:ExportConfig()
        notify("Config", "Exported " .. tostring(data.Flags and "flags" or "config"))
    end
})

local Keybinds = Config:Group({
    Title = "Keybinds",
    Icon = "keyboard",
    Height = 235,
    Segment = "Keybinds"
})

Keybinds:Keybind({
    Title = "Menu Toggle",
    Default = Enum.KeyCode.RightShift,
    Flag = "menu_key"
})

Keybinds:Keybind({
    Title = "Main Action",
    Default = Enum.KeyCode.F,
    Flag = "action_key"
})

Keybinds:Button({
    Title = "Minimize UI",
    Callback = function()
        Window:SetMinimized(true)
    end
})

local About = Config:Group({
    Title = "About",
    Icon = "question",
    Height = 220,
    Segment = "About"
})

About:Paragraph({
    Title = "Example Script",
    Content = "This file previews the UI like a real multi-page script: Combat, Visuals, Movement, Utility, and Config."
})

About:Button({
    Title = "Show Notification",
    Callback = function()
        notify("Singularity", "Example callback works.")
    end
})
