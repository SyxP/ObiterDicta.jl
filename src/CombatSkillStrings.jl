struct CombatSkill
    id :: Int
end

getMasterFileClasses(::Type{CombatSkill}) = ["skill"]

function handleDataFile(::Type{CombatSkill}, MasterList, file)
    for item in StaticData(file)["list"]
        push!(MasterList, CombatSkill(item["id"]))
    end
end

const SkillMasterList = CombatSkill[]
function getMasterList(::Type{CombatSkill})
    getMasterList(CombatSkill, SkillMasterList)
end

function getInternalList(::Type{CombatSkill})
    Files = getMasterFileList(CombatSkill)
    [StaticData(file) for file in Files]
end

function getLocalizedList(::Type{CombatSkill})
    Files = getLocalizeDataInfo()["skill"]
    [LocalizedData(file) for file in Files]
end

function getInternalVersion(mySkill :: CombatSkill; dontWarn = !GlobalDebugMode)
    for SkillList in getInternalList(CombatSkill)
        for skill in SkillList["list"]
            (skill["id"] == mySkill.id) && return skill
        end
    end
    
    dontWarn || @warn "Internal Skill with $(mySkill.id) not found"
    return
end

function getLocalizedVersion(mySkill :: CombatSkill; dontWarn = !GlobalDebugMode)
    for SkillList in getLocalizedList(CombatSkill)
        if !haskey(SkillList, "dataList")
            if (length(SkillList) > 0)
                @warn "Unable to read Localized Skill List"
                return SkillList
            end
            
            # Skipping Empty Skill List
            continue
        end
        
        for skill in SkillList["dataList"]
            length(skill) == 0 && continue
            !haskey(skill, "id") && @info skill
            (skill["id"] == mySkill.id) && return skill
        end
    end
    
    dontWarn || @warn "Localized Skill with $(mySkill.id) not found."
    return
end

### Skill Specific Retrievals

getID(skill :: CombatSkill) = skill.id
getStringID(skill :: CombatSkill) = string(skill.id)

function getLocalizedLevelList(skill :: CombatSkill, tier = 0) 
    # Tier 0 means no only taking input with no uptie/threadspin field.
    levelList = getLocalizedField(skill, "levelList", Dict{String, Any}[], nothing)
    levelList === nothing && return nothing
    
    function readLevel(entry)
        haskey(entry, "level") ? entry["level"] : -1
    end
   
    return getLevelList(levelList, readLevel, tier)
end

function getInternalLevelList(skill :: CombatSkill, tier = 0)
    levelList = getInternalField(skill, "skillData", Dict{String, Any}[], nothing)
    levelList === nothing && return nothing
    
    function readLevel(entry)
        haskey(entry, "gaksungLevel") ? entry["gaksungLevel"] : -1
    end
   
    return getLevelList(levelList, readLevel, tier)
end

function getCoinValues(skill :: CombatSkill, tier = 999)
    entry = getInternalLevelList(skill, tier)
    Ans = Coin[]
    entry === nothing && return Ans
    !haskey(entry, "defaultValue") && return Ans
    
    
    push!(Ans, Coin(entry["defaultValue"], "ADD"))
    !haskey(entry, "coinList") && return Ans
    for coinStat in entry["coinList"]
        op, val = coinStat["operatorType"], coinStat["scale"]
        push!(Ans, Coin(val, op))
    end
    
    return Ans
end

function getCoinString(skill :: CombatSkill, tier = 999)
    Ans = getCoinValues(skill, tier)
    return getCoinString(Ans)
end

for (fn, field, defValue) in [(:getName, "name", ""),
                              (:getCoinDesc, "coinlist", Any[]),
                              (:getDesc, "desc", ""),
                              (:getAbName, "abName", "")]
    @eval function $fn(skill :: CombatSkill, tier = 999)
        entry = getLocalizedLevelList(skill, tier)
        entry === nothing && return nothing
        return haskey(entry, $field) ? entry[$field] : $defValue
    end
end

LocalCombatFields = [(:getType, "defType", ""),
                     (:getTier, "gaksungLevel", -1),
                     (:getOffLevelCorrection, "skillLevelCorrection", nothing),
                     (:getAbilityScriptList, "abilityScriptList", Any[]),
                     (:getCoinList, "coinList", Any[]),
                     (:getBaseValue, "defaultValue", nothing),
                     (:getSinType, "attributeType", ""),
                     (:getAtkType, "atkType", ""),
                     (:getWeight, "targetNum", ""),
                     (:getMPUsage, "mpUsage", -1000),
                     (:getIndiscriminate, "canTeamKill", nothing)]

for (fn, field, defValue) in LocalCombatFields
    @eval function $fn(skill :: CombatSkill, tier = 999)
        entry = getInternalLevelList(skill, tier)
        entry === nothing && return nothing
        return haskey(entry, $field) ? entry[$field] : $defValue
    end
end

function getMainFields(skill :: CombatSkill, tier = 999, offenseLvl = -1; verbose = false)
    Entries = String[]
    for (key, fn, defVal) in [("Type", getType, ""),
                             ("Sanity Cost", getMPUsage, -1000),
                             ("Weight", getWeight, ""),
                             ("Indiscriminate", getIndiscriminate, nothing)]
        S = fn(skill, tier)
        S == "" && continue
        S === defVal && continue
        push!(Entries, "$(@blue(key)): $(string(S))")
    end

    tmp = getOffLevelCorrection(skill, tier)
    if tmp !== nothing
        Ntmp = NumberStringWithSign(tmp)
        if offenseLvl == -1 
            push!(Entries, "$(@blue("Offense Level Corr.")): $Ntmp")
        else
            push!(Entries, "$(@blue("Offense Level")): $(offenseLvl + tmp) ($Ntmp)")
        end
    end

    LongEntries = String[]
    if verbose
        while length(Entries) % 3 != 0
            push!(Entries, "")
        end
        TmpEntries, LongEntries = getOtherFields(skill, tier)
        append!(Entries, TmpEntries)
    end

    length(Entries) == 0 && length(LongEntries) == 0 && return ""
    content = GridFromList(Entries, 3)
    if length(LongEntries) > 0
        content /= join(LongEntries, "\n") 
    end
    return content
end

getLocalizedAtkType(skill :: CombatSkill, tier = 999) = 
    AttackTypes(getAtkType(skill, tier))

function getOtherFields(skill :: CombatSkill, tier = 999)
    Entries = String[]
    LongEntries = String[]
    EntriesToSkip = [x[2] for x in LocalCombatFields]
    for (key, value) in getInternalLevelList(skill, tier)
        key in EntriesToSkip && continue
        
        Tmp = EscapeAndFlattenField(value)
        if length(Tmp) < 20
            push!(Entries, "$(key): $(Tmp)")
        else
            push!(LongEntries, "$(key): $(Tmp)")
        end
    end

    return Entries, LongEntries
end

function getDescriptionString(skill :: CombatSkill, tier = 999)
    AnsArr = String[]
    
    Str = getAbName(skill, tier)
    if Str !== nothing && Str != ""
        S = @blue("Origin") * ": $(EscapeAndFlattenField(Str))"
        push!(AnsArr, S)
    end

    Str = getDesc(skill, tier)
    shouldNotSkip = true
    (Str === nothing) && (shouldNotSkip = false)
    if Str isa Vector
        all(x -> x == "", Str) && (shouldNotSkip = false)
    end

    if shouldNotSkip
        for line in split(Str, "\n")
            push!(AnsArr, line)
        end
    end

    CoinDesc = getCoinDesc(skill, tier)
    if CoinDesc !== nothing
        for (coin, entry) in enumerate(CoinDesc)
            !haskey(entry, "coindescs") && continue
            N = length(entry["coindescs"])
            for (action, desc) in enumerate(entry["coindescs"])
                length(desc) == 0 && continue
                !haskey(desc, "desc") && @info "Unable to Parse: $desc."
                desc["desc"] == "" && continue

                descIO = IOBuffer()
                print(descIO, "Coin {red}$coin{/red}")
                N > 1 && print(descIO, " ({blue}$action{/blue})")

                print(descIO, ": $(EscapeString(desc["desc"]))")
                push!(AnsArr, String(take!(descIO)))
            end
        end
    end

    return AnsArr
end

function SkillDescriptionStringExceptions()
    return [("<Mechanical Amalgam>" => "[Mechanical Amalgam]")]
end

function getSkillExceptionChange(Str)
    for change in SkillDescriptionStringExceptions()
        Str = replace(Str, change)
    end
    return Str
end

function getNormDescriptionString(skill :: CombatSkill, tier = 999)
    StrArr = getDescriptionString(skill, tier)
    
    StrArr = getSkillExceptionChange.(StrArr)
    StrArr = replace.(StrArr, "\n" => " ", r"<[^<>]*>" => "")
    filter!(!=(""), StrArr)
    Str = join(StrArr, "\n")

    for change in getSkillReplaceDict()
        Str = replace(Str, change)
    end
    return TextBox(Str; width = 85, fit = false)
end

function getActionsString(skill :: CombatSkill, tier = 999)
    LineBreak = hLine(93, "{bold white} Actions {/bold white}"; box = :DOUBLE)
    content = LineBreak
    hasEntries = false

    for (i, Action) in enumerate(getAbilityScriptList(skill, tier))
        content /= DisplaySkillAsTree(Action, "Before Clash, Action $i")
        hasEntries = true
    end

    for (coin, entry) in enumerate(getCoinList(skill, tier))
        !haskey(entry, "abilityScriptList") && continue
        for (i, Action) in enumerate(entry["abilityScriptList"])
            content /= DisplaySkillAsTree(Action, "Coin $coin, Action $i")
            hasEntries = true
        end
    end

    hasEntries || return ""
    return content
end

function getTitle(skill :: CombatSkill, tier = 999)
    io = IOBuffer()
    Str = getName(skill, tier)
    Str !== nothing && print(io, "{red} $Str {/red}")
    print(io, " ({blue} $(getStringID(skill)) {/blue}")

    if getTier(skill) != -1
        print(io, " @ Tier : {blue}$(getTier(skill, tier)){/blue}")
    end
    print(io, ")")
        
    return  String(take!(io))
end

function getPrintTitle(skill :: CombatSkill, tier = 999)
    io = IOBuffer()
    Str = getName(skill, tier)
    hasPrinted = false
    if Str !== nothing && Str != ""
        hasPrinted = true
        print(io, Str)
    end

    Str = getStringID(skill)
    if hasPrinted
        print(io, " ($(@dim(Str)))")
    else
        print(io, Str)
    end

    return String(take!(io))
end

function getSubtitle(skill :: CombatSkill, tier = 999)
    io = IOBuffer()
    Str = getSinType(skill, tier)
    if Str == ""
        print(io, "No Attribute")
    else
        print(io, getSinString(Str))
    end

    Str = getLocalizedAtkType(skill, tier)
    Str != "" && print(io, ", $(getLocalizedAtkType(skill, tier))")

    Str = getCoinString(skill, tier)
    Str != "" && print(io, " {underline} $Str {/underline}")
    return String(take!(io))
end

function InternalSkillPanel(skill :: CombatSkill, 
    tier = 999, offenseLvl = -1; 
    verbose = true, addedTitle = "", addedSubtitle = "")
    
    Title = addedTitle * getTitle(skill, tier)
    content = getNormDescriptionString(skill, tier)
    mySub = addedSubtitle * getSubtitle(skill, tier)

    MainFields = getMainFields(skill, tier, offenseLvl; verbose)
    if MainFields != ""
        LineBreak = hLine(93, "{bold white} Fields {/bold white}"; box = :DOUBLE)
        content /= LineBreak
        content /= TextBox(MainFields; width = 93, fit = false)
    end

    if verbose
        content /= getActionsString(skill, tier)
    end

    return output = Panel(
    content,
    title = Title,
    subtitle = mySub,
    subtitle_justify = :right,
    width = 100,
    fit = false)
end