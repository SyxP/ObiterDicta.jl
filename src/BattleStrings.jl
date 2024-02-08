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

InternalBattleFields = [
    (:getParticipantInfo, "participantInfo", nothing),
    (:getWaveList, "waveList", Any[]),
    (:getTurnLimit, "turnLimit", -1),
    (:getStaminaCost, "staminaCost", nothing),
    (:getStageType, "stageType", nothing),

    (:getStageLevel, "stageLevel", nothing),
    (:getRecommendedLevel, "recommendedLevel", nothing),
    (:getRewardList, "rewardList", Any[]),
]

for (fn, field, default) in InternalBattleFields
    @eval function ($fn)(myBattle :: T) where T <: Battle
        getInternalField(myBattle, $field, $default, $default)
    end
end

function getWaveListString(myBattle :: T; verbose = false, showCt = true) where T <: Battle
    stageType = getStageType(myBattle)
    waveList = getWaveList(myBattle)
    io = IOBuffer()
    enemyUnitList = Tuple{EnemyUnit, Int}[]
    Ct = 0

    function getEnemyString(enemyDict)
        unitID = get(enemyDict, "unitID", -1)
        unitLevel = get(enemyDict, "unitLevel", nothing)
        unitCount = get(enemyDict, "unitCount", 1)
        
        enemyStruct = nothing
        if stageType == "Normal"
            enemyStruct = RegularEnemyUnit(unitID)
        elseif stageType == "Abnormality"
            enemyStruct = AbnormalityEnemyUnit(unitID)
        end
        (unitID == -1 || enemyStruct === nothing) && return ""
        (unitLevel === nothing) && (unitLevel = getRawLevel(enemyStruct))
        Ct += 1
        push!(enemyUnitList, (enemyStruct, unitLevel))

        io2 = IOBuffer()
        showCt && print(io2, "($(@dim(string(Ct)))) ")
        print(io2, "$unitCount× $(@blue(getName(enemyStruct))) @Lvl $unitLevel")

        enemyString = String(take!(io2))
        return enemyString
    end

    function getJustifiedList(enemyList; initCt = 0)
        enemyStringList = [getEnemyString(enemyDict) for enemyDict in enemyList]
        for i in 1:length(enemyStringList)
            i != length(enemyStringList) && (enemyStringList[i] *= ", ")
        end

        io2 = IOBuffer()
        Ct2 = initCt 
        for enemyString in enemyStringList
            if Ct2 + textwidth(enemyString) > 95
                println(io2)
                Ct2 = 0
            end
            Ct2 += textwidth(enemyString)
            print(io2, enemyString)
        end

        return String(take!(io2))
    end

    for (idx, wave) in enumerate(waveList)
        println(io, @blue("Wave $idx")*":")
        enemyList = get(wave, "unitList", Any[])
        println(io, getJustifiedList(enemyList))
        subenemyList = get(wave, "subUnitList", Any[])
        if length(subenemyList) > 0
            println(io, "Additional Units: " * getJustifiedList(subenemyList; initCt = 20))
        end

        if verbose
            BGMList = get(wave, "bgmList", Any[])
            if length(BGMList) > 0
                println(io, @red("BGM") * ": " * join(BGMList, ", "))
            end
            BattleMapInfo = get(wave, "battleMapInfo", Dict{String, Any}())
            battleMapStrings = String[]
            haskey(BattleMapInfo, "mapName") && push!(battleMapStrings, @red("Map Name") * ": " * BattleMapInfo["mapName"])
            haskey(BattleMapInfo, "mapSize") && push!(battleMapStrings, @red("Map Size") * ": " * string(BattleMapInfo["mapSize"]))
            haskey(wave, "enemyPositionID")  && push!(battleMapStrings, @red("Position ID") * ": " * string(wave["enemyPositionID"]))
            println(io, join(battleMapStrings, "   "))
        end
    end
    S = String(take!(io))
    return S
end