local config = require 'config.client'
local sharedConfig = require 'config.shared'
local PlayerData = QBX.PlayerData
local UIConfig = UIConfig
local speedMultiplier = config.useMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local next = next
local nos = 0
local playerState = LocalPlayer.state
local stress = playerState.stress or 0
local hunger = playerState.hunger or 100
local thirst = playerState.thirst or 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local dev = false
local admin = false
local playerDead = false
local showMenu = false
local showCircleB = false
local showSquareB = false
local CinematicHeight = 0.2
local w = 0
local radioTalking = false

DisplayRadar(false)

local function CinematicShow(bool)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    if bool then
        for i = CinematicHeight, 0, -1.0 do
            Wait(10)
            w = i
        end
    else
        for i = 0, CinematicHeight, 1.0 do
            Wait(10)
            w = i
        end
    end
end

local function hasHarness()
    if not IsPedInAnyVehicle(cache.ped, false) then return end
    return exports['jim-mechanic']:HasHarness()
end

local function loadSettings()
    exports.qbx_core:Notify(locale('notify.hud_settings_loaded'), 'success')
    Wait(1000)
    TriggerEvent("hud:client:LoadMap")
end

local function SendAdminStatus()
    SendNUIMessage({
        action = 'menu',
        topic = 'adminonly',
        adminOnly = config.AdminOnly,
        isAdmin = admin,
    })
end

local function sendUIUpdateMessage(data)
    SendNUIMessage({
        action = 'updateUISettings',
	icons = data.icons,
	layout = data.layout,
	colors = data.colors,
	})
end

local function HandleSetupResource()
	local isAdminOrGreater = lib.callback.await('hud:server:getRank')
        if isAdminOrGreater then
            admin = true
        else
            admin = false
        end
        SendAdminStatus()
    if config.AdminOnly then
        -- Send the client what the saved ui config is (enforced by the server)
        if next(UIConfig) then
            sendUIUpdateMessage(UIConfig)
        end
    end
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(2000)
    HandleSetupResource()
    -- local hudSettings = GetResourceKvpString('hudSettings')
    -- if hudSettings then loadSettings(json.decode(hudSettings)) end
    loadSettings()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}
    admin = false
    SendAdminStatus()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    PlayerData = val
end)

-- Event Handlers
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)

    HandleSetupResource()
    -- local hudSettings = GetResourceKvpString('hudSettings')
    -- if hudSettings then loadSettings(json.decode(hudSettings)) end
    loadSettings()
end)

AddEventHandler("pma-voice:radioActive", function(isRadioTalking)
    radioTalking = isRadioTalking
end)

-- Callbacks & Events
RegisterCommand('menu', function()
    Wait(50)
    if showMenu then return end
    TriggerEvent("hud:client:playOpenMenuSounds")
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
    showMenu = true
end)

RegisterNUICallback('closeMenu', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playCloseMenuSounds")
    showMenu = false
    SetNuiFocus(false, false)
end)

RegisterKeyMapping('menu', locale('info.open_menu'), 'keyboard', config.menuKey)

-- Reset hud
local function restartHud()
    TriggerEvent("hud:client:playResetHudSounds")
    exports.qbx_core:Notify(locale('notify.hud_restart'), 'error')
    Wait(1500)
    if IsPedInAnyVehicle(cache.ped) then
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = false,
            seatbelt = false,
        })
        Wait(500)
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = true,
            seatbelt = false,
        })
    end
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = false,
    })
    Wait(500)
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = true,
    })
    Wait(500)
    exports.qbx_core:Notify(locale('notify.hud_start'), 'success')
    SendNUIMessage({
        action = 'menu',
        topic = 'restart',
    })
end

RegisterNUICallback('restartHud', function(_, cb)
    cb({})
    Wait(50)
    restartHud()
end)

RegisterCommand('resethud', function()
    Wait(50)
    restartHud()
end)

RegisterNUICallback('resetStorage', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:resetStorage")
end)

RegisterNetEvent("hud:client:resetStorage", function()
    Wait(50)
    if sharedConfig.menu.isResetSoundsChecked then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
    end
    local menu = lib.callback.await('hud:server:getMenu', false)
    loadSettings(menu)
    SetResourceKvp('hudSettings', json.encode(menu))
end)

-- Notifications
RegisterNUICallback('openMenuSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isOpenMenuSoundsChecked = true
    else
        sharedConfig.menu.isOpenMenuSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playOpenMenuSounds", function()
    Wait(50)
    if not sharedConfig.menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "monkeyopening", 0.5)
end)

RegisterNetEvent("hud:client:playCloseMenuSounds", function()
    Wait(50)
    if not sharedConfig.menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "catclosing", 0.05)
end)

RegisterNUICallback('resetHudSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isResetSoundsChecked = true
    else
        sharedConfig.menu.isResetSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playResetHudSounds", function()
    Wait(50)
    if not sharedConfig.menu.isResetSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
end)

RegisterNUICallback('checklistSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isListSoundsChecked = true
    else
        sharedConfig.menu.isListSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playHudChecklistSound", function()
    Wait(50)
    if not sharedConfig.menu.isListSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "shiftyclick", 0.5)
end)

RegisterNUICallback('showOutMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isOutMapChecked = true
    else
        sharedConfig.menu.isOutMapChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('saveUISettings', function(data, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
    TriggerServerEvent("hud:server:saveUIData", data)
end)

RegisterNUICallback('showOutCompass', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isOutCompassChecked = true
    else
        sharedConfig.menu.isOutCompassChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFollowCompass', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        sharedConfig.menu.isCompassFollowChecked = true
    else
        sharedConfig.menu.isCompassFollowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showMapNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isMapNotifChecked = true
    else
        sharedConfig.menu.isMapNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFuelAlert', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isLowFuelChecked = true
    else
        sharedConfig.menu.isLowFuelChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showCinematicNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isCinematicNotifChecked = true
    else
        sharedConfig.menu.isCinematicNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Status
RegisterNUICallback('dynamicChange', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Vehicle
RegisterNUICallback('HideMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isMapEnabledChecked = true
    else
        sharedConfig.menu.isMapEnabledChecked = false
    end
    DisplayRadar(sharedConfig.menu.isMapEnabledChecked)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:LoadMap", function()
    Wait(50)
    -- Credit to Dalrae for the solve.
    local defaultAspectRatio = 1920/1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX/resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008
    end
    if sharedConfig.menu.isToggleMapShapeChecked == "square" then
        lib.requestStreamedTextureDict('squaremap')
        if not HasStreamedTextureDictLoaded("squaremap") then
            Wait(150)
        end
        if sharedConfig.menu.isMapNotifChecked then
            exports.qbx_core:Notify(locale('notify.load_square_map'), 'inform')
        end
        SetMinimapClipType(0)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
        -- 0.0 = nav symbol and icons left
        -- 0.1638 = nav symbol and icons stretched
        -- 0.216 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.047, 0.1638, 0.183)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)

        -- -0.01 = map pulled left
        -- 0.025 = map raised up
        -- 0.262 = map stretched
        -- 0.315 = map shorten
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.025, 0.262, 0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetRadarBigmapEnabled(true, false)
        SetMinimapClipType(0)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
        if sharedConfig.menu.isToggleMapBordersChecked then
            showCircleB = false
            showSquareB = true
        end
        Wait(1200)
        if sharedConfig.menu.isMapNotifChecked then
            exports.qbx_core:Notify(locale('notify.loaded_square_map'), 'success')
        end
    elseif sharedConfig.menu.isToggleMapShapeChecked == "circle" then
        lib.requestStreamedTextureDict('circlemap')
        if not HasStreamedTextureDictLoaded("circlemap") then
            Wait(150)
        end
        if sharedConfig.menu.isMapNotifChecked then
            exports.qbx_core:Notify(locale('notify.load_circle_map'), 'inform')
        end
        SetMinimapClipType(1)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasksm")
        -- -0.0100 = nav symbol and icons left
        -- 0.180 = nav symbol and icons stretched
        -- 0.258 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", -0.0100 + minimapOffset, -0.030, 0.180, 0.258)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.200 + minimapOffset, 0.0, 0.065, 0.20)

        -- -0.00 = map pulled left
        -- 0.015 = map raised up
        -- 0.252 = map stretched
        -- 0.338 = map shorten
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.00 + minimapOffset, 0.015, 0.252, 0.338)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetMinimapClipType(1)
        SetRadarBigmapEnabled(true, false)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
        if sharedConfig.menu.isToggleMapBordersChecked then
            showSquareB = false
            showCircleB = true
        end
        Wait(1200)
        if sharedConfig.menu.isMapNotifChecked then
            exports.qbx_core:Notify(locale('notify.loaded_circle_map'), 'success')
        end
    end
end)

RegisterNUICallback('ToggleMapShape', function(data, cb)
    cb({})
    Wait(50)
    if sharedConfig.menu.isMapEnabledChecked then
        sharedConfig.menu.isToggleMapShapeChecked = data.shape
        Wait(50)
        TriggerEvent("hud:client:LoadMap")
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('ToggleMapBorders', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        sharedConfig.menu.isToggleMapBordersChecked = true
    else
        sharedConfig.menu.isToggleMapBordersChecked = false
    end

    if sharedConfig.menu.isToggleMapBordersChecked then
        if sharedConfig.menu.isToggleMapShapeChecked == "square" then
            showSquareB = true
        else
            showCircleB = true
        end
    else
        showSquareB = false
        showCircleB = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Compass
RegisterNUICallback('showCompassBase', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        sharedConfig.menu.isCompassShowChecked = true
    else
        sharedConfig.menu.isCompassShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showStreetsNames', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        sharedConfig.menu.isShowStreetsChecked = true
    else
        sharedConfig.menu.isShowStreetsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showPointerIndex', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        sharedConfig.menu.isPointerShowChecked = true
    else
        sharedConfig.menu.isPointerShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showDegreesNum', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        sharedConfig.menu.isDegreesShowChecked = true
    else
        sharedConfig.menu.isDegreesShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('changeCompassFPS', function(data, cb)
    cb({})
	Wait(50)
    if data.fps == "optimized" then
        sharedConfig.menu.isChangeCompassFPSChecked = true
    else
        sharedConfig.menu.isChangeCompassFPSChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('cinematicMode', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        CinematicShow(true)
        if sharedConfig.menu.isCinematicNotifChecked then
            exports.qbx_core:Notify(locale('notify.cinematic_on'), 'success')
        end
    else
        CinematicShow(false)
        if sharedConfig.menu.isCinematicNotifChecked then
            exports.qbx_core:Notify(locale('notify.cinematic_off'), 'error')
        end
        if (IsPedInAnyVehicle(cache.ped) and not IsThisModelABicycle(cache.vehicle)) or not sharedConfig.menu.isOutMapChecked then
            DisplayRadar(true)
        end
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('updateMenuSettingsToClient', function(data, cb)
    sharedConfig.menu.isOutMapChecked = data.isOutMapChecked
    sharedConfig.menu.isOutCompassChecked = data.isOutCompassChecked
    sharedConfig.menu.isCompassFollowChecked = data.isCompassFollowChecked
    sharedConfig.menu.isOpenMenuSoundsChecked = data.isOpenMenuSoundsChecked
    sharedConfig.menu.isResetSoundsChecked = data.isResetSoundsChecked
    sharedConfig.menu.isListSoundsChecked = data.isListSoundsChecked
    sharedConfig.menu.isMapNotifChecked = data.isMapNotifyChecked
    sharedConfig.menu.isLowFuelChecked = data.isLowFuelAlertChecked
    sharedConfig.menu.isCinematicNotifChecked = data.isCinematicNotifyChecked
    sharedConfig.menu.isMapEnabledChecked = data.isMapEnabledChecked
    sharedConfig.menu.isToggleMapShapeChecked = data.isToggleMapShapeChecked
    sharedConfig.menu.isToggleMapBordersChecked = data.isToggleMapBordersChecked
    sharedConfig.menu.isCompassShowChecked = data.isShowCompassChecked
    sharedConfig.menu.isShowStreetsChecked = data.isShowStreetsChecked
    sharedConfig.menu.isPointerShowChecked = data.isPointerShowChecked
    CinematicShow(data.isCineamticModeChecked)
    cb({})
end)

RegisterNetEvent("hud:client:EngineHealth", function(newEngine)
    engine = newEngine
end)

RegisterNetEvent('hud:client:ToggleAirHud', function()
    showAltitude = not showAltitude
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

RegisterNetEvent('hud:client:UpdateUISettings', function(data)
    UIConfig = data
    sendUIUpdateMessage(data)
end)

--- Send player buff infomation to nui
--- @param data table - Buff data
--  {
--      display: boolean - Whether to show buff or not
--      iconName: string - which icon to use
--      name: string - buff name used to identify buff
--      progressValue: number(0 - 100) - current progress of buff shown on icon
--      progressColor: string (hex #ffffff) - progress color on icon
--  }
RegisterNetEvent('hud:client:BuffEffect', function(data)
    if data.progressColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            display = data.display,
            iconColor = data.iconColor,
            iconName = data.iconName,
            buffName = data.buffName,
            progressValue = data.progressValue,
            progressColor = data.progressColor,
        })
    elseif data.progressValue ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            progressValue = data.progressValue,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            display = data.display,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:BuffEffect")
    end
end)

RegisterNetEvent('hud:client:EnhancementEffect', function(data)
    if data.iconColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            iconColor = data.iconColor,
            enhancementName = data.enhancementName,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            enhancementName = data.enhancementName,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:EnhancementEffect")
    end
end)

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(config.weaponsArmedMode) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updateShowPlayerHud(show)
    if prevPlayerStats['show'] ~= show then
        prevPlayerStats['show'] = show
        SendNUIMessage({
            action = 'hudtick',
            topic = 'display',
            show = show
        })
    end
end

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    if shouldUpdate then
        -- Since we found updated data, replace player cache with data
        prevPlayerStats = data
        SendNUIMessage({
            action = 'hudtick',
            topic = 'status',
            show = data[1],
            health = data[2],
            playerDead = data[3],
            armor = data[4],
            thirst = data[5],
            hunger = data[6],
            stress = data[7],
            voice = data[8],
            radioChannel = data[9],
            radioTalking = data[10],
            talking = data[11],
            armed = data[12],
            oxygen = data[13],
            parachute = data[14],
            nos = data[15],
            cruise = data[16],
            nitroActive = data[17],
            harness = data[18],
            hp = data[19],
            speed = data[20],
            engine = data[21],
            cinematic = data[22],
            dev = data[23],
        })
    end
end

local prevVehicleStats = {
    nil, --[1] show,
    nil, --[2] isPaused,
    nil, --[3] seatbelt
    nil, --[4] speed
    nil, --[5] fuel
    nil, --[6] altitude
    nil, --[7] showAltitude
    nil, --[8] showSeatbelt
    nil, --[9] showSquareBorder
    nil --[10] showCircleBorder
}

local function updateShowVehicleHud(show)
    if prevVehicleStats[1] ~= show then
        prevVehicleStats[1] = show
        prevVehicleStats[3] = false
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = false,
            seatbelt = false,
        })
    end
end

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then shouldUpdate = true break end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'car',
            topic = 'status',
            show = data[1],
            isPaused = data[2],
            seatbelt = data[3],
            speed = data[4],
            fuel = data[5],
            altitude = data[6],
            showAltitude = data[7],
            showSeatbelt = data[8],
            showSquareB = data[9],
            showCircleB = data[10],
        })
    end
end

local lastFuelUpdate = 0
local lastFuelCheck = {}

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        lastFuelCheck = math.floor(GetVehicleFuelLevel(vehicle))
    end
    return lastFuelCheck
end

-- HUD Update loop

CreateThread(function()
    local wasInVehicle = false
    while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(500)

            local show = true
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(cache.ped)
            
            -- Player hud
            if not IsWhitelistedWeaponArmed(weapon) then
                -- weapon ~= 0 fixes unarmed on Offroad vehicle Blzer Aqua showing armed bug
                if weapon ~= `WEAPON_UNARMED` and weapon ~= 0 then
                    armed = true
                else
                    armed = false
                end
            end

            playerDead = IsEntityDead(cache.ped) or PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"] or false
            parachute = GetPedParachuteState(cache.ped)

            -- Stamina
            if not IsEntityInWater(cache.ped) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end
            
            -- Oxygen
            if IsEntityInWater(cache.ped) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end

            -- Voice setup            
            local talking = NetworkIsPlayerTalking(playerId)
            local voice = 0
            if LocalPlayer.state['proximity'] then
                voice = LocalPlayer.state['proximity'].distance
                -- Player enters server with Voice Chat off, will not have a distance (nil)
                if voice == nil then
                    voice = 0
                end
            end

            if IsPauseMenuActive() then
                show = false
            end
				
            if not (IsPedInAnyVehicle(cache.ped) and not IsThisModelABicycle(cache.vehicle)) then
                updatePlayerHud({
                    show,
                    GetEntityHealth(cache.ped) - 100,
                    playerDead,
                    GetPedArmour(cache.ped),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    parachute,
                    -1,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    -1,
                    sharedConfig.menu.isCineamticModeChecked,
                    dev,
                })
            end

            -- Vehicle hud

            if IsPedInAnyHeli(cache.ped) or IsPedInAnyPlane(cache.ped) then
                showAltitude = true
                showSeatbelt = false
            end

            if IsPedInAnyVehicle(cache.ped) and not IsThisModelABicycle(cache.vehicle) then
                if not wasInVehicle then
                    DisplayRadar(sharedConfig.menu.isMapEnabledChecked)
                end

                wasInVehicle = true
                
                updatePlayerHud({
                    show,
                    GetEntityHealth(cache.ped) - 100,
                    playerDead,
                    GetPedArmour(cache.ped),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(cache.ped),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(cache.vehicle) / 10),
                    sharedConfig.menu.isCineamticModeChecked,
                    dev,
                })

                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    seatbeltOn,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    getFuelLevel(cache.vehicle),
                    math.ceil(GetEntityCoords(cache.ped).z * 0.5),
                    showAltitude,
                    showSeatbelt,
                    showSquareB,
                    showCircleB,
                })
                showAltitude = false
                showSeatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    updateShowVehicleHud(false)
                    prevVehicleStats[1] = false
                    prevVehicleStats[3] = false
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end
                DisplayRadar(not sharedConfig.menu.isOutMapChecked)
            end
        else
            -- Not logged in, dont show Status/Vehicle UI (cached)
            updateShowPlayerHud(false)
            updateShowVehicleHud(false)
            DisplayRadar(false)
            Wait(1000)
        end
    end
end)

function isElectric(vehicle)
    local noBeeps = false
    for _, v in pairs(config.FuelBlacklist) do
        if GetEntityModel(vehicle) == GetHashKey(v) then
            noBeeps = true
        end
    end
    return noBeeps
end

-- Low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if IsPedInAnyVehicle(cache.ped, false) and not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(cache.ped, false))) and not isElectric(GetVehiclePedIsIn(cache.ped, false)) then
                if exports[config.FuelScript]:GetFuel(GetVehiclePedIsIn(cache.ped, false)) <= 20 then -- At 20% Fuel Left
                    if sharedConfig.menu.isLowFuelChecked then
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                        exports.qbx_core:Notify(locale('notify.low_fuel'), 'error')
                        Wait(60000) -- repeats every 1 min until empty
                    end
                end
            end
        end
        Wait(10000)
    end
end)

-- Money HUD

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({
            action = 'show',
            type = 'cash',
            cash = amount
        })
    else
        SendNUIMessage({
            action = 'show',
            type = 'bank',
            bank = amount
        })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    cashAmount = PlayerData.money['cash']
    bankAmount = PlayerData.money['bank']
		if type == 'cash' and amount == 0 then return end
    SendNUIMessage({
        action = 'updatemoney',
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
end)

-- Harness Check / Seatbelt Check

CreateThread(function()
    while true do
        Wait(1500)
        if LocalPlayer.state.isLoggedIn then
            if IsPedInAnyVehicle(cache.ped, false) then
                hasHarness()
                local veh = GetEntityModel(GetVehiclePedIsIn(cache.ped, false))
                if seatbeltOn ~= true and IsThisModelACar(veh) then
                    TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                end
            end
        end
    end
end)


-- Stress Gain

CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            if cache.vehicle then
                local speed = GetEntitySpeed(cache.vehicle) * speedMultiplier
                local stressSpeed = seatbeltOn and config.stress.minForSpeeding or config.stress.minForSpeedingUnbuckled
                if speed >= stressSpeed then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
        end
        Wait(10000)
    end
end)

local function IsWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(config.stress.whitelistedWeapons) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local weapon = GetSelectedPedWeapon(cache.ped)
            if weapon ~= `WEAPON_UNARMED` then
                if IsPedShooting(cache.ped) and not IsWhitelistedWeaponStress(weapon) then
                    if math.random() < config.stress.chance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                    Wait(100)
                else
                    Wait(500)
                end
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(config.stress.blurIntensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(config.stress.effectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local effectInterval = GetEffectInterval(stress)
            if stress >= 100 then
                local BlurIntensity = GetBlurIntensity(stress)
                local FallRepeat = math.random(2, 4)
                local RagdollTimeout = FallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)

                if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                    SetPedToRagdollWithFall(cache.ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(cache.ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end

                Wait(1000)
                for _ = 1, FallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif stress >= config.stress.minForShaking then
                local BlurIntensity = GetBlurIntensity(stress)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
        else
            Wait(1000)
        end
    end
end)

-- Minimap update
CreateThread(function()
    while true do
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
        Wait(500)
    end
end)

local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    while true do
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
        end
        Wait(0)
    end
end)

-- Compass
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

local prevBaseplateStats = { nil, nil, nil, nil, nil, nil, nil}

local function updateBaseplateHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevBaseplateStats[k] ~= v then shouldUpdate = true break end
    end
    prevBaseplateStats = data
    if shouldUpdate then
        SendNUIMessage ({
            action = 'baseplate',
            topic = 'compassupdate',
            show = data[1],
            street1 = data[2],
            street2 = data[3],
            showCompass = data[4],
            showStreets = data[5],
            showPointer = data[6],
            showDegrees = data[7],
        })
    end
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}

local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 5000 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return lastCrossroadCheck
end

-- Compass Update loop

CreateThread(function()
    local lastHeading = 1
    local heading
    local lastIsOutCompassCheck = sharedConfig.menu.isOutCompassChecked
    local lastInVehicle = false
	while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(400)
            local show = true
            local camRot = GetGameplayCamRot(0)

            if sharedConfig.menu.isCompassFollowChecked then
                heading = tostring(round(360.0 - ((camRot.z + 360.0) % 360.0)))
            else
                heading = tostring(round(360.0 - GetEntityHeading(cache.ped)))
            end

            if heading == '360' then
                heading = '0'
            end

            if heading ~= lastHeading or lastInVehicle ~= cache.vehicle then
                if cache.vehicle then
		local crossroads = getCrossroads(cache.ped)
                    SendNUIMessage ({
                        action = 'update',
                        value = heading
                    })
                    updateBaseplateHud({
                        show,
                        crossroads[1],
                        crossroads[2],
                        sharedConfig.menu.isCompassShowChecked,
			sharedConfig.menu.isShowStreetsChecked,
			sharedConfig.menu.isPointerShowChecked,
                        sharedConfig.menu.isDegreesShowChecked,
                    })
                    lastInVehicle = true
                else
		if not sharedConfig.menu.isOutCompassChecked then
                        SendNUIMessage ({
                            action = 'update',
                            value = heading
                        })
                        SendNUIMessage ({
                            action = 'baseplate',
                            topic = 'opencompass',
                            show = true,
                            showCompass = true,
                        })
			prevBaseplateStats[1] = true
			prevBaseplateStats[4] = true
                    else
                        SendNUIMessage ({
                            action = 'baseplate',
                            topic = 'closecompass',
                            show = false,
                        })
                        prevBaseplateStats[1] = false
                    end
                    lastInVehicle = false
                end
            end
            lastHeading = heading
            if lastIsOutCompassCheck ~= sharedConfig.menu.isOutCompassChecked and not IsPedInAnyVehicle(cache.ped) then
                if not sharedConfig.menu.isOutCompassChecked then
                    SendNUIMessage ({
                        action = 'baseplate',
                        topic = 'opencompass',
                        show = true,
                        showCompass = true,
                    })
                else
                    SendNUIMessage ({
                        action = 'baseplate',
                        topic = 'closecompass',
                        show = false,
                    })
                end
                lastIsOutCompassCheck = sharedConfig.menu.isOutCompassChecked
            end
        else
            Wait(1000)
        end
    end
end)
