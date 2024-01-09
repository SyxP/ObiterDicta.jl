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
    pFilters = Filter{EGOGift}[]
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
    Applications[r"\[(.*)\]$"] = (x) -> (push!(pFilters, constructGeneralFilter(EGOGift, x)); ExactNumber = false)
    
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
        EGOGiftSearchList, Tmp = applyFilter(EGOGiftSearchList, currFilter)
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
function EGOGiftTierFilter(tier)
    tierNum = tryparse(Int, tier)
    tierNum === nothing && return TrivialFilter(EGOGift)

    function Fn(x)
        getTier(x) === nothing && return false
        return getTier(x) == tierNum
    end
    newDesc = "Filter: E.G.O Gift has tier $(@red(tier))"
    return Filter{EGOGift}(Fn, newDesc)
end

function EGOGiftCostFilter(cost, op)
    compareN = tryparse(Int, cost)
    compareN === nothing && return TrivialFilter(EGOGift)
    (op == "<=") && (op = "≤")
    (op == ">=") && (op = "≥")

    function Fn(x)
        getPrice(x) === nothing && return false
        return CompareNumbers(getPrice(x), compareN, op)
    end
    newDesc = "Filter: E.G.O Gift costs $(@blue(op))$(@red(cost))"
    return Filter{EGOGift}(Fn, newDesc)
end

function EGOGiftAttributeFilter(sin)
    sinStr = getClosestSinFromName(sin)
    sinStr === nothing && return TrivialFilter(EGOGift)
    
    function Fn(x)
        getAttributeType(x) === nothing && return false
        return getAttributeType(x) == sinStr
    end
    newDesc = "Filter: E.G.O Gift has attribute $(getSinString(sinStr)) (Input: $(@dim(sin)))"
    return Filter{EGOGift}(Fn, newDesc)
end

function EGOGiftTagFilter(tag)
    newTag = superNormString(tag)
    newTag = replace(newTag, " " => "", "_" => "")

    function Fn(x)
        getTag(x) === nothing && return false
        Lst = [superNormString(x) for x in getTag(x)]
        normLst = [replace(x, " " => "", "_" => "") for x in Lst]
        return newTag ∈ normLst
    end
    newDesc = "Filter: E.G.O Gift has tag $(@red(tag))"
    return Filter{EGOGift}(Fn, newDesc)
end

function EGOGiftKeywordFilter(buff)
    io = Pipe()
    foundBuff = nothing
    redirect_stdout(io) do
        foundBuff = BuffParser(buff)
    end
    close(io)

    foundBuff === nothing && return TrivialFilter(EGOGift)
    if foundBuff isa Vector
        length(foundBuff) == 0 && return TrivialFilter(EGOGift)
        foundBuff = foundBuff[1]
    end

    function Fn(x)
        getKeyword(x) === nothing && return false
        return getKeyword(x) == getID(foundBuff)
    end
    Desc = "Filter: E.G.O Gift has keyword $(@red(getName(foundBuff))) (Input: $(@dim(buff)))"
    return Filter{EGOGift}(Fn, Desc)
end

function EGOGiftNoKeywordFilter()
    function Fn(x)
        S = getKeyword(x)
        S === nothing && return true
        S == "" && return true
        return false
    end
    newDesc = "Filter: E.G.O Gift has no keyword"
    return Filter{EGOGift}(Fn, newDesc) 
end

function EGOGiftNoTierFilter()
    function Fn(x)
        getTier(x) === nothing && return true
        getTier(x) == -1 && return true
        return false
    end
    newDesc = "Filter: E.G.O Gift has no tier"
    return Filter{EGOGift}(Fn, newDesc)
end

function EGOGiftCanUpgradeFilter()
    newDesc = "Filter: E.G.O Gift can be upgraded"
    return Filter{EGOGift}(hasUpgrade, newDesc)
end

function constructFilter(::Type{EGOGift}, input)
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

    return TrivialFilter(EGOGift)
end

# Printing and Searching

function printSingle(myEGOGift :: EGOGift, verbose)
    println(toString(myEGOGift; verbose = verbose))
    return myEGOGift
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
        @info "No previously searched `ego-gift list`."
        return ""
    end

    N = parse(Int, num)

    if !(1 ≤ N ≤ length(EGOGiftPreviousSearchResult))
        @info "There are only $(length(EGOGiftPreviousSearchResult)) E.G.O. Gifts. You asked for the $N-th entry."
        return ""
    end

    return printSingle(EGOGiftPreviousSearchResult[N], verbose)
end