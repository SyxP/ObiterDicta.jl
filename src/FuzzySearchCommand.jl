function FuzzySearchHelp()
    S = raw"""Fuzzy Searches. Available Commands:
              - search news : Looks through past news articles.
        """

    println(S)
    return S
end

function FuzzySearchParser(input)
    lowercase(input) == "news" && return searchNews()

    @info "Unable to parse $input (try `search help`)"
    return
end

FuzzySearchRegex = r"^[sS]earch (.+)$"
FuzzySearchCommand = Command(FuzzySearchRegex, FuzzySearchParser, [1], FuzzySearchHelp)