function getLocalizedList(::Type{EGOVoice})
    Files = getLocalizeDataInfo()["egoVoice"]
end

function getSinnerVersion(::Type{EGOVoice}, id)
    localData = getLocalizedList(EGOVoice)
    for file in localData
        S = match(r"([0-9]+)", file)
        if S !== nothing
            N = parse(Int, S.captures[1])
            if N == id
                return LocalizedData(file)["dataList"]
            end
        end
    end

    return nothing
end

function getEGOVoiceStrings(::Type{EGOVoice}, egoID)
    sinnerID = (egoID ÷ 100) % 100
    sinnerVersion = getSinnerVersion(EGOVoice, sinnerID)
    
    function filterEntries(entry)
        S = haskey(entry, "id") ? entry["id"] : ""
        return occursin(string(egoID), S)
    end

    function getEntryString(entry)
        io = IOBuffer()
        print(io, haskey(entry, "desc") ? entry["desc"] : "")
        print(io, " (")
        print(io, @red(haskey(entry, "id") ? entry["id"] : ""))
        print(io, "): ")
        print(io, haskey(entry, "dlg") ? entry["dlg"] : "")

        return String(take!(io))
    end
    matchingList = filter(filterEntries, sinnerVersion)

    return getEntryString.(matchingList)
end