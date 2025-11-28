local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Check world/sea where player is
local placeId = game.PlaceId
local isFirstSea = placeId == 2753915549
local isSecondSea = placeId == 4442272183
local isThirdSea = placeId == 7449423635

pcall(function()
    local data = player:WaitForChild("Data")
    if not data:FindFirstChild("Team") or data.Team.Value == "" then
        -- Haven't chosen a team yet, choose Pirates
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Pirates")
    end
end)

local hasTeleportedToSky = false -- Flag to track if we've teleported to sky area
local TweenService = game:GetService("TweenService")
-- Bypass tweenTo: langsung set CFrame tanpa tween
local function bypassTween(part, cframe)
    part.CFrame = cframe
end
-- Ganti semua panggilan tweenTo menjadi bypassTween
local RunService = game:GetService("RunService")
local PlayerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local activeTween = nil -- Added missing variable declaration
local camera = workspace.CurrentCamera
local humanoid = character:FindFirstChildOfClass("Humanoid")
local lastPosition = nil
local lastMoveTime = tick()
local Backpack = game.Players.LocalPlayer.Backpack

-- Control variables
local isDead = false
local respawnCooldown = 0 -- seconds
local lastDeathTime = 0
local lastRaidTime = 0

if camera and humanoid then
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
end

-- Notification function
local function showCustomNotif(title, text)
    -- Remove old notification if exists
    local oldNotif = PlayerGui:FindFirstChild("CustomNotification")
    if oldNotif then oldNotif:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomNotification"
    screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(0.5, -150, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextStrokeTransparency = 0.7
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 24
    titleLabel.Text = title
    titleLabel.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.Position = UDim2.new(0, 0, 0.5, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.7
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextSize = 18
    textLabel.Text = text
    textLabel.Parent = frame
end

showCustomNotif("Gr0k3_Script", "Gr0k3_Script")

-- Redeem codes
local REDEEM_CODES = {
    "fudd10", "fudd10_V2", "Chandler", "BIGNEWS", "KITT_RESET",
    "Sub2UncleKizaru", "SUB2GAMERROBOT_RESET1", "Sub2Fer999", "Enyu_is_Pro",
    "JCWK", "StarcodeHEO", "MagicBUS", "KittGaming", "Sub2CaptainMaui",
    "Sub2OfficialNoobie", "TheGreatAce", "Sub2NoobMaster123", "Sub2Daigrock",
    "Axiore", "StrawHatMaine", "TantaiGaming", "Bluxxy", "SUB2GAMERROBOT_EXP1"
}

local fruitValues = {
    ["Spin-Spin"] = 7500,
    ["Chop-Chop"] = 8000,
    ["Spring-Spring"] = 25000,
    ["Bomb-Bomb"] = 30000,
    ["Smoke-Smoke"] = 50000,
    ["Spike-Spike"] = 60000,
    ["Flame-Flame"] = 75000,
    ["Falcon-Falcon"] = 80000,
    ["Ice-Ice"] = 90000,
    ["Sand-Sand"] = 85000,
    ["Dark-Dark"] = 100000,
    ["Diamond-Diamond"] = 130000,
    ["Light-Light"] = 120000,
    ["Rubber-Rubber"] = 110000,
    ["Barrier-Barrier"] = 70000,
    ["Ghost-Ghost"] = 75000,
    ["Magma-Magma"] = 130000,
    ["Quake-Quake"] = 120000,
    ["Love-Love"] = 150000,
    ["Spider-Spider"] = 170000,
    ["Sound-Sound"] = 190000,
    ["Phoenix-Phoenix"] = 200000,
    ["Portal-Portal"] = 1000000,
    ["Rumble-Rumble"] = 400000,
    ["Pain-Pain"] = 180000,
    ["Blizzard-Blizzard"] = 250000,
    ["Gravity-Gravity"] = 300000,
    ["Mammoth-Mammoth"] = 350000,
    ["T-Rex-T-Rex"] = 360000,
    ["Dough-Dough"] = 400000,
    ["Shadow-Shadow"] = 280000,
    ["Venom-Venom"] = 320000,
    ["Control-Control"] = 420000,
    ["Spirit-Spirit"] = 380000,
    ["Dragon-Dragon"] = 15000000,
    ["Leopard-Leopard"] = 2500000,
    ["Kitsune-Kitsune"] = 8000000,
}

local function getIslandCFrames()
    local success, result = pcall(function()
        return {
            workspace.Map.CircleIsland.RaidSummon2.MainRaid.CFrame,
            workspace.Map.CircleIsland.Island2.SpawnLocation.CFrame,
            workspace.Map.CircleIsland.Island3.SpawnLocation.CFrame,
            workspace.Map.CircleIsland.Island4.SpawnLocation.CFrame,
            workspace.Map.CircleIsland.Island5.SpawnLocation.CFrame,
        }
    end)
    return success and result or {}
end

-- Utility functions
local function getFruitValue(fruitName)
    return fruitValues[fruitName] or 0
end

local function redeemCodes()
    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Redeem")
    for _, code in ipairs(REDEEM_CODES) do
        local success, result = pcall(function()
            return remote:InvokeServer(code)
        end)
        if success then
            print("[INFO] Redeemed code: " .. code)
        else
            print("[WARNING] Failed to redeem code: " .. code .. " - " .. result)
        end
        task.wait(0.1)
    end
end

-- Auto Haki purchase
local beliHakiSudah = false
local MIN_BELI_HAKI = 25000

local function beliBusoHaki()
    if beliHakiSudah then return end
    local data = player:FindFirstChild("Data")
    local dataBeli = data and data:FindFirstChild("Beli")
    if not dataBeli then return end
    if dataBeli.Value >= MIN_BELI_HAKI then
        local ok, res = pcall(function()
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Buso")
        end)
        print("BuyHaki:", ok, res)
        if ok and (res == 1 or res == true) then
            beliHakiSudah = true
        else
            warn("Gagal beli Buso Haki:", res)
        end
    end
end

-- Buso activation
local function activateBuso()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end)
end

-- Movement functions
local function stopActiveTween()
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
end

local function tweenTo(cframe)
    if not character or not hrp then
        warn("[ERROR] Character or HRP not found")
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local originalSpeed

    if humanoid then
        humanoid.AutoRotate = false
        originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 0 -- stop walk/run animation
    end

    -- Remove old BodyVelocity if exists
    local oldBV = hrp:FindFirstChild("AutoVelocity")
    if oldBV then oldBV:Destroy() end

    -- Create new BodyVelocity
    local bv = Instance.new("BodyVelocity")
    bv.Name = "AutoVelocity"
    bv.MaxForce = Vector3.new(1, 1, 1) * 1e9
    bv.Velocity = Vector3.zero
    bv.P = 10000
    bv.Parent = hrp

    local reached = false
    local connection

    -- Target position + 5 studs offset upwards
    local targetPos = cframe.Position + Vector3.new(0, 5, 0)

    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local distance = (hrp.Position - targetPos).Magnitude
        if distance < 1 then
            reached = true
            bv.Velocity = Vector3.zero
            connection:Disconnect()
        else
            local direction = (targetPos - hrp.Position).Unit
            bv.Velocity = direction * 325
        end
    end)

    repeat task.wait() until reached
    bv:Destroy()

    if humanoid then
        humanoid.AutoRotate = true
        humanoid.WalkSpeed = originalSpeed or 16 -- restore normal speed
    end
end

-- NoClip
RunService.Stepped:Connect(function()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Combat functions
local function cariMusuh(namaMusuh)
    if not workspace:FindFirstChild("Enemies") then
        print("[WARNING] workspace.Enemies not found")
        return nil
    end

    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        if enemy.Name:lower():find(namaMusuh:lower()) and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            return enemy
        end
    end
    return nil
end

local function tarikSemuaMusuh()
    if not character or not hrp then
        print("[WARNING] Character or HRP not found")
        return
    end

    local targetPos = hrp.Position - Vector3.new(0, 30, 0)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then
        print("[WARNING] Enemies folder not found in workspace")
        return
    end

    for _, enemy in pairs(enemiesFolder:GetChildren()) do
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        if enemyHRP then
            local bodyPosition = Instance.new("BodyPosition")
            bodyPosition.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyPosition.Position = targetPos
            bodyPosition.P = 3000
            bodyPosition.D = 100
            bodyPosition.Parent = enemyHRP

            task.delay(2, function()
                if bodyPosition and bodyPosition.Parent then
                    bodyPosition:Destroy()
                end
            end)
        end
    end
end

local function serangMusuh(enemy, onKilled)
    local enemyHead = enemy:FindFirstChild("Head")
    local humanoid = enemy:FindFirstChild("Humanoid")
    if enemyHead and humanoid then
        tarikSemuaMusuh()
        local targetPos = enemyHead.Position + Vector3.new(0, 50, 0)
        local targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, hrp.CFrame.Rotation.Y, 0)
        
        tweenTo(targetCFrame)
        task.wait(0.01)
        
        local diedConn
        diedConn = humanoid.Died:Connect(function()
            diedConn:Disconnect()
            if onKilled then onKilled() end
        end)
        
        while enemy and humanoid.Health > 0 do
            local newPos = enemyHead.Position + Vector3.new(0, 30, 0)
            hrp.CFrame = CFrame.new(newPos) * CFrame.Angles(0, hrp.CFrame.Rotation.Y, 0)
            
            ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer(0.5)
            local targetPart = enemy:FindFirstChild("Head")
            if targetPart then
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(targetPart, {}, nil, "40763608")
            end
            task.wait(0.01)
        end
    end
end

-- Quest locations
local questLocations = {
    banditQuest = CFrame.new(1058.99231, 16.1369934, 1551.73328),
    spawnBandit = CFrame.new(974.83252, 16.6637402, 1549.89343, -0.754428506, -2.40687843e-08, 0.656382263, -3.70106363e-08, 1, -5.87019855e-09, -0.656382263, -2.87217699e-08, -0.754428506),
    adventurerQuest = CFrame.new(-1598.08899, 35.5500031, 153.378006),
    spawnMonkey = CFrame.new(-1812.14014, 23.1662636, 175.781586, 0.987128317, 0, 0.159930259, -0, 1, -0, -0.159930259, 0, 0.987128317),
    spawnGorilla = CFrame.new(-1277.40112, 6.53513145, -525.158203, 0.94795996, -2.47628709e-08, 0.318389535, 1.24504833e-08, 1, 4.07058316e-08, -0.318389535, -3.46233975e-08, 0.94795996),
    spawnGorillaKing = CFrame.new(-1091.20435, 6.71452713, -534.324341, 0.79231745, -2.62457558e-08, 0.610109031, -1.58773739e-09, 1, 4.50800535e-08, -0.610109031, -3.66864086e-08, 0.79231745),
    pirateQuest = CFrame.new(-1141.07495, 4.1000061, 3831.55005),
    spawnPirate = CFrame.new(-1183.90747, 5.06627464, 3865.84131, -0.974830806, -6.06302635e-08, 0.222945869, -7.81738621e-08, 1, -6.98646119e-08, -0.222945869, -8.55347224e-08, -0.974830806),
    spawnBrute = CFrame.new(-1265.14148, 15.1842632, 4235.27539, -0.357135236, 1.48908743e-08, -0.934052706, -5.1093977e-08, 1, 3.54780134e-08, 0.934052706, 6.03949175e-08, -0.357135236),
    spawnChef = CFrame.new(-1129.82458, 31.9290009, 4103.30078, -0.355795443, 5.40568692e-08, -0.934563875, -5.57308901e-08, 1, 7.9058978e-08, 0.934563875, 8.02128994e-08, -0.355795443),
    DesertAdventurerQuest = CFrame.new(894.489014, 5.13999939, 4392.43408, 0.819155693, 0, -0.573571265, 0, 1, 0, 0.573571265, 0, 0.819155693),
    spawnDesertBandit = CFrame.new(937.161377, 6.816782, 4480.01807, -0.0406585857, 1.4276381e-08, 0.999173105, -2.85458572e-08, 1, -1.54497908e-08, -0.999173105, -2.9150419e-08, -0.0406585857),
    spawnDesertOfficer = CFrame.new(1541.38, 14.8188658, 4388.90527, 0.301426411, 7.89662096e-08, -0.953489423, -6.62301458e-09, 1, 8.07243978e-08, 0.953489423, -1.80174915e-08, 0.301426411),
    villagerQuest = CFrame.new(1387.1886, 86.6210175, -1295.04456, -0.475204468, 0, 0.879875481, 0, 1, 0, -0.879875481, 0, -0.475204468),
    spawnSnowBandit = CFrame.new(1393.68384, 87.6397018, -1432.66577, 0.96290648, 1.07437819e-08, 0.269835293, 3.00778891e-09, 1, -5.05493603e-08, -0.269835293, 4.94859123e-08, 0.96290648),
    spawnSnowman = CFrame.new(1199.26782, 106.142906, -1439.76074, 0.243096024, 9.24429244e-08, 0.970002234, -9.90611859e-09, 1, -9.28191568e-08, -0.970002234, 1.29550104e-08, 0.243096024),
    spawnYeti = CFrame.new(1150.20776, 106.60273, -1511.29443, 0.909659147, 2.09939763e-08, 0.415355563, 2.46324543e-08, 1, -1.04491477e-07, -0.415355563, 1.05282851e-07, 0.909659147),
    marineQuest = CFrame.new(-5039.58594, 27.3500061, 4324.68018, -0.0253843069, -0, -0.999677837, 0, 1, -0, 0.999677837, 0, -0.0253843069),
    spawnChiefPetty = CFrame.new(-4889.86328, 21.0189533, 4083.02759, 0.983654439, 1.81624138e-08, -0.180066437, -2.81177326e-09, 1, 8.55051141e-08, 0.180066437, -8.36011793e-08, 0.983654439),
    spawnViceAdmiral = CFrame.new(-5086.47656, 99.6870346, 4406.73633, -0.944283128, 7.4285289e-08, 0.329134285, 5.68611931e-08, 1, -6.25648013e-08, -0.329134285, -4.03639184e-08, -0.944283128),
    skyadventurerQuest = CFrame.new(-4839.52979, 716.369019, -2619.44189, 0.972022355, 0, 0.234888479, 0, 1, 0, -0.234888479, 0, 0.972022355),
    spawnSkyBandit = CFrame.new(-4940.17627, 278.100952, -2841.86206, 0.42414704, 0, 0.905593336, -0, 1.00000012, -0, -0.905593455, 0, 0.42414698),
    spawnDarkMaster = CFrame.new(-5229.21436, 388.687012, -2251.19995, -0.967216611, -0, -0.25395298, -0, 1.00000012, -0, 0.25395298, 0, -0.967216611),
    jailkeeperQuest = CFrame.new(5310.60498, 0.350006104, 474.946991, 0.373947144, 0, 0.92745018, 0, 1, 0, -0.92745018, 0, 0.373947144),
    spawnPrisoner = CFrame.new(5215.87305, 1.66576385, 377.900452, 0.780110538, 0, 0.625641704, -0, 1, -0, -0.625641704, 0, 0.780110538),
    spawnDangerousPrisoner = CFrame.new(5060.83008, 1.68623841, 1036.71082, -0.22944288, -0, -0.973322093, -0, 1, -0, 0.973322213, 0, -0.22944285),
    colosseumQuest = CFrame.new(-1580.047, 6.3500061, -2986.4751, -0.460947275, -0, -0.887427449, 0, 1, -0, 0.887427449, 0, -0.460947275),
    spawnToga = CFrame.new(-1758.77527, 7.47754288, -2778.8811, -0.0162689853, -0, -0.999867737, -0, 1.00000012, -0, 0.999867737, 0, -0.0162689853),
    spawnGladiator = CFrame.new(-1336.29822, 7.40954971, -3518.02734, -0.924333453, 0, 0.381585747, 0, 1, -0, -0.381585747, 0, -0.924333453),
    themayorQuest = CFrame.new(-5313.37012, 10.9499969, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469),
    spawnMilitarySoldier = CFrame.new(-5580.53564, 8.90534782, 8438.72461, -0.316637725, 0, 0.948546588, 0, 1.00000012, -0, -0.948546588, 0, -0.316637725),
    spawnMilitarySpy = CFrame.new(-5832.50195, 77.5662613, 8897.02832, 0.70166105, 0, -0.712510884, -0, 1, -0, 0.712510943, 0, 0.701660991),
    spawnMagmaAdmiral = CFrame.new(-5693.84424, 17.7410927, 8744.93066, 0.780046701, 4.54188076e-10, 0.625721276, -5.82540016e-10, 1, 3.52154747e-13, -0.625721276, -3.64782399e-10, 0.780046701),
    kingneptuneQuest = CFrame.new(61121.1094, 17.9530029, 1564.526, -0.95208931, 0, 0.305820376, 0, 1, 0, -0.305820376, 0, -0.95208931),
    spawnFishmanWarrior = CFrame.new(60840.9023, 17.1697235, 1301.12561, -0.859312057, 0, -0.511451602, 0, 1, 0, 0.511451602, 0, -0.859312057),
    spawnFishmanCommando = CFrame.new(61858.9062, 17.330492, 1695.12585, 0.69767791, 0, 0.716411531, 0, 1, 0, -0.716411531, 0, 0.69767791),
    spawnFishmanLord = CFrame.new(61352.9023, 32.3587723, 1029.12549, -0.999911666, 0, -0.0132932952, 0, 1, 0, 0.0132932952, 0, -0.999911666),
    moleQuestindex1 = CFrame.new(-4721.88916, 843.875, -1949.96594, 0.996191859, 0, -0.0871884301, 0, 1, 0, 0.0871884301, 0, 0.996191859),
    moleQuestindex2dan3 = CFrame.new(-7859.09814, 5544.18994, -381.476013, -0.348013401, 0, 0.937489688, 0, 1, 0, -0.937489688, 0, -0.348013401),
    spawnGodGuard = CFrame.new(-4700.31494, 842.974915, -1792.79773, 0.978144467, 0, 0.207926437, 0, 1, 0, -0.207926437, 0, 0.978144467),
    spawnShanda = CFrame.new(-7710.76562, 5544.19092, -336.445465, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    spawnWysper = CFrame.new(-7995.29688, 5544.76074, -709.273804, -0.0871314928, 0, -0.996196806, 0, 1, 0, 0.996196806, 0, -0.0871314928),
    skyquestgiver2 = CFrame.new(-7904.68506, 5634.66113, -1409.96704, 0.993162751, 0, 0.116737984, 0, 1, 0, -0.116737984, 0, 0.993162751),
    spawnRoyalSquad = CFrame.new(-7513.94873, 5605.57617, -1421.01245, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469),
    spawnRoyalSoldier = CFrame.new(-7946.94922, 5606.22607, -1824.01257, -0.173624292, 0, -0.984811962, 0, 1, 0, 0.984811962, 0, -0.173624292),
    spawnThunderGod = CFrame.new(-7779.26123, 5606.93701, -2421.94995, -0.996191859, 0, 0.0871884301, 0, 1, 0, -0.0871884301, 0, -0.996191859),
    freezeburgQuest = CFrame.new(5259.81982, 37.3500061, 4050.02905, -0.559458017, 0, 0.828858733, 0, 1, 0, -0.828858733, 0, -0.559458017),
    spawnGalleyPirate = CFrame.new(5838.07324, 37.365654, 3914.32227, -0.90629667, 0, 0.422642112, 0, 1, 0, -0.422642112, 0, -0.90629667),
    spawnGalleyCaptain = CFrame.new(5792.354, 58.9349976, 4823.92285, -0.939700961, 0, -0.341998369, 0, 1, 0, 0.341998369, 0, -0.939700961),
    spawnCyborg = CFrame.new(6216.625, 8.33799744, 3990.00391, 0.173624337, 0, 0.984811902, 0, 1, 0, -0.984811902, 0, 0.173624337),
    pintuMasukKingNeptune = CFrame.new(4050.31104, -1.68800354, -1814.12402, 0.0700715333, 0, 0.997539878, 0, 1, 0, -0.997542977, 0, 0.0700711384),
    pintuKeluarKingNeptune = CFrame.new(61170.0469, -2, 1952.83398, -0.303610444, 0, 0.952796161, 0, 1, 0, -0.952799857, 0, -0.303613931),
    area1QuestGiver = CFrame.new(-429.544006, 71.7700043, 1836.18201, -0.230981946, -0, -0.972958326, 0, 1, -0, 0.972958326, 0, -0.230981946),
    spawnRaider = CFrame.new(-700.493469, 39.4542732, 2289.63135, 0.99999994, 0, 0, 0, 1, 0, 0, 0, 0.99999994),
    spawnMercenary = CFrame.new(-1042.69775, 73.2742538, 1443.08301, 0.99999994, 0, 0, 0, 1, 0, 0, 0, 0.99999994),
    spawnDiamond = CFrame.new(-1711.37097, 199.231522, -97.082077, -0.694649816, 0, -0.719348073, 0, 1, 0, 0.719348073, 0, -0.694649816),
    area2QuestGiver = CFrame.new(638.445007, 71.7700043, 918.236023, 0.319999993, 0, 0.947417617, 0, 1, 0, -0.947417617, 0, 0.319999993),
    spawnSwanPirate = CFrame.new(1029.53748, 73.3842773, 1128.61084, 0.982314885, 0, 0.187236786, -0, 1, -0, -0.187236801, 0, 0.982314765),
    spawnFactory = CFrame.new(-198.384384, 73.2742691, -655.226624, -0.154084623, -0, -0.988057673, -0, 1, -0, 0.988057673, 0, -0.154084623),
    spawnJeremy = CFrame.new(2352.5603, 449.245209, 645.60675, 0.251757473, 0, 0.967790425, -0, 1.00000012, -0, -0.967790425, 0, 0.251757473),
    marineQuestGiver = CFrame.new(-2440.7959, 71.7140045, -3216.06812, 0.670647144, 0, 0.741776526, 0, 1, 0, -0.741776526, 0, 0.670647144),
    spawnMarineLieutenant = CFrame.new(-2868.32007, 73.2804108, -2987.87695, 0.812500179, 0, -0.582961023, -0, 1.00000012, -0, 0.582961023, 0, 0.812500179),
    spawnMarineCaptain = CFrame.new(-1762.54504, 100.592926, -3173.36499, -0.996079266, -0, -0.0884659439, -0, 1.00000012, -0, 0.0884659439, 0, -0.996079266),
    spawnOrbitus = CFrame.new(-2087.04297, 73.2917862, -4170.99072, 0.310393035, 0, 0.950608313, -0, 1, -0, -0.950608313, 0, 0.310393035),
    graveyardQuestGiver = CFrame.new(-5497.06201, 47.5919952, -795.237, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146),
    spawnZombie = CFrame.new(-5614.95947, 47.3545113, -938.469177, 0.342042685, 0, -0.939684391, 0, 1, 0, 0.939684391, 0, 0.342042685),
    spawnVampire = CFrame.new(-5952.99512, 5.27639103, -1568.52808, -0.99255079, 0, -0.12183179, 0, 1, 0, 0.12183179, 0, -0.99255079),
    snowQuestGiver = CFrame.new(609.859009, 400.119995, -5372.25879, -0.374604106, 0, 0.927184999, 0, 1, 0, -0.927184999, 0, -0.374604106),
    spawnSnowTrooper = CFrame.new(642.664368, 400.295349, -5454.49072, 0.707134247, 0, 0.707079291, 0, 1, 0, -0.707079291, 0, 0.707134247),
    spawnWinterWarrior = CFrame.new(1446.27026, 428.295349, -5369.21338, -0.642763495, 0, 0.766064644, 0, 1, 0, -0.766064644, 0, -0.642763495),
    iceQuestGiver = CFrame.new(-6064.06885, 15.2420044, -4902.979, 0.453972578, 0, -0.891015649, 0, 1, 0, 0.891015649, 0, 0.453972578),
    spawnLab = CFrame.new(-5640.38965, 14.8250189, -4680.93994, -0.601813972, 0, 0.798636317, 0, 1, 0, -0.798636317, 0, -0.601813972),
    spawnHorned = CFrame.new(-6398.37891, 28.4234943, -5866.41113, -0.996390641, 0, 0.0848869234, 0, 1.00000012, -0, -0.0848869234, 0, -0.996390641),
    spawnSmokeAdmiral = CFrame.new(-5019.80713, 22.9609489, -5370.59619, -0.29242146, 0, 0.95628953, 0, 1, 0, -0.95628953, 0, -0.29242146),
    fireQuestGiver = CFrame.new(-5428.03223, 15.0619965, -5299.43506, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213),
    spawnMagmaNinja = CFrame.new(-5203.0459, 23.1334648, -6196.55322, 0.485845178, 0, -0.874044895, -0, 1.00000012, -0, 0.874045014, 0, 0.485845119),
    spawnLavaPirate = CFrame.new(-5265.24463, 14.8250189, -4341.92383, 0.74314785, 0, 0.669127226, 0, 1, 0, -0.669127226, 0, 0.74314785),
    rearQuestGiver = CFrame.new(1040.55542, 124.943008, 32909.1055, -0.344175458, 0, 0.938905537, 0, 1, 0, -0.938905537, 0, -0.344175458),
    spawnShipDeck = CFrame.new(580.312805, 123.93042, 33124.2656, 0.707134247, 0, -0.707079291, 0, 1, 0, 0.707079291, 0, 0.707134247),
    spawnShipEngineer = CFrame.new(1025.65674, 38.9304276, 32740.8594, 0.422592968, 0, 0.906319559, 0, 1, 0, -0.906319559, 0, 0.422592968),
    FrontQuestGiver = CFrame.new(974.075989, 124.955002, 33253.6211, -1.1920929e-07, -1.60054265e-38, -0.99999994, 7.38711301e-39, 1, -1.60054293e-38, 0.99999994, -7.38711581e-39, -1.1920929e-07),
    spawnShipSteward = CFrame.new(801.375366, 124.05941, 33505.1719, -0.00170850754, 0, -0.999998569, 0, 1, 0, 0.999998569, 0, -0.00170850754),
    spawnShipOfficer = CFrame.new(1144.53174, 179.931412, 33112.6094, -0.984812498, 0, -0.173621133, 0, 1, 0, 0.173621133, 0, -0.984812498),
    FrostQuestGiver = CFrame.new(5667.6582, 26.8000031, -6486.08984, -0.93358767, 0, -0.358349651, 0, 1, 0, 0.358349651, 0, -0.93358767),
    spawnArcticWarrior = CFrame.new(6271.31543, 26.8892612, -6151.53809, 0.656062782, 0, 0.754706323, 0, 1, 0, -0.754706323, 0, 0.656062782),
    spawnSnowLurker = CFrame.new(5763.84668, 27.1630821, -6671.04639, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685),
    spawnAwakenedIceAdmiral = CFrame.new(6551.7959, 320.829346, -6989.89795, -0.544830263, 0, 0.838546336, 0, 1, 0, -0.838546336, 0, -0.544830263),
    forgottenQuestGiver = CFrame.new(-3054.44507, 238.343994, -10142.8193, 0.990270376, -0, -0.139156565, 0, 1, -0, 0.139156565, 0, 0.990270376),
    spawnSeaSoldier = CFrame.new(-2550.9231, 25.8416176, -9839.99707, -0.9510414, 0, 0.309063554, 0, 1, 0, -0.309063554, 0, -0.9510414),
    spawnWaterFighter = CFrame.new(-3331.70483, 237.719971, -10553.3564, -0.29242146, 0, 0.95628953, 0, 1, 0, -0.95628953, 0, -0.29242146),
    spawnTideKeeper = CFrame.new(-3795.94678, 76.5251083, -11581.7803, -0.372312933, 7.38784252e-08, 0.928107262, 4.7038955e-09, 1, -7.77141906e-08, -0.928107262, -2.45682781e-08, -0.372312933),
}

-- Quest spawn locations
local questSpawns = {
    ["Toga Warrior"] = {
        questLocations.spawnToga,
        CFrame.new(-2020.10413, 7.60335493, -2700.86304, -0.332056165, 1.15881015e-07, 0.943259597, 5.13338039e-09, 1, -1.21044565e-07, -0.943259597, -3.53514835e-08, -0.332056165),
        CFrame.new(-2089.38794, 7.75676537, -2849.77344, 0.296399236, 0, 0.955064178, -0, 1.00000012, -0, -0.955064178, 0, 0.296399236)
    },
    ["Gladiator"] = {
        questLocations.spawnGladiator,
        CFrame.new(-1446.98962, 7.75676489, -3185.14868, 0.489073187, 0, 0.872242749, -0, 1, -0, -0.872242749, 0, 0.489073187),
        CFrame.new(-1117.43396, 7.60376549, -3286.27173, 0.0766213834, 0, 0.997060239, -0, 1.00000012, -0, -0.997060359, 0, 0.076621376)
    },
    ["Raider"] = {
        questLocations.spawnRaider,
        CFrame.new(-701.988403, 39.4542732, 2358.73218, -0.824941039, -0, -0.565218925, -0, 1.00000012, -0, 0.565218985, 0, -0.82494092),
        CFrame.new(311.721893, 39.4555817, 2295.78955, 0.901167929, 0, -0.433470309, -0, 1.00000012, -0, 0.433470309, 0, 0.901167929)   
    },
    ["Mercenary"] = {
        questLocations.spawnMercenary,
        CFrame.new(-932.052795, 73.2742538, 1659.31433, 0.490336567, 0, 0.871533155, -0, 1, -0, -0.871533275, 0, 0.490336508),
        CFrame.new(-1103.93408, 73.2742615, 1174.63745, 0.885018885, 0, 0.465555161, -0, 1, -0, -0.465555161, 0, 0.885018885)
    },
    ["Factory"] = {
        questLocations.spawnFactory,
        CFrame.new(-198.384384, 73.2742691, -655.226624, -0.154084623, -0, -0.988057673, -0, 1, -0, 0.988057673, 0, -0.154084623),
        CFrame.new(-250.743546, 73.2742691, -52.8167305, 0.790497422, 0, 0.612465382, -0, 1, -0, -0.612465382, 0, 0.790497422)
    }
}

-- Quest functions
local function ambilQuestBandit()
    tweenTo(questLocations.banditQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BanditQuest1", 1)
    tweenTo(questLocations.spawnBandit)
end

local function ambilQuestAdventurer(index)
    tweenTo(questLocations.adventurerQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "JungleQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnMonkey)
    elseif index == 2 then
        tweenTo(questLocations.spawnGorilla)
    else
        tweenTo(questLocations.spawnGorillaKing)
    end
end

local function ambilQuestPirate(index)
    tweenTo(questLocations.pirateQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BuggyQuest1", index)
    if index == 1 then
        tweenTo(questLocations.spawnPirate)
    elseif index == 2 then
        tweenTo(questLocations.spawnBrute)
    else
        tweenTo(questLocations.spawnChef)
    end
end

local function ambilQuestDesert(index)
    tweenTo(questLocations.DesertAdventurerQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "DesertQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnDesertBandit)
    else
        tweenTo(questLocations.spawnDesertOfficer)
    end
end

local function ambilQuestVillager(index)
    tweenTo(questLocations.villagerQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "SnowQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnSnowBandit)
    elseif index == 2 then
        tweenTo(questLocations.spawnSnowman)
    else
        tweenTo(questLocations.spawnYeti)
    end
end

local function ambilQuestMarine(index)
    tweenTo(questLocations.marineQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "MarineQuest2", index)
    if index == 1 then
        tweenTo(questLocations.spawnChiefPetty)
    else
        tweenTo(questLocations.spawnViceAdmiral)
    end
end

local function ambilQuestSkyAdventurer(index)
    tweenTo(questLocations.skyadventurerQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "SkyQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnSkyBandit)
    else
        tweenTo(questLocations.spawnDarkMaster)
    end
end

local function ambilQuestJailKeeper(index)
    tweenTo(questLocations.jailkeeperQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "PrisonerQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnPrisoner)
    else
        tweenTo(questLocations.spawnDangerousPrisoner)
    end
end

local function ambilQuestColosseum(index)
    tweenTo(questLocations.colosseumQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "ColosseumQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnToga)
    else
        tweenTo(questLocations.spawnGladiator)
    end
end

local function ambilQuestTheMayor(index)
    tweenTo(questLocations.themayorQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "MagmaQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnMilitarySoldier)
    elseif index == 2 then
        tweenTo(questLocations.spawnMilitarySpy)
    else
        tweenTo(questLocations.spawnMagmaAdmiral)
    end
end

local sudahMasuk = false

local function ambilQuestKingNeptune(index)
    if not sudahMasuk then
        tweenTo(questLocations.pintuMasukKingNeptune)
        task.wait(1.5)
        sudahMasuk = true
    end

    tweenTo(questLocations.kingneptuneQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "FishmanQuest", index)

    if index == 1 then
        tweenTo(questLocations.spawnFishmanWarrior)
    elseif index == 2 then
        tweenTo(questLocations.spawnFishmanCommando)
    else
        tweenTo(questLocations.spawnFishmanLord)
    end
end

local sudahTeleportMole = false

local function ambilQuestMole(index)
    if player:WaitForChild("Data"):WaitForChild("Level").Value >= 450 and not hasTeleportedToSky then
        local targetCFrame = workspace.Map.SkyArea1:GetChildren()[13].CFrame
        hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)
        hasTeleportedToSky = true
        task.wait(1)
    end

    if index ~= 1 and index ~= 2 and index ~= 3 then
        warn("[ERROR] Index untuk ambilQuestMole harus 1, 2, atau 3. Index yang diberikan:", index)
        return
    end

    if index == 1 then
        tweenTo(questLocations.moleQuestindex1)
    else
        tweenTo(questLocations.moleQuestindex2dan3)
    end

    task.wait(0.01)

    local success, result = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "SkyExp1Quest", index)
    end)

    if not success then
        warn("[ERROR] Gagal memulai quest Mole. Error:", result)
        return
    end

    if index == 1 then
        tweenTo(questLocations.spawnGodGuard)
    elseif index == 2 then
        tweenTo(questLocations.spawnShanda)
    elseif index == 3 then
        tweenTo(questLocations.spawnWysper)
    end
end

local function ambilQuestSky2(index)
    tweenTo(questLocations.skyquestgiver2)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "SkyExp2Quest", index)
    if index == 1 then
        tweenTo(questLocations.spawnRoyalSquad)
    elseif index == 2 then
        tweenTo(questLocations.spawnRoyalSoldier)
    else
        tweenTo(questLocations.spawnThunderGod)
    end
end

local function ambilQuestFreezeburg(index)
    tweenTo(questLocations.freezeburgQuest)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "FountainQuest", index)
    if index == 1 then
        tweenTo(questLocations.spawnGalleyPirate)
    elseif index == 2 then
        tweenTo(questLocations.spawnGalleyCaptain)
    else
        tweenTo(questLocations.spawnCyborg)
    end
end

local function ambilQuestArea1Giver(index)
    tweenTo(questLocations.area1QuestGiver)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "Area1Quest", index)
    if index == 1 then
        tweenTo(questLocations.spawnRaider)
    elseif index == 2 then
        tweenTo(questLocations.spawnMercenary)
    else
        tweenTo(questLocations.spawnDiamond)
    end
end

local function ambilQuestArea2Giver(index)
    tweenTo(questLocations.area2QuestGiver)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "Area2Quest", index)
    if index == 1 then
        tweenTo(questLocations.spawnSwanPirate)
    elseif index == 2 then
        tweenTo(questLocations.spawnFactory)
    else
        tweenTo(questLocations.spawnJeremy)
    end
end

local function ambilQuestMarineGiver(index)
    tweenTo(questLocations.marineQuestGiver)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "MarineQuest3", index)
    if index == 1 then
        tweenTo(questLocations.spawnMarineLieutenant)
    elseif index == 2 then
        tweenTo(questLocations.spawnMarineCaptain)
    else
        tweenTo(questLocations.spawnOrbitus)
    end
end

local function ambilQuestGraveyard(index)
    tweenTo(questLocations.graveyardQuestGiver)
    task.wait(0.01)
    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "ZombieQuest", index)
   if index == 1 then
    tweenTo(questLocations.spawnZombie)
   else
    tweenTo(questLocations.spawnVampire)
   end
end

local function ambilQuestSnowQuestGiver(index)
     tweenTo(questLocations.snowQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "SnowMountainQuest", index)
   if index == 1 then
     tweenTo(questLocations.spawnSnowTrooper)
   else
     tweenTo(questLocations.spawnWinterWarrior)
   end
end

local function ambilQuestIceQuestGiver(index)
     tweenTo(questLocations.iceQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "IceSideQuest", index)
   if index == 1 then
     tweenTo(questLocations.spawnLab)
   elseif index == 2 then
     tweenTo(questLocations.spawnHorned)
   else
     tweenTo(questLocations.spawnSmokeAdmiral)
   end
end

local function ambilQuestFire(index)
     tweenTo(questLocations.fireQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "FireSideQuest", index)
   if index == 1 then
     tweenTo(questLocations.spawnMagmaNinja)
   else
     tweenTo(questLocations.spawnLavaPirate)
   end
end

local function ambilQuestRearCrew(index)
     tweenTo(questLocations.rearQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", " ShipQuest1", index)
   if index == 1 then
     tweenTo(questLocations.spawnShipDeck)
   else
     tweenTo(questLocations.spawnShipEngineer)
   end
end

local function ambilQuestFrontCrew(index)
     tweenTo(questLocations.FrontQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "ShipQuest2", index)
   if index == 1 then
     tweenTo(questLocations.spawnShipSteward)
   else
     tweenTo(questLocations.spawnShipOfficer)
   end
end

local function ambilQuestFrost(index)
     tweenTo(questLocations.FrostQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "FrostQuest", index)
   if index == 1 then
     tweenTo(questLocations.spawnArcticWarrior)
   elseif index == 2 then
     tweenTo(questLocations.spawnSnowLurker)
   else
     tweenTo(questLocations.spawnAwakenedIceAdmiral)
   end
end

local function ambilQuestForgotten(index)
     tweenTo(questLocations.forgottenQuestGiver)
     task.wait(0.01)
     ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "ForgottenQuest", index)
   if index == 1 then
     tweenTo(questLocations.spawnSeaSoldier)
   elseif index == 2 then
     tweenTo(questLocations.spawnWaterFighter)
   else
     tweenTo(questLocations.spawnTideKeeper)
   end
end

-- Auto stat upgrade
local function tambahStatOtomatis()
    while true do
        local stats = player:FindFirstChild("Data") and player.Data:FindFirstChild("Stats")
        if not stats then return end

        local melee = stats:FindFirstChild("Melee")
        local defense = stats:FindFirstChild("Defense")
        if not (melee and defense) then return end

        local meleeLevel = melee:FindFirstChild("Level")
        local defenseLevel = defense:FindFirstChild("Level")
        if not (meleeLevel and defenseLevel) then return end

        if meleeLevel.Value >= 200 and defenseLevel.Value < meleeLevel.Value - 100 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Defense", 50)
        else
            ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Melee", 50)
        end

        task.wait(0.5)
    end
end

-- Fighting styles
local fightingStyles = {
    {
        name = "Dark Step",
        costType = "Beli",
        cost = 150000,
        requiredMastery = 0,
        path = "Black Leg",
        buyFunction = function() 
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg") 
        end
    },
    {
        name = "Electro",
        costType = "Beli",
        cost = 500000,
        requiredMastery = 400,
        path = "Electro",
        buyFunction = function() 
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro") 
        end
    },
    {
        name = "Fishman Karate",
        costType = "Beli",
        cost = 750000,
        requiredMastery = 400,
        path = "Fishman Karate",
        buyFunction = function() 
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate") 
        end
    },
    {
        name = "Dragon Breath",
        costType = "Fragment",
        cost = 1500,
        requiredMastery = 400,
        path = "Dragon Breath",
        buyFunction = function() 
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward","DragonClaw","1") 
        end
    },
    {
        name = "Superhuman",
        costType = "Beli",
        cost = 3000000,
        requiredMastery = 400,
        path = "Superhuman",
        buyFunction = function() 
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman") 
        end
    }
}

local function autoBuyFightingStylesNoCheck()
    for i = #fightingStyles, 1, -1 do
        local style = fightingStyles[i]
        local ok, res = pcall(style.buyFunction)
        print("[AUTO BUY NO CHECK] Try buy:", style.name, ok, res)
        -- stop buying lower styles if this one was successfully acquired
        if ok and (player.Backpack:FindFirstChild(style.path) or player.Character:FindFirstChild(style.path)) then
            break
        end
    end
end


local function getMastery(stylePath)
    local char = player.Character or player.CharacterAdded:Wait()
    if char:FindFirstChild(stylePath) then
        return char[stylePath].Level.Value
    end
    return 0
end

local function getFragments()
    return player.Data.Fragments.Value
end

local function getBeli()
    return player.Data.Beli.Value
end

local function equipBestFightingStyle()
    -- Autobuy all fighting styles without mastery/cost checks
    pcall(autoBuyFightingStylesNoCheck)

    local priorityOrder = {"Superhuman", "Dragon Breath", "Fishman Karate", "Electro", "Black Leg", "Combat"}
    for _, styleName in ipairs(priorityOrder) do
        local style = player.Backpack:FindFirstChild(styleName) or player.Character:FindFirstChild(styleName)
        if style then
            style.Parent = player.Character
            print("[INFO] Equipped fighting style: " .. styleName)
            return
        end
    end
    
    local combat = player.Backpack:FindFirstChild("Combat")
    if combat then
        combat.Parent = player.Character
    end
end

local function waitForCharacter()
    while not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") do
        task.wait(1)
    end
    return player.Character
end

-- CharacterAdded modification
player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    lastPosition = nil
    lastMoveTime = tick() -- must be tick()
    task.delay(0.5, function()
    end)
end)

-- Initial setup
task.spawn(function()
    task.wait(0.1)
    equipBestFightingStyle()
    activateBuso()
end)

-- Redeem codes
redeemCodes()

-- STATS
task.spawn(tambahStatOtomatis)

task.spawn(function()
    while true do
        pcall(beliBusoHaki) -- auto-buy buso haki
        local success, result = pcall(function()
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Check")
        end)

        print("Cousin Check:", success, result)
        if success and result then
            local buySuccess, buyResult = pcall(function()
                return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
            end)
            print("Cousin Buy:", buySuccess, buyResult)

            task.wait(1)

            for _, tool in ipairs(player.Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:find("Fruit") then
                    local fruitName = tool.Name:gsub(" Fruit", "")
                    local value = getFruitValue(fruitName)

                    if value < 1000000 then
                        local storeSuccess, storeResult = pcall(function()
                            return ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName, tool)
                        end)
                        if storeSuccess then
                            print("✅ Stored low value fruit:", fruitName)
                        else
                            warn("❌ Gagal store:", fruitName, storeResult)
                        end
                    else
                        print("ℹ️ Skip storing fruit:", fruitName, "with value:", value)
                    end
                end
            end
        end

        task.wait(600)
    end
end)

-- Main game functions
local sudahUnlockSea2 = isSecondSea or isThirdSea -- Set true if already in Sea 2 or 3

local function getLowValueFruit()
    local backpack = player:WaitForChild("Backpack")
    for _, item in pairs(backpack:GetChildren()) do
        local fruitName = item.Name
        local value = fruitValues[fruitName]
        if value and value < 1000000 then
            return fruitName
        end
    end
    return nil
end

-- Fungsi utama auto raid
local function autoRaid()
    print("🚨 Memulai Auto Raid...")

    local fruitName = getLowValueFruit()

    if fruitName then
        print("🪙 Pakai buah:", fruitName)
        local args = {"RaidsNpc", "Select", fruitName}
        ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
    else
        print("🔑 Pakai microchip (Flame)")
        local args = {"RaidsNpc", "Select", "Flame"}
        ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
    end

    task.wait(1)

    local detector = workspace.Map.CircleIsland.RaidSummon.Button.Main:FindFirstChild("ClickDetector")
    if detector then
        fireclickdetector(detector)
        print("✅ Raid sudah dimulai, masuk ke pulau...")
    else
        warn("❌ ClickDetector tidak ditemukan!")
        return
    end

    local islandCFrames = getIslandCFrames()
    for i, islandCFrame in ipairs(islandCFrames) do
        print("🚶 Melangkah ke Island " .. i)
        tweenTo(islandCFrame)

        print("⚔️ Mencari musuh di Island " .. i)
        while true do
            local enemy = cariMusuh()
            if enemy then
                serangMusuh(enemy)
                task.wait(0.5)
            else
                print("🏝️ Island " .. i .. " bersih, lanjut ke island berikutnya")
                break
            end
        end
    end

    print("🎉 Raid selesai!")
end

local function equipItem(namaItem)
    local backpack = player.Backpack
    local item = backpack:FindFirstChild(namaItem)
    if item then
        player.Character.Humanoid:EquipTool(item)
    end
end

local function isQuestActive()
    local success, result = pcall(function()
        return player.PlayerGui.Main.Quest.Visible
    end)
    return success and result
end

local function checkMovement()
    local currentPos = hrp.Position
    if lastPosition then
        if (currentPos - lastPosition).Magnitude > 5 then
            lastMoveTime = tick()
        end
    end
    lastPosition = currentPos

    if tick() - lastMoveTime > 10 then
        print("[WARNING] Character idle for more than 10 seconds, restarting loop...")
        return true
    end
    return false
end

local function memilikiItem(namaItem)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remote = ReplicatedStorage.Modules.Net["RF/ReadPlayerData"]
    
    local success, result = pcall(function()
        return remote:InvokeServer()
    end)
    
    if success and result and result.Items then
        return result.Items[namaItem] == true
    end
    return false
end

-- Special function for Bartilo quest
local function selesaikanQuestBartilo()
    local function ambilQuestBartilo(id)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", id)
    end

    local function remoteBartiloProgress()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo")
    end

    local function aktifkanTombolColosseum()
        local tombol = {
            CFrame.new(-1850.49304, 13.1790009, 1750.89697),
            CFrame.new(-1858.87305, 19.378006, 1712.01794),
            CFrame.new(-1803.94299, 16.5789948, 1750.89697),
            CFrame.new(-1858.55798, 16.8600006, 1724.79504),
            CFrame.new(-1869.54199, 15.9880066, 1681.00696),
            CFrame.new(-1800.09802, 16.4980011, 1684.52405),
            CFrame.new(-1819.26294, 14.7949982, 1717.90601),
            CFrame.new(-1813.51794, 14.8600006, 1724.79504),
        }
        for _, cf in ipairs(tombol) do
            tweenTo(cf)
            task.wait(0.5)
        end
    end

    print("Starting Bartilo quest...")

    -- Stage 1: Defeat 50 Swan Pirates
    ambilQuestBartilo(1)
    while isQuestActive() do
        local enemy = cariMusuh("Swan Pirate")
        if enemy then
            serangMusuh(enemy)
        else
            tweenTo(questLocations.spawnSwanPirate)
            task.wait(0.5)
        end
        task.wait(0.01)
    end

    -- Stage 2: Kill Jeremy
    print("Bartilo quest stage 2: Going to Jeremy's location...")
    tweenTo(questLocations.spawnJeremy)
    task.wait(1)
    
    local jeremyDefeated = false
    local startTime = os.time()
    
    while not jeremyDefeated and (os.time() - startTime < 60) do
        local jeremy = cariMusuh("Jeremy")
        if jeremy then
            serangMusuh(jeremy, function()
                jeremyDefeated = true
            end)
        else
            print("Looking for Jeremy...")
            tweenTo(questLocations.spawnJeremy)
            task.wait(0.5)
        end
        task.wait(0.01)
    end

    if jeremyDefeated then
        remoteBartiloProgress()
        
        -- Stage 3: Colosseum button puzzle
        aktifkanTombolColosseum()
        task.wait(1)
        
        -- Completion confirmation
        local success = pcall(remoteBartiloProgress)
        if success then
            showCustomNotif("SUCCESS", "Bartilo Quest Completed!")
            return true
        else
            warn("Failed to complete Bartilo quest")
        end
    else
        warn("Failed to defeat Jeremy within 60 seconds")
    end
    return false
end

-- Function for farming Factory Staff
local function farmingFactoryStaff()
    ambilQuestArea2Giver(2)
    local currentSpawnIndex = 1

    while isQuestActive() do
        local enemy = cariMusuh("Factory Staff")
        if not enemy then
            currentSpawnIndex = currentSpawnIndex + 1
            if currentSpawnIndex > #questSpawns["Factory"] then
                currentSpawnIndex = 1
            end
            print("Moving to Factory spawn point #"..currentSpawnIndex)
            tweenTo(questSpawns["Factory"][currentSpawnIndex])
            task.wait(0.5)
        else
            serangMusuh(enemy)
        end
        task.wait(0.01)
    end
end

-- Auto respawn function
local function autoRespawn()
    if isDead then return end
    isDead = true
    local deathTime = os.time()

    print("⛔ Karakter mati, memulai proses respawn...")

    local waitTime = respawnCooldown - (os.time() - deathTime)
    if waitTime > 0 then
        print("🕒 Menunggu "..waitTime.." detik sebelum respawn...")
        task.wait(waitTime)
    end

    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetSpawnPoint")
        player:LoadCharacter()
    end)

    repeat
        task.wait(0.01)
        local char = player.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
    until hrp

    print("✅ Karakter berhasil direspawn")

    local char = player.Character
    local humanoid = char:WaitForChild("Humanoid")
    isDead = false

    setupDeathDetection(humanoid)
    task.wait(1)
    equipBestFightingStyle()
    activateBuso()
end

function setupDeathDetection(humanoid)
    if humanoid then
        humanoid.Died:Connect(function()
            autoRespawn()
        end)
    end
end

player.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    isDead = false

    setupDeathDetection(humanoid)
    task.delay(0.5, function()
    end)
end)

-- Recovery system
local function recoverySystem()
    while true do
        task.wait(2)
        
        -- Check if character is not valid
        if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
            print("⚠️ Sistem recovery: Karakter tidak valid, memuat ulang...")
            player:LoadCharacter()
            character = player.Character or player.CharacterAdded:Wait()
            hrp = character:WaitForChild("HumanoidRootPart")
        end
        
        -- Check if character is stuck in dead state
        if character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0 and not isDead then
            print("⚠️ Sistem recovery: Terdeteksi karakter mati tapi tidak terdeteksi oleh sistem")
            autoRespawn()
        end
    end
end

-- Run recovery system in background
task.spawn(recoverySystem)

-- Main game loop
while true do
    local success, err = pcall(function()
        -- Skip if character is dead
        if isDead or (character and character.Humanoid and character.Humanoid.Health <= 0) then
            task.wait(0.01)
        else
            local level = player:WaitForChild("Data"):WaitForChild("Level").Value       
        
            if level >= 1100 and (isSecondSea or isThirdSea) and (tick() - lastRaidTime > 300) then
                lastRaidTime = tick()
                -- Beli chip "Flame" jika belum memiliki
                if not memilikiItem("Flame") then
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Buy", "Flame")
                    end)
                end
                autoRaid()
            end
               
            -- Level-based quests
            if isFirstSea then
                -- Logic for First Sea
                if level < 10 then
                    ambilQuestBandit()
                    while isQuestActive() do
                        local enemy = cariMusuh("Bandit")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 10 and level < 15 then
                    ambilQuestAdventurer(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Monkey")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 15 and level < 30 then
                    ambilQuestAdventurer(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Gorilla") or cariMusuh("The Gorilla King")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 30 and level < 40 then
                    ambilQuestPirate(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Pirate")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 40 and level < 60 then
                    ambilQuestPirate(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Brute") or cariMusuh("Chef")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 60 and level < 75 then
                    ambilQuestDesert(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Desert Bandit")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 75 and level < 90 then
                    ambilQuestDesert(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Desert Officer")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 90 and level < 100 then
                    ambilQuestVillager(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Snow Bandit")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 100 and level < 120 then
                    ambilQuestVillager(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Snowman") or cariMusuh("Yeti")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 120 and level < 150 then
                    ambilQuestMarine(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Chief Petty Officer") or cariMusuh("Vice Admiral")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 150 and level < 175 then
                    ambilQuestSkyAdventurer(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Sky Bandit")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 175 and level < 190 then
                    ambilQuestSkyAdventurer(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Dark Master")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 190 and level < 210 then
                    ambilQuestJailKeeper(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Prisoner")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 210 and level < 250 then
                    ambilQuestJailKeeper(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Dangerous Prisoner")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 250 and level < 300 then
                    -- Fase 1: ambil dan kill Toga Warrior
                    ambilQuestColosseum(1)
                    local idx = 1
                    while isQuestActive() do
                        local enemy = cariMusuh("Toga Warrior")
                        if not enemy then
                            idx = idx % #questSpawns["Toga Warrior"] + 1
                            tweenTo(questSpawns["Toga Warrior"][idx])
                            task.wait(0.5)
                        else
                            serangMusuh(enemy)
                        end
                        task.wait(0.1)
                    end

                    -- Fase 2: ambil dan kill Gladiator
                    ambilQuestColosseum(2)
                    idx = 1
                    while isQuestActive() do
                        local enemy = cariMusuh("Gladiator")
                        if not enemy then
                            idx = idx % #questSpawns["Gladiator"] + 1
                            tweenTo(questSpawns["Gladiator"][idx])
                            task.wait(0.5)
                        else
                            serangMusuh(enemy)
                        end
                        task.wait(0.1)
                    end
                elseif level >= 300 and level < 325 then
                    ambilQuestTheMayor(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Military Soldier")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 325 and level < 375 then
                    ambilQuestTheMayor(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Military Spy") or cariMusuh("Magma Admiral")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 375 and level < 400 then
                    ambilQuestKingNeptune(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Fishman Warrior")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 400 and level < 450 then
                    ambilQuestKingNeptune(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Fishman Commando") or cariMusuh("Fisman Lord")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 450 and level < 475 then
                    ambilQuestMole(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("God's Guard")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 475 and level < 525 then
                    ambilQuestMole(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Shanda") or cariMusuh("Wysper")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 525 and level < 550 then
                    ambilQuestSky2(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Royal Squad")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 550 and level < 625 then
                    ambilQuestSky2(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Royal Soldier") or cariMusuh("Thunder God")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 625 and level < 650 then
                    ambilQuestFreezeburg(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Galley Pirate")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 650 and level < 700 then
                    ambilQuestFreezeburg(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Galley Captain") or cariMusuh("Cyborg")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                              
                elseif level >= 700 and not sudahUnlockSea2 then
                    print("Starting Sea 2 unlock process...")
                    
                    -- 1. Go to Detective
                    local detektifCFrame = CFrame.new(4853.36182, 4.3500061, 717.710999)
                    tweenTo(detektifCFrame)
                    task.wait(2)
                    
                    -- 2. Request Key
                    local keySuccess, keyResult = pcall(function()
                        return ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Detective")
                    end)
                    
                    if not keySuccess then
                        warn("Failed to request key:", keyResult)
                        -- continue to attack Ice Admiral even if key request fails
                    end

                    -- 3. Wait and equip Key (if successfully obtained)
                    local key
                    local keyWaitTime = 0
                    while keyWaitTime < 2 do
                        key = player.Backpack:FindFirstChild("Key") or player.Character:FindFirstChild("Key")
                        if key then break end
                        task.wait(1)
                        keyWaitTime = keyWaitTime + 1
                        print("Waiting for Key...", keyWaitTime, "seconds")
                    end

                    if key then
                        if key.Parent == player.Backpack then
                            player.Character.Humanoid:EquipTool(key)
                            task.wait(1)
                        end
                    else
                        warn("Key not found after 10 seconds, proceeding to attack Ice Admiral without Key.")
                    end
                    
                    -- 4. Go to Ice Admiral
                    local iceAdmiralCFrame = CFrame.new(1344.547, 42.253006, -1327.88904)
                    tweenTo(iceAdmiralCFrame)
                    task.wait(0.5)
                    
                    -- 5. Attack Ice Admiral using existing function
                    local iceAdmiralDefeated = false
                    local battleStartTime = os.time()
                    
                    while os.time() - battleStartTime < 30 do
                        local enemy = cariMusuh("Ice Admiral") or cariMusuh("Ice Admiral [Lv. 700] [Boss]")
                        
                        if enemy then
                            equipBestFightingStyle()
                            serangMusuh(enemy, function()
                                iceAdmiralDefeated = true
                            end)
                            
                            if iceAdmiralDefeated then
                                break
                            end
                        else
                            print("Looking for Ice Admiral...")
                        end
                        task.wait(0.5)
                    end
                    
                    if iceAdmiralDefeated then
                        print("Successfully defeated Ice Admiral!")
                        task.wait(0.01)
                        
                        -- Force trigger completion dialog from Ice Admiral
                        pcall(function()
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress", "Ice Admiral")
                        end)
                        
                        -- 6. Return to Detective
                        tweenTo(detektifCFrame)
                        task.wait(0.5)
                        
                        -- 7. Report to Detective
                        local reportSuccess = pcall(function()
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Detective")
                        end)
                        
                        if reportSuccess then
                            sudahUnlockSea2 = true
                            print("Successfully unlocked Sea 2!")
                            
                            -- 8. Go to Experiment Captain
                            local captainCFrame = CFrame.new(-1163.06006, 6.74200439, 1727.85303)
                            tweenTo(captainCFrame)
                            task.wait(0.5)
                            
                            -- 9. Teleport to Sea 2
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress","Dressrosa")
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                        end
                    end
                end

            -- SECOND SEA
            elseif isSecondSea or isThirdSea then
                if level >= 700 and level < 725 then
                    ambilQuestArea1Giver(1)
                    local currentSpawnIndex = 1
                    while isQuestActive() do
                        local enemy = cariMusuh("Raider")
                        
                        if not enemy then
                            currentSpawnIndex = currentSpawnIndex + 1
                            if currentSpawnIndex > #questSpawns["Raider"] then
                                currentSpawnIndex = 1
                            end
                            
                            print("Moving to Raider spawn point #"..currentSpawnIndex)
                            tweenTo(questSpawns["Raider"][currentSpawnIndex])
                            task.wait(0.5)
                        else
                            serangMusuh(enemy)
                        end
                        task.wait(0.01)
                    end
                    
                elseif level >= 725 and level <= 775 then
                    ambilQuestArea1Giver(2)
                    local currentSpawnIndex = 1
                    
                    if level >= 750 then
                        local diamondEnemy = cariMusuh("Diamond")
                        if diamondEnemy then
                            ambilQuestArea1Giver(3)
                            while isQuestActive() do
                                diamondEnemy = cariMusuh("Diamond")
                                if diamondEnemy then
                                    serangMusuh(diamondEnemy)
                                else
                                    ambilQuestArea1Giver(2)
                                    break
                                end
                                task.wait(0.01)
                            end
                        end
                    end
                    
                    while isQuestActive() do
                        local enemy = cariMusuh("Mercenary")
                        
                        if not enemy then
                            currentSpawnIndex = currentSpawnIndex + 1
                            if currentSpawnIndex > #questSpawns["Mercenary"] then
                                currentSpawnIndex = 1
                            end
                            
                            print("Moving to Mercenary spawn point #"..currentSpawnIndex)
                            tweenTo(questSpawns["Mercenary"][currentSpawnIndex])
                            task.wait(0.5)
                        else
                            serangMusuh(enemy)
                        end
                        task.wait(0.01)
                    end

                elseif level >= 775 and level < 800 then
                    ambilQuestArea2Giver(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Swan Pirate")
                        if enemy then serangMusuh(enemy)
                        end
                        task.wait(0.01)
                    end
                    
                elseif level >= 800 and level <= 850 then
                    ambilQuestArea2Giver(2)
                    local currentSpawnIndex = 1

                    if level >= 825 then
                        local jeremyEnemy = cariMusuh("Jeremy")
                        if jeremyEnemy then
                            ambilQuestArea2Giver(3)
                            while isQuestActive() do
                                jeremyEnemy = cariMusuh("Jeremy")
                                if jeremyEnemy then
                                    serangMusuh(jeremyEnemy)
                                else
                                    ambilQuestArea2Giver(2)
                                    break
                                end
                                task.wait(0.01)
                            end
                        end
                    end

                    while isQuestActive() do
                        local enemy = cariMusuh("Factory Staff")
                        if not enemy then
                            currentSpawnIndex = currentSpawnIndex + 1
                            if currentSpawnIndex > #questSpawns["Factory"] then
                                currentSpawnIndex = 1
                            end
                            print("Moving to Factory spawn point #"..currentSpawnIndex)
                            tweenTo(questSpawns["Factory"][currentSpawnIndex])
                            task.wait(0.5)
                        else
                            serangMusuh(enemy)
                        end
                        task.wait(0.01)
                    end
                    
                elseif level >= 850 and level < 875 then
                    -- Check if already has Warrior Helmet
                    if memilikiItem("Warrior Helmet") then
                        farmingFactoryStaff()
                    else
                        -- If not, do Bartilo quest
                        if selesaikanQuestBartilo() then
                            -- After completing Bartilo quest, continue farming Factory Staff
                            farmingFactoryStaff()
                        else
                            -- If failed, try again
                            warn("Failed to complete Bartilo quest, trying again...")
                        end
                    end
                    
                elseif level >= 875 and level < 900 then
                    ambilQuestMarineGiver(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Marine Lieutenant")
                        if enemy then serangMusuh(enemy) 
                        end
                        task.wait(0.01)
                    end
                    
                elseif level >= 900 and level < 925 then
                    ambilQuestMarineGiver(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Marine Captain") or cariMusuh("Orbitus")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 925 and level < 950 then
                    ambilQuestGraveyard(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Zombie")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 950 and level < 975 then
                    ambilQuestGraveyard(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Vampire")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 975 and level < 1000 then
                    ambilQuestSnowQuestGiver(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Snow Trooper")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1000 and level < 1050 then
                    ambilQuestSnowQuestGiver(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Winter Warrior")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1050 and level < 1100 then
                    ambilQuestIceQuestGiver(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Lab Subordinate")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1100 and level < 1150 then
                    ambilQuestIceQuestGiver(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Horned Warrior")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1150 and level < 1200 then
                    ambilQuestIceQuestGiver(3)
                    while isQuestActive() do
                        local enemy = cariMusuh("Smoke Admiral")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1200 and level < 1250 then
                    ambilQuestFire(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Magma Ninja")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1250 and level < 1275 then
                    ambilQuestFire(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Lava Pirate")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1275 and level < 1300 then
                    ambilQuestRearCrew(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Ship Deckhand")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1300 and level < 1325 then
                    ambilQuestRearCrew(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Ship Engineer")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1325 and level < 1350 then
                    ambilQuestFrontCrew(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Ship Steward")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1350 and level < 1375 then
                    ambilQuestFrontCrew(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Ship Officer")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1375 and level < 1400 then
                    ambilQuestFrost(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Arctic Warrior")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1400 and level < 1425 then
                    ambilQuestFrost(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Snow Lurker")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1425 and level < 1450 then
                    ambilQuestFrost(3)
                    while isQuestActive() do
                        local enemy = cariMusuh("Awakened Ice Admiral")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1450 and level < 1475 then
                    ambilQuestForgotten(1)
                    while isQuestActive() do
                        local enemy = cariMusuh("Sea Soldier")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1475 and level < 1500 then
                    ambilQuestForgotten(2)
                    while isQuestActive() do
                        local enemy = cariMusuh("Water Fighter")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                    
                elseif level >= 1500 then
                    ambilQuestForgotten(3)
                    while isQuestActive() do
                        local enemy = cariMusuh("Tide Keeper")
                        if enemy then serangMusuh(enemy) end
                        task.wait(0.01)
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("[ERROR] Error occurred:", err)
    end
    task.wait(0.1)
end

-- Maintain character at height 50 studs while waiting (or always)
do
    local RunService = game:GetService("RunService")
    RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                hrp.CFrame = CFrame.new(pos.X, 50, pos.Z)
            end
        end
    end)
end


-- Resume farming on death/respawn
do
    local function onCharacter(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            print("[INFO] Character died, will resume farming after respawn.")
            -- Delay to allow respawn
            wait(5)
            -- Re-initialize player and character variables if needed
            player = game.Players.LocalPlayer
            -- Resume farming logic (e.g., start auto-farming or tweenTo last target)
            if typeof(startFarming) == "function" then
                startFarming()
            elseif typeof(autoFarm) == "function" then
                autoFarm()
            end
        end)
    end

    game.Players.LocalPlayer.CharacterAdded:Connect(onCharacter)
    if game.Players.LocalPlayer.Character then
        onCharacter(game.Players.LocalPlayer.Character)
    end
end