--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║        STRANGER THINGS: THE UPSIDE DOWN BATTLE              ║
    ║           Roblox Server Script - Main Game Logic            ║
    ║     Estilo Pixel Art | Inspirado en Soul Knight             ║
    ╚══════════════════════════════════════════════════════════════╝

    INSTRUCCIONES DE INSTALACIÓN:
    1. Crea un nuevo lugar en Roblox Studio
    2. Coloca este Script en ServerScriptService
    3. Crea un LocalScript en StarterPlayerScripts llamado "ClientHandler"
    4. Crea un Script en ServerScriptService llamado "WorldBuilder" (ver abajo)
    5. Sube los assets de pixel art desde la Toolbox

    ESTRUCTURA DEL JUEGO:
    - Mundo 1: Hawkins (Mundo Normal) - pixel art colorido
    - Mundo 2: The Upside Down - pixel art oscuro/rojo
    - Boss Final: Vecna
    - 5 Personajes: Eleven, Mike, Dustin, Will, Max
    - 5 Poderes: Telekinesis, Comunicación, Trampa de Luz, Visión, Patineta
]]

-- ═══════════════════════════════════════════════════════
--                    SERVICIOS CORE
-- ═══════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- ═══════════════════════════════════════════════════════
--               DATASTORES (GUARDADO DE DATOS)
-- ═══════════════════════════════════════════════════════
local PlayerDataStore = DataStoreService:GetDataStore("StrangerThingsPlayerData_v1")

-- ═══════════════════════════════════════════════════════
--              CONFIGURACIÓN GLOBAL DEL JUEGO
-- ═══════════════════════════════════════════════════════
local CONFIG = {
    -- Mundos
    WORLD_HAWKINS_SIZE     = Vector3.new(400, 1, 400),
    WORLD_UPSIDE_SIZE      = Vector3.new(400, 1, 400),
    TILE_SIZE              = 4, -- Tamaño de cada "pixel" en el mundo

    -- Jugadores
    MAX_PLAYERS            = 10,
    RESPAWN_TIME           = 5,
    MAX_HEALTH             = 100,
    HEALTH_REGEN_RATE      = 1, -- HP por segundo fuera de combate

    -- Combate
    POWER_COOLDOWN         = 3,
    MELEE_DAMAGE           = 15,
    POWER_BASE_DAMAGE      = 30,
    KNOCKBACK_FORCE        = 50,

    -- Vecna (Boss)
    VECNA_MAX_HEALTH       = 5000,
    VECNA_PHASE2_HP        = 2500,  -- Cambia de fase al 50% HP
    VECNA_PHASE3_HP        = 1000,  -- Fase final al 20% HP
    VECNA_ATTACK_INTERVAL  = 2.5,
    VECNA_MOVE_SPEED       = 14,
    VECNA_SPAWN_POS        = Vector3.new(0, 5, -180),

    -- Monstruos del Upside Down
    DEMOGORGON_HEALTH      = 200,
    DEMOGORGON_DAMAGE      = 20,
    DEMOGORGON_SPEED       = 16,
    MAX_DEMOGORGONS        = 15,
    SPAWNER_INTERVAL       = 12,

    -- Experiencia y niveles
    XP_PER_KILL_MONSTER    = 25,
    XP_PER_KILL_BOSS       = 500,
    XP_PER_LEVEL           = 100,
    MAX_LEVEL              = 50,

    -- Portal al Upside Down
    PORTAL_POSITION        = Vector3.new(0, 3, 10),
    PORTAL_COOLDOWN        = 30,

    -- Colores del mundo (Pixel Art Palette)
    COLORS = {
        -- Hawkins (Mundo Normal)
        HAWKINS_GRASS      = Color3.fromRGB(76, 153, 0),
        HAWKINS_GRASS_DARK = Color3.fromRGB(56, 120, 0),
        HAWKINS_PATH       = Color3.fromRGB(180, 140, 80),
        HAWKINS_ROAD       = Color3.fromRGB(60, 60, 60),
        HAWKINS_BUILDING   = Color3.fromRGB(210, 180, 140),
        HAWKINS_ROOF       = Color3.fromRGB(139, 69, 19),
        HAWKINS_SKY        = Color3.fromRGB(100, 150, 255),
        HAWKINS_TREE       = Color3.fromRGB(34, 100, 34),
        HAWKINS_TRUNK      = Color3.fromRGB(101, 67, 33),
        HAWKINS_WATER      = Color3.fromRGB(64, 128, 255),

        -- Upside Down
        UD_GROUND          = Color3.fromRGB(20, 8, 8),
        UD_VINE            = Color3.fromRGB(80, 20, 20),
        UD_PARTICLES       = Color3.fromRGB(180, 0, 0),
        UD_SPORE           = Color3.fromRGB(100, 0, 30),
        UD_SKY             = Color3.fromRGB(30, 0, 0),
        UD_GLOW            = Color3.fromRGB(255, 50, 0),
        UD_ROCK            = Color3.fromRGB(40, 15, 15),

        -- UI
        UI_RED             = Color3.fromRGB(220, 20, 60),
        UI_BLUE            = Color3.fromRGB(30, 100, 255),
        UI_GOLD            = Color3.fromRGB(255, 215, 0),
        UI_DARK            = Color3.fromRGB(10, 10, 20),
        UI_WHITE           = Color3.fromRGB(240, 240, 255),

        -- Personajes (pixel palette)
        CHAR_ELEVEN        = Color3.fromRGB(255, 200, 150),
        CHAR_MIKE          = Color3.fromRGB(200, 100, 50),
        CHAR_DUSTIN        = Color3.fromRGB(150, 200, 255),
        CHAR_WILL          = Color3.fromRGB(180, 180, 220),
        CHAR_MAX           = Color3.fromRGB(255, 100, 100),

        -- Poderes
        POWER_TELEKINESIS  = Color3.fromRGB(200, 0, 255),
        POWER_FIREBALL     = Color3.fromRGB(255, 100, 0),
        POWER_LIGHT        = Color3.fromRGB(255, 255, 0),
        POWER_VISION       = Color3.fromRGB(0, 200, 255),
        POWER_SKATEBOARD   = Color3.fromRGB(255, 50, 50),

        -- Vecna
        VECNA_BODY         = Color3.fromRGB(30, 0, 30),
        VECNA_GLOW         = Color3.fromRGB(180, 0, 255),
        VECNA_EYE          = Color3.fromRGB(255, 0, 0),
    }
}

-- ═══════════════════════════════════════════════════════
--           DEFINICIÓN DE PERSONAJES
-- ═══════════════════════════════════════════════════════
local CHARACTERS = {
    {
        id         = "eleven",
        name       = "Eleven",
        subtitle   = "La Niña con Poderes",
        description= "Telekinesis devastadora. Puede mover objetos con su mente y proteger aliados.",
        color      = CONFIG.COLORS.CHAR_ELEVEN,
        hairColor  = Color3.fromRGB(50, 30, 20),
        shirtColor = Color3.fromRGB(180, 180, 200),
        pantsColor = Color3.fromRGB(50, 50, 80),
        power      = "telekinesis",
        stats      = {speed=14, power=10, defense=6, health=100},
        lore       = "Escapó del Lab de Hawkins. Su número: 011.",
        unlocked   = true,
        cost       = 0,
    },
    {
        id         = "mike",
        name       = "Mike Wheeler",
        subtitle   = "El Líder",
        description= "Comunicación con el Upside Down. Aumenta stats de aliados cercanos.",
        color      = COLOR3.fromRGB(200, 120, 60) or Color3.fromRGB(200, 120, 60),
        hairColor  = Color3.fromRGB(30, 20, 10),
        shirtColor = Color3.fromRGB(80, 80, 180),
        pantsColor = Color3.fromRGB(50, 50, 100),
        power      = "communication",
        stats      = {speed=15, power=7, defense=7, health=100},
        lore       = "Líder del Grupo de Dungeons & Dragons.",
        unlocked   = true,
        cost       = 0,
    },
    {
        id         = "dustin",
        name       = "Dustin Henderson",
        subtitle   = "El Ingeniero",
        description= "Trampas de luz. Coloca dispositivos que atrapan enemigos.",
        color      = Color3.fromRGB(220, 190, 140),
        hairColor  = Color3.fromRGB(200, 150, 50),
        shirtColor = Color3.fromRGB(200, 100, 0),
        pantsColor = Color3.fromRGB(80, 60, 40),
        power      = "light_trap",
        stats      = {speed=13, power=8, defense=8, health=100},
        lore       = "Fanático de la ciencia y experto en criaturas.",
        unlocked   = false,
        cost       = 150,
    },
    {
        id         = "will",
        name       = "Will Byers",
        subtitle   = "El Superviviente",
        description= "Visión del Upside Down. Ve a través de las paredes y detecta enemigos.",
        color      = Color3.fromRGB(180, 160, 200),
        hairColor  = Color3.fromRGB(40, 25, 15),
        shirtColor = Color3.fromRGB(100, 150, 80),
        pantsColor = Color3.fromRGB(60, 80, 50),
        power      = "upside_vision",
        stats      = {speed=16, power=6, defense=5, health=120},
        lore       = "Sobrevivió al Upside Down. Conectado a la Mente Colmena.",
        unlocked   = false,
        cost       = 200,
    },
    {
        id         = "max",
        name       = "Max Mayfield",
        subtitle   = "La Patinadora",
        description= "Patineta de velocidad. Carga hacia enemigos causando daño masivo.",
        color      = Color3.fromRGB(255, 130, 130),
        hairColor  = Color3.fromRGB(200, 50, 20),
        shirtColor = Color3.fromRGB(150, 50, 150),
        pantsColor = Color3.fromRGB(50, 30, 80),
        power      = "skateboard_charge",
        stats      = {speed=18, power=9, defense=5, health=90},
        lore       = "Llegó de California. La más rápida del grupo.",
        unlocked   = false,
        cost       = 250,
    },
}

-- ═══════════════════════════════════════════════════════
--              DEFINICIÓN DE PODERES
-- ═══════════════════════════════════════════════════════
local POWERS = {
    telekinesis = {
        name        = "Telekinesis",
        damage      = 40,
        range       = 30,
        cooldown    = 4,
        color       = CONFIG.COLORS.POWER_TELEKINESIS,
        aoe         = true,
        aoeRadius   = 8,
        knockback   = 80,
        description = "Lanza una onda psíquica que aplasta a múltiples enemigos.",
        particle    = "💜",
    },
    communication = {
        name        = "Comunicación",
        damage      = 25,
        range       = 25,
        cooldown    = 3,
        color       = CONFIG.COLORS.POWER_FIREBALL,
        aoe         = false,
        healAlly    = 20,
        buffRadius  = 15,
        description = "Envía señal del Upside Down. Cura aliados y potencia al equipo.",
        particle    = "🔥",
    },
    light_trap = {
        name        = "Trampa de Luz",
        damage      = 35,
        range       = 20,
        cooldown    = 5,
        color       = CONFIG.COLORS.POWER_LIGHT,
        aoe         = true,
        aoeRadius   = 5,
        stunDuration= 3,
        description = "Coloca una trampa de luz deslumbrante que aturde enemigos.",
        particle    = "⚡",
    },
    upside_vision = {
        name        = "Visión del Upside Down",
        damage      = 20,
        range       = 40,
        cooldown    = 6,
        color       = CONFIG.COLORS.POWER_VISION,
        aoe         = false,
        revealRadius= 50,
        slowEffect  = 0.5,
        description = "Visión extradimensional. Ralentiza y revela enemigos ocultos.",
        particle    = "👁️",
    },
    skateboard_charge = {
        name        = "Carga de Patineta",
        damage      = 55,
        range       = 35,
        cooldown    = 5,
        color       = CONFIG.COLORS.POWER_SKATEBOARD,
        aoe         = true,
        aoeRadius   = 4,
        knockback   = 120,
        description = "Carga imparable en patineta. Destruye todo a su paso.",
        particle    = "🛹",
    },
}

-- ═══════════════════════════════════════════════════════
--              ESTADO DEL JUEGO (RUNTIME)
-- ═══════════════════════════════════════════════════════
local GameState = {
    playerData        = {}, -- [userId] = {character, level, xp, coins, kills, deaths}
    playerCooldowns   = {}, -- [userId] = {power = tick, melee = tick}
    demogorgons       = {}, -- Lista de demogorgones activos
    vecna             = nil, -- Referencia al modelo de Vecna
    vecnaHealth       = CONFIG.VECNA_MAX_HEALTH,
    vecnaPhase        = 1,
    vecnaActive       = false,
    portalCooldown    = {},  -- [userId] = tick
    worldLoaded       = false,
    currentEvent      = nil, -- "hawkins_night", "upside_invasion", etc.
    spawnerActive     = false,
    gameTime          = 0,
}

-- ═══════════════════════════════════════════════════════
--           REMOTE EVENTS / FUNCTIONS
-- ═══════════════════════════════════════════════════════
local function SetupRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "StrangerThingsRemotes"
    folder.Parent = ReplicatedStorage

    local remotes = {
        -- Eventos del servidor al cliente
        "UpdateHealthUI",      -- (player, hp, maxHp)
        "UpdateXPUI",          -- (player, xp, level, maxXp)
        "UpdateCoinsUI",       -- (player, coins)
        "SpawnPowerEffect",    -- (position, powerType, color)
        "ShowDamageNumber",    -- (position, damage, isCrit)
        "VecnaHealthUpdate",   -- (hp, maxHp, phase)
        "WorldTransition",     -- (worldName)
        "ShowNotification",    -- (player, title, message, color)
        "PlayerDied",          -- (player, killerName)
        "BossDefeated",        -- ()
        "SpawnDemogorgonEffect",-- (position)
        "CharacterEquipped",   -- (player, characterId)
        "UpdateKillFeed",      -- (killerName, victimName)
        "PlayWorldSound",      -- (soundType)

        -- Eventos del cliente al servidor
        "UsePower",            -- (player, targetPos)
        "SelectCharacter",     -- (player, characterId)
        "MeleeAttack",         -- (player, targetPos)
        "EnterPortal",         -- (player)
        "PurchaseCharacter",   -- (player, characterId)
        "RequestPlayerData",   -- (player)
        "ReportPosition",      -- (player, position) -- anti-cheat básico
    }

    for _, name in ipairs(remotes) do
        local re = Instance.new("RemoteEvent")
        re.Name = name
        re.Parent = folder
    end

    -- Functions
    local getDataFunc = Instance.new("RemoteFunction")
    getDataFunc.Name = "GetPlayerData"
    getDataFunc.Parent = folder

    local getCharsFunc = Instance.new("RemoteFunction")
    getCharsFunc.Name = "GetCharacterList"
    getCharsFunc.Parent = folder

    return folder
end

local RemotesFolder = SetupRemotes()

local function GetRemote(name)
    return RemotesFolder:FindFirstChild(name)
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE SONIDO
-- ═══════════════════════════════════════════════════════
-- IDs de sonido de Roblox (gratuitos y disponibles)
local SOUND_IDS = {
    bgm_hawkins    = "rbxassetid://1837602584",  -- Música ambiental
    bgm_upside     = "rbxassetid://1847566482",  -- Música oscura
    bgm_boss       = "rbxassetid://1837606568",  -- Música de boss
    sfx_power      = "rbxassetid://9068386060",  -- Sonido de poder
    sfx_hit        = "rbxassetid://9068386060",  -- Hit
    sfx_portal     = "rbxassetid://9068386060",  -- Portal
    sfx_vecna      = "rbxassetid://9068386060",  -- Vecna
    sfx_levelup    = "rbxassetid://9068386060",  -- Level up
    sfx_death      = "rbxassetid://9068386060",  -- Muerte
}

local function PlaySound(soundId, volume, pitch, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = parent or Workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 10)
end

-- ═══════════════════════════════════════════════════════
--              CONSTRUCTOR DE MUNDOS (PIXEL ART)
-- ═══════════════════════════════════════════════════════
local WorldBuilder = {}

-- Función auxiliar para crear partes pixeladas
local function CreatePixelPart(size, color, pos, name, parent, material)
    local part = Instance.new("Part")
    part.Name = name or "PixelPart"
    part.Size = size
    part.Position = pos
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = true
    part.Parent = parent or Workspace
    return part
end

-- Pixel Art: Árbol de Hawkins 8-bit
local function CreatePixelTree(pos, folder)
    local C = CONFIG.COLORS
    -- Tronco (2 capas)
    CreatePixelPart(Vector3.new(2,4,2), C.HAWKINS_TRUNK, pos + Vector3.new(0,2,0), "Trunk", folder, Enum.Material.Wood)
    -- Copa del árbol (varias capas para dar forma pixel)
    local layers = {
        {size=Vector3.new(8,2,8), yOff=5},
        {size=Vector3.new(10,2,10), yOff=3},
        {size=Vector3.new(6,2,6), yOff=7},
    }
    for _, l in ipairs(layers) do
        CreatePixelPart(l.size, C.HAWKINS_TREE, pos + Vector3.new(0, l.yOff, 0), "Leaf", folder, Enum.Material.Grass)
    end
end

-- Pixel Art: Casa estilo Hawkins
local function CreatePixelHouse(pos, folder, colorOverride)
    local C = CONFIG.COLORS
    local bc = colorOverride or C.HAWKINS_BUILDING
    -- Base de la casa
    CreatePixelPart(Vector3.new(20,12,16), bc, pos + Vector3.new(0,6,0), "HouseBody", folder, Enum.Material.SmoothPlastic)
    -- Techo (escalonado para efecto pixel)
    CreatePixelPart(Vector3.new(22,2,18), C.HAWKINS_ROOF, pos + Vector3.new(0,13,0), "Roof1", folder, Enum.Material.SmoothPlastic)
    CreatePixelPart(Vector3.new(18,2,14), C.HAWKINS_ROOF, pos + Vector3.new(0,15,0), "Roof2", folder, Enum.Material.SmoothPlastic)
    CreatePixelPart(Vector3.new(14,2,10), C.HAWKINS_ROOF, pos + Vector3.new(0,17,0), "Roof3", folder, Enum.Material.SmoothPlastic)
    -- Ventanas (pixel cuadradas)
    local winColor = Color3.fromRGB(200, 220, 255)
    CreatePixelPart(Vector3.new(4,4,0.5), winColor, pos + Vector3.new(-5,7,8.1), "WinL", folder, Enum.Material.Neon)
    CreatePixelPart(Vector3.new(4,4,0.5), winColor, pos + Vector3.new(5,7,8.1), "WinR", folder, Enum.Material.Neon)
    -- Puerta
    CreatePixelPart(Vector3.new(4,6,0.5), Color3.fromRGB(101,67,33), pos + Vector3.new(0,3,8.1), "Door", folder, Enum.Material.Wood)
end

-- Pixel Art: Farola de Hawkins
local function CreateStreetLight(pos, folder)
    CreatePixelPart(Vector3.new(0.6,10,0.6), Color3.fromRGB(80,80,80), pos + Vector3.new(0,5,0), "Pole", folder, Enum.Material.Metal)
    local lamp = CreatePixelPart(Vector3.new(2,1,2), Color3.fromRGB(255,255,200), pos + Vector3.new(0,10.5,0), "Lamp", folder, Enum.Material.Neon)
    -- PointLight
    local pl = Instance.new("PointLight")
    pl.Brightness = 2
    pl.Range = 20
    pl.Color = Color3.fromRGB(255, 240, 180)
    pl.Parent = lamp
end

-- Pixel Art: Portal al Upside Down
local function CreatePortal(pos, folder)
    local C = CONFIG.COLORS
    -- Base del portal (anillos concéntricos pixelados)
    for i = 1, 5 do
        local ring = CreatePixelPart(
            Vector3.new(8 - i*1, 0.3, 8 - i*1),
            (i % 2 == 0) and C.UD_GLOW or Color3.fromRGB(80,0,80),
            pos + Vector3.new(0, i*0.1, 0),
            "PortalRing"..i,
            folder,
            Enum.Material.Neon
        )
        ring.Shape = Enum.PartType.Cylinder
    end
    -- Texto flotante "PORTAL"
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = false
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = "⬤  PORTAL AL UPSIDE DOWN"
    label.TextColor3 = C.UD_GLOW
    label.TextScaled = true
    label.Font = Enum.Font.Code
    label.Parent = billboard
    billboard.Parent = CreatePixelPart(Vector3.new(1,1,1), Color3.fromRGB(0,0,0), pos + Vector3.new(0,1,0), "PortalAnchor", folder)

    -- Partículas del portal
    local particleAtt = Instance.new("Attachment")
    particleAtt.Position = Vector3.new(0,2,0)
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180,0,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,0,100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50,0,50))
    })
    pe.LightEmission = 0.8
    pe.Rate = 30
    pe.Lifetime = NumberRange.new(1.5, 3)
    pe.Speed = NumberRange.new(3, 8)
    pe.SpreadAngle = Vector2.new(60,60)
    pe.Parent = particleAtt
    particleAtt.Parent = folder:FindFirstChild("PortalAnchor") or folder
    return folder
end

-- ═══════════════════════════════════════════════════════
--           CONSTRUCCIÓN: MUNDO HAWKINS
-- ═══════════════════════════════════════════════════════
function WorldBuilder.BuildHawkins()
    local C = CONFIG.COLORS
    local folder = Instance.new("Folder")
    folder.Name = "World_Hawkins"
    folder.Parent = Workspace

    -- Suelo base (tablero de ajedrez pixel)
    for x = -10, 10 do
        for z = -10, 10 do
            local isDark = (x + z) % 2 == 0
            local color = isDark and C.HAWKINS_GRASS or C.HAWKINS_GRASS_DARK
            CreatePixelPart(
                Vector3.new(CONFIG.TILE_SIZE, 1, CONFIG.TILE_SIZE),
                color,
                Vector3.new(x * CONFIG.TILE_SIZE, 0, z * CONFIG.TILE_SIZE),
                "Grass",
                folder,
                Enum.Material.Grass
            )
        end
    end

    -- Camino central (efecto pixel)
    for z = -10, 10 do
        CreatePixelPart(
            Vector3.new(CONFIG.TILE_SIZE*2, 1.05, CONFIG.TILE_SIZE),
            C.HAWKINS_PATH,
            Vector3.new(0, 0, z * CONFIG.TILE_SIZE),
            "Path",
            folder,
            Enum.Material.SmoothPlastic
        )
    end

    -- Casas de Hawkins (layout estilo pixel map)
    local housePositions = {
        Vector3.new(-50, 0, -30),
        Vector3.new(-50, 0, 30),
        Vector3.new(50, 0, -30),
        Vector3.new(50, 0, 30),
        Vector3.new(-50, 0, 0),
        Vector3.new(50, 0, 0),
    }
    local houseColors = {
        Color3.fromRGB(220, 180, 140),
        Color3.fromRGB(200, 160, 120),
        Color3.fromRGB(230, 200, 160),
        Color3.fromRGB(180, 150, 120),
        Color3.fromRGB(210, 170, 130),
        Color3.fromRGB(240, 210, 170),
    }
    for i, pos in ipairs(housePositions) do
        CreatePixelHouse(pos, folder, houseColors[i])
    end

    -- Árboles decorativos
    local treePos = {
        Vector3.new(-70,-1,-50), Vector3.new(-75,-1,-20), Vector3.new(-65,-1,20),
        Vector3.new(70,-1,-50),  Vector3.new(75,-1,-20),  Vector3.new(65,-1,20),
        Vector3.new(-30,-1,-70), Vector3.new(30,-1,-70),  Vector3.new(0,-1,-80),
    }
    for _, pos in ipairs(treePos) do
        CreatePixelTree(pos, folder)
    end

    -- Farolas
    for i = -4, 4, 2 do
        CreateStreetLight(Vector3.new(-10, 0, i*10), folder)
        CreateStreetLight(Vector3.new(10, 0, i*10), folder)
    end

    -- Agua (lago de Hawkins) - pixelado con variación de color
    for x = -5, 5 do
        for z = 8, 12 do
            local isDeep = (x+z) % 3 == 0
            CreatePixelPart(
                Vector3.new(CONFIG.TILE_SIZE, 0.5, CONFIG.TILE_SIZE),
                isDeep and Color3.fromRGB(40, 100, 220) or C.HAWKINS_WATER,
                Vector3.new(x*CONFIG.TILE_SIZE, -0.3, z*CONFIG.TILE_SIZE + 80),
                "Water",
                folder,
                Enum.Material.Neon
            )
        end
    end

    -- Portal al Upside Down (centro del mundo)
    CreatePortal(CONFIG.PORTAL_POSITION, folder)

    -- Laboratorio de Hawkins (norte)
    local labFolder = Instance.new("Folder")
    labFolder.Name = "Lab"
    labFolder.Parent = folder
    -- Edificio principal del lab
    CreatePixelPart(Vector3.new(60,20,40), Color3.fromRGB(100,100,120), Vector3.new(0,10,-120), "LabMain", labFolder, Enum.Material.SmoothPlastic)
    CreatePixelPart(Vector3.new(62,2,42), Color3.fromRGB(80,80,100), Vector3.new(0,21,-120), "LabRoof", labFolder, Enum.Material.SmoothPlastic)
    -- Ventanas del lab con brillo rojo (peligro)
    for i = -2, 2 do
        CreatePixelPart(Vector3.new(6,5,0.5), Color3.fromRGB(255,50,0), Vector3.new(i*10, 12, -100.1), "LabWin", labFolder, Enum.Material.Neon)
    end
    -- Valla del laboratorio
    for i = -7, 7 do
        CreatePixelPart(Vector3.new(0.5,6,0.5), Color3.fromRGB(60,60,60), Vector3.new(i*5, 3, -97), "Fence", labFolder, Enum.Material.Metal)
        CreatePixelPart(Vector3.new(5,0.5,0.5), Color3.fromRGB(60,60,60), Vector3.new(i*5 + 2.5, 6, -97), "FenceTop", labFolder, Enum.Material.Metal)
    end

    -- Configurar iluminación de Hawkins (día/noche cycle)
    Lighting.Brightness = 2
    Lighting.ClockTime = 15 -- Tarde
    Lighting.Ambient = Color3.fromRGB(120, 120, 160)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 140)
    Lighting.FogColor = Color3.fromRGB(180, 180, 220)
    Lighting.FogEnd = 400
    Lighting.FogStart = 200

    -- Atmosphere
    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.3
    atmo.Offset = 0.1
    atmo.Color = Color3.fromRGB(200, 200, 255)
    atmo.Decay = Color3.fromRGB(100, 100, 180)
    atmo.Glare = 0.1
    atmo.Haze = 0.5
    atmo.Parent = Lighting

    print("[WorldBuilder] ✅ Hawkins construido correctamente.")
    return folder
end

-- ═══════════════════════════════════════════════════════
--           CONSTRUCCIÓN: THE UPSIDE DOWN
-- ═══════════════════════════════════════════════════════
function WorldBuilder.BuildUpsideDown()
    local C = CONFIG.COLORS
    local folder = Instance.new("Folder")
    folder.Name = "World_UpsideDown"
    folder.Parent = Workspace
    folder.Archivable = true

    -- Suelo del Upside Down (pixel art oscuro)
    for x = -10, 10 do
        for z = -10, 10 do
            local isDark = (x*2 + z*3) % 4 == 0
            local color = isDark and Color3.fromRGB(30,5,5) or C.UD_GROUND
            CreatePixelPart(
                Vector3.new(CONFIG.TILE_SIZE, 1, CONFIG.TILE_SIZE),
                color,
                Vector3.new(x * CONFIG.TILE_SIZE, -60, z * CONFIG.TILE_SIZE),
                "UDGround",
                folder,
                Enum.Material.SmoothPlastic
            )
        end
    end

    -- Rocas y formaciones del Upside Down
    local rockPositions = {
        {Vector3.new(-40,-58,-40), Vector3.new(8,6,8)},
        {Vector3.new(40,-58,-40),  Vector3.new(6,8,6)},
        {Vector3.new(-40,-58,40),  Vector3.new(10,5,8)},
        {Vector3.new(40,-58,40),   Vector3.new(7,9,7)},
        {Vector3.new(0,-57,-60),   Vector3.new(14,7,10)},
        {Vector3.new(-60,-58,0),   Vector3.new(9,8,9)},
        {Vector3.new(60,-58,0),    Vector3.new(11,6,11)},
    }
    for _, r in ipairs(rockPositions) do
        CreatePixelPart(r[2], C.UD_ROCK, r[1], "Rock", folder, Enum.Material.SmoothPlastic)
        -- Añadir variación de pixel art
        CreatePixelPart(r[2] * Vector3.new(0.6,0.4,0.6), Color3.fromRGB(50,10,10), r[1] + Vector3.new(2,r[2].Y*0.3,2), "RockDetail", folder, Enum.Material.SmoothPlastic)
    end

    -- Enredaderas del Upside Down (vines pixeladas)
    for i = 1, 30 do
        local x = math.random(-80, 80)
        local z = math.random(-80, 80)
        local height = math.random(3, 12)
        CreatePixelPart(
            Vector3.new(1, height, 1),
            C.UD_VINE,
            Vector3.new(x, -59 + height/2, z),
            "Vine",
            folder,
            Enum.Material.SmoothPlastic
        )
        -- Nodo de la enredadera
        CreatePixelPart(
            Vector3.new(3, 2, 3),
            Color3.fromRGB(60, 15, 15),
            Vector3.new(x, -59 + height + 1, z),
            "VineNode",
            folder,
            Enum.Material.SmoothPlastic
        )
    end

    -- Arena de combate del boss (centro del Upside Down)
    -- Plataforma hexagonal pixelada para Vecna
    for x = -4, 4 do
        for z = -4, 4 do
            if math.abs(x) + math.abs(z) <= 6 then
                local isAlt = (x + z) % 2 == 0
                CreatePixelPart(
                    Vector3.new(CONFIG.TILE_SIZE, 1, CONFIG.TILE_SIZE),
                    isAlt and Color3.fromRGB(50,0,50) or Color3.fromRGB(30,0,30),
                    Vector3.new(x*CONFIG.TILE_SIZE, -59.5, z*CONFIG.TILE_SIZE),
                    "BossArena",
                    folder,
                    Enum.Material.SmoothPlastic
                )
            end
        end
    end

    -- Pilares de la arena del boss
    local pillarPositions = {
        Vector3.new(-20,-55,-20), Vector3.new(20,-55,-20),
        Vector3.new(-20,-55,20),  Vector3.new(20,-55,20),
    }
    for _, pos in ipairs(pillarPositions) do
        CreatePixelPart(Vector3.new(4,12,4), Color3.fromRGB(40,0,40), pos, "Pillar", folder, Enum.Material.SmoothPlastic)
        -- Brillo en la cima del pilar
        local top = CreatePixelPart(Vector3.new(5,2,5), C.VECNA_GLOW, pos + Vector3.new(0,7,0), "PillarTop", folder, Enum.Material.Neon)
        local pl = Instance.new("PointLight")
        pl.Color = C.VECNA_GLOW
        pl.Brightness = 3
        pl.Range = 20
        pl.Parent = top
    end

    -- Partículas ambientales del Upside Down
    local ambientPart = CreatePixelPart(Vector3.new(200,1,200), Color3.fromRGB(15,0,0), Vector3.new(0,-62,0), "AmbientBase", folder)
    local sporeEmitter = Instance.new("ParticleEmitter")
    sporeEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 30))
    })
    sporeEmitter.LightEmission = 0.5
    sporeEmitter.Rate = 80
    sporeEmitter.Lifetime = NumberRange.new(4, 8)
    sporeEmitter.Speed = NumberRange.new(1, 3)
    sporeEmitter.SpreadAngle = Vector2.new(180, 180)
    sporeEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    sporeEmitter.Parent = ambientPart

    print("[WorldBuilder] ✅ The Upside Down construido correctamente.")
    return folder
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE PERSONAJES (PIXEL ART)
-- ═══════════════════════════════════════════════════════
local CharacterSystem = {}

-- Aplica colores de pixel art a un personaje de Roblox
function CharacterSystem.ApplyPixelSkin(character, charData)
    if not character or not charData then return end

    -- Humanoid
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = charData.stats.speed
        hum.MaxHealth = charData.stats.health
        hum.Health = charData.stats.health
        hum.JumpPower = 40
    end

    -- Descripción visual del personaje
    local desc = Instance.new("HumanoidDescription")
    desc.HeadColor = charData.color
    desc.TorsoColor = charData.shirtColor
    desc.LeftArmColor = charData.color
    desc.RightArmColor = charData.color
    desc.LeftLegColor = charData.pantsColor
    desc.RightLegColor = charData.pantsColor

    -- Ropa (usando prendas base de Roblox)
    -- (En producción, aquí se pondrían IDs de assets de Roblox)
    desc.GraphicTShirtTemplate = 0
    desc.ShirtTemplate = 0
    desc.PantsTemplate = 0

    if hum then
        local success, err = pcall(function()
            hum:ApplyDescription(desc)
        end)
        if not success then
            warn("[CharSystem] Error aplicando descripción: " .. tostring(err))
        end
    end

    -- Efectos visuales pixel art en el personaje
    CharacterSystem.AddPixelGlow(character, charData)
    CharacterSystem.AddNameTag(character, charData)
end

-- Añade un brillo sutil al personaje según su tipo
function CharacterSystem.AddPixelGlow(character, charData)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Pequeño PointLight temático del personaje
    local pl = Instance.new("PointLight")
    pl.Color = charData.color
    pl.Brightness = 0.5
    pl.Range = 8
    pl.Parent = root
end

-- Añade una etiqueta de nombre encima del personaje
function CharacterSystem.AddNameTag(character, charData)
    local head = character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "NameTag"
    bb.Size = UDim2.new(0, 160, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = false

    -- Fondo pixelado
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 2
    bg.BorderColor3 = charData.color
    bg.Parent = bb

    -- Nombre del personaje
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = charData.name
    nameLabel.TextColor3 = charData.color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Code -- Fuente monoespaciada (look pixel)
    nameLabel.Parent = bg

    -- Nombre del jugador (debajo)
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1, 0, 0.4, 0)
    playerLabel.Position = UDim2.new(0, 0, 0.6, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = character.Name
    playerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    playerLabel.TextScaled = true
    playerLabel.Font = Enum.Font.Code
    playerLabel.Parent = bg

    bb.Parent = head
end

-- ═══════════════════════════════════════════════════════
--              SISTEMA DE COMBATE
-- ═══════════════════════════════════════════════════════
local CombatSystem = {}

-- Efecto visual de daño (número flotante)
function CombatSystem.ShowDamageNumber(position, damage, isCrit)
    GetRemote("ShowDamageNumber"):FireAllClients(position, damage, isCrit or false)
end

-- Aplicar daño a un humanoid con efectos
function CombatSystem.DealDamage(target, damage, attacker, powerType)
    if not target or not target.Parent then return end
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Crítico aleatorio (15% de probabilidad)
    local isCrit = math.random(1, 100) <= 15
    local finalDamage = isCrit and math.floor(damage * 1.75) or damage

    -- Anti-cheat básico: verificar daño razonable
    if finalDamage > 300 then finalDamage = 300 end

    hum:TakeDamage(finalDamage)
    CombatSystem.ShowDamageNumber(target.PrimaryPart and target.PrimaryPart.Position or Vector3.new(0,5,0), finalDamage, isCrit)

    -- Efecto de golpe (flash rojo)
    for _, part in ipairs(target:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsA("UnionOperation") then
            local origColor = part.Color
            part.Color = Color3.fromRGB(255, 50, 50)
            task.delay(0.1, function()
                if part and part.Parent then
                    part.Color = origColor
                end
            end)
        end
    end

    return finalDamage
end

-- Knockback a un personaje
function CombatSystem.ApplyKnockback(character, direction, force)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = direction.Unit * force + Vector3.new(0, force * 0.3, 0)
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Parent = root
    game:GetService("Debris"):AddItem(bv, 0.15)
end

-- Usar poder del jugador
function CombatSystem.UsePower(player, targetPos)
    local data = GameState.playerData[player.UserId]
    if not data then return end

    local charData = nil
    for _, c in ipairs(CHARACTERS) do
        if c.id == data.selectedCharacter then
            charData = c
            break
        end
    end
    if not charData then return end

    local powerKey = charData.power
    local powerData = POWERS[powerKey]
    if not powerData then return end

    -- Verificar cooldown
    local now = tick()
    local cdTable = GameState.playerCooldowns[player.UserId]
    if cdTable and cdTable.power and (now - cdTable.power) < powerData.cooldown then
        return -- Todavía en cooldown
    end

    -- Guardar cooldown
    GameState.playerCooldowns[player.UserId] = GameState.playerCooldowns[player.UserId] or {}
    GameState.playerCooldowns[player.UserId].power = now

    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Disparar efecto visual a todos los clientes
    GetRemote("SpawnPowerEffect"):FireAllClients(targetPos, powerKey, powerData.color)

    -- Lógica de daño según el tipo de poder
    if powerData.aoe then
        -- Daño en área
        local hitPlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (pRoot.Position - targetPos).Magnitude
                    if dist <= powerData.aoeRadius then
                        local dmg = CombatSystem.DealDamage(p.Character, powerData.damage, player, powerKey)
                        if dmg then
                            table.insert(hitPlayers, p)
                            if powerData.knockback then
                                local dir = (pRoot.Position - targetPos)
                                CombatSystem.ApplyKnockback(p.Character, dir, powerData.knockback)
                            end
                        end
                    end
                end
            end
        end
        -- También dañar Demogorgones
        for _, dem in ipairs(GameState.demogorgons) do
            if dem.model and dem.model.Parent then
                local demRoot = dem.model.PrimaryPart
                if demRoot then
                    local dist = (demRoot.Position - targetPos).Magnitude
                    if dist <= powerData.aoeRadius then
                        dem.health = dem.health - powerData.damage
                        CombatSystem.ShowDamageNumber(demRoot.Position, powerData.damage, false)
                        if dem.health <= 0 then
                            CombatSystem.KillDemogorgon(dem, player)
                        end
                    end
                end
            end
        end
        -- Daño a Vecna
        if GameState.vecnaActive and GameState.vecna then
            local vecRoot = GameState.vecna.PrimaryPart
            if vecRoot then
                local dist = (vecRoot.Position - targetPos).Magnitude
                if dist <= powerData.aoeRadius + 5 then
                    CombatSystem.DamageVecna(powerData.damage, player)
                end
            end
        end
    else
        -- Disparo en línea recta
        local dir = (targetPos - root.Position).Unit
        -- Raycast
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(root.Position, dir * powerData.range, rayParams)

        if result and result.Instance then
            local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
            if hitChar then
                -- Jugador
                local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                if hitPlayer and hitPlayer ~= player then
                    CombatSystem.DealDamage(hitChar, powerData.damage, player, powerKey)
                end
                -- Demogorgon
                for _, dem in ipairs(GameState.demogorgons) do
                    if dem.model == hitChar then
                        dem.health = dem.health - powerData.damage
                        CombatSystem.ShowDamageNumber(result.Position, powerData.damage, false)
                        if dem.health <= 0 then
                            CombatSystem.KillDemogorgon(dem, player)
                        end
                        break
                    end
                end
                -- Vecna
                if GameState.vecna and hitChar == GameState.vecna then
                    CombatSystem.DamageVecna(powerData.damage, player)
                end
            end
        end
    end

    -- Efectos especiales del poder
    if powerKey == "light_trap" then
        CombatSystem.PlaceLightTrap(targetPos, player, powerData)
    elseif powerKey == "communication" then
        CombatSystem.HealNearbyAllies(root.Position, powerData.healAlly, player)
    end

    -- XP por usar el poder (pequeña cantidad)
    CombatSystem.GiveXP(player, 2)
end

-- Trampa de luz (Dustin)
function CombatSystem.PlaceLightTrap(pos, caster, powerData)
    local trap = Instance.new("Part")
    trap.Name = "LightTrap"
    trap.Size = Vector3.new(4, 0.5, 4)
    trap.Position = pos
    trap.Color = CONFIG.COLORS.POWER_LIGHT
    trap.Material = Enum.Material.Neon
    trap.Anchored = true
    trap.CanCollide = false
    trap.Parent = Workspace

    local pl = Instance.new("PointLight")
    pl.Color = CONFIG.COLORS.POWER_LIGHT
    pl.Brightness = 5
    pl.Range = 15
    pl.Parent = trap

    -- Duración de la trampa: 8 segundos
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not trap or not trap.Parent then
            conn:Disconnect()
            return
