struct EGO
    id :: Int
end

# ego-empty are placeholders for EGO not in game yet.
getMasterFileClasses(::Type{EGO}) = ["ego"]
getMaxThreadspin(::Type{EGO}) = 4

function handleDataFile(::Type{EGO}, MasterList, file)
    for item in StaticData(file)["list"]
        push!(MasterList, EGO(item["id"]))
    end
end

EGOMasterList = EGO[]
function getMasterList(::Type{EGO})
    getMasterList(EGO, EGOMasterList)
end

function getInternalList(::Type{EGO})
    Files = getMasterFileList(EGO)
    [StaticData(file) for file in Files]
end

function getLocalizedList(::Type{EGO})
    Files = getLocalizeDataInfo()["ego"]
    [LocalizedData(file) for file in Files]
end

function getInternalVersion(myEGO :: EGO; dontWarn = !GlobalDebugMode)
    for EGOList in getInternalList(EGO)
        for entry in EGOList["list"]
            if entry["id"] == myEGO.id
                return entry
            end
        end
    end

    dontWarn || @info "No Internal EGO matching $(myEGO.id) found."
    return
end

function getLocalizedVersion(myEGO :: EGO; dontWarn = !GlobalDebugMode)
    for EGOList in getLocalizedList(EGO)
        for entry in EGOList["dataList"]
            if entry["id"] == myEGO.id
                return entry
            end
        end
    end

    dontWarn || @info "No Localized EGO matching $(myEGO.id) found."
    return
end

### Retrieval
getID(ego :: EGO) = ego.id
getStringID(ego :: EGO) = string(ego.id)
getTitle(ego :: EGO) = getLocalizedField(ego, "name", "", "")

InternalEGOFields = [(:getPassiveList, "awakeningPassiveList", Any[]),
                     (:getEGOClass, "egoClass", -1),
                     (:getEGOType, "egoType", ""),
                     (:getSinnerID, "characterId", -1),
                     (:getRequirement, "requirementList", Any[]),
                     (:getSeason, "season", -1),
                     (:getAdditionalAttachment, "additionalAttachment", ""),
                     (:getConferredResistance, "attributeResistList", Any[]),
                     (:getAwakeningSkill, "awakeningSkillId", -1),
                     (:getCorrosionSkill, "corrosionSkillId", -1),
                     (:getCorrosionProb, "corrosionSectionList", [])]

for (fn, field, default) in InternalEGOFields 
    @eval $fn(ego :: EGO) =
        getInternalField(ego, $field, $default, nothing)
end

function getOtherFields(ego :: EGO)
    Entries = String[]
    LongEntries = String[]
    EntriesToSkip = [x[2] for x in InternalEGOFields]
    for (key, value) in getInternalVersion(ego)
        key in EntriesToSkip && continue
        if key == "skillTier"
            push!(Entries, "Skill Tier: $(value)")
            continue
        end
        key == "id" && continue

        Tmp = EscapeAndFlattenField(value)
        if length(Tmp) < 20
            push!(Entries, "$(key): $(Tmp)")
        else
            push!(LongEntries, "$(key): $(Tmp)")
        end
    end

    return Entries, LongEntries
end

function getConferredResistanceStr(ego :: EGO; verbose)
    AnsArr = String[]
    
    for entry in getConferredResistance(ego)
        Tmp = entry["type"]
        if !verbose && Tmp ∈ ["WHITE", "BLACK"]
            continue
        end
        sinType = getSinString(Tmp)
        sinValue = entry["value"]
        S = "$sinType res.: $sinValue×"
        push!(AnsArr, S)
    end
    
    return AnsArr
end

function isEvent(ego :: EGO)
    S = getAdditionalAttachment(ego)
    if S ∉ ["EVENT", ""]
        @info "Unable to parse Additional Attachment $S"
    end
    return S == "EVENT"
end
function getSeasonStr(ego :: EGO)
    N = getSeason(ego)
    
    Ans = getSeasonNameFromInt(N)
    (isEvent(ego)) && (Ans *= " [Event]")
    
    return Ans
end

function getCorrosionProbStr(ego :: EGO)
    AnsArr = String[]
    for entry in getCorrosionProb(ego)
        section = string(entry["section"])
        prob    = string(entry["probability"])
        push!(AnsArr, "$(@blue(section)): $prob")
    end

    return join(AnsArr, @dim("; "))
end

function getMainFields(ego :: EGO; verbose)
    Fields = getConferredResistanceStr(ego; verbose = verbose)
    LongFields = String[]
    function AddField(FieldName, FieldValue)
        FieldStr = @blue(FieldName)*": $(FieldValue)"
        if length(FieldStr) > 40
            push!(LongFields, FieldStr)
        else
            push!(Fields, FieldStr)
        end
    end

    push!(LongFields, " " * getSeasonStr(ego))
    AddField("Corrosion Prob.", getCorrosionProbStr(ego))
    if verbose
        Entries, LongEntries = getOtherFields(ego)
        append!(Fields, Entries)
        append!(LongFields, LongEntries)
    end

    egoVoice = getEGOVoiceStrings(EGOVoice, getID(ego))
    append!(LongFields, egoVoice)

    Content = GridFromList(Fields, 4)
    Content /= join(LongFields, "\n ")

    return Content
end

function getRequirementStr(ego :: EGO)
    EGOMats = String[]
    for entry in getRequirement(ego)
        try
            SinType = getSinString(entry["attributeType"])
            Amount  = entry["num"]
            push!(EGOMats, "$SinType×$Amount")
        catch _
            @warn "Unable to parse EGO requirement: $entry"
        end
    end

    return join(EGOMats, @dim("; "))
end

getSearchTitle(ego :: EGO) = getSinnerName(getSinnerID(ego))*getTitle(ego)
function getFullTitle(ego :: EGO)
    io = IOBuffer()
    SinnerName = getSinnerName(getSinnerID(ego))
    print(io, "⟨"*@blue(SinnerName)*"⟩")
    print(io, " ")
    print(io, getTitle(ego))
    print(io, " (")
    print(io, @dim(getStringID(ego)))
    print(io, ")")

    return String(take!(io))
end
function getFullTitle(ego :: EGO, threadspin)
    getFullTitle(ego) * " @ Threadspin $threadspin"
end
function getSubtitle(ego :: EGO)
    io = IOBuffer()
    print(io, getEGOType(ego))
    print(io, " - ")
    print(io, getRequirementStr(ego))
    return String(take!(io))
end

function getTopPanel(ego :: EGO, threadspin = getMaxThreadspin(EGO); verbose = false)
    title = getFullTitle(ego, threadspin)
    subtitle = getSubtitle(ego)
    content = getMainFields(ego; verbose = verbose)

    return output = Panel(
        content,
        title=title,
        subtitle=subtitle,
        subtitle_justify=:right,
        width=100,
        fit=false)
end

function getSkillPanel(ego :: EGO, threadspin; verbose = false)
    awakeningSkill = getAwakeningSkill(ego)
    corrosionSkill = getCorrosionSkill(ego)
    
    Panels = Panel[]
    if awakeningSkill != -1
        CSawakeSkill = CombatSkill(awakeningSkill)
        S = InternalSkillPanel(CSawakeSkill, threadspin; verbose = verbose)
        push!(Panels, S)
    end
    if corrosionSkill != -1
        CScorrodeSkill = CombatSkill(corrosionSkill)
        S = InternalSkillPanel(CScorrodeSkill, threadspin; verbose = verbose)
        push!(Panels, S)
    end

    return vstack(Panels...)
end

function getPassivePanel(ego :: EGO, threadspin; verbose = false)
    S = Passive.(getPassiveList(ego))
    Panels = Panel[]
    threadspin == 1 && return vstack(Panels...)
    if length(S) == 1
        push!(Panels, PassivePanel(S[1]; subtitle = "Passive"))
    else
        for (idx, entry) in enumerate(S)
            push!(Panels, PassivePanel(entry; subtitle = "Passive $idx"))
        end
    end

    return vstack(Panels...)
end

function getFullPanel(ego :: EGO, threadspin = getMaxThreadspin(EGO); verbose = false)
    Ans = getTopPanel(ego, threadspin; verbose)
    Ans /= getSkillPanel(ego, threadspin; verbose)
    Ans /= getPassivePanel(ego, threadspin; verbose)

    return Ans
end