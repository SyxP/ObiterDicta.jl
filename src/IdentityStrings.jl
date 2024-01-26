struct Personality
    id :: Int
end

getMasterFileClasses(::Type{Personality}) = ["personality"]

IdentityMasterList = Personality[]
function getMasterList(::Type{Personality})
    getMasterList(Personality, IdentityMasterList)
end

getLocalizedFolders(::Type{Personality}) = ["personality"]

function getInternalVersion(myIdentity :: Personality; dontWarn=!GlobalDebugMode)
    for IdentityList in getInternalList(Personality)
        for identity in IdentityList["list"]
            (identity["id"] == myIdentity.id) && return identity
        end
    end

    dontWarn || @warn "Identity $(myIdentity.id) not found in internal list."
    return nothing
end

function getLocalizedVersion(myIdentity :: Personality; dontWarn=!GlobalDebugMode)
    for IdentityList in getLocalizedList(Personality)
        if !haskey(IdentityList, "dataList")
            if (length(IdentityList) > 0)
                @warn "Unable to read Localized Identity List"
                return IdentityList
            end

            # Skipping Empty Identity List
            continue
        end
        for identity in IdentityList["dataList"]
            length(identity) == 0 && continue
            (identity["id"] == myIdentity.id) && return identity
        end
    end

    dontWarn || @warn "Identity $(myIdentity.id) not found in localized list."
    return nothing
end

### Retrieval
getID(identity :: Personality) = identity.id
getStringID(identity :: Personality) = string(identity.id)
getMaxUptie(::Type{Personality}) = 4
getMaxLevel(::Type{Personality}) = 40

getTitle(identity :: Personality) = getLocalizedField(identity, "title", "", "")
function getEscapedTitle(identity :: Personality) 
    S = strip(getTitle(identity))
    S = replace(S, "\n" => " - ")
    S = replace(S, "  " => " ")
    return S
end

getSinnerName(identity :: Personality) = getLocalizedField(identity, "name", "", "")
function getSearchTitle(identity :: Personality)
    return getTitle(identity)*getSinnerName(identity)
end
function getFullTitle(identity :: Personality)
    io = IOBuffer()
    print(io, "⟨"*@blue(getSinnerName(identity))*"⟩")
    print(io, " ")
    print(io, getEscapedTitle(identity))
    print(io, " (")
    print(io, @dim(getStringID(identity)))
    print(io, ")") 
    return String(take!(io))
end
function getFullTitle(identity :: Personality, level, uptie)
    return getFullTitle(identity) * " @ Uptie $uptie and Level $level"
end

InternalIdentityFields = [(:getCharID, "characterId", ""),
                          (:getRarity, "rank", -1),
                          (:getHP, "hp", Dict{String, Any}()),
                          (:getBreakSectionRaw, "breakSection", Dict{String, Any}()),
                          (:getFactionList, "unitKeywordList", String[]),
                          (:getPanicType, "panicType", -1),
                          (:getPanicSkillRaw, "panicSkillOnErosion", -1),
                          (:getDefenseSkillRaw, "defenseSkillIDList", -1),
                          (:getAttackSkillList, "attributeList", Dict{String, Any}[]),
                          (:getResistInfoRaw, "resistInfo", Dict{String, Any}()),
                          (:getDefenseCorrection, "defCorrection", nothing),
                          (:getMinSpeedList, "minSpeedList", Int[]),
                          (:getMaxSpeedList, "maxSpeedList", Int[]),
                          (:getSinAttributeRaw, "uniqueAttribute", ""),
                          (:getMentalConditionRaw, "mentalConditionInfo", Dict{String, Any}()),
                          (:getSeason, "season", -1),
                          (:getAdditionalAttachment, "additionalAttachment", ""),
                          (:getWalpurgisType, "walpurgisType", "")]

for (fn, field, default) in InternalIdentityFields 
    @eval $fn(identity :: Personality) =
        getInternalField(identity, $field, $default, nothing)
end

function getOtherFields(identity :: Personality)
    Entries = String[]
    LongEntries = String[]
    EntriesToSkip = [x[2] for x in InternalIdentityFields]
    for (key, value) in getInternalVersion(identity)
        key == "id" && continue
        key in EntriesToSkip && continue
        Tmp = EscapeAndFlattenField(value)
        if length(key*Tmp) < 20
            push!(Entries, "$(key): $(Tmp)")
        else
            push!(LongEntries, "$(key): $(Tmp)")
        end
    end

    return Entries, LongEntries
end

function getRarityString(identity :: Personality)
    N = getRarity(identity)
    (N isa Int) && return getRarityString(N)
        
    @info "Unable to parse Rarity String: $N"
    return ""
end
function getSubtitle(identity :: Personality, uptie)
    io = IOBuffer()
    print(io, getRarityString(identity))
    print(io, " - ")
    print(io, getSinString(getSinAttributeRaw(identity)))
    return String(take!(io))
end

getMinSpeed(identity :: Personality, uptie) = getMinSpeedList(identity)[uptie]
getMaxSpeed(identity :: Personality, uptie) = getMaxSpeedList(identity)[uptie]
function getSpeedRange(identity :: Personality, uptie)
    minSpeed = getMinSpeed(identity, uptie)
    maxSpeed = getMaxSpeed(identity, uptie)
    return "$minSpeed - $maxSpeed"
end

function getDefenseCorrString(identity :: Personality, level)
    defenseCorr = getDefenseCorrection(identity)
    totalDef = defenseCorr + level
    return "$totalDef (" * @dim(NumberStringWithSign(defenseCorr)) * ")"  
end

function getHPField(identity :: Personality, field; debug = GlobalDebugMode)
    HPData = getHP(identity)
    try
        return HPData[field]
    catch _
        debug && @info "Unable to parse HP Data $HPData for Personality $(identity.id)"
        return 0
    end
end
getBaseHP(identity :: Personality) = getHPField(identity, "defaultStat")
getIncrementHP(identity :: Personality) = getHPField(identity, "incrementByLevel")

function getHP(identity :: Personality, level)
    baseHP = getBaseHP(identity)
    increment = getIncrementHP(identity)

    totalHP = Float64(baseHP + level*increment)
    roundedHP = round(Int, totalHP, RoundNearestTiesUp)
    return roundedHP
end
function getBreakSections(identity :: Personality, level)
    Sections = getBreakSectionRaw(identity)["sectionList"]
    TotalHP = getHP(identity, level)
    return reverse([round(Int, TotalHP*x/100, RoundNearestTiesUp) for x in Sections])
end
function getBreakSectionRawString(identity)
    Sections = getBreakSectionRaw(identity)["sectionList"]
    return join(Sections, ", ")
end
function getBreakSectionsString(identity :: Personality, level)
    Sections = getBreakSections(identity, level)
    return join(Sections, ", ")
end
function getHPString(identity :: Personality)
    return "$(getBaseHP(identity)) (+ $(getIncrementHP(identity)))"
end

for i in 1:3
    @eval $(Symbol(:getSkill, i))(identity :: Personality) = 
        CombatSkill(getAttackSkillList(identity)[$i]["skillId"])
end
function getAttackCombatSkills(identity :: Personality)
    Skills = Tuple{Int, CombatSkill}[]
    for entry in getAttackSkillList(identity)
        push!(Skills, (entry["number"], CombatSkill(entry["skillId"])))  
    end
    return Skills
end
function getDefenseCombatSkill(identity :: Personality)
    return CombatSkill.(getDefenseSkillRaw(identity))
end
getPanicCombatSkill(identity :: Personality) = CombatSkill(getPanicSkillRaw(identity))

function getResistance(identity :: Personality, resistType)
    for entry in getResistInfoRaw(identity)["atkResistList"]
        if entry["type"] == resistType
            return entry["value"]
        end
    end
    return 1.0
end

function getResistanceString(identity :: Personality)
    resistStrList = String[]
    for entry in getResistInfoRaw(identity)["atkResistList"]
        resistType = entry["type"]
        resistValue = entry["value"]
        resistTypeStr = @blue(AttackTypes(resistType)*" res.")
        S = "$resistTypeStr: $(resistValue)×"
        push!(resistStrList, S)
    end
    while length(resistStrList) % 3 != 0
        push!(resistStrList, "")
    end

    return resistStrList
end

function isEvent(identity :: Personality)
    S = getAdditionalAttachment(identity)
    if S ∉ ["EVENT", ""]
        @info "Unable to parse Additional Attachment $S"
    end
    return S == "EVENT"
end
function getSeasonStr(identity :: Personality)
    N = getSeason(identity)

    Ans = getSeasonNameFromInt(N)
    (isEvent(identity)) && (Ans *= " [Event]")

    return Ans
end


function getMainFields(identity :: Personality, level, uptie; verbose)
    Fields = getResistanceString(identity)
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
    
    AddField("Faction", join(getFactionList(identity), ", "))
    AddField("Speed Range", getSpeedRange(identity, uptie))
    AddField("Stagger Thres.", getBreakSectionsString(identity, level))
    AddField("Def. Level", getDefenseCorrString(identity, level))
    AddField("HP", getHP(identity, level))
    
    push!(LongFields, " "*@red(getSeasonStr(identity)))
    if verbose
        AddField("Detailed HP", getHPString(identity))
        AddField("Stagger %", getBreakSectionRawString(identity))
        if getWalpurgisType(identity) != ""
            AddField("Walpurgis Type", getWalpurgisType(identity))
        end
        
        Entries, LongEntries = getOtherFields(identity)
        append!(Fields, Entries)
        append!(LongFields, LongEntries)
    end

    Content = GridFromList(Fields, 3)
    Content /= join(LongFields, "\n ")
    verbose && (Content /= getPanicInfoStr(identity, uptie))

    return Content
end

### Printing

function getTopPanel(identity :: Personality, level, uptie; verbose = false)
    title = getFullTitle(identity, level, uptie)
    subtitle = getSubtitle(identity, uptie)
    content = getMainFields(identity, level, uptie; verbose)

    return output = Panel(
        content,
        title=title,
        subtitle=subtitle,
        subtitle_justify=:right,
        width=100,
        fit=false)
end

function getAttackPanel(identity :: Personality, level, uptie; verbose = false)
    Panels = []
    for (idx, entry) in enumerate(getAttackCombatSkills(identity))
        Ct = @blue(string(entry[1]))
        Skill = entry[2]
        prefixTitle = "$Ct× Skill $(@blue(string(idx))):"
        push!(Panels, InternalSkillPanel(Skill, uptie, level; verbose = verbose, addedTitle = prefixTitle))
    end

    # Hardcoded to show only 2 skills if UT1,2
    if 1 ≤ uptie ≤ 2
        return vstack(Panels[1:2]...)
    else
        return vstack(Panels...)
    end
end

function getDefensePanel(identity :: Personality, level, uptie; verbose = false)
    Skills = getDefenseCombatSkill(identity)
    if length(Skills) == 1
        return InternalSkillPanel(Skills[1], uptie, level; verbose = verbose, addedTitle = "Defense:")
    end

    Panels = []
    for (idx, entry) in enumerate(Skills)
        prefixTitle = "Def Skill $idx:"
        push!(Panels, InternalSkillPanel(entry, uptie, level; verbose = verbose, addedTitle = prefixTitle))
    end

    return vstack(Panels...)
end

function getPanicPanel(identity :: Personality, level, uptie)
    return InternalSkillPanel(getPanicCombatSkill(identity), uptie, level; verbose = true, addedTitle = "Panic:")
end
function getSanityFactors(identity :: Personality, uptie, type)
    S = getMentalConditionRaw(identity)
    function readLevel(entry)
        haskey(entry, "level") ? entry["level"] : -1
    end

    if haskey(S, type)
        return getLevelList(S[type], readLevel, uptie)
    end
    return String[]
end
getPositiveSanityFactors(identity :: Personality, uptie) =
    getSanityFactors(identity, uptie, "add")
getNegativeSanityFactors(identity :: Personality, uptie) =
    getSanityFactors(identity, uptie, "min")

function getPassivePanel(identity :: Personality, uptie)
    Panels = Panel[]
    for (fn, name) in [(getBattlePassive, @green("Passsive")),
                       (getSupportPassive, @green("Support Passive"))]
        S = fn(identity, uptie)

        if length(S) == 1
            push!(Panels, PassivePanel(S[1]; subtitle = "$name"))
        else
            for (idx, entry) in enumerate(S)
                push!(Panels, PassivePanel(entry; subtitle = "$name $idx"))
            end
        end
    end

    return vstack(Panels...)
end

function getFullPanel(identity :: Personality, level = getMaxLevel(Personality), 
                      uptie = getMaxUptie(Personality); verbose = false, showSkills = true, showPassives = true)
    Ans = getTopPanel(identity, level, uptie; verbose)
    showSkills && (Ans /= getAttackPanel(identity, level, uptie; verbose))
    showSkills && (Ans /= getDefensePanel(identity, level, uptie; verbose))
    verbose && (Ans /= getPanicPanel(identity, level, uptie))
    showPassives && (Ans /= getPassivePanel(identity, uptie))

    return Ans
end