const PossiblePassiveJSONClasses = ["passive"] 
# personality-passive is used to figure out the map Identity -> passive
function getPassiveJSONListFromStatic(dataClasses = PossiblePassiveJSONClasses)
    GetFileListFromStatic(dataClasses)
end

PassiveMasterList = Dict{String, Any}[]
function getPassiveMasterList()
    forceReload = ForceReloadDebug()

    global PassiveMasterList
    !forceReload && length(PassiveMasterList) != 0 && return PassiveMasterList

    for file in getPassiveJSONListFromStatic()
        append!(PassiveMasterList, StaticData(file)["list"])
    end
    return PassiveMasterList
end

function getExactInternalPassive(id)
end