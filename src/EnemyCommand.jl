function EnemyHelp()
    # TODO: Show some example usage of enemies.
    S = raw"""Looks up enemies. Available Commands:
              `enemy list jsons`         - List all internal JSONs.
              `enemy list _bundle.json_` - List all enemies in _bundle.json_. (*)
              `enemy _query_ _flags_`    - Looks up _query_.

              Available Flags:
              !v/!verbose  - Outputs the internal additional fields.
              !top_num_    - Outputs the top _num_ enemies matching the query. Default is 5. (*)
              !i/!internal - Only performs the query on internal enemy names.
              !s/!succint  - Only show the main Enemy panel. You can also !hide-skills, !hide-passives.
              [_filter_]   - Filter the list of enemies.

              After (*), `enemy _number_` will directly output the corresponding enemy.
              To see available filters, use `enemy filters help`.
              Example usage:

        """

    println(S)
    return S
end

function FilterHelp(::Type{EnemyUnit})
    # Future way could be to filter based on origin and/or locations of enemies.

    S = raw"""Filters reduce the search space.
              There are no available filters as of now.
        """
    
    println(S)
    return S
end

function EnemyParser(input)
    S = match(r"^filters? help$", input)
    (S !== nothing) && return FilterHelp(EnemyUnit)

    S = match(r"^list jsons?$", input)
    (S !== nothing) && return printJSONList(EnemyUnit)

    if match(r"list all", input) !== nothing
        println("Do you mean: `enemy !all`?")
    end

    S = match(r"^list (.*)$", input)
    (S !== nothing) && return printEnemyFromJSON(S.captures[1])

    S = match(r"^!rand$", input)
    (S !== nothing) && return printRandom(EnemyUnit, false)
    S = match(r"^(!rand ![vV](erbose)?)|(![vV](erbose)? !rand)$", input)
    (S !== nothing) && return printRandom(EnemyUnit, true)

    TopNumber = 1
    UseInternalIDs = false
    Verbose = false
    PrintAll = false
    EnemySearchList = EnemyUnit[]
    pFilters = Filter{EnemyUnit}[]
    ExactNumber = true
    ShowSkills = true
    ShowPassives = true
    Level = 10

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI]nternal$"] = (x) -> (UseInternalIDs = true; ExactNumber = false)
    Applications[r"^![tT]op$"] = (x) -> (TopNumber = 1; ExactNumber = false)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x); ExactNumber = false)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true; ExactNumber = false)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![lL]vl([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![lL]evel([0-9]+)$"] = (x) -> (Level = parse(Int, x))
    Applications[r"^![sS](uccint)?$"] = (_) -> (ShowSkills = false; ShowPassives = false)
    Applications[r"^![hH]ide-?[pP](assives?)?$"] = (_) -> (ShowPassives = false)
    Applications[r"^![hH]ide-?[sS](kills?)?$"] = (_) -> (ShowSkills = false)
    Applications[r"^\[(.*)\]$"] = (x) -> (push!(pFilters, constructGeneralFilter(Personality, x)); ExactNumber = false)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    S = match(r"^([0-9]+)$", newQuery)
    if S !== nothing && ExactNumber
        return printEnemyExactNumberInput(newQuery, Tier, Level, Verbose; showSkills = ShowSkills, showPassives = ShowPassives)
    end
    
    (length(EnemySearchList) == 0) && (EnemySearchList = getMasterList(EnemyUnit))

    for currFilter in pFilters
        Tmp = ""
        EnemySearchList, Tmp = applyFilter(EnemySearchList, currFilter, Level, Tier)
        if Tmp != ""
            println(Tmp)
        end
    end

    PrintAll && return printAllEnemy(EnemySearchList, Level)
    length(EnemySearchList) == 0 && return PrintAllEnemy(EnemySearchList, Level)

    HaystackEnemies = []
    for enemy in EnemySearchList
        if UseInternalIDs
            push!(HaystackEnemies, (getStringID(enemy), enemy))
        else
            if hasLocalizedVersion(enemy)
                push!(HaystackEnemies, (getName(enemy), enemy))
            end
        end
    end

    TopNumber == 1 && return searchSingleEnemy(newQuery, HaystackEnemies, Level, 
                                               Verbose; showSkills = ShowSkills, showPassives = ShowPassives)
    return searchTopEnemy(newQuery, HaystackEnemies, TopNumber, Level)
end

EnemyRegex = r"^[eE]nemy (.*)$"
EnemyCommand = Command(EnemyRegex, EnemyParser, [1], EnemyHelp)

# Filters
function constructFilter(::Type{EnemyUnit}, input)
    return TrivialFilter(Enemy)
end

# Printing and Searching
function printSingle(enemy :: EnemyUnit, level, verbose; showSkills = true, showPassives = true)
    println(getFullPanel(enemy, level; verbose = verbose, showSkills = showSkills, showPassives = showPassives))
    return enemy
end

function printRandom(::Type{EnemyUnit}, verbose)
    randEnemy = rand(getMasterList(EnemyUnit))
    printSingle(randEnemy, getRawLevel(randEnemy), verbose)
    return randEnemy
end

function searchSingleEnemy(query, haystack, level, verbose; showSkills = true, showPassives = true)
    print("Using $(@red(query)) as query")
    AddParams = String[]

    length(AddParams) > 0 && print(" with $(join(AddParams, "; "))")
    println(".")

    result = SearchClosestString(query, haystack)[1][2]
    printSingle(result, level, verbose; showSkills = showSkills, showPassives = showPassives)
    return result
end

function searchTopEnemy(query, haystack, topN, level)
    println("Using $(@red(query)) as query. The $topN closest enemies are:")
    result = SearchClosestString(query, haystack; top = topN)
    resultEnemy = [x[2] for x in result]

    return printFromEnemyList(resultEnemy, level)
end

function printFromEnemyList(list, level::Int)
    return printFromEnemyList(list, repeat([level], length(list)))
end

function printFromEnemyList(list, level::Vector{Int})
    if length(list) != length(level)
        @info "Error: Enemy List and Level List needs to be of the same length."
    end
end