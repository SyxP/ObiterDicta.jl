function PersonalityHelp()
    S = raw"""Looks up identities. Available Commands:
              `id list jsons`         - List all internal JSONs.
              `id list _bundle.json_` - List all identities in _bundle.json_
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
              `id !i 1010101 !ut1 !olvl40` - Outputs the internal identity with ID 1010101 Uptie 1 and Level 40.
              `id !all [id=donqui] [s2=wrath]` - Outputs all Don Quixote identities with Wrath S2.
        """

    println(S)
    return S
end

function FilterHelp(::Type{Personality})
    S = raw"""Filters reduce the search space. 
              Note that filters can not have spaces between the [].
              Available Filters:
              [id:_num_]               - Sinner's Number must _num_. Note that Sinclair is given the ID 10.
              [id:_name_]              - Sinner's Name must be _name_.
              [health_op__num_]        - Health of the identity must _op_ _num_.
              [resist:_type__op__num_] - Resistance of type _type_ _op_ _num_.
              [def:type:_type_]        - Defensive Type must be _type_ (e.g. Guard).
              [*:sin:_type_]           - Any (*) skill must have sin Affinity _type_.
              [*:atkType:_type_]       - Any (*) skill must have attack Type _type_.
              [*:minRoll_op__num_]     - All (*) skill must have minimum roll _op_ _num_.
              [*:maxRoll_op__num_]     - All (*) skill must have maximum roll _op_ _num_.
              [*:numCoins_op__num_]    - All (*) skill must have number of coins _op_ _num_.

              * can be one of S1, S2, S3, atkSkills, def, allSkills
              _op_ can be one of =, <, ≤ (<=), >, ≥ (>=)
              [^_query_] constructs a filter that is true if [_query_] is false.
        """

    println(S)
    return S
end

function PersonalityParser(input)
    S = match(r"^filters? help", input)
    (S !== nothing) && return FilterHelp(Personality)
    
    S = match(r"^list jsons?$", input)
    (S !== nothing) && return printJSONList(Personality)
    
    S = match(r"^list (.*)$", input)
    (S !== nothing) && return printPersonalityFromJSON(S.captures[1])

    S = match(r"^([0-9]+)$", input)
    if S !== nothing
        return printPersonalityExactNumberInput(S.captures[1], false)
    end

    S = match(r"^([0-9]+) +![vV](erbose)?$", input)
    if S !== nothing
        return printPersonalityExactNumberInput(S.captures[1], true)
    end
    S = match(r"^![vV](erbose)? ([0-9]+)$", input)
    if S !== nothing
        return printPersonalityExactNumberInput(S.captures[2], true)
    end

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

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![tT]ier([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![lL]vl([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![lL]evel([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![uU]ptie([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![uU][tT]([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^\[(.*)\]$"] = (x) -> push!(pFilters, constructFilter(Personality, x))


    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(PersonalitySearchList) == 0) && (PersonalitySearchList = getMasterList(Personality))

    for currFilter in pFilters
        Tmp = ""
        PersonalitySearchList, Tmp = applyFilter(PersonalitySearchList, currFilter, Level, Tier)
        if Tmp != ""
            tprintln(Tmp)
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

PersonalityRegex = r"^(id|identity|identities) (.*)$"
PersonalityCommand = Command(PersonalityRegex, PersonalityParser,
                             [2], PersonalityHelp)
# Filters
struct PersonalityFilter
    fn :: Function # returns true if passed Filter
    description :: String # printed while Filter is applied
end
TrivialPersonalityFilter = PersonalityFilter((x, lvl, uptie) -> true, "")

function NotFilter(filter :: PersonalityFilter)
    Fn(x, lvl, uptie) = !filter.fn(x, lvl, uptie)
    return PersonalityFilter(Fn, "$(@red("Not")) " * filter.description)
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

function SinnerHealthFilter(num :: String, relation :: String)
    N = parse(Int, num)
    (relation == "<=") && (relation = "≤")
    (relation == ">=") && (relation = "≥")
    
    function Fn(x, lvl, uptie)
        totalHP = getHP(x, lvl)
        return CompareNumbers(totalHP, N, relation)
    end

    filterStr = "Filter: Sinner Health $(@blue(relation)) $(@red(num))"
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

function getSkillFunctions(skillStr)
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

function CombatSkillSinFilter(skillNumStr, sinQuery)
    skillFn, skillDesc = getSkillFunctions(skillNumStr)
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
    skillFn, skillDesc = getSkillFunctions(skillNumStr)
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
                                   (:CombatSkillNumCoinsFilter, getNumCoins, "number of coins")]
    @eval function ($defineFn)(skillNumStr, num :: String, op)
        (op == "<=") && (op = "≤")
        (op == ">=") && (op = "≥")
        compareN = parse(Int, num)
        skillFn, skillDesc = getSkillFunctions(skillNumStr)
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

        filterStr = "Filter: $(@red(skillDesc)) to have "* $desc * " $(@blue(op))$(@red(num)) "
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

    filterStr = "Filter: Sinner's resistance to $(AttackTypes(searchType)) $(@blue(op))$(@red(num))× (Input: $(@dim(resistType)))"
    return PersonalityFilter(Fn, filterStr)
end

function constructFilter(::Type{Personality}, input)
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

    S = match(r"[iI]d(entity)?[=:]([0-9]+)", input)
    if S !== nothing
        N = parse(Int, S.captures[2])
        return SinnerPersonalityFilter(N)
    end

    S = match(r"[iI]d(entity)?[=:](.+)", input)
    if S !== nothing
        query = string(S.captures[2])
        return SinnerPersonalityFilter(query)
    end

    S = match(r"[dD]ef[:=][tT]ype[:=](.+)", input)
    if S !== nothing
        query = string(S.captures[1])
        return DefenseTypePersonalityFilter(query)
    end

    S = match(r"^(.*)[:=][sS]in(type|affinity)?[:=](.+)$", input)
    if S !== nothing
        skillNumStr = string(S.captures[1])
        sinQuery = string(S.captures[3])
        return CombatSkillSinFilter(skillNumStr, sinQuery)
    end

    S = match(r"^(.*)[:=][aA](tk|ttack)[tT]ype[:=](.+)$", input)
    if S !== nothing
        skillNumStr = string(S.captures[1])
        atkTypeQuery = string(S.captures[3])
        return CombatSkillAtkTypeFilter(skillNumStr, atkTypeQuery)
    end

    S = match(r"^(health|hp)([<>=≤≥]+)([0-9]+)$", input)
    if S !== nothing
        num = string(S.captures[3])
        op = string(S.captures[2])
        return SinnerHealthFilter(num, op)
    end

    S = match(r"^(.*)[:=][mM]in[rR]olls?([<>=≤≥]+)(.+)$", input)
    if S !== nothing
        skillNumStr = string(S.captures[1])
        num = string(S.captures[3])
        op = string(S.captures[2])
        return CombatSkillMinRollFilter(skillNumStr, num, op)
    end

    S = match(r"^(.*)[:=][mM]ax[rR]olls?([<>=≤≥]+)(.+)$", input)
    if S !== nothing
        skillNumStr = string(S.captures[1])
        num = string(S.captures[3])
        op = string(S.captures[2])
        return CombatSkillMaxRollFilter(skillNumStr, num, op)
    end

    S = match(r"^(.*)[:=]([nN]um)?[cC]oins?([<>=≤≥]+)(.+)$", input)
    if S !== nothing
        skillNumStr = string(S.captures[1])
        num = string(S.captures[4])
        op = string(S.captures[3])
        return CombatSkillNumCoinsFilter(skillNumStr, num, op)
    end

    S = match(r"^[rR]es(ist)?[:=]([a-zA-Z]+)([<>=≤≥]+)([0-9\.]+)$", input)
    if S !== nothing
        resType = string(S.captures[2])
        op = string(S.captures[3])
        num = string(S.captures[4])
        return SinnerResistanceFilter(resType, op, num)
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

printSingle(myID :: Personality, tier, level, verbose) = 
    tprintln(getFullPanel(myID, level, tier; verbose = verbose))

printRandom(::Type{Personality}, verbose) = 
    printSingle(rand(getMasterList(Personality)), rand(1:getMaxUptie(Personality)), 
                rand(1:getMaxLevel(Personality)), verbose)

function searchSinglePersonality(query, haystack, tier, level, verbose)
    tprint("Using {red}$query{/red} as query")
    AddParams = String[]
    tier !== 999 && push!(AddParams, "Tier: {red}$tier{red}")
    level != -1 && push!(AddParams, "Level: {red}$level{/red}")

    length(AddParams) > 0 && tprint(" with $(join(AddParams, "; "))")
    tprintln(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, tier, level, verbose)
    return result
end

function searchTopPersonality(query, haystack, topN, tier)
    tprintln("Using {red}$query{/red} as query. The $topN closest Personalitys are:")
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

function printPersonalityExactNumberInput(num, verbose)
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
                       getMaxUptie(Personality), getMaxLevel(Personality), verbose)
end