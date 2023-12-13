function ClashCalculatorHelp()
    S = raw"""Computes the likely outcome between two clashes. Usage:  
              `clash-calc _skill1_ _modifier_ _skill2_ _modifier_`

              The format for skills is as follows:
              `(id:*: _identity info_)`  - (*) can be s1, s2, s3 or def
              `(ego:*: _ego info_)`      - (*) can be awake or corr
              `(skill: _skill info_)`    - Skill name search
              `(exact: _skill string_)`  - Exact. Example of _skill string_ is `2(+4)x3`
              You may append `@_olvl_` to specify the offense level of the skill.
              Defaults to current max offense level for identities.

              Available modifiers:
              `[coinPower:X]`      - +X Coin Power
              `[plusCoinPower:X]`  - +X Plus Coin Power
              `[minusCoinPower:X]` - +X Minus Coin Power (X = 2 decreases coin power by 2 on minus coins)
              `[finalPower:X]`     - +X Final Power
              `[basePower:X]`      - +X Base Power
              `[offLevel:X]`       - +X Offense Level (X can be negative)
              `[sp:X]`             - Sets Sanity to X

              Example Usage:
              `clash-calc (s3:[id:don] warp)@40 [coinPower:4] [sp:45] (skill:hair coupons)@60 [offLevel:5]` 
              - Clash result between [Don] Warp - Rip Space at Level 40 with 10 Charge Count and
                Ricardo's Hair Coupons without passive.
        """

    println(S)
    return S
end

mutable struct ParseClashSkill
    CoinVec      :: Vector{Coin}
    OffenseLevel :: Int
    Sanity       :: Int
    FinalPower   :: Int
    Description  :: String
    ModDesc      :: Vector{String}
end

function ParseClashSkill(input :: String)
    skillRegex = r"^(\(.*\)(@[0-9]+)?)(.*)$"
    S = match(skillRegex, input)
    if S !== nothing
        skill = fetchClashSkill(S.captures[1])
        skill === nothing && return
        applyClashModifiers!(skill, string(S.captures[3]))
        return skill
    end

    @info "This line is not supposed to be reachable."
    return
end

function ClashCalculatorParse(input)
    skillRegex = r"(\(.*\)(@[0-9]+)?( +\[[a-zA-Z0-9:\-]*\])*) (\(.*\)(@[0-9]+)?( +\[[a-zA-Z0-9:\-]*\])*)"
    S = match(skillRegex, input)
    if S !== nothing
        Skill1 = ParseClashSkill(string(S.captures[1]))
        if Skill1 === nothing
            @info "Unable to find $(S.captures[1]) skill. Try `clash-calc help`"
            return 
        end
        Skill2 = ParseClashSkill(string(S.captures[4]))
        if Skill2 === nothing
            @info "Unable to find $(S.captures[4]) skill. Try `clash-calc help`"
            return
        end

        return printClashOutcome(Skill1, Skill2)
    end

    @info "Unable to parse $input (try `clash-calc help`)"
    return
end

ClashCalculatorRegex = r"^clash(-)?calc(ulator)? (.*)$"
ClashCalculatorCommand = Command(ClashCalculatorRegex, ClashCalculatorParse,
                                 [3], ClashCalculatorHelp)  

function parseClashModifiers(input :: String)
    modRegex = r"\[([^\[\]]*)\]"
    return [x.match in eachmatch(modRegex, input)]
end

function applyClashModifiers!(skill :: ParseClashSkill, modifiers)
    Applications = Dict{Regex, Function}()
    Applications[r"\[[cC]oin[pP]ower[:=]([+-]?[0-9]+)\]"] = 
        x -> (skill.CoinVec = increaseCoinPower(skill.CoinVec, parse(Int, x)); 
              skill.ModDesc = push!(skill.ModDesc, "Coin Power $(NumberStringWithSign(parse(Int, x)))"))
    Applications[r"\[[pP]lus[cC]oin[pP]ower[:=]([+-]?[0-9]+)\]"] = 
        x -> (skill.CoinVec = increasePlusCoinPower(skill.CoinVec, parse(Int, x));
              skill.ModDesc = push!(skill.ModDesc, "Plus Coin Power $(NumberStringWithSign(parse(Int, x)))"))
    Applications[r"\[[mM]inus[cC]oin[pP]ower[:=]([+-]?[0-9]+)\]"] = 
        x -> (skill.CoinVec = increaseMinusCoinPower(skill.CoinVec, parse(Int, x));
              skill.ModDesc = push!(skill.ModDesc, "Minus Coin Power $(NumberStringWithSign(parse(Int, x)))"))
    Applications[r"\[[bB]ase[pP]ower[:=]([+-]?[0-9]+)\]"] = 
        x -> (skill.CoinVec = augmentBasePower(skill.CoinVec, parse(Int, x));
              skill.ModDesc = push!(skill.ModDesc, "Base Power $(NumberStringWithSign(parse(Int, x)))"))
    Applications[r"\[[fF]inal[pP]ower[:=]([+-]?[0-9]+)\]"] = 
        x -> (skill.FinalPower += parse(Int, x);
              skill.ModDesc = push!(skill.ModDesc, "Final Power $(NumberStringWithSign(parse(Int, x)))"))
    
    Applications[r"\[[oO]ffense[lL]evel[:=]([+-]?[0-9]+)\]"] = x -> skill.OffenseLevel += parse(Int, x)
    Applications[r"\[[sS]([pP]|anity)[:=]([+-]?[0-9]+)\]"] = 
    function changeSanity(_, x)
        newSP = tryparse(Int, x)
        newSP === nothing && return
        if !(-45 ≤ newSP ≤ 45)
            @info "Sanity must be between -45 and 45"
        else
            skill.Sanity = newSP
        end
        return
    end

    newQuery, activeFlags = parseQuery(modifiers, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    return skill
end

function getTitle(skill :: ParseClashSkill)
    io = IOBuffer()
    print(io, skill.Description)
    print(io, " at Offense Level $(@red(string(skill.OffenseLevel))) and $(@red(string(skill.Sanity))) SP")
    if length(skill.ModDesc) > 0
        print(io, " with ")
        print(io, join(skill.ModDesc, ", ", " and "))
    end

    return String(take!(io))
end

function fetchClashSkillSkill(input, level)
    S = match(r"^skill[:=](.*)$", input)
    S === nothing && return
    skill = nothing
    io = Pipe()
    redirect_stdout(io) do
        skill = SkillParser(string(S.captures[1]))
        skill === nothing && return
        if skill isa Vector
            length(skill) == 0 && return
            skill = skill[1]
        end
    end
    close(io)

    tier = SkillTierParser(input)
    return ParseClashSkill(
        getCoinValues(skill, tier),
        level + getOffLevelCorrection(skill, tier),
        0,
        0,
        "($(@blue(getCoinString(skill, tier)))) " * getTitle(skill),
        String[]
    )

    return
end

function fetchClashSkillPersonality(input, level)
    T = match(r"^[iI][dD](entity)?[:=]([^:=]*)[:=](.*)$", input)
    T === nothing && return
    io = Pipe()
    foundPersonality = nothing
    redirect_stdout(io) do
        foundPersonality = PersonalityParser(string(T.captures[3]))
    end
    close(io)

    foundPersonality === nothing && return
    if foundPersonality isa Vector
        length(foundPersonality) == 0 && return
        foundPersonality = foundPersonality[1]
    end

    fnList, desc = getSkillFunctions(Personality, string(T.captures[2]))
    if length(fnList) != 1
        @info "Invalid Skill $(T.captures[2]) specified."
        return
    end
    
    uptie = PersonalityUptieParser(T.captures[3])
    skill = (fnList[1])(foundPersonality)

    return ParseClashSkill(
        getCoinValues(skill, uptie),
        level + getOffLevelCorrection(skill, uptie),
        0,
        0,
        "($(@blue(getCoinString(skill, uptie)))) $desc of $(getEscapedTitle(foundPersonality))" * getTitle(skill),
        String[]
    )
end

function fetchClashSkillEGO(input, level)
    S = match(r"^[eE](go|GO)[:=]([^:=]+)[:=](.*)$", input)
    S === nothing && return
    io = Pipe()
    foundEGO = nothing
    redirect_stdout(io) do
        foundEGO = EGOParser(string(S.captures[3]))
    end
    close(io)

    foundEGO === nothing && return
    if foundEGO isa Vector
        length(foundEGO) == 0 && return
        foundEGO = foundEGO[1]
    end

    fnList, desc = getSkillFunctions(EGO, string(S.captures[2]))
    if length(fnList) != 1
        @info "Invalid Skill $(S.captures[2]) specified."
        return
    end

    ts = EGOThreadspinParser(string(S.captures[3]))
    skill = (fnList[1])(foundEGO)

    return ParseClashSkill(
        getCoinValues(skill, ts),
        level + getOffLevelCorrection(skill, ts),
        0,
        0,
        "($(@blue(getCoinString(skill, ts)))) $desc of" * getTitle(skill),
        String[]
    )
end

function fetchClashSkillExact(input, level)
    S = match(r"^[eE]xact[:=](.*)$", input)
    S === nothing && return
    coinVec = getCoinVecFromString(S.captures[1])
    return ParseClashSkill(
        coinVec,
        level,
        0,
        0,
        @blue(getCoinString(coinVec)),
        String[]
    )
end

function fetchClashSkill(input)
    skillNameRegex = r"\((.*)\)(@(.*))?"
    S = match(skillNameRegex, input)
    level = getMaxLevel(Personality)
    if S.captures[2] !== nothing
        level = parse(Int, S.captures[2][2:end])
    end

    for fn in [fetchClashSkillSkill, fetchClashSkillExact,
               fetchClashSkillPersonality, fetchClashSkillEGO]
        skill = fn(S.captures[1], level)
        skill !== nothing && return skill
    end
    return
end

function printClashOutcome(Skill1, Skill2)
    Linebreak = "-"^50
    io = IOBuffer()
    println(io, "Skill 1: $(getTitle(Skill1))")
    println(io, "Skill 2: $(getTitle(Skill2))")
    println(io, Linebreak)
    
    # Compare Offense Level
    diff = Skill1.OffenseLevel - Skill2.OffenseLevel
    if diff > 0
        boost = floor(Int, diff / 3)
        Skill1.CoinVec = augmentBasePower(Skill1.CoinVec, boost)
    else diff < 0
        boost = floor(Int, - diff / 3)
        Skill2.CoinVec = augmentBasePower(Skill2.CoinVec, boost)
    end

    Trials = 100_000
    s1WonFirstClash, s2WonFirstClash, results = clashEvaluateSkills(Skill1.CoinVec, Skill1.FinalPower, Skill1.Sanity, 
                                                                    Skill2.CoinVec, Skill2.FinalPower, Skill2.Sanity;
                                                                    Iters = Trials)

    s1WinRate = count(>(0), results) / Trials
    s1WinRateStr = @sprintf "%.2f" 100s1WinRate
    s2WinRate = count(<(0), results) / Trials
    s2WinRateStr = @sprintf "%.2f" 100s2WinRate
    TiesRate  = count(==(0), results) / Trials
    if s1WinRate > s2WinRate 
        println(io, "Skill 1 wins $(@green(s1WinRateStr))% of the time.")
        println(io, "Skill 2 wins $(s2WinRateStr)% of the time.")
    else
        println(io, "Skill 1 wins $(s1WinRateStr)% of the time.")
        println(io, "Skill 2 wins $(@green(s2WinRateStr))% of the time.")
    end
    if TiesRate > 0
        println(io, "Skill 1 and Skill 2 tie $(@green(@printf "%.2f" 100TiesRate))% of the time.")
    end
    println(io, Linebreak)
    println(io, "For the first clash,")
    s1FirstWinRate = s1WonFirstClash/Trials
    s1FirstWinRateStr = @sprintf "%.2f" 100s1FirstWinRate
    s2FirstWinRate = s2WonFirstClash/Trials
    s2FirstWinRateStr = @sprintf "%.2f" 100s2FirstWinRate

    if s1FirstWinRate > s2FirstWinRate
        println(io, "Skill 1 wins $(@green(s1FirstWinRateStr))% of the time.")
        println(io, "Skill 2 wins $(s2FirstWinRateStr)% of the time.")
    else
        println(io, "Skill 1 wins $(s1FirstWinRateStr)% of the time.")
        println(io, "Skill 2 wins $(@green(s2FirstWinRateStr))% of the time.")
    end
    println(io, Linebreak)

    minCoin, maxCoin = extrema(results)
    for i in minCoin:maxCoin
        winCount = count(==(i), results)
        winCount > 0 || continue
        winRate = winCount / Trials
        winRateStr = @sprintf "%.2f" 100winRate
        if i < 0
            println(io, "$winRateStr% of the time, Skill 2 wins by $(-i) coin$(i > 1 ? "s" : "").")
        elseif i > 0
            println(io, "$winRateStr% of the time, Skill 1 wins by $i coin$(i > 1 ? "s" : "").")
        else
            println(io, "$winRateStr% of the time, Skill 1 and Skill 2 tie.")
        end
    end

    println(String(take!(io)))
    return s1WonFirstClash, s2WonFirstClash, results
end