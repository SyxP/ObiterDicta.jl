SteamNewsURL = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid=1973530&count=300&format=json"

function getSteamNewsJSON()
    data = Downloads.download(SteamNewsURL)
    return JSON.parsefile(data)["appnews"]["newsitems"]
end