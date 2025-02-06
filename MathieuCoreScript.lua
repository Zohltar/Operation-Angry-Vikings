MESSAGE:New("Mathieu Core Loaded"):ToAll()

function findFirstUnitName(grp)
    local group = Group.getByName(grp:GetName())
    if group then
        -- Obtenez la liste des unités du groupe
        local units = group:getUnits()
        if units and #units > 0 then
            -- Récupérez la première unité
            local firstUnit = units[1]
            if firstUnit and firstUnit:isExist() then
                local unitName = firstUnit:getName()
                -- Retourne le nom de la première unité
                env.info("Nom de la première unité du groupe [" .. group:getName() .. "] est : " .. unitName)
                return unitName
            else
                env.warning("La première unité du groupe [" .. group:getName() .. "] n'existe pas.")
            end
        else
            env.warning("Aucune unité trouvée dans le groupe [" .. group:getName() .. "].")
        end
    else
        env.warning("Groupe introuvable : " .. grp:GetName())
    end -- Fin du bloc `if group then`

    -- Si aucun nom d'unité n'est trouvé, retournez `nil`
    return nil
end

function findAllUnits(grp)
    local group = Group.getByName(grp:GetName())
    if group then
        -- Obtenez la liste des unités du groupe
        local units = group:getUnits()
        if units and #units > 0 then
            -- Récupérez la première unité
            return units
        else
            env.warning("Aucune unité trouvée dans le groupe [" .. group:getName() .. "].")
        end
    else
        env.warning("Groupe introuvable : " .. grp:GetName())
    end -- Fin du bloc `if group then`

    -- Si aucun nom d'unité n'est trouvé, retournez `nil`
    return nil
end

local routes_ = {} -- format {points, "nom du groupe qui fourni la route", "nom de la route"}

function getWaypoints(group)
    
    if group then
        local route = group:CopyRoute(0,9)
        if route ~= nil  then
            return route -- Renvoie les points de route (waypoints)
        end
    end
    env.warning("Impossible de récupérer les waypoints pour le groupe : " .. groupName)
    return nil
end

-- Stocker routes des groupes
function stockerRoute(groupName, nomRoute)
    local waypoints = getWaypoints(groupName) -- Récupérer les waypoints du groupe
    if waypoints then
        -- Ajouter à la table globale
        table.insert(routes_, { waypoints = waypoints, groupName = groupName, nomRoute = nomRoute })
        env.info("Route du groupe [" .. groupName .. "] stockée sous le nom : " .. nomRoute)

        -- Écrire dans le fichier
        local filePath = lfs.writedir() .. "routeStockee.lua"
        local file = io.open(filePath, "a") -- Ouvrir en mode ajout
        if file then
            file:write("-- Route stockée pour " .. groupName .. " (" .. nomRoute .. ")\n")
            file:write("return {\n")
            file:write("    groupName = \"" .. groupName .. "\",\n")
            file:write("    nomRoute = \"" .. nomRoute .. "\",\n")
            file:write("    waypoints = {\n")
            for _, waypoint in ipairs(waypoints) do
                file:write("        {\n")
                for key, value in pairs(waypoint) do
                    if type(value) == "string" then
                        file:write("            " .. key .. " = \"" .. value .. "\",\n")
                    else
                        file:write("            " .. key .. " = " .. tostring(value) .. ",\n")
                    end
                end
                file:write("        },\n")
            end
            file:write("    }\n")
            file:write("}\n")
            file:close()
            env.info("Route enregistrée dans le fichier : " .. filePath)
        else
            env.warning("Impossible d'ouvrir le fichier : " .. filePath)
        end
    else
        env.warning("Aucune route trouvée pour le groupe : " .. groupName)
    end
end


--pour utiliser les wpStocké
function setWaypoints(groupName, waypoints)
    local group = Group.getByName(groupName)
    if group and waypoints then
        local controller = group:getController()
        if controller then
            local mission = {
                id = 'Mission',
                params = {
                    route = {
                        points = waypoints
                    }
                }
            }
            controller:setTask(mission)
            env.info("Waypoints assignés au groupe : " .. groupName)
        else
            env.warning("Impossible d'obtenir le contrôleur pour le groupe : " .. groupName)
        end
    else
        env.warning("Groupe ou waypoints invalides pour le groupe : " .. groupName)
    end
end



--Changement de waypoint
function switchWP(grpName, wpNum1, wpNum2)
    -- grpName est le nom du groupe qui doit exécuter l'action
    -- wpNum1 est l'index du waypoint initial (pas nécessaire ici mais peut être utile pour des contrôles supplémentaires)
    -- wpNum2 est l'index du waypoint vers lequel rediriger le groupe

    local group = Group.getByName(grpName)  -- Récupère le groupe par son nom
	if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe '" .. grpName .. "' n'existe pas ou est invalide.")
        return
    end
	
    if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe '" .. grpName .. "' n'existe pas ou est invalide.")
        return
    end

    local controller = group:getController()  -- Récupère le contrôleur du groupe

    -- Créez une tâche pour que le groupe change de waypoint
    local task = {
        id = 'WrappedAction',
        params = {
            action = {
                id = 'SwitchWaypoint',
                params = {
                    fromWaypointIndex = wpNum1,  -- Index du waypoint de départ
                    goToWaypointIndex = wpNum2,  -- Index du waypoint de destination
                }
            }
        }
    }

    -- Applique la tâche au contrôleur du groupe
    controller:setTask(task)

    -- Log pour le débogage
    env.info("Le groupe '" .. grpName .. "' a été redirigé du waypoint " .. wpNum1 .. " vers le waypoint " .. wpNum2 .. ".")
	--MESSAGE:New("Le groupe '" .. grpName .. "' a été redirigé du waypoint " .. wpNum1 .. " vers le waypoint " .. wpNum2 .. "."):ToAll()
end

--AttackGroupTaskPush / set
function AttackGroupTaskPush(attackerGroupName, attackedGroupName, typePush)
    -- attackerGroupName : le groupe qui va exécuter la tâche d'attaque.
    -- attackedGroup : le groupe cible de l'attaque à planifier.
    -- typePush : 0 = push, 1 = set.

    local group = Group.getByName(attackerGroupName)
    local groupOfTarget = Group.getByName(attackedGroupName)
	local typeDePush = 0
	typeDePush = typePush

    if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe attaquant '" .. attackerGroupName .. "' n'existe pas ou est invalide.")
        return
    end

    if not groupOfTarget or not groupOfTarget:isExist() then
        env.warning("TriggerAction: Le groupe cible '" .. attackedGroupName .. "' n'existe pas ou est invalide.")
        return
    end

    local controller = group:getController() -- Récupère le contrôleur du groupe.

    -- Crée la tâche pour attaquer le groupe cible.
    local taskAttack = {
        id = 'AttackGroup',
        params = {
            groupId = groupOfTarget:getID(), -- Utilisation correcte de l'ID.
            weaponType = "ALL",
        }
    }

    -- Applique la tâche au contrôleur du groupe.
    if typeDePush == 0 then
        controller:pushTask(taskAttack)
    elseif typeDePush == 1 then
        controller:setTask(taskAttack)
    else
        env.warning("TriggerAction: Mauvais type de tâche passé. Utilisez 0 (push) ou 1 (set).")
        return
    end

    -- Log pour le débogage.
    env.info("Le groupe '" .. attackerGroupName .. "' a reçu la tâche '" .. taskAttack.id .. "' pour attaquer '" .. attackedGroupName .. "'.")	
    --MESSAGE:New("Le groupe '" .. attackerGroupName .. "' attaque le groupe '" .. attackedGroupName .. "'."):ToAll()
end

-- valide la présence d'une unité dans une zone True si oui, False si non
function IsUnitInZone(zoneName)
    local zone = ZONE:FindByName(zoneName)
    if not zone then
        return false -- La zone n'existe pas
    end

    local unitsInZone = SET_UNIT:New():FilterZones({zone}):FilterOnce()
    return unitsInZone:Count() > 0
end

-- Flag ON ou OFF
function setFlagValue(flagName, value)
    if type(flagName) == "string" and (value == 0 or value == 1) then
        trigger.action.setUserFlag(flagName, value) -- Définit la valeur du flag (0 pour OFF, 1 pour ON)
        if value == 0 then
            env.info("FLAG OFF exécuté pour : " .. flagName) -- Log pour FLAG OFF
        elseif value == 1 then
            env.info("FLAG ON exécuté pour : " .. flagName) -- Log pour FLAG ON
        end
    else
        env.warning("Le paramètre passé à setFlagOff n'est pas valide.")
    end
end


function DestroyUnit( unitName )
	local group = Group.findByUnit( unitName )

end



-- Fonction pour suivre la durée de vie d'une unité spawné et les détruire à la fin
function subscribeLifeTimeChecker(grp, esperanceVie, flagName) -- (group = Groupe d'unité, esperanceVie = en secondes, flagName = nom du flag)
    -- Vérifie si le groupe est déjà enregistré pour éviter les doublons
    for _, entry in ipairs(flagsToCheck) do
        if entry.group == grp then
            env.warning("Le groupe " .. grp:GetName() .. " est déjà enregistré dans flagsToCheck.")
            return
        end
    end

    -- Ajoute le groupe à la liste des groupes à surveiller
    table.insert(flagsToCheck, {group = grp, esperance = timer.getTime() + esperanceVie, flagName = flagName})

    -- Démarre une minuterie pour surveiller la durée de vie des groupes
    if not lifeTimeCheckerRunning then
        lifeTimeCheckerRunning = true
        timer.scheduleFunction(minuterieDeVie, nil, timer.getTime() + 1)
    end
end



-- Fonction appelée périodiquement pour vérifier les durées de vie
function minuterieDeVie()
    local currentTime = timer.getTime()

    for i = #flagsToCheck, 1, -1 do -- Parcourt la table en sens inverse pour supprimer les entrées
        local entry = flagsToCheck[i]
        local flagName = entry.flagName

        -- Vérifie la durée de vie ou le flag
        if currentTime >= entry.esperance or trigger.misc.getUserFlag(flagName) == 0 then
            local group = entry.group
            if group and group:IsAlive() then
                env.info("Destruction du groupe: " .. group:GetName() .. " après " .. entry.esperance - (entry.esperance - currentTime) .. " secondes.")
                group:Destroy()
            end

            -- Supprime l'entrée de la table et nettoie le flag
            table.remove(flagsToCheck, i)
            trigger.action.setUserFlag(flagName, 0)
        end
    end

    -- Relance la minuterie si des groupes restent à surveiller
    if #flagsToCheck > 0 then
        timer.scheduleFunction(minuterieDeVie, nil, timer.getTime() + 1)
    else
        lifeTimeCheckerRunning = false
        env.info("Aucun groupe restant à surveiller. Minuterie arrêtée.")
    end
end

-- Fonction pour calculer la distance entre deux points
function getDistance(point1, point2)
    local dx = point1.x - point2.x
    local dy = point1.y - point2.y
    local dz = point1.z - point2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Function to create a hold task for a ground unit
function createHoldTaskForGroundUnit(groupName)
    local group = Group.getByName(groupName)
    if group then
        local controller = group:getController()
        if controller then
            local holdTask = {
                id = 'Hold',
                params = {}
            }
            controller:setTask(holdTask)
        end
    end
end


--générateur de spawn 

function genSpawn(nomDuGroupTemplate, unitLimit, maxRespawn, freqRespawn, zones) -- Nom du group de units à prendre comme template: string, nombre limite à créer = int, fréquence des respawn (indiquer 0 pour ne pas le définir dans cette fonction =  int, limite de groupe à spawner Tableau de nom de zones (optionnel) = moose script zones
	local Spawn_Template = SPAWN:New( nomDuGroupTemplate )
    local initMaxRespawn = maxRespawn ~= nil and maxRespawn or 0
	Spawn_Template:InitLimit( unitLimit, initMaxRespawn )
	--Spawn_Template:InitRepeatOnLanding()
	Spawn_Template:InitRepeatOnEngineShutDown()
	if zones ~= nil then Spawn_Template:InitRandomizeZones( zones )end
	if freqRespawn ~= 0 then 
		Spawn_Template:SpawnScheduled(freqRespawn, 0.5)
		env.info("Spawn Template created for: " .. nomDuGroupTemplate)
	end
	
	--on Spawn actions
	Spawn_Template:OnSpawnGroup(function(grp)			
		--Log dans le dcs.log
		env.info("Spawned groupe name: " .. grp:GetName())		
		end) 	
	
	return Spawn_Template
end

function setAircraftGroupsROEToReturnFire()
    -- Récupérer tous les groupes d'aéronefs vivants dans la mission
    local aircraftGroups = SET_GROUP:New():FilterCategories("plane"):FilterActive(true):FilterOnce()

    -- Parcourir chaque groupe et définir le ROE à "Return Fire"
    aircraftGroups:ForEachGroup(function(group)
        if group then
            env.info("Changing ROE to Return Fire for aircraft group: " .. group:GetName())
            group:OptionROEHoldFire() -- Définit le ROE sur "Return Fire"
        end
    end)

    -- Log dans le DCS log
    env.info("ROE for all aircraft groups set to 'Return Fire'")
end


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

    -- Fonction pour calculer la distance entre deux points
    local function getDistance(point1, point2)
        local dx = point1.x - point2.x
        local dy = point1.y - point2.y
        local dz = point1.z - point2.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end

    -- Trouver toutes les unités dans le monde
    local allUnits = coalition.getGroups(coalition.side.RED, Group.Category.GROUND)
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
                    if distance <= 100 then
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
    end

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
        table.insert(positions, {groupName = groupName, pos = pos})
        env.info("Position de la première unité du groupe " .. groupName .. " trouvée à " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
        -- Réarmer le groupe
        SPAWN:New(groupName):SpawnFromVec3(pos):Spawn()
    end

    -- Pour chacun des groupes, faire un SPAWN = New(nom du groupe) et faire un SpawnFromVec3 à la position de l'unité correspondante au groupe
    --[[
    for _, data in ipairs(positions) do
        env.info("Réarmement du groupe " .. data.groupName .. " à la position " .. data.pos.x .. ", " .. data.pos.y .. ", " .. data.pos.z)
        local rearmed_spawn = SPAWN:New("RedOffensiveArtillery")            
            :SpawnFromVec3(data.pos)
            :Spawn()
        env.info("Réarmement du groupe " .. data.groupName .. " effectué.")
    end--]]
end


--ReArmUnit("RearmTruck-1-1")

-- Fonction pour surveiller un groupe et détruire le groupe à un waypoint donné
function monitorGroupDestroyOnWaypoint(groupName, waypointIndexToDestroy)
    -- Vérifie si le groupe existe
    local group = Group.getByName(groupName)
    if not group then
        env.warning("Le groupe " .. groupName .. " n'existe pas.")
        return
    end

    -- Gestionnaire d'événements
    local waypointHandler = {}
    
    function waypointHandler:onEvent(event)
        if event == nil or event.id ~= world.event.S_EVENT_WAYPOINT_REACHED then
            return
        end

        -- Vérifie si l'unité appartient au groupe spécifié
        local unit = event.initiator
        if not unit then
            env.warning("Unité non spécifiée dans l'événement S_EVENT_WAYPOINT_REACHED.")
            return
        end

        local unitGroup = unit:getGroup()
        if not unitGroup or unitGroup:getName() ~= groupName then
            return
        end

        -- Vérifie si le waypoint atteint est le bon
        local waypointIndex = event.waypoint
        if waypointIndex == waypointIndexToDestroy then
            env.info("Le groupe " .. groupName .. " a atteint le waypoint " .. waypointIndex .. ". Destruction...")
            group:destroy()
            -- Nettoie le gestionnaire d'événements
            world.removeEventHandler(waypointHandler)
        end
    end

    -- Ajoute le gestionnaire d'événements
    world.addEventHandler(waypointHandler)
    env.info("Surveillance du groupe " .. groupName .. " pour le waypoint " .. waypointIndexToDestroy .. " activée.")
end

-- Exemple d'appel de la fonction
--monitorGroupDestroyOnWaypoint("MonGroupe", 4)


-- Fonction pour basculer la visibilité de la carte F10
function toggleMapVisibility(option)
    if option == "all" then
        trigger.action.setUserFlag("MapVisibility", 1)
        trigger.action.outText("Carte F10: Mode All (Tout visible)", 10)
    elseif option == "fogOfWar" then
        trigger.action.setUserFlag("MapVisibility", 2)
        trigger.action.outText("Carte F10: Mode Fog of War (Visibilité limitée)", 10)
    else
        trigger.action.outText("Option non valide pour la visibilité de la carte F10.", 10)
        return
    end
end


