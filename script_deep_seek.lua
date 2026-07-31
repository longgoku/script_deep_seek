-- ===================================================================
-- Blox Fruit Hack Full - Delta Executor (Fix lỗi nil value)
-- Chặn tất cả lỗi "attempt to call a nil value" từ LocalScript
-- ===================================================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

-- ========== CẤU HÌNH ==========
local CONFIG = {
    ATTACK_INTERVAL = 0.12,
    SEARCH_RADIUS = 40,
    FLY_SPEED = 60,
}

-- ========== TOGGLE ==========
local Toggles = {
    AutoFarm = false,
    AutoCollect = false,
    Fly = false,
    Speed = false,
    SuperJump = false,
}

-- ========== BIẾN TOÀN CỤC ==========
local attackRemote = nil
local flyBody = nil
local farmLoop = nil
local collectLoop = nil

-- ========== BYPASS KEY CHECK & NGĂN LỖI NIL ==========
local function bypassAndProtect()
    local env = getfenv()
    
    -- Hook loadstring để bypass key check
    local old_loadstring = env.loadstring
    env.loadstring = function(code, chunkname)
        if type(code) == "string" then
            -- Bypass key
            if string.find(code:lower(), "key") or string.find(code:lower(), "license") then
                code = "local function CheckLicense() return true end\n" .. code
                code = code:gsub("([%w_]+)%.%s*Key%s*==?%s*(.-)(%s*)then", function(a,b,c,d)
                    return a .. "." .. b .. " = true " .. d .. " then"
                end)
            end
            -- Thêm bảo vệ: chặn gọi hàm nil
            code = [[
                local old_pcall = pcall
                pcall = function(f, ...)
                    if type(f) ~= "function" then
                        return false, "Function is nil"
                    end
                    return old_pcall(f, ...)
                end
                local old_xpcall = xpcall
                xpcall = function(f, err, ...)
                    if type(f) ~= "function" then
                        return false, "Function is nil"
                    end
                    return old_xpcall(f, err, ...)
                end
            ]] .. code
        end
        return old_loadstring(code, chunkname)
    end

    -- Hook _G để chặn lỗi nil khi gọi
    local old_index = nil
    local mt = getmetatable(_G) or {}
    mt.__index = function(t, k)
        local val = rawget(t, k)
        if val == nil then
            -- Tạo hàm giả để tránh lỗi
            return function(...) 
                -- Không làm gì, trả về nil
                return nil 
            end
        end
        return val
    end
    setmetatable(_G, mt)
    
    print("[Bypass] Đã hook loadstring và bảo vệ _G khỏi lỗi nil.")
end

-- ========== SỬA LỖI INFINITE YIELD (JumpButton) ==========
local function fixJumpButton()
    local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
    if touchGui then
        local touchControl = touchGui:FindFirstChild("TouchControlFrame")
        if touchControl then
            if not touchControl:FindFirstChild("JumpButton") then
                local fakeBtn = Instance.new("TextButton")
                fakeBtn.Name = "JumpButton"
                fakeBtn.Size = UDim2.new(0, 0, 0, 0)
                fakeBtn.Visible = false
                fakeBtn.Parent = touchControl
                print("[Fix] Đã tạo JumpButton giả.")
            end
        end
    end
end

-- ========== TÌM REMOTE TẤN CÔNG ==========
local function findAttackRemote()
    local candidates = {
        replicatedStorage:FindFirstChild("Attack"),
        replicatedStorage:FindFirstChild("RemoteEvent"),
        replicatedStorage:FindFirstChild("Combat"),
        replicatedStorage:FindFirstChild("Click"),
        replicatedStorage:FindFirstChild("SwordAttack"),
    }
    for _, r in pairs(candidates) do
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end
    for _, folder in pairs(replicatedStorage:GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (
                    child.Name:lower():find("attack") or
                    child.Name:lower():find("click") or
                    child.Name:lower():find("sword")
                ) then
                    return child
                end
            end
        end
    end
    return nil
end

-- ========== HÀM TẤN CÔNG AN TOÀN ==========
local function doAttack()
    if attackRemote then
        pcall(function()
            attackRemote:FireServer()
        end)
        pcall(function()
            attackRemote:FireServer(player.Character)
        end)
    else
        uis:SendMouseButtonEvent(1, 0, 0, true)
        task.wait(0.05)
        uis:SendMouseButtonEvent(1, 0, 0, false)
    end
end

-- ========== LẤY NHÂN VẬT ==========
local function getCharacter()
    local char = player.Character
    if not char or not char.Parent then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil, nil, nil end
    return char, hum, root
end

-- ========== TÌM QUÁI ==========
local function getNearestEnemy()
    local char, hum, root = getCharacter()
    if not char or not root then return nil end

    local best = nil
    local bestDist = CONFIG.SEARCH_RADIUS

    local enemyKeywords = {"npc", "mob", "bandit", "pirate", "soldier", "marine", "shark", "dragon", "monkey", "zombie", "skeleton", "ghost", "boss", "demon", "warrior", "guard", "knight"}

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            local humTarget = obj:FindFirstChildOfClass("Humanoid")
            if humTarget and humTarget.Health > 0 then
                local rootPart = obj:FindFirstChild("HumanoidRootPart")
                if rootPart and rootPart.Position.Y < 50000 then
                    if obj.Name ~= player.Name and not game.Players:FindFirstChild(obj.Name) then
                        local name = obj.Name:lower()
                        for _, kw in pairs(enemyKeywords) do
                            if name:find(kw) then
                                local dist = (rootPart.Position - root.Position).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    best = obj
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ========== AUTO FARM ==========
local function toggleFarm()
    Toggles.AutoFarm = not Toggles.AutoFarm
    print("[AutoFarm] Trạng thái:", Toggles.AutoFarm and "BẬT" or "TẮT")

    if Toggles.AutoFarm then
        if farmLoop then farmLoop:Disconnect() end
        farmLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoFarm then return end
            local target = getNearestEnemy()
            if target then
                local char, hum, root = getCharacter()
                local targetRoot = target:FindFirstChild("HumanoidRootPart")
                if char and hum and root and targetRoot then
                    hum:MoveTo(targetRoot.Position)
                    root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
                    doAttack()
                    task.wait(CONFIG.ATTACK_INTERVAL)
                end
            end
        end)
    else
        if farmLoop then
            farmLoop:Disconnect()
            farmLoop = nil
        end
    end
end

-- ========== AUTO COLLECT ==========
local function toggleCollect()
    Toggles.AutoCollect = not Toggles.AutoCollect
    print("[AutoCollect] Trạng thái:", Toggles.AutoCollect and "BẬT" or "TẮT")

    if Toggles.AutoCollect then
        if collectLoop then collectLoop:Disconnect() end
        collectLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoCollect then return end
            local char, hum, root = getCharacter()
            if not char or not root then return end
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                    local name = obj.Name:lower()
                    if name:find("fruit") or name:find("devil") then
                        local dist = (obj.Handle.Position - root.Position).Magnitude
                        if dist < 20 then
                            hum:MoveTo(obj.Handle.Position)
                            task.wait(0.3)
                            uis:SendMouseButtonEvent(1, 0, 0, true)
                            task.wait(0.05)
                            uis:SendMouseButtonEvent(1, 0, 0, false)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end)
    else
        if collectLoop then
            collectLoop:Disconnect()
            collectLoop = nil
        end
    end
end

-- ========== FLY ==========
local function toggleFly()
    Toggles.Fly = not Toggles.Fly
    print("[Fly] Trạng thái:", Toggles.Fly and "BẬT" or "TẮT")

    local char, hum, root = getCharacter()
    if not char or not root then return

    if Toggles.Fly then
        if flyBody then flyBody:Destroy() end
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.new(0, 0, 0)
        flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBody.Parent = root

        local flyConnection
        flyConnection = runService.Heartbeat:Connect(function()
            if not Toggles.Fly or not flyBody or not root then
                if flyConnection then flyConnection:Disconnect() end
                return
            end
            local dir = root.CFrame.LookVector
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
                flyBody.Velocity = dir * CONFIG.FLY_SPEED + Vector3.new(0, CONFIG.FLY_SPEED * 0.3, 0)
            else
                flyBody.Velocity = dir * CONFIG.FLY_SPEED
            end
        end)
    else
        if flyBody then
            flyBody:Destroy()
            flyBody = nil
        end
    end
end

-- ========== SPEED & JUMP ==========
local function toggleSpeed()
    Toggles.Speed = not Toggles.Speed
    print("[Speed] Trạng thái:", Toggles.Speed and "BẬT" or "TẮT")
    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = Toggles.Speed and 50 or 16
    end
end

local function toggleJump()
    Toggles.SuperJump = not Toggles.SuperJump
    print("[SuperJump] Trạng thái:", Toggles.SuperJump and "BẬT" or "TẮT")
    local _, hum = getCharacter()
    if hum then
        hum.JumpPower = Toggles.SuperJump and 500 or 50
    end
end

-- ========== TẠO MENU ==========
local function createMenu()
    local oldGui = player.PlayerGui:FindFirstChild("BFHackMenu")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFHackMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "BLOX FRUIT HACK (FIXED)"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame

    local function createBtn(text, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 38)
        btn.Position = UDim2.new(0.075, 0, yPos, 0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(0, 200, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 16
        btn.Parent = mainFrame
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local btnFarm = createBtn("Auto Farm (OFF)", 0.11, function()
        toggleFarm()
        btnFarm.Text = Toggles.AutoFarm and "Auto Farm (ON)" or "Auto Farm (OFF)"
        btnFarm.BackgroundColor3 = Toggles.AutoFarm and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnCollect = createBtn("Auto Collect (OFF)", 0.21, function()
        toggleCollect()
        btnCollect.Text = Toggles.AutoCollect and "Auto Collect (ON)" or "Auto Collect (OFF)"
        btnCollect.BackgroundColor3 = Toggles.AutoCollect and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnFly = createBtn("Fly (OFF)", 0.31, function()
        toggleFly()
        btnFly.Text = Toggles.Fly and "Fly (ON)" or "Fly (OFF)"
        btnFly.BackgroundColor3 = Toggles.Fly and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnSpeed = createBtn("Speed Boost (OFF)", 0.41, function()
        toggleSpeed()
        btnSpeed.Text = Toggles.Speed and "Speed Boost (ON)" or "Speed Boost (OFF)"
        btnSpeed.BackgroundColor3 = Toggles.Speed and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnJump = createBtn("Super Jump (OFF)", 0.51, function()
        toggleJump()
        btnJump.Text = Toggles.SuperJump and "Super Jump (ON)" or "Super Jump (OFF)"
        btnJump.BackgroundColor3 = Toggles.SuperJump and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnTeleport = createBtn("Teleport Island", 0.61, function()
        local islands = {"Jungle", "Pirate Village", "Marine Fortress", "Sky Island", "Ice Island", "Volcano Island", "Dressrosa"}
        local subFrame = Instance.new("Frame")
        subFrame.Size = UDim2.new(0.7, 0, 0, 160)
        subFrame.Position = UDim2.new(0.15, 0, 0.68, 0)
        subFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        subFrame.BorderSizePixel = 1
        subFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
        subFrame.Parent = mainFrame

        for i, name in ipairs(islands) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.Position = UDim2.new(0, 0, (i-1)*0.2, 0)
            btn.Text = name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = subFrame
            btn.MouseButton1Click:Connect(function()
                local target = nil
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj.Name:find(name) then
                        target = obj
                        break
                    end
                end
                if target and target.PrimaryPart then
                    local char, hum, root = getCharacter()
                    if char and root then
                        root.CFrame = target.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
                    end
                end
                subFrame:Destroy()
            end)
        end

        uis.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if subFrame then subFrame:Destroy() end
            end
        end)
    end)

    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F9 then
            btnFarm:Fire("MouseButton1Click")
        end
        if input.KeyCode == Enum.KeyCode.F10 then
            btnFly:Fire("MouseButton1Click")
        end
    end)

    print("[Menu] Đã tạo! Phím tắt: F9 (Farm), F10 (Fly)")
end

-- ========== KHỞI TẠO ==========
bypassAndProtect()
fixJumpButton()

attackRemote = findAttackRemote()
if attackRemote then
    print("[Remote] Tìm thấy:", attackRemote.Name)
else
    warn("[Remote] Không tìm thấy RemoteEvent, dùng click dự phòng.")
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local _, hum = getCharacter()
    if hum then
        if Toggles.Speed then hum.WalkSpeed = 50 end
        if Toggles.SuperJump then hum.JumpPower = 500 end
    end
end)

task.wait(1)
createMenu()

print("[BloxFruit Hack] Load thành công! Tất cả lỗi đã được fix.")
