abstract type EnemyUnit end

struct RegularEnemyUnit <: EnemyUnit
    id :: Int
end

struct AbnormalityEnemyUnit <: EnemyUnit
    id :: Int
end

getMasterFileClasses(::Type{RegularEnemyUnit}) = ["enemy"]
getMasterFileClasses(::Type{AbnormalityEnemyUnit}) = ["abnormality-unit"]

EnemyUnitMasterList = RegularEnemyUnit[]
AbnormalityMasterList = AbnormalityEnemyUnit[]

for (typeEnemy, masterList) in [(RegularEnemyUnit, EnemyUnitMasterList),
                                (AbnormalityEnemyUnit, AbnormalityMasterList)]
    @eval function getMasterList(::Type{$typeEnemy})
        getMasterList($typeEnemy, $masterList)
    end
end

function enemyUnitTypes()
    return [RegularEnemyUnit, AbnormalityEnemyUnit]
end
function getMasterFileClasses(::Type{EnemyUnit})
    Lst = [getMasterFileClasses(tEnemy) for tEnemy in enemyUnitTypes()]
    return foldl(vcat, Lst)
end
function getMasterFileList(::Type{EnemyUnit})
    Lst = [getMasterFileList(tEnemy) for tEnemy in enemyUnitTypes()]
    return foldl(vcat, Lst)
end
function getMasterList(::Type{EnemyUnit})
    Lst = [getMasterList(tEnemy) for tEnemy in enemyUnitTypes()]
    return foldl(vcat, Lst)
end

getLocalizedFolders(::Type{T}) where T <: EnemyUnit = ["enemy"]

function getInternalVersion(myEnemy :: T; dontWarn = !GlobalDebugMode) where T <: EnemyUnit
    for EnemyList in getInternalList(T)
        haskey(EnemyList, "list") || continue
        for enemy in EnemyList["list"]
            if enemy["id"] == myEnemy.id
                return enemy
            end
        end
    end

    dontWarn || @warn "No Internal Enemy matching $T $(myEnemy.id) found."
    return 
end

EnemyNameMemoizeDict = Dict{Int, Int}()

function getLocalizedVersion(myEnemy :: T; dontWarn = !GlobalDebugMode) where T <: EnemyUnit
    if !haskey(EnemyNameMemoizeDict, myEnemy.id)
        searchID = myEnemy.id
        searchInternal = getInternalVersion(myEnemy)
        (searchInternal !== nothing) && (searchID = get(searchInternal, "nameID", myEnemy.id))
        EnemyNameMemoizeDict[myEnemy.id] = searchID
    end
    searchID = EnemyNameMemoizeDict[myEnemy.id]

    for EnemyList in getLocalizedList(T)
        haskey(EnemyList, "dataList") || continue
        for enemy in EnemyList["dataList"]
            if enemy["id"] == searchID
                return enemy
            end
        end
    end

    dontWarn || @warn "No Localized Enemy matching $T $(myEnemy.id) found."
    return
end

### Retrieval Functions
getID(myEnemy :: T) where T <: EnemyUnit = myEnemy.id
getStringID(myEnemy :: T) where T <: EnemyUnit = string(myEnemy.id)

InternalEnemyFields = [
    # id should use getID.
    (:getKeywordList, "unitKeywordList", String[]),
    (:getNameID, "nameID", nothing),
    (:getAppearance, "appearance", ""),
    (:getSDPortrait, "sdPortrait", ""),

    (:getHP, "hp", Dict{String, Any}()),
    (:getHasMP, "hasMp", false),
    (:getMP, "mp", Dict{String, Any}()),
    (:getDefenseCorr, "defCorrection", nothing),
    (:getBreakSectionRaw, "breakSection", Int[]),
    (:getRawLevel, "level", -1), ## Note this is over-written by the stage information.
    (:getResistancesRaw, "resistInfo", Dict{String, Any}()),

    (:getPatternID, "patternID", "-1"),
    (:getPatternList, "patternList", String[]),
    (:getSkillList, "attributeList", Dict{String, Any}[]),

    (:getMinSpeedList, "minSpeedList", Int[]),
    (:getMaxSpeedList, "maxSpeedList", Int[]),
    (:getStartActionSlotList, "startActionSlotNumList", Int[]),
    (:getMaxActionSlot, "maxActionSlotNum", nothing),

    (:getPanicValue, "panic", nothing),
    (:getPanicType, "panicType", -1),
    (:getLowMoraleValue, "lowMorale", nothing),
    (:getMentalConditionRaw, "mentalConditionInfo", Dict{String, Any}()),

    (:getSlotWeightConditionList, "slotWeightConditionList", Dict{String, Any}[]),
    (:getInitialBuffListRaw, "initBuffList", Dict{String, Any}[]),
    (:getPassiveListRaw, "passiveSet", Dict{String, Any}()),
]