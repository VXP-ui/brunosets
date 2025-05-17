local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ClickInterval = 0.10
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil
local enabled = true
local targetPlayer = nil
local currentHighlight = nil

local nameESPEnabled = false
local nameESPFolder = Instance.new("Folder")
nameESPFolder.Name = "NameESPFolder"
nameESPFolder.Parent = workspace

local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function applyHighlight(player)
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
    if player and player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SilentAimHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
        currentHighlight = highlight
    end
end

local function clearHighlight()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

local function createNameESP(player)
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    if nameESPFolder:FindFirstChild(player.Name) then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = player.Name
    billboardGui.Adornee = player.Character.Head
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboardGui

    billboardGui.Parent = nameESPFolder
end

local function removeNameESP(player)
    local esp = nameESPFolder:FindFirstChild(player.Name)
    if esp then
        esp:Destroy()
    end
end

local function clearAllNameESPs()
    for _, esp in ipairs(nameESPFolder:GetChildren()) do
        esp:Destroy()
    end
end

local function isLobbyVisible()
    return localPlayer:FindFirstChild("PlayerGui")
        and localPlayer.PlayerGui:FindFirstChild("MainGui")
        and localPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
        and localPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("Lobby")
        and localPlayer.PlayerGui.MainGui.MainFrame.Lobby:FindFirstChild("Currency")
        and localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

local function lockCameraToHead()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local head = targetPlayer.Character.Head
        local headPosition = camera:WorldToViewportPoint(head.Position)
        if headPosition.Z > 0 then
            local cameraPosition = camera.CFrame.Position
            local direction = (head.Position - cameraPosition).Unit
            camera.CFrame = CFrame.new(cameraPosition, head.Position)
        end
    end
end

local function autoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if (isLeftMouseDown or isRightMouseDown) and not isLobbyVisible() and enabled then
            mouse1click()
        elseif not isLeftMouseDown and not isRightMouseDown then
            autoClickConnection:Disconnect()
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        enabled = not enabled
        clearHighlight()
        notify("Silent Aim", enabled and "Enabled ✅" or "Disabled ❌")
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        nameESPEnabled = not nameESPEnabled
        if nameESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    createNameESP(player)
                end
            end
            notify("Name ESP", "Enabled")
        else
            clearAllNameESPs()
            notify("Name ESP", "Disabled")
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            autoClick()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        if not isRightMouseDown then
            isRightMouseDown = true
            autoClick()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeNameESP(player)
    if player == targetPlayer then
        clearHighlight()
        targetPlayer = nil
    end
end)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if nameESPEnabled and player ~= localPlayer then
            createNameESP(player)
        end
    end)
end)
RunService.Heartbeat:Connect(function()
    if not enabled or isLobbyVisible() then
        clearHighlight()
        return
    end

    local newTarget = getClosestPlayerToMouse()
    if newTarget ~= targetPlayer then
        targetPlayer = newTarget
        applyHighlight(targetPlayer)
    end

    if targetPlayer then
        lockCameraToHead()
    end
end)

notify("Silent Aim", "Loaded - Press RightShift to toggle (Made By virtue.fu)")
notify("Name ESP", "Loaded - Press RightControl to toggle (Made By virtue.fu)")
