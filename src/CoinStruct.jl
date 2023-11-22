struct Coin
    value :: Int
    operation :: String
end

function getCoinString(coinList :: Vector{Coin})
    length(coinList) == 0 && return ""
    if coinList[begin].operation != "ADD"
        @info "Unable to parse $coinList."
        return ""
    end
    length(coinList) == 1 && return string(coinList[begin].value)
    io = IOBuffer()
    print(io, coinList[begin].value)
            
    OpDict = Dict{String, String}("ADD" => "+", "SUB" => "-", "MUL" => "×")

    CurrOp, CurrVal = coinList[2].operation, coinList[2].value
    CurrIter = 1
    for coin in coinList[3:end]
        if CurrOp == coin.operation && CurrVal == coin.value
            CurrIter += 1
        else
            print(io, " ($(OpDict[CurrOp]) $CurrVal)")
            (CurrIter > 1) && print(io, "×$CurrIter")

            CurrOp, CurrVal = coin.operation, coin.value
            CurrIter = 1
        end
    end

    print(io, " ($(OpDict[CurrOp]) $CurrVal)")
    (CurrIter > 1) && print(io, "×$CurrIter")

    return String(take!(io))
end