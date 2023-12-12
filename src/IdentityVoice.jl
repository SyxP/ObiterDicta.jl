function getLocalizedVoiceFile(myID :: Personality)
    FileList = getLocalizeDataInfo()["personalityVoice"]
    str = getStringID(myID)
    for file in FileList
        if occursin(str, file)
            return LocalizedData(file)
        end
    end
    return nothing
end

function getVoiceData(myID :: Personality; verbose = false)
    file = getLocalizedVoiceFile(myID)
    if file === nothing
        @info "Voice for $(getFullTitle(myID)) not found."
        return ""
    end

    io = IOBuffer()
    println(io, "Voice lines for $(getFullTitle(myID)):\n")
    currEntries = file["dataList"]
    filter!(x-> match(r"[^ ]", x["desc"]) !== nothing, currEntries)
    NumEntries = length(currEntries)
    N = ceil(Int, log10(NumEntries + 1))
    lengthArr = length.([entry["desc"] for entry in file["dataList"]])  
    maxLength = maximum(lengthArr) 
   
    for (idx, entry) in enumerate(currEntries)
        print(io, @dim(lpad(string(idx), N)))
        print(io, " ")
       
        if verbose
            print(io, @blue(entry["desc"]))
            print(io, " ($(@dim(entry["id"])))")
        else
            print(io, @blue(rpad(entry["desc"], maxLength)))
        end
        
        print(io, ": ")
        paddingLength = maxLength + N + 3
        S = split(EscapeString(entry["dlg"]), "\n")
        AnsArr = String[]
        function insertStr(str)
            if lastindex(str) > 90 - paddingLength
                for c in collect(eachindex(str))
                    c < (80 - paddingLength) && continue
                    str[c] != ' ' && continue
                    push!(AnsArr, str[begin:prevind(str, c)])
                    return insertStr(str[nextind(str, c):end])
                end
            end

            push!(AnsArr, str)
            return
        end

        for entryDlg in S
            insertStr(entryDlg)
        end
        Seperator = "\n"*" "^paddingLength
        print(io, join(AnsArr, Seperator))
        println(io)
    end

    return String(take!(io))
end

function PersonalityVoiceHelp()
    S = raw"""Outputs the dialogue lines of IDs.
              Use `id-voice _entry_` to get the voice lines of
              _entry_. You may use the same syntax as in `id help`.
              
              If the verbose flag is set, the dialogue internal ID will
              also be shown. If the entry search will return multiple entries,
              only the first will be displayed, and the Identity Search List
              will be updated.
        """

    println(S)
    return S
end

function PersonalityVoiceParse(input)
    io = Pipe()
    result = redirect_stdout(io) do 
        PersonalityParser(input) 
    end
    close(io)

    if result === nothing
        println("No identities found.")
    elseif result isa Vector && length(result) == 0
        println("No identities found.")
    end

    (result isa Vector) && (result = result[begin])
    isVerbose = match(r"![vV]", input) !== nothing 

    S = getVoiceData(result; verbose = isVerbose)
    println(S)
    return result
end 

PersonalityVoiceRegex = r"^[iI][d|D|dentity]-?[vV]oice (.*)$"
PersonalityVoiceCommand = Command(PersonalityVoiceRegex, PersonalityVoiceParse, 
                                  [1], PersonalityVoiceHelp)
