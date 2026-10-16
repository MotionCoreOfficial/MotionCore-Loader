-- Motion Core | Avatar Shake V3
-- Compact UI overlay for the protected Avatar Shake engine.

local CORE_URL = "https://raw.githubusercontent.com/MotionCoreOfficial/MotionCore-Loader/main/scripts/AvatarShakeCore.lua"

local fetched, source = pcall(function()
    return game:HttpGet(CORE_URL)
end)
if not fetched or type(source) ~= "string" or #source < 100 then
    warn("[Motion Core] Avatar Shake gagal dimuat: koneksi ke GitHub bermasalah.")
    return
end

local core, compileError = loadstring(source)
if not core then
    warn("[Motion Core] Avatar Shake gagal dibuka: " .. tostring(compileError))
    return
end

local started, runtimeError = pcall(core)
if not started then
    warn("[Motion Core] Avatar Shake gagal dijalankan: " .. tostring(runtimeError))
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then return end

local parents = {player:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
if type(gethui) == "function" then
    local ok, target = pcall(gethui)
    if ok and typeof(target) == "Instance" then
        table.insert(parents, 1, target)
    end
end

local gui
for _ = 1, 30 do
    for _, parent in ipairs(parents) do
        if parent then
            local candidate = parent:FindFirstChild("MotionCore_AvatarShake", true)
            if candidate and candidate:IsA("ScreenGui") then
                gui = candidate
                break
            end
        end
    end
    if gui then break end
    task.wait(0.1)
end
if not gui then
    warn("[Motion Core] Panel Avatar Shake tidak ditemukan.")
    return
end

local panel = gui:FindFirstChild("Window")
local header = panel and panel:FindFirstChild("DragHeader")
if not panel or not header then return end

local function findLabel(value, scope)
    for _, child in ipairs((scope or panel):GetDescendants()) do
        if child:IsA("TextLabel") and child.Text == value then
            return child
        end
    end
    return nil
end

local function findLabelPrefix(prefix)
    for _, child in ipairs(panel:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text:sub(1, #prefix) == prefix then
            return child
        end
    end
    return nil
end

local function bounds(node, x, y, w, h, size)
    if not node then return end
    node.Position = UDim2.fromOffset(x, y)
    node.Size = UDim2.fromOffset(w, h)
    if size and (node:IsA("TextLabel") or node:IsA("TextButton")) then
        node.TextSize = size
    end
    if node:IsA("TextButton") then
        local rounding = node:FindFirstChildOfClass("UICorner")
        if rounding then rounding.CornerRadius = UDim.new(0, 6) end
    end
end

panel.Size = UDim2.fromOffset(230, 205)
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -12, 0.5, 0)
local rounding = panel:FindFirstChildOfClass("UICorner")
if rounding then rounding.CornerRadius = UDim.new(0, 10) end

local bg = panel:FindFirstChild("MotionCoreBackground")
if bg then bg.ImageTransparency = 0.62 end
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("Frame") and child ~= header and child.Size == UDim2.fromScale(1, 1) then
        child.BackgroundTransparency = 0.24
    end
    if child:IsA("Frame") and child.Size.Y.Offset == 1 then
        bounds(child, 9, 41, 212, 1)
    end
end

header.Size = UDim2.fromOffset(230, 40)
for _, child in ipairs(header:GetChildren()) do
    if child:IsA("ImageLabel") then
        bounds(child, 9, 6, 28, 28)
    end
end
bounds(findLabel("MOTION CORE", header), 43, 7, 126, 16, 12)
local subtitle = findLabel("AVATAR SHAKE  /  V2", header)
if subtitle then subtitle.Text = "AVATAR SHAKE" end
bounds(subtitle, 43, 23, 127, 12, 9)
bounds(header:FindFirstChild("–"), 176, 8, 22, 24, 15)
bounds(header:FindFirstChild("×"), 203, 8, 20, 24, 17)

bounds(panel:FindFirstChild("START SHAKE"), 9, 47, 212, 35, 12)
bounds(findLabelPrefix("STATUS"), 10, 83, 210, 14, 9)
local modeLabel = findLabel("SHAKE MODE")
if modeLabel then modeLabel.Text = "MODE" end
bounds(modeLabel, 10, 103, 42, 23, 9)

bounds(panel:FindFirstChild("NORMAL"), 53, 101, 52, 26, 8)
bounds(panel:FindFirstChild("STRONG"), 109, 101, 54, 26, 8)
bounds(panel:FindFirstChild("EXTREME"), 167, 101, 54, 26, 8)
bounds(findLabel("SPEED"), 10, 137, 100, 24, 10)
bounds(findLabel("INTENSITY"), 10, 172, 100, 24, 10)

local minuses, pluses = {}, {}
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("TextButton") then
        if child.Name == "−" then table.insert(minuses, child) end
        if child.Name == "+" then table.insert(pluses, child) end
    end
end
table.sort(minuses, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
table.sort(pluses, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
bounds(minuses[1], 137, 135, 25, 28, 16)
bounds(pluses[1], 196, 135, 25, 28, 15)
bounds(minuses[2], 137, 170, 25, 28, 16)
bounds(pluses[2], 196, 170, 25, 28, 15)

for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("TextLabel") then
        if child.Text:match("^%d+ Hz$") then
            bounds(child, 164, 138, 30, 22, 10)
        elseif child.Text:match("^%d+%.%d+$") then
            bounds(child, 164, 173, 30, 22, 10)
        elseif child.Text:find("Visual orang lain", 1, true) then
            child:Destroy()
        end
    end
end

local floating = gui:FindFirstChild("MotionCoreFloatingLogo")
if floating then
    floating.Size = UDim2.fromOffset(40, 40)
    floating.Position = UDim2.new(1, -54, 0.32, 0)
    local floatCorner = floating:FindFirstChildOfClass("UICorner")
    if floatCorner then floatCorner.CornerRadius = UDim.new(0, 11) end
end

local scale = panel:FindFirstChildOfClass("UIScale")
if scale then
    local inUpdate = false
    local function fitMobile()
        if inUpdate or not scale.Parent then return end
        local camera = workspace.CurrentCamera
        local size = camera and camera.ViewportSize or Vector2.new(800, 600)
        local target = math.clamp(math.min((size.X - 20) / 230, (size.Y - 22) / 205), 0.7, 1)
        target = target * (UserInputService.TouchEnabled and 0.94 or 1)
        if math.abs(scale.Scale - target) > 0.001 then
            inUpdate = true
            scale.Scale = target
            inUpdate = false
        end
    end
    scale:GetPropertyChangedSignal("Scale"):Connect(fitMobile)
    fitMobile()
end
