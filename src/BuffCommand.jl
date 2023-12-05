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
              
              After (*), `buff _number_` will directly output the corresponding buff.
              For panic and buffs pertaining specific game modes, look in the corresponding commands.
              Example usage:
              `buff bleed !top` - Outputs the top 5 bleed buffs.
              `buff eviscerate !i !v`  - Outputs the internal buff Eviscerate and its internal fields.
        """
    println(S)
end

function BuffParser(input)
    S = match(r"list jsons?$", input)
    (S !== nothing) && return printJSONList(Buff)
    
    S = match(r"^list all$", input)
    (S !== nothing) && return printMasterList(Buff)
    
    S = match(r"list (.*)$", input)
    (S !== nothing) && return printBuffFromJSON(S.captures[1])

    S = match(r"^([0-9]+)$", input)
    if S !== nothing
        return printBuffExactNumberInput(S.captures[1])
    end

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    BuffSearchList = Buff[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(BuffSearchList) == 0) && (BuffSearchList = getMasterList(Buff))

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
    
    TopNumber == 1 && return searchSingleBuff(newQuery, HaystackBuffs; verbose = Verbose)
    return searchTopBuffs(newQuery, HaystackBuffs, TopNumber)

    @info "Unable to parse $input (try `buff help`)"
    return
end

BuffRegex = r"^buff (.*)$"
BuffCommand = Command(BuffRegex, BuffParser, [1], BuffHelp)

# Printing and Searching

printSingle(id :: Buff) = tprintln(toString(id))
printLocalized(id :: Buff) = tprintln(LocalizedBuffPanel(id))

function searchSingleBuff(query, haystack; verbose = true)
    tprintln("Using {red}$query{/red} as query.")
    result = SearchClosestString(query, haystack)[1][2]
    verbose ? printSingle(result) : printLocalized(result)
    return result
end

function searchTopBuffs(query, haystack, topN)
    tprintln("Using {red}$query{/red} as query. The $topN closest Buffs are:")
    result = SearchClosestString(query, haystack; top = topN)
    
    ResultStrings = String[]
    global BuffPreviousSearchResult
    empty!(BuffPreviousSearchResult)
    
    for (target, buff) in result
        push!(BuffPreviousSearchResult, buff)
        id = string(getID(buff))
        if target == id 
            push!(ResultStrings, target)
        else
            push!(ResultStrings, "$target ("* @dim(id) * ")")
        end
    end
    
    println(GridFromList(ResultStrings, 1; labelled = true))
    return result
end

function printJSONList(::Type{Buff})
    println("Listing the contents of $(join(getMasterFileClasses(Buff), ", ")): ")
    JSONList = getMasterFileList(Buff)
    println(GridFromList(JSONList, 2; labelled = true))
    return JSONList
end

BuffPreviousSearchResult = Buff[]
function printBuffSearchResult(List)
    global BuffPreviousSearchResult
    BuffPreviousSearchResult = copy(List)

    println(GridFromList(getTitle.(List), 2; labelled = true))
    return BuffPreviousSearchResult
end

function printBuffFromJSONInternal(file)
    BuffDatabase = StaticData(file)["list"]
    Names = [Buff(buff["id"]) for buff in BuffDatabase]
    
    tprintln("Listing the buffs in {yellow}$file{/yellow}: ")
    return printBuffSearchResult(Names)
end

function printMasterList(::Type{Buff})
    Names = getMasterList(Buff)

    tprintln("Listing all the buffs: ")
    return printBuffSearchResult(Names)
end

function printBuffFromJSON(input)
    JSONList = getMasterFileList(Buff)
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printBuffFromJSONInternal(JSONList[val])
    end

    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printBuffFromJSONInternal(result[begin][begin])
end

function printBuffExactNumberInput(num)
    global BuffPreviousSearchResult
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