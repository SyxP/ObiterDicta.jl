# Passive Command

function PassiveHelp()
    S = raw"""Look up Passives. Available Commands:
              `passive _query_ _flags`  - Looks up _query_.
              `passive _num_`           - Outputs the _num_-th option of a !topn query.

              Note that passives internal IDs are numbers, to search for id 31415
              `passive !i 31415`
    
              Available Flags:
              !i/!internal - Only perform the query on internal IDs.
              !text        - Searches through the description of the Passive.              
              !top_num_    - Outputs the top _num_ passives matching the query. Default is 5.      
        """
    println(S)
end
#TODO: Given a passive -> Look up its owner

function PassiveParser(input)
    if match(r"^!rand(om)?$", input) !== nothing 
        return printRandomPassive()
    elseif match(r"^[0-9]+$", input) !== nothing
        return printPassiveExactNumberInput(input)
    end

    TopNumber = 1
    UseInternalIDs = false
    UseTexts = false
    PassiveSearchList = Passive[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![tT]ext$"] = () -> (UseTexts = true)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(PassiveSearchList) == 0) && (PassiveSearchList = getMasterList(Passive))
    HaystackPassives = [] 
    for myPass in PassiveSearchList
        if UseInternalIDs
            push!(HaystackPassives, (getStringID(myPass), myPass))
        elseif UseTexts
            S = getEscapedDesc(myPass)
            if S !== nothing
                push!(HaystackPassives, (S, myPass))
            end
        else
            if hasLocalizedVersion(myPass)
                push!(HaystackPassives, (getName(myPass), myPass))
            end
        end
    end
        
    TopNumber == 1 && return searchSinglePassive(newQuery, HaystackPassives)    
    return searchTopPassives(newQuery, HaystackPassives, TopNumber; searchText = UseTexts)
    
    @info "Unable to parse $input (try `passive help`)"
    return
end

PassiveRegex = r"^passive (.*)$"
PassiveCommand = Command(PassiveRegex, PassiveParser, [1], PassiveHelp)

# Printing and Searching

printSinglePassive(id :: Passive) = println(toString(id))

function printRandomPassive()
    myPass = rand(getMasterList(Passive))
    printSinglePassive(myPass)
    return myPass
end

function searchSinglePassive(query, haystack)
    println("Using $(@red(query)) as query.")
    result = SearchClosestString(query, haystack)[1][2]
    printSinglePassive(result)
    return result
end

PassivePreviousSearchResult = Passive[]
function searchTopPassives(query, haystack, topN; searchText = false)
    println("Using $(@red(query)) as query. The $topN closest Buffs are:")
    result = SearchClosestString(query, haystack; top = topN)
    ResultStrings = String[]

    global PassivePreviousSearchResult
    empty!(PassivePreviousSearchResult)

    for (target, myPass) in result
        push!(PassivePreviousSearchResult, myPass)
        id = getStringID(myPass)
        if searchText
            lengthCutoff = 80
            prefix = target[begin:min(lengthCutoff, end)] 
            (length(target) > lengthCutoff) && (prefix *= "...")
            passName = getName(myPass)

            push!(ResultStrings, "$passName ($(@dim(prefix)))")
        elseif target == id
            push!(ResultStrings, target)
        else
            push!(ResultStrings, "$target ("* @dim(id) * ")")
        end
    end
    
    println(GridFromList(ResultStrings, 1; labelled = true))
    return result
end

function printPassiveExactNumberInput(input)
    N = parse(Int, input)

    global PassivePreviousSearchResult
    if !(1 ≤ N ≤ length(PassivePreviousSearchResult))
        @info "There are only $(length(PassivePreviousSearchResult)) passives in your previous search. You asked for the $N-th entry."
        return -1
    end

    printSinglePassive(PassivePreviousSearchResult[N])
    return PassivePreviousSearchResult[N]
end