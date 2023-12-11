function EGOHelp()
    S = raw"""Looks up E.G.Os. Available Commands:
              `ego list jsons`         - List all internal JSONs.
              `ego list _bundle.json_` - List all E.G.Os in _bundle.json_
              `ego _query_ _flags_`    - Looks up _query_.

              Available Flags:
              !v/!verbose  - Outputs the internal additional fields.
              !top_num_    - Outputs the top _num_ E.G.Os matching the query. Default is 5. (*)
              !i/!internal - Only performs the query on internal E.G.O names.
              !ts_num_     - Sets the threadspin at _num_. Without this, it is set to the maximum possible.
              [_filter_]   - Filter the list of E.G.Os

              After (*), `ego _number_` will directly output the corresponding E.G.O.
              To see available filters, use `ego filters help`.
              Example usage:
              `ego !i 20805 !ts2` - Outputs the internal E.G.O with ID 20805 and Threadspin 2.
              `ego !all [id=fish] [wrathRes>1]` - Outputs all Ishmael E.G.Os with Wrath Resistance > 1.
        """
    
    println(S)
    return S
end

function FilterHelp(::Type{EGO})
    S = raw"""Filters reduce the search space.
              Note that filters can not have spaces between the [].
              Available Fitlers:
              [id:_num_]               - E.G.O owner's Number must be _num_.
              [id:_name_]              - E.G.O owner's Name must be _name_.
              [season:_x_]             - E.G.O is from Season _x_.
              [event]                  - E.G.O is from an event.
              [canCorrode]             - E.G.O can corrode.
              [type:_tier_]            - E.G.O is of type _tier_ (e.g. ZAYIN).
              [resist:_type__op__num_] - Conferred resistance of sin _type_ _op_ _num_.
              [*:sin:_type_]           - Any (*) skill must have sin Affinity _type_.
              [*:atkType:_type_]       - Any (*) skill must have attack Type _type_.
              [*:targetType:_type_]    - All (*) skill must have target type _type_.
              [*:minRoll_op__num_]     - All (*) skill must have minimum roll _op_ _num_.
              [*:maxRoll_op__num_]     - All (*) skill must have maximum roll _op_ _num_.
              [*:SPUse_op__num_]       - All (*) skill must have sanity usage _op_ _num_.
              [*:numCoins_op__num_]    - All (*) skill must have number of coins _op_ _num_.
              [*:weight_op__num_]      - All (*) skill must have weight _op_ _num_.
              [*:offCor_op__num_]      - All (*) skill must have offense correction _op_ _num_.
              [fn:_FunName_]           - ⟨Adv⟩ Filters based on FunName(ego, ts). See `filtreg help`.

              * can be one of awake, corr, allSkills
              _op_ can be one of =, <, ≤ (<=), >, ≥ (>=)
              [^_query_] constructs a filter that is true iff [_query_] is false.
              [_queryA_|_queryB_] constructs a filter that is true iff either [_queryA_] or [_queryB_] is true.
        """

    println(S)
    return S
end

function EGOParser(input)
    S = match(r"^filters? help$", input)
    (S !== nothing) && return FilterHelp(EGO)

    S = match(r"^list jsons?$", input)
    (S !== nothing) && return printJSONList(EGO)

    if match(r"list all", input) !== nothing
        println("Do you mean: `ego !all`?")
    end

    S = match(r"^list (.*)$", input)
    (S !== nothing) && return printEGOFromJSON(S.captures[1])

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(EGO, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(EGO, true)

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    PrintAll = false
    EGOSearchList = EGO[]
    Tier = getMaxThreadspin(EGO)
    pFilters = EGOFilter[]
    ExactNumber = true

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true; ExactNumber = false)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5; ExactNumber = false)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x); ExactNumber = false)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true; ExactNumber = false)
    Applications[r"^![tT]ier([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![tT]hreadspin([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![tT][sS]([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^\[(.*)\]$"] = (x) -> (push!(pFilters, constructFilter(EGO, x)); ExactNumber = false)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    S = match(r"^([0-9]+)$", newQuery)
    if S !== nothing && ExactNumber
        return printEGOExactNumberInput(newQuery, Tier, Verbose)
    end

    (length(EGOSearchList) == 0) && (EGOSearchList = getMasterList(EGO))

    for currFilter in pFilters
        Tmp = ""
        EGOSearchList, Tmp = applyFilter(EGOSearchList, currFilter, Tier)
        if Tmp != ""
            tprintln(Tmp)
        end
    end

    PrintAll && return printAllEGO(EGOSearchList, Tier)
    length(EGOSearchList) == 0 && return printAllEGO(EGOSearchList, Tier)
    
    HaystackEGO = []
    for myEGO in EGOSearchList
        if UseInternalIDs
            push!(HaystackEGO, (getStringID(myEGO), myEGO))
        else
            if hasLocalizedVersion(myEGO)
                push!(HaystackEGO, (getSearchTitle(myEGO), myEGO))
            end
        end
    end

    TopNumber == 1 && return searchSingleEGO(newQuery, HaystackEGO, Tier, Verbose)
    return searchTopEGO(newQuery, HaystackEGO, TopNumber, Tier)
end

EGORegex = r"^(ego|EGO) (.*)$"
EGOCommand = Command(EGORegex, EGOParser, [2], EGOHelp)

# Filters
TrivialEGOFilter = EGOFilter((x, threadspin) -> true, "")

function NotFilter(filter :: EGOFilter)
    Fn(x, ts) = !filter.fn(x, ts)
    return EGOFilter(Fn, "$(@red("Not")) " * filter.description)
end

function OrFilter(filterList :: Vector{EGOFilter})
    Fn(x, ts) = any([filter.fn(x, ts) for filter in filterList])
    io = IOBuffer()
    println(io, "$(@red("Or")) Filter with length $(length(filterList))")
    for (idx, filter) in enumerate(filterList)
        println(io, " - $(@dim(string(idx))): " * filter.description)
    end
    return EGOFilter(Fn, String(take!(io)))
end

function EvalFilter(::Type{EGO}, str :: String)
    Entries = split(str, ":")
    Fn(x, ts) = (FilterRegistry[Entries[1]])(x, ts, Entries[2:end]...)
    return EGOFilter(Fn, "Custom Filter: $(@blue(str))")
end

function SinnerEGOFilter(num :: Integer)
    Fn(x, ts) = getSinnerID(x) == num
    filterStr = "Filter: Sinner to $(@red(getSinnerName(num)))"

    return EGOFilter(Fn, filterStr)
end

function SinnerEGOFilter(str :: String)
    num = getClosestSinnerIDFromName(str)
    Fn(x, ts) = getSinnerID(x) == num
    filterStr = "Filter: Sinner to $(@red(getSinnerName(num))) (Input: $(@dim(str)))"   

    return EGOFilter(Fn, filterStr)
end

function EGOEventFilter()
    Fn(x, ts) = isEvent(x)
    filterStr = "Filter: Sinner is from an Event"
    return EGOFilter(Fn, filterStr)
end

function EGOSeasonFilter(str)
    N = getSeasonIDFromName(str)
    N == -1 && return TrivialPersonalityFilter
    Fn(x, ts) = getSeason(x) == N
    filterStr = "Filter: E.G.O Season is $(@red(getSeasonNameFromInt(N))) (Input: $(@dim(str)))"

    return EGOFilter(Fn, filterStr)
end

function EGOTypeFilter(str)
    typeStr = getClosestEGOType(str)
    Fn(x, ts) = getEGOType(x) == typeStr
    filterStr = "Filter: E.G.O Class is $(@red(typeStr)) (Input: $(@dim(str)))"

    return EGOFilter(Fn, filterStr)
end

function EGOCorrodableFilter()
    Fn(x, ts) = getCorrosionSkill(x) !== nothing
    filterStr = "Filter: E.G.O can corrode"

    return EGOFilter(Fn, filterStr)
end

function getSkillFunctions(::Type{EGO}, skillStr)
    if match(r"^[aA]wake(ning)?$", skillStr) !== nothing
        return [getAwakeningSkill], "Awakening Skill"
    elseif match(r"^[cC]orr(osion)?$", skillStr) !== nothing
        return [getCorrosionSkill], "Corrosion Skill"
    elseif match(r"^[aA]ll([sS]kills?)$", skillStr) !== nothing
        SkillFn = [getAwakeningSkill, getCorrosionSkill]
        return SkillFn, "All Skills"
    end

    return Function[], ""
end

function EGOSinFilter(skillNumStr, sinQuery)
    skillFn, skillDesc = getSkillFunctions(EGO, skillNumStr)
    skillDesc == "" && return TrivialEGOFilter
    internalSin = getClosestSinFromName(sinQuery)
    function Fn(x, ts)
        for tmpFn in skillFn
            Lst = tmpFn(x)
            Lst === nothing && continue
            if Lst isa Vector
                for skill in Lst
                    getSinType(skill, ts) == internalSin && return true
                end
            else
                skill = Lst
                getSinType(skill, ts) == internalSin && return true
            end
        end
        return false
    end

    filterStr = "Filter: $(@red(skillDesc)) to have Sin Affinity $(getSinString(internalSin)) (Input: $(@dim(sinQuery)))"
    return EGOFilter(Fn, filterStr)
end

function EGOAtkTypeFilter(skillNumStr, atkTypeQuery)
    skillFn, skillDesc = getSkillFunctions(EGO, skillNumStr)
    skillDesc == "" && return TrivialEGOFilter
    internalAtkType = getClosestAtkTypeFromName(atkTypeQuery)
    function Fn(x, ts)
        for tmpFn in skillFn
            Lst = tmpFn(x)
            Lst === nothing && continue
            if Lst isa Vector
                for skill in Lst
                    getAtkType(skill, ts) == internalAtkType && return true
                end
            else
                skill = Lst
                getAtkType(skill, ts) == internalAtkType && return true
            end
        end
        return false
    end

    filterStr = "Filter: $(@red(skillDesc)) to have Attack Type $(AttackTypes(internalAtkType)) (Input: $(@dim(atkTypeQuery)))"
    return EGOFilter(Fn, filterStr)
end

function EGOTargetTypeFilter(skillNumStr, targetType)
    skillFn, skillDesc = getSkillFunctions(EGO, skillNumStr)
    skillDesc == "" && return TrivialEGOFilter
    normTargetType = lowercase(superNormString(targetType))
    function Fn(x, ts)
        for tmpFn in skillFn
            Lst = tmpFn(x)
            Lst === nothing && continue
            if Lst isa Vector
                for skill in Lst
                    S = getTargetType(skill, ts)
                    lowercase(superNormString(S)) == normTargetType || return false
                end
            else
                skill = Lst
                S = getTargetType(skill, ts)
                lowercase(superNormString(S)) == normTargetType || return false
            end
        end
        return true
    end

    filterStr = "Filter: $(@red(skillDesc)) to have Target Type $(@red(targetType)) (Input: $(@dim(targetType)))"
    return EGOFilter(Fn, filterStr)
end

for (defineFn, lookupFn, desc) in [(:EGOMinRollFilter, getMinRoll, "minimum roll"),
                                   (:EGOMaxRollFilter, getMaxRoll, "maximum roll"),
                                   (:EGONumCoinsFilter, getNumCoins, "number of coins"),
                                   (:EGOWeightFilter, getWeight, "weight"),
                                   (:EGOSanityCostFilter, getMPUsage, "sanity cost"),
                                   (:EGOOffCorFilter, getOffLevelCorrection, "offensive level correction")]
    @eval function ($defineFn)(skillNumStr, num :: String, op)
        (op == "<=") && (op = "≤")
        (op == ">=") && (op = "≥")
        compareN = parse(Int, num)
        skillFn, skillDesc = getSkillFunctions(EGO, skillNumStr)
        skillDesc == "" && return TrivialEGOFilter
        function Fn(x, ts)
            for tmpFn in skillFn
                Lst = tmpFn(x)
                Lst === nothing && continue
                if Lst isa Vector
                    for skill in Lst
                        N = ($lookupFn)(skill, ts)
                        CompareNumbers(N, compareN, op) || return false
                    end
                else
                    skill = Lst
                    N = ($lookupFn)(skill, ts)
                    CompareNumbers(N, compareN, op) || return false
                end
            end
            return true
        end

        filterStr = "Filter: $(@red(skillDesc)) to have "* $desc * " $(@blue(op)) $(@red(num)) "
        return EGOFilter(Fn, filterStr)
    end
end

function EGOResistFilter(sinType, op, num)
    compareN = tryparse(Float64, num)
    compareN === nothing && return TrivialEGOFilter
    searchType = getClosestSinFromName(sinType)
    (op == "<=") && (op = "≤")
    (op == ">=") && (op = "≥")

    function Fn(x, ts)
        N = getConferredResistance(x, searchType)
        return CompareNumbers(N, compareN, op) 
    end

    filterStr = "Filter: E.G.O conferred $(getSinString(searchType)) resistances $(@blue(op)) $(@red(num)) (Input: $(@dim(sinType)))"
    return EGOFilter(Fn, filterStr)
end
    
function constructFilter(::Type{EGO}, input)
    parts = split(input, "|")
    if length(parts) > 1
        return OrFilter([constructFilter(EGO, x) for x in parts])
    end

    Ct = 0
    while Ct < length(input) && input[Ct + 1] == '^'
        Ct += 1
    end
    if Ct > 0
        if Ct % 2 == 1
            return NotFilter(constructFilter(EGO, input[Ct+1:end]))
        else
            return constructFilter(EGO, input[Ct+1:end])
        end
    end

    S = match(r"^fn[:=](.+)$", input)
    if S !== nothing
        query = string(S.captures[1])
        return EvalFilter(EGO, query)
    end

    S = match(r"^[iI]d(entity)?[=:]([0-9]+)$", input)
    if S !== nothing
        N = parse(Int, S.captures[2])
        return SinnerEGOFilter(N)
    end
    for (myRegex, filterFn, params) in [(r"^[iI]d(entity)?[:=](.+)$", SinnerEGOFilter, [2]),
                                        (r"^[sS]eason[:=](.*)", EGOSeasonFilter, [1]),
                                        (r"^[eE]vent$", EGOEventFilter, []),
                                        (r"^[cC]an[cC]orrode$", EGOCorrodableFilter, []),
                                        (r"^[tT]ype[:=](.*)", EGOTypeFilter, [1]),
                                        (r"^(.*)[:=][sS]in(type|affinity)?[:=](.+)$", EGOSinFilter, [1, 3]),
                                        (r"^(.*)[:=][aA](tk|ttack)[tT]ype[:=](.+)$", EGOAtkTypeFilter, [1, 3]),
                                        (r"^(.*)[:=][tT]arget[tT]ype[:=](.+)$", EGOTargetTypeFilter, [1, 2]),
                                        (r"^[rR]es(ist)?[:=](.*)([<=>≤≥]+)(.+)$", EGOResistFilter, [2, 3, 4]),
                                        (r"^(.*)[:=][mM]in[rR]olls?([<>=≤≥]+)(.+)$", EGOMinRollFilter, [1, 3, 2]),
                                        (r"^(.*)[:=][mM]ax[rR]olls?([<>=≤≥]+)(.+)$", EGOMaxRollFilter, [1, 3, 2]),
                                        (r"^(.*)[:=][wW]eight([<>=≤≥]+)(.+)$", EGOWeightFilter, [1, 3, 2]),
                                        (r"^(.*)[:=][sS][pP]([cC]ost|[uU]se)?([<>=≤≥]+)(.+)$", EGOSanityCostFilter, [1, 4, 3]),
                                        (r"^(.*)[:=]([nN]um)?[cC]oins?([<>=≤≥]+)(.+)$", EGONumCoinsFilter, [1, 4, 3]),
                                        (r"^(.*)[:=][oO]ff[cC]or(rection)?([<>=≤≥]+)(.+)$", EGOOffCorFilter, [1, 4, 3])]
        S = match(myRegex, input)
        if S !== nothing
            stringParams = [string(S.captures[i]) for i in params]
            return filterFn(stringParams...)
        end
    end

    return TrivialEGOFilter
end

function applyFilter(EGOList, pFilter, threadspin)
    N = length(EGOList)
    newList = EGO[]
    for myEGO in EGOList
        if pFilter.fn(myEGO, threadspin)
            push!(newList, myEGO)
        end
    end
    if length(newList) < N
        return newList, pFilter.description
    else
        return newList, ""
    end
end

# Printing and Searching

printSingle(myEGO :: EGO, threadspin, verbose) = 
    tprintln(getFullPanel(myEGO, threadspin; verbose = verbose))

printRandom(::Type{EGO}, verbose) = 
    printSingle(rand(getMasterList(EGO)), rand(1:getMaxThreadspin(EGO)), verbose)

function searchSingleEGO(query, haystack, threadspin, verbose)
    tprint("Using {red}$query{/red} as query")
    AddParams = String[]
    threadspin != 999 && push!(AddParams, "Threadspin: {red}$threadspin{/red}")

    length(AddParams) > 0 && tprint(" with $(join(AddParams, "; "))")
    tprintln(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, threadspin, verbose)
    return result
end

function searchTopEGO(query, haystack, topN, threadspin)
    tprintln("Using {red}$query{/red} as query. The $topN closest EGOs are:")
    result = SearchClosestString(query, haystack; top = topN)
    resultEGO = [x[2] for x in result]

    return printFromEGOList(resultEGO, threadspin)
end

EGOPreviousSearchResult = EGO[]
function printFromEGOList(list, threadspin = getMaxThreadspin(EGO))
    global EGOPreviousSearchResult = copy(list)

    if length(EGOPreviousSearchResult) == 0
        println("No results found.")
        return EGOPreviousSearchResult
    end

    ResultStrings = String[]
    for myEGO in list
        push!(ResultStrings, getFullTitle(myEGO))
    end

    print(GridFromList(ResultStrings, 1; labelled = true))
    return EGOPreviousSearchResult
end

function printAllEGO(list, threadspin)
    println("E.G.Os that match the filters:")
    return printFromEGOList(list, threadspin)
end

function printJSONList(::Type{EGO})
    println("Listing the contents of $(join(getMasterFileClasses(EGO), ", ")):")
    EGOList = getMasterFileList(EGO)
    println(GridFromList(EGOList, 2; labelled = true))
    return EGOList
end

function printEGOFromJSONInternal(file)
    println("Listing the E.G.Os of $(@yellow(file)):")
    EGODatabase = StaticData(file)["list"]
    Names = [EGO(item["id"]) for item in EGODatabase]
    return printFromEGOList(Names)
end

function printEGOFromJSON(input)
    JSONList = getMasterFileList(EGO)
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printEGOFromJSONInternal(JSONList[val])
    end

    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printEGOFromJSONInternal(result[begin][begin])
end

function printEGOExactNumberInput(num, ts, verbose)
    global EGOPreviousSearchResult
    if length(EGOPreviousSearchResult) == 0
        @info "No previously search `ego list`."
        return ""
    end

    N = parse(Int, num)

    if !(1 ≤ N ≤ length(EGOPreviousSearchResult))
        @info "There are only $(length(EGOPreviousSearchResult)) E.G.Os. You asked for the $N-th entry."
        return ""
    end

    return printSingle(EGOPreviousSearchResult[N], ts, verbose)
end