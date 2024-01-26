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
getName(myEnemy :: T) where T <: EnemyUnit = getLocalizedField(myEnemy, "name", "", "")
getDesc(myEnemy :: T) where T <: EnemyUnit = getLocalizedField(myEnemy, "desc", "", "")

InternalEnemyFields = [
    # id should use getID.
    (:getKeywordList, "unitKeywordList", String[]),
    (:getNameID, "nameID", nothing),
    (:getAppearance, "appearance", ""),
    (:getSDPortrait, "sdPortrait", ""),

    (:getHP, "hp", Dict{String, Any}()),
    (:getHasMP, "hasMp", false),
    (:getMP, "mp", Dict{String, Any}()),
    (:getDefenseCorrection, "defCorrection", 0),
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

    (:getAttributeType, "attributeType", ""), 
    (:getClassType, "classType", "")
]

for (fn, field, default) in InternalEnemyFields
    @eval $fn(myEnemy :: RegularEnemyUnit) =
        getInternalField(myEnemy, $field, $default, $default)
end

function getSearchTitle(enemy :: RegularEnemyUnit)
    return getName(enemy)
end
function getFullTitle(enemy :: RegularEnemyUnit)
    io = IOBuffer()
    print(io, @blue(getName(enemy)))
    print(io, " (")
    print(io, @dim(getStringID(enemy)))
    print(io, ")")

    return String(take!(io))
end
function getFullTitle(enemy :: RegularEnemyUnit, level)
    return getFullTitle(enemy) * " @ Level $level"
end

function getSpeedRange(enemy :: RegularEnemyUnit)
    # MinSpeed and MaxSpeed are always lenght 1
    minSpeed = getMinSpeedList(enemy)[1]
    maxSpeed = getMaxSpeedList(enemy)[1]
    return "$minSpeed - $maxSpeed"
end

function getDefenseCorrString(enemy :: RegularEnemyUnit, level)
    defenseCorr = getDefenseCorrection(enemy)
    totalDef = defenseCorr + level
    return "$totalDef (" * @dim(NumberStringWithSign(defenseCorr)) * ")"
end

function getHPField(enemy :: RegularEnemyUnit, field; debug = GlobalDebugMode)
    HPData = getHP(enemy)
    try
        return HPData[field]
    catch _ 
        debug && @info "Unable to parse HP Data $HPData for Enemy $(enemy.id)"
        return 0
    end
end
getBaseHP(enemy :: RegularEnemyUnit) = getHPField(enemy, "defaultStat")
getIncrementHP(enemy :: RegularEnemyUnit) = getHPField(enemy, "incrementByLevel")

function getHP(enemy :: RegularEnemyUnit, level)
    baseHP = getBaseHP(enemy)
    increment = getIncrementHP(enemy)

    totalHP = Float64(baseHP + level*increment)
    roundedHP = round(Int, totalHP, RoundNearestTiesUp)
    return roundedHP
end
function getBreakSections(enemy :: RegularEnemyUnit, level)
    Sections = getBreakSectionRaw(enemy)["sectionList"]
    TotalHP = getHP(enemy, level)
    return reverse([round(Int, TotalHP*x/100, RoundNearestTiesUp) for x in Sections])
end
function getBreakSectionRawString(enemy :: RegularEnemyUnit)
    Sections = getBreakSectionRaw(enemy)["sectionList"]
    return join(Sections, ", ")
end
function getBreakSectionsString(enemy :: RegularEnemyUnit, level)
    Sections = getBreakSections(enemy, level)
    return join(Sections, ", ")
end
function getHPString(enemy :: RegularEnemyUnit)
    return "$(getBaseHP(enemy)) (+ $(getIncrementHP(enemy)))"
end

function getResistanceString(enemy :: RegularEnemyUnit; verbose)
    resistStrList = String[]
    resistDict = getResistancesRaw(enemy)
    if haskey(resistDict, "atkResistList")
        for entry in resistDict["atkResistList"]
            resistType = entry["type"]
            resistValue = entry["value"]
            resistTypeStr = @blue(AttackTypes(resistType)* " res.")
            S = "$resistTypeStr: $(resistValue)×"
            push!(resistStrList, S)
        end 
    end

    if haskey(resistDict, "attributeResistList")
        for entry in resistDict["attributeResistList"]
            resistType = entry["type"]
            resistValue = entry["value"]
            (!verbose && resistType ∈ ["BLACK", "WHITE"]) && continue
            (!verbose && resistValue == 1) && continue

            resistTypeStr = getSinString(resistType; suffix = " res.")
            S = "$resistTypeStr: $(resistValue)×"
            push!(resistStrList, S)
        end
    end

    return resistStrList
end

function getMainFields(enemy :: RegularEnemyUnit, level; verbose)
    Fields = getResistanceString(enemy; verbose)
    LongFields = String[]
    function AddField(FieldName, FieldValue)
        FieldStr = @blue(FieldName)*": $(FieldValue)"
        if length(FieldStr) > 40
            push!(LongFields, FieldStr)
            push!(Fields, "") # Keep Padding
        else
            push!(Fields, FieldStr)
        end
    end

    AddField("Speed Range", getSpeedRange(enemy))
    AddField("Stagger Thres.", getBreakSectionsString(enemy, level))
    AddField("Def. Level", getDefenseCorrString(enemy, level))
    AddField("HP", getHP(enemy, level))

    if verbose
        AddField("Detailed HP", getHPString(enemy))
        AddField("Stagger %", getBreakSectionRawString(enemy))
    end

    Content = GridFromList(Fields, 4)
    Content /= join(LongFields, "\n ")
    # verbose && (Content /= getPanicInfoStr(enemy))

    return Content
end

function getSubtitle(enemy)
    io = IOBuffer()
    print(io, getClassType(enemy))
    Tmp = getAttributeType(enemy)
    if Tmp != ""
        print(io, getSinString(Tmp; prefix = " "))
    end
    return join([getDesc(enemy), String(take!(io))], " - ")
end

function getTopPanel(enemy :: RegularEnemyUnit, level; verbose = false)
    title = getFullTitle(enemy, level)
    subtitle = getSubtitle(enemy)
    content = getMainFields(enemy, level; verbose)

    return output = Panel(
        content,
        title=title,
        subtitle=subtitle,
        subtitle_justify=:right,
        width=100,
        fit=false)
end