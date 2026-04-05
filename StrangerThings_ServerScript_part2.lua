        end
        if tick() - startTime > 8 then
            trap:Destroy()
            conn:Disconnect()
            return
        end
        -- Detectar enemigos sobre la trampa
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= caster and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (pRoot.Position - pos).Magnitude
                    if dist <= powerData.aoeRadius then
                        -- Aturdir (reducir velocidad)
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local origSpeed = hum.WalkSpeed
                            hum.WalkSpeed = 0
                            task.delay(powerData.stunDuration, function()
                                if hum and hum.Parent then
                                    hum.WalkSpeed = origSpeed
                                end
                            end)
                            CombatSystem.DealDamage(p.Character, powerData.damage, caster, "light_trap")
                            trap:Destroy()
                            conn:Disconnect()
                        end
                    end
                end
            end
        end
    end)
end

-- Curar aliados cercanos (Mike)
function CombatSystem.HealNearbyAllies(pos, healAmount, caster)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local dist = (pRoot.Position - pos).Magnitude
                if dist <= POWERS.communication.buffRadius then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local newHp = math.min(hum.MaxHealth, hum.Health + healAmount)
                        hum.Health = newHp
                        -- Mostrar número de curación (verde)
                        GetRemote("ShowDamageNumber"):FireAllClients(pRoot.Position + Vector3.new(0,3,0), healAmount, false)
                    end
                end
            end
        end
    end
end

-- Melee básico
function CombatSystem.MeleeAttack(player, targetPos)
    local now = tick()
    local cdTable = GameState.playerCooldowns[player.UserId]
    if cdTable and cdTable.melee and (now - cdTable.melee) < 0.8 then return end

    GameState.playerCooldowns[player.UserId] = GameState.playerCooldowns[player.UserId] or {}
    GameState.playerCooldowns[player.UserId].melee = now

    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Hitbox frontal de melee
    local meleeRange = 6
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local dist = (pRoot.Position - root.Position).Magnitude
                if dist <= meleeRange then
                    local data = GameState.playerData[player.UserId]
                    local power = data and data.power or 1
                    local damage = CONFIG.MELEE_DAMAGE + math.floor(power * 0.5)
                    CombatSystem.DealDamage(p.Character, damage, player, "melee")
                    local dir = pRoot.Position - root.Position
                    CombatSystem.ApplyKnockback(p.Character, dir, CONFIG.KNOCKBACK_FORCE * 0.5)
                end
            end
        end
    end

    -- Melee a Demogorgones
    for _, dem in ipairs(GameState.demogorgons) do
        if dem.model and dem.model.Parent then
            local demRoot = dem.model.PrimaryPart
            if demRoot then
                local dist = (demRoot.Position - root.Position).Magnitude
                if dist <= meleeRange then
                    local data = GameState.playerData[player.UserId]
                    local power = data and data.power or 1
                    local damage = CONFIG.MELEE_DAMAGE + math.floor(power * 0.5)
                    dem.health = dem.health - damage
                    CombatSystem.ShowDamageNumber(demRoot.Position, damage, false)
                    if dem.health <= 0 then
                        CombatSystem.KillDemogorgon(dem, player)
                    end
                end
            end
        end
    end
end

-- Dar XP al jugador
function CombatSystem.GiveXP(player, amount)
    local data = GameState.playerData[player.UserId]
    if not data then return end

    data.xp = data.xp + amount
    local xpNeeded = data.level * CONFIG.XP_PER_LEVEL

    if data.xp >= xpNeeded and data.level < CONFIG.MAX_LEVEL then
        data.level = data.level + 1
        data.xp = data.xp - xpNeeded
        data.coins = data.coins + (data.level * 10) -- Bonus de monedas al subir nivel
        GetRemote("ShowNotification"):FireClient(player,
            "⬆ NIVEL " .. data.level,
            "¡Has subido al nivel " .. data.level .. "!",
            CONFIG.COLORS.UI_GOLD
        )
        PlaySound(SOUND_IDS.sfx_levelup, 0.7, 1, player.Character and player.Character.HumanoidRootPart or Workspace)
    end

    GetRemote("UpdateXPUI"):FireClient(player, data.xp, data.level, data.level * CONFIG.XP_PER_LEVEL)
    GetRemote("UpdateCoinsUI"):FireClient(player, data.coins)
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE DEMOGORGONES
-- ═══════════════════════════════════════════════════════
local MonsterSystem = {}

-- Crear un Demogorgon pixelado
function MonsterSystem.SpawnDemogorgon(position)
    if #GameState.demogorgons >= CONFIG.MAX_DEMOGORGONS then return end

    local model = Instance.new("Model")
    model.Name = "Demogorgon"

    -- Cuerpo principal (pixel art style)
    local body = Instance.new("Part")
    body.Name = "HumanoidRootPart"
    body.Size = Vector3.new(4, 5, 4)
    body.Color = Color3.fromRGB(50, 10, 10)
    body.Material = Enum.Material.SmoothPlastic
    body.Position = position
    body.Parent = model

    -- Cabeza (flor del demogorgon - estilo pixel)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(5, 4, 5)
    head.Color = Color3.fromRGB(80, 20, 20)
    head.Material = Enum.Material.SmoothPlastic
    head.Position = position + Vector3.new(0, 4.5, 0)
    head.Parent = model

    -- Pétalos de la "flor" (4 piezas pixeladas)
    for i = 0, 3 do
        local angle = math.rad(i * 90)
        local petal = Instance.new("Part")
        petal.Size = Vector3.new(2.5, 3, 1.5)
        petal.Color = Color3.fromRGB(120, 30, 30)
        petal.Material = Enum.Material.SmoothPlastic
        petal.Position = position + Vector3.new(math.cos(angle)*3.5, 5, math.sin(angle)*3.5)
        petal.Parent = model
    end

    -- Humanoid para comportamiento NPC
    local hum = Instance.new("Humanoid")
    hum.MaxHealth = CONFIG.DEMOGORGON_HEALTH
    hum.Health = CONFIG.DEMOGORGON_HEALTH
    hum.WalkSpeed = CONFIG.DEMOGORGON_SPEED
    hum.JumpPower = 50
    hum.Parent = model

    -- Soldar partes
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = head
    weld.Parent = model

    model.PrimaryPart = body
    model.Parent = Workspace

    -- Efectos de partículas del demogorgon
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(Color3.fromRGB(180, 0, 0))
    pe.LightEmission = 0.5
    pe.Rate = 10
    pe.Lifetime = NumberRange.new(0.5, 1.5)
    pe.Speed = NumberRange.new(1, 3)
    pe.Parent = head

    -- Nombre tag
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "💀 DEMOGORGON"
    lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Code
    lbl.Parent = bb
    bb.Parent = head

    local demEntry = {
        model = model,
        health = CONFIG.DEMOGORGON_HEALTH,
        target = nil,
        lastAttack = 0,
        id = #GameState.demogorgons + 1
    }
    table.insert(GameState.demogorgons, demEntry)

    -- AI del Demogorgon
    task.spawn(function()
        MonsterSystem.DemogorgonAI(demEntry)
    end)

    GetRemote("SpawnDemogorgonEffect"):FireAllClients(position)
    return demEntry
end

-- IA del Demogorgon
function MonsterSystem.DemogorgonAI(demEntry)
    while demEntry.model and demEntry.model.Parent and demEntry.health > 0 do
        task.wait(0.3)

        if not demEntry.model or not demEntry.model.Parent then break end

        -- Buscar jugador más cercano
        local closestPlayer = nil
        local closestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                local demRoot = demEntry.model.PrimaryPart
                if pRoot and demRoot then
                    local dist = (pRoot.Position - demRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = p
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character then
            local target = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = demEntry.model:FindFirstChildOfClass("Humanoid")
            if target and hum then
                -- Moverse hacia el jugador
                hum:MoveTo(target.Position)

                -- Atacar si está cerca
                if closestDist <= 5 then
                    local now = tick()
                    if now - demEntry.lastAttack >= 1.5 then
                        demEntry.lastAttack = now
                        local playerHum = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if playerHum and playerHum.Health > 0 then
                            playerHum:TakeDamage(CONFIG.DEMOGORGON_DAMAGE)
                            CombatSystem.ShowDamageNumber(
                                target.Position,
                                CONFIG.DEMOGORGON_DAMAGE,
                                false
                            )
                        end
                    end
                end
            end
        end
    end
end

-- Matar un Demogorgon
function CombatSystem.KillDemogorgon(demEntry, killer)
    if demEntry.model then
        -- Efecto de muerte (partículas rojas)
        local pos = demEntry.model.PrimaryPart and demEntry.model.PrimaryPart.Position or Vector3.new(0,0,0)
        local deathEffect = Instance.new("Part")
        deathEffect.Size = Vector3.new(6, 6, 6)
        deathEffect.Position = pos
        deathEffect.Anchored = true
        deathEffect.CanCollide = false
        deathEffect.Transparency = 0.8
        deathEffect.Color = Color3.fromRGB(200, 0, 0)
        deathEffect.Material = Enum.Material.Neon
        deathEffect.Parent = Workspace
        game:GetService("Debris"):AddItem(deathEffect, 1.5)

        demEntry.model:Destroy()
        demEntry.model = nil
    end

    -- Remover de la lista
    for i, d in ipairs(GameState.demogorgons) do
        if d == demEntry then
            table.remove(GameState.demogorgons, i)
            break
        end
    end

    -- Dar XP y monedas al asesino
    if killer then
        CombatSystem.GiveXP(killer, CONFIG.XP_PER_KILL_MONSTER)
        local data = GameState.playerData[killer.UserId]
        if data then
            data.kills = data.kills + 1
            data.coins = data.coins + 10
            GetRemote("UpdateCoinsUI"):FireClient(killer, data.coins)
        end
    end
end

-- Spawner automático de Demogorgones
function MonsterSystem.StartSpawner()
    if GameState.spawnerActive then return end
    GameState.spawnerActive = true

    task.spawn(function()
        while GameState.spawnerActive do
            task.wait(CONFIG.SPAWNER_INTERVAL)
            if #GameState.demogorgons < CONFIG.MAX_DEMOGORGONS then
                -- Spawn en posiciones aleatorias del Upside Down
                local spawnPositions = {
                    Vector3.new(math.random(-80, 80), -55, math.random(-80, 80)),
                    Vector3.new(math.random(-80, 80), -55, math.random(-80, 80)),
                }
                for _, pos in ipairs(spawnPositions) do
                    MonsterSystem.SpawnDemogorgon(pos)
                    task.wait(1)
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
--           SISTEMA DE VECNA (BOSS FINAL)
-- ═══════════════════════════════════════════════════════
local VecnaSystem = {}

-- Crear el modelo de Vecna (pixel art intimidante)
function VecnaSystem.SpawnVecna()
    if GameState.vecnaActive then return end
    GameState.vecnaActive = true
    GameState.vecnaHealth = CONFIG.VECNA_MAX_HEALTH
    GameState.vecnaPhase = 1

    local C = CONFIG.COLORS
    local pos = CONFIG.VECNA_SPAWN_POS

    local model = Instance.new("Model")
    model.Name = "Vecna"

    -- Cuerpo de Vecna (grande, intimidante, pixelado)
    -- Torso
    local torso = Instance.new("Part")
    torso.Name = "HumanoidRootPart"
    torso.Size = Vector3.new(8, 10, 5)
    torso.Color = C.VECNA_BODY
    torso.Material = Enum.Material.SmoothPlastic
    torso.Position = pos
    torso.Parent = model

    -- Cabeza
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(7, 7, 5)
    head.Color = Color3.fromRGB(20, 0, 20)
    head.Material = Enum.Material.SmoothPlastic
    head.Position = pos + Vector3.new(0, 9, 0)
    head.Parent = model

    -- Ojos de Vecna (brillantes y siniestros)
    for _, side in ipairs({-2, 2}) do
        local eye = Instance.new("Part")
        eye.Size = Vector3.new(2, 2, 0.5)
        eye.Color = C.VECNA_EYE
        eye.Material = Enum.Material.Neon
        eye.Position = pos + Vector3.new(side, 10, 2.6)
        eye.Parent = model

        local eyeLight = Instance.new("PointLight")
        eyeLight.Color = C.VECNA_EYE
        eyeLight.Brightness = 3
        eyeLight.Range = 12
        eyeLight.Parent = eye
    end

    -- Brazos (largos y amenazantes)
    for _, side in ipairs({-1, 1}) do
        local arm = Instance.new("Part")
        arm.Size = Vector3.new(3, 14, 3)
        arm.Color = C.VECNA_BODY
        arm.Material = Enum.Material.SmoothPlastic
        arm.Position = pos + Vector3.new(side * 6.5, 0, 0)
        arm.Parent = model

        -- Garras
        for i = 0, 3 do
            local claw = Instance.new("Part")
            claw.Size = Vector3.new(1, 4, 1)
            claw.Color = Color3.fromRGB(80, 0, 80)
            claw.Material = Enum.Material.SmoothPlastic
            claw.Position = pos + Vector3.new(side * 6.5 + (i-1.5) * 1.2, -8, 0)
            claw.Parent = model
        end
    end

    -- Piernas
    for _, side in ipairs({-1, 1}) do
        local leg = Instance.new("Part")
        leg.Size = Vector3.new(4, 10, 4)
        leg.Color = C.VECNA_BODY
        leg.Material = Enum.Material.SmoothPlastic
        leg.Position = pos + Vector3.new(side * 2.5, -10, 0)
        leg.Parent = model
    end

    -- Aura de Vecna (partículas moradas)
    local auraAtt = Instance.new("Attachment")
    auraAtt.Parent = torso
    local aura = Instance.new("ParticleEmitter")
    aura.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.VECNA_GLOW),
        ColorSequenceKeypoint.new(0.5, C.VECNA_EYE),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50,0,50))
    })
    aura.LightEmission = 0.8
    aura.Rate = 60
    aura.Lifetime = NumberRange.new(2, 4)
    aura.Speed = NumberRange.new(5, 15)
    aura.SpreadAngle = Vector2.new(180, 180)
    aura.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 1.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    aura.Parent = auraAtt

    -- Humanoid de Vecna
    local hum = Instance.new("Humanoid")
    hum.MaxHealth = CONFIG.VECNA_MAX_HEALTH
    hum.Health = CONFIG.VECNA_MAX_HEALTH
    hum.WalkSpeed = CONFIG.VECNA_MOVE_SPEED
    hum.JumpPower = 0
    hum.DisplayName = "⚡ VECNA ⚡"
    hum.Parent = model

    -- Health bar de Vecna (BillboardGui grande)
    local bb = Instance.new("BillboardGui")
    bb.Name = "VecnaHPBar"
    bb.Size = UDim2.new(0, 400, 0, 80)
    bb.StudsOffset = Vector3.new(0, 12, 0)
    bb.AlwaysOnTop = false

    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1,0,1,0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(10,0,10)
    bgFrame.BorderColor3 = C.VECNA_GLOW
    bgFrame.BorderSizePixel = 3
    bgFrame.Parent = bb

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,0.4,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "☠ VECNA - SEÑOR DEL UPSIDE DOWN ☠"
    nameLabel.TextColor3 = C.VECNA_GLOW
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Code
    nameLabel.Parent = bgFrame

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1,0,0.4,0)
    hpBar.Position = UDim2.new(0,0,0.5,0)
    hpBar.BackgroundColor3 = Color3.fromRGB(180,0,0)
    hpBar.Parent = bgFrame

    local phaseLabel = Instance.new("TextLabel")
    phaseLabel.Name = "PhaseLabel"
    phaseLabel.Size = UDim2.new(1,0,0.2,0)
    phaseLabel.Position = UDim2.new(0,0,0.8,0)
    phaseLabel.BackgroundTransparency = 1
    phaseLabel.Text = "FASE 1 - DESPERTAR"
    phaseLabel.TextColor3 = Color3.fromRGB(255,100,100)
    phaseLabel.TextScaled = true
    phaseLabel.Font = Enum.Font.Code
    phaseLabel.Parent = bgFrame
    bb.Parent = head

    model.PrimaryPart = torso
    model.Parent = Workspace

    GameState.vecna = model

    -- Notificar a todos los jugadores
    for _, p in ipairs(Players:GetPlayers()) do
        GetRemote("ShowNotification"):FireClient(p,
            "☠ VECNA HA DESPERTADO",
            "El Señor del Upside Down ha aparecido. ¡Únanse para derrotarlo!",
            C.VECNA_GLOW
        )
    end
    GetRemote("VecnaHealthUpdate"):FireAllClients(GameState.vecnaHealth, CONFIG.VECNA_MAX_HEALTH, 1)

    -- Iniciar IA de Vecna
    task.spawn(function()
        VecnaSystem.VecnaAI()
    end)

    print("[VecnaSystem] ☠ Vecna ha aparecido!")
    return model
end

-- IA de Vecna (Multi-fase)
function VecnaSystem.VecnaAI()
    local attackTimer = 0

    while GameState.vecnaActive and GameState.vecna and GameState.vecna.Parent do
        task.wait(0.5)

        if not GameState.vecna or not GameState.vecna.Parent then break end

        local hum = GameState.vecna:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            VecnaSystem.VecnaDefeated()
            break
        end

        -- Verificar fase según HP
        local hpPercent = GameState.vecnaHealth / CONFIG.VECNA_MAX_HEALTH
        if hpPercent <= 0.2 and GameState.vecnaPhase < 3 then
            VecnaSystem.TransitionPhase(3)
        elseif hpPercent <= 0.5 and GameState.vecnaPhase < 2 then
            VecnaSystem.TransitionPhase(2)
        end

        -- Buscar objetivo
        local closestPlayer = nil
        local closestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                local vecRoot = GameState.vecna.PrimaryPart
                if pRoot and vecRoot then
                    local dist = (pRoot.Position - vecRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = p
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character then
            local target = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if target and hum then
                hum:MoveTo(target.Position)
            end

            -- Ataques de Vecna según fase
            attackTimer = attackTimer + 0.5
            local attackInterval = CONFIG.VECNA_ATTACK_INTERVAL
            if GameState.vecnaPhase == 2 then attackInterval = 1.8 end
            if GameState.vecnaPhase == 3 then attackInterval = 1.2 end

            if attackTimer >= attackInterval then
                attackTimer = 0
                VecnaSystem.VecnaAttack(closestPlayer)
            end
        end
    end
end

-- Ataques de Vecna por fase
function VecnaSystem.VecnaAttack(target)
    if not GameState.vecna or not target or not target.Character then return end
    local vecRoot = GameState.vecna.PrimaryPart
    if not vecRoot then return end

    local phase = GameState.vecnaPhase
    local attacks = {
        -- Fase 1: Ataques básicos
        function()
            -- Proyectil de mente
            if target.Character then
                local pRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (pRoot.Position - vecRoot.Position).Magnitude
                    if dist <= 25 then
                        local hum = target.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:TakeDamage(25)
                            CombatSystem.ShowDamageNumber(pRoot.Position, 25, false)
                        end
                    end
                end
            end
        end,
        -- Fase 2: Más ataques, más daño
        function()
            -- Ataque AoE
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local dist = (pRoot.Position - vecRoot.Position).Magnitude
                        if dist <= 20 then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:TakeDamage(35)
                                CombatSystem.ShowDamageNumber(pRoot.Position, 35, false)
                                CombatSystem.ApplyKnockback(p.Character, pRoot.Position - vecRoot.Position, 60)
                            end
                        end
                    end
                end
            end
            -- Invoca Demogorgones extra
            MonsterSystem.SpawnDemogorgon(vecRoot.Position + Vector3.new(math.random(-15,15), 0, math.random(-15,15)))
        end,
        -- Fase 3: Modo enojo total
        function()
            -- Ataque masivo a TODOS los jugadores
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local dist = (pRoot.Position - vecRoot.Position).Magnitude
                        if dist <= 35 then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:TakeDamage(50)
                                CombatSystem.ShowDamageNumber(pRoot.Position, 50, true)
                                CombatSystem.ApplyKnockback(p.Character, pRoot.Position - vecRoot.Position, 100)
                            end
                        end
                    end
                end
            end
            -- Invoca múltiples Demogorgones
            for i = 1, 3 do
                task.delay(i * 0.5, function()
                    if GameState.vecna then
                        MonsterSystem.SpawnDemogorgon(vecRoot.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20)))
                    end
                end)
            end
        end,
    }

    local attackFn = attacks[math.min(phase, #attacks)]
    if attackFn then
        task.spawn(attackFn)
    end

    GetRemote("PlayWorldSound"):FireAllClients("vecna_attack")
end

-- Transición de fase de Vecna
function VecnaSystem.TransitionPhase(phase)
    GameState.vecnaPhase = phase
    local phaseNames = {
        [1] = "FASE 1 - DESPERTAR",
        [2] = "FASE 2 - FURIA",
        [3] = "FASE 3 - APOCALIPSIS"
    }
    local phaseColors = {
        [1] = Color3.fromRGB(180,0,255),
        [2] = Color3.fromRGB(255,100,0),
        [3] = Color3.fromRGB(255,0,0),
    }

    -- Actualizar label de fase en la UI de Vecna
    if GameState.vecna then
        local head = GameState.vecna:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChild("VecnaHPBar")
            if bb then
                local bgFrame = bb:FindFirstChildOfClass("Frame")
                if bgFrame then
                    local phaseLabel = bgFrame:FindFirstChild("PhaseLabel")
                    if phaseLabel then
                        phaseLabel.Text = phaseNames[phase] or ""
                        phaseLabel.TextColor3 = phaseColors[phase] or Color3.fromRGB(255,0,0)
                    end
                end
            end
        end
    end

    -- Notificar
    for _, p in ipairs(Players:GetPlayers()) do
        GetRemote("ShowNotification"):FireClient(p,
            "⚡ VECNA - " .. (phaseNames[phase] or ""),
            "¡Vecna ha cambiado de forma! ¡Tengan cuidado!",
            phaseColors[phase] or Color3.fromRGB(255,0,0)
        )
    end
    GetRemote("VecnaHealthUpdate"):FireAllClients(GameState.vecnaHealth, CONFIG.VECNA_MAX_HEALTH, phase)

    print("[VecnaSystem] Vecna transición a fase " .. phase)
end

-- Dañar a Vecna
function CombatSystem.DamageVecna(damage, attacker)
    if not GameState.vecnaActive then return end
    GameState.vecnaHealth = math.max(0, GameState.vecnaHealth - damage)

    -- Actualizar la barra de vida de Vecna en el modelo
    if GameState.vecna then
        local head = GameState.vecna:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChild("VecnaHPBar")
            if bb then
                local bgFrame = bb:FindFirstChildOfClass("Frame")
                if bgFrame then
                    local hpBar = bgFrame:FindFirstChild("HPBar")
                    if hpBar then
                        local pct = GameState.vecnaHealth / CONFIG.VECNA_MAX_HEALTH
                        hpBar.Size = UDim2.new(pct, 0, 0.4, 0)
                    end
                end
            end
        end
    end

    CombatSystem.ShowDamageNumber(
        GameState.vecna and GameState.vecna.PrimaryPart and GameState.vecna.PrimaryPart.Position or Vector3.new(0,0,0),
        damage,
        false
    )
    GetRemote("VecnaHealthUpdate"):FireAllClients(GameState.vecnaHealth, CONFIG.VECNA_MAX_HEALTH, GameState.vecnaPhase)

    if GameState.vecnaHealth <= 0 then
        VecnaSystem.VecnaDefeated()
    end
end

-- Victoria sobre Vecna
function VecnaSystem.VecnaDefeated()
    if not GameState.vecnaActive then return end
    GameState.vecnaActive = false

    -- Efecto épico de derrota
    if GameState.vecna then
        local pos = GameState.vecna.PrimaryPart and GameState.vecna.PrimaryPart.Position or Vector3.new(0,-58,0)

        -- Explosión de partículas
        for i = 1, 5 do
            task.delay(i * 0.3, function()
                local explosion = Instance.new("Explosion")
                explosion.Position = pos + Vector3.new(math.random(-5,5), math.random(0,5), math.random(-5,5))
                explosion.BlastRadius = 10
                explosion.BlastPressure = 0
                explosion.DestroyJointRadiusPercent = 0
                explosion.Parent = Workspace
            end)
        end

        task.delay(1.5, function()
            if GameState.vecna then
                GameState.vecna:Destroy()
                GameState.vecna = nil
            end
        end)
    end

    -- Dar recompensas a todos los jugadores
    for _, p in ipairs(Players:GetPlayers()) do
        CombatSystem.GiveXP(p, CONFIG.XP_PER_KILL_BOSS)
        local data = GameState.playerData[p.UserId]
        if data then
            data.coins = data.coins + 500
            data.kills = data.kills + 1
            GetRemote("UpdateCoinsUI"):FireClient(p, data.coins)
        end
        GetRemote("ShowNotification"):FireClient(p,
            "🏆 ¡VECNA DERROTADO!",
            "¡El Upside Down ha sido sellado! +500 XP +500 Monedas",
            CONFIG.COLORS.UI_GOLD
        )
    end

    GetRemote("BossDefeated"):FireAllClients()

    -- Respawnear Vecna después de 5 minutos
    task.delay(300, function()
        if #Players:GetPlayers() > 0 then
            VecnaSystem.SpawnVecna()
        end
    end)

    print("[VecnaSystem] ✅ Vecna derrotado. Respawn en 5 minutos.")
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE DATOS DE JUGADORES
-- ═══════════════════════════════════════════════════════
local DataSystem = {}

function DataSystem.LoadData(player)
    local defaultData = {
        selectedCharacter = "eleven",
        unlockedChars     = {"eleven", "mike"},
        level             = 1,
        xp                = 0,
        coins             = 100,
        kills             = 0,
        deaths            = 0,
        power             = 1,
    }

    local success, data = pcall(function()
        return PlayerDataStore:GetAsync("player_" .. player.UserId)
    end)

    if success and data then
        -- Merge con defaults (por si hay campos nuevos)
        for k, v in pairs(defaultData) do
            if data[k] == nil then
                data[k] = v
            end
        end
        GameState.playerData[player.UserId] = data
        print("[DataSystem] ✅ Datos cargados para " .. player.Name)
    else
        GameState.playerData[player.UserId] = defaultData
        print("[DataSystem] ⚠ Datos nuevos creados para " .. player.Name)
    end

    return GameState.playerData[player.UserId]
end

function DataSystem.SaveData(player)
    local data = GameState.playerData[player.UserId]
    if not data then return end

    local success, err = pcall(function()
        PlayerDataStore:SetAsync("player_" .. player.UserId, data)
    end)

    if success then
        print("[DataSystem] ✅ Datos guardados para " .. player.Name)
    else
        warn("[DataSystem] ❌ Error guardando datos para " .. player.Name .. ": " .. tostring(err))
    end
end

-- ═══════════════════════════════════════════════════════
--              MANEJO DE JUGADORES
-- ═══════════════════════════════════════════════════════
local function OnPlayerAdded(player)
    print("[Server] 👋 " .. player.Name .. " se ha unido al juego.")

    -- Cargar datos
    local data = DataSystem.LoadData(player)
    GameState.playerCooldowns[player.UserId] = {}

    -- Configurar RemoteFunction para datos
    RemotesFolder.GetPlayerData.OnServerInvoke = function(p)
        return GameState.playerData[p.UserId]
    end

    RemotesFolder.GetCharacterList.OnServerInvoke = function(p)
        local pData = GameState.playerData[p.UserId]
        local result = {}
        for _, char in ipairs(CHARACTERS) do
            local entry = {
                id          = char.id,
                name        = char.name,
                subtitle    = char.subtitle,
                description = char.description,
                lore        = char.lore,
                power       = char.power,
                stats       = char.stats,
                cost        = char.cost,
                unlocked    = char.unlocked or (pData and table.find(pData.unlockedChars, char.id) ~= nil),
                isSelected  = pData and pData.selectedCharacter == char.id,
                colorR      = char.color.R,
                colorG      = char.color.G,
                colorB      = char.color.B,
            }
            table.insert(result, entry)
        end
        return result
    end

    -- Cuando el personaje aparezca en el juego
    player.CharacterAdded:Connect(function(character)
        task.wait(1) -- Esperar a que el personaje cargue
        local pData = GameState.playerData[player.UserId]
        if pData then
            -- Aplicar el personaje seleccionado
            local charData = nil
            for _, c in ipairs(CHARACTERS) do
                if c.id == pData.selectedCharacter then
                    charData = c
                    break
                end
            end
            if charData then
                CharacterSystem.ApplyPixelSkin(character, charData)
            end

            -- Actualizar UI
            GetRemote("UpdateXPUI"):FireClient(player, pData.xp, pData.level, pData.level * CONFIG.XP_PER_LEVEL)
            GetRemote("UpdateCoinsUI"):FireClient(player, pData.coins)
        end

        -- Health regen loop
        task.spawn(function()
            while player.Character == character and character.Parent do
                task.wait(2)
                local hum = character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                    -- Solo regen fuera de combate (comprobando si recibió daño recientemente)
                    local lastDmg = GameState.playerCooldowns[player.UserId] and GameState.playerCooldowns[player.UserId].lastDamage
                    if not lastDmg or tick() - lastDmg > 5 then
                        hum.Health = math.min(hum.MaxHealth, hum.Health + CONFIG.HEALTH_REGEN_RATE)
                    end
                end
                -- Actualizar HP UI
                if hum then
                    GetRemote("UpdateHealthUI"):FireClient(player, hum.Health, hum.MaxHealth)
                end
            end
        end)

        -- Detectar muerte del jugador
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                local pData2 = GameState.playerData[player.UserId]
                if pData2 then
                    pData2.deaths = pData2.deaths + 1
                end
                GetRemote("PlayerDied"):FireClient(player, "Upside Down")
                print("[Server] 💀 " .. player.Name .. " ha muerto.")
            end)
        end
    end)

    -- Bienvenida
    task.delay(3, function()
        if player and player.Parent then
            GetRemote("ShowNotification"):FireClient(player,
                "👋 BIENVENIDO, " .. player.Name:upper(),
                "Elige tu personaje y lucha contra Vecna. ¡El Upside Down te espera!",
                CONFIG.COLORS.UI_BLUE
            )
        end
    end)
end

local function OnPlayerRemoving(player)
    print("[Server] 👋 " .. player.Name .. " ha salido del juego.")
    DataSystem.SaveData(player)
    GameState.playerData[player.UserId] = nil
    GameState.playerCooldowns[player.UserId] = nil
    GameState.portalCooldown[player.UserId] = nil
end

-- ═══════════════════════════════════════════════════════
--           CONECTAR REMOTE EVENTS (SERVIDOR)
-- ═══════════════════════════════════════════════════════
local function SetupRemoteListeners()
    -- Usar poder
    GetRemote("UsePower").OnServerEvent:Connect(function(player, targetPos)
        if typeof(targetPos) ~= "Vector3" then return end
        -- Anti-cheat: verificar posición válida
        if targetPos.Magnitude > 500 then return end
        task.spawn(function()
            CombatSystem.UsePower(player, targetPos)
        end)
    end)

    -- Ataque melee
    GetRemote("MeleeAttack").OnServerEvent:Connect(function(player, targetPos)
        if typeof(targetPos) ~= "Vector3" then return end
        task.spawn(function()
            CombatSystem.MeleeAttack(player, targetPos)
        end)
    end)

    -- Seleccionar personaje
    GetRemote("SelectCharacter").OnServerEvent:Connect(function(player, characterId)
        local data = GameState.playerData[player.UserId]
        if not data then return end

        -- Verificar que el personaje está desbloqueado
        local charData = nil
        for _, c in ipairs(CHARACTERS) do
            if c.id == characterId then
                charData = c
                break
            end
        end
        if not charData then return end

        local isUnlocked = charData.unlocked or table.find(data.unlockedChars, characterId) ~= nil
        if not isUnlocked then
            GetRemote("ShowNotification"):FireClient(player,
                "🔒 BLOQUEADO",
                "Necesitas " .. charData.cost .. " monedas para desbloquear a " .. charData.name,
                CONFIG.COLORS.UI_RED
            )
            return
        end

        data.selectedCharacter = characterId
        GetRemote("CharacterEquipped"):FireClient(player, characterId)

        -- Reaplicar skin al personaje actual
        if player.Character then
            CharacterSystem.ApplyPixelSkin(player.Character, charData)
        end

        GetRemote("ShowNotification"):FireClient(player,
            "✅ PERSONAJE SELECCIONADO",
            "¡Ahora juegas como " .. charData.name .. "!",
            charData.color
        )

        print("[CharSystem] " .. player.Name .. " seleccionó: " .. charData.name)
    end)

    -- Comprar personaje
    GetRemote("PurchaseCharacter").OnServerEvent:Connect(function(player, characterId)
        local data = GameState.playerData[player.UserId]
        if not data then return end

        local charData = nil
        for _, c in ipairs(CHARACTERS) do
            if c.id == characterId then
                charData = c
                break
            end
        end
        if not charData then return end

        -- Ya desbloqueado
        if table.find(data.unlockedChars, characterId) then
            GetRemote("ShowNotification"):FireClient(player, "ℹ INFO", "Ya tienes a " .. charData.name, CONFIG.COLORS.UI_BLUE)
            return
        end

        -- Verificar monedas
        if data.coins < charData.cost then
            GetRemote("ShowNotification"):FireClient(player,
                "❌ MONEDAS INSUFICIENTES",
                "Necesitas " .. charData.cost .. " monedas. Tienes " .. data.coins,
                CONFIG.COLORS.UI_RED
            )
            return
        end

        -- Comprar
        data.coins = data.coins - charData.cost
        table.insert(data.unlockedChars, characterId)
        GetRemote("UpdateCoinsUI"):FireClient(player, data.coins)
        GetRemote("ShowNotification"):FireClient(player,
            "🎉 ¡COMPRADO!",
            "¡Has desbloqueado a " .. charData.name .. "!",
            CONFIG.COLORS.UI_GOLD
        )
