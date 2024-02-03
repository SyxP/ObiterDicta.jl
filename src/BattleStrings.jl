abstract type Battle end

BattleTypes = [
    (:StoryBattle, ["battle-story"]),
    (:DungeonBattle, ["battle-dungeon"]),
    (:AbnormalityBattle, ["battle-ab"]),
    (:MirrorDungeonBattle, ["battle-mirrordungeon"]), 
    (:ThreadDungeonBattle, ["battle-thread-dungeon"]),
    (:EXPDungeonBattle, ["battle-exp-dungeon"]),
    (:RailwayBattle, ["battle-railway-dungeon"])
]

for (BattleType, BattleFiles) in BattleTypes
    MasterListSymbol = Symbol(BattleType, "MasterList")

    @eval begin  
        struct $BattleType <: Battle
            id :: Int
        end

        getMasterFileClasses(::Type{$BattleType}) = $BattleFiles

        ($MasterListSymbol) = ($BattleType)[]
        function getMasterList(::Type{$BattleType})
            getMasterList($BattleType, $MasterListSymbol)
        end
    end
end

function battleTypes()
    return [getproperty(@__MODULE__, x[1]) for x in BattleTypes]
end

function getMasterFileClasses(::Type{Battle})
    Lst = [getMasterFileClasses(tBattle) for tBattle in battleTypes()]
    return foldl(vcat, Lst)
end
function getMasterFileList(::Type{Battle})
    Lst = [getMasterFileList(tBattle) for tBattle in battleTypes()]
    return foldl(vcat, Lst)
end
function getMasterList(::Type{Battle})
    Lst = [getMasterList(tBattle) for tBattle in battleTypes()]
    return foldl(vcat, Lst)
end

function getInternalVersion(myBattle :: T; dontWarn = !GlobalDebugMode) where T <: Battle
    for BattleList in getInternalList(T)
        haskey(BattleList, "list") || continue
        for entry in BattleList["list"]
            if entry["id"] == myBattle.id
                return entry
            end
        end
    end

    dontWarn || @warn "No Internal Battle matching $(myBattle.id) found."
    return
end

### Retrieval Functions
getID(myBattle :: T) where T <: Battle = myBattle.id
getStringID(myBattle :: T) where T <: Battle = string(myBattle.id)

# Common Fields
# participantInfo, waveList, turnlimit, staminaCost, stageType
# Possibly missing Fields
# stageLevel (overwritten by waveList's level)
# recommendedLevel, rewardList