function BuffHelp()
    S = raw"""Looks up Buffs (Status Effects). Available Commands
              `buff list jsons`         - List all internal JSONs.
              `buff list all`           - List all buffs. (*)
              `buff list _bundle.json_` - List all buffs in _bundle.json_. (*)
              `buff _query_ _flags_`    - Looks up _query_. 
              
              Available Flags:
              !v/!verbose  - Outputs the internal buff data.
              !top_num_    - Outputs the top _num_ buffs matching the query. Default is 5.
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
    if S !== nothing
        return printBuffJSONList()
    end
    S = match(r"^list all$", input)
    if S !== nothing
        return printBuffMasterList(LastUsedBuffJSON)
    end
    S = match(r"list (.*)$", input)
    if S !== nothing
        return printBuffFromJSON(S.captures[1])
    end

    S = match(r"^([0-9]+)$", input)
    if S !== nothing
        return printBuffExactNumberInput(S.captures[1])
    end

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    BuffSearchList = Dict{String, Any}[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(BuffSearchList) == 0) && (BuffSearchList = getBuffMasterList())
    HaystackBuffs = []
    for Buff in BuffSearchList
        id = Buff["id"]
        if UseInternalIDs
            push!(HaystackBuffs, (id, id))
        else
            S = findExactLocalizedBuff(id; dontWarn = true)
            if S !== nothing
                push!(HaystackBuffs, (S["name"], id))
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

printSingleBuff(id) = println(BuffStringFromId(id))
printLocalizedBuff(id) = println(LocalizedBuffString(id))
function searchSingleBuff(query, haystack; verbose = true)
    tprintln("Using {red}$query{/red} as query.")
    result = SearchClosestString(query, haystack)[1][2]
    verbose ? printSingleBuff(result) : printLocalizedBuff(result)
    return result
end
function searchTopBuffs(query, haystack, topN)
    tprintln("Using {red}$query{/red} as query. The $topN closest Buffs are:")
    result = SearchClosestString(query, haystack; top = topN)
    ResultStrings = String[]
    for (x, y) in result
        if x == y
            push!(ResultStrings, x)
        else
            push!(ResultStrings, "$x ("* @dim(y) * ")")
        end
    end
    println(GridFromList(ResultStrings, 1; labelled = true))
    return result
end
function printBuffJSONList()
    println("Listing the contents of $(join(PossibleDataClasses, ", ")): ")
    JSONList = getBuffJSONListfromStatic()
    println(GridFromList(JSONList, 2; labelled = true))
    return "data/StaticData/static-data/" .* JSONList
end

LastUsedBuffJSON = ""
BuffMasterList = Dict{String, Any}[]

function printBuffFromJSONInternal(file)
    BuffDatabase = StaticData(file)["list"]
    global LastUsedBuffJSON = file
    Names = [Buff["id"] for Buff in BuffDatabase]

    tprintln("Listing the buffs in {yellow}$file{/yellow}: ")
    println(GridFromList(Names, 4; labelled = true))
    return Names
end

function printBuffMasterList(file)
    Names = [Buff["id"] for Buff in getBuffMasterList()]
    global LastUsedBuffJSON = -1

    tprintln("Listing all the buffs: ")
    println(GridFromList(Names, 4; labelled = true))
    return Names
end

function getBuffMasterList()
    forceReload = false
    if DebugMode
        prompt = DefaultPrompt(["yes", "no"], 2, "Would you like to force reload Buff Master List?")
        c = ask(prompt)
        isYesInput(c) && (forceReload = true)
    end

    global BuffMasterList
    !forceReload && length(BuffMasterList) != 0 && return BuffMasterList

    for file in getBuffJSONListfromStatic()
        append!(BuffMasterList, StaticData(file)["list"])
    end
    return BuffMasterList
end

function printBuffFromJSON(input)
    JSONList = getBuffJSONListfromStatic()
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printBuffFromJSONInternal(JSONList[val])
    end
    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printBuffFromJSONInternal(result[begin][begin])
end

function printBuffExactNumberInput(num)
    if LastUsedBuffJSON == ""
        @info "No previously searched `buff list`."
        return ""
    end
    n = parse(Int, num)

    if LastUsedBuffJSON == -1
       if !(1 ≤ n ≤ length(BuffMasterList))
           @info "There are only $(length(BuffMasterList)) buffs. You asked for the $n-th entry."
           return ""
       end

        return printSingleBuff(BuffMasterList[n]["id"])
    end      

    BuffDatabase = StaticData(LastUsedBuffJSON)["list"]
    if !(1 ≤ n ≤ length(BuffDatabase))
        @info "$(@red(LastUsedBuffJSON)) only has $(length(BuffDatabase)) entries. You asked for the $n-th entry."
        return ""
    end
    return printSingleBuff(BuffDatabase[n]["id"])
end

const PossibleDataClasses = ["buff", "mirror-dungeon-floor-buff"]
# TODO: The following Buff types are not supported ["panic-buff", "rail-Line2-buff"]
function getBuffJSONListfromStatic(dataClasses = PossibleDataClasses)
    Files = String[]
    for dataClass in dataClasses
        item = findStaticDataInfo(dataClass)
        for file in item["fileList"]
            push!(Files, "$dataClass/$file")
        end
    end
    unique!(Files)
    return Files
end

function getInternalBuffList()
    [StaticData(file) for file in getBuffJSONListfromStatic()]
end

function getLocalizedBuffList()
    Files = getLocalizeDataInfo()["buf"]
    [LocalizedData(file) for file in Files]
end

function findExactInternalBuff(id)
    for BuffList in getInternalBuffList()
        for Buff in BuffList["list"]
            (Buff["id"] == id) && return Buff
        end
    end
    
    @warn "Internal Buff with $id not found."
    return
end

function getMaxStacks(Buff)
    return haskey(Buff, "maxStack") ? Buff["maxStack"] : 99
end

function getBuffClass(Buff)
    return haskey(Buff, "buffClass") ? Buff["buffClass"] : "No Class"
end

function InternalBuffString(id)
    Buff = findExactInternalBuff(id)
    if Buff === nothing
        return ""
    end
    io = IOBuffer()

    Title = "{red} $(Buff["id"]) {/red} ({blue} $(getBuffClass(Buff)) {/blue}: Max Stacks = $(getMaxStacks(Buff)))"
    TopLine = String[]

    haskey(Buff, "buffType") && (push!(TopLine, "Buff Type => $(Buff["buffType"])"))
    haskey(Buff, "canBeDespelled") && (push!(TopLine, "Can Be Despelled => $(Buff["canBeDespelled"])")) 
    haskey(Buff, "iconId") && (push!(TopLine, "Icon ID => $(Buff["iconId"])"))
    content = GridFromList(TopLine, 3)

    OtherFieldsio = IOBuffer()
    for (key, value) in Buff
        if key ∈ ["buffType", "canBeDespelled", "id", "buffClass", "maxStack", "list", "iconId"]
            continue
        end
        println(OtherFieldsio, "$(key) => $(EscapeString(string(value)))")
    end

    OtherField = String(take!(OtherFieldsio))
    if OtherField != ""
        LineBreak = hLine(93, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherField ; fit = true)
    end

   

    Actions = Buff["list"]
    if length(Actions) > 0
        LineBreak = hLine(94, "{bold white}Actions{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        for (i, Action) in enumerate(Actions)
            content /= DisplaySkillAsTree(Action, "Action $i")
        end
    end
    
    
    output = Panel(
        content,
        title = Title,
        width = 100, 
        fit   = false)
    println(io, output)
    String(take!(io))
end

function findExactLocalizedBuff(id; dontWarn = true)
    for BuffList in getLocalizedBuffList()
        for Buff in BuffList["dataList"]
            (Buff["id"] == id) && return Buff
        end
    end

    dontWarn || @warn "Localized Buff with $id not found."
    return
end

function LocalizedBuffString(id)
    LocalBuff = findExactLocalizedBuff(id)
    if LocalBuff === nothing
        return ""
    end
    
    io = IOBuffer()

    Title = "{red} $(LocalBuff["name"]) {/red} ({blue} $(LocalBuff["id"]) {/blue})"
    contentio = IOBuffer()
    haskey(LocalBuff, "summary") && println(contentio, "{blue}Summary: {/blue}" * EscapeString(LocalBuff["summary"]))
    haskey(LocalBuff, "desc") && println(contentio, "{blue}Description: {/blue}" * EscapeString(LocalBuff["desc"]))
    
    UndefinedFlag = false
    if haskey(LocalBuff, "undefined") && LocalBuff["undefined"] == "-"
        println(contentio, "Has {blue}undefined{/blue} (\"-\") field.")
        UndefinedFlag = true
    end
    content = TextBox(String(take!(contentio)))

    OtherFieldsio = IOBuffer()
    for (key, value) in LocalBuff
        if key ∈ ["name", "summary", "desc", "id"]
            continue
        end
        if key == "undefined" && UndefinedFlag
            continue
        end
        println(OtherFieldsio, "$(key) => $(value)")
    end
    OtherField = String(take!(OtherFieldsio))
    if OtherField != ""
        LineBreak = hLine(93, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherField ; fit = true)
    end
    
    output = Panel(
        content,
        title = Title,
        width = 100, 
        fit   = false)
    println(io, output)

    String(take!(io))
end

BuffStringFromId(id) = LocalizedBuffString(id)*InternalBuffString(id)
