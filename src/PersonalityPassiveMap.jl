struct PersonalityPassive
    id :: Integer
end
PersonalityPassive(x :: Personality) = PersonalityPassive(x.id)

getMasterFileClasses(::Type{PersonalityPassive}) = ["personality-passive"]

function handleDataFile(::Type{PersonalityPassive}, MasterList, file)
    for item in StaticData(file)["list"]
        push!(MasterList, PersonalityPassive(item["personalityID"]))
    end
end

const PersonalityPassiveMasterList = PersonalityPassive[]
function getMasterList(::Type{PersonalityPassive})
    getMasterList(PersonalityPassive, PersonalityPassiveMasterList)
end

function getInternalList(::Type{PersonalityPassive})
    Files = getMasterFileList(PersonalityPassive)
    [StaticData(file) for file in Files]
end

function getInternalVersion(myPassive :: PersonalityPassive; dontWarn = !GlobalDebugMode)
    for PersonalityPassiveList in getInternalList(PersonalityPassive)
        for entry in PersonalityPassiveList["list"]
            if entry["personalityID"] == myPassive.id
                return entry
            end
        end
    end

    dontWarn || @warn "PersonalityPassive $(myPassive.id) not found."
    return nothing
end

### Retrieval

function getPersonality(myPassive :: PersonalityPassive)
    return Personality(myPassive.id)
end
getBattlePList(myPassive :: PersonalityPassive) =
    getInternalField(myPassive, "battlePassiveList", Dict{String, Any}[], nothing)
getSupportPList(myPassive :: PersonalityPassive) =
    getInternalField(myPassive, "supporterPassiveList", Dict{String, Any}[], nothing)

function getPassiveFilterSinner(sinnerID)
    PassiveLists = Passive[]
    for entry in getMasterList(PersonalityPassive)
        person = getPersonality(entry)
        getSinnerName(person) == sinnerID || continue
        
        for fn in [getBattlePList, getSupportPList]
            for levelList in fn(entry)
                haskey(levelList, "passiveIDList") || continue
                S = levelList["passiveIDList"]
                append!(PassiveLists, Passive.(S))
            end
        end
    end

    return PassiveLists
end

for (newFn, pListFn) in [(:getBattlePassive, getBattlePList),
                         (:getSupportPassive, getSupportPList)]
    @eval function ($newFn)(id :: Personality, uptie)
        myPass = PersonalityPassive(id)
        
        function readLevel(entry)
            haskey(entry, "level") ? entry["level"] : -1
        end

        S = getLevelList(($pListFn)(myPass), readLevel, uptie)
        if haskey(S, "passiveIDList")
            return Passive.(S["passiveIDList"])
        else
            return Passive[]
        end
    end
end