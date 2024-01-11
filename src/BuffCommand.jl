# Buff Command

function BuffHelp()
    S = raw"""Looks up Buffs (Status Effects). Available Commands:
              `buff list jsons`         - List all internal JSONs.
              `buff list all`           - List all buffs. (*)
              `buff list _bundle.json_` - List all buffs in _bundle.json_. (*)
              `buff _query_ _flags_`    - Looks up _query_. 
              
              Available Flags:
              !v/!verbose  - Outputs the internal buff data.
              !top_num_    - Outputs the top _num_ buffs matching the query. Default is 5. (*)
              !i/!internal - Only performs the query on internal buff names.
              !a/!all      - Outputs all buffs matching the filters.
              !rand        - Outputs a random buff.
              [_filter_]   - Filter the list of buffs.
              
              After (*), `buff _number_` will directly output the corresponding buff.
              To see available filters, use `buff filters help`.
              For panic and buffs pertaining specific game modes, look in the corresponding commands.
              Example usage:
              `buff bleed !top` - Outputs the top 5 bleed buffs.
              `buff eviscerate !i !v`  - Outputs the internal buff Eviscerate and its internal fields.
        """
    println(S)
end

function FilterHelp(::Type{Buff})
    S = raw"""Filters reduce the search space.
              Available Filters:
              [sin:_type_]    - Buff is of sin _type_
              [keyword:_tag_] - Buff has keyword _tag_
              [tag:_tag_]     - Buff has tag _tag_
        """

        # To implement: Positive vs Negative Buffs
        # Max Stacks Filter

    println(S)
    return S
end

function BuffParser(input)
    S = match(r"^filters? help$", input)
    (S !== nothing) && return FilterHelp(Buff)

    S = match(r"list jsons?$", input)
    (S !== nothing) && return printJSONList(Buff)
    S = match(r"^list all$", input)
    (S !== nothing) && return printMasterList(Buff)
    S = match(r"list (.*)$", input)
    (S !== nothing) && return printFromJSON(Buff, S.captures[1])

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(Buff, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(Buff, true)

    S = match(r"^([0-9]+)$", input)
    if S !== nothing
        return printExactNumberInput(Buff, S.captures[1])
    end

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    BuffSearchList = Buff[]
    PrintAll = false
    pFilters = Filter{Buff}[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true)
    Applications[r"^\[(.*)\]$"] = (x) -> (push!(pFilters, constructGeneralFilter(Buff, x)))

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(BuffSearchList) == 0) && (BuffSearchList = getMasterList(Buff))

    for currFilter in pFilters
        Tmp = ""
        BuffSearchList, Tmp = applyFilter(BuffSearchList, currFilter)
        Tmp != "" && println(Tmp)
    end

    PrintAll && return printAll(Buff, BuffSearchList)
    length(BuffSearchList) == 0 && return printAll(Buff, BuffSearchList)

    HaystackBuffs = []
    for buff in BuffSearchList
        id = getID(buff)
        if UseInternalIDs
            push!(HaystackBuffs, (id, buff))
        else
            if hasLocalizedVersion(buff)
                push!(HaystackBuffs, (getName(buff), buff))
            end
        end
    end
    
    TopNumber == 1 && return searchSingle(Buff, newQuery, HaystackBuffs; verbose = Verbose)
    return searchTop(Buff, newQuery, HaystackBuffs, TopNumber)

    @info "Unable to parse $input (try `buff help`)"
    return
end

BuffRegex = r"^buff (.*)$"
BuffCommand = Command(BuffRegex, BuffParser, [1], BuffHelp)

function buffKeywordFilter(keyword)
    io = Pipe()
    foundBuff = nothing
    redirect_stdout(io) do
        foundBuff = BuffParser(keyword)
    end
    close(io)

    foundBuff === nothing && return TrivialFilter(Buff)
    if foundBuff isa Vector
        length(foundBuff) == 0 && return TrivialFilter(Buff)
        foundBuff = foundBuff[1]
    end

    function Fn(x)
        getKeywordList(x) === nothing && return false
        return uppercase(getID(foundBuff)) ∈ getKeywordList(x)
    end
    Desc = "Filter: Buff has keyword $(@red(getID(foundBuff))) (Input: $(@dim(keyword)))"
    return Filter{Buff}(Fn, Desc)
end

function buffTagFilter(tag)
    function Fn(x)
        getKeywordList(x) === nothing && return false
        return uppercase(tag) ∈ getKeywordList(x)
    end
    Desc = "Filter: Buff has tag $(@red(tag))"
    return Filter{Buff}(Fn, Desc)
end

function buffSinFilter(sinQuery)
    internalSin = getClosestSinFromName(sinQuery)
    function Fn(x)
        return getAttributeType(x) == internalSin
    end

    Desc = "Filter: Buff is of attribute $(getSinString(internalSin)) (Input: $(@red(sinQuery)))"
    return Filter{Buff}(Fn, Desc)
end

function constructFilter(::Type{Buff}, input)
    for (myRegex, filterFn, params) in [
        (r"^[sS]in:(.*)$", buffSinFilter, [1]),
        (r"^[kK]eyword:(.*)$", buffKeywordFilter, [1]),
        (r"^[tT]ag:(.*)$", buffTagFilter, [1]),
    ]
        S = match(myRegex, input)
        if S !== nothing
            stringParams = [string(S.captures[i]) for i in params]
            return filterFn(stringParams...)
        end
    end

    return TrivialFilter(Buff)
end

# Printing and Searching

printSingle(id :: Buff) = println(toString(id))
printLocalized(id :: Buff) = println(LocalizedBuffPanel(id))
function printRandom(::Type{Buff}, verbose)
    Ans = rand(getMasterList(Buff))
    verbose ? printSingle(Ans) : printLocalized(Ans)
    return Ans
end

function searchSingle(::Type{Buff}, query, haystack; verbose = true)
    println("Using $(@red(query)) as query.")
    result = SearchClosestString(query, haystack)[1][2]
    verbose ? printSingle(result) : printLocalized(result)
    return result
end

function searchTop(::Type{Buff}, query, haystack, topN)
    println("Using $(@red(query)) as query. The $topN closest Buffs are:")
    result = SearchClosestString(query, haystack; top = topN)
    
    ResultStrings = String[]
    SearchResult = Buff[]
    for (target, buff) in result
        push!(SearchResult, buff)
        id = string(getID(buff))
        if target == id 
            push!(ResultStrings, target)
        else
            push!(ResultStrings, "$target ("* @dim(id) * ")")
        end
    end
    
    setPreviousSearch(Buff, SearchResult)
    println(GridFromList(ResultStrings, 1; labelled = true))
    return result
end

function printJSONList(::Type{Buff})
    println("Listing the contents of $(join(getMasterFileClasses(Buff), ", ")): ")
    JSONList = getMasterFileList(Buff)
    println(GridFromList(JSONList, 2; labelled = true))
    return JSONList
end

function printAll(::Type{Buff}, buffList)
    println("Buffs that match the filters:")
    return printList(Buff, buffList)
end

function printList(::Type{Buff}, List)
    setPreviousSearch(Buff, List)
    if length(List) > 0
        println(GridFromList(getTitle.(List), 2; labelled = true))
    else
        println("No buffs match the filters.")
    end

    return getCopyPreviousSearch(Buff)
end

function printFromJSONInternal(::Type{Buff}, file)
    BuffDatabase = StaticData(file)["list"]
    Names = [Buff(buff["id"]) for buff in BuffDatabase]
    
    println("Listing the buffs in $(@yellow(file)): ")
    return printList(Buff, Names)
end

function printMasterList(::Type{Buff})
    Names = getMasterList(Buff)

    println("Listing all the buffs: ")
    return printList(Buff, Names)
end

function printFromJSON(::Type{Buff}, input)
    JSONList = getMasterFileList(Buff)
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printFromJSONInternal(Buff, JSONList[val])
    end

    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printFromJSONInternal(Buff, result[begin][begin])
end

function printExactNumberInput(::Type{Buff}, num)
    BuffPreviousSearchResult = getCopyPreviousSearch(Buff)
    if length(BuffPreviousSearchResult) == 0
        @info "No previously searched `buff list`."
        return ""
    end

    N = parse(Int, num)

    if !(1 ≤ N ≤ length(BuffPreviousSearchResult))
        @info "There are only $(length(BuffPreviousSearchResult)) buffs. You asked for the $N-th entry."
        return ""
    end

    return printSingle(BuffPreviousSearchResult[N])
end