FilterRegistry = Dict{String, Function}()

function RegisterFunction(Str, Fun)
    FilterRegistry[Str] = Fun
end

function FilterRegistryHelpStr()
    S = raw"""For use in filters, you may wish to use your own functions.
              You first write your function in Julia Mode. Then, you 
              register it with: `RegisterFunction(\"FilterName\", YourFn)`.

              You can list the registered filters with: `filtreg list`.
        """

    println(S)
    return S
end

function FilterRegistryParser(input)
    input == "list" && return printFilterRegistryList()
    
    @info "Unable to parse $input (try 'filtreg help')"
    return
end

FilterRegistryRegex = r"filtreg (.*)"
FiltRegCommand = Command(FilterRegistryRegex, FilterRegistryParser,
                         [1], FilterRegistryHelpStr)

function printFilterRegistryList()
    Names = keys(FilterRegistry)
    
    println(GridFromList(Names, 2; labelled = true))
    return FilterRegistry
end

# Examples of usage for Filter Registry Functions
# Too niche to be considered in standard inclusion
# You may need to RegisterFunction(_name_, ObiterDicta._fn_)
# instead of RegisterFunction(_name_, _fn_)

function IDSkillHasCoinFilter(id, lvl, uptie, skillNumStr, coinNumStr)
    # Checks if id @ uptie has coinNumStr for any skill in skillNumStr
    SkillFnList, _ = getSkillFunctions(Personality, skillNumStr)
    CoinVec = getCoinVecFromString(string(coinNumStr))
    for tmpFn in SkillFnList
        Lst = tmpFn(id)
        if Lst isa Vector
            for skill in Lst
                getCoinValues(skill, uptie) == CoinVec && return true
            end
        else
            skill = Lst
            getCoinValues(skill, uptie) == CoinVec && return true
        end
    end
    return false
end
RegisterFunction("id-coin", IDSkillHasCoinFilter)

function IDDuplicateSinFilter(id, lvl, uptie)
    SkillFnList, _ = getSkillFunctions(Personality, "atkSkills")
    Sins = [getSinType(skillFn(id), uptie) for skillFn in SkillFnList]
    return length(unique(Sins)) < 3
end
# RegisterFunction("id-has-same-sin", IDDuplicateSinFilter)

function IDDifferentAtkTypeFilter(id, lvl, uptie)
    SkillFnList, _ = getSkillFunctions(Personality, "allSkills")
    AttackTypes = Any[]
    for skillFn in SkillFnList
        Lst = skillFn(id)
        if Lst isa Vector
            append!(AttackTypes, [getLocalizedAtkType(x, uptie) for x in Lst])
        else
            push!(AttackTypes, getLocalizedAtkType(Lst, uptie))
        end
    end

    return "Slash" ∈ AttackTypes && "Pierce" ∈ AttackTypes && "Blunt" ∈ AttackTypes
end
RegisterFunction("id-all-diff-atk", IDDifferentAtkTypeFilter)

function IDNoChangeInMaxRoll(id, lvl, uptie)
    SkillFnList, _ = getSkillFunctions(Personality, "atkSkills")
    MaxRolls3 = [getMaxRoll(skillFn(id), 3) for skillFn in SkillFnList]
    MaxRolls4 = [getMaxRoll(skillFn(id), 4) for skillFn in SkillFnList]
    return MaxRolls3 == MaxRolls4
end
# RegisterFunction("id-ut3->4-no-maxroll-change", IDNoChangeInMaxRoll)

function IDNumStaggerThreshold(id, lvl, uptie, num)
    Sections = getBreakSectionRaw(id)["sectionList"]
    return length(Sections) == parse(Int, num)
end
# RegisterFunction("id-num-stagger-threshold", IDNumStaggerThreshold)

function IDFirstStaggerPecentage(id, lvl, uptie, percentage)
    Sections = getBreakSectionRaw(id)["sectionList"]
    newPecentage = replace(percentage, "<=" => "≤", ">=" => "≥")
    op = newPecentage[1:1]
    N = parse(Int, newPecentage[nextind(newPecentage, 1):end])
    return CompareNumbers(Sections[1], N, op)
end
# RegisterFunction("id-1st-stagger%", IDFirstStaggerPecentage)

function IDPassCheck(id, lvl, uptie, sin, lowStr, highStr)
    low = parse(Int, lowStr)
    high = parse(Int, highStr)
    iSin = getClosestSinFromName(sin)

    SkillFnList, _ = getSkillFunctions(Personality, "atkSkills")
    for fn in SkillFnList
        skill = fn(id)
        N = getMaxRoll(skill, uptie)
        if getSinType(skill, uptie) == iSin
            N ≥ low && return true
        else
            N ≥ high && return true
        end
    end
    return false
end

RegisterFunction("id-pass-check", IDPassCheck) 

function EGODifferentSin(ego, ts)
    awakeSkill = getAwakeningSkill(ego)
    corrSkill  = getCorrosionSkill(ego)
    if awakeSkill === nothing || corrSkill === nothing
        return false
    end
    return getSinType(awakeSkill, ts) != getSinType(corrSkill, ts)
end
# RegisterFunction("ego-diff-sin", EGODifferentSin)

function EGODifferentAtkType(ego, ts)
    awakeSkill = getAwakeningSkill(ego)
    corrSkill  = getCorrosionSkill(ego)
    if awakeSkill === nothing || corrSkill === nothing
        return false
    end
    return getAtkType(awakeSkill, ts) != getAtkType(corrSkill, ts)
end
# RegisterFunction("ego-diff-atype", EGODifferentAtkType)

function EGOCostNum(ego, ts, numWithOp)
    Reqs = getRequirement(ego)
    newNum = replace(numWithOp, "<=" => "≤", ">=" => "≥")
    op = newNum[1:1]
    N = parse(Int, newNum[nextind(numWithOp, 1):end])
    return CompareNumbers(length(Reqs), N, op)
end
# RegisterFunction("ego-cost-num", EGOCostNum)

function EGOTotalResources(ego, ts, numWithOp)
    Reqs = getRequirement(ego)
    newNum = replace(numWithOp, "<=" => "≤", ">=" => "≥")
    op = newNum[1:1]
    N = parse(Int, newNum[nextind(numWithOp, 1):end])
    return CompareNumbers(sum(x["num"] for x in Reqs), N, op)
end
# RegisterFunction("ego-total-cost", EGOTotalResources)

function EGOCorrosionPlusCoin(ego, ts)
    corrSkill = getCorrosionSkill(ego)
    corrSkill === nothing && return false
    CoinLst = getCoinValues(corrSkill, ts)
    return isPlusCoin(CoinLst)
end

RegisterFunction("ego-corr-plus-coin", EGOCorrosionPlusCoin)