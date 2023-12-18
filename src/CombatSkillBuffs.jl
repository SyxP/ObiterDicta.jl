function hasBuffData(Action :: Dict{String, Any}, str)
    return haskey(Action, "buffData") && haskey(Action["buffData"], "buffKeyword") && Action["buffData"]["buffKeyword"] == str
end

function hasBuffCount(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "turn") && bData["turn"] != 0
end

function hasBuffPotency(Action :: Dict{String, Any}, str)
    bData = Action["buffData"]
    return haskey(bData, "stack") && bData["stack"] != 0
end

function inflictsBuff(Action :: Dict{String, Any})
    bData = Action["buffData"]
    return haskey(bData, "target") && bData["target"] ∈ ["Target" , "EveryUnit"]
end

function gainsBuff(Action :: Dict{String, Any})
    bData = Action["buffData"]
    return haskey(bData, "target") && bData["target"] ∈ ["Self", "EveryUnit"]
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

### Internal Functions

function inflictBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && inflictsBuff(Action)
        return true
    end

    if actionScriptRandomDebuff(Action, str) && (match(r"^GiveRandomDebuffSinStack", Action["scriptName"]) !== nothing)
        return true
    end

    return false
end

function inflictBuffCountInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffCount(Action, str) && inflictsBuff(Action)
        return true
    end
    return false
end

function gainsBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && gainsBuff(Action)
        return true
    end
    return false
end

function gainsBuffCountInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffCount(Action, str) && gainsBuff(Action)
        return true
    end
    return false
end

function burstTremorInternal(Action :: Dict{String, Any})
    !haskey(Action, "scriptName") && return false
    return occursin("VibrationExplosion", Action["scriptName"])
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

function inflictBuffPotency(skill :: CombatSkill, tier, buff :: Buff)
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        inflictBuffPotencyInternal(Action, buffStr)
    end
end

function inflictBuffCount(skill :: CombatSkill, tier, buff :: Buff)
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        inflictBuffCountInternal(Action, buffStr)
    end
end

inflictBuff(skill :: CombatSkill, tier, buff :: Buff) = (inflictBuffPotency(skill, tier, buff) || inflictBuffCount(skill, tier, buff))

function gainsBuffPotency(skill :: CombatSkill, tier, buff :: Buff)
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        gainsBuffPotencyInternal(Action, buffStr)
    end
end

function gainsBuffCount(skill :: CombatSkill, tier, buff :: Buff)
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        gainsBuffCountInternal(Action, buffStr)
    end
end

gainsBuff(skill :: CombatSkill, tier, buff :: Buff) = (gainsBuffPotency(skill, tier, buff) || gainsBuffCount(skill, tier, buff))

function interactsBuff(skill :: CombatSkill, tier, buff :: Buff)
    inflictBuff(skill, tier, buff) && return true
    gainsBuff(skill, tier, buff) && return true
    
    buffStr = getID(buff)
    return WalkActionTree(skill, tier) do Action
        actionScriptHasBuff(Action, buffStr)
    end
end

function burstTremor(skill :: CombatSkill, tier)
    return WalkActionTree(skill, tier) do Action
        burstTremorInternal(Action)
    end
end