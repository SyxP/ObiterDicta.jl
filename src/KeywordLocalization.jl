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
    Mapping = Dict{String, String}(
        "CRIMSON" => "red",
        "SCARLET" => "#FFA500",
        "AMBER" => "#CFAF00",
        "SHAMROCK" => "green",
        "AZURE" => "blue",
        "INDIGO" => "#4B0082",
        "VIOLET" => "#7F00FF"
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

    return myDict
end