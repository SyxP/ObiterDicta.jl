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

CoinRegex = r"^([0-9]*)(\([+-×*][0-9]+\)([×*x][0-9]+)?)+$"

function getCoinVecFromString(str)
    NewStr = replace(str, r"[^0-9\(\)+\-*×x]" => "")
    if !occursin(CoinRegex, NewStr)
        @info "Unable to parse to Coin String $str."
        return
    end
    
    Vec = split(NewStr, "(")
    Ans = Coin[]
    push!(Ans, Coin(parse(Int, Vec[1]), "ADD"))
    for entry in Vec[2:end]
        operation = entry[begin]
        opStr = ""
        if operation == '+'
            opStr = "ADD"
        elseif operation == '-'
            opStr = "SUB"
        elseif operation ∈ "×x*"
            opStr = "MUL"
        end
        Reps = 1
        SplitStr = split(entry, ")")
        Value = parse(Int, SplitStr[1][2:end])
        if length(SplitStr) == 2 && length(SplitStr[2]) > 1
            Reps = parse(Int, SplitStr[2][2:end])
        end
        append!(Ans, fill(Coin(Value, opStr), Reps))
    end

    return Ans
end 

function increasePlusCoinPower(coinList :: Vector{Coin}, power :: Int)
    length(coinList) == 0 && return coinList
    Ans = [coinList[1]]
    for coin in coinList[2:end]
        if coin.operation == "ADD"
            push!(Ans, Coin(coin.value + power, coin.operation))
        else
            push!(Ans, coin)
        end
    end
    return Ans
end

function increaseMinusCoinPower(coinList :: Vector{Coin}, power :: Int)
    length(coinList) == 0 && return coinList
    Ans = [coinList[1]]
    for coin in coinList[2:end]
        if coin.operation == "SUB"
            push!(Ans, Coin(coin.value - power, coin.operation))
        else
            push!(Ans, coin)
        end
    end
    return Ans
end

function augmentBasePower(coinList :: Vector{Coin}, power :: Int)
    Ans = Coin[]
    for (i, coin) in enumerate(coinList)
        if coin.operation == "ADD" && i == 1
            push!(Ans, Coin(coin.value + power, coin.operation))
        else
            push!(Ans, coin)
        end
    end
    return Ans
end

function increaseCoinPower(coinList :: Vector{Coin}, power :: Int)
    Ans = increasePlusCoinPower(coinList, power)
    Ans = increaseMinusCoinPower(Ans, power)
    return Ans
end

function evaluateOnce(coinList :: Vector{Coin}, finalpower :: Int, sanity :: Int)
    Ans = coinList[begin].value
    headChance = (50+sanity)/100

    for coin in coinList[2:end]
        rand() > headChance && continue
        if coin.operation == "ADD"
            Ans += coin.value
        elseif coin.operation == "SUB"
            Ans = max(coin.value - Ans, 0)
        elseif coin.operation == "MUL"
            Ans *= coin.value
        end
    end
    return Ans + finalpower
end

# Naive Clash simulator. Doesn't take into account status effects.
function clashEvaluateSkills(skill1 :: Vector{Coin}, finalpower1 :: Int, sanity1 :: Int,
                             skill2 :: Vector{Coin}, finalpower2 :: Int, sanity2 :: Int; Iters = 100_000)
    s1WonFirstClash, s2WonFirstClash = 0, 0
    # 0 is a tie
    # Positive is skill1 won. Negative is skill2 won
    # 2 (e.g.) is skill1 winning with 2 coins, -3 is skill2 winning with 3.
    results = Int[]

    for _ in 1:Iters
        currS1, currS2 = copy(skill1), copy(skill2)
        parryCounter = 0
        FirstFlag = true
        while length(currS1) > 1 && length(currS2) > 1
            parryCounter += 1
            parryCounter > 99 && break
            s1Roll = evaluateOnce(currS1, finalpower1, sanity1)
            s2Roll = evaluateOnce(currS2, finalpower2, sanity2)
            if s1Roll > s2Roll
                pop!(currS2)
                FirstFlag && (s1WonFirstClash += 1)
                FirstFlag = false
            elseif s2Roll > s1Roll
                pop!(currS1)
                FirstFlag && (s2WonFirstClash += 1)
                FirstFlag = false
            end
        end

        if length(currS1) > 1 && length(currS2) > 1
            push!(results, 0)
        else
            push!(results, (length(currS1) - 1) - (length(currS2) - 1))
        end
    end

    return s1WonFirstClash, s2WonFirstClash, results
end