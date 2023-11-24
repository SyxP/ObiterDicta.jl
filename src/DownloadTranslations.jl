# The purpose of this file is to ease in the updating process of translations.

function updateTranslation(lang, refSite)
    global git_download_cache
    llang, ulang = lowercase(lang), uppercase(lang)

    srcPath = joinpath(git_download_cache, llang)
    localPath = joinpath(DataDir, "Localize", llang)
    !isdir(localPath) && mkdir(localPath)

    if isdir(srcPath)
        run(`$(git()) -C $(srcPath) pull`)
    else
        mkdir(srcPath)
        run(`$(git()) clone $refSite $(srcPath)`)
    end

    newHome = joinpath(srcPath, "Localize", ulang)
    for (root, dirs, files) in walkdir(newHome)
        for dir in dirs
            path = joinpath(localPath, dir)
            !isdir(path) && mkdir(path)
        end
        Ct = length(newHome) + 1
        while Ct < length(root) && !(uppercase(root[Ct]) ∈ 'A':'Z')
            Ct += 1
        end
        currentFolder = root[Ct:end]

        
        for file in files
            Src = joinpath(root, file)
            Dest = joinpath(localPath, currentFolder, "$(ulang)_" * file)
            cp(Src, Dest, force = true)
        end
    end
end

updateCN() = updateTranslation("cn",
             "https://github.com/LocalizeLimbusCompany/LocalizeLimbusCompany")

