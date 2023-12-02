function getSinnerName(id)
    SinnerName = LocalizedData("Characters")["dataList"]
    for item in SinnerName
        if item["id"] == id
            return item["name"]
        end
    end

    return ""
end

function getClosestSinnerIDFromName(name)
    SinnerName = LocalizedData("Characters")["dataList"]
    haystack = [(item["name"], item["id"]) for item in SinnerName]
    SinnerName = LocalizedData("Characters", English)["dataList"]
    append!(haystack, [(item["name"], item["id"]) for item in SinnerName])

    return SearchClosestString(name, haystack)[1][2]
end