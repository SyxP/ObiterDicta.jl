# Includes Observation Level Stories. Not implemented.

struct AbnormalityGuide
    id :: Int
end

getLocalizedFolders(::Type{AbnormalityGuide}) = ["abnormalityGuideContent"]

function getLocalizedVersion(myAbnormality :: AbnormalityGuide; dontWarn = !GlobalDebugMode)
    for AbnormalityList in getLocalizedList(AbnormalityGuide)
        if !haskey(AbnormalityList, "dataList")
            if (length(AbnormalityList) > 0)
                @warn "Unable to read Localized Abnormality List"
            end
            return
        end

        for entry in AbnormalityList["dataList"]
            if entry["id"] == myAbnormality.id
                return entry
            end
        end
    end

    dontWarn || @warn "No Localized Abnormality matching $(myAbnormality.id) found."
    return
end

function getGuide(abno :: AbnormalityEnemyUnit)
    return AbnormalityGuide(abno.id)
end

### Retrieval
getID(guide :: AbnormalityGuide) = guide.id
getID(abno :: AbnormalityEnemyUnit) = (getGuide(abno)).id 

LocalizedAbnormalityFields = [
    (:getGuideCodeName, "codeName", ""),
    (:getGuideName, "name", ""),
    (:getGuideClue, "clue", ""), # Rarely Used
    (:getGuideStoryList, "storyList", Dict{String, Any}[])
]

for (fn, field, default) in LocalizedAbnormalityFields
    @eval $fn(guide :: AbnormalityGuide) = getLocalizedField(guide, $field, $default, $default)
    @eval $fn(abno :: AbnormalityEnemyUnit) = ($fn)(getGuide(abno))
end
