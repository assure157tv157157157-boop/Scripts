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
local ClearToolsRemote = ReplicatedStorage.RE:WaitForChild("1Clea1rTool1s")
local ClothesRemote = ReplicatedStorage.RE:WaitForChild("1Clothe1s")

-- Variáveis globais
local selectedPlayer = nil
local isFollowingKill = false
local isFollowingPull = false
local running = false
local connection = nil
local flingConnection = nil
local originalPosition = nil
local savedPosition = nil
local originalProperties = {}
local selectedKillPullMethod = nil
local selectedFlingMethod = nil
local soccerBall = nil
local couch = nil
local isSpectating = false
local spectatedPlayer = nil
local characterConnection = nil
local flingToggle = nil

-- Evento de rede para definir dono da rede
local SetNetworkOwnerEvent = Instance.new("RemoteEvent")
SetNetworkOwnerEvent.Name = "SetNetworkOwnerEvent_" .. tostring(math.random(1000, 9999))
SetNetworkOwnerEvent.Parent = ReplicatedStorage

local serverScriptCode = [[
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local event = ReplicatedStorage:WaitForChild("]] .. SetNetworkOwnerEvent.Name .. [[")
    
    event.OnServerEvent:Connect(function(player, part, networkOwner)
        if part and part:IsA("BasePart") then
            pcall(function()
                part:SetNetworkOwner(networkOwner)
                part.Anchored = false
                part.CanCollide = true
                part.CanTouch = true
            end)
        end
    end)
]]

pcall(function()
    loadstring(serverScriptCode)()
end)

-- Função para desabilitar CarClient
local function disableCarClient()
    local backpack = plr:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = true
    end
end

-- Função para habilitar CarClient
local function enableCarClient()
    local backpack = plr:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = false
    end
end

-- Função para obter lista de jogadores
local function getPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            table.insert(t, p.Name)
        end
    end
    return t
end

-- Atualizar dropdown
local function updateDropdown(dropdown)
    local currentValue = dropdown:Get()
    local playerNames = getPlayers()
    dropdown:Set(playerNames)
    
    if currentValue and not table.find(playerNames, currentValue) then
        dropdown:Set("")
        selectedPlayer = nil
        if isSpectating then
            stopSpectating()
        end
        if running or isFollowingKill or isFollowingPull then
            running = false
            isFollowingKill = false
            isFollowingPull = false
            if connection then connection:Disconnect() connection = nil end
            if flingConnection then flingConnection:Disconnect() flingConnection = nil end
            if flingToggle then flingToggle:Set(false) end
        end
    elseif currentValue and table.find(playerNames, currentValue) then
        dropdown:Set(currentValue)
    end
end

--////////////////////////////////////////////////////
--// PLAYER LIST
local dropdown = TrollTab:AddDropdown({
    Name = "Escolher Player",
    Options = getPlayers(),
    Callback = function(v)
        selectedPlayer = v
        if v and v ~= "" then
            selectedPlayer = Players:FindFirstChild(v)
        else
            selectedPlayer = nil
        end
    end
})

TrollTab:AddButton({
    Name = "Atualizar Lista",
    Callback = function()
        dropdown:Set(getPlayers())
    end
})

--==============================
-- SPECTATE FUNCTIONS
--==============================
local Camera = workspace.CurrentCamera
local spectating = false
local spectateConn
local charConn
local currentTarget

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

local function stopSpectating()
    resetCamera()
    spectating = false
    isSpectating = false
    spectatedPlayer = nil
end

local function spectatePlayer(player)
    if not spectating or not player then return end
    
    resetCamera()
    spectating = true
    isSpectating = true
    currentTarget = player
    spectatedPlayer = player
    
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

-- Toggle para spectar
TrollTab:AddToggle({
    Name = "👁️ Spectar Jogador",
    Default = false,
    Callback = function(state)
        spectating = state
        isSpectating = state
        
        if not state then
            resetCamera()
            return
        end
        
        if selectedPlayer and selectedPlayer ~= "" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target then
                spectatePlayer(target)
            else
                resetCamera()
            end
        else
            resetCamera()
        end
    end
})

--==============================
-- TELEPORTAR PARA JOGADOR
--==============================
local function teleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = plr.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = plr.Character:FindFirstChild("Humanoid")
        if not myHRP or not myHumanoid then
            return
        end

        -- Zerar a física do personagem antes do teleporte
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
                part.Anchored = true
            end
        end

        -- Teleportar para a posição do jogador-alvo
        local success, errorMessage = pcall(function()
            myHRP.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 2, 0))
        end)
        if not success then
            warn("Erro ao teletransportar: " .. tostring(errorMessage))
            return
        end

        -- Garantir que o Humanoid saia do estado sentado ou voando
        myHumanoid.Sit = false
        myHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

        -- Aguardar 0,5 segundos com o personagem ancorado
        task.wait(0.5)

        -- Desancorar todas as partes do personagem e restaurar física
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
    end
end

TrollTab:AddButton({
    Name = "📍 Teleportar no Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "" then
            teleportToPlayer(selectedPlayer)
        end
    end
})

--==============================
-- SECTIONS
--==============================
TrollTab:AddSection({"Kill"})

local DropdownKillPullMethod = TrollTab:AddDropdown({
    Name = "Selecionar Método (Matar/Puxar)",
    Description = "Escolha o método para matar ou puxar",
    Options = {"Sofá", "Ônibus"},
    Callback = function(value)
        selectedKillPullMethod = value
    end
})

-- Função para equipar sofá
local function equipSofa()
    local backpack = plr:WaitForChild("Backpack")
    local sofa = backpack:FindFirstChild("Couch") or plr.Character:FindFirstChild("Couch")
    if not sofa then
        local args = { [1] = "PickingTools", [2] = "Couch" }
        local success = pcall(function()
            ToolRemote:InvokeServer(unpack(args))
        end)
        if not success then return false end
        repeat
            sofa = backpack:FindFirstChild("Couch")
            task.wait()
        until sofa or task.wait(5)
        if not sofa then return false end
    end
    if sofa.Parent ~= plr.Character then
        sofa.Parent = plr.Character
    end
    return true
end

-- Função para matar com sofá
local function killWithSofa(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    if not equipSofa() then return end
    isFollowingKill = true
    originalPosition = plr.Character:FindFirstChild("HumanoidRootPart").Position
end

-- Função para puxar com sofá
local function pullWithSofa(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    if not equipSofa() then return end
    isFollowingPull = true
    originalPosition = plr.Character:FindFirstChild("HumanoidRootPart").Position
end

-- Função para matar com ônibus
local function killWithBus(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    local character = plr.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not myHRP then return end
    savedPosition = myHRP.Position
    
    pcall(function()
        myHRP.Anchored = true
        myHRP.CFrame = CFrame.new(Vector3.new(1181.83, 76.08, -1158.83))
        task.wait(0.2)
        myHRP.Velocity = Vector3.zero
        myHRP.RotVelocity = Vector3.zero
        myHRP.Anchored = false
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
    task.wait(0.5)

    disableCarClient()

    local args = { [1] = "DeleteAllVehicles" }
    pcall(function()
        CarRemote:FireServer(unpack(args))
    end)
    
    args = { [1] = "PickingCar", [2] = "SchoolBus" }
    pcall(function()
        CarRemote:FireServer(unpack(args))
    end)
    
    task.wait(1)
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    local busName = plr.Name .. "Car"
    local bus = vehiclesFolder:FindFirstChild(busName)
    if not bus then return end
    
    pcall(function()
        myHRP.Anchored = true
        myHRP.CFrame = CFrame.new(Vector3.new(1171.15, 79.45, -1166.2))
        task.wait(0.2)
        myHRP.Velocity = Vector3.zero
        myHRP.RotVelocity = Vector3.zero
        myHRP.Anchored = false
        humanoid:ChangeState(Enum.HumanoidStateType.Seated)
    end)
    
    local sitStart = tick()
    repeat
        task.wait()
        if tick() - sitStart > 10 then return end
    until humanoid.Sit
    
    for _, part in ipairs(bus:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            pcall(function() part:SetNetworkOwner(nil) end)
        end
    end
    
    running = true
    connection = RunService.Stepped:Connect(function()
        if not running then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    local lastUpdate = tick()
    local updateInterval = 0.05
    local startTime = tick()
    flingConnection = RunService.Heartbeat:Connect(function()
        if not running then return end
        local targetCharacter = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
        local newTargetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
        local newTargetHumanoid = targetCharacter:FindFirstChild("Humanoid")
        if not newTargetHRP or not newTargetHumanoid then return end
        if not myHRP or not humanoid then running = false return end
        if tick() - lastUpdate < updateInterval then return end
        lastUpdate = tick()
        local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
        pcall(function()
            local targetPosition = newTargetHRP.Position + offset
            bus:PivotTo(
                CFrame.new(targetPosition) * CFrame.Angles(
                    math.rad(Workspace.DistributedGameTime * 12000),
                    math.rad(Workspace.DistributedGameTime * 15000),
                    math.rad(Workspace.DistributedGameTime * 18000)
                )
            )
        end)
        local playerSeated = false
        for _, seat in ipairs(bus:GetDescendants()) do
            if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Name ~= "VehicleSeat" then
                if seat.Occupant == newTargetHumanoid then
                    playerSeated = true
                    break
                end
            end
        end
        if playerSeated or tick() - startTime > 10 then
            running = false
            if connection then connection:Disconnect() connection = nil end
            if flingConnection then flingConnection:Disconnect() flingConnection = nil end
            pcall(function()
                bus:PivotTo(CFrame.new(Vector3.new(-76.6, -401.97, -84.26)))
            end)
            task.wait(0.5)

            disableCarClient()

            local args = { [1] = "DeleteAllVehicles" }
            pcall(function()
                CarRemote:FireServer(unpack(args))
            end)
            if character then
                local myHRP = character:FindFirstChild("HumanoidRootPart")
                if myHRP and savedPosition then
                    pcall(function()
                        myHRP.Anchored = true
                        myHRP.CFrame = CFrame.new(savedPosition + Vector3.new(0, 5, 0))
                        task.wait(0.2)
                        myHRP.Velocity = Vector3.zero
                        myHRP.RotVelocity = Vector3.zero
                        myHRP.Anchored = false
                        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
                    end)
                end
            end
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end
                end
            end
            local myHumanoid = character and character:FindFirstChild("Humanoid")
            if myHumanoid then myHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
            for _, seat in ipairs(Workspace:GetDescendants()) do
                if seat:IsA("Seat") or seat:IsA("VehicleSeat") then seat.Disabled = false end
            end
            pcall(function()
                ClothesRemote:FireServer("CharacterSizeUp", 1)
            end)
        end
    end)
end

-- Conexões para seguir jogador
local followConnection
followConnection = RunService.Heartbeat:Connect(function()
    if (isFollowingKill or isFollowingPull) and selectedPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and Players:FindFirstChild(selectedPlayer) and Players:FindFirstChild(selectedPlayer).Character and Players:FindFirstChild(selectedPlayer).Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
            plr.Character:SetPrimaryPartCFrame(
                CFrame.new(targetPosition) * CFrame.Angles(
                    math.rad(Workspace.DistributedGameTime * 12000),
                    math.rad(Workspace.DistributedGameTime * 15000),
                    math.rad(Workspace.DistributedGameTime * 18000)
                )
            )
        end)
    end
end)

-- Conexão para verificar se jogador sentou
local sitCheckConnection
sitCheckConnection = RunService.Heartbeat:Connect(function()
    if (isFollowingKill or isFollowingPull) and selectedPlayer and Players:FindFirstChild(selectedPlayer) and Players:FindFirstChild(selectedPlayer).Character and Players:FindFirstChild(selectedPlayer).Character:FindFirstChild("Humanoid") then
        pcall(function()
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            if targetPlayer.Character.Humanoid.Sit then
                if isFollowingKill then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        plr.Character:SetPrimaryPartCFrame(CFrame.new(0, -500, 0))
                        task.wait(0.5)
                        ToolRemote:InvokeServer("PickingTools", "Couch")
                        task.wait(1)
                    end
                end
                isFollowingKill = false
                isFollowingPull = false
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and originalPosition then
                    local myHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    local myHumanoid = plr.Character:FindFirstChild("Humanoid")
                    if myHRP then
                        myHRP.Anchored = true
                        myHRP.CFrame = CFrame.new(originalPosition + Vector3.new(0, 5, 0))
                        task.wait(0.2)
                        myHRP.Velocity = Vector3.zero
                        myHRP.RotVelocity = Vector3.zero
                        myHRP.Anchored = false
                        if myHumanoid then myHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
                    end
                    originalPosition = nil
                end
            end
        end)
    end
end)

-- Botões de kill/pull
TrollTab:AddButton({
    Name = "Matar",
    Description = "Inicia o matar com o método selecionado",
    Callback = function()
        if isFollowingKill or isFollowingPull or running then return end
        if not selectedPlayer or not selectedKillPullMethod then return end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then return end
        
        if selectedKillPullMethod == "Sofá" then
            killWithSofa(targetPlayer)
        elseif selectedKillPullMethod == "Ônibus" then
            killWithBus(targetPlayer)
        end
    end
})

TrollTab:AddButton({
    Name = "Puxar",
    Description = "Inicia o puxar com o método selecionado",
    Callback = function()
        if isFollowingKill or isFollowingPull or running then return end
        if not selectedPlayer or not selectedKillPullMethod or selectedKillPullMethod ~= "Sofá" then return end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then return end
        
        pullWithSofa(targetPlayer)
    end
})

TrollTab:AddButton({
    Name = "Parar (Matar ou Puxar)",
    Description = "Para o movimento de matar ou puxar",
    Callback = function()
        isFollowingKill = false
        isFollowingPull = false
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
        local myHumanoid = plr.Character:FindFirstChild("Humanoid")
        if myHumanoid then myHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        for _, seat in ipairs(Workspace:GetDescendants()) do
            if seat:IsA("Seat") or seat:IsA("VehicleSeat") then seat.Disabled = false end
        end
        if originalPosition then
            local myHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.Anchored = true
                myHRP.CFrame = CFrame.new(originalPosition + Vector3.new(0, 5, 0))
                task.wait(0.2)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
                myHRP.Anchored = false
                if myHumanoid then myHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
            originalPosition = nil
        end

        disableCarClient()

        local args = { [1] = "DeleteAllVehicles" }
        pcall(function()
            CarRemote:FireServer(unpack(args))
        end)
    end
})

--==============================
-- SECTIONS PARA FLING
--==============================
TrollTab:AddSection({"Fling"})

local DropdownFlingMethod = TrollTab:AddDropdown({
    Name = "Selecionar Método de Fling",
    Description = "Escolha o método para aplicar fling",
    Options = {"Sofá", "Ônibus", "Bola", "Bola V2", "Barco", "Caminhão"},
    Callback = function(value)
        selectedFlingMethod = value
    end
})

-- Função para equipar bola
local function equipBola()
    local backpack = plr:WaitForChild("Backpack")
    local bola = backpack:FindFirstChild("SoccerBall") or plr.Character:FindFirstChild("SoccerBall")
    if not bola then
        local args = { [1] = "PickingTools", [2] = "SoccerBall" }
        local success = pcall(function()
            ToolRemote:InvokeServer(unpack(args))
        end)
        if not success then return false end
        repeat
            bola = backpack:FindFirstChild("SoccerBall")
            task.wait()
        until bola or task.wait(5)
        if not bola then return false end
    end
    if bola.Parent ~= plr.Character then
        bola.Parent = plr.Character
    end
    return true
end

-- Função para fling com sofá
local function flingWithSofa(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not myHRP then return end
    savedPosition = myHRP.Position
    
    if not equipSofa() then return end
    task.wait(0.5)
    couch = character:FindFirstChild("Couch")
    if not couch then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj.Name == "Couch" or obj.Name == "Couch" .. plr.Name) and (obj:IsA("BasePart") or obj:IsA("Tool")) then
                couch = obj
                break
            end
        end
    end
    if not couch then return end
    
    if couch:IsA("BasePart") then
        originalProperties = {
            Anchored = couch.Anchored,
            CanCollide = couch.CanCollide,
            CanTouch = couch.CanTouch
        }
        couch.Anchored = false
        couch.CanCollide = true
        couch.CanTouch = true
        pcall(function() couch:SetNetworkOwner(nil) end)
    end
    
    running = true
    connection = RunService.Stepped:Connect(function()
        if not running then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    local startTime = tick()
    flingConnection = RunService.Heartbeat:Connect(function()
        if not running then return end
        if not targetPlayer or not targetPlayer.Character then running = false return end
        local newTargetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local newTargetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if not newTargetHRP or not newTargetHumanoid then running = false return end
        if not myHRP or not humanoid then running = false return end
        
        pcall(function()
            local targetPosition = newTargetHRP.Position
            character:SetPrimaryPartCFrame(
                CFrame.new(targetPosition) * CFrame.Angles(
                    math.rad(Workspace.DistributedGameTime * 12000),
                    math.rad(Workspace.DistributedGameTime * 15000),
                    math.rad(Workspace.DistributedGameTime * 18000)
                )
            )
        end)
        
        if newTargetHumanoid.Sit or tick() - startTime > 10 then
            running = false
            flingConnection:Disconnect()
            flingConnection = nil
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    pcall(function() part:SetNetworkOwner(nil) end)
                end
            end
            
            local walkFlingInstance = Instance.new("BodyVelocity")
            walkFlingInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            walkFlingInstance.Velocity = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5)).Unit * 1000000 + Vector3.new(0, 1000000, 0)
            walkFlingInstance.Parent = myHRP
            
            pcall(function()
                myHRP.Anchored = true
                myHRP.CFrame = CFrame.new(Vector3.new(-59599.73, 2040070.50, -293391.16))
                myHRP.Anchored = false
            end)
            
            local spinStart = tick()
            local spinConnection
            spinConnection = RunService.Heartbeat:Connect(function()
                if tick() - spinStart >= 0.5 then
                    spinConnection:Disconnect()
                    return
                end
                pcall(function()
                    character:SetPrimaryPartCFrame(
                        myHRP.CFrame * CFrame.Angles(
                            math.rad(Workspace.DistributedGameTime * 12000),
                            math.rad(Workspace.DistributedGameTime * 15000),
                            math.rad(Workspace.DistributedGameTime * 18000)
                        )
                    )
                end)
            end)
            
            task.wait(0.5)
            local args = { [1] = "PlayerWantsToDeleteTool", [2] = "Couch" }
            pcall(function()
                ClearToolsRemote:FireServer(unpack(args))
            end)
            
            pcall(function()
                myHRP.Anchored = true
                myHRP.CFrame = CFrame.new(savedPosition + Vector3.new(0, 5, 0))
                task.wait(0.2)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
                myHRP.Anchored = false
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
            
            if walkFlingInstance then walkFlingInstance:Destroy() end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            
            if flingToggle then flingToggle:Set(false) end
        end
    end)
end

-- Função para fling com bola
local function flingWithBall(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not myHRP then return end
    
    if not equipBola() then return end
    task.wait(0.5)
    
    local args = { [1] = "PlayerWantsToDeleteTool", [2] = "SoccerBall" }
    pcall(function()
        ClearToolsRemote:FireServer(unpack(args))
    end)
    
    local workspaceCom = Workspace:FindFirstChild("WorkspaceCom")
    if not workspaceCom then return end
    local soccerBalls = workspaceCom:FindFirstChild("001_SoccerBalls")
    if not soccerBalls then return end
    soccerBall = soccerBalls:FindFirstChild("Soccer" .. plr.Name)
    if not soccerBall then return end
    
    originalProperties = {
        Anchored = soccerBall.Anchored,
        CanCollide = soccerBall.CanCollide,
        CanTouch = soccerBall.CanTouch
    }
    soccerBall.Anchored = false
    soccerBall.CanCollide = true
    soccerBall.CanTouch = true
    pcall(function() soccerBall:SetNetworkOwner(nil) end)
    savedPosition = myHRP.Position
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        humanoid.Sit = false
    end
    
    for _, seat in ipairs(Workspace:GetDescendants()) do
        if seat:IsA("Seat") or seat:IsA("VehicleSeat") then seat.Disabled = true end
    end
    
    pcall(function()
        ClothesRemote:FireServer("CharacterSizeDown", 4)
    end)
    
    running = true
    local lastFlingTime = 0
    connection = RunService.Heartbeat:Connect(function()
        if not running or not targetPlayer.Character then return end
        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = targetPlayer.Character:FindFirstChild("Humanoid")
        local myHRP = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum or not myHRP then return end
        
        local moveDir = hum.MoveDirection
        local isStill = moveDir.Magnitude < 0.1
        local isSitting = hum.Sit
        
        if isSitting then
            local y = math.sin(tick() * 50) * 2
            soccerBall.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 0.75 + y, 0))
        elseif isStill then
            local z = math.sin(tick() * 50) * 3
            soccerBall.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 0.75, z))
        else
            local offset = moveDir.Unit * math.clamp(hrp.Velocity.Magnitude * 0.15, 5, 12)
            soccerBall.CFrame = CFrame.new(hrp.Position + offset + Vector3.new(0, 0.75, 0))
        end
        myHRP.CFrame = CFrame.new(soccerBall.Position + Vector3.new(0, 1, 0))
    end)
    
    flingConnection = RunService.Heartbeat:Connect(function()
        if not running or not targetPlayer.Character then return end
        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (soccerBall.Position - hrp.Position).Magnitude
        if dist < 4 and tick() - lastFlingTime > 0.4 then
            lastFlingTime = tick()
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            local fling = Instance.new("BodyVelocity")
            fling.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            fling.Velocity = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5)).Unit * 500000 +