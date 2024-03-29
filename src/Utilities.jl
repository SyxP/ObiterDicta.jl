LocalizeDatabase = Dict{Tuple{String, LangMode}, Dict{String, Any}}()
StaticDatabase   = Dict{String, Dict{String, Any}}()
DataDir          = pkgdir(@__MODULE__, "data")
BackupDir        = pkgdir(@__MODULE__, "data", "Backup")

function fetchDataFilepath(path)
    if isfile(joinpath(DataDir, path))
        return joinpath(DataDir, path)
    elseif isfile(joinpath(BackupDir, path))
        return joinpath(BackupDir, path)
    else
        @info "File at $path not found."
        return nothing
    end
end


LocalizeMasterDatabase = nothing
function getLocalizeDataInfo()
    global LocalizeMasterDatabase
    if LocalizeMasterDatabase === nothing
        LocalizeMasterDatabase = JSON.parsefile(fetchDataFilepath("Localize/RemoteLocalizeFileList.json"))
    end
    return LocalizeMasterDatabase
end

function readDataFile(filePath)
    Ext = split(filePath, ".")[end]
    if Ext == "json"
        return JSON.parsefile(filePath)
    end

    io = open(filePath, "r")
    S = read(io, String)
    close(io)

    myS = collect(filter(x-> x != '\0' && x != '\x10', S))
    St, En = 1, length(myS)
    while myS[St] != '{' && St < En
        St += 1
    end
    while myS[En] != '}' && En > St
        En -= 1
    end

    Rest = String(myS[St:En])

    try
        return JSON.parse(Rest)
    catch _ 
        @info "Unable to parse $filePath"
        return
    end

    return Dict{String, Any}()
end

StaticMasterDatabase = nothing
function getStaticDataInfo()
    global StaticMasterDatabase
    if StaticMasterDatabase === nothing
        StaticMasterDatabase = readDataFile(fetchDataFilepath("StaticData/static-data/static-data-info.json"))
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
    forceReload =  ForceReloadDebug("Would you like to force reload $Name?")

    if !forceReload && haskey(LocalizeDatabase, (Name, CurrLang))
        return LocalizeDatabase[(Name, CurrLang)]
    end

    fileParts = split(Name, "/")
    exactFileName = uppercase(getLangMode()) * "_" * fileParts[end] * ".json"
    filePath = ""

    for (root, _, files) in walkdir(joinpath(DataDir, "Localize", getLangMode()))
        for file in files
            if file == exactFileName
                filePath = joinpath(root, file)
                break
            end
        end

        filePath == "" || break
    end

    if filePath == ""
        if CurrLang == English
            @info "No English files exists for $Name"
            global LocalizeDatabase[(Name, CurrLang)] = Dict{String, Any}()
            return LocalizeDatabase[(Name, CurrLang)]
        end
        @warn "No $CurrLang files exists for $Name"
        global LocalizeDatabase[(Name, CurrLang)] = LocalizedData(Name, English)
        return LocalizeDatabase[(Name, CurrLang)]
    end

    try
        global LocalizeDatabase[(Name, CurrLang)] = readDataFile(filePath)
    catch ex
        GlobalDebugMode && @warn "Unable to load $filePath" # Incomplete Translation
        if CurrLang == English
            @warn "No English files exists for $filePath"
            rethrow(ex)
        else
            return LocalizedData(Name, English)
        end
    end

    return LocalizeDatabase[(Name, CurrLang)]
end

function StaticData(Name)
    forceReload =  ForceReloadDebug("Would you like to force reload $Name?")

    if !forceReload && haskey(StaticDatabase, Name)
        return StaticDatabase[Name]
    end
    
    filePath = fetchDataFilepath("StaticData/static-data/" * Name * ".json")
    try
        global StaticDatabase[Name] = readDataFile(filePath)
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

# Can be memoized to speedup if it ever gets too slow
function superNormString(str::AbstractString)
    newStr = Unicode.normalize(str, :NFKD) 
    newStr = Unicode.normalize(newStr; casefold = true,
                                       stripmark = true,
                                       stripignore = true,
                                       stripcc = true)
   
    newStr = replace(newStr, "…" => "...", "’" => "'")
    filter(!isspace, newStr)
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
 
    if top > length(haystack)
        return sort(haystack; by = x -> evaluator(x[1]))
    else
        return partialsort(haystack, 1:top; by = x -> evaluator(x[1]))
    end
end