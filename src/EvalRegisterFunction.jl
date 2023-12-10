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

### Examples of usage for Filter Registry Functions
### Too niche to be considered in main help

function IDSkillHasCoinFilter(id, lvl, uptie, skillNumStr, coinNumStr)
    # Checks if id @ uptie has coinNumStr for any skill in skillNumStr
    SkillFnList, _ = getSkillFunctions(skillNumStr)
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
    SkillFnList, _ = getSkillFunctions("atkSkills")
    Sins = [getSinType(skillFn(id), uptie) for skillFn in SkillFnList]
    return length(unique(Sins)) < 3
end
RegisterFunction("id-has-same-sin", IDDuplicateSinFilter)

function IDNoChangeInMaxRoll(id, lvl, uptie)
    SkillFnList, _ = getSkillFunctions("atkSkills")
    MaxRolls3 = [getMaxRoll(skillFn(id), 3) for skillFn in SkillFnList]
    MaxRolls4 = [getMaxRoll(skillFn(id), 4) for skillFn in SkillFnList]
    return MaxRolls3 == MaxRolls4
end
# RegisterFunction("id-ut3->4-no-maxroll-change", IDNoChangeInMaxRoll)