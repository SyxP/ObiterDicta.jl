module ObiterDicta
    using ReplMaker, InteractiveUtils
    using Term, Term.Layout, Term.Prompts
    using fzf_jll, ripgrep_jll
    using UnicodePlots
    using StringManipulation, Printf
    using Unicode

    using StringDistances

    using Downloads, HTTP, JSON
    using Scratch, Git
    using SHA

    function usesClipboard(input)
        clipboardRegexes = [r"^clipboard (.*)$", r"^(.*) clipboard$"]
        for clipboardRegex in clipboardRegexes
            S = match(clipboardRegex, input)
            if S !== nothing
                return true
            end
        end
        return false
    end

    function ClipboardParser(input)
        clipboardRegexes = [r"^clipboard (.*)$", r"^(.*) clipboard$"]
        for clipboardRegex in clipboardRegexes
            S = match(clipboardRegex, input)
            if S !== nothing
                tmpFile, _ = mktemp()
                io = open(tmpFile, "w")
                returnValue = nothing
                redirect_stdout(io) do
                    returnValue = MainParser(string(S.captures[1]))
                end
                close(io)

                io = open(tmpFile, "r")
                copyString = read(io, String)
                close(io)
                clipboard(completeStrip(copyString))
                println("Output of command $(@red(S.captures[1])) saved to clipboard.")

                return returnValue
            end
        end

        return nothing
    end

    function MainParser(input)
        usesClipboard(input) && return ClipboardParser(input)  
        Commands = [SetLangCommand, HelpCommand, EXPCommand,
                    FiltRegCommand, FuzzySearchCommand,
                    UpdateBundleCommand, BannerGreetingsCommand,
                    BuffCommand, PassiveCommand, SkillCommand,
                    PersonalityCommand, EGOCommand,
                    EGOGiftCommand,
                    MirrorDungeon3Command,
                    PersonalityVoiceCommand, AnnouncerVoiceCommand,
                    ClashCalculatorCommand]
        for command in Commands
            S = CheckCommand(command, input)
            S == false || return S
        end
        @info "Unable to parse $input"
        return
    end

    function getHelp()
        S = raw"""Available Commands:
        lang       - Set Language
        update     - Updates Data Files. Warning: for internal use
        search     - Fuzzy Search

        exp        - Experience Levels
        buff       - Status Effects
        skill      - Skills
        id         - Sinner Identities
        ego        - E.G.Os
        ego-gift   - E.G.O Gifts

        md3        - Mirror Dungeon 3
                  
        greeting   - Profile Card Text
        id-voice   - Identity Voice Lines
        announcer  - Announcer Voice Lines
        clash-calc - Clash Calculator
    
        For more information you can use `[command] help`.
        To save the output of a command to clipboard, use `clipboard [command]`.
        """
        println(S)
    end

    # Back-End Functions
    include("Command.jl")
    include("Printing.jl")
    include("LanguageInternalization.jl")
    include("DebugFunctions.jl")   
    include("KeywordLocalization.jl")
    include("SinnerNames.jl")
    include("ExtensionsHandler.jl")

    # Downloading
    include("DownloadTranslations.jl")
    include("DownloadBundles.jl")
    include("DownloadCatalogS1.jl")

    # Contains File Retrieval and String Searching
    include("Utilities.jl")
    include("CommonInterface.jl")
    include("Filter.jl")

    include("FuzzySearch.jl")
    include("FuzzySearchCommand.jl")

    # Internal Structures
    include("CoinStruct.jl")
    include("RarityUtils.jl")
    include("RegisterFunction.jl")
    include("Items.jl")

    # Utility Modes
    include("ExperienceLevels.jl")

    include("BannerGreetingsStrings.jl")
    include("BannerGreetingsCommand.jl")

    include("BuffStrings.jl")
    include("BuffCommand.jl")
    
    include("PassiveStrings.jl")
    include("PassiveCommand.jl")
   
    include("CombatSkillStrings.jl")
    include("CombatSkillCommand.jl")
    include("CombatSkillBuffs.jl")

    include("IdentityStrings.jl")
    include("IdentityVoice.jl")
    include("IdentityCommand.jl")

    include("EGOStrings.jl")
    include("EGOVoiceStrings.jl")
    include("EGOCommand.jl")

    include("EGOGiftStrings.jl")
    include("EGOGiftCommand.jl")

    include("EnemyStrings.jl")
    include("EnemyCommand.jl")
    include("AbnormalityGuides.jl")

    include("ClashCalculator.jl")

    include("Announcer.jl")
    
    include("BattleStrings.jl")
    include("MirrorDungeon3.jl")
    
    # Dependent on Structs
    include("PanicStrings.jl")
    include("PersonalityPassiveMap.jl")

    function StartREPL()
        currRepl = nothing
        try 
            currRepl = Base.active_repl
        catch _
            return
        end

        initrepl(MainParser, 
             prompt_text="Limbus Query> ",
             prompt_color = :blue, 
             start_key=')', 
             repl = currRepl,
             mode_name="Limbus_mode",
             show_function=(args...) -> nothing)    
    end

    # This will be filled in inside `__init__()`
    git_download_cache = ""
    function __init__()
        global git_download_cache = @get_scratch!("downloaded_files")
        # StartREPL() REPL.jl regression
    end

    export RegisterFunction # For Custom Filter Functions

    # Not meant to be used. Internal hooks
    export qUpdate, UpdateDataFilesFromCatalogS1
end
