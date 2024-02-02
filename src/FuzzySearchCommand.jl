function FuzzySearchHelp()
    S = raw"""Fuzzy Searches. Available Commands:
        - search news     : Past Steam news articles.
        - search story    : Localized story content.
        - search static   : Static Data Folder
        - search localize : Localized Folder
        """

    println(S)
    return S
end

function FuzzySearchParser(input)
    lowercase(input) == "news" && return searchNews()
    lowercase(input) == "story" && return searchStory()
    lowercase(input) == "static" && return searchStatic()
    S = match(r"^locali[zs]ed?$", lowercase(input))
    (S !== nothing) && return searchLocalize()

    @info "Unable to parse $input (try `search help`)"
    return
end

FuzzySearchRegex = r"^[sS]earch (.+)$"
FuzzySearchCommand = Command(FuzzySearchRegex, FuzzySearchParser, [1], FuzzySearchHelp)