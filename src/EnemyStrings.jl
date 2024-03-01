abstract type EnemyUnit end

struct RegularEnemyUnit <: EnemyUnit
    id :: Int
end

struct AbnormalityEnemyUnit <: EnemyUnit
    id :: Int
end

struct AbnormalityPart <: EnemyUnit
    id :: Int
end

struct LevelledEnemy{T <: EnemyUnit}
    enemy :: T
    level :: Int
end

getMasterFileClasses(::Type{RegularEnemyUnit}) = ["enemy"]
getMasterFileClasses(::Type{AbnormalityEnemyUnit}) = ["abnormality-unit"]
getMasterFileClasses(::Type{AbnormalityPart}) = ["abnormality-part"]

EnemyUnitMasterList = RegularEnemyUnit[]
AbnormalityMasterList = AbnormalityEnemyUnit[]
AbnormalityPartMasterList = AbnormalityPart[]

for (typeEnemy, masterList) in [(RegularEnemyUnit, EnemyUnitMasterList),
                                (AbnormalityEnemyUnit, AbnormalityMasterList),
                                (AbnormalityPart, AbnormalityPartMasterList)]
    @eval function getMasterList(::Type{$typeEnemy})
        getMasterList($typeEnemy, $masterList)
    end
end

function enemyUnitTypes()
    return [RegularEnemyUnit, AbnormalityEnemyUnit, AbnormalityPart]
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
    (:getFactionList, "associationList", String[]),
    (:getNameID, "nameID", nothing),
    (:getAppearance, "appearance", ""),
    (:getSDPortrait, "sdPortrait", ""),

    (:getHP, "hp", Dict{String, Any}()),
    (:getHasMP, "hasMp", false),
    (:getMP, "mp", nothing),
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

AbnormalityFieldsToSkip = [
    "defCorrection",
    "minSpeedList",
    "maxSpeedList",
    "startActionSlotNumList",
    "initBuffList"
]

for (fn, field, default) in InternalEnemyFields
    field ∈ AbnormalityFieldsToSkip && continue
    @eval $fn(myEnemy :: AbnormalityEnemyUnit) =
        getInternalField(myEnemy, $field, $default, $default)
end

InternalAbnormalityFields = [
    (:getPartListRaw, "abnormalityPartList", Int[]),
    (:getPhaseListRaw, "phaseIDList", Int[]),
    (:getAggro, "aggro", nothing),

    (:getShowAtkLevel, "showAtkLevel", true),
    (:getShowDefLevel, "showDefLevel", true),
    (:getShowHP, "showHp", true),
    (:getShowUnitLevel, "showUnitLevel", true),

    (:getStartActionSlot, "startActionSlotNum", nothing), 
    
    (:getStoryID, "storyID", nothing),
    (:getViewID, "viewid", nothing)
] 

for (fn, field, default) in InternalAbnormalityFields
    @eval $fn(myEnemy :: AbnormalityEnemyUnit) =
        getInternalField(myEnemy, $field, $default, $default)
end

InternalAbnormalityPartFields = [
    #id should use getID.
    (:getNameID, "nameID", nothing),    
    (:getViewID, "viewid", nothing),
    (:getSDPortrait, "sdPortrait", ""),

    (:getPartType, "partType", ""),
    (:getHP, "hp", Dict{String, Any}()),
    (:getDefenseCorrection, "defCorrection", 0),
    (:getBreakSectionRaw, "breakSection", Int[]),
    (:getIsDestroyable, "isDestroyable", false),

    (:getSkillList, "attributeList", Dict{String, Any}[]),
    (:getResistancesRaw, "resistInfo", Dict{String, Any}()),

    (:getMinSpeedList, "minSpeedList", Int[]),
    (:getMaxSpeedList, "maxSpeedList", Int[]),
    (:getPassiveListRaw, "passiveSet", Dict{String, Any}()),

    (:getCanChangeSpriteOnDestroyed, "canChangeSpriteOnDestoryed", false),
    (:getCanUseSkillOnDestroyed, "canUseSkillOnDestroyed", false),
    (:getCanVanish, "canVanish", false),

    (:getShowAtkLevel, "showAtkLevel", true),
    (:getShowDefLevel, "showDefLevel", true),
    (:getShowHP, "showHp", true),
    (:getShowUnitLevel, "showUnitLevel", true),
]

for (fn, field, default) in InternalAbnormalityPartFields
    @eval $fn(myEnemy :: AbnormalityPart) =
        getInternalField(myEnemy, $field, $default, $default)
end

function getKeywordUsed(::Type{RegularEnemyUnit})
    [x[2] for x in InternalEnemyFields]
end
function getKeywordUsed(::Type{AbnormalityEnemyUnit})
    Ans = [x[2] for x in InternalAbnormalityFields]
    for x in InternalEnemyFields
        x[2] ∈ AbnormalityFieldsToSkip && continue
        push!(Ans, x[2])
    end

    return Ans
end
function getKeywordUsed(::Type{AbnormalityPart})
    [x[2] for x in InternalAbnormalityPartFields]
end

function getOtherFields(enemy :: T) where T <: EnemyUnit
    Entries = Tuple{String, String}[]
    EntriesToSkip = getKeywordUsed(T)
    for (key, value) in getInternalVersion(enemy)
        key == "id" && continue
        key in EntriesToSkip && continue
        Tmp = EscapeAndFlattenField(value)

        push!(Entries, (key, Tmp))
    end
    
    return Entries
end

function getSearchTitle(enemy :: T) where T <: EnemyUnit
    return getName(enemy)
end

function getFullTitle(enemy :: T) where T <: EnemyUnit
    io = IOBuffer()
    print(io, @blue(getName(enemy)))
    print(io, " (")
    print(io, @dim(getStringID(enemy)))
    print(io, ")")

    return String(take!(io))
end

function getFullTitle(enemy :: T, level) where T <: EnemyUnit
    return getFullTitle(enemy) * " @ Level $level"
end
function getFullTitle(levEnemy :: LevelledEnemy{T}) where T <: EnemyUnit
    return getFullTitle(levEnemy.enemy, levEnemy.level)
end

function getSpeedRange(enemy :: T) where T <: EnemyUnit
    if T == AbnormalityEnemyUnit
        # Abnormalities don't have speed range. Try Abnormality Parts
        return ""
    end
    
    # MinSpeed and MaxSpeed are always length 1
    minSpeed = getMinSpeedList(enemy)[1]
    maxSpeed = getMaxSpeedList(enemy)[1]
    return "$minSpeed - $maxSpeed"
end

function getDefenseCorrString(enemy :: T, level) where T <: EnemyUnit
    if T == AbnormalityEnemyUnit
        # Abnormalities don't have defense correction. Try Abnormality Parts
        return ""
    end

    defenseCorr = getDefenseCorrection(enemy)
    totalDef = max(0, defenseCorr + level)
    return "$totalDef (" * @dim(NumberStringWithSign(defenseCorr)) * ")"
end

function getHPField(enemy :: T, field; debug = GlobalDebugMode) where T <: EnemyUnit
    HPData = getHP(enemy)
    try
        return HPData[field]
    catch _ 
        debug && @info "Unable to parse HP Data $HPData for Enemy $(enemy.id)"
        return 0
    end
end
getBaseHP(enemy :: T) where T <: EnemyUnit = getHPField(enemy, "defaultStat")
getIncrementHP(enemy :: T) where T <: EnemyUnit = getHPField(enemy, "incrementByLevel")

function getHP(enemy :: T, level) where T <: EnemyUnit
    baseHP = getBaseHP(enemy)
    increment = getIncrementHP(enemy)

    totalHP = Float64(baseHP + level*increment)
    roundedHP = round(Int, totalHP, RoundNearestTiesUp)
    return roundedHP
end
function getBreakSections(enemy :: T, level) where T
    if T == AbnormalityEnemyUnit
        # Generally Abnormality do not have Break Sections. Try Abnormality Parts
        return []
    end

    Sections = getBreakSectionRaw(enemy)["sectionList"]
    TotalHP = getHP(enemy, level)
    return reverse([round(Int, TotalHP*x/100, RoundNearestTiesUp) for x in Sections])
end
function getBreakSectionRawString(enemy :: T) where T <: EnemyUnit
    if T == AbnormalityEnemyUnit
        # Generally Abnormality do not have Break Sections. Try Abnormality Parts
        return ""
    end

    Sections = getBreakSectionRaw(enemy)["sectionList"]
    return join(Sections, ", ")
end
function getBreakSectionsString(enemy :: T, level) where T <: EnemyUnit
    if T == AbnormalityEnemyUnit
        # Generally Abnormality do not have Break Sections. Try Abnormality Parts
        return ""
    end

    Sections = getBreakSections(enemy, level)
    return join(Sections, ", ")
end
function getHPString(enemy :: T) where T <: EnemyUnit
    return "$(getBaseHP(enemy)) (+ $(getIncrementHP(enemy)))"
end

for (fnName, field) in [(:getAtkResistance, "atkResistList"),
                        (:getSinResistance, "attributeResistList")]
    @eval function ($fnName)(enemy :: T, resistType) where T <: EnemyUnit
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
function getResistanceString(enemy :: T; verbose) where T <: EnemyUnit
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

function getAbnormalityPartsList(enemy :: AbnormalityEnemyUnit)
    AbnormalityPart.(getPartListRaw(enemy))
end
function getAbnormalityPhasesList(enemy :: AbnormalityEnemyUnit)
    AbnormalityEnemyUnit.(getPhaseListRaw(enemy))
end

function showPanicPanel(enemy :: AbnormalityEnemyUnit)
    getHasMP(enemy) && (getPanicValue(enemy) !== nothing)
end

function getMainFields(enemy :: RegularEnemyUnit, level = getRawLevel(enemy); verbose)
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
        getHasMP(enemy) && (getMP(enemy) !== nothing) && AddField(@red("MP"), getMP(enemy); noFormat = true)
        
        if length(getSlotWeightConditionList(enemy)) > 0
            AddField("Slot Weight Condition", join(getSlotWeightConditionList(enemy), ", "))
        end

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

function getMainFields(enemy :: AbnormalityEnemyUnit, level = getRawLevel(enemy); verbose)
    Fields = String[]
    LongFields = String[]
    if length(getResistancesRaw(enemy)) != 0
        Fields = getResistanceString(enemy; verbose)
    end

    AddField(FieldName, FieldValue; noFormat = false) = begin
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
    AddField("HP", getHP(enemy, level))
    AddField("Has MP", getHasMP(enemy))

    if verbose
        AddField("Detailed HP", getHPString(enemy))
        getHasMP(enemy) && (getMP(enemy) !== nothing) && AddField(@red("MP"), getMP(enemy); noFormat = true)
        AddField("Level", getRawLevel(enemy))

        if length(getSlotWeightConditionList(enemy)) > 0
            AddField("Slot Weight Condition", join(getSlotWeightConditionList(enemy), ", "))
        end

        for (fn, checkValue, fieldName) in [
            (getSDPortrait, "", "SD Portrait"),
            (getNameID, nothing, "Name ID"),
            (getViewID, nothing, "View ID"),
            (getStoryID, nothing, "Story ID"),
            (getShowAtkLevel, true, "Show Attack Level"),
            (getShowDefLevel, true, "Show Defense Level"),
            (getShowHP, true, "Show HP"),
            (getShowUnitLevel, true, "Show Unit Level"),
        ]
            (fn(enemy) != checkValue) && AddField(fieldName, fn(enemy))
        end
       
        AddField("Appearance", getAppearance(enemy))

        OtherFields = getOtherFields(enemy)
        for (key, value) in OtherFields
            AddField(key, value; noFormat = true)
        end
    end

    Content = GridFromList(Fields, 4)
    Content /= join(LongFields, "\n")

    Content /= LineBreak("Parts")
    for part in getAbnormalityPartsList(enemy)
        Content /= getContentText(part, level; verbose)
    end

    Content /= LineBreak("Skill Pattern")
    Content /= getPatternString(enemy)
    verbose && showPanicPanel(enemy) && (Content /= getPanicInfoStr(enemy))

    return Content
end

function getContentText(enemyPart :: AbnormalityPart, level; verbose = false)
    Fields = getResistanceString(enemyPart; verbose)
    LongFields = String[]

    function AddField(FieldName, FieldValue; noFormat = false)
        FieldStr = @blue(FieldName)*": $(FieldValue)"
        noFormat && (FieldStr = FieldName * ": $(FieldValue)")
        if length(completeStrip(FieldStr)) > 23
            push!(LongFields, FieldStr)
            push!(Fields, "") # Keep Padding
        else
            push!(Fields, FieldStr)
        end
    end

    AddField("Speed Range", getSpeedRange(enemyPart))
    AddField("Stagger Thres.", getBreakSectionsString(enemyPart, level))
    AddField("HP", getHP(enemyPart, level))
    AddField("Def. Level", getDefenseCorrString(enemyPart, level))
    AddField("Is Destroyable", getIsDestroyable(enemyPart))

    if verbose
        AddField("Detailed HP", getHPString(enemyPart))
        AddField("Stagger %", getBreakSectionRawString(enemyPart))

        for (fn, checkValue, fieldName) in [
            (getSDPortrait, "", "SD Portrait"),
            (getNameID, nothing, "Name ID"),
            (getViewID, nothing, "View ID"),
            (getShowAtkLevel, true, "Show Attack Level"),
            (getShowDefLevel, true, "Show Defense Level"),
            (getShowHP, true, "Show HP"),
            (getShowUnitLevel, true, "Show Unit Level"),
            (getCanChangeSpriteOnDestroyed, false, "Change Sprite (on Destroy)"),
            (getCanUseSkillOnDestroyed, false, "Use Skill (on Destroy)"),
            (getCanVanish, false, "Can Vanish")
        ]
            (fn(enemyPart) != checkValue) && AddField(fieldName, fn(enemyPart))
        end

        OtherFields = getOtherFields(enemyPart)
        for (key, value) in OtherFields
            AddField(key, value; noFormat = true)
        end
    end

    Content = "$(@blue(getName(enemyPart))) $(@dim(getPartType(enemyPart) * " " * getStringID(enemyPart)))"
    Content /= GridFromList(Fields, 4)
    Content /= join(LongFields, "\n")

    return Content
end

function getSubtitle(enemy :: T) where T <: EnemyUnit
    io = IOBuffer()
    print(io, getClassType(enemy))
    Tmp = getAttributeType(enemy)
    if Tmp != ""
        print(io, getSinString(Tmp; prefix = " "))
    end
    S = String(take!(io))
    
    AnsArr = [getDesc(enemy)]
    (S != "") && push!(AnsArr, S)
    if T == AbnormalityEnemyUnit
        S = getGuideCodeName(enemy)
        (S != "") && push!(AnsArr, S)
    end

    return join(AnsArr, " - ")
end

function getTopPanel(enemy :: T, level; verbose = false) where T <: EnemyUnit
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

function getSanityFactors(enemy :: T, type) where T <: EnemyUnit
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
getPositiveSanityFactors(enemy :: T) where T <: EnemyUnit =
    getSanityFactors(enemy, "add")
getNegativeSanityFactors(enemy :: T) where T <: EnemyUnit =
    getSanityFactors(enemy, "min")

function getPatternString(enemy :: T) where T <: EnemyUnit
    io = IOBuffer()
    if getPatternID(enemy) != "-1"
        println(io, "$(@blue("Pattern ID")): $(getPatternID(enemy))")
    end

    if T == RegularEnemyUnit
        print(io, @red("Starting Action Slots: "))
        print(io, join(string.(getStartActionSlotList(enemy)), ", "))
        print(io, " "^10)
        print(io, @red("Max Slots: "))
        print(io, getMaxActionSlot(enemy))
        print(io, "\n")
    elseif T == AbnormalityEnemyUnit 
        io2 = IOBuffer()
        if getStartActionSlot(enemy) !== nothing
            print(io2, @red("Starting Action Slot: "))
            print(io2, getStartActionSlot(enemy))
            print(io2, " "^10)
        end
        if getMaxActionSlot(enemy) !== nothing
            print(io2, @red("Max Slots: "))
            print(io2, getMaxActionSlot(enemy))
        end
        println(io, strip(String(take!(io2))))
    end

    Tree = getPatternList(enemy)
    if length(Tree) > 0
        print(io, DisplaySlotListAsTree(Tree, "Slot List"))
    end

    return String(take!(io))
end

function getCombatSkillPanel(enemy :: T, level; verbose = false) where T <: EnemyUnit
    Panels = []
    tier = max(getRawLevel(enemy), 1)
    for (idx, entry) in enumerate(getSkillList(enemy))
        Ct = @blue(string(entry["number"]))
        Skill = CombatSkill(entry["skillId"])
        prefixTitle = "Skill $(@blue(string(idx))):"
        if entry["number"] != 0
            prefixTitle = "$Ct× Skill $(@blue(string(idx))):"
        end
        push!(Panels, InternalSkillPanel(Skill, tier, level; verbose = verbose, addedTitle = prefixTitle))
    end

    return vstack(Panels...)
end

function getPassiveList(enemy :: T) where T <: EnemyUnit
    return Passive.(get(getPassiveListRaw(enemy), "passiveIdList", Int[]))
end

function getPassivePanel(enemy :: T) where T <: EnemyUnit
    Panels = []
    Parts = EnemyUnit[enemy]
    if T == AbnormalityEnemyUnit
        append!(Parts, getAbnormalityPartsList(enemy))
    end

    for enemyPart in Parts 
        S = getPassiveList(enemyPart)
  
        if length(S) == 1
            push!(Panels, PassivePanel(S[1]))
        else
            for (idx, entry) in enumerate(getPassiveList(enemyPart))
                prefixTitle = "Passive $(@blue(string(idx))):"
                if enemyPart isa AbnormalityPart
                    prefixTitle = getName(enemyPart) * " $prefixTitle"
                end
                push!(Panels, PassivePanel(entry; subtitle = prefixTitle))
            end
        end
    end

    return vstack(Panels...)
end

function getPartialPanel(enemy :: T, level = getRawLevel(enemy); verbose = false,
                      showSkills = true, showPassives = true) where T <: EnemyUnit
    Ans = getTopPanel(enemy, level; verbose)
    showSkills && (Ans /= getCombatSkillPanel(enemy, level; verbose))
    showPassives && (Ans /= getPassivePanel(enemy))

    return Ans
end

function getFullPanel(enemy :: T, level = getRawLevel(enemy); verbose = false,
                                showSkills = true, showPassives = true) where T <: EnemyUnit 

    if T != AbnormalityEnemyUnit
        return getPartialPanel(enemy, level; verbose, showSkills, showPassives)
    end

    Phases = getAbnormalityPhasesList(enemy)
    if length(Phases) == 0
        Phases = [enemy]
    end
    Panels = getPartialPanel.(Phases, level; verbose, showSkills, showPassives)

    return vstack(Panels...)
end

function getFullPanel(levEnemy :: LevelledEnemy{T}; verbose = false, 
                      showSkills = true, showPassives = true) where T <: EnemyUnit
    return getFullPanel(levEnemy.enemy, levEnemy.level; verbose, showSkills, showPassives)
end