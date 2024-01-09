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

function getLocalizedVersion(myEnemy :: T; dontWarn = !GlobalDebugMode) where T <: EnemyUnit
    for EnemyList in getLocalizedList(T)
        haskey(EnemyList, "dataList") || continue
        for enemy in EnemyList["dataList"]
            if enemy["id"] == myEnemy.id
                return enemy
            end
        end
    end

    dontWarn || @warn "No Localized Enemy matching $T $(myEnemy.id) found."
end

### Retrieval Functions
getID(myEnemy :: T) where T <: EnemyUnit = myEnemy.id
getStringID(myEnemy :: T) where T <: EnemyUnit = string(myEnemy.id)

