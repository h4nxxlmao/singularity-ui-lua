--[[
    Singularity UI
    A compact Roblox Luau interface library with its own Singularity visual system.

    This file is self-contained and can be used as a ModuleScript or through
    loadstring(game:HttpGet(...))().
]]

local Singularity = {}
Singularity.__index = Singularity

Singularity.Name = "Singularity UI"
Singularity.Version = "0.2.0"
Singularity.UseLucide = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local DEFAULT_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local SLOW_TWEEN = TweenInfo.new(0.34, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local PRESS_TWEEN = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DEFAULT_LOGO = 73636428262287

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Control = {}
Control.__index = Control

local LUCIDE_LOADER_URL = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
local LucideIcons = nil
local LucideTried = false
local DecalTextureCache = {}

Singularity.Themes = {
    Dark = {
        Window = Color3.fromRGB(8, 9, 11),
        Topbar = Color3.fromRGB(13, 14, 17),
        Sidebar = Color3.fromRGB(10, 11, 14),
        Surface = Color3.fromRGB(15, 16, 20),
        SurfaceHover = Color3.fromRGB(24, 26, 31),
        Input = Color3.fromRGB(19, 21, 25),
        Stroke = Color3.fromRGB(40, 43, 50),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentDark = Color3.fromRGB(38, 40, 46),
        Text = Color3.fromRGB(242, 244, 248),
        Subtext = Color3.fromRGB(178, 186, 198),
        Muted = Color3.fromRGB(115, 124, 137),
        Success = Color3.fromRGB(75, 214, 139),
        Warning = Color3.fromRGB(234, 181, 80),
        Danger = Color3.fromRGB(255, 105, 117)
    }
}

Singularity.Themes.Singularity = Singularity.Themes.Dark
Singularity.Themes.SingularityDark = Singularity.Themes.Dark
Singularity.Themes["singularity-dark"] = Singularity.Themes.Dark
Singularity.Themes.Reference = Singularity.Themes.Dark

Singularity.Icons = {
    alert = "rbxassetid://73186275216515",
    bag = "rbxassetid://8601111810",
    boss = "rbxassetid://13132186360",
    cart = "rbxassetid://128874923961846",
    compas = "rbxassetid://125300760963399",
    crosshair = "rbxassetid://12614416478",
    dcs = "rbxassetid://15310731934",
    discord = "rbxassetid://94434236999817",
    eyes = "rbxassetid://14321059114",
    fish = "rbxassetid://97167558235554",
    folder = "rbxassetid://111411260968321",
    gamepad = "rbxassetid://84173963561612",
    gps = "rbxassetid://17824309485",
    idea = "rbxassetid://16833255748",
    loop = "rbxassetid://122032243989747",
    menu = "rbxassetid://6340513838",
    next = "rbxassetid://12662718374",
    notify = "rbxassetid://70884221600423",
    payment = "rbxassetid://18747025078",
    player = "rbxassetid://12120698352",
    plug = "rbxassetid://137601480983962",
    question = "rbxassetid://17510196486",
    rod = "rbxassetid://103247953194129",
    scan = "rbxassetid://109869955247116",
    scroll = "rbxassetid://114127804740858",
    settings = "rbxassetid://70386228443175",
    shop = "rbxassetid://4985385964",
    skeleton = "rbxassetid://17313330026",
    star = "rbxassetid://107005941750079",
    start = "rbxassetid://108886429866687",
    stat = "rbxassetid://12094445329",
    strom = "rbxassetid://13321880293",
    sword = "rbxassetid://82472368671405",
    sword1 = "rbxassetid://109643735374029",
    user = "rbxassetid://108483430622128",
    water = "rbxassetid://100076212630732",
    web = "rbxassetid://137601480983962"
}

Singularity.IconPacks = {
    default = Singularity.Icons
}

local function copy(source)
    local target = {}

    for key, value in pairs(source) do
        target[key] = value
    end

    return target
end

local function resolveTheme(theme)
    local base = copy(Singularity.Themes.Dark)

    if typeof(theme) == "string" then
        local key = string.lower(theme)
        local selected = Singularity.Themes[theme] or Singularity.Themes[key]

        if selected then
            return copy(selected)
        end
    end

    if typeof(theme) == "table" then
        for key, value in pairs(theme) do
            base[key] = value
        end
    end

    return base
end

function Singularity:RegisterIcons(packName, icons)
    if typeof(packName) == "table" and icons == nil then
        icons = packName
        packName = "default"
    end

    if typeof(icons) ~= "table" then
        warn("[Singularity UI] RegisterIcons expected an icon table")
        return nil
    end

    local normalizedName = string.lower(tostring(packName or "default"))
    local aliases = {}

    for name, image in pairs(icons) do
        if typeof(name) == "string" then
            aliases[string.lower(name)] = image
        end
    end

    for name, image in pairs(aliases) do
        icons[name] = image
    end

    self.IconPacks[normalizedName] = icons

    if normalizedName == "default" then
        self.Icons = icons
    end

    return icons
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
        math.max(0, normalSize.X.Offset - 2),
        normalSize.Y.Scale,
        math.max(0, normalSize.Y.Offset - 2)
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

local function setIconColor(icon, color)
    if not icon then
        return
    end

    if icon:IsA("UIStroke") then
        icon.Color = color
    end

    if icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
        icon.ImageColor3 = color
    elseif icon:IsA("TextLabel") or icon:IsA("TextButton") then
        icon.TextColor3 = color
    elseif icon:IsA("Frame") and icon.BackgroundTransparency < 1 then
        icon.BackgroundColor3 = color
    end

    for _, child in ipairs(icon:GetChildren()) do
        setIconColor(child, color)
    end
end

local function searchableText(options, fallback)
    options = normalizeOptions(options)

    return string.lower(table.concat({
        tostring(options.Title or options.Name or fallback or ""),
        tostring(options.Desc or options.Description or options.Content or ""),
        tostring(options.Flag or ""),
        tostring(options.Placeholder or "")
    }, " "))
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

local function fetchText(url)
    if game.HttpGetAsync then
        local ok, result = pcall(function()
            return game:HttpGetAsync(url)
        end)

        if ok then
            return result
        end
    end

    if game.HttpGet then
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)

        if ok then
            return result
        end
    end

    return nil
end

local function getLucideIcons()
    if not Singularity.UseLucide or LucideTried then
        return LucideIcons
    end

    LucideTried = true

    if not loadstring then
        return nil
    end

    local source = fetchText(LUCIDE_LOADER_URL)

    if not source then
        return nil
    end

    local chunk = loadstring(source)

    if not chunk then
        return nil
    end

    local ok, icons = pcall(chunk)

    if not ok or typeof(icons) ~= "table" then
        return nil
    end

    pcall(function()
        icons.SetIconsType("lucide")
    end)

    LucideIcons = icons
    return LucideIcons
end

local function normalizedAssetId(id)
    local text = tostring(id)

    if text:find("rbxassetid://") == 1 then
        text = text:gsub("rbxassetid://", "")
    end

    return text:match("^%d+$") and text or nil
end

local function decalTexture(id)
    local assetId = normalizedAssetId(id)

    if not assetId then
        return nil
    end

    if DecalTextureCache[assetId] then
        return DecalTextureCache[assetId]
    end

    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)
    end)

    if not ok or typeof(objects) ~= "table" then
        return nil
    end

    local object = objects[1]
    local decal = nil

    if object then
        if object:IsA("Decal") then
            decal = object
        else
            decal = object:FindFirstChildWhichIsA("Decal", true)
        end
    end

    local texture = decal and decal.Texture or nil

    if object then
        pcall(function()
            object:Destroy()
        end)
    end

    if texture and texture ~= "" then
        DecalTextureCache[assetId] = texture
        return texture
    end

    return nil
end

local function assetImage(id)
    local text = tostring(id)

    if text:find("rbxthumb://") == 1 or text:find("http://") == 1 or text:find("https://") == 1 then
        return text
    end

    local texture = decalTexture(text)

    if texture then
        return texture
    end

    if text:find("rbxassetid://") == 1 then
        return text
    end

    return "rbxassetid://" .. text
end

local function setAssetImage(imageLabel, image, fallback)
    imageLabel.Image = assetImage(image)

    if fallback then
        fallback.Visible = false
    end

    local assetId = normalizedAssetId(image)

    if not assetId then
        return
    end

    task.spawn(function()
        local texture = decalTexture(assetId)

        if texture and imageLabel and imageLabel.Parent then
            imageLabel.Image = texture
        end
    end)
end

local function makeAssetIcon(parent, image, theme, size)
    local icon = create("ImageLabel", {
        BackgroundTransparency = 1,
        ImageColor3 = theme.Text,
        Size = UDim2.fromOffset(size, size),
        Parent = parent
    })

    setAssetImage(icon, image)

    return icon
end

local function lookupIconInPack(pack, key)
    if typeof(pack) ~= "table" then
        return nil
    end

    return pack[key] or pack[string.lower(key)]
end

local function lookupRegisteredIcon(icon)
    local key = string.lower(tostring(icon))
    local packName, packKey = key:match("^([%w_%-]+):(.+)$")

    if packName and packKey then
        return lookupIconInPack(Singularity.IconPacks[packName], packKey)
    end

    local direct = lookupIconInPack(Singularity.Icons, key)

    if direct then
        return direct
    end

    for _, pack in pairs(Singularity.IconPacks) do
        local image = lookupIconInPack(pack, key)

        if image then
            return image
        end
    end

    return nil
end

local function makeLucideImage(parent, icon, theme, size)
    local icons = getLucideIcons()

    if not icons then
        return nil
    end

    local iconData = nil
    local ok = false

    if typeof(icons.Icon2) == "function" then
        ok = pcall(function()
            iconData = icons.Icon2(tostring(icon), "lucide")
        end)
    else
        ok = true
        iconData = lookupIconInPack(icons, tostring(icon))
    end

    if not ok or not iconData then
        return nil
    end

    local image = nil
    local rectSize = nil
    local rectOffset = nil

    if typeof(iconData) == "string" then
        image = iconData
    elseif typeof(iconData) == "table" then
        image = iconData[1]

        if iconData[2] then
            rectSize = iconData[2].ImageRectSize
            rectOffset = iconData[2].ImageRectPosition
        end
    end

    if not image then
        return nil
    end

    local iconLabel = create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = image,
        ImageColor3 = theme.Text,
        ImageRectSize = rectSize or Vector2.new(0, 0),
        ImageRectOffset = rectOffset or Vector2.new(0, 0),
        Size = UDim2.fromOffset(size, size),
        Parent = parent
    })

    return iconLabel
end

local function line(parent, position, size, color, rotation)
    local object = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = position,
        Rotation = rotation or 0,
        Size = size,
        Parent = parent
    })
    addCorner(object, 2)
    return object
end

local function makeLucideIcon(parent, icon, theme, size)
    icon = string.lower(tostring(icon))
    size = size or 18

    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent
    })

    local color = theme.Text
    local stroke = math.max(1, math.floor(size / 9))

    if icon == "search" then
        local circle = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.18, 0.16),
            Size = UDim2.fromScale(0.5, 0.5),
            Parent = holder
        })
        addCorner(circle, size)
        addStroke(circle, color, 0, stroke)
        line(holder, UDim2.fromScale(0.72, 0.72), UDim2.fromScale(0.36, 0.1), color, 45)
    elseif icon == "settings" then
        local circle = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.29, 0.29),
            Size = UDim2.fromScale(0.42, 0.42),
            Parent = holder
        })
        addCorner(circle, size)
        addStroke(circle, color, 0, stroke)
        for index = 0, 5 do
            line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.1, 0.86), color, index * 30)
        end
    elseif icon == "page" or icon == "file" then
        local box = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.24, 0.14),
            Size = UDim2.fromScale(0.52, 0.72),
            Parent = holder
        })
        addCorner(box, 3)
        addStroke(box, color, 0, stroke)
        line(holder, UDim2.fromScale(0.54, 0.36), UDim2.fromScale(0.26, 0.08), color, 0)
        line(holder, UDim2.fromScale(0.5, 0.54), UDim2.fromScale(0.34, 0.08), color, 0)
    elseif icon == "user" or icon == "profile" then
        local head = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.35, 0.18),
            Size = UDim2.fromScale(0.3, 0.3),
            Parent = holder
        })
        addCorner(head, size)
        addStroke(head, color, 0, stroke)
        local body = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.23, 0.58),
            Size = UDim2.fromScale(0.54, 0.24),
            Parent = holder
        })
        addCorner(body, size)
        addStroke(body, color, 0, stroke)
    elseif icon == "aimbot" or icon == "crosshair" or icon == "combat" then
        local circle = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.24, 0.24),
            Size = UDim2.fromScale(0.52, 0.52),
            Parent = holder
        })
        addCorner(circle, size)
        addStroke(circle, color, 0, stroke)
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.72, 0.08), color, 0)
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.08, 0.72), color, 0)
    elseif icon == "weapon" then
        line(holder, UDim2.fromScale(0.5, 0.48), UDim2.fromScale(0.72, 0.12), color, -25)
        line(holder, UDim2.fromScale(0.36, 0.66), UDim2.fromScale(0.24, 0.1), color, 65)
    elseif icon == "minus" then
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.55, 0.08), color, 0)
    elseif icon == "x" or icon == "close" then
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.6, 0.08), color, 45)
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.6, 0.08), color, -45)
    else
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.62, 0.08), color, 0)
        line(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.08, 0.62), color, 0)
    end

    return holder
end

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
        ZIndex = props.ZIndex or 1,
        Parent = parent
    })
end

local function makeIcon(parent, icon, theme, size)
    if not icon then
        return nil
    end

    size = size or 20

    local iconString = tostring(icon)

    if typeof(icon) == "number"
        or iconString:find("rbxassetid://") == 1
        or iconString:find("rbxthumb://") == 1
        or iconString:find("http://") == 1
        or iconString:find("https://") == 1 then
        return makeAssetIcon(parent, icon, theme, size)
    end

    local lucideIcon = makeLucideImage(parent, icon, theme, size)

    if lucideIcon then
        return lucideIcon
    end

    local drawnIcon = makeLucideIcon(parent, icon, theme, size)

    if drawnIcon then
        return drawnIcon
    end

    local registeredIcon = lookupRegisteredIcon(icon)

    if registeredIcon then
        return makeAssetIcon(parent, registeredIcon, theme, size)
    end

    return nil
end

function Singularity:SetTheme(theme)
    self.Theme = resolveTheme(theme)
    return self.Theme
end

function Singularity:_ensureNotificationLayer()
    if self._notificationGui and self._notificationGui.Parent then
        return self._notificationHolder
    end

    local theme = self.Theme or resolveTheme("singularity-dark")

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

    local theme = self._notificationTheme or self.Theme or resolveTheme("singularity-dark")
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

    makeText(frame, options.Title or "Singularity", 13, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 18)
    })

    if options.Content then
        makeText(frame, options.Content, 12, theme.Subtext, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 0, 30),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top
        })
    end

    local progress = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = frame
    })
    addCorner(progress, 1)

    frame.Position = UDim2.fromOffset(16, -6)
    frame.Size = UDim2.fromOffset(292, 0)
    tween(frame, {
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(292, options.Content and 78 or 58)
    }, SLOW_TWEEN)
    tween(progress, { Size = UDim2.new(0, 0, 0, 1) }, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))

    task.delay(duration, function()
        if frame and frame.Parent then
            tween(progress, { BackgroundTransparency = 1 }, DEFAULT_TWEEN)
            local closeTween = tween(frame, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(16, -6),
                Size = UDim2.fromOffset(292, 0)
            }, SLOW_TWEEN)

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

    local theme = resolveTheme(options.Theme or self.Theme or "singularity-dark")
    self.Theme = theme

    local window = setmetatable({
        Library = self,
        Theme = theme,
        ThemeName = tostring(options.Theme or "singularity-dark"),
        Options = options,
        Tabs = {},
        Flags = {},
        _flagControls = {},
        _connections = {},
        _minimized = false
    }, Window)

    window:_build()

    task.defer(function()
        if window and window.Main and window.Main.Parent then
            window:_ensureBuiltInSettings()
        end
    end)

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

local function getViewportSize()
    local camera = workspace.CurrentCamera

    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function resolveGameName(options)
    if options.Game or options.GameName then
        return tostring(options.Game or options.GameName)
    end

    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    if ok and typeof(info) == "table" and info.Name then
        return tostring(info.Name)
    end

    return game.Name or "Universal"
end

local function resolveWindowSize(options)
    local viewport = getViewportSize()
    local margin = options.ScreenMargin or (viewport.X <= 620 and 8 or 20)
    local requested = options.Size or UDim2.fromOffset(680, 410)
    local requestedWidth = requested.X.Offset
    local requestedHeight = requested.Y.Offset

    if requestedWidth <= 0 then
        requestedWidth = viewport.X * (requested.X.Scale > 0 and requested.X.Scale or 0.82)
    end

    if requestedHeight <= 0 then
        requestedHeight = viewport.Y * (requested.Y.Scale > 0 and requested.Y.Scale or 0.72)
    end

    local maxWidth = math.max(300, viewport.X - (margin * 2))
    local maxHeight = math.max(300, viewport.Y - (margin * 2))
    local constraintMaxWidth = math.min(options.MaxWidth or 900, maxWidth)
    local constraintMaxHeight = math.min(options.MaxHeight or 600, maxHeight)
    local defaultMinWidth = viewport.X <= 620 and 292 or 540
    local defaultMinHeight = viewport.Y <= 520 and 280 or 320
    local constraintMinWidth = math.min(options.MinWidth or defaultMinWidth, constraintMaxWidth)
    local constraintMinHeight = math.min(options.MinHeight or defaultMinHeight, constraintMaxHeight)
    local width = math.clamp(requestedWidth, constraintMinWidth, constraintMaxWidth)
    local height = math.clamp(requestedHeight, constraintMinHeight, constraintMaxHeight)

    return UDim2.fromOffset(width, height),
        Vector2.new(constraintMinWidth, constraintMinHeight),
        Vector2.new(constraintMaxWidth, constraintMaxHeight)
end

local function resolveSidebarWidth(options, windowSize)
    if options.SidebarWidth then
        return math.min(options.SidebarWidth, math.max(150, windowSize.X.Offset - 210))
    end

    if windowSize.X.Offset <= 500 then
        return 58
    elseif windowSize.X.Offset <= 660 then
        return 168
    end

    return 190
end

local function isCompactWindowSize(windowSize)
    return windowSize.X.Offset <= 500
end

local function resolveMinimizedSize(options, windowSize)
    return UDim2.fromOffset(48, 48)
end

local function resolveScale(options)
    if options.Scale ~= nil then
        return options.Scale
    end

    if UserInputService.TouchEnabled then
        return options.MobileScale or 0.74
    end

    return 0.86
end

function Window:_build()
    local options = self.Options
    local theme = self.Theme
    local size, minSize, maxSize = resolveWindowSize(options)
    local sidebarWidth = resolveSidebarWidth(options, size)
    local scale = resolveScale(options)

    local screenGui = create("ScreenGui", {
        Name = options.Name or "SingularityUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local main = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(size.X.Scale, math.max(0, size.X.Offset - 18), size.Y.Scale, math.max(0, size.Y.Offset - 18)),
        Parent = screenGui
    })
    addCorner(main, 8)
    local mainStroke = addStroke(main, theme.Stroke, 0.08)

    if options.Acrylic == true then
        main.BackgroundTransparency = 0.04
    end

    local uiScale = create("UIScale", {
        Scale = scale,
        Parent = main
    })

    local sizeConstraint = create("UISizeConstraint", {
        MinSize = minSize,
        MaxSize = maxSize,
        Parent = main
    })

    local sidebar = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(0, sidebarWidth, 1, -16),
        Parent = main
    })

    local brandCard = create("Frame", {
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = sidebar
    })
    addCorner(brandCard, 7)

    local logo = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(36, 36),
        Parent = brandCard
    })
    addCorner(logo, 8)

    local logoId = firstDefined(options.Logo, DEFAULT_LOGO)

    if logoId ~= false then
        local fallbackLogo = makeText(logo, "S", 18, theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local logoImage = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(30, 30),
            Parent = logo
        })

        self.LogoImage = logoImage
        setAssetImage(logoImage, logoId, fallbackLogo)

        logoImage:GetPropertyChangedSignal("IsLoaded"):Connect(function()
            if logoImage.IsLoaded and fallbackLogo then
                fallbackLogo.Visible = false
            end
        end)

        if logoImage.IsLoaded then
            fallbackLogo.Visible = false
        end
    else
        makeText(logo, "S", 18, theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center
        })
    end

    local gameName = resolveGameName(options)
    local title = makeText(brandCard, options.Title or "Singularity", 14, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(54, 12),
        Size = UDim2.new(1, -62, 0, 18)
    })

    local subtitle = makeText(brandCard, options.Subtitle or gameName, 12, theme.Subtext, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(54, 30),
        Size = UDim2.new(1, -62, 0, 16)
    })

    local navigationLabel = makeText(sidebar, options.NavigationTitle or "Pages", 12, theme.Muted, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(2, 68),
        Size = UDim2.new(1, -4, 0, 18)
    })

    local tabHolder = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(0, 88),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Size = UDim2.new(1, 0, 1, -148),
        Parent = sidebar
    })
    addPadding(tabHolder, 0, 0, 4, 0)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabHolder
    })

    local footer = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 54),
        Parent = sidebar
    })
    addCorner(footer, 7)
    addStroke(footer, theme.Stroke, 0.4)

    local profile = options.Profile or {}
    local profileName = profile.Name
    local profileRole = profile.Role
    local profileAvatar = profile.Avatar

    if profile.Enabled ~= false and LocalPlayer then
        profileName = profileName or LocalPlayer.DisplayName or LocalPlayer.Name
        profileRole = profileRole or ("@" .. LocalPlayer.Name)

        if not profileAvatar then
            local ok, thumbnail = pcall(function()
                return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)

            if ok then
                profileAvatar = thumbnail
            end
        end
    end

    local avatar = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(10, 9),
        Size = UDim2.fromOffset(34, 34),
        Parent = footer
    })
    addCorner(avatar, 8)
    addStroke(avatar, theme.Stroke, 0.42)

    local avatarIcon = makeIcon(avatar, profileAvatar or "user", theme, profileAvatar and 34 or 18)
    avatarIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    avatarIcon.Position = UDim2.fromScale(0.5, 0.5)

    if profileAvatar and (avatarIcon:IsA("ImageLabel") or avatarIcon:IsA("ImageButton")) then
        avatarIcon.ImageColor3 = Color3.new(1, 1, 1)
    end

    local profileNameLabel = makeText(footer, profileName or options.FooterTitle or "User", 12, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(52, 10),
        Size = UDim2.new(1, -62, 0, 16)
    })

    local profileRoleLabel = makeText(footer, profileRole or options.FooterText or "Singularity", 11, theme.Subtext, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(52, 28),
        Size = UDim2.new(1, -62, 0, 14)
    })

    local divider = create("Frame", {
        BackgroundColor3 = theme.Stroke,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 16, 12),
        Size = UDim2.new(0, 1, 1, -24),
        Parent = main
    })

    local contentShell = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 22, 0),
        Size = UDim2.new(1, -sidebarWidth - 30, 1, 0),
        Parent = main
    })

    local pageTitle = makeText(contentShell, "Page", 17, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(14, 18),
        Size = UDim2.new(1, -82, 0, 24)
    })

    local segmentHolder = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(14, 50),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Size = UDim2.new(1, -28, 0, 30),
        Parent = contentShell
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = segmentHolder
    })

    local pageHolder = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 92),
        Size = UDim2.new(1, -24, 1, -106),
        Parent = contentShell
    })

    local dragHeader = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 16, 0),
        Size = UDim2.new(1, -sidebarWidth - 16, 0, 48),
        Parent = main
    })

    local searchFrame = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = theme.Input,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -70, 0, 10),
        Size = UDim2.fromOffset(116, 20),
        Parent = main
    })
    addCorner(searchFrame, 7)
    addStroke(searchFrame, theme.Stroke, 0.55)

    local searchIcon = makeIcon(searchFrame, "search", theme, 14)
    searchIcon.Position = UDim2.fromOffset(8, 5)
    setIconColor(searchIcon, theme.Muted)

    local search = create("TextBox", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = options.SearchPlaceholder or "Search",
        PlaceholderColor3 = theme.Muted,
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Text = "",
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchFrame
    })

    search.Focused:Connect(function()
        tween(searchFrame, { BackgroundColor3 = theme.SurfaceHover, Size = UDim2.fromOffset(152, 20) }, DEFAULT_TWEEN)
    end)

    search.FocusLost:Connect(function()
        tween(searchFrame, { BackgroundColor3 = theme.Input, Size = UDim2.fromOffset(116, 20) }, DEFAULT_TWEEN)
    end)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        self:_applySearch(search.Text)
    end)

    local actions = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(52, 22),
        Parent = main
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = actions
    })

    local minimize = self:_topButton(actions, "minus", theme.Subtext)
    local close = self:_topButton(actions, "x", theme.Danger)

    local minimizedLogo = create("Frame", {
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(32, 32),
        Visible = false,
        Parent = main
    })
    addCorner(minimizedLogo, 9)

    if logoId ~= false then
        local miniFallback = makeText(minimizedLogo, "S", 17, theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local miniLogoImage = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(22, 22),
            Parent = minimizedLogo
        })
        setAssetImage(miniLogoImage, logoId, miniFallback)

        miniLogoImage:GetPropertyChangedSignal("IsLoaded"):Connect(function()
            if miniLogoImage.IsLoaded and miniFallback then
                miniFallback.Visible = false
            end
        end)

        if miniLogoImage.IsLoaded then
            miniFallback.Visible = false
        end
    else
        makeText(minimizedLogo, "S", 17, theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center
        })
    end

    local minimizedTitle = makeText(main, options.Title or "Singularity", 13, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(50, 12),
        Size = UDim2.new(1, -124, 0, 22)
    })
    minimizedTitle.Visible = false

    self.ScreenGui = screenGui
    self.Main = main
    self.MainStroke = mainStroke
    self.UIScale = uiScale
    self.Topbar = dragHeader
    self.BrandCard = brandCard
    self.BrandLogo = logo
    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.NavigationLabel = navigationLabel
    self.Footer = footer
    self.ProfileAvatar = avatar
    self.ProfileNameLabel = profileNameLabel
    self.ProfileRoleLabel = profileRoleLabel
    self.MinimizedLogo = minimizedLogo
    self.MinimizedTitle = minimizedTitle
    self.SearchBox = searchFrame
    self.SearchInput = search
    self.PageTitle = pageTitle
    self.SegmentHolder = segmentHolder
    self.TopbarLine = divider
    self.MinimizeButton = minimize
    self.CloseButton = close
    self.Actions = actions
    self.SizeConstraint = sizeConstraint
    self.Sidebar = sidebar
    self.SidebarLine = divider
    self.TabHolder = tabHolder
    self.ContentShell = contentShell
    self.Content = pageHolder
    self.OriginalSize = size
    self.MinimizedSize = resolveMinimizedSize(options, size)
    self.SidebarWidth = sidebarWidth
    self.UserResized = false

    self:_makeDraggable(brandCard)
    self:_makeDraggable(dragHeader)
    self:_makeDraggable(minimizedLogo)
    self:_makeResizable()
    self:_watchViewportSize()
    self:_applyResponsiveLayout(size)

    minimize.MouseButton1Click:Connect(function()
        self:SetMinimized(not self._minimized)
    end)

    minimizedLogo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self:SetMinimized(false)
        end
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
    tween(main, {
        BackgroundTransparency = options.Acrylic == true and 0.04 or 0,
        Size = size
    }, SLOW_TWEEN)
end

function Window:_applyResponsiveLayout(size)
    local compact = isCompactWindowSize(size)
    local sidebarWidth = resolveSidebarWidth(self.Options, size)

    if self.BrandCard then
        self.BrandCard.Size = UDim2.new(1, 0, 0, compact and 50 or 58)
    end

    if self.BrandLogo then
        self.BrandLogo.Position = compact and UDim2.fromOffset(9, 7) or UDim2.fromOffset(10, 10)
        self.BrandLogo.Size = UDim2.fromOffset(compact and 36 or 36, compact and 36 or 36)
    end

    if self.TitleLabel then
        self.TitleLabel.Visible = not compact and sidebarWidth >= 150
    end

    if self.SubtitleLabel then
        self.SubtitleLabel.Visible = not compact and sidebarWidth >= 150
    end

    if self.NavigationLabel then
        self.NavigationLabel.Visible = not compact
    end

    if self.TabHolder then
        self.TabHolder.Position = UDim2.fromOffset(0, compact and 60 or 88)
        self.TabHolder.Size = UDim2.new(1, 0, 1, compact and -120 or -148)
    end

    if self.Footer then
        self.Footer.Size = UDim2.new(1, 0, 0, compact and 46 or 54)
    end

    if self.ProfileAvatar then
        self.ProfileAvatar.Position = compact and UDim2.fromOffset(10, 6) or UDim2.fromOffset(10, 9)
    end

    if self.ProfileNameLabel then
        self.ProfileNameLabel.Visible = not compact
    end

    if self.ProfileRoleLabel then
        self.ProfileRoleLabel.Visible = not compact
    end

    if self.PageTitle then
        self.PageTitle.TextSize = compact and 15 or 17
        self.PageTitle.Position = UDim2.fromOffset(compact and 10 or 14, 18)
        self.PageTitle.Size = UDim2.new(1, compact and -64 or -82, 0, 24)
    end

    if self.SegmentHolder then
        self.SegmentHolder.Position = UDim2.fromOffset(compact and 10 or 14, 50)
        self.SegmentHolder.Size = UDim2.new(1, compact and -20 or -28, 0, 30)
    end

    if self.Content then
        self.Content.Position = UDim2.fromOffset(compact and 8 or 12, 92)
        self.Content.Size = UDim2.new(1, compact and -16 or -24, 1, -106)
    end

    if self.SearchBox then
        self.SearchBox.Visible = not compact and not self._minimized
    end

    for _, tab in ipairs(self.Tabs) do
        if tab.TitleLabel then
            tab.TitleLabel.Visible = not compact and sidebarWidth >= 150
        end

        if tab.IconObject then
            tab.IconObject.Position = compact and UDim2.fromOffset(21, 6) or UDim2.fromOffset(12, 6)
        end
    end

    if self.MinimizedTitle then
        self.MinimizedTitle.Visible = self._minimized and self.MinimizedSize.X.Offset > 160
    end

    if self.Actions then
        self.Actions.Position = UDim2.new(1, -12, 0, 12)
    end

    return sidebarWidth
end

function Window:_updateResponsiveSize(animated)
    local defaultSize, minSize, maxSize = resolveWindowSize(self.Options)
    local preferredSize = self.UserResized and self.OriginalSize or defaultSize
    local size = UDim2.fromOffset(
        math.clamp(preferredSize.X.Offset, minSize.X, maxSize.X),
        math.clamp(preferredSize.Y.Offset, minSize.Y, maxSize.Y)
    )
    local sidebarWidth = resolveSidebarWidth(self.Options, size)

    self.OriginalSize = size
    self.MinimizedSize = resolveMinimizedSize(self.Options, size)
    self.SidebarWidth = sidebarWidth

    if self.SizeConstraint then
        self.SizeConstraint.MinSize = self._minimized and Vector2.new(44, 48) or minSize
        self.SizeConstraint.MaxSize = maxSize
    end

    if self.Sidebar then
        self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, -16)
    end

    if self.SidebarLine then
        self.SidebarLine.Position = UDim2.fromOffset(sidebarWidth + 16, 12)
    end

    if self.ContentShell then
        self.ContentShell.Position = UDim2.fromOffset(sidebarWidth + 22, 0)
        self.ContentShell.Size = UDim2.new(1, -sidebarWidth - 30, 1, 0)
    end

    if self.Topbar then
        self.Topbar.Position = UDim2.fromOffset(sidebarWidth + 16, 0)
        self.Topbar.Size = UDim2.new(1, -sidebarWidth - 16, 0, 48)
    end

    self:_applyResponsiveLayout(size)

    local targetSize = self._minimized and self.MinimizedSize or self.OriginalSize

    if self.Main then
        if animated then
            tween(self.Main, { Size = targetSize }, DEFAULT_TWEEN)
        else
            self.Main.Size = targetSize
        end
    end
end

function Window:_watchViewportSize()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    table.insert(self._connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        self:_updateResponsiveSize(true)
    end))
end

function Window:_topButton(parent, text, textColor)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Input,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = textColor,
        TextSize = 12,
            Size = UDim2.fromOffset(22, 22),
        Parent = parent
    })

    addCorner(button, 6)
    addStroke(button, self.Theme.Stroke, 0.55)

    local icon = makeIcon(button, text, self.Theme, 13)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = self.Theme.SurfaceHover }, DEFAULT_TWEEN)
    end)

    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = self.Theme.Input }, DEFAULT_TWEEN)
    end)

    button.MouseButton1Down:Connect(function()
        press(button, UDim2.fromOffset(22, 22))
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
        Size = UDim2.fromOffset(16, 16),
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
        local minSize = self.SizeConstraint and self.SizeConstraint.MinSize or Vector2.new(300, 280)
        local maxSize = self.SizeConstraint and self.SizeConstraint.MaxSize or Vector2.new(900, 620)
        local width = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
        local height = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)

        self.OriginalSize = UDim2.fromOffset(width, height)
        self.MinimizedSize = resolveMinimizedSize(self.Options, self.OriginalSize)
        self.UserResized = true
        self.Main.Size = self.OriginalSize
        self:_applyResponsiveLayout(self.OriginalSize)
    end))
end

function Window:SetMinimized(value)
    self._minimized = value
    self.Sidebar.Visible = not value
    self.ContentShell.Visible = not value
    self.TopbarLine.Visible = not value
    self.SearchBox.Visible = not value and not isCompactWindowSize(self.OriginalSize)
    self.MinimizedLogo.Visible = value
    self.MinimizedTitle.Visible = false
    if self.Actions then
        self.Actions.Visible = not value
    end
    if self.ResizeHandle then
        self.ResizeHandle.Visible = not value
    end

    self:_updateResponsiveSize(false)

    if self.MainStroke then
        tween(self.MainStroke, {
            Transparency = value and 1 or 0.08
        }, SLOW_TWEEN)
    end

    tween(self.Main, {
        BackgroundTransparency = value and 1 or (self.Options.Acrylic == true and 0.04 or 0),
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

local function encodeConfigValue(value)
    local valueType = typeof(value)

    if valueType == "Color3" then
        return {
            Type = "Color3",
            R = math.floor(value.R * 255 + 0.5),
            G = math.floor(value.G * 255 + 0.5),
            B = math.floor(value.B * 255 + 0.5)
        }
    elseif valueType == "EnumItem" then
        return {
            Type = "EnumItem",
            EnumType = tostring(value.EnumType),
            Name = value.Name
        }
    end

    return value
end

local function decodeConfigValue(value)
    if typeof(value) == "table" and value.Type == "Color3" then
        return Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255)
    end

    if typeof(value) == "table" and value.Type == "EnumItem" then
        local enumType = tostring(value.EnumType or ""):gsub("^Enum%.", "")
        local enumName = tostring(value.Name or "")
        local ok, enumValue = pcall(function()
            return Enum[enumType][enumName]
        end)

        if ok and enumValue then
            return enumValue
        end
    end

    return value
end

local function sanitizeConfigName(name)
    name = tostring(name or "Singularity")
    name = name:gsub("[^%w%-%_%. ]", "_"):gsub("^%s+", ""):gsub("%s+$", "")

    if name == "" then
        name = "Singularity"
    end

    return name
end

function Window:GetFlag(flag)
    return self.Flags[flag]
end

function Window:SetFlag(flag, value)
    self.Flags[flag] = value
end

function Window:_registerFlagControl(flag, control)
    if flag and control then
        self._flagControls[tostring(flag)] = control
    end
end

function Window:SetScale(scale)
    scale = math.clamp(tonumber(scale) or resolveScale(self.Options), 0.55, 1.25)
    self.Options.Scale = scale

    if self.UIScale then
        tween(self.UIScale, { Scale = scale }, DEFAULT_TWEEN)
    end
end

function Window:SetSize(width, height)
    width = tonumber(width) or self.OriginalSize.X.Offset
    height = tonumber(height) or self.OriginalSize.Y.Offset

    local _, minSize, maxSize = resolveWindowSize(self.Options)
    width = math.clamp(width, minSize.X, maxSize.X)
    height = math.clamp(height, minSize.Y, maxSize.Y)

    self.UserResized = true
    self.OriginalSize = UDim2.fromOffset(width, height)
    self.Options.Size = self.OriginalSize
    self:_updateResponsiveSize(true)
end

function Window:SetTheme(themeName)
    self.ThemeName = tostring(themeName or "singularity-dark")
    self.Theme = resolveTheme(self.ThemeName)
    self.Library.Theme = self.Theme

    if self.Main then
        self.Main.BackgroundColor3 = self.Theme.Window
    end

    self:Notify({
        Title = "Theme",
        Content = "Theme saved. Reopen the UI to fully redraw controls.",
        Duration = 2
    })
end

function Window:ExportConfig()
    local data = {
        Flags = {},
        UI = {
            Theme = self.ThemeName or "singularity-dark",
            Scale = self.UIScale and self.UIScale.Scale or resolveScale(self.Options),
            Width = self.OriginalSize and self.OriginalSize.X.Offset or nil,
            Height = self.OriginalSize and self.OriginalSize.Y.Offset or nil,
            SidebarWidth = self.SidebarWidth
        }
    }

    for key, value in pairs(self.Flags) do
        data.Flags[key] = encodeConfigValue(value)
    end

    return data
end

function Window:ImportConfig(data)
    if typeof(data) ~= "table" then
        return false
    end

    if typeof(data.Flags) == "table" then
        for key, value in pairs(data.Flags) do
            local decoded = decodeConfigValue(value)
            self:SetFlag(key, decoded)

            local control = self._flagControls and self._flagControls[tostring(key)]
            if control and control.Set then
                control.Set(decoded, true)
            end
        end
    end

    if typeof(data.UI) == "table" then
        if data.UI.Scale then
            self:SetScale(data.UI.Scale)
        end

        if data.UI.Width or data.UI.Height then
            self:SetSize(data.UI.Width or self.OriginalSize.X.Offset, data.UI.Height or self.OriginalSize.Y.Offset)
        end
    end

    return true
end

function Window:SaveConfig(name)
    name = sanitizeConfigName(name or self.Options.ConfigName or self.Options.Title or "Singularity")

    if typeof(writefile) ~= "function" then
        return false, nil
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(self:ExportConfig())
    end)

    if not ok then
        return false, nil
    end

    local folderReady = false

    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
            if not isfolder("SingularityUI") then
                makefolder("SingularityUI")
            end

            folderReady = isfolder("SingularityUI")
        end
    end)

    local path = folderReady and ("SingularityUI/" .. name .. ".json") or ("SingularityUI_" .. name .. ".json")
    local wrote = pcall(function()
        writefile(path, encoded)
    end)

    return wrote, path
end

function Window:LoadConfig(name)
    name = sanitizeConfigName(name or self.Options.ConfigName or self.Options.Title or "Singularity")

    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
        return false, nil
    end

    local path = "SingularityUI/" .. name .. ".json"

    if not isfile(path) then
        path = "SingularityUI_" .. name .. ".json"

        if not isfile(path) then
            return false, nil
        end
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok then
        return false, path
    end

    return self:ImportConfig(decoded), path
end

function Window:Tab(options)
    options = normalizeOptions(options)

    local tab = setmetatable({
        Window = self,
        Title = options.Title or options.Name or ("Tab " .. tostring(#self.Tabs + 1)),
        Icon = options.Icon,
        IsSystem = options.System == true,
        LayoutOrder = options.LayoutOrder,
        Segments = options.Segments or options.Subtabs or options.Sections or {},
        ActiveSegment = options.ActiveSegment or options.DefaultSegment,
        SegmentCallback = options.SegmentCallback,
        Controls = {}
    }, Tab)

    tab:_build()
    table.insert(self.Tabs, tab)

    local onlySystemSelected = self.ActiveTab and self.ActiveTab.IsSystem and not tab.IsSystem

    if not self.ActiveTab or onlySystemSelected or options.Default then
        tab:Select()
    else
        tab.Page.Visible = false
    end

    return tab
end

Window.CreateTab = Window.Tab

function Window:_selectTab(targetTab)
    self.ActiveTab = targetTab
    targetTab.Page.CanvasPosition = Vector2.new(0, 0)

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

        setIconColor(tab.IconObject, selected and self.Theme.Text or self.Theme.Subtext)
    end

    self:_applySearch(self.SearchInput and self.SearchInput.Text or "")
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
    local hasActiveSegment = false

    for _, segment in ipairs(segments) do
        if optionTitle(segment) == tab.ActiveSegment then
            hasActiveSegment = true
            break
        end
    end

    if not hasActiveSegment then
        tab.ActiveSegment = optionTitle(segments[1])
    end

    for _, segment in ipairs(segments) do
        local label = optionTitle(segment)
        local selected = label == tab.ActiveSegment
        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = selected and self.Theme.SurfaceHover or self.Theme.Surface,
            BackgroundTransparency = selected and 0 or 0.35,
            BorderSizePixel = 0,
            Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium,
            Text = label,
            TextColor3 = selected and self.Theme.Text or self.Theme.Subtext,
            TextSize = 12,
            Size = UDim2.fromOffset(math.max(76, (#label * 7) + 28), 28),
            Parent = self.SegmentHolder
        })
        addCorner(button, 7)
        addStroke(button, self.Theme.Stroke, selected and 0.55 or 0.8)

        button.MouseButton1Click:Connect(function()
            press(button, button.Size)
            tab.ActiveSegment = label
            self:_renderSegments(tab)
            self:_applySearch(self.SearchInput and self.SearchInput.Text or "")
            safeCall(tab.SegmentCallback, tab.ActiveSegment)
        end)
    end
end

function Window:_filterControls(controls, query, segment)
    local anyVisible = false

    for _, control in ipairs(controls or {}) do
        local matchesSearch = query == "" or string.find(control.SearchText or "", query, 1, true) ~= nil
        local matchesSegment = not segment or control.Segment == nil or control.Segment == segment
        local visible = matchesSearch and matchesSegment

        if control.ChildrenControls then
            local childVisible = self:_filterControls(control.ChildrenControls, matchesSearch and "" or query, segment)
            visible = (matchesSearch and matchesSegment) or childVisible
        end

        if control.Frame then
            control.Frame.Visible = visible
        end

        anyVisible = anyVisible or visible
    end

    return anyVisible
end

function Window:_applySearch(query)
    query = string.lower(tostring(query or ""))

    if not self.ActiveTab then
        return
    end

    self:_filterControls(self.ActiveTab.Controls, query, self.ActiveTab.ActiveSegment)
    self.ActiveTab.Page.CanvasPosition = Vector2.new(0, 0)
end

function Tab:_build()
    local window = self.Window
    local theme = window.Theme
    local compact = window.OriginalSize and isCompactWindowSize(window.OriginalSize) or false

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = self.LayoutOrder or (self.IsSystem and 10000 or #window.Tabs + 1),
        Text = "",
        Size = UDim2.new(1, 0, 0, 32),
        Parent = window.TabHolder
    })
    addCorner(button, 8)

    local icon = makeIcon(button, self.Icon or self.Title:sub(1, 1), theme, 18)

    if icon then
        icon.Position = compact and UDim2.fromOffset(21, 7) or UDim2.fromOffset(12, 7)
    end

    local titleOffset = icon and 36 or 12
    local title = makeText(button, self.Title, 13, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(titleOffset, 0),
        Size = UDim2.new(1, -titleOffset - 10, 1, 0)
    })
    title.Visible = not compact

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
        Padding = UDim.new(0, 6),
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
        press(button, UDim2.new(1, 0, 0, 32))
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

function Tab:_refreshSearch()
    if self.Window and self.Window.ActiveTab then
        if self.ParentTab then
            self.ParentTab:_refreshSearch()
        else
            self.Window:_applySearch(self.Window.SearchInput and self.Window.SearchInput.Text or "")
        end
    end
end

function Tab:_base(options, height)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local hasBodyText = hasSupportText(options)
    local insetX = self.IsGroup and 16 or 12
    local frame = create("Frame", {
        BackgroundColor3 = self.IsGroup and theme.Window or theme.Surface,
        BackgroundTransparency = self.IsGroup and 1 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, height or 54),
        Parent = self.Page
    })

    if not self.IsGroup then
        addCorner(frame, 7)
        addStroke(frame, theme.Stroke, 0.38)
    end

    local title = makeText(frame, options.Title or options.Name or "Control", 12, theme.Text, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(insetX, hasBodyText and 6 or 0),
        Size = UDim2.new(1, -(insetX * 2), 0, hasBodyText and 18 or height or 54)
    })

    local desc = nil

    if hasBodyText then
        desc = makeText(frame, options.Desc or options.Description or options.Content, 11, theme.Subtext, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(insetX, 27),
            Size = UDim2.new(1, -(insetX * 2), 0, 18)
        })
    end

    local control = setmetatable({
        Tab = self,
        Window = self.Window,
        Frame = frame,
        Title = title,
        Desc = desc,
        Options = options,
        SearchText = searchableText(options),
        Segment = options.Segment or self.Segment or self.ActiveSegment
    }, Control)

    table.insert(self.Controls, control)
    self:_refreshSearch()
    return control
end

function Tab:Group(options)
    options = normalizeOptions(options)

    local theme = self.Window.Theme
    local height = options.Height or 260
    local segment = options.Segment or self.Segment or self.ActiveSegment
    local hasIcon = options.Icon ~= false and options.Icon ~= nil
    local frame = create("Frame", {
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, height),
        Parent = self.Page
    })
    addCorner(frame, 7)
    addStroke(frame, theme.Stroke, 0.34, 1)

    if hasIcon then
        local icon = makeIcon(frame, options.Icon, theme, 16)

        if icon then
            icon.Position = UDim2.fromOffset(14, 9)
        end
    end

    makeText(frame, options.Title or options.Name or "Group", 12, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(hasIcon and 40 or 16, 8),
        Size = UDim2.new(1, hasIcon and -52 or -28, 0, 24)
    })

    local content = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(0, 34),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, 0, 1, -40),
        Parent = frame
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content
    })

    local group = setmetatable({
        Window = self.Window,
        ParentTab = self,
        Page = content,
        Controls = {},
        IsGroup = true,
        Frame = frame,
        SearchText = searchableText(options, "Group"),
        Segment = segment
    }, {
        __index = Tab
    })

    table.insert(self.Controls, {
        Frame = frame,
        SearchText = group.SearchText,
        Segment = segment,
        ChildrenControls = group.Controls
    })

    self:_refreshSearch()
    return group
end

function Tab:Section(title)
    local theme = self.Window.Theme

    local label = makeText(self.Page, tostring(title or "Section"), 12, theme.Muted, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 20)
    })
    label.Text = string.upper(label.Text)

    table.insert(self.Controls, {
        Frame = label,
        SearchText = string.lower(tostring(title or "Section")),
        Segment = self.Segment or self.ActiveSegment
    })

    self:_refreshSearch()

    return label
end

function Tab:Paragraph(options)
    options = normalizeOptions(options)

    local text = options.Desc or options.Content or options.Description or ""
    local height = text ~= "" and 72 or 44
    local control = self:_base(options, height)

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -24, 0, 34)
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
            Size = UDim2.new(1, 0, 0, 28),
            Parent = self.Page
        })

        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            Position = UDim2.fromOffset(16, 0),
            Size = UDim2.new(1, -32, 1, 0),
            Text = options.Title or options.Name or "Button",
            TextColor3 = theme.Text,
            TextSize = 12,
            Parent = row
        })
        addCorner(button, 7)
        addStroke(button, theme.Stroke, 0.12)

        button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
        end)

        button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = theme.Input }, DEFAULT_TWEEN)
        end)

        button.MouseButton1Click:Connect(function()
            press(button, UDim2.new(1, -32, 1, 0))
            safeCall(options.Callback)
        end)

        local control = setmetatable({
            Tab = self,
            Window = self.Window,
            Frame = row,
            Button = button,
            Options = options,
            SearchText = searchableText(options),
            Segment = options.Segment or self.Segment or self.ActiveSegment
        }, Control)

        table.insert(self.Controls, control)
        self:_refreshSearch()
        return control
    end

    local control = self:_base(options, hasSupportText(options) and 54 or 38)
    local frame = control.Frame
    local theme = self.Window.Theme

    if control.Title then
        control.Title.Size = UDim2.new(1, -54, 0, control.Desc and 18 or frame.Size.Y.Offset)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -54, 0, 18)
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

    local arrow = makeText(frame, ">", 14, theme.Accent, Enum.Font.GothamBold, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        TextXAlignment = Enum.TextXAlignment.Center
    })

    control.Arrow = arrow
    return control
end

function Tab:Toggle(options)
    options = normalizeOptions(options)

    local control = self:_base(options, self.IsGroup and 28 or (hasSupportText(options) and 52 or 38))
    local frame = control.Frame
    local theme = self.Window.Theme
    local value = firstDefined(options.Default, options.Value, false)

    if control.Title then
        control.Title.Size = UDim2.new(1, -82, 0, control.Desc and 18 or frame.Size.Y.Offset)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -92, 0, 18)
    end

    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = value and theme.AccentDark or theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.new(1, self.IsGroup and -16 or -12, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        Parent = frame
    })
    addCorner(track, 10)
    addStroke(track, value and theme.Accent or theme.Stroke, value and 0.05 or 0.32)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = value and theme.Accent or theme.Surface,
        BorderSizePixel = 0,
        Position = value and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Parent = track
    })
    addCorner(knob, 8)
    addStroke(knob, theme.Stroke, 0.2)

    local object = setmetatable({
        Value = value,
        Set = nil
    }, {
        __index = control
    })

    local function apply(nextValue, silent)
        value = nextValue == true
        object.Value = value

        tween(track, { BackgroundColor3 = value and theme.AccentDark or theme.Input }, DEFAULT_TWEEN)
        tween(knob, {
            BackgroundColor3 = value and theme.Accent or theme.Surface,
            Position = value and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
        }, DEFAULT_TWEEN)

        local stroke = track:FindFirstChildOfClass("UIStroke")
        if stroke then
            tween(stroke, { Color = value and theme.Accent or theme.Stroke, Transparency = value and 0.05 or 0.32 }, DEFAULT_TWEEN)
        end

        if options.Flag then
            self.Window:SetFlag(options.Flag, value)
        end

        if not silent then
            safeCall(options.Callback, value)
        end
    end

    object.Set = function(first, second, third)
        if first == object then
            apply(second, third)
        else
            apply(first, second)
        end
    end

    self.Window:_registerFlagControl(options.Flag, object)

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            press(track, UDim2.fromOffset(38, 20))
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
    local control = self:_base(options, self.IsGroup and 46 or (hasSupportText(options) and 62 or 50))
    local frame = control.Frame

    local valueLabel = makeText(frame, tostring(value) .. suffix, 12, theme.Muted, Enum.Font.GothamMedium, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, self.IsGroup and -16 or -12, 0, self.IsGroup and 0 or (control.Desc and 8 or 10)),
        Size = UDim2.fromOffset(72, 18),
        TextXAlignment = Enum.TextXAlignment.Right
    })

    if control.Title then
        control.Title.Size = UDim2.new(1, -84, 0, self.IsGroup and 22 or 18)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -96, 0, 18)
    end

    local track = create("Frame", {
        AnchorPoint = self.IsGroup and Vector2.new(0, 0) or Vector2.new(0, 1),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Position = self.IsGroup and UDim2.fromOffset(16, 28) or UDim2.new(0, 12, 1, -14),
        Size = UDim2.new(1, self.IsGroup and -32 or -24, 0, 4),
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
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(10, 10),
        Parent = track
    })
    addCorner(handle, 5)
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

    object.Set = function(first, second, third)
        if first == object then
            apply(second, third)
        else
            apply(first, second)
        end
    end

    self.Window:_registerFlagControl(options.Flag, object)

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
            Size = UDim2.new(1, 0, 0, 30),
            Parent = self.Page
        })

        local box = create("TextBox", {
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.GothamMedium,
            PlaceholderText = options.Placeholder or options.Title or "",
            PlaceholderColor3 = theme.Muted,
            Position = UDim2.fromOffset(16, 0),
            Size = UDim2.new(1, -32, 1, 0),
            Text = tostring(value),
            TextColor3 = theme.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row
        })
        addCorner(box, 7)
        addStroke(box, theme.Stroke, 0.12)
        addPadding(box, 10, 0, 10, 0)

        local control = setmetatable({
            Tab = self,
            Window = self.Window,
            Frame = row,
            Box = box,
            Value = value,
            Options = options,
            SearchText = searchableText(options),
            Segment = options.Segment or self.Segment or self.ActiveSegment
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

        control.Set = function(first, second, third)
            if first == control then
                apply(second, third)
            else
                apply(first, second)
            end
        end

        self.Window:_registerFlagControl(options.Flag, control)

        box.FocusLost:Connect(function()
            apply(box.Text)
        end)

        apply(value, true)
        self:_refreshSearch()
        return control
    end

    local theme = self.Window.Theme
    local control = self:_base(options, hasSupportText(options) and 66 or 52)
    local frame = control.Frame
    local value = firstDefined(options.Default, options.Value, "")

    if control.Title then
        control.Title.Size = UDim2.new(1, -212, 0, 18)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -212, 0, 18)
    end

    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = theme.Muted,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(options.Width or 188, 28),
        Text = tostring(value),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    addCorner(box, 7)
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

    object.Set = function(first, second, third)
        if first == object then
            apply(second, third)
        else
            apply(first, second)
        end
    end

    self.Window:_registerFlagControl(options.Flag, object)

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
    local collapsedHeight = self.IsGroup and 28 or (hasSupportText(options) and 58 or 44)
    local maxVisible = options.MaxVisible or 5
    local optionHeight = 28
    local expandedHeight = collapsedHeight + (math.min(#values, maxVisible) * (optionHeight + 3)) + 12
    local control = self:_base(options, collapsedHeight)
    local frame = control.Frame
    local selected = multi and {} or firstDefined(options.Default, options.Value)
    local expanded = false
    frame.ClipsDescendants = false

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
        control.Title.Size = UDim2.new(1, self.IsGroup and -124 or -170, 0, self.IsGroup and 28 or 18)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -190, 0, 18)
    end

    local selectButton = create("TextButton", {
        AnchorPoint = self.IsGroup and Vector2.new(1, 0.5) or Vector2.new(1, 0),
        AutoButtonColor = false,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Position = self.IsGroup and UDim2.new(1, -16, 0.5, 0) or UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(options.Width or (self.IsGroup and 104 or 152), self.IsGroup and 24 or 26),
        Text = "",
        ZIndex = 8,
        Parent = frame
    })
    addCorner(selectButton, 7)
    addStroke(selectButton, theme.Stroke, 0.55)

    local selectText = makeText(selectButton, options.Placeholder or "Select", 11, theme.Subtext, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -30, 1, 0),
        ZIndex = 9
    })

    local chevron = makeText(selectButton, "+", 12, theme.Subtext, Enum.Font.GothamBold, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 9
    })

    local list = create("ScrollingFrame", {
        Active = true,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(self.IsGroup and 16 or 12, collapsedHeight - 2),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, self.IsGroup and -32 or -24, 0, math.min(#values, maxVisible) * (optionHeight + 3)),
        Visible = false,
        ZIndex = 20,
        Parent = frame
    })
    addCorner(list, 8)
    addStroke(list, theme.Stroke, 0.55)
    addPadding(list, 5, 5, 5, 5)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 3),
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
        chevron.Text = expanded and "-" or "+"

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

        expandedHeight = collapsedHeight + (math.min(#values, maxVisible) * (optionHeight + 3)) + 12
        list.Size = UDim2.new(1, self.IsGroup and -32 or -24, 0, math.min(#values, maxVisible) * (optionHeight + 3))

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
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, optionHeight),
                ZIndex = 21,
                Parent = list
            })
            addCorner(item, 6)

            item.MouseEnter:Connect(function()
                tween(item, { BackgroundColor3 = theme.SurfaceHover }, DEFAULT_TWEEN)
            end)

            item.MouseLeave:Connect(function()
                tween(item, { BackgroundColor3 = theme.Surface }, DEFAULT_TWEEN)
            end)

            item.Activated:Connect(function()
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

    object.Set = function(first, second, third)
        if first == object then
            apply(second, third)
        else
            apply(first, second)
        end
    end
    object.Refresh = function(first, second)
        values = (first == object and second or first) or values
        rebuild()
    end

    self.Window:_registerFlagControl(options.Flag, object)

    selectButton.Activated:Connect(function()
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
    local control = self:_base(options, self.IsGroup and 28 or (hasSupportText(options) and 52 or 38))
    local frame = control.Frame
    local key = firstDefined(options.Default, options.Key, Enum.KeyCode.RightControl)
    local listening = false

    if control.Title then
        control.Title.Size = UDim2.new(1, self.IsGroup and -58 or -112, 0, self.IsGroup and 28 or 18)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -126, 0, 18)
    end

    local keyButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Position = UDim2.new(1, self.IsGroup and -16 or -12, 0.5, 0),
        Size = UDim2.fromOffset(self.IsGroup and 32 or 92, 24),
        Text = formatKeyCode(key),
        TextColor3 = theme.Text,
        TextSize = 12,
        Parent = frame
    })
    addCorner(keyButton, 7)
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

    object.Set = function(first, second, third)
        if first == object then
            apply(second, third)
        else
            apply(first, second)
        end
    end

    self.Window:_registerFlagControl(options.Flag, object)

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
    local control = self:_base(options, hasSupportText(options) and 112 or 96)
    local frame = control.Frame
    local value = startColor

    if control.Title then
        control.Title.Size = UDim2.new(1, -66, 0, 18)
    end

    if control.Desc then
        control.Desc.Size = UDim2.new(1, -66, 0, 18)
    end

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(36, 24),
        Parent = frame
    })
    addCorner(swatch, 7)
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

    object.Set = function(first, second, third)
        if first == object then
            applyColor(second, third)
        else
            applyColor(first, second)
        end
    end

    self.Window:_registerFlagControl(options.Flag, object)

    for index, channel in ipairs(channels) do
        local rowY = (control.Desc and 52 or 40) + ((index - 1) * 20)

        makeText(frame, channel.Name, 11, theme.Subtext, Enum.Font.GothamBold, {
            Position = UDim2.fromOffset(12, rowY - 4),
            Size = UDim2.fromOffset(16, 16),
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local track = create("Frame", {
            BackgroundColor3 = theme.Input,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(34, rowY),
            Size = UDim2.new(1, -58, 0, 6),
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

function Window:_buildBuiltInSettings()
    local hasUserTabs = false

    for _, tab in ipairs(self.Tabs) do
        if not tab.IsSystem then
            hasUserTabs = true
            break
        end
    end

    local settings = self:Tab({
        Title = "Settings",
        Icon = "settings",
        System = true,
        LayoutOrder = 10000
    })
    self._builtInSettingsTab = settings

    settings:Paragraph({
        Title = "Instructions",
        Content = self.Options.Instructions or "Static UI settings and JSON config saving are built in for every script."
    })

    settings:Input({
        Title = "Config Name",
        Placeholder = "Default",
        Default = self.Options.ConfigName or self.Options.Title or "Singularity",
        Flag = "__ui_config_name"
    })

    settings:Slider({
        Title = "Scale",
        Min = 55,
        Max = 125,
        Default = math.floor((self.UIScale and self.UIScale.Scale or resolveScale(self.Options)) * 100 + 0.5),
        Suffix = "%",
        Flag = "__ui_scale",
        Callback = function(value)
            self:SetScale(value / 100)
        end
    })

    settings:Slider({
        Title = "Width",
        Min = 540,
        Max = 900,
        Default = self.OriginalSize.X.Offset,
        Flag = "__ui_width",
        Callback = function(value)
            self:SetSize(value, self.OriginalSize.Y.Offset)
        end
    })

    settings:Slider({
        Title = "Height",
        Min = 320,
        Max = 600,
        Default = self.OriginalSize.Y.Offset,
        Flag = "__ui_height",
        Callback = function(value)
            self:SetSize(self.OriginalSize.X.Offset, value)
        end
    })

    settings:Button({
        Title = "Save Config JSON",
        Callback = function()
            local saved, path = self:SaveConfig(self:GetFlag("__ui_config_name"))
            self:Notify({
                Title = saved and "Config saved" or "Config unavailable",
                Content = saved and ("Saved JSON to " .. tostring(path)) or "This executor does not expose writefile.",
                Duration = 2
            })
        end
    })

    settings:Button({
        Title = "Load Config JSON",
        Callback = function()
            local loaded, path = self:LoadConfig(self:GetFlag("__ui_config_name"))
            self:Notify({
                Title = loaded and "Config loaded" or "Config unavailable",
                Content = loaded and ("Loaded JSON from " .. tostring(path)) or "No readable config was found.",
                Duration = 2
            })
        end
    })

    if hasUserTabs and settings.Page then
        settings.Page.Visible = false
    end

    if hasUserTabs and self.ActiveTab == settings then
        self.ActiveTab = nil
    end

    return settings
end

function Window:_ensureBuiltInSettings()
    if self._builtInSettingsTab then
        return self._builtInSettingsTab
    end

    return self:_buildBuiltInSettings()
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

Singularity.Theme = resolveTheme("singularity-dark")

return Singularity
