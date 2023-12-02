module ObiterDictaUnity

    using UnityPy

    function UpdateDataFilesFromCatalogS1()
        # This does everything pseudo-automatically magically
        # It might break if the internal structure changes
        # It might also break with other edits to this file
    
        ObiterDicta.DownloadDataBundles()
        ObiterDicta.DeleteDataFiles()

        bundleLocation = joinpath(git_download_cache, "Bundles")
        unzipLocation = joinpath(git_download_cache, "Unbundled Data") 
        for file in ObiterDicta.getDataURLs()
            filepath = ObiterDicta.getFilePathFromBundleURL(file, bundleLocation)
            @info filepath 
            LoadTextBundle(filepath, unzipLocation)
        end
    
        NewHome = joinpath(unzipLocation, "Assets", "Resources_moved")
        for (root, _, files) in walkdir(NewHome)
            for file in files
                absPath = joinpath(root, file)
                fileName = relpath(absPath, NewHome)
                target = joinpath(DataDir, fileName)
                ObiterDicta.CheckProposedLocation(target)
                mv(absPath, joinpath(DataDir, fileName))
            end
        end
    
        ObiterDicta.cleanUpBundleFolder(unzipLocation)
    end

    function qUpdate(URL = "")
        Latest = ObiterDicta.getLatestCatalogS1()
        if !(URL == "" || URL == Latest)
            ObiterDicta.appendNewCatalogS1Version(URL)
        end
        
        ObiterDicta.updateAll()
        sleep(2)
        @info "Download Complete. Adding Git Commits"
       
        run(`$(git()) status`)
        run(`$(git()) add $(DataDir)`)
        run(`$(git()) commit -m "Update $(getLatestCatalogS1())"`)

        return
    end

    export qUpdate
end