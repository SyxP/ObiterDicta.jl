# Combat Skill Command

function SkillHelp()
    S = raw"""Looks up Skills. Available Commands:
              `skill list jsons`         - List all internal JSONs.
              `skill list all`           - List all skills. (*)
              `skill list _bundle.json_` - List all skills in _bundle.json_. (*)
              `skill _query_ _flags`     - Looks up _query_.

              Available Flags:
              !v/!verbose  - Outputs the internal additional fields.
              !top_num_    - Outputs the top _num_ skills matching the query. Default is 5. (*)
              !i/!internal - Only performs the query on internal skill names.
              !tier_num_   - Sets the tier at _num_. Without this, it is set to the maximum possible.
              !olvl_num_   - Sets the offense level at _num_.
              !offenselevel/!offenselvl/!olevel are all equivalent.

              After (*), `skill _number_` will directly output the corresponding buff.
              Example usage:
              `skill qs !tier3 !v`  - Searches Quick Suppresion at Tier 3 w/ Internal Data
              `skill !i 1010101`    - Searches for internal skill with ID 1010101
        """

    println(S)
    return S
end

function SkillParser(input)
    S = match(r"list jsons?$", input)
    (S !== nothing) && return printJSONList(CombatSkill)

    S = match(r"list all$", input)
    (S !== nothing) && return printMasterList(CombatSkill)

    S = match(r"list (.*)$", input)
    (S !== nothing) && return printSkillFromJSON(S.captures[1])

    S = match(r"^([0-9]+)$", input)
    if S !== nothing
        return printSkillExactNumberInput(S.captures[1], false)
    end

    S = match(r"^([0-9]+) +![vV](erbose)?$", input)
    if S !== nothing
        return printSkillExactNumberInput(S.captures[1], true)
    end
    S = match(r"^![vV](erbose)? ([0-9]+)$", input)
    if S !== nothing
        return printSkillExactNumberInput(S.captures[2], true)
    end

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(CombatSkill, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(CombatSkill, true)

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    SkillSearchList = CombatSkill[]
    Tier = 999
    OffenseLevel = -1

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![tT]ier([0-9]+)$"] = (x) -> (Tier = parse(Int, x))
    Applications[r"^![oO](ffense)?(level|lvl)([0-9]+)$"] = (_, _, x) -> (OffenseLevel = parse(Int, x))

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(SkillSearchList) == 0) && (SkillSearchList = getMasterList(CombatSkill))

    HaystackSkills = []
    for mySkill in SkillSearchList
        if UseInternalIDs
            push!(HaystackSkills, (getStringID(mySkill), mySkill))
        else
            if hasLocalizedVersion(mySkill)
                push!(HaystackSkills, (getName(mySkill), mySkill))
            end

            # Add custom search strings (qs -> "quick suppresion")
        end
    end

    TopNumber == 1 && return searchSingleSkill(newQuery, HaystackSkills, Tier, OffenseLevel, Verbose)
    return searchTopSkills(newQuery, HaystackSkills, TopNumber, Tier)
end

SkillRegex = r"^skill (.*)$"
SkillCommand = Command(SkillRegex, SkillParser, [1], SkillHelp)

# Printing and Searching

printSingle(skill :: CombatSkill, tier, offenseLevel, verbose) = 
    tprintln(InternalSkillPanel(skill, tier, offenseLevel; verbose = verbose))

printRandom(::Type{CombatSkill}, verbose) = 
    printSingle(rand(getMasterList(CombatSkill)), rand(1:4), -1, verbose)

function searchSingleSkill(query, haystack, tier, offenseLevel, verbose)
    tprint("Using {red}$query{/red} as query")
    AddParams = String[]
    tier !== 999 && push!(AddParams, "Tier: {red}$tier{red}")
    offenseLevel != -1 && push!(AddParams, "OLvl: {red}$offenseLevel{/red}")

    length(AddParams) > 0 && tprint(" with $(join(AddParams, "; "))")
    tprintln(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, tier, offenseLevel, verbose)
    return result
end

function searchTopSkills(query, haystack, topN, tier) 
    tprint("Using {red}$query{/red} as query")
    AddParams = String[]
    tier !== 999 && push!(AddParams, "Tier: {red}$tier{red}")

    length(AddParams) > 0 && tprint(" with $(join(AddParams, "; "))")
    tprintln(".")
    tprintln("The $topN closest skills are:")
    result = SearchClosestString(query, haystack; top = topN)

    ResultStrings = String[]
    global SkillPreviousSearchResult
    empty!(SkillPreviousSearchResult)

    for (_, buff) in result
        push!(SkillPreviousSearchResult, buff)
        push!(ResultStrings, getPrintTitle(buff, tier))
    end

    println(GridFromList(ResultStrings, 3; labelled = true))
    return result
end

function printJSONList(::Type{CombatSkill})
    println("Listing the contents of $(join(getMasterFileClasses(CombatSkill), ", ")): ")
    JSONList = getMasterFileList(CombatSkill)
    println(GridFromList(JSONList, 2; labelled = true))
    return JSONList
end

SkillPreviousSearchResult = CombatSkill[]

function printSkillFromJSONInternal(file)
    SkillDatabase = StaticData(file)["list"]
    Names = [CombatSkill(s["id"]) for s in SkillDatabase]
    global SkillPreviousSearchResult = Names

    tprintln("Listing the skills in {yellow}$file{/yellow}:")
    println(GridFromList(getPrintTitle.(Names), 4; labelled = true))
    return Names
end

function printMasterList(::Type{CombatSkill})
    Names = getMasterList(CombatSkill)
    global SkillPreviousSearchResult = copy(Names)
    
    tprintln("Listing all the skills:")
    println(GridFromList(getPrintTitle.(Names), 3; labelled = true))
    return Names
end

function printSkillFromJSON(input)
    JSONList = getMasterFileList(CombatSkill)
    if match(r"^[0-9]+$", input) !== nothing
        val = parse(Int, input)
        return printSkillFromJSONInternal(JSONList[val])
    end

    newInput = split(input, ".")[begin]
    result = SearchClosestString(newInput, [[x] for x in JSONList])
    return printSkillFromJSONInternal(result[begin][begin])
end

function printSkillExactNumberInput(num, verbose)
    global SkillPreviousSearchResult
    if length(SkillPreviousSearchResult) == 0
        @info "No previously search `skill list`."
        return ""
    end

    N = parse(Int, num)
    
    if !(1 ≤ N ≤ length(SkillPreviousSearchResult))
        @info "There are only $(length(SkillPreviousSearchResult)) skills in your previous search. You asked for the $N-th entry."
        return -1
    end

    return printSingle(SkillPreviousSearchResult[N], 999, -1, verbose)
end