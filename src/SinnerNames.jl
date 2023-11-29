function getSinnerName(id)
    SinnerName = LocalizedData("Characters")["dataList"]
    for item in SinnerName
        if item["id"] == id
            return item["name"]
        end
    end

    return ""
end