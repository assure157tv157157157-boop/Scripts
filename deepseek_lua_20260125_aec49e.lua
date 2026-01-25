--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
end)

--// UI LIB
local Library = loadstring(game:HttpGet("https://pastefy.app/denUvbha/raw"))()

local Window = Library:MakeWindow({
    Title = "Spectra hub | Brookhaven RP 🏡",
    SubTitle = "by: assure_TV",
    LoadText = "Carregando Spectra",
    Flags = "Spectrahub_Brookhaven"
})

Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://74457342844346", BackgroundTransparency = 0 },
    Corner = { CornerRadius = UDim.new(35, 1) }
})

--////////////////////////////////////////////////////
--// TROLL TAB
local TrollTab = Window:MakeTab({
    Title = "Troll",
    Icon = "rbxassetid://6862780932"
})

--////////////////////////////////////////////////////
--// REMOTES
local ToolRemote = ReplicatedStorage.RE:WaitForChild("1Too1l")
local CarRemote  = ReplicatedStorage.RE:WaitForChild("1Ca1r")

--////////////////////////////////////////////////////
--// VARIÁVEIS DO FLING
local LoopTeleportConnection = nil
local flingActive = false
local currentFlingThread = nil
local currentSpin = nil

--////////////////////////////////////////////////////
--// PLAYER LIST
local selectedPlayer

local function getPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            table.insert(t, p.Name)
        end
    end
    return t
end

-- Função para verificar se o jogador selecionado é válido
local function IsValidPlayer()
    return selectedPlayer and Players:FindFirstChild(selectedPlayer) ~= nil
end

-- Função para obter o character do jogador selecionado
local function GetSelectedPlayerCharacter()
    if not IsValidPlayer() then return nil end
    return Players[selectedPlayer].Character
end

-- Função para obter o HumanoidRootPart do jogador selecionado
local function GetSelectedPlayerHRP()
    local char = GetSelectedPlayerCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local dropdown = TrollTab:AddDropdown({
    Name = "Escolher Player",
    Options = getPlayers(),
    Callback = function(v)
        selectedPlayer = v
        print("Player selected:", v)
    end
})

TrollTab:AddButton({
    Name = "Atualizar Lista",
    Callback = function()
        dropdown:Set(getPlayers())
        print("Player list updated!")
    end
})

--==================================
-- FUNÇÃO DE FLING COM BARCO
--==================================
local function boatFling()
    if not IsValidPlayer() then
        warn("No player selected!")
        return
    end

    local Player = Players.LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Vehicles = workspace:FindFirstChild("Vehicles")

    if not Humanoid or not RootPart then
        return
    end

    local function spawnBoat()
        RootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        CarRemote:FireServer("PickingBoat", "MilitaryBoatFree")
        task.wait(1)
        return Vehicles:FindFirstChild(Player.Name .. "Car")
    end

    local PCar = Vehicles:FindFirstChild(Player.Name .. "Car") or spawnBoat()
    if not PCar then
        return
    end

    local Seat = PCar:FindFirstChild("Body") and PCar.Body:FindFirstChild("VehicleSeat")
    if not Seat then
        return
    end

    repeat 
        task.wait(0.1)
        RootPart.CFrame = Seat.CFrame * CFrame.new(0, 1, 0)
    until Humanoid.SeatPart == Seat

    local TargetPlayer = Players:FindFirstChild(selectedPlayer)
    if not TargetPlayer or not TargetPlayer.Character then
        return
    end

    local TargetC = TargetPlayer.Character
    local TargetH = TargetC:FindFirstChildOfClass("Humanoid")
    local TargetRP = TargetC:FindFirstChild("HumanoidRootPart")

    if not TargetRP or not TargetH then
        return
    end

    flingActive = true
    local Spin = Instance.new("BodyAngularVelocity")
    Spin.Name = "Spinning"
    Spin.Parent = PCar.PrimaryPart
    Spin.MaxTorque = Vector3.new(0, math.huge, 0)
    Spin.AngularVelocity = Vector3.new(0, 369, 0)
    currentSpin = Spin

    local function moveCar(TargetRP, offset)
        if PCar and PCar.PrimaryPart then
            PCar:SetPrimaryPartCFrame(CFrame.new(TargetRP.Position + offset))
        end
    end

    currentFlingThread = task.spawn(function()
        while flingActive and PCar and PCar.Parent and TargetRP and TargetRP.Parent do
            task.wait(0.01) 
            
            moveCar(TargetRP, Vector3.new(0, 1, 0))  
            moveCar(TargetRP, Vector3.new(0, -2.25, 5))  
            moveCar(TargetRP, Vector3.new(0, 2.25, 0.25))  
            moveCar(TargetRP, Vector3.new(-2.25, -1.5, 2.25))  
            moveCar(TargetRP, Vector3.new(0, 1.5, 0))  
            moveCar(TargetRP, Vector3.new(0, -1.5, 0))  

            if PCar and PCar.PrimaryPart and flingActive then
                local Rotation = CFrame.Angles(
                    math.rad(math.random(-369, 369)),  
                    math.rad(math.random(-369, 369)), 
                    math.rad(math.random(-369, 369))
                )
                PCar:SetPrimaryPartCFrame(CFrame.new(TargetRP.Position + Vector3.new(0, 1.5, 0)) * Rotation)
            end
        end

        if Spin and Spin.Parent then
            Spin:Destroy()
        end
    end)
end

--==================================
-- FUNÇÃO PARA PARAR FLING
--==================================
local function stopFling()
    flingActive = false
    
    if currentFlingThread then
        task.cancel(currentFlingThread)
        currentFlingThread = nil
    end
    
    if currentSpin and currentSpin.Parent then
        currentSpin:Destroy()
        currentSpin = nil
    end
end

--==================================
-- BOTÕES DE FLING
--==================================
TrollTab:AddButton({
    Name = "Fling Barco",
    Callback = function ()
        boatFling()
        print("Button Clicked")
    end
})

TrollTab:AddButton({
    Name = "Parar Fling Barco",
    Callback = function ()
        stopFling()
        print("Button Clicked")
    end
})

--==============================
-- SPECTATE (BOTÃO ARRUMADO)
--==============================
local Camera = workspace.CurrentCamera

local spectating = false
local spectateConn
local charConn
local currentTarget

--==============================
-- FUNÇÕES SPECTATE
--==============================
local function resetCamera()
    if spectateConn then spectateConn:Disconnect() spectateConn = nil end
    if charConn then charConn:Disconnect() charConn = nil end

    currentTarget = nil

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function spectatePlayer(player)
    if not spectating or not player then return end

    resetCamera()
    spectating = true
    currentTarget = player

    spectateConn = RunService.RenderStepped:Connect(function()
        if not spectating then return end
        if not currentTarget or not currentTarget.Character then return end

        local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
            Camera.CameraType = Enum.CameraType.Custom
        end
    end)

    charConn = player.CharacterAdded:Connect(function()
        task.wait(0.1)
        if spectating and currentTarget == player then
            spectatePlayer(player)
        end
    end)
end

--==============================
-- PLAYER SAINDO
--==============================
Players.PlayerRemoving:Connect(function(plr)
    if spectating and currentTarget == plr then
        resetCamera()
        spectating = false
    end
end)

--==============================
-- BOTÃO SPECTATE
--==============================
TrollTab:AddToggle({
    Name = "👁️ Spectar Jogador",
    Default = false,
    Callback = function(state)
        spectating = state

        if not state then
            resetCamera()
            return
        end

        local target = Players:FindFirstChild(selectedPlayer)
        if target then
            spectatePlayer(target)
        else
            resetCamera()
        end
    end
})

--==============================
-- TROCA DE PLAYER (SEM QUEBRAR LISTA)
--==============================
task.spawn(function()
    local lastSelected

    while true do
        task.wait(0.15)

        if not spectating then
            lastSelected = nil
            continue
        end

        if selectedPlayer ~= lastSelected then
            lastSelected = selectedPlayer
            local newTarget = Players:FindFirstChild(selectedPlayer)

            if newTarget then      
                spectatePlayer(newTarget)      
            else      
                resetCamera()      
            end
        end
    end
end)

--==============================
-- TELEPORTAR PARA JOGADOR
--==============================
TrollTab:AddButton({
    Name = "📍 Teleportar no Jogador",
    Callback = function()
        if not selectedPlayer then return end

        local target = Players:FindFirstChild(selectedPlayer)

        if not target or not target.Character then return end

        local myChar = plr.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")

        if myHRP and targetHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
        end
    end
})