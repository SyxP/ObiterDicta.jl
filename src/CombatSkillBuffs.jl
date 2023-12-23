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

function actionScriptMatchesRegex(Action :: Dict{String, Any}, str :: Regex)
    haskey(Action, "scriptName") || return false
    return match(str, Action["scriptName"]) !== nothing
end

### Internal Functions

function exactBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) 
        return getBuffPotencyPerAction(Action, str)
    end

    return 0
end

function exactBuffCountInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffCount(Action, str) 
        return getBuffCountPerAction(Action, str)
    end

    return 0
end

function inflictBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && inflictsBuff(Action)
        return getBuffPotencyPerAction(Action, str)
    end

    if actionScriptMatchesRegex(Action, r"^1040603$") && hasBuffData(Action, str) # Ryoushuu O.O.F
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

    if actionScriptMatchesRegex(Action, r"^1040603$") && hasBuffData(Action, str) # Ryoushuu O.O.F
        return getBuffCountPerAction(Action, str)
    end

    return 0
end

function gainsBuffPotencyInternal(Action :: Dict{String, Any}, str)
    if actionScriptGivesBuff(Action, str) && hasBuffData(Action, str) && hasBuffPotency(Action, str) && gainsBuff(Action)
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

for (boolFnName, ctFnName, retrieveFn) in 
    [(:inflictBuffPotency, :getInflictedBuffPotency, inflictBuffPotencyInternal),
     (:inflictBuffCount, :getInflictedBuffCount,  inflictBuffCountInternal),
     (:gainsBuffPotency, :getGainedBuffPotency, gainsBuffPotencyInternal),
     (:gainsBuffCount, :getGainedBuffCount, gainsBuffCountInternal),
     (:exactBuffCount, :getExactBuffCount, exactBuffCountInternal),
     (:exactBuffPotency, :getExactBuffPotency, exactBuffPotencyInternal)]

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
        actionScriptHasBuff(Action, buffStr) || hasBuffData(Action, buffStr)
    end
end

function burstTremor(skill :: CombatSkill, tier)
    return WalkActionTree(skill, tier) do Action
        burstTremorInternal(Action)
    end
end