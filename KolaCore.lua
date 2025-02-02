MESSAGE:New("KolaCore v0.15 Loaded"):ToAll()
env.info("KolaCore v0.15 Loaded")

kola = {} -- pour gérer tout les variable ou fonctions kola. 
kola.tableauSpawnedGroup = {}
kola.isInterceptorAlreadyAirborne = false -- variable pour vérifier la présence des F-14 dans les airs
kola.flagInstance = trigger.misc.getUserFlag("flagInstance") -- pour trapper l'instance de la mission. 0 = prod, 1 = QA, 2 = DEV
env.info("Valeur du flag instance: " .. kola.flagInstance)
redScoreFlag = "RedScore"
blueScoreFlag = "BlueScore"
local RedBorderZones = {
		ZONE:New("RedBorder-1"), 
		ZONE:New("RedBorder-2"),
		ZONE:New("RedBorder-3"),
		ZONE:New("RedBorder-4"),
		ZONE:New("RedBorder-5")
	}

-- Informe quelle type d'instance est en cours
if kola.flagInstance == 0 then
    -- Production: Moins de messages affichés
    env.info("Mode Production activé.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : Production", 20)
elseif kola.flagInstance == 1 then
    -- QA: Messages intermédiaires pour tests
    env.info("Mode QA activé. Messages supplémentaires affichés pour le débogage.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : QA (Quality Assurance)", 20)
    trigger.action.outText("Mode QA actif : validez le bon déroulement de la mission. Fine tuning.", 20)
elseif kola.flagInstance == 2 then
    -- Développement: Plus de détails pour débogage
    env.info("Mode Développement activé.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : Développement", 20)
    trigger.action.outText("Mode Dev actif : Développement, test et débogage", 20)
else
    -- Valeur inattendue
    env.warning("Valeur inattendue pour flagInstance : " .. tostring(flagInstance))
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Erreur : flagInstance a une valeur inattendue !", 10)
end

-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **							 Début section des fonctions                                          **
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
  


flagsToCheck = {}
kola.eventHandler = {}
landingToMonitor = {}
unitlandingToMonitor = {}
grpToMonitor = {}
kola.kh65EventHandler = {}
local range = 500 -- Distance pour le réarmement automatique (en mètres)
efivTerminalZone = ZONE:New("efiv_terminal")

-- Fonction pour vérifier la présence d'avions bleus dans l'une des zones de la frontière russe
function areBluePlanesNearRussianBorder(zones)
    local blueGroups = coalition.getGroups(coalition.side.BLUE, Group.Category.AIRPLANE)
    for _, group in ipairs(blueGroups) do
        if group and group:isExist() then
            for _, unit in ipairs(group:getUnits()) do
                if unit and unit:isExist() then
                    local unitPos = POINT_VEC3:NewFromVec3(unit:getPoint())
                    if unitPos then
                        env.info("Position de l'unité bleue: " .. unit:getName() .. " - x: " .. unitPos.x .. ", y: " .. unitPos.y .. ", z: " .. unitPos.z)
                        for _, zone in ipairs(zones) do
                            if zone and zone:IsPointVec3InZone(unitPos) then
                                env.info("Unité bleue " .. unit:getName() .. " détectée dans la zone " .. zone:GetName())
                                return true
                            else
                                env.info("Unité bleue " .. unit:getName() .. " n'est pas dans la zone " .. zone:GetName())
                            end
                        end
                    else
                        env.warning("Impossible d'obtenir la position de l'unité " .. unit:getName())
                    end
                end
            end
        end
    end
    return false
end



function spawnRedFlankerCIfBluePlanesDetected()
    if areBluePlanesNearRussianBorder(RedBorderZones) then
        Spawn_RedFlankerC = genSpawn("FlankerC", 4, 1800)   
        env.info("RedFlankerC group spawned because blue planes were detected near the Russian border.")
    else
        env.info("No blue planes detected near the Russian border. RedFlankerC group not spawned.")
    end
	TIMER:New(spawnRedFlankerCIfBluePlanesDetected):Start(60)
end

-- Vous pouvez également utiliser un timer pour vérifier périodiquement
TIMER:New(spawnRedFlankerCIfBluePlanesDetected):Start(60) -- Vérifie toutes les 60 secondes

-- Fonction pour rearm un spawn
function ReArmUnit(truckName)
    -- Vérifier si le camion de réarmement existe
    local truckUnit = Unit.getByName(truckName)
    if not truckUnit then
        env.warning("Le camion de réarmement n'a pas été trouvé : " .. truckName)
        return
    end
    env.info("Rearm Truck Name: " .. truckName)
    -- Récupérer la position du camion de réarmement
    local truckPos = truckUnit:getPoint()
    local truckCoalition = truckUnit:getCoalition()

	--[[déplacé dans mathieucorescript.lua
    -- Fonction pour calculer la distance entre deux points
    local function getDistance(point1, point2)
        local dx = point1.x - point2.x
        local dy = point1.y - point2.y
        local dz = point1.z - point2.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end--]]

    -- Trouver toutes les unités dans le monde de la même coalition que le camion de réarmement
    local allUnits = coalition.getGroups(truckCoalition, Group.Category.GROUND)
    local unitsInRange = {}
    -- Parcourir tous les groupes et unités pour trouver celles qui sont à proximité du camion de réarmement
    for _, group in ipairs(allUnits) do
        -- Vérifier si le groupe existe
        if group and group:isExist() then
            -- Parcourir toutes les unités du groupe
            for _, unit in ipairs(group:getUnits()) do
                -- Vérifier si l'unité existe et est à proximité du camion de réarmement    
                if unit and unit:isExist() then
                    -- Récupérer la position de l'unité
                    local unitPos = unit:getPoint()
                    local distance = getDistance(truckPos, unitPos)
                    -- Vérifier si l'unité est à moins de 100 mètres du camion de réarmement
                    if distance <= 100 and unit:getName() ~= truckName then
                        env.info("Unité trouvée près du camion de réarmement: " .. unit:getName() .. " à " .. distance .. " mètres.")
                        --  Ajouter l'unité à la liste des unités à réarmer                    
                        table.insert(unitsInRange, unit)
                    end
                end
            end
        end
    end
    -- Log du nombre d'unités trouvées près du camion de réarmement
    env.info("Nb Units found près du truck: " .. #unitsInRange)
    -- Vérifier si aucune unité n'a été trouvée près du camion de réarmement
    if #unitsInRange == 0 then
        env.warning("Aucune unité trouvée près du camion de réarmement.")
        return
    end-- fin de la vérification des unités trouvées

    -- Trouver les groupes des unités trouvées
    local unitsGroups = {}    
    for _, unit in ipairs(unitsInRange) do
        -- Vérifier si l'unité a un groupe et si le groupe n'a pas déjà été trouvé  
        local group = unit:getGroup()
        if group and not unitsGroups[group:getName()] then
            env.info("Groupe de la unit " .. unit:getName() .." trouvé près du camion de réarmement: " .. group:getName())
            -- Ajouter le groupe à la table des groupes
            unitsGroups[group:getName()] = group
        end
    end

    -- Trouver la première unité de chacun de ces groupes et les placer dans une table
    local positions = {}
    for groupName, group in pairs(unitsGroups) do
        -- Récupérer la première unité du groupe
        local firstUnit = group:getUnit(1)
        local pos = firstUnit:getPosition().p
        -- Ajouter la position à la table
        table.insert(positions, {groupName = groupName, pos = pos, numGroupUnits = group:getSize()})
        env.info("Position de la première unité du groupe " .. groupName .. " trouvée à " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)        
    end

    -- Pour chacun des groupes, faire un SPAWN = New(nom du groupe) et faire un SpawnFromVec3 à la position de l'unité correspondante au groupe
    for _, data in ipairs(positions) do
        local existingGroup = Group.getByName(data.groupName)
        if existingGroup and existingGroup:isExist() then
            existingGroup:destroy()
            env.info("Groupe existant " .. data.groupName .. " supprimé avant le respawn.")
        end
        env.info("Réarmement du groupe " .. data.groupName .. " à la position " .. data.pos.x .. ", " .. data.pos.y .. ", " .. data.pos.z)
        local rearmed_Spawn = SPAWN:New(data.groupName)
        rearmed_Spawn:InitLimit(data.numGroupUnits, 0)
        rearmed_Spawn:SpawnFromVec3(data.pos)
        rearmed_Spawn:Spawn()
        env.info("Réarmement du groupe " .. data.groupName .. " effectué.")
    end    
end-- fin de la fonction ReArmUnit

-- loop pour réarmer les unités
-- Table pour stocker les états de réarmement des camions
local resupplyStatus = {}

-- Fonction pour arrêter la boucle de réarmement pour un camion spécifique
function stopResupply(groupe)
    local groupeName = groupe:GetName()
    if groupeName then
        resupplyStatus[groupeName] = false
    else
        env.warning("Impossible de trouver le groupe pour arrêter le réarmement.")
    end
end

-- Fonction pour démarrer la boucle de réarmement pour un camion spécifique
function startResupply(groupe, loopTime)
    local groupeName = groupe:GetName()
    if groupeName then
        resupplyStatus[groupeName] = true
        loopResupply(groupe, loopTime)
		env.info("La boucle de réarmement pour le groupe " .. groupe:GetName() .. " a été démarrée.")
    else
        env.warning("Impossible de trouver le groupe pour démarrer le réarmement.")
    end
end

-- Fonction pour réarmer les unités en boucle pour un camion spécifique
function loopResupply(groupe, loopTime)
    local groupeName = groupe:GetName()
    if not groupeName or (resupplyStatus[groupeName] ~= nil and not resupplyStatus[groupeName]) then
        env.info("La boucle de réarmement pour le groupe " .. groupe:GetName() .. " a été arrêtée.")
        return
    end

    if groupe and loopTime then
        ReArmUnit(findFirstUnitName(groupe))
        TIMER:New(function() loopResupply(groupe, loopTime) end):Start(loopTime)
    elseif groupe then
        ReArmUnit(findFirstUnitName(groupe))
        TIMER:New(function() loopResupply(groupe, 300) end):Start(300)
    else
        env.warning("Le groupe n'a pas été trouvé pour le réarmement.")
    end
end

-- Pour démarrer la boucle de réarmement pour un camion spécifique
--startResupply(groupe, loopTime)

-- Pour arrêter la boucle de réarmement pour un camion spécifique
--stopResupply(groupe)
--loopResupply(spawnedAmmoTruckGroup)
--loopResupply(spawnedAmmoTruck2Group)

-- Fonction pour vérifier si une unité n'a plus de munitions
function isUnitOutOfAmmo(unit)
    local ammo = unit:getAmmo()
    if ammo then
        for _, weapon in ipairs(ammo) do
            if weapon.count > 0 then
                return false
            end
        end
    end
    return true
end

-- Fonction pour trouver le camion de réarmement le plus proche
function findClosestAmmoTruck(pos)
    local unitPos = unit:getPoint()
    local closestTruck = nil
    local minDistance = math.huge

    for _, truckName in ipairs(ammoTrucks) do
        local truckUnit = Unit.getByName(truckName)
        if truckUnit and truckUnit:isExist() then
            local truckPos = truckUnit:getPoint()
            local distance = getDistance(unitPos, truckPos)
            if distance < minDistance then
                minDistance = distance
                closestTruck = truckUnit
            end
        end
    end

    return closestTruck
end



-- Fonction pour déplacer une unité vers un point
function moveUnitTo(unit, point)
    local controller = unit:getController()
    if controller then
        local mission = {
            id = 'Mission',
            params = {
                route = {
                    points = {
                        [1] = {
                            action = "Cone",
                            x = point.x,
                            y = point.y,
                            z = point.z,
                        }
                    }
                }
            }
        }
        controller:setTask(mission)
    end
end

-- Fonction pour initier le réarmement
function initiateResupply(unit)
    local closestTruck = findClosestAmmoTruck(unit:getPoint())
    if closestTruck then
        moveUnitTo(unit, closestTruck:getPoint())
        loopResupply(closestTruck:getGroup():getName())
    else
        env.warning("Aucun camion de réarmement trouvé pour l'unité " .. unit:getName())
    end
end

-- Table pour stocker les camions dynamiques
ammoTrucks = {}

-- Définition de la méthode onEvent pour gérer les événements
function kola.eventHandler:onEvent(event)
    if event == nil then
        env.warning("L'événement est nul")
        return
    end
	local landedUnitsByGroup = {}
	if event.id == world.event.S_EVENT_LAND then
    	if event.place then
    		env.info("Landing à cette place: " .. event.place:getName() .. " par " .. event.initiator:getName())
		else
			env.warning("L'événement S_EVENT_LAND n'a pas de lieu associé.")
		end

	for i, monitoredUnits in ipairs(unitlandingToMonitor) do
		for _, unitName in ipairs(monitoredUnits) do
			if event.initiator and event.initiator:getName() == unitName then
				env.info("L'unité surveillée " .. unitName .. " a déclenché un événement d'atterrissage.")				
				if landingToMonitor[i] == "all" or (event.place and event.place:getName() == landingToMonitor[i]) then
					env.info("Atterrissage confirmé sur un lieu surveillé : " .. (event.place and event.place:getName() or "Inconnu"))
					local unit = Unit.getByName(unitName)
					if unit and unit:isExist() then
						local group = unit:getGroup()
						if group then
							local groupName = group:getName()
							
							-- Initialise ou met à jour le suivi des unités atterrissées
							landedUnitsByGroup[groupName] = landedUnitsByGroup[groupName] or {}
							landedUnitsByGroup[groupName][unitName] = true
							env.info("Unité enregistrée comme atterrie : " .. unitName)

							-- Log l'état actuel des unités atterrissées
							env.info("DEBUG landedUnitsByGroup pour " .. groupName .. ":")
							for name, _ in pairs(landedUnitsByGroup[groupName]) do
								env.info(" - " .. name)
							end

							-- Vérifie si toutes les unités du groupe ont atterri
							local totalUnits = 0
							local landedUnits = 0
							for _, groupUnit in ipairs(group:getUnits()) do
								if groupUnit and groupUnit:isExist() then
									totalUnits = totalUnits + 1
									if landedUnitsByGroup[groupName][groupUnit:getName()] then
										landedUnits = landedUnits + 1
									else
										env.warning("Unité non enregistrée comme atterrie : " .. groupUnit:getName())
									end
								end
							end

							if totalUnits == landedUnits and totalUnits > 0 then
								env.info("Toutes les unités du groupe " .. groupName .. " ont atterri.")
								group:destroy()
								--landedUnitsByGroup[groupName] = nil
								--table.remove(unitlandingToMonitor, i)
								--table.remove(landingToMonitor, i)
							else
								env.info("Atterrissages incomplets : " .. landedUnits .. "/" .. totalUnits)
							end
						else
							env.warning("Impossible d'obtenir le groupe pour l'unité " .. unitName)
						end
					else
						env.warning("L'unité " .. unitName .. " n'existe pas ou n'est pas valide.")
					end
				else
					env.info("Atterrissage non surveillé ou lieu non valide.")
				end
			end
		end
	end


		
		
    -- Vérification des décollages de F-14
    elseif event.id == world.event.S_EVENT_TAKEOFF then
        if event.initiator:getTypeName() == "F-14B" or event.initiator:getTypeName() == "F-14A" then
            -- Appel de la fonction AttackGroupTaskPush avec validation des paramètres
            if spawnedBlueInterceptName ~= nil and spawnedRedStrikeGroupName ~= nil then
                AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0)
                env.info("AttackGroupTaskPush appelé avec les paramètres :")
                env.info("Attaquant : " .. tostring(spawnedBlueInterceptName) .. ", Cible : " .. tostring(spawnedRedStrikeGroupName))
            else
                env.warning("Erreur : spawnedBlueInterceptName ou spawnedRedStrikeGroupName est nil.")
                env.info("spawnedBlueInterceptName : " .. tostring(spawnedBlueInterceptName))
                env.info("spawnedRedStrikeGroupName : " .. tostring(spawnedRedStrikeGroupName))
            end

            -- Gestion de l'état des intercepteurs
            if not kola.isInterceptorAlreadyAirborne then
                env.info("Un F-14 a décollé : " .. event.initiator:getName())
                if kola.flagInstance == 2 then
                    trigger.action.outText("F-14 détecté dans le ciel !", 10)
                end
                Spawn_RedStrikeEscort:Spawn() -- Démarre l'escorte
                kola.isInterceptorAlreadyAirborne = true
            end
        else
            -- Vérifie si des F-14 sont actifs
            if not kola.detectActiveF14s() then
                if kola.isInterceptorAlreadyAirborne then
                    env.info("Aucun F-14 actif. Arrêt de l'escorte.")
                    if Spawn_RedStrikeEscort ~= nil then 
                        --Spawn_RedStrikeEscort:SpawnScheduleStop() 
                    end
                    kola.isInterceptorAlreadyAirborne = false
                end
            end
        end
    end
end




-- Fonction de gestion des atterrissages des helicos ai pour dispawn
-- Fonction pour vérifier s'il y a des F-14B ou F-14A actifs
function kola.detectActiveF14s()
    local blueUnits = coalition.getPlayers(coalition.side.BLUE) -- Récupère toutes les unités de la coalition bleue
    for _, unit in pairs(blueUnits) do
        if unit:isExist() and unit:getLife() > 0 then -- Vérifie que l'unité existe et est en vie
            local unitType = unit:getTypeName()
            local unitAltitude = unit:getPoint().y -- Récupère l'altitude de l'unité

            -- Vérifie si c'est un F-14 (A ou B) et si l'altitude est significative (au-dessus du sol)
            if (unitType == "F-14B" or unitType == "F-14A") and unitAltitude > 10 then -- Tolérance pour considérer "en vol"
                env.info("F-14 actif détecté : " .. unit:getName())
                return true
            end
        end
    end
    return false -- Aucun F-14 actif trouvé
end

-- Enregistrement du gestionnaire d'événements
world.addEventHandler(kola.eventHandler)


  -- Fonction pour s'abonner à l'événement LAND pour un lieu spécifique
function kola.subscribeToLandEvent(placeToMonitor, Grp) -- utilisez "all" dans placeToMonitor pour surveiller tous les airfields.
    
    table.insert(landingToMonitor, placeToMonitor)
    
    -- Obtenir toutes les unités du groupe Moose
    local unitNames = {}  -- Table pour stocker les noms des unités
    for _, unit in ipairs(Grp:GetUnits()) do
        table.insert(unitNames, unit:GetName())  -- Ajouter le nom de chaque unité
    end
    table.insert(unitlandingToMonitor, unitNames)  -- Ajouter la table des noms au tableau
    
    table.insert(grpToMonitor, Grp)
    
    -- Enregistre le gestionnaire d'événements
    world.addEventHandler(kola.eventHandler)
end
 
-- Fonction pour détecter la présence de F-14B ou F-14A bleus dans le ciel


  
 function kola.addFirstUnitNameToTransportTable(groupName)
    -- Vérifiez si le groupe existe
    local group = Group.getByName(groupName)
    if group then
        -- Obtenez la liste des unités du groupe
        local units = group:getUnits()
        if units and #units > 0 then
            -- Récupérez le nom de la première unité
            local firstUnit = units[1]
            if firstUnit and firstUnit:isExist() then
                local unitName = firstUnit:getName()
                
                -- Ajoutez ce nom à la table `ctld.transportPilotNames`
                table.insert(ctld.transportPilotNames, unitName)
                
                -- Log pour confirmation
                env.info("Nom de la première unité ajouté à ctld.transportPilotNames: " .. unitName)
            else
                env.warning("La première unité du groupe n'existe pas.")
            end
        else
            env.warning("Aucune unité trouvée dans le groupe : " .. groupName)
        end
    else
        env.warning("Groupe introuvable : " .. groupName)
    end
end


-- Fonction pour obtenir et afficher le score
function kola.getMissionScore()
    local blueScore = trigger.misc.getUserFlag("BlueScore") -- Lire le drapeau BlueScore
    local redScore = trigger.misc.getUserFlag("RedScore")   -- Lire le drapeau RedScore

    -- Construire le message
    local messageText = "Le score est de : " .. blueScore .. " pour les bleus et de : " .. redScore .. " pour les rouges"
	MESSAGE:New(messageText):ToAll() -- Envoyer le message en jeu
	

    -- Écrire le score dans un fichier
    --kola.writeScoreToFile(blueScore, redScore) Désactivé, retirer le commentaire pour activer et desanitize le serveur de mission
end

-- Fonction pour écrire le score dans un fichier
function kola.writeScoreToFile(blueScore, redScore)
    local lfs = lfs -- LFS est déjà disponible dans DCS

    -- Obtenir le chemin du répertoire de la mission
    local missionDir = lfs.writedir() .. "Missions/"

    -- Générer le nom du fichier avec la date et l'heure actuelles
    local date = os.date("%Y-%m-%d-%H-%M") -- Format : aaaa-mm-jj-hh:mm
    local filename = missionDir .. "score_" .. date .. ".txt"

    -- Créer le contenu du fichier
    local content = "Scores de la mission :\n"
    content = content .. "Bleus : " .. blueScore .. "\n"
    content = content .. "Rouges : " .. redScore .. "\n"
    content = content .. "Enregistré à : " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"

    -- Ouvrir le fichier en mode écriture
    local file, err = io.open(filename, "w")
    if file then
        file:write(content) -- Écrire le contenu dans le fichier
        file:close() -- Fermer le fichier
        env.info("Score écrit dans le fichier : " .. filename) -- Log dans le fichier DCS
    else
        env.warning("Erreur lors de l'écriture du fichier : " .. err) -- Log en cas d'erreur
    end
end

function kola.monitorEndgameFlag()
    local flagValue = trigger.misc.getUserFlag("EndgameFlag") -- Obtenir la valeur du flag
    if flagValue == 1 then
        -- Exécuter la fonction de changement du ROE
        env.info("EndgameFlag is ON, executing setAircraftGroupsROEToReturnFire...")
        setAircraftGroupsROEToReturnFire()
        
        -- Réinitialiser le flag pour éviter les répétitions
        trigger.action.setUserFlag("EndgameFlag", 0)
    end

    -- Répéter la vérification toutes les 2 secondes
    timer.scheduleFunction(kola.monitorEndgameFlag, nil, timer.getTime() + 2)
end
kola.monitorEndgameFlag()

-- Score pour Kill de missile de croisière ou 
-- Nom du flag à mettre à jour dans le mission editor vient le nom du flag à utiliser, ici BlueScore
local blueScoreFlag = "BlueScore"

-- Gestionnaire d'événements
kola.artilleryUnithasAttacked = {}
local lastScoreTime = 0
function kola.kh65EventHandler:onEvent(event)
	if event.id == world.event.S_EVENT_UNIT_LOST then
        if event.initiator then
            
			local initiatorName = event.initiator:getName() or "Unité sans nom"
            local initiatorType = event.initiator:getTypeName() or "Type inconnu"
            local initiatorCategory = event.initiator:getCategory() or "Catégorie inconnue"
			local currentScore = trigger.misc.getUserFlag(blueScoreFlag) or 0
			--local weapon = event.weapon
			--env.info("Type de l'arme : " .. weapon:getTypeName())
			--[[
			MESSAGE:New("Type de l'arme : " .. weapon:getTypeName()):ToAll()
			MESSAGE:New("Type de l'initiateur : " .. initiatorType):ToAll()
			MESSAGE:New("Catégorie de l'initiateur : " .. initiatorCategory):ToAll()
			MESSAGE:New("Nom de l'initiateur : " .. initiatorName):ToAll()
			--]]

			-- Vérifier si l'instance est en mode débogage
			if kola.flagInstance == 2 then
            -- Détection d'une unité ou d'un missile détruit
            trigger.action.outText("Unité perdue : " .. initiatorName .. 
                                   " (Type: " .. initiatorType .. ", Catégorie: " .. initiatorCategory .. ")", 10)
			end
            -- Vérifier si l'objet est un missile surveillé pour pointage
            if initiatorType == "X_65"   then
				local newScore = currentScore + 50
                trigger.action.setUserFlag(blueScoreFlag, newScore)                
				trigger.action.outText("Missile de croisière Kh-65 détruit. +50 points pour les Blues. Score actuel : " .. newScore, 10)
				env.info("Un missile " .. initiatorType .. " a été détruit ! Score actuel : " .. newScore)
            elseif initiatorType == "X_22" then
				local newScore = currentScore + 100
				trigger.action.setUserFlag(blueScoreFlag, newScore)                
				trigger.action.outText("Missile de anti navire Kh-22 détruit. +100 points pour les Blues. Score actuel : " .. newScore, 10)
				env.info("Un missile " .. initiatorType .. " a été détruit ! Score actuel : " .. newScore)
--[[
			elseif initiatorType == "SMERCH_9M55F" then
				local IvaloAirFieldZone = ZONE:New("IvaloAirFieldZone")
				local weaponPos = weapon:getPoint()
				if IvaloAirFieldZone:IsVec3InZone(weaponPos) then
					trigger.action.outText("Missile 9M55F a touché la zone IvaloAirFieldZone", 10)
					env.info("Missile 9M55F a touché la zone IvaloAirFieldZone")
				end]]--
			end
        else
            trigger.action.outText("Une unité anonyme a été perdue", 10)
        end
    end-- fin de l'event S_EVENT_UNIT_LOST
	
	if event.id == world.event.S_EVENT_MARK_REMOVED then
		eventPos = event.pos
		if event.text then
			env.info("Marque supprimée : " .. event.text)
			if string.sub(event.text, 1, 6) == "-Spawn" then --valider que la string commence par -Spawn	
				local altitudeString = string.match(event.text, "^%-Spawn%s*(%d+)")
				env.info("Altitude de spawn : " .. altitudeString)    
				if altitudeString then
					-- Convertir la chaîne en nombre et stocker dans une variable
					local spawnAltitude = tonumber(altitudeString)
					eventPos.y=spawnAltitude
					-- Documenter l'altitude détectée
					trigger.action.outText("Commande Spawn détectée avec altitude : " .. spawnAltitude, 10)        
					-- Utiliser ou stocker l'altitude pour plus tard
					env.info("Altitude de spawn définie : " .. spawnAltitude)        									
				else
						-- Si aucune altitude n'est trouvée, informer l'utilisateur
						trigger.action.outText("Erreur : Aucune altitude valide après '-Spawn'.", 10)
				end					
				SPAWN:New("SpawnTest") --spawener à la position de la mark et à l'altitude indiquée dans le text de l'envent
					:SpawnFromVec3(eventPos)
					--:Spawn()
			end
		end
	end	-- fin de l'event S_EVENT_MARK_REMOVED

	
	
	
	if event.id == world.event.S_EVENT_HIT then
        local weapon = event.weapon
        if weapon then
            local weaponPos = weapon:getPoint()
            local currentTime = timer.getTime()
            
            if efivTerminalZone:IsVec3InZone(weaponPos) and (currentTime - lastScoreTime) >= 5 then
                -- Incrémenter le score des rouges                
                local currentScore = trigger.misc.getUserFlag(redScoreFlag) or 0
                local newScore = currentScore + 50 -- Ajouter 50 points
                trigger.action.setUserFlag(redScoreFlag, newScore)
                if (currentTime - lastScoreTime) >= 30 then
					trigger.action.outText("Ivalo airfield subit des dégats!", 20)					
				end
				lastScoreTime = currentTime
				env.info("Ivalo airfield subit des dégats. Les rouges ont gagné 50 points. Score actuel : " .. newScore)
            end
        end
    end
end-- fin de la fonction onEvent


-- Enregistre le gestionnaire d'événements
world.addEventHandler(kola.kh65EventHandler)






-- Fonction pour parser la chaîne de caractères et extraire les valeurs
function kola.parseSpawnString(spawnString)
    local textTrigger, x, y, z = string.match(spawnString, "^(%-Spawn)%s+x=(%d+),%s+y=(%d+),%s+z=(%d+)$")
    if textTrigger and x and y and z then
        x = tonumber(x)
        y = tonumber(y)
        z = tonumber(z)
        return textTrigger, x, y, z
    else
        env.warning("La chaîne de caractères n'est pas dans le format attendu.")
        return nil
    end
end


-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **
-- **                            Section de définition des spawns.                                    **
-- **
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************

--***
--RED Spawns:
---
-- Fonction pour spawn un camion de ravitaillement
Spawn_AmmoTruck = genSpawn("RearmTruck-1",1,300)
Spawn_AmmoTruck:OnSpawnGroup(function(grp)
	spawnedAmmoTruckGroupName = grp:GetName() -- Stocke le nom du groupe spawné
	spawnedAmmoTruckGroup = grp -- Stocke l'objet du groupe spawné
	if kola.flagInstance == 2 then
		MESSAGE:New("Camion de ravitaillement spawné : " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
	end	
end)

Spawn_AmmoTruck2 = genSpawn("RedAmmoTruck-1",1,300)
Spawn_AmmoTruck2:OnSpawnGroup(function(grp)
	spawnedAmmoTruck2GroupName = grp:GetName() -- Stocke le nom du groupe spawné
	spawnedAmmoTruck2Group = grp -- Stocke l'objet du groupe spawné
	if kola.flagInstance == 2 then
		MESSAGE:New("Camion de ravitaillement 2 spawné : " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
	end	
end)

-- supply guards
spawn_supplyguards = genSpawn("SupplyGuards",2,300)


-- Red Anti Air
	--KirkenesSAM
		Spawn_KirkenesSAM = genSpawn("KirkenesSAM",18,1200)
		
	--fin de KirkenesSAM
-- fin de red anti air

--Red Infantry
	--Red Drop Troops
	Spawn_RedTroop = genSpawn( "TroopTransportSpawn", 16, 0 )		
	Spawn_RedManpadTroop = genSpawn( "RedManPadSpawn", 2, 0 )
	
	--Spawn les petits soldats
	  petitsSoldatsZoneTable = { 	
					ZONE:New( "SoldatSpawnZone-1" ), 
					ZONE:New( "SoldatSpawnZone-2" ),
					ZONE:New( "SoldatSpawnZone-3" ),
					ZONE:New( "SoldatSpawnZone-4" ), 
					ZONE:New( "SoldatSpawnZone-5" )
				}

	Spawn_Soldats = genSpawn ( "SpawnSoldat", 20, 45, petitsSoldatsZoneTable)
	
	--sneak AAA attack
	Spawn_RedSneak1 = genSpawn( "RedSneakAttack-1", 11, 300 )
	Spawn_RedSneak1:InitLimit(11, 55)
	Spawn_RedSneak2 = genSpawn( "RedSneakAttack-2", 11, 300 )
	Spawn_RedSneak2:InitLimit(11, 55)
	Spawn_RedSneak3 = genSpawn( "RedSneakAttack-3", 3, 300 )
	Spawn_RedSneak3:InitLimit(3, 15)

	--RedOffensiveArtillery
	---[[ old gen artillery
	Spawn_RedOffensiveArtillery = genSpawn( "RedOffensiveArtillery", 3, 300 )
	Spawn_RedOffensiveArtillery:OnSpawnGroup(function(grp)
		spawnedRedOffensiveArtilleryGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedOffensiveArtilleryGroup = grp -- Stocke l'objet du groupe spawné
		if kola.flagInstance == 2 then
			MESSAGE:New("Artillerie offensive spawnée : " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
		end
		-- Log dans le dcs.log
		env.info("Spawned OffensiveArtillerygroup name: " .. spawnedRedOffensiveArtilleryGroupName)
		
			
	end)--]]

--[[function ReSpawnArtillery()
	Spawn_RedOffensiveArtillery = SPAWN:New( "RedOffensiveArtillery")
		:InitLimit(4, 0)
		:SpawnScheduled(300, 0.6)
		:Spawn()
	TIMER:New(ReSpawnArtillery):Start(300)
end
ReSpawnArtillery()--]]
--TIMER:New(function() ReArmUnit("RearmTruck-1-1") end):Start(30) old rearm function call
env.info("RearmTruck-1-1 tente de réarmer les unités")


	

-- FIN RED INFANTRY

-- Red Naval
	--Spawn Les Speedboat
	ZoneSpeedBoatTable = { ZONE:New( "NavalSpawnZone-1" ) }
	Spawn_Rescue_1 = genSpawn( "NavalSpawn-1", 10, 60 , ZoneSpeedBoatTable )

	--Red Backup (Speedboat)
	Spawn_RedBackup = genSpawn( "RedBackupSpawn", 8, 0 )
	Spawn_RedBackup:OnSpawnGroup(function(grp)
			spawnedRedBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
			spawnedRedBackupGroup = grp -- Stocke l'objet du groupe spawné
			-- Message pour les joueurs
			if kola.flagInstance == 2 then
				MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
			end
		
			-- Log dans le dcs.log
			env.info("Spawned Backupgroup name: " .. spawnedRedBackupGroupName)
		end)
			
	-- Naval Targets
	--Naval Tanker Target
	NavalTargetSpawnZoneTable = { 	
					ZONE:New( "NavalTargetSpawnZone" )
				}	  
	Spawn_RedNavalTankerTarget = genSpawn("NavalTankerSpawn",8,600, NavalTargetSpawnZoneTable)	
-- FIN RED NAVAL TARGET

-- RED Helico
	-- Spawn Red Transport
	Spawn_RedTransport = SPAWN:New("RedTransportSpawn")
	  :InitLimit(2, 0)
	  :OnSpawnGroup(function(grp)
		  local firstUnit = findFirstUnitName(grp)
		  if firstUnit then
			   kola.addFirstUnitNameToTransportTable(grp:GetName())
			  table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
			  ctld.preLoadTransport(firstUnit, 10, true)
			  kola.subscribeToLandEvent("Naval-3-1", grp)

			  -- Log dans le dcs.log
			  env.info("Spawned group name: " .. grp:GetName())

			  -- Associe un flag nommé au groupe pour sa gestion
			  local flagName = "LifeTime_" .. grp:GetName()
			  trigger.action.setUserFlag(flagName, 1)
			  subscribeLifeTimeChecker(grp, 1800, flagName)
		  else
			  env.warning("Aucune unité trouvée dans le groupe: " .. grp:GetName())
		  end
	  end)
	  :SpawnScheduled(180, 0.6)
	  :SpawnScheduleStop()
	

	-- Red Helico Backup
	Spawn_RedHeloBackup = genSpawn( "RedHeloBackup", 1, 0 )	
	Spawn_RedHeloBackup:OnSpawnGroup(function(grp)
		spawnedRedHeloBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedHeloBackupGroup = grp -- Stocke l'objet du groupe spawné
		if kola.flagInstance == 2 then
			MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
		end
    
		-- Log dans le dcs.log
		env.info("Spawned Backupgroup name: " .. spawnedRedHeloBackupGroupName)
		kola.subscribeToLandEvent("all", grp)
		local flagName = "LifeTime_" .. grp:GetName()
        trigger.action.setUserFlag(flagName, 1)
        subscribeLifeTimeChecker(grp, 1800, flagName)
	end) 
	--End of Red Helico Backup
 
	-- Spawn Red Vehicule Transport
	Spawn_RedVehiculeTransport = genSpawn("RedVehiculeTransportSpawn",1,180)
	Spawn_RedVehiculeTransport:SpawnScheduleStop()
	Spawn_RedVehiculeTransport:OnSpawnGroup(function(grp)
			local firstUnit = findFirstUnitName(grp)
			if firstUnit then
				kola.addFirstUnitNameToTransportTable(grp:GetName())
				table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
				ctld.preLoadTransport(firstUnit, {inf = 8, at = 6, aa = 2}, true)
				kola.subscribeToLandEvent("Naval-3-1", grp)

				-- Log dans le dcs.log
				env.info("Spawned group: " .. grp:GetName())

				local flagName = "LifeTime_" .. grp:GetName()
				trigger.action.setUserFlag(flagName, 1)
				subscribeLifeTimeChecker(grp, 1200, flagName)
			else
				env.warning("Aucune unité trouvée dans le groupe: " .. grp:GetName())
			end		
		end)
	--Red Hind Strike on Banak
	Spawn_RedHindStrike = genSpawn("HindStike",4,600)
--FIN RED Helico	  
	  
-- Red Aircrafts --
	-- Endgame (Poseidon Tu-22 Flight anti ship strike)
	Endgame_ZoneTable = { 	
					ZONE:New( "EndgameSpawnZone-1" ), 
					ZONE:New( "EndgameSpawnZone-2" ),
					ZONE:New( "EndgameSpawnZone-3" ),
					ZONE:New( "EndgameSpawnZone-4" ), 
					ZONE:New( "EndgameSpawnZone-5" )
					
				}
	Spawn_Endgame = genSpawn( "Poseidon", 4, 360, Endgame_ZoneTable )
	Spawn_Endgame:SpawnScheduleStop()
	Spawn_Endgame:OnSpawnGroup(function(grp)
			spawnedEndgameGroupName = grp:GetName()
			spawnedEndgameGroup = grp
			if kola.flagInstance == 2 then
				MESSAGE:New("Poseidons Spawned"):ToAll()
			end
			kola.subscribeToLandEvent("Murmansk International", grp)
			
			-- Log dans le dcs.log
			env.info("Spawned EndGame name: " .. spawnedEndgameGroupName)
			end) 
	-- End of EndgameSpawn
	-- Red Strike
	 RedStrike_ZoneTable = { 	
					ZONE:New( "RedStrikeSpawnZone-1" ), 
					ZONE:New( "RedStrikeSpawnZone-2" ),
					ZONE:New( "RedStrikeSpawnZone-3" ),
					ZONE:New( "RedStrikeSpawnZone-4" ), 
					ZONE:New( "RedStrikeSpawnZone-5" ),
					ZONE:New( "RedStrikeSpawnZone-6" )
				}
				
	Spawn_RedStrike = genSpawn( "RedStrike1", 4 , 180, RedStrike_ZoneTable )
	Spawn_RedStrike:OnSpawnGroup(function(grp)
			spawnedRedStrikeGroupName = grp:GetName() -- Stocke le nom du groupe spawné
			spawnedRedStrikeGroup = grp -- Stocke l'objet du groupe spawné
			local flagName = "LifeTime_" .. grp:GetName()
			  trigger.action.setUserFlag(flagName, 1)
			  subscribeLifeTimeChecker(grp, 5400, flagName)-- 1h30 lifespan max, à voir
			if kola.flagInstance == 2 then
				MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
			end
			-- Log dans le dcs.log
			env.info("Spawned Strikegroup name: " .. spawnedRedStrikeGroupName)
			if kola.detectActiveF14s() then AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0) end
			kola.subscribeToLandEvent("all", grp)
		end) 
	Spawn_RedStrike:SpawnScheduleStop() 
	-- End of Red Strike
 
	--Red Strike Escort (Su-27)
	RedStrike_ZoneTable = { 	
					ZONE:New( "RedStrikeSpawnZone-1" ), 
					ZONE:New( "RedStrikeSpawnZone-2" ),
					ZONE:New( "RedStrikeSpawnZone-3" ),
					ZONE:New( "RedStrikeSpawnZone-4" ), 
					ZONE:New( "RedStrikeSpawnZone-5" ),
					ZONE:New( "RedStrikeSpawnZone-6" )
				}				
	Spawn_RedStrikeEscort = genSpawn( "RedEscortSpawn", 2, 0, RedStrike_ZoneTable )
	Spawn_RedStrikeEscort:OnSpawnGroup(function(grp)
				local spawnedRedEscortSpawnStrikeGroupName = grp:GetName() -- Stocke le nom du groupe spawné
				local spawnedRedEscortSpawnStrikeGroup = grp -- Stocke l'objet du groupe spawné
				if not kola.detectActiveF14s() then
					kola.isInterceptorAlreadyAirborne = false
					if not kola.isInterceptorAlreadyAirborne then
						env.info("Su-27: Aucun F-14 actif. Arrêt de l'escorte.")
						if Spawn_RedStrikeEscort ~= nil then Spawn_RedStrikeEscort:SpawnScheduleStop()	end -- Arrête l'escorte s'il n'y a plus de F-14
					end
				else
					MESSAGE:New("Su-27: Враг обнаружен!"):ToAll()
				end
			-- Log dans le dcs.log
				env.info("Spawned Strikegroup name: " .. grp:GetName())
				if kola.detectActiveF14s() then AttackGroupTaskPush(spawnedRedEscortSpawnStrikeGroupName, spawnedBlueInterceptName, 1) end
				kola.subscribeToLandEvent("all", grp)
			end) 
		 
	 -- End of Red Strike Escort
 
	-- Red Interceptors Mig-25
	Spawn_RedInterceptor = genSpawn( "Foxbat-1", 10, 900 )
	Spawn_RedInterceptor:OnSpawnGroup(function(grp)
				local spawnedRedInterceptorGroupName = grp:GetName() -- Stocke le nom du groupe spawné
				local spawnedRedInterceptorGroup = grp -- Stocke l'objet du groupe spawné
				--Log dans le dcs.log
				env.info("Spawned Strikegroup name: " .. grp:GetName())
				if kola.flagInstance == 2 then
					MESSAGE:New("Foxbat Spawned"):ToAll()
				end
				kola.subscribeToLandEvent("Olenya", grp)
			end)   
	-- Spawn des mig 21 patrouille russe
	Spawn_RedPatrol = genSpawn("RedPatrolMig21",9,1200)
	Spawn_RedPatrol:OnSpawnGroup(function(grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 5400, flagName) 
			kola.subscribeToLandEvent("all", grp )
			end)
	Spawn_RedPatrol:SpawnScheduleStart()

	-- blackjack Tu-160
	Spawn_Blackjack = genSpawn("Blackjack",8,1800)
	Spawn_Blackjack:OnSpawnGroup(function(grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 2400, flagName) 
			kola.subscribeToLandEvent("all", grp )
			monitorGroupDestroyOnWaypoint(grp:GetName(), 3)
			end)
	Spawn_Blackjack:SpawnScheduleStart()

	-- Su-30 Flanker-C Déplacé dans la fonction qui surveille la frontiere Red
	
	
	
	
	-- RedIranHelp
	Spawn_RedIranHelp = genSpawn("RedIranHelp", 3, 600)
	Spawn_RedIranHelp:SpawnScheduleStop()
	



--FIN RED Aircrafts
--FIN RED Spawns

-- **************************************************************** 
-- **************************************************************** 
-- **                     Blue spawns                            **
-- **************************************************************** 
-- **************************************************************** 

-- BLUE INFANTRY / TANK
	--Spawn Bleu Manpad 
	Spawn_BlueAirDef_1 = genSpawn("BlueAirDef",2,180)
	-- fin Bleu Manpad
	
	--Spawn Soldats Def Bleu
	BlueDefZoneTable = { ZONE:New( "BlueDefSpawnZone" ) }
	Spawn_BlueDef_1 = genSpawn("BlueDefenderInfantry",10,60,BlueDefZoneTable)
	-- fin soldats def Bleu
	
	
	--Liberators
	Spawn_BlueLiberatrors = genSpawn( "LiberatorsSpawn", 3, 0)
	Spawn_BlueLiberatrors:OnSpawnGroup(function(grp)
			spawnedLiberatorGroupName = grp:GetName() -- Stocke le nom du groupe spawné
			spawnedLiberatorGroup = grp -- Stocke l'objet du groupe spawné    
			end)
			
	-- Détruire les liberators restants, si défini
	if spawnedLiberatorGroup and spawnedLiberatorGroup:IsAlive() then
	  spawnedLiberatorGroup:Destroy()
	end
	-- fin Liberators

-- spawn pour BlueKirunaGroundBackup
Spawn_BlueKirunaGroundBackup = genSpawn("BlueKirunaGroundBackup", 6, 1800)	


-- FIN BLUE INFANTRY
-- Rearm Trucks
-- SamRearmTruck

Spawn_SamRearmTruck = genSpawn("SamRearmTruck",1,300)
Spawn_SamRearmTruck:OnSpawnGroup(function(grp)
	spawnedSamRearmTruckGroupName = grp:GetName() -- Stocke le nom du groupe spawné
	spawnedSamRearmTruckGroup = grp -- Stocke l'objet du groupe spawné
	if kola.flagInstance == 2 then
		MESSAGE:New("Camion de ravitaillement 2 spawné : " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
	end	
end)

-- BLUE Aircrafts

-- Blue AirPatrol F-16
	Spawn_BluePatrol = genSpawn( "IceVenom-1" , 2 , 600)	
	Spawn_BluePatrol:OnSpawnGroup(function(grp)
		local spawnedBluePatrolGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		local spawnedBluePatrolGroup = grp -- Stocke l'objet du groupe spawné
	    --Log dans le dcs.log
		env.info("Spawned Strikegroup name: " .. grp:GetName())
		if kola.flagInstance == 2 then
			MESSAGE:New("IceVenom Spawned"):ToAll()
		end
		kola.subscribeToLandEvent("Kiruna", grp)
	end) 
	
	Spawn_BlueF16Patrol = genSpawn("BleuViggenPatrol", 3, 900) -- changé pour des viggen AJS37, mais je garde le nom du spawn pour compatibilité.
	Spawn_BlueF16Patrol:OnSpawnGroup(function(grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 4300, flagName) 
			kola.subscribeToLandEvent("Vidsel", grp )
			monitorGroupDestroyOnWaypoint(grp:GetName(), 4)
			end)
	Spawn_BlueF16Patrol:SpawnScheduleStop()

	Spawn_BlueViggenPatrol2 = genSpawn("BleuViggenPatrol-2", 3, 900)

	--Blue AWAC
	Spawn_BlueAWAC = genSpawn("BleuAWAC", 1, 1800)
	Spawn_BlueAWAC:OnSpawnGroup(function(grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			--subscribeLifeTimeChecker(grp, 4300, flagName) 
			kola.subscribeToLandEvent("CVN75", grp )
			end)
	Spawn_BlueAWAC:SpawnScheduleStop()

	--Blue Tankers
	Spawn_BlueTexaco = genSpawn("Texaco-288-T88Y", 1, 1800)
	Spawn_BlueArco = genSpawn("Arco-268-T68Y", 1, 1800)

	--Blue F14 Interceptors
	Spawn_BlueIntercept = genSpawn("TomcatIntercept", 4, 120)
	Spawn_BlueIntercept:SpawnScheduleStop()
	Spawn_BlueIntercept:OnSpawnGroup(function(grp)
			spawnedBlueInterceptName = grp:GetName()-- Stocke le nom du groupe spawné
			spawnedBlueInterceptGroup = grp
			kola.subscribeToLandEvent("all", grp )
					env.info("Spawned group name: " .. grp:GetName())
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 5400, flagName)				
			end)

	Spawn_BlueDeathStrikeF16 = genSpawn("BlueDeathStrikeF16", 3, 1800)
	Spawn_BlueDeathStrikeF16:SpawnScheduleStop()

-- fin bleu Aircrafts

-- Bleu Helico
	-- Spawn Bleu CH-47F
	Spawn_BlueChinook = genSpawn("helicargo11",2, 1700)
	Spawn_BlueChinook:OnSpawnGroup(function(grp)
			kola.addFirstUnitNameToTransportTable(grp:GetName())
			table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
			ctld.preLoadTransport(firstUnit, 33, true)
			--kola.subscribeToLandEvent("Kiruna", grp)
			kola.subscribeToLandEvent("Bodo", grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 5400, flagName)
		end)
	-- Spawn Bleu helo patrol
	Spawn_BlueHeloPatrol = genSpawn("BleuHeloPatrol",4, 1700)
	Spawn_BlueHeloPatrol:OnSpawnGroup(function(grp)
			kola.subscribeToLandEvent("Tarawa-1", grp)
			--kola.subscribeToLandEvent("Bodo", grp)
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 5400, flagName)
		end)
	--Spawn BlueAttackChopper
	Spawn_BlueAttack = genSpawn("BlueSpawnAttack",2,30)
	Spawn_BlueAttack:SpawnScheduleStop()
	Spawn_BlueAttack:OnSpawnGroup(function(grp)
			spawnedBlueAttackGroupName = grp:GetName()-- Stocke le nom du groupe spawné
			spawnedBlueAttackGroup = grp
			kola.subscribeToLandEvent("Tarawa-1", grp )
					env.info("Spawned group name: " .. grp:GetName())
			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 1100, flagName)
			end)	  
	-- fin Spawn BlueAttackChopper

	-- Ravitailleur (Blue Transport)
	
	Spawn_Ravitailleur = genSpawn("BlueRenfortTroopTransport",1, 80)
	Spawn_Ravitailleur:OnSpawnGroup(function(grp)
				local firstUnit = findFirstUnitName(grp)
				kola.addFirstUnitNameToTransportTable(grp:GetName())
				table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
				--kola.subscribeToLandEvent("Tarawa-1", grp)
				-- Log dans le dcs.log
				env.info("Spawned group name: " .. grp:GetName())
				-- Associe un flag nommé au groupe pour sa gestion
				local flagName = "LifeTime_" .. grp:GetName()
				trigger.action.setUserFlag(flagName, 1)
				subscribeLifeTimeChecker(grp, 1800, flagName)					
			end)
	Spawn_Ravitailleur:SpawnScheduleStop()

	Spawn_Ravitailleur2 = genSpawn("BlueRenfortTroopTransport-1",1, 80)
	Spawn_Ravitailleur2:OnSpawnGroup(function(grp)
				local firstUnit = findFirstUnitName(grp)
				kola.addFirstUnitNameToTransportTable(grp:GetName())
				table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
				--kola.subscribeToLandEvent("Tarawa-1", grp)
				-- Log dans le dcs.log
				env.info("Spawned group name: " .. grp:GetName())
				-- Associe un flag nommé au groupe pour sa gestion
				local flagName = "LifeTime_" .. grp:GetName()
				trigger.action.setUserFlag(flagName, 1)
				subscribeLifeTimeChecker(grp, 1800, flagName)					
			end)
	Spawn_Ravitailleur2:SpawnScheduleStop()
	
	--[[ 3 ravitaileurs c'est un peu beaucoup
	Spawn_Ravitailleur3 = genSpawn("BlueRenfortTroopTransport-2",1, 80)
	Spawn_Ravitailleur3:OnSpawnGroup(function(grp)
				local firstUnit = findFirstUnitName(grp)
				kola.addFirstUnitNameToTransportTable(grp:GetName())
				table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
				--kola.subscribeToLandEvent("Tarawa-1", grp)
				-- Log dans le dcs.log
				env.info("Spawned group name: " .. grp:GetName())
				-- Associe un flag nommé au groupe pour sa gestion
				local flagName = "LifeTime_" .. grp:GetName()
				trigger.action.setUserFlag(flagName, 1)
				subscribeLifeTimeChecker(grp, 1800, flagName)					
			end)
	Spawn_Ravitailleur3:SpawnScheduleStop()
	--]]
		
	-- fin Ravitailleur (Blue Transport)


--****************
--FIN BLEU Spawns
--****************
  
  
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **																								  **	
-- **                            FIN Section de définition des spawns.                                **
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************


-- Menu principal
local kolaMenu = missionCommands.addSubMenu("Mission Commands", EODMenu)
	missionCommands.addCommand("Score", kolaMenu, kola.getMissionScore)			
	local alliesMenu = missionCommands.addSubMenu("Allies Commands", kolaMenu)
		-- Sous-menu pour les intercepteurs F-14
		local allyF14InterceptSubMenu = missionCommands.addSubMenu("F-14 Interceptors", alliesMenu)
			missionCommands.addCommand("Start F-14 Interceptors", allyF14InterceptSubMenu, function()
				Spawn_BlueIntercept:SpawnScheduleStart()
				end)
			missionCommands.addCommand("Stop F-14 Interceptors", allyF14InterceptSubMenu, function()
				Spawn_BlueIntercept:SpawnScheduleStop()
				end)
		local allyF16PatrolSubMenu = missionCommands.addSubMenu("F-16 Patrol", alliesMenu)
			missionCommands.addCommand("Start F-16 Patrol", allyF16PatrolSubMenu, function()
				Spawn_BlueF16Patrol:SpawnScheduleStart()
				end)
			missionCommands.addCommand("Stop F-16 Patrol", allyF16PatrolSubMenu, function()
				Spawn_BlueF16Patrol:SpawnScheduleStop()
				end)
		local allyF16StrikeSubMenu = missionCommands.addSubMenu("F-16 Strike", alliesMenu)
			missionCommands.addCommand("Start F-16 Strike", allyF16StrikeSubMenu, function()
				Spawn_BlueDeathStrikeF16:SpawnScheduleStart()
				end)
			missionCommands.addCommand("Stop F-16 Strike", allyF16StrikeSubMenu, function()
				Spawn_BlueDeathStrikeF16:SpawnScheduleStop()
				end)
		local allyBlueAWACmenu = missionCommands.addSubMenu("AWAC", alliesMenu)
			missionCommands.addCommand("Start AWAC Spawning", allyBlueAWACmenu, function()
				Spawn_BlueAWAC:SpawnScheduleStart()
				end)
			missionCommands.addCommand("Stop AWAC Spawning", allyBlueAWACmenu, function()
				Spawn_BlueAWAC:SpawnScheduleStop()
				end)

		-- Sous-menu pour le Rescue
		local rescueSubMenu = missionCommands.addSubMenu("Rescue Spawn Options", alliesMenu)
			missionCommands.addCommand("Spawn Close Rescue", rescueSubMenu, function()
				trigger.action.setUserFlag("CloseRescueFlag", 1)
			end)
			missionCommands.addCommand("Spawn Far Rescue", rescueSubMenu, function()
				trigger.action.setUserFlag("FarRescueFlag", 1)
			end)				
	-- Sous-menu pour les options de mission
	local missionSubMenu = missionCommands.addSubMenu("Mission Options", kolaMenu)
		-- Sous-menu pour le redémarrage de la mission
		local missionRestartSubMenu = missionCommands.addSubMenu("Mission Reload and Options", missionSubMenu)
		missionCommands.addCommand("Reboot Mission", missionRestartSubMenu, function()
			trigger.action.setUserFlag("EndgameFlag", 66)
		end)
		missionCommands.addCommand("Return Fire All", missionRestartSubMenu,setAircraftGroupsROEToReturnFire)
		-- Sous-menu pour les options de fin de partie
		local endgameSubMenu = missionCommands.addSubMenu("Endgame Options", missionSubMenu)
		missionCommands.addCommand("Spawn Poseidon Flight", endgameSubMenu, function()
			trigger.action.setUserFlag("EndgameSpawnFlag", 5)
		end)
		missionCommands.addCommand("Stop Poseidon Spawning", endgameSubMenu, function()
			trigger.action.setUserFlag("EndgameSpawnFlag", 100)
		end)
		
		
--EOF
