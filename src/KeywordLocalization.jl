function getSinString(str)
    myDict = loadColourToSinDict()
    newStr = ""
    colour = getHexFromColour(str)
    if !haskey(myDict, str)
        @warn "Unable to Parse Colour $str."
        return str
    end

    return Term.Style.apply_style("{$colour}" * myDict[str] * "{/$colour}")
end

function getHexFromColour(colour)
    # TODO : Change this to use ui/ColorCode.json
    Mapping = Dict{String, String}(
        "CRIMSON" => "red",
        "SCARLET" => "#FFA500",
        "AMBER" => "#CFAF00",
        "SHAMROCK" => "green",
        "AZURE" => "blue",
        "INDIGO" => "#4B0082",
        "VIOLET" => "#7F00FF",
        "NEUTRAL" => "202020",
        "BLACK" => "black",
        "WHITE" => "CCCCCC"
    )
    if !haskey(Mapping, colour)
        @warn "Unable to Parse Colour $colour."
        return ""
    end

    return Mapping[colour]
end

function loadColourToSinDict()
    ColourDB = LocalizedData("AttributeText")["dataList"]
    myDict = Dict{String, String}()
    for Colour in ColourDB
        myDict[Colour["id"]] = Colour["name"]
    end

    myDict["NEUTRAL"] = "Neutral"
    return myDict
end

function getSkillReplaceDict()
    ReplacementDict = Dict{String, String}()
    for file in getLocalizeDataInfo()["skillTag"]
        for entry in LocalizedData(file)["dataList"]
            ReplacementDict["[$(entry["id"])]"] = entry["name"]
        end
    end
    for file in getLocalizeDataInfo()["keyword"]
        for entry in LocalizedData(file)["dataList"]
            ReplacementDict["[$(entry["id"])]"] = entry["name"]
        end
    end

    return ReplacementDict
end

function getEGOGiftKeywordDict()
    ReplacementDict = Dict{String, String}()
    for file in getLocalizeDataInfo()["egoGiftCategory"]
        for entry in LocalizedData(file)["dataList"]
            ReplacementDict[entry["id"]] = entry["name"]
        end
    end

    return ReplacementDict
end
function getEGOGiftKeywordFromAttribute()
    oldDict = getEGOGiftKeywordDict()
    replaceDict = Dict{String, String}()

    for (key, value) in oldDict
        buff = Buff(key)
        attributeType = getAttributeType(buff)
        colourValue = "Random"
        if attributeType != ""
            colour = getHexFromColour(attributeType)
            colourValue = Term.Style.apply_style("{$colour}" * value * "{/$colour}")
        end

        replaceDict[attributeType] = colourValue
    end

    return replaceDict
end
function getKeywordSinString(attributeType)
    replaceDict = getEGOGiftKeywordFromAttribute()
    return replaceDict[attributeType]
end

function getClosestSinFromName(str)
    Haystack = Tuple{String, String}[]
    for entry in LocalizedData("AttributeText")["dataList"]
        push!(Haystack, (entry["name"], entry["id"]))
        push!(Haystack, (entry["id"], entry["id"]))
    end

    for entry in LocalizedData("AttributeText", English)["dataList"]
        push!(Haystack, (entry["name"], entry["id"]))
    end
    for nullStr in ["Neutral", "Nothing", "None"]
        push!(Haystack, (nullStr, "NEUTRAL"))
    end
    
    return SearchClosestString(str, Haystack)[1][2]
end

function AttackTypes(S)
    ReplaceDict = Dict("HIT" => "Blunt",
                       "PENETRATE" => "Pierce",
                       "SLASH" => "Slash",
                       "NONE" => "None") 
    return haskey(ReplaceDict, S) ? ReplaceDict[S] : S
end

function getClosestAtkTypeFromName(str)
    Haystack = [("hit", "HIT"),
                ("blunt", "HIT"),
                ("penetrate", "PENETRATE"),
                ("pierce", "PENETRATE"),
                ("slash", "SLASH")]

    for nullStr in ["Neutral", "Nothing", "None"]
        push!(Haystack, (nullStr, "NONE"))
    end
    return SearchClosestString(str, Haystack)[1][2]
end

function getSeasonNameFromInt(N)
    # Hardcoded Function

    if N == 0
        Ans = "Season 0"
    elseif N == 1
        Ans = "Season 1: Orientation"
    elseif N == 2
        Ans = "Season 2: Reminiscence"
    elseif N == 3
        Ans = "Season 3: Bon Voyage"
    elseif N == 9101
        Ans = "Walpurgis Night"
    else
        @info "Unknown Season $N"
    end

    return Ans
end

function getSeasonIDFromName(Str)
    Haystack = Tuple{String, Int}[]
    function AddEntry(SeasonID, ListOfSeasonName)
        for SeasonName in ListOfSeasonName
            push!(Haystack, (SeasonName, SeasonID))
        end
    end

    AddEntry(0, ["S0", "0", "Season0", "SeasonZero", "Zero"])
    AddEntry(1, ["S1", "1", "Season1", "SeasonOne", "One", "Orientation"])
    AddEntry(2, ["S2", "2", "Season2", "SeasonTwo", "Two", "Reminiscence"])
    AddEntry(3, ["S3", "3", "Season3", "SeasonThree", "Three", "BonExpedition"])
    AddEntry(9101, ["Walpurgis Night", "Walpurgisnacht", "9101"])

    return SearchClosestString(Str, Haystack)[1][2]
end

getEGOTiers() = ["ZAYIN", "TETH", "HE", "WAW", "ALEPH"]
function getClosestEGOType(str)
    Haystack = Tuple{String, String}[]
    for (idx, class) in enumerate(getEGOTiers())
        push!(Haystack, (string(idx), class))
        push!(Haystack, (class, class))
    end

    return SearchClosestString(str, Haystack)[1][2]
end