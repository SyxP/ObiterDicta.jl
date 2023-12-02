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
    S = "Currently being worked on." ## TODO

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

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(PersonalitySearchList) == 0) && (PersonalitySearchList = getMasterList(Personality))
    
    PrintAll && return printAllPersonality(PersonalitySearchList, Tier)
    
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
    
    ResultStrings = String[]
    for myID in list
        push!(ResultStrings, getFullTitle(myID))
    end

    println(GridFromList(ResultStrings, 1; labelled = true))
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