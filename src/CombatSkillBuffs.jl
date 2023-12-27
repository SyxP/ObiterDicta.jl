function hasBuffData(Action :: Dict{String, Any}, str)
    return haskey(Action, "buffData") && haskey(Action["buffData"], "buffKeyword") && Action["buffData"]["buffKeyword"] == str
end

function hasBuffCount(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "turn") && bData["turn"] != 0
end

function getBuffCountPerAction(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "turn") ? abs(bData["turn"]) : 0
end

function hasBuffPotency(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "stack") && bData["stack"] != 0
end

function getBuffPotencyPerAction(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "stack") ? abs(bData["stack"]) : 0
end

function targetElse(target :: String)
    if target in ["Target", "EveryUnit", "EveryAlly"]
        return true
    end
    for rGx in [r"LowestHpValueAlly"]
        if match(rGx, target) !== nothing
            return true
        end
    end
    return false
end

function targetSelf(target :: String)
    if target in ["Self", "EveryUnit", "EveryAlly"]
        return true
    end
    if match(r"ExceptSelf", target) !== nothing
        return false
    end
    for rGx in [r"LowestHpValueAlly"]
        if match(rGx, target) !== nothing
            return true
        end
    end

    return false
end

function inflictsBuff(Action :: Dict{String, Any})
    bData = Action["buffData"]
    return haskey(bData, "target") && targetElse(bData["target"]) 
end

function gainsBuff(Action :: Dict{String, Any})
    bData = Action["buffData"]
    return haskey(bData, "target") && targetSelf(bData["target"])
end

function actionScriptGivesBuff(Action :: Dict{String, Any}, str)
    !haskey(Action, "scriptName") && return false
    return occursin("GiveBuff", Action["scriptName"])
end

function actionScriptHasBuff(Action :: Dict{String, Any}, str)
    !haskey(Action, "scriptName") && return false
    return occursin(str, Action["scriptName"])
end

function actionScriptRandomDebuff(Action :: Dict{String, Any}, str)
    haskey(Action, "scriptName") || return false
    match(r"^GiveRandomDebuffSin", Action["scriptName"]) !== nothing || return false
    str ∈ ["Combustion", "Laceration", "Vibration", "Burst", "Sinking"]
end

function actionScriptMatches(Action :: Dict{String, Any}, str :: Regex)
    haskey(Action, "scriptName") || return false
    return match(str, Action["scriptName"]) !== nothing
end
function actionScriptMatches(Action :: Dict{String, Any}, str :: String)
    haskey(Action, "scriptName") || return false
    return Action["scriptName"] == str
end

### Internal Functions
# Check GetGivingStackBuff and GetGivingTurnBuff
# TODO: 854204, 854704

function inflictBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && inflictsBuff(Action)
        return getBuffPotencyPerAction(Action, str)
    end

    # Yi Sang Dimension Shredder
    # Threadspin 4 does not have GetGivingStackBuff
    if actionScriptMatches(Action, "2010411_1_gaksung") && str == "DimensionRift"
        return 3
    elseif actionScriptMatches(Action, "2010411_1_gaksung4th") && str == "DimensionRift"
        return 5
    elseif actionScriptMatches(Action, "2010421_1_gaksung") && str == "DimensionRift"
        return 3
    elseif actionScriptMatches(Action, "2010421_1_gaksung4th") && str == "DimensionRift"
        return 5
    end

    # Yi Sang Alleyway Watchdog
    if actionScriptMatches(Action, "2020411_1_gaksung") && (str == "Agility" || str == "VioletResultUp")
        return 1
    elseif actionScriptMatches(Action, "2020411_1_gaksung4th") && (str == "Agility" || str == "VioletResultUp")
        return 1
    elseif actionScriptMatches(Action, "2020421_1_gaksung") && (str == "Paralysis" || str == "Binding")
        return 2
    elseif actionScriptMatches(Action, "2020421_1_gaksung4th") && (str == "Paralysis" || str == "Binding")
        return 2 # Check if Yi Sang Alleyway Watchdog actually gains +3 Charge Count
    end

    # Faust Leap 
    if actionScriptMatches(Action, "1020202_2") && (str == "Binding")
        return 4
    end

    # Faust Overcharge
    if actionScriptMatches(Action, "1020203_2") && (str == "Paralysis")
        return 3
    elseif actionScriptMatches(Action, "1020203_2") && (str == "Reduction")
        return 2
    end

    # Faust Law and Order 
    if actionScriptMatches(Action, "1020503_4") && (str == "Agility")
        return 1
    elseif actionScriptMatches(Action, "1020503_4") && (str == "DefenseUp")
        return 2
    end

    # Does not have GetGivingStackBuff

    # Yi Sang Enjamb
    if actionScriptMatches(Action, "1010103_1") && hasBuffData(Action, str)
        return getBuffPotencyPerAction(Action, str)
    end

    # Ryoushuu O.O.F
    if actionScriptMatches(Action, "1040603") && hasBuffData(Action, str) 
        return getBuffPotencyPerAction(Action, str)
    end

    # Sinclair Contre Attaque
    if actionScriptMatches(Action, r"^1100803_3_3") && hasBuffData(Action, str)
        return getBuffPotencyPerAction(Action, str)
    end

    if actionScriptRandomDebuff(Action, str)
        S = match(r"^GiveRandomDebuffSinStack([0-9]+)$", Action["scriptName"])
        S !== nothing && return parse(Int, S.captures[1])
    end

    return 0
end

function inflictBuffCountInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffCount(Action, str) && inflictsBuff(Action)
        return getBuffCountPerAction(Action, str)
    end

    # Ryoushuu O.O.F
    # Does not have GetGivingTurnBuff
    if actionScriptMatches(Action, r"1040603") && hasBuffData(Action, str) 
        return getBuffCountPerAction(Action, str)
    end

    return 0
end

function gainsBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && gainsBuff(Action)
        return getBuffPotencyPerAction(Action, str)
    end

    # Yi Sang Alleyway Watchdog
    if actionScriptMatches(Action, "2020411_1_gaksung") && (str == "Agility" || str == "VioletResultUp")
        return 1
    elseif actionScriptMatches(Action, "2020411_1_gaksung4th") && (str == "Agility" || str == "VioletResultUp")
        return 1
    elseif actionScriptMatches(Action, "2020421_1_gaksung") && (str == "Paralysis" || str == "Binding")
        return 2
    elseif actionScriptMatches(Action, "2020421_1_gaksung4th") && (str == "Paralysis" || str == "Binding")
        return 2 # Check if Yi Sang Alleyway Watchdog actually gains +3 Charge Count
    end

    # Sinclair Contre Attaque
    if actionScriptMatches(Action, r"^1100803_3_2") && hasBuffData(Action, str) 
        return getBuffPotencyPerAction(Action, str)
    end


    return 0
end

function gainsBuffCountInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffCount(Action, str) && gainsBuff(Action)
        return getBuffCountPerAction(Action, str)
    end

    return 0
end

function interactBuffInternal(Action :: Dict{String, Any}, str)
    if actionScriptMatches(Action, r"^1070704") && (str == "Breath" || str == "DefenseUp")
        return true
    end

    return false
end

function burstTremorInternal(Action :: Dict{String, Any})
    !haskey(Action, "scriptName") && return false
    return occursin("VibrationExplosion", Action["scriptName"])
end
function addAggroInternal(Action :: Dict{String, Any})
    !haskey(Action, "scriptName") && return false
    return occursin("AddTaunt", Action["scriptName"])
end

function WalkActionTree(fn, skill :: CombatSkill, tier)
    for action in getAbilityScriptList(skill, tier)
        fn(action) && return true
    end

    for entry in getCoinList(skill, tier)
        !haskey(entry, "abilityScriptList") && continue
        for Action in entry["abilityScriptList"]
            fn(Action) && return true
        end
    end

    return false
end

for (boolFnName, ctFnName, retrieveFn) in 
    [(:inflictBuffPotency, :getInflictedBuffPotency, inflictBuffPotencyInternal),
     (:inflictBuffCount, :getInflictedBuffCount,  inflictBuffCountInternal),
     (:gainsBuffPotency, :getGainedBuffPotency, gainsBuffPotencyInternal),
     (:gainsBuffCount, :getGainedBuffCount, gainsBuffCountInternal)]

    @eval function ($boolFnName)(skill :: CombatSkill, tier, buff :: Buff)
        buffStr = getID(buff)
        return WalkActionTree(skill, tier) do Action
            ($retrieveFn)(Action, buffStr) > 0
        end
    end

    @eval function ($ctFnName)(skill :: CombatSkill, tier, buff :: Buff)
        buffStr = getID(buff)
        Ct = 0
        WalkActionTree(skill, tier) do Action
            Ct += ($retrieveFn)(Action, buffStr)
            false
        end
        return Ct
    end
end


inflictBuff(skill :: CombatSkill, tier, buff :: Buff) = (inflictBuffPotency(skill, tier, buff) || inflictBuffCount(skill, tier, buff))
gainsBuff(skill :: CombatSkill, tier, buff :: Buff) = (gainsBuffPotency(skill, tier, buff) || gainsBuffCount(skill, tier, buff))

function interactsBuff(skill :: CombatSkill, tier, buff :: Buff)
    inflictBuff(skill, tier, buff) && return true
    gainsBuff(skill, tier, buff) && return true
    
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        interactBuffInternal(Action, buffStr) && return true
        actionScriptHasBuff(Action, buffStr) || hasBuffData(Action, buffStr)
    end
end

function burstTremor(skill :: CombatSkill, tier)
    return WalkActionTree(skill, tier) do Action
        burstTremorInternal(Action)
    end
end
function addAggro(skill :: CombatSkill, tier)
    return WalkActionTree(skill, tier) do Action
        addAggroInternal(Action)
    end
end