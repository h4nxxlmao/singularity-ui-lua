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
    NavigationTitle = "Preview",
    SearchPlaceholder = "Search preview",
    Profile = {
        Enabled = true
    },
    Instructions = "Static UI settings are always available here. Use the preview pages to test every public control and window helper.",
    Size = UDim2.fromOffset(720, 440),
    ToggleKey = Enum.KeyCode.RightShift
})

local StatusLabel

local function inspectValue(value)
    if typeof(value) == "Color3" then
        return string.format("rgb(%d,%d,%d)", math.floor(value.R * 255), math.floor(value.G * 255), math.floor(value.B * 255))
    end

    if typeof(value) == "EnumItem" then
        return value.Name
    end

    if typeof(value) == "table" then
        local items = {}

        for key, entry in pairs(value) do
            table.insert(items, tostring(key) .. "=" .. tostring(entry))
        end

        table.sort(items)
        return "{" .. table.concat(items, ", ") .. "}"
    end

    return tostring(value)
end

local function preview(action, value)
    local text = action .. (value ~= nil and (": " .. inspectValue(value)) or "")
    print("[Singularity Preview]", text)

    if StatusLabel then
        StatusLabel.Desc.Text = text
    end
end

local Controls = Window:CreateTab({
    Title = "Controls",
    Icon = "layout-dashboard",
    Segments = { "Basic", "Inputs", "Pickers" }
})

local Methods = Window:CreateTab({
    Title = "Methods",
    Icon = "settings",
    Segments = { "Window", "Flags", "Objects" }
})

local Config = Window:CreateTab({
    Title = "Config",
    Icon = "folder",
    Segments = { "Files", "Import", "Info" }
})

local Layout = Window:CreateTab({
    Title = "Layout",
    Icon = "page",
    Segments = { "Sections", "Long", "Search" }
})

local Basic = Controls:CreateGroup({
    Title = "Basic Controls",
    Icon = "plug",
    Height = 300,
    Segment = "Basic"
})

StatusLabel = Basic:CreateParagraph({
    Title = "Live Preview",
    Content = "Click any control to see callback output here."
})

Basic:CreateButton({
    Title = "Button",
    Desc = "Calls Window:Notify and updates this preview.",
    Callback = function()
        preview("Button clicked")
        Window:Notify({
            Title = "Button",
            Content = "Button callback fired.",
            Duration = 2
        })
    end
})

local EnabledToggle = Basic:CreateToggle({
    Title = "Toggle Slider",
    Desc = "Uses the slider toggle style.",
    Default = true,
    Flag = "preview_toggle",
    Callback = function(value)
        preview("Toggle callback", value)
    end
})

local PowerSlider = Basic:CreateSlider({
    Title = "Slider",
    Min = 0,
    Max = 100,
    Default = 45,
    Suffix = "%",
    Flag = "preview_slider",
    Callback = function(value)
        preview("Slider callback", value)
    end
})

local Inputs = Controls:CreateGroup({
    Title = "Inputs",
    Icon = "keyboard",
    Height = 260,
    Segment = "Inputs"
})

local TextInput = Inputs:CreateInput({
    Title = "Input",
    Placeholder = "Type text",
    Default = "Singularity",
    Flag = "preview_input",
    Callback = function(value)
        preview("Input callback", value)
    end
})

local SingleDropdown = Inputs:CreateDropdown({
    Title = "Dropdown",
    Values = { "Closest", "Lowest HP", "Mouse", "Random" },
    Default = "Closest",
    Flag = "preview_dropdown",
    Callback = function(value)
        preview("Dropdown callback", value)
    end
})

local MultiDropdown = Inputs:CreateDropdown({
    Title = "Multi Dropdown",
    Multi = true,
    Values = { "ESP", "Tracers", "Names", "Health" },
    Default = { "ESP", "Names" },
    Flag = "preview_multi_dropdown",
    Callback = function(value)
        preview("Multi dropdown callback", value)
    end
})

local Pickers = Controls:CreateGroup({
    Title = "Pickers",
    Icon = "palette",
    Height = 230,
    Segment = "Pickers"
})

local ActionKey = Pickers:CreateKeybind({
    Title = "Keybind",
    Default = Enum.KeyCode.F,
    Flag = "preview_keybind",
    Callback = function(key)
        preview("Keybind pressed", key)
    end
})

local AccentColor = Pickers:CreateColorpicker({
    Title = "Colorpicker",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "preview_color",
    Callback = function(value)
        preview("Colorpicker callback", value)
    end
})

local WindowMethods = Methods:CreateGroup({
    Title = "Window Methods",
    Icon = "settings",
    Height = 300,
    Segment = "Window"
})

WindowMethods:CreateButton({
    Title = "Window:Notify()",
    Callback = function()
        preview("Window:Notify()")
        Window:Notify({
            Title = "Notify",
            Content = "Window notification helper works.",
            Duration = 2
        })
    end
})

WindowMethods:CreateButton({
    Title = "Window:SetMinimized(true)",
    Callback = function()
        preview("Window:SetMinimized(true)")
        Window:SetMinimized(true)
    end
})

WindowMethods:CreateButton({
    Title = "Window:SetScale(0.9)",
    Callback = function()
        preview("Window:SetScale(0.9)")
        Window:SetScale(0.9)
    end
})

WindowMethods:CreateButton({
    Title = "Window:SetSize(720, 440)",
    Callback = function()
        preview("Window:SetSize(720, 440)")
        Window:SetSize(720, 440)
    end
})

WindowMethods:CreateButton({
    Title = "Window:SetTheme()",
    Callback = function()
        preview("Window:SetTheme(\"singularity-dark\")")
        Window:SetTheme("singularity-dark")
    end
})

local FlagMethods = Methods:CreateGroup({
    Title = "Flags",
    Icon = "flag",
    Height = 230,
    Segment = "Flags"
})

FlagMethods:CreateButton({
    Title = "Window:SetFlag()",
    Callback = function()
        Window:SetFlag("manual_flag", "set from button")
        preview("Window:SetFlag()", Window:GetFlag("manual_flag"))
    end
})

FlagMethods:CreateButton({
    Title = "Window:GetFlag()",
    Callback = function()
        preview("Window:GetFlag(preview_input)", Window:GetFlag("preview_input"))
    end
})

FlagMethods:CreateButton({
    Title = "Window:ExportConfig()",
    Callback = function()
        local data = Window:ExportConfig()
        preview("Window:ExportConfig()", "flags=" .. tostring(data.Flags ~= nil))
    end
})

local ObjectMethods = Methods:CreateGroup({
    Title = "Returned Objects",
    Icon = "loop",
    Height = 280,
    Segment = "Objects"
})

ObjectMethods:CreateButton({
    Title = "Toggle:Set(false)",
    Callback = function()
        EnabledToggle:Set(false)
        preview("Toggle:Set(false)")
    end
})

ObjectMethods:CreateButton({
    Title = "Slider:Set(80)",
    Callback = function()
        PowerSlider:Set(80)
        preview("Slider:Set(80)")
    end
})

ObjectMethods:CreateButton({
    Title = "Input:Set(\"Updated\")",
    Callback = function()
        TextInput:Set("Updated")
        preview("Input:Set(\"Updated\")")
    end
})

ObjectMethods:CreateButton({
    Title = "Dropdown:Set(\"Mouse\")",
    Callback = function()
        SingleDropdown:Set("Mouse")
        preview("Dropdown:Set(\"Mouse\")")
    end
})

ObjectMethods:CreateButton({
    Title = "Dropdown:Refresh()",
    Callback = function()
        SingleDropdown:Refresh({ "Closest", "Mouse", "Team Check", "New Option" })
        preview("Dropdown:Refresh()", "added New Option")
    end
})

ObjectMethods:CreateButton({
    Title = "Colorpicker:Set()",
    Callback = function()
        AccentColor:Set(Color3.fromRGB(180, 180, 180))
        preview("Colorpicker:Set()", Color3.fromRGB(180, 180, 180))
    end
})

ObjectMethods:CreateButton({
    Title = "Keybind:Set(Q)",
    Callback = function()
        ActionKey:Set(Enum.KeyCode.Q)
        preview("Keybind:Set(Q)")
    end
})

local FileConfig = Config:CreateGroup({
    Title = "File Config",
    Icon = "folder",
    Height = 230,
    Segment = "Files"
})

FileConfig:CreateInput({
    Title = "Config Name",
    Placeholder = "Preview",
    Default = "Preview",
    Flag = "config_name"
})

FileConfig:CreateButton({
    Title = "Window:SaveConfig(name)",
    Callback = function()
        local ok = Window:SaveConfig(Window:GetFlag("config_name") or "Preview")
        preview("Window:SaveConfig()", ok)
    end
})

FileConfig:CreateButton({
    Title = "Window:LoadConfig(name)",
    Callback = function()
        local ok = Window:LoadConfig(Window:GetFlag("config_name") or "Preview")
        preview("Window:LoadConfig()", ok)
    end
})

local ImportConfig = Config:CreateGroup({
    Title = "Import Config",
    Icon = "download",
    Height = 210,
    Segment = "Import"
})

ImportConfig:CreateButton({
    Title = "Window:ImportConfig(table)",
    Callback = function()
        local ok = Window:ImportConfig({
            Flags = {
                preview_toggle = true,
                preview_slider = 25,
                preview_input = "Imported"
            },
            UI = {
                Scale = 0.95,
                Width = 720,
                Height = 440
            }
        })

        EnabledToggle:Set(true, true)
        PowerSlider:Set(25, true)
        TextInput:Set("Imported", true)
        preview("Window:ImportConfig()", ok)
    end
})

ImportConfig:CreateButton({
    Title = "Singularity:Notify()",
    Callback = function()
        preview("Singularity:Notify()")
        Singularity:Notify({
            Title = "Library Notify",
            Content = "Direct library notification works too.",
            Duration = 2
        })
    end
})

local ConfigInfo = Config:CreateGroup({
    Title = "Built In Settings",
    Icon = "idea",
    Height = 170,
    Segment = "Info"
})

ConfigInfo:CreateParagraph({
    Title = "Static UI Page",
    Content = "The built-in UI tab cannot be disabled. It previews scale, width, height, save config, and load config."
})

Layout:CreateSection("Section Label Preview")

local Sections = Layout:CreateGroup({
    Title = "Sections",
    Icon = "page",
    Height = 210,
    Segment = "Sections"
})

Sections:CreateParagraph({
    Title = "Paragraph",
    Content = "This previews standalone sections, grouped paragraphs, and wrapped instruction text."
})

Sections:CreateButton({
    Title = "Select Controls Tab",
    Callback = function()
        Controls:Select()
        preview("Tab:Select()", "Controls")
    end
})

local Long = Layout:CreateGroup({
    Title = "Long Content",
    Icon = "list",
    Height = 340,
    Segment = "Long"
})

for index = 1, 8 do
    Long:CreateToggle({
        Title = "Scrollable Toggle " .. tostring(index),
        Default = index % 2 == 0,
        Flag = "scroll_toggle_" .. tostring(index),
        Callback = function(value)
            preview("Scrollable toggle " .. tostring(index), value)
        end
    })
end

local Search = Layout:CreateGroup({
    Title = "Search Targets",
    Icon = "search",
    Height = 260,
    Segment = "Search"
})

Search:CreateParagraph({
    Title = "Search Test",
    Content = "Try searching for button, dropdown, keybind, import, scrollable, or notify."
})

Search:CreateButton({
    Title = "Reset Preview",
    Callback = function()
        EnabledToggle:Set(true)
        PowerSlider:Set(45)
        TextInput:Set("Singularity")
        SingleDropdown:Set("Closest")
        MultiDropdown:Set({
            ESP = true,
            Names = true
        })
        AccentColor:Set(Color3.fromRGB(255, 255, 255))
        ActionKey:Set(Enum.KeyCode.F)
        Window:SetScale(1)
        Window:SetSize(720, 440)
        preview("Preview reset")
    end
})
