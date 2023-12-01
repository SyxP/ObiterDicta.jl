module ObiterDicta
    using ReplMaker
    using Term, Term.Layout, Term.Prompts
    using StringDistances
    using Unicode
    using JSON

    using Downloads
    using Scratch, Git
    using HTTP
    using SHA

    function MainParser(input)
        Commands = [SetLangCommand, HelpCommand, EXPCommand,
                    UpdateBundleCommand, BannerGreetingsCommand,
                    BuffCommand, PassiveCommand, SkillCommand]
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
    
                  For more information you can use `[command] help`
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

    # Downloading
    include("DownloadTranslations.jl")
    include("DownloadBundles.jl")
    include("DownloadCatalogS1.jl")

    # Contains File Retrieval and String Searching
    include("Utilities.jl")
    include("CommonInterface.jl")

    # Internal Structures
    include("CoinStruct.jl")

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

    include("IdentityStrings.jl")

    include("EGOStrings.jl")
    
    # Dependent on Structs
    include("PanicStrings.jl")
    include("PersonalityPassiveMap.jl")

    function StartREPL()
        initrepl(MainParser, 
             prompt_text="Limbus Query> ",
             prompt_color = :blue, 
             start_key=')', 
             mode_name="Limbus_mode",
             show_function=(args...) -> nothing)    
    end

    # This will be filled in inside `__init__()`
    git_download_cache = ""
    function __init__()
        global git_download_cache = @get_scratch!("downloaded_files")
        StartREPL()
    end

    function qUpdate(URL = "")
        (URL != "") && appendNewCatalogS1Version(URL)
        try
            updateAll()
        catch err
            @info "Update Failed, Likely due to world age issue. Run it again."
            rethrow(err)
        end

        @info "Download Complete. Adding Git Commits"
        run(`$(git()) add $(pkgdir(@__MODULE__))`)
        run(`$(git()) commit -m "Update $(getLatestCatalogS1())"`)
    end

    export qUpdate
end
