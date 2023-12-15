function PersonalityHelp()
    S = raw"""Looks up identities. Available Commands:
              `id list jsons`         - List all internal JSONs.
              `id list _bundle.json_` - List all identities in _bundle.json_. (*)
              `id _query_ _flags_`    - Looks up _query_.

              Available Flags:
              !v/!verbose  - Outputs the internal additional fields.
              !top_num_    - Outputs the top _num_ identities matching the query. Default is 5. (*)
              !a/!all      - Outputs all identities matching the filters. (*)
              !i/!internal - Only performs the query on internal identity names.
              !ut_num_     - Sets the uptie at _num_. Without this, it is set to the maximum possible.
              !level_num_  - Sets the offense level at _num_. (!lvl is equivalent)
              [_filter_]   - Filter the list of identities

              After (*), `id _number_` will directly output the corresponding identity.
              To see available filters, use `id filters help`.
              Example usage:
              `id !i 10101 !ut1 !olvl40` - Outputs the internal identity with ID 10101 Uptie 1 and Level 40.
              `id !all [id=donqui] [s2=wrath]` - Outputs all Don Quixote identities with Wrath S2.
        """

    println(S)
    return S
end

function FilterHelp(::Type{Personality})
    S = raw"""Filters reduce the search space. 
              Note that filters can not have spaces between the [].
              Available Filters:
              [id:_num_]                - ID's Number must be _num_. Note that Sinclair is given the ID 10.
              [id:_name_]               - ID's Name must be _name_.
              [rarity:_x_]              - Rarity must be _x_. (_x_ should be "2*"/"00")
              [season:_x_]              - ID is from Season _x_.
              [event]                   - ID is from Event
              [faction:_name_]          - ID is from Faction _name_
              [health_op__num_]         - Health of the identity must _op_ _num_.
              [defCor_op__num_]         - Defense Correction of the identity must _op_ _num_.
              [maxSpeed_op__num_]       - Maximum Speed of the identity must _op_ _num_.
              [minSpeed_op__num_]       - Minimum Speed of the identity must _op_ _num_.
              [resist:_type__op__num_]  - Resistance of type _type_ _op_ _num_.
              [def:type:_type_]         - Defensive Type must be _type_ (e.g. Guard).
              [*:sin:_type_]            - Any (*) skill must have sin Affinity _type_.
              [*:atkType:_type_]        - Any (*) skill must have attack Type _type_.
              [*:minRoll_op__num_]      - All (*) skill must have minimum roll _op_ _num_.
              [*:maxRoll_op__num_]      - All (*) skill must have maximum roll _op_ _num_.
              [*:numCoins_op__num_]     - All (*) skill must have number of coins _op_ _num_.
              [*:weight_op__num_]       - All (*) skill must have weight _op_ _num_.
              [*:offCor_op__num_]       - All (*) skill must have offense correction _op_ _num_.
              [pass:**:isReson]         - All (**) passives have resonance requirements.
              [pass:**:isStock]         - All (**) passives have stock requirements.
              [pass:**:_type__op__num_] - All (**) passives have cost _type_ _op_ _num_.
              [fn:_FunName_]            - ⟨Adv⟩ Filters based on FunName(id, level, uptie). See `filtreg help`.

              * can be one of S1, S2, S3, atkSkills (S1, S2 and S3), def, allSkills
              ** can be pass, spass or allPass
              _op_ can be one of =, <, ≤ (<=), >, ≥ (>=)
              [^_query_] constructs a filter that is true iff [_query_] is false.
              [_queryA_|_queryB_] constructs a filter that is true iff either [_queryA_] or [_queryB_] is true.
        """

    println(S)
    return S
end

function PersonalityUptieParser(input)
    for uptieRegex in [r"![uU]ptie([0-9]+)", r"![uU][tT]([0-9]+)", r"![tT]ier([0-9]+)"]
        S = match(uptieRegex, input)
        S !== nothing && return tryparse(Int, S.captures[1])
    end

    return getMaxUptie(Personality)
end

function PersonalityParser(input)
    S = match(r"^filters? help$", input)
    (S !== nothing) && return FilterHelp(Personality)
    
    S = match(r"^list jsons?$", input)
    (S !== nothing) && return printJSONList(Personality)

    if match(r"list all", input) !== nothing
        println("Do you mean: `id !all`?")
    end
    
    S = match(r"^list (.*)$", input)
    (S !== nothing) && return printPersonalityFromJSON(S.captures[1])

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(Personality, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(Personality, true)

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    PrintAll = false
    PersonalitySearchList = Personality[]
    Tier = getMaxUptie(Personality)
    Level = getMaxLevel(Personality)
    pFilters = PersonalityFilter[]
    ExactNumber = true

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true; ExactNumber = false)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5; ExaxtNumber = false)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x); ExactNumber = false)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true; ExactNumber = false)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![tT]ier([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![lL]vl([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![lL]evel([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![uU]ptie([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![uU][tT]([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^\[(.*)\]$"] = (x) -> (push!(pFilters, constructFilter(Personality, x)); ExactNumber = false)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    S = match(r"^([0-9]+)$", newQuery)
    if S !== nothing && ExactNumber
        return printPersonalityExactNumberInput(newQuery, Tier, Level, Verbose)
    end

    (length(PersonalitySearchList) == 0) && (PersonalitySearchList = getMasterList(Personality))

    for currFilter in pFilters
        Tmp = ""
        PersonalitySearchList, Tmp = applyFilter(PersonalitySearchList, currFilter, Level, Tier)
        if Tmp != ""
            println(Tmp)
        end
    end

    PrintAll && return printAllPersonality(PersonalitySearchList, Tier)
    length(PersonalitySearchList) == 0 && return printAllPersonality(PersonalitySearchList, Tier)
    
    HaystackPersonality = []
    for myID in PersonalitySearchList
        if UseInternalIDs
            push!(HaystackPersonality, (getStringID(myID), myID))
        else
            if hasLocalizedVersion(myID)
                push!(HaystackPersonality, (getSearchTitle(myID), myID))
            end
        end
    end

    TopNumber == 1 && return searchSinglePersonality(newQuery, HaystackPersonality, Tier, Level, Verbose)
    return searchTopPersonality(newQuery, HaystackPersonality, TopNumber, Tier)
end

PersonalityRegex = r"^[iI](d|D|dentity|dentities) (.*)$"
PersonalityCommand = Command(PersonalityRegex, PersonalityParser,
                             [2], PersonalityHelp)
# Filters

TrivialPersonalityFilter = PersonalityFilter((x, lvl, uptie) -> true, "")

function NotFilter(filter :: PersonalityFilter)
    Fn(x, lvl, uptie) = !filter.fn(x, lvl, uptie)
    return PersonalityFilter(Fn, "$(@red("Not")) " * filter.description)
end

function OrFilter(filterList :: Vector{PersonalityFilter})
    Fn(x, lvl, uptie) = any(filterList[i].fn(x, lvl, uptie) for i in 1:length(filterList))
    io = IOBuffer()
    println(io, "$(@red("Or")) Filter with length $(length(filterList)):")
    for (idx, filter) in enumerate(filterList)
        println(io, " - $(@dim(string(idx))): $(filter.description)")
    end
    filterStr = String(take!(io))
    return PersonalityFilter(Fn, filterStr)        
end

function EvalFilter(::Type{Personality}, str :: String)
    Entries = split(str, ":")
    Fn(x, lvl, uptie) = (FilterRegistry[Entries[1]])(x, lvl, uptie, Entries[2:end]...)
    return PersonalityFilter(Fn, "Custom Filter: $(@blue(str))")
end

function SinnerPersonalityFilter(num :: Integer)
    Fn(x, lvl, utpie) = getCharID(x) == num
    filterStr = "Filter: Sinner to $(@red(getSinnerName(num)))"

    return PersonalityFilter(Fn, filterStr)
end

function SinnerPersonalityFilter(str :: String)
    num = getClosestSinnerIDFromName(str)
    Fn(x, lvl, uptie) = getCharID(x) == num
    filterStr = "Filter: Sinner to $(@red(getSinnerName(num))) (Input: $(@dim(str)))"

    return PersonalityFilter(Fn, filterStr)
end

function SinnerEventFilter()
    Fn(x, lvl, uptie) = isEvent(x)
    filterStr = "Filter: Sinner is from an Event"
    return PersonalityFilter(Fn, filterStr)
end

function SinnerSeasonFilter(str)
    N = getSeasonIDFromName(str)
    N == -1 && return TrivialPersonalityFilter
    Fn(x, lvl, uptie) = getSeason(x) == N
    filterStr = "Filter: Sinner Season is $(@red(getSeasonNameFromInt(N))) (Input: $(@dim(str)))"
    return PersonalityFilter(Fn, filterStr)
end

function SinnerFactionFilter(str)
    normStr = lowercase(superNormString(str))
    function Fn(x, lvl, uptie)
        factionList = getFactionList(x)
        Lst = [lowercase(superNormString(x)) for x in factionList]
        return any(Lst .== normStr)
    end
    filterStr = "Filter: Sinner Faction to $(@red(normStr))"
    return PersonalityFilter(Fn, filterStr)
end

function SinnerRarityFilter(str :: String)
    N = getRarityFromString(str)
    N == 0 && return TrivialPersonalityFilter
    Fn(x, lvl, uptie) = getRarity(x) == N
    filterStr = "Filter: Sinner Rarity is $(getRarityString(N))"
    return PersonalityFilter(Fn, filterStr)
end

function SinnerHealthFilter(num :: String, relation :: String)
    N = parse(Int, num)
    (relation == "<=") && (relation = "≤")
    (relation == ">=") && (relation = "≥")

    function Fn(x, lvl, uptie)
        compareN = getHP(x, lvl)
        return CompareNumbers(compareN, N, relation)
    end

    filterStr = "Filter: Sinner Health $(@blue(relation)) $(@red(num))"
    return PersonalityFilter(Fn, filterStr)
end

for (fnName, lookupFn, desc) in [(:SinnerMaxSpeedFilter, getMaxSpeed, "Maximum Speed"),
                                 (:SinnerMinSpeedFilter, getMinSpeed, "Minimum Speed")]
    @eval function ($fnName)(num :: String, relation :: String)
        N = parse(Int, num)
        (relation == "<=") && (relation = "≤")
        (relation == ">=") && (relation = "≥")
    
        function Fn(x, lvl, uptie)
            compareN = ($lookupFn)(x, uptie)
            return CompareNumbers(compareN, N, relation)
        end

        filterStr = "Filter: Sinner " * $desc * " $(@blue(relation)) $(@red(num))"
        return PersonalityFilter(Fn, filterStr)
    end
end

function SinnerDefCorrectionFilter(num :: String, relation :: String)
    N = parse(Int, num)
    (relation == "<=") && (relation = "≤")
    (relation == ">=") && (relation = "≥")

    function Fn(x, lvl, uptie)
        def = getDefenseCorrection(x)
        return CompareNumbers(def, N, relation)
    end

    filterStr = "Filter: Sinner Defense Correction $(@blue(relation)) $(@red(NumberStringWithSign(N)))"
    return PersonalityFilter(Fn, filterStr)
end

function DefenseTypePersonalityFilter(str :: String)
    newStr = lowercase(superNormString(str))
    function Fn(x, lvl, uptie)
        defSkillList = getDefenseCombatSkill(x)
        Lst = [lowercase(superNormString(getType(x))) for x in defSkillList]
        return any(Lst .== newStr)
    end

    filterStr = "Filter: Defense Type to $(@red(newStr))"
    return PersonalityFilter(Fn, filterStr)
end

function getSkillFunctions(::Type{Personality}, skillStr)
    if match(r"^[sS](kill)?1$", skillStr) !== nothing
        return [getSkill1], "Skill 1"
    elseif match(r"^[sS](kill)?2$", skillStr) !== nothing
        return [getSkill2], "Skill 2"
    elseif match(r"^[sS](kill)?3$", skillStr) !== nothing
        return [getSkill3], "Skill 3"
    elseif match(r"^[aA](tk|ttack)([sS]kills?)$", skillStr) !== nothing
        return [getSkill1, getSkill2, getSkill3], "All Attack Skills"
    elseif match(r"^[dD](ef|effence)([sS]kills?)?$", skillStr) !== nothing
        return [getDefenseCombatSkill], "All Defense Skills"
    elseif match(r"^[aA]ll([sS]kills?)$", skillStr) !== nothing
        SkillFn = [getSkill1, getSkill2, getSkill3, getDefenseCombatSkill]
        return SkillFn, "All Skills"
    end
    
    return Function[], ""
end

function getPassiveFunctions(::Type{Personality}, skillStr)
    if match(r"^[pP]ass(ive)?$", skillStr) !== nothing
        return [getBattlePassive], "Passive"
    elseif match(r"[sS]upp(ort)?$", skillStr) !== nothing
        return [getSupportPassive], "Support Passive"
    elseif match(r"[sS][pP]ass(ive)?$", skillStr) !== nothing
        return [getSupportPassive], "Support Passive"
    elseif match(r"[aA]ll[pP]ass(ives?)?$", skillStr) !== nothing
        return [getBattlePassive, getSupportPassive], "All Passives"
    end

    return Function[], ""
end

function CombatSkillSinFilter(skillNumStr, sinQuery)
    skillFn, skillDesc = getSkillFunctions(Personality, skillNumStr)
    skillDesc == "" && return TrivialPersonalityFilter
    internalSin = getClosestSinFromName(sinQuery)
    function Fn(x, lvl, uptie)
        for tmpFn in skillFn
            Lst = tmpFn(x)
            if Lst isa Vector
                for skill in Lst
                    getSinType(skill, uptie) == internalSin && return true
                end
            else
                skill = Lst
                getSinType(skill, uptie) == internalSin && return true
            end
        end
        return false
    end

    filterStr = "Filter: $(@red(skillDesc)) to have Sin Affinity $(getSinString(internalSin)) (Input: $(@dim(sinQuery)))"
    return PersonalityFilter(Fn, filterStr)
end

function CombatSkillAtkTypeFilter(skillNumStr, atkTypeQuery)
    skillFn, skillDesc = getSkillFunctions(Personality, skillNumStr)
    skillDesc == "" && return TrivialPersonalityFilter
    internalAtkType = getClosestAtkTypeFromName(atkTypeQuery)
    function Fn(x, lvl, uptie)
        for tmpFn in skillFn
            Lst = tmpFn(x)
            if Lst isa Vector
                for skill in Lst
                    getAtkType(skill, uptie) == internalAtkType && return true
                end
            else
                skill = Lst
                getAtkType(skill, uptie) == internalAtkType && return true
            end
        end
        return false
    end

    filterStr = "Filter: $(@red(skillDesc)) to have Attack Type $(AttackTypes(internalAtkType)) (Input: $(@dim(atkTypeQuery)))"
    return PersonalityFilter(Fn, filterStr)
end

for (defineFn, lookupFn, desc) in [(:CombatSkillMinRollFilter, getMinRoll, "minimum roll"),
                                   (:CombatSkillMaxRollFilter, getMaxRoll, "maximum roll"),
                                   (:CombatSkillNumCoinsFilter, getNumCoins, "number of coins"),
                                   (:CombatSkillWeightFilter, getWeight, "weight"),
                                   (:CombatSkillOffCorFilter, getOffLevelCorrection, "offensive level correction")]
    @eval function ($defineFn)(skillNumStr, num :: String, op)
        (op == "<=") && (op = "≤")
        (op == ">=") && (op = "≥")
        compareN = parse(Int, num)
        skillFn, skillDesc = getSkillFunctions(Personality, skillNumStr)
        skillDesc == "" && return TrivialPersonalityFilter
        function Fn(x, lvl, uptie)
            for tmpFn in skillFn
                Lst = tmpFn(x)
                if Lst isa Vector
                    for skill in Lst
                        N = ($lookupFn)(skill, uptie)
                        CompareNumbers(N, compareN, op) || return false
                    end
                else
                    skill = Lst
                    N = ($lookupFn)(skill, uptie)
                    CompareNumbers(N, compareN, op) || return false
                end
            end
            return true
        end

        filterStr = "Filter: $(@red(skillDesc)) to have "* $desc * " $(@blue(op)) $(@red(num)) "
        return PersonalityFilter(Fn, filterStr)
    end
end

function SinnerResistanceFilter(resistType, op, num)
    compareN = tryparse(Float64, num)
    compareN === nothing && return TrivialPersonalityFilter
    searchType = getClosestAtkTypeFromName(resistType) 
    (op == "<=") && (op = "≤")
    (op == ">=") && (op = "≥")

    function Fn(x, lvl, uptie)
        N = getResistance(x, searchType) 
        return CompareNumbers(N, compareN, op) 
    end

    filterStr = "Filter: Sinner's resistance to $(AttackTypes(searchType)) $(@blue(op)) $(@red(string(num)))× (Input: $(@dim(resistType)))"
    return PersonalityFilter(Fn, filterStr)
end

for (defineFn, lookupFn, desc) in [(:SinnerPassiveResonFilter, hasResonanceCondition, "Resonance"),
                                   (:SinnerPassiveStockFilter, hasStockCondition, "Stock")]
    @eval function ($defineFn)(passStr)
        passFn, passDesc = getPassiveFunctions(Personality, passStr)
        passDesc == "" && return TrivialPersonalityFilter

        function Fn(x, lvl, uptie)
            for tmpFn in passFn
                Lst = tmpFn(x, uptie)
                if Lst isa Vector
                    for pass in Lst
                        ($lookupFn)(pass) || return false
                    end
                else
                    pass = Lst
                    ($lookupFn)(pass) || return false
                end
            end
            return true
        end

        filterStr = "Filter: $passDesc has " * $desc * " condition"
        return PersonalityFilter(Fn, filterStr)
    end
end

function SinnerPassiveSinFilter(passStr, sinQuery, num = 0, op = ">")
    passFn, passDesc = getPassiveFunctions(Personality, passStr)
    passDesc == "" && return TrivialPersonalityFilter
    internalSin = getClosestSinFromName(sinQuery)
    (op == "<=") && (op = "≤")
    (op == ">=") && (op = "≥")

    function Fn(x, lvl, uptie)
        for tmpFn in passFn
            Lst = tmpFn(x, uptie)
            if Lst isa Vector
                for pass in Lst
                    N = getRequirement(pass, internalSin)
                    CompareNumbers(N, num, op) || return false
                end
            else
                pass = Lst
                N = getRequirement(pass, internalSin)
                CompareNumbers(N, num, op) || return false
            end
        end
        return true
    end

    filterStr = "Filter: $passDesc to require $(getSinString(internalSin)) E.G.O resources $(@blue(op)) $(@red(string(num))) (Input: $(@dim(sinQuery)))"
    return PersonalityFilter(Fn, filterStr)
end

function constructFilter(::Type{Personality}, input)
    parts = split(input, "|")
    if length(parts) > 1
        return OrFilter([constructFilter(Personality, x) for x in parts])
    end
    
    Ct = 0
    while Ct < length(input) && input[Ct + 1] == '^'
        Ct += 1
    end
    if Ct > 0
        if Ct % 2 == 1
            return NotFilter(constructFilter(Personality, input[Ct+1:end]))
        else
            return constructFilter(Personality, input[Ct+1:end])
        end
    end

    S = match(r"^fn[:=](.+)$", input)
    if S !== nothing
        query = string(S.captures[1])
        return EvalFilter(Personality, query)
    end

    S = match(r"[iI]d(entity)?[=:]([0-9]+)", input)
    if S !== nothing
        N = parse(Int, S.captures[2])
        return SinnerPersonalityFilter(N)
    end
  
    for (myRegex, filterFn, params) in [(r"[iI]d(entity)?[:=](.+)$", SinnerPersonalityFilter, [2]),
                                        (r"^[dD]ef[:=][tT]ype[:=](.+)$", DefenseTypePersonalityFilter, [1]),
                                        (r"^[rR]arity[:=](.+)$", SinnerRarityFilter, [1]),
                                        (r"^[eE]vent$", SinnerEventFilter, []),
                                        (r"^[sS]eason[:=](.+)$", SinnerSeasonFilter, [1]),
                                        (r"^[fF]ac(tion)?[:=](.+)$", SinnerFactionFilter, [2]),
                                        (r"^(.*)[:=][sS]in(type|affinity)?[:=](.+)$", CombatSkillSinFilter, [1, 3]),
                                        (r"^(.*)[:=][aA](tk|ttack)[tT]ype[:=](.+)$", CombatSkillAtkTypeFilter, [1, 3]),
                                        (r"^(health|hp)([<>=≤≥]+)([0-9]+)$", SinnerHealthFilter, [3, 2]),
                                        (r"^min[sS]peed([<>=≤≥]+)([0-9]+)$", SinnerMinSpeedFilter, [2, 1]),
                                        (r"^max[sS]peed([<>=≤≥]+)([0-9]+)$", SinnerMaxSpeedFilter, [2, 1]),
                                        (r"^[dD]ef[cC]or(rection)?([<>=≤≥]+)([-+]?[0-9]+)$", SinnerDefCorrectionFilter, [3, 2]),
                                        (r"^(.*)[:=][mM]in[rR]olls?([<>=≤≥]+)(.+)$", CombatSkillMinRollFilter, [1, 3, 2]),
                                        (r"^(.*)[:=][mM]ax[rR]olls?([<>=≤≥]+)(.+)$", CombatSkillMaxRollFilter, [1, 3, 2]),
                                        (r"^(.*)[:=][wW]eight([<>=≤≥]+)(.+)$", CombatSkillWeightFilter, [1, 3, 2]),
                                        (r"[rR]es(ist)?[:=]([a-zA-Z]+)([<>=≤≥]+)([0-9\.]+)$", SinnerResistanceFilter, [2, 3, 4]),
                                        (r"^(.*)[:=][oO]ff(ense)?[cC]or(rection)?([<>=≤≥]+)(.+)$", CombatSkillOffCorFilter, [1, 5, 4]),
                                        (r"^(.*)[:=]([nN]um)?[cC]oins?([<>=≤≥]+)(.+)$", CombatSkillNumCoinsFilter, [1, 4, 3]),
                                        (r"^[pP]ass(ive)?[:=](.*)[:=](is)?[rR]eson(anance)?$", SinnerPassiveResonFilter, [2]),
                                        (r"^[pP]ass(ive)?[:=](.*)[:=](is)?[sS]tock$", SinnerPassiveStockFilter, [2]),
                                        (r"^[pP]ass(ive)?[:=](.*)[:=](.+)([<>=≤≥]+)([0-9]+)$", SinnerPassiveSinFilter, [2, 3, 5, 4]),
                                        (r"^[pP]ass(ive)?[:=](.*)[:=](.+)$", SinnerPassiveSinFilter, [2, 3])]
        S = match(myRegex, input)
        if S !== nothing
            stringParams = [string(S.captures[i]) for i in params]
            return filterFn(stringParams...)
        end
    end

    return TrivialPersonalityFilter
end

function applyFilter(personalityList, pFilter, lvl, uptie)
    N = length(personalityList)
    newList = Personality[]
    for myID in personalityList
        if pFilter.fn(myID, lvl, uptie)
            push!(newList, myID)
        end
    end
    if length(newList) < N
        return newList, pFilter.description
    else
        return newList, ""
    end
end

# Printing and Searching

function printSingle(myID :: Personality, tier, level, verbose)
    println(getFullPanel(myID, level, tier; verbose = verbose))
    return myID
end

function printRandom(::Type{Personality}, verbose)
    randID = rand(getMasterList(Personality))
    printSingle(randID, rand(1:getMaxUptie(Personality)), 
                rand(1:getMaxLevel(Personality)), verbose)

    return randID
end

function searchSinglePersonality(query, haystack, tier, level, verbose)
    print("Using $(@red(query)) as query")
    AddParams = String[]
    tier !== getMaxUptie(Personality) && push!(AddParams, "Uptie: $(@red(string(tier)))")
    level != -1 && push!(AddParams, "Level: $(@red(string(level)))")

    length(AddParams) > 0 && print(" with $(join(AddParams, "; "))")
    println(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, tier, level, verbose)
    return result
end

function searchTopPersonality(query, haystack, topN, tier)
    println("Using $(@red(query)) as query. The $topN closest Personalitys are:")
    result = SearchClosestString(query, haystack; top = topN)
    resultPersonality = [x[2] for x in result]
    
    return printFromPersonalityList(resultPersonality, tier)
end

PersonalityPreviousSearchResult = Personality[]
function printFromPersonalityList(list, tier = getMaxUptie(Personality))
    global PersonalityPreviousSearchResult = copy(list)

    if length(PersonalityPreviousSearchResult) == 0
        println("No results found.")
        return PersonalityPreviousSearchResult
    end
    
    ResultStrings = String[]
    for myID in list
        push!(ResultStrings, getFullTitle(myID))
    end

    print(GridFromList(ResultStrings, 1; labelled = true))
    return PersonalityPreviousSearchResult
end

function printAllPersonality(list, tier)
    println("Identities that match the filters:")
    return printFromPersonalityList(list, tier)
end

function printJSONList(::Type{Personality})
    println("Listing the contents of $(join(getMasterFileClasses(Personality), ", ")):")
    JSONList = getMasterFileList(Personality)
    println(GridFromList(JSONList, 2; labelled = true))
    return JSONList
end

function printPersonalityFromJSONInternal(file)
    PersonalityDatabase = StaticData(file)["list"]
    println("Listing the identities in $(@yellow(file)):")
    Names = [Personality(s["id"]) for s in PersonalityDatabase]
    return printFromPersonalityList(Names)
end

function printPersonalityFromJSON(input)
    JSONList = getMasterFileList(Personality)
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printPersonalityFromJSONInternal(JSONList[val])
    end

    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printPersonalityFromJSONInternal(result[begin][begin])
end

function printPersonalityExactNumberInput(num, uptie, level, verbose)
    global PersonalityPreviousSearchResult
    if length(PersonalityPreviousSearchResult) == 0
        @info "No previously search `identity list`."
        return ""
    end

    N = parse(Int, num)

    if !(1 ≤ N ≤ length(PersonalityPreviousSearchResult))
        @info "There are only $(length(PersonalityPreviousSearchResult)) ids. You asked for the $N-th entry."
        return -1
    end

    return printSingle(PersonalityPreviousSearchResult[N],
                       uptie, level, verbose)
end