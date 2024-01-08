struct Greeting
    ID :: Int
    Owner
    Condition
end

getMasterFileClasses(::Type{Greeting}) = ["greeting-wordsids"]

function handleDataFile(::Type{Greeting}, MasterList, file)
    for item in StaticData(file)["list"]
        if !haskey(item, "condition") || !haskey(item, "conditionRefId")
            push!(MasterList, Greeting(item["id"], -1, "Default"))
        else
            push!(MasterList, Greeting(item["id"], item["conditionRefId"], item["condition"]))
        end
    end
end

const GreetingMasterList = Greeting[]
function getMasterList(::Type{Greeting})
    getMasterList(Greeting, GreetingMasterList)
end

function getLocalizedList(::Type{Greeting})
    [LocalizedData("IntroductionPreset")]
end

function getInternalVersion(myGreeting :: Greeting; dontWarn = !GlobalDebugMode)
    for GreetingList in getInternalList(Greeting)
        if GreetingList["id"] == myGreeting.ID
            return GreetingList
        end
    end

    dontWarn || @warn "Internal Greeting with ID $(myGreeting.ID) not found."
    return
end

for (fn, str) in [(:getLocalizedWordVersion, "introduce_word_"),
                  (:getLocalizedSentenceVersion, "introduce_sentence_")]
    @eval function ($fn)(myGreeting::Greeting; dontWarn=!GlobalDebugMode)
        for GreetingList in getLocalizedList(Greeting)
            for greeting in GreetingList["dataList"]
                if greeting["id"] == ($str) * string(myGreeting.ID)
                    return greeting
                end
            end
        end

        dontWarn || @warn "Localized Greeting with ID $(myGreeting.ID) not found."
        return
    end
end

getWordContent(greet :: Greeting) = 
    getField(greet, getLocalizedWordVersion, "content", nothing, "")
getUnescapedSentenceContent(greet :: Greeting) =
    getField(greet, getLocalizedSentenceVersion, "content", nothing, "")
getSentenceContent(greet :: Greeting) = 
    EscapeString(getUnescapedSentenceContent(greet))
getStringID(greet :: Greeting) = string(greet.ID)
getStringOwner(greet :: Greeting) = string(greet.Owner)
getEGOFromOwner(greet :: Greeting) = getTitle(EGO(greet.Owner))
getIDFromOwner(greet :: Greeting)  = getEscapedTitle(Personality(greet.Owner))

function toString(greet :: Greeting)
    io = IOBuffer()
    if greet.Condition == "GetEGO"
        println(io, "When acquiring the ego $(@red(getEGOFromOwner(greet))) ($(@dim(getStringOwner(greet)))),")
    elseif greet.Condition == "GetPersonality"
        println(io, "When acquiring the identity $(@red(getIDFromOwner(greet))) ($(@dim(getStringOwner(greet)))),")
    elseif greet.Condition == "Default"
        println(io, "At the start of the game, you get")
    else
        @info "Unable to parse condition of $(greet.ID)"
    end

    println(io, "$(@blue("Word")):  $(getWordContent(greet))")
    println(io, "$(@blue("Sentence")): $(getSentenceContent(greet))")
    return String(take!(io))
end

function getRandomCombination(::Type{Greeting})
    myWord = getWordContent(rand(getMasterList(Greeting)))
    mySentence = getUnescapedSentenceContent(rand(filter(x-> getSentenceContent(x) != "", getMasterList(Greeting))))
    
    if match(r"\{0\}", mySentence) !== nothing
        mySentence = replace(mySentence, "{0}" => @red(myWord))
    end

    return mySentence
end