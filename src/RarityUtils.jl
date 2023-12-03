function getRarityString(num :: Int)
    Yellow0 = @yellow("0")

    if 1 ≤ num ≤ 3
        return Yellow0^num
    else
        @info "Unable to parse Rarity String: $num"
        return ""
    end
end

function getRarityFromString(strInput :: String)
    str = uppercase(strInput)
    if str == "1*" || str == "0" || str == "O"
        return 1
    elseif str == "2*" || str == "00" || str == "OO"
        return 2
    elseif str == "3*" || str == "000" || str == "OOO"
        return 3
    else
        GlobalDebugMode && @info "Unable to parse Rarity String: $str"
        return 0
    end
end