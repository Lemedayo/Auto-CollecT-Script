-- プレイヤーとキャラクター
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- GUI作成
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoPromptGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- ドラッグ可能
local dragging = false
local dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- トグルボタン
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 180, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleButton.TextColor3 = Color3.fromRGB(255,255,255)
toggleButton.Text = "Auto Prompt: OFF"
toggleButton.Parent = frame

local autoEnabled = false
toggleButton.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    toggleButton.Text = autoEnabled and "Auto Prompt: ON" or "Auto Prompt: OFF"
end)

-- 監視用テーブル
local trackedPrompts = {}

-- ProximityPrompt 発火関数（テレポート付き）
local function safeFire(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if not prompt.Parent then return end
    if not autoEnabled then return end

    -- プレイヤーをPrompt付近にテレポート
    hrp.CFrame = prompt.Parent.CFrame + Vector3.new(0,3,0)
    task.wait(0.05) -- 少し待つと安全

    pcall(function()
        fireproximityprompt(prompt, math.huge)
    end)
end

-- Prompt 監視関数
local function watchPrompts(parent)
    -- 既存Promptを登録
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            trackedPrompts[v] = true
            safeFire(v)
        end
    end

    -- 新規追加Promptも登録
    parent.DescendantAdded:Connect(function(desc)
        if desc:IsA("ProximityPrompt") then
            trackedPrompts[desc] = true
            safeFire(desc)
        end
    end)
end

-- Debris と ItemsFolder を監視
watchPrompts(workspace:WaitForChild("Debris"))

local itemsFolder = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("ItemsFolder")
if itemsFolder then
    watchPrompts(itemsFolder)
end

-- GUIトグルがONになったら既存Promptも発火
game:GetService("RunService").RenderStepped:Connect(function()
    if autoEnabled then
        for prompt,_ in pairs(trackedPrompts) do
            safeFire(prompt)
        end
    end
end)
