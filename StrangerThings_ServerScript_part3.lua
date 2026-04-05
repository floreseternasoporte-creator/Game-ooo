        print("[Shop] " .. player.Name .. " compró: " .. charData.name)
    end)

    -- Entrar al portal
    GetRemote("EnterPortal").OnServerEvent:Connect(function(player)
        local now = tick()
        if GameState.portalCooldown[player.UserId] and (now - GameState.portalCooldown[player.UserId]) < CONFIG.PORTAL_COOLDOWN then
            GetRemote("ShowNotification"):FireClient(player, "⏳ PORTAL", "El portal se está recargando...", CONFIG.COLORS.UI_BLUE)
            return
        end
        GameState.portalCooldown[player.UserId] = now

        if not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Teletransportar al Upside Down
        root.CFrame = CFrame.new(0, -55, 0)
        GetRemote("WorldTransition"):FireClient(player, "UpsideDown")
        GetRemote("ShowNotification"):FireClient(player,
            "🌀 UPSIDE DOWN",
            "Has entrado al Upside Down. ¡Cuidado con Vecna!",
            CONFIG.COLORS.UD_GLOW
        )
        print("[Portal] " .. player.Name .. " entró al Upside Down.")
    end)
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE CICLO DÍA/NOCHE (HAWKINS)
-- ═══════════════════════════════════════════════════════
local function StartDayNightCycle()
    task.spawn(function()
        local time = 15 -- Empezar a las 3pm
        while true do
            task.wait(5)
            time = time + 0.2
            if time >= 24 then time = 0 end
            Lighting.ClockTime = time

            -- Hawkins de noche se vuelve más misterioso
            if time > 20 or time < 6 then
                Lighting.Ambient = Color3.fromRGB(20, 20, 50)
                Lighting.Brightness = 0.5
                -- Spawnear más Demogorgones de noche
            else
                Lighting.Ambient = Color3.fromRGB(100, 100, 140)
                Lighting.Brightness = 2
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
--              INICIALIZACIÓN PRINCIPAL
-- ═══════════════════════════════════════════════════════
local function Initialize()
    print("╔════════════════════════════════════════════╗")
    print("║  STRANGER THINGS: THE UPSIDE DOWN BATTLE  ║")
    print("║       Iniciando servidor del juego...      ║")
    print("╚════════════════════════════════════════════╝")

    -- Limpiar workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name ~= "Camera" and obj.Name ~= "Terrain" and not obj:IsA("Script") then
            -- No destruir objetos base
        end
    end

    -- Construir mundos
    task.spawn(function()
        WorldBuilder.BuildHawkins()
        task.wait(1)
        WorldBuilder.BuildUpsideDown()
        GameState.worldLoaded = true
        print("[Init] ✅ Mundos construidos correctamente.")

        -- Iniciar sistemas
        task.wait(2)
        MonsterSystem.StartSpawner()
        print("[Init] ✅ Spawner de Demogorgones iniciado.")

        -- Spawnear Vecna después de 60 segundos (dar tiempo a los jugadores)
        task.delay(60, function()
            VecnaSystem.SpawnVecna()
        end)
        print("[Init] ✅ Vecna spawneará en 60 segundos.")

        -- Ciclo día/noche
        StartDayNightCycle()
        print("[Init] ✅ Ciclo día/noche iniciado.")
    end)

    -- Conectar eventos de jugadores
    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)

    -- Para jugadores que ya estén en el servidor
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            OnPlayerAdded(player)
        end)
    end

    -- Conectar remote events
    SetupRemoteListeners()

    -- Guardado automático cada 2 minutos
    task.spawn(function()
        while true do
            task.wait(120)
            for _, player in ipairs(Players:GetPlayers()) do
                DataSystem.SaveData(player)
            end
            print("[DataSystem] ✅ Guardado automático completado.")
        end
    end)

    -- Contador de juego
    task.spawn(function()
        while true do
            task.wait(1)
            GameState.gameTime = GameState.gameTime + 1
        end
    end)

    print("[Init] 🎮 ¡Servidor iniciado correctamente! Esperando jugadores...")
end

-- ═══════════════════════════════════════════════════════
--              EJECUTAR INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════
Initialize()

-- ═══════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════
--
--    SCRIPT DE CLIENTE (LocalScript en StarterPlayerScripts)
--    Nombre: ClientHandler
--    COPIA ESTO EN UN NUEVO LocalScript
--
-- ══════════════════════════════════════════════════════
--[[

-- ╔══════════════════════════════════════════════╗
-- ║     CLIENT HANDLER - STRANGER THINGS UI     ║
-- ║        LocalScript - StarterPlayerScripts    ║
-- ╚══════════════════════════════════════════════╝

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local mouse = player:GetMouse()

-- Esperar a que los remotes estén listos
local RemotesFolder = ReplicatedStorage:WaitForChild("StrangerThingsRemotes", 10)
if not RemotesFolder then
    warn("[Client] No se encontraron los RemoteEvents.")
    return
end

local function GetRemote(name)
    return RemotesFolder:WaitForChild(name, 5)
end

-- ═══════════════════════════════════════════════════════
--              COLORES Y ESTILOS PIXEL ART
-- ═══════════════════════════════════════════════════════
local PIXEL_COLORS = {
    bg        = Color3.fromRGB(10, 10, 20),
    bgLight   = Color3.fromRGB(20, 20, 40),
    border    = Color3.fromRGB(60, 60, 120),
    red       = Color3.fromRGB(220, 20, 60),
    blue      = Color3.fromRGB(30, 100, 255),
    gold      = Color3.fromRGB(255, 215, 0),
    white     = Color3.fromRGB(240, 240, 255),
    green     = Color3.fromRGB(50, 200, 80),
    purple    = Color3.fromRGB(180, 0, 255),
    darkRed   = Color3.fromRGB(100, 0, 20),
}

-- ═══════════════════════════════════════════════════════
--              CREAR SCREENGUI PRINCIPAL
-- ═══════════════════════════════════════════════════════
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "StrangerThingsUI"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = playerGui

-- ═══════════════════════════════════════════════════════
--              HUD PRINCIPAL (Pixel Art Style)
-- ═══════════════════════════════════════════════════════

-- Barra de vida (esquina superior izquierda)
local HUDFrame = Instance.new("Frame")
HUDFrame.Name = "HUD"
HUDFrame.Size = UDim2.new(0, 280, 0, 110)
HUDFrame.Position = UDim2.new(0, 10, 0, 10)
HUDFrame.BackgroundColor3 = PIXEL_COLORS.bg
HUDFrame.BackgroundTransparency = 0.2
HUDFrame.BorderColor3 = PIXEL_COLORS.border
HUDFrame.BorderSizePixel = 2
HUDFrame.Parent = MainGui

-- Título del HUD
local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, 0, 0.2, 0)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "▶ STRANGER THINGS"
hudTitle.TextColor3 = PIXEL_COLORS.red
hudTitle.TextScaled = true
hudTitle.Font = Enum.Font.Code
hudTitle.Parent = HUDFrame

-- Barra de HP
local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(0.3, 0, 0.22, 0)
hpLabel.Position = UDim2.new(0, 5, 0.22, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "❤ HP"
hpLabel.TextColor3 = PIXEL_COLORS.red
hpLabel.TextScaled = true
hpLabel.Font = Enum.Font.Code
hpLabel.Parent = HUDFrame

local hpBarBg = Instance.new("Frame")
hpBarBg.Size = UDim2.new(0.65, 0, 0.2, 0)
hpBarBg.Position = UDim2.new(0.32, 0, 0.23, 0)
hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
hpBarBg.BorderColor3 = PIXEL_COLORS.red
hpBarBg.BorderSizePixel = 1
hpBarBg.Parent = HUDFrame

local hpBar = Instance.new("Frame")
hpBar.Name = "HPBar"
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = PIXEL_COLORS.red
hpBar.BorderSizePixel = 0
hpBar.Parent = hpBarBg

local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "100/100"
hpText.TextColor3 = PIXEL_COLORS.white
hpText.TextScaled = true
hpText.Font = Enum.Font.Code
hpText.Parent = hpBarBg

-- Barra de XP
local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.new(0.3, 0, 0.22, 0)
xpLabel.Position = UDim2.new(0, 5, 0.48, 0)
xpLabel.BackgroundTransparency = 1
xpLabel.Text = "⭐ XP"
xpLabel.TextColor3 = PIXEL_COLORS.gold
xpLabel.TextScaled = true
xpLabel.Font = Enum.Font.Code
xpLabel.Parent = HUDFrame

local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(0.65, 0, 0.2, 0)
xpBarBg.Position = UDim2.new(0.32, 0, 0.49, 0)
xpBarBg.BackgroundColor3 = Color3.fromRGB(40, 35, 0)
xpBarBg.BorderColor3 = PIXEL_COLORS.gold
xpBarBg.BorderSizePixel = 1
xpBarBg.Parent = HUDFrame

local xpBar = Instance.new("Frame")
xpBar.Name = "XPBar"
xpBar.Size = UDim2.new(0, 0, 1, 0) -- Empieza vacía
xpBar.BackgroundColor3 = PIXEL_COLORS.gold
xpBar.BorderSizePixel = 0
xpBar.Parent = xpBarBg

-- Nivel
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, 0, 0.22, 0)
levelLabel.Position = UDim2.new(0, 0, 0.72, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "NIVEL 1  |  Monedas: 100"
levelLabel.TextColor3 = PIXEL_COLORS.white
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.Code
levelLabel.Parent = HUDFrame

-- ═══════════════════════════════════════════════════════
--      INDICADOR DE PODER / COOLDOWN
-- ═══════════════════════════════════════════════════════
local PowerFrame = Instance.new("Frame")
PowerFrame.Name = "PowerIndicator"
PowerFrame.Size = UDim2.new(0, 100, 0, 100)
PowerFrame.Position = UDim2.new(0.5, -50, 1, -120)
PowerFrame.BackgroundColor3 = PIXEL_COLORS.bg
PowerFrame.BackgroundTransparency = 0.2
PowerFrame.BorderColor3 = PIXEL_COLORS.purple
PowerFrame.BorderSizePixel = 2
PowerFrame.Parent = MainGui

local powerIcon = Instance.new("TextLabel")
powerIcon.Name = "PowerIcon"
powerIcon.Size = UDim2.new(1, 0, 0.6, 0)
powerIcon.BackgroundTransparency = 1
powerIcon.Text = "💜"
powerIcon.TextScaled = true
powerIcon.Font = Enum.Font.Code
powerIcon.Parent = PowerFrame

local powerName = Instance.new("TextLabel")
powerName.Size = UDim2.new(1, 0, 0.2, 0)
powerName.Position = UDim2.new(0, 0, 0.6, 0)
powerName.BackgroundTransparency = 1
powerName.Text = "PODER"
powerName.TextColor3 = PIXEL_COLORS.purple
powerName.TextScaled = true
powerName.Font = Enum.Font.Code
powerName.Parent = PowerFrame

local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Name = "CooldownLabel"
cooldownLabel.Size = UDim2.new(1, 0, 0.2, 0)
cooldownLabel.Position = UDim2.new(0, 0, 0.8, 0)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text = "[E] LISTO"
cooldownLabel.TextColor3 = PIXEL_COLORS.green
cooldownLabel.TextScaled = true
cooldownLabel.Font = Enum.Font.Code
cooldownLabel.Parent = PowerFrame

-- ═══════════════════════════════════════════════════════
--        BARRA DE VIDA DE VECNA (Centro superior)
-- ═══════════════════════════════════════════════════════
local VecnaHPFrame = Instance.new("Frame")
VecnaHPFrame.Name = "VecnaHPFrame"
VecnaHPFrame.Size = UDim2.new(0, 500, 0, 60)
VecnaHPFrame.Position = UDim2.new(0.5, -250, 0, 10)
VecnaHPFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 10)
VecnaHPFrame.BackgroundTransparency = 0.2
VecnaHPFrame.BorderColor3 = Color3.fromRGB(180, 0, 255)
VecnaHPFrame.BorderSizePixel = 2
VecnaHPFrame.Visible = false
VecnaHPFrame.Parent = MainGui

local vecnaTitle = Instance.new("TextLabel")
vecnaTitle.Size = UDim2.new(1, 0, 0.4, 0)
vecnaTitle.BackgroundTransparency = 1
vecnaTitle.Text = "☠ VECNA - SEÑOR DEL UPSIDE DOWN ☠"
vecnaTitle.TextColor3 = Color3.fromRGB(180, 0, 255)
vecnaTitle.TextScaled = true
vecnaTitle.Font = Enum.Font.Code
vecnaTitle.Parent = VecnaHPFrame

local vecnaHPBarBg = Instance.new("Frame")
vecnaHPBarBg.Size = UDim2.new(0.95, 0, 0.35, 0)
vecnaHPBarBg.Position = UDim2.new(0.025, 0, 0.45, 0)
vecnaHPBarBg.BackgroundColor3 = Color3.fromRGB(30, 0, 30)
vecnaHPBarBg.BorderColor3 = Color3.fromRGB(180, 0, 255)
vecnaHPBarBg.BorderSizePixel = 1
vecnaHPBarBg.Parent = VecnaHPFrame

local vecnaHPBar = Instance.new("Frame")
vecnaHPBar.Name = "VecnaBar"
vecnaHPBar.Size = UDim2.new(1, 0, 1, 0)
vecnaHPBar.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
vecnaHPBar.BorderSizePixel = 0
vecnaHPBar.Parent = vecnaHPBarBg

local vecnaPhaseLabel = Instance.new("TextLabel")
vecnaPhaseLabel.Name = "PhaseLabel"
vecnaPhaseLabel.Size = UDim2.new(1, 0, 0.2, 0)
vecnaPhaseLabel.Position = UDim2.new(0, 0, 0.82, 0)
vecnaPhaseLabel.BackgroundTransparency = 1
vecnaPhaseLabel.Text = "FASE 1 - DESPERTAR"
vecnaPhaseLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
vecnaPhaseLabel.TextScaled = true
vecnaPhaseLabel.Font = Enum.Font.Code
vecnaPhaseLabel.Parent = VecnaHPFrame

-- ═══════════════════════════════════════════════════════
--        PANTALLA DE SELECCIÓN DE PERSONAJE
-- ═══════════════════════════════════════════════════════
local CharSelectScreen = Instance.new("Frame")
CharSelectScreen.Name = "CharacterSelect"
CharSelectScreen.Size = UDim2.new(1, 0, 1, 0)
CharSelectScreen.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
CharSelectScreen.BorderSizePixel = 0
CharSelectScreen.Visible = false
CharSelectScreen.ZIndex = 10
CharSelectScreen.Parent = MainGui

-- Fondo animado (estilo pixel art con scanlines)
local scanlines = Instance.new("Frame")
scanlines.Size = UDim2.new(1, 0, 1, 0)
scanlines.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scanlines.BackgroundTransparency = 0.85
scanlines.BorderSizePixel = 0
scanlines.ZIndex = 11
scanlines.Parent = CharSelectScreen

-- Título principal
local csTitle = Instance.new("TextLabel")
csTitle.Size = UDim2.new(1, 0, 0.1, 0)
csTitle.Position = UDim2.new(0, 0, 0.02, 0)
csTitle.BackgroundTransparency = 1
csTitle.Text = "☠  STRANGER THINGS: THE UPSIDE DOWN BATTLE  ☠"
csTitle.TextColor3 = Color3.fromRGB(220, 20, 60)
csTitle.TextScaled = true
csTitle.Font = Enum.Font.Code
csTitle.ZIndex = 12
csTitle.Parent = CharSelectScreen

local csSubtitle = Instance.new("TextLabel")
csSubtitle.Size = UDim2.new(1, 0, 0.05, 0)
csSubtitle.Position = UDim2.new(0, 0, 0.11, 0)
csSubtitle.BackgroundTransparency = 1
csSubtitle.Text = ">> SELECCIONA TU PERSONAJE <<"
csSubtitle.TextColor3 = Color3.fromRGB(180, 0, 255)
csSubtitle.TextScaled = true
csSubtitle.Font = Enum.Font.Code
csSubtitle.ZIndex = 12
csSubtitle.Parent = CharSelectScreen

-- Contenedor de personajes (scroll horizontal)
local charContainer = Instance.new("ScrollingFrame")
charContainer.Size = UDim2.new(0.85, 0, 0.55, 0)
charContainer.Position = UDim2.new(0.075, 0, 0.17, 0)
charContainer.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
charContainer.BackgroundTransparency = 0.3
charContainer.BorderColor3 = Color3.fromRGB(60, 0, 120)
charContainer.BorderSizePixel = 2
charContainer.ScrollBarThickness = 4
charContainer.CanvasSize = UDim2.new(0, 900, 0, 0)
charContainer.ZIndex = 12
charContainer.Parent = CharSelectScreen

local uiLayout = Instance.new("UIListLayout")
uiLayout.FillDirection = Enum.FillDirection.Horizontal
uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiLayout.Padding = UDim.new(0, 10)
uiLayout.Parent = charContainer

-- Panel de detalles del personaje seleccionado
local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0.85, 0, 0.25, 0)
detailPanel.Position = UDim2.new(0.075, 0, 0.73, 0)
detailPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
detailPanel.BackgroundTransparency = 0.3
detailPanel.BorderColor3 = Color3.fromRGB(60, 0, 120)
detailPanel.BorderSizePixel = 2
detailPanel.ZIndex = 12
detailPanel.Parent = CharSelectScreen

local detailName = Instance.new("TextLabel")
detailName.Name = "DetailName"
detailName.Size = UDim2.new(0.4, 0, 0.35, 0)
detailName.Position = UDim2.new(0.02, 0, 0.05, 0)
detailName.BackgroundTransparency = 1
detailName.Text = "Selecciona un personaje"
detailName.TextColor3 = PIXEL_COLORS.gold
detailName.TextScaled = true
detailName.Font = Enum.Font.Code
detailName.TextXAlignment = Enum.TextXAlignment.Left
detailName.ZIndex = 13
detailName.Parent = detailPanel

local detailDesc = Instance.new("TextLabel")
detailDesc.Name = "DetailDesc"
detailDesc.Size = UDim2.new(0.58, 0, 0.55, 0)
detailDesc.Position = UDim2.new(0.02, 0, 0.4, 0)
detailDesc.BackgroundTransparency = 1
detailDesc.Text = ""
detailDesc.TextColor3 = PIXEL_COLORS.white
detailDesc.TextScaled = true
detailDesc.Font = Enum.Font.Code
detailDesc.TextXAlignment = Enum.TextXAlignment.Left
detailDesc.TextWrapped = true
detailDesc.ZIndex = 13
detailDesc.Parent = detailPanel

-- Stats del personaje
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0.35, 0, 0.9, 0)
statsFrame.Position = UDim2.new(0.63, 0, 0.05, 0)
statsFrame.BackgroundTransparency = 1
statsFrame.ZIndex = 13
statsFrame.Parent = detailPanel

-- Botón de selección / compra
local selectBtn = Instance.new("TextButton")
selectBtn.Name = "SelectBtn"
selectBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
selectBtn.Position = UDim2.new(0.79, 0, 0.15, 0)
selectBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
selectBtn.BorderColor3 = PIXEL_COLORS.green
selectBtn.BorderSizePixel = 2
selectBtn.Text = "✅ SELECCIONAR"
selectBtn.TextColor3 = PIXEL_COLORS.white
selectBtn.TextScaled = true
selectBtn.Font = Enum.Font.Code
selectBtn.ZIndex = 13
selectBtn.Parent = detailPanel

-- Botón para cerrar la pantalla de selección
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 120, 0, 40)
closeBtn.Position = UDim2.new(1, -130, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
closeBtn.BorderColor3 = PIXEL_COLORS.red
closeBtn.BorderSizePixel = 2
closeBtn.Text = "✖ CERRAR"
closeBtn.TextColor3 = PIXEL_COLORS.white
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Code
closeBtn.ZIndex = 13
closeBtn.Parent = CharSelectScreen

closeBtn.MouseButton1Click:Connect(function()
    CharSelectScreen.Visible = false
end)

-- Variable para el personaje actualmente visto en detalles
local selectedCharId = nil

-- Función para crear una tarjeta de personaje
local function CreateCharCard(charInfo)
    local card = Instance.new("Frame")
    card.Name = "CharCard_" .. charInfo.id
    card.Size = UDim2.new(0, 150, 1, -20)
    card.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    card.BorderColor3 = Color3.fromRGB(60, 0, 120)
    card.BorderSizePixel = 2
    card.ZIndex = 13
    card.Parent = charContainer

    -- Imagen del personaje (pixel art simulado con bloques de color)
    local charPreview = Instance.new("Frame")
    charPreview.Size = UDim2.new(0.9, 0, 0.55, 0)
    charPreview.Position = UDim2.new(0.05, 0, 0.03, 0)
    charPreview.BackgroundColor3 = Color3.fromRGB(charInfo.colorR * 255, charInfo.colorG * 255, charInfo.colorB * 255)
    charPreview.BorderSizePixel = 0
    charPreview.ZIndex = 14
    charPreview.Parent = card

    -- Pixel art básico del personaje (bloques de colores)
    local pixelBody = Instance.new("Frame")
    pixelBody.Size = UDim2.new(0.5, 0, 0.6, 0)
    pixelBody.Position = UDim2.new(0.25, 0, 0.3, 0)
    pixelBody.BackgroundColor3 = Color3.fromRGB(charInfo.colorR * 255 * 0.7, charInfo.colorG * 255 * 0.7, charInfo.colorB * 255 * 0.7)
    pixelBody.BorderSizePixel = 0
    pixelBody.ZIndex = 15
    pixelBody.Parent = charPreview

    local pixelHead = Instance.new("Frame")
    pixelHead.Size = UDim2.new(0.5, 0, 0.35, 0)
    pixelHead.Position = UDim2.new(0.25, 0, 0, 0)
    pixelHead.BackgroundColor3 = Color3.fromRGB(charInfo.colorR * 255, charInfo.colorG * 255, charInfo.colorB * 255)
    pixelHead.BorderSizePixel = 0
    pixelHead.ZIndex = 15
    pixelHead.Parent = charPreview

    -- Texto del nombre en la tarjeta
    local cardName = Instance.new("TextLabel")
    cardName.Size = UDim2.new(1, 0, 0.15, 0)
    cardName.Position = UDim2.new(0, 0, 0.58, 0)
    cardName.BackgroundTransparency = 1
    cardName.Text = charInfo.name
    cardName.TextColor3 = Color3.fromRGB(charInfo.colorR * 255, charInfo.colorG * 255, charInfo.colorB * 255)
    cardName.TextScaled = true
    cardName.Font = Enum.Font.Code
    cardName.ZIndex = 14
    cardName.Parent = card

    -- Subtítulo
    local cardSub = Instance.new("TextLabel")
    cardSub.Size = UDim2.new(1, 0, 0.1, 0)
    cardSub.Position = UDim2.new(0, 0, 0.73, 0)
    cardSub.BackgroundTransparency = 1
    cardSub.Text = charInfo.subtitle
    cardSub.TextColor3 = Color3.fromRGB(180, 180, 200)
    cardSub.TextScaled = true
    cardSub.Font = Enum.Font.Code
    cardSub.ZIndex = 14
    cardSub.Parent = card

    -- Estado (desbloqueado / bloqueado / precio)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0.13, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.85, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Code
    statusLabel.TextScaled = true
    statusLabel.ZIndex = 14
    statusLabel.Parent = card

    if charInfo.isSelected then
        statusLabel.Text = "▶ ACTIVO"
        statusLabel.TextColor3 = PIXEL_COLORS.green
        card.BorderColor3 = PIXEL_COLORS.green
        card.BorderSizePixel = 3
    elseif charInfo.unlocked then
        statusLabel.Text = "✅ DESBLOQUEADO"
        statusLabel.TextColor3 = PIXEL_COLORS.blue
    else
        statusLabel.Text = "🔒 " .. charInfo.cost .. " 💰"
        statusLabel.TextColor3 = PIXEL_COLORS.gold
        -- Overlay de bloqueado
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.5
        lockOverlay.BorderSizePixel = 0
        lockOverlay.ZIndex = 16
        lockOverlay.Parent = card
        local lockIcon = Instance.new("TextLabel")
        lockIcon.Size = UDim2.new(1, 0, 0.4, 0)
        lockIcon.Position = UDim2.new(0, 0, 0.1, 0)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Text = "🔒"
        lockIcon.TextScaled = true
        lockIcon.ZIndex = 17
        lockIcon.Parent = lockOverlay
    end

    -- Click en la tarjeta para ver detalles
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 18
    btn.Parent = card

    btn.MouseButton1Click:Connect(function()
        selectedCharId = charInfo.id
        -- Actualizar panel de detalles
        detailName.Text = charInfo.name .. " - " .. charInfo.subtitle
        detailName.TextColor3 = Color3.fromRGB(charInfo.colorR * 255, charInfo.colorG * 255, charInfo.colorB * 255)
        detailDesc.Text = charInfo.description .. "\n\n" .. charInfo.lore
        -- Actualizar botón
        if charInfo.unlocked or charInfo.isSelected then
            if charInfo.isSelected then
                selectBtn.Text = "▶ EN USO"
                selectBtn.BackgroundColor3 = PIXEL_COLORS.blue
            else
                selectBtn.Text = "✅ SELECCIONAR"
                selectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            end
        else
            selectBtn.Text = "💰 COMPRAR " .. charInfo.cost
            selectBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 0)
        end
    end)

    return card
end

-- Cargar tarjetas de personajes
local function LoadCharacterCards()
    -- Limpiar tarjetas existentes
    for _, child in ipairs(charContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Obtener lista de personajes del servidor
    local charList = RemotesFolder:FindFirstChild("GetCharacterList") and
                     RemotesFolder.GetCharacterList:InvokeServer()

    if charList then
        for _, charInfo in ipairs(charList) do
            CreateCharCard(charInfo)
        end
    end
end

-- Botón de selección / compra
selectBtn.MouseButton1Click:Connect(function()
    if not selectedCharId then return end
    local charList = RemotesFolder.GetCharacterList:InvokeServer()
    local charInfo = nil
    for _, c in ipairs(charList) do
        if c.id == selectedCharId then charInfo = c break end
    end
    if not charInfo then return end

    if charInfo.unlocked or charInfo.isSelected then
        GetRemote("SelectCharacter"):FireServer(selectedCharId)
        task.delay(0.5, function()
            CharSelectScreen.Visible = false
        end)
    else
        GetRemote("PurchaseCharacter"):FireServer(selectedCharId)
        task.delay(0.5, LoadCharacterCards)
    end
end)

-- ═══════════════════════════════════════════════════════
--        SISTEMA DE NOTIFICACIONES (Pixel Art)
-- ═══════════════════════════════════════════════════════
local notifQueue = {}
local notifActive = false

local function ShowNotification(title, message, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 350, 0, 80)
    notif.Position = UDim2.new(1, 10, 0.7, 0)
    notif.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    notif.BackgroundTransparency = 0.1
    notif.BorderColor3 = color or PIXEL_COLORS.blue
    notif.BorderSizePixel = 2
    notif.ZIndex = 20
    notif.Parent = MainGui

    local notifBar = Instance.new("Frame")
    notifBar.Size = UDim2.new(0.03, 0, 1, 0)
    notifBar.BackgroundColor3 = color or PIXEL_COLORS.blue
    notifBar.BorderSizePixel = 0
    notifBar.ZIndex = 21
    notifBar.Parent = notif

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.95, 0, 0.45, 0)
    titleLbl.Position = UDim2.new(0.05, 0, 0.05, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = color or PIXEL_COLORS.gold
    titleLbl.TextScaled = true
    titleLbl.Font = Enum.Font.Code
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 21
    titleLbl.Parent = notif

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(0.95, 0, 0.45, 0)
    msgLbl.Position = UDim2.new(0.05, 0, 0.52, 0)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = message
    msgLbl.TextColor3 = PIXEL_COLORS.white
    msgLbl.TextScaled = true
    msgLbl.Font = Enum.Font.Code
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.ZIndex = 21
    msgLbl.Parent = notif

    -- Animar entrada
    TweenService:Create(notif,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -360, 0.7, 0)}
    ):Play()

    -- Auto-eliminar después de 4 segundos
    task.delay(4, function()
        if notif and notif.Parent then
            TweenService:Create(notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 10, 0.7, 0)}
            ):Play()
            task.delay(0.35, function()
                if notif and notif.Parent then notif:Destroy() end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════
--          NÚMEROS DE DAÑO FLOTANTES
-- ═══════════════════════════════════════════════════════
local camera = workspace.CurrentCamera

local function ShowDamageNumber(worldPos, damage, isCrit)
    local screenPos, onScreen = camera:WorldToScreenPoint(worldPos + Vector3.new(0, 2, 0))
    if not onScreen then return end

    local dmgLabel = Instance.new("TextLabel")
    dmgLabel.Size = UDim2.new(0, isCrit and 80 or 60, 0, isCrit and 40 or 30)
    dmgLabel.Position = UDim2.new(0, screenPos.X - (isCrit and 40 or 30), 0, screenPos.Y - 20)
    dmgLabel.BackgroundTransparency = 1
    dmgLabel.Text = (isCrit and "⚡" or "") .. tostring(damage)
    dmgLabel.TextColor3 = isCrit and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
    dmgLabel.TextScaled = true
    dmgLabel.Font = Enum.Font.Code
    dmgLabel.ZIndex = 25
    dmgLabel.Parent = MainGui

    -- Animar hacia arriba y desvanecer
    TweenService:Create(dmgLabel,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0, screenPos.X - (isCrit and 40 or 30), 0, screenPos.Y - 80),
            TextTransparency = 1
        }
    ):Play()
    game:GetService("Debris"):AddItem(dmgLabel, 1.3)
end

-- ═══════════════════════════════════════════════════════
--         BOTONES DE ACCIÓN (HUD inferior)
-- ═══════════════════════════════════════════════════════
local ActionBar = Instance.new("Frame")
ActionBar.Size = UDim2.new(0, 300, 0, 50)
ActionBar.Position = UDim2.new(0, 10, 1, -60)
ActionBar.BackgroundTransparency = 1
ActionBar.Parent = MainGui

-- Botón de selección de personaje
local charBtn = Instance.new("TextButton")
charBtn.Size = UDim2.new(0, 140, 0, 44)
charBtn.Position = UDim2.new(0, 0, 0, 0)
charBtn.BackgroundColor3 = Color3.fromRGB(20, 0, 50)
charBtn.BorderColor3 = PIXEL_COLORS.purple
charBtn.BorderSizePixel = 2
charBtn.Text = "👤 PERSONAJES"
charBtn.TextColor3 = PIXEL_COLORS.white
charBtn.TextScaled = true
charBtn.Font = Enum.Font.Code
charBtn.Parent = ActionBar

charBtn.MouseButton1Click:Connect(function()
    LoadCharacterCards()
    CharSelectScreen.Visible = true
end)

-- Botón de portal
local portalBtn = Instance.new("TextButton")
portalBtn.Size = UDim2.new(0, 140, 0, 44)
portalBtn.Position = UDim2.new(0, 150, 0, 0)
portalBtn.BackgroundColor3 = Color3.fromRGB(30, 0, 30)
portalBtn.BorderColor3 = Color3.fromRGB(180, 0, 255)
portalBtn.BorderSizePixel = 2
portalBtn.Text = "🌀 PORTAL"
portalBtn.TextColor3 = PIXEL_COLORS.white
portalBtn.TextScaled = true
portalBtn.Font = Enum.Font.Code
portalBtn.Parent = ActionBar

portalBtn.MouseButton1Click:Connect(function()
    GetRemote("EnterPortal"):FireServer()
end)

-- ═══════════════════════════════════════════════════════
--         INPUT DEL JUGADOR (Teclado y Mouse)
-- ═══════════════════════════════════════════════════════
local powerOnCooldown = false
local POWER_COOLDOWN_TIME = 4

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not player.Character then return end

    -- E: Usar poder
    if input.KeyCode == Enum.KeyCode.E then
        if not powerOnCooldown then
            local targetPos = mouse.Hit.Position
            GetRemote("UsePower"):FireServer(targetPos)
            powerOnCooldown = true
            cooldownLabel.Text = "[E] " .. POWER_COOLDOWN_TIME .. "s"
            cooldownLabel.TextColor3 = PIXEL_COLORS.red
            local cdLeft = POWER_COOLDOWN_TIME
            local conn
            conn = RunService.Heartbeat:Connect(function(dt)
                cdLeft = cdLeft - dt
                if cdLeft <= 0 then
                    powerOnCooldown = false
                    cooldownLabel.Text = "[E] LISTO"
                    cooldownLabel.TextColor3 = PIXEL_COLORS.green
                    conn:Disconnect()
                else
                    cooldownLabel.Text = "[E] " .. math.ceil(cdLeft) .. "s"
                end
            end)
        end
    end

    -- F: Ataque melee
    if input.KeyCode == Enum.KeyCode.F then
        local targetPos = mouse.Hit.Position
        GetRemote("MeleeAttack"):FireServer(targetPos)
    end

    -- Tab: Abrir selección de personaje
    if input.KeyCode == Enum.KeyCode.Tab then
        if CharSelectScreen.Visible then
            CharSelectScreen.Visible = false
        else
            LoadCharacterCards()
            CharSelectScreen.Visible = true
        end
    end
end)

-- Click izquierdo: también ataque melee
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local targetPos = mouse.Hit.Position
        GetRemote("MeleeAttack"):FireServer(targetPos)
    end
end)

-- ═══════════════════════════════════════════════════════
--         ESCUCHAR EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════

-- Actualizar HP
GetRemote("UpdateHealthUI").OnClientEvent:Connect(function(hp, maxHp)
    local pct = math.clamp(hp / maxHp, 0, 1)
    TweenService:Create(hpBar,
        TweenInfo.new(0.2),
        {Size = UDim2.new(pct, 0, 1, 0)}
    ):Play()
    hpText.Text = math.floor(hp) .. "/" .. maxHp
    hpBar.BackgroundColor3 = pct > 0.5 and PIXEL_COLORS.red or
                             (pct > 0.25 and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(255, 50, 0))
end)

-- Actualizar XP
GetRemote("UpdateXPUI").OnClientEvent:Connect(function(xp, level, maxXp)
    local pct = math.clamp(xp / maxXp, 0, 1)
    TweenService:Create(xpBar,
        TweenInfo.new(0.3),
        {Size = UDim2.new(pct, 0, 1, 0)}
    ):Play()
    levelLabel.Text = "NIVEL " .. level .. "  |  XP: " .. xp .. "/" .. maxXp
end)

-- Actualizar monedas
GetRemote("UpdateCoinsUI").OnClientEvent:Connect(function(coins)
    local lvlText = levelLabel.Text
    levelLabel.Text = lvlText:match("NIVEL %d+") .. "  |  💰 " .. coins
end)

-- Notificaciones
GetRemote("ShowNotification").OnClientEvent:Connect(function(title, message, color)
    ShowNotification(title, message, color)
end)

-- Números de daño
GetRemote("ShowDamageNumber").OnClientEvent:Connect(function(pos, damage, isCrit)
    ShowDamageNumber(pos, damage, isCrit)
end)

-- Actualizar HP de Vecna
GetRemote("VecnaHealthUpdate").OnClientEvent:Connect(function(hp, maxHp, phase)
    VecnaHPFrame.Visible = true
    local pct = math.clamp(hp / maxHp, 0, 1)
    TweenService:Create(vecnaHPBar,
        TweenInfo.new(0.4),
        {Size = UDim2.new(pct, 0, 1, 0)}
    ):Play()
    local phaseColors = {
        [1] = Color3.fromRGB(180, 0, 255),
        [2] = Color3.fromRGB(255, 100, 0),
        [3] = Color3.fromRGB(255, 0, 0),
    }
    vecnaHPBar.BackgroundColor3 = phaseColors[phase] or Color3.fromRGB(180, 0, 255)
    local phaseNames = {[1]="FASE 1 - DESPERTAR", [2]="FASE 2 - FURIA", [3]="FASE 3 - APOCALIPSIS"}
    vecnaPhaseLabel.Text = phaseNames[phase] or ""
end)

-- Boss derrotado
GetRemote("BossDefeated").OnClientEvent:Connect(function()
    task.delay(3, function()
        TweenService:Create(vecnaHPFrame,
            TweenInfo.new(1),
            {BackgroundTransparency = 1}
        ):Play()
        task.delay(1, function()
            VecnaHPFrame.Visible = false
        end)
    end)
end)

-- Transición de mundo
GetRemote("WorldTransition").OnClientEvent:Connect(function(worldName)
    -- Flash de transición
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = worldName == "UpsideDown" and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(200, 200, 255)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.ZIndex = 30
    flash.Parent = MainGui

    local worldLabel = Instance.new("TextLabel")
    worldLabel.Size = UDim2.new(1, 0, 0.2, 0)
    worldLabel.Position = UDim2.new(0, 0, 0.4, 0)
    worldLabel.BackgroundTransparency = 1
    worldLabel.Text = worldName == "UpsideDown" and "⬛ ENTRANDO AL UPSIDE DOWN..." or "🌤 REGRESANDO A HAWKINS..."
    worldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    worldLabel.TextScaled = true
    worldLabel.Font = Enum.Font.Code
    worldLabel.ZIndex = 31
    worldLabel.Parent = MainGui

    task.delay(1.5, function()
        TweenService:Create(flash, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
        task.delay(0.9, function()
            flash:Destroy()
            worldLabel:Destroy()
        end)
    end)
end)

-- Muerte del jugador
GetRemote("PlayerDied").OnClientEvent:Connect(function(killerName)
    ShowNotification("💀 HAS MUERTO", "Fuiste derrotado. Respawneando...", PIXEL_COLORS.red)
end)

-- Pantalla de instrucciones al inicio
task.delay(1, function()
    ShowNotification(
        "🎮 CONTROLES",
        "E: Poder | F/Click: Melee | Tab: Personajes | Portal: Upside Down",
        PIXEL_COLORS.blue
    )
end)

print("[Client] ✅ UI de Stranger Things cargada correctamente.")
]]

--[[
    ═══════════════════════════════════════════════════════════
    FIN DEL SCRIPT - RESUMEN DE LA ESTRUCTURA DEL JUEGO
    ═══════════════════════════════════════════════════════════

    📁 ESTRUCTURA DE ARCHIVOS EN ROBLOX STUDIO:
    ├── ServerScriptService/
    │   └── StrangerThings_ServerScript (este archivo)
    ├── StarterPlayerScripts/
    │   └── ClientHandler (el LocalScript dentro de los comentarios --[[ arriba]])
    └── ReplicatedStorage/
        └── StrangerThingsRemotes/ (creado automáticamente)

    🌍 MUNDOS:
    ├── World_Hawkins (suelo pixel art, casas, árboles, farolas, lago, lab)
    └── World_UpsideDown (suelo oscuro, enredaderas, arena de Vecna, pilares)

    👥 PERSONAJES:
    ├── Eleven    - Telekinesis AoE (desbloqueado por defecto)
    ├── Mike      - Comunicación/Curación (desbloqueado por defecto)
    ├── Dustin    - Trampas de Luz (150 monedas)
    ├── Will      - Visión del Upside Down (200 monedas)
    └── Max       - Carga de Patineta (250 monedas)

    ⚔️ SISTEMA DE COMBATE:
    ├── Poderes: Tecla E (cooldown por personaje)
    ├── Melee: Click o tecla F
    ├── Números de daño flotantes
    ├── Sistema de críticos (15%)
    └── Knockback

    👹 ENEMIGOS:
    ├── Demogorgones (spawn automático, IA de persecución)
    └── Vecna (Boss con 3 fases, 5000 HP)

    📊 PROGRESIÓN:
    ├── Sistema de XP y niveles (máx. 50)
    ├── Monedas para desbloquear personajes
    ├── Guardado automático con DataStore
    └── Regeneración de vida fuera de combate

    🎮 CONTROLES:
    ├── E: Usar poder del personaje
    ├── F o Click: Ataque melee
    ├── Tab: Pantalla de selección de personajes
    └── Portal: Botón en HUD o acercarse al portal

    🔊 AUDIO: Configurar Sound IDs en SOUND_IDS para música del juego
    🎨 ASSETS: Configurar IDs de Roblox para texturas pixel art
    ═══════════════════════════════════════════════════════════
]]
