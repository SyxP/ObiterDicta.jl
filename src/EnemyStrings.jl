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
    (:getFactionList, "unitKeywordList", String[]),
    (:getNameID, "nameID", nothing),
    (:getAppearance, "appearance", ""),
    (:getSDPortrait, "sdPortrait", ""),

    (:getHP, "hp", Dict{String, Any}()),
    (:getHasMP, "hasMp", true),
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

function getOtherFields(enemy :: RegularEnemyUnit)
    Entries = Tuple{String, String}[]
    EntriesToSkip = [x[2] for x in InternalEnemyFields]
    for (key, value) in getInternalVersion(enemy)
        key == "id" && continue
        key in EntriesToSkip && continue
        Tmp = EscapeAndFlattenField(value)

        push!(Entries, (key, Tmp))
    end
    
    return Entries
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

for (fnName, field) in [(:getAtkResistance, "atkResistList"),
                        (:getSinResistance, "attributeResistList")]
    @eval function ($fnName)(enemy :: RegularEnemyUnit, resistType)
        resistDict = getResistancesRaw(enemy)
        !haskey(resistDict, $field) && return nothing
        for entry in resistDict[$field]
            if entry["type"] == resistType
                return entry["value"]
            end
        end
        return 1.0
    end
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
    function AddField(FieldName, FieldValue; noFormat = false)
        FieldStr = @blue(FieldName)*": $(FieldValue)"
        noFormat && (FieldStr = FieldName * ": $(FieldValue)")
        if length(completeStrip(FieldStr)) > 30
            push!(LongFields, FieldStr)
            push!(Fields, "") # Keep Padding
        else
            push!(Fields, FieldStr)
        end
    end
    
    AddField("Faction", join(getFactionList(enemy), ", "))
    AddField("Speed Range", getSpeedRange(enemy))
    AddField("Stagger Thres.", getBreakSectionsString(enemy, level))
    AddField("Def. Level", getDefenseCorrString(enemy, level))
    AddField("HP", getHP(enemy, level))
    AddField("Has MP", getHasMP(enemy))

    if verbose
        AddField("Detailed HP", getHPString(enemy))
        AddField("Stagger %", getBreakSectionRawString(enemy))
        getHasMP(enemy) && AddField(@red("MP"), getMP(enemy); noFormat = true)

        # Only print Level if it is not = 1
        if getRawLevel(enemy) != 1
            AddField("Level", getRawLevel(enemy))
        end

        (getNameID(enemy) !== nothing) && AddField("Name ID", getNameID(enemy))
        (getSDPortrait(enemy) !== "") && AddField("SD Portrait", getSDPortrait(enemy))

        AddField("Appearance", getAppearance(enemy))

        OtherFields = getOtherFields(enemy)
        for (key, value) in OtherFields
            AddField(key, value; noFormat = true)
        end
    end

    Content = GridFromList(Fields, 4)
    Content /= join(LongFields, "\n")
    Content /= getPatternString(enemy)
    verbose && getHasMP(enemy) && (Content /= getPanicInfoStr(enemy))

    return Content
end

function getSubtitle(enemy)
    io = IOBuffer()
    print(io, getClassType(enemy))
    Tmp = getAttributeType(enemy)
    if Tmp != ""
        print(io, getSinString(Tmp; prefix = " "))
    end
    S = String(take!(io))
    S == "" && return getDesc(enemy)
    return join([getDesc(enemy), S], " - ")
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

function getSanityFactors(enemy :: RegularEnemyUnit, type)
    S = getMentalConditionRaw(enemy)
    tier = getRawLevel(enemy)
    
    function readLevel(entry)
        get(entry, "level", -1)
    end

    if haskey(S, type)
        return getLevelList(S[type], readLevel, tier)
    end
    return String[]
end
getPositiveSanityFactors(enemy :: RegularEnemyUnit) =
    getSanityFactors(enemy, "add")
getNegativeSanityFactors(enemy :: RegularEnemyUnit) =
    getSanityFactors(enemy, "min")

function getPatternString(enemy)
    io = IOBuffer()
    if getPatternID(enemy) != "-1"
        println(io, "$(@blue("Pattern ID")): $(getPatternID(enemy))")
    end

    print(io, @red("Starting Action Slots: "))
    print(io, join(string.(getStartActionSlotList(enemy)), ", "))
    print(io, " "^10)
    print(io, @red("Max Slots: "))
    print(io, getMaxActionSlot(enemy))
    print(io, "\n")


    Tree = getPatternList(enemy)
    if length(Tree) > 0
        print(io, DisplaySlotListAsTree(Tree, "Slot List"))
    end

    return String(take!(io))
end


function getCombatSkillPanel(enemy :: RegularEnemyUnit, level; verbose = false)
    Panels = []
    tier = getRawLevel(enemy)
    for (idx, entry) in enumerate(getSkillList(enemy))
        Ct = @blue(string(entry["number"]))
        Skill = CombatSkill(entry["skillId"])
        prefixTitle = "$Ct× Skill $(@blue(string(idx))):"
        push!(Panels, InternalSkillPanel(Skill, tier, level; verbose = verbose, addedTitle = prefixTitle))
    end

    return vstack(Panels...)
end

function getPassiveList(enemy :: RegularEnemyUnit)
    return Passive.(get(getPassiveListRaw(enemy), "passiveIdList", Int[]))
end


function getPassivePanel(enemy :: RegularEnemyUnit)
    Panels = []
    S = getPassiveList(enemy)

    if length(S) == 1
        push!(Panels, PassivePanel(S[1]))
    else
        for (idx, entry) in enumerate(getPassiveList(enemy))
            prefixTitle = "Passive $(@blue(string(idx))):"
            push!(Panels, PassivePanel(entry; subtitle = prefixTitle))
        end
    end

    return vstack(Panels...)
end

function getFullPanel(enemy :: RegularEnemyUnit, level; verbose = false,
                      showSkills = true, showPassives = true)
    Ans = getTopPanel(enemy, level; verbose)
    showSkills && (Ans /= getCombatSkillPanel(enemy, level; verbose))
    showPassives && (Ans /= getPassivePanel(enemy))

    return Ans
end