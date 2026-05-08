--[[
    Singularity UI
    A compact WindUI-inspired Roblox Luau interface library.

    This file is self-contained and can be used as a ModuleScript or through
    loadstring(game:HttpGet(...))().
]]

local Singularity = {}
Singularity.__index = Singularity

Singularity.Name = "Singularity UI"
Singularity.Version = "0.2.0"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local DEFAULT_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLOW_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Control = {}
Control.__index = Control

Singularity.Themes = {
    Dark = {
        Window = Color3.fromRGB(5, 5, 5),
        Topbar = Color3.fromRGB(10, 10, 10),
        Sidebar = Color3.fromRGB(7, 7, 7),
        Surface = Color3.fromRGB(12, 12, 12),
        SurfaceHover = Color3.fromRGB(22, 22, 22),
        Input = Color3.fromRGB(17, 17, 17),
        Stroke = Color3.fromRGB(42, 42, 42),
        Accent = Color3.fromRGB(245, 245, 245),
        AccentDark = Color3.fromRGB(32, 32, 32),
        Text = Color3.fromRGB(248, 248, 248),
        Subtext = Color3.fromRGB(172, 172, 172),
        Muted = Color3.fromRGB(105, 105, 105),
        Success = Color3.fromRGB(235, 235, 235),
        Warning = Color3.fromRGB(210, 210, 210),
        Danger = Color3.fromRGB(245, 245, 245)
    }
}

Singularity.Themes.Singularity = Singularity.Themes.Dark
Singularity.Themes.SingularityDark = Singularity.Themes.Dark
Singularity.Themes.Reference = Singularity.Themes.Dark

local function copy(source)
    local target = {}

    for key, value in pairs(source) do
        target[key] = value
    end

    return target
end

local function resolveTheme(theme)
    local base = copy(Singularity.Themes.Dark)

    if typeof(theme) == "string" and Singularity.Themes[theme] then
        return copy(Singularity.Themes[theme])
    end

    if typeof(theme) == "table" then
        for key, value in pairs(theme) do
            base[key] = value
        end
    end

    return base
end

local function tween(instance, properties, info)
    local tweenObject = TweenService:Create(instance, info or DEFAULT_TWEEN, properties)
    tweenObject:Play()
    return tweenObject
end

local function press(button, normalSize)
    if not button or not button:IsA("GuiObject") then
        return
    end

    normalSize = normalSize or button.Size

    local pressedSize = UDim2.new(
        normalSize.X.Scale,
        normalSize.X.Offset - 2,
        normalSize.Y.Scale,
        normalSize.Y.Offset - 2
    )

    tween(button, { Size = pressedSize }, PRESS_TWEEN)

    task.delay(0.08, function()
        if button and button.Parent then
            tween(button, { Size = normalSize }, DEFAULT_TWEEN)
        end
    end)
end

local function create(className, properties)
    local object = Instance.new(className)
    local parent = nil
    local children = nil

    if properties then
        parent = properties.Parent
        children = properties.Children

        for key, value in pairs(properties) do
            if key ~= "Parent" and key ~= "Children" then
                object[key] = value
            end
        end
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = object
        end
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function addStroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function addPadding(parent, left, top, right, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        Parent = parent
    })
end

local function safeCall(callback, ...)
    if typeof(callback) == "function" then
        local ok, message = pcall(callback, ...)

        if not ok then
            warn(("[Singularity UI] callback error: %s"):format(tostring(message)))
        end
    end
end

local function mountGui(screenGui)
    local parents = {}

    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)

        if ok and hui then
            table.insert(parents, hui)
        end
    end

    table.insert(parents, CoreGui)

    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if not playerGui then
            local ok, result = pcall(function()
                return LocalPlayer:WaitForChild("PlayerGui", 2)
            end)

            if ok then
                playerGui = result
            end
        end

        if playerGui then
            table.insert(parents, playerGui)
        end
    end

    for _, parent in ipairs(parents) do
        local ok = pcall(function()
            screenGui.Parent = parent
        end)

        if ok and screenGui.Parent == parent then
            return parent
        end
    end

    error("[Singularity UI] could not mount ScreenGui")
end

local function normalizeOptions(options)
    if typeof(options) == "string" then
        return { Title = options }
    end

    return options or {}
end

local function hasSupportText(options)
    return options.Desc ~= nil or options.Description ~= nil or options.Content ~= nil
end

local function firstDefined(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if value ~= nil then
            return value
        end
    end

    return nil
end

local function optionTitle(option)
    if typeof(option) == "table" then
        return tostring(option.Title or option.Name or option.Value or "Option")
    end

    return tostring(option)
end

local function optionValue(option)
    if typeof(option) == "table" and option.Value ~= nil then
        return option.Value
    end

    return option
end

local function formatKeyCode(keyCode)
    if typeof(keyCode) == "EnumItem" then
        return keyCode.Name
    end

    return tostring(keyCode or "None")
end

local IconGlyphs = {
    aimbot = "A",
    combat = "C",
    home = "H",
    page = "P",
    settings = "S",
    slider = "%",
    toggle = "T",
    weapon = "W"
}

local function getSliderConfig(options)
    local packed = options.Value

    if typeof(packed) == "table" then
        return packed.Min or options.Min or 0,
            packed.Max or options.Max or 100,
            firstDefined(packed.Default, packed.Value, options.Default, options.Min, 0)
    end

    return options.Min or 0, options.Max or 100, firstDefined(options.Default, packed, 0)
end

local function roundValue(value, step, decimals)
    if step and step > 0 then
        value = math.floor((value / step) + 0.5) * step
    end

    if decimals and decimals > 0 then
        local scale = 10 ^ decimals
        return math.floor(value * scale + 0.5) / scale
    end

    return math.floor(value + 0.5)
end

local function makeText(parent, text, size, color, font, props)
    props = props or {}

    return create("TextLabel", {
        BackgroundTransparency = 1,
        Font = font or Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = color,
        TextSize = size or 14,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = props.TextWrapped or false,
        TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd,
        Size = props.Size or UDim2.new(1, 0, 0, 20),
        Position = props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        Parent = parent
    })
end

local function makeIcon(parent, icon, theme, size)
    if not icon then
        return nil
    end

    size = size or 20

    if typeof(icon) == "number" or tostring(icon):find("rbxassetid://") == 1 then
        return create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = typeof(icon) == "number" and ("rbxassetid://" .. tostring(icon)) or tostring(icon),
            ImageColor3 = theme.Text,
            Size = UDim2.fromOffset(size, size),
            Parent = parent
        })
    end

    local text = IconGlyphs[string.lower(tostring(icon))] or tostring(icon):sub(1, 2)

    return create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = theme.Text,
        TextSize = math.max(10, size - 9),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.fromOffset(size, size),
        Parent = parent
    })
end

function Singularity:SetTheme(theme)
    self.Theme = resolveTheme(theme)
    return self.Theme
end

function Singularity:_ensureNotificationLayer()
    if self._notificationGui and self._notificationGui.Parent then
        return self._notificationHolder
    end

    local theme = self.Theme or resolveTheme("Dark")

    local gui = create("ScreenGui", {
        Name = "SingularityNotifications",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local holder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.fromOffset(330, 600),
        Parent = gui
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder
    })

    self._notificationGui = gui
    self._notificationHolder = holder
    self._notificationTheme = theme

    mountGui(gui)

    return holder
end

function Singularity:Notify(options)
    options = normalizeOptions(options)

    local theme = self._notificationTheme or self.Theme or resolveTheme("Dark")
    local holder = self:_ensureNotificationLayer()
    local duration = options.Duration or 2.6

    local frame = create("Frame", {
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.fromOffset(292, options.Content and 78 or 58),
        Parent = holder
    })
    addCorner(frame, 10)
    addStroke(frame, theme.Stroke, 0.15)
    addPadding(frame, 14, 12, 14, 12)

    local accent = create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, -22),
        Position = UDim2.fromOffset(0, 11),
        Parent = frame
    })
    addCorner(accent, 2)

    makeText(frame, options.Title or "Singularity", 13, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 0, 18)
    })

    if options.Content then
        makeText(frame, options.Content, 12, theme.Subtext, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(10, 22),
            Size = UDim2.new(1, -20, 0, 30),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top
        })
    end

    local progress = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -8),
        Size = UDim2.new(1, -20, 0, 1),
        Parent = frame
    })
    addCorner(progress, 1)

    frame.Position = UDim2.fromOffset(20, 0)
    tween(frame, { BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }, DEFAULT_TWEEN)
    tween(progress, { Size = UDim2.new(0, 0, 0, 1) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))

    task.delay(duration, function()
        if frame and frame.Parent then
            local closeTween = tween(frame, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(20, 0),
                Size = UDim2.fromOffset(292, 0)
            }, DEFAULT_TWEEN)

            closeTween.Completed:Wait()

            if frame and frame.Parent then
                frame:Destroy()
            end
        end
    end)

    return frame
end

function Singularity:CreateWindow(options)
    options = normalizeOptions(options)

    local theme = resolveTheme(options.Theme or self.Theme or "Dark")
    self.Theme = theme

    local window = setmetatable({
        Library = self,
        Theme = theme,
        Options = options,
        Tabs = {},
        Flags = {},
        _connections = {},
        _minimized = false
    }, Window)

    window:_build()

    if options.Notify ~= false then
        self:Notify({
            Title = options.Title or "Singularity",
            Content = "Interface loaded",
            Duration = 2,
            Color = theme.Accent
        })
    end

    return window
end

function Window:_build()
    local options = self.Options
    local theme = self.Theme
    local size = options.Size or UDim2.fromOffset(760, 480)
    local sidebarWidth = options.SidebarWidth or 230
    local scale = options.Scale or 0.94

    local screenGui = create("ScreenGui", {
        Name = options.Name or "SingularityUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local main = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Size = size,
        Parent = screenGui
    })
    addCorner(main, 10)
    addStroke(main, theme.Stroke, 0.15)

    local uiScale = create("UIScale", {
        Scale = scale,
        Parent = main
    })

    local sizeConstraint = create("UISizeConstraint", {
        MinSize = Vector2.new(560, 360),
        MaxSize = Vector2.new(980, 680),
        Parent = main
    })

    local sidebar = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(0, sidebarWidth, 1, -24),
        Parent = main
    })

    local brandCard = create("Frame", {
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 76),
        Parent = sidebar
    })
    addCorner(brandCard, 9)
    addStroke(brandCard, theme.Stroke, 0.52)

    local logo = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(4, 6, 6),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(48, 48),
        Parent = brandCard
    })
    addCorner(logo, 11)
    addStroke(logo, theme.Stroke, 0.72)

    if options.Logo then
        local logoImage = makeIcon(logo, options.Logo, theme, 26)
        logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
        logoImage.Position = UDim2.fromScale(0.5, 0.5)
    else
        makeText(logo, tostring(options.LogoText or options.Title or "S"):sub(1, 1), 18, theme.Text, Enum.Font.GothamMedium, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center
        })
    end

    local title = makeText(brandCard, options.Title or "Singularity", 15, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(78, 20),
        Size = UDim2.new(1, -92, 0, 20)
    })

    makeText(brandCard, options.Subtitle or options.Game or "Singularity - Dark", 13, theme.Subtext, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(78, 39),
        Size = UDim2.new(1, -92, 0, 18)
    })

    makeText(sidebar, options.NavigationTitle or "Pages", 12, theme.Muted, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(2, 92),
        Size = UDim2.new(1, -4, 0, 18)
    })

    local tabHolder = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 120),
        Size = UDim2.new(1, 0, 1, -198),
        Parent = sidebar
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabHolder
    })

    local footer = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 58),
        Parent = sidebar
    })
    addCorner(footer, 8)
    addStroke(footer, theme.Stroke, 0.58)

    makeText(footer, options.FooterTitle or "Singularity - Dark", 12, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(14, 11),
        Size = UDim2.new(1, -28, 0, 16)
    })

    makeText(footer, options.FooterText or "RightShift to toggle", 12, theme.Text, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(14, 31),
        Size = UDim2.new(1, -28, 0, 16)
    })

    local divider = create("Frame", {
        BackgroundColor3 = theme.Stroke,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 20, 14),
        Size = UDim2.new(0, 1, 1, -28),
        Parent = main
    })

    local contentShell = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 28, 0),
        Size = UDim2.new(1, -sidebarWidth - 38, 1, 0),
        Parent = main
    })

    local pageTitle = makeText(contentShell, "Page", 19, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(18, 24),
        Size = UDim2.new(1, -90, 0, 26)
    })

    local segmentHolder = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 0, 34),
        Parent = contentShell
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = segmentHolder
    })

    local pageHolder = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 112),
        Size = UDim2.new(1, -32, 1, -132),
        Parent = contentShell
    })

    local dragHeader = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 20, 0),
        Size = UDim2.new(1, -sidebarWidth - 20, 0, 58),
        Parent = main
    })

    local actions = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(58, 24),
        Parent = main
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = actions
    })

    local minimize = self:_topButton(actions, "-", theme.Subtext)
    local close = self:_topButton(actions, "x", theme.Danger)

    self.ScreenGui = screenGui
    self.Main = main
    self.UIScale = uiScale
    self.Topbar = dragHeader
    self.TitleLabel = title
    self.PageTitle = pageTitle
    self.SegmentHolder = segmentHolder
    self.TopbarLine = divider
    self.MinimizeButton = minimize
    self.CloseButton = close
    self.SizeConstraint = sizeConstraint
    self.Sidebar = sidebar
    self.SidebarLine = divider
    self.TabHolder = tabHolder
    self.ContentShell = contentShell
    self.Content = pageHolder
    self.OriginalSize = size
    self.MinimizedSize = UDim2.new(size.X.Scale, size.X.Offset, 0, 54)

    self:_makeDraggable(brandCard)
    self:_makeDraggable(dragHeader)
    self:_makeResizable()

    minimize.MouseButton1Click:Connect(function()
        self:SetMinimized(not self._minimized)
    end)

    close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    if options.ToggleKey ~= false then
        local key = options.ToggleKey or Enum.KeyCode.RightShift

        table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end

            if input.KeyCode == key then
                self.Main.Visible = not self.Main.Visible
            end
        end))
    end

    mountGui(screenGui)
end
function Window:_topButton(parent, text, textColor)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Input,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = textColor,
        TextSize = 12,
        Size = UDim2.fromOffset(24, 24),
        Parent = parent
    })

    addCorner(button, 6)
    addStroke(button, self.Theme.Stroke, 0.55)

    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = self.Theme.SurfaceHover }, DEFAULT_TWEEN)
    end)

    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = self.Theme.Input }, DEFAULT_TWEEN)
    end)

    button.MouseButton1Down:Connect(function()
        press(button, UDim2.fromOffset(24, 24))
    end)

    return button
end

function Window:_makeDraggable(handle)
    local dragging = false
    local dragStart = nil
    local startPosition = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = self.Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local rawDelta = input.Position - dragStart
        local scale = self.UIScale and self.UIScale.Scale or 1
        local delta = Vector2.new(rawDelta.X / scale, rawDelta.Y / scale)
        self.Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end))
end

function Window:_makeResizable()
    local dragging = false
    local dragStart = nil
    local startSize = nil

    local handle = create("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Input,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Position = UDim2.new(1, -8, 1, -8),
        Size = UDim2.fromOffset(18, 18),
        Text = "",
        TextColor3 = self.Theme.Muted,
        TextSize = 12,
        Parent = self.Main
    })
    self.ResizeHandle = handle
    addCorner(handle, 5)
    addStroke(handle, self.Theme.Stroke, 0.35)

    create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = self.Theme.Muted,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.fromOffset(7, 1),
        Parent = handle
    })

    create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = self.Theme.Muted,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.fromOffset(1, 7),
        Parent = handle
    })

    handle.MouseEnter:Connect(function()
        tween(handle, { BackgroundColor3 = self.Theme.SurfaceHover }, DEFAULT_TWEEN)
    end)

    handle.MouseLeave:Connect(function()
        if not dragging then
            tween(handle, { BackgroundColor3 = self.Theme.Input }, DEFAULT_TWEEN)
        end
    end)

    handle.InputBegan:Connect(function(input)
        if self._minimized then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startSize = self.Main.Size

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                tween(handle, { BackgroundColor3 = self.Theme.Input }, DEFAULT_TWEEN)
            end
        end)
    end)

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging or self._minimized then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local rawDelta = input.Position - dragStart
        local scale = self.UIScale and self.UIScale.Scale or 1
        local delta = Vector2.new(rawDelta.X / scale, rawDelta.Y / scale)
        local minSize = self.SizeConstraint and self.SizeConstraint.MinSize or Vector2.new(560, 360)
        local maxSize = self.SizeConstraint and self.SizeConstraint.MaxSize or Vector2.new(980, 680)
        local width = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
        local height = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)

        self.OriginalSize = UDim2.fromOffset(width, height)
        self.Main.Size = self.OriginalSize
    end))
end

function Window:SetMinimized(value)
    self._minimized = value
    self.Sidebar.Visible = not value
    self.ContentShell.Visible = not value
    if self.ResizeHandle then
        self.ResizeHandle.Visible = not value
    end
    self.MinimizeButton.Text = value and "+" or "-"

    if self.SizeConstraint then
        self.SizeConstraint.MinSize = value and Vector2.new(560, 54) or Vector2.new(560, 360)
    end

    tween(self.Main, {
        Size = value and self.MinimizedSize or self.OriginalSize
    }, SLOW_TWEEN)
end

function Window:Destroy()
    for _, connection in ipairs(self._connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function Window:Notify(options)
    return self.Library:Notify(options)
end

function Window:GetFlag(flag)
    return self.Flags[flag]
end

function Window:SetFlag(flag, value)
    self.Flags[flag] = value
end

function Window:Tab(options)
    options = normalizeOptions(options)

    local tab = setmetatable({
        Window = self,
        Title = options.Title or options.Name or ("Tab " .. tostring(#self.Tabs + 1)),
        Icon = options.Icon,
        Segments = options.Segments or options.Subtabs or options.Sections or {},
        ActiveSegment = options.ActiveSegment or options.DefaultSegment,
        SegmentCallback = options.SegmentCallback,
        Controls = {}
    }, Tab)

    tab:_build()
    table.insert(self.Tabs, tab)

    if not self.ActiveTab or options.Default then
        tab:Select()
    else
        tab.Page.Visible = false
    end

    return tab
end

Window.CreateTab = Window.Tab

function Window:_selectTab(targetTab)
    self.ActiveTab = targetTab

    if self.PageTitle then
        self.PageTitle.Text = targetTab.Title
    end

    self:_renderSegments(targetTab)

    for _, tab in ipairs(self.Tabs) do
        local selected = tab == targetTab
        tab.Page.Visible = selected
        tab.Button.BackgroundTransparency = selected and 0 or 1
        tab.Button.BackgroundColor3 = selected and self.Theme.SurfaceHover or self.Theme.Sidebar
        tab.TitleLabel.TextColor3 = selected and self.Theme.Text or self.Theme.Subtext

        if tab.IconObject then
            if tab.IconObject:IsA("ImageLabel") then
                tab.IconObject.ImageColor3 = selected and self.Theme.Text or self.Theme.Subtext
            else
                tab.IconObject.TextColor3 = selected and self.Theme.Text or self.Theme.Subtext
            end
        end
    end
end

function Window:_renderSegments(tab)
    if not self.SegmentHolder then
        return
    end

    for _, child in ipairs(self.SegmentHolder:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end

    local segments = tab.Segments or {}

    if #segments == 0 then
        self.SegmentHolder.Visible = false
        return
    end

    self.SegmentHolder.Visible = true
    tab.ActiveSegment = tab.ActiveSegment or optionTitle(segments[1])

        for index, segment in ipairs(segments) do
        local label = optionTitle(segment)
        local selected = label == tab.ActiveSegment
        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = selected and self.Theme.SurfaceHover or self.Theme.Sidebar,
            BackgroundTransparency = selected and 0 or 0.45,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            LayoutOrder = index,
            Text = label,
            TextColor3 = selected and self.Theme.Text or self.Theme.Muted,
            TextSize = 13,
            Size = UDim2.fromOffset(math.max(58, (#label * 8) + 24), 34),
            Parent = self.SegmentHolder
        })

        addCorner(button, 8)

        if selected then
            addStroke(button, self.Theme.Stroke, 0.8)
        end

        button.MouseButton1Click:Connect(function()
            press(button, button.Size)
            tab.ActiveSegment = label
            self:_renderSegments(tab)
            safeCall(tab.SegmentCallback, label)
        end)
    end
end

function Tab:_build()
    local window = self.Window
    local theme = window.Theme

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, 38),
        Parent = window.TabHolder
    })
    addCorner(button, 8)

    local icon = makeIcon(button, self.Icon or self.Title:sub(1, 1), theme, 22)

    if icon then
        icon.Position = UDim2.fromOffset(14, 8)
    end

    local titleOffset = icon and 44 or 14
    local title = makeText(button, self.Title, 13, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(titleOffset, 0),
        Size = UDim2.new(1, -titleOffset - 10, 1, 0)
    })

    local page = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 4,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = window.Content
    })

    addPadding(page, 0, 0, 0, 0)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })

    button.MouseEnter:Connect(function()
        if window.ActiveTab ~= self then
            tween(button, { BackgroundTransparency = 0.45, BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
        end
    end)

    button.MouseLeave:Connect(function()
        if window.ActiveTab ~= self then
            tween(button, { BackgroundTransparency = 1, BackgroundColor3 = theme.Sidebar }, DEFAULT_TWEEN)
        end
    end)

    button.MouseButton1Click:Connect(function()
        press(button, UDim2.new(1, 0, 0, 38))
        self:Select()
    end)

    self.Button = button
    self.TitleLabel = title
    self.IconObject = icon
    self.Page = page
end

function Tab:Select()
    self.Window:_selectTab(self)
end

function Tab:_base(options, height)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local hasBodyText = hasSupportText(options)
    local insetX = self.IsGroup and 22 or 14
    local frame = create("Frame", {
        BackgroundColor3 = self.IsGroup and theme.Window or theme.Surface,
        BackgroundTransparency = self.IsGroup and 1 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, height or 64),
        Parent = self.Page
    })

    if not self.IsGroup then
        addCorner(frame, 8)
        addStroke(frame, theme.Stroke, 0.45)
    end

    local title = makeText(frame, options.Title or options.Name or "Control", self.IsGroup and 13 or 13, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(insetX, hasBodyText and 8 or 0),
        Size = UDim2.new(1, -(insetX * 2), 0, hasBodyText and 22 or height or 64)
    })

    local desc = nil

    if hasBodyText then
        desc = makeText(frame, options.Desc or options.Description or options.Content, 12, theme.Subtext, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(insetX, 32),
            Size = UDim2.new(1, -(insetX * 2), 0, 20)
        })
    end

    local control = setmetatable({
        Tab = self,
        Window = self.Window,
        Frame = frame,
        Title = title,
        Desc = desc,
        Options = options
    }, Control)

    table.insert(self.Controls, control)
    return control
end

function Tab:Group(options)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local height = options.Height or 310
    local frame = create("Frame", {
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, height),
        Parent = self.Page
    })
    addCorner(frame, 8)
    addStroke(frame, theme.Stroke, 0.42, 1)

    local icon = makeIcon(frame, options.Icon or "A", theme, 20)
    icon.Position = UDim2.fromOffset(16, 14)

    makeText(frame, options.Title or options.Name or "Group", 13, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(44, 13),
        Size = UDim2.new(1, -60, 0, 24)
    })

    local content = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 44),
        Size = UDim2.new(1, 0, 1, -52),
        Parent = frame
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content
    })

    local group = setmetatable({
        Window = self.Window,
        ParentTab = self,
        Page = content,
        Controls = {},
        IsGroup = true,
        Frame = frame
    }, {
        __index = Tab
    })

    return group
end

function Tab:Section(title)
    local theme = self.Window.Theme

    local label = makeText(self.Page, tostring(title or "Section"), 12, theme.Muted, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 24)
    })
    label.Text = string.upper(label.Text)

    return label
end

function Tab:Paragraph(options)
    options = normalizeOptions(options)

    local text = options.Desc or options.Content or options.Description or ""
    local height = text ~= "" and 86 or 54
    local control = self:_base(options, height)

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -28, 0, 42)
        control.Desc.TextWrapped = true
        control.Desc.TextYAlignment = Enum.TextYAlignment.Top
    end

    return control
end

function Tab:Button(options)
    options = normalizeOptions(options)

    if self.IsGroup or options.Full then
        local theme = self.Window.Theme
        local row = create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Parent = self.Page
        })

        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            Position = UDim2.fromOffset(22, 0),
            Size = UDim2.new(1, -44, 1, 0),
            Text = options.Title or options.Name or "Button",
            TextColor3 = theme.Text,
            TextSize = 13,
            Parent = row
        })
        addCorner(button, 8)
        addStroke(button, theme.Stroke, 0.12)

        button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
        end)

        button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = theme.Input }, DEFAULT_TWEEN)
        end)

        button.MouseButton1Click:Connect(function()
            press(button, UDim2.new(1, -44, 1, 0))
            safeCall(options.Callback)
        end)

        local control = setmetatable({
            Tab = self,
            Window = self.Window,
            Frame = row,
            Button = button,
            Options = options
        }, Control)

        table.insert(self.Controls, control)
        return control
    end

    local control = self:_base(options, hasSupportText(options) and 66 or 48)
    local frame = control.Frame
    local theme = self.Window.Theme

    if control.Title then
        control.Title.Size = UDim2.new(1, -62, 0, control.Desc and 20 or frame.Size.Y.Offset)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -62, 0, 20)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            safeCall(options.Callback)
        end
    end)

    frame.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
    end)

    frame.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = theme.Surface }, DEFAULT_TWEEN)
    end)

    local arrow = makeText(frame, ">", 16, theme.Accent, Enum.Font.GothamBold, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        TextXAlignment = Enum.TextXAlignment.Center
    })

    control.Arrow = arrow
    return control
end

function Tab:Toggle(options)
    options = normalizeOptions(options)

    local control = self:_base(options, self.IsGroup and 30 or (hasSupportText(options) and 58 or 44))
    local frame = control.Frame
    local theme = self.Window.Theme
    local value = firstDefined(options.Default, options.Value, false)

    if control.Title then
        control.Title.Size = UDim2.new(1, -58, 0, control.Desc and 20 or frame.Size.Y.Offset)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -74, 0, 20)
    end

    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = value and theme.Accent or theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.new(1, self.IsGroup and -22 or -14, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        Parent = frame
    })
    addCorner(track, 5)
    addStroke(track, theme.Stroke, 0.15)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        Visible = value,
        Parent = track
    })
    addCorner(knob, 4)

    local object = setmetatable({
        Value = value,
        Set = nil
    }, {
        __index = control
    })

    local function apply(nextValue, silent)
        value = nextValue == true
        object.Value = value

        tween(track, { BackgroundColor3 = value and theme.Accent or theme.Input }, DEFAULT_TWEEN)
        knob.Visible = value

        if options.Flag then
            self.Window:SetFlag(options.Flag, value)
        end

        if not silent then
            safeCall(options.Callback, value)
        end
    end

    object.Set = apply

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            press(track, UDim2.fromOffset(20, 20))
            apply(not value)
        end
    end)

    apply(value, true)
    return object
end

function Tab:Slider(options)
    options = normalizeOptions(options)

    local min, max, default = getSliderConfig(options)
    local step = options.Step
    local decimals = options.Rounding or options.Decimals or 0
    local suffix = options.Suffix or ""
    local value = math.clamp(default, min, max)
    local theme = self.Window.Theme
    local control = self:_base(options, self.IsGroup and 56 or (hasSupportText(options) and 74 or 62))
    local frame = control.Frame

    local valueLabel = makeText(frame, tostring(value) .. suffix, 13, theme.Muted, Enum.Font.GothamMedium, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, self.IsGroup and -22 or -14, 0, self.IsGroup and 0 or (control.Desc and 12 or 14)),
        Size = UDim2.fromOffset(82, 20),
        TextXAlignment = Enum.TextXAlignment.Right
    })

    if control.Title then
        control.Title.Size = UDim2.new(1, -96, 0, self.IsGroup and 24 or 20)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -116, 0, 20)
    end

    local track = create("Frame", {
        AnchorPoint = self.IsGroup and Vector2.new(0, 0) or Vector2.new(0, 1),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Position = self.IsGroup and UDim2.fromOffset(22, 34) or UDim2.new(0, 14, 1, -18),
        Size = UDim2.new(1, self.IsGroup and -44 or -28, 0, 5),
        Parent = frame
    })
    addCorner(track, 3)

    local fill = create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track
    })
    addCorner(fill, 4)

    local handle = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Parent = track
    })
    addCorner(handle, 6)
    addStroke(handle, theme.Accent, 0.15)

    local dragging = false
    local object = setmetatable({
        Value = value,
        Set = nil
    }, {
        __index = control
    })

    local function apply(nextValue, silent)
        nextValue = math.clamp(nextValue, min, max)
        nextValue = roundValue(nextValue - min, step, decimals) + min
        nextValue = math.clamp(nextValue, min, max)
        value = nextValue
        object.Value = value

        local alpha = (value - min) / (max - min)
        if max == min then
            alpha = 0
        end

        valueLabel.Text = tostring(value) .. suffix
        tween(fill, { Size = UDim2.fromScale(alpha, 1) }, DEFAULT_TWEEN)
        tween(handle, { Position = UDim2.fromScale(alpha, 0.5) }, DEFAULT_TWEEN)

        if options.Flag then
            self.Window:SetFlag(options.Flag, value)
        end

        if not silent then
            safeCall(options.Callback, value)
        end
    end

    local function fromInput(input, silent)
        local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        apply(min + ((max - min) * math.clamp(alpha, 0, 1)), silent)
    end

    object.Set = apply

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input)
        end
    end)

    table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end))

    table.insert(self.Window._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    apply(value, true)
    return object
end

function Tab:Input(options)
    options = normalizeOptions(options)

    if self.IsGroup or options.Full then
        local theme = self.Window.Theme
        local value = firstDefined(options.Default, options.Value, options.Text, "")
        local row = create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 36),
            Parent = self.Page
        })

        local box = create("TextBox", {
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.GothamMedium,
            PlaceholderText = options.Placeholder or options.Title or "",
            PlaceholderColor3 = theme.Muted,
            Position = UDim2.fromOffset(22, 0),
            Size = UDim2.new(1, -44, 1, 0),
            Text = tostring(value),
            TextColor3 = theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row
        })
        addCorner(box, 8)
        addStroke(box, theme.Stroke, 0.12)
        addPadding(box, 12, 0, 12, 0)

        local control = setmetatable({
            Tab = self,
            Window = self.Window,
            Frame = row,
            Box = box,
            Value = value,
            Options = options
        }, Control)

        local function apply(nextValue, silent)
            if options.Numeric then
                nextValue = tonumber(nextValue) or 0
            end

            value = nextValue
            control.Value = value
            box.Text = tostring(value)

            if options.Flag then
                self.Window:SetFlag(options.Flag, value)
            end

            if not silent then
                safeCall(options.Callback, value)
            end
        end

        control.Set = apply

        box.FocusLost:Connect(function()
            apply(box.Text)
        end)

        apply(value, true)
        return control
    end

    local theme = self.Window.Theme
    local control = self:_base(options, hasSupportText(options) and 78 or 64)
    local frame = control.Frame
    local value = firstDefined(options.Default, options.Value, "")

    if control.Title then
        control.Title.Size = UDim2.new(1, -248, 0, 20)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -248, 0, 20)
    end

    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = theme.Muted,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(options.Width or 220, 32),
        Text = tostring(value),
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    addCorner(box, 8)
    addStroke(box, theme.Stroke, 0.5)
    addPadding(box, 10, 0, 10, 0)

    local object = setmetatable({
        Value = value,
        Set = nil,
        Box = box
    }, {
        __index = control
    })

    local function apply(nextValue, silent)
        if options.Numeric then
            nextValue = tonumber(nextValue) or 0
        end

        value = nextValue
        object.Value = value
        box.Text = tostring(value)

        if options.Flag then
            self.Window:SetFlag(options.Flag, value)
        end

        if not silent then
            safeCall(options.Callback, value)
        end
    end

    object.Set = apply

    box.Focused:Connect(function()
        tween(box, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
    end)

    box.FocusLost:Connect(function()
        tween(box, { BackgroundColor3 = theme.Input }, DEFAULT_TWEEN)
        apply(box.Text)
    end)

    apply(value, true)
    return object
end

function Tab:Dropdown(options)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local values = options.Values or options.Options or {}
    local multi = options.Multi or false
    local collapsedHeight = self.IsGroup and 32 or (hasSupportText(options) and 68 or 54)
    local maxVisible = options.MaxVisible or 5
    local optionHeight = 32
    local expandedHeight = collapsedHeight + (math.min(#values, maxVisible) * (optionHeight + 4)) + 14
    local control = self:_base(options, collapsedHeight)
    local frame = control.Frame
    local selected = multi and {} or firstDefined(options.Default, options.Value)
    local expanded = false

    if multi then
        local default = firstDefined(options.Default, options.Value)

        if typeof(default) == "table" then
            for key, entry in pairs(default) do
                if typeof(key) == "number" then
                    selected[entry] = true
                else
                    selected[key] = entry == true
                end
            end
        elseif default ~= nil then
            selected[default] = true
        end
    end

    if control.Title then
        control.Title.Size = UDim2.new(1, self.IsGroup and -144 or -190, 0, self.IsGroup and 32 or 20)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -220, 0, 20)
    end

    local selectButton = create("TextButton", {
        AnchorPoint = self.IsGroup and Vector2.new(1, 0.5) or Vector2.new(1, 0),
        AutoButtonColor = false,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Position = self.IsGroup and UDim2.new(1, -22, 0.5, 0) or UDim2.new(1, -14, 0, 15),
        Size = UDim2.fromOffset(options.Width or (self.IsGroup and 112 or 170), self.IsGroup and 28 or 30),
        Text = "",
        Parent = frame
    })
    addCorner(selectButton, 7)
    addStroke(selectButton, theme.Stroke, 0.55)

    local selectText = makeText(selectButton, options.Placeholder or "Select", 12, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -34, 1, 0)
    })

    local chevron = makeText(selectButton, "v", 12, theme.Subtext, Enum.Font.GothamBold, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        TextXAlignment = Enum.TextXAlignment.Center
    })

    local list = create("ScrollingFrame", {
        Active = true,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(self.IsGroup and 22 or 14, collapsedHeight - 2),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, self.IsGroup and -44 or -28, 0, math.min(#values, maxVisible) * (optionHeight + 4)),
        Visible = false,
        Parent = frame
    })
    addCorner(list, 8)
    addStroke(list, theme.Stroke, 0.55)
    addPadding(list, 6, 6, 6, 6)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = list
    })

    local object = setmetatable({
        Value = selected,
        Set = nil,
        Refresh = nil
    }, {
        __index = control
    })

    local function describeSelection()
        if multi then
            local text = {}

            for _, option in ipairs(values) do
                local value = optionValue(option)

                if selected[value] then
                    table.insert(text, optionTitle(option))
                end
            end

            return #text > 0 and table.concat(text, ", ") or (options.Placeholder or "Select")
        end

        if selected == nil then
            return options.Placeholder or "Select"
        end

        for _, option in ipairs(values) do
            if optionValue(option) == selected then
                return optionTitle(option)
            end
        end

        return tostring(selected)
    end

    local function apply(nextValue, silent)
        selected = nextValue
        object.Value = selected
        selectText.Text = describeSelection()

        if options.Flag then
            self.Window:SetFlag(options.Flag, selected)
        end

        if not silent then
            safeCall(options.Callback, selected)
        end
    end

    local function setExpanded(nextExpanded)
        expanded = nextExpanded
        list.Visible = expanded
        chevron.Text = expanded and "^" or "v"

        tween(frame, {
            Size = UDim2.new(1, 0, 0, expanded and expandedHeight or collapsedHeight)
        }, DEFAULT_TWEEN)
    end

    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end

        expandedHeight = collapsedHeight + (math.min(#values, maxVisible) * (optionHeight + 4)) + 14
        list.Size = UDim2.new(1, self.IsGroup and -44 or -28, 0, math.min(#values, maxVisible) * (optionHeight + 4))

        for _, option in ipairs(values) do
            local value = optionValue(option)
            local item = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Surface,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                Text = "  " .. optionTitle(option),
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, optionHeight),
                Parent = list
            })
            addCorner(item, 7)

            item.MouseEnter:Connect(function()
                tween(item, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
            end)

            item.MouseLeave:Connect(function()
                tween(item, { BackgroundColor3 = theme.Surface }, DEFAULT_TWEEN)
            end)

            item.MouseButton1Click:Connect(function()
                if multi then
                    selected[value] = not selected[value]
                    apply(selected)
                else
                    apply(value)
                    setExpanded(false)
                end
            end)
        end

        selectText.Text = describeSelection()
    end

    object.Set = apply
    object.Refresh = function(newValues)
        values = newValues or values
        rebuild()
    end

    selectButton.MouseButton1Click:Connect(function()
        press(selectButton, selectButton.Size)
        setExpanded(not expanded)
    end)

    rebuild()
    apply(selected, true)
    return object
end

function Tab:Keybind(options)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local control = self:_base(options, self.IsGroup and 30 or (hasSupportText(options) and 60 or 44))
    local frame = control.Frame
    local key = firstDefined(options.Default, options.Key, Enum.KeyCode.RightControl)
    local listening = false

    if control.Title then
        control.Title.Size = UDim2.new(1, self.IsGroup and -66 or -130, 0, self.IsGroup and 30 or 20)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -150, 0, 20)
    end

    local keyButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Position = UDim2.new(1, self.IsGroup and -22 or -14, 0.5, 0),
        Size = UDim2.fromOffset(self.IsGroup and 34 or 104, 28),
        Text = formatKeyCode(key),
        TextColor3 = theme.Text,
        TextSize = 12,
        Parent = frame
    })
    addCorner(keyButton, 8)
    addStroke(keyButton, theme.Stroke, 0.55)

    local object = setmetatable({
        Value = key,
        Set = nil
    }, {
        __index = control
    })

    local function apply(nextKey, silent)
        key = nextKey
        object.Value = key
        keyButton.Text = formatKeyCode(key)

        if options.Flag then
            self.Window:SetFlag(options.Flag, key)
        end

        if not silent then
            safeCall(options.Changed, key)
        end
    end

    object.Set = apply

    keyButton.MouseButton1Click:Connect(function()
        press(keyButton, keyButton.Size)
        listening = true
        keyButton.Text = "..."
    end)

    table.insert(self.Window._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if listening then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                listening = false
                apply(input.KeyCode)
            end

            return
        end

        if input.KeyCode == key then
            safeCall(options.Callback, key)
        end
    end))

    apply(key, true)
    return object
end

function Tab:Colorpicker(options)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local startColor = firstDefined(options.Default, options.Value, Color3.fromRGB(255, 255, 255))
    local control = self:_base(options, hasSupportText(options) and 132 or 116)
    local frame = control.Frame
    local value = startColor

    if control.Title then
        control.Title.Size = UDim2.new(1, -76, 0, 20)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -76, 0, 20)
    end

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(42, 28),
        Parent = frame
    })
    addCorner(swatch, 8)
    addStroke(swatch, theme.Stroke, 0.4)

    local object = setmetatable({
        Value = value,
        Set = nil
    }, {
        __index = control
    })

    local channels = {
        { Name = "R", Value = math.floor(value.R * 255 + 0.5), Color = Color3.fromRGB(239, 82, 94) },
        { Name = "G", Value = math.floor(value.G * 255 + 0.5), Color = Color3.fromRGB(52, 199, 128) },
        { Name = "B", Value = math.floor(value.B * 255 + 0.5), Color = Color3.fromRGB(91, 141, 255) }
    }

    local sliders = {}

    local function applyColor(nextColor, silent)
        value = nextColor
        object.Value = value
        swatch.BackgroundColor3 = value

        local channelValues = {
            math.floor(value.R * 255 + 0.5),
            math.floor(value.G * 255 + 0.5),
            math.floor(value.B * 255 + 0.5)
        }

        for index, slider in ipairs(sliders) do
            slider.Value = channelValues[index]
            slider.Fill.Size = UDim2.new(channelValues[index] / 255, 0, 1, 0)
        end

        if options.Flag then
            self.Window:SetFlag(options.Flag, value)
        end

        if not silent then
            safeCall(options.Callback, value)
        end
    end

    object.Set = applyColor

    for index, channel in ipairs(channels) do
        local rowY = (control.Desc and 62 or 48) + ((index - 1) * 24)

        makeText(frame, channel.Name, 12, theme.Subtext, Enum.Font.GothamBold, {
            Position = UDim2.fromOffset(14, rowY - 3),
            Size = UDim2.fromOffset(18, 18),
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local track = create("Frame", {
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(40, rowY),
            Size = UDim2.new(1, -70, 0, 8),
            Parent = frame
        })
        addCorner(track, 4)

        local fill = create("Frame", {
            BackgroundColor3 = channel.Color,
            BorderSizePixel = 0,
            Size = UDim2.new(channel.Value / 255, 0, 1, 0),
            Parent = track
        })
        addCorner(fill, 4)

        sliders[index] = {
            Track = track,
            Fill = fill,
            Value = channel.Value
        }

        local dragging = false

        local function updateFromInput(input)
            local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            sliders[index].Value = math.floor(alpha * 255 + 0.5)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            applyColor(Color3.fromRGB(sliders[1].Value, sliders[2].Value, sliders[3].Value))
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)

        table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end))

        table.insert(self.Window._connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    applyColor(value, true)
    return object
end

Tab.CreateSection = Tab.Section
Tab.CreateGroup = Tab.Group
Tab.CreateParagraph = Tab.Paragraph
Tab.CreateButton = Tab.Button
Tab.CreateToggle = Tab.Toggle
Tab.CreateSlider = Tab.Slider
Tab.CreateInput = Tab.Input
Tab.CreateDropdown = Tab.Dropdown
Tab.CreateKeybind = Tab.Keybind
Tab.CreateColorpicker = Tab.Colorpicker

Singularity.Theme = resolveTheme("Dark")

return Singularity
