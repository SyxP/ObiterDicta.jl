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
    for item in StaticData(file)["list"]
        push!(MasterList, EGOGift(item["id"]))
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
        for entry in EGOGiftList["dataList"]
            if entry["id"] == myEGOGift.id
                return entry
            end
        end
    end


    dontWarn || @warn "No Localized EGO Gift matching $(myEGOGift.id) found."
    return
end