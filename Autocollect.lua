local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

local originalCFrame
local teleporting = false
local targets = {}

-- GUI作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCollectGui"
screenGui.Parent = PlayerGui

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, 200, 0, 80)
window.Position = UDim2.new(0.5, -100, 0.1, 0)
window.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
window.BorderSizePixel = 0
window.Parent = screenGui

local dragBar = Instance.new("TextButton")
dragBar.Name = "DragBar"
dragBar.Size = UDim2.new(1, 0, 0, 20)
dragBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dragBar.Text = "Auto Collect Gui"
dragBar.TextColor3 = Color3.new(1, 1, 1)
dragBar.Font = Enum.Font.SourceSansBold
dragBar.TextSize = 16
dragBar.Parent = window

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 0, 60)
toggleButton.Position = UDim2.new(0, 0, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
toggleButton.Text = "OFF"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 24
toggleButton.Parent = window

-- ドラッグ機能
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        update(input)
    end
end)

-- ターゲット探し
local function refreshTargets()
    targets = {}

    -- Debris内のFallenPresentを探す
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, obj in ipairs(debris:GetChildren()) do
            if obj.Name == "FallenPresent" then
                table.insert(targets, obj)
            end
        end
    end

    -- CollectablesFolder内のアイテムを探す
    local collectablesFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("CollectablesFolder")
    if collectablesFolder then
        for _, obj in ipairs(collectablesFolder:GetChildren()) do
            if obj.Name == "Haste Potion" or obj.Name == "Gold Dust" or obj.Name == "Luck Potion" or
               obj.Name == "Galactic Coin" or obj.Name == "Universal Coin" or obj.Name == "Coin" or
               obj.Name == "Energy Disk" or obj.Name == "Vivalesce" or obj.Name == "Peanut Potion" or
               obj.Name == "Sorrow Essence" or obj.Name == "Exotic Essence" or obj.Name == "Peanut Potion" or
               obj.Name == "StarCoin" or obj.Name == "Exotic Essence" then
                table.insert(targets, obj)
            end
        end
    end

    -- FallingViolenceもターゲットに追加
    local fallingViolence = workspace.Debris:FindFirstChild("FallingViolence")
    if fallingViolence then
        table.insert(targets, fallingViolence)
    end
end

-- ターゲットの正しい位置を取得
local function getTargetPosition(target)
    if target:IsA("Model") then
        if target.PrimaryPart then
            return target.PrimaryPart.Position
        else
            -- PrimaryPartない場合は適当にModel内のPart探す
            local part = target:FindFirstChildWhichIsA("BasePart")
            if part then
                return part.Position
            end
        end
    elseif target:IsA("BasePart") then
        return target.Position
    end
    return nil
end

-- 一番近いターゲットを見つける
local function findNearestTarget()
    local nearest = nil
    local shortestDistance = math.huge
    for _, target in ipairs(targets) do
        local pos = getTargetPosition(target)
        if pos then
            local dist = (HumanoidRootPart.Position - pos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                nearest = target
            end
        end
    end
    return nearest
end

-- アイテムを回収するために近づいたときに回収
local function collectItem(target)
    local targetPos = getTargetPosition(target)
    if targetPos then
        local distance = (HumanoidRootPart.Position - targetPos).Magnitude
        -- プレイヤーがアイテムに近づいたら回収する
        if distance < 10 then -- 距離10ユニット以内で回収
            -- アイテムを回収 (削除しない)
            -- 例えば、アイテムを回収したフラグをつけるなどの処理
        end
    end
end

-- テレポート管理
RunService.Heartbeat:Connect(function()
    if teleporting then
        refreshTargets()

        local target = findNearestTarget()
        if target then
            local pos = getTargetPosition(target)
            if pos then
                -- アイテムよりほんの少し上にテレポート (10ユニット)
                HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) -- 10ユニットに変更

                -- アイテムを回収
                collectItem(target)
            end
        else
            -- ターゲット消えたら元の場所に戻す
            if originalCFrame then
                HumanoidRootPart.CFrame = originalCFrame
                originalCFrame = nil
            end
        end
    end
end)

-- トグルボタン処理
toggleButton.MouseButton1Click:Connect(function()
    teleporting = not teleporting
    if teleporting then
        originalCFrame = HumanoidRootPart.CFrame
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(34, 177, 76)
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        if originalCFrame then
            HumanoidRootPart.CFrame = originalCFrame
            originalCFrame = nil
        end
    end
end)