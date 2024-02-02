module ObiterDictaUnity

    using UnityPy, ObiterDicta, Git, ObiterDictaSteam

    function (ObiterDicta.UpdateDataFilesFromCatalogS1)()
        # This does everything pseudo-automatically magically
        # It might break if the internal structure changes
        # It might also break with other edits to this file
    
        ObiterDicta.DownloadDataBundles()
        ObiterDicta.DeleteDataFiles()

        bundleLocation = joinpath(ObiterDicta.git_download_cache, "Bundles")
        unzipLocation = joinpath(ObiterDicta.git_download_cache, "Unbundled Data") 
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
                target = joinpath(ObiterDicta.DataDir, fileName)
                ObiterDicta.CheckProposedLocation(target)
                mv(absPath, joinpath(ObiterDicta.DataDir, fileName))
            end
        end
    
        ObiterDicta.cleanUpBundleFolder(unzipLocation)
    end

    function (ObiterDicta.qUpdate)(URL = "")
        Latest = ObiterDicta.getLatestCatalogS1()
        if !(URL == "" || URL == Latest)
            ObiterDicta.appendNewCatalogS1Version(URL)
        end

        ObiterDictaSteam.getSteamNews()
        
        ObiterDicta.updateAll()
        sleep(2)
        @info "Download Complete. Adding Git Commits"
       
        run(`$(git()) status`)
        run(`$(git()) add $(ObiterDicta.DataDir)`)
        run(`$(git()) commit -m "Update $(ObiterDicta.getLatestCatalogS1())"`)

        return
    end

    export qUpdate
end