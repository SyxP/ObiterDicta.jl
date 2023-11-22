LocalizeDatabase = Dict{Tuple{String, LangMode}, Dict{String, Any}}()
StaticDatabase   = Dict{String, Dict{String, Any}}()
DataDir          = pkgdir(@__MODULE__, "data")

LocalizeMasterDatabase = nothing
function getLocalizeDataInfo()
    global LocalizeMasterDatabase
    if LocalizeMasterDatabase === nothing
        LocalizeMasterDatabase = JSON.parsefile("$DataDir/Localize/RemoteLocalizeFileList.json")
    end
    return LocalizeMasterDatabase
end

StaticMasterDatabase = nothing
function getStaticDataInfo()
    global StaticMasterDatabase
    if StaticMasterDatabase === nothing
        StaticMasterDatabase = JSON.parsefile("$DataDir/StaticData/static-data/static-data-info.json")
    end
    return StaticMasterDatabase
end

function findStaticDataInfo(name)
    StaticDB = getStaticDataInfo()["dataList"]
    for item in StaticDB
        item["dataClass"] == name && return item
    end

    @info "Unable to find $name in `static-data-info.json`."
    return
end

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

    filePath = "$DataDir/Localize/$(getLangMode())/" * join(fileParts, "/") * ".json"
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
    
    filePath = "$DataDir/StaticData/static-data/" * Name * ".json"
    try
        global StaticDatabase[Name] = JSON.parsefile(filePath)
    catch ex
        @error "Unable to load $filePath"
        rethrow(ex)
    end

    return StaticDatabase[Name]
end

function GetFileListFromStatic(dataClasses)
    Files = String[]
    for dataClass in dataClasses
        item = findStaticDataInfo(dataClass)
        for file in item["fileList"]
            push!(Files, "$dataClass/$file")
        end
    end
    unique!(Files)
    return Files
end

function superNormString(str::AbstractString)
    newStr = Unicode.normalize(str; casefold = true,
                                    stripmark = true,
                                    stripignore = true,
                                    stripcc = true)
    
    String(filter(x -> !(x ∈ " '.…"), collect(newStr)))
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


    normNeedle = superNormString(needle)
    function evaluator(newStr)
        evaluate(TokenMax(JaroWinkler()), superNormString(newStr), normNeedle)
    end
    
    return partialsort(haystack, 1:top; by = x -> evaluator(x[1]))
end