function EGOGiftHelp()
    S = raw"""Looks up E.G.O Gifts. Available Commands:
              `ego-gift list jsons`         - List all internal JSONs. 
              `ego-gift _query_ _flags_`    - Looks up _query_.

              Available Flags:
              !v/!verbose   - Outputs the internal additional fields.
              !top_num_     - Outputs the top _num_ E.G.O Gifts matching the query. Default is 5. (*)
              !i/!internal  - Only performs the query on internal E.G.O Gift names.
              !a/!all       - Outputs all E.G.O Gifts matching the filters. (*)
              !hidden       - Add hidden E.G.O Gifts to search.
              !in:_dungeon_ - E.G.O Gift is in (†).
              [_filter_]    - Filter the list of E.G.O Gifts.

              After (*), `ego-gift _number_` will directly output the corresponding E.G.O Gift.
              To see available filters, use `ego-gift filters help`.
              Example usage:
              `ego-gift !i 1055` - Outputs the internal E.G.O Gift with ID 1055.
              `ego-gift !all [keyword:sinking] [tier:2] [in:md]` - Outputs all Tier 2 Sinking E.G.O Gifts in Mirror Dungeon.

              (†) can be any of:
              - `md`/`mirror`        - Mirror Dungeon
              - `story`              - Story
              - `3.5`/`hellschicken` - Hells Chicken Dungeon.
              Note that Hell's Chicken Dungeon E.G.O Gifts are not included by default.
              To include them, use the flag `!in:3.5`.
        """

    println(S)
    return S
end

function FilterHelp(::Type{T}) where T <: EGOGift
    S = raw"""Filters reduce the search space.
              Available Filters:
              [keyword:_buff_]    - E.G.O Gift contains _buff_.
              [tag:_tag_]         - E.G.O Gift has tag _tag_.
              [tier:_tier_]       - E.G.O Gift is of tier _tier_.
              [attribute:_sin_]   - E.G.O Gift has attribute _sin_.
              [cost_op__num_]     - E.G.O Gift has cost _op_ _num_.

              [noKeyword]         - E.G.O Gift is not affiliated with any buffs.
              [noTier]            - E.G.O Gift is not affiliated with any tiers.
              [canUpgrade]        - E.G.O Gift can be upgraded.
    """

    println(S)
    return S
end

function EGOGiftParser(input)
    S = match(r"^filters? help$", input)
    (S !== nothing) && return FilterHelp(EGOGift)

    S = match(r"^list jsons?$", input)
    (S !== nothing) && return printJSONList(EGOGift)

    if match(r"list all", input) !== nothing
        println("Do you mean: `ego-gift !all`?")
    end

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(EGOGift, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(EGOGift, true)

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    PrintAll = false
    EGOGiftSearchList = EGOGift[]
    pFilters = EGOGiftFilter[]
    ExactNumber = true
    UseHidden = false

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true; ExactNumber = false)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5; ExactNumber = false)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x); ExactNumber = false)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true; ExactNumber = false)
    Applications[r"^![hH]idden$"] = () -> (UseHidden = true; ExactNumber = false)
    Applications[r"^!in:[mM][dD]$"] = () -> (append!(EGOGiftSearchList, getMasterList(MirrorDungeonEGOGift)))
    Applications[r"^!in:[mM]irror([dD]ungeon)?$"] = () -> (append!(EGOGiftSearchList, getMirrorList(MirrorDungeonEGOGift)))
    Applications[r"^!in:[sS]tory$"] = 
        () -> (append!(EGOGiftSearchList, getMasterList(StoryEGOGift)))
    Applications[r"^!in:(3.5|[hH]ells?([cC]hicken)?([dD]ungeon)?)$"] = 
        (_, _, _) -> (append!(EGOGiftSearchList, getMasterList(HellsChickenDungeonEGOGift)))
    Applications[r"\[(.*)\]$"] = (x) -> (push!(pFilters, constructFilter(EGOGift, x)); ExactNumber = false)
    
    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    S = match(r"^([0-9]+)$", newQuery)
    if S !== nothing && ExactNumber
        return printEGOGiftExactNumberInput(newQuery, Verbose)
    end

    if length(EGOGiftSearchList) == 0
        append!(EGOGiftSearchList, getMasterList(MirrorDungeonEGOGift))
        append!(EGOGiftSearchList, getMasterList(StoryEGOGift))
    end

    if !UseHidden
        filter!(!isHidden, EGOGiftSearchList)
    end

    for currFilter in pFilters
        Tmp = ""
        EGOGiftSearchList, Tmp = applyFilter(EGOGift, EGOGiftSearchList, currFilter)
        if Tmp != ""
            println(Tmp)
        end
    end

    PrintAll && return printAllEGOGift(EGOGiftSearchList)
    length(EGOGiftSearchList) == 0 && return printAllEGOGift(EGOGiftSearchList)

    HaystackEGOGift = []
    for myEGOGift in EGOGiftSearchList
        if UseInternalIDs
            push!(HaystackEGOGift, (getStringID(myEGOGift), myEGOGift))
        else
            push!(HaystackEGOGift, (getSearchTitle(myEGOGift), myEGOGift))
        end
    end

    TopNumber == 1 && return searchSingleEGOGift(newQuery, HaystackEGOGift, Verbose)
    return searchTopEGOGift(newQuery, HaystackEGOGift, TopNumber)
end

EGOGiftRegex = r"^(ego|EGO)-?[gG]ifts? (.*)$"
EGOGiftCommand = Command(EGOGiftRegex, EGOGiftParser, [2], EGOGiftHelp)

# Filters
struct EGOGiftFilter
    fn :: Function # return true if passed Filter
    description :: String # printed while Filter is applied
end

TrivialEGOGiftFilter = EGOGiftFilter((x) -> true, "")

function NotFilter(filter :: EGOGiftFilter)
    Fn(x) = !filter.fn(x)
    return EGOGiftFilter(Fn, "$(@red("Not")) " * filter.description)
end

function OrFilter(filterList :: Vector{EGOGiftFilter})
    Fn(x) = any([filter.fn(x) for filter in filterList])
    io = IOBuffer()
    println(io, "$(@red("Or")) Filter with length $(length(filterList))")
    for (idx, filter) in enumerate(filterList)
        println(io, " - $(@dim(string(idx))): " * filter.description)
    end
    return EGOGiftFilter(Fn, String(take!(io)))
end

function EvalFilter(::Type{EGOGift}, str)
    Entries = split(str, ":")
    Fn(x) = (FilterRegistry[Entries[1]])(x, Entries[2:end]...)
    return EGOGiftFilter(Fn, "Custom Filter: $(@blue(str))")
end

function EGOGiftTierFilter(tier)
    tierNum = tryparse(Int, tier)
    tierNum === nothing && return TrivialEGOGiftFilter
    function Fn(x)
        getTier(x) === nothing && return false
        return getTier(x) == tierNum
    end
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift has tier $(@red(tier))")
end

function EGOGiftCostFilter(cost, op)
    compareN = tryparse(Int, cost)
    compareN === nothing && return TrivialEGOGiftFilter
    (op == "<=") && (op = "≤")
    (op == ">=") && (op = "≥")

    function Fn(x)
        getPrice(x) === nothing && return false
        return CompareNumbers(getPrice(x), compareN, op)
    end
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift costs $(@blue(op))$(@red(cost))")
end

function EGOGiftAttributeFilter(sin)
    sinStr = getClosestSinFromName(sin)
    sinStr === nothing && return TrivialEGOGiftFilter
    function Fn(x)
        getAttributeType(x) === nothing && return false
        return getAttributeType(x) == sinStr
    end
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift has attribute $(getSinString(sinStr)) (Input: $(@dim(sin)))")
end

function EGOGiftTagFilter(tag)
    newTag = superNormString(tag)
    newTag = replace(newTag, " " => "", "_" => "")

    function Fn(x)
        getTags(x) === nothing && return false
        Lst = [superNormString(x) for x in getTags(x)]
        normLst = [replace(x, " " => "", "_" => "") for x in Lst]
        return newTag ∈ normLst
    end
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift has tag $(@red(tag))")
end

function EGOGiftKeywordFilter(buff)
    io = Pipe()
    foundBuff = nothing
    redirect_stdout(io) do
        foundBuff = BuffParser(buff)
    end
    close(io)

    foundBuff === nothing && return TrivialEGOGiftFilter
    if foundBuff isa Vector
        length(foundBuff) == 0 && return TrivialEGOGiftFilter
        foundBuff = foundBuff[1]
    end

    function Fn(x)
        getKeyword(x) === nothing && return false
        return getKeyword(x) == getID(foundBuff)
    end
    Desc = "Filter: E.G.O Gift has keyword $(@red(getName(foundBuff))) (Input: $(@dim(buff)))"
    return EGOGiftFilter(Fn, Desc)
end

function EGOGiftNoKeywordFilter()
    function Fn(x)
        S = getKeyword(x)
        S === nothing && return true
        S == "" && return true
        return false
    end
    
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift has no keyword")
end

function EGOGiftNoTierFilter()
    function Fn(x)
        getTier(x) === nothing && return true
        getTier(x) == -1 && return true
        return false
    end
    return EGOGiftFilter(Fn, "Filter: E.G.O Gift has no tier")
end

function EGOGiftCanUpgradeFilter()
    return EGOGiftFilter(hasUpgrade, "Filter: E.G.O Gift can be upgraded")
end

function constructFilter(::Type{EGOGift}, input)
    parts = split(input, "|")
    if length(parts) > 1
        return OrFilter([constructFilter(EGOGift, x) for x in parts])
    end

    Ct = 0
    while Ct < length(input) && input[Ct+1] == '^'
        Ct += 1
    end
    if Ct > 0
        if Ct % 2 == 1
            return NotFilter(constructFilter(EGOGift, input[Ct+1:end]))
        else
            return constructFilter(EGOGift, input[Ct+1:end])
        end
    end

    S = match(r"^fn[:=](.+)$", input)
    if S !== nothing
        query = string(S.captures[1])
        return EvalFilter(EGOGift, query)
    end

    for (myRegex, filterFn, params) in [
        (r"^noKeyword$", EGOGiftNoKeywordFilter, []),
        (r"^noTier$", EGOGiftNoTierFilter, []),
        (r"^canUpgrade$", EGOGiftCanUpgradeFilter, []),
        (r"^[tT]ier[:=](.+)$", EGOGiftTierFilter, [1]),
        (r"^[aA]ttribute[:=](.+)$", EGOGiftAttributeFilter, [1]),
        (r"^[sS]in[:=](.+)$", EGOGiftAttributeFilter, [1]),
        (r"^[tT]ag[:=](.+)$", EGOGiftTagFilter, [1]),
        (r"^[kK](ey)?word[:=](.+)$", EGOGiftKeywordFilter, [2]),
        (r"^[bB]uff[:=](.+)$", EGOGiftKeywordFilter, [1]),
        (r"^[cC]ost([<>=≤≥]+)(.+)$", EGOGiftCostFilter, [2, 1]),]
        S = match(myRegex, input)
        if S !== nothing
            stringParams = [string(S.captures[i]) for i in params]
            return filterFn(stringParams...)
        end
    end

    return TrivialEGOGiftFilter
end

function applyFilter(::Type{EGOGift}, EGOGiftList, pFilter)
    N = length(EGOGiftList)
    newList = EGOGift[]

    for myEGOGift in EGOGiftList
        if pFilter.fn(myEGOGift)
            push!(newList, myEGOGift)
        end
    end

    if length(newList) < N
        return newList, pFilter.description
    else
        return newList, ""
    end
end

# Printing and Searching

function printSingle(myEGOGift :: EGOGift, verbose)
    println(toString(myEGOGift; verbose = verbose))
end

function printRandom(::Type{EGOGift}, verbose)
    Ans = rand(getMasterList(EGOGift))
    printSingle(Ans, verbose)
    return Ans
end

function searchSingleEGOGift(query, haystack, verbose)
    print("Using $(@red(query)) as query")
    println(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, verbose)
    return result
end

function searchTopEGOGift(query, haystack, topN)
    println("Using $(@red(query)) as query. The $topN closest E.G.O Gifts are:")
    result = SearchClosestString(query, haystack; top = topN)
    resultEGOGift = [x[2] for x in result]

    return printFromEGOGiftList(resultEGOGift)
end

EGOGiftPreviousSearchResult = EGOGift[]
function printFromEGOGiftList(list)
    global EGOGiftPreviousSearchResult = copy(list)

    if length(EGOGiftPreviousSearchResult) == 0
        println("No results found.")
        return EGOGiftPreviousSearchResult
    end

    ResultStrings = String[]
    for myEGOGift in list
        push!(ResultStrings, getTitle(myEGOGift))
    end

    print(GridFromList(ResultStrings, 1; labelled = true))
    return EGOGiftPreviousSearchResult
end

function printAllEGOGift(list)
    println("E.G.O. Gifts that match the filters:")
    return printFromEGOGiftList(list)
end

function printJSONList(::Type{EGOGift})
    println("Listing the contents of $(join(getMasterFileClasses(EGOGift), ", ")): ")
    JSONList = getMasterFileList(EGOGift)
    println(GridFromList(JSONList, 2; labelled = true))
    return JSONList
end

function printEGOGiftExactNumberInput(num, verbose)
    global EGOGiftPreviousSearchResult
    if length(EGOGiftPreviousSearchResult) == 0
        @info "No previously search `ego-gift list`."
        return ""
    end


    N = parse(Int, num)

    if !(1 ≤ N ≤ length(EGOGiftPreviousSearchResult))
        @info "There are only $(length(EGOGiftPreviousSearchResult)) E.G.O. Gifts. You asked for the $N-th entry."
        return ""
    end

    return printSingle(EGOGiftPreviousSearchResult[N], verbose)
end