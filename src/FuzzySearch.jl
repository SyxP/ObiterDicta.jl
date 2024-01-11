function openFuzzySearch(dir)
    # https://news.ycombinator.com/item?id=38471822
    """rg --ignore-case --color=always --line-number --no-heading @Args |
      fzf --ansi `
          --color 'hl:-1:underline,hl+:-1:underline:reverse' `
          --delimiter '~' `
          --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" `
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'"""

    RipGrepCommand = `$(ripgrep_jll.rg()) --ignore-case --color=always --line-number --no-heading . $dir --field-match-separator '~' --field-context-separator '~'`
    FzfCommand = `$(fzf_jll.fzf()) --ansi --color 'hl:-1:underline,hl+:-1:underline:reverse' --reverse --delimiter '~' --preview "cat -n {1} " --preview-window 'down,60%,border-top,+{2}-5'`
    return read(pipeline(RipGrepCommand, FzfCommand), String)
end

function searchNews()
    NewsDir = joinpath(DataDir, "News/")
    response = openFuzzySearch(NewsDir)

    URLdb = JSON.parsefile(joinpath(DataDir, "SteamLinks.json"))

    if response !== nothing
        filePath, lineNumber, _ = split(response, "~")
        fileName = splitpath(filePath)[end]

        getURL = get(URLdb, fileName, "")
        println("You have selected $fileName at line $lineNumber.")
        getURL != "" && println("You can find the full News at $(@green(getURL))")
    end

    return response
end