function MirrorDungeon3Help()
    S = raw"""Mirror Dungeon 3 Functions:
              `md3 compare _giftList_` - Quickly compare _giftList_.
              `md3 fusion chart`       - Shows the fusion chart.
              `md3 fusion fixed`       - Shows the fixed fusion formulaes.
              `md3 fusion _giftList_`  - Shows likely output of fusion of _giftList_.

              `_giftList_` is a space-separated list of E.G.O Gift names.
              Each E.G.O Gift name should be in a bracket. For example,
              `(coin) (wound clerid) (relation)`
        """

    println(S)
end

function MirrorDungeon3Parser(input)
    S = match(r"^compare (.+)$", input)
    (S !== nothing) && return printMirrorDungeon3Compare(S.captures[1])

    S = match(r"^[fF]usion [cC]hart$", input)
    (S !== nothing) && return printFusionChart()

    S = match(r"^[fF]usion [fF]ix(ed)?( [cC]hart)?$", input)
    (S !== nothing) && return printFusionFixedChart()

    S = match(r"^[fF]usion (.+)$", input)
    (S !== nothing) && return printFusedGifts(S.captures[1])

    @info "Unable to parse $input (try `md3 help`)"
    return
end

MirrorDungeon3Regex = r"^[mM]([dD]|irror(-?[dD]ungeon)?)3 (.+)$"
MirrorDungeon3Command = Command(MirrorDungeon3Regex, MirrorDungeon3Parser, [3], MirrorDungeon3Help)

function printMirrorDungeon3Compare(input)
    giftList = parseListOfGifts(input)
    for (i, gift) in enumerate(giftList)
        println(@dim(string(i)) * " " * getSummaryMDGift(gift))
    end

    global EGOGiftPreviousSearchResult = copy(giftList)
    return giftList
end

function searchMirrorDungeonEGOGift(input)
    searchStr = input * " !in:md"
    io = Pipe()
    foundGift = nothing
    redirect_stdout(io) do
        foundGift = EGOGiftParser(searchStr)
    end
    close(io)

    foundGift === nothing && return nothing
    if foundGift isa Vector
        length(foundGift) == 0 && return nothing
        foundGift = foundGift[1]
    end

    return foundGift
end

function getSummaryMDGift(gift :: MirrorDungeonEGOGift)
    S = String[]
    push!(S, @blue(getName(gift)) * " ($(@dim(getStringID(gift))))")
    push!(S, getSinString(getAttributeType(gift)))
    push!(S, "Cost $(getPrice(gift))")
    push!(S, "Tier $(getTier(gift))")

    Tmp = getTypeKeyword(gift)
    if Tmp !== nothing && Tmp != ""
        push!(S, Tmp)
    end

    if hasUpgrade(gift)
        push!(S, "[Can Upgrade]")
    end

    return join(S, " - ")
end

function parseListOfGifts(input)
    # (_gift1_) (_gift2_) ...
    tokens = tokenize(input)
    giftList = EGOGift[]
    for token in tokens
        S = match(r"^\(?([^\(\)]*)\)?$", token)
        foundGift = searchMirrorDungeonEGOGift(S.captures[1])
        (S === nothing) && continue
        (foundGift === nothing) && continue

        push!(giftList, foundGift)
    end

    return giftList
end

function makeMDFusionEquation(inputTiers, noBonus, withBonus)
    maxInput = maximum(inputTiers)

    function getColoredStr(input)
        if input < maxInput
            return @dim(string(input))
        elseif input == maxInput
            return @red(string(input))
        else
            return @green(string(input))
        end
    end

    noBonusStr = getColoredStr(noBonus)
    withBonusStr = getColoredStr(withBonus)
    return join(inputTiers, " + ") * " = $noBonusStr ($(withBonusStr))"
end

function getFusionTierDict()
    MDCommonDatabase = StaticData("mirror-dungeon-common-data/mirror-dungeon-common-data")["egoGiftCombineTierTable"]
    fusionDict = Dict{Vector{Int}, Tuple{Int, Int}}()

    for entry in MDCommonDatabase["combineTwo"]
        inputTier = [entry["aTier"], entry["bTier"]]
        noBonus = entry["mismatchedAttributeResult"]
        withBonus = entry["matchedAttributeResult"]
        fusionDict[sort(inputTier)] = (noBonus, withBonus)
    end

    for entry in MDCommonDatabase["combineThree"]
        inputTier = [entry["aTier"], entry["bTier"], entry["cTier"]]
        noBonus = entry["mismatchedAttributeResult"]
        withBonus = entry["matchedAttributeResult"]
        fusionDict[sort(inputTier)] = (noBonus, withBonus)
    end

    return fusionDict
end

function getMaximumFusionTier()
    MDCommonDatabase = StaticData("mirror-dungeon-common-data/mirror-dungeon-common-data")["egoGiftCombineTierTable"]
    return MDCommonDatabase["maximumAvailableTier"]
end

function printFusionChart()
    io = IOBuffer()
    println(io, "The maximum tier of E.G.O gift that can be fused is Tier $(@blue(string(getMaximumFusionTier()))).")
    println(io, "For inputs of tier A, B and C, A + B + C = D (E) means the")
    println(io, "result is tier D if the input gifts are not all of the same") 
    println(io, "sin attibute and the result is tier E if they are the same.") 
    print(io, "-"^59)
    output = String(take!(io))

    fusionDict = getFusionTierDict()
    keyOrder = sort(collect(keys(fusionDict)); by = x -> (length(x), sum(x), x[begin]))
    equationStrings = String[]

    for key in keyOrder
        fusionInfo = fusionDict[key]
        push!(equationStrings, makeMDFusionEquation(key, fusionInfo[1], fusionInfo[2]))
    end
    output /= GridFromList(equationStrings, 3)
    print(output)

    return fusionDict
end

function getFusionFixedDict()
    MDCommonDatabase = StaticData("mirror-dungeon-common-data/mirror-dungeon-common-data")["egoGiftCombineFixedTable"]["combineFixed"]
    
    fusionDict = Dict{Vector{Int}, Int}()
    for entry in MDCommonDatabase
        result = entry["resultEgoGiftId"]
        inputs = Int[]
        for fields in ["aEgoGiftId", "bEgoGiftId", "cEgoGiftId"]
            haskey(entry, fields) && push!(inputs, entry[fields])
        end

        fusionDict[sort(inputs)] = result
    end

    return fusionDict
end

function getFusionFormula(inputEGOGifts, outputEGOGift)
    return join(getTitle.(inputEGOGifts), " + ") * " = " * getTitle(outputEGOGift)
end
function printFusionFixedChart()
    fusionDict = getFusionFixedDict()

    io = IOBuffer()
    for key in sort(collect(keys(fusionDict)); by = x -> (length(x), sum(x), x[begin]))
        output = fusionDict[key]
        inputEGOGifts = [MirrorDungeonEGOGift(x) for x in key]
        outputEGOGift = MirrorDungeonEGOGift(output)
        formula = getFusionFormula(inputEGOGifts, outputEGOGift)
        println(io, formula)
    end

    print(String(take!(io)))
    return fusionDict
end

function hasFixedFormula(inputs :: Vector{T}) where T <: EGOGift
    fusionDict = getFusionFixedDict()
    inputIDs = [getID(x) for x in inputs]
    return haskey(fusionDict, sort(inputIDs))
end
function getFixedFormula(inputs :: Vector{T}) where T <: EGOGift
    fusionDict = getFusionFixedDict()
    inputIDs = [getID(x) for x in inputs]
    return fusionDict[sort(inputIDs)]
end

function fuseEGOGifts(inputs :: Vector{T}) where T <: EGOGift
    if hasFixedFormula(inputs)
        outputGift = MirrorDungeonEGOGift(getFixedFormula(inputs))
        println("This is a fixed formula for $(getTitle(outputGift)).")
        println(getFusionFormula(inputs, outputGift))
        return [outputGift]
    end

    listTypes = getAttributeType.(inputs)
    tierTypes = sort(getTier.(inputs))
    fusionDict = getFusionTierDict()
    outputTier = fusionDict[tierTypes][allequal(listTypes) ? 2 : 1]
    
    queryStr = "!in:md !all [tier:$outputTier]"
    (allequal(listTypes)) && (queryStr *= " [attribute:$(listTypes[1])]")
    io = Pipe()
    redirect_stdout(io) do
        EGOGiftParser(queryStr)
    end
    close(io)

    global EGOGiftPreviousSearchResult
    Names = getTitle.(EGOGiftPreviousSearchResult)
    content = "The predicted outcome is of tier $(@blue(string(outputTier)))."
    (allequal(listTypes)) && (content *= "\nAs all inputs are of the same sin attribute, a $(getKeywordSinString(listTypes[1])) E.G.O Gift is predicted.")
    content /= GridFromList(Names, 3; labelled = true)
    print(content)

    return copy(EGOGiftPreviousSearchResult)
end
function printFusedGifts(input)
    giftList = parseListOfGifts(input)
    return fuseEGOGifts(giftList)
end