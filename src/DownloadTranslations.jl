# The purpose of this file is to ease in the updating process of translations.

function updateCN()
    global git_download_cache
    refSite = "https://github.com/LocalizeLimbusCompany/LocalizeLimbusCompany"
    cnPath = joinpath(git_download_cache, "cn")
    localCNPath = joinpath(DataDir, "Localize", "cn")
    !isdir(localCNPath) && mkdir(localCNPath)

    if isdir(cnPath)
        run(`$(git()) -C $(cnPath) pull`)
    else
        mkdir(cnPath)
        run(`$(git()) clone $refSite $(cnPath)`)
    end

    newHome = joinpath(cnPath, "Localize", "CN")
    for (root, dirs, files) in walkdir(newHome)
        for dir in dirs
            path = joinpath(localCNPath, dir)
            !isdir(path) && mkdir(path)
        end
        Ct = length(newHome) + 1
        while Ct < length(root) && !(uppercase(root[Ct]) ∈ 'A':'Z')
            Ct += 1
        end
        currentFolder = root[Ct:end]

        
        for file in files
            Src = joinpath(root, file)
            Dest = joinpath(localCNPath, currentFolder, "CN_" * file)
            cp(Src, Dest, force = true)
        end
    end
end

# Downloads a resource, stores it within a scratchspace
function download_dataset(url)
    fname = joinpath(download_cache, basename(url))
    if !isfile(fname)
        download(url, fname)
    end
    return fname
end