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

function parseQuery(query, flags)
    # flags is an array of regexs representing the flags
    # This locates all the substrings of query that are flags
    # and returns a pair (newQuery, activeFlags)
    # newQuery is the query with the flags removed
    # activeFlags is an array of (flag, tokens) that were found
    # Note: This takes O(query * flags) time. 

    queryArr = split(query, r" ")
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