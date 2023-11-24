@enum LangMode begin
    English  = 1
    Japanese = 2
    Korean   = 3
    Chinese  = 4
    Russian  = 5
end 

global CurrLanguage = English

function setLangMode(langStr)
    tmpStr = String(filter(∈('a':'z'), collect(lowercase(langStr))))
    Options = Dict{String, LangMode}([
            "english" => English, "en" => English, "eng" => English, 
            "japanese" => Japanese, "ja" => Japanese, "jp" => Japanese, "jap" => Japanese, 
            "korean" => Korean, "ko" => Korean, "kr" => Korean, "kor" => Korean,
            "chinese" => Chinese, "zh" => Chinese, "cn" => Chinese,
            "russian" => Russian, "ru" => Russian, "rus" => Russian])
    if haskey(Options, tmpStr)
        @info "Language Mode set to $langStr"
        global CurrLanguage = Options[tmpStr]
    else
        @info "Unknown Language Mode $langStr"
    end

    return CurrLanguage
end

function setLangModeHelp()
    S = raw"""Sets the language mode. Options are English (en), Japanese (jp), Korean (kr), Chinese (zh)
              Example Usage: `lang en`
        """
    println(S)
end

function getLangMode()
    Options = Dict{LangMode, String}(English => "en", Japanese => "jp", Korean => "kr", Chinese => "cn", Russian => "ru")
    if haskey(Options, CurrLanguage)
        return Options[CurrLanguage]
    else
        @info "Current LangMode $CurrLanguage is not supported. Defaulting to English"    
        return "en"
    end
end

setLangRegex = r"^(set[ -]?)?lang (.*)$"
SetLangCommand = Command(setLangRegex, setLangMode, [2], setLangModeHelp)
