struct Announcer
    id
end

getMasterFileClasses(::Type{Announcer}) = ["announcer"]

AnnouncerMasterList = Announcer[]
function getMasterList(::Type{Announcer})
    getMasterList(Announcer, AnnouncerMasterList)
end

getLocalizedFolders(::Type{Announcer}) = ["announcerVoice"]

function getInternalVersion(myAnnouncer :: Announcer; dontWarn = !GlobalDebugMode)
    for AnnouncerList in getInternalList(Announcer)
        for entry in AnnouncerList["list"]
            if entry["id"] == myAnnouncer.id
                return entry
            end
        end
    end

    dontWarn || @warn "No Internal Announcer matching $(myAnnouncer.id) found."
    return
end

function getLocalizedVersion(myAnnouncer :: Announcer; dontWarn = !GlobalDebugMode)
    Names = getLocalizedFolders(Announcer)
    for name in Names
        Lst = getLocalizeDataInfo()[name]
        for AnnouncerName in Lst
            S = match(r"_([0-9]+)$", AnnouncerName)
            S === nothing && continue
            idx = parse(Int, S.captures[1])
            if idx == myAnnouncer.id
                return LocalizedData(AnnouncerName)["dataList"]
            end
        end
    end 

    dontWarn || @warn "No Localized Announcer matching $(myAnnouncer.id) found."
    return
end

### Retrieval
getID(myAnnouncer :: Announcer) = myAnnouncer.id
getStringID(myAnnouncer :: Announcer) = string(myAnnouncer.id)
function getTitle(myAnnouncer :: Announcer)
    TitleDict = LocalizedData("Announcer")["dataList"]
    for entry in TitleDict
        entry["id"] == getID(myAnnouncer) && return @blue(entry["name"])
    end

    return ""
end

function getAnnouncerData(myAnnouncer :: Announcer; verbose = false)
    internalFile = getInternalVersion(myAnnouncer)
    localizedFile = deepcopy(getLocalizedVersion(myAnnouncer))
    if internalFile === nothing
        @info "Internal file for Announcer $(myAnnouncer.id) not found."
        return ""
    elseif localizedFile === nothing
        @info "Localized file for Announcer $(myAnnouncer.id) not found."
        return ""
    end

    io = IOBuffer()
    println(io, "Announcer lines for $(getTitle(myAnnouncer)) ($(@dim(getStringID(myAnnouncer)))):")
    verbose && println(io, "Image String: $(internalFile["imgStr"])")

    internalKeywords = internalFile["announcerKeywords"]
    NumEntries = length(internalKeywords)
    N = ceil(Int, log10(NumEntries + 6))

    function splitStr(io, Str, leftPad)
        ScreenWidth = 75
        if textwidth(Str) > ScreenWidth
            for c in eachindex(Str)
                textwidth(Str[begin:c]) < ScreenWidth && continue
                getLangMode() == "en" && Str[c] != ' ' && continue
                println(io, Str[begin:prevind(Str, c)])
                return splitStr(io, ' '^leftPad * strip(Str[c:end]), leftPad)
            end
        end

        print(io, Str)
        return
    end

    idx = 1
    for entry in internalKeywords
        io2 = IOBuffer()
        print(io2, @dim(lpad(string(idx), N)))
        print(io2, " ")
        print(io2, @blue(get(entry, "voicetype", "")))
        verbose && print(io2, " ($(@dim(get(entry, "path", ""))))")
        for (name, kword) in [("Priority", "priority"),
                              ("Index", "index")]
            if haskey(entry, kword)
                print(io2, " $(name): $(entry[kword])")
            end
        end

        localMatch = Any[]

        if haskey(entry, "path")
            localMatch = filter(x -> occursin(entry["path"], x["id"]), localizedFile) 
            for currMatch in localMatch
                regexStr = Regex("""\\Q$(entry["path"])\\E_(.*)""")
                S = match(regexStr, currMatch["id"])
                entryName = ""
                if S !== nothing
                    entryName = S.captures[1]
                else
                    @info "Unable to parse $(currMatch["id"]) for $(entry["path"])"
                end
                dialog = currMatch["dlg"]
                print(io2, "\n")
                strPrint = " > $(@green(rpad(entryName, 4))) $dialog"
                splitStr(io2, strPrint, 8)
            end

            filter!(x -> !occursin(entry["path"], x["id"]), localizedFile) 
        end

        entryStr = String(take!(io2))
        if verbose || length(localMatch) > 0
            println(io, entryStr)
            idx += 1
        end
    end

    for entry in localizedFile
        print(io, @dim(lpad(string(idx), N)))
        print(io, " $(@red(entry["id"]))")
        print(io, "\n")
        strPrint = " >      " * entry["dlg"]
        splitStr(io, strPrint, 8)
    end

    return String(take!(io))
end

function AnnouncerVoiceHelp()
    S = raw"""Outputs the dialogue lines of Announcers.
              `announcer _entry_ _flags_` to get the voice lines.

              Possible flags:
              !v/!verbose  - Outputs the internal data.
              !i/!internal - Searches using the internal IDs.
              !all         - Outputs all entries. (*)

              After (*), `announcer _number_` will directly output the corresponding entry.
        """

    println(S)
    return S
end

function AnnouncerVoiceParser(input)
    UseInternalIDs = false
    Verbose = false
    PrintAll = false
    AnnouncerSearchList = Announcer[]

    Applications = Dict{Regex, Function}()
    Applications[r"^![iI](nternal)?$"] = (_) -> (UseInternalIDs = true)
    Applications[r"^![vV](erbose)?$"] = (_) -> (Verbose = true)
    Applications[r"^![aA](ll)?$"] = (_) -> (PrintAll = true)

    newQuery, activeFlags = parseQuery(input, keys(Applications))
    for (flag, token) in activeFlags
        Applications[flag]((match(flag, token).captures)...)
    end

    S = match(r"^([0-9]+)$", newQuery)
    if S !== nothing
        return printExactNumberInput(Announcer, newQuery, Verbose)
    end

    (length(AnnouncerSearchList) == 0) && (AnnouncerSearchList = getMasterList(Announcer))

    PrintAll && return printAll(Announcer, AnnouncerSearchList)

    HaystackAnnouncers = []
    for announcer in AnnouncerSearchList
        id = getStringID(announcer)
        if UseInternalIDs
            push!(HaystackAnnouncers, (id, announcer))
        else
            push!(HaystackAnnouncers, (getTitle(announcer), announcer))
        end
    end

    return searchSingle(Announcer, newQuery, HaystackAnnouncers; verbose = Verbose)
end

AnnouncerVoiceRegex = r"^announcer (.*)$"
AnnouncerVoiceCommand = Command(AnnouncerVoiceRegex, AnnouncerVoiceParser, [1], AnnouncerVoiceHelp)

# Printing and Searching

function printSingle(myAnnouncer :: Announcer, verbose)
    println(getAnnouncerData(myAnnouncer, verbose = verbose))
    return myAnnouncer
end

function printRandom(myAnnouncer :: Announcer, verbose)
    Ans = rand(getMasterList(Announcer))
    printSingle(Ans, verbose)
    return Ans
end

function searchSingle(::Type{Announcer}, query, Haystack; verbose = false)
    println("Using $(@red(query)) as query.")

    result = SearchClosestString(query, Haystack)[1][2]
    printSingle(result, verbose)
    return result
end

function printFromList(::Type{Announcer}, list)
    PreviousSearchList = setPreviousSearch(Announcer, list)

    if length(PreviousSearchList) == 0
        println("No results found.")
        return PreviousSearchList
    end

    ResultStrings = String[]
    for announcer in PreviousSearchList
        push!(ResultStrings, getTitle(announcer))
    end

    print(GridFromList(ResultStrings, 3; labelled = true))
    return PreviousSearchList
end

function printAll(::Type{Announcer}, list)
    return printFromList(Announcer, list)
end

function printExactNumberInput(::Type{Announcer}, num, verbose)
    PreviousSearchList = getPreviousSearch(Announcer)
    if length(PreviousSearchList) == 0
        @info "No previously searched `announcer list`."
        return ""
    end

    N = parse(Int, num)
    
    if !(1 ≤ N ≤ length(PreviousSearchList))
        @info "There are only $(length(PreviousSearchList)) announcers. You asked for the $N-th entry."
        return ""
    end
    
    return printSingle(PreviousSearchList[N], verbose)
end