function BannerGreetingsHelp()
    S = raw"""Look up banner greetings. Available Commands:
              `banner greeting list words`       - List all word greetings.
              `banner greeting list sentences`   - List all sentence greetings.
              `banner greeting _query_`          - Looks up _query_ in a word greeting.

              Available Flags:
              !top_num_    - Outputs the top _num_ greetings matching the query. Default is 5.
              !i/!internal - Only perform the query on unlock condition.
              !sentence    - Searches through the added sentence instead of the added word.
        """

    println(S)
end

function BannerGreetingsParser(input)
    if match(r"^list words$", input) !== nothing
        return printMasterWordList(Greeting)
    elseif match(r"^list sentences$", input) !== nothing
        return printMasterSentenceList(Greeting)
    elseif match(r"^!rand$", input) !== nothing
        return printRandom(Greeting)
    elseif match(r"^[0-9]+$", input) !== nothing
        return printGreetingExactNumberInput(input)
    end

    TopNumber = 1
    UseInternalIDs = false
    UseSentence = false
    BannerSearchList = Greeting[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![tT]op$"] = () -> (TopNumber = 5)
    Applications[r"^![tT]op([0-9]+)$"] = (x) -> (TopNumber = parse(Int, x))
    Applications[r"^![sS]entence$"] = () -> (UseSentence = true)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    (length(BannerSearchList) == 0) && (BannerSearchList = getMasterList(Greeting))

    HaystackBannerGreetings = []
    for myBanner in BannerSearchList
        if UseInternalIDs
            push!(HaystackBannerGreetings, (getStringOwner(myBanner), myBanner))
        else
            if UseSentence
                push!(HaystackBannerGreetings, (getSentenceContent(myBanner), myBanner))
            else
                push!(HaystackBannerGreetings, (getWordContent(myBanner), myBanner))
            end
        end
    end

    TopNumber == 1 && return searchSingleBannerGreeting(newQuery, HaystackBannerGreetings, TopNumber)
    return searchTopBannerGreeting(newQuery, HaystackBannerGreetings, TopNumber)

    @info "Unable to parse $input (try `banner greeting help`)"
    return
end

BannerGreetingsRegex = r"^banner greeting (.*)$"
BannerGreetingsCommand = Command(BannerGreetingsRegex, BannerGreetingsParser, [1], BannerGreetingsHelp)

printSingleBannerGreeting(greet :: Greeting) = println(toString(greet))

function printRandom(::Type{Greeting})
    S = getRandomCombination(Greeting)
    println(S)
    return
end

function searchSingleBannerGreeting(query, haystack, TopNumber)
    println("Using $(@red(query)) as query.")
    result = SearchClosestString(query, haystack)[1][2]
    printSingleBannerGreeting(result)
    return result
end

global BannerPreviousSearchResult = Greeting[]
function searchTopBannerGreeting(query, haystack, TopNumber)
    println("Using $(@red(query)) as query. The $TopNumber closest Banner Greetings are:")
    result = SearchClosestString(query, haystack; top = TopNumber)

    ResultStrings = String[]
    global BannerPreviousSearchResult
    empty!(BannerPreviousSearchResult)

    for (target, greet) in result
        push!(BannerPreviousSearchResult, greet)
        push!(ResultStrings, getPrintTitle(greet))
    end

    println(GridFromList(ResultStrings, 1; labelled = true))
    return result
end

function printMasterWordList(::Type{Greeting})
    println("Listing the contents of $(join(getMasterFileClasses(Greeting), ", ")): ")
    Names = getMasterList(Greeting)
    global BannerPreviousSearchResult = deepcopy(Names)
    println(GridFromList(getWordContent.(Names), 4; labelled = true))
    return Names
end

function printMasterSentenceList(::Type{Greeting})
    println("Listing the contents of $(join(getMasterFileClasses(Greeting), ", ")): ")
    Names = getMasterList(Greeting)
    global BannerPreviousSearchResult = deepcopy(Names)
    println(GridFromList(getSentenceContent.(Names), 1; labelled = true))
    return Names
end


function printGreetingExactNumberInput(input)
    N = parse(Int, input)

    global BannerPreviousSearchResult
    if !(1 ≤ N ≤ length(BannerPreviousSearchResult))
        @info "There are only $(length(BannerPreviousSearchResult)) Banner Greetings. You asked for the $N-th entry."
        return -1
    end

    printSingleBannerGreeting(BannerPreviousSearchResult[N])
    return BannerPreviousSearchResult[N]
end