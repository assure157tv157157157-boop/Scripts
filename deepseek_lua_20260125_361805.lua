--////////////////////////////////////////////////////
--// VARIÁVEIS DO MATAR/PUXAR
local isFollowingKill = false
local isFollowingPull = false
local running = false
local connection = nil
local flingConnection = nil
local originalPosition = nil
local savedPosition = nil
local selectedKillPullMethod = nil
local couch = nil

--////////////////////////////////////////////////////
--// FUNÇÃO PARA DESABILITAR/HABILITAR CARCLIENT
local function disableCarClient()
    local backpack = plr:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = true
    end
end

local function enableCarClient()
    local backpack = plr:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = false
    end
end

--////////////////////////////////////////////////////
--// FUNÇÃO PARA EQUIPAR SOFÁ
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

--////////////////////////////////////////////////////
--// FUNÇÃO DE MATAR COM SOFÁ
local function killWithSofa(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    if not equipSofa() then return end
    isFollowingKill = true
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        originalPosition = hrp.Position
    end
end

--////////////////////////////////////////////////////
--// FUNÇÃO DE PUXAR COM SOFÁ
local function pullWithSofa(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    if not equipSofa() then return end
    isFollowingPull = true
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        originalPosition = hrp.Position
    end
end

--////////////////////////////////////////////////////
--// FUNÇÃO DE MATAR COM ÔNIBUS
local function killWithBus(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not plr.Character then return end
    local character = plr.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not myHRP then return end
    savedPosition = myHRP.Position
    
    -- Teleportar para spawn do ônibus
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

    -- Desabilitar CarClient
    disableCarClient()

    -- Spawnar ônibus
    local args = { [1] = "DeleteAllVehicles" }
    pcall(function()
        CarRemote:FireServer(unpack(args))
    end)
    
    args = { [1] = "PickingCar", [2] = "SchoolBus" }
    pcall(function()
        CarRemote:FireServer(unpack(args))
    end)
    
    task.wait(1)
    
    -- Encontrar o ônibus
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    local busName = plr.Name .. "Car"
    local bus = vehiclesFolder:FindFirstChild(busName)
    if not bus then return end
    
    -- Sentar no ônibus
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
    
    -- Configurar ônibus para fling
    for _, part in ipairs(bus:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            pcall(function() part:SetNetworkOwner(nil) end)
        end
    end
    
    running = true
    
    -- Conexão para evitar colisões
    connection = RunService.Stepped:Connect(function()
        if not running then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    -- Fling com ônibus
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
        
        -- Verificar se jogador sentou no ônibus ou timeout
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
            
            -- Teleportar ônibus para longe
            pcall(function()
                bus:PivotTo(CFrame.new(Vector3.new(-76.6, -401.97, -84.26)))
            end)
            task.wait(0.5)

            -- Deletar veículo
            disableCarClient()
            local args = { [1] = "DeleteAllVehicles" }
            pcall(function()
                CarRemote:FireServer(unpack(args))
            end)
            
            -- Retornar à posição original
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
            
            -- Restaurar física
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end
                end
            end
            
            -- Restaurar estados
            local myHumanoid = character and character:FindFirstChild("Humanoid")
            if myHumanoid then myHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
            
            -- Habilitar bancos
            for _, seat in ipairs(Workspace:GetDescendants()) do
                if seat:IsA("Seat") or seat:IsA("VehicleSeat") then seat.Disabled = false end
            end
        end
    end)
end

--////////////////////////////////////////////////////
--// CONEXÕES PARA SEGUIR E VERIFICAR SE SENTOU
local followConnection = RunService.Heartbeat:Connect(function()
    if (isFollowingKill or isFollowingPull) and selectedPlayer and plr.Character and 
       plr.Character:FindFirstChild("HumanoidRootPart") and Players:FindFirstChild(selectedPlayer) and 
       Players:FindFirstChild(selectedPlayer).Character and 
       Players:FindFirstChild(selectedPlayer).Character:FindFirstChild("HumanoidRootPart") then
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        pcall(function()
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

local sitCheckConnection = RunService.Heartbeat:Connect(function()
    if (isFollowingKill or isFollowingPull) and selectedPlayer and Players:FindFirstChild(selectedPlayer) and 
       Players:FindFirstChild(selectedPlayer).Character and 
       Players:FindFirstChild(selectedPlayer).Character:FindFirstChild("Humanoid") then
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        pcall(function()
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
                
                -- Retornar à posição original
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

--////////////////////////////////////////////////////
--// ADICIONAR ELEMENTOS À UI
TrollTab:AddSection({ "Matar/Puxar" })

-- Dropdown para selecionar método
local DropdownKillPullMethod = TrollTab:AddDropdown({
    Name = "Selecionar Método (Matar/Puxar)",
    Description = "Escolha o método para matar ou puxar",
    Options = {"Sofá", "Ônibus"},
    Callback = function(value)
        selectedKillPullMethod = value
    end
})

-- Botão Matar
TrollTab:AddButton({
    Name = "Matar",
    Description = "Inicia o matar com o método selecionado",
    Callback = function()
        if isFollowingKill or isFollowingPull or running then 
            warn("Já está executando uma ação!")
            return 
        end
        if not selectedPlayer then 
            warn("Selecione um jogador primeiro!")
            return 
        end
        if not selectedKillPullMethod then 
            warn("Selecione um método primeiro!")
            return 
        end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then 
            warn("Jogador não encontrado!")
            return 
        end
        
        if selectedKillPullMethod == "Sofá" then
            killWithSofa(targetPlayer)
            print("Matar com Sofá iniciado!")
        elseif selectedKillPullMethod == "Ônibus" then
            killWithBus(targetPlayer)
            print("Matar com Ônibus iniciado!")
        end
    end
})

-- Botão Puxar
TrollTab:AddButton({
    Name = "Puxar",
    Description = "Inicia o puxar com o método selecionado",
    Callback = function()
        if isFollowingKill or isFollowingPull or running then 
            warn("Já está executando uma ação!")
            return 
        end
        if not selectedPlayer then 
            warn("Selecione um jogador primeiro!")
            return 
        end
        if not selectedKillPullMethod or selectedKillPullMethod ~= "Sofá" then 
            warn("Puxar só está disponível com Sofá!")
            return 
        end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then 
            warn("Jogador não encontrado!")
            return 
        end
        
        pullWithSofa(targetPlayer)
        print("Puxar com Sofá iniciado!")
    end
})

-- Botão Parar
TrollTab:AddButton({
    Name = "Parar (Matar ou Puxar)",
    Description = "Para o movimento de matar ou puxar",
    Callback = function()
        isFollowingKill = false
        isFollowingPull = false
        running = false
        
        -- Limpar conexões
        if connection then 
            connection:Disconnect() 
            connection = nil 
        end
        if flingConnection then 
            flingConnection:Disconnect() 
            flingConnection = nil 
        end
        
        -- Restaurar física do personagem
        if plr.Character then
            for _, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
        end
        
        -- Restaurar estados
        local myHumanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
        if myHumanoid then 
            myHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) 
        end
        
        -- Habilitar bancos
        for _, seat in ipairs(Workspace:GetDescendants()) do
            if seat:IsA("Seat") or seat:IsA("VehicleSeat") then 
                seat.Disabled = false 
            end
        end
        
        -- Retornar à posição original se necessário
        if originalPosition and plr.Character then
            local myHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.Anchored = true
                myHRP.CFrame = CFrame.new(originalPosition + Vector3.new(0, 5, 0))
                task.wait(0.2)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
                myHRP.Anchored = false
                if myHumanoid then 
                    myHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) 
                end
            end
            originalPosition = nil
        end
        
        -- Deletar veículos
        disableCarClient()
        local args = { [1] = "DeleteAllVehicles" }
        pcall(function()
            CarRemote:FireServer(unpack(args))
        end)
        
        print("Ação parada com sucesso!")
    end
})