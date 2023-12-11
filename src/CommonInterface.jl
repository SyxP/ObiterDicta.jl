# Suggested Interface for any Command
# getMasterFileClasses(::Type{T}) - List Of Data Files
# handleDataFile(::Type{T}, MasterList, File) - Used when making a MasterList
# getMasterList(::Type{T}) - Returning the MasterList
# getLocalizedList(::Type{T}) - This is not a uniform interface. Often 
# returns a list of (list of) JSON Dict{String, Any} rather than T[]
# getLocalizedVersion(x :: T), getInternalVersion(x :: T)

# The functions below should be overloaded if necessary.

function getMasterFileList(::Type{T}) where T
    dataClasses = getMasterFileClasses(T)
    GetFileListFromStatic(dataClasses)
end

function getMasterList(::Type{T}, MasterList) where T
    forceReload = ForceReloadDebug("Would you like to reload the master list?")
    
    !forceReload && length(MasterList) != 0 && return MasterList

    for file in getMasterFileList(T)
        handleDataFile(T, MasterList, file)
    end

    return MasterList
end

function getField(x :: T, fn :: Function, fieldName, cantFind, defaultReturn) where T
    Ver = fn(x)
    if Ver !== nothing
        return haskey(Ver, fieldName) ? Ver[fieldName] : cantFind
    end

    return defaultReturn
end

function hasLocalizedVersion(x :: T) where T
    S = getLocalizedVersion(x; dontWarn = true)
    return S !== nothing
end

getLocalizedField(x :: T, fieldName, cantFind, defaultReturn) where T= 
getField(x, getLocalizedVersion, fieldName, cantFind, defaultReturn)

getInternalField(x :: T, fieldName, cantFind, defaultReturn) where T = 
getField(x, getInternalVersion, fieldName, cantFind, defaultReturn)

function getLevelList(myDict, readLevel, tier)
    copyDict = copy(myDict)

    sort!(copyDict, by = readLevel)
    Cumulative = Dict{String, Any}()
    for entry in copyDict
        readLevel(entry) > tier && break
        for (key, value) in entry
            Cumulative[key] = value
        end
    end
    return Cumulative

end

function CompareNumbers(a, b, op :: String)
    if op == "<"
        return a < b
    elseif op == "≤"
        return a ≤ b
    elseif op == "="
        return a == b
    elseif op == "≥"
        return a ≥ b
    elseif op == ">"
        return a > b
    elseif op == "≠"
        return a != b
    end
    return true # Fallback if op is invalid
end