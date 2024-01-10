function openFuzzySearch(dir)
    # https://news.ycombinator.com/item?id=38471822
    """rg --ignore-case --color=always --line-number --no-heading @Args |
      fzf --ansi `
          --color 'hl:-1:underline,hl+:-1:underline:reverse' `
          --delimiter ':' `
          --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" `
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'"""

    RipGrepCommand = `$(ripgrep_jll.rg()) --ignore-case --color=always --line-number --no-heading . $dir`
    FzfCommand = `$(fzf_jll.fzf()) --ansi --color 'hl:-1:underline,hl+:-1:underline:reverse' --reverse --delimiter ':' --preview "cat -n {1} " --preview-window 'down,60%,border-top,+{2}-5'`
    read(pipeline(RipGrepCommand, FzfCommand), String)
end