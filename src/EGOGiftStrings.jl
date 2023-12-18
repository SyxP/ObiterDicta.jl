abstract type EGOGift end
struct StoryEGOGift <: EGOGift
    id :: Int
end

struct MirrorDungeonEGOGift <: EGOGift
    id :: Int
end

struct HellsChickenDungeonEGOGift <: EGOGift
    id :: Int
end

getMasterFileClasses(::Type{StoryEGOGift}) = ["ego-gift"]
getMasterFileClasses(::Type{MirrorDungeonEGOGift}) = ["ego-gift-mirrordungeon"]
getMasterFileClasses(::Type{HellsChickenDungeonEGOGift}) = ["ego-gift-hellschickendungeon"]
getMaxTier(::Type{T}) where T <: EGOGift = 3

function handleDataFile(::Type{T}, MasterList, file) where T <: EGOGift
    staticDB = StaticData(file)
    if !haskey(staticDB, "list")
        if length(keys(staticDB)) > 0
            @info "Unknown File Format $file : $(keys(staticDB))"
        end
        return
    end

    for item in staticDB["list"]
        push!(MasterList, T(item["id"]))
    end
end

StoryEGOGiftMasterList = StoryEGOGift[]
MDEGOGiftMasterList    = MirrorDungeonEGOGift[]
HCDGOGiftMasterList    = HellsChickenDungeonEGOGift[]

for (typeEGO, masterList) = [(StoryEGOGift, StoryEGOGiftMasterList),
                             (MirrorDungeonEGOGift, MDEGOGiftMasterList),
                             (HellsChickenDungeonEGOGift, HCDGOGiftMasterList)]
    @eval function getMasterList(::Type{$typeEGO})
        getMasterList($typeEGO, $masterList)
    end
end

function egoGiftTypes()
    return [StoryEGOGift, MirrorDungeonEGOGift, HellsChickenDungeonEGOGift]
end
function getMasterFileClasses(::Type{EGOGift})
    Lst = [getMasterFileClasses(tEGOGifts) for tEGOGifts in egoGiftTypes()]
    return foldl(vcat, Lst)
end
function getMasterFileList(::Type{EGOGift})
    Lst = [getMasterFileList(tEGOGifts) for tEGOGifts in egoGiftTypes()]
    return foldl(vcat, Lst)
end
function getMasterList(::Type{EGOGift})
    Types = [StoryEGOGift, MirrorDungeonEGOGift]
    Lst = [getMasterList(tEGOGifts) for tEGOGifts in Types]
    return foldl(vcat, Lst)
end

function getInternalList(::Type{T}) where T <: EGOGift
    Files = getMasterFileList(T)
    [StaticData(file) for file in Files]
end

function getLocalizedList(::Type{T}) where T <: EGOGift
    Files = getLocalizeDataInfo()["egoGifts"]
    [LocalizedData(file) for file in Files]
end

function getInternalVersion(myEGOGift :: T; dontWarn = !GlobalDebugMode) where T <: EGOGift
    for EGOGiftList in getInternalList(T)
        haskey(EGOGiftList, "list") || continue
        for entry in EGOGiftList["list"]
            if entry["id"] == myEGOGift.id
                return entry
            end
        end
    end

    dontWarn || @warn "No Internal EGO Gift matching $(myEGOGift.id) found."
    return
end

function getLocalizedVersion(myEGOGift :: T; dontWarn = !GlobalDebugMode) where T <: EGOGift
    for EGOGiftList in getLocalizedList(T)
        haskey(EGOGiftList, "dataList") || continue
        for entry in EGOGiftList["dataList"]
            if entry["id"] == myEGOGift.id
                return entry
            end
        end
    end


    dontWarn || @warn "No Localized EGO Gift matching $(myEGOGift.id) found."
    return
end

### Retrieval Functions 

getID(myEGOGift :: T) where T <: EGOGift = myEGOGift.id
getStringID(myEGOGift :: T) where T <: EGOGift = string(getID(myEGOGift))

EGOGiftInternalFields = [(:getPrice, "price"),
                         (:getTag, "tag"),
                         (:getAttributeType, "attributeType"),
                         (:getKeyword, "keyword"),
                         (:getUpgradeDataList, "upgradeDataList"),
                         (:getLockType, "lockType")]

for (func_name, field_name) in EGOGiftInternalFields
    @eval function $(func_name)(myEGOGift :: T) where T <: EGOGift
        getInternalField(myEGOGift, $(field_name), nothing, nothing)
    end
end

function getName(myEGOGift :: T) where T <: EGOGift
    getLocalizedField(myEGOGift, "name", "", "")
end
function getDesc(myEGOGift :: T) where T <: EGOGift
    getLocalizedField(myEGOGift, "desc", nothing, "")
end
function getEscapedDesc(myEGOGift :: T) where T <: EGOGift
    S = getDesc(myEGOGift)
    S === nothing && return nothing

    upgradeS = replace(S, r"<style=\"upgradeHighlight\">([^<>]*)</style>" => s"{red}\1{/red}")
    upgradeS = Term.Style.apply_style(upgradeS)
    return EscapeString(replaceSkillTag(upgradeS))
end

function getTier(myEGOGift :: T) where T <: EGOGift
    tags = getTag(myEGOGift)
    tags === nothing && return nothing
    for tag in tags
        S = match(r"TIER_(\d+)", tag)
        if S !== nothing
            return parse(Int, (S.captures)[1])
        end
    end

    return -1
end
function getTierString(myEGOGift :: T) where T <: EGOGift
    tier = getTier(myEGOGift)
    tier === nothing && return nothing
    tier == -1 && return @red("No tier found.")
    return "$(@blue("Tier")): $(string(tier))"
end

function getTypeKeyword(myEGOGift :: T) where T <: EGOGift
    kWord = getKeyword(myEGOGift)
    kWord === nothing && return nothing
    replaceDict = getEGOGiftKeywordDict()
    return haskey(replaceDict, kWord) ? replaceDict[kWord] : kWord
end
function getOtherTags(myEGOGift :: T) where T <: EGOGift
    tags = getTag(myEGOGift)
    tags === nothing && return nothing
    newTags = filter(x -> !startswith(x, "TIER_"), tags)
    return length(newTags) > 0 ? newTags : nothing
end

function hasUpgrade(myEGOGift :: T) where T <: EGOGift
    dataList = getUpgradeDataList(myEGOGift)
    dataList === nothing && return false
    return length(dataList) > 1
end
function getLocalizedUpgradeGifts(myEGOGift :: T) where T <: EGOGift
    hasUpgrade(myEGOGift) || return [(1, myEGOGift)]
    dataList = getUpgradeDataList(myEGOGift)
    return [(entry["upgradeLevel"] + 1, T(entry["localizeID"])) for entry in dataList if haskey(entry, "localizeID")]
end
function isHidden(myEGOGift :: T) where T <: EGOGift
    return getLocalizedVersion(myEGOGift) === nothing
end

function getSearchTitle(myEGOGift :: T) where T <: EGOGift
    return getName(myEGOGift)
end
function getTitle(myEGOGift :: T) where T <: EGOGift
    strArr = String[]

    name = getName(myEGOGift)
    if name != ""
        push!(strArr, @red(name))
    end
    id = getStringID(myEGOGift)
    if id !== nothing
        if name !== "" 
            push!(strArr, "("*@blue(id)*")")
        else
            push!(strArr, @blue(id))
        end
    end

    return join(strArr, " ")
end

function getContent(myEGOGift :: T) where T <: EGOGift
    io = IOBuffer()
    for (idx, upgradeGifts) in getLocalizedUpgradeGifts(myEGOGift)
        desc = getEscapedDesc(upgradeGifts)
        prefixIdx = ""
        if hasUpgrade(myEGOGift)
            prefixIdx = idx == 1 ? "Base " : "+"^(idx - 1) * " "
            prefixIdx = rpad(prefixIdx, 5)
        end
        if desc !== nothing && desc != ""
            println(io, "$(@blue(prefixIdx*"Description")): $desc")
        end
    end
        
    for (fn, name) in []
        Tmp = fn(myEGOGift)
        (Tmp !== nothing) && println(io, "$(@blue(name)): $Tmp")
    end

    mainFieldStrings = String[]
    if getTierString(myEGOGift) !== nothing
        push!(mainFieldStrings, getTierString(myEGOGift))
    end
    for (fn, name) in [(getTypeKeyword, "Keywords"),
                       (getOtherTags, "Other Tags"),
                       (getLockType, "Lock Type")]
        Tmp = fn(myEGOGift)
        (Tmp !== nothing) && push!(mainFieldStrings, "$(@blue(name)): $(string(Tmp))")
    end
    print(io, join(mainFieldStrings, "   "))

    Ans = TextBox(String(take!(io)); width = 93, fit = false)
    return Ans
end

function getOtherFields(myEGOGift :: T) where T <: EGOGift
    Entries = String[]
    function addEntry(key, value)
        Tmp = EscapeAndFlattenField(value)
        escKey = EscapeAndFlattenField(key)
        push!(Entries, "$(escKey): $(Tmp)")
    end
    
    EntriesToSkip = [x[2] for x in EGOGiftInternalFields]
    for (key, value) in getInternalVersion(myEGOGift)
        key in EntriesToSkip && continue
        key in ["id"] && continue
        addEntry(key, value)
    end

    localGifts = getLocalizedUpgradeGifts(myEGOGift)
    if localGifts !== nothing
        for (idx, localGift) in localGifts
            getLocalizedVersion(localGift) === nothing && continue
            for (key, value) in getLocalizedVersion(localGift)
                key in ["name", "id", "simpleDesc", "desc"] && continue
                addEntry(key, value)
            end
        end
    end

    Content = ""
    (length(Entries) > 0) && (Content = join(Entries, "\n "))

    if localGifts !== nothing
        for (idx, localGift) in localGifts
            getLocalizedVersion(localGift) === nothing && continue
            for (key, value) in getLocalizedVersion(localGift)
                key == "simpleDesc" || continue
                for (subidx, entry) in enumerate(value)
                    prefix = ""
                    if hasUpgrade(myEGOGift)
                        prefix = idx == 1 ? "Base " : "+"^(idx - 1) * " "
                        prefix = rpad(prefix, 5)
                    end
                    code = haskey(entry, "abilityID") ? " ($(@dim(string(entry["abilityID"]))))" : ""
                    escEntry = EscapeString(replaceSkillTag(entry["simpleDesc"]))
                    S = "$(prefix)Desc $(subidx)$code: $escEntry"
                    Content /= S
                end
            end
        end
    end

    Content = completeStrip(Content)
    hasEntries = length(Content) > 0
    return hasEntries, Content
end

function getSubtitle(myEGOGift :: T) where T <: EGOGift
    strArr = String[]

    sinAffinity = getAttributeType(myEGOGift)
    if sinAffinity !== nothing
        push!(strArr, getSinString(sinAffinity))
    end    

    price = getPrice(myEGOGift)
    if price !== nothing
        push!(strArr, "($(string(price)) cost)")
    end

    return join(strArr, " ")
end

function EGOGiftPanel(myEGOGift :: T, verbose) where T <: EGOGift
    title = getTitle(myEGOGift)
    subtitle = getSubtitle(myEGOGift)
    
    content = getContent(myEGOGift)
    hasEntries, OtherFields = getOtherFields(myEGOGift)
    if verbose && hasEntries 
        content /= LineBreak("Other Fields")
        content /= TextBox(OtherFields; width = 93, fit = false)
    end
    
    return Panel(
        content,
        title = title, 
        subtitle = subtitle,
        subtitle_justify = :right,
        width = 100,
        fit = false
    )
end

function toString(myEGOGift :: T; verbose = false) where T <: EGOGift
    io = IOBuffer()
    println(io, EGOGiftPanel(myEGOGift, verbose))
    return String(take!(io))
end
