local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Library = {}
local Theme = {
    Base = Color3.fromRGB(10, 13, 26),
    Panel = Color3.fromRGB(17, 21, 39),
    Surface = Color3.fromRGB(25, 29, 49),
    Hover = Color3.fromRGB(34, 37, 61),
    Accent = Color3.fromRGB(147, 51, 234),
    Secondary = Color3.fromRGB(95, 86, 230),
    Text = Color3.fromRGB(241, 241, 252),
    Muted = Color3.fromRGB(159, 165, 191),
    Outline = Color3.fromRGB(48, 53, 77),
    Success = Color3.fromRGB(65, 205, 158),
}
local LOGO = "rbxassetid://111668536257891"
local BACKGROUND = "rbxassetid://99587349687677"

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, object)
end

local function outline(object, color)
    return create("UIStroke", {
        Color = color or Theme.Outline,
        Thickness = 1,
        Transparency = 0.25,
    }, object)
end

local function pad(parent, left, top, right, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function text(parent, value, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or Theme.Text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
    }, parent)
end

local function button(parent, caption, color)
    local instance = create("TextButton", {
        BackgroundColor3 = color or Theme.Surface,
        BorderSizePixel = 0,
        Text = tostring(caption or ""),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = true,
    }, parent)
    round(instance, 7)
    return instance
end

local function safeInvoke(callback, value)
    if type(callback) == "function" then
        local ok, err = pcall(callback, value)
        if not ok then warn("[Motion Core UI] Callback error: " .. tostring(err)) end
    end
end

local function scrolling(parent, extra)
    local scroller = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Secondary,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
    }, parent)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, extra or 7),
    }, scroller)
    return scroller
end

local function asSelection(values)
    local result = {}
    if type(values) == "table" then
        if #values > 0 then
            for _, item in ipairs(values) do result[tostring(item)] = true end
        else
            for item, enabled in pairs(values) do if enabled then result[tostring(item)] = true end end
        end
    elseif values ~= nil then
        result[tostring(values)] = true
    end
    return result
end

local function selectionCaption(values)
    local labels = {}
    for key, enabled in pairs(values) do
        if enabled then table.insert(labels, key) end
    end
    table.sort(labels)
    if #labels == 0 then return "Choose items..." end
    if #labels > 2 then return tostring(#labels) .. " selected" end
    return table.concat(labels, ", ")
end

local function valuesArray(values)
    local result = {}
    if type(values) == "table" then
        for _, entry in ipairs(values) do table.insert(result, tostring(entry)) end
    end
    return result
end

local function setupDrag(target, handle)
    local active, offset, dragInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            offset = input.Position - target.AbsolutePosition
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if active and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local pointer = input.Position
            target.Position = UDim2.new(0, pointer.X - offset.X, 0, pointer.Y - offset.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = false
        end
    end)
end

function Library:CreateWindow(config)
    config = config or {}
    local guiParent = CoreGui
    pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)
    if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end

    local old = guiParent:FindFirstChild("MotionCoreForestMarketUI")
    if old then old:Destroy() end
    local gui = create("ScreenGui", {
        Name = "MotionCoreForestMarketUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 300,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent)
    local desktop = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(598, 414),
        BackgroundColor3 = Theme.Base,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    round(desktop, 12)
    outline(desktop)

    local scale = create("UIScale", {Scale = 1}, desktop)
    local function updateScale()
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        scale.Scale = math.min(1, math.max(0.58, math.min((viewport.X - 14) / 598, (viewport.Y - 20) / 414)))
    end
    updateScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    local wallpaper = create("ImageLabel", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        Image = BACKGROUND,
        ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 0.67,
        BackgroundTransparency = 1,
    }, desktop)
    create("Frame", {
        BackgroundColor3 = Theme.Base,
        BackgroundTransparency = 0.28,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
    }, wallpaper)

    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.07,
        Size = UDim2.new(1, 0, 0, 57),
        BorderSizePixel = 0,
    }, desktop)
    local logo = create("ImageLabel", {
        Position = UDim2.fromOffset(13, 9),
        Size = UDim2.fromOffset(38, 38),
        BackgroundTransparency = 1,
        Image = LOGO,
        ScaleType = Enum.ScaleType.Fit,
    }, header)
    local brand = text(header, "MOTION CORE", 17, Theme.Text, true)
    brand.Position = UDim2.fromOffset(59, 9)
    brand.Size = UDim2.fromOffset(330, 22)
    local subbrand = text(header, "FOREST MARKET   •   CONTROL PANEL", 10, Theme.Muted, false)
    subbrand.Position = UDim2.fromOffset(60, 33)
    subbrand.Size = UDim2.fromOffset(360, 14)
    local minimize = button(header, "—", Theme.Surface)
    minimize.Position = UDim2.new(1, -46, 0, 15)
    minimize.Size = UDim2.fromOffset(30, 28)
    setupDrag(desktop, header)

    local floating = create("ImageButton", {
        Name = "FloatingLogo",
        Position = UDim2.fromOffset(24, 210),
        Size = UDim2.fromOffset(51, 51),
        BackgroundColor3 = Theme.Panel,
        Image = LOGO,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
    }, gui)
    round(floating, 13)
    outline(floating, Theme.Accent)
    setupDrag(floating, floating)
    minimize.MouseButton1Click:Connect(function()
        desktop.Visible = false
        floating.Visible = true
    end)
    floating.MouseButton1Click:Connect(function()
        desktop.Visible = true
        floating.Visible = false
    end)

    local sidebar = create("Frame", {
        Position = UDim2.fromOffset(0, 57),
        Size = UDim2.new(0, 139, 1, -57),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.07,
        BorderSizePixel = 0,
    }, desktop)
    local sideList = scrolling(sidebar, 5)
    pad(sideList, 8, 8, 8, 8)

    local body = create("Frame", {
        Position = UDim2.fromOffset(139, 57),
        Size = UDim2.new(1, -139, 1, -57),
        BackgroundTransparency = 1,
    }, desktop)
    local activePage, activeSideButton = nil, nil

    local window = {
        Gui = gui,
        Flags = {},
        _config = config,
        _tabs = {},
        _saved = {},
        _storage = nil,
    }
    local folder = config.ConfigFolder or "MotionCore/ForestMarket"
    local configOptions = config.Config or {}
    local file = folder .. "/" .. (configOptions.AutoSaveFile or "Default") .. ".json"
    window._storage = file

    if configOptions.AutoLoad and type(readfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(file) then
                local data = HttpService:JSONDecode(readfile(file))
                if type(data) == "table" then window._saved = data end
            end
        end)
    end

    function window:_save()
        if not configOptions.AutoSave or type(writefile) ~= "function" then return end
        pcall(function()
            if type(makefolder) == "function" then
                local partial = ""
                for segment in string.gmatch(folder, "[^/]+") do
                    partial = partial == "" and segment or (partial .. "/" .. segment)
                    if type(isfolder) == "function" and not isfolder(partial) then makefolder(partial) end
                end
            end
            writefile(file, HttpService:JSONEncode(self.Flags))
        end)
    end

    local notifications = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.fromOffset(280, 300),
        BackgroundTransparency = 1,
    }, gui)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 6),
    }, notifications)

    function window:Notify(data)
        data = data or {}
        local toast = create("Frame", {
            Size = UDim2.new(1, 0, 0, 61),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
        }, notifications)
        round(toast, 9)
        outline(toast, Theme.Accent)
        local heading = text(toast, data.Title or "Motion Core", 12, Theme.Text, true)
        heading.Position = UDim2.fromOffset(12, 8)
        heading.Size = UDim2.new(1, -24, 0, 17)
        local detail = text(toast, data.Content or "", 11, Theme.Muted)
        detail.Position = UDim2.fromOffset(12, 27)
        detail.Size = UDim2.new(1, -24, 0, 25)
        detail.TextWrapped = true
        detail.TextTruncate = Enum.TextTruncate.None
        task.delay(tonumber(data.Duration) or 3, function()
            if toast.Parent then toast:Destroy() end
        end)
    end

    local function controlValue(settings, initial)
        if settings.Flag and window._saved[settings.Flag] ~= nil then return window._saved[settings.Flag] end
        return initial
    end
    local function changed(settings, value)
        if settings.Flag then window.Flags[settings.Flag] = value end
        safeInvoke(settings.Callback, value)
        window:_save()
    end
    local function containerAddMethods(holder)
        local methods = {}

        function methods:AddToggle(opts)
            opts = opts or {}
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, 39),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
            }, holder)
            round(row)
            local title = text(row, opts.Name, 12, Theme.Text)
            title.Position = UDim2.fromOffset(10, 0)
            title.Size = UDim2.new(1, -80, 1, 0)
            local switch = button(row, "", Theme.Hover)
            switch.Position = UDim2.new(1, -51, 0, 9)
            switch.Size = UDim2.fromOffset(40, 21)
            round(switch, 11)
            local knob = create("Frame", {
                Size = UDim2.fromOffset(15, 15),
                Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
            }, switch)
            round(knob, 9)
            local state = controlValue(opts, opts.Default == true) == true
            local function apply(value, notify)
                state = value == true
                switch.BackgroundColor3 = state and Theme.Accent or Theme.Hover
                knob.Position = state and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3)
                if notify then changed(opts, state) end
            end
            apply(state, window._saved[opts.Flag or ""] ~= nil)
            switch.MouseButton1Click:Connect(function() apply(not state, true) end)
            local api = {}
            function api:SetValue(value) apply(value, true) end
            function api:GetValue() return state end
            return api
        end

        function methods:AddSlider(opts)
            opts = opts or {}
            local minimum = tonumber(opts.Min) or 0
            local maximum = tonumber(opts.Max) or 100
            local decimals = math.max(0, math.min(4, tonumber(opts.Rounding) or 0))
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, 55),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
            }, holder)
            round(row)
            local label = text(row, opts.Name, 12)
            label.Position = UDim2.fromOffset(10, 5)
            label.Size = UDim2.new(1, -78, 0, 19)
            local readout = text(row, "", 11, Theme.Muted, true)
            readout.Position = UDim2.new(1, -75, 0, 5)
            readout.Size = UDim2.fromOffset(65, 19)
            readout.TextXAlignment = Enum.TextXAlignment.Right
            local track = create("Frame", {
                Position = UDim2.new(0, 11, 1, -18),
                Size = UDim2.new(1, -22, 0, 7),
                BackgroundColor3 = Theme.Hover,
                BorderSizePixel = 0,
            }, row)
            round(track, 5)
            local fill = create("Frame", {
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
            }, track)
            round(fill, 5)
            local value = tonumber(controlValue(opts, opts.Default or minimum)) or minimum
            local factor = 10 ^ decimals
            local function apply(number, notify)
                value = math.floor(math.clamp(number, minimum, maximum) * factor + 0.5) / factor
                local proportion = maximum > minimum and (value - minimum) / (maximum - minimum) or 0
                fill.Size = UDim2.fromScale(proportion, 1)
                readout.Text = tostring(value)
                if notify then changed(opts, value) end
            end
            apply(value, window._saved[opts.Flag or ""] ~= nil)
            local dragging = false
            local function fromPosition(position)
                local fraction = math.clamp((position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                apply(minimum + (maximum - minimum) * fraction, true)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    fromPosition(input.Position)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    fromPosition(input.Position)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            local api = {}
            function api:SetValue(nextValue) apply(tonumber(nextValue) or minimum, true) end
            function api:GetValue() return value end
            return api
        end

        function methods:AddDropdown(opts)
            opts = opts or {}
            local choices = valuesArray(opts.Values)
            local multi = opts.Multi == true
            local state = controlValue(opts, opts.Default or (multi and {} or choices[1]))
            if multi then state = asSelection(state) end
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, 43),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, holder)
            round(row)
            local caption = text(row, opts.Name, 12)
            caption.Position = UDim2.fromOffset(10, 1)
            caption.Size = UDim2.new(1, -20, 0, 17)
            local selector = button(row, "", Theme.Hover)
            selector.Position = UDim2.fromOffset(8, 21)
            selector.Size = UDim2.new(1, -16, 0, 20)
            selector.TextXAlignment = Enum.TextXAlignment.Left
            selector.TextTruncate = Enum.TextTruncate.AtEnd
            selector.TextSize = 11
            local entries = create("ScrollingFrame", {
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(8, 46),
                Size = UDim2.new(1, -16, 0, 0),
                ScrollBarThickness = 3,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
            }, row)
            round(entries, 6)
            create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, entries)
            local expanded = false
            local function captionText()
                selector.Text = "  " .. (multi and selectionCaption(state) or tostring(state or "Choose item...")) .. "  ▾"
            end
            local function setExpanded(show)
                expanded = show and #choices > 0
                local targetHeight = expanded and math.min(164, #choices * 28 + 6) or 0
                entries.Visible = expanded
                entries.Size = UDim2.new(1, -16, 0, targetHeight)
                row.Size = UDim2.new(1, 0, 0, 43 + (expanded and targetHeight + 5 or 0))
            end
            local function draw()
                for _, oldOption in ipairs(entries:GetChildren()) do
                    if oldOption:IsA("TextButton") then oldOption:Destroy() end
                end
                for _, choice in ipairs(choices) do
                    local selected = multi and state[choice] or tostring(state) == choice
                    local option = button(entries, (selected and "  ✓ " or "     ") .. choice, selected and Theme.Accent or Theme.Panel)
                    option.Size = UDim2.new(1, -3, 0, 26)
                    option.TextXAlignment = Enum.TextXAlignment.Left
                    option.TextSize = 11
                    option.MouseButton1Click:Connect(function()
                        if multi then
                            state[choice] = not state[choice] or nil
                            if not state[choice] then state[choice] = nil end
                            changed(opts, state)
                        else
                            state = choice
                            changed(opts, state)
                            setExpanded(false)
                        end
                        captionText()
                        draw()
                    end)
                end
                captionText()
            end
            selector.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
            draw()
            if window._saved[opts.Flag or ""] ~= nil then safeInvoke(opts.Callback, state) end
            local api = {}
            function api:SetValues(newValues)
                choices = valuesArray(newValues)
                if multi then
                    state = {}
                else
                    state = choices[1]
                end
                setExpanded(false)
                draw()
                changed(opts, state)
            end
            function api:SetValue(nextValue)
                state = multi and asSelection(nextValue) or nextValue
                draw()
                changed(opts, state)
            end
            function api:GetValue() return state end
            return api
        end

        function methods:AddTextInput(opts)
            opts = opts or {}
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, 61),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
            }, holder)
            round(row)
            local label = text(row, opts.Name, 12)
            label.Position = UDim2.fromOffset(10, 4)
            label.Size = UDim2.new(1, -20, 0, 20)
            local field = create("TextBox", {
                BackgroundColor3 = Theme.Hover,
                BorderSizePixel = 0,
                Text = tostring(controlValue(opts, opts.Default or "")),
                PlaceholderText = tostring(opts.Placeholder or ""),
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.Muted,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Position = UDim2.fromOffset(8, 27),
                Size = UDim2.new(1, -16, 0, 26),
            }, row)
            round(field, 6)
            field.FocusLost:Connect(function() changed(opts, field.Text) end)
            if window._saved[opts.Flag or ""] ~= nil then safeInvoke(opts.Callback, field.Text) end
            local api = {}
            function api:SetValue(value) field.Text = tostring(value); changed(opts, field.Text) end
            function api:GetValue() return field.Text end
            return api
        end

        function methods:AddButton(opts)
            opts = opts or {}
            local action = button(holder, opts.Name or "Execute", Theme.Surface)
            action.Size = UDim2.new(1, 0, 0, 35)
            outline(action)
            action.MouseButton1Click:Connect(function()
                task.spawn(function() safeInvoke(opts.Callback) end)
            end)
            return action
        end

        function methods:AddStatusList(opts)
            opts = opts or {}
            local panel = create("Frame", {
                Size = UDim2.new(1, 0, 0, 62),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
            }, holder)
            round(panel)
            local heading = text(panel, opts.Name or "Status", 12, Theme.Text, true)
            heading.Position = UDim2.fromOffset(9, 6)
            heading.Size = UDim2.new(1, -18, 0, 17)
            local lines = create("Frame", {
                Position = UDim2.fromOffset(9, 27),
                Size = UDim2.new(1, -18, 0, 28),
                BackgroundTransparency = 1,
            }, panel)
            local function refresh()
                local rows = opts.Rows or {}
                if type(opts.Update) == "function" then
                    local ok, data = pcall(opts.Update)
                    if ok and type(data) == "table" then rows = data end
                end
                for _, instance in ipairs(lines:GetChildren()) do instance:Destroy() end
                local height = math.max(1, #rows) * 19
                for index, item in ipairs(rows) do
                    local line = text(lines, tostring(item.Text or "") .. (opts.ShowColon and ": " or "  ") .. tostring(item.Value or ""), 11, item.Tone == "Success" and Theme.Success or item.Tone == "Accent" and Theme.Accent or Theme.Muted)
                    line.Position = UDim2.fromOffset(0, (index - 1) * 19)
                    line.Size = UDim2.new(1, 0, 0, 18)
                end
                lines.Size = UDim2.new(1, -18, 0, height)
                panel.Size = UDim2.new(1, 0, 0, height + 35)
            end
            refresh()
            task.spawn(function()
                while gui.Parent and panel.Parent do
                    task.wait(math.max(0.25, tonumber(opts.UpdateRate) or 1))
                    refresh()
                end
            end)
            return panel
        end

        function methods:AddDependencyGroupbox(opts)
            opts = opts or {}
            local group = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Panel,
                BorderSizePixel = 0,
            }, holder)
            round(group, 9)
            outline(group)
            pad(group, 8, 8, 8, 8)
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 7),
            }, group)
            local headerButton = button(group, "   " .. tostring(opts.Name or "Settings") .. "    ▾", Theme.Hover)
            headerButton.Size = UDim2.new(1, 0, 0, 29)
            headerButton.TextXAlignment = Enum.TextXAlignment.Left
            headerButton.TextSize = 12
            local contentArea = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = not opts.Collapsed,
            }, group)
            create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, contentArea)
            local collapsed = opts.Collapsed == true
            headerButton.MouseButton1Click:Connect(function()
                if opts.Collapsible == false then return end
                collapsed = not collapsed
                contentArea.Visible = not collapsed
                headerButton.Text = "   " .. tostring(opts.Name or "Settings") .. (collapsed and "    ▸" or "    ▾")
            end)
            return containerAddMethods(contentArea)
        end
        return methods
    end

    function window:AddTab(opts)
        opts = opts or {}
        local page = create("Frame", {
            Name = tostring(opts.Name or "Tab"),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
        }, body)
        local tabButton = button(sideList, tostring(opts.Name or "Tab"), Theme.Panel)
        tabButton.Size = UDim2.new(1, 0, 0, 31)
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.TextSize = 12
        pad(tabButton, 11, 0, 0, 0)
        local function activate()
            if activePage then activePage.Visible = false end
            if activeSideButton then activeSideButton.BackgroundColor3 = Theme.Panel end
            activePage, activeSideButton = page, tabButton
            page.Visible = true
            tabButton.BackgroundColor3 = Theme.Accent
        end
        tabButton.MouseButton1Click:Connect(activate)
        if not activePage then activate() end

        local tab = {}
        function tab:AddCenterTabbox(name)
            return self:_addTabbox(name)
        end
        function tab:AddLeftTabbox(name)
            return self:_addTabbox(name)
        end
        function tab:_addTabbox(name)
            local holder = create("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, page)
            local heading = text(holder, name or "", 13, Theme.Text, true)
            heading.Position = UDim2.fromOffset(13, 9)
            heading.Size = UDim2.new(1, -26, 0, 20)
            local tabsBar = create("ScrollingFrame", {
                Position = UDim2.fromOffset(10, 34),
                Size = UDim2.new(1, -20, 0, 33),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 0,
                ScrollingDirection = Enum.ScrollingDirection.X,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.X,
            }, holder)
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, tabsBar)
            local pages = create("Frame", {
                Position = UDim2.fromOffset(10, 73),
                Size = UDim2.new(1, -20, 1, -81),
                BackgroundTransparency = 1,
            }, holder)
            local activeContent, activeButton
            local box = {}
            function box:AddTab(sub)
                sub = sub or {}
                local nameText = tostring(sub.Name or "Settings")
                local width = math.clamp(#nameText * 7 + 23, 78, 160)
                local btn = button(tabsBar, nameText, Theme.Surface)
                btn.Size = UDim2.fromOffset(width, 29)
                local subpage = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Visible = false,
                }, pages)
                local scroll = scrolling(subpage, 8)
                pad(scroll, 2, 2, 5, 9)
                local function selectSubtab()
                    if activeContent then activeContent.Visible = false end
                    if activeButton then activeButton.BackgroundColor3 = Theme.Surface end
                    activeContent, activeButton = subpage, btn
                    subpage.Visible = true
                    btn.BackgroundColor3 = Theme.Accent
                end
                btn.MouseButton1Click:Connect(selectSubtab)
                if not activeContent then selectSubtab() end
                return containerAddMethods(scroll)
            end
            return box
        end
        return tab
    end

    function window:Destroy()
        gui:Destroy()
    end

    return window
end

return Library
