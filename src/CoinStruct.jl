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

function numCoins(coinList :: Vector{Coin})
    length(coinList) - 1 # First coin is always supposed to be base coin.
end

function extremaValues(coinList :: Vector{Coin})
    length(coinList) == 0 && return 0, 0
    if coinList[begin].operation != "ADD"
        @info "Unable to parse $coinList."
        return 0, 0
    end

    baseCoin = coinList[begin].value
    minPossible, maxPossible = baseCoin, baseCoin
    for coin in coinList[2:end]
        headRoll, tailRoll = 0, 0
        if coin.operation == "ADD"
            headRoll = maxPossible + coin.value
            tailRoll = minPossible
        elseif coin.operation == "SUB"
            headRoll = minPossible - coin.value
            tailRoll = maxPossible
        elseif coin.operation == "MUL"
            headRoll = maxPossible * coin.value
            tailRoll = minPossible
        else
            @info "Unable to parse $coin."
            return 0, 0
        end
        
        maxPossible = max(maxPossible, headRoll, tailRoll)
        minPossible = min(minPossible, headRoll, tailRoll)
        maxPossible = max(0, maxPossible)
        minPossible = max(0, minPossible)
    end
    return minPossible, maxPossible 
end

minRoll(coinList :: Vector{Coin}) = extremaValues(coinList)[1]
maxRoll(coinList :: Vector{Coin}) = extremaValues(coinList)[2]