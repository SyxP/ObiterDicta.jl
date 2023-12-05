module ObiterDicta
    using ReplMaker
    using Term, Term.Layout, Term.Prompts
    using UnicodePlots

    using InteractiveUtils: clipboard
    using StringManipulation: remove_decorations
    using Unicode

    using StringDistances

    using Downloads, HTTP, JSON
    using Scratch, Git
    using SHA

    function MainParser(input)
        S = match(r"^clipboard (.*)$", input) 
        if S !== nothing
            cFile = mktemp()[1]
            io = open(cFile, "w")
            redirect_stdout(io) do
                MainParser(string(S.captures[1]))
            end
            close(io)

            io = open(cFile, "r")            
            Ans = remove_decorations(read(io, String))
            println("Saved to clipboard. Query: $(S.captures[1])")
            clipboard(Ans)
            close(io)
            return
        end

        Commands = [SetLangCommand, HelpCommand, EXPCommand,
                    FiltRegCommand,
                    UpdateBundleCommand, BannerGreetingsCommand,
                    BuffCommand, PassiveCommand, SkillCommand,
                    PersonalityCommand, EGOCommand,
                    PersonalityVoiceCommand]
        for command in Commands
            S = CheckCommand(command, input)
            S == false || return S
        end
        @info "Unable to parse $input"
        return
    end

    function getHelp()
        S = raw"""Available Commands:
                  lang (Set Language)
                  update (Updates Data Files. Warning: for internal use)
                  exp (Experience Levels)
                  buff (Status Effects)
                  skill (Skills)
                  banner greeting (Profile Card Text)
                  id (Sinner Identities)
                  id-voice (Identity Voice Lines)
                  ego (E.G.Os)
    
                  For more information you can use `[command] help`.
                  To save the information to your clipboard, you can use
                  `clipboard [command] _args_`.
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

    # Internal Structures
    include("CoinStruct.jl")
    include("CharacterStructs.jl")
    include("RarityUtils.jl")
    include("EvalRegisterFunction.jl")

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

    include("IdentityVoice.jl")
    include("IdentityStrings.jl")
    include("IdentityCommand.jl")

    include("EGOVoiceStrings.jl")
    include("EGOStrings.jl")
    include("EGOCommand.jl")
    
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
        StartREPL()
    end

    export RegisterFunction # For RegistryFunctions

    # Not meant to be used. Internal hooks
    export qUpdate, UpdateDataFilesFromCatalogS1
end
