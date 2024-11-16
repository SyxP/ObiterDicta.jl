function EXPHelp()
    S = raw"""Looks up EXP Tables. Available Commands:
              exp manager _level_
              exp enke _level_ / exp enkephalin _level_

              exp uptie / exp ut
              exp ut _rarity_ _start_ _end_
              exp threadspin / exp ts 
              exp ts _tier_ _start_ _end_

              exp id _level_
              exp id plot
              exp refill
    """

    println(S)
end

function EXPParser(input)
    for managerRegex in [r"manager ([0-9]*)", r"enke ([0-9]+)", r"enkephalin ([0-9]+)"]
        S = match(managerRegex, input)
        if S !== nothing
            level = parse(Int, S.captures[1])
            return getEXPManagerLevel(level)
        end
    end
    for idRegex in [r"id ([0-9]+)$", r"identity ([0-9]+)$"]
        S = match(idRegex, input)
        if S !== nothing
            level = parse(Int, S.captures[1])
            return getEXPIdentity(level)
        end
    end
    for idRegex in [r"id ([0-9]+) ([0-9]+)$", r"identity ([0-9]+) ([0-9]+)$"]
        S = match(idRegex, input)
        if S !== nothing
            level1 = parse(Int, S.captures[1])
            level2 = parse(Int, S.captures[2])
            return getEXPIdentity(level1, level2)
        end
    end
    S = match(r"^id(entity)? plots?$", input)
    (S !== nothing) && return getEXPPlot()

    S = match(r"^(uptie|ut) ([^ ]*) ([0-9]+) ([0-9]+)$", input)
    if S !== nothing
        return getEXPUptie(S.captures[2], parse(Int, S.captures[3]), parse(Int, S.captures[4]))
    end
    match(r"^(uptie|ut)$", input) !== nothing && return getEXPUptie()

    S = match(r"^(threadspin|ts) ([^ ]*) ([0-9]+) ([0-9]+)$", input)
    if S !== nothing
        return getEXPThreadspin(S.captures[2], parse(Int, S.captures[3]), parse(Int, S.captures[4]))
    end
    match(r"^(threadspin|ts)$", input) !== nothing && return getEXPThreadspin()

    match(r"refill$", input) !== nothing && return getEXPRefill()

    @info "Unable to parse $input (try 'exp help')"
    return 
end

EXPRegex = r"(exp|experience|upgrade) (.*)"
EXPCommand = Command(EXPRegex, EXPParser, [2], EXPHelp)

function getEXPManagerLevel(level)
    # Outputs the needed amount of EXP to reach Manager level level
    # Outputs the needed amount of EXP to get from level to level + 1 
    # Outputs the amount of Enkephalin at the level

    ManagerLevelDatabase = StaticData("common-data/common-data")["levelTable"]
    MinLevel, MaxLevel = 1, length(ManagerLevelDatabase["expTable"]) + 1
    if !(MinLevel <= level <= MaxLevel)
        @info "Manager Level out of range."
        return
    end

    CumSumEXP = foldl(+, ManagerLevelDatabase["expTable"][1:(level - 1)]; init = 0)
    println("The required amount of EXP to reach Manager Level " 
            * @blue(string(level)) * " is " * @magenta(string(CumSumEXP)) * ".")
   
    ProgressEXP = 0
    if level != MaxLevel
        ProgressEXP = ManagerLevelDatabase["expTable"][level]
        println("To get from Manager Level " * @blue(string(level)) * " => " 
                * @blue(string(level + 1)) * " is " * @magenta(string(ProgressEXP)) * ".")
    else
        println("This is currently the maximum Manager Level.")
    end

    EnkeCap = ManagerLevelDatabase["enkephalinTable"][level]
    println("The Enkephalin Cap at Manager Level " * @blue(string(level)) * 
            " is " * @magenta(string(EnkeCap)) * ".")

    return CumSumEXP, ProgressEXP, EnkeCap
end

function getEXPUptie()
    UptieDatabase = StaticData("common-data/common-data")["personalityLevelTable"]["gacksungPieceTable"]
    for (key, rarity) in [("rank1", "0"), ("rank2", "00"), ("rank3", "000")]
        println("For $(@yellow(rarity)) Upties:")
        UptieStrings = String[]
        for (i, cost) in enumerate(UptieDatabase[key])
            io = IOBuffer()
            print(io, "UT " * @dim(@blue(string(i))) * " => " * @dim(@blue(string(i+1))) * ": ")
            print(io, @magenta(string(cost["thread"])) * " thread")
            if cost["piece"] != 0
                print(io, " + " * @magenta(string(cost["piece"])) * " E.G.O shards")
            end
            push!(UptieStrings, String(take!(io)))
        end
        println(join(UptieStrings, "$(@dim(";"))\t"))
    end

    return
end

function getEXPUptie(rarityString, startTier, endTier)
    UptieDatabase = StaticData("common-data/common-data")["personalityLevelTable"]["gacksungPieceTable"]
    ThreadCost = EGOShardCost = 0

    tier = getRarityFromString(rarityString)
    if tier == 0
        println("Unable to parse rarity: $rarityString.")
        return
    end
    searchKeyTier = "rank" * string(tier)
    for (i, cost) in enumerate(UptieDatabase[searchKeyTier])
        (startTier ≤ i ≤ endTier - 1) || continue
        ThreadCost += cost["thread"]
        EGOShardCost += cost["piece"]
    end

    print("To get from UT $(@blue(string(startTier))) => $(@blue(string(endTier))) for rarity $(@yellow(rarityString)), ")
    print("you need $(@magenta(string(ThreadCost))) thread")
    EGOShardCost != 0 && print(" and $(@magenta(string(EGOShardCost))) E.G.O shard")
    print(".")

    return ThreadCost, EGOShardCost
end

function getEXPThreadspin()
    ThreadspinDatabase = StaticData("common-data/common-data")["egoLevelTable"]["gacksungPieceTable"]
    Tiers = getEGOTiers()
    for tier in Tiers
        println("For $(@yellow(tier)) Threadspins:")
        ThreadspinStrings = String[]
        for (i, cost) in enumerate(ThreadspinDatabase[tier])
            io = IOBuffer()
            print(io, "TS " * @dim(@blue(string(i))) * " => " * @dim(@blue(string(i+1))) * ": ")
            print(io, @magenta(string(cost["thread"])) * " thread")
            if cost["piece"] != 0
                print(io, " + " * @magenta(string(cost["piece"])) * " E.G.O shards")
            end
            push!(ThreadspinStrings, String(take!(io)))
        end
        println(join(ThreadspinStrings, "$(@dim(";"))\t"))
    end
end

function getEXPThreadspin(rawRarityString, startTier, endTier)
    ThreadspinDatabase = StaticData("common-data/common-data")["egoLevelTable"]["gacksungPieceTable"]
    rarityString = getClosestEGOType(rawRarityString)
    ThreadCost = EGOShardCost = 0

    for (i, cost) in enumerate(ThreadspinDatabase[rarityString])
        (startTier ≤ i ≤ endTier - 1) || continue
        ThreadCost += cost["thread"]
        EGOShardCost += cost["piece"]
    end

    print("To get from TS $(@blue(string(startTier))) => $(@blue(string(endTier))) for rarity $(@yellow(rarityString)), ")
    print("you need $(@magenta(string(ThreadCost))) thread")
    EGOShardCost != 0 && print(" and $(@magenta(string(EGOShardCost))) E.G.O shards")
    print(".")

    return ThreadCost, EGOShardCost
end

getEXPDatabase() = StaticData("common-data/common-data-a1c7")["personalityLevelTable"]["expTable"]
function getEXPIdentity(level)
    IdentityEXPDatabase = getEXPDatabase()
    if !(1 <= level <= length(IdentityEXPDatabase) + 1)
        @info "Identity Level out of range."
        return
    end

    CumSumEXP = foldl(+, IdentityEXPDatabase[1:(level - 1)]; init = 0)
    println("The required amount of EXP to reach Identity Level "
            * @blue(string(level)) * " is " * @magenta(string(CumSumEXP)) * ".")

    ProgressEXP = 0
    if level != length(IdentityEXPDatabase) + 1
        ProgressEXP = IdentityEXPDatabase[level]
        println("To get from Identity Level " * @blue(string(level)) * " => "
                * @blue(string(level + 1)) * " is " * @magenta(string(ProgressEXP)) * ".")  
    else
        println("This is currently the maximum Identity Level.")
    end

    return CumSumEXP, ProgressEXP
end

function getEXPIdentity(level1, level2)
    level1 > level2 && return getEXPIdentity(level2, level1) # Ensure level1 < level2

    IdentityEXPDatabase = getEXPDatabase()
    for level in [level1, level2]
        if !(1 <= level <= length(IdentityEXPDatabase) + 1)
            @info "Identity Level $level out of range."
            return
        end
    end


    CumSumEXP = foldl(+, IdentityEXPDatabase[level1:(level2 - 1)]; init = 0)
    println("The required amount of EXP to reach Identity Level "
            * @blue(string(level1)) * " => " * @blue(string(level2)) * " is "
            * @magenta(string(CumSumEXP)) * ".")
    return CumSumEXP
end

function getEXPPlot()
    IdentityEXPDatabase = getEXPDatabase()
    Title = "Experience Points Needed Per Level"
    xRange = 2:(length(IdentityEXPDatabase)+1)
    yRange = Int.(IdentityEXPDatabase)

    S = lineplot(xRange, yRange; title = Title, xlabel = "Level", ylabel = "EXP Needed")
    println(S)
    return S
end

function getEXPRefill()
    RefillEXPDatabase = StaticData("common-data/common-data")
    println("The Enkephalin/Module is " * @magenta(string(RefillEXPDatabase["enkephalinForAModule"])) * ".")
    EnkePriceTable = RefillEXPDatabase["enkephalinPriceTable"]["priceTable"]
    println("You can refill up to $(@magenta(string(length(EnkePriceTable)))) times a day, with module cap "
            * @magenta(string(RefillEXPDatabase["staminaStorageMax"])) * ".")
    RefillStrings = String[]
    for (i, cost) in enumerate(EnkePriceTable)
        io = IOBuffer()
        print(io, @dim(@blue(string(i))) * ": ")
        print(io, @magenta(string(cost)) * " L")
        push!(RefillStrings, String(take!(io)))
    end
    println(join(RefillStrings, "$(@dim(";")) "))

    return EnkePriceTable
end