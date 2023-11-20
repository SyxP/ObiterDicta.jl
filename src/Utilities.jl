@enum LangMode begin
    English  = 1
    Japanese = 2
    Korean   = 3
    Chinese  = 4
end 

global CurrLanguage = English
global DebugMode = false # Can only be turn on in Julia Mode.

function setLangMode(langStr)
    tmpStr = String(filter(∈('a':'z'), collect(lowercase(langStr))))
    Options = Dict{String, LangMode}([
            "english" => English, "en" => English, "eng" => English, 
            "japanese" => Japanese, "ja" => Japanese, "jp" => Japanese, "jap" => Japanese, 
            "korean" => Korean, "ko" => Korean, "kr" => Korean, "kor" => Korean,
            "chinese" => Chinese, "zh" => Chinese])
    if haskey(Options, tmpStr)
        @info "Language Mode set to $langStr"
        global CurrLanguage = Options[tmpStr]
    else
        @info "Unknown Language Mode $langStr"
    end

    return CurrLanguage
end

function setLangModeHelp()
    S = raw"""Sets the language mode. Options are English (en), Japanese (jp), Korean (kr), Chinese (zh)
              Example Usage: `lang en`
        """
    println(S)
end

function getLangMode()
    Options = Dict{LangMode, String}(English => "en", Japanese => "jp", Korean => "kr")
    if haskey(Options, CurrLanguage)
        return Options[CurrLanguage]
    else
        @info "Current LangMode $CurrLanguage is not supported. Defaulting to English"    
        return "en"
    end
end

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

setLangRegex = r"^(set[ -]?)?lang (.*)$"
SetLangCommand = Command(setLangRegex, setLangMode, [2], setLangModeHelp)

isYesInput(Str) = Str ∈ ["y", "Y", "yes", "Yes", "YES"]

LocalizeDatabase = Dict{Tuple{String, LangMode}, Dict{String, Any}}()
StaticDatabase   = Dict{String, Dict{String, Any}}()

function LocalizedData(Name, CurrLang = CurrLanguage)
    forceReload = false
    if DebugMode
        prompt = DefaultPrompt(["yes", "no"], 2, "Would you like to force reload $Name?")
        c = ask(prompt)
        isYesInput(c) && (forceReload = true)
    end

    if !forceReload && haskey(LocalizeDatabase, (Name, CurrLang))
        return LocalizeDatabase[(Name, CurrLang)]
    end

    fileParts = split(Name, "/")
    fileParts[end] = uppercase(getLangMode()) * "_" * fileParts[end]

    filePath = "data/Localize/$(getLangMode())/" * join(fileParts, "/") * ".json"
    try
        global LocalizeDatabase[(Name, CurrLang)] = JSON.parsefile(filePath)
    catch ex
        @error "Unable to load $filePath"
        rethrow(ex)
    end

    return LocalizeDatabase[(Name, CurrLang)]
end

function StaticData(Name)
    forceReload = false
    if DebugMode
        prompt = DefaultPrompt(["yes", "no"], 2, "Would you like to force reload $Name?")
        c = ask(prompt)
        isYesInput(c) && (forceReload = true)
    end

    if !forceReload && haskey(StaticDatabase, Name)
        return StaticDatabase[Name]
    end
    
    filePath = "data/StaticData/static-data/" * Name * ".json"
    try
        global StaticDatabase[Name] = JSON.parsefile(filePath)
    catch ex
        @error "Unable to load $filePath"
        rethrow(ex)
    end

    return StaticDatabase[Name]
end

function SearchClosestString(needle, haystack; top = 1)
    # haystack is an array of tuples of the form (string, value)
    # Finds the closest string in haystack to needle
    # Returns the an array of tuple (string, value) of the closest strings
    # value is used for ID numbers

    if length(haystack) == 0 
        @error "SearchClosestString on empty haystack"
        return
    end

    return partialsort(haystack, 1:top; by = x -> evaluate(DamerauLevenshtein(), x[1], needle))
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

function DisplaySkillAsTree(SkillDict, Title = "")

    myDict = deepcopy(SkillDict)
    if haskey(myDict, "ability")
        Title *= " (" * @red(myDict["ability"])
        if haskey(myDict, "value")
            Title *= ", {yellow}value{/yellow} ⇒ " * @blue(string(myDict["value"]))
            delete!(myDict, "value")
        end
        Title *= ")"
        delete!(myDict, "ability")
    end

    function pn(io, node; kw...)
        # https://github.com/FedeClaudi/Term.jl/issues/206
        if node == myDict
            print(io, Title)
        elseif node isa AbstractDict
            print(io, string(typeof(node)))
        else
            print(io, node)
        end
    end
    Term.Tree(myDict; print_node_function = pn)
end

function EscapeString(Str)
    replace(Str, "{" => "[[", "}" => "]]")
end

function GridFromList(StringList, columns = 1; labelled = false)
    n = ceil(Int, log10(1 + length(StringList)))
    StringCols = fill("", columns)

    for (i, Str) in enumerate(StringList)
        Prefix = labelled ? "{dim}$(lpad(i, n)){/dim} " : ""
        StringCols[mod1(i, columns)] *= Prefix * EscapeString(Str) * "\n"
    end
    
    GridList = [TextBox(rstrip(Str), fit = true, padding = Padding(0, 0, 0, 0)) for Str in StringCols]
    return grid(GridList; layout=(nothing, columns))
end