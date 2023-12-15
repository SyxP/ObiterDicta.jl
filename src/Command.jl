struct Command
    CommandName :: Regex
    Fn          :: Function
    Subset      # As the regex command will likely capture multiple groups, 
                # one has to specify the subset to be captured. This is an array of arrays,
                # with each input will result in a call to the function Fn.
    HelpFn      :: Function
end

isHelpRegex = r"^help$|^\?$"
HelpCommand = Command(isHelpRegex, getHelp, [], getHelp)

function CheckCommand(CustomCommand :: Command, Query :: String)
    Matches = match(CustomCommand.CommandName, Query)
    if Matches !== nothing
        length(CustomCommand.Subset) == 0 && return (CustomCommand.Fn)()
        
        firstQuery = strip(Matches.captures[CustomCommand.Subset][begin])
        match(isHelpRegex, firstQuery) !== nothing && return CustomCommand.HelpFn()
        return (CustomCommand.Fn)(strip.(Matches.captures[CustomCommand.Subset])...)
    end
    
    return false
end

function splitQuery(query)
    parts = String[]
    io = IOBuffer()
    OpenParenthesis = 0
    OpenBrackets = 0
    for c in query
        if c == '('
            OpenParenthesis += 1
        elseif c == ')'
            OpenParenthesis -= 1
        elseif c == '['
            OpenBrackets += 1
        elseif c == ']'
            OpenBrackets -= 1
        end
            
        if c == ' ' && OpenParenthesis == 0 && OpenBrackets == 0
            S = strip(String(take!(io)))
            match(r"^\s*$", S) !== nothing || push!(parts, S)
        else
            print(io, c)
        end

        if OpenBrackets < 0 || OpenParenthesis < 0
            @info "Mismatched Brackets: Unable to parse $query"
            return String[]
        end
    end
    push!(parts, String(take!(io)))

    if OpenParenthesis != 0 || OpenBrackets != 0
        @info "Mismatched Brackets: Unable to parse $query"
        return String[]
    end

    return parts
end

function parseQuery(query, flags)
    # flags is an array of regexs representing the flags
    # This locates all the substrings of query that are flags
    # and returns a pair (newQuery, activeFlags)
    # newQuery is the query with the flags removed
    # activeFlags is an array of (flag, tokens) that were found
    # Note: This takes O(query * flags) time. 

    queryArr = splitQuery(query)
    activeFlags = Tuple{Regex, String}[]
    for flag in flags
        for (i, token) in enumerate(queryArr)
            if match(flag, token) !== nothing
                push!(activeFlags, (flag, token))
                queryArr[i] = ""
            end
        end
    end

    newQuery = strip(replace(join(queryArr, " "), r"  " => " "))
    return newQuery, activeFlags
end