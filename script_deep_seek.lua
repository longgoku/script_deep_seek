-- =====================================================================
-- BLOX FRUIT HACK - FULL CHỨC NĂNG (FIX LỖI HOÀN TOÀN)
-- Dành cho Delta Executor, tương thích với Blox Fruit
-- Tác giả: palofsc (dựa trên cơ chế bypass BF-BananaCat)
-- =====================================================================

-- ============================ KHỞI TẠO ============================
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local coreGui = game:GetService("CoreGui")  -- Dùng CoreGui để tránh bị xóa

-- ============================ BYPASS KEY CHECK ============================
local function bypassKeyCheck()
    local env = getfenv()
    local old_loadstring = env.loadstring
    env.loadstring = function(code, chunkname)
        if type(code) == "string" then
            if code:lower():find("key") or code:lower():find("license") then
                print("[Bypass] Đã vá key check")
                code = "local function CheckLicense() return true end\n" .. code
                code = code:gsub("([%w_]+)%.%s*Key%s*==?%s*(.-)(%s*)then", function(a, b, c, d)
                    return a .. "." .. b .. " = true " .. d .. " then"
                end)
            end
        end
        return old_loadstring(code, chunkname)
    end
    print("[Bypass] Hook loadstring thành công")
end
bypassKeyCheck()

-- ============================ FIX LỖI INFINITE YIELD ============================
local function fixInfiniteYield()
    -- Tạo JumpButton giả để tránh lỗi WaitForChild
    local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
    if touchGui then
        local touchControl = touchGui:FindFirstChild("TouchControlFrame")
        if touchControl and not touchControl:FindFirstChild("JumpButton") then
            local fake = Instance.new("TextButton")
            fake.Name = "JumpButton"
            fake.Size = UDim2.new(0, 0, 0, 0)
            fake.Visible = false
            fake.Parent = touchControl
            print("[Fix] Đã tạo JumpButton giả")
        end
    end
    -- Vô hiệu hóa lỗi Skyjump (nếu có)
    pcall(function()
        local skyjump = player.Character and player.Character:FindFirstChild("Skyjump")
        if skyjump then skyjump:Destroy() end
    end)
end

-- ============================ FIX LỖI REMOTE EVENT DMGDEBUG ============================
local function fixDMGDebug()
    local remote = replicatedStorage:FindFirstChild("Remotes")
    if remote then
        local dmg = remote:FindFirstChild("DMGDEBUG")
        if dmg and dmg:IsA("RemoteEvent") then
            -- Tạo OnClientEvent rỗng để hấp thụ sự kiện
            dmg.OnClientEvent:Connect(function() end)
            print("[Fix] Đã hook DMGDEBUG để ngăn tràn hàng đợi")
        end
    end
end

-- ============================ TÌM REMOTE TẤN CÔNG ============================
local attackRemote = nil
local function findAttackRemote()
    local candidates = {
        replicatedStorage:FindFirstChild("Attack"),
        replicatedStorage:FindFirstChild("RemoteEvent"),
        replicatedStorage:FindFirstChild("Combat"),
        replicatedStorage:FindFirstChild("Click"),
    }
    for _, r in pairs(candidates) do
        if r and r:IsA("RemoteEvent") then return r end
    end
    for _, folder in pairs(replicatedStorage:GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (
                    child.Name:lower():find("attack") or
                    child.Name:lower():find("click") or
                    child.Name:lower():find("sword") or
                    child.Name:lower():find("combat")
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
    print("[Remote] Tìm thấy:", attackRemote.Name)
else
    warn("[Remote] Không tìm thấy Remote, dùng click dự phòng")
end

-- ============================ CẤU HÌNH ============================
local CONFIG = {
    ATTACK_INTERVAL = 0.12,
    SEARCH_RADIUS = 40,
    FLY_SPEED = 60,
}

-- ============================ TOGGLE ============================
local Toggles = {
    AutoFarm = false,
    AutoCollect = false,
    Fly = false,
    Speed = false,
    SuperJump = false,
}

-- ============================ HÀM LẤY NHÂN VẬT ============================
local function getChar()
    local char = player.Character
    if not char or not char.Parent then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil, nil, nil end
    return char, hum, root
end

-- ============================ TẤN CÔNG ============================
local function doAttack()
    if attackRemote then
        pcall(function() attackRemote:FireServer() end)
        pcall(function() attackRemote:FireServer(player.Character) end)
    else
        uis:SendMouseButtonEvent(1, 0, 0, true)
        task.wait(0.05)
        uis:SendMouseButtonEvent(1, 0, 0, false)
    end
end

-- ============================ TÌM QUÁI (LỌC Y > 50000) ============================
local enemyKeywords = {
    "npc","mob","bandit","pirate","soldier","marine","shark",
    "dragon","monkey","zombie","skeleton","ghost","boss",
    "demon","warrior","guard","knight","raider","brute","ninja"
}

local function getNearestEnemy()
    local char, hum, root = getChar()
    if not char or not root then return nil end

    local best = nil
    local bestDist = CONFIG.SEARCH_RADIUS

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local rp = obj:FindFirstChild("HumanoidRootPart")
                if rp then
                    -- Bỏ qua Y > 50000
                    if rp.Position.Y > 50000 then continue end
                    -- Bỏ qua player
                    if obj.Name == player.Name or game.Players:FindFirstChild(obj.Name) then continue end
                    local name = obj.Name:lower()
                    local isEnemy = false
                    for _, kw in pairs(enemyKeywords) do
                        if name:find(kw) then isEnemy = true; break end
                    end
                    if isEnemy then
                        local dist = (rp.Position - root.Position).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = obj
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================ AUTO FARM ============================
local farmLoop = nil
local function toggleFarm()
    Toggles.AutoFarm = not Toggles.AutoFarm
    print("[Farm]", Toggles.AutoFarm and "BẬT" or "TẮT")
    if Toggles.AutoFarm then
        if farmLoop then farmLoop:Disconnect() end
        farmLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoFarm then return end
            local target = getNearestEnemy()
            if target then
                local char, hum, root = getChar()
                local tr = target:FindFirstChild("HumanoidRootPart")
                if char and hum and root and tr then
                    hum:MoveTo(tr.Position)
                    root.CFrame = CFrame.lookAt(root.Position, tr.Position)
                    doAttack()
                    task.wait(CONFIG.ATTACK_INTERVAL)
                end
            end
        end)
    else
        if farmLoop then farmLoop:Disconnect(); farmLoop = nil end
    end
end

-- ============================ AUTO COLLECT ============================
local collectLoop = nil
local function toggleCollect()
    Toggles.AutoCollect = not Toggles.AutoCollect
    print("[Collect]", Toggles.AutoCollect and "BẬT" or "TẮT")
    if Toggles.AutoCollect then
        if collectLoop then collectLoop:Disconnect() end
        collectLoop = runService.Heartbeat:Connect(function()
            if not Toggles.AutoCollect then return end
            local char, hum, root = getChar()
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
        if collectLoop then collectLoop:Disconnect(); collectLoop = nil end
    end
end

-- ============================ FLY ============================
local flyBody = nil
local flyCon = nil
local function toggleFly()
    Toggles.Fly = not Toggles.Fly
    print("[Fly]", Toggles.Fly and "BẬT" or "TẮT")
    local char, hum, root = getChar()
    if not char or not root then return

    if Toggles.Fly then
        if flyBody then flyBody:Destroy() end
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.new(0, 0, 0)
        flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBody.Parent = root
        if flyCon then flyCon:Disconnect() end
        flyCon = runService.Heartbeat:Connect(function()
            if not Toggles.Fly or not flyBody or not root then
                if flyCon then flyCon:Disconnect(); flyCon = nil end
                return
            end
            local dir = root.CFrame.LookVector
            local spd = CONFIG.FLY_SPEED
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
                flyBody.Velocity = dir * spd + Vector3.new(0, spd * 0.3, 0)
            else
                flyBody.Velocity = dir * spd
            end
        end)
    else
        if flyBody then flyBody:Destroy(); flyBody = nil end
        if flyCon then flyCon:Disconnect(); flyCon = nil end
    end
end

-- ============================ SPEED & JUMP ============================
local function toggleSpeed()
    Toggles.Speed = not Toggles.Speed
    local _, hum = getChar()
    if hum then hum.WalkSpeed = Toggles.Speed and 50 or 16 end
    print("[Speed]", Toggles.Speed and "BẬT" or "TẮT")
end

local function toggleJump()
    Toggles.SuperJump = not Toggles.SuperJump
    local _, hum = getChar()
    if hum then hum.JumpPower = Toggles.SuperJump and 500 or 50 end
    print("[Jump]", Toggles.SuperJump and "BẬT" or "TẮT")
end

-- ============================ MENU (CORE GUI) ============================
local function createMenu()
    -- Xóa menu cũ
    local old = coreGui:FindFirstChild("BFMenu")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = coreGui  -- Gắn vào CoreGui để chắc chắn hiển thị

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 400, 0, 480)
    main.Position = UDim2.new(0.5, -200, 0.5, -240)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 2
    main.BorderColor3 = Color3.fromRGB(0, 200, 255)
    main.Draggable = true
    main.Active = true
    main.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "⚡ BLOX FRUIT HACK [DELTA]"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = main

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
        btn.Parent = main
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local btnFarm = createBtn("🔁 Auto Farm (OFF)", 0.11, function()
        toggleFarm()
        btnFarm.Text = Toggles.AutoFarm and "🔁 Auto Farm (ON)" or "🔁 Auto Farm (OFF)"
        btnFarm.BackgroundColor3 = Toggles.AutoFarm and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnCollect = createBtn("📦 Auto Collect (OFF)", 0.21, function()
        toggleCollect()
        btnCollect.Text = Toggles.AutoCollect and "📦 Auto Collect (ON)" or "📦 Auto Collect (OFF)"
        btnCollect.BackgroundColor3 = Toggles.AutoCollect and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnFly = createBtn("✈️ Fly (OFF)", 0.31, function()
        toggleFly()
        btnFly.Text = Toggles.Fly and "✈️ Fly (ON)" or "✈️ Fly (OFF)"
        btnFly.BackgroundColor3 = Toggles.Fly and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnSpeed = createBtn("💨 Speed Boost (OFF)", 0.41, function()
        toggleSpeed()
        btnSpeed.Text = Toggles.Speed and "💨 Speed Boost (ON)" or "💨 Speed Boost (OFF)"
        btnSpeed.BackgroundColor3 = Toggles.Speed and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    local btnJump = createBtn("🦘 Super Jump (OFF)", 0.51, function()
        toggleJump()
        btnJump.Text = Toggles.SuperJump and "🦘 Super Jump (ON)" or "🦘 Super Jump (OFF)"
        btnJump.BackgroundColor3 = Toggles.SuperJump and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(200, 50, 50)
    end)

    -- Teleport (submenu)
    local islands = {"Jungle","Pirate Village","Marine Fortress","Sky Island","Ice Island","Volcano Island","Dressrosa"}
    local btnTele = createBtn("📍 Teleport to Island", 0.61, function()
        local sub = Instance.new("Frame")
        sub.Size = UDim2.new(0.7, 0, 0, 160)
        sub.Position = UDim2.new(0.15, 0, 0.68, 0)
        sub.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        sub.BorderSizePixel = 1
        sub.BorderColor3 = Color3.fromRGB(0, 200, 255)
        sub.Parent = main
        for i, name in ipairs(islands) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 32)
            b.Position = UDim2.new(0, 0, (i-1)*0.2, 0)
            b.Text = name
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.BackgroundColor3 = Color3.fromRGB(30,30,45)
            b.BorderSizePixel = 0
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = sub
            b.MouseButton1Click:Connect(function()
                local target = nil
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj.Name:find(name) then
                        target = obj; break
                    end
                end
                if target and target.PrimaryPart then
                    local char, hum, root = getChar()
                    if char and root then
                        root.CFrame = target.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
                    end
                end
                sub:Destroy()
            end)
        end
        uis.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if sub then sub:Destroy() end
            end
        end)
    end)

    -- Nút ẩn menu (dấu -)
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, 40, 0, 30)
    hideBtn.Position = UDim2.new(0.9, 0, 0.03, 0)
    hideBtn.Text = "−"
    hideBtn.TextColor3 = Color3.fromRGB(255,255,255)
    hideBtn.BackgroundColor3 = Color3.fromRGB(60,60,80)
    hideBtn.BorderSizePixel = 1
    hideBtn.BorderColor3 = Color3.fromRGB(0,200,255)
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 24
    hideBtn.Parent = main
    local menuVisible = true
    hideBtn.MouseButton1Click:Connect(function()
        menuVisible = not menuVisible
        main.Visible = menuVisible
        hideBtn.Text = menuVisible and "−" or "+"
    end)

    -- Phím tắt
    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F9 then
            btnFarm:Fire("MouseButton1Click")
        elseif input.KeyCode == Enum.KeyCode.F10 then
            btnFly:Fire("MouseButton1Click")
        elseif input.KeyCode == Enum.KeyCode.F11 then
            hideBtn:Fire("MouseButton1Click")
        end
    end)

    print("[Menu] ✅ Menu đã hiển thị! Phím: F9(Farm), F10(Fly), F11(Ẩn/Hiện)")
end

-- ============================ KHỞI TẠO ============================
-- Fix các lỗi đã biết
fixInfiniteYield()
fixDMGDebug()

-- Cập nhật khi nhân vật respawn
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local _, hum = getChar()
    if hum then
        if Toggles.Speed then hum.WalkSpeed = 50 end
        if Toggles.SuperJump then hum.JumpPower = 500 end
    end
end)

-- Tạo menu sau 1 giây
task.wait(1)
createMenu()

print("[BloxFruit] ✅ Load thành công! Chúc bạn farm vui vẻ!")
