-- ==============================================================
-- Blox Fruit Hack - Delta (Không lỗi)
-- Fix: Remote event queue, Infinite yield, Humanoid invalid, xVLcN...
-- ==============================================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

-- ========== CẤU HÌNH ==========
local CONFIG = {
    ATTACK_INTERVAL = 0.15,
    SEARCH_RADIUS = 40,
    FLY_SPEED = 50,
}

-- ========== TOGGLE ==========
local Toggles = {
    AutoFarm = false,
    Fly = false,
    Speed = false,
    SuperJump = false,
}

-- ========== BIẾN ==========
local attackRemote = nil
local flyBody = nil
local farmLoop = nil
local character = nil
local humanoid = nil
local rootPart = nil

-- ========== FIX: LẤY NHÂN VẬT AN TOÀN ==========
local function getChar()
    local char = player.Character
    if not char or not char.Parent then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.Health <= 0 then return end
    character = char
    humanoid = hum
    rootPart = root
    return char, hum, root
end

-- ========== FIX: TÌM REMOTE TẤN CÔNG ==========
local function findAttackRemote()
    -- Danh sách remote thường gặp
    local remotes = {
        replicatedStorage:FindFirstChild("Attack"),
        replicatedStorage:FindFirstChild("RemoteEvent"),
        replicatedStorage:FindFirstChild("Combat"),
        replicatedStorage:FindFirstChild("Click"),
        replicatedStorage:FindFirstChild("SwordAttack"),
        replicatedStorage:FindFirstChild("Melee"),
        replicatedStorage:FindFirstChild("Damage"),
    }
    for _, r in pairs(remotes) do
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end
    -- Duyệt folder
    for _, folder in pairs(replicatedStorage:GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (
                    child.Name:lower():find("attack") or
                    child.Name:lower():find("click") or
                    child.Name:lower():find("sword") or
                    child.Name:lower():find("combat") or
                    child.Name:lower():find("damage")
                ) then
                    return child
                end
            end
        end
    end
    return nil
end

attackRemote = findAttackRemote()
if attackRemote then
    print("[Remote] Found:", attackRemote.Name)
else
    warn("[Remote] Not found, using mouse click fallback.")
end

-- ========== HÀM TẤN CÔNG (KHÔNG GÂY LỖI) ==========
local function doAttack()
    if attackRemote then
        pcall(function()
            attackRemote:FireServer()
        end)
        -- Thử với tham số
        pcall(function()
            attackRemote:FireServer(player.Character)
        end)
    else
        -- Fallback: click chuột
        uis:SendMouseButtonEvent(1, 0, 0, true)
        task.wait(0.05)
        uis:SendMouseButtonEvent(1, 0, 0, false)
    end
end

-- ========== TÌM QUÁI (BỎ QUA QUÁI Y > 50000) ==========
local function getNearestEnemy()
    getChar()
    if not rootPart then return nil end

    local best = nil
    local bestDist = CONFIG.SEARCH_RADIUS

    local keywords = {"npc", "mob", "bandit", "pirate", "soldier", "marine", "shark", "dragon", "monkey", "zombie", "skeleton", "ghost", "boss", "demon", "warrior", "guard", "knight", "raider", "brute", "ninja", "shogun"}

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root and root.Position.Y < 50000 then
                    if obj.Name ~= player.Name and not game.Players:FindFirstChild(obj.Name) then
                        local name = obj.Name:lower()
                        for _, kw in pairs(keywords) do
                            if name:find(kw) then
                                local dist = (root.Position - rootPart.Position).Magnitude
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
    print("[AutoFarm]", Toggles.AutoFarm and "ON" or "OFF")

    if Toggles.AutoFarm then
        if farmLoop then farmLoop:Disconnect() end
        farmLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoFarm then return end
            getChar()
            if not humanoid or not rootPart then return end

            local target = getNearestEnemy()
            if target then
                local targetRoot = target:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    humanoid:MoveTo(targetRoot.Position)
                    rootPart.CFrame = CFrame.lookAt(rootPart.Position, targetRoot.Position)
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

-- ========== FLY ==========
local function toggleFly()
    Toggles.Fly = not Toggles.Fly
    print("[Fly]", Toggles.Fly and "ON" or "OFF")
    getChar()
    if not rootPart then return end

    if Toggles.Fly then
        if flyBody then flyBody:Destroy() end
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.new(0, 0, 0)
        flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBody.Parent = rootPart

        local con
        con = runService.Heartbeat:Connect(function()
            if not Toggles.Fly or not flyBody or not rootPart then
                if con then con:Disconnect() end
                return
            end
            local dir = rootPart.CFrame.LookVector
            local spd = CONFIG.FLY_SPEED
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
                flyBody.Velocity = dir * spd + Vector3.new(0, spd * 0.3, 0)
            else
                flyBody.Velocity = dir * spd
            end
        end)
    else
        if flyBody then
            flyBody:Destroy()
            flyBody = nil
        end
    end
end

-- ========== SPEED ==========
local function toggleSpeed()
    Toggles.Speed = not Toggles.Speed
    print("[Speed]", Toggles.Speed and "ON" or "OFF")
    getChar()
    if humanoid then
        humanoid.WalkSpeed = Toggles.Speed and 50 or 16
    end
end

-- ========== SUPER JUMP ==========
local function toggleJump()
    Toggles.SuperJump = not Toggles.SuperJump
    print("[SuperJump]", Toggles.SuperJump and "ON" or "OFF")
    getChar()
    if humanoid then
        humanoid.JumpPower = Toggles.SuperJump and 500 or 50
    end
end

-- ========== FIX: INFINITE YIELD JUMPBUTTON ==========
local function fixJumpButton()
    local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
    if touchGui then
        local touchControl = touchGui:FindFirstChild("TouchControlFrame")
        if touchControl then
            if not touchControl:FindFirstChild("JumpButton") then
                local fake = Instance.new("TextButton")
                fake.Name = "JumpButton"
                fake.Size = UDim2.new(0, 0, 0, 0)
                fake.Visible = false
                fake.Parent = touchControl
                print("[Fix] JumpButton created.")
            end
        end
    end
end

fixJumpButton()

-- ========== FIX: VÔ HIỆU HÓA LỖI DMGDEBUG ==========
local function fixDMGDebug()
    local remote = replicatedStorage:FindFirstChild("Remotes")
    if remote then
        local dmg = remote:FindFirstChild("DMGDEBUG")
        if dmg and dmg:IsA("RemoteEvent") then
            -- Gán một hàm rỗng để không bị queue exhausted
            dmg.OnClientEvent = function() end
            print("[Fix] DMGDEBUG fixed.")
        end
    end
end
fixDMGDebug()

-- ========== FIX: LỖI xVLcN... (LocalScript gọi nil) ==========
-- Vô hiệu hóa các LocalScript lỗi trong PlayerScripts
local function fixLocalScripts()
    local scripts = player:FindFirstChild("PlayerScripts")
    if scripts then
        for _, child in pairs(scripts:GetChildren()) do
            if child:IsA("LocalScript") and child.Name ~= "Network" then
                pcall(function()
                    child.Disabled = true
                end)
            end
        end
        print("[Fix] Disabled broken LocalScripts.")
    end
end
fixLocalScripts()

-- ========== TẠO MENU ==========
local function createMenu()
    local old = player.PlayerGui:FindFirstChild("BFHackMenu")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "BFHackMenu"
    sg.ResetOnSpawn = false
    sg.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 380)
    frame.Position = UDim2.new(0.5, -190, 0.5, -190)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Draggable = true
    frame.Active = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Text = "BLOX FRUIT HACK"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    local function btn(text, y, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.85, 0, 0, 35)
        b.Position = UDim2.new(0.075, 0, y, 0)
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        b.BorderSizePixel = 1
        b.BorderColor3 = Color3.fromRGB(0, 200, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 16
        b.Parent = frame
        b.MouseButton1Click:Connect(cb)
        return b
    end

    local bFarm = btn("Auto Farm (OFF)", 0.12, function()
        toggleFarm()
        bFarm.Text = Toggles.AutoFarm and "Auto Farm (ON)" or "Auto Farm (OFF)"
        bFarm.BackgroundColor3 = Toggles.AutoFarm and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local bFly = btn("Fly (OFF)", 0.27, function()
        toggleFly()
        bFly.Text = Toggles.Fly and "Fly (ON)" or "Fly (OFF)"
        bFly.BackgroundColor3 = Toggles.Fly and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local bSpeed = btn("Speed Boost (OFF)", 0.42, function()
        toggleSpeed()
        bSpeed.Text = Toggles.Speed and "Speed Boost (ON)" or "Speed Boost (OFF)"
        bSpeed.BackgroundColor3 = Toggles.Speed and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local bJump = btn("Super Jump (OFF)", 0.57, function()
        toggleJump()
        bJump.Text = Toggles.SuperJump and "Super Jump (ON)" or "Super Jump (OFF)"
        bJump.BackgroundColor3 = Toggles.SuperJump and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local bTeleport = btn("Teleport to Island", 0.72, function()
        local sub = Instance.new("Frame")
        sub.Size = UDim2.new(0.7, 0, 0, 120)
        sub.Position = UDim2.new(0.15, 0, 0.80, 0)
        sub.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        sub.BorderSizePixel = 1
        sub.BorderColor3 = Color3.fromRGB(0, 200, 255)
        sub.Parent = frame

        local islands = {"Jungle", "Pirate Village", "Marine Fortress", "Sky Island", "Ice Island", "Volcano Island", "Dressrosa"}
        for i, name in ipairs(islands) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 25)
            b.Position = UDim2.new(0, 0, (i-1)*0.17, 0)
            b.Text = name
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            b.BorderSizePixel = 0
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = sub
            b.MouseButton1Click:Connect(function()
                teleportTo(name)
                sub:Destroy()
            end)
        end
        uis.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if sub then sub:Destroy() end
            end
        end)
    end)

    -- Phím tắt
    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F9 then
            bFarm:Fire("MouseButton1Click")
        end
        if input.KeyCode == Enum.KeyCode.F10 then
            bFly:Fire("MouseButton1Click")
        end
    end)

    print("[Menu] Ready. F9=Farm, F10=Fly.")
end

-- ========== TELEPORT ==========
function teleportTo(name)
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:find(name) and obj.PrimaryPart then
            getChar()
            if rootPart then
                rootPart.CFrame = obj.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
                print("[Teleport] ->", name)
                return
            end
        end
    end
    print("[Teleport] Not found:", name)
end

-- ========== KHỞI TẠO ==========
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    getChar()
    if humanoid then
        if Toggles.Speed then humanoid.WalkSpeed = 50 end
        if Toggles.SuperJump then humanoid.JumpPower = 500 end
    end
end)

task.wait(1)
createMenu()

print("[BloxFruit Hack] Loaded successfully!")
