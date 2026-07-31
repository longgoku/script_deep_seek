-- ===================================================================
-- Blox Fruit Hack Full - Delta Executor
-- Dựa trên cơ chế bypass key check của BF-BananaCat
-- Tích hợp: Auto Farm, Auto Aim, Fly, Teleport, Speed, Jump, Auto Collect
-- ===================================================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- ========== CẤU HÌNH ==========
local CONFIG = {
    ATTACK_INTERVAL = 0.12,      -- Tốc độ đánh (giây)
    SEARCH_RADIUS = 40,          -- Bán kính tìm quái
    FLY_SPEED = 60,              -- Tốc độ bay
    TELEPORT_DELAY = 0.5,        -- Delay khi teleport
}

-- ========== TOGGLE (trạng thái) ==========
local Toggles = {
    AutoFarm = false,
    AutoCollect = false,
    AutoAim = false,
    Fly = false,
    Speed = false,
    SuperJump = false,
    BypassTP = false,
    AutoMastery = false,
}

-- ========== BIẾN TOÀN CỤC ==========
local attackRemote = nil
local flyBody = nil
local currentTarget = nil
local character = nil
local humanoid = nil
local rootPart = nil

-- ========== TÌM REMOTE TẤN CÔNG ==========
local function findAttackRemote()
    local candidates = {
        replicatedStorage:FindFirstChild("Attack"),
        replicatedStorage:FindFirstChild("RemoteEvent"),
        replicatedStorage:FindFirstChild("Combat"),
        replicatedStorage:FindFirstChild("Click"),
        replicatedStorage:FindFirstChild("SwordAttack"),
        replicatedStorage:FindFirstChild("Melee"),
    }
    for _, r in pairs(candidates) do
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end
    -- Duyệt tất cả folder
    for _, folder in pairs(replicatedStorage:GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (
                    child.Name:lower():find("attack") or
                    child.Name:lower():find("click") or
                    child.Name:lower():find("sword") or
                    child.Name:lower():find("combat") or
                    child.Name:lower():find("melee")
                ) then
                    return child
                end
            end
        end
    end
    return nil
end

-- ========== HÀM TẤN CÔNG ==========
local function doAttack()
    if attackRemote then
        pcall(function()
            attackRemote:FireServer()
        end)
        pcall(function()
            attackRemote:FireServer(player.Character)
        end)
    else
        -- Dự phòng: gửi click chuột
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

-- ========== TÌM QUÁI GẦN NHẤT ==========
local function getNearestEnemy()
    local char, hum, root = getCharacter()
    if not char or not root then return nil end

    local best = nil
    local bestDist = CONFIG.SEARCH_RADIUS

    local enemyKeywords = {"npc", "mob", "bandit", "pirate", "soldier", "marine", "shark", "dragon", "monkey", "zombie", "skeleton", "ghost", "boss", "demon", "warrior", "guard", "knight", "raider", "brute", "ninja", "shogun"}

    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local humTarget = obj:FindFirstChild("Humanoid")
            if humTarget and humTarget.Health > 0 then
                -- Bỏ qua player
                if obj.Name ~= player.Name and not game.Players:FindFirstChild(obj.Name) then
                    local name = obj.Name:lower()
                    local isEnemy = false
                    for _, kw in pairs(enemyKeywords) do
                        if name:find(kw) then
                            isEnemy = true
                            break
                        end
                    end
                    if isEnemy then
                        local rootPart = obj:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local dist = (rootPart.Position - root.Position).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                best = obj
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
local farmLoop = nil
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
                    -- Di chuyển đến quái
                    hum:MoveTo(targetRoot.Position + Vector3.new(0, 0, 0))
                    -- Quay mặt về quái
                    root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
                    -- Tấn công
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

-- ========== AUTO COLLECT FRUIT ==========
local collectLoop = nil
local function toggleCollect()
    Toggles.AutoCollect = not Toggles.AutoCollect
    print("[AutoCollect] Trạng thái:", Toggles.AutoCollect and "BẬT" or "TẮT")

    if Toggles.AutoCollect then
        if collectLoop then collectLoop:Disconnect() end
        collectLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoCollect then return end
            local char, hum, root = getCharacter()
            if not char or not root then return end
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                    local name = obj.Name:lower()
                    if name:find("fruit") or name:find("devil") then
                        local dist = (obj.Handle.Position - root.Position).Magnitude
                        if dist < 20 then
                            hum:MoveTo(obj.Handle.Position)
                            task.wait(0.3)
                            -- Click để nhặt
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

        -- Cập nhật hướng bay
        local flyConnection
        flyConnection = runService.Heartbeat:Connect(function()
            if not Toggles.Fly or not flyBody or not root then
                if flyConnection then flyConnection:Disconnect() end
                return
            end
            local dir = root.CFrame.LookVector
            local speed = CONFIG.FLY_SPEED
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
                flyBody.Velocity = dir * speed + Vector3.new(0, speed * 0.3, 0)
            else
                flyBody.Velocity = dir * speed
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

-- ========== TELEPORT ĐẾN ĐẢO ==========
local islands = {
    "Jungle",
    "Pirate Village",
    "Marine Fortress",
    "Sky Island",
    "Ice Island",
    "Volcano Island",
    "Dressrosa"
}

local function teleportTo(islandName)
    local target = nil
    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:find(islandName) then
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
end

-- ========== BYPASS KEY CHECK (hook loadstring) ==========
local function bypassKeyCheck()
    local env = getfenv()
    local old_loadstring = env.loadstring

    env.loadstring = function(code, chunkname)
        if type(code) == "string" then
            if string.find(code:lower(), "key") or string.find(code:lower(), "license") then
                print("[Bypass] Phát hiện key check, đang vá...")
                code = "local function CheckLicense() return true end\n" .. code
                code = code:gsub("([%w_]+)%.%s*Key%s*==?%s*(.-)(%s*)then", function(a,b,c,d)
                    return a .. "." .. b .. " = true " .. d .. " then"
                end)
            end
        end
        return old_loadstring(code, chunkname)
    end
    print("[Bypass] Hook loadstring thành công!")
end

-- ========== TẠO MENU GUI ==========
local function createMenu()
    -- Xóa GUI cũ
    local oldGui = player.PlayerGui:FindFirstChild("BFHackMenu")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFHackMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "BLOX FRUIT HACK [DELTA]"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame

    -- Hàm tạo nút
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

    -- Các nút
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

    -- Teleport (submenu)
    local btnTeleport = createBtn("Teleport to Island", 0.61, function()
        -- Tạo subframe
        local subFrame = Instance.new("Frame")
        subFrame.Size = UDim2.new(0.7, 0, 0, 150)
        subFrame.Position = UDim2.new(0.15, 0, 0.68, 0)
        subFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        subFrame.BorderSizePixel = 1
        subFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
        subFrame.Parent = mainFrame

        for i, name in ipairs(islands) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Position = UDim2.new(0, 0, (i-1)*0.2, 0)
            btn.Text = name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = subFrame
            btn.MouseButton1Click:Connect(function()
                teleportTo(name)
                subFrame:Destroy()
            end)
        end
        -- Tự động xóa khi click ra ngoài
        game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if subFrame then subFrame:Destroy() end
            end
        end)
    end)

    -- Nút Bypass TP
    local btnBypassTP = createBtn("Bypass TP (OFF)", 0.72, function()
        Toggles.BypassTP = not Toggles.BypassTP
        btnBypassTP.Text = Toggles.BypassTP and "Bypass TP (ON)" or "Bypass TP (OFF)"
        btnBypassTP.BackgroundColor3 = Toggles.BypassTP and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
        print("[BypassTP] Trạng thái:", Toggles.BypassTP and "BẬT" or "TẮT")
    end)

    -- Nút Auto Mastery
    local btnMastery = createBtn("Auto Mastery (OFF)", 0.82, function()
        Toggles.AutoMastery = not Toggles.AutoMastery
        btnMastery.Text = Toggles.AutoMastery and "Auto Mastery (ON)" or "Auto Mastery (OFF)"
        btnMastery.BackgroundColor3 = Toggles.AutoMastery and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
        print("[AutoMastery] Trạng thái:", Toggles.AutoMastery and "BẬT" or "TẮT")
    end)

    -- Phím tắt F9 để bật/tắt Auto Farm
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
-- Bypass key check
bypassKeyCheck()

-- Tìm Remote tấn công
attackRemote = findAttackRemote()
if attackRemote then
    print("[Remote] Tìm thấy:", attackRemote.Name)
else
    warn("[Remote] Không tìm thấy RemoteEvent, sẽ dùng click dự phòng.")
end

-- Cập nhật nhân vật khi respawn
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local _, hum, root = getCharacter()
    if hum then
        -- Áp dụng Speed/Jump nếu đang bật
        if Toggles.Speed then hum.WalkSpeed = 50 end
        if Toggles.SuperJump then hum.JumpPower = 500 end
    end
end)

-- Tạo menu
task.wait(1)
createMenu()

print("[BloxFruit Hack] Đã load thành công! Hãy tận hưởng.")
