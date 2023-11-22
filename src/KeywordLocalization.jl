function getSinString(str)
    myDict = loadColourToSinDict()
    newStr = ""
    colour = getHexFromColour(str)
    if !haskey(myDict, str)
        @warn "Unable to Parse Colour $str."
        return str
    end

    return "{$colour}" * myDict[str] * "{/$colour}"
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
        "NEUTRAL" => "202020"
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

    return ReplacementDict
end

function AttackTypes(S)
    ReplaceDict = Dict("HIT" => "Blunt",
                       "PENETRATE" => "Pierce",
                       "SLASH" => "Slash",
                       "NONE" => "None") 
    return haskey(ReplaceDict, S) ? ReplaceDict[S] : S
end