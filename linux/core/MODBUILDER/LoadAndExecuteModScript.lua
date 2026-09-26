-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function HandleModScript(H, MOD_DEF, IsMulti_pak, global_integer_to_float, conf, _bScriptName)
  H.pv(H.THIS.."From HandleModScript()")
  
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strformat = string.format
    local strmatch = string.match
    local strgmatch = string.gmatch
    local strupper = string.upper
    local strrep = string.rep
  local print = print
  local printf = H.printf
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  local My = {}
  
  My.CheckPoint = H.CheckPoint
  
  My.IsFUNCexist = false
  
  My.CheckPoint(2)

  if IsMulti_pak == nil then IsMulti_pak = false end
  
  local file = "" --the current mbin_file_source string
  H.FullPathFile = "" -- the filenamepath of the current or new EXML file
  H.NMSPathFileLessEXML = ""     -- the NMSfilenamepath  of the current or new EXML file
  local ActiveFile = nil  -- the filenamepath of the current EXML file
  My.SavingToDiskDone = false
  
  local AtLeastOne_EXML_CHANGE_TABLE = false
  local AtLeastOne_MBIN_CHANGE_TABLE = false
  
  local TextFileTable = {}
  
  local NumReplacements = 0
  local NumFilesAdded = 0
  local NumREGEXBEFORE = 0
  local NumREGEXAFTER = 0
  local NumXLST = 0
  
  -- local UserScriptName = H.LoadFileData("CurrentModScript.txt")
  -- UserScriptName = strsub(UserScriptName,#(H.gMASTER_FOLDER_PATH..[[ModScript\]])+1)
  local UserScriptName = _bScriptName
  
  --***************************************************************************************************
  local function ExecuteREGEX(H, From, Command, displayCommand, DelayedInfoTable, DelayedReportData)
    -- print("")
    local spacer = "      "
    -- print(spacer..From..": Using 64bit version")
    -- H.Report("","  "..From.."  : Using 64bit version")
    if DelayedInfoTable then
      DelayedInfoTable[#DelayedInfoTable+1] = spacer..H._zBRIGHTGREEN..From..H._zDEFAULT..": "..displayCommand
    else
      print(spacer..H._zBRIGHTGREEN..From..H._zDEFAULT..": "..displayCommand)
    end

    if DelayedInfoTable then
      H.SetReportData(DelayedReportData,"","  "..From.."  : ["..displayCommand.."]")
    else
      H.Report("","  "..From.."  : ["..displayCommand.."]")
    end
    os.execute([[sed-4.7-x64.exe ]]..Command)
  end
  --***************************************************************************************************
  
  --***************************************************************************************************
  local function ObsoleteNames(H, oldName, newName)
    H.Report("","In script, detected: OBSOLETE "..oldName ..", please use "..newName.." instead","NOTICE")
    print(">>> "..H.gcNOTICE.." [NOTICE] In script, detected: OBSOLETE "..oldName ..", please use "..newName.." instead "..H._zDEFAULT)
  end
  --***************************************************************************************************
  
  local CurrentScriptName = H.LoadFileData("CurrentModScript.txt")
  -- because strgsub pattern does not work with all folder names (ex.: ".")
  if strfind(CurrentScriptName,H.gMASTER_FOLDER_PATH..[[ModScript\]],1,true) then
    local start = strfind(CurrentScriptName,H.gMASTER_FOLDER_PATH..[[ModScript\]],1,true)
    CurrentScriptName = strsub(CurrentScriptName,1,start - 1)..strsub(CurrentScriptName,#(H.gMASTER_FOLDER_PATH..[[ModScript\]]) + start)
  end
  CurrentScriptName = "["..CurrentScriptName.."]"
  H.Report(CurrentScriptName,">>>>>>> Loaded script")
  
  local prn2 = H.pv --print

local function AddFiles(H, tRef)
    -- print("")
    print(H._zBRIGHTGREEN..">>> ADDing files:"..H._zDEFAULT)
    H.Report("")
    H.Report("","{>>> ADDing files:")
    
    local WildcardsInUse = false
    
    prn2([[@@@ #tRef = ]]..#tRef)
    for i=1,#tRef do
      --absolute path: H.gNMS_PCBANKS_FOLDER_PATH to NMS pak files folder
      --absolute path: H.gMASTER_FOLDER_PATH to AMUMSS main folder
      --relative path: H.gPathToModbuilderMod
      --relative path: H.gPathToModScriptFromModbuilder
      -- print("")
      -- print("@@@ Processing ADD_FILES["..i.."]")
      
      local okToProcess = true
      
      --checking
      local AddFilesST = tRef[i]
      local EXTFS = ""
      local INTFS = ""
      local FD = {}
      
      if AddFilesST["COMMENT"] and AddFilesST["COMMENT"] ~= "" and type(AddFilesST["COMMENT"]) == "string" then
        local comment = "'"..AddFilesST["COMMENT"].."'"
        -- comment = comment:gsub([[\\]],[[\]]) -- revert needed, see when loading script
        print("")
        print(H._zBRIGHTGREEN..[[ >>> Script's ]]..H._zBLACKonYELLOW..[[ Comment ]]..H._zDEFAULT..[[: <<< ]]..H._zBRIGHTORANGE..comment..H._zDEFAULT.." >>>")
        H.Report("","[Comment] [["..comment.."]]")
      end
      
      local AMUMSSpath = H.gMASTER_FOLDER_PATH
      if AddFilesST["EXTERNAL_FILE_SOURCE"] then
        EXTFS = AddFilesST["EXTERNAL_FILE_SOURCE"]:upper()
        EXTFS = strgsub(EXTFS,"^AMUMSS+",AMUMSSpath)
      end
      
      if AddFilesST["INTERNAL_FILE_SOURCE"] then
        INTFS = AddFilesST["INTERNAL_FILE_SOURCE"]:upper()
      end
      
      if AddFilesST["FILE_DESTINATION"] then
        if type(AddFilesST["FILE_DESTINATION"]) == "string" then
          FD[1] = AddFilesST["FILE_DESTINATION"]:upper()
          if FD[1] == "" then
            print(">>> "..H.gcWARNING.." [WARNING] FILE_DESTINATION is EMPTY. Please verify your script "..H._zDEFAULT)
            H.Report(CurrentScriptName,"FILE_DESTINATION is EMPTY. Please verify your script","WARNING")
            okToProcess = false
          end
        elseif type(AddFilesST["FILE_DESTINATION"]) == "table" then
          FD = AddFilesST["FILE_DESTINATION"]
          for j=1,#FD do
            FD[j] = FD[j]:upper()
            if FD[j] == "" then
              print(">>> "..H.gcWARNING.." [WARNING] FILE_DESTINATION["..j.."] is EMPTY. Please verify your script "..H._zDEFAULT)
              H.Report(CurrentScriptName,"FILE_DESTINATION["..j.."] is EMPTY. Please verify your script","WARNING")
              okToProcess = false
            end
          end
        else
          print(">>> "..H.gcWARNING.." [WARNING] FILE_DESTINATION["..i.."] is NOT a string or table of strings. Please verify your script "..H._zDEFAULT)
          H.Report(CurrentScriptName,"FILE_DESTINATION["..i.."] is NOT a string or table of strings. Please verify your script","WARNING")
          okToProcess = false
        end
        
        if okToProcess then
          for j=1,#FD do
            if FD[j] == "" then
              print(">>> "..H.gcWARNING.." [WARNING] Unknown FILE_DESTINATION["..i.."]. Please verify your script "..H._zDEFAULT)
              H.Report(CurrentScriptName,"Unknown FILE_DESTINATION["..i.."]. Please verify your script","WARNING")
              okToProcess = false
              break
            end
          end
        end
      else
        print(">>> "..H.gcWARNING.." [WARNING] Missing FILE_DESTINATION. Please verify your script "..H._zDEFAULT)
        H.Report(CurrentScriptName,"Missing FILE_DESTINATION. Please verify your script","WARNING")
        okToProcess = false
      end
      
      local INTERNAL_Exist = false
      local EXTERNAL_Exist = false
      local CONTENT_Exist = false
      
      INTERNAL_Exist = INTFS ~= nil and INTFS ~= ""
      EXTERNAL_Exist = EXTFS ~= nil and EXTFS ~= ""
      CONTENT_Exist = AddFilesST["FILE_CONTENT"] ~= nil --it could be ""
      
      local TooManyErr = false
      if CONTENT_Exist then
        if INTERNAL_Exist or EXTERNAL_Exist then
          --error: too many
          TooManyErr = true
          okToProcess = false
        end
      elseif INTERNAL_Exist then
        if EXTERNAL_Exist then
          --error: too many
          TooManyErr = true
          okToProcess = false
        end
      elseif not EXTERNAL_Exist then
        --error: all 3 missing
        print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES["..i.."]: One of INTERNAL_FILE_SOURCE, EXTERNAL_FILE_SOURCE or FILE_CONTENT must be used. Please verify your script "..H._zDEFAULT)
        H.Report(CurrentScriptName,"ADD_FILES["..i.."]: One of INTERNAL_FILE_SOURCE, EXTERNAL_FILE_SOURCE or FILE_CONTENT must be used. Please verify your script","WARNING")
        okToProcess = false
      end
      
      if TooManyErr then
        print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES["..i.."]: ONLY one of INTERNAL_FILE_SOURCE, EXTERNAL_FILE_SOURCE or FILE_CONTENT must be used. Please verify your script "..H._zDEFAULT)
        H.Report(CurrentScriptName,"ADD_FILES["..i.."]: ONLY one of INTERNAL_FILE_SOURCE, EXTERNAL_FILE_SOURCE or FILE_CONTENT must be used. Please verify your script","WARNING")
      end
      --End checking
      
      --#########################################
      if okToProcess then
        for j=1,#FD do
          local DestNormOrgFilenamePath = H.NormalizePath(FD[j])
          prn2("@@@ 1: DestNormOrgFilenamePath = ["..DestNormOrgFilenamePath.."]")
          
          local newFilenameProvided = false
          local _,count = strgsub(DestNormOrgFilenamePath,[[%.]],"") --escaping '.'
          prn2("@@@    count '.' = "..count)
          if count == 0 then
            --no extension, assume it is a folder name and that the end '\' is missing
            --add '\'
            DestNormOrgFilenamePath = strgsub(DestNormOrgFilenamePath..[[\]],[[\\]],[[\]])
            prn2("@@@ 1A: DestNormOrgFilenamePath = ["..DestNormOrgFilenamePath.."]")
          else
            newFilenameProvided = true
          end
          
          --local DestNormFolderPath = H.NormalizePath(H.gMASTER_FOLDER_PATH .. H.gPathToModbuilderMod .. H.GetFolderPathFromFilePath(DestNormOrgFilenamePath)) --..[[\]])
          local DestNormFolderPath = H.NormalizePath(H.gPathToModbuilderMod .. H.GetFolderPathFromFilePath(DestNormOrgFilenamePath)) --..[[\]])
          prn2("@@@ 2:      DestNormFolderPath = ["..DestNormFolderPath.."]")
          --local DestNormFilePath = H.NormalizePath(H.gMASTER_FOLDER_PATH .. H.gPathToModbuilderMod .. DestNormOrgFilenamePath)
          local DestNormFilePath = H.NormalizePath(H.gPathToModbuilderMod .. DestNormOrgFilenamePath)
          prn2("@@@ 3:        DestNormFilePath = ["..DestNormFilePath.."]")
          
          local _,count = strgsub(DestNormOrgFilenamePath,[[\]],"")
          prn2("@@@    count '\\' = "..count)
          if count > 0 then
            if not H.IsDirExist(strgsub(DestNormFolderPath,[[\]],[[\\]])) then
              local DestNormFolderPathNoMod = strgsub(DestNormFolderPath,H.gPathToModbuilderMod,"")
              if not H.gIs_LEAN_MODE then
                print("       new folder: " .. DestNormFolderPathNoMod)
              end
              H.Report("","       new 'folder': "..[["]]..DestNormFolderPathNoMod..[["]])
              DestNormFolderPath = strgsub(DestNormFolderPath,[[\]],[[\\]])
              H.mkdir(DestNormFolderPath)
            end
          end
          
          --*********************
          if INTERNAL_Exist then
            --process INTERNAL:
            --       source = NMS path and filename
            --  destination = where I like in the style of NMS paths and filename!
            --                absolute or relative to ModScript folder
            --                with or without Destination Filename
            local source = H.NormalizePath(INTFS)
            local pakName = H.LocateAnyFileInPAK(source)
            if pakName ~= "" then
              --we need to get the file from this NMS pak and send it to DESTINATION
              prn2("@@@ pakName = "..pakName)
              
              --were to save the extracted file
              local tmpFilePath = [[.\_INTERNAL]]
              H.mkdir(tmpFilePath)
              
  -- local cmd = [[psarc.exe extract "]]..H.gNMS_PCBANKS_FOLDER_PATH..pakName..[[" --to="]]..tmpFilePath..[[" "]]..source..[[" -y]]
  -- ONE file at the time
  local cmd = [[hgpaktool.exe -U --upper -A -O "]]..tmpFilePath..[[" -f "]]..string.gsub(source,[[\]],[[/]])..[[" "]]..H.gNMS_PCBANKS_FOLDER_PATH..pakName..[["]]
  -- print("A: "..cmd)
              prn2("@@@ 5a: cmd = ["..cmd.."]")
              local success,sResult,nResult = H.NewThread(cmd)
              prn2("@@@ 5b: result = ["..strformat("%s, %s with (%d)",success,sResult,nResult).."]")
              
              if success then
                --now we copy it to DESTINATION
                
                --point to MODBUILDER\_INTERNAL
                FilePathSource = tmpFilePath..[[\]]..source
                
                local newFilename = H.GetFilenameFromFilePath(DestNormOrgFilenamePath)
                prn2("@@@ 5c: newFilename = ["..newFilename.."]")
                
                local src = FilePathSource
                local dest = DestNormOrgFilenamePath
                
                --do we need to add the filename to dest?
                if not newFilenameProvided then
                  --no filename given, use current name of the source with the destination path
                  local currentFilename = H.GetFilenameFromFilePath(FilePathSource)
                  prn2("@@@ 5e: currentFilename = ["..currentFilename.."]")
                  local currentFilenamePath = H.NormalizePath([[.\MOD\]]..dest..[[\]]..currentFilename)
                  if not H.gIs_LEAN_MODE then
                    print("        create file: "..currentFilenamePath)
                  end
                  H.Report("","      create 'file': "..[["]]..currentFilenamePath..[["]])
                  dest = currentFilenamePath
                else
                  --use destination new path and filename
                  local currentFilenamePath = H.NormalizePath([[.\MOD\]]..dest)
                  if not H.gIs_LEAN_MODE then
                    print("        create file: "..currentFilenamePath)
                  end
                  H.Report("","      create 'file': "..[["]]..currentFilenamePath..[["]])
                  dest = currentFilenamePath
                end
                
                prn2("@@@ 5f:  src = ["..src.."]")
                -- print("@@@ 5g: dest = ["..strsub(dest,7).."]")
                -- printf("UserScriptName = %s",UserScriptName)
                -- add to list
                if not scriptFileList[dest] then
                  scriptFileList[dest] = {}
                end
                scriptFileList[dest][#scriptFileList[dest]+1] = UserScriptName
                    
                os.remove(dest) --so that MoveFileDirectory() can move it
                local success,errmsg = H.MoveFileDirectory(src,dest)
                if not success then
                  print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES["..i.."]: Could not copy INTERNAL_FILE_SOURCE to DESTINATION. Please verify your script "..H._zDEFAULT)
                  H.Report(CurrentScriptName,"ADD_FILES["..i.."]: Could not copy INTERNAL_FILE_SOURCE to DESTINATION. Please verify your script","WARNING")
                end
                
                NumFilesAdded = NumFilesAdded + 1
              else
                print(">>> "..H.gcWARNING.." [WARNING] Cannot extract file "..H._zDEFAULT..source)
                H.Report("","Cannot extract file "..source,"WARNING")
              end
              
              --remove temp folder
              H.DeleteDir(tmpFilePath)
              
            else
              print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES["..i.."]: Cannot find INTERNAL_FILE_SOURCE in NMS paks. Please verify your script "..H._zDEFAULT)
              H.Report(CurrentScriptName,"ADD_FILES["..i.."]: Cannot find INTERNAL_FILE_SOURCE in NMS paks. Please verify your script","WARNING")
            end
            
          --*********************
          elseif CONTENT_Exist then
            --process FILE_CONTENT:
            --       source = FILE_CONTENT
            --  destination = a NMS path in MODBUILDER\MOD folder
            --                a Destination Filename is REQUIRED
            if not newFilenameProvided then
              print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES["..i.."]: Missing DESTINATION filename, required with FILE_CONTENT. Please verify your script "..H._zDEFAULT)
              H.Report(CurrentScriptName,"ADD_FILES["..i.."]: Missing DESTINATION filename, required with FILE_CONTENT. Please verify your script","WARNING")
            else
              if not H.gIs_LEAN_MODE then
                print("      create file: "..DestNormOrgFilenamePath)
              end
              H.Report("","      create 'file': "..[["]]..DestNormOrgFilenamePath..[["]])
              DestNormFilePath = strgsub(DestNormFilePath,[[\]],[[\\]])
              local FileData = AddFilesST["FILE_CONTENT"]:gsub([[\\]],[[\]]) -- change \\ to \ in the string
              
              if type(FileData) == "string" and H.ltrim(FileData):sub(1,5) == [[<?xml]] then
                -- an EXML: auto-indentation ON
                local FileDataTable = H.stringToTable(FileData)
                
                -- print(" = = = = = BEFORE")
                -- for i=1,#FileDataTable do
                  -- print(FileDataTable[i])
                -- end
                -- print(" = = = = = END BEFORE")

                FileDataTable = H.AutoAdjustIndentation(FileDataTable,FileDataTable,1)
                
                -- print(" = = = = = AFTER")
                -- for i=1,#FileDataTable do
                  -- print(FileDataTable[i])
                -- end
                -- print(" = = = = = END AFTER")
-- H.WFAK()
                FileData = table.concat(FileDataTable,"\n")
              end
              
              -- add to list
              local dest = strsub(DestNormFilePath,strfind(DestNormFilePath,[[MOD\\]],1,true)+5):gsub([[\\]],[[\]])
              -- print("@@@ CONTENT: Dest = ["..dest.."]")
              -- printf("UserScriptName = %s",UserScriptName)
              if not scriptFileList[dest] then
                scriptFileList[dest] = {}
              end
              scriptFileList[dest][#scriptFileList[dest]+1] = UserScriptName
              
              H.WriteToFile(FileData, DestNormFilePath)
              NumFilesAdded = NumFilesAdded + 1
            end
            
          --*********************
          elseif EXTERNAL_Exist then
            --process EXTERNAL:
            --       source = where it is(absolute or relative to ModScript folder)
            --  destination = a NMS path in MODBUILDER\MOD folder
            --                with or without Destination Filename
            
            local FilePathSource = ""
            if strsub(EXTFS,2,2) == ":" then
              --we have a complete path
              FilePathSource = EXTFS
            else
              -- path relative to current script folder
              FilePathSource = H.GetFolderPathFromFilePath(H.LoadFileData("CurrentModScript.txt"))..[[\]]..EXTFS
            end
            
            WildcardsInUse = WildcardsInUse or H.IsWildcardsExist(FilePathSource)
            
            FilePathSource = H.NormalizePath(FilePathSource)
            prn2("@@@ 4: FilePathSource = ["..FilePathSource.."]")
            
            if H.IsFileExist(FilePathSource) then
              local newFilename = H.GetFilenameFromFilePath(DestNormOrgFilenamePath)
              prn2("@@@ 4a: newFilename = ["..newFilename.."]")
              
              if not newFilenameProvided then
                --no filename given, use current name
                local currentFilename = H.GetFilenameFromFilePath(FilePathSource)
                prn2("@@@ 4b: currentFilename = ["..currentFilename.."]")
                prn2("@@@ 4c: DestNormFolderPath\\currentFilename = ["..DestNormFolderPath..[[\]]..currentFilename.."]")
                local currentFilenamePath = H.NormalizePath(DestNormFolderPath..[[\]]..currentFilename)
                if not H.gIs_LEAN_MODE then
                  print("        create file: "..currentFilenamePath)
                end
                H.Report("","      create 'file': "..[["]]..currentFilenamePath..[["]])
                
                local success,sResult,nResult = H.CopyFile(FilePathSource,DestNormFolderPath,[[/y /h /i /r /q]],false)
                
                prn2("@@@ 4d: result = ["..strformat("success = %s, %s with (%d)",success,sResult,nResult).."]")
                if success == nil then
                  print(">>> "..H.gcWARNING.." [WARNING] Could not copy file(s) "..H._zDEFAULT)
                  H.Report("","Could not copy file(s)","WARNING")
                  NumFilesAdded = NumFilesAdded - 1
                else
                  local tmp = strsub(currentFilenamePath,7)
                  -- print("@@@ 4e: FilePathSource = ["..tmp.."]")
                  -- printf("UserScriptName = %s",UserScriptName)
                  -- add to list
                  if not scriptFileList[tmp] then
                    scriptFileList[tmp] = {}
                  end
                  scriptFileList[tmp][#scriptFileList[tmp]+1] = UserScriptName
                  
                end
              else
                --use destination new filename
                local newFilenamePath = strgsub(DestNormFolderPath..[[\]]..newFilename,[[\\]],[[\]])
                prn2("@@@ 4f: newFilenamePath = ["..newFilenamePath.."]")
                if not H.gIs_LEAN_MODE then
                  print("        create file: "..newFilenamePath)
                end
                H.Report("","      create 'file': "..[["]]..newFilenamePath..[["]])
                
                local success,sResult,nResult = H.CopyFile(FilePathSource,newFilenamePath..[[*]],[[/y /h /i /r /q]],false)
                
                prn2("@@@ 4g: result = ["..strformat("success = %s, %s with (%d)",success,sResult,nResult).."]")
                if success == nil then
                  print(">>> "..H.gcWARNING.." [WARNING] Could not copy any file "..H._zDEFAULT)
                  H.Report("","Could not copy any file","WARNING")
                  NumFilesAdded = NumFilesAdded - 1
                else
                  local tmp = strsub(newFilenamePath,7)
                  -- print("@@@ 4h: FilePathSource = ["..tmp.."]")
                  -- printf("UserScriptName = %s",UserScriptName)
                  -- add to list
                  if not scriptFileList[tmp] then
                    scriptFileList[tmp] = {}
                  end
                  scriptFileList[tmp][#scriptFileList[tmp]+1] = UserScriptName
                  
                end
              end
              NumFilesAdded = NumFilesAdded + 1
              
            else
              print(">>> "..H.gcWARNING.." [WARNING] Cannot find file or path "..H._zDEFAULT.." "..FilePathSource)
              H.Report("","Cannot find file or path "..FilePathSource,"WARNING")
            end
          end
          -- print("")
        end --for j=1,#FD do
      -- else
        -- print("")
      end --okToProcess
      -- print("")
    end --for i=1,#tRef do
    
    My.ADD_FILES_End = H.dClock(os.clock() - My.ADD_FILES_Start)
    if WildcardsInUse then
      print("\n    >>>>> Ended with "..NumFilesAdded .. " files/groups of files ADDed in "..My.ADD_FILES_End.." <<<<<\n")
      H.Report("","\n    >>>>> Ended with "..NumFilesAdded .. " files/groups of files ADDed in "..My.ADD_FILES_End.." <<<<<\n}")
    else
      print("\n    >>>>> Ended with "..NumFilesAdded .. " files ADDed in "..My.ADD_FILES_End.." <<<<<\n")
      H.Report("","\n    >>>>> Ended with "..NumFilesAdded .. " files ADDed in "..My.ADD_FILES_End.." <<<<<\n}")
    end
    
end
  
  --Add new files
  prn2(" >>> JUST BEFORE ADD_FILES <<<")
  My.ADD_FILES_Start = os.clock()
  if MOD_DEF["ADD_FILES"] and type(MOD_DEF["ADD_FILES"]) == "table" and #MOD_DEF["ADD_FILES"] > 0 then
    AddFiles(H, MOD_DEF["ADD_FILES"])

  else
    if MOD_DEF["ADD_FILES"] then
      if type(MOD_DEF["ADD_FILES"]) ~= "table" then
        print(H.gcWARNING.."    [WARNING] ADD_FILES not a table. Check script... "..H._zDEFAULT)
        H.Report("","ADD_FILES is not a table. Check script...","WARNING")
      else
        print("    [INFO]"..H._zBRIGHTGREEN.." ADD_FILES table is empty."..H._zDEFAULT)
        H.Report("","ADD_FILES table is empty.","INFO")
      end
    end
  end
  -- print("")
  -- print("================>>> conf")
  -- for k,v in pairs(conf) do
    -- printf("k = <%s>, v = <%s>",k,tostring(v))
  -- end
  -- print("")

  prn2(">>> JUST BEFORE MODIFICATIONS <<<")
  if MOD_DEF["MODIFICATIONS"] then
    for n=1,#MOD_DEF["MODIFICATIONS"] do
      local iEXML_CT_IsNil = false
      local iEXML_CT_IsString = false
      local iEXML_CT_IsNoSubTable = falsew
      
      local nMOD = MOD_DEF["MODIFICATIONS"][n]
      
      -- alias
      if nMOD["MBIN_CT"] then
        nMOD["MBIN_CHANGE_TABLE"] = nMOD["MBIN_CT"]
        -- nMOD["MBIN_CT"] = nil -- kept so that script can refer to it
      end
      
      if nMOD["MBIN_CHANGE_TABLE"] then
        -- H.pv([[==> type(nMOD["MBIN_CHANGE_TABLE"]) = ]]..type(nMOD["MBIN_CHANGE_TABLE"]))
        -- H.pv([[==> #nMOD["MBIN_CHANGE_TABLE"] = ]]..#nMOD["MBIN_CHANGE_TABLE"])
        
        local RemoveFlagExist = false
-- printf("A: RemoveFlagExist = %s",tostring(RemoveFlagExist))

        -- to allow to update content of MBIN_CT table while the script is running (thru the use of EXT_FUNC)
        local i_MBIN_CT = 1
        while i_MBIN_CT <= #nMOD["MBIN_CHANGE_TABLE"] do
        -- for i_MBIN_CT=1,#nMOD["MBIN_CHANGE_TABLE"] do
          if H.WDEBUG then H.WFAK("============>>>>>> Just entering pre-processing mbin_change_table["..i_MBIN_CT.."]") end
          local mMBIN_CT = nMOD["MBIN_CHANGE_TABLE"][i_MBIN_CT]
          
          -- alias
          if mMBIN_CT["MBIN_FS"] then
            mMBIN_CT["MBIN_FILE_SOURCE"] = mMBIN_CT["MBIN_FS"]
            -- mMBIN_CT["MBIN_FS"] = nil -- kept so that script can refer to it
          end

          -- these were renamed
          if mMBIN_CT["EXML_CHANGE_TABLE"] then
            ObsoleteNames(H, "EXML_CHANGE_TABLE","MXML_CHANGE_TABLE")
          end

          if mMBIN_CT["EXML_CT"] then
            mMBIN_CT["EXML_CHANGE_TABLE"] = mMBIN_CT["EXML_CT"]
            -- mMBIN_CT["EXML_CT"] = nil -- kept so that script can refer to it
            ObsoleteNames(H, "EXML_CT","MXML_CT")
          end

          if mMBIN_CT["MXML_CT"] then
            mMBIN_CT["EXML_CHANGE_TABLE"] = mMBIN_CT["MXML_CT"]
            -- mMBIN_CT["MXML_CT"] = nil -- kept so that script can refer to it
          end

          if mMBIN_CT["MXML_CHANGE_TABLE"] then
            -- we do this for now UNTIL we change the internal name
            mMBIN_CT["EXML_CHANGE_TABLE"] = mMBIN_CT["MXML_CHANGE_TABLE"]
            -- mMBIN_CT["MXML_CHANGE_TABLE"] = nil -- kept so that script can refer to it
          end
          -- END: these were renamed

          -- -- create an empty table if MXML_CHANGE_TABLE does not exist, IT IS REQUIRED
          -- if not mMBIN_CT["EXML_CHANGE_TABLE"] then
            -- mMBIN_CT["EXML_CHANGE_TABLE"] = {{}} -- a table of one empty table
          -- end
          
          -- local RequestedExmlDATA = mMBIN_CT["EXML_DATA"]
          -- if RequestedExmlDATA and (RequestedExmlDATA == "" or #RequestedExmlDATA == 0 or RequestedExmlDATA[1] == "") then
            -- RequestedExmlDATA = nil
          -- end
          
          -- *****************   EXTERNAL FUNCTION CALL: ext_func section   ********************
          -- = = = = WARNING handling = = = =
          H.IsExFunc = false
          
          My.ext_func = mMBIN_CT["EXT_FUNC"]
          if My.ext_func and (My.ext_func == "" or #My.ext_func == 0) then
            My.ext_func = nil
          end

          if My.ext_func then
            if type(My.ext_func) == "table" then      
              for i=1,#My.ext_func do
                if type(My.ext_func[i]) == "string" then
                  -- printf("==================>>> My.ext_func[%d] = [%s]",i,tostring(My.ext_func[i]))
                  if type(conf[My.ext_func[i]]) ~= "function" then
                    print(">>> "..H.gcWARNING..[=[ [WARNING] In your script, the name of 'EXT_FUNC[]=]..i..[=[]' does not refer to a valid function name, please correct! ]=]..H._zDEFAULT)
                    H.Report("",[=[>>> In your script, the name of 'EXT_FUNC[]=]..i..[=[]' does not refer to a valid function name, please correct!]=],"WARNING")
                    My.ext_func = nil
                  end        
                else
                  print(">>> "..H.gcWARNING..[=[ [WARNING] In your script, the name of 'EXT_FUNC[]=]..i..[=[]' is not a string, please correct! ]=]..H._zDEFAULT)
                  H.Report("",[=[>>> In your script, the name of 'EXT_FUNC[]=]..i..[=[]' is not a string, please correct!]=],"WARNING")
                  My.ext_func = nil
                end
              end -- for i=1,#ext_func do
            else
              print(">>> "..H.gcWARNING..[[ [WARNING] In your script, 'EXT_FUNC' is not a table, please correct! ]]..H._zDEFAULT)
              H.Report("",[[>>> In your script, 'EXT_FUNC' is not a table, please correct!]],"WARNING")
              My.ext_func = nil
            end -- if type(ext_func) == "table" then
          end
          
          if My.ext_func then
            H.IsExFunc = true
          end
          --***************************************************************************************************
          
          AtLeastOne_MBIN_CHANGE_TABLE = true
          
          local NEW_FILEPATH_AND_NAME = {}
          local REMOVE_FLAG = {}
          local mbin_file_source = mMBIN_CT["MBIN_FILE_SOURCE"]

          if mbin_file_source == nil then
            mbin_file_source = {}
          end
          if H.gDEBUG_EXT_FUNC then printf("^v^v^v #mbin_file_source = %d",#mbin_file_source) end
          
          --=================== Test which mbin_file_source alt syntax is used ========================
          local syntax = 0
          if type(mbin_file_source) ~= "table" then
            -- ==============================================================================================================================  alternate syntax #1
            syntax = 1
            -- H.pv("alt syntax #1: only a string.  Make it a table, we want a table!")
            mbin_file_source = {}
            mbin_file_source[1] = H.MXML_PC_EXMLtoMBIN(mMBIN_CT["MBIN_FILE_SOURCE"])
            NEW_FILEPATH_AND_NAME[#NEW_FILEPATH_AND_NAME+1] = ""
            REMOVE_FLAG[#REMOVE_FLAG+1] = ""
            
            -- for Conflicts
            if mbin_file_source[1] == nil then mbin_file_source[1] = "" end
            -- H.pv("#1 [a String] "..mbin_file_source[1]..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"])
            H.WriteToFileAppend(mbin_file_source[1]..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"].."\n", "MBIN_PAKS.txt")
            
          else
            -- ["MBIN_FILE_SOURCE"]     = { 
                      -- {"METADATA\SIMULATION\ENVIRONMENT\PLANETBUILDINGTABLE.MBIN", "METADATA\SIMULATION\ENVIRONMENT\PLANETBUILDINGTABLE.MBIN"}
                      -- }
            local tempTable = {}
            local tempConflicts = {}
            for i=1,#mbin_file_source do
              if type(mbin_file_source[i]) == "table" then
                -- ==============================================================================================================================  alternate syntax #3
                syntax = 3
                -- handle MBIN_FILE_SOURCE as a table of tables
                -- H.pv("alt syntax #3: Convert mbin_file_source to a simple table")
                tempTable[#tempTable+1] = H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][1])
                
                --and save info for NEW_FILEPATH_AND_NAME
                NEW_FILEPATH_AND_NAME[#NEW_FILEPATH_AND_NAME+1] = H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][2])
                
                if strfind(tempTable[#tempTable],[[LANGUAGE\]],1,true) then
                  -- a LANGUAGE file
                  if H.gFastPAKlist[tempTable[#tempTable]] then
                    -- a genuine NMS LANGUAGE file, record it
                    H.parentOfCustomLanguageFiles[NEW_FILEPATH_AND_NAME[#NEW_FILEPATH_AND_NAME]] = tempTable[#tempTable]
                  else
                    -- go up the chain to find the original
                    for k,v in pairs(H.parentOfCustomLanguageFiles) do
                      -- WBERTRO: to be completed
                    end
                  end
                end
                
                if mbin_file_source[i][3] == nil then
                  REMOVE_FLAG[#REMOVE_FLAG+1] = ""
                else
                  REMOVE_FLAG[#REMOVE_FLAG+1] = strupper(mbin_file_source[i][3])
                end
                
                -- for Conflicts
                if REMOVE_FLAG[#REMOVE_FLAG] == "" then
                  -- H.pv("#3.1: Adding to tempConflicts "..H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][1]))
                  tempConflicts[#tempConflicts+1] = H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][1])
                else
                  -- H.pv("["..REMOVE_FLAG[#REMOVE_FLAG].."]")
                  -- let us remove any sign of mbin_file_source[i][1] in tempConflicts
                  for tC=1,#tempConflicts do
                    if tempConflicts[tC] == H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][1]) then
                      -- table.remove(tempConflicts,tC)
                      tempConflicts[tC] = "NIL"
                    end
                  end
                  tempConflicts = H.refreshTable(tempConflicts)
                end
                -- H.pv("#3.2 [T of T] "..H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][2])..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"])
                H.WriteToFileAppend(H.MXML_PC_EXMLtoMBIN(mbin_file_source[i][2])..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"].."\n", "MBIN_PAKS.txt")
                
              else
                -- ==============================================================================================================================  alternate syntax #2
                syntax = 2
                -- print("alt syntax #2: Handle MBIN_FILE_SOURCE as a table of strings")
                tempTable[#tempTable+1] = H.MXML_PC_EXMLtoMBIN(mbin_file_source[i])
                NEW_FILEPATH_AND_NAME[#NEW_FILEPATH_AND_NAME+1] = ""
                REMOVE_FLAG[#REMOVE_FLAG+1] = ""
                
                -- for Conflicts
                -- H.pv("#2 [T of String(s)] "..H.MXML_PC_EXMLtoMBIN(mbin_file_source[i])..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"])
                H.WriteToFileAppend(H.MXML_PC_EXMLtoMBIN(mbin_file_source[i])..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"].."\n", "MBIN_PAKS.txt")
              end
            end
            
            -- if some were left, record them
            -- H.pv("#tempConflicts = "..#tempConflicts)
            for tC=1,#tempConflicts do
              H.pv("#3.1 [T of T] "..tempConflicts[tC]..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"])
              H.WriteToFileAppend(tempConflicts[tC]..", "..UserScriptName..": "..MOD_DEF["MOD_FILENAME"].."\n", "MBIN_PAKS.txt")
            end
            
            mbin_file_source = tempTable
          end
          --=================== END: Test which mbin_file_source alt syntax is used ========================
          
          if H.WDEBUG then print("*** syntax = type "..syntax) end
          if #mbin_file_source == 0 and not H.IsExFunc then
            print(">>> "..H.gcWARNING.." [WARNING] No MBIN source file specified for MBIN_CHANGE_TABLE["..i_MBIN_CT.."]! Check script... "..H._zDEFAULT)
            H.Report("","No MBIN source file specified for MBIN_CHANGE_TABLE["..i_MBIN_CT.."]! Check script...","WARNING")
          end
          
          -- local OkToSkipOpeningFile = false
          
          if mMBIN_CT["COMMENT"] and mMBIN_CT["COMMENT"] ~= "" and type(mMBIN_CT["COMMENT"]) == "string" then
            local comment = "'"..mMBIN_CT["COMMENT"].."'"
            -- comment = comment:gsub([[\\]],[[\]]) -- revert needed, see when loading script
            print("")
            print(H._zBRIGHTGREEN..[[ >>> Script's ]]..H._zBLACKonYELLOW..[[ MBIN_CT Comment ]]..H._zDEFAULT..[[: <<< ]]..H._zBRIGHTORANGE..comment..H._zDEFAULT.." >>>")
            H.Report("","[Comment] [["..comment.."]]")
          end

          -- PRE-processing MBIN_CT loop
          local MBIN_table = {}
          for u=1,#mbin_file_source do
            --change MBIN.PC/MBIN to EXML
            local file = H.NormalizePath(mbin_file_source[u])
            file = strgsub(file,[[%.MBIN%.PC]],[[.MBIN]])
            file = strgsub(file,[[%.MXML]],[[.MBIN]])
            
            -- remove extension
            local fileLessEXT = strgsub(file,H.GetExtensionFromFilePath(file).."$","")
            if H.WDEBUG then print("*** local fileLessEXT = ["..tostring(fileLessEXT).."]") end

            -- -- ^V^V^V^V
            -- print("\n"..">>> "..H._zUnderline..H._zYELLOW..file..H._zDEFAULT)
            -- -- ^V^V^V^V
            
            H.FullPathFile = H.gPathToModbuilderMod..strgsub(file,[[%.MBIN]],[[.MXML]])
            if H.WDEBUG then print("***        H.FullPathFile = ["..H.FullPathFile.."]") end
            
            if not H.EXMLmodTable[fileLessEXT] and not H.IsFileExist(H.FullPathFile) then
              -- EXML NOT in MOD: we need to get a fresh copy in MOD
              --   MAY not exist?
              if H.WDEBUG then print(H.FullPathFile.." n'existe pas in MOD") end
              
              -- add to list of files to unpack into _TEMP\EXTRACTED and decompile into _TEMP\DECOMPILED
              MBIN_table[#MBIN_table+1] = file
            end
          end
          
          -- for xyz=1,#MBIN_table do
            -- H.printf("===> xyz: MBIN_table[%d] = <%s>",xyz,MBIN_table[xyz])
          -- end
          
          if #MBIN_table > 0 then
            -- we need to unpack / decompile those files and copy them into MODBUILDER\MOD
            -- printf("#MBIN_table = %d",#MBIN_table)
            -- H.DprintTable(MBIN_table)
            -- H.WFAKD("THIS MUST BE RESOLVED...")
            H.ProcessMBINtable(MBIN_table,H.IsCOMBINE_MODS_flag,UserScriptName,"AMUMSS")
          end
          -- END: PRE-processing MBIN_CT loop

          -- Main MBIN_CT loop
          for u=1,#mbin_file_source do
            My.startTimeThisMBIN = os.clock()
            -- printf("startTimeThisMBIN = %f",My.startTimeThisMBIN)
            
            if H.WDEBUG then H.WFAK("\n===========>>>>>> Just entering loop processing mbin_file_source["..u.."]") end

            H.newMBINtoCreate = false
            local ReplaceNumber = 0
            local NumREGEXBEFORElocal = 0
            local NumREGEXAFTERlocal = 0
            local NumXLSTlocal = 0
            
            --change MBIN.PC/MBIN to EXML
            file = strgsub(mbin_file_source[u],[[%.MBIN%.PC]],[[.MBIN]])
            file = strgsub(file,[[%.MBIN]],[[.MXML]])
            file = H.NormalizePath(file)
            
            -- remove extension
            local fileLessEXML = strgsub(file,H.GetExtensionFromFilePath(file).."$","")
            if H.WDEBUG then print("*** fileLessEXML = ["..fileLessEXML.."]") end
            -- ^V^V^V^V
            print("\n"..">>> "..H._zUnderline..H._zYELLOW..file..H._zDEFAULT)
            -- ^V^V^V^V
            
            H.FullPathFile = H.gPathToModbuilderMod..file
            if H.WDEBUG then print("***        H.FullPathFile = ["..H.FullPathFile.."]") end

            H.NMSPathFileLessEXML = strsub(H.gPathToModbuilderMod..fileLessEXML,7)
            if H.WDEBUG then print("*** H.NMSPathFileLessEXML = ["..H.NMSPathFileLessEXML.."]") end

            H.IsNotLinkedFile = true
            if H.linkedFiles[H.NMSPathFileLessEXML] then
              print("      "..H.gcWARNING.." [WARNING] This is a linked file, modding linked files is futile!".." "..H._zDEFAULT)

              H.Report("",">>> " .. file)
              H.Report("","This is a linked file, modding linked files is futile!","WARNING")
              H.IsNotLinkedFile = false
            end
            
            if H.IsNotLinkedFile then
              -- MBINCompiler handles:
              --    *.MBIN -> *.MXML -> *.MBIN
              --    *.GEOMETRY.MBIN.PC -> *.GEOMETRY.MXML -> *.GEOMETRY.MBIN.PC
              --    *.GEOMETRY.DATA.MBIN.PC -> *.GEOMETRY.DATA.MXML -> *.GEOMETRY.DATA.MBIN.PC
              
              -- H.printf("              H.IsEXML_CREATE_GLOBAL = [%s]",tostring(H.IsEXML_CREATE_GLOBAL))
              -- H.printf("IsEXMLcreate(H,mMBIN_CT.EXML_CREATE) = [%s]",tostring(IsEXMLcreate(H,mMBIN_CT["EXML_CREATE"])))
              
              --=================== REGEXBEFORE ========================
              --we have to do this BEFORE opening H.FullPathFile

              My.DelayedREGEXBEFOREinfo = {}
              -- My.DelayedReportData = {}
              if mMBIN_CT["REGEXBEFORE"] then
                -- = = = = = =
                if not H.EXMLmodTable[H.NMSPathFileLessEXML] then
                  -- to force a reload of this file
                  H.EXMLorgTable[H.NMSPathFileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true)
                  -- and remember original extension
                  H.EXMLorgExtTable[H.NMSPathFileLessEXML] = H.GetExtensionFromFilePath(H.FullPathFile)
                  H.EXMLmodTable[H.NMSPathFileLessEXML] = H.cloneArray(H.EXMLorgTable[H.NMSPathFileLessEXML])
                end
                H.mkdir(H.GetFolderPathFromFilePath(H.FullPathFile))
                -- H.WriteToFile(H.ConvertLineTableToText(H.EXMLmodTable[H.NMSPathFileLessEXML]), H.FullPathFile)
                H.WriteToFile(H.EXMLmodTable[H.NMSPathFileLessEXML], H.FullPathFile)
                -- = = = = = =

                local regexbefore = mMBIN_CT["REGEXBEFORE"]
                if type(regexbefore) ~= "table" then
                  My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ""
                  My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ">>> "..H.gcERROR.." [ERROR] REGEXBEFORE is not a table, please correct your script "..H._zDEFAULT
                  H.SetReportData(H.DelayedReportData,"","REGEXBEFORE is not a table, please correct your script","ERROR")
                end
                for i=1,#regexbefore do
                  if type(regexbefore[i][1]) == "string" then
                    local ToFindRegex = regexbefore[i][1]:gsub([[\]],[[\\]]):gsub([[\\\\]],[[\\]]) -- \ will be \\, \\ will be \\ -- must keep double \ in find
                    ToFindRegex = ToFindRegex:gsub([["]],[[\"]]) -- must escapes " that is used to defined the sed "s/ToFindRegex/ToReplaceRegex/" command part
                    -- ToFindRegex = ToFindRegex:gsub([[\\/>]],[[\/>]]) -- correcting for />
                    -- ToFindRegex = ToFindRegex:gsub([[\\/]],[[\/]]) -- correcting for / -- Lyravega
                    -- ToFindRegex = ToFindRegex:gsub([[//]],[[\]]) -- correcting for //
                    
                    local ToReplaceRegex = regexbefore[i][2]:gsub([[\]],[[\\]]):gsub([[\\\\]],[[\\]]) -- the \ will be \\, the \\ will be \\ -- must keep double \ in replacement
                    ToReplaceRegex = ToReplaceRegex:gsub([["]],[[\"]]) -- must escapes " that is used to defined the sed "s/ToFindRegex/ToReplaceRegex/" command part
                    ToReplaceRegex = ToReplaceRegex:gsub([[\\(%d)]],[[\%1]]) -- correcting for \digit where n is a number
                    -- ToReplaceRegex = ToReplaceRegex:gsub([[\\/>]],[[\/>]]) -- correcting for />
                    -- ToReplaceRegex = ToReplaceRegex:gsub([[\\/]],[[\/]]) -- correcting for / -- Lyravega
                    -- ToReplaceRegex = ToReplaceRegex:gsub([[//]],[[\]]) -- correcting for //
                    
                    -- we must block the 'e' flag of the's' command has it could execute malicious code
                    -- only allow 'g' flag
                    local RegexFlag = regexbefore[i][3] and regexbefore[i][3]:gsub([[\\]],[[\]]):gsub([["]],[[\"]]):gsub("([^g])",[[]]) or ""
                    
                    -- H.printf("%d            org = [%s]",i,regexbefore[i][1])
                    -- H.printf("%d    ToFindRegex = [%s]\n",i,ToFindRegex)
                    -- H.printf("%d            org = [%s]",i,regexbefore[i][2])
                    -- H.printf("%d ToReplaceRegex = [%s]\n",i,ToReplaceRegex)
                    -- H.printf("%d            org = [%s]",i,regexbefore[i][3])
                    -- H.printf("%d      RegexFlag = [%s]",i,RegexFlag)

                    if ToFindRegex == nil or ToReplaceRegex == nil then
                      My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ""
                      My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ">>> "..H.gcERROR.." [ERROR] missing REGEXBEFORE member, please correct your script "..H._zDEFAULT
                      H.SetReportData(H.DelayedReportData,"","missing REGEXBEFORE member, please correct your script","ERROR")
                    else
                      if ToFindRegex ~= "" then
                        My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ""
                        local flag = "]"
                        if RegexFlag ~= "" then
                          flag = "]: flag = ["..RegexFlag.."]"
                        end
                        -- local displayCommand = [["s/]]..ToFindRegex..[[/]]..ToReplaceRegex..[[/]]..RegexFlag..[["]]
                        local displayCommand = "["..ToFindRegex.."] ==> ["..ToReplaceRegex..flag
                        
                        H.DeleteFile([[sedResults.txt]])
                        local From = "REGEXBEFORE"
                        local sep = string.char(1) -- alternate to standard [[/]]
                        local Command = [[-i -r "s]]..sep..ToFindRegex..sep..ToReplaceRegex..sep..RegexFlag..[[w sedResults.txt" "]]..H.FullPathFile..[["]]
                        
                        -- -- for debug purposes
                        -- -- Command = strsub(Command,4)..[[ > "]]..From..[[_output.txt"]]
                        -- H.printf("%d        Command = [%s]\n",i,Command)
                        
                        ExecuteREGEX(H,From,Command,displayCommand,My.DelayedREGEXBEFOREinfo,H.DelayedReportData)
                        
                        local sedResults = H.ParseTextFileIntoTable([[sedResults.txt]])
                        if #sedResults > 0 then
                          if #sedResults == 1 then
                            My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = "         --> "..#sedResults.." change"
                            H.SetReportData(H.DelayedReportData,"","      --> "..#sedResults.." change")
                          else
                            My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = "         --> "..#sedResults.." changes"
                            H.SetReportData(H.DelayedReportData,"","      --> "..#sedResults.." changes")
                          end
                          H.SetReportData(H.DelayedReportData,"","[[")
                          for j=1,#sedResults do
                            local tmp = H.trim(sedResults[j])
                            if H.gIs_FULL_MODE then
                              My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = "         --> "..tmp
                            end
                            H.SetReportData(H.DelayedReportData,"","         --> "..tmp)
                          end
                          H.SetReportData(H.DelayedReportData,"","]]")
                          NumREGEXBEFORE = NumREGEXBEFORE + 1
                          NumREGEXBEFORElocal = NumREGEXBEFORElocal + 1
                        else
                          My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ">>> "..H.gcWARNING.." [WARNING] REGEXBEFORE failed to perform any change "..H._zDEFAULT
                          H.SetReportData(H.DelayedReportData,"","REGEXBEFORE failed to perform any change","WARNING")
                        end
                        -- My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ""
                        -- H.WFAK("in pause...")                      
                      end
                    end
                  else
                    -- BAD formed regexbefore
                    My.DelayedREGEXBEFOREinfo[#My.DelayedREGEXBEFOREinfo+1] = ">>> "..H.gcERROR.." [ERROR] REGEXBEFORE field ["..i.."] is not a string, please correct your script "..H._zDEFAULT
                    H.SetReportData(H.DelayedReportData,"","REGEXBEFORE field ["..i.."] is not a string, please correct your script","ERROR")
                    break
                  end -- if type(
                end -- for i=1,#regexbefore do
                
                -- to force a reload of this file
                H.EXMLmodTable[H.NMSPathFileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true) -- MAY NOT NEED true
              end
              --=================== end REGEXBEFORE ========================
              
              --=================== XLST ========================
              if mMBIN_CT["XLST"] then
                -- = = = = = =
                if not H.EXMLmodTable[H.NMSPathFileLessEXML] then
                  -- to force a reload of this file
                  H.EXMLorgTable[H.NMSPathFileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true)
                  -- and remember original extension
                  H.EXMLorgExtTable[H.NMSPathFileLessEXML] = H.GetExtensionFromFilePath(H.FullPathFile)
                  H.EXMLmodTable[H.NMSPathFileLessEXML] = H.cloneArray(H.EXMLorgTable[H.NMSPathFileLessEXML])
                end
                H.mkdir(H.GetFolderPathFromFilePath(H.FullPathFile))
                -- H.WriteToFile(H.ConvertLineTableToText(H.EXMLmodTable[H.NMSPathFileLessEXML]), H.FullPathFile)
                H.WriteToFile(H.EXMLmodTable[H.NMSPathFileLessEXML], H.FullPathFile)
                -- = = = = = =

                local xlst = mMBIN_CT["XLST"]
                local tempXslFileName = os.tmpname()
                local tempXslFile = io.open(tempXslFileName, "w")
                tempXslFile:write(xlst)
                io.close(tempXslFile)
                os.execute([[powershell.exe .\transform-xml.ps1 ]]..tempXslFileName..[[ ]]..H.FullPathFile)
                os.remove(tempXslFileName)
                NumXLST = NumXLST + 1
                NumXLSTlocal = NumXLSTlocal + 1

                -- to force a reload of this file
                H.EXMLmodTable[H.NMSPathFileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true) -- MAY NOT NEED true
              end
              --=================== end XLST ========================
              
              if H.WDEBUG then print("        ActiveFile = ["..tostring(ActiveFile).."]") end
              if H.WDEBUG then print("    H.FullPathFile = ["..tostring(H.FullPathFile).."]") end
                
              if ActiveFile and ActiveFile ~= "" and not My.SavingToDiskDone then
                if My.SAVE_EXML then
                  My.endBracket = ""
                  if #TextFileTable == 0 then
                    My.endBracket = "}"
                  end
                  -- H.Report("","    ==> Saved to disk: ["..ActiveFile.."]"..My.endBracket)
                  H.Report("",My.endBracket)
                end
                My.SavingToDiskDone = true
                -- H.DEBUG_SavingToDisk_print(" BEFORE this ExchangePropertyValue(): Done writing to disk")
              end

              if H.WDEBUG then H.WFAK("Just before 'opening/retrieving/already open' ["..H.FullPathFile.."]") end
              
              --#################### THE MXML WILL BE OPENED HERE
              My.startOpening = os.clock()
              My.IsNotAlreadyOpen = false
              if not H.EXMLmodTable[H.NMSPathFileLessEXML] then
                if H.WDEBUG then H.WFAK(" = = = NOT IN EXMLmodTABLE = = =") end
                
                if not H.EXMLorgTable[H.NMSPathFileLessEXML] then
                  if H.WDEBUG then H.WFAK(" = = = NOT IN EXMLorgTable, read from disk = = =") end
                  My.IsNotAlreadyOpen = true
                  if not H.gIs_LEAN_MODE then
                    print("     *** Opening original file from disk")
                    -- print("         Saving to original table in memory")
                  end
                  
                  H.EXMLorgTable[H.NMSPathFileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true)
                  if H.WDEBUG then printf("^v^v^v^v^v Z0: #H.EXMLorgTable[H.NMSPathFileLessEXML] = %d",#H.EXMLorgTable[H.NMSPathFileLessEXML]) end
  -- H.tablePrintSave(H.EXMLorgTable,5)
                  
                  -- and remember original extension
                  H.EXMLorgExtTable[H.NMSPathFileLessEXML] = H.GetExtensionFromFilePath(H.FullPathFile)
                  
                  -- table of strings in H.EXMLmodTable
                  -- if not H.gIs_LEAN_MODE then
                    -- print("         Saved a clone to modded table in memory")
                  -- end
                  H.EXMLmodTable[H.NMSPathFileLessEXML] = H.cloneArray(H.EXMLorgTable[H.NMSPathFileLessEXML]) -- a clone of the original
                  if H.WDEBUG then printf("^v^v^v^v^v Z1: #H.EXMLmodTable[H.NMSPathFileLessEXML] = %d",#H.EXMLmodTable[H.NMSPathFileLessEXML]) end
                  if H.WDEBUG then printf("Loaded from MOD [%s] = ["..H._zYELLOW.."%s"..H._zDEFAULT.."]",H.NMSPathFileLessEXML,string.sub(tostring(H.EXMLorgTable[H.NMSPathFileLessEXML][1]),1,150)) end
                  
                else
                  if not H.gIs_LEAN_MODE then
                    print("     *** Retrieving a clone of the original file") -- to modded table in memory")
                  end
                  -- print(" = = = LOADING from ORG TABLE = = =")
                  -- table of strings in H.EXMLmodTable
                  H.EXMLmodTable[H.NMSPathFileLessEXML] = H.cloneArray(H.EXMLorgTable[H.NMSPathFileLessEXML]) -- a clone of the original
                end

                if not H.gIs_LEAN_MODE then
                  -- print("     *** Using modded copy")
                end
              else
                -- A MODDED EXML FILE
                -- print(" = = = LOADING from MOD TABLE = = =")
                if not H.gIs_LEAN_MODE then
                  print("     *** File already opened, using modded copy")
                end              
              end

              TextFileTable = H.EXMLmodTable[H.NMSPathFileLessEXML] -- a reference
              if H.WDEBUG then printf("^v^v^v^v^v Z2: H.NMSPathFileLessEXML = [%s]",H.NMSPathFileLessEXML) end
              if H.WDEBUG then printf("^v^v^v^v^v Z2: #TextFileTable = %d",#TextFileTable) end
      -- printf("^v^v^v^v^v Z2: #TextFileTable = %d",#TextFileTable)
              H.TextFileTableCheck = TextFileTable
              --#################### END: THE MXML IS NOW OPENED HERE
              
              -- print(" # # # # # TextFileTable")
              -- for i=1,#TextFileTable do
                -- printf("- %s",TextFileTable[i])
              -- end

              if My.IsNotAlreadyOpen and not H.gIs_LEAN_MODE then
                print("             in "..H.dClock(os.clock() - My.startOpening))
                if H.MXMLwithArray_sizeInfo[H.FullPathFile] then
                  print("     === Array Information is available in MapFileTrees files...")
                end
              end

              if H.gDEBUG_CheckTables then H.CheckTables("LISTING: AFTER MAIN opening",true) end
              ActiveFile = H.FullPathFile
              if H.WDEBUG then print("     NEW MXML ActiveFile = ["..tostring(ActiveFile).."]") end
              
              -- not saved yet
              My.SavingToDiskDone = false
              
              -- NEW
              H.newMBINtoCreate = #NEW_FILEPATH_AND_NAME > 0 and NEW_FILEPATH_AND_NAME[u] and NEW_FILEPATH_AND_NAME[u] ~= ""

              if mMBIN_CT["EXML_CHANGE_TABLE"] or H.newMBINtoCreate then
                H.Report("","{>>> " .. file)
              else
                H.Report("",">>> " .. file)
              end
              
              if #TextFileTable == 0 then
                print(H.gcWARNING..[[>>> [WARNING] File is EMPTY ]]..H._zDEFAULT)
                H.Report("",[[File is EMPTY]],"WARNING")
              end

              if #TextFileTable > 0 and (H.IsEXML_CREATE_GLOBAL and IsEXMLcreate(H,mMBIN_CT["EXML_CREATE"])) and H.IsEXMLType(file) and strmatch(file,"%.MXML$") then
                -- local IsCanbeEXML = true
                
                -- H.printf("H.NMSPathFileLessEXML = [%s]",H.NMSPathFileLessEXML)
                
                -- check if file is an ENTITY
                if strmatch(file,"%.ENTITY%.") then
                  local s = table.concat(TextFileTable)
                  if strfind(s,[[ linked="]],1,true) then
                    -- -- an ENTITY with linked= stuff
                    -- H.EntityFilesUsingLinked[H.NMSPathFileLessEXML] = true

                    -- get linked filenames to prevent these from being modded/used for nothing
                    for w in strgmatch(s,[[ linked="(.-)"]]) do              
                      -- H.NMSPathFileLessEXML = strsub(H.gPathToModbuilderMod..fileLessEXML,7)
                      local x = w:upper():gsub([[/]],[[\]]):gsub([[%.MXML$]],[[]])
              
                      -- H.printf("  linked = [%s]",x)
                      H.linkedFiles[x] = true
                    end
                  end
                end
                
                -- for k,v in pairs(H.linkedFiles) do
                  -- H.printf(" => [%s]: [%s]",k,tostring(v))
                -- end
                
-- H.printf("LANGUAGE: file = [%s]",file)
                -- if IsCanbeEXML and H.linkedFiles[H.NMSPathFileLessEXML] == nil then
                if H.linkedFiles[H.NMSPathFileLessEXML] == nil then
                  print("     === EXML version is possible")
                  H.Report("","    === EXML version is possible")
                  H.EXMLcreate[H.NMSPathFileLessEXML] = file
                else
                  print("     === EXML creation is OFF")
                  H.Report("","    === EXML creation is OFF")
                end
              else
                print("     --- EXML creation is OFF")
                H.Report("","    --- EXML creation is OFF")
              end
              
              if H.newMBINtoCreate then
                --result of using alternate syntax #3
                --user asked to create a new file
                NEW_FILEPATH_AND_NAME[u] = H.NormalizePath(NEW_FILEPATH_AND_NAME[u])
                --change MBIN.PC/MBIN to MXML, leave other extensions alone
                NEW_FILEPATH_AND_NAME[u] = strgsub(NEW_FILEPATH_AND_NAME[u],[[%.MBIN%.PC]],[[.MBIN]])
                NEW_FILEPATH_AND_NAME[u] = strgsub(NEW_FILEPATH_AND_NAME[u],[[%.MBIN]],[[.MXML]])
                
                print("    => "..H._zBRIGHTORANGE.."Copying/renaming"..H._zDEFAULT.." to ["..H._zUnderline..H._zYELLOW..NEW_FILEPATH_AND_NAME[u]..H._zDEFAULT.."]")
                H.Report("","=> Copying/renaming to ["..NEW_FILEPATH_AND_NAME[u].."]")
                
                -- remove extension
                NEW_fileLessEXML = strgsub(NEW_FILEPATH_AND_NAME[u],H.GetExtensionFromFilePath(NEW_FILEPATH_AND_NAME[u]).."$","")
                if H.WDEBUG then printf("^v^v^v^v^v NEW_fileLessEXML = [%s]",NEW_fileLessEXML) end
                
                if not H.EXMLmodTable[fileLessEXML] then
                  if H.WDEBUG then printf(" -------------------- SOURCE NOT IN EXMLmodTable: should NOT happen [%s] ---------------------",fileLessEXML) end
                  if not H.EXMLorgTable[fileLessEXML] then
                    if H.WDEBUG then print(" = = = NOT IN EXMLorgTable, read from disk = = =") end
                    if not H.gIs_LEAN_MODE then
                      print("     +++ Opening file ["..H.FullPathFile.."] from original on disk")
                    end

                    if H.IsFileExist(H.FullPathFile) then
                      H.EXMLorgTable[fileLessEXML] = H.ParseTextFileIntoTable(H.FullPathFile,true)
                      
                      -- and remember original extension
                      H.EXMLorgExtTable[fileLessEXML] = H.GetExtensionFromFilePath(H.FullPathFile)
                    else
                      print(H.gcWARNING.."    => This file does not exist anymore, did you already REMOVE it! "..H._zDEFAULT)
                      H.Report("","=> This file does not exist anymore, did you already REMOVE it! ")
                    end
                    
                    -- table of strings in H.EXMLmodTable
                    H.EXMLmodTable[fileLessEXML] = H.cloneArray(H.EXMLorgTable[fileLessEXML]) -- a clone of the original
                  
                  else
                    if not H.gIs_LEAN_MODE then
                      print("     +++ Retrieving file ["..file.."] from clone of original table")
                    end
                    -- print(" = = = LOADING from ORG TABLE = = =")
                    -- table of strings in H.EXMLmodTable
                    H.EXMLmodTable[fileLessEXML] = H.cloneArray(H.EXMLorgTable[fileLessEXML]) -- a clone of the original
                  end
                end
                
                if H.WDEBUG then print(" = = = SOURCE opened from EXMLmodTable = = =") end
                
                -- if H.EXML_NEWorgTable[NEW_fileLessEXML] then
                -- end
                
                if H.WDEBUG then print(" = = = clone modded file to original NEW file = = =") end
                H.EXMLorgTable[NEW_fileLessEXML] = H.cloneArray(H.EXMLmodTable[fileLessEXML])
                -- and remember original extension
                H.EXMLorgExtTable[NEW_fileLessEXML] = H.EXMLorgExtTable[fileLessEXML]
                
                -- script created files ARE NEVER turned into EXML
                -- H.EXMLcreate[NEW_fileLessEXML] = H.EXMLcreate[fileLessEXML]
                
                -- clone the modded source to a modded destination
                if H.WDEBUG then print(" = = = clone modded file to modded NEW file = = =") end
                H.EXMLmodTable[NEW_fileLessEXML] = H.cloneArray(H.EXMLmodTable[fileLessEXML])
                
                -- add to script file list this new file
                if not scriptFileList[NEW_FILEPATH_AND_NAME[u]] then
                  scriptFileList[NEW_FILEPATH_AND_NAME[u]] = {}
                end
                scriptFileList[NEW_FILEPATH_AND_NAME[u]][#scriptFileList[NEW_FILEPATH_AND_NAME[u]]+1] = UserScriptName
                if H.WDEBUG then print(" = = = SOURCE IN EXMLmodTable: DONE = = =") end
                
                if H.gDEBUG_CheckTables then H.CheckTables("LISTING: AFTER Secondary opening",true) end
                
                ReplaceNumber = ReplaceNumber + 1
  -- printf("C0: ReplaceNumber = %d",ReplaceNumber)
                
                if REMOVE_FLAG[u] == "REMOVE" then
                  if H.WDEBUG then print("*** detected REMOVE flag") end
                  RemoveFlagExist = true
  -- printf("C0: RemoveFlagExist = %s",tostring(RemoveFlagExist))
                  
                  H.EXMLcreate[fileLessEXML] = nil
                  -- to forces 'disregard' at the end
                  -- H.EXMLmodTable[fileLessEXML] = {"REMOVE"}
                  -- if H.WDEBUG then printf("*** 'REMOVE' written to H.EXMLmodTable[%s]",fileLessEXML) end
                  -- if H.WDEBUG then printf("*** H.EXMLmodTable[%s] = [%s]",fileLessEXML,H.EXMLmodTable[fileLessEXML]) end
                  
                  -- delete from script list
                  -- scriptFileList[NEW_FILEPATH_AND_NAME[u]] = nil
                  scriptFileList[fileLessEXML] = nil

                  if H.gDEBUG_CheckTables then H.CheckTables("LISTING: AFTER 'REMOVE' flag detected",true) end
                else
                  -- print("*** NO REMOVE")
                end

              end -- if #NEW_FILEPATH_AND_NAME > 0 and NEW_FILEPATH_AND_NAME[u] and NEW_FILEPATH_AND_NAME[u] ~= "" then
              
              -- output delayed print and Report info
              for mREGEXBEFORE=1,#My.DelayedREGEXBEFOREinfo do
                print(My.DelayedREGEXBEFOREinfo[mREGEXBEFORE])
              end

              if #My.DelayedREGEXBEFOREinfo > 0 then
                print("")
              end

              My.DelayedREGEXBEFOREinfo = H.ReportDelayedInfo(My.DelayedREGEXBEFOREinfo,"My.DelayedREGEXBEFOREinfo")
              -- END: output delayed print and Report info
              
              -- so we can restore the current EXML file later on
              My.ActiveFile_bak = ActiveFile -- the full path or the name of the SEC_EDIT
              My.TextFileTable_bak = TextFileTable -- the complete EXML file in table format
              My.FullPathFile_bak = H.FullPathFile -- the full path to the EXML file (in MODBUILDER\MOD)
              if H.WDEBUG then H.WFAK("@@@@@ Internally saved ActiveFile <"..tostring(ActiveFile).."> to _bak") end
              
              -- print("*** #TextFileTable = ["..#TextFileTable.."]")
              
              if #TextFileTable == 0 and mMBIN_CT["EXML_CHANGE_TABLE"] then
                if H.WDEBUG then H.WFAK("EMPTY TextFileTable and MXML_CT exist") end
                -- if not OkToSkipOpeningFile and REMOVE_FLAG[u] ~= "REMOVE" then
                if REMOVE_FLAG[u] ~= "REMOVE" then
                  -- print("*** NO REMOVE")
                  --this file does not exist, problem
                  print(">>> "..H.gcERROR.." [ERROR] file does not exist! See above for source of problem... "..H._zDEFAULT)
                  H.Report("","file does not exist! See above for source...","ERROR")
                  
                  -- remove traces
                  if H.WDEBUG then H.WFAK("EMPTY: Set EXML tables to NIL") end
                  H.EXMLorgTable[fileLessEXML] = nil
                  H.EXMLorgExtTable[fileLessEXML] = nil
                  H.EXMLmodTable[fileLessEXML] = nil
                  H.EXMLcreate[fileLessEXML] = nil
                end
                
              else -- #TextFileTable == 0 and mMBIN_CT["EXML_CHANGE_TABLE"] then            
               -- print("*** going to process...")
                if H.WDEBUG then H.WFAK("Just before MapFileTrees") end
                --=================== Only create MapFileTrees of MXML ORIGINAL... ========================
                if H._bReCreateMapFileTree ~= "X" then
                  local src = [[.\_TEMP\DECOMPILED\]]..file
                  if H.IsFileExist(src) then
                    if H._bCreateMapFileTree then
                      if H._bAllowMapFileTreeCreator == "Y" then
                        if not H.gIs_LEAN_MODE then
                          print("     MapFileTree creation/update on 2nd thread...")
                        end
                        H.Report("","    MapFileTree creation/update done by 2nd thread")
                        
                        local Recreate = ""
                        if H._bReCreateMapFileTree == "Y" then
                          --inform we need to recreate
                          Recreate = ".recreate"
                        end
                        
                        if H.IsFileExist([[MapFileTreeSharedList.txt]]) then
                          H.WriteToFileAppend(file..Recreate.."\n",[[MapFileTreeSharedList.txt]])
                        else
                          H.WriteToFile(file..Recreate.."\n",[[MapFileTreeSharedList.txt]])
                        end
                        
                      else
                        --MAIN thread processing
                        -- OBSOLETE/DEPRICATED
                        DisplayMapFileTreeEXT(H,H.ParseTextFileIntoTable([[.\_TEMP\DECOMPILED\]]..file),file)
                      end
                      
                    else
                      if not H.gIs_LEAN_MODE then
                        print("    Skipping MapFileTree creation/update")
                      end
                      H.Report("","    Skipping MapFileTree creation/update")
                    end
                    
                  else
                    if H.GetExtensionFromFilePath(file) == ".MBIN" then
                      print("    Skipping MapFileTree creation/update, file is missing OR comes from a PAK")
                      H.Report("","    Skipping MapFileTree creation/update, file is missing OR comes from a PAK")
                    end
                  end
                else
                  if not H.gIs_LEAN_MODE then
                    print("    Skipping, USER asked to NEVER create/update MapFileTree files")
                  end
                  H.Report("","    Skipping, USER asked to NEVER create/update MapFileTree files")
                end
                --=================== end create MapFileTrees ========================
                if H.WDEBUG then H.WFAK("Just after MapFileTrees") end
                
                local ADDNumber = 0
                local REMOVENumber = 0
                
                if H.gIs_LEAN_MODE then
                  print("")
                  print("    "..H._zBRIGHTGREEN.."processing using LEAN mode at "..H.dClock()..H._zDEFAULT)
                end
                
-- print("--> H.EXMLcreate:")
-- for k,v in pairs(H.EXMLcreate) do
  -- H.printf("[%s] = [%s]",k,v)
-- end

                if not RequestedExmlDATA and mMBIN_CT["EXML_CHANGE_TABLE"] then
                  if H.WDEBUG then H.WFAK("In 'no RequestedExmlDATA and processing MXML_CT': starting normal processing of MXML_CT") end
                  AtLeastOne_EXML_CHANGE_TABLE = true
                  
                  local IsMissingCurlyBrackets = false
                  if H.ReportInvalidTableContent(mMBIN_CT["EXML_CHANGE_TABLE"],"MXML_CHANGE_TABLE") then
                    if type(mMBIN_CT["EXML_CHANGE_TABLE"][1]) ~= "table" then
                      print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE is missing curly brackets, verify your script ]]..H._zDEFAULT)
                      H.Report("",[[>>> MXML_CHANGE_TABLE is missing curly brackets, verify your script]],"WARNING")
                      IsMissingCurlyBrackets = true
                    end
                  end
                  
                  local EXML_CHANGE_TABLE = mMBIN_CT["EXML_CHANGE_TABLE"]
                  
                  -- print(";;; MXML_CHANGE_TABLE "..n..", "..i_MBIN_CT)
                  -- for key,v in pairs(EXML_CHANGE_TABLE) do
                    -- print(key,type(v))
                  -- end
                  -- print(";;;")
                  
                  if EXML_CHANGE_TABLE then
                    if type(EXML_CHANGE_TABLE) == "string" then
                      print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE entry is a STRING, verify your script ]]..H._zDEFAULT)
                      H.Report("",[[>>> MXML_CHANGE_TABLE entry is a STRING, verify your script]],"WARNING")
                      iEXML_CT_IsString = true
                      break
                    else
                      if type(EXML_CHANGE_TABLE) ~= "table" then
                        -- print("MXML_CHANGE_TABLE = "..type(EXML_CHANGE_TABLE))
                        print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE entry is not a TABLE, verify your script ]]..H._zDEFAULT)
                        H.Report("",[[>>> MXML_CHANGE_TABLE entry is not a TABLE, verify your script]],"WARNING")
                        break
                      else
                        if #EXML_CHANGE_TABLE == 0 then
                          print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE table does not contain any usable TABLE, verify your script ]]..H._zDEFAULT)
                          H.Report("",[[>>> MXML_CHANGE_TABLE table does not contain any usable TABLE, verify your script]],"WARNING")
                          iEXML_CT_IsNoSubTable = true
                        end
                      end
                    end
                  else
                    print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE entry is NIL, verify your script ]]..H._zDEFAULT)
                    H.Report("",[[>>> MXML_CHANGE_TABLE entry is NIL, verify your script]],"WARNING")
                    iEXML_CT_IsNil = true
                  end
                  
                  --***************************************************************************************************
                  -- test iEXML_CT for commands that can change the original EXML
                  My.SAVE_EXML = false
                  
                  if not My.SAVE_EXML and not iEXML_CT_IsString and not iEXML_CT_IsNil and not iEXML_CT_IsNoSubTable and not IsMissingCurlyBrackets and H.IsEXMLtoBeSaved(EXML_CHANGE_TABLE) then
                    My.SAVE_EXML = true
                    -- print("=====================================================================>>> SAVE_EXML says to save")
                  end
                  --***************************************************************************************************

                  local ECT_Index = 0
                  
                  -- to allow to update content of the EXML_CT table while the script is running (thru the use of a VCT.FUNCTION)
                  local i_EXML_CT = 1
                  while i_EXML_CT <= #EXML_CHANGE_TABLE do
                  -- for i=1,#EXML_CHANGE_TABLE do
                    -- print("In MXML_CHANGE_TABLE for loop #"..i)
                    My.startTimeThisModification = os.clock()
                    -- printf("startTimeThisModification = %f",My.startTimeThisModification)
                    
                    My.IsSecEditNumber = false
                    My.IsSecEditNotFound = false
                    My.IsSecEmptyNumber = false
                    
                    local iEXML_CT = EXML_CHANGE_TABLE[i_EXML_CT]
                    
                    -- ###########################
                    -- WARNING: Check if H.IsEXMLtoBeSaved(MXML_CT) contains the aliases
                    -- ###########################
                    
                    --allow alias names
                    if iEXML_CT["ITF"] then
                      iEXML_CT["INTEGER_TO_FLOAT"] = iEXML_CT["ITF"]
                      iEXML_CT["ITF"] = nil
                    end
                    if iEXML_CT["SKW"] then
                      iEXML_CT["SPECIAL_KEY_WORDS"] = iEXML_CT["SKW"]
                      iEXML_CT["SKW"] = nil
                    end
                    if iEXML_CT["FSKWG"] then
                      iEXML_CT["FOREACH_SKW_GROUP"] = iEXML_CT["FSKWG"]
                      iEXML_CT["FSKWG"] = nil
                    else
                      if iEXML_CT["SPECIAL_KEY_WORDS"] and type(iEXML_CT["SPECIAL_KEY_WORDS"][1]) == "table" then
                        iEXML_CT["FOREACH_SKW_GROUP"] = iEXML_CT["SPECIAL_KEY_WORDS"]
                        iEXML_CT["SPECIAL_KEY_WORDS"] = nil
                        print(">>> [INFO]"..H._zBRIGHTGREEN.." Upgrading: "..H._zBRIGHTORANGE.." SKW to FSKWG "..H._zDEFAULT)
                        H.Report("","Upgraded SKW to FSKWG")
                      end
                    end
                    if iEXML_CT["MATH_OP"] then
                      iEXML_CT["MATH_OPERATION"] = iEXML_CT["MATH_OP"]
                      iEXML_CT["MATH_OP"] = nil
                    end
                    if iEXML_CT["PKW"] then
                      iEXML_CT["PRECEDING_KEY_WORDS"] = iEXML_CT["PKW"]
                      iEXML_CT["PKW"] = nil
                    end
                    if iEXML_CT["PKW_1"] then
                      iEXML_CT["PRECEDING_FIRST"] = iEXML_CT["PKW_1"]
                      iEXML_CT["PKW_1"] = nil
                    end
                    if iEXML_CT["AFTER_KEY_WORDS"] then
                      iEXML_CT["AKW"] = iEXML_CT["AFTER_KEY_WORDS"]
                      iEXML_CT["AFTER_KEY_WORDS"] = nil
                    end
                    if iEXML_CT["VCT"] then
                      iEXML_CT["VALUE_CHANGE_TABLE"] = iEXML_CT["VCT"]
                      iEXML_CT["VCT"] = nil
                    end
                    if iEXML_CT["WIS"] then
                      iEXML_CT["WHERE_IN_SECTION"] = iEXML_CT["WIS"]
                      iEXML_CT["WIS"] = nil
                    end
                    if iEXML_CT["WISS"] then
                      iEXML_CT["WHERE_IN_SUBSECTION"] = iEXML_CT["WISS"]
                      iEXML_CT["WISS"] = nil
                    end
                    if iEXML_CT["CO"] then
                      iEXML_CT["CUSTOM_ORDER"] = iEXML_CT["CO"]
                      iEXML_CT["CO"] = nil
                    end
                    if iEXML_CT["SEC_COPY"] then
                      iEXML_CT["SEC_SAVE_TO"] = iEXML_CT["SEC_COPY"]
                      iEXML_CT["SEC_COPY"] = nil
                    end
                    if iEXML_CT["SEC_PASTE"] then
                      iEXML_CT["SEC_ADD_NAMED"] = iEXML_CT["SEC_PASTE"]
                      iEXML_CT["SEC_PASTE"] = nil
                    end
                    --END: allow alias names
                    
                    --these were renamed
                    if iEXML_CT["ADD_NAMED_SECTION"] then
                      iEXML_CT["SEC_ADD_NAMED"] = iEXML_CT["ADD_NAMED_SECTION"]
                      iEXML_CT["ADD_NAMED_SECTION"] = nil
                      ObsoleteNames(H, "ADD_NAMED_SECTION","SEC_ADD_NAMED")
                    end
                    if iEXML_CT["SECTION_ADD_NAMED"] then
                      iEXML_CT["SEC_ADD_NAMED"] = iEXML_CT["SECTION_ADD_NAMED"]
                      iEXML_CT["SECTION_ADD_NAMED"] = nil
                      ObsoleteNames(H, "SECTION_ADD_NAMED","SEC_ADD_NAMED")
                    end
                    if iEXML_CT["EDIT_SECTION"] then
                      iEXML_CT["SEC_EDIT"] = iEXML_CT["EDIT_SECTION"]
                      iEXML_CT["EDIT_SECTION"] = nil
                      ObsoleteNames(H, "EDIT_SECTION","SEC_EDIT")
                    end
                    if iEXML_CT["SECTION_EDIT"] then
                      iEXML_CT["SEC_EDIT"] = iEXML_CT["SECTION_EDIT"]
                      iEXML_CT["SECTION_EDIT"] = nil
                      ObsoleteNames(H, "SECTION_EDIT","SEC_EDIT")
                    end
                    if iEXML_CT["KEEP_SECTION"] then
                      iEXML_CT["SEC_KEEP"] = iEXML_CT["KEEP_SECTION"]
                      iEXML_CT["KEEP_SECTION"] = nil
                      ObsoleteNames(H, "KEEP_SECTION","SEC_KEEP")
                    end
                    if iEXML_CT["SECTION_KEEP"] then
                      iEXML_CT["SEC_KEEP"] = iEXML_CT["SECTION_KEEP"]
                      iEXML_CT["SECTION_KEEP"] = nil
                      ObsoleteNames(H, "SECTION_KEEP","SEC_KEEP")
                    end
                    if iEXML_CT["SAVE_SECTION_TO"] then
                      iEXML_CT["SEC_SAVE_TO"] = iEXML_CT["SAVE_SECTION_TO"]
                      iEXML_CT["SAVE_SECTION_TO"] = nil
                      ObsoleteNames(H, "SAVE_SECTION_TO","SEC_SAVE_TO")
                    end
                    if iEXML_CT["SECTION_SAVE_TO"] then
                      iEXML_CT["SEC_SAVE_TO"] = iEXML_CT["SECTION_SAVE_TO"]
                      iEXML_CT["SECTION_SAVE_TO"] = nil
                      ObsoleteNames(H, "SECTION_SAVE_TO","SEC_SAVE_TO")
                    end
                    if iEXML_CT["WI_SEC_LOP"] then
                      iEXML_CT["WISEC_LOP"] = iEXML_CT["WI_SEC_LOP"]
                      iEXML_CT["WI_SEC_LOP"] = nil
                      ObsoleteNames(H, "WI_SEC_LOP","WISEC_LOP")
                    end
                    if iEXML_CT["WISUB_SEC_LOP"] then
                      iEXML_CT["WISUBSEC_LOP"] = iEXML_CT["WISUB_SEC_LOP"]
                      iEXML_CT["WISUB_SEC_LOP"] = nil
                      ObsoleteNames(H, "WISUB_SEC_LOP","WISUBSEC_LOP")
                    end
                    if iEXML_CT["WISUB_SEC_OPTION"] then
                      iEXML_CT["WISUBSEC_OPTION"] = iEXML_CT["WISUB_SEC_OPTION"]
                      iEXML_CT["WISUB_SEC_OPTION"] = nil
                      ObsoleteNames(H, "WISUB_SEC_OPTION","WISUBSEC_OPTION")
                    end
                    --END: these were renamed
                    
                    IsEXML_CT_TableOfTables = true
                    if iEXML_CT == nil then
                      print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE entry is NIL, verify your script ]]..H._zDEFAULT)
                      H.Report("",[[>>> MXML_CHANGE_TABLE entry is NIL, verify your script]],"WARNING")
                      iEXML_CT_IsNil = true
                      break
                    else
                    
                      -- print(";;; MXML_CHANGE_TABLE "..n..", "..i_MBIN_CT..", "..i)
                      -- for key,v in pairs(iEXML_CT) do
                        -- print(key,type(v))
                      -- end
                      -- print(";;;")
                      
                      -- print("iEXML_CT = "..type(iEXML_CT))
                      if type(iEXML_CT) ~= "table" then
                        print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE entry is not a correct TABLE of TABLES, verify your script ]]..H._zDEFAULT)
                        H.Report("",[[>>> MXML_CHANGE_TABLE entry is not a correct TABLE of TABLES, verify your script]],"WARNING")
                        IsEXML_CT_TableOfTables = false
                      -- else
                        -- H.pv(" ==> type(iEXML_CT) = "..type(iEXML_CT))
                        -- H.pv(" ==> #iEXML_CT = "..#iEXML_CT)
                      end
                    end
  -- table.concat(TextFileTable)                  
                    
                    -- *****************   SEC_EMPTY section   ********************
                    My.sec_empty = H.ReturnStringFrom(iEXML_CT["SEC_EMPTY"])
                    My.IsSecEmpty = (My.sec_empty ~= "")
                    
                    if My.IsSecEmpty and tonumber(My.sec_empty) then
                      -- problem sec_empty is a number, delayed reporting
                      My.IsSecEmptyNumber = true
                      My.sec_empty = ""
                      My.IsSecEmpty = false
                      My.IsEmptyFromDisk = false
                    end
                    
                    if My.IsSecEmpty then
                      H.DEBUG_SEC_print("")
                      H.DEBUG_SEC_print(" ______ SEE BELOW My.IsSecEmpty ______")
                      H.DEBUG_SEC_print("")
                      
                      My.tmpFileText = "<EMPTY>\n"
                      H.gSection[My.sec_empty] = "<EMPTY>\n"
                      
                      My.sec_emptySavedPath = [[..\TOOLS\SavedSections\]]..My.sec_empty..[[.xml]]
                      if My.IsEmptyFromDisk then
                        -- try to read back the lines from a file in the TOOLS\SavedSections folder using the sec_empty name.xml
                        if H.IsFileExist(My.sec_emptySavedPath) then
                          H.WriteToFile("",H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..My.sec_empty..[[.xml]])
                          H.DEBUG_SEC_print([[@@@@@ sec_empty_A: Found sec_empty in a file in the TOOLS\SavedSections folder using the sec_empty name.xml, length = ]]..#My.tmpFileText)
                        else
                          --check if this section name already exist in internal H.gSection list
                          if H.gSection[My.sec_empty] and H.gSection[My.sec_empty] ~= "???" then
                            --already in H.gSection, nothing more to do right now, we will use it
                            H.DEBUG_SEC_print("@@@@@ sec_empty_B: Found sec_empty in internal H.gSection list, length = "..#My.tmpFileText)
                          else
                            --no such named section exist internally or externally: CREATE it
                            H.DEBUG_SEC_print("@@@@@ sec_empty_C: CREATING empty section")
                            --create an entry with that name and with empty content
                          end
                        end
                        
                      else
                        --check if this section name already exist in internal H.gSection list
                        if H.gSection[My.sec_empty] and H.gSection[My.sec_empty] ~= "???" then
                          --already in H.gSection, nothing more to do right now, we will use it
                          H.DEBUG_SEC_print("@@@@@ sec_empty_D: Found sec_empty in internal H.gSection list, length = "..#My.tmpFileText)
                        else
                          --try to read back the lines from a file in the TOOLS\SavedSections folder using the sec_empty name.xml
                          if H.IsFileExist(My.sec_emptySavedPath) then
                            H.WriteToFile("",H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..My.sec_empty..[[.xml]])
                            -- H.printf("<<< sec_empty loaded from disk %s.xml >>>",My.sec_empty)
                            H.DEBUG_SEC_print([[@@@@@ sec_empty_E: Found sec_empty in a file in the TOOLS\SavedSections folder using the sec_empty name.xml, length = ]]..#My.tmpFileText)
                          else
                            --no such named section exist internally or externally: CREATE it
                            H.DEBUG_SEC_print("@@@@@ sec_empty_F: DID NOT find specified sec_empty: BAD NAME?")
                            --create an entry with that name and with empty content
                         end
                        end
                      end
                      
                      H.FullPathFile = My.sec_empty -- add ..[[.xml]] ?
                      ActiveFile = My.sec_empty -- add ..[[.xml]] ?
                      
                      -- load it as if an MXML
                      TextFileTable = My.tmpFileText:splitB("\n")
  if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"Empty TextFileTable:") end
                      
                      H.DEBUG_SEC_print("@@@@@ sec_empty_2: ActiveFile = ["..tostring(ActiveFile).."]")
                      H.DEBUG_SEC_print("@@@@@ sec_empty_2: #TextFileTable = ["..#TextFileTable.."]")
                      H.DEBUG_SEC_print("@@@@@ sec_empty_2: TextFileTable[1] = ["..TextFileTable[1].."]")
                    end                  
                    -- *****************  END: SEC_EMPTY section   ********************

                    -- *****************   SEC_EDIT section   ********************
                    My.IsEditFromDisk = (type(iEXML_CT["SEC_EDIT"]) == "table")
                    My.sec_edit = H.ReturnStringFrom(iEXML_CT["SEC_EDIT"])
                    My.IsEditSection = (My.sec_edit ~= "")
                    
                    if My.IsEditSection and tonumber(My.sec_edit) then
                      -- problem SEC_EDIT is a number, delayed reporting
                      My.IsSecEditNumber = true
                      My.sec_edit = ""
                      My.IsEditSection = false
                      My.IsEditFromDisk = false
                    end
                    
                    My.foundEditSection = false
                    
                    if My.IsEditSection then
                      H.DEBUG_SEC_print("")
                      H.DEBUG_SEC_print(" ______ SEE BELOW My.IsEditSection ______")
                      H.DEBUG_SEC_print("")
                      
                      My.tmpFileText = ""
                      
                      My.sec_editSavedPath = [[..\TOOLS\SavedSections\]]..My.sec_edit..[[.xml]]
                      if My.IsEditFromDisk then
                        --try to read back the lines from a file in the TOOLS\SavedSections folder using the SEC_edit name.xml
                        if H.IsFileExist(My.sec_editSavedPath) then
                          H.gSection[My.sec_edit] = H.LoadFileData(My.sec_editSavedPath)
                          My.foundEditSection = true
                          My.tmpFileText = H.gSection[My.sec_edit]
                          H.DEBUG_SEC_print([[@@@@@ SEC_edit_A: Found SEC_edit in a file in the TOOLS\SavedSections folder using the SEC_EDIT name.xml, length = ]]..#My.tmpFileText)
                        else
                          --check if this section name already exist in internal H.gSection list
                          if H.gSection[My.sec_edit] and H.gSection[My.sec_edit] ~= "???" then
                            --already in H.gSection, nothing more to do right now, we will use it
                            My.foundEditSection = true
                            My.tmpFileText = H.gSection[My.sec_edit]
                            H.DEBUG_SEC_print("@@@@@ SEC_edit_B: Found SEC_edit in internal H.gSection list, length = "..#My.tmpFileText)
                          else
                            --no such named section exist internally or externally: WARNING
                            -- -- delayed reporting
                            -- My.IsSecEditNotFound = true
                            H.DEBUG_SEC_print("@@@@@ SEC_edit_C: DID NOT find specified SEC_EDIT: BAD NAME?")
                            --create an entry with that name and with empty content
                            H.gSection[My.sec_edit] = "???"
                          end
                        end
                        
                      else
                        --check if this section name already exist in internal H.gSection list
                        if H.gSection[My.sec_edit] and H.gSection[My.sec_edit] ~= "???" then
                          --already in H.gSection, nothing more to do right now, we will use it
                          My.foundEditSection = true
                          My.tmpFileText = H.gSection[My.sec_edit]
                          H.DEBUG_SEC_print("@@@@@ SEC_edit_D: Found SEC_edit in internal H.gSection list, length = "..#My.tmpFileText)
                        else
                          --try to read back the lines from a file in the TOOLS\SavedSections folder using the SEC_edit name.xml
                          if H.IsFileExist(My.sec_editSavedPath) then
                            H.gSection[My.sec_edit] = H.LoadFileData(My.sec_editSavedPath)
                            -- H.printf("<<< SEC_EDIT loaded from disk %s.xml >>>",My.sec_edit)
                            My.foundEditSection = true
                            My.tmpFileText = H.gSection[My.sec_edit]
                            H.DEBUG_SEC_print([[@@@@@ SEC_edit_E: Found SEC_edit in a file in the TOOLS\SavedSections folder using the SEC_EDIT name.xml, length = ]]..#My.tmpFileText)
                          else
                            --no such named section exist internally or externally: WARNING
                            -- -- delayed reporting
                            -- My.IsSecEditNotFound = true
                            H.DEBUG_SEC_print("@@@@@ SEC_edit_F: DID NOT find specified SEC_EDIT: BAD NAME?")
                            --create an entry with that name and with empty content
                            H.gSection[My.sec_edit] = "???"
                         end
                        end
                      end
                      
                      if My.foundEditSection then
                        H.FullPathFile = My.sec_edit -- add ..[[.xml]] ?
                        ActiveFile = My.sec_edit -- add ..[[.xml]] ?
                        
                        -- load it as if a regular MXML
                        TextFileTable = My.tmpFileText:gsub("\n%s*\n",H.modCHANGED.."\n"):splitB("\n")
                        
                        H.DEBUG_SEC_print("@@@@@ SEC_edit_2: ActiveFile = ["..tostring(ActiveFile).."]")
                        H.DEBUG_SEC_print("@@@@@ SEC_edit_2: #TextFileTable = ["..#TextFileTable.."]")
                        H.DEBUG_SEC_print("@@@@@ SEC_edit_2: TextFileTable[1] = ["..TextFileTable[1].."]")
                      else
                        --even if it was requested, we are not able to find/edit this named section
                        H.DEBUG_SEC_print("@@@@@ NO SEC_EDIT POSSIBLE: named section not found")
                        My.IsEditSection = false
                        -- ActiveFile = nil
                        -- TextFileTable = {}
                        
                        -- NOTICE to user by delayed reporting
                        My.IsSecEditNotFound = true
                        
                        -- and fall thru to doing the requested actions on the full MXML
                        -- restore the current EXML file
                        ActiveFile = My.ActiveFile_bak
                        if H.WDEBUG then print("     RESTORED ActiveFile from bak = ["..tostring(ActiveFile).."]") end
                        
                        TextFileTable = My.TextFileTable_bak
                        
                        H.FullPathFile = My.FullPathFile_bak
                        H.DEBUG_SEC_print("@@@@@ NO SEC_EDIT: Internally restored to <"..tostring(ActiveFile).."> from ActiveFile_bak")
                        
                      end
                      H.DEBUG_SEC_print("@@@@@ SEC_EDIT: ActiveFile is now <"..tostring(ActiveFile)..">")
                    else
                      -- NOT in SEC_EDIT mode
                      -- restore the current MXML file
                      ActiveFile = My.ActiveFile_bak

                      TextFileTable = My.TextFileTable_bak

                      H.FullPathFile = My.FullPathFile_bak
                      H.DEBUG_SEC_print("@@@@@ NO SEC_EDIT: Internally restored to <"..tostring(ActiveFile).."> from ActiveFile_bak")
                      
                    end
                    -- *****************  END: SEC_EDIT section   ********************
                    if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"SEC_EDIT TextFileTable:") end

                    GUARD = "Wbertro"
                    if iEXML_CT["FOREACH_SKW_GROUP"] then
                      -- -- *****************   foreach_SKWG section   ********************
                      local foreach_SKWG = iEXML_CT["FOREACH_SKW_GROUP"]
                      
                      local foreach_SKWGBadTable = false
                      
                      if type(foreach_SKWG) ~= "table" then
                        foreach_SKWGBadTable = true
                      else --a table
                        if #foreach_SKWG == 0 then
                          --foreach_SKWG should be at least ONE table
                          foreach_SKWGBadTable = true
                        else --some tables
                          for i=1,#foreach_SKWG do
                            if type(foreach_SKWG[i]) ~= "table" then
                              foreach_SKWGBadTable = true
                              break
                            end
                          end
                        end
                      end
                      
                      if foreach_SKWGBadTable then
                        print("")
                        print(">>> "..H.gcWARNING..[[ [WARNING] FOREACH_SKW_GROUP is NOT a correct table with sub-tables ]]..H._zDEFAULT)
                        H.Report("",[[>>> FOREACH_SKW_GROUP is NOT a correct table with sub-tables]],"WARNING")
                      end
                      
                      -- if IsSpecialKeyWords and IsForeach_SKW then
                        -- print("")
                        -- print(gcNOTICE..[[>>> [NOTICE] FOREACH_SKW_GROUP and SPECIAL_KEY_WORDS are found, only SPECIAL_KEY_WORDS will be used" ]]..H._zDEFAULT)
                        -- H.Report("",[[>>> FOREACH_SKW_GROUP and SPECIAL_KEY_WORDS are found, only SPECIAL_KEY_WORDS will be used]],"NOTICE")
                        -- IsForeach_SKW = false
                        -- -- foreach_SKW_words = {}
                      -- end
                      
                      if not foreach_SKWGBadTable then
                        --folding foreach_SKW into spec_key_words
                        H.pv("#foreach_SKWG = "..#foreach_SKWG)
                        for i=1,#foreach_SKWG do
                          ECT_Index = i
                          H.DEBUG_VCTproperty_print("     ===>> before ExchangePropertyValue(): #TextFileTable = "..#TextFileTable)
                          local moddedFileTable,ReplNumber,ADDcount,REMOVEcount,IsFUNCexist = ExchangePropertyValue(
                                H,
                                n,
                                i_MBIN_CT,
                                u,
                                ECT_Index,
                                H.FullPathFile,
                                TextFileTable,
                                My.TextFileTable_bak,
                                iEXML_CT["VALUE_CHANGE_TABLE"],
                                iEXML_CT["VCT_COMMENT"],
                                foreach_SKWG[i],
                                iEXML_CT["PRECEDING_KEY_WORDS"],
                                iEXML_CT["PRECEDING_FIRST"],
                                iEXML_CT["AKW"],
                                iEXML_CT["COMPRESS_PAK"],
                                -- iEXML_CT["CREATE_EXML"],
                                iEXML_CT["CREATE_HOS"],
                                iEXML_CT["CREATE_HOES"],
                                -- iEXML_CT["EXT_FUNC"],
                                -- mMBIN_CT["EXML_CREATE"],
                                iEXML_CT["EXML_FLAGS"],
                                iEXML_CT["EXML_ID"],
                                iEXML_CT["EXML_INDEX"],
                                iEXML_CT["FIND_ALL_SECTIONS"],
                                iEXML_CT["SECTION_UP"],
                                iEXML_CT["SECTION_UP_SPECIAL"],
                                iEXML_CT["SECTION_UP_PRECEDING"],
                                iEXML_CT["CUSTOM_ORDER"],
                                iEXML_CT["SECTION_ACTIVE"],
                                iEXML_CT["WHERE_IN_SECTION"],
                                iEXML_CT["WISEC_LOP"],
                                iEXML_CT["WHERE_IN_SUBSECTION"],
                                iEXML_CT["WISUBSEC_LOP"],
                                iEXML_CT["WISUBSEC_OPTION"],
                                iEXML_CT["SEC_SAVE_TO"],
                                iEXML_CT["SEC_UNSAVED"],
                                iEXML_CT["SEC_KEEP"],
                                iEXML_CT["SEC_ADD_NAMED"],
                                iEXML_CT["SECADD_COMMENT"],
                                My.sec_edit,
                                My.IsEditSection,
                                iEXML_CT["MATH_OPERATION"],
                                iEXML_CT["INTEGER_TO_FLOAT"],
                                global_integer_to_float,
                                iEXML_CT["VALUE_MATCH"],
                                iEXML_CT["REPLACE_TYPE"],
                                iEXML_CT["VALUE_MATCH_TYPE"],
                                iEXML_CT["VALUE_MATCH_OPTIONS"],
                                iEXML_CT["NOTICE_OFF"],
                                iEXML_CT["LINE_OFFSET"],
                                iEXML_CT["AUTO_GNH"],
                                iEXML_CT["ADD_OPTION"],
                                iEXML_CT["ADD"],
                                iEXML_CT["REMOVE"],
                                iEXML_CT["COMMENT"],
                                IsEXML_CT_TableOfTables,
                                IsMissingCurlyBrackets,
                                My.IsSecEditNumber,
                                My.IsSecEditNotFound,
                                My.sec_empty,
                                My.IsSecEmpty,
                                My.IsSecEmptyNumber,
                                true,
                                iEXML_CT["SUB_LEVEL"],
                                iEXML_CT["MAIN_SECTION"],
                                conf,
                                GUARD
                              )
                          -- H.DEBUG_VCTproperty_print("     ===>>A) after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable)
                          if H.WDEBUG then print("     ===>> after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable) end
                          
                          My.IsFUNCexist = My.IsFUNCexist or IsFUNCexist
                          
                          TextFileTable = moddedFileTable --update TextFileTable for next iteration
                          
  if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"P1 TextFileTable:") end
                          -- if file was discarded
                          if #TextFileTable == 0 then
                            if H.WDEBUG then print("^v^v^v^v^v  A: #TextFileTable = %d",#TextFileTable) end
                            if H.WDEBUG then print("@@@@@ ActiveFile set to <nil>") end
                            ActiveFile = nil
                          elseif not My.IsEditSection and H.TextFileTableCheck ~= TextFileTable then
                            -- a new table was created
                            -- we need to refresh the reference
                            H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                            H.TextFileTableCheck = TextFileTable
                            if H.WDEBUG then print("@@@@@ refreshed reference") end
                            if H.WDEBUG then printf("      refreshed reference to H.EXMLmodTable[%s] with TextFileTable",H.NMSPathFileLessEXML) end
                            if H.WDEBUG then printf("@@@@@ refreshed reference") end
                            
                            -- do I need to
                            My.TextFileTable_bak = TextFileTable
                          end
                          -- H.DEBUG_VCTproperty_print("     ===>>B) after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable)
                          
                          ReplaceNumber = ReplaceNumber + ReplNumber
                          ADDNumber = ADDNumber + ADDcount
                          REMOVENumber = REMOVENumber + REMOVEcount
                        end --for i=1,#foreach_SKWG[1] do
                      end --if IsForeach_SKW then
                      
                    else --iEXML_CT["FOREACH_SPECIAL_KEY_WORDS_GROUP"] == nil
                      ECT_Index = i_EXML_CT -- i
                      H.DEBUG_VCTproperty_print("     ===>> before ExchangePropertyValue(): #TextFileTable = "..#TextFileTable)
                      local moddedFileTable,ReplNumber,ADDcount,REMOVEcount,IsFUNCexist = ExchangePropertyValue(
                            H,
                            n,
                            i_MBIN_CT,
                            u,
                            ECT_Index,
                            H.FullPathFile,
                            TextFileTable,
                            My.TextFileTable_bak,
                            iEXML_CT["VALUE_CHANGE_TABLE"],
                            iEXML_CT["VCT_COMMENT"],
                            iEXML_CT["SPECIAL_KEY_WORDS"],
                            iEXML_CT["PRECEDING_KEY_WORDS"],
                            iEXML_CT["PRECEDING_FIRST"],
                            iEXML_CT["AKW"],
                            iEXML_CT["COMPRESS_PAK"],
                            -- iEXML_CT["CREATE_EXML"],
                            iEXML_CT["CREATE_HOS"],
                            iEXML_CT["CREATE_HOES"],
                            -- iEXML_CT["EXT_FUNC"],
                            -- mMBIN_CT["EXML_CREATE"],
                            iEXML_CT["EXML_FLAGS"],
                            iEXML_CT["EXML_ID"],
                            iEXML_CT["EXML_INDEX"],
                            iEXML_CT["FIND_ALL_SECTIONS"],
                            iEXML_CT["SECTION_UP"],
                            iEXML_CT["SECTION_UP_SPECIAL"],
                            iEXML_CT["SECTION_UP_PRECEDING"],
                            iEXML_CT["CUSTOM_ORDER"],
                            iEXML_CT["SECTION_ACTIVE"],
                            iEXML_CT["WHERE_IN_SECTION"],
                            iEXML_CT["WISEC_LOP"],
                            iEXML_CT["WHERE_IN_SUBSECTION"],
                            iEXML_CT["WISUBSEC_LOP"],
                            iEXML_CT["WISUBSEC_OPTION"],
                            iEXML_CT["SEC_SAVE_TO"],
                            iEXML_CT["SEC_UNSAVED"],
                            iEXML_CT["SEC_KEEP"],
                            iEXML_CT["SEC_ADD_NAMED"],
                            iEXML_CT["SECADD_COMMENT"],
                            My.sec_edit,
                            My.IsEditSection,
                            iEXML_CT["MATH_OPERATION"],
                            iEXML_CT["INTEGER_TO_FLOAT"],
                            global_integer_to_float,
                            iEXML_CT["VALUE_MATCH"],
                            iEXML_CT["REPLACE_TYPE"],
                            iEXML_CT["VALUE_MATCH_TYPE"],
                            iEXML_CT["VALUE_MATCH_OPTIONS"],
                            iEXML_CT["NOTICE_OFF"],
                            iEXML_CT["LINE_OFFSET"],
                            iEXML_CT["AUTO_GNH"],
                            iEXML_CT["ADD_OPTION"],
                            iEXML_CT["ADD"],
                            iEXML_CT["REMOVE"],
                            iEXML_CT["COMMENT"],
                            IsEXML_CT_TableOfTables,
                            IsMissingCurlyBrackets,
                            My.IsSecEditNumber,
                            My.IsSecEditNotFound,
                            My.sec_empty,
                            My.IsSecEmpty,
                            My.IsSecEmptyNumber,
                            false,
                            iEXML_CT["SUB_LEVEL"],
                            iEXML_CT["MAIN_SECTION"],
                            conf,
                            GUARD
                          )
                      -- H.DEBUG_VCTproperty_print("     ===>>A) after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable)
                      if H.WDEBUG then print("     ===>> after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable) end
                      
                      My.IsFUNCexist = My.IsFUNCexist or IsFUNCexist

                      TextFileTable = moddedFileTable --update TextFileTable for next iteration
             
  if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"P2 TextFileTable:") end
                      if not My.IsEditSection then
                        assert(H.TextFileTableCheck == TextFileTable, " = = = = = = = = = = = = = = = = = = = = = = = = = WARNING: A: H.TextFileTableCheck ~= TextFileTable")
                      end

                      -- if file was discarded
                      if #TextFileTable == 0 then
  if H.WDEBUG then printf("^v^v^v^v^v  B: #TextFileTable = %d",#TextFileTable) end
                        H.DEBUG_SEC_print("@@@@@ ActiveFile set to <nil>")
                        ActiveFile = nil
                      elseif not My.IsEditSection and H.TextFileTableCheck ~= TextFileTable then
                        -- a new table was created
                        -- we need to refresh the reference
                        H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                        H.TextFileTableCheck = TextFileTable
                        
                        -- do I need to
                        My.TextFileTable_bak = TextFileTable
                      end
                      -- H.DEBUG_VCTproperty_print("     ===>>B) after ExchangePropertyValue(): #moddedFileTable = "..#moddedFileTable)
                      
                      ReplaceNumber = ReplaceNumber + ReplNumber
                      ADDNumber = ADDNumber + ADDcount
                      REMOVENumber = REMOVENumber + REMOVEcount
                    end --if iEXML_CT["FOREACH_SPECIAL_KEY_WORDS_GROUP"] then
                    
                    if TextFileTable[1] and H.trim(TextFileTable[1]):sub(1,5) == [[<?xml]] then
                      -- this is the EXML file
                      -- so we can restore the current EXML file later on
                      My.ActiveFile_bak = ActiveFile
                      My.TextFileTable_bak = TextFileTable
                      My.FullPathFile_bak = H.FullPathFile
                      H.DEBUG_SEC_print("@@@@@ Internally saved ActiveFile <"..tostring(ActiveFile).."> to _bak")
                    end
                    i_EXML_CT = i_EXML_CT + 1

                    -- printf("startTimeThisModification = %f",My.startTimeThisModification)
                    if not H.gIs_LEAN_MODE then
                      print(H._zBRIGHTGREEN.."                >>> processed in "..H.dClock(os.clock() - My.startTimeThisModification)..H._zDEFAULT)
                    end
                  end --while i_EXML_CT <= #EXML_CHANGE_TABLE do -- for i=1,#EXML_CHANGE_TABLE do
                  
                  if iEXML_CT_IsNil or iEXML_CT_IsString then
                    if H.WDEBUG then print("BREAK out of 'for u=1,#mbin_file_source do'") end
                    break -- out of:  for u=1,#mbin_file_source do
                  end
                  
                  -- if H.THIS == "In TestReCreatedScript: " then CheckReCreatedEXMLAgainstOrg(H,file) end
                -- else
                  -- NoEXML_CHANGE_TABLE = true
                  -- -- print("[INFO] [\"MODIFICATIONS\"] has no [\"MXML_CHANGE_TABLE\"]")
                  -- -- H.Report("","[\"MODIFICATIONS\"] has no [\"MXML_CHANGE_TABLE\"]")
                
                end -- if mMBIN_CT["EXML_CHANGE_TABLE"] then

  -- printf("E: H.newMBINtoCreate = %s",tostring(H.newMBINtoCreate))
  -- printf("E: ReplaceNumber = %d",ReplaceNumber)
                H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT,nil)
                -- print("")
                print(H._zBRIGHTORANGE.."   = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ="..H._zDEFAULT)
                -- print(H._zBRIGHTGREEN.."                Ended processing of MODIFICATIONS["..n.."]["..i_MBIN_CT.."]["..u.."]["..ECT_Index.."]"..H._zDEFAULT)

                -- printf("startTimeThisMBIN = %f",My.startTimeThisMBIN)
                
                print(H._zBRIGHTGREEN.."                Ended total processing of this file in "..H.dClock(os.clock() - My.startTimeThisMBIN)..H._zDEFAULT)
                
                -- H.DEBUG_StopAtEachProcessing_print("Elasped processing time = "..H.dClock(os.clock() - My.startTimeThisModification))
                
                if ADDNumber > 0 then
                  H.Report(ADDNumber.." ADD(s) made","  Ended processing with")
                  print("    >>>>> "..ADDNumber.." ADD(s) made")
                end
                
                if REMOVENumber > 0 then
                  H.Report(REMOVENumber.." REMOVE(s) made","  Ended processing with")
                  print("    >>>>> "..REMOVENumber.." REMOVE(s) made")
                end
                
                if ReplaceNumber > 0 then
                  H.Report(ReplaceNumber.." CHANGE(s) made","  Ended processing with")
                  print("    >>>>> "..ReplaceNumber.." CHANGE(s) made")
                end
                
                if NumREGEXBEFORElocal > 0 then
                  H.Report(NumREGEXBEFORElocal.." REGEXBEFORE action(s)","  Ended processing with")
                  print("    >>>>> "..NumREGEXBEFORElocal.." REGEXBEFORE action(s)")
                end
                
                if NumREGEXAFTERlocal > 0 then
                  H.Report(NumREGEXAFTERlocal .. " REGEXAFTER action(s)","  Ended processing with")
                  print("    >>>>> "..NumREGEXAFTERlocal.." REGEXAFTER action(s)")
                end
                
                if NumXLSTlocal > 0 then
                  H.Report(NumXLSTlocal.." XLST action(s)","  Ended processing with")
                  print("    >>>>> "..NumXLSTlocal.." XLST action(s)")
                end

                local numRepl = ReplaceNumber + ADDNumber + REMOVENumber + NumREGEXBEFORElocal + NumREGEXAFTERlocal + NumXLSTlocal
                print("    >>>>> Ended with a total of "..numRepl.." action(s) made")
                H.Report(file,"     on File:")
                
                if mMBIN_CT["EXML_CHANGE_TABLE"] or H.newMBINtoCreate then
                  H.Report("","  Ended with a total of "..numRepl.." action(s) made }")
                else
                  H.Report("","  Ended with a total of "..numRepl.." action(s) made")
                end
                NumReplacements = NumReplacements + numRepl
                
                -- print("   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
              end -- if #TextFileTable == 0 and mMBIN_CT["EXML_CHANGE_TABLE"] then
              
              --=================== REGEXAFTER ========================
              if mMBIN_CT["REGEXAFTER"] then
                local regexafter = mMBIN_CT["REGEXAFTER"]
                if type(regexafter) ~= "table" then
                  print("")
                  print(">>> "..H.gcERROR.." [ERROR] REGEXAFTER is not a table, please correct your script "..H._zDEFAULT)
                  H.Report("","REGEXAFTER is not a table, please correct your script","ERROR")
                else
                  -- we must save the current changes to H.FullPathFile
                  -- BECAUSE REGEX needs the file on disk

                  -- = = = = = =
                  -- H.WriteToFile(H.ConvertLineTableToText(TextFileTable), H.FullPathFile)
                  H.WriteToFile(TextFileTable, H.FullPathFile)
                  -- = = = = = =
                  
                  for i=1,#regexafter do
                    if type(regexafter[i][1]) == "string" then
                      
                      local ToFindRegex = regexafter[i][1]:gsub([[\]],[[\\]]):gsub([[\\\\]],[[\\]]) -- \ will be \\, \\ will be \\ -- must keep double \ in find
                      ToFindRegex = ToFindRegex:gsub([["]],[[\"]]) -- must escapes " that is used to defined the sed "s/ToFindRegex/ToReplaceRegex/" command part
                      -- ToFindRegex = ToFindRegex:gsub([[\\/>]],[[\/>]]) -- correcting for />
                      -- ToFindRegex = ToFindRegex:gsub([[\\/]],[[\/]]) -- correcting for / -- Lyravega
                      -- ToFindRegex = ToFindRegex:gsub([[//]],[[\]]) -- correcting for //

                      local ToReplaceRegex = regexafter[i][2]:gsub([[\]],[[\\]]):gsub([[\\\\]],[[\\]]) -- \ will be \\, \\ will be \\ -- must keep double \ in replacement
                      ToReplaceRegex = ToReplaceRegex:gsub([["]],[[\"]]) -- must escapes " that is used to defined the sed "s/ToFindRegex/ToReplaceRegex/" command part
                      ToReplaceRegex = ToReplaceRegex:gsub([[\\(%d)]],[[\%1]]) -- correcting for \digit where n is a number
                      -- ToReplaceRegex = ToReplaceRegex:gsub([[\\/>]],[[\/>]]) -- correcting for />
                      -- ToReplaceRegex = ToReplaceRegex:gsub([[\\/]],[[\/]]) -- correcting for / -- Lyravega
                      -- ToReplaceRegex = ToReplaceRegex:gsub([[//]],[[\]]) -- correcting for //

                      -- we must block the 'e' flag of the's' command has it could execute malicious code
                      -- only allow 'g' flag
                      local RegexFlag = regexafter[i][3] and regexafter[i][3]:gsub([[\\]],[[\]]):gsub([["]],[[\"]]):gsub("([^g])",[[]]) or ""
                      
                      -- H.printf("            org = [%s]",regexafter[i][1])
                      -- H.printf("    ToFindRegex = [%s]\n",ToFindRegex)
                      -- H.printf("            org = [%s]",regexafter[i][2])
                      -- H.printf(" ToReplaceRegex = [%s]\n",ToReplaceRegex)
                      -- H.printf("            org = [%s]",regexafter[i][3])
                      -- H.printf("      RegexFlag = [%s]",RegexFlag)

                      if ToFindRegex == nil or ToReplaceRegex == nil then
                        print("")
                        print(">>> "..H.gcERROR.." [ERROR] missing REGEXAFTER member, please correct your script "..H._zDEFAULT)
                        H.Report("","missing REGEXAFTER member, please correct your script","ERROR")
                      else
                        if ToFindRegex ~= "" then
                          print("")
                          local flag = "]"
                          if RegexFlag ~= "" then
                            flag = "]: flag = ["..RegexFlag.."]"
                          end
                          -- local displayCommand = [["s/]]..ToFindRegex..[[/]]..ToReplaceRegex..[[/]]..RegexFlag..[["]]
                          local displayCommand = "["..ToFindRegex.."] ==> ["..ToReplaceRegex..flag
                          
                          H.DeleteFile([[sedResults.txt]])
                          local From = "REGEXAFTER"
                          local sep = string.char(1) -- alternate to standard [[/]]
                          local Command = [[-i -r "s]]..sep..ToFindRegex..sep..ToReplaceRegex..sep..RegexFlag..[[w sedResults.txt" "]]..H.FullPathFile..[["]]

                          -- -- for debug purposes
                          -- -- Command = strsub(Command,4)..[[ > "]]..From..[[_output.txt"]]
                          -- H.printf("        Command = [%s]\n",Command)
                          
                          ExecuteREGEX(H,From,Command,displayCommand)

                          local sedResults = H.ParseTextFileIntoTable([[sedResults.txt]])
                          if #sedResults > 0 then
                            if #sedResults == 1 then
                              H.printf("       --> %d change",#sedResults)
                              H.Report("","      --> "..#sedResults.." change")
                            else
                              H.printf("       --> %d changes",#sedResults)
                              H.Report("","      --> "..#sedResults.." changes")
                            end
                            H.Report("","[[")
                            for j=1,#sedResults do
                              local tmp = H.trim(sedResults[j])
                              if H.gIs_FULL_MODE then
                                H.printf("         --> %s",tmp)
                              end
                              H.Report("","       --> "..tmp)
                            end
                            H.Report("","]]")
                            NumREGEXAFTER = NumREGEXAFTER + 1
                            NumREGEXAFTERlocal = NumREGEXAFTERlocal + 1
                          else
                            print(">>> "..H.gcWARNING.." [WARNING] REGEXAFTER failed to perform any change "..H._zDEFAULT)
                            H.Report("","REGEXAFTER failed to perform any change","WARNING")
                          end
                          -- print("")
                          -- H.WFAK("in pause...")
                        end
                      end
                    else
                      -- BAD formed regexafter
                      print(">>> "..H.gcERROR.." [ERROR] REGEXAFTER field ["..i.."] is not a string, please correct your script "..H._zDEFAULT)
                      H.Report("","REGEXAFTER field ["..i.."] is not a string, please correct your script","ERROR")
                      break -- out of: for i=1,#regexafter do
                    end -- if type(
                  end -- for i=1,#regexafter do
                  
                  --and re-open H.FullPathFile
                  TextFileTable = H.ParseTextFileIntoTable(H.FullPathFile,true) --the EXML file in MODBUILDER\MOD
                  -- refresh the modded table because TextFileTable is a new table
                  H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                  H.TextFileTableCheck = TextFileTable
                end
              end
              --=================== end REGEXAFTER ========================
              
  if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"M TextFileTable:") end
              if not My.IsEditSection then
                assert(H.TextFileTableCheck == TextFileTable, " = = = = = = = = = = = = = = = = = = = = = = = = = WARNING: H.TextFileTableCheck ~= TextFileTable")
              end
            end -- if H.IsNotLinkedFile then
          end --for u=1,#mbin_file_source do
          
if H.WDEBUG then printf("^v^v^v^v^v  C: #TextFileTable = %d",#TextFileTable) end
          -- print(" * * * * * *")
          -- print("                                === H.EXMLmodTable ===")
          -- for k,v in pairs(H.EXMLmodTable) do
            -- H.printf("                                  - %s",k)
          -- end
          -- print(" * * * * * *                                ================")
          
          -- WBERTRO: EXTERNAL FUNCTION CALL: using MBIN_CT.EXML_DATA

          -- WBERTRO: For DEBUG
          if H.IsExFunc and H.gDEBUG_EXT_FUNC then
            print("")
            print("                                >>> BEFORE H.IsExFunc ===")
            if H.EXMLorgTable then
              printf("                                =>> H.EXMLorgTable[%d index] ===",#H.EXMLorgTable)
              for k,v in pairs(H.EXMLorgTable) do
                H.printf("                                  - [%s] = [%s] (%d lines)",k,strsub(tostring(v[1]),1,100),#v)
              end
              print("                                ================")
            end
            
            if H.EXMLmodTable then
              printf("                                =>> H.EXMLmodTable[%d index] ===",#H.EXMLmodTable)
              for k,v in pairs(H.EXMLmodTable) do
                H.printf("                                  - [%s] = [%s] (%d lines)",k,strsub(tostring(v[1]),1,100),#v)
              end
              print("                                ================")
            end
            
            if H.returnedTables and next(H.returnedTables) ~= nil then
              printf("                                =>> From PREVIOUS ReturnedTable[%d index] ===",#H.returnedTables)
              for k,v in pairs(H.returnedTables) do
                H.printf("                                ==> H.returnedTables[%s]",k)
                if type(v) == "table" then
                  for i=1,#v do
                    H.printf("                                  - [%s]",strsub(tostring(v[1]),1,100))
                  end
                else -- string, number or boolean
                  H.printf("                                   - [%s]",strsub(tostring(v),1,100))
                end
              end
              print("                                ================")
            end
          end
          -- END: For DEBUG
          
          -- WBERTRO: EXTERNAL FUNCTION CALL: using MBIN_CT.EXT_FUNC
          if H.IsExFunc then
            if H.gDEBUG_EXT_FUNC then print("") end
            if H.gDEBUG_EXT_FUNC then printf("^v^v^v GOING IN EXT_FUNC = <%s>",type(My.ext_func)) end

            --***************************************************************************************************
            local function MyErrHandler(x)
              -- H.printf("In MyErrHandler: x = [%s]",tostring(x))
              -- copy raw script for user (* required to indicate a file)
              H.CopyFile("UserLoadedScript.lua",[[..\TOOLS\ModScriptCheck\]]..strgsub(H.GetFilenameFromFilePath(_bScriptName),"%.lua",""):gsub("%.LUA","")..[[.RawScript.lua*]])
              
              -- print("   x = "..tostring(x))
              local line = tostring(tonumber(strmatch(x,":(%d+):")) + H.seleneExtraLines)
              -- print("line = "..tostring(line))
              local g = strgsub(x,"^(.-:).-(:.-)$","%1"..line.."%2")
              -- print("   g = "..tostring(g))

              print(H.gcERROR.." Lua Script error: "..g.." "..H._zDEFAULT)
              
              local tmp = g
              -- local tmp = strsub(x,strfind(x,":")+1)
              -- print(H.gcERROR.." Lua Script error: "..tmp.." "..H._zDEFAULT)
              print("                       "..H.gcNOTICE..[[ line number above ^ refers to TOOLS\ModScriptCheck\]]..strgsub(_bScriptName,"%.lua",""):gsub("%.LUA","")..[[.RawScript.lua ]]..H._zDEFAULT)
              
              H.SetReportData(H.DelayedReportData,"","Lua Script error: "..tmp,"ERR")
              H.LuaEndedOk(H.THIS)
            end
            --***************************************************************************************************
            
--  = = = = = = = = = = = = = = = =
            -- *****************   My.ext_func section   ********************
            if type(My.ext_func) == "table" then
              for k=1,#My.ext_func do
                if type(My.ext_func[k]) == "string" then
                  if H.gDEBUG_EXT_FUNC then printf("@@@ Processing My.ext_func[%d] = [%s]",k,My.ext_func[k]) end

                  My.ExFuncName = "return conf."..My.ext_func[k]..[[(...)]]
                  if H.gDEBUG_EXT_FUNC then printf("My.ExFuncName = <%s>",My.ExFuncName) end
                  
                  ExFunc = load(My.ExFuncName,"My.ext_func","t")
                  
                  if type(ExFunc) == "function" then
                    My.ExFuncArg = {}
                    -- create function arguments                        
                    My.ExFuncArg["MBIN_CT"]          = nMOD["MBIN_CHANGE_TABLE"] -- a reference to MBIN_CT table
                    My.ExFuncArg["MBIN_CT_Index"]    = i_MBIN_CT -- the current index into MBIN_CT table
                    My.ExFuncArg["ModdedMXMLs"]      = H.EXMLmodTable
                    My.ExFuncArg["ModdedEXMLs"]      = H.EXMLmodTable -- alias for now
                    My.ExFuncArg["ReturnedValues"]   = H.returnedTables
                    
                    -- transform gSection strings into tables
                    local sections = {}
                    for k,v in pairs(H.gSection) do
                      sections[k] = H.rtrim(v:gsub("\n%s*\n",H.modCHANGED.."\n")):splitB("\n")
                    end
                    My.ExFuncArg["Sections"]         = sections -- H.gSection
                    
                    My.ExFuncArg["SavedValues"]      = H.gSavedValues
                    
                    -- For DEBUG
                    if H.gDEBUG_EXT_FUNC then
                      print("   ===>>> My.ExFuncArg:")
                      for k,v in pairs(My.ExFuncArg) do
                        printf("   ===>>> k = <%s>, v = <%s> %s",k,type(v),v)
                      end
                    end
                    
                    -- ADD log.lua and REPORT.lua info
                    print("")
                    print(" -> Using "..H._zBRIGHTORANGE.."TheDATA"..H._zDEFAULT.." supplied by "..H._zBRIGHTORANGE.."EXT_FUNC"..H._zDEFAULT.." to call script function "..H._zBRIGHTORANGE..My.ext_func[k].."()"..H._zDEFAULT)
                    print("")
                    H.Report("","    >>> Using 'TheDATA' supplied by EXT_FUNC to call script function '"..My.ext_func[k].."()'")
                    
                    -- printf("==================>>> ExFuncName = [%s]",My.ExFuncName)
                    -- print("=== CALLING function ===")
-- xpcall EXT_FUNC HERE
                    My.status,My.funcResult = xpcall(ExFunc, MyErrHandler, My.ExFuncArg)
                    -- My.status,My.funcResult = pcall(ExFunc, My.ExFuncArg)
                    -- if not My.status then                    
                      -- H.printf("My.funcResult = [%s]",tostring(My.funcResult))
                    -- end
                    -- print("=== END: CALLING function ===")

                    if My.status then
                      if H.gDEBUG_EXT_FUNC then printf("      ======>>> My.funcResult = [%s]",tostring(My.funcResult)) end
                      
                      if type(My.funcResult) == "table" then
                        if next(My.funcResult) then
                          if H.gDEBUG_EXT_FUNC then print("      ======>>> Processing returned values:") end
                          if H.gDEBUG_EXT_FUNC then H.DprintTable(My.funcResult,10) end

                          H.IsReservedWords = false
                          for k,v in pairs(My.funcResult) do
                            if H.gDEBUG_EXT_FUNC then printf("      ======>>> type(v) = [%s]",type(v)) end
                            if type(v) == "table" and k == "AMUMSS_Dictionary" then
                              if H.gDEBUG_EXT_FUNC then print("      ======>>> <AMUMSS_Dictionary> detected") end
                              H.returnedTables["AMUMSS_Dictionary"] = v
                              H.IsReservedWords = true
                            elseif type(v) == "boolean" and k == "AMUMSS_Language" then
                              if H.gDEBUG_EXT_FUNC then print("      ======>>> <AMUMSS_Language> detected") end
                              H.IsReservedWords = true
                            end
                            
                            local IsEXML = false
                            
                            if type(v) == "table" then
                              local s,r = pcall(table.concat, v)
                              if s then
                                IsEXML = true
                              else
                                print(">>> "..H.gcWARNING..[[ [WARNING] The returned 'result table' of your script function is wrong, please correct! ]]..H._zDEFAULT)
                                H.Report("",[[>>> The returned 'result table' of your script function is wrong, please correct!]],"WARNING")
                              end
                            elseif (type(v) == "string" and strfind(v,"<Data template=")) then
                              IsEXML = true
                            end
                            
                            if IsEXML then
                              if H.gDEBUG_EXT_FUNC then print("*** EXML ***") end

                              if strfind(k,".MBIN$") or strfind(k,".MXML$") or strfind(k,".MBIN.PC$") then
                                H.kNormalized = H.NormalizePath(k,true)
                              else
                                H.kNormalized = k
                              end
                  if H.gDEBUG_EXT_FUNC then H.printf("[%s] normalized = [%s]",k,H.kNormalized) end

                              if type(v) == "string" then
                                -- the EXML is a string
                                if H.gDEBUG_EXT_FUNC then printf("      ======>>> k = <%s>, v = <%s>",tostring(k),tostring(strsub(v,1,350))) end
                                
                                if H.ltrim(v):sub(1,5) == [[<?xml]] then
                                  -- an EXML: auto-indentation ON
                                elseif H.ltrim(v):sub(1,15) == [[<Data template=]] then
                                  -- a pseudo EXML: auto-indentation ON, add EXML header
                                  v = [[<?xml version="1.0" encoding="utf-8"?>]]..v
                                end
                                
                                -- @lMonk code returns "/>, the missing space makes it more difficult to compare
                                v = strgsub(v,[["/>]],[[" />]])

                                FileDataTable = H.stringToTable(v)
                  if H.gDEBUG_EXT_FUNC then H.DprintTable(FileDataTable,10) end
                  -- H.WriteToFile(table.concat(FileDataTable),[[FileDataTableBEFORE.lua]])
                                FileDataTable = H.AutoAdjustIndentation(FileDataTable,FileDataTable,1)
                  if H.gDEBUG_EXT_FUNC then H.DprintTable(FileDataTable,10) end
                  -- H.WriteToFile(table.concat(FileDataTable),[[FileDataTableAFTER.lua]])
                                
                                if H.EXMLmodTable[H.kNormalized] then
                                  -- update it
                                  if H.gDEBUG_EXT_FUNC then print("*** H.EXMLmodTable UPDATED ***") end
                                  H.EXMLmodTable[H.kNormalized] = FileDataTable
                                  NumReplacements = NumReplacements + 1
                                elseif not H.IsReservedWords then
                                  print(">>> "..H._zBRIGHTORANGE.." Could not find ["..k.."] in the internal EXML MODDED table.  Creating new file! "..H._zDEFAULT)
                                  H.Report("","Could not find ["..k.."] in the internal EXML MODDED table Created new file!","")

                                  -- print(">>> "..H.gcWARNING.." [WARNING] Could not find ["..k.."] in the internal EXML MODDED table, check your script! "..H._zDEFAULT)
                                  -- H.Report("","Could not find ["..k.."] in the internal EXML MODDED table, check your script!","WARNING")
                                end
                                -- v = table.concat(FileDataTable,"\n")
                                -- H.WriteToFile(v,[[.\MOD\]]..k)
                              
                              else -- if type(v) == "table" then
                                -- the EXML is a table
                                if H.gDEBUG_EXT_FUNC then print("*** EXML ALREADY A TABLE ***") end

                                if H.EXMLmodTable[H.kNormalized] then
                                  -- update it
                                  if H.gDEBUG_EXT_FUNC then print("*** H.EXMLmodTable UPDATED ***") end
                                  H.EXMLmodTable[H.kNormalized] = v
                                  NumReplacements = NumReplacements + 1
                                elseif not H.IsReservedWords then
                                  print(">>> "..H._zBRIGHTORANGE.." Could not find ["..k.."] in the internal EXML MODDED table.  Creating new file! "..H._zDEFAULT)
                                  H.Report("","Could not find ["..k.."] in the internal EXML MODDED table Created new file!","")

                                  -- print(">>> "..H.gcWARNING.." [WARNING] Could not find ["..k.."] in the internal EXML MODDED table, check your script! "..H._zDEFAULT)
                                  -- H.Report("","Could not find ["..k.."] in the internal EXML MODDED table, check your script!","WARNING")
                                end
                              end
                              
                            else -- not an EXML
                              if H.gDEBUG_EXT_FUNC then print("*** NOT AN EXML, must be a returned 'associated' name ***") end
                              if H.gDEBUG_EXT_FUNC then H.printf("type(v) = %s",type(v)) end
                              if type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "table" then
                                if H.gDEBUG_EXT_FUNC then H.printf("k = [%s], v = [%s]",k,tostring(v)) end
                                H.returnedTables[k] = v
                              -- elseif type(v) == "table" then
                                -- H.returnedTables[k] = v
                              else
                                -- not an approved type
                                if H.gDEBUG_EXT_FUNC then print("*** NOT AN APPROUVED TYPE ***") end
                              end
                            end -- if IsEXML then
                          end -- for k,v in pairs(My.funcResult) do
                      
                          -- process RESERVED keywords
                          if H.IsReservedWords then
                            if H.gDEBUG_EXT_FUNC then print("      ======>>> processing H.IsReservedWords") end
                            
                            local newDict = H.returnedTables["AMUMSS_Dictionary"]
                            if type(newDict) == "table" then
                              if H.gDEBUG_EXT_FUNC then print("      ======>>> processing <AMUMSS_Dictionary>") end
                              local dictFilenamePath = [[ModScript\ModHelperScripts\Dictionary.lua]]
                              H.tablePrintSave(newDict, [[..\]]..dictFilenamePath,"DICTIONARY")
                              NumReplacements = NumReplacements + 1
                              -- reset
                              H.returnedTables["AMUMSS_Dictionary"] = nil
                              print(" "..H.gcNOTICE.." * * * * Done CREATING/UPDATING "..dictFilenamePath.." "..H._zDEFAULT)
                              H.Report("")
                              H.Report(""," * * * * Done CREATING/UPDATING "..dictFilenamePath,"")
                            end
                            
                            local Language = H.returnedTables["AMUMSS_Language"]
                            if type(Language) == "boolean" and Language then
                              if H.gDEBUG_EXT_FUNC then print("      ======>>> processing <AMUMSS_Language>") end
                              -- FORCE save of H.EXMLmodTable 'LANGUAGE' tables to _TEMP\DECOMPILED\LANGUAGE
                              for k,v in pairs(H.EXMLmodTable) do
                                if strsub(k,1,9) == [[LANGUAGE\]] then
                                  local exml = table.concat(v,"\n")
                                  H.WriteToFile(exml,[[.\_TEMP\DECOMPILED\]]..k..[[.MXML]])
                                  -- NumReplacements = NumReplacements + 1
                                  -- reset this EXMLmodTable to the original so that it is discarded later on and no pak is created
                                  H.EXMLmodTable[k] = H.cloneArray(H.EXMLorgTable[k])
                                  -- reset
                                  H.returnedTables["AMUMSS_Language"] = nil
                                end
                              end
                              print(" "..H.gcNOTICE.." * * * * Done CREATING SMALLER LANGUAGE files "..H._zDEFAULT)
                              H.Report("")
                              H.Report(""," * * * * Done CREATING SMALLER LANGUAGE files","")
                            end

                            -- reset
                            H.IsReservedWords = false                            
                          end

                          if H.gDEBUG_EXT_FUNC then print("================>>> END: Processing returned values:") end
                      
                        else
                          print(">>> "..H.gcWARNING..[[ [WARNING] The returned result of your script function is NIL, please correct! ]]..H._zDEFAULT)
                          H.Report("",[[>>> The returned result of your script function is NIL, please correct!]],"WARNING")
                        end -- if next(My.funcResult) then
                        
                      elseif type(My.funcResult) == "string" or type(My.funcResult) == "number" or type(My.funcResult) == "boolean" then
                        My.funcResult = tostring(My.funcResult)
                        if My.funcResult ~= "IGNORE" then
                          print(">>> "..H.gcWARNING..[[ [WARNING] The returned result (]]..My.funcResult..[[) of your script function is not a table, please correct! ]]..H._zDEFAULT)
                          H.Report("",[[>>> The returned result (]]..My.funcResult..[[) of your script function is not a table, please correct!]],"WARNING")
                        end
                        
                      elseif My.funcResult == nil then
                        print(">>> "..H.gcNOTICE..[[ [NOTICE] Your script function returned NOTHING! ]]..H._zDEFAULT)
                        H.Report("",[[>>> Your script function returned NOTHING!]],"NOTICE")
                        
                      else
                        print(">>> "..H.gcWARNING..[[ [WARNING] Your script function returned an UNHANDLED value type, please correct! ]]..H._zDEFAULT)
                        H.Report("",[[>>> Your script function returned  an UNHANDLED value type, please correct!]],"WARNING")
                      end -- if type(My.funcResult) == "table" then
                      
                    else -- here error handled by MyErrHandler()
                      print(">>> "..H.gcWARNING.." [WARNING] "..My.ext_func[k].."() returned an error message, check your script! "..H._zDEFAULT)
                      H.Report("",My.ext_func[k].."() returned an error message, check your script!","WARNING")
                      -- print(">>> "..H.gcWARNING.." [WARNING] "..My.ext_func[k][1].."() returned this error message: <"..My.funcResult..">, check your script! "..H._zDEFAULT)
                      -- H.Report("",My.ext_func[k][1].."() returned this error message: <"..My.funcResult..">, check your script!","WARNING")
                    end -- if My.status then
                  else
                    print(">>> "..H.gcWARNING..[=[ [WARNING] In your script, the name of 'DATA[]=]..k..[=[]' is not a valid function name, please correct! ]=]..H._zDEFAULT)
                    H.Report("",[=[>>> In your script, the name of 'DATA[]=]..k..[=[]' is not a valid function name, please correct!]=],"WARNING")
                  end -- if type(ExFunc) == "function" then
                    
                else
                  printf(">>> "..H.gcWARNING..[=[ [WARNING] In your script, 'EXT_FUNC[]=]..k..[=[]' is not a string, please correct! ]=]..H._zDEFAULT)
                  H.Report("",[=[>>> In your script, 'EXT_FUNC[]=]..k..[=[]' is not a string, please correct!]=],"WARNING")
                end -- if type(My.ext_func[k]) == "string" then
              end -- for k=1,#My.ext_func do
              
            else
              print(">>> "..H.gcWARNING..[[ [WARNING] In your script, 'EXT_FUNC' is not a table, please correct! ]]..H._zDEFAULT)
              H.Report("",[[>>> In your script, 'EXT_FUNC' is not a table, please correct!]],"WARNING")
            end -- if type(My.ext_func) == "table" then
          end -- if My.ext_func then
          -- END: My.ext_func
          --***************************************************************************************************

          -- WBERTRO: For DEBUG
          if H.IsExFunc and H.gDEBUG_EXT_FUNC then
            print("")
            print("                                >>> AFTER H.IsExFunc ===")
            if H.EXMLorgTable then
              printf("                                =>> H.EXMLorgTable[%d index] ===",#H.EXMLorgTable)
              for k,v in pairs(H.EXMLorgTable) do
                H.printf("                                  - [%s] = [%s] (%d lines)",k,strsub(tostring(v[1]),1,100),#v)
              end
              print("                                ================")
            end
            
            if H.EXMLmodTable then
              printf("                                =>> H.EXMLmodTable[%d index] ===",#H.EXMLmodTable)
              for k,v in pairs(H.EXMLmodTable) do
                H.printf("                                  - [%s] = [%s] (%d lines)",k,strsub(tostring(v[1]),1,100),#v)
              end
              print("                                ================")
            end
            
            if H.returnedTables and next(H.returnedTables) ~= nil then
              printf("                                =>> From UPDATED returnedTables[%d index] ===",#H.returnedTables)
              for k,v in pairs(H.returnedTables) do
                H.printf("                                ==> H.returnedTables[%s]",k)
                if type(v) == "table" then
                  for i=1,#v do
                    H.printf("                                  - [%s]",strsub(tostring(v[1]),1,100))
                  end
                else -- string, number or boolean
                  H.printf("                                   - [%s]",strsub(tostring(v),1,100))
                end
              end
              print("                                ================")
            end
          end
          -- END: For DEBUG
--  = = = = = = = = = = = = = = = =

          print("")
          if MbinFsDiscard(H,mMBIN_CT["MBIN_FS_DISCARD"]) then
          -- if mMBIN_CT["MBIN_FS_DISCARD"] == "TRUE" then
            if H.WDEBUG then H.WFAK("<<< MBIN_FS_DISCARD >>> TRUE") end
            for u=1,#mbin_file_source do
              local file = strgsub(mbin_file_source[u],[[%.MBIN%.PC]],[[.MBIN]])
              file = strgsub(file,[[%.MBIN]],[[.MXML]])
              file = H.NormalizePath(file)
              -- print("["..[[.\MOD\]]..file.."]")

              -- remove extension
              local fileLessEXML = strgsub(file,H.GetExtensionFromFilePath(file).."$","")
              
              -- DO NOT USE, may block discarding a genuine modder created file
              -- if table.concat(H.EXMLorgTable[fileLessEXML]) == table.concat(H.EXMLmodTable[fileLessEXML]) then
                -- -- safe to discard
                
                if H.WDEBUG then H.WFAK("<<< MBIN_FS_DISCARD >>> ["..[[.\MOD\]]..file.."]") end
              
                H.DeleteFile([[.\MOD\]]..file)
    -- print(" * * * * * *")
    -- print("                                === BEFORE H.EXMLmodTable == NIL ===")
    -- local count = 0
    -- for k,v in pairs(H.EXMLmodTable) do
      -- count = count + 1
      -- H.printf("                                  -%d: %s (%s)",count,k,v[1])
    -- end
    -- print(" * * * * * *                                ================")
    
                -- remove from original/modded list
                if H.WDEBUG then H.WFAK("MBIN_FS_DISCARD: Set EXML tables to NIL") end

                H.EXMLorgTable[fileLessEXML] = nil
                H.EXMLorgExtTable[fileLessEXML] = nil
                H.EXMLmodTable[fileLessEXML] = nil
                H.EXMLcreate[fileLessEXML] = nil
                
    -- print(" * * * * * *")
    -- print("                                === AFTER H.EXMLmodTable == NIL ===")
    -- local count = 0
    -- for k,v in pairs(H.EXMLmodTable) do
      -- count = count + 1
      -- H.printf("                                  -%d: %s (%s)",count,k,v[1])
    -- end
    -- print(" * * * * * *                                ================")
    
  -- H.WFAKD([[Waiting: .\MOD\]]..file)
                -- remove from script list
                scriptFileList[fileLessEXML] = nil
                
                --remove original empty folder(s), if any
                local FolderPath = lfs.currentdir()..[[\MOD\]]..H.GetFolderPathFromFilePath(file)
                -- print("*** FolderPath = ["..FolderPath.."]")
                repeat
                  --to remove all empty folders in the path
                  local cmd = [[rd /q "]]..FolderPath..[[" 1>NUL 2>NUL]]
                  H.NewThread(cmd)
                  FolderPath = H.GetFolderPathFromFilePath(FolderPath)
                  -- print("["..FolderPath.."]")
                until FolderPath == ""
                -- print("*** after deleting empty folders")
                
                ActiveFile = nil
                if H.WDEBUG then H.WFAK("@@@@@ ActiveFile set to <nil> due to MBIN_FS_DISCARD == TRUE") end
                print(H._zBRIGHTGREEN..">>> "..H._zBRIGHTORANGE.."Discarded:"..H._zBRIGHTGREEN.." ["..file.."]"..H._zDEFAULT)
                H.Report("",">>> Discarded: ["..file.."]")
              -- end
            end
            
          else
            if H.WDEBUG then H.WFAK("B: <<< DONE WITH MBIN_FS LOOP >>>, #TextFileTable = "..#TextFileTable.."") end
-- printf("D: ReplaceNumber = %d",ReplaceNumber)
            
-- printf("D: RemoveFlagExist = %s",tostring(RemoveFlagExist))
            if #TextFileTable ~= 0 then
              -- H.printf("=================================================>>> AFTER: My.ActiveFile_bak = %s",tostring(My.ActiveFile_bak))
              -- if not My.foundEditSection and My.SAVE_EXML then
                  -- print("=====================================================================>>> BOTH say to save !!!!!!!!!!!!!!!!!!!")
              -- else
                -- if not My.foundEditSection then
                  -- print("=====================================================================>>> NOT foundEditSection says to save")
                -- end
                -- if My.SAVE_EXML then
                  -- print("=====================================================================>>> SAVE_EXML says to save")
                -- end
              -- end
              
              -- if not My.foundEditSection then
              if My.SAVE_EXML then
                if mMBIN_CT["EXML_CHANGE_TABLE"] then
                  -- saving only if MXML_CT exist
                  -- on last mbin_file_source
                  -- if H.WDEBUG then H.WFAK("B: Just before saving changes to ["..file.."]") end
                  
                  if TextFileTable[1] and H.trim(TextFileTable[1]):sub(1,5) ~= [[<?xml]] then
                    -- this is NOT the EXML file
                    -- restore the current EXML file
                    ActiveFile = My.ActiveFile_bak
                    TextFileTable = My.TextFileTable_bak
  -- H.lineLevels = LineLevels(TextFileTable)
                    H.FullPathFile = My.FullPathFile_bak
                    H.DEBUG_SEC_print("@@@@@ Internally restored ActiveFile_bak to <"..tostring(ActiveFile)..">")
                  end
                  
                  -- if #TextFileTable > 100000 then
                    -- My.SavingToDiskStart = os.clock()
                    -- if not H.gIs_LEAN_MODE then
                      -- print(H._zBRIGHTGREEN.."   >>> Large file: "..H._zBRIGHTORANGE.."Saving "..H._zBRIGHTGREEN..ActiveFile..H._zBRIGHTORANGE.." to disk..."..H._zDEFAULT)
                    -- end
                  -- else
                    -- if not H.gIs_LEAN_MODE then
                      -- print("   "..H._zBRIGHTGREEN..">>> "..H._zBRIGHTORANGE.."Saving "..H._zBRIGHTGREEN..ActiveFile..H._zBRIGHTORANGE.." to disk..."..H._zDEFAULT)
                    -- end
                    -- if not H.gIs_LEAN_MODE then
                      -- print("   "..H._zBRIGHTGREEN..">>> "..H._zBRIGHTORANGE.."Saving "..H._zBRIGHTGREEN..ActiveFile..H._zBRIGHTORANGE.." to memory..."..H._zDEFAULT)
                    -- end
                    -- -- H.printf("ActiveFile = [%s]",ActiveFile)
                  -- end
                  My.endBracket = ""
                  if #TextFileTable == 0 then
                    My.endBracket = "}"
                  end
                  -- H.Report("","    >>> Saved to disk: ["..ActiveFile.."]"..My.endBracket)
                  H.Report("",My.endBracket)
                  -- H.DEBUG_SavingToDisk_print(strformat(" AFTER this ExchangePropertyValue(): Saving to disk, #TextFileTable = %d, [%s]",#TextFileTable,ActiveFile))

                  -- = = = = = =
-- --                  H.WriteToFile(H.ConvertLineTableToText(TextFileTable), ActiveFile)
--                  H.WriteToFile(TextFileTable, ActiveFile)
                  -- = = = = = =

                  My.SavingToDiskDone = true
                  -- H.DEBUG_SavingToDisk_print(" AFTER this ExchangePropertyValue(): Done writing to disk")
                  -- if not H.gIs_LEAN_MODE and #TextFileTable > 100000 then
                    -- print(H._zBRIGHTGREEN.."        - done in "..H.dClock(os.clock() - My.SavingToDiskStart)..H._zDEFAULT)
                  -- end
                -- else
                  -- if H.WDEBUG then H.WFAK("B: No MXML_CT, no need to save ["..file.."]") end
                end
              end
              
            -- elseif not OkToSkipOpeningFile and not RemoveFlagExist then
            elseif not RemoveFlagExist and not H.IsExFunc then
if H.WDEBUG then printf("^v^v^v^v^v  D: #TextFileTable = %d",#TextFileTable) end
              -- print("*** NO REMOVE")
              print(">>> "..H.gcWARNING.." [WARNING] EMPTY MBIN file or does not exist! Check script... "..H._zDEFAULT)
              H.Report("","EMPTY MBIN file or does not exist! Check script...","WARNING")
              --reset
              RemoveFlagExist = false
            end -- if #TextFileTable ~= 0 then
            
          end -- if MbinFsDiscard(H,mMBIN_CT["MBIN_FS_DISCARD"]) then

          i_MBIN_CT = i_MBIN_CT + 1        
        end -- while i_MBIN_CT <= #nMOD["MBIN_CHANGE_TABLE"] do
        
        if H.WDEBUG then H.WFAK([=[                       =======================>>>>  OUT OF:  while i_MBIN_CT <= #nMOD["MBIN_CHANGE_TABLE"] do]=]) end
      end -- if nMOD["MBIN_CHANGE_TABLE"] then
      
      if iEXML_CT_IsNil or iEXML_CT_IsString then
        if H.WDEBUG then print([=[BREAK out of 'while i_MBIN_CT <= #nMOD["MBIN_CHANGE_TABLE"] do']=]) end
        break -- out of: for n=1,#MOD_DEF["MODIFICATIONS"] do
      end
      
    end -- for n=1,#MOD_DEF["MODIFICATIONS"] do
    if H.WDEBUG then H.WFAK([=[                       =======================>>>>  OUT OF: for n=1,#MOD_DEF["MODIFICATIONS"] do]=]) end
    
  end -- if MOD_DEF["MODIFICATIONS"]~=nil then
  
  if AtLeastOne_EXML_CHANGE_TABLE and MOD_DEF["MODIFICATIONS"] and NumReplacements == 0 then
    print(">>> "..H.gcWARNING.." [WARNING] No replacement done. Please verify your script "..H._zDEFAULT)
    H.Report(CurrentScriptName,"No replacement done. Please verify your script","WARNING")
  end
  if MOD_DEF["ADD_FILES"] and NumFilesAdded == 0 then
    if #MOD_DEF["ADD_FILES"] >= 1 and MOD_DEF["ADD_FILES"][1]["FILE_DESTINATION"] ~= "" then
      print(">>> "..H.gcWARNING.." [WARNING] ADD_FILES could not add files. Please verify your script "..H._zDEFAULT)
      H.Report(CurrentScriptName,"ADD_FILES could not add files. Please verify your script","WARNING")
    end
  end
  
  if MOD_DEF["ADD_FILES"] or AtLeastOne_EXML_CHANGE_TABLE or AtLeastOne_MBIN_CHANGE_TABLE then
    H.Report("")
    
    if NumREGEXBEFORE > 0 or NumREGEXAFTER > 0 then
      H.Report(NumREGEXBEFORE.." REGEXBEFORE action(s), "..NumREGEXAFTER .. " REGEXAFTER action(s)")
    end
    
    if NumXLST > 0 then
      H.Report(NumXLST.." XLST action(s)")
    end
    
    NumReplacements = NumReplacements + NumREGEXBEFORE + NumREGEXAFTER + NumXLST
    -- if IsMulti_pak then
      -- H.Report("["..NumReplacements.." action(s), "..NumFilesAdded .. " files/groups of files ADDed]","Ended sub-script processing with ")
    -- else
      H.Report("["..NumReplacements.." action(s), "..NumFilesAdded .. " files/groups of files ADDed]","Ended script processing with")
    -- end
    
    print("")
    print("    "..H._zBGintense.."                                                                              "..H._zDEFAULT)
    print("    "..H._zDEFAULT..">>>>>"..H._zDEFAULT.." Ended ALL with "..NumReplacements.." action(s) made and "..NumFilesAdded .. " files/groups of files ADDed "..H._zDEFAULT.."<<<<<"..H._zDEFAULT)
    print("    "..H._zBGintense.."                                                                              "..H._zDEFAULT)
    
    print("")
  end
  
  if not H.gIs_LEAN_MODE and H._mSerializeScript == "Y" and My.IsFUNCexist then
    -- this FORCES serializing a script with VCT's FUNC_xxx() AFTER it was processed by AMUMSS
    
    if #MOD_DEF < 10000 then
      print(">>> [INFO]"..H._zBRIGHTGREEN..[[ Creating ]]..H._zBRIGHTORANGE..[['scriptname'.postserial.lua]]..H._zBRIGHTGREEN..[[ in TOOLS\ModScriptCheck folder due to the use of VCT function, please wait...]]..H._zDEFAULT)
      -- print("")
      -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      local outTable = {}
      local itemName = "NMS_MOD_DEFINITION_CONTAINER"
      
      SerializeLoadedScript(H,itemName,MOD_DEF,outTable)
      outTable = PostProcessing(H,outTable)
      
      outTable[#outTable] = strsub(outTable[#outTable],1,-2) -- remove last ,
      -- outTable[#outTable] = outTable[#outTable]:gsub(",","") -- remove last line comma
      
      local scriptFilenamePath = H.LoadFileData("CurrentModScript.txt")
      local scriptFilename = H.GetFilenameFromFilePath(scriptFilenamePath)
      
      -- H.WriteToFile(H.ConvertLineTableToText(outTable), [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.postserial.lua]])
      H.WriteToFile(outTable, [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.postserial.lua]])
      -- for i=1,#outTable do
        -- print(outTable[i])
      -- end
      
      -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      -- print("")
    else
      print(">>> [INFO]"..H._zBRIGHTGREEN..[[ AUTO-Skipping creation of ]]..H._zBRIGHTORANGE..[['scriptname'.postserial.lua]]..H._zBRIGHTGREEN..[[, VERY LARGE script]]..H._zDEFAULT)
    end
  end

  H.pv(H.THIS.."From end of HandleModScript()")
end

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- NOT USED
-- function CheckReCreatedEXMLAgainstOrg(H,file)
  -- -- now we can compare the ORIG_MOD with this ReCreated_MOD
  -- --if the SAME then SUCCESS
  -- --else report FAILURE
  -- H.pv(H.THIS.."From CheckReCreatedEXMLAgainstOrg()")
  -- print("")
  -- -- H.Report("")
  -- -- *file (ORG EXML)        H.gMASTER_FOLDER_PATH..[[\SCRIPTBUILDER\MOD\]]..string.gsub(nMOD["MBIN_CHANGE_TABLE"][m]["MBIN_FILE_SOURCE"],"%.MBIN",".MXML"),
  -- --local temp = H.gMASTER_FOLDER_PATH..H.gPathToModbuilderMod..file
  -- local temp = H.gPathToModbuilderMod..file
  -- -- temp = string.gsub(temp,[[\]],[[\\]]) --no need to do this replacement
  
  -- local say = temp
  -- -- because string.gsub pattern does not work with all folder names (ex.: ".")
  -- if string.find(say,H.gMASTER_FOLDER_PATH,1,true) then
    -- local start = string.find(say,H.gMASTER_FOLDER_PATH,1,true)
    -- say = string.sub(say,1,start - 1)..string.sub(say,#H.gMASTER_FOLDER_PATH + start)
  -- end
  -- print("           "..say)
  -- -- H.Report("","           "..say,"")
  
  -- local ORIG_MOD = H.LoadFileData(temp)
  -- print("  Original MOD is "..#ORIG_MOD.." long")
  -- H.Report("","  Original MOD is "..#ORIG_MOD.." long")
  
  -- temp = string.gsub(temp,H.gPathToModbuilderMod,[[\Modified_PAK\DECOMPILED\]])
  
  -- local say = temp
  -- -- because string.gsub pattern does not work with all folder names (ex.: ".")
  -- if string.find(say,H.gMASTER_FOLDER_PATH,1,true) then
    -- local start = string.find(say,H.gMASTER_FOLDER_PATH,1,true)
    -- say = string.sub(say,1,start - 1)..string.sub(say,#H.gMASTER_FOLDER_PATH + start)
  -- end
  -- print("     "..say)
  -- -- H.Report("","     "..say,"")
  
  -- local ReCreated_MOD = H.LoadFileData(temp)
  -- print("Re-Created MOD is "..#ReCreated_MOD.." long")
  -- H.Report("","Re-Created MOD is "..#ReCreated_MOD.." long")
  
  -- ResultsCreatingScript[#ResultsCreatingScript + 1] = {}
  -- ResultsCreatingScript[#ResultsCreatingScript][1] = file
  
  -- if ReCreated_MOD == ORIG_MOD then
    -- ResultsCreatingScript[#ResultsCreatingScript][2] = "Success"
    -- print("\n      ********************************************************************************")
    -- print("\n      >>>>>>>>>>>>  Script MOD creation SUCCEEDED, BOTH FILES IDENTICAL!  <<<<<<<<<<<<")
    -- print("\n      ********************************************************************************")
    -- H.Report("",">>>>>>>>>>>>  Script MOD creation SUCCEEDED, BOTH FILES IDENTICAL!  <<<<<<<<<<<<","SUCCESS")
  -- else
    -- ResultsCreatingScript[#ResultsCreatingScript][2] = "Failure"
    -- print("\n      --------------------------------------------------------")
    -- print("\n      XXXXXXXXXXXX  Script MOD creation FAILURE!  XXXXXXXXXXXX")
    -- print("\n      --------------------------------------------------------")
    -- H.Report("","XXXXXXXXXXXX  Script MOD creation FAILURE!  XXXXXXXXXXXX","ERROR")
  -- end
  -- print("")
  -- H.Report("")
  -- H.pv(H.THIS.."From end of CheckReCreatedEXMLAgainstOrg()")
-- end

--***************************************************************************************************
function LineLevels(EXMLTable)
  local strfind = string.find
  local start = os.clock()
  local lineLevels = {}
  local level = 0
  -- find Data line
  local dataLine = 0
  repeat
    dataLine = dataLine + 1
    if EXMLTable[dataLine] == nil then
      break
    else
      lineLevels[#lineLevels+1] = level
    end
  until strfind(EXMLTable[dataLine],[[te=]],1,true)

  if dataLine > #EXMLTable then
    -- no Template found
    dataLine = 1
  end
  
  for i = dataLine, #EXMLTable do
    local text = EXMLTable[i]
    
    if strfind(text,[[/>]],1,true) then
      --ALL lines with "/>"
      lineLevels[#lineLevels+1] = level + 1
      
    -- #######################################################
    -- from here on, no lines with "/>".  Only lines with ">"
    elseif strfind(text,[[</Property>]],1,true) then
      --like: </Property>
      lineLevels[#lineLevels+1] = level
      level = level - 1

    elseif strfind(text,[[me=]],1,true) or strfind(text,[[ue=]],1,true) then
      --like: <Property name="ProceduralTexture" value="TkProceduralTextureChosenOptionList.xml">        
      level = level + 1
      lineLevels[#lineLevels+1] = level
      
    -- elseif strfind(text,[[me=]],1,true) then
      -- --here there is NO value
      -- --like: <Property name="Landmarks">
      -- level = level + 1
      -- lineLevels[#lineLevels+1] = level
      
    -- elseif strfind(text,[[ue=]],1,true) then
      -- --like: <Property value="TkProceduralTextureChosenOptionSampler.xml">
      -- level = level + 1
      -- lineLevels[#lineLevels+1] = level
      
    elseif strfind(text,[[</Data>]],1,true) then
      --like: </Data>
      lineLevels[#lineLevels+1] = level      
    end
  end
  
  -- printf("         Done LineLevels() in %s",H.dClock(os.clock() - start))
  return lineLevels
end

--***************************************************************************************************
function GetSpecKeyWordsInfo(H,spec_key_words)
  local Info = ""
  for i=1,#spec_key_words,2 do
    if spec_key_words[i] and spec_key_words[i+1] then
      Info = Info..[[<"]]..spec_key_words[i]..[[","]]..spec_key_words[i+1]..[["> + ]]
    end
  end
  Info = H.rtrim(string.sub(Info,1,-4))
  return Info
end

--***************************************************************************************************
function GetPrecKeyWordsInfo(prec_key_words)
  local Info = ""
  for i=1,#prec_key_words do
    if prec_key_words[i] then
      Info = Info..[["]]..prec_key_words[i]..[[",]]
    end
  end
  return [[{]]..Info..[[},]]
end

--***************************************************************************************************
function GetValueMatchInfo(val_match,IsValueMatchOptionsMatch)
  local OR = " or "
  -- if IsValueMatchOptionsMatch ~= true then
    -- OR = " and "
  -- end
  local Info = ""
  for i=1,#val_match do
    if type(val_match[i][1]) =="table" then
      Info = Info..val_match[i][1][1].."-"..val_match[i][1][2]..OR
    else
      if val_match[i][1] and val_match[i][1] ~= "" then
        if type(tonumber(val_match[i][1])) == "number" then
          Info = Info..val_match[i][1]..OR
        else
          Info = Info..[["]]..val_match[i][1]..[["]]..OR
        end
      end
    end
  end
  --remove last " or " OR " and "
  return string.sub(Info,1,(#OR+1)*-1)
end

--***************************************************************************************************
function GetWhereInSectionInfo(WhereKeyWords)
  local Info = ""
  for i=1,#WhereKeyWords do
    if WhereKeyWords[i][1] and WhereKeyWords[i][2] then
      Info = Info..[[{"]]..WhereKeyWords[i][1]..[[","]]..WhereKeyWords[i][2]..[[",}, ]]
    end
  end
  Info = string.sub(Info,1,-2)
  return Info
end
--***************************************************************************************************

--***************************************************************************************************
function GetWhereInSubSectionInfo(SubWhereKeyWords)
  local Info = ""
  for i=1,#SubWhereKeyWords do
    if SubWhereKeyWords[i][1] and SubWhereKeyWords[i][2] then
      Info = Info..[[{"]]..SubWhereKeyWords[i][1]..[[","]]..SubWhereKeyWords[i][2]..[[",}, ]]
    end
  end
  Info = string.sub(Info,1,-2)
  return Info
end
--***************************************************************************************************

--***************************************************************************************************
local MapFileTreeSharedListPINGtime = os.clock()
-- only do it every sec or more
function MapFileTreeSharedListPING(H)
  if MapFileTreeSharedListPINGtime + 10 < os.clock() then -- wait for at least 10 sec
    MapFileTreeSharedListPINGtime = os.clock()
    -- printf("At %f: did a PING",MapFileTreeSharedListPINGtime)
    if H.IsFileExist([[MapFileTreeSharedList.txt]]) then
      H.WriteToFileAppend("PING".."\n",[[MapFileTreeSharedList.txt]])
    end
  end
end

--*************************************** handles generic SECTION_UP *******************************************
function Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,KeyWordLine,section_up)
  -- SHOULD NOT AFFECT KWinfo
  -- H.pv("")
  -- H.pv([[D ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]])
  if section_up > 0 then
    -- H.pv("Processing SECTION_UP = "..section_up)
    for n=1,#GroupStartLine do
      local Section_UP = section_up
      local currentLine = GroupStartLine[n]
      -- H.pv("  SECTION_UP: Current line = "..currentLine)
      repeat
        GroupStartLine[n] = H.GoUPToOwnerStart(TextFileTable,currentLine)
        GroupEndLine[n] = H.GoDownToOwnerEnd(TextFileTable,GroupStartLine[n]+1)
        KeyWordLine[n] = KeyWordLine[n] --stays the same
        currentLine = GroupStartLine[n]
        Section_UP = Section_UP - 1
      until Section_UP == 0
    end
  end
  return GroupStartLine,GroupEndLine,KeyWordLine
end
--*************************************** END: handles generic SECTION_UP **************************************

--***************************************************************************************************
function ShowKeyWordInfo(H,spec_key_words,prec_key_words,IsPrecedingKeyWords,IsSpecialKeyWords,IsPrecedingFirstTRUE,IsUsingForeach_SKWG,item)
  if IsPrecedingKeyWords or IsSpecialKeyWords then
    if not H.gIs_LEAN_MODE then print("") end
  end
  
  if IsUsingForeach_SKWG then
    H.Report(""," -> using FOREACH_SKW_GROUP["..item.."]")
  end
  
  local Info = ""
  if IsPrecedingFirstTRUE then
    if IsPrecedingKeyWords then
      Info = GetPrecKeyWordsInfo(prec_key_words)
      H.Report(""," -> Based on PRECEDING_KEY_WORDS: >>> "..Info.." <<< ")
      if not H.gIs_LEAN_MODE then print(" -> Based on PRECEDING_KEY_WORDS: >>> "..Info.." <<< ") end
      
      if IsSpecialKeyWords then
        Info = GetSpecKeyWordsInfo(H,spec_key_words)
        H.Report("","    and SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ")
        if not H.gIs_LEAN_MODE then print("     and SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ") end
      end
      if H.IsKWpattern then
        H.Report("","    <<< Treated as lua Patterns >>>")
        if not H.gIs_LEAN_MODE then print("    <<< Treated as "..H._zBRIGHTORANGE.."Lua Patterns"..H._zDEFAULT.." >>>") end
      end
    else
      if IsSpecialKeyWords then
        Info = GetSpecKeyWordsInfo(H,spec_key_words)
        H.Report(""," -> Based on SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ")
        if not H.gIs_LEAN_MODE then print(" -> Based on SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ") end
        if H.IsKWpattern then
          H.Report("","    <<< Treated as lua Patterns >>>")
          if not H.gIs_LEAN_MODE then print("    <<< Treated as "..H._zBRIGHTORANGE.."Lua Patterns"..H._zDEFAULT.." >>>") end
        end      
      end
    end
    
  else
    if IsSpecialKeyWords then
      Info = GetSpecKeyWordsInfo(H,spec_key_words)
      H.Report(""," -> Based on SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ")
      if not H.gIs_LEAN_MODE then print(" -> Based on SPECIAL_KEY_WORDS pairs: >>> "..Info.." <<< ") end
      
      if IsPrecedingKeyWords then
        Info = GetPrecKeyWordsInfo(prec_key_words)
        H.Report("","            and PRECEDING_KEY_WORDS: >>> "..Info.." <<< ")
        if not H.gIs_LEAN_MODE then print("             and PRECEDING_KEY_WORDS: >>> "..Info.." <<< ") end
      end
      if H.IsKWpattern then
        H.Report("","    <<< Treated as lua Patterns >>>")
        if not H.gIs_LEAN_MODE then print("    <<< Treated as "..H._zBRIGHTORANGE.."Lua Patterns"..H._zDEFAULT.." >>>") end
      end      
    else
      if IsPrecedingKeyWords then
        Info = GetPrecKeyWordsInfo(prec_key_words)
        H.Report(""," -> Based on PRECEDING_KEY_WORDS: >>> "..Info.." <<< ")
        if not H.gIs_LEAN_MODE then print(" -> Based on PRECEDING_KEY_WORDS: >>> "..Info.." <<< ") end
      if H.IsKWpattern then
        H.Report("","    <<< Treated as lua Patterns >>>")
        if not H.gIs_LEAN_MODE then print("    <<< Treated as "..H._zBRIGHTORANGE.."Lua Patterns"..H._zDEFAULT.." >>>") end
      end      
      end
    end
  end
end
--****************************** END: ShowKeyWordInfo ***********************************************

--***************************************************************************************************
-- prepare info to inform user
function PrepareInfoForUser(H,VCTproperty,VCTvalue,VCTSaveValueName
      ,IsMath_Operation,math_operation,IsInline
      ,IsInteger_to_floatPRESERVE,IsInteger_to_floatFORCE
      ,IsValueMatch,val_match,IsValueMatchOptionsMatch,value_match_options,value_match_type,newIsValueMatchType
      ,IsLineOffset,line_offset -- ,IsMainSection,IsSubLevel,subLevelNumber
      ,IsSpecialKeyWords,spec_key_words
      ,IsPrecedingKeyWords,prec_key_words
      ,IsHOSCreated,IsCreateHOESTRUE
      -- ,IsCreateHOSTRUE,IsCreateHOESTRUE
      ,IsWhereKeyWords,WhereKeyWords
      ,IsSubWhereKeyWords,IsWisubSecOptionALL,SubWhereKeyWords
      ,IsWiSecLopAND,IsWiSecLopNOR,IsWisubSecLopAND,IsWisubSecLopNOR
      ,IsTextToAdd,IsReplaceADDAFTERLINE,IsReplaceADDAFTERSECTION,IsAuto_GNH
      ,IsToRemove,IsToRemoveLINE,IsToRemoveSECTION,IsToRemoveHBOS
      ,IsReplace,IsReplaceRAW,IsReplaceONCE,IsReplaceONCEInsideSection,IsReplaceALL,IsReplaceAllInSection,IsReplaceAllInsideSection,IsReplaceFOLLOWING
      ,IsLargeNumOfReplacement,RememberNumberOfGroups,NumFoundSections
      ,IsFUNCexist,FUNC_detected
      )
  local spacer = 0
  local msg0 = ""
  local msg1 = ""
  local msg2 = ""
  local msg3 = ""
  local Rmsg3 = ""
  local msg4 = ""
  local msg5 = ""
  local Info = ""
  
  if IsMath_Operation or IsInline then
    msg1 = "Math_operation "
    
    --clean and count
    local mathOp,b = string.gsub(math_operation,"!","")
    mathOp,c = string.gsub(mathOp,"%$","")
    -- mathOp,d = string.gsub(mathOp,"@","")
    local mo = string.sub(mathOp,2)..string.sub(mathOp,1,1)
    
    local Inline = ""
    if IsInline then Inline = "@" end
    
    msg2 = Inline..string.rep([[!]],b)..string.rep([[$]],c)..mo
    -- print("msg2 = <"..msg2..">")
    -- "["..msg2..qm12..VCTvalueTmp..userInputR..qm12.."]"
    
    if IsValueMatch then
      msg3 = " matching ["..value_match_options..GetValueMatchInfo(val_match).."]"
    end
    
  else
    if IsValueMatch then
      if IsValueMatchOptionsMatch then
        msg3 = " matching "..H._zBRIGHTORANGE..GetValueMatchInfo(val_match,IsValueMatchOptionsMatch)..H._zDEFAULT
        Rmsg3 = " matching "..GetValueMatchInfo(val_match,IsValueMatchOptionsMatch)
      else
        msg3 = " not matching "..H._zBRIGHTORANGE..GetValueMatchInfo(val_match,IsValueMatchOptionsMatch)..H._zDEFAULT
        Rmsg3 = " not matching "..GetValueMatchInfo(val_match,IsValueMatchOptionsMatch)
      end
    end
  end
  
  if newIsValueMatchType then
    msg3 = msg3.." of type ["..value_match_type.."]"
    Rmsg3 = Rmsg3.." of type ["..value_match_type.."]"
  end
  
  if IsLineOffset then
    if IsSpecialKeyWords then
      local ThreeDots = ""
      if #spec_key_words > 2 then ThreeDots = "... " end
      msg5 = " at "..ThreeDots.."["..spec_key_words[#spec_key_words-1].."] and ["..spec_key_words[#spec_key_words].."]"
    else
      msg5 = " at ["..prec_key_words[#prec_key_words].."]"
    end
    msg4 = " with a LINE_OFFSET of ["..line_offset.."]" --was offset
  end
  
  local VCTvalueTmp,IsNotNil = GetVCTvalueTmp(VCTvalue)
  
  local userInput = ""
  local userInputR = ""
  if IsNotNil then
    userInput = H._zBRIGHTGREEN.." (or user input)"..H._zDEFAULT
    userInputR = " (or user input)"
  end
  -- print("   VCTvalue = <"..tostring(VCTvalue)..">")
  -- print("VCTvalueTmp = <"..tostring(VCTvalueTmp)..">")
  
  if FUNC_detected and not IsFUNCexist then
    print("\n"..">>> "..H.gcNOTICE.." [NOTICE] '() detected' below: If a 'user script function' => Correct your Function name! "..H._zDEFAULT)
    H.Report("","'() detected' below: If a 'user script function' => Correct your Function name!","NOTICE")
  end
  
  if IsTextToAdd then
    spacer = 11
    if IsReplaceADDAFTERLINE then
      H.Report("","    Looking to >>> add some text <<< after LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInputR..[["]].."]"..Rmsg3..msg4)
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> add some text <<< after LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInput..[["]].."]"..msg3..msg4) end
    elseif IsReplaceADDAFTERSECTION then
      H.Report("","    Looking to >>> add some text <<< after SECTION")
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> add some text <<< after SECTION") end
    else
      H.Report("","    Looking to >>> replace some text <<< at LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInputR..[["]].."]"..Rmsg3..msg4)
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> replace some text <<< at LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInput..[["]].."]"..msg3..msg4) end
    end
    
    if IsToRemoveHBOS then
      H.Report("","               >>> remove HBOS <<<")
      if not H.gIs_LEAN_MODE then print("               >>> remove HBOS <<<") end
    end
    
    if IsAuto_GNH then
      H.Report("","               >>> AUTO-generating NameHash <<<")
      if not H.gIs_LEAN_MODE then print("               >>> AUTO-generating NameHash <<<") end
    end
    
  elseif IsToRemove then
    spacer = 11
    if IsToRemoveLINE then
      H.Report("","    Looking to >>> remove LINE <<< at Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInputR..[["]].."]"..Rmsg3..msg4)
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> remove LINE <<< at Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInput..[["]].."]"..msg3..msg4) end
    elseif IsToRemoveSECTION then
      H.Report("","    Looking to >>> remove SECTION <<< "..Rmsg3)
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> remove SECTION <<< "..msg3) end
    else
      H.Report("","    Looking to >>> remove some text <<< at LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInputR..[["]].."]"..Rmsg3..msg4)
      if not H.gIs_LEAN_MODE then print("\n    Looking to >>> remove some text <<< at LINE with Property name ["..[["]]..VCTproperty..[["]].."] and value ["..[["]]..VCTvalueTmp..userInput..[["]].."]"..msg3..msg4) end
    end
    
  else
    --reset
    IsLargeNumOfReplacement = false
    
    local qm12 = [["]]
    if type(tonumber(VCTvalueTmp)) == "number" then qm12 = [[]] end
    H.Report("","    Looking for >>> ["..[["]]..VCTproperty..[["]].."] New value will be >>> "..msg1.."["..msg2..qm12..VCTvalueTmp..userInputR..qm12.."]"..Rmsg3..msg4..msg5)
    
    local part1 = H.trim(VCTproperty)
    if #part1 > 100 then
      part1 = string.sub(part1,1,30)..H._zBRIGHTGREEN..[[ ..trimmed.. ]]..H._zDEFAULT..H.ltrim(string.sub(part1,-30))
    end
    local part2 = H.trim(VCTvalueTmp)
    qm12 = [["]]
    local part2tmp = part2:gsub([["]],"")
    if part2tmp then
      if type(tonumber(part2tmp)) == "number" then qm12 = [[]] end
    else
      if type(tonumber(part2)) == "number" then qm12 = [[]] end
    end
    if part2:sub(1,1) == '"' then qm12 = [[]] end
    
    if #part2 > 100 then
      part2 = string.sub(part2,1,30)..H._zBRIGHTGREEN..[[ ..trimmed.. ]]..H._zDEFAULT..H.ltrim(string.sub(part2..userInput,-30))
    end
    -- print("msg2 = <"..msg2..">")
    -- print("qm12 = <"..qm12..">")
    -- print("part2 = <"..part2..">")
    if not H.gIs_LEAN_MODE then
      print("\n    Looking for >>> ["..[["]]..part1..[["]].."] New value will be >>> "..msg1.."["..msg2..qm12..part2..userInput..qm12.."]"..msg3..msg4..msg5)
    end
    spacer = 12
  end
  
  local LOP = ""
  if IsWhereKeyWords then
    LOP = "(OR)"
    if IsWiSecLopAND then
      LOP = "(AND)"
    end
    if IsWiSecLopNOR then
      LOP = "(NOR)"
    end
    Info = GetWhereInSectionInfo(WhereKeyWords)
    
    msg0 = string.rep(" ",spacer).."    >>> using WHERE_IN_SECTION "..LOP.." "..Info.." to restrict search..."
    H.Report("",msg0)
    
    if not H.gIs_LEAN_MODE then
      msg0 = string.rep(" ",spacer).."    >>> using WHERE_IN_SECTION "..H._zBRIGHTGREEN..LOP..H._zDEFAULT.." "..Info.." to restrict search..."
      print(msg0)
    end
    
    local secCount = ""
    if RememberNumberOfGroups > 1 then
      secCount = "s"
    end
    msg0 = string.rep(" ",spacer).."    >>> Evaluated "..RememberNumberOfGroups.." section"..secCount..", found "..NumFoundSections.." sub-section(s) against WHERE_IN_SECTION keywords..."
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then print(msg0) end
  end
  
  if IsSubWhereKeyWords then
    local Option = ""
    if IsWisubSecOptionALL then
      Option = "with [ALL sub-sections] "
    end
    LOP = "(OR)"
    if IsWisubSecLopAND then
      LOP = "(AND)"
    elseif IsWisubSecLopNOR then
      LOP = "(NOR)"
    end
    Info = GetWhereInSubSectionInfo(SubWhereKeyWords)
    msg0 = string.rep(" ",spacer).."    >>> using WHERE_IN_SUBSECTION "..LOP.." "..Option..Info.." to restrict search..."
    H.Report("",msg0)
    
    if not H.gIs_LEAN_MODE then
      msg0 = string.rep(" ",spacer).."    >>> using WHERE_IN_SUBSECTION "..H._zBRIGHTGREEN..LOP..H._zDEFAULT.." "..Option..Info.." to restrict search..."
      print(msg0)
    end
    
    local secCount = ""
    if RememberNumberOfGroups > 1 then
      secCount = "s"
    end
    msg0 = string.rep(" ",spacer).."    >>> Evaluated "..RememberNumberOfGroups.." section"..secCount..", found "..NumFoundSections.." sub-section(s) against WHERE_IN_SUBSECTION keywords..."
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then print(msg0) end
  end
  
  if IsReplace then
    if IsReplaceONCE then msg0 = "ONCE" end
    if IsReplaceONCEInsideSection then msg0 = "ONCEINSIDE" end
    if IsReplaceALL then msg0 = "ALL" end
    if IsReplaceAllInSection then msg0 = "ALLINSECTION" end
    if IsReplaceAllInsideSection then msg0 = "ALLINSIDESECTION" end
    if IsReplaceFOLLOWING then msg0 = "FOLLOWING" end
    if IsReplaceRAW then msg0 = "RAW" end
    
    msg0 = string.rep(" ",spacer).."    >>> Replace ["..msg0.."]"
    if IsPrecedingKeyWords then
      Info = GetPrecKeyWordsInfo(prec_key_words)
      msg0 = msg0.." based on key_words: "..Info
    end
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then
      print(msg0)
    end
  end
  
  if IsInteger_to_floatPRESERVE then
    msg0 = string.rep(" ",spacer).."    >>> INTEGER_TO_FLOAT is [PRESERVE]"
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then
      print(msg0)
    end
  elseif IsInteger_to_floatFORCE then
    msg0 = string.rep(" ",spacer).."    >>> INTEGER_TO_FLOAT is [FORCE]"
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then
      print(msg0)
    end
  end
  
  -- if IsCreateHOSTRUE then
  if IsHOSCreated then
    msg0 = string.rep(" ",spacer).."    >>> Creating "..H._zBRIGHTGREEN.."HOS"..H._zDEFAULT
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then
      print(msg0)
    end
  end
  
  if IsCreateHOESTRUE then
    msg0 = string.rep(" ",spacer).."    >>> Creating "..H._zBRIGHTGREEN.."HOES"..H._zDEFAULT
    H.Report("",msg0)
    if not H.gIs_LEAN_MODE then
      print(msg0)
    end
  end
  
  -- if IsSubLevel then
    -- msg0 = string.rep(" ",spacer).."    >>> SUB_LEVEL "..subLevelNumber.." requested"
      -- H.Report("",msg0)
      -- if not H.gIs_LEAN_MODE then
        -- print(msg0)
      -- end
  -- end
  
end
--****************************** END: PrepareInfoForUser ***********************************************

--***************************************************************************************************
--on the first possible VCT
function OnFirstVCT(H,section_up_preceding,section_up_special,section_up
      ,IsSpecialKeyWords,spec_key_words
      ,IsPrecedingFirstTRUE,IsPrecedingKeyWords,prec_key_words
      ,IsWhereKeyWords,IsSubWhereKeyWords
      ,IsEditSection
      ,IsAfterKeyWords,a_key_words
      -- ,IsMainSection,IsSubLevel
      )
  H.pv("First time")
  
  -- if IsMainSection then
    -- H.pv("   with MAIN_SECTION")
      -- H.Report("","       >>>>> Search in MAIN section requested")
      -- if not H.gIs_LEAN_MODE then
        -- print("\n       >>>>> Search in MAIN section requested")
      -- end
  -- end
  
  if IsSpecialKeyWords then
    H.pv("   with SPECIAL_KEY_WORDS")
    
    if #spec_key_words%2 ~= 0 then
      --not an even number of spec_key_words: problem
      -- print("")
      print(">>> "..gcWARNING.." [WARNING] SPECIAL_KEY_WORDS: NOT an even number of (name/value).  LAST entry will be IGNORED.  Please correct your script! "..H._zDEFAULT)
      H.Report("","SPECIAL_KEY_WORDS: NOT an even number of (name/value).  LAST entry will be IGNORED.  Please correct your script!","WARNING")
    end
    
  elseif IsPrecedingKeyWords then
    H.pv("   with SomeKeyWords")
    
  else --no key_words
    local tmp = "file"
    if IsEditSection then
      tmp = "section"
    end
    
    if IsWhereKeyWords or IsSubWhereKeyWords then
      H.Report(""," -> No key_word specified, using whole "..tmp.." to apply conditions...")
      if not H.gIs_LEAN_MODE then
        print("\n -> No key_word specified, using whole "..tmp.." to apply conditions...")
      end
    else
      H.Report(""," -> No key_word specified, using whole "..tmp.."...")
      if not H.gIs_LEAN_MODE then
        print("\n -> No key_word specified, using whole "..tmp.."...")
      end
    end
  end
  
  if IsPrecedingFirstTRUE then
    if section_up_preceding > 0 then
      if section_up_preceding == 1 then
        H.Report("","       >>>>> Going UP "..section_up_preceding.." parent section after PRECEDING_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_preceding.." parent section after PRECEDING_KEY_WORDS...")
        end
      else
        H.Report("","       >>>>> Going UP "..section_up_preceding.." parent sections after PRECEDING_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_preceding.." parent sections after PRECEDING_KEY_WORDS...")
        end
      end
    end
    
    if section_up_special > 0 then
      if section_up_special == 1 then
        H.Report("","       >>>>> Going UP "..section_up_special.." parent section after SPECIAL_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_special.." parent section after SPECIAL_KEY_WORDS...")
        end
      else
        H.Report("","       >>>>> Going UP "..section_up_special.." parent sections after SPECIAL_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_special.." parent sections after SPECIAL_KEY_WORDS...")
        end
      end
    end
    
  else
    if section_up_special > 0 then
      if section_up_special == 1 then
        H.Report("","       >>>>> Going UP "..section_up_special.." parent section after SPECIAL_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_special.." parent section after SPECIAL_KEY_WORDS...")
        end
      else
        H.Report("","       >>>>> Going UP "..section_up_special.." parent sections after SPECIAL_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_special.." parent sections after SPECIAL_KEY_WORDS...")
        end
      end
    end
    
    if section_up_preceding > 0 then
      if section_up_preceding == 1 then
        H.Report("","       >>>>> Going UP "..section_up_preceding.." parent section after PRECEDING_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_preceding.." parent section after PRECEDING_KEY_WORDS...")
        end
      else
        H.Report("","       >>>>> Going UP "..section_up_preceding.." parent sections after PRECEDING_KEY_WORDS...")
        if not H.gIs_LEAN_MODE then
          print("      -- Going UP "..section_up_preceding.." parent sections after PRECEDING_KEY_WORDS...")
        end
      end
    end
  end
  
  if section_up > 0 then
    if section_up == 1 then
      H.Report("","       >>>>> Going UP "..section_up.." parent section...")
      if not H.gIs_LEAN_MODE then
        print("      -- Going UP "..section_up.." parent section...")
      end
    else
      H.Report("","       >>>>> Going UP "..section_up.." parent sections...")
      if not H.gIs_LEAN_MODE then
        print("      -- Going UP "..section_up.." parent sections...")
      end
    end
  end

  if IsAfterKeyWords then
    local Info = GetPrecKeyWordsInfo(a_key_words)
    H.Report("","       with AKW "..Info)
    if not H.gIs_LEAN_MODE then
      print("     with AKW :"..Info)
    end
  end
  
  if H.exml_id ~= "" then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE..[[      Adding _id="]]..H.exml_id..[[" to HOS]]..H._zDEFAULT)
    end
    H.Report("",[[     Adding _id="]]..H.exml_id..[[" to HOS]])
  end
  
  if H.exml_index ~= "" then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE..[[      Adding _index="]]..H.exml_index..[[" to HOS]]..H._zDEFAULT)
    end
    H.Report("",[[     Adding _index="]]..H.exml_index..[[" to HOS]])
  end
  
  -- if H.IsEXMLflagREMOVE then
    -- if not H.gIs_LEAN_MODE then
      -- print([[      Adding _remove="true" to HOS]])
    -- end
    -- H.Report("",[[     Adding _remove="true" to HOS]])
  -- elseif H.IsEXMLflagOVERWRITE then
  if H.IsEXMLflagOVERWRITE then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE..[[      Adding _overwrite="true" to HOS]]..H._zDEFAULT)
    end
    H.Report("",[[     Adding _overwrite="true" to HOS]])
  end
  if H.IsEXMLflagUPDATESECTION or H.IsReplaceWholeSECTION then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE..[[      Updating section(s)]]..H._zDEFAULT)
    end
    H.Report("",[[     Updating section(s)]])
  end
  if H.IsEXMLflagADDNEWSECTION and not H.IsReplaceWholeSECTION then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE..[[      Adding new section(s)]]..H._zDEFAULT)
    end
    H.Report("",[[     Adding new section(s)]])
  end
end

--****************************** END: OnFirstVCT ***********************************************

--****************************** GetVCTvalueTmp ***********************************************
function GetVCTvalueTmp(VCTvalue)
  local VCTvalueTmp = VCTvalue
  local defaultPos = string.find(string.gsub(string.gsub(VCTvalue,"%s+",""),'"',""),"GUIF({",1,true)
  if defaultPos then
    VCTvalueTmp = string.sub(VCTvalue, defaultPos + 7, defaultPos + 7 + string.find(string.sub(VCTvalue,defaultPos + 7),",",1,true) - 2)
  end
  -- print("VCTvalueTmp = <"..VCTvalueTmp..">")
  return VCTvalueTmp,(defaultPos ~= nil)
end
--****************************** END: GetVCTvalueTmp ***********************************************

-- *****************   mbin_fs_discard section   ********************
function MbinFsDiscard(H,mbin_fs_discard)
  mbin_fs_discard = H.ReturnStringFrom(mbin_fs_discard)
  mbin_fs_discard = string.upper(mbin_fs_discard)
  
  local Ismbin_fs_discard = (mbin_fs_discard ~= "")
  local Ismbin_fs_discardTRUE = (mbin_fs_discard == "TRUE")
  local Ismbin_fs_discardFALSE = (mbin_fs_discard == "FALSE")
  if Ismbin_fs_discard and not (Ismbin_fs_discardTRUE or Ismbin_fs_discardFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] MBIN_FS_DISCARD value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(mbin_fs_discard,[[>>> MBIN_FS_DISCARD value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  return Ismbin_fs_discardTRUE
end
--***************************************************************************************************

-- *****************   sec_keep section   ********************
function SectionKeep(H,sec_keep)
  sec_keep = H.ReturnStringFrom(sec_keep)
  sec_keep = string.upper(sec_keep)
  
  local IsKeepSection = (sec_keep ~= "")
  local IsKeepSectionTRUE = (sec_keep == "TRUE")
  local IsKeepSectionFALSE = (sec_keep == "FALSE")
  if IsKeepSection and not (IsKeepSectionTRUE or IsKeepSectionFALSE) then
    print(H.gcWARNING..[[>>> [WARNING] SEC_KEEP value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(sec_keep,[[>>> SEC_KEEP value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  return IsKeepSectionTRUE
end
--***************************************************************************************************

-- *****************   exml_create section   ********************
function IsEXMLcreate(H,exml_create)
  exml_create = H.ReturnStringFrom(exml_create)
  exml_create = string.upper(exml_create)
  
  if exml_create == "" then
    --default option
    exml_create = "TRUE"
  end
  
  local IsEXMLcreate = (exml_create ~= "")
  
  local IsEXMLcreateTRUE = (exml_create == "TRUE")
  local IsEXMLcreateFALSE = (exml_create == "FALSE") --only used on next line
  if IsEXMLcreate and not (IsEXMLcreateTRUE or IsEXMLcreateFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] EXML_CREATE value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(exml_create,[[>>> EXML_CREATE value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  -- H.printf("H.IsEXMLcreateTRUE = %s",tostring(H.IsEXMLcreateTRUE))
  return IsEXMLcreateTRUE
end
--***************************************************************************************************

-- *****************   auto_gnh section   ********************
function Auto_GNH(H,auto_gnh)
  auto_gnh = H.ReturnStringFrom(auto_gnh)
  auto_gnh = string.upper(auto_gnh)
  
  local IsAuto_GNH = (auto_gnh ~= "")
  local IsAuto_GNHTRUE = (auto_gnh == "TRUE")
  local IsAuto_GNHFALSE = (auto_gnh == "FALSE")
  if IsAuto_GNH and not (IsAuto_GNHTRUE or IsAuto_GNHFALSE) then
    print(H.gcWARNING..[[>>> [WARNING] AUTO_GNH value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(auto_gnh,[[>>> AUTO_GNH value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  return IsAuto_GNHTRUE
end
--***************************************************************************************************

--[=[
ExchangePropertyValue(
H                           ,H
modificationIndex           ,n
MBINchangeTableIndex        ,m
EXMLchangeTableIndex        ,u

item                       ,ECT_Index
                 -- file                        ,file: full NMS path with extension .MXML
file (ORG MXML)            ,H.FullPathFile, aka: H.gPathToModbuilderMod..string.gsub(MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["MBIN_FILE_SOURCE"],".MBIN$",".MXML")
TextFileTable              ,TextFileTable: the normal work 'table' containing the file above or the SEC_EDIT
TextFileTable_bak          ,TextFileTable_bak: the original EXML in a table (can be used when TextFileTable is a SEC_EDIT)

value_change_table         ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["VALUE_CHANGE_TABLE"]
vct_comment                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["VCT_COMMENT"]

special_key_words          ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SPECIAL_KEY_WORDS"]
preceding_key_words        ,PRECEDING_KEY_WORDS_SUB [==]PRECEDING_KEY_WORDS_SUB = MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["PRECEDING_KEY_WORDS"][==]

preceding_first            ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["PRECEDING_FIRST"]
after_key_words            ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["AKW"]

compress_pak               ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["COMPRESS_PAK"]
-- create_exml                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["CREATE_EXML"]
create_hos                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["CREATE_HOS"]
create_hoes                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["CREATE_HOES"]

-- exml_create                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CREATE"]

exml_flags                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["EXML_FLAGS"]
exml_id                    ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["EXML_ID"]
exml_index                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["EXML_INDEX"]

find_all_sections          ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["FIND_ALL_SECTIONS"]
section_up                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SECTION_UP"]
section_up_special         ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SECTION_UP_SPECIAL"]
section_up_preceding       ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SECTION_UP_PRECEDING"]
custom_order               ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["CUSTOM_ORDER"]
section_active             ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SECTION_ACTIVE"]
where_key_words            ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["WHERE_IN_SECTION"]
wi_sec_lop                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["WISEC_LOP"]
subwhere_key_words         ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["WHERE_IN_SUBSECTION"]
wisub_sec_lop              ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["WISUBSEC_LOP"]
wisub_sec_option           ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["WISUBSEC_OPTION"]

sec_save_to                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SEC_SAVE_TO"]
sec_unsaved                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SEC_UNSAVED"]
sec_keep                   ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SEC_KEEP"]
sec_add_named              ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SEC_ADD_NAMED"]
secadd_comment             ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SECADD_COMMENT"]

sec_edit                   ,My.sec_edit
IsEditSection              ,My.IsEditSection

math_operation             ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["MATH_OPERATION"]
integer_to_float           ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["INTEGER_TO_FLOAT"]
global_integer_to_float    ,global_integer_to_float

value_match                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["VALUE_MATCH"]
replace_type               ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["REPLACE_TYPE"]
value_match_type           ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["VALUE_MATCH_TYPE"]
value_match_options        ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["VALUE_MATCH_OPTIONS"]

notice_off                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["NOTICE_OFF"]

line_offset                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["LINE_OFFSET"]
auto_gnh                   ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["AUTO_GNH"]
add_option                 ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["ADD_OPTION"]
text_to_add                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["ADD"]
to_remove                  ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["REMOVE"]

comment                    ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["COMMENT"]

IsEXML_CT_TableOfTables    ,IsEXML_CT_TableOfTables
IsMissingCurlyBrackets     ,IsMissingCurlyBrackets
IsSecEditNumber            ,My.IsSecEditNumber
IsSecEditNotFound          ,My.IsSecEditNotFound

sec_empty                  ,My.sec_empty
IsSecEmpty                 ,My.IsSecEmpty
IsSecEmptyNumber           ,My.IsSecEmptyNumber

IsUsingForeach_SKWG        ,true/false
subLevel                   ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["SUB_LEVEL"]
mainSection                ,MOD_DEF["MODIFICATIONS"][n]["MBIN_CHANGE_TABLE"][m]["EXML_CHANGE_TABLE"][i]["MAIN_SECTION"]
script_env                 ,conf

GUARD                      ,to detect if all arg are here
)
--]=]

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--called each time with all property/value combo in value_change_table
function ExchangePropertyValue(
          H
          ,modificationIndex,MBINchangeTableIndex,EXMLchangeTableIndex
          ,item,file,TextFileTable,TextFileTable_bak
          ,value_change_table,vct_comment
          ,special_key_words,preceding_key_words
          ,preceding_first,after_key_words,compress_pak
          -- ,create_exml
          ,create_hos,create_hoes
          -- ,exml_create
          ,exml_flags,exml_id,exml_index
          ,find_all_sections,section_up,section_up_special,section_up_preceding
          ,custom_order,section_active,where_key_words,wi_sec_lop,subwhere_key_words,wisub_sec_lop,wisub_sec_option
          ,sec_save_to,sec_unsaved,sec_keep,sec_add_named,secadd_comment,sec_edit,IsEditSection
          ,math_operation,integer_to_float,global_integer_to_float
          ,value_match,replace_type,value_match_type,value_match_options
          ,notice_off
          ,line_offset,auto_gnh,add_option,text_to_add,to_remove
          ,comment
          ,IsEXML_CT_TableOfTables
          ,IsMissingCurlyBrackets,IsSecEditNumber,IsSecEditNotFound
          ,sec_empty,IsSecEmpty,IsSecEmptyNumber
          ,IsUsingForeach_SKWG
          ,subLevel,mainSection
          ,conf
          ,GUARD)
          
  if GUARD ~= "Wbertro" then
    print("GUARD is wrong!")
    WaitForAyKey()
    return
  end
  
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strrep = string.rep
    local strformat = string.format
    local strmatch = string.match
    local strgmatch = string.gmatch
  local print = print
  local printf = H.printf
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  local My = {}
  
  My.CheckPoint = H.CheckPoint
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: ExchangePropertyValue() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  
  My._mISxxx = H._mISxxx
  My.gMaxNumberOfGroups = H.gMaxNumberOfGroups
  
  GUIF = H.GUIF
  GNH = H.GNH

My.CheckPoint(3)

-- ShowLocals()
-- H.WFAK("A")

  local ReplNumber = 0
  local ADDcount = 0
  local REMOVEcount = 0
  
  H.IsKWpattern = false

  My.IsFUNCexist = false

  My.IsdotOn = true
  My.dotCount = 0
  
  if H.gIs_LEAN_MODE then
    if item%2 == 0 then
      print(H._zUpOneLine.." > ")
    else
      print(H._zUpOneLine.." < ")
    end
  end
  
  if not H.gIs_LEAN_MODE then
    print(H._zBRIGHTORANGE.."   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"..H._zDEFAULT)
    if IsUsingForeach_SKWG then
      print(H._zBRIGHTGREEN.."                processing FOREACH_SKW_GROUP["..item.."], please wait..."..H._zDEFAULT)
    else
      print(H._zBRIGHTGREEN.."                processing MODIFICATIONS["..modificationIndex.."]["..MBINchangeTableIndex.."]["..EXMLchangeTableIndex.."]["..item.."], please wait..."..H._zDEFAULT)
    end
  end
  
  if not IsEXML_CT_TableOfTables then
    print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE first entry is not just a simple table: check your script! ]]..H._zDEFAULT)
    H.Report("",[[>>> MXML_CHANGE_TABLE first entry is not just a simple table: check your script!]],"WARNING")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  if IsMissingCurlyBrackets then
    print(">>> "..H.gcWARNING..[[ [WARNING] MXML_CHANGE_TABLE first entry is Missing Curly Brackets, check your script! ]]..H._zDEFAULT)
    H.Report("",[[>>> MXML_CHANGE_TABLE first entry is Missing Curly Brackets, check your script!]],"WARNING")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  if IsSecEditNumber then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_EDIT: "]]..tostring(sec_edit)..[[": name_of_section cannot start with a number, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_EDIT: "]]..tostring(sec_edit)..[[": name_of_section cannot start with a number, it won't be used!]],"WARNING")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  if IsSecEmptyNumber then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_EMPTY: "]]..tostring(sec_empty)..[[": name_of_section cannot start with a number, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_EMPTY: "]]..tostring(sec_empty)..[[": name_of_section cannot start with a number, it won't be used!]],"WARNING")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  if IsSecEditNotFound then
    print(">>> "..H.gcNOTICE..[[ [NOTICE] SEC_EDIT: "]]..tostring(sec_edit)..[[" is NOT found, section won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_EDIT: "]]..tostring(sec_edit)..[[" is NOT found, section won't be used!]],"NOTICE")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcNOTICE..[[          Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  -- if not H.gIs_LEAN_MODE and comment ~= nil and comment ~= "" and type(comment) == "string" then
  if comment and comment ~= "" and type(comment) == "string" then
    comment = comment:gsub([[\\]],[[\]]) -- revert needed, see when loading script
    
    print(H._zBRIGHTGREEN..[[ >>> Script's ]]..H._zBLACKonYELLOW..[[ Comment ]]..H._zDEFAULT..[[: <<< ]]..H._zBRIGHTORANGE..comment..H._zDEFAULT.." >>>")
    H.Report("","[Comment] #"..item.." [["..comment.."]]")
  end
  
  if IsSecEmpty then
    My.tmp = ""
    if SectionKeep(H,sec_keep) then
      My.tmp = " to disk"
    end
    
    if not H.gIs_LEAN_MODE then
      print("                >>>"..H._zBRIGHTORANGE.." Created empty section "..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_empty..[["]]..H._zDEFAULT.."]"..My.tmp)
    end
    H.Report("","                >>> Created empty section ["..[["]]..sec_empty..[["]].."]"..My.tmp)
  end
  
  if H.gDEBUG_StopAtEachProcessing then 
    print("************************************************************************************************************************************************  STOP *****")
    H.WFAK("==============>>>>> press key for next processing...")
  end
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: Report_flush() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  H.Report_flush(true,H.THIS)
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." AFTER: Report_flush() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  
  if IsSecEmpty then
    ReplNumber = 1
    return TextFileTable, ReplNumber, ADDcount, REMOVEcount, false
    -- looping to next MXML_CHANGE_TABLE
  end
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: IsMath_Operation section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- *****************   IsMath_Operation section   ********************
  My.IsMath_Operation = false
  math_operation = H.ReturnStringFrom(math_operation)
  if math_operation == nil then math_operation = "" end
  if #math_operation > 0 then
    My.IsMath_Operation = true
  end
  --***************************************************************************************************
  
  -- *****************   text_to_add section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: text_to_add section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  if text_to_add then
    local function CheckAddString(s)
      local _,opening = s:gsub("<","<",-1)
      local _,closing = s:gsub(">",">",-1)
      local IsMissing = false
      if opening ~= closing then
        print(">>> "..H.gcWARNING..[[ [WARNING] missing '<' or '>' in "ADD" string: check your script! ]]..H._zDEFAULT)
        H.Report("",[[>>>  missing '<' or '>' in "ADD" string: check your script!]],"WARNING")
        IsMissing = true
      end
      return IsMissing
    end
    
    if type(text_to_add) == "string" then
      -- print("@@@@@@@@@@@@@@@@")
      -- print(text_to_add)
      -- print("@@@@@@@@@@@@@@@@")
      My.ADDlength = #text_to_add
      H.DEBUG_TextToAdd_print("Processing text_to_add: string of length "..My.ADDlength)
      
      -- make text_to_add into a table
      if My.ADDlength > 10000 then
        My.ADDstart = os.clock()
        if not H.gIs_LEAN_MODE then
          print(H._zBRIGHTGREEN..[[ ==> Transforming "ADD" string into a table...]]..H._zDEFAULT)
        end
      end
      
      My.IsMissing = CheckAddString(text_to_add)
      text_to_add = H.stringToTable(text_to_add:gsub([[\\]],[[\]]), H.modADDED) -- change \\ to \ in the string -- .." Z0"
      
      if My.IsMissing then
        -- -- FOR DEBUG
        -- if #text_to_add < 100 then
          -- print("    >>>>>> ")
          -- for i=1,#text_to_add do
            -- print("    >>>>>> "..text_to_add[i])
          -- end
          -- print("    >>>>>> ")
        -- end

        -- if not CheckAddString(table.concat(text_to_add)) then        
          -- -- possibly auto-corrected
          -- print(">>> "..H.gcNOTICE..[[ [NOTICE] missing '<' or '>' in "ADD" string MAY have been AUTO_CORRECTED successfully by AMUMSS! ]]..H._zDEFAULT)
          -- H.Report("",[[>>>  missing '<' or '>' in "ADD" string MAY have been AUTO_CORRECTED successfully by AMUMSS!]],"NOTICE")
        -- else
          text_to_add = {""}
        -- end
      end

      if My.ADDlength > 10000 then
        if not H.gIs_LEAN_MODE then
          print(H._zBRIGHTGREEN.."      - done in "..H.dClock(os.clock() - My.ADDstart)..H._zDEFAULT)
        end
      end
      
    elseif type(text_to_add) == "table" then
      H.DEBUG_TextToAdd_print("Processing text_to_add: table, #text_to_add = "..#text_to_add)
      if #text_to_add > 0 and text_to_add[1] then
        My.ADDstart = os.clock()
        
        My.tmpTTA = table.concat(text_to_add)
        
        if not H.gIs_LEAN_MODE then
          print(H._zBRIGHTGREEN.."    ==> Making "..H._zDEFAULT..[["ADD"]]..H._zBRIGHTGREEN.." into a multi-line table..."..H._zDEFAULT)
        end  

        My.IsMissing = CheckAddString(My.tmpTTA)
        text_to_add = H.stringToTable(My.tmpTTA:gsub([[\\]],[[\]]), H.modADDED) -- and change \\ to \ in the string -- .." Z1"
          
        if My.IsMissing then
          -- -- FOR DEBUG
          -- if #text_to_add < 100 then
            -- print("    >>>>>> ")
            -- for i=1,#text_to_add do
              -- print("    >>>>>> "..text_to_add[i])
            -- end
            -- print("    >>>>>> ")
          -- end
                  
          -- if not CheckAddString(table.concat(text_to_add)) then        
            -- -- possibly auto-corrected
            -- print(">>> "..H.gcNOTICE..[[ [NOTICE] missing '<' or '>' in "ADD" string probably AUTO_CORRECTED! ]]..H._zDEFAULT)
            -- H.Report("",[[>>>  missing '<' or '>' in "ADD" string probably AUTO_CORRECTED!]],"NOTICE")
          -- else
            text_to_add = {""}
          -- end
        end
        
        if not H.gIs_LEAN_MODE then
          print(H._zBRIGHTGREEN.."      - done in "..H.dClock(os.clock() - My.ADDstart)..H._zDEFAULT)
        end
        
      else
        text_to_add = {""}
      end
      
    else
      -- bad type: not a string or table
      text_to_add = {""}
      print(">>> "..H.gcWARNING..[[ [WARNING] "ADD" is NOT a 'string' NOR a 'table': check your script! ]]..H._zDEFAULT)
      H.Report("",[[>>>  "ADD" is NOT a 'string' NOR a 'table': check your script!]],"WARNING")
    end
  else
      text_to_add = {""}
  end
  
  My.IsTextToAdd = (text_to_add[1] ~= "")
  
  if My.IsTextToAdd then
    H.DEBUG_TextToAdd_print("END: Processing text_to_add from script: My.IsTextToAdd = "..tostring(My.IsTextToAdd))
    H.DEBUG_TextToAdd_print("END: Processing text_to_add from script: #text_to_add = "..#text_to_add)
    H.DEBUG_TextToAdd_print("END: Processing text_to_add from script: text_to_add[1] = ["..tostring(text_to_add[1]).."]")
  end
  
-- print("&&&&&&&&&&&&&&&&&&&&&&&&&")
-- for i=1,#text_to_add do
  -- if text_to_add[i] then
    -- print(text_to_add[i])
  -- end
-- end
-- print("&&&&&&&&&&&&&&&&&&&&&&&&&")
-- H.WFAK()
  -- *****************  END: text_to_add section   ********************
  
  -- *****************   value_change_table section   ********************
  --Note: value_change_table is the original to create val_change_table (the normalized table)
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: value_change_table section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  
  local val_change_table = {{"",""}} -- ,nil as 3rd and 4th strings
  -- local IsChangeTable = false
  My.IsSomeSamePropertyChangeTable = false
  My.IsNotTheSamePropertyChangeTable = false
  My.IsAllTheSameChangeTable = false
  My.IsAllChangeTableIGNORE = true
  My.IsVCTempty = false

-- printf("A0:   My.IsSomeSamePropertyChangeTable = %s",tostring(My.IsSomeSamePropertyChangeTable))
-- printf("A0: My.IsNotTheSamePropertyChangeTable = %s",tostring(My.IsNotTheSamePropertyChangeTable))
-- printf("A0:         My.IsAllTheSameChangeTable = %s",tostring(My.IsAllTheSameChangeTable))
-- printf("A0:          My.IsAllChangeTableIGNORE = %s",tostring(My.IsAllChangeTableIGNORE))
  
  if value_change_table == nil then
    val_change_table[1][1] = "IGNORE"
    val_change_table[1][2] = "IGNORE"
    --val_change_table[1][3] = nil
    My.IsVCTempty = true
  else
    if type(value_change_table) ~= "table" then
      --not a table
      -- just one word
      if value_change_table == "" then
        -- one empty word
        val_change_table[1][1] = "IGNORE"
        val_change_table[1][2] = "IGNORE"
        --val_change_table[1][3] = nil
        My.IsVCTempty = true
      else
        -- one word not empty
        -- Make it a table, we want a table!
        -- will not crash AMUMSS but will not produce a good EXML probably
        val_change_table[1][1] = value_change_table
        val_change_table[1][2] = value_change_table
        --val_change_table[1][3] = nil
        print(">>> "..H.gcWARNING..[[ [WARNING] this VALUE_CHANGE_TABLE entry is NOT a 'table of tables': check your script! ]]..H._zDEFAULT)
        H.Report("",[[>>> this VALUE_CHANGE_TABLE entry is NOT a 'table of tables': check your script!]],"WARNING")
      end
    else
      -- a table
      if type(value_change_table[1]) ~= "table" then
        -- problem, not a table of tables
        print(">>> "..H.gcWARNING..[[ [WARNING] this VALUE_CHANGE_TABLE entry is NOT a 'table of tables': check your script! ]]..H._zDEFAULT)
        H.Report("",[[>>> this VALUE_CHANGE_TABLE entry is NOT a 'table of tables': check your script!]],"WARNING")
        if H._mSERIALIZING == "Y" then
          print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
          H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
        end
        value_change_table = nil
      else
        -- already a table, let us use it
        val_change_table = value_change_table
      end
    end
  end
  
  -- if (#val_change_table > 0) and (val_change_table[1] ~= "" or val_change_table[2] ~= "") then
    -- IsChangeTable = true
  -- end
  
  -- valid unless we detect a problem below
  My.IsValidVCT = true
  
  for i=1,#val_change_table do    
    if type(val_change_table[i]) == "table" then
      val_change_table[i][1] = tostring(val_change_table[i][1])
      -- H.pv(val_change_table[i][1])
      -- H.printf("val_change_table[i][1] %d, %s",i,val_change_table[i][1])
    else
      print(">>> "..H.gcERROR..[[ [ERROR] In your script, a VALUE_CHANGE_TABLE "Property name/value" below is of incorrect type, please correct! ]]..H._zDEFAULT)
      H.Report("",[[>>> In your script, a VALUE_CHANGE_TABLE "Property name/value" below is of incorrect type, please correct!]],"ERROR")
      if H._mSERIALIZING == "Y" then
        print(">>> "..H.gcERROR..[[          Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
        H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
      end
      -- bad formed VCT
      My.IsValidVCT = false
      break
      -- if My.IsMath_Operation then
        -- val_change_table[i][1] = "0" --to prevent a crash
      -- else
        -- val_change_table[i][1] = "NIL" --to prevent a crash
      -- end
    end
    
    if val_change_table[i][1] == "nil" then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] In your script, a VALUE_CHANGE_TABLE "Property name/value" below is NIL, please correct! ]]..H._zDEFAULT)
      H.Report("",[[>>> In your script, a VALUE_CHANGE_TABLE "Property name/value" below is NIL, please correct!]],"ERROR")
      if H._mSERIALIZING == "Y" then
        print(">>> "..H.gcERROR..[[          Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
        H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
      end
      if My.IsMath_Operation then
        val_change_table[i][1] = "0" --to prevent a crash
      else
        val_change_table[i][1] = "NIL" --to prevent a crash
      end
    end
    
    val_change_table[i][2] = tostring(val_change_table[i][2])
    --H.pv(val_change_table[i][2])
    
    if val_change_table[i][2] == "nil" then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] In your script, VALUE_CHANGE_TABLE "newvalue" (for "]]..val_change_table[i][1]..[[" below) is NIL, please correct! ]]..H._zDEFAULT)
      H.Report("",[[>>> In your script VALUE_CHANGE_TABLE "newvalue" (for "]]..val_change_table[i][1]..[[" below) is NIL, please correct!]],"ERROR")
      if H._mSERIALIZING == "Y" then
        print(">>> "..H.gcERROR..[[          Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
        H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
      end
      if My.IsMath_Operation then
        val_change_table[i][2] = "NIL" --to prevent a crash
      else
        val_change_table[i][2] = "NIL" --to prevent a crash
      end
    end
    
    val_change_table[i][3] = H.trim(tostring(val_change_table[i][3]))
    
    if val_change_table[i][3] ~= "nil" then
      if type(val_change_table[i][3]) ~= "string" then
        print(">>> "..H.gcERROR..[[ [ERROR] In your script, VALUE_CHANGE_TABLE "NamedValue" (for "]]..val_change_table[i][1]..[[" below) is not a STRING, please correct! ]]..H._zDEFAULT)
        H.Report("",[[>>> In your script VALUE_CHANGE_TABLE "NamedValue" (for "]]..val_change_table[i][1]..[[" below) is not a STRING, please correct!]],"ERROR")
        val_change_table[i][3] = "NIL"  --to prevent a crash
      elseif type(tonumber(val_change_table[i][3])) == "number" then
        print(">>> "..H.gcERROR..[[ [ERROR] In your script, VALUE_CHANGE_TABLE "NamedValue" (for "]]..val_change_table[i][1]..[[" below) is a NUMBER, not a valid NamedValue, please correct! ]]..H._zDEFAULT)
        H.Report("",[[>>> In your script VALUE_CHANGE_TABLE "NamedValue" (for "]]..val_change_table[i][1]..[[" below) is a NUMBER, not a valid NamedValue, please correct!]],"ERROR")
        val_change_table[i][3] = "NIL"  --to prevent a crash
      end
    else
      val_change_table[i][3] = "NIL"  --to prevent a crash
    end
    
    if type(val_change_table[i][4]) ~= "table" then
      val_change_table[i][4] = H.trim(tostring(val_change_table[i][4]))

      if val_change_table[i][4] then
        if type(val_change_table[i][4]) ~= "string" and type(val_change_table[i][4]) ~= "number" then
          print(">>> "..H.gcERROR..[[ [ERROR] In your script, VALUE_CHANGE_TABLE "funcArg" (for "]]..val_change_table[i][2]..[[" below) is not a STRING or NUMBER, please correct! ]]..H._zDEFAULT)
          H.Report("",[[>>> In your script VALUE_CHANGE_TABLE "newvalue" (for "]]..val_change_table[i][2]..[[" below) is not a STRING or NUMBER, please correct!]],"ERROR")
          val_change_table[i][4] = ""  --to prevent a crash
        end
      else
        val_change_table[i][4] = ""  --to prevent a crash
      end
    
    else        
      if val_change_table[i][4] == "nil" then
        val_change_table[i][4] = ""  --to prevent a crash
      end
    end

    -- adjust \\ to \
    val_change_table[i][1] = strgsub(val_change_table[i][1],[[\\]],[[\]])
    val_change_table[i][2] = strgsub(val_change_table[i][2],[[\\]],[[\]])
  end
  
-- print(" ~ ~ ~ ~ ~")
-- for i=1,#val_change_table do
    -- printf("val_change_table[%d][1] = [%s]",i,tostring(val_change_table[i][1]))
    -- printf("val_change_table[%d][2] = [%s]",i,tostring(val_change_table[i][2]))
-- end
-- print(" ~ ~ ~ ~ ~")

  if My.IsValidVCT then
    --check if val_change_table contains multiple of the same [1]
    if #val_change_table > 1 then
      My.propChangeTable = strupper(val_change_table[1][1])
      
      --do not use, interferes with IsLineOffset
      --when modder used "IGNORE" intentionally
      --if not My.IsVCTempty or My.propChangeTable ~= "IGNORE" then
      
      if My.propChangeTable ~= "IGNORE" then
        for i=2,#val_change_table do
          if My.propChangeTable == strupper(val_change_table[i][1]) then
            My.IsSomeSamePropertyChangeTable = true
          else
            My.IsNotTheSamePropertyChangeTable = true
          end
        end
      end
      
-- printf("B0:   My.IsSomeSamePropertyChangeTable = %s",tostring(My.IsSomeSamePropertyChangeTable))
-- printf("B0: My.IsNotTheSamePropertyChangeTable = %s",tostring(My.IsNotTheSamePropertyChangeTable))

      My.IsAllTheSameChangeTable = (My.IsSomeSamePropertyChangeTable and not My.IsNotTheSamePropertyChangeTable)
      
-- printf("B1:         My.IsAllTheSameChangeTable = %s",tostring(My.IsAllTheSameChangeTable))
-- printf("B1:          My.IsAllChangeTableIGNORE = %s",tostring(My.IsAllChangeTableIGNORE))
  
      if My.IsSomeSamePropertyChangeTable and My.IsNotTheSamePropertyChangeTable then
        --some are the same and some are not
        --could lead to problems: REPORT
        print(">>> "..H.gcNOTICE..[[ [NOTICE] In next section of your script, some VALUE_CHANGE_TABLE "property" are duplicates, other are not, please correct! ]]..H._zDEFAULT)
        print(">>> "..H.gcNOTICE..[[          It could lead to unreliable replacements, please split into two MXML_CHANGE_TABLE sub-tables instead ]]..H._zDEFAULT)
        H.Report("",[[>>> In next section of your script, some VALUE_CHANGE_TABLE "property" are duplicates, other are not, please correct!]],"NOTICE")
        H.Report("",[[              >>> It could lead to unreliable replacements, please split into two MXML_CHANGE_TABLE sub-tables instead]])
      end
      
    end
    
    if #val_change_table > 1 and not My.IsVCTempty then
      for i=1,#val_change_table do
        if strupper(val_change_table[i][1]) ~= "IGNORE" then
          My.IsAllChangeTableIGNORE = false
          break
        end
      end
    else
      -- only one or none
      My.IsAllChangeTableIGNORE = false
    end
  else
    -- BAD syntax VCT
    val_change_table = {{"",""}} -- ,nil as 3rd and 4th strings
    val_change_table[1][1] = "IGNORE"
    val_change_table[1][2] = "IGNORE"
    --val_change_table[1][3] = nil
    My.IsVCTempty = true
  end
  
-- printf("C0: My.IsAllTheSameChangeTable = %s",tostring(My.IsAllTheSameChangeTable))
-- printf("C0:  My.IsAllChangeTableIGNORE = %s",tostring(My.IsAllChangeTableIGNORE))
  
  --  *******************************************************
  -- FROM HERE ON [value_change_table] is known as [val_change_table] (a table of sub-tables)
  --  *******************************************************
  
  -- *****************   integer_to_float section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: integer_to_float section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  if integer_to_float == nil  or integer_to_float == "" then
    integer_to_float = global_integer_to_float
  end
  integer_to_float = H.ReturnStringFrom(integer_to_float)
  integer_to_float = strupper(integer_to_float)
  
  My.IsInteger_to_floatDeclared = (integer_to_float ~= "")
  My.IsInteger_to_floatPRESERVE = (integer_to_float == "PRESERVE")
  My.IsInteger_to_floatFORCE = (integer_to_float == "FORCE")
  if My.IsInteger_to_floatDeclared and not (My.IsInteger_to_floatPRESERVE or My.IsInteger_to_floatFORCE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] INTEGER_TO_FLOAT value is incorrect, should be "", "FORCE" or "PRESERVE" ]]..H._zDEFAULT)
    H.Report(integer_to_float,[[>>> INTEGER_TO_FLOAT value is incorrect, should be "", "FORCE" or "PRESERVE"]],"WARNING")
  end
  
  -- *****************   sec_unsaved section   ********************
  if type(sec_unsaved) == "table" or type(sec_unsaved) == "number" or type(sec_unsaved) == "boolean" then
    print(">>> "..H.gcWARNING..[[ [WARNING] sec_unsaved: "]]..tostring(sec_unsaved)..[[" is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> sec_unsaved: "]]..tostring(sec_unsaved)..[[" is not a valid name_of_section STRING, it won't be used!]],"WARNING")
    sec_unsaved = ""
  else
    sec_unsaved = H.ReturnStringFrom(sec_unsaved)
  end
  
  if sec_unsaved == "error" then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_UNSAVED is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_UNSAVED is not a valid name_of_section STRING, it won't be used!]],"WARNING")
    sec_unsaved = ""
  end
  
  My.IsUnSavedSection = (sec_unsaved ~= "")
  
  if My.IsUnSavedSection and tonumber(sec_unsaved) then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_UNSAVED: "]]..tostring(sec_unsaved)..[[", name_of_section cannot start with a number, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_UNSAVED: "]]..tostring(sec_unsaved)..[[", name_of_section cannot start with a number, it won't be used!]],"WARNING")
    sec_unsaved = ""
  end
  
  My.IsSkipThisEXML_CT = false
  My.OnDisk = false
  
  if My.IsUnSavedSection then
    --check if this section name already exist in internal H.gSection list
    if H.gSection[sec_unsaved] then
      --already in H.gSection
      -- do not execute this MXML_CT
      My.IsSkipThisEXML_CT = true
      H.DEBUG_SEC_print("@@@@@ SEC_UNSAVED: Found section in internal H.gSection list")
    else
      --try to read back the lines from a file in the TOOLS\SavedSections folder using the SEC_edit name.xml
      if H.IsFileExist([[..\TOOLS\SavedSections\]]..sec_unsaved..[[.xml]]) then
        My.OnDisk = true
        -- do not execute this MXML_CT
        My.IsSkipThisEXML_CT = true
        H.DEBUG_SEC_print([[@@@@@ SEC_UNSAVED: Found section in a file in the TOOLS\SavedSections folder]])
      else
        --no such named section exist internally or externally
        H.DEBUG_SEC_print("@@@@@ SEC_UNSAVED: DID NOT find specified section: execute MXML_CT")
        
        -- do as if SEC_SAVE_TO was used
        sec_save_to = sec_unsaved
        My.IsSaveSectionTo = true
        
        -- creates bogus record for later use
        H.gSection[sec_save_to] = "???"
      end
    end    
  end
  
  if My.IsSkipThisEXML_CT then
    -- skip this MXML_CT
    My.tmp = " in Memory"
    if My.OnDisk then
      My.tmp = " on Disk"
    end
    if not H.gIs_LEAN_MODE then
      print("       >>>>> "..H._zBRIGHTORANGE.." SEC_UNSAVED named section "..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_unsaved..[["]]..H._zDEFAULT.."] exist"..My.tmp..", skipping processing")
    end
    H.Report("","       >>>>> SEC_UNSAVED named section ["..[["]]..sec_unsaved..[["]].."] exist"..My.tmp..", skipping processing")
    H.Report_flush(true,H.THIS)
    return TextFileTable, ReplNumber, ADDcount, REMOVEcount, My.IsFUNCexist
  end
  
  -- *****************   sec_save_to section   ********************
  if not My.IsUnSavedSection then
    if type(sec_save_to) == "table" or type(sec_save_to) == "number" or type(sec_save_to) == "boolean" then
      print(">>> "..H.gcWARNING..[[ [WARNING] SEC_SAVE_TO: "]]..tostring(sec_save_to)..[[" is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
      H.Report("",[[>>> SEC_SAVE_TO: "]]..tostring(sec_save_to)..[[" is not a valid name_of_section STRING, it won't be used!]],"WARNING")
      sec_save_to = ""
    else
      sec_save_to = H.ReturnStringFrom(sec_save_to)
    end
    
    if sec_save_to == "error" then
      print(">>> "..H.gcWARNING..[[ [WARNING] SEC_SAVE_TO is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
      H.Report("",[[>>> SEC_SAVE_TO is not a valid name_of_section STRING, it won't be used!]],"WARNING")
      sec_save_to = ""
    end
    
    My.IsSaveSectionTo = (sec_save_to ~= "")

    if My.IsSaveSectionTo and tonumber(sec_save_to) then
      print(">>> "..H.gcWARNING..[[ [WARNING] SEC_SAVE_TO: "]]..tostring(sec_save_to)..[[", name_of_section cannot start with a number, it won't be used! ]]..H._zDEFAULT)
      H.Report("",[[>>> SEC_SAVE_TO: "]]..tostring(sec_save_to)..[[", name_of_section cannot start with a number, it won't be used!]],"WARNING")
      sec_save_to = ""
    end
    
    if My.IsSaveSectionTo then
      -- creates bogus record for later use
      H.gSection[sec_save_to] = "???"
    end
  end
  
  -- *****************   sec_keep section   ********************
  My.IsKeepSection = SectionKeep(H,sec_keep)
  
  -- *****************   sec_edit section   ********************
  -- see before "foreach_SKWG section"
  -- *****************  END: sec_edit section   ********************
  
  -- *****************   sec_add_named section   ********************
  if type(sec_add_named) == "table" or type(sec_add_named) == "number" or type(sec_add_named) == "boolean" then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[" is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[" is not a valid name_of_section STRING, it won't be used!]],"WARNING")
    sec_add_named = ""
  else
    sec_add_named = H.ReturnStringFrom(sec_add_named)
  end
  
  if sec_add_named == "error" then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_ADD_NAMED is not a valid name_of_section STRING, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_ADD_NAMED is not a valid name_of_section STRING, it won't be used!]],"WARNING")
    sec_add_named = ""
  end
  
  My.IsUseSection_add_named = (sec_add_named ~= "")

  if My.IsUseSection_add_named and tonumber(sec_add_named) then
    print(">>> "..H.gcWARNING..[[ [WARNING] SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[", name_of_section cannot start with a number, it won't be used! ]]..H._zDEFAULT)
    H.Report("",[[>>> SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[", name_of_section cannot start with a number, it won't be used!]],"WARNING")
    sec_add_named = ""
  end
  
  if My.IsUseSection_add_named then
    --check if this section name already exist in internal H.gSection list
    if H.gSection[sec_add_named] and H.gSection[sec_add_named] ~= "???" then
      --already in H.gSection list, nothing more to do right now
      H.DEBUG_SEC_print("@@@@@ B: In SEC_add_named: '"..tostring(sec_add_named).."' already exist in internal list, nothing to do right now")
      H.DEBUG_SEC_print("@@@@@ B: SEC_add_named = ["..strsub(H.gSection[sec_add_named],1,350).."...]")
      My.IsTextToAdd = true
      
    else
      --try to read back the lines from a file in the TOOLS\SavedSections folder using the sec_add_named name.xml
      if H.IsFileExist([[..\TOOLS\SavedSections\]]..sec_add_named..[[.xml]]) then
        H.gSection[sec_add_named] = H.LoadFileData([[..\TOOLS\SavedSections\]]..sec_add_named..[[.xml]])
        H.DEBUG_SEC_print("@@@@@   B ==> H.gSection[sec_add_named] = ["..strsub(H.gSection[sec_add_named],1,150).."...]")
        H.DEBUG_SEC_print([[@@@@@ B: In SEC_add_named: Found in a file in the TOOLS\SavedSections folder using the SEC_ADD_NAMED ']]..tostring(sec_add_named)..[[.xml', ADDED to internal list]])
        My.IsTextToAdd = true
      else
        --no such named section exist
        H.DEBUG_SEC_print("@@@@@ B: In SEC_add_named: DID NOT find specified SEC_ADD_NAMED: BAD NAME?")
        print(">>> "..H.gcWARNING..[[ [WARNING] SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[" is not FOUND, it won't be used! ]]..H._zDEFAULT)
        H.Report("",[[>>> SEC_ADD_NAMED: "]]..tostring(sec_add_named)..[[" is not FOUND, it won't be used!]],"WARNING")
        My.IsUseSection_add_named = false
        H.gSection[sec_add_named] = "???"
      end
    end
  end
  -- *****************  END: sec_add_named section   ********************
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: to_remove section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- *****************   to_remove section   ********************
  to_remove = H.ReturnStringFrom(to_remove)
  to_remove = strupper(to_remove)
  
  My.IsToRemove = (to_remove ~= "")
  My.IsToRemoveLINE = (to_remove == "LINE")
  My.IsToRemoveSECTION = (to_remove == "SECTION")
  My.IsToRemoveHBOS = (to_remove == "HBOS")
  if My.IsToRemove and not (My.IsToRemoveLINE or My.IsToRemoveSECTION or My.IsToRemoveHBOS) then
    print(">>> "..H.gcWARNING..[[ [WARNING] REMOVE value is incorrect, should be "", "LINE", "SECTION" or "HBOS" ]]..H._zDEFAULT)
    H.Report(to_remove,[[>>> REMOVE value is incorrect, should be "", "LINE", "SECTION" or "HBOS"]],"WARNING")
  end
  -- *****************  END: to_remove section   ********************
  
  -- *****************   preceding_first section   ********************
  preceding_first = H.ReturnStringFrom(preceding_first)
  preceding_first = strupper(preceding_first)
  
  local IsPrecedingFirst = (preceding_first ~= "")
  
  local IsPrecedingFirstTRUE = (preceding_first == "TRUE")
  My.IsPrecedingFirstFALSE = (preceding_first == "FALSE") --only use next line
  if IsPrecedingFirst and not (IsPrecedingFirstTRUE or My.IsPrecedingFirstFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] PRECEDING_FIRST value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(preceding_first,[[>>> PRECEDING_FIRST value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  -- *****************   create_hos section   ********************
  create_hos = H.ReturnStringFrom(create_hos)
  create_hos = strupper(create_hos)
  
  My.IsCreateHOS = (create_hos ~= "")
  
  My.IsCreateHOSTRUE = (create_hos == "TRUE")
  My.IsCreateHOSFALSE = (create_hos == "FALSE") --only used on next line
  if My.IsCreateHOS and not (My.IsCreateHOSTRUE or My.IsCreateHOSFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] CREATE_HOS value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(create_hos,[[>>> CREATE_HOS value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  -- *****************   create_hoes section   ********************
  create_hoes = H.ReturnStringFrom(create_hoes)
  create_hoes = strupper(create_hoes)
  
  My.IsCreateHOES = (create_hoes ~= "")
  
  My.IsCreateHOESTRUE = (create_hoes == "TRUE")
  My.IsCreateHOESFALSE = (create_hoes == "FALSE") --only used on next line
  if My.IsCreateHOES and not (My.IsCreateHOESTRUE or My.IsCreateHOESFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] CREATE_HOES value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    H.Report(create_hoes,[[>>> CREATE_HOES value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  end
  
  if My.IsCreateHOESTRUE then
    -- turn OFF ADD
    My.IsTextToAdd = false
    -- overwrite REMOVE command
    My.IsToRemove = true
    My.IsToRemoveLINE = false
    My.IsToRemoveSECTION = true
    My.IsToRemoveHBOS = false
  end
  
  -- *****************   replace_type section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: replace_type section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  replace_type = H.ReturnStringFrom(replace_type)
  replace_type = strupper(replace_type)
  
  -- to preserve backward compatibility
  My.tmpIsADDAFTERSECTION = false
  if replace_type == "ADDAFTERSECTION" then
    My.tmpIsADDAFTERSECTION = true
    replace_type = ""
  end
  
  My.IsOrgReplace_typeEmpty = false
  if replace_type == "" then
    My.IsOrgReplace_typeEmpty = true
    replace_type = "ONCE"
  end
  
  -- IsReplaceONCEInsideSection: do like IsReplaceONCE but with GroupStartLine + 1
  local IsReplaceONCEInsideSection = (replace_type == "ONCEINSIDE")
  local IsReplaceONCE = (replace_type == "ONCE") or IsReplaceONCEInsideSection
  
  -- IsReplaceAllInsideSection: do like IsReplaceAllInSection but with GroupStartLine + 1
  local IsReplaceAllInsideSection = (replace_type == "ALLINSIDESECTION")
  local IsReplaceAllInSection = (replace_type == "ALLINSECTION") or IsReplaceAllInsideSection
  
  local IsReplaceALL = (replace_type == "ALL") -- or IsReplaceAllInSection or IsReplaceAllInsideSection

  local IsReplaceFOLLOWING = (replace_type == "FOLLOWING") -- NOT USED
  local IsReplaceRAW = (replace_type == "RAW")
  
  local IsReplace = true
  if not My.IsTextToAdd and not (IsReplaceONCE or IsReplaceONCEInsideSection or IsReplaceALL or IsReplaceAllInSection or IsReplaceAllInsideSection or IsReplaceFOLLOWING or IsReplaceRAW) then
    -- print(">>> "..H.gcWARNING..[[ [WARNING] REPLACE_TYPE value is incorrect, should only be "", "ONCE", "ALL", "ALLINSECTION", "FOLLOWING" or "RAW" ]]..H._zDEFAULT)
    -- H.Report(replace_type,[[>>> REPLACE_TYPE value is incorrect, should only be "", "ONCE", "ALL", "ALLINSECTION", "FOLLOWING" or "RAW": found]],"WARNING")
    print(">>> "..H.gcWARNING..[[ [WARNING] REPLACE_TYPE value is incorrect, should only be "", "ONCE", "ONCEINSIDE", "ALL", "ALLINSECTION", "ALLINSIDESECTION" or "RAW" ]]..H._zDEFAULT)
    H.Report(replace_type,[[>>> REPLACE_TYPE value is incorrect, should only be "", "ONCE", "ONCEINSIDE", "ALL", "ALLINSECTION", "ALLINSIDESECTION" or "RAW": found]],"WARNING")
    IsReplace = false
  end
  
  -- if IsReplaceONCEInsideSection or IsReplaceAllInsideSection then
    -- -- do as if LINE_OFFSET exist
    -- IsLineOffset = true
    -- offset = 1
  -- end
  
  if IsReplaceRAW then
    -- using RAW implies that ALL is also used
    IsReplaceALL = true
    IsReplaceONCE = false
  end
  -- print(" A:              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."]     IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
  
  -- *****************   line_offset section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: line_offset section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  line_offset = H.ReturnStringFrom(line_offset)
  
  local IsLineOffset = (line_offset ~= nil and line_offset ~= "")
  -- print("line_offset = ["..tostring(line_offset).."]")
  -- print("IsLineOffset = ["..tostring(IsLineOffset).."]")
  
  -- if IsLineOffset == true then script will use LINE_OFFSET
  
  local line_offsetNumber = 0
  if IsLineOffset then
    line_offsetNumber = (tonumber(line_offset) or math.huge)
    if IsLineOffset and line_offsetNumber == math.huge then
      print(">>> "..H.gcWARNING..[[ [WARNING] LINE_OFFSET value type is incorrect, should be "" or "+/- a number" ]]..H._zDEFAULT)
      H.Report(line_offset,[[>>> LINE_OFFSET value type is incorrect, should be "" or "+/- a number"]],"WARNING")
    end
  else
    line_offset = 0
  end
  
  local offset = 0
  local offset_sign = "+"
  if IsLineOffset then
    if line_offsetNumber < 0 then
      offset_sign = "-"
    end
    offset = math.abs(math.tointeger(line_offsetNumber))
  end
  
  if offset == 1 and (My.IsAllChangeTableIGNORE or My.IsAllTheSameChangeTable) then
    -- no need to use offset when all are IGNORE or the SAME
    IsLineOffset = false
    -- offset = 0
    IsReplaceONCEInsideSection = true
    IsReplaceONCE = true
  end
  
  -- if offset > 1 and (My.IsAllChangeTableIGNORE or My.IsAllTheSameChangeTable) then
    -- My.IsAllChangeTableIGNORE = false
    -- My.IsAllTheSameChangeTable = false
  -- end
  
  H.DEBUG_CurrentLine_print("@@@   IsLineOffset = ["..tostring(IsLineOffset).."]")
  H.DEBUG_CurrentLine_print("@@@         offset = "..offset)
  
  -- -- *****************   exml_create section   ********************
  -- exml_create = H.ReturnStringFrom(exml_create)
  -- exml_create = strupper(exml_create)
  
  -- if exml_create == "" then
    -- --default option
    -- exml_create = "TRUE"
  -- end
  
  -- H.IsEXMLcreate = (exml_create ~= "")
  
  -- H.IsEXMLcreateTRUE = (exml_create == "TRUE")
  -- H.IsEXMLcreateFALSE = (exml_create == "FALSE") --only used on next line
  -- if H.IsEXMLcreate and not (H.IsEXMLcreateTRUE or H.IsEXMLcreateFALSE) then
    -- print(">>> "..H.gcWARNING..[[ [WARNING] EXML_CREATE value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
    -- H.Report(exml_create,[[>>> EXML_CREATE value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
  -- end
-- -- H.printf("H.IsEXMLcreateTRUE = %s",tostring(H.IsEXMLcreateTRUE))
  
  -- *****************   exml_flags section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: exml_flags section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  exml_flags = strupper(H.ReturnStringFrom(exml_flags))
  
  -- if exml_flags == "" then
    -- --default option
    -- exml_flags = "ADDNEWSECTION"
  -- end
  
  -- H.IsEXMLflagREMOVE = (exml_flags == "REMOVE") -- add _remove="true"
  H.IsEXMLflagOVERWRITE = (exml_flags == "OVERWRITE") -- add _overwrite="true"
  H.IsEXMLflagUPDATESECTION = (exml_flags == "UPDATESECTION") -- keep original _id/_index
  H.IsEXMLflagADDNEWSECTION = (exml_flags == "ADDNEWSECTION") -- remove existing _id/_index and do not add one
  
  My.IsExml_flags = (exml_flags ~= "")
  if My.IsExml_flags then
    -- if not (H.IsEXMLflagREMOVE or H.IsEXMLflagOVERWRITE or H.IsEXMLflagUPDATESECTION or H.IsEXMLflagADDNEWSECTION) then
    if not (H.IsEXMLflagOVERWRITE or H.IsEXMLflagUPDATESECTION or H.IsEXMLflagADDNEWSECTION) then
      -- print(">>> "..H.gcWARNING..[[ [WARNING] EXML_FLAGS value is incorrect, should only be "", "REMOVE", "OVERWRITE", "UPDATESECTION" or "ADDNEWSECTION" ]]..H._zDEFAULT)
      -- H.Report(replace_type,[[>>> EXML_FLAGS value is incorrect, should only be "", "REMOVE", "OVERWRITE", "UPDATESECTION" or "ADDNEWSECTION"]],"WARNING")
      print(">>> "..H.gcWARNING..[[ [WARNING] EXML_FLAGS value is incorrect, should only be "", "OVERWRITE", "UPDATESECTION" or "ADDNEWSECTION" ]]..H._zDEFAULT)
      H.Report(replace_type,[[>>> EXML_FLAGS value is incorrect, should only be "", "OVERWRITE", "UPDATESECTION" or "ADDNEWSECTION"]],"WARNING")
      My.IsExml_flags = false
    end
  end
  
  -- *****************   exml_id section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: exml_id section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  H.exml_id = strupper(H.ReturnStringFrom(exml_id))
  
  if H.exml_id == "error" or H.exml_id == "sub_table" then
    --default option
    H.exml_id = ""
  end
  
  My.IsExml_id = (H.exml_id ~= "")
  
  -- *****************   exml_index section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: exml_index section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  H.exml_index = strupper(H.ReturnStringFrom(exml_index))
  
  if H.exml_index == "error" or H.exml_index == "sub_table" then
    --default option
    H.exml_index = ""
  end
  
  My.IsExml_index = (H.exml_index ~= "")
  if My.IsExml_index then
    H.exml_index = (tonumber(H.exml_index) or math.huge)
    if H.exml_index == math.huge then
      print(">>> "..H.gcWARNING..[[ [WARNING] EXML_INDEX value type is incorrect, should be "" or "a number" ]]..H._zDEFAULT)
      H.Report(line_offset,[[>>> EXML_INDEX value type is incorrect, should be "" or "a number"]],"WARNING")
      H.exml_index = ""
    end
  end
  
  -- *****************   add_option section   ********************
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: add_option section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  add_option = strupper(H.ReturnStringFrom(add_option))
  
  if My.IsTextToAdd then
    if add_option == "" then
      if My.tmpIsADDAFTERSECTION then
        --for backward compatibility from REPLACE_TYPE
        add_option = "ADDAFTERSECTION"
      else
        --default option
        add_option = "ADDAFTERLINE"
      end
    end
  end
  
  -- if add_option == "ADDATLINE" then
    -- add_option = "REPLACEATLINE" --for backward compatibility
  -- end
  
  H.IsReplaceADDBEFORESECTION = (add_option == "ADDBEFORESECTION") and My.IsTextToAdd
  H.IsReplaceADDAFTERSECTION = (add_option == "ADDAFTERSECTION") and My.IsTextToAdd
  H.IsReplaceADDAFTERLINE = (add_option == "ADDAFTERLINE") and My.IsTextToAdd
  H.IsAddATLINE = (add_option == "ADDATLINE") and My.IsTextToAdd
  H.IsReplaceATLINE = (add_option == "REPLACEATLINE") and My.IsTextToAdd
  H.IsReplaceWholeSECTION = (add_option == "REPLACEWHOLESECTION") and My.IsTextToAdd
  H.IsReplaceADDENDSECTION = (add_option == "ADDENDSECTION") and My.IsTextToAdd
  
  My.IsAddOption = (add_option ~= "")
  if My.IsAddOption then
    if My.IsTextToAdd and not (H.IsReplaceADDBEFORESECTION or H.IsReplaceADDAFTERSECTION or H.IsReplaceADDAFTERLINE or H.IsReplaceATLINE or H.IsAddATLINE or H.IsReplaceADDENDSECTION or H.IsReplaceWholeSECTION) then
      print(">>> "..H.gcWARNING..[[ [WARNING] ADD_OPTION value is incorrect, should only be "", "REPLACEatLINE", "REPLACEwholeSECTION", "ADDatLINE", "ADDafterLINE", "ADDbeforeSECTION", "ADDafterSECTION" or "ADDendSECTION" ]]..H._zDEFAULT)
      H.Report(replace_type,[[>>> ADD_OPTION value is incorrect, should only be "", "REPLACEatLINE", "REPLACEwholeSECTION", "ADDatLINE", "ADDafterLINE", "ADDbeforeSECTION, "ADDafterSECTION or ADDendSECTION"]],"WARNING")
      My.IsAddOption = false
    end
  end
  
  if H.IsReplaceWholeSECTION then
    H.IsReplaceADDAFTERSECTION = true
    My.IsToRemoveSECTION = true

    My.IsToRemoveLINE = false
    My.IsToRemoveHBOS = false
  end
  
  -- *****************   auto_gnh section   ********************
  My.IsAuto_GNH = Auto_GNH(H,auto_gnh)
  
  -- *****************   value_match section   ********************
  local val_match = {}
  My.IsValueMatch = false
  
  if value_match == nil then
    value_match = ""
  end
  
  if type(value_match) ~= 'table' then
    local val = H.ReturnStringFrom(value_match)
    -- printf("NOT TABLE: val = <%s>",val)
    val_match[1] = val
    My.IsValueMatch = (val_match[1] ~= "")
  else
    --make all non-empty members STRING
    for i=1,#value_match do
      if type(value_match[i]) == "table" then
        if #value_match[i] == 2 then
          -- looks like with have a RANGE
          -- printf("   value_match[%d] = <%s>",i,value_match[i])
        
          val_match[i] = value_match[i]
          -- printf("   type(val_match[%d]) = <%s>",i,type(val_match[i]))

          My.IsValueMatch = true
        else
          print(">>> "..H.gcWARNING..[[ [WARNING] VALUE_MATCH SUB-TABLE value must have two arguments ]]..H._zDEFAULT)
          H.Report(replace_type,[[>>> VALUE_MATCH SUB-TABLE value must have two arguments]],"WARNING")          
        end
      else
        local val = H.ReturnStringFrom(value_match[i])
        -- printf("TABLE: val[%d] = <%s>",i,val)

        if val ~= "" then
          val_match[i] = val
          My.IsValueMatch = true
        end
      end
    end
  end
  
  for i=1,#val_match do
    local vm = val_match[i]
    if type(vm) == "table" then
      -- check if members are numbers or string numbers
      for j=1,#vm do
        if #vm == 2 then
          local vmType = type(vm[j])
          if vmType == "string" or vmType == "number" then
            -- OK
          else
            print(">>> "..H.gcWARNING..[[ [WARNING] VALUE_MATCH SUB-TABLE values must be STRING or NUMBER ]]..H._zDEFAULT)
            H.Report(replace_type,[[>>> VALUE_MATCH SUB-TABLE value must be STRING or NUMBER]],"WARNING")          
          end
        end
      end
    else
      local IsRegEx = H.IsExpressionRegular(vm)
      if IsRegEx then
        -- one is regex, IsReplaceALL is needed
        IsReplaceALL = true
        IsReplaceONCE = false
        -- print(" B:              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."]     IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
      end
      
      -- THIS would be more for VCT case
      -- if (strsub(vm,1,1) == "{" and strsub(vm,1,3) ~= "{:}" and strsub(vm,-1,-1) ~= "}") or (strsub(vm,1,1) ~= "{" and strsub(vm,-1,-1) == "}" and strsub(vm,-1,-3) ~= "{:}") then
        -- print(">>> "..H.gcWARNING..[[ [WARNING] VALUE_MATCH value ]]..vm..[[ is incorrect.  Inconsistent use of curly brackets {} ]]..H._zDEFAULT)
        -- H.Report(replace_type,[[>>> VALUE_MATCH value ]]..vm..[[ is incorrect.  Inconsistent use of curly brackets {}]],"WARNING")
      -- end
    end
    -- here, we keep val_match[i] original value
  end
  
  if My.IsValueMatch then
    --pre-process all val_match
    local v_match = {}
    for i=1,#val_match do
      local v = val_match[i]
      if type(v) == "table" then
        if #v == 2 then
          for j=1,2 do
            v[j] = tonumber(v[j]) -- make it a number when a string
          end
          
          -- make RANGE smaller to larger
          if v[1] > v[2] then
            v[1],v[2] = v[2],v[1]
          end
          
          v_match[i] = {}
          v_match[i][1] = v --the original table
          v_match[i][2] = v
          v_match[i][3] = true -- always numbers
          v_match[i][4] = false -- we do not care if integer or not
          v_match[i][5] = false -- no regex
        end
      else
        v = v:gsub([[\\]],[[\]]):gsub([[//]],[[/]]) -- :gsub([[\]],[[/]]) cannot use here, HG uses BOTH \ and / !!!
        local value_matchIsNumber, value_matchIsInteger = CheckValueType(v,false)
        
        local vm,IsRegEx = H.makeRegExUppercase(v)
        -- printf("vm = [%s], IsRegEx = [%s]",vm,tostring(IsRegEx))        
        v_match[i] = {}
        v_match[i][1] = v --the original
        v_match[i][2] = vm --the cleaned value
        v_match[i][3] = value_matchIsNumber
        v_match[i][4] = value_matchIsInteger
        v_match[i][5] = IsRegEx
        
        H.IsKWpattern = H.IsKWpattern or IsRegEx
        
        -- print(" original: v_match["..i.."][1] = ["..v_match[i][1].."]")
        -- print("       vm: v_match["..i.."][2] = ["..v_match[i][2].."]")
        -- print(" IsNumber: v_match["..i.."][3] = ["..tostring(v_match[i][3]).."]")
        -- print("IsInteger: v_match["..i.."][4] = ["..tostring(v_match[i][4]).."]")
        -- print("  IsRegEx: v_match["..i.."][5] = ["..tostring(v_match[i][5]).."]")
        -- print("=====")
      end
    end
    
    -- --check for mixed STRING and NUMBER
    -- local IsMixedValues = false
    -- for i=2,#v_match do
      -- if v_match[i-1][3] ~= v_match[i][3] then
        -- IsMixedValues = true
        -- break
      -- end
    -- end
    
    -- CAUSES problems when we really want to use both
    -- if IsMixedValues then
      -- print(">>> "..H.gcWARNING..[[ [WARNING] MIXED use of STRING and NUMBER, all will be considered STRING ]]..H._zDEFAULT)
      -- H.Report(replace_type,[[>>> MIXED use of STRING and NUMBER, all will be considered STRING]],"WARNING")
      -- for i=1,#v_match do
        -- v_match[i][3] = false
      -- end
    -- end
    
    val_match = v_match
  end
  
  --  *******************************************************
  -- FROM HERE ON [value_match] is known as [val_match] (a table)
  --  *******************************************************
  
  -- *****************   value_match_type section   ********************
  value_match_type = H.ReturnStringFrom(value_match_type)
  value_match_type = strupper(value_match_type)
  
  local IsValueMatchType = (value_match_type ~= "")
  local IsValueMatchTypeNumber = (value_match_type == "NUMBER")
  local IsValueMatchTypeString = (value_match_type == "STRING")
  
  if My.IsValueMatch and IsValueMatchType and not (IsValueMatchTypeNumber or IsValueMatchTypeString) then
    print(">>> "..H.gcWARNING..[[ [WARNING] VALUE_MATCH_TYPE value is incorrect, should be "", "NUMBER" or "STRING" ]]..H._zDEFAULT)
    H.Report(value_match_type,[[>>> VALUE_MATCH_TYPE value is incorrect, should be "", "NUMBER" or "STRING"]],"WARNING")
    IsValueMatchType = false
  end
  
  -- *****************   value_match_options section   ********************
  value_match_options = H.ReturnStringFrom(value_match_options)
  
  if value_match_options == "" then
    value_match_options = "="
  end
  local IsValueMatchOptions = true
  
  value_match_options = strupper(value_match_options)
  local IsValueMatchOptionsMatch = (value_match_options == "=")
  local IsValueMatchOptionsNoMatch = (value_match_options == "~=")
  local IsValueMatchOptionsLSS = (value_match_options == "<")
  local IsValueMatchOptionsLEQ = (value_match_options == "<=")
  local IsValueMatchOptionsGTR = (value_match_options == ">")
  local IsValueMatchOptionsGEQ = (value_match_options == ">=")
  -- print("IsValueMatchOptions = "..tostring(IsValueMatchOptions))
  -- print("IsValueMatchOptionsLSS = "..tostring(IsValueMatchOptionsLSS))
-- H.WFAK("value_match_options")
  if My.IsValueMatch and IsValueMatchOptions
      and not (IsValueMatchOptionsMatch
            or IsValueMatchOptionsNoMatch
            or IsValueMatchOptionsLSS
            or IsValueMatchOptionsLEQ
            or IsValueMatchOptionsGTR
            or IsValueMatchOptionsGEQ) then
    print(">>> "..H.gcWARNING..[[ [WARNING] VALUE_MATCH_OPTIONS value is incorrect, should be "", "=", "~=", "<", "<=", ">" or ">=" ]]..H._zDEFAULT)
    H.Report(IsValueMatchOptions,[[>>> VALUE_MATCH_OPTIONS value is incorrect, should be "", "=", "~=", "<", "<=", ">" or ">="]],"WARNING")
    IsValueMatchOptions = false
  end
  
  for i=1,#val_match do
    if not val_match[i][3] and (
                 IsValueMatchOptionsLSS
              or IsValueMatchOptionsLEQ
              or IsValueMatchOptionsGTR
              or IsValueMatchOptionsGEQ) then
      print(">>> "..H.gcWARNING..[[ [WARNING] Incorrect value of VALUE_MATCH_OPTIONS used with VALUE_MATCH, should be "", "=" or "~=" ]]..H._zDEFAULT)
      H.Report(IsValueMatchOptions,[[>>> Incorrect value of VALUE_MATCH_OPTIONS used with VALUE_MATCH, should be "", "=" or "~="]],"WARNING")
      IsValueMatchOptions = false
      break
    end
  end
  
  --***************************************************************************************************
  local function CheckValueMatchOptions(H,val_match,exstring,iGLine)
    --doing an AND of all the VALUE_MATCH fields
    local p = function() end
-- local p = print
    
    local matchResult = false
    
    if exstring == nil then
      return matchResult
    end
    
    local valueIsNumber, valueIsInteger = CheckValueType(exstring,false)
    p("=====")
    p(" - valueIsNumber = ["..tostring(valueIsNumber).."]")
    p(" - valueIsInteger = ["..tostring(valueIsInteger).."]")
    
    if not valueIsNumber then
      exstring = strupper(exstring)
    end
    p(" - exstring = ["..exstring.."]")
    
    local trace = ""
    for i=1,#val_match do
      local V = val_match[i]
      
      local vm = V[2]
      local value_matchIsNumber = V[3]
      local value_matchIsInteger = V[4]
      local IsRegEx = V[5]
      
      p(" - original = ["..tostring(V[1]).."]")
      p("   - vm = ["..tostring(vm).."]")
      p("   - value_matchIsNumber = ["..tostring(value_matchIsNumber).."]")
      p("   - value_matchIsInteger = ["..tostring(value_matchIsInteger).."]")
      p("   - IsRegEx = ["..tostring(IsRegEx).."]")
      
      -- we need vm without <>
      local IsNumber = false
      local IsString = false
      if valueIsNumber and value_matchIsNumber then
        --ok to compare as NUMBER
        IsNumber = true
        if not valueIsInteger then
          v = H.string_round(exstring)
          vm = H.string_round(vm)
        end
      elseif not valueIsNumber and not value_matchIsNumber then
        --ok to compare as STRING
        IsString = true
      else
        --cannot compare
        matchResult = false
        break
      end
      
      p("   - IsString = ["..tostring(IsString).."]")
      p("   - IsNumber = ["..tostring(IsNumber).."]")
      
      -- true or ? == true
      -- false and ? == false
      
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end

      if IsString then
        if IsRegEx then
          p("     - vm = ["..vm.."]")
          p("     -  v = ["..exstring.."]")
          --let us use lua regular pattern matching
          if IsValueMatchOptionsMatch then
            trace = trace.."A"
            matchResult = matchResult or (strfind(exstring,vm) ~= nil)
            -- if matchResult then
              -- p("exstring = ["..exstring.."]")
              -- p("vm = [["..vm.."]]")
              -- p("match col = ["..tostring(strfind(exstring,vm)).."]")
            -- end
          elseif IsValueMatchOptionsNoMatch then
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end
            trace = trace.."B"
            matchResult = matchResult or (strfind(exstring,vm) ~= nil)
          end
        else
          if IsValueMatchOptionsMatch then
            trace = trace.."C"
            matchResult = matchResult or (exstring == vm)
          elseif IsValueMatchOptionsNoMatch then
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end
            trace = trace.."D"
            matchResult = matchResult or (exstring == vm)
          end
        end
        
      elseif IsNumber then
        if type(vm) == "table" then
          -- a RANGE
          if IsValueMatchOptionsMatch then
            trace = trace.." table MATCH "
            matchResult = matchResult or ( tonumber(exstring) >= tonumber(vm[1]) and tonumber(exstring) <= tonumber(vm[2]) )
          elseif IsValueMatchOptionsNoMatch then
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end
            trace = trace.." table NO MATCH "
            -- matchResult = matchResult or ( tonumber(exstring) < tonumber(vm[1]) or tonumber(exstring) > tonumber(vm[2]) )
            matchResult = matchResult or ( tonumber(exstring) >= tonumber(vm[1]) and tonumber(exstring) <= tonumber(vm[2]) )
          end
          
        else
          if IsValueMatchOptionsMatch then
            trace = trace.."G"
            matchResult = matchResult or (tonumber(exstring) == tonumber(vm))
          elseif IsValueMatchOptionsNoMatch then
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end
            trace = trace.."H"
            -- matchResult = not matchResult and (tonumber(exstring) ~= tonumber(vm))
            matchResult = matchResult or (tonumber(exstring) == tonumber(vm))
          elseif IsValueMatchOptionsLSS then
            trace = trace.."I"
            matchResult = matchResult or (tonumber(exstring) < tonumber(vm))
          elseif IsValueMatchOptionsLEQ then
            trace = trace.."J"
            matchResult = matchResult or (tonumber(exstring) <= tonumber(vm))
          elseif IsValueMatchOptionsGTR then
            trace = trace.."K"
            matchResult = matchResult or (tonumber(exstring) > tonumber(vm))
          elseif IsValueMatchOptionsGEQ then
            trace = trace.."L"
            matchResult = matchResult or (tonumber(exstring) >= tonumber(vm))
          end
        end
      end
      
      p("   - matchResult = ["..tostring(matchResult).."]")
      if (matchResult and not IsValueMatchOptionsNoMatch) then
        trace = trace.." then break "
        break
      end
    end --for i=1,#val_match do
    
-- IMPORTANT: for NOMATCH, we try to match AND reverse the answer at the end
    if IsValueMatchOptionsNoMatch then
      matchResult = not matchResult
    end
    
    p("===== TRACE = "..trace)
    -- printf("%6d: matchResult = %s (%s): %s",iGLine,tostring(matchResult),trace,exstring)
    return matchResult
  end
  --***************************************************************************************************
  
  -- *****************   notice_off section   ********************
  notice_off = H.ReturnStringFrom(notice_off)
  notice_off = strupper(notice_off)
  if notice_off == "" then
    notice_off = "FALSE" -- default
  end
  
  local IsNotice_off = (notice_off ~= "")
  
  local IsNotice_offTRUE = (notice_off == "TRUE")
  local IsNotice_offFALSE = (notice_off == "FALSE")
  if IsNotice_off and not (IsNotice_offTRUE or IsNotice_offFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] NOTICE_OFF value is incorrect, should be "", "TRUE", true or "FALSE", false ]]..H._zDEFAULT)
    H.Report(notice_off,[[>>> NOTICE_OFF value is incorrect, should be "", "TRUE", true or "FALSE", false]],"WARNING")
    IsNotice_off = false
  else
    IsNotice_off = IsNotice_offTRUE
  end
  
  -- *****************   mainSection section   ********************
  mainSection = H.ReturnStringFrom(mainSection)
  mainSection = strupper(mainSection)
  if mainSection == "" then
    mainSection = "FALSE" -- default
  end
  
  H.IsMainSection = (mainSection ~= "")
  
  H.IsMainSectionTRUE = (mainSection == "TRUE")
  H.IsMainSectionFALSE = (mainSection == "FALSE")
  if H.IsMainSection and not (H.IsMainSectionTRUE or H.IsMainSectionFALSE) then
    print(">>> "..H.gcWARNING..[[ [WARNING] MAIN_SECTION value is incorrect, should be "", "TRUE", true or "FALSE", false ]]..H._zDEFAULT)
    H.Report(notice_off,[[>>> NOTICE_OFF value is incorrect, should be "", "TRUE", true or "FALSE", false]],"WARNING")
    H.IsMainSection = false
  else
    H.IsMainSection = H.IsMainSectionTRUE
  end
  
  -- DISABLE MAIN_SECTION
  H.IsMainSection = false

  -- *****************   subLevel section   ********************
  
  -- Wbertro: COULD BE MADE SIMILAR TO SECTION_ACTIVE: number or table of numbers
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: subLevel section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  subLevel = H.ReturnStringFrom(subLevel)
  
  H.IsSubLevel = (subLevel ~= nil and subLevel ~= "")
  -- print("subLevel = ["..tostring(subLevel).."]")
  -- print("IsSubLevel = ["..tostring(H.IsSubLevel).."]")
  
  H.subLevelNumber = 0
  if H.IsSubLevel then
    H.subLevelNumber = (math.abs(tonumber(subLevel)) or math.huge)
    if H.IsSubLevel and H.subLevelNumber == math.huge then
      print(">>> "..H.gcWARNING..[[ [WARNING] SUBLEVEL value type is incorrect, should be "" or a "number" ]]..H._zDEFAULT)
      H.Report(subLevel,[[>>> SUBLEVEL value type is incorrect, should be "" or a "number"]],"WARNING")
    end
  else
    H.subLevelNumber = -math.huge -- no restriction on level
  end
  
  -- -- DISABLED for now
  -- H.IsSubLevel = false
  
  H.DEBUG_CurrentLine_print("@@@     IsSubLevel = ["..tostring(H.IsSubLevel).."]")
  H.DEBUG_CurrentLine_print("@@@ subLevelNumber = "..H.subLevelNumber)
  
  -- *****************   special_key_words section   ********************
  local spec_key_words = {}
  local IsSpecialKeyWords = false
  local DoEmptyTest = true
  
  local special_key_wordsBadTable = false
  if special_key_words == nil then
    H.pv("special_key_words is nil")
    spec_key_words[1] = ""
    spec_key_words[2] = ""
    DoEmptyTest = false
  else
    if type(special_key_words) ~= "table" then
      H.pv("special_key_words is not a table")
      if special_key_words == "" then
        --nothing to do
        DoEmptyTest = false
      else
        --Not a table AND only one value: problem
        H.pv("special_key_words == Only one value, problem!")
        spec_key_words[1] = special_key_words
      end
    else
      if type(special_key_words[1]) == "table" then
        --problem
        special_key_wordsBadTable = true
        
      else
        --already a simple table, use it
        H.pv("special_key_words is a table")
        spec_key_words = special_key_words
      end
    end
  end
  
  -- --to remove empty words
  -- local tempTable = {}
  -- for i=1,#spec_key_words do
    -- if spec_key_words[i] ~= "" then
      -- tempTable[i] = strgsub(spec_key_words[i],[[\\]],[[\]])
    -- end
  -- end
  -- spec_key_words = tempTable
  
  if special_key_wordsBadTable then
    print("")
    print(">>> "..H.gcWARNING..[[ [WARNING] SPECIAL_KEY_WORDS first entry is a table, in your script ]]..H._zDEFAULT)
    H.Report("",[[>>> SPECIAL_KEY_WORDS first entry is a table, in your script]],"WARNING")
    if H._mSERIALIZING == "Y" then
      print(">>> "..H.gcWARNING..[[         Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS ]]..H._zDEFAULT)
      H.Report("",[[>>> Check SerializedScript.lua (if it was generated) to see how your script shows to AMUMSS]],"WARNING")
    end
  end
  
  if DoEmptyTest and #spec_key_words > 0 then
    if (#spec_key_words >= 2 and #spec_key_words%2 == 0) then
      IsSpecialKeyWords = true
    end
    
    if #spec_key_words == 1 then
      --only one spec_key_words: problem
      print("")
      print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS will be IGNORED: ONLY ONE (name or value).  Please correct your script! "..H._zDEFAULT)
      H.Report("","SPECIAL_KEY_WORDS will be IGNORED: ONLY ONE (name or value).  Please correct your script!","WARNING")
    elseif #spec_key_words%2 ~= 0 then
      --odd number of spec_key_words: problem
      print("")
      print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS will be IGNORED: ODD number of (name or value).  Please correct your script! "..H._zDEFAULT)
      H.Report("","SPECIAL_KEY_WORDS will be IGNORED: ODD number of (name or value).  Please correct your script!","WARNING")
    end
    
    -- if IsSpecialKeyWords and (spec_key_words[1] == "" or spec_key_words[2] == "") then
      -- --one or both keywords are empty
      -- print("")
      -- print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS will be IGNORED: empty string found.  Please correct your script!"..H._zDEFAULT)
      -- H.Report("","SPECIAL_KEY_WORDS will be IGNORED: empty string found.  Please correct your script!","WARNING")
    -- end
    
    if DoEmptyTest then
      local EmptyWord = false
      for i=1,#spec_key_words,2 do
        if spec_key_words[i] == "" then
          EmptyWord = true
          break
        end
      end
      
      if IsSpecialKeyWords and EmptyWord then
        --at least one keyword is empty
        print("")
        print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS: at least one empty string found. "..H._zDEFAULT)
        H.Report("","SPECIAL_KEY_WORDS: at least one empty string found.","WARNING")
        spec_key_words = {"",""}
        IsSpecialKeyWords = false
      end
    end
    
  end
  
  for i=1,#spec_key_words do
    if spec_key_words[i] == nil then
      print("")
      print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS are IGNORED: at least one NIL value found.  Please correct your script! "..H._zDEFAULT)
      H.Report("","SPECIAL_KEY_WORDS are IGNORED: at least one NIL value found.  Please correct your script!","WARNING")
      spec_key_words = {"",""}
      IsSpecialKeyWords = false
      break
    elseif type(spec_key_words[i]) ~= "string" then
      if type(spec_key_words[i]) == "number" then
        -- make numbers into strings
        spec_key_words[i] = tostring(spec_key_words[i])
      else
        print("")
        print(">>> "..H.gcWARNING.." [WARNING] SPECIAL_KEY_WORDS are IGNORED: at least one NIL value found.  Please correct your script! "..H._zDEFAULT)
        H.Report("","SPECIAL_KEY_WORDS are IGNORED: at least one NIL value found.  Please correct your script!","WARNING")
        spec_key_words = {"",""}
        IsSpecialKeyWords = false
        break
      end
    else
      if spec_key_words[i] ~= "" then
        H.IsKWpattern = H.IsKWpattern or H.IsExpressionRegular(spec_key_words[i])
  -- print(spec_key_words[i])
        spec_key_words[i] = spec_key_words[i]:gsub([[\\]],[[\]]):gsub([[//]],[[/]]) -- :gsub([[/]],[[\]]) cannot use this last one, HG uses BOTH \ and / !!!
  -- print(spec_key_words[i])
      end
    end
    
    spec_key_words[i] = spec_key_words[i]:gsub("^%^(.+)%$$","%1") -- remove ^ and $ anchors, if any
  end
  
  local EmptySpecialKeyWords = ""
  if DoEmptyTest then
    EmptySpecialKeyWords = " empty words"
  end
  H.pv("# spec_key_words = "..#spec_key_words..EmptySpecialKeyWords)
  H.pv(GetSpecKeyWordsInfo(H,spec_key_words))
  
  --  *******************************************************
  -- FROM HERE ON [special_key_words] is known as [spec_key_words] (a table)
  --  *******************************************************
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: preceding_key_words section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- *****************   preceding_key_words section   ********************
  H.IsPrecedingKeyWords = true
  H.IsOnePrecedingWordOnly = false
  H.FirstPrecedingWordNotEmpty = 0
  
  if preceding_key_words == nil then preceding_key_words = "" end
  
  H.prec_key_words = {{}}
  if type(preceding_key_words) == "string" then
    -- just one string
    -- Make it a table of sub-table of strings
    -- print("PKW_A: a string")
    H.prec_key_words[1][1] = preceding_key_words
    -- H.IsOnePrecedingWordOnly = true
    
  elseif type(preceding_key_words) == "table" then
    -- a table
    if type(preceding_key_words[1]) == "string" then
      -- a table of strings
      -- print("PKW_B: a table of strings")
      -- make it a table of sub-table of strings
      H.prec_key_words[1] = preceding_key_words
      
    elseif type(preceding_key_words[1]) == "table" then
      -- a table of sub-tables of strings
      -- print("PKW_C: a table of sub-tables")
      H.prec_key_words = preceding_key_words
      -- H.IsPrecedingKeyWords = true
      
    elseif preceding_key_words[1] == nil then
      -- skip, empty sub-table
    else
      print(">>> "..H.gcWARNING.." [WARNING] PRECEDING_KEY_WORDS are IGNORED: not a valid form.  Please correct your script! "..H._zDEFAULT)
      H.Report("","PRECEDING_KEY_WORDS are IGNORED: not a valid form.  Please correct your script!","WARNING")
      H.IsPrecedingKeyWords = false
    end
  else
    print(">>> "..H.gcWARNING.." [WARNING] PRECEDING_KEY_WORDS are IGNORED: not STRING or TABLE form.  Please correct your script! "..H._zDEFAULT)
    H.Report("","PRECEDING_KEY_WORDS are IGNORED: not STRING or TABLE form.  Please correct your script!","WARNING")
    H.IsPrecedingKeyWords = false
  end
  
  if H.IsPrecedingKeyWords then
    --to remove empty words
    local tempTable = {{}}
    -- print("#H.prec_key_words = "..#H.prec_key_words)
    for j=1,#H.prec_key_words do
      -- printf("   #H.prec_key_words[%d] = %d",j,#H.prec_key_words[j])
      for i=1,#H.prec_key_words[j] do
        if type(H.prec_key_words[j][i]) == "number" then
          H.prec_key_words[j][i] = tostring(H.prec_key_words[j][i])
        end
        if H.prec_key_words[j][i] and H.prec_key_words[j][i] ~= "" then
          H.IsKWpattern = H.IsKWpattern or H.IsExpressionRegular(H.prec_key_words[j][i])
          -- printf("      H.prec_key_words[%d][%d] = [%s]",j,i,H.prec_key_words[j][i])
          local tmp = H.prec_key_words[j][i]:gsub([[\\]],[[\]]):gsub([[//]],[[/]]) -- :gsub([[/]],[[\]]) cannot use this last one, HG uses BOTH \ and / !!!
          tmp = tmp:gsub("^%^(.+)%$$","%1") -- remove ^ and $ anchors
          -- printf("      tmp = [%s]",tmp)
          if tempTable[j] == nil then
            tempTable[j] = {}
          end
          tempTable[j][i] = tmp
        end
      end
    end
    H.prec_key_words = tempTable
  end
  
  if H.prec_key_words[1][1] == nil or H.prec_key_words[1][1] == "" then
    -- H.IsOnePrecedingWordOnly = false
    H.IsPrecedingKeyWords = false
  -- else
    -- -- H.IsPrecedingKeyWords = true
    -- H.FirstPrecedingWordNotEmpty = 1
  end
  
  -- --one or many words
  -- --maybe empty or not
  -- if #H.prec_key_words[1] > 1 then
    -- H.IsOnePrecedingWordOnly = false
    -- H.FirstPrecedingWordNotEmpty = 1
    -- H.IsPrecedingKeyWords = true
  -- elseif #H.prec_key_words[1] == 1 then
    -- --only one word
    -- H.IsOnePrecedingWordOnly = true
    -- H.IsPrecedingKeyWords = true
    -- H.FirstPrecedingWordNotEmpty = 1
  -- else
    -- -- H.IsPrecedingKeyWords = false
    -- H.prec_key_words[1][1] = ""
  -- end

  -- H.printf("==> H.IsPrecedingKeyWords = %s",tostring(H.IsPrecedingKeyWords))
  -- H.printf("  PKW:  #H.prec_key_words = %s",tostring(#H.prec_key_words))
  -- H.printf("     type(H.prec_key_words) = %s",type(H.prec_key_words))
  -- H.printf("  PKW: #H.prec_key_words[1] = %s",tostring(#H.prec_key_words[1]))
  -- H.printf("     type(H.prec_key_words[1]) = %s",type(H.prec_key_words[1]))
  -- H.printf("   H.prec_key_words[1][1] = [%s]",tostring(H.prec_key_words[1][1]))
  -- H.printf("     type(H.prec_key_words[1][1]) = %s",type(H.prec_key_words[1][1]))
  -- H.printf("  PKW list: %s",GetPrecKeyWordsInfo(H.prec_key_words[1]))

  --  *******************************************************
  -- FROM HERE ON [preceding_key_words] is known as [H.prec_key_words] (a table)
  --  *******************************************************
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: after_key_words section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- *****************   after_key_words section   ********************
  H.IsAfterKeyWords = true
  -- H.IsOneAfterWordOnly = false
  -- H.FirstAfterWordNotEmpty = 0
  
  if after_key_words == nil then after_key_words = "" end
  
  H.a_key_words = {}
  if type(after_key_words) == "string" then
    -- print("AKW_A: a string")
    -- Make it a table strings
    H.a_key_words[1] = after_key_words
    -- H.IsOneAfterWordOnly = true
    
  elseif type(after_key_words) == "table" then
    -- a table
    if type(after_key_words[1]) == "string" then
      -- print("AKW_B: a table of strings")
      -- make it a table of strings
      for i=1,#after_key_words do
        H.a_key_words[#H.a_key_words+1] = after_key_words[i]
      end
      
    -- elseif type(after_key_words[1]) == "table" then
      -- -- a table of sub-tables of strings
      -- -- print("AKW_C: a table of sub-tables")
      -- H.a_key_words = after_key_words
      -- -- H.IsAfterKeyWords = true
      
    -- elseif after_key_words[1] == nil then
      -- -- skip, empty sub-table
    else
      print(">>> "..H.gcWARNING.." [WARNING] AKW are IGNORED: not a valid form.  Please correct your script! "..H._zDEFAULT)
      H.Report("","AKW are IGNORED: not a valid form.  Please correct your script!","WARNING")
      H.IsAfterKeyWords = false
    end
  else
    print(">>> "..H.gcWARNING.." [WARNING] AKW are IGNORED: not STRING or TABLE form.  Please correct your script! "..H._zDEFAULT)
    H.Report("","AKW are IGNORED: not STRING or TABLE form.  Please correct your script!","WARNING")
    H.IsAfterKeyWords = false
  end
  
  if H.IsAfterKeyWords then
    --to remove empty words
    local tempTable = {}
    -- print("  #H.a_key_words = "..#H.a_key_words)
    for j=1,#H.a_key_words do
      -- printf("    #H.a_key_words[%d] = %d",j,#H.a_key_words[j])
      -- for i=1,#H.a_key_words[j] do
        if type(H.a_key_words[j]) == "number" then
          H.a_key_words[j] = tostring(H.a_key_words[j])
        end
        if H.a_key_words[j] and H.a_key_words[j] ~= "" then
          H.IsKWpattern = H.IsKWpattern or H.IsExpressionRegular(H.a_key_words[j])
          -- printf("      H.a_key_words[%d] = [%s]",j,H.a_key_words[j])
          local tmp = H.a_key_words[j]:gsub([[\\]],[[\]]):gsub([[//]],[[/]]) -- :gsub([[/]],[[\]]) cannot use this last one, HG uses BOTH \ and / !!!
          tmp = tmp:gsub("^%^(.+)%$$","%1") -- remove ^ and $ anchors
          -- printf("      tmp = [%s]",tmp)
          -- if tempTable[j] == nil then
            -- tempTable[j] = {}
          -- end
          tempTable[j] = tmp
        end
      -- end
    end
    H.a_key_words = tempTable
  end
  
  if H.a_key_words[1] == nil or H.a_key_words[1] == "" then
    H.IsAfterKeyWords = false
  end
  
  -- H.printf("==> H.IsAfterKeyWords = %s",tostring(H.IsAfterKeyWords))
  -- H.printf("  AKW:  #H.a_key_words = %s",tostring(#H.a_key_words))
  -- H.printf("     type(H.a_key_words) = %s",type(H.a_key_words))
  -- H.printf("     type(H.a_key_words[1]) = %s",type(H.a_key_words[1]))
  -- H.printf("  AKW list: %s",GetPrecKeyWordsInfo(H.a_key_words))
  
  --  *******************************************************
  -- FROM HERE ON [after_key_words] is known as [H.a_key_words] (a table)
  --  *******************************************************
  
  -- *****************   section_up section   ********************
  if section_up == nil then
    section_up = 0
  else
    if type(section_up) ~= "number" then
      print(">>> "..H.gcWARNING.." [WARNING] SECTION_UP is not a proper number, please correct your script! "..H._zDEFAULT)
      H.Report("",">>> SECTION_UP is not a proper number, please correct your script!","WARNING")
      section_up = 0
    end
  end
  section_up = math.tointeger(math.abs(tonumber(section_up)))
  H.pv("section_up = "..section_up)
  -- ***************** END: section_up section   ********************
  
  -- *****************   section_up_special section   ********************
  if section_up_special == nil then
    section_up_special = 0
  else
    if type(section_up_special) ~= "number" then
      print(">>> "..H.gcWARNING.." [WARNING] SECTION_UP_SPECIAL is not a proper number, please correct your script! "..H._zDEFAULT)
      H.Report("",">>> SECTION_UP_SPECIAL is not a proper number, please correct your script!","WARNING")
      section_up = 0
    end
  end
  section_up_special = math.tointeger(math.abs(tonumber(section_up_special)))
  H.pv("section_up_special = "..section_up_special)
  -- ***************** END: section_up_special section   ********************
  
  -- *****************   section_up_preceding section   ********************
  -- NOT USED >>> DISABLED
  --this line effectively deactivates SECTION_UP_PRECEDING
  section_up_preceding = 0
  
  if section_up_preceding == nil then
    section_up_preceding = 0
  else
    if type(section_up_preceding) ~= "number" then
      print(">>> "..H.gcWARNING.." [WARNING] SECTION_UP_PRECEDING is not a proper number, please correct your script! "..H._zDEFAULT)
      H.Report("",">>> SECTION_UP_PRECEDING is not a proper number, please correct your script!","WARNING")
      section_up = 0
    end
  end
  section_up_preceding = math.tointeger(math.abs(tonumber(section_up_preceding)))
  H.pv("section_up_preceding = "..section_up_preceding)
  -- ***************** END: section_up_preceding section   ********************
  
  -- *****************   where_key_words section   ********************
  local WhereKeyWords = {{"",""}}
  local IsWhereKeyWords = false
  
  if where_key_words == nil or where_key_words == "" then
    WhereKeyWords[1][1] = "IGNORE"
    WhereKeyWords[1][2] = "IGNORE"
  else
    if type(where_key_words) ~= "table" then
      --not a table, make it a table
      print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SECTION is not a proper table of tables, please correct your script! "..H._zDEFAULT)
      H.Report("",">>> WHERE_IN_SECTION is not a proper table of tables, please correct your script!","WARNING")
      WhereKeyWords[1][1] = "IGNORE"
      WhereKeyWords[1][2] = "IGNORE"
    else
      --already a table, use it
      local NotTableOfTables = false
      local NotTwoItems = false
      for i=1,#where_key_words do
        if type(where_key_words[i]) ~= "table" then
          NotTableOfTables = true
          break
        elseif #where_key_words[i] ~= 2 then
          NotTwoItems = true
          break
        end
      end
      if NotTableOfTables then
        print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SECTION is not a proper table of tables, please correct your script! "..H._zDEFAULT)
        H.Report("",">>> WHERE_IN_SECTION is not a proper table of tables, please correct your script!","WARNING")
      end
      if NotTwoItems then
        print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SECTION tables should have two items each, please correct your script! "..H._zDEFAULT)
        H.Report("",">>> WHERE_IN_SECTION tables should have two items each, please correct your script!","WARNING")
      end
      if not NotTableOfTables and not NotTwoItems then
        --we can use it
        WhereKeyWords = where_key_words
      else
        WhereKeyWords[1][1] = "IGNORE"
        WhereKeyWords[1][2] = "IGNORE"
      end
    end
  end
  
  for i=1,#WhereKeyWords do
    if WhereKeyWords[i][1] == nil then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] A WHERE_IN_SECTION "Property name/value" is nil, please correct your script! ]]..H._zDEFAULT)
      H.Report("",[[>>> A WHERE_IN_SECTION "Property name/value" is nil, please correct your script!]],"ERROR")
      WhereKeyWords[i][1] = "IGNORE" --to prevent a crash
      break
    end
    if WhereKeyWords[i][2] == nil then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] A WHERE_IN_SECTION "newvalue" is nil, please correct your script! ]]..H._zDEFAULT)
      H.Report("",[[>>> A WHERE_IN_SECTION "newvalue" is nil, please correct your script!]],"ERROR")
      WhereKeyWords[i][2] = "IGNORE" --to prevent a crash
      break
    end
    
    WhereKeyWords[i][1] = strgsub(WhereKeyWords[i][1],[[\\]],[[\]])
    
    if type(WhereKeyWords[i][2]) == "number" then
      WhereKeyWords[i][2] = tostring(WhereKeyWords[i][2])
    else
      WhereKeyWords[i][2] = strgsub(WhereKeyWords[i][2],[[\\]],[[\]])
    end
  end
  
  if (#WhereKeyWords > 0) and (WhereKeyWords[1][1] ~= "IGNORE" or WhereKeyWords[1][2] ~= "IGNORE") then
    IsWhereKeyWords = true
    if My.IsOrgReplace_typeEmpty or (not My.IsOrgReplace_typeEmpty and not IsReplaceONCE) then
      -- the user did NOT specify ONCE
      IsReplaceALL = true
      IsReplaceONCE = false
    end
  end
  -- print(" C:              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."]     IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
  
  --  *******************************************************
  -- FROM HERE ON [where_key_words] is known as [WhereKeyWords] (a table of tables)
  --  *******************************************************
  
  -- *****************   wi_sec_lop section   ********************
  wi_sec_lop = H.ReturnStringFrom(wi_sec_lop)
  wi_sec_lop = strupper(wi_sec_lop)
  
  local IsWiSecLop = (wi_sec_lop ~= "")
  
  local IsWiSecLopOR = (wi_sec_lop == "OR") --default
  local IsWiSecLopAND = (wi_sec_lop == "AND")
  local IsWiSecLopNOR = (wi_sec_lop == "NOR")
  if IsWiSecLop and not (IsWiSecLopOR or IsWiSecLopAND or IsWiSecLopNOR) then
    print(">>> "..H.gcWARNING..[[ [WARNING] WISEC_LOP value is incorrect, should be "", "AND", "OR" or "NOR" ]]..H._zDEFAULT)
    H.Report(wi_sec_lop,[[>>> WISEC_LOP value is incorrect, should be "", "AND", "OR" or "NOR"]],"WARNING")
  end
  
  if not (IsWiSecLopAND or IsWiSecLopNOR) then
    IsWiSecLopOR = true --default
  end
  
  -- *****************   subwhere_key_words section   ********************
  local SubWhereKeyWords = {{"",""}}
  H.IsSubWhereKeyWords = false
  
  if subwhere_key_words == nil or subwhere_key_words == "" then
    SubWhereKeyWords[1][1] = "IGNORE"
    SubWhereKeyWords[1][2] = "IGNORE"
  else
    if type(subwhere_key_words) ~= "table" then
      --not a table, make it a table
      print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SUBSECTION is not a proper table of tables, please correct your script! "..H._zDEFAULT)
      H.Report("",">>> WHERE_IN_SUBSECTION is not a proper table of tables, please correct your script!","WARNING")
      SubWhereKeyWords[1][1] = "IGNORE"
      SubWhereKeyWords[1][2] = "IGNORE"
    else
      --already a table, use it
      local NotTableOfTables = false
      local NotTwoItems = false
      for i=1,#subwhere_key_words do
        if type(subwhere_key_words[i]) ~= "table" then
          NotTableOfTables = true
          break
        elseif #subwhere_key_words[i] ~= 2 then
          NotTwoItems = true
          break
        end
      end
      if NotTableOfTables then
        print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SUBSECTION is not a proper table of tables, please correct your script! "..H._zDEFAULT)
        H.Report("",">>> WHERE_IN_SUBSECTION is not a proper table of tables, please correct your script!","WARNING")
      end
      if NotTwoItems then
        print(">>> "..H.gcWARNING.." [WARNING] WHERE_IN_SUBSECTION tables should have two items each, please correct your script! "..H._zDEFAULT)
        H.Report("",">>> WHERE_IN_SUBSECTION tables should have two items each, please correct your script!","WARNING")
      end
      if not NotTableOfTables and not NotTwoItems then
        --we can use it
        SubWhereKeyWords = subwhere_key_words
      end
    end
  end
  
  for i=1,#SubWhereKeyWords do
    if SubWhereKeyWords[i][1] == nil then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] A WHERE_IN_SUBSECTION "Property name/value" is nil, please correct your script! ]]..H._zDEFAULT)
      H.Report("",[[>>> A WHERE_IN_SUBSECTION "Property name/value" is nil, please correct your script!]],"ERROR")
      SubWhereKeyWords[i][1] = "IGNORE" --to prevent a crash
      break
    end
    if SubWhereKeyWords[i][2] == nil then
      --we have a problem, should not be nil
      print(">>> "..H.gcERROR..[[ [ERROR] A WHERE_IN_SUBSECTION "newvalue" is nil, please correct your script! ]]..H._zDEFAULT)
      H.Report("",[[>>> A WHERE_IN_SUBSECTION "newvalue" is nil, please correct your script!]],"ERROR")
      SubWhereKeyWords[i][2] = "IGNORE" --to prevent a crash
      break
    end
    
    SubWhereKeyWords[i][1] = strgsub(SubWhereKeyWords[i][1],[[\\]],[[\]])
    
    if type(SubWhereKeyWords[i][2]) == "number" then
      SubWhereKeyWords[i][2] = tostring(SubWhereKeyWords[i][2])
    else
      SubWhereKeyWords[i][2] = strgsub(SubWhereKeyWords[i][2],[[\\]],[[\]])
    end
  end
  
  if (#SubWhereKeyWords > 0) and (SubWhereKeyWords[1][1] ~= "IGNORE" or SubWhereKeyWords[1][2] ~= "IGNORE") then
    H.IsSubWhereKeyWords = true
    if My.IsOrgReplace_typeEmpty or (not My.IsOrgReplace_typeEmpty and not IsReplaceONCE) then
      -- the user did NOT specify ONCE
      IsReplaceALL = true
      IsReplaceONCE = false
    end
  end
  -- print(" D:              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."]     IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
  
  --  *******************************************************
  -- FROM HERE ON [subwhere_key_words] is known as [SubWhereKeyWords] (a table of tables)
  --  *******************************************************
  
  -- *****************   wisub_sec_lop section   ********************
  wisub_sec_lop = H.ReturnStringFrom(wisub_sec_lop)
  wisub_sec_lop = strupper(wisub_sec_lop)
  
  local IsWisubSecLop = (wisub_sec_lop ~= "")
  
  local IsWisubSecLopOR = (wisub_sec_lop == "OR") --default
  local IsWisubSecLopAND = (wisub_sec_lop == "AND")
  local IsWisubSecLopNOR = (wisub_sec_lop == "NOR")
  
  if IsWisubSecLop and not (IsWisubSecLopAND or IsWisubSecLopOR or IsWisubSecLopNOR) then
    print(">>> "..H.gcWARNING..[[ [WARNING] WISUBSEC_LOP value is incorrect, should be "", "AND", "OR" or "NOR" ]]..H._zDEFAULT)
    H.Report(wisub_sec_lop,[[>>> WISUBSEC_LOP value is incorrect, should be "", "AND", "OR" or "NOR"]],"WARNING")
  end
  
  if not (IsWisubSecLopAND or IsWisubSecLopNOR) then
    IsWisubSecLopOR = true --default
  end
  
  -- *****************   wisub_sec_option section   ********************
  wisub_sec_option = H.ReturnStringFrom(wisub_sec_option)
  wisub_sec_option = strupper(wisub_sec_option)
  
  local IsWisubSecOption = (wisub_sec_option ~= "")
  
  local IsWisubSecOptionONCE = (wisub_sec_option == "ONCE") --default
  local IsWisubSecOptionALL = (wisub_sec_option == "ALL")
  if IsWisubSecOption and not (IsWisubSecOptionONCE or IsWisubSecOptionALL) then
    print(">>> "..H.gcWARNING..[[ [WARNING] WISUBSEC_OPTION value is incorrect, should be "", "ONCE" or "ALL" ]]..H._zDEFAULT)
    H.Report(wisub_sec_option,[[>>> WISUBSEC_OPTION value is incorrect, should be "", "ONCE" or "ALL"]],"WARNING")
  end
  
  if not IsWisubSecOptionALL then
    IsWisubSecOptionONCE = true -- default
  end
  
  -- *****************   custom_order   ********************
  My.ProcessOrder = {"SU","SA","WIS","WISS"} -- standard order
  My.CustomOrder = false
  
  local IsBadCO = false
  if custom_order then
    if type(custom_order) == "table" then
      My.CustomOrder = true
      for i=1,#custom_order do
        if custom_order[i] == nil or type(custom_order[i]) ~= "string" then
          IsBadCO = true
          break
        end
        
        local found = false
        for j=1,#My.ProcessOrder do
          if strupper(custom_order[i]) == My.ProcessOrder[j] or custom_order[i] == "" then
            found = true
            break
          end
        end
        
        if not found then
          IsBadCO = true
          break
        end
      end -- for i=1,#custom_order do
      
    else
      IsBadCO = true
    end
  end
  
  if My.CustomOrder then
    if IsBadCO then
      print(">>> "..H.gcWARNING..[[ [WARNING] CUSTOM_ORDER is incorrect, using default processing order ]]..H._zDEFAULT)
      H.Report(wisub_sec_option,[[>>> CUSTOM_ORDER is incorrect, using default processing order]],"WARNING")
    else
      My.CustomOrder = true
      My.ProcessOrder = custom_order
      
      local co = ""
      for i=1,#My.ProcessOrder do
        if co == "" and My.ProcessOrder[i] ~= "" then
          co = strupper(My.ProcessOrder[i])
        elseif My.ProcessOrder[i] ~= "" then
          co = co.."-"..strupper(My.ProcessOrder[i])
        end
      end
      
      if not H.gIs_LEAN_MODE then
        print("    >>> [INFO] Using: "..H._zBRIGHTORANGE..[[ CUSTOM_ORDER < ]]..co..[[ > ]]..H._zDEFAULT)
      end
      H.Report(wisub_sec_option,[[    >>> Using CUSTOM_ORDER < ]]..co..[[ >]])
    end
  end
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: section_active section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- *****************   section_active section   ********************
  local SectionActive = {}
  H.IsSectionActive = false
  local badEntry = false
  
  if section_active == nil then
    --nothing to do
  elseif type(section_active) ~= "number" and type(section_active) ~= "string" and type(section_active) ~= "table" then
    badEntry = true
  else
    if type(section_active) == "number" then
      if math.abs(section_active) >= 0 then
        SectionActive[#SectionActive+1] = math.abs(section_active)
        H.IsSectionActive = true
      end
      
    elseif type(section_active) == "string" then
      if section_active == "LAST" then
        SectionActive[#SectionActive+1] = math.huge
        H.IsSectionActive = true
      else
        local sa = math.tointeger(tonumber(section_active))
        if sa then
          if math.abs(sa) >= 0 then
            SectionActive[#SectionActive+1] = math.abs(sa)
            H.IsSectionActive = true
          end
        else
          badEntry = true
        end
      end
      
    elseif type(section_active) == "table" then
      for i=1,#section_active do
        if type(section_active[i]) == "number" then
          if math.abs(section_active[i]) >= 0 then
            SectionActive[i] = math.abs(section_active[i])
            H.IsSectionActive = true
          end
          
        elseif type(section_active[i]) == "string" then
          if section_active[i] == "LAST" then
            SectionActive[i] = math.huge
            H.IsSectionActive = true
          else
            local sa = math.tointeger(tonumber(section_active[i]))
            if sa then
              if math.abs(sa) >= 0 then
                SectionActive[i] = math.abs(sa)
                H.IsSectionActive = true
              end
            else
              badEntry = true
              break
            end
          end
        else
          badEntry = true
          break
        end
      end
    end
  end
  
  if badEntry then
    print(">>> "..H.gcWARNING.." [WARNING] SECTION_ACTIVE is not a proper number or table of numbers or 'LAST', please correct your script! "..H._zDEFAULT)
    H.Report("",">>> SECTION_ACTIVE is not a proper number or table of numbers or 'LAST', please correct your script!","WARNING")
    SectionActive = {}
    H.IsSectionActive = false
  end
  
  -- local IsSectionActiveNegative = false
  -- --makes all positive
  -- for i=1,#SectionActive do
    -- if SectionActive[i] < 0 then
      -- SectionActive[i] = math.abs(SectionActive[i])
      -- IsSectionActiveNegative = true
    -- end
  -- end
  
  --================================================================
  local function SortList(one,two)
    return (one < two)
  end
  --================================================================
  
  -- if #SectionActive == 1 and SectionActive[1] == 0 then
    -- --only one section and 0
    -- H.IsSectionActive = false
  -- end
  
  if #SectionActive > 0 then
    --sort ascending
    table.sort(SectionActive,SortList)
  end
  
-- --DEBUG
-- for m=1,#SectionActive do
  -- print("- SectionActive["..m.."] = "..SectionActive[m])
-- end
-- print("IsSectionActiveNegative = "..tostring(IsSectionActiveNegative))
-- print("")

  -- if H.IsSectionActive then
    -- if IsSectionActiveNegative then
      -- IsReplaceONCE = true
      -- IsReplaceALL = false
    -- else
      -- IsReplaceONCE = false
      -- IsReplaceALL = true
    -- end
  -- end
  
  --  *******************************************************
  -- FROM HERE ON [section_active] is known as [SectionActive] (a table of numbers)
  --  *******************************************************
  
  if H.IsKWpattern then
    IsReplaceONCE = false
    IsReplaceALL = true
  end
  
  if My._mISxxx then
    print("")
    print(" + AFTER all preparations...")
    print(" +                 IsReplace: ["..tostring(IsReplace).."]               IsReplaceRAW: ["..tostring(IsReplaceRAW).."]")
    print(" +       IsPrecedingKeyWords: ["..tostring(H.IsPrecedingKeyWords).."]         IsSpecialKeyWords: ["..tostring(IsSpecialKeyWords).."]")
    print(" +    IsOnePrecedingWordOnly: ["..tostring(H.IsOnePrecedingWordOnly).."]")
    print(" +FirstPrecedingWordNotEmpty: ["..H.FirstPrecedingWordNotEmpty.."]            IsReplaceFOLLOWING: ["..tostring(IsReplaceFOLLOWING).."]")
    print(" +              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."             IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
    print(" +     IsReplaceAllInSection: ["..tostring(IsReplaceAllInSection).."]")
    print(" +      IsPrecedingFirstTRUE: ["..tostring(IsPrecedingFirstTRUE))
    print(" +            My.IsTextToAdd: ["..tostring(My.IsTextToAdd)
              .."]  IsReplaceADDAFTERSECTION: ["..tostring(H.IsReplaceADDAFTERSECTION)
              .."]     IsReplaceADDAFTERLINE: ["..tostring(H.IsReplaceADDAFTERLINE)
              .."]           IsReplaceATLINE: ["..tostring(H.IsReplaceATLINE)
              .."]               IsAddATLINE: ["..tostring(H.IsAddATLINE)
              .."]     IsReplaceWholeSECTION: ["..tostring(H.IsReplaceWholeSECTION).."]")
    print(" +             My.IsToRemove: ["..tostring(My.IsToRemove)
              .."]            My.IsToRemoveLINE: ["..tostring(My.IsToRemoveLINE)
              .."]      My.IsToRemoveSECTION: ["..tostring(My.IsToRemoveSECTION)
              .."] My.IsToRemoveHBOS: ["..tostring(My.IsToRemoveHBOS).."]")
    print(" +       IsValueMatchOptions: ["..tostring(IsValueMatchOptions).."]        value_match_options: ["..value_match_options.."]")
    print(" +           IsWhereKeyWords: ["..tostring(IsWhereKeyWords).."]           H.IsSectionActive: ["..tostring(H.IsSectionActive).."]")
    print(" +My.IsAllTheSameChangeTable: ["..tostring(My.IsAllTheSameChangeTable).."]")
    print(" +              IsLineOffset: ["..tostring(IsLineOffset).."]")
    print(" +               IsKWpattern: ["..tostring(H.IsKWpattern).."]")
    print(" +        H.IsEXMLcreateTRUE: ["..tostring(H.IsEXMLcreateTRUE).."]")
    print(" +            #SectionActive: ["..#SectionActive.."]")
    print("")
  end
  
  -- *****************   SCRIPTBUILDERscript section   ********************
  local ScriptType = "User"
  if H.gSCRIPTBUILDERscript then
    --treat this script as a SCRIPTBUILDER script
    ScriptType = "SCRIPTBUILDER"
  end
  
  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." ENTERING: MAIN SECTION (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  My.CheckPoint(4)
  -- *****************   main section   ********************
  -- H.gVerbose = true
  -- H.pv("H.gVerbose is ON")
  
  -- LOADED ONCE per MXML_CHANGE_TABLE
  --    the EXML file as one UPPERCASE text, for speed searching for uniqueness
  H.DEBUG_TableToStringCount_print("###  ---- H.WholeTextFileTable refresh: #TextFileTable = "..#TextFileTable.." ----")
  H.WholeTextFileTable = {}
  H.WholeTextFileTable[#H.WholeTextFileTable+1] = table.concat(TextFileTable):upper()
  H.DEBUG_TableToStringCount_print("###  ---- H.WholeTextFileTable refresh DONE ----")

  if strfind(file,".MXML",1,true) then
    _,My.lineEndings = strgsub(H.WholeTextFileTable[1],'>','>',-1)
    if My.lineEndings ~= #TextFileTable then
      H.printf(">>> "..H.gcWARNING..[[ [WARNING] Modded MXML's line count(%d) does not match number of line endings ">"(%d), Keywords search and ADD could probably fail.  Please correct your script! ]]..H._zDEFAULT,#TextFileTable,My.lineEndings)
      H.printf(">>> "..H.gcWARNING..[[          Most probable cause is a previous "ADD" operation that did not include a trailing CRLF at the end of the string ]]..H._zDEFAULT)
      H.Report("",[[>>> Modded MXML's line count(]]..#TextFileTable..[[) does not match number of line endings ">"(]]..My.lineEndings..[[), Keywords search and ADD could probably fail.  Please correct your script!]],"WARNING")
      H.Report("",[[>>> Most probable cause is a previous "ADD" operation that did not include a trailing CRLF at the end of the string]],"WARNING")
-- H.printf("My.lineEndings %d, #TextFileTable %d",My.lineEndings,#TextFileTable)

-- print("MMM MMM MMM")
-- for i=1,#TextFileTable do
  -- H.printf("%d: %s",i,TextFileTable[i])
-- end
-- print("MMM MMM MMM")
-- H.WFAK()
    end
    H.DEBUG_TableToStringCount_print("###  ---- lineEndings = "..My.lineEndings..", #TextFileTable = "..#TextFileTable)
  end
  
  local GroupStartLine = {}
  local GroupEndLine = {}
  local SpecialKeyWordLine = {}
  local SectionsTable = {}
  
  local Group_Found = false
  
  --Note: all property/value combo in val_change_table use the Same_KEY_WORDS
  
  local tFindGroup = 0
  My.IsHOSCreated = false
  My.IsHOESCreated = false
  
  -- printf("#H.prec_key_words = %d",#H.prec_key_words)
  
  local prec_key_words -- THIS one must stay a LOCAL
  H.mPKW = 1
  repeat -- process PKW for-each
    prec_key_words = H.prec_key_words[H.mPKW]
    
    -- if #H.prec_key_words > 1 then
      -- printf("In process PKW for-each: type(prec_key_words) = %s",type(prec_key_words))
    -- end
    
    if #H.prec_key_words[1] > 1 then
      H.IsPrecedingKeyWords = true
      H.IsOnePrecedingWordOnly = false
      H.FirstPrecedingWordNotEmpty = 1
    elseif #H.prec_key_words[1] == 1 then
      --only one word
      H.IsPrecedingKeyWords = true
      H.IsOnePrecedingWordOnly = true
      H.FirstPrecedingWordNotEmpty = 1
    else
      H.IsPrecedingKeyWords = false
      H.IsOnePrecedingWordOnly = false
      H.FirstPrecedingWordNotEmpty = 0
      H.prec_key_words[1][1] = ""
    end

    -- *****************   ISxxx section   ********************
    if My._mISxxx then
      print("")
      print(" + AFTER PKW for-each...")
      print(" +       IsPrecedingKeyWords: ["..tostring(H.IsPrecedingKeyWords).."]")
      print(" +    IsOnePrecedingWordOnly: ["..tostring(H.IsOnePrecedingWordOnly).."]")
      print(" +FirstPrecedingWordNotEmpty: ["..H.FirstPrecedingWordNotEmpty.."]")
      print("")
    end
    
    H.KWinfo = {}
    -- H.PossibleHOStable = {}
  
    -- if not H.IsMainSection and (H.IsPrecedingKeyWords or IsSpecialKeyWords) then
    if H.IsPrecedingKeyWords or IsSpecialKeyWords then
      H.DEBUG_GROUPS_print("SKW or PKW exist")
      
      ShowKeyWordInfo(H,spec_key_words,prec_key_words,H.IsPrecedingKeyWords,IsSpecialKeyWords,IsPrecedingFirstTRUE,IsUsingForeach_SKWG,item)
      
      --#####################################################################################################################
      --********************  FINDGROUP (processing spec_key_words and prec_key_words) **************************************
      --find group(s) where key_words lead
      
      --H.IsOnePrecedingWordOnly is ONLY used for display above, Findgroup() will decide if it is activated using IsOnlyOnePreceding
      
      H.DEBUG_SEC_print(H._zBRIGHTRED.."                         BEFORE FindGroup()   >>>          file = ["..file.."]"..H._zDEFAULT)
      H.DEBUG_SEC_print(H._zBRIGHTRED.."                                              >>>    #TextFileTable = <"..#TextFileTable..">"..H._zDEFAULT)
      
      My.CheckPoint(5)
      tFindGroup = os.clock()
      H.DEBUG_FindGroup_timing_print("         >> ".."FINDGROUP START at "..H.dClock(0))

      -- H.printf(" BEFORE FindGroup().My.IsCreateHOSTRUE = %s",tostring(My.IsCreateHOSTRUE))
      -- H.printf("    BEFORE FindGroup().My.IsHOSCreated = %s",tostring(My.IsHOSCreated))
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE: FindGroup() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
      
      Group_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, My.IsHOSCreated, outKWinfo
      -- Group_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, outKWinfo, H.PossibleHOStable
              = FindGroup(H, TextFileTable, H.WholeTextFileTable, prec_key_words, IsPrecedingFirstTRUE
                         ,IsSpecialKeyWords, spec_key_words, section_up_special, section_up_preceding
                         ,H.IsAfterKeyWords, IsEditSection, IsReplaceONCE, My.IsCreateHOSTRUE, My.IsHOSCreated, H.KWinfo)
                         -- ,IsEditSection, IsReplaceONCE, My.IsCreateHOSTRUE, H.KWinfo, H.PossibleHOStable)
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." AFTER: FindGroup() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))

-- printf("#outKWinfo = %d, #GroupStartLine= %d",#outKWinfo,#GroupStartLine)
      
      -- if H.IsShowSections and H.IsKWpattern then
      H.KWinfo = {} -- we restart
        for Z=1,#outKWinfo do
          local info = outKWinfo[Z]
          -- printf("Z: %d: [%s]",Z,info)

          if info and info ~= "" then
            local s = ""
            for w in strgmatch(info,"(.-):") do
              local p,v = H.GetPropertyNameValue(w)
              if p == nil then
                s = s..strformat("<"..H._zBRIGHTORANGE.."%s"..H._zDEFAULT.."> + ",v)
              elseif v == nil then
                s = s..strformat("<"..H._zBRIGHTORANGE.."%s"..H._zDEFAULT.."> + ",p)
              else
                s = s..strformat("<"..H._zBRIGHTORANGE.."%s"..H._zDEFAULT.." - "..H._zBRIGHTORANGE.."%s"..H._zDEFAULT.."> + ",p,v)
              end
            end
            if s == "" then
              H.KWinfo[#H.KWinfo+1] = " ==> based on "..strsub(info,1,-4)
            else
              H.KWinfo[#H.KWinfo+1] = " ==> based on "..strsub(s,1,-4)
            end
            -- printf(" - [%s]",H.KWinfo[#H.KWinfo])
          -- elseif info == "" then
            -- H.KWinfo[Z] = ""
          end
        end
      -- end
      
-- printf("#H.KWinfo = %d, #GroupStartLine= %d",#H.KWinfo,#GroupStartLine)

      if not IsEditSection then
        assert(H.TextFileTableCheck == TextFileTable, " = = = = = = = = = = = = = = = = = = = = = = = = = WARNING: X: H.TextFileTableCheck ~= TextFileTable")
      end
      
      tFindGroupEND = os.clock() - tFindGroup
      H.DEBUG_FindGroup_timing_print("        >> ".."FINDGROUP ENDED in "..H.dClock(tFindGroupEND))

      if H.gDEBUG_GROUPS and H.IsShowSections then
          ShowSections(H,SectionsTable,"AFG:")
          print(" = = = = = = = = gDEBUG_GROUPS")
          for p=1,#GroupStartLine do
            print("   "..p..":   "..GroupStartLine[p].." - "..GroupEndLine[p])
          end
          print(" = = = = = = = = gDEBUG_GROUPS")
      end
      
      if IsOnlyOnePreceding then
        H.pv("Only 'one' PRECEDING_KEY_WORDS detected")
      end
      
      if not Group_Found then
        print(">>> "..H.gcWARNING.." [WARNING] Some KEY_WORDS not found, script result may be wrong!, see REPORT.lua "..H._zDEFAULT)
        H.Report(Info,"Some KEY_WORDS not found, script result may be wrong!","WARNING")
      end
      --********************  END: FINDGROUP (processing spec_key_words and prec_key_words) **************************************
      --#####################################################################################################################
      
    else
      H.DEBUG_GROUPS_print("NO SKW and NO PKW or IsMainSection")
      --no key_words to search =>> use the whole file
      if IsReplaceRAW or IsEditSection then
        GroupStartLine = {1}
        SpecialKeyWordLine = {1}
     else
        -- GroupStartLine = {3}
        -- SpecialKeyWordLine = {3}
        -- in case of strange EXML header
        for i=1,#TextFileTable do
          if strsub(strupper(H.ltrim(TextFileTable[i])),1,8) == [[<DATA TE]] then
            GroupStartLine = {i}
            SpecialKeyWordLine = {i}
            break
          end
        end
      end
      
      H.KWinfo = {""}
      
      GroupEndLine = {#TextFileTable}
      -- SpecialKeyWordLine = {""}
      SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"<->",SectionsTable)
      Group_Found = true
    end
    
    -- until SECTION_ACTIVE turns it ON
    H.IsListOfValues = false
    
    -- assert(#H.KWinfo == #GroupStartLine,"AFTER any/all SKW and PKW were processed #H.KWinfo ~= #GroupStartLine")
    
    -- AFTER any/all spec_key_words and prec_key_words were processed
    H.DEBUG_GROUPS_print("D: AFTER any/all spec_key_words and prec_key_words were processed: #Sections = "..#GroupStartLine)
    -- ********  Groups AFTER processing SPECIAL, UP_SPECIAL and PRECEDING keywords  *************

    --recreate Group List and remove duplicates
    GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = RemoveDuplicateGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
    H.DEBUG_GROUPS_print("AFTER RemoveDuplicateGroups(): #Sections = "..#GroupStartLine)

    --recreate Group List and remove Overlapping sections keeping outer sections
    GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,true,"A",H.KWinfo)
    H.DEBUG_GROUPS_print("AFTER PurgeOverlappingSections() keeping outer sections: #Sections = "..#GroupStartLine)
    -- *******************************************************************************************
    
    -- assert(#H.KWinfo == #GroupStartLine,"AFTER Duplicate and Purge #H.KWinfo ~= #GroupStartLine")

    H.NumFoundSections = #GroupStartLine
    
    if H.gDEBUG_GROUPS then
      H.DEBUG_GROUPS_print("A: NumFoundSections = "..H.NumFoundSections)
      ShowSections(H,SectionsTable,"ASUP:")
    end
    
    --to be able to say how many groups were evaluated
    H.RememberNumberOfGroups = 0
    
    --**************************************** handles WHERE_IN_SECTION ***********************************
    -- a BIT FASTER than WISS
    local function ProcessWHERE_IN_SECTION(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
      H.RememberNumberOfGroups = #(GetLASTsections(SectionsTable))
      
      if Group_Found and IsWhereKeyWords then
        H.DEBUG_WIS_print("")
        H.DEBUG_WIS_print("   In Group_Found and IsWhereKeyWords\n")
        -- print("#GroupStartLine = "..#GroupStartLine)
        
        if IsWiSecLopOR then
          H.DEBUG_WIS_print(">>> using OR section")
          local GroupState = {}
          
          for i=1,#GroupStartLine do
            --for each group
            H.DEBUG_WIS_print("   In Group "..i)
            local FoundInSection = false
            
            GroupState[i] = FoundInSection
            local WhereKeyWordsState = {}
            for wK = 1,#WhereKeyWords do
              --for each pair of WhereKeyWords
              --check if WhereKeyWords are found in this group
              H.DEBUG_WIS_print("      looking for ["..WhereKeyWords[wK][1].."],["..WhereKeyWords[wK][2].."]")
              WhereKeyWordsState[wK] = false
              for j=GroupStartLine[i],GroupEndLine[i] do
                --for each line in this group
                local text = TextFileTable[j]
                -- if (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]],1,true) or WhereKeyWords[wK][1] == "IGNORE")
                      -- and (strfind(text,[[value="]]..WhereKeyWords[wK][2]..[["]],1,true) or WhereKeyWords[wK][2] == "IGNORE") then
                if (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]]) or WhereKeyWords[wK][1] == "IGNORE")
                      and (strfind(text,[[ue="]]..WhereKeyWords[wK][2]..[["]]) or WhereKeyWords[wK][2] == "IGNORE") then
                  -- print("At group #"..i..", WhereKeyWords["..wK.."] is found")
                  H.DEBUG_WIS_print("      Found at "..j)
                  WhereKeyWordsState[wK] = true
                  -- if IsWiSecLopOR then
                    --any true is ok
                    break
                  -- end
                end
              end
              
              if WhereKeyWordsState[wK] then
                --word 'wK' found in this group
                H.DEBUG_WIS_print("      Found")
                FoundInSection = true
                break
              end
            end
            
            GroupState[i] = FoundInSection
          end --for i=1,#GroupStartLine do
          
          --clean unwanted groups
          for i=#GroupStartLine,1,-1 do
            if not GroupState[i] then
              table.remove(GroupStartLine,i)
              table.remove(GroupEndLine,i)
              table.remove(SpecialKeyWordLine,i)
              table.remove(KWinfo,i)
            end
          end
        end --if IsWisubSecLopOR then
        
        if IsWiSecLopAND or IsWiSecLopNOR then
          H.DEBUG_WIS_print(">>> using AND/NOR section")
          
          local newGSL = {}
          local newGEL = {}
          local newSKWL = {}
          local newKWinfo = {}
          --***************************************************************************
          local function SaveSection(StartLine,EndLine,SKWLine,KWinfo)
            newGSL[#newGSL+1] = StartLine
            newGEL[#newGEL+1] = EndLine
            newSKWL[#newSKWL+1] = SKWLine
            newKWinfo[#newKWinfo+1] = KWinfo
          end
          --***************************************************************************
          
          for i=1,#GroupStartLine do
            --for each group
            local keywordState = {}
            for wK=1,#WhereKeyWords do
              --for each pair of WhereKeyWords

              -- set ALL keywords state to default values
              if IsWiSecLopAND then
                keywordState[wK] = false -- if found, it will become true
              else
                keywordState[wK] = true -- if found, it will become false
              end

              --check if WhereKeyWords are found in this group
              keywordState[wK] = false
              for j=GroupStartLine[i],GroupEndLine[i] do
                --for each line in this group
                local text = TextFileTable[j]
                
                local found = false
                if IsWiSecLopAND then
                  -- found = (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]],1,true) or WhereKeyWords[wK][1] == "IGNORE")
                          -- and (strfind(text,[[value="]]..WhereKeyWords[wK][2]..[["]],1,true) or WhereKeyWords[wK][2] == "IGNORE")
                  found = (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]]) or WhereKeyWords[wK][1] == "IGNORE")
                          and (strfind(text,[[ue="]]..WhereKeyWords[wK][2]..[["]]) or WhereKeyWords[wK][2] == "IGNORE")
                else -- IsWiSecLopNOR
                  keywordState[wK] = true
                  -- found = (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]],1,true) or WhereKeyWords[wK][1] == "IGNORE")
                          -- and (strfind(text,[[value="]]..WhereKeyWords[wK][2]..[["]],1,true) ~= nil)
                  found = (strfind(text,[[="]]..WhereKeyWords[wK][1]..[["]]) or WhereKeyWords[wK][1] == "IGNORE")
                          -- and (strfind(text,[[ue="]]..WhereKeyWords[wK][2]..[["]]) ~= nil)
                          and (strfind(text,[[ue="]]) ~= nil and strfind(text,[[ue="]]..WhereKeyWords[wK][2]..[["]]) ~= nil) -- Wbertro -- Lyr
                end
                
                if found then
                  --a pair was found
                  H.DEBUG_WIS_print("    At group #"..i.." line "..j..", ["..WhereKeyWords[wK][1].."],["..WhereKeyWords[wK][2].."]")
                  H.DEBUG_WIS_print("   FOUND pair in section")
                  if IsWiSecLopAND then
                    keywordState[wK] = true
                  else -- IsWiSecLopNOR
                    keywordState[wK] = false -- do not save this section
                  end
                  
                  break
                end
              end --for j=GroupStartLine[i],GroupEndLine[i] do
            end --for wK=1,#WhereKeyWords do
            
            local allFound = true
            for wK=1,#WhereKeyWords do
              if not keywordState[wK] then
                allFound = false
                break
              end
            end
            
            if allFound then
              --this section is good, remember it
              H.DEBUG_WIS_print("   saving "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..SpecialKeyWordLine[i]..")")
              SaveSection(GroupStartLine[i],GroupEndLine[i],SpecialKeyWordLine[i],KWinfo[i])
            end
            
          end --for i=1,#GroupStartLine do
          
          --recreate Group List and remove duplicates
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = RemoveDuplicateGroups(newGSL,newGEL,newSKWL,newKWinfo)
        end
        
        H.NumFoundSections = #GroupStartLine
        Group_Found = (H.NumFoundSections > 0)
        
        if not Group_Found then
          -- ShowKeyWordInfo(H,spec_key_words,prec_key_words,H.IsPrecedingKeyWords,IsSpecialKeyWords,IsPrecedingFirstTRUE,IsUsingForeach_SKWG,item) -- the SPECIAL and PRECEDING keywords
          
          local spacer = 11
          local Info = GetWhereInSectionInfo(WhereKeyWords)
          local LOP = "(OR)"
          if IsWiSecLopAND then
            LOP = "(AND)"
          end
          if IsWiSecLopNOR then
            LOP = "(NOR)"
          end
          local msg0 = strrep(" ",spacer).."    >>> using WHERE_IN_SECTION "..LOP.." "..Info.." to restrict search..."
          H.Report("",msg0)
          
          msg0 = strrep(" ",spacer).."    >>> using WHERE_IN_SECTION "..H._zBRIGHTGREEN..LOP..H._zDEFAULT.." "..Info.." to restrict search..."
          if not H.gIs_LEAN_MODE then
            print(msg0)
          end
          
          local secCount = ""
          if H.RememberNumberOfGroups > 1 then
            secCount = "s"
          end
          msg0 = strrep(" ",spacer).."    >>> Evaluated "..H.RememberNumberOfGroups.." section"..secCount..", found "..H.NumFoundSections.." sub-section(s) against WHERE_IN_SECTION keywords..."
          H.Report("",msg0)
          if not H.gIs_LEAN_MODE then
            print(msg0)
          end
          
          print("")
          print(">>> "..H.gcWARNING.." [WARNING] KEY_WORDS not found, skipping this change!, see REPORT.lua "..H._zDEFAULT)
          H.Report(Info,"KEY_WORDS not found, skipping this change!","WARNING")
        end
        
      end --if Group_Found and IsWhereKeyWords then

      GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = AscGroupsOrder(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)

      return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
    end
    --**************************************** END: handles WHERE_IN_SECTION ***********************************
    
    --**************************************** handles WHERE_IN_SUBSECTION ***********************************
    -- a BIT SLOWER than WIS
    local function ProcessWHERE_IN_SUBSECTION(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
    
-- print("WWWWWW  WWWWW ==> WISS IN")
-- for i=1,#GroupStartLine do
  -- H.printf("%d: %d - %d",i,GroupStartLine[i],GroupEndLine[i])
-- end
-- print("WWWWWW  WWWWW")

      H.RememberNumberOfGroups = #(GetLASTsections(SectionsTable))
      
      local newGSL = {}
      local newGEL = {}
      local newSKWL = {}
      local newKWinfo = {}
      --***************************************************************************
      local function SaveSubSectionAtLine(TextFileTable,linenum,KWinfo)
        newGSL[#newGSL+1] = H.GoUPToOwnerStart(TextFileTable,linenum + 1)
        newGEL[#newGEL+1] = H.GoDownToOwnerEnd(TextFileTable,linenum + 1)
        newSKWL[#newSKWL+1] = linenum
        newKWinfo[#newKWinfo+1] = KWinfo
      end
      --***************************************************************************
      
      if Group_Found and H.IsSubWhereKeyWords then
        H.DEBUG_WISS_print("")
        H.DEBUG_WISS_print("In Group_Found and IsSubWhereKeyWords\n")
        H.DEBUG_WISS_print("WHERE_IN_SUBSECTION: #Sections = "..#GroupStartLine)
        H.DEBUG_WISS_print("       IsWisubSecLopOR = "..tostring(IsWisubSecLopOR))
        H.DEBUG_WISS_print("      IsWisubSecLopAND = "..tostring(IsWisubSecLopAND))
        H.DEBUG_WISS_print("      IsWisubSecLopNOR = "..tostring(IsWisubSecLopNOR))
        H.DEBUG_WISS_print("  IsWisubSecOptionONCE = "..tostring(IsWisubSecOptionONCE))
        
        if IsWisubSecLopOR then
          H.DEBUG_GROUPS_print(">>> using OR section")
          for i=1,#GroupStartLine do --for each section
            H.DEBUG_WISS_print("    Section is "..GroupStartLine[i].."-"..GroupEndLine[i])
            for wK=1,#SubWhereKeyWords do --for each SubWhereKeyWord pair
              --check if pair is found in this section
              for j=GroupStartLine[i],GroupEndLine[i] do --for each line in this section
                local text = TextFileTable[j]
                -- if (strfind(text,[[="]]..SubWhereKeyWords[wK][1]..[["]],1,true) or SubWhereKeyWords[wK][1] == "IGNORE")
                      -- and (strfind(text,[[value="]]..SubWhereKeyWords[wK][2]..[["]],1,true) or SubWhereKeyWords[wK][2] == "IGNORE") then
                if (strfind(text,[[="]]..SubWhereKeyWords[wK][1]..[["]]) or SubWhereKeyWords[wK][1] == "IGNORE")
                      and (strfind(text,[[ue="]]..SubWhereKeyWords[wK][2]..[["]]) or SubWhereKeyWords[wK][2] == "IGNORE") then
                  H.DEBUG_WISS_print("    At group #"..i.." line "..j..", SubWhereKWindexGroup["..wK.."] is found")
                  --a pair was found
                  SaveSubSectionAtLine(TextFileTable,j,KWinfo[i])
                  
                  if IsWisubSecOptionONCE then
                    --doing only first find of each section
                    break --get out of this section
                  end
                end --if keywords found
              end --for j=GroupStartLine[i],GroupEndLine[i] do --for each line in this section
            end --for wK=1,#SubWhereKeyWords do --for each SubWhereKeyWord pair
          end --for i=1,#GroupStartLine do --for each section
          
          --recreate Group List and remove duplicates
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = RemoveDuplicateGroups(newGSL,newGEL,newSKWL,newKWinfo)
          
        end --if IsWisubSecLopOR then
        
        --***************************************************************************
        local function GetPairSections(GroupStartLine,GroupEndLine,SubWhereKWindex,IsWisubSecLopNOR,KWinfo)
          -- local p = function() end
          -- local p = print
          -- if IsWisubSecLopNOR == nil then IsWisubSecLopNOR = false end
          
          newGSL = {}
          newGEL = {}
          newSKWL = {}
          newKWinfo = {}
          
          H.DEBUG_WISS_print("   GetPairSections: keywords = ["..SubWhereKeyWords[SubWhereKWindex][1].."] + ["..SubWhereKeyWords[SubWhereKWindex][2].."]")
          H.DEBUG_WISS_print("   GetPairSections: #Sections = "..#GroupStartLine)
          
          for i=1,#GroupStartLine do --for each group
            H.DEBUG_WISS_print("   GetPairSections: lines = "..GroupStartLine[i].."-"..GroupEndLine[i])
            for j=GroupStartLine[i],GroupEndLine[i] do
              --for each line in this group
              local text = TextFileTable[j]
              H.DEBUG_WISS_print("   GetPairSections: text["..j.."] = ["..text.."]")
              
              local found = false
              if IsWisubSecLopAND then
                -- found = (strfind(text,[[="]]..SubWhereKeyWords[SubWhereKWindex][1]..[["]],1,true) or SubWhereKeyWords[SubWhereKWindex][1] == "IGNORE")
                        -- and (strfind(text,[[value="]]..SubWhereKeyWords[SubWhereKWindex][2]..[["]],1,true) or SubWhereKeyWords[SubWhereKWindex][2] == "IGNORE")
                found = (strfind(text,[[="]]..SubWhereKeyWords[SubWhereKWindex][1]..[["]]) or SubWhereKeyWords[SubWhereKWindex][1] == "IGNORE")
                        and (strfind(text,[[ue="]]..SubWhereKeyWords[SubWhereKWindex][2]..[["]]) or SubWhereKeyWords[SubWhereKWindex][2] == "IGNORE")
              elseif IsWisubSecLopNOR then
                -- found = (strfind(text,[[="]]..SubWhereKeyWords[SubWhereKWindex][1]..[["]],1,true) or SubWhereKeyWords[SubWhereKWindex][1] == "IGNORE")
                        -- and (not strfind(text,[[value="]]..SubWhereKeyWords[SubWhereKWindex][2]..[["]],1,true))
                found = (strfind(text,[[="]]..SubWhereKeyWords[SubWhereKWindex][1]..[["]]) or SubWhereKeyWords[SubWhereKWindex][1] == "IGNORE")
                        -- and (not strfind(text,[[ue="]]..SubWhereKeyWords[SubWhereKWindex][2]..[["]]))
                        and (strfind(text,[[ue="]]) ~= nil and not strfind(text,[[ue="]]..SubWhereKeyWords[SubWhereKWindex][2]..[["]])) -- lyr
              end
              
              if found then
                --a pair was found
                H.DEBUG_WISS_print("    At group #"..i.." line "..j..", SubWhereKWindexGroup = "..SubWhereKWindex)
                if IsWisubSecLopAND then
                  H.DEBUG_WISS_print("   GetPairSections: FOUND pair")
                else
                  H.DEBUG_WISS_print("   GetPairSections: pair NOT FOUND in section")
                end
                
                SaveSubSectionAtLine(TextFileTable,j,KWinfo[i])
                
                if (IsWisubSecOptionONCE and #GroupStartLine > 1) or (IsWisubSecLopNOR and not IsWisubSecOptionALL) then
                  --doing only first sub-group of each group when multiple groups exist
                  break
                end
              end --if keywords found
              
            end --for j=GroupStartLine[i],GroupEndLine[i] do
          end --for i=1,#GroupStartLine do
          
          --here all sections meeting 1st pair keywords are in newGSL...
          --now we check if next pair is also in these sections
          
          H.DEBUG_WISS_print("   GetPairSections: #newGSL = "..#newGSL)
          --recreate Group List and remove duplicates
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = RemoveDuplicateGroups(newGSL,newGEL,newSKWL,newKWinfo)
          H.DEBUG_WISS_print("   GetPairSections: after RemoveDuplicateGroups, #GroupStartLine = "..#GroupStartLine)
          return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
        end
        --***************************************************************************
        
        if IsWisubSecLopAND or IsWisubSecLopNOR then
          H.DEBUG_GROUPS_print(">>> using AND/NOR section")
          --by default, we keep the section unless one of the pairs is NOT found
          for SubWhereKWindex=1,#SubWhereKeyWords do --for each SubWhereKeyWord pair
            H.DEBUG_WISS_print("AND/NOR BEFORE: SubWhereKWindex = "..SubWhereKWindex)
            GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = GetPairSections(GroupStartLine,GroupEndLine,SubWhereKWindex,IsWisubSecLopNOR,KWinfo)
            H.DEBUG_WISS_print("AND/NOR AFTER: #GroupStartLine = "..#GroupStartLine)
          end
        end
        
        H.NumFoundSections = #GroupStartLine
        Group_Found = (H.NumFoundSections > 0)
        
        if not Group_Found then
          -- ShowKeyWordInfo(H,spec_key_words,prec_key_words,H.IsPrecedingKeyWords,IsSpecialKeyWords,IsPrecedingFirstTRUE,IsUsingForeach_SKWG,item)
          
          local spacer = 11
          local Info = GetWhereInSubSectionInfo(SubWhereKeyWords)
          local Option = ""
          if IsWisubSecOptionALL then
            Option = "with [ALL sub-sections] "
          end
          local LOP = "(OR)"
          if IsWisubSecLopAND then
            LOP = "(AND)"
          end
          if IsWisubSecLopNOR then
            LOP = "(NOR)"
          end
          local msg0 = strrep(" ",spacer).."    >>> using WHERE_IN_SUBSECTION "..LOP.." "..Option..Info.." to restrict search..."
          H.Report("",msg0)
          
          msg0 = strrep(" ",spacer).."    >>> using WHERE_IN_SUBSECTION "..H._zBRIGHTGREEN..LOP..H._zDEFAULT.." "..Option..Info.." to restrict search..."
          if not H.gIs_LEAN_MODE then
            print(msg0)
          end
          
          local secCount = ""
          if H.RememberNumberOfGroups > 1 then
            secCount = "s"
          end
          msg0 = strrep(" ",spacer).."    >>> Evaluated "..H.RememberNumberOfGroups.." section"..secCount..", found "..H.NumFoundSections.." sub-section(s) against WHERE_IN_SUBSECTION keywords..."
          H.Report("",msg0)
          if not H.gIs_LEAN_MODE then
            print(msg0)
          end
          
          print("")
          print(">>> "..H.gcWARNING.." [WARNING] KEY_WORDS not found, skipping this change!, see REPORT.lua "..H._zDEFAULT)
          H.Report(Info,"KEY_WORDS not found, skipping this change!","WARNING")
        end
      end
      
      GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = AscGroupsOrder(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)

-- print("WWWWWW  WWWWW ==> WISS OUT")
-- for i=1,#GroupStartLine do
  -- H.printf("%d: %d - %d",i,GroupStartLine[i],GroupEndLine[i])
-- end
-- print("WWWWWW  WWWWW")

      return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
    end
    --**************************************** END: handles WHERE_IN_SUBSECTION ***********************************
    
    H.IsSectionActiveValuesNotUsed = false
    local numGroupsBeforeSectionActive = H.NumFoundSections
    
    -- ====================================================================================    
    -- START: the next 4 handlers sequence is programmable !!!
    -- My.ProcessOrder = {"SU","SA","WIS","WISS"} -- standard order
    --    SU   = SECTION_UP
    --    SA   = SECTION_ACTIVE
    --    WIS  = WHERE_IN_SECTION
    --    WISS = WHERE_IN_SUBSECTION
    
    local tProcessOrder = os.clock()

    for pOrder = 1, #My.ProcessOrder do
      local p = My.ProcessOrder[pOrder]:upper()
      -- print("I: Processing ["..p.."]")
      
      if p == "SU" then
        --**************************************** process SECTION_UP ***********************************
        if section_up > 0 then
          H.pv("   Found SECTION_UP = "..section_up)
          
          if #GroupStartLine == 1 and strfind(strupper(TextFileTable[GroupStartLine[1]]),[[<DATA TE]],1,true) then
            section_up = 0 -- disable SECTION_UP
            print(">>> "..H.gcWARNING.." [WARNING] SECTION_UP ignored, using whole file "..H._zDEFAULT)
            H.Report("","       SECTION_UP ignored, using whole file","WARNING")
          else
            GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up)
            SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UP",SectionsTable)
          end
          -- assert(#H.KWinfo == #GroupStartLine,"AFTER Process_SectionUP() #H.KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: process SECTION_UP ***********************************
      elseif p == "SA" then
        --**************************************** process SECTION_ACTIVE ******************************************
        if H.IsSectionActive then
          --in GroupStartLine,GroupEndLine,SpecialKeyWordLine tables:
            --insert in  SectionsTable:
                --'not active' ones with "-A"
                --'active' ones with "+A"
            --keep only the 'active' ones in GroupStartLine,GroupEndLine,SpecialKeyWordLine tables
            
          --return SECTION_ACTIVE and SECTION_INACTIVE groups
          
      -- for m=1,#SectionActive do
        -- print("- SectionActive["..m.."] = "..SectionActive[m])
      -- end
      
          local GSLA,GELA,SKWLA,KWinfoA,GSLI,GELI,SKWLI,KWinfoI,IsOkToUse,IsListOfValues = ProcessSECTION_ACTIVE(GroupStartLine,GroupEndLine,SpecialKeyWordLine,SectionActive,TextFileTable,H.KWinfo)
          H.IsListOfValues = IsListOfValues
          -- H.printf("       IsOkToUse = [%s]",tostring(IsOkToUse))
          -- H.printf("H.IsListOfValues = [%s]",tostring(H.IsListOfValues))

      -- for m=1,#GSLA do
        -- print("- GSLA["..m.."] = "..GSLA[m])
      -- end
      -- for m=1,#GSLI do
        -- print("- GSLI["..m.."] = "..GSLI[m])
      -- end
      -- H.WFAK()
      
          if IsOkToUse then
            --some/all SECTION_ACTIVE values where processed
            --adding the SECTION_INACTIVE groups as 'SI'
            SectionsTable = AddSectionsIntoTable(H,GSLI,GELI,SKWLI,"SI",SectionsTable)
            --adding the SECTION_ACTIVE groups as 'SA'
            SectionsTable = AddSectionsIntoTable(H,GSLA,GELA,SKWLA,"SA",SectionsTable)
                  -- ShowSections(H,SectionsTable,"SA:")
                  
            --re-make the future USING groups
            GroupStartLine = GSLA
            GroupEndLine = GELA
            SpecialKeyWordLine = SKWLA
            H.KWinfo = KWinfoA
          else
            H.IsSectionActiveValuesNotUsed = true
          end
          -- assert(#H.KWinfo == #GroupStartLine,"AFTER ProcessSECTION_ACTIVE() #H.KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: process SECTION_ACTIVE *************************************
      elseif p == "WIS" then
        --**************************************** process WHERE_IN_SECTION ***********************************
        if IsWhereKeyWords then
          H.DEBUG_GROUPS_print("   Found <"..#WhereKeyWords.."> word pair(s) for WHERE_IN_SECTION, looking...")
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = ProcessWHERE_IN_SECTION(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
          SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"WiSec",SectionsTable)
          H.DEBUG_GROUPS_print("      after WHERE_IN_SECTION: NumFoundSections = "..#GroupStartLine)
          -- assert(#H.KWinfo == #GroupStartLine,"AFTER ProcessWHERE_IN_SECTION() #H.KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: process WHERE_IN_SECTION ***********************************
      elseif p == "WISS" then
        --**************************************** process WHERE_IN_SUBSECTION ***********************************
        if H.IsSubWhereKeyWords then
          H.DEBUG_GROUPS_print("   Found <"..#SubWhereKeyWords.."> word pair(s) for WHERE_IN_SUBSECTION, looking...")
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = ProcessWHERE_IN_SUBSECTION(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
          SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"WiSub",SectionsTable)
          H.DEBUG_GROUPS_print("      after WHERE_IN_SUBSECTION: NumFoundSections = "..#GroupStartLine)
          -- assert(#H.KWinfo == #GroupStartLine,"AFTER ProcessWHERE_IN_SUBSECTION() #H.KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: process WHERE_IN_SUBSECTION ***********************************
      end
    end
    local tProcessOrderEND = os.clock() - tProcessOrder
    H.DEBUG_FindGroup_timing_print("        >> ".."PROCESSORDER in "..H.dClock(tProcessOrderEND))

    -- assert(#H.KWinfo == #GroupStartLine,"AFTER 4 handlers #H.KWinfo ~= #GroupStartLine")

    -- ====================================================================================    END: the next 4 handlers sequence is programmable !!!
    
    --recreate Group List and remove duplicates
    GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = RemoveDuplicateGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
    SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"RD",SectionsTable)
    
    if My.IsToRemove then
      GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,true,"F",H.KWinfo)
      SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"P",SectionsTable)
    end
    
    H.DEBUG_GROUPS_print("")
    H.DEBUG_GROUPS_print("AFTER SECTION_UP, WHEREx, SECTION_ACTIVE and RemoveDuplicateGroups(): #GroupStartLine = "..#GroupStartLine)
    
    -- AKW processing
    if H.IsAfterKeyWords then
      if #GroupStartLine == 1 and strfind(strupper(TextFileTable[GroupStartLine[1]]),[[<DATA TE]],1,true) then
        section_up = 0 -- disable SECTION_UP
        print(">>> "..H.gcWARNING.." [WARNING] AKW ignored, using whole file "..H._zDEFAULT)
        H.Report("","       AKW ignored, using whole file","WARNING")
      else
  -- ShowSections(H,SectionsTable,"AK")
        -- H.printf("==> ENTERING AKW processing")
        H.All_AfterWords_Found = false
        H.UPPERafter_key_words = H.ReturnUpperCaseKwTable(H.a_key_words)
        
  -- for i=1,#H.UPPERafter_key_words do
    -- H.printf(" - [%s]",H.UPPERafter_key_words[i])
  -- end
        
        local SectionStartLine = {}
        local SectionEndLine = {}
        local PrecKeyWordLine = {}
    
        --lets try with all the PREC_KEY_WORDS
        local TopLine
        local BottomLine
  --H.DEBUG_FindGroup_print = H.DEBUG_print
        --                                                         PrecKeywordsSections(TextFileTable,H.UPPERafter_key_words,GroupStartLine,GroupEndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine   ,IsPrecedingFirstTRUE,IsSpecialKeyWords,H.IsAfterKeyWords,My.IsCreateHOSTRUE,H.KWinfo,true)
        TopLine,BottomLine,PrecKeyWordLine,IsHOSCreated,H.KWinfo = PrecKeywordsSections(TextFileTable,H.UPPERafter_key_words,GroupStartLine,GroupEndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine,true                ,false            ,false            ,My.IsCreateHOSTRUE,H.KWinfo,false)
  --function H.DEBUG_FindGroup_print() end
        H.All_AfterWords_Found = (#TopLine > 0)
        
        if H.All_AfterWords_Found then
          -- if #TopLine > 1 and #UPPERafter_key_words == 1 then
          if #TopLine > 1 then
            HandleLists(H, TextFileTable, TopLine, BottomLine, PrecKeyWordLine)
          end
          
          GroupStartLine = TopLine
          GroupEndLine = BottomLine
          SpecialKeyWordLine = PrecKeyWordLine
        end
        
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = RemoveDuplicateGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"AK",SectionsTable)
        
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KeepOuterSections,"G",H.KWinfo)
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"AKx",SectionsTable)

        if not H.All_AfterWords_Found then
          local Info = GetPrecKeyWordsInfo(H.a_key_words)
          print(">>> "..H.gcWARNING.." [WARNING] -- >>>>> Could not find [\"AKW\"] = "..Info.." <<<<< "..H._zDEFAULT)
          H.Report("","       >>>>> Could not find [\"AKW\"] = "..Info.." <<<<<","WARNING")
        end
        -- H.printf("==> EXITING AKW processing")
      end
    end
    -- END: AKW processing

    -- readjusting AFTER SECTION_UP, WHEREx, SECTION_ACTIVE and AKW
    H.NumFoundSections = #GroupStartLine
    
    H.DEBUG_GROUPS_print("B: NumFoundSections = "..H.NumFoundSections)
    H.DEBUG_GROUPS_print(H._zYELLOW.."*** Found "..#GroupStartLine.." section(s)"..H._zDEFAULT)
    
    local IsLargeNumOfReplacement = false
    
    local IsLargeNumOfGroupsFound = false
    if not IsLargeNumOfGroupsFound and not H.gIs_FULL_MODE and not IsReplaceONCE and #GroupStartLine > My.gMaxNumberOfGroups then
      IsLargeNumOfGroupsFound = true
      print(H._zBRIGHTGREEN..">>> "..H._zYELLOW.."LARGE number"..H._zDEFAULT..H._zBRIGHTGREEN.." of sections found, reducing log.lua output!  See Report.lua for full output"..H._zDEFAULT)
      print(H._zYELLOW.."               BE PATIENT"..H._zDEFAULT..", the output may only seem to stop at times...")
    end
    
    local SaveSectionDone = false
    
    if Group_Found then
      H.DEBUG_GROUPS_print("Entering Group_Found...")
      
      if not (IsReplaceALL or H.IsSectionActive) and not (H.IsSubWhereKeyWords and IsWisubSecOptionALL) then
        -- 'Only FIRST section will be used'
        H.DEBUG_GROUPS_print("NOTICE: making the groups ONLY one group (the whole file!)")
        GroupStartLine = {GroupStartLine[1]}
        GroupEndLine = {GroupEndLine[1]}
        SpecialKeyWordLine = {SpecialKeyWordLine[1]}
        H.KWinfo = {H.KWinfo[1]}
      end
      
      H.DEBUG_GROUPS_print("D: AFTER no REPLACEALL and no SECTIONACTIVE: #GroupStartLine = "..#GroupStartLine)
      
      if #GroupStartLine > 1 and (My.IsTextToAdd or My.IsToRemove) then
        if My.IsToRemove then
          -- H.printf("CG: My.IsToRemove = %s",tostring(My.IsToRemove))
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = CompressGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
          SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"CG",SectionsTable)
        end
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = ReverseGroupsOrder(GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo)
        -- GroupStartLine,GroupEndLine,SpecialKeyWordLine,H.KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,true,"H",H.KWinfo)
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"RO",SectionsTable)
        -- assert(#H.KWinfo == #GroupStartLine,"RO #H.KWinfo ~= #GroupStartLine")
      end
      
      -- assert(#H.KWinfo == #GroupStartLine,"FINAL #H.KWinfo ~= #GroupStartLine")
        
      -- NOW is the time to add 'Using'
      SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"Using ",SectionsTable)
      H.DEBUG_GROUPS_print("E: AFTER reversing order: #GroupStartLine = "..#GroupStartLine)
      --===================================================
            --   FROM NOW ON, THE GROUPS/SECTIONS ARE 'DEFINED'
      --===================================================
      
      My.CheckPoint(6)
      --used by IsReplaceONCE, IsReplaceFOLLOWING and IsOnlyOnePreceding
      --initialize
      local LastReplacementLine = GroupStartLine[1]
      
      local AtLeastOneReplacementDone = false
      
      -- H.printf(" AFTER FindGroup().My.IsHOSCreated = %s",tostring(My.IsHOSCreated))
      -- H.printf("AFTER FindGroup().My.IsHOESCreated = %s",tostring(My.IsHOESCreated))
      if My.IsHOSCreated then
        AtLeastOneReplacementDone = true
      end
      
-- EXTERNAL FUNCTION CALL: using VCT function call
      --*************************************************
      local function ExecuteFUNC(H, orgVCTproperty, exstringORG, VCTvalue, ex, funcArg)
        -- VCTvalue is the 'function name'
        -- orgVCTproperty is the 'Property name/value'
        -- exstringORG is the 'current value' of that Property OR ""
        -- ex is the retrieved 'NamedValue' OR nil
        -- funcArg is any 'extra arguments' to the function
        printf("[%s] [%s] [%s] [%s] [%s]",tostring(VCTvalue),tostring(orgVCTproperty),tostring(exstringORG),tostring(ex),tostring(funcArg))
        
        My.pos = strfind(VCTvalue,"()",1,true)
        -- print("My.pos = ["..tostring(My.pos).."]")
        
        -- if My.pos == nil then -- was already tested by My.IsFUNCexist
          -- -- problem, should not happen
          -- print(">>> "..H.gcERROR..[[ [BUG] "VCTvalue:My.pos == nil", please report ]]..H._zDEFAULT)
          -- H.Report("",[[>>> [BUG] "VCTvalue:My.pos == nil", please report]],"BUG")
          -- VCTvalue = ""
          -- return VCTvalue
        -- elseif My.pos == 0 then
        if My.pos == 0 then
          -- should not happen
          print(">>> "..H.gcWARNING.." [WARNING] Problem <"..VCTvalue..">: () used without a function name, check your script! "..H._zDEFAULT)
          H.Report("","Problem <"..VCTvalue..">: () used without a function name, check your script!","WARNING")
          VCTvalue = ""
          return VCTvalue
        end
        
        -- the script function
        My.func = "return conf."..strsub(VCTvalue,1,My.pos-1)..[[(...)]]
        -- print("==============  My.func = ["..tostring(My.func).."]  ==============")
        
        My.funcArg = [[","]]..tostring(funcArg):upper()
        if type(funcArg) == "table" then
          My.funcArg = [[","TableOfFuncArg]] -- ..tostring(funcArg)
        end
        
        My.ex = ex
        if ex == nil then
          My.ex = [[","NIL]]
        end                
        
        if not H.gIs_LEAN_MODE then
          print("                >>> "..H._zBRIGHTGREEN.."Script Function:"..H._zDEFAULT.." ["..strsub(VCTvalue,1,My.pos-1)..[[("]]..tostring(orgVCTproperty)..[[","]]..tostring(exstringORG)..My.ex..My.funcArg..[=[")]]=])
        end
        H.Report("",">>> Script Function: ["..strsub(VCTvalue,1,My.pos-1)..[[("]]..tostring(orgVCTproperty)..[[","]]..tostring(exstringORG)..My.ex..My.funcArg..[=[")]]=])

        -- MUST BE GLOBAL , otherwise pcall() fails !?
        tmp = load(My.func,"VCTfunc","t")
        if type(tmp) == "function" then
          My.status,My.funcResult = pcall(tmp, orgVCTproperty, exstringORG, ex, funcArg)

          if My.status then
            VCTvalue = tostring(My.funcResult)
          else
            print(">>> "..H.gcWARNING.." [WARNING] Problem <"..My.func.."()> returned this error message: <"..My.funcResult..">, check your script! "..H._zDEFAULT)
            H.Report("","Problem <"..My.func.."()> returned this error message: <"..My.funcResult..">, check your script!","WARNING")
            VCTvalue = ""
          end
          -- print("AMUMSS: "..My.func.." returned: "..VCTvalue)
        else
          -- should not happen
          print(">>> "..H.gcWARNING.." [WARNING] Problem <"..My.func.."()> is not a known Function, check your script! "..H._zDEFAULT)
          H.Report("","Problem <"..My.func.."()> is not a known Function, check your script!","WARNING")
        end
        
        if VCTvalue == nil then
          print(">>> "..H.gcNOTICE.." [NOTICE] <"..My.func.."()> returned NIL, check your script! "..H._zDEFAULT)
          H.Report("","<"..My.func.."()> returned NIL, check your script!","NOTICE")
          VCTValue = "" -- to prevent crash
        end
        
        return VCTvalue
      end
      --********************  END: local function ExecuteFUNC()  *****************************
      
      --*********************************************************************************
      local function TestOperand1(H, operand1, IsLockValue, lockedValue, IsLookup)
        if operand1 == nil then operand1 = 0 end
        if IsLookup == nil then IsLookup = false end
        if IsLockValue then
          if lockedValue == nil then
            lockedValue = operand1
            if not H.gIs_LEAN_MODE then
              print("                >>> Locked value is ["..tostring(lockedValue).."]")
            end
            H.Report("","                >>> Locked value is ["..tostring(lockedValue).."]")
          end
          operand1 = lockedValue
        elseif IsLookup then
          if not H.gIs_LEAN_MODE then
            print("                >>> Lookup value is ["..tostring(operand1).."]")
          end
          H.Report("","                >>> Lookup value is ["..tostring(operand1).."]")
        end
        return operand1,lockedValue
      end
      --*********************************************************************************
      
      H.IsLockValue = false --used by MATH_OPERATION L and LB
      H.lockedValue = nil
      
      --we have val_change_table that has all {property, value} to be changed with these prec_key_words
      H.jVCT = 0 --to iterate the val_change_table
      
      --=============================================== OUTER while loop ===================================
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering:  while H.jVCT <= (#val_change_table - 1) (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
      while H.jVCT <= (#val_change_table - 1) do
        MapFileTreeSharedListPING(H)
        
        --used to limit output
        H.numChangeTableRepl = 0
        
        --point to next VCTproperty/VCTvalue combo
        H.jVCT = H.jVCT + 1
        
        if H.jVCT == 1 then
          H.prn(">>> Entering 'outer' while, val_change_table["..H.jVCT.."]")
        else
          H.prn(">>> Looping 'outer' while val_change_table["..H.jVCT.."]")
        end
        
        -- VCT entry H.jVCT
        local VCTproperty = val_change_table[H.jVCT][1] or ""
        local VCTvalue = val_change_table[H.jVCT][2] or ""
        local VCTSaveValueName = val_change_table[H.jVCT][3] or ""
        local VCTfuncArg = val_change_table[H.jVCT][4] -- or "" -- was causing a bug
        
        My.IsFUNCexist = false
        My.FUNC_detected = false
        
        My.pos = strfind(VCTvalue,"()",1,true)
        if My.pos then
          -- could it be a user script function
          My.FUNC_detected = true
          My.FUNC = VCTvalue
          -- print("==============  My.FUNC = ["..My.FUNC.."]  ==============")
          My.IsFUNCexist = type(conf[strsub(VCTvalue,1,My.pos-1)]) == "function"
        end
        -- print("==============  My.IsFUNCexist = ["..tostring(My.IsFUNCexist).."]  ==============")
        
        H.DEBUG_CurrentLine_print("@@@ A: USING these: VCTproperty=["..VCTproperty.."] ".."VCTvalue=["..VCTvalue.."]".." VCTSaveValueName=["..VCTSaveValueName.."]")
        
        H.IsAddToStringValueFlag = (type(VCTvalue) == "string" and type(tonumber(VCTvalue)) ~= "number" and strfind(VCTvalue,"{:}",1,true) ~= nil)
        
        local IsOneReplacementDoneThisValue = false
        H.IsAutoIncrementOffset = false -- ONLY used to display or not "Auto-incremented"
        
        if H.gDEBUG_EXTRA_BEHAVIOR then
          print(" + === BEFORE EXTRA_BEHAVIOR:")
          print(" +                           H.jVCT: ["..tostring(H.jVCT).."]")
          print(" +                    My.IsVCTempty: ["..tostring(My.IsVCTempty).."]")
          print(" +          H.IsAutoIncrementOffset: ["..tostring(H.IsAutoIncrementOffset).."]")
          print(" +         H.IsAddToStringValueFlag: ["..tostring(H.IsAddToStringValueFlag).."]")
          print(" +       My.IsAllTheSameChangeTable: ["..tostring(My.IsAllTheSameChangeTable).."]")
          print(" +        My.IsAllChangeTableIGNORE: ["..tostring(My.IsAllChangeTableIGNORE).."]")
          print(" +                     IsLineOffset: ["..tostring(IsLineOffset).."]")
          print(" +                           offset: ["..tostring(offset).."]")
          print(" +                         VCTvalue: ["..tostring(VCTvalue).."]")
          print(" +                      VCTproperty: ["..tostring(VCTproperty).."]")
        end
        
  -- **********
  -- PRE-PROCESSING value_change_table(H.jVCT)
  -- **********

        --#########################################
        --  EXTRA BEHAVIOR section
        --#########################################
        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering: EXTRA BEHAVIOR section (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
        
        if not My.IsValueMatch and not H.IsListOfValues then
          H.DEBUG_CurrentLine_print("@@@ A: USING these BEFORE: VCTproperty=["..VCTproperty.."] ".."VCTvalue=["..VCTvalue.."]")
          --processing of IGNORE behavior
          if strupper(VCTproperty) == "IGNORE" and strupper(VCTvalue) == "IGNORE" then
            H.prn([[In BOTH VCTproperty="IGNORE" and VCTvalue="IGNORE"]])
            if IsSpecialKeyWords and not H.IsPrecedingKeyWords then
              H.prn("   with SPECIAL_KEY_WORDS first:")
              H.prn("      Using last word of PRECEDING_KEY_WORDS as 'VCTproperty'")
              
              if #prec_key_words == 1 and H.IsPrecedingKeyWords then --meaning not empty AND only one
                H.prn("      Using ONLY word of PRECEDING_KEY_WORDS as 'VCTproperty'")
                VCTproperty = prec_key_words[#prec_key_words]
              else
                H.prn("   Using last word of SPECIAL_KEY_WORDS as 'VCTproperty' when PRECEDING_KEY_WORDS >= 1")
                VCTproperty = spec_key_words[#spec_key_words]
              end
              
            elseif #prec_key_words > 2 then
              --TODO: works with text_to_add, we could check
              H.prn("   Using both last words as 'VCTproperty' and 'VCTvalue' with PRECEDING_KEY_WORDS > 2")
              VCTproperty = prec_key_words[#prec_key_words - 1]
              VCTvalue = prec_key_words[#prec_key_words]
              
            elseif #prec_key_words >= 1 then
              H.prn("   Using last word as 'VCTproperty' with PRECEDING_KEY_WORDS >= 1")
              VCTproperty = prec_key_words[#prec_key_words]
            end
            
            if not My.IsVCTempty then
              if ((IsLineOffset or My.IsAllTheSameChangeTable or My.IsAllChangeTableIGNORE) and H.jVCT > 1) then
                --for next value_change, increment offset
H.DEBUG_CurrentLine_print(" = = = = AUTO-INCREMENT offset on IGNORE,IGNORE")
                offset = offset + 1
                H.IsAutoIncrementOffset = true -- turn ON display "Auto-incremented"
              end              
            end
            
          elseif strupper(VCTproperty) == "IGNORE" then
            if not My.IsVCTempty then
              -- if H.IsListOfValues then
-- H.DEBUG_CurrentLine_print(" = = = = AUTO-INCREMENT offset on IGNORE,xyz with List of Values")
                -- IsLineOffset = true
                -- offset = SectionActive[H.jVCT] + 1 -- because _index starts at 0 
                -- -- H.IsAutoIncrementOffset = true -- turn ON display "Auto-incremented"
              -- else
                if ((IsLineOffset or My.IsAllTheSameChangeTable or My.IsAllChangeTableIGNORE) and H.jVCT > 1) then
H.DEBUG_CurrentLine_print(" = = = = AUTO-INCREMENT offset on IGNORE,xyz")
                  --for next value_change, increment offset
                  offset = offset + 1
                  H.IsAutoIncrementOffset = true -- turn ON display "Auto-incremented"
                end
              -- end
            end

            if IsSpecialKeyWords and not H.IsPrecedingKeyWords then
              H.prn("   with SPECIAL_KEY_WORDS only:")
              if not IsLineOffset and (not IsReplaceONCEInsideSection and not IsReplaceAllInsideSection) then
                VCTproperty = spec_key_words[#spec_key_words]
              end
              
            elseif #prec_key_words >= 1 and prec_key_words[1] ~= "" then
              --TODO: probably using a math_operation, we could check
              -- if My.IsMath_Operation or IsReplaceAllInSection or IsReplaceONCEInsideSection then
              if My.IsMath_Operation or IsReplaceAllInSection then
                --keep the "IGNORE" VCTproperty
              elseif not IsReplaceONCEInsideSection and not IsReplaceAllInsideSection then
                H.prn("   with PRECEDING_KEY_WORDS >= 1")
                VCTproperty = prec_key_words[#prec_key_words] --use the last PRECEDING_KEY_WORDS
              end
            end
          end
          
          -- ShowKeyWordInfo(H,spec_key_words,prec_key_words,H.IsPrecedingKeyWords,IsSpecialKeyWords,IsPrecedingFirstTRUE,IsUsingForeach_SKWG,item)
          H.DEBUG_CurrentLine_print("@@@ A: USING these  AFTER: VCTproperty=["..VCTproperty.."] ".."VCTvalue=["..VCTvalue.."]")
        end -- if not My.IsValueMatch and not H.IsListOfValues then
        
        if H.gDEBUG_EXTRA_BEHAVIOR then
          print(" + === AFTER EXTRA_BEHAVIOR:")
          print(" +                         VCTvalue: ["..tostring(VCTvalue).."]")
          print(" +                      VCTproperty: ["..tostring(VCTproperty).."]")
          print(" +                           offset: ["..tostring(offset).."]")
          print(" +          H.IsAutoIncrementOffset: ["..tostring(H.IsAutoIncrementOffset).."]")
          print(" + === === ===")
        end
        
        --#########################################
        -- END: EXTRA BEHAVIOR section
        --#########################################
        
        -- original case after EXTRA BEHAVIOR
        -- used for display
        H.orgVCTproperty = VCTproperty
        H.orgVCTvalue = VCTvalue

        if gDEBUG_VCTproperty then
          print("   VCTproperty = ["..tostring(VCTproperty).."]")
          print("      VCTvalue = ["..tostring(VCTvalue).."]")
        end

        -- if My.IsMath_Operation or strsub(VCTvalue,1,1) == "@" then
          -- print("   H.orgVCTproperty = ["..tostring(H.orgVCTproperty).."]")
          -- print("      H.orgVCTvalue = ["..tostring(H.orgVCTvalue).."]")
          -- print("   math_operation = ["..tostring(math_operation).."]")
          -- H.WFAK("Values BEFORE...")
        -- end
        
        My.IsInline = false
        if strsub(VCTvalue,1,1) == "@" then
          -- lyravega: Inline math operations
          -- For example, a targeted number value of 5 has a replacement of "*2". If AMUMSS did 5*2 and used it as the result, that could be perfect.
          My.IsInline = true
          My.value = strsub(VCTvalue,2):gsub("%s","") -- remove "@" and all space characters
          
          -- -- ***************************************************************************
          -- -- INLINE MATH_OPERATION test
              -- -- >>> @: always 1st character of string, triggers evaluation of INLINE MATH_OP
              -- -- >>> optNum1: required when MATH_OP is of type SUFFIX, defaults to '0' for + and -, otherwise '1'
              -- -- >>> MATH_OP: one of the MATH_OPERATION, see how rules apply
              -- -- >>> optNum2: required when MATH_OP is one of {+, -, *, /, //, %, ^} (not of type SUFFIX)
          -- local test = { -- test value, resulting math_op, resulting VCTvalue
                        -- {"@*5", "*", "5"},
                        -- {"@*-5", "*", "-5"},
                        -- {"@*5.45", "*", "5.45"},
                        -- {"@*-5.45", "*", "-5.45"},
                        -- {"@+1600", "+", "1600"},
                        -- {"@-+1600", "-", "+1600"},
                        -- {"@+-1600", "+", "-1600"},
                        -- {"@++1600", "+", "+1600"},
                        -- {"@0.6*F:MaxAmount", "*F:MaxAmount", "0.6"},
                        -- {"@+0.6*F:MaxAmount", "*F:MaxAmount", "+0.6"},
                        -- {"@-0.6*F:MaxAmount", "*F:MaxAmount", "-0.6"},
                        -- {"@!$20/L:5", "!$/L:5", "20"},
                        -- {"@!$+20/L:5", "!$/L:5", "+20"},
                        -- {"@!$20.5/L:5.2", "!$/L:5.2", "20.5"},
                        -- {"@!$-20.5/L:5.2", "!$/L:5.2", "-20.5"},
                        -- }
          -- for i=1,#test do
            -- My.value = test[i][1]
            -- print("")
            -- print("      My.value = ["..tostring(My.value).."]")
            -- My.value = strsub(My.value,2) -- remove "@"
            -- print("        A:test = ["..tostring(My.value).."]")
            
            -- My.tmp = My.value:gsub("[!%$]","")
            -- print("      A:My.tmp = ["..tostring(My.tmp).."]")
            -- My.VCTvalue = string.match(My.tmp,"^([%+%-%d%.]+)")
            -- print(" A:My.VCTvalue = ["..tostring(My.VCTvalue).."]")
            
            -- if strfind(My.value,":",1,true) then
              -- -- a SUFFIX math_op
              -- if not tonumber(My.VCTvalue) then
                -- print(">>> [WARNING] INLINE MATH_OP missing number/operation BEFORE ':'")
              -- end
              
              -- My.MATH_OP = strgsub(My.value,tostring(My.VCTvalue),"",1)
            -- else
              -- -- only {+, -, *, /, %, //, ^}
              -- My.MATH_OP = string.match(My.value,"^([!%$%+%-%*/*%%%^])")
              -- -- remove math_op SUFFIX
              -- My.VCTvalue = strgsub(My.value, "^[!%$]", ""):gsub("^[%+%-%*/*%%%^]","")
            -- end
            -- My.tmp = tostring(My.MATH_OP) == test[i][2]
            -- print("       >>>  My.MATH_OP = ["..tostring(My.MATH_OP).."] "..tostring(My.tmp).." ["..test[i][2].."]")
            -- My.tmp = tostring(My.VCTvalue) == test[i][3]
            -- print("       >>> My.VCTvalue = ["..tostring(My.VCTvalue).."] "..tostring(My.tmp).." ["..test[i][3].."]")
            
          -- end
          -- H.WFAK("TEST INLINE")
          -- -- ***************************************************************************

          VCTvalue = string.match(My.value:gsub("!%$",""),"^([%+%-%d%.]+)")
          
          if strfind(My.value,":",1,true) then
            -- a SUFFIX math_op
            if not tonumber(VCTvalue) then
              print(">>> "..H.gcWARNING.." [WARNING] INLINE MATH_OP missing number/operation BEFORE ':' "..H._zDEFAULT)
              H.Report("","INLINE MATH_OP missing number/operation BEFORE ':'","WARNING")
            end
            
            math_operation = strgsub(My.value,tostring(VCTvalue),"",1)
          else
            -- only {+, -, *, /, %, //, ^}
            math_operation = string.match(My.value,"^([!%$%+%-%*/*%%%^])")
            -- remove math_op SUFFIX
            VCTvalue = strgsub(My.value, "^[!%$]", ""):gsub("^[%+%-%*/*%%%^]","")
          end
          -- simulate normal VCTvalue
          H.orgVCTvalue = VCTvalue
          
          H.DEBUG_INLINEmath_op_print("  ==========================  ")
          H.DEBUG_INLINEmath_op_print("      VCTvalue = ["..tostring(VCTvalue).."]")
          H.DEBUG_INLINEmath_op_print("   H.orgVCTvalue = ["..tostring(H.orgVCTvalue).."]")
          H.DEBUG_INLINEmath_op_print("math_operation = ["..tostring(math_operation).."]")
          -- H.WFAK("INLINE MATH_OP values...")
        end -- if strsub(VCTvalue,1,1) == "@" then
        
        --next line should be done only once for each VCT
        H.IsRegular = false
        if not IsReplaceRAW then
          VCTproperty,H.IsRegular = H.makeRegExUppercase(VCTproperty)
        else
          VCTproperty = VCTproperty:upper()
        end
        H.prn("VCTproperty = ["..VCTproperty.."], H.IsRegular = "..tostring(H.IsRegular))
        
        if H.IsRegular then
          IsReplaceALL = true
          IsReplaceONCE = false
        end
        
        if H.jVCT == 1 then --on the first possible VCT even if NONE
          if IsEditSection then
            if not H.gIs_LEAN_MODE then
              print("       >>>>> "..H._zBRIGHTORANGE.."Editing section named"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_edit..[["]]..H._zDEFAULT.."]")
              if My.IsKeepSection then
                if sec_save_to ~= "" then
                  print("       >>>>> "..H._zBRIGHTORANGE.."    Saving to section"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_save_to..[["]]..H._zDEFAULT.."] on disk")
                elseif sec_edit ~= "" then
                  print("       >>>>> "..H._zBRIGHTORANGE.." Saving section named"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_edit..[["]]..H._zDEFAULT.."] to disk")
                end
              end
            end
            H.Report("","       >>>>> Editing section named ["..[["]]..sec_edit..[["]].."]")
            if My.IsKeepSection then
              if sec_save_to ~= "" then
                H.Report("","       >>>>>     Saving to section ["..[["]]..sec_save_to..[["]].."] on disk")
              elseif sec_edit ~= "" then
                H.Report("","       >>>>>  Saving section named ["..[["]]..sec_edit..[["]].."] to disk")
              end
            end
          end
          
          H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering: OnFirstVCT() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
          -- Done ONLY on the 1st VCT entry
          OnFirstVCT(H,section_up_preceding,section_up_special,section_up
                ,IsSpecialKeyWords,spec_key_words
                ,IsPrecedingFirstTRUE,H.IsPrecedingKeyWords,prec_key_words
                ,IsWhereKeyWords,H.IsSubWhereKeyWords
                ,IsEditSection
                ,H.IsAfterKeyWords,H.a_key_words
                -- ,H.IsMainSection,H.IsSubLevel
                )
                
          if My.IsSaveSectionTo then
            --save the first section to a file in the TOOLS\SavedSections folder using the SEC_SAVE_TO name.xml
            --we overwrite any existing file with that name
            -- H.thisSection = ""
            -- for m=GroupStartLine[1],GroupEndLine[1] do
              -- local line = TextFileTable[m]
              -- H.thisSection = H.thisSection..line.."\n"
            -- end
            H.DEBUG_SEC_print("@@@@@ D: #TextFileTable = "..#TextFileTable)
            H.DEBUG_SEC_print("@@@@@ D: For section "..tostring(GroupStartLine[1]).."-"..tostring(GroupEndLine[1])..", on the first possible VCT")
            
            -- Note: search THIS below for the actual code that
            --    get section and remove the _id/_index
            
-- if H.IsSectionActive and #GroupStartLine == 1 then
  -- -- check if this is a list of values
  -- local IsListOfValues = false
  -- local name = strmatch(TextFileTable[GroupStartLine[1]],[["(.*)"]])
  -- for i=GroupStartLine[1]+1,GroupEndLine[1] do
    -- if name == strmatch(TextFileTable[i],[["(.*)"]]) and strmatch(TextFileTable[i],[[/>]])
      -- IsListOfValues = true
      -- break
    -- end
  -- end
  -- if IsListOfValues then
    -- -- find the line(s) with the proper SECTION_ACTIVE values
    
  -- end
-- end


            -- print(">>> TextFileTable:")
            -- for i=1,#TextFileTable do
              -- H.printf(">>> %d: [%s]",i,TextFileTable[i])
            -- end
            H.thisSection = ""
            if H.IsEXMLflagUPDATESECTION then
              H.thisSection = table.concat(TextFileTable,"\n",GroupStartLine[1],GroupEndLine[1]):gsub(H.modFlag.." %w*","")
            else
              H.thisSection = table.concat(TextFileTable,"\n",GroupStartLine[1],GroupEndLine[1]):gsub([[ _.-=".-"]], ""):gsub(H.modFlag.." %w*","")
            end
            
            H.DEBUG_SEC_print("@@@@@ D0: H.thisSection = ("..#H.thisSection..") ["..strsub(H.thisSection,1,300).."...]")
            H.DEBUG_SEC_print("@@@@@ D: sec_save_to = <"..sec_save_to..">")
            
            -- ALWAYS save it internally!!!
            -- if H.gSection[sec_save_to] then
              -- --was saved internally, update content
              H.DEBUG_SEC_print("@@@@@ D: Saving content of SEC_save_to to internal list")
              H.gSection[sec_save_to] = H.thisSection
              IsOneReplacementDoneThisValue = true
              SaveSectionDone = true
            -- end
            
            if My.IsKeepSection then
              H.DEBUG_SEC_print([[@@@@@ D: Writing SEC_save_to DISK to TOOLS\SavedSections folder]])
              if not H.gIs_LEAN_MODE then  
                print("         >>> "..H._zBRIGHTORANGE.."Saving section"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_save_to..[["]]..H._zDEFAULT.."] to disk ("..(GroupEndLine[1]-GroupStartLine[1]+1).." lines)")
              end
              H.Report("","         >>> Saving section ["..[["]]..sec_save_to..[["]].."] to disk ("..(GroupEndLine[1]-GroupStartLine[1]+1).." lines)")
              H.WriteToFile(H.thisSection,H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..sec_save_to..[[.xml]])
            end
          end
        end
        
        H.DEBUG_GROUPS_print("F: #GroupStartLine = "..#GroupStartLine)
        H.DEBUG_GROUPS_print("F: NumFoundSections = "..H.NumFoundSections)
        
        -- if not H.IsMainSection and H.NumFoundSections > 0 and H.jVCT == 1 then --just say on the first val_change_table
        if H.NumFoundSections > 0 and H.jVCT == 1 then --just say on the first val_change_table
          local so = ""
          if H.IsSectionActive then
            for i=1,#SectionActive do
              if SectionActive[i] == math.huge then
                SectionActive[i] = "LAST"
              end
              so = so..SectionActive[i]..", "
            end
            so = strsub(so,1,-3)
          end
          
          if numGroupsBeforeSectionActive > 1 or (H.IsSectionActive and H.IsListOfValues) then
            -- when multiple sections were found or list of values
            tFindGroupTotal = os.clock() - tFindGroup
            
            H.Report("","       >>>>> Found "..numGroupsBeforeSectionActive.." valid candidate sections in "..H.dClock(tFindGroupTotal))
            if not H.gIs_LEAN_MODE then print("       >>>>> Found "..numGroupsBeforeSectionActive.." valid candidate sections in "..H.dClock(tFindGroupTotal)) end
            
            if not (IsReplace or H.IsSectionActive) then
              H.Report("","KEY_WORDS located more than one section and REPLACE_TYPE/SECTION_ACTIVE are missing!","NOTICE")
              if not H.gIs_LEAN_MODE then print(">>> "..H.gcNOTICE.." [NOTICE] KEY_WORDS located more than one section and REPLACE_TYPE/SECTION_ACTIVE are missing! "..H._zDEFAULT) end
            end
            
            if H.IsSectionActive then
              H.Report("","       >>>>> using ACTIVE section(s) as requested: ["..so.."]")
              if not H.gIs_LEAN_MODE then print("       >>>>> using ACTIVE section(s) as requested: ["..so.."]") end
              
              if H.IsListOfValues then
                if not H.gIs_LEAN_MODE then print([[       >>>>> SECTION_ACTIVE is from a list of values]]) end
                H.Report("",[[       >>>>> SECTION_ACTIVE is from a list of values]])
              end
              
              -- if IsReplaceALL then
                -- H.Report("",[[       >>>>> SECTION_ACTIVE forces REPLACE_TYPE = "ALL"]])
                -- if not H.gIs_LEAN_MODE then print([[       >>>>> SECTION_ACTIVE forces REPLACE_TYPE = "ALL"]]) end
              -- end
              
              -- if IsReplaceONCE then
                -- H.Report("",[[       >>>>> negative SECTION_ACTIVE forces REPLACE_TYPE = "ONCE"]])
                -- if not H.gIs_LEAN_MODE then print([[       >>>>> negative SECTION_ACTIVE forces REPLACE_TYPE = "ONCE"]]) end
              -- end
              
            elseif not IsReplaceONCE and (IsReplaceALL or IsReplaceAllInSection or IsReplaceAllInsideSection or(My.IsOrgReplace_typeEmpty and not (My.IsTextToAdd or My.IsToRemove))) then
                H.Report("","       >>>>> using ALL valid sections as requested")
                if not H.gIs_LEAN_MODE then print("       >>>>> using ALL valid sections as requested") end
                
            else
              H.Report("",[[       >>>>> 'Only FIRST section will be used']],"")
              if not H.gIs_LEAN_MODE then print([[       >>>>>]]..H.gcNOTICE..[[ Only FIRST section is used ]]..H._zDEFAULT.." ") end
            end
          end
          
          -- print("")
          -- ********************  This IS THE MASTER ShowSections()  **************************
          -- the ONLY one to ShowSections() in production code
          ShowSections(H,SectionsTable,"  ")
          
          if H.IsSectionActiveValuesNotUsed then
            print(">>> "..H.gcNOTICE.." [NOTICE] SECTION_ACTIVE values were not used, some out of range: ["..so.."] "..H._zDEFAULT)
            H.Report("","SECTION_ACTIVE values were not used, some out of range: ["..so.."]","NOTICE")
          end
          -- ***********************************************************************************
          -- print("")
        end
        
        H.DEBUG_CurrentLine_print("@@@ B: USING these: VCTproperty=["..VCTproperty.."] ".."VCTvalue=["..VCTvalue.."] ".."VCTSaveValueName=["..VCTSaveValueName.."]")
        local newIsValueMatchType = IsValueMatchType
        if not IsValueMatchType then
          --none specified by the user
          --let us force it to be of the same type as the new VCTvalue
          
          local VCTvalueTmp = GetVCTvalueTmp(VCTvalue)
          local ValueTypeIsNumber, ValueIsInteger = CheckValueType(VCTvalueTmp,false)
          if ValueTypeIsNumber then
            value_match_type = "NUMBER"
          else
            value_match_type = "STRING"
          end
          newIsValueMatchType = true
        end
        
        -- if My.IsMath_Operation or strsub(VCTvalue,1,1) == "@" then
          -- print("   H.orgVCTproperty = ["..tostring(H.orgVCTproperty).."]")
          -- print("      H.orgVCTvalue = ["..tostring(H.orgVCTvalue).."]")
          -- print("   math_operation = ["..tostring(math_operation).."]")
          -- H.WFAK("Values AFTER...")
        -- end
        
        -- if not H.IsListOfValues then
          H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering: PrepareInfoForUser() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
          -- Done for EACH VCT entry
          PrepareInfoForUser(H,H.orgVCTproperty,H.orgVCTvalue,VCTSaveValueName
                            ,My.IsMath_Operation,math_operation,My.IsInline
                            ,My.IsInteger_to_floatPRESERVE,My.IsInteger_to_floatFORCE
                            ,My.IsValueMatch,val_match,IsValueMatchOptionsMatch,value_match_options,value_match_type,newIsValueMatchType
                            ,IsLineOffset,line_offset -- ,H.IsMainSection,H.IsSubLevel,H.subLevelNumber
                            ,IsSpecialKeyWords,spec_key_words
                            ,H.IsPrecedingKeyWords,prec_key_words
                            ,My.IsHOSCreated,My.IsCreateHOESTRUE
                            -- ,My.IsCreateHOSTRUE,My.IsCreateHOESTRUE
                            ,IsWhereKeyWords,WhereKeyWords
                            ,H.IsSubWhereKeyWords,IsWisubSecOptionALL,SubWhereKeyWords
                            ,IsWiSecLopAND,IsWiSecLopNOR,IsWisubSecLopAND,IsWisubSecLopNOR
                            ,My.IsTextToAdd,H.IsReplaceADDAFTERLINE,H.IsReplaceADDAFTERSECTION,My.IsAuto_GNH
                            ,My.IsToRemove,My.IsToRemoveLINE,My.IsToRemoveSECTION,My.IsToRemoveHBOS
                            ,IsReplace,IsReplaceRAW,IsReplaceONCE,IsReplaceONCEInsideSection,IsReplaceALL,IsReplaceAllInSection,IsReplaceAllInsideSection,IsReplaceFOLLOWING
                            ,IsLargeNumOfReplacement,H.RememberNumberOfGroups,H.NumFoundSections
                            ,My.IsFUNCexist,My.FUNC_detected
                            )
        -- end
        
        -- if not H.gIs_LEAN_MODE and not IsNotice_off and (tonumber(VCTvalue) and tonumber(VCTvalue) > 99999999) then
          -- --MBINCompiler may produce a problematic MBIN that once decompiled will have a value of "1.0E+7"
          -- print(">>> "..H.gcNOTICE..[[ [NOTICE] MBINCompiler may generate a MBIN that once decompiled will have a value like "1E+09" ]]..H._zDEFAULT)
          -- print(H.gcNOTICE..[[         xxxxx Your script contains a value over "99999999" xxxxx ]]..H._zDEFAULT)
          -- print(H.gcNOTICE..[[         A value like "100000123" will become "100000120", (it won't be exact) ]]..H._zDEFAULT)
          -- print(H.gcNOTICE..[[         Bigger values may become like "1E+09" ]]..H._zDEFAULT)
          -- print(H.gcNOTICE..[[         That could prevent NMS from using the mod ]]..H._zDEFAULT)
          -- H.Report("",[[MBINCompiler may generate a MBIN that once decompiled will have a value like "1E+09"]],"NOTICE")
          -- H.Report("",[[       xxxxx Your script contains a value over "99999999" xxxxx]],"")
          -- H.Report("",[[       A value like "100000123" will become "100000120", (it won't be exact)]],"")
          -- H.Report("",[[       Bigger values may become like "1E+09"]],"")
          -- H.Report("",[[       That could prevent NMS from using the mod]],"")
        -- end
        
        if not H.gIs_LEAN_MODE and #GroupStartLine > 1 and (My.IsTextToAdd or My.IsToRemove) then
          --we reversed the order of the Groups
          --so that we add or remove from the bottom up
          H.Report("","       >>>>> Processing Sections in reverse order for ADD/REMOVE <<<<<")
          if not H.gIs_LEAN_MODE then
            print("\n       >>>>> Processing Sections in reverse order for ADD/REMOVE <<<<<")
            print("")
          end
        end
        
  -- **********
  -- END PRE-PROCESSING value_change_table(H.jVCT)
  -- **********
        
        thisGroup = 0 --to iterate thru GroupStartLine/GroupEndLine groups
        
        -- collectgarbage("step",0)
        -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." FORCED collectgarbage (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
        
        --=============================================== INNER while loop ===================================
        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering: while there are groups of lines (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
        
        -- local repl_done

        -- For EACH valid section found
        while thisGroup <= #GroupStartLine - 1 do
          H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: 'while there are groups of lines' (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
          
          MapFileTreeSharedListPING(H)
          
          -- repl_done = false
          
          --go explore next group for the current VCTproperty
          thisGroup = thisGroup + 1
          if thisGroup == 1 then
            H.prn(">>> Entering 'groups while' at thisGroup = "..thisGroup.." for H.jVCT = "..H.jVCT)
          else
            H.prn(">>> Looping 'groups while' at thisGroup = "..thisGroup.." for H.jVCT = "..H.jVCT)
          end
          
          if H.jVCT == 1 and not My.IsTextToAdd and strfind(TextFileTable[GroupStartLine[thisGroup]],[[">]],1,true) then
            -- ==> doing this ONLY on first VCT
            local spacer = "    "
            local part1 = ""
            if My.IsExml_id then
              -- part1 = [[>>> Added/changed _id="]]..H.exml_id..[["]]
              -- print(H._zBRIGHTORANGE..[[                ]]..part1..H._zDEFAULT)
              -- H.Report("",spacer..part1)
              local s = strmatch(TextFileTable[GroupStartLine[thisGroup]],[[" _id="(.-)"]])
              if s then
                TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[_id=".-">]], [[_id="]]..H.exml_id..[[">]]..H.modCHANGED) -- .." Z2"
              else
                TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[">]], [[" _id="]]..H.exml_id..[[">]]..H.modADDED) -- .." Z3"
              end
              ReplNumber = ReplNumber + 1
              IsOneReplacementDoneThisValue = true
              AtLeastOneReplacementDone = true
            end
            if My.IsExml_index and not H.IsReplaceWholeSECTION then
              -- part1 = [[>>> Added/changed _index="]]..H.exml_index..[["]]
              -- print(H._zBRIGHTORANGE..[[                ]]..part1..H._zDEFAULT)
              -- H.Report("",spacer..part1)
              local s = strmatch(TextFileTable[GroupStartLine[thisGroup]],[[" _index="(.-)"]])
              if s then
                TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[_index=".-">]], [[_index="]]..H.exml_index..[[">]]..H.modCHANGED) -- .." Z4"
              else
                TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[">]], [[" _index="]]..H.exml_index..[[">]]..H.modADDED) -- .." Z5"
              end
              ReplNumber = ReplNumber + 1
              IsOneReplacementDoneThisValue = true
              AtLeastOneReplacementDone = true
            end
            
            if My.IsExml_flags then
              if H.IsEXMLflagOVERWRITE then
                if strfind(TextFileTable[GroupStartLine[thisGroup]],[[ _overwrite="true"]],1,true) == nil then
                  print(spacer..H._zBRIGHTGREEN.."-> On line "..GroupStartLine[thisGroup]..[[, ]]..H._zBRIGHTORANGE..[[Added _overwrite="true"]]..H._zDEFAULT)
                  H.Report("",spacer.."-> On line "..GroupStartLine[thisGroup]..[[, Added _overwrite="true"]])
                  
                  TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[">]], [[" _overwrite="true">]]..H.modADDED) -- .." Z6"
                  ReplNumber = ReplNumber + 1
                  IsOneReplacementDoneThisValue = true
                  AtLeastOneReplacementDone = true
                else
                  print(spacer..H._zBRIGHTGREEN.."-> On line "..GroupStartLine[thisGroup]..[[, ]]..H._zBRIGHTORANGE..[[_overwrite="true" already exist]]..H._zDEFAULT)
                  H.Report("",spacer.."-> On line "..GroupStartLine[thisGroup]..[[, _overwrite="true" already exist]])
                end
              end
              
              -- -- no need to do this: the section is removed in the MXML or not
              -- --   and MXMLtoEXML() will detect if the section was removed
              -- if H.IsEXMLflagREMOVE then
                -- local spacer = "    "
                -- local part1 = "-> On line "..GroupStartLine[thisGroup]..[[, Added _remove="true"]]
                -- print(spacer..part1)
                -- H.Report("",spacer..part1)
                
                -- TextFileTable[GroupStartLine[thisGroup]] = strgsub(TextFileTable[GroupStartLine[thisGroup]], [[">]], [[" _remove="true">]])
                -- IsOneReplacementDoneThisValue = true
                -- AtLeastOneReplacementDone = true
              -- end
            end
          end
          
          local iGLine
          if H.jVCT == 1 and (IsReplaceONCEInsideSection or IsReplaceAllInsideSection) then
            -- we want to skip to the 1st line INSIDE the section
H.DEBUG_CurrentLine_print(" = = = = POINT to 2nd line")
            iGLine = GroupStartLine[thisGroup] -- because iGLine will be incremented in the while loop
          elseif H.IsListOfValues then
H.DEBUG_CurrentLine_print(" = = = = POINT to the 1st/next SECTION_ACTIVE line")
-- H.printf("GroupStartLine[%d] = %d, SectionActive[%d] = %d",thisGroup,GroupStartLine[thisGroup],H.jVCT,SectionActive[H.jVCT])
            
            if not H.gIs_LEAN_MODE then
              print("                >>> Using SECTION_ACTIVE = ["..SectionActive[H.jVCT].."]")
            end
            H.Report("","                >>> Using SECTION_ACTIVE = ["..SectionActive[H.jVCT].."]")

            iGLine = GroupStartLine[thisGroup] + SectionActive[H.jVCT] -- iGLine will be incremented in the while loop
          else
H.DEBUG_CurrentLine_print(" = = = = STAY on 1st line")
            iGLine = GroupStartLine[thisGroup] - 1 -- -1 because iGLine will be incremented in the while loop
          end
          
          H.DEBUG_CurrentLine_print("    >>> we are at line "..(iGLine+1).." in section ["..thisGroup.."] = "..(iGLine+1).."-"..GroupEndLine[thisGroup])
          
          local StartLine = GroupStartLine[thisGroup] --to remember the section 'start line' for the 'out of section' NOTICE below
          local EndLine = GroupEndLine[thisGroup] --to remember the section 'end line' for the 'out of section' NOTICE below
          -- local EndLineBackup = GroupEndLine[thisGroup] --to remember the section 'end line' for restoring it
          
          -- if IsReplaceFOLLOWING then
            -- --GroupEndLine[thisGroup] was adjusted below
            -- if not H.gIs_LEAN_MODE then print("                >>> FOLLOWING forces line "..iGLine.." as base to "..H._zBRIGHTGREEN.."END of file"..H._zDEFAULT) end
            -- H.Report("","                >>> FOLLOWING forces line "..iGLine.." as base to END of file")
            -- GroupEndLine[thisGroup] = #TextFileTable
            
          if IsOnlyOnePreceding then
            if LastReplacementLine < GroupStartLine[thisGroup] then
              LastReplacementLine = GroupStartLine[thisGroup]
            end
            
            H.pv("LastReplacementLine: "..LastReplacementLine)
            iGLine = LastReplacementLine
            if not H.gIs_LEAN_MODE and not IsLargeNumOfReplacement then
              print("                >>> Only one PRECEDING_KEY_WORDS forces line "..iGLine.." as base...")
            end
            H.Report("","               >>> Only one PRECEDING_KEY_WORDS forces line "..iGLine.." as base...")
          -- elseif IsReplaceONCEInsideSection or IsReplaceAllInsideSection then
            -- --use the 2nd line of the new group
            -- iGLine = iGLine + 1
            -- H.pv("NewGroupLine: "..iGLine)
          elseif IsReplaceONCE then
            --using the 1st line of the new group
            H.pv("NewGroupLine: "..iGLine)
          end
          
          -- if IsLineOffset and iGLine == 0 then
            -- do we need to apply the offset???
            --    it is handle in each case below
          -- end
          
          -- can we FAST find the lines matching VCTproperty?
          My.linesNumFound = {}
          if not IsReplaceRAW then
            if not My.IsVCTempty then
              -- print("==>>> "..tostring(VCTproperty),tostring(H.IsRegular),#TextFileTable,tostring(iGLine),tostring(GroupEndLine[thisGroup]))
              My.linesNumFound = H.GetPropertyEXT(VCTproperty,H.IsRegular,TextFileTable,iGLine,GroupEndLine[thisGroup]) -- must be iGLine for IGNORE to work, do not change, was iGLine + 1

              if H.IsSubLevel then
                H.lineLevels = LineLevels(TextFileTable)
                for i=1,#My.linesNumFound do
                  -- printf("%d: %d",H.lineLevels[My.linesNumFound[i]],My.linesNumFound[i])
                  if H.lineLevels[My.linesNumFound[i]] ~= H.subLevelNumber then
                    My.linesNumFound[i] = "NIL"
                  end
                end
                My.linesNumFound = H.refreshTable(My.linesNumFound)
              end

              if #My.linesNumFound < My.gMaxNumberOfGroups then
                IsLargeNumOfGroupsFound = false
                -- printf("IsLargeNumOfGroupsFound = %s",tostring(IsLargeNumOfGroupsFound))
              end
            -- else
              -- -- empty VCT, let's find the lines at the sub-level
              -- if H.IsSubLevel then
                -- H.lineLevels = LineLevels(TextFileTable)
                -- print("RRR RRR RRR RRR")
                -- H.printf("H.subLevelNumber = %d",H.subLevelNumber)
                -- H.printf("#H.lineLevels = %d",#H.lineLevels)
                -- for i=1,#GroupStartLine do
                  -- H.printf("   GroupStartLine[i] = %d, H.lineLevels[GroupStartLine[i]] = %d",GroupStartLine[i],H.lineLevels[GroupStartLine[i]])
                  -- if H.lineLevels[GroupStartLine[i]] == H.subLevelNumber then
                    -- H.printf("      Line %d: [%s]",i,TextFileTable[i])
                  -- end
                -- end
                -- print("RRR RRR RRR RRR")
              -- end
            end
            
            -- print(" = = = = = = = My.linesNumFound")
            -- for i=1,#My.linesNumFound do
              -- printf("Found line: %d",My.linesNumFound[i])
            -- end
            -- print(" = = = = = = =")
          end
          
          -- to iterate thru My.linesNumFound table
          My.linesNumFoundIndex = 0
          
          My.SearchGroupRange = tostring(iGLine + 1).."-"..tostring(GroupEndLine[thisGroup])
          
          if not My.IsTextToAdd and not My.IsToRemove then
            My.tmp = ""
            if My.IsKeepSection then
              My.tmp = " to disk"
            end
            
            My.tmp2 = ""
            if H.IsSubLevel then
              My.tmp2 = " at SUB_LEVEL "..H.subLevelNumber
            end
            
            if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
              if not H.gIs_LEAN_MODE then
                if #My.linesNumFound > 0 then
                  print("                >>> Searching in lines "..My.SearchGroupRange..My.tmp2..[[...]])
                end
                if My.IsSaveSectionTo then
                  print("                >>> "..H._zBRIGHTORANGE.."Saved section"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..[["]]..sec_save_to..[["]]..H._zDEFAULT.."]"..My.tmp)
                end
              end
            end
            
            if #My.linesNumFound > 0 then
              H.Report("","                >>> Searching in lines "..My.SearchGroupRange..My.tmp2..[[...]])
            end
            if My.IsSaveSectionTo then
              H.Report("","                >>> Saved section ["..[["]]..sec_save_to..[["]].."]"..My.tmp)            
            end
            
          else
            H.DEBUG_CurrentLine_print("   >>> SearchGroupRange = "..My.SearchGroupRange)
          end
          
          --using while because we can change the value of iGLine and GroupEndLine
          --that is useful with line_offset, text_to_add and maybe other manipulations
          
          -- print("Just before the BIG INNER WHILE: ["..VCTproperty.."] ["..VCTvalue.."], about to process line "..iGLine + 1)
          My.InWhile = false
          
          --=============================================== SECTION while loop ===================================
          --loop thru all the lines in this group
          H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." BEFORE entering: 'while lines in group' (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
          -- For EACH line in this section
          while iGLine <= (GroupEndLine[thisGroup] - 1) and (#My.linesNumFound > 0 or My.IsTextToAdd or My.IsToRemove or IsReplaceRAW or VCTproperty == "IGNORE") do
            if not My.InWhile then
              H.DEBUG_CurrentLine_print("    >>> Entering 'inner' 'lines in group["..thisGroup.."]' while at line "..iGLine.." for H.jVCT = "..H.jVCT)
              -- print("This line: ["..TextFileTable[iGLine].."]")
              My.InWhile = true
            -- else
              -- --generates lots of lines
              -- -- H.pv(">>> Looping 'inner' while at line "..iGLine.."...")
            end
            -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." LOOPING the while lines in group (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
            
-- **********
-- PRE-PROCESSING group(thisGroup) at line iGLine
-- **********
            -- no replacement done so far in this line
            repl_done = false
            
            if not (H.IsReplaceATLINE or H.IsAddATLINE) or ((H.IsReplaceATLINE or H.IsAddATLINE) and VCTvalue == "IGNORE") then
              if #My.linesNumFound > 0 then
                My.linesNumFoundIndex = My.linesNumFoundIndex + 1
                if My.linesNumFoundIndex <= #My.linesNumFound then
                  iGLine = My.linesNumFound[My.linesNumFoundIndex]
                  H.DEBUG_CurrentLine_print(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT..": ".."@@@ Using linesNumFound["..My.linesNumFoundIndex.."] at "..iGLine)
                else
                  H.DEBUG_LoopBreak_print("Z: break out of this group on 'linesNumFoundIndex > #linesNumFound' to next group")
                  break
                end
              else
                iGLine = iGLine + 1 -- next line (old way when VCT is empty)
              end
                -- ??? required now ??? with the Break at the end after the replacement
                -- My.linesNumFound[1] = nil -- reset for next iGLine for now...  should break out of while loop when only one found
            end
            
            -- if H.IsMainSection then
              -- -- we need to stay in the main section
              -- while H.lineLevels[iGLine] ~= 1 do
                -- iGLine = iGLine + 1
              -- end
            -- end

            local CurrentLine = iGLine --used with text_to_add and to_remove
            
            local line = TextFileTable[iGLine]
            H.DEBUG_CurrentLine_print("@@@ CurrentLine: "..iGLine.." ["..tostring(line).."]")
            
            if line == nil then
              if not My.IsSaveSectionTo then
                print(">>> "..H.gcWARNING.." [WARNING] Problem with [current line] being nil "..H._zDEFAULT)
                H.Report("","Problem with [current line] being nil","WARNING")
              end
              break
            end
-- **********
-- END PRE-PROCESSING group(thisGroup) at line iGLine
-- **********
            
            -- print("VCTValue = <"..VCTvalue..">")
            -- print([[VCTvalue:gsub("%s+","") = <]]..tostring( (VCTvalue:gsub("%s+","")) )..">")
            -- print([[VCTvalue:gsub("%s+",""):find("GUIF({",1,true) = <]]..tostring( (VCTvalue:gsub("%s+",""):find("GUIF({",1,true)) )..">")
            if VCTvalue:gsub("%s+",""):find("GUIF({",1,true) then
              -- print("A: got here with VCTvalue = <"..VCTvalue..">")
              tmp = load("return "..VCTvalue,"GUIF","t")
              -- print("type(tmp) = <"..type(tmp)..">")
              if type(tmp) == "function" then
                VCTvalue = tostring(tmp())
                VCTvalue = tmp() -- execute GUIF()

                if type(VCTvalue) == "boolean" then
                  -- translate to NMS type
                  if VCTvalue then
                    VCTvalue = "True"
                  else
                    VCTvalue = "False"
                  end
                end
                -- print("@@@ VCTvalue = ["..VCTvalue.."]")
                if VCTvalue == nil then
                  print(">>> "..H.gcNOTICE.." [NOTICE] GUIF() returned NIL, check your script! "..H._zDEFAULT)
                  H.Report("","GUIF() returned NIL, check your script!","NOTICE")
                  VCTValue = "" -- to prevent crash
                end
              else
                print(">>> "..H.gcWARNING.." [WARNING] Problem GUIF() being nil, check your script! "..H._zDEFAULT)
                H.Report("","Problem GUIF() being nil, check your script!","WARNING")
              end
            end
            -- print("After H.GUIF(), VCTValue = <"..VCTvalue..">")
            
            if VCTvalue:gsub("%s+",""):find([[GNH("]],1,true) then
              -- print("A: got here with VCTvalue = <"..VCTvalue..">")
              tmp = load("return "..VCTvalue,"GNH","t")
              -- print("type(tmp) = <"..type(tmp)..">")
              if type(tmp) == "function" then
                --VCTvalue = tostring(tmp())
                VCTvalue = tmp() -- execute GNH()
                if not type(VCTvalue) == "string" then
                  print(">>> "..H.gcWARNING.." [WARNING] Problem GNH() did not return a string, check your script! "..H._zDEFAULT)
                  H.Report("","Problem GNH() did not return a string, check your script!","WARNING")
                  VCTvalue = ""
                end
                if VCTvalue == nil then
                  print(">>> "..H.gcNOTICE.." [NOTICE] GNH() returned NIL, check your script! "..H._zDEFAULT)
                  H.Report("","GNH() returned NIL, check your script!","NOTICE")
                  VCTValue = "" -- to prevent crash
                end
              else
                print(">>> "..H.gcWARNING.." [WARNING] Problem GNH() being nil, check your script! "..H._zDEFAULT)
                H.Report("","Problem GNH() being nil, check your script!","WARNING")
              end
            end
            -- print("After GNH(), VCTValue = <"..VCTvalue..">")
            
            My.negOffset = 0 -- only used to adjust line display
            
            if IsReplaceRAW then
              H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if IsReplaceRAW (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
              
              -- H.printf("RAW: VCTproperty = [%s]",VCTproperty)
              -- H.printf("RAW:    VCTvalue = [%s]",VCTvalue)
              if strfind(line:upper(),VCTproperty,1,true) then --not for regular expression
                -- print("Found a line at "..iGLine..": "..VCTproperty)
                --we found A line containing the VCTproperty string
                --it is "anything goes here", free for all!
                --if we searched [[oper]], it will find [[Property]] ==> in all lines
                
                -- H.DEBUG_ReplaceRAW_print("RAW replacement of: [" .. VCTproperty .. "] with: [" .. VCTvalue.."]")
                
                --fix-up pattern first to prevent side-effects
                pattern = strgsub(H.orgVCTproperty, "[%%%]%^%-$().[*+?]", "%%%1")
                -- H.DEBUG_ReplaceRAW_print("RAW search pattern: ["..pattern.."]")
                -- H.DEBUG_ReplaceRAW_print(" >>> current size of TextFileTable = "..#TextFileTable)
                
                local _,NumLinesVCTvalue = VCTvalue:gsub("\n","")
                if NumLinesVCTvalue < 2 then
                  -- only one line => direct replacement
                  -- H.DEBUG_ReplaceRAW_print(" BEFORE TextFileTable = "..TextFileTable[iGLine])
                  TextFileTable[iGLine] = strgsub(line,pattern,VCTvalue)..H.modCHANGED
                  -- H.DEBUG_ReplaceRAW_print("  AFTER TextFileTable = "..TextFileTable[iGLine])
                else
                  -- VCTvalue contains multiple lines, we need to insert them into TextFileTable
                  -- H.DEBUG_ReplaceRAW_print("at line = "..(iGLine).." inserting "..NumLinesVCTvalue.." lines")
                  local textmod = table.concat(TextFileTable,"\n",1,iGLine-1) -- to remove the current line
                  
                  VCTvalue = H.NormalizeStrEndlines(VCTvalue)
                  textmod = textmod.."\n"..VCTvalue.."\n" -- adding the new lines
                  textmod = textmod..table.concat(TextFileTable,"\n",iGLine+1,#TextFileTable) -- appending the rest of the lines                  
                  textmod = strgsub(textmod,"\n\n",H.modCHANGED.."\n") -- remove empty lines

                  TextFileTable = textmod:splitB("\n") -- to make it a table again
                  
                  if not IsEditSection then
                    -- refresh the modded table because TextFileTable is a new table
                    H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                    H.TextFileTableCheck = TextFileTable
                    TextFileTable_bak = TextFileTable                  
                  end
                end
                -- H.DEBUG_ReplaceRAW_print(" >>> NEW size of TextFileTable = "..#TextFileTable.." [#original - 1(original line is replaced) + #newlines]")
                
                repl_done = true
              end
              
            else -- not a "RAW" operation
              H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if NOT IsReplaceRAW (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
              -- print("not IsReplaceRAW...")
              -- print("B: VCTproperty=["..VCTproperty.."] ".."VCTvalue=["..VCTvalue.."]")
              -- H.pv("   ===> processing line"..line)
              
              H.DEBUG_VCTproperty_print("======")
              H.DEBUG_VCTproperty_print("    INFO: VCTproperty = ["..VCTproperty.."]")
              -- --next line should be done only once for each VCT
              -- local VCTproperty,H.IsRegular = H.makeRegExUppercase(VCTproperty)
              -- print("VCTproperty = ["..VCTproperty.."]")
              
              My.pNameValue = H.GetProperty(line)
              H.DEBUG_VCTproperty_print("    found pNameValue = ["..tostring(My.pNameValue):upper().."] at "..iGLine)
              
              My.IsFoundpNameValue = false
              
              if VCTproperty == "IGNORE" then
                My.IsFoundpNameValue = true
              else
                if My.pNameValue then
                  My.pNameValue = My.pNameValue:upper()
                  if H.IsRegular then
                    -- we must have found the Property name/value=
                    My.IsFoundpNameValue = (string.match(My.pNameValue,VCTproperty) ~= nil)
                  else
                    My.IsFoundpNameValue = (My.pNameValue == VCTproperty)
                  end
                end
              end
              H.DEBUG_VCTproperty_print("   IsFoundpNameValue = ["..tostring(My.IsFoundpNameValue).."]")
              H.DEBUG_VCTproperty_print("======")
              
              -- (iGLine == 2) is a special case where the whole EXML content was removed
              -- if  (iGLine == 2) or My.IsFoundpNameValue or My.IsTextToAdd or My.IsToRemove or (VCTproperty == "IGNORE" and (My.IsMath_Operation or IsReplaceAllInSection or IsReplaceONCEInsideSection or My.IsInline)) then
              if  (iGLine == 2) or My.IsFoundpNameValue or My.IsTextToAdd or My.IsToRemove or (VCTproperty == "IGNORE" and (My.IsMath_Operation or IsReplaceAllInSection or My.IsInline)) then
                H.DEBUG_CurrentLine_print("@@@ C: USING VCTproperty=["..VCTproperty.."] === Found << THE >> line at "..iGLine)
                -- H.printf("My.IsUseSection_add_named = %s",tostring(My.IsUseSection_add_named))
                -- H.printf("           My.IsTextToAdd = %s",tostring(My.IsTextToAdd))

  -- if My._mISxxx then
    -- print("")
    -- print(" + IN 'JUST in Found THE line'")
    -- print(" +              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."             IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
    -- print(" +     IsReplaceAllInSection: ["..tostring(IsReplaceAllInSection).."]")
    -- print(" +            My.IsTextToAdd: ["..tostring(My.IsTextToAdd)
              -- .."]  IsReplaceADDAFTERSECTION: ["..tostring(H.IsReplaceADDAFTERSECTION)
              -- .."]         IsReplaceADDAFTERLINE: ["..tostring(H.IsReplaceADDAFTERLINE)
              -- .."]     IsReplaceATLINE: ["..tostring(H.IsReplaceATLINE)
              -- .."]     IsAddATLINE: ["..tostring(H.IsAddATLINE)
              -- .."]     IsReplaceWholeSECTION: ["..tostring(H.IsReplaceWholeSECTION).."]")
    -- print(" +             My.IsToRemove: ["..tostring(My.IsToRemove)
              -- .."]            My.IsToRemoveLINE: ["..tostring(My.IsToRemoveLINE)
              -- .."]      My.IsToRemoveSECTION: ["..tostring(My.IsToRemoveSECTION)
              -- .."] My.IsToRemoveHBOS: ["..tostring(My.IsToRemoveHBOS).."]")
    -- print("")
  -- end
                
                if not My.IsTextToAdd and not My.IsToRemove then
-- print("not My.IsTextToAdd and not My.IsToRemove: process LineOffset")
                  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if not My.IsTextToAdd and not My.IsToRemove (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                  -- if IsLineOffset or My.IsAllTheSameChangeTable or My.IsAllChangeTableIGNORE then
                  if IsLineOffset then
                    --process line_offset stuff
                    
                    -- doc says: If a line is found using the KEYWORDS, it is used as the starting point
                    if IsSpecialKeyWords or H.IsPrecedingKeyWords then
                      if iGLine < SpecialKeyWordLine[thisGroup] then
                        -- only the first time
                        -- iGLine should be the line found by the KEYWORDS in this section
                        iGLine = SpecialKeyWordLine[thisGroup]
                        H.DEBUG_CurrentLine_print("@@@ USING SpecialKeyWordLine[thisGroup] as line to process: "..iGLine)
                      end
                    end
                    
                    if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                      print("                >>> Current line is "..iGLine)
                    end
                    H.Report("","                >>> Current line is "..iGLine)
                    
                    if offset_sign == "+" then
                      if #TextFileTable >= iGLine + offset then
                        line = TextFileTable[iGLine + offset]
                        iGLine = iGLine + offset --we go forward in the file
                      else
                        H.Report("","Problem with [current line + offset] being after the end of file","WARNING")
                      end
                    elseif offset_sign == "-" then
                      -- line = TextFileTable[iGLine - offset]
                      if iGLine - offset >= 1 then
                        line = TextFileTable[iGLine - offset]
                        --iGLine=iGLine - offset --we do not backtrack in the file
                        My.negOffset = offset
                      else
                        H.Report("","Problem with [current line - offset] being before the beginning of file","WARNING")
                      end
                    end
                    
                    local AIO = ""
                    if H.IsAutoIncrementOffset then
                      AIO = "Auto-incremented "
                    end
                    
                    local offsetDisplay = offset
                    if tonumber(line_offset) < 0 then
                      offsetDisplay = -offsetDisplay
                    end
                    if not H.gIs_LEAN_MODE then
                      print("                >>> "..AIO.."LINE_OFFSET of ["..offsetDisplay.."] forces to look starting at line "..(iGLine - My.negOffset))
                    end --was offset
                    H.Report("","                >>> "..AIO.."LINE_OFFSET of ["..offsetDisplay.."] forces to look starting at line "..iGLine) --was offset
                  end
                end
                
                -- exstring is UPPERCASE
                -- exstringORG is original case
                local _,exstring,_,exstringORG = H.GetPropertyValue(line)
                -- H.printf("==>        line = [%s]",line)                
                -- H.printf("==>    exstring = [%s]",exstring)                
                -- H.printf("==> exstringORG = [%s]",exstringORG)                
                My.IsNamedValueSaved = false
                My.IsNamedValueUsed = false
                if VCTSaveValueName ~= "NIL" and VCTSaveValueName ~= "" then
                  if VCTSaveValueName:sub(1,3) == "{:}" then
                    -- just get rid of trigger string
                    My.ex = VCTSaveValueName:sub(4)
                    H.DEBUG_NamedValue_print("Retrieving My.ex = <"..My.ex..">")
                    
                    My.ex = H.gSavedValues[My.ex]
                    H.DEBUG_NamedValue_print("Retrieved My.ex = <"..tostring(My.ex)..">")
                    if My.ex then
                      -- saved NamedValue exist
                      H.DEBUG_NamedValue_print("Original VCTvalue = <"..VCTvalue..">")
                      
                      if My.IsFUNCexist then
-- EXTERNAL FUNCTION CALL: using VCT function call
                        VCTvalue = ExecuteFUNC(H,H.orgVCTproperty, exstringORG, My.FUNC, My.ex, VCTfuncArg)
                      else
                        VCTvalue = My.ex
                      end
                      
                      My.IsNamedValueUsed = true
                      H.DEBUG_NamedValue_print("New VCTvalue = <"..VCTvalue..">")
                    else
                      -- value was not previously saved, use VCTvalue as usual. Nothing more to do
                      print(">>> "..H.gcNOTICE.." [NOTICE] 'NamedValue' ["..VCTSaveValueName:sub(4).."] was NOT previously saved "..H._zDEFAULT)
                      H.Report("","'NamedValue' [["..VCTSaveValueName:sub(4).."]] was NOT previously saved","NOTICE")
                    end
                    
                  else
                    -- save the existing EXML value for later use
                    H.DEBUG_NamedValue_print("Saving NamedValue '"..VCTSaveValueName.."' = <"..exstringORG..">")
                    H.gSavedValues[VCTSaveValueName] = exstringORG
                    My.IsNamedValueSaved = true

                    My.ex = exstringORG
                    H.DEBUG_NamedValue_print("Using My.ex = <"..tostring(My.ex)..">")

                    if My.IsFUNCexist then
-- EXTERNAL FUNCTION CALL: using VCT function call
                      VCTvalue = ExecuteFUNC(H,H.orgVCTproperty, exstringORG, My.FUNC, My.ex, VCTfuncArg)
                    end
                    
                    H.DEBUG_NamedValue_print("New VCTvalue = <"..VCTvalue..">")
                  end
                  
                else
                  if My.IsFUNCexist then
-- EXTERNAL FUNCTION CALL: using VCT function call
                    VCTvalue = ExecuteFUNC(H,H.orgVCTproperty, exstringORG, My.FUNC, nil, VCTfuncArg)
                  end
                  
                end
                
                -- H.WFAK()
                if My.IsNamedValueSaved then
                  if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                    print("                >>> "..H._zBRIGHTORANGE.."NamedValue"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..VCTSaveValueName..H._zDEFAULT.."] "..H._zBRIGHTORANGE.."saved as"..H._zDEFAULT.." ["..exstringORG.."]")
                  end
                  H.Report("","                >>> NamedValue [["..VCTSaveValueName.."]] saved as [["..exstringORG.."]]")
                elseif My.IsNamedValueUsed then
                  if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                    print("                >>> "..H._zBRIGHTORANGE.."NamedValue"..H._zDEFAULT.." ["..H._zBRIGHTGREEN..VCTSaveValueName:sub(4)..H._zDEFAULT.."] "..H._zBRIGHTORANGE.."retrieved as"..H._zDEFAULT.." ["..VCTvalue.."]")
                  end
                  H.Report("","                >>> NamedValue [["..VCTSaveValueName:sub(4).."]] retrieved as [["..VCTvalue.."]]")
                end
                
                if not exstring and strmatch(line,"<EMPTY>") then
                  exstring = ""
                end
                
                -- IMPORTANT NOTE: exstring could be "" here
                if H.gDEBUG_Before_Value_match then
                  print("======= (Before value_match)")
                  if IsLineOffset then
                    --getting new value from offset line
                    print("(After offset)                        Line "..iGLine..": line value=["..tostring(exstring).."] ["..line.."], VCTproperty=\""..VCTproperty.."\", VCTvalue=\""..VCTvalue.."\"")
                  else
                    print("(NO offset used)                      Line "..iGLine..": line value=["..tostring(exstring).."] ["..line.."], VCTproperty=\""..VCTproperty.."\", VCTValue=\""..VCTvalue.."\"")
                  end
                  
                  print("           My.IsValueMatch = ["..tostring(My.IsValueMatch).."]")
                  print("       IsValueMatchOptions = ["..tostring(IsValueMatchOptions).."]")
                  print("          value_match_type = "..value_match_type)
                  print("       newIsValueMatchType = ["..tostring(newIsValueMatchType).."]")
                  print("                 val_match = ["..GetValueMatchInfo(val_match).."]")
                  print("                  exstring = ["..tostring(exstring).."]")
                  if My.IsValueMatch then
                    print("  CheckValueMatchOptions() = ["..tostring(CheckValueMatchOptions(H,val_match,exstring)).."]")
                  end
                  H.printf(" My.IsUseSection_add_named = [%s]",tostring(My.IsUseSection_add_named))
                  H.printf("            My.IsTextToAdd = [%s]",tostring(My.IsTextToAdd))
                  H.printf("                 repl_done = [%s]",tostring(repl_done))
                  print("=======")
                end
                
-- print("======= (Before value_match)")
                if not My.IsValueMatch or (My.IsValueMatch and CheckValueMatchOptions(H,val_match,exstring,iGLine)) then
                  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: processing ValueMatch (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))

                  if not newIsValueMatchType or exstring == ""
                        or (value_match_type == "NUMBER" and type(tonumber(exstring)) == string.lower(value_match_type))
                        or (value_match_type == "STRING" and type(exstring) == string.lower(value_match_type)) then
                    H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: processing of VCT value (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
-- print("IN: processing of value_match")
                        
                    H.extraKWinfo = ""
                    if H.IsKWpattern and My.IsValueMatch then
                      H.extraKWinfo = "  "..H.KWinfo[thisGroup].." + <"..H._zBRIGHTORANGE..exstring..H._zDEFAULT..">"
                    end

                    if not My.IsTextToAdd and not My.IsToRemove then
-- print("not My.IsTextToAdd and not My.IsToRemove: IN value_match")
                      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if not ADD and not REMOVE (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                      -- print("(After value_match, value_match_type) Line "..iGLine..": value=["..exstring.."] ["..line.."], Property=\""..VCTproperty.."\", Value=\""..VCTvalue.."\"")
                      local NewValue = nil --could be a number OR a string
                      local tmpNewValue = nil --to be able to evaluate it before IntegerIntegrity()
                      
                      local IsOriginal = true
                      local OrgValueTypeIsNumber, OrgValueIsInteger = CheckValueType(exstring,My.IsInteger_to_floatFORCE,IsOriginal)
                      -- printf("            exstring = <%s>",exstring)
                      -- printf("OrgValueTypeIsNumber = <%s>",tostring(OrgValueTypeIsNumber))
                      -- printf("   OrgValueIsInteger = <%s>",tostring(OrgValueIsInteger))
                      
                      if My.IsMath_Operation or My.IsInline then
                        local scriptValue = VCTvalue
                        local scriptmath_operation = math_operation
                        local exmlValue = exstring
                        H.DEBUG_INLINEmath_op_print("         scriptValue = ["..tostring(scriptValue).."]")
                        H.DEBUG_INLINEmath_op_print("           exmlValue = ["..tostring(exmlValue).."]")
                        H.DEBUG_INLINEmath_op_print("scriptmath_operation = ["..tostring(scriptmath_operation).."]")
                        -- H.WFAK("Entry values for IsMath_Operation...")
                        
                        if strfind(math_operation,"$",1,true) then
                          --swap order of operands
                          scriptValue,exmlValue = exmlValue,scriptValue
                        end
                        --always remove the "$", if any
                        scriptmath_operation = strgsub(scriptmath_operation,"%$","")
                        
                        if not H.IsLockValue and strfind(math_operation,"!",1,true) then
                          --preserve the value
                          H.IsLockValue = true
                        end
                        --always remove the "!", if any
                        scriptmath_operation = strgsub(scriptmath_operation,"!","")
                        
                        if #scriptmath_operation < 3 then -- {+, -, *, /, %, //, ^} only
                          -- H.WFAK("PLAIN")
                          tmpNewValue = ExecuteMathOperation(H,
                                          scriptmath_operation,
                                          tonumber(exmlValue), --does exmlValue - scriptValue
                                          tonumber(scriptValue)
                                        )
                          NewValue =  IntegerIntegrity(tmpNewValue,OrgValueIsInteger)
                          
                        elseif strfind(strsub(scriptmath_operation, 2, 3),"F:") then --"*F:endString"
                          -- H.WFAK("F:")
                          local operand1 = tonumber(TranslateMathOperatorCommandAndGetValue(H,TextFileTable, strsub(scriptmath_operation, 4), --scriptValue to look for
                                              iGLine, --from this line
                                              "forward"
                                            )
                                          )
                          operand1,H.lockedValue = TestOperand1(H,operand1,H.IsLockValue,H.lockedValue)
                          
                          tmpNewValue = ExecuteMathOperation(H,
                                          strsub(scriptmath_operation, 1, 1),
                                          operand1,
                                          tonumber(scriptValue)
                                        )
                          NewValue =  IntegerIntegrity(tmpNewValue,OrgValueIsInteger)
                          
                        elseif strfind(strsub(scriptmath_operation, 2, 4),"FB:") then
                          -- H.WFAK("FB:")
                          local operand1 = tonumber(TranslateMathOperatorCommandAndGetValue(H,TextFileTable, strsub(scriptmath_operation, 5),
                                              iGLine,
                                              "backward"
                                            )
                                          )
                          H.DEBUG_INLINEmath_op_print("FB:         operand1 = ["..tostring(operand1).."]")
                          operand1,H.lockedValue = TestOperand1(H,operand1,H.IsLockValue,H.lockedValue)
                          H.DEBUG_INLINEmath_op_print("FB:         operand1 = ["..tostring(operand1).."]")
                          H.DEBUG_INLINEmath_op_print("FB:      H.lockedValue = ["..tostring(H.lockedValue).."]")
                          
                          tmpNewValue = ExecuteMathOperation(H,
                                          strsub(scriptmath_operation, 1, 1),
                                          operand1,
                                          tonumber(scriptValue)
                                        )
                          H.DEBUG_INLINEmath_op_print("FB:      tmpNewValue = ["..tostring(tmpNewValue).."]")
                          NewValue =  IntegerIntegrity(tmpNewValue,OrgValueIsInteger)
                          H.DEBUG_INLINEmath_op_print("FB:         NewValue = ["..tostring(NewValue).."]")
                          
                        elseif strfind(strsub(scriptmath_operation, 2, 3),"L:") then
                          -- H.WFAK("L:")
                          -- print("=====")
                          -- print("%% math_operation = ["..strsub(scriptmath_operation, 1, 1).."]")
                          -- print("%% offset = ["..tonumber(strsub(scriptmath_operation, 4)).."]")
                          -- print("%% current line iGLine = "..iGLine)
                          -- print("%% currentline = ["..TextFileTable[iGLine].."]")
                          -- print("%% Lookup line = ["..TextFileTable[iGLine + tonumber(strsub(scriptmath_operation, 4))].."]")
                          -- -- print("%% value on Lookup line = ["..tostring(tonumber(H.StripInfo(TextFileTable[iGLine + tonumber(strsub(scriptmath_operation, 4))],[[value="]],[["]]))).."]")
                          -- print("%% value on Lookup line = ["..tostring(tonumber(H.GetValue(TextFileTable[iGLine + tonumber(strsub(scriptmath_operation, 4))]))).."]")
                          -- print("%% ["..tonumber(scriptValue).."]")
                          -- print("=====")
                          
                          -- local operand1 = tonumber(H.StripInfo(TextFileTable[iGLine + math.floor(tonumber(strsub(scriptmath_operation, 4)) + 0.5)],[[ue="]],[["]]))
                          local operand1 = tonumber(H.GetValue(TextFileTable[iGLine + math.floor(tonumber(strsub(scriptmath_operation, 4)) + 0.5)]))
                          operand1,H.lockedValue = TestOperand1(H,operand1,H.IsLockValue,H.lockedValue,true)
                          
                          tmpNewValue = ExecuteMathOperation(H,
                                          strsub(scriptmath_operation, 1, 1),
                                          operand1,
                                          tonumber(scriptValue)
                                        )
                          -- print("%% ["..tmpNewValue.."]")
                          -- print("%% ["..tostring(OrgValueIsInteger).."]")
                          NewValue =  IntegerIntegrity(tmpNewValue,OrgValueIsInteger)
                          -- print("%% ["..NewValue.."]")
                          -- H.WFAK("After MATH L")
                          
                        elseif strfind(strsub(scriptmath_operation, 2, 4),"LB:") then
                          -- H.WFAK("LB:")
                          -- local operand1 = tonumber(H.StripInfo(TextFileTable[iGLine - math.floor(tonumber(strsub(scriptmath_operation, 5)) + 0.5)],[[ue="]],[["]]))
                          local operand1 = tonumber(H.GetValue(TextFileTable[iGLine - math.floor(tonumber(strsub(scriptmath_operation, 5)) + 0.5)]))
                          operand1,H.lockedValue = TestOperand1(H,operand1,H.IsLockValue,H.lockedValue,true)
                          
                          tmpNewValue = ExecuteMathOperation(H,
                                          strsub(scriptmath_operation, 1, 1),
                                          operand1,
                                          tonumber(scriptValue)
                                        )
                          NewValue =  IntegerIntegrity(tmpNewValue,OrgValueIsInteger)
                          
                        else
                          --not a valid math_operation, keep original value
                          print(">>> "..H.gcWARNING..[[ [WARNING] INVALID MATH_OPERATION: ]]..math_operation.." "..H._zDEFAULT)
                          H.Report("",[[INVALID MATH_OPERATION: ]]..math_operation,"WARNING")
                          tmpNewValue = scriptValue
                          NewValue = scriptValue
                        end
                      else
                        --no math_operation, keep original value
                        tmpNewValue = VCTvalue
                        NewValue = VCTvalue
                      end
                      -- print("tmpNewValue = <"..tmpNewValue..">")
                      H.DEBUG_CurrentLine_print("@@@ A: USING: NewValue=["..NewValue.."]")
                      -- print("@@@ A: USING: NewValue=["..NewValue.."]")
                      
                      local tmpNewValueTypeIsNumber, tmpNewValueIsInteger = CheckValueType(tmpNewValue,My.IsInteger_to_floatFORCE)
                      local NewValueTypeIsNumber, NewValueIsInteger = CheckValueType(NewValue,My.IsInteger_to_floatFORCE)
                      -- printf("   NewValueTypeIsNumber = <%s>",tostring(NewValueTypeIsNumber))
                      -- printf("      NewValueIsInteger = <%s>",tostring(NewValueIsInteger))
                      
                      -- if VCTproperty == "SEED" then
                        -- print("==>line "..iGLine..": OrgValue["..tostring(exstring).."] Number["..tostring(OrgValueTypeIsNumber).."] Integer["..tostring(OrgValueIsInteger).."] "..tostring(math.type(tonumber(exstring))))
                        -- print("==>line "..iGLine..": tmpValue["..tostring(tmpNewValue).."] Number["..tostring(tmpNewValueTypeIsNumber).."] Integer["..tostring(tmpNewValueIsInteger).."] "..tostring(math.type(tonumber(tmpNewValue))))
                        -- print("==>line "..iGLine..": NewValue["..tostring(NewValue).."] Number["..tostring(NewValueTypeIsNumber).."] Integer["..tostring(NewValueIsInteger).."] "..tostring(math.type(tonumber(NewValue))))
                      -- end
                      
                      -- ShowLocals()
                      -- H.WFAK("B")

                      if My.IsMath_Operation or My.IsInline then
                        --we only care about an INTEGER number becoming a FLOAT
                        if OrgValueTypeIsNumber and OrgValueIsInteger and not tmpNewValueIsInteger and (not My.IsInteger_to_floatDeclared or (My.IsInteger_to_floatDeclared and not My.IsInteger_to_floatPRESERVE)) then
                          if not IsLargeNumOfReplacement then
                            print(">>> "..H.gcNOTICE..[[ [NOTICE] Below: ORIGINAL integer value = "]]..exstring..[["  RESULT of math operation = "]]..tmpNewValue..[["  INTEGER conversion = "]]..NewValue..[[" ]]..H._zDEFAULT)
                            print("    "..H.gcNOTICE..[[ [   >>>] To override, use ["INTEGER_TO_FLOAT"] = "FORCE" or "PRESERVE" ]]..H._zDEFAULT)
                          end
                          H.Report("",[[Below: ORIGINAL integer value = "]]..exstring..[["  RESULT of math operation = "]]..tmpNewValue..[["  INTEGER conversion = "]]..NewValue..[["]],"NOTICE")
                          H.Report("",[[To override, use ["INTEGER_TO_FLOAT"] = "FORCE" or "PRESERVE"]],"   >>>")
                        end
                        
                        if tonumber(NewValue) and math.abs(tonumber(NewValue)) > 2147483647 then
                          --MBINCompiler may produce a problematic MBIN that once decompiled will have a value of "1.0E+7"
                          print(">>> "..H.gcNOTICE..[[ [NOTICE] If value type is 'int32', new value is too big or small ]]..H._zDEFAULT)
                          -- print(">>> "..H.gcNOTICE..[[ [NOTICE] MBINCompiler may generate a MBIN that once decompiled will have a value like "1E+09"]]..H._zDEFAULT)
                          -- print(H.gcNOTICE..[[         xxxxx Your script contains a value over "99999999" xxxxx]]..H._zDEFAULT)
                          -- print(H.gcNOTICE..[[         A value like "100000123" will become "100000120", (it won't be exact)]]..H._zDEFAULT)
                          -- print(H.gcNOTICE..[[         Bigger values may become like "1E+09"]]..H._zDEFAULT)
                          -- print(H.gcNOTICE..[[         That could prevent NMS from using the mod]]..H._zDEFAULT)
                          H.Report("",[[ If value type is 'int32', new value is too big or small]],"NOTICE")
                          -- H.Report("",[[MBINCompiler may generate a MBIN that once decompiled will have a value like "1E+09"]],"NOTICE")
                          -- H.Report("",[[       xxxxx Your script contains a value over "99999999" xxxxx]],"")
                          -- H.Report("",[[       A value like "100000123" will become "100000120", (it won't be exact)]],"")
                          -- H.Report("",[[       Bigger values may become like "1E+09"]],"")
                          -- H.Report("",[[       That could prevent NMS from using the mod]],"")
                        end
                        
                      else
                        --when not a Math_Operation
                        -- print("Not MATH: NewValue=["..NewValue.."]")
                        if NewValue == "IGNORE" and not My.IsVCTempty then
                          --skip is intentional
                          repl_done = true
                          
                        else
                          --  we only care about a change from
                              -- (number to string)
                              -- (string to integer)
                              -- INTEGER number becoming a FLOAT
                          -- and we DON'T preserve INTEGERs when not in a MATH_OPERATION
                          -- This IS A LITERAL CHANGE
                          if exstring == "" then
                            H.DEBUG_CurrentLine_print("@@@ A: USING: NewValue = ["..NewValue.."]")
                            H.DEBUG_CurrentLine_print("@@@ A: type(NewValue)  = ["..type(NewValue).."]")
                            H.DEBUG_CurrentLine_print("@@@ A: IsValueMatchType= ["..tostring(IsValueMatchType).."]")
                            if NewValue ~= "" and type(NewValue) ~= "string" then
                              print(">>> "..H.gcNOTICE..[[ [NOTICE] ORIGINAL value is EMPTY, type is UNKNOWN.  Make sure you use the right type ]]..H._zDEFAULT)
                              H.Report("",[[ORIGINAL value is EMPTY, type is UNKNOWN.  Make sure you use the right type]],"NOTICE")
                            end
                          else
                            if NewValue ~= "{:}" then
                              if OrgValueTypeIsNumber then
                                if not NewValueTypeIsNumber then
                                  if not H.S_msg_number_to_string then
                                    print(">>> "..H.gcNOTICE..[[ [NOTICE] ORIGINAL(number) and NEW(string) values are mismatched types ]]..H._zDEFAULT)
                                    H.Report("",[[ORIGINAL(number) and NEW(string) values are mismatched types]],"WARNING")
                                  end
                                else
                                  if OrgValueIsInteger and not NewValueIsInteger then
                                    if My.IsInteger_to_floatDeclared then
                                      print(">>> "..H.gcNOTICE..[[ [NOTICE] INTEGER_TO_FLOAT command ignored here.  Value is literal, not a MATH_OPERATION ]]..H._zDEFAULT)
                                      H.Report("",[[INTEGER_TO_FLOAT command ignored here.  Value is literal, not a MATH_OPERATION]],"NOTICE")
                                    end                    
                                    print(">>> "..H.gcNOTICE..[[ [NOTICE] ORIGINAL(integer) and NEW(float) values are mismatched types ]]..H._zDEFAULT)
                                    H.Report("",[[ORIGINAL(integer) and NEW(float) values are mismatched types]],"NOTICE")
                                  end
                                end
                              end
                            else
                              -- NewValue should be equal to OrgValue
                            end
                          end
                          
                        end
                      end
                      
                      H.pv("(After math_operation) Line "..iGLine..": value=["..tostring(NewValue).."] ["..line.."], Property=\""..VCTproperty.."\", Value=\""..VCTvalue.."\"")
                      if NewValue ~= "IGNORE" then
                        local Ending = [[ />]]
                        if strfind(line,[[">]],1,true) then
                          Ending = [[>]]
                        end
                        Ending = [["]]..(strmatch(line,[[( _.-".-") ]]) or "")..Ending

                        -- H.printf("==> Ending = [%s]",Ending)
                        
                        -- we CANNOT use gsub here because it could replace at wrong places like:
                        -- <Property name="_3rdPersonAngleSpeedRangePitch" value="3" />
                        -- when replacing such a value (3 with 8) it becomes:
                        -- <Property name="_8rdPersonAngleSpeedRangePitch" value="8" />
                        
                        local postValue = ""
                        local preValue = ""
                        
                        if H.IsAddToStringValueFlag then
                          preValue = NewValue:sub(1,NewValue:find("{:}",1,true)-1) -- before the {:}
                          postValue = NewValue:sub(NewValue:find("{:}",1,true)+3)  -- after the {:}
                          NewValue = exstringORG -- the original case value
                        end
                        
                        if tonumber(NewValue) and OrgValueTypeIsNumber and not OrgValueIsInteger then 
                          -- if math.type(tonumber(NewValue)) == "float" then
                            NewValue = strformat("%0.6f",NewValue + 0.0)
                          -- else
                            -- NewValue = strformat("%0.6i",NewValue)
                          -- end
                        end
                        
                        if H.S_msg_report_new_equal_old_value and strupper(tostring(NewValue)) == strupper(tostring(exstring)) and tostring(exstring) ~= "" then
                          print(">>> "..H.gcNOTICE.." [NOTICE] -- >>>>> NEW value(s) = OLD value(s) <<<<< "..H._zDEFAULT)
                          H.Report("","       >>>>> NEW value(s) = OLD value(s) <<<<<","NOTICE")
                        end                      
                        
                        --   p, v as 'Property name=', 'value='
                        --   p, nil as 'Property name=', nil
                        --   nil, v as nil, 'Property value='
                        --   nil, nil if not found
                        local p,v = H.GetPropertyNameValue(line)
                        -- if strfind(line,[[me=]],1,true) and strfind(line,[[ue=]],1,true) then
                        local IsTextFileTableUpdated = false
                        if p and v then
                          --standard value replacement on a line with the VCTproperty
                          --a line with BOTH name AND value, value could be EMPTY
                          --like: <Property name="Filename" value="MODELS/PLANETS/BIOMES/BARREN/HQ/TREES/DRACAENA.SCENE.MBIN" />
                          --like: <Property name="ProceduralTexture" value="TkProceduralTextureChosenOptionList">
                          TextFileTable[iGLine] = strsub(line,1,strfind(line,[[value="]],1,true)-1)..[[value="]]..preValue..tostring(NewValue)..postValue..Ending..H.modCHANGED

                          IsTextFileTableUpdated = true
                          repl_done = true
                          
                        -- elseif strfind(line,[[ue=]],1,true) then
                        elseif v then
                          -- lines with value only, CANNOT BE EMPTY
                          -- like: <Property value="TkProceduralTextureChosenOptionSampler">
                          -- could be a SIGNIFICANT KEY_WORD
                          TextFileTable[iGLine] = strsub(line,1,strfind(line,[[value="]],1,true)-1)..[[value="]]..preValue..tostring(NewValue)..postValue..Ending..H.modCHANGED

                          IsTextFileTableUpdated = true
                          repl_done = true
                          
                        -- elseif strfind(line,[[me=]],1,true) then
                        elseif p then
                          -- lines with name only, CANNOT BE EMPTY
                          -- like: <Property name="GenericTable">
                          -- like: <Property name="List" />
                          -- could be a SIGNIFICANT KEY_WORD
                          TextFileTable[iGLine] = strsub(line,1,strfind(line,[[name="]],1,true)-1)..[[name="]]..preValue..tostring(NewValue)..postValue..Ending..H.modCHANGED

                          IsTextFileTableUpdated = true
                          repl_done = true
                          
                        else
                          repl_done = true
                          print(">>> "..H.gcWARNING.." [WARNING] XXX At "..iGLine..": Found an Un-handled line type ["..line.."], check your script! "..H._zDEFAULT)
                          H.Report(line,"XXX At "..iGLine..": Check your script, found an Un-handled line type:","WARNING")
                          
                        end
                        
                        if IsTextFileTableUpdated then
                          if vct_comment and type(vct_comment) == "table" then
                            -- format vct_comment: <!--spacer Table-->
                            if type(vct_comment[H.jVCT]) == "string" and vct_comment[H.jVCT] ~= "" then
                              TextFileTable[iGLine] = TextFileTable[iGLine]..[[ <!--]]..vct_comment[H.jVCT]:gsub([[\n]],""):gsub([[\r]],"")..[[-->]]
                              H.printf("C1: TextFileTable[iGLine] = [%s]",TextFileTable[iGLine])
                            end
                          end
                        end
                        
                        H.pv("(After replacement) Line "..tostring(iGLine)..": TextFileTable[iGLine] = ["..tostring(TextFileTable[iGLine]).."]")
                      else
                        -- print("(value is IGNORE) Line "..iGLine..": TextFileTable[iGLine] = ["..TextFileTable[iGLine].."]")
                        -- print("   >>> the line is SKIPPED")
                      end
                    end --if not My.IsTextToAdd and not My.IsToRemove then
                    -- print("BEFORE My.IsTextToAdd or My.IsToRemove: IN value_match")
                    
                    if My.IsTextToAdd or My.IsToRemove then
                      -- print("My.IsTextToAdd or My.IsToRemove")
                      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if ADD or REMOVE (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                      H.IsAddNeedsRemove = false
                      
                      if My.IsTextToAdd or H.IsReplaceWholeSECTION then
                        -- print("My.IsTextToAdd")
                        H.DEBUG_TextToAdd_print("=== Preparing to ADD some text at "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        
                        -- we cannot have a remove operation at the same time, except for a H.IsAddNeedsRemove
                        My.IsToRemove = false
                        
                        if H.IsReplaceADDAFTERLINE then
                          --this is the default
                          iGLine = SpecialKeyWordLine[thisGroup]
                          H.DEBUG_TextToAdd_print("===    -> Adding text after line found by KW: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        
                        elseif H.IsAddATLINE then
                          iGLine = SpecialKeyWordLine[thisGroup]
                          H.DEBUG_TextToAdd_print("===    -> Adding text at line found by KW: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        
                        elseif H.IsReplaceADDBEFORESECTION then
                          -- iGLine becomes the start of the section - 1
                          iGLine = GroupStartLine[thisGroup] - 1
                          if strsub(TextFileTable[iGLine],1,8) == "<Data te" then
                            print(">>> "..H.gcWARNING.." [WARNING] ADD operation aborted, selected section points to <Data template> "..tostring(TextFileTable[iGLine]).."! "..H._zDEFAULT)
                            H.Report("","ADD operation aborted, selected section points to <Data template> "..tostring(TextFileTable[iGLine]).."!","WARNING")
                            break
                          end
                          H.DEBUG_TextToAdd_print("===    -> Adding text before section: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        
                        elseif H.IsReplaceADDAFTERSECTION then
                          -- iGLine becomes the end of the section
                          iGLine = GroupEndLine[thisGroup]
                          if TextFileTable[iGLine] == "</Data>" then
                            print(">>> "..H.gcWARNING.." [WARNING] ADD operation aborted, selected section points to last line of file "..tostring(TextFileTable[iGLine]).."! "..H._zDEFAULT)
                            H.Report("","ADD operation aborted, selected section points to last line of file "..tostring(TextFileTable[iGLine]).."!","WARNING")
                            break
                          end
                          H.DEBUG_TextToAdd_print("===    -> Adding text after section: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                          
                          if H.IsReplaceWholeSECTION then
                            H.IsAddNeedsRemove = true
                          end
                          
                        elseif H.IsReplaceATLINE then
                          --no need to change iGLine
                          H.DEBUG_TextToAdd_print("===    -> Removing existing line and Adding text at line: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                          --we take care of removing the line in My.IsToRemove below
                          if not H.gIs_LEAN_MODE then print([[>>> [INFO] Turning ON automatic current line removal at line ]]..iGLine) end
                          H.Report(add_option,[[=== >>> Turning ON automatic current line removal at line ]]..iGLine,"INFO")
                          H.IsAddNeedsRemove = true
                          -- My.IsToRemove = true
                          My.IsToRemoveLINE = true
                        
                        elseif H.IsReplaceADDENDSECTION then
                          -- iGLine becomes the end of the section minus one line
                          iGLine = GroupEndLine[thisGroup] - 1
                          -- if TextFileTable[iGLine] == "</Data>" then
                            -- print(">>> "..H.gcWARNING.." [WARNING] ADD operation aborted, selected section points to last line of file "..tostring(TextFileTable[iGLine]).."! "..H._zDEFAULT)
                            -- H.Report("","ADD operation aborted, selected section points to last line of file "..tostring(TextFileTable[iGLine]).."!","WARNING")
                            -- break
                          -- end
                          H.DEBUG_TextToAdd_print("===    -> Adding text at end of section: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        end
                        
                        -- Wbertro: this could be more elaborate
                        if type(iGLine) == "string" then
                          H.printf("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  iGLine = %s",tostring(iGLine))
                          iGLine = 1
                        end
                        
                        if IsLineOffset then
                          H.DEBUG_TextToAdd_print("===    -> line before applying offset: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                          if offset_sign == "+" then
                            iGLine = iGLine + offset
                            if iGLine > #TextFileTable then
                              iGLine = #TextFileTable - 1
                            end
                          elseif offset_sign == "-" then
                            iGLine = iGLine - offset
                            if not IsEditSection then
                              H.DataTemplateLine = 0
                              for i=1,#TextFileTable do
                                if strfind(TextFileTable[i],"<Data te",1,true) then
                                  H.DataTemplateLine = i
                                  break
                                end
                              end
                              if iGLine < H.DataTemplateLine then
                                iGLine = H.DataTemplateLine --it must be after the header at least
                              end
                            end
                          end
                          H.DEBUG_TextToAdd_print("===    -> line after applying offset: "..tostring(iGLine).." ["..tostring(TextFileTable[iGLine]).."]")
                        end
                        
                        H.DEBUG_TextToAdd_print("=== A: #text_to_add = "..#text_to_add)
                        H.DEBUG_TextToAdd_print("=== A: text_to_add = [\n"..tostring(text_to_add[1])..H._zBRIGHTGREEN.."_..._"..H._zDEFAULT..tostring(text_to_add[#text_to_add]).."] of type '"..type(text_to_add).."'")
                        -- if H.WDEBUG then H.WFAK() end
                        if My.IsUseSection_add_named then
                          -- print("In My.IsUseSection_add_named")
                          --get section content
                          if H.gSection[sec_add_named] then
                            H.DEBUG_SEC_print("@@@@@ B STRING ==> H.gSection[sec_add_named] = ["..strsub(H.gSection[sec_add_named],1,150).."...]")
                            --retrieve the section
                            -- make H.gSection[sec_add_named] into a table

                            -- print("OOO OOO OOO OOO")
                            -- local s = H.rtrim(H.gSection[sec_add_named]):splitB("\n")
                            -- for i=1,#s do
                              -- H.printf("OOO %d: [%s]",i,s[i])
                            -- end
                            -- print("OOO OOO OOO OOO")
                            
                            if H.IsReplaceWholeSECTION then
                              -- get _index of current section
                              -- text_to_add = H.rtrim(H.gSection[sec_add_named]:gsub("\n%s*\n",H.modREPLACED.."\n")):splitB("\n")
                              -- print("In IsReplaceWholeSECTION")
                              text_to_add = H.rtrim(H.gSection[sec_add_named].."\n"):gsub(">[#%s%w]*\n",">"..H.modREPLACED.."\n"):splitB("\n")
                              
                              H.currentIndex = strmatch(TextFileTable[GroupStartLine[thisGroup]],[[ _index="(.-)"]])
                              H.DEBUG_TextToAdd_print("ReplaceWholeSECTION active: found H.currentIndex = ["..tostring(H.currentIndex).."]")
                              if H.currentIndex then
                                text_to_add[1] = strgsub(text_to_add[1], [[">]], [[" _index="]]..H.currentIndex..[[">]])
                              end
                            else
                              -- print("In NOT IsReplaceWholeSECTION")
                              -- text_to_add = H.rtrim(H.gSection[sec_add_named]:gsub("\n%s*\n",H.modCHANGED.."\n")):splitB("\n")
                              text_to_add = H.rtrim(H.gSection[sec_add_named]).."\n"
                              text_to_add = text_to_add:gsub(">[#%s%w]*\n",">"..H.modADDED.."\n"):splitB("\n") -- .." Z7"
                            end
                            
                            H.DEBUG_SEC_print("@@@@@ B TABLE ==> #text_to_add = ["..#text_to_add.."]")
                            
                            -- print("PPP PPP PPP PPP")
                            -- for i=1,#text_to_add do
                              -- H.printf("PPP %d: [%s]",i,text_to_add[i])
                            -- end                            
                            -- print("PPP PPP PPP PPP")
                            
                            if strmatch(text_to_add[1],"<EMPTY>") then
                              -- silently remove the 1st line created by SEC_EMPTY
                              text_to_add[1] = "NIL"
                              text_to_add = H.refreshTable(text_to_add)
                            end
                            
                            if My.IsToRemoveHBOS then
                              if My.IsUseSection_add_named then
                                -- trim top and bottom lines
                                if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                                  print(H._zBRIGHTGREEN.."    -- REMOVED line 1 of NAMED_SECTION: "..H._zDEFAULT.."["..text_to_add[1].."]"..H.extraKWinfo)
                                  print(H._zBRIGHTGREEN.."           and line "..#text_to_add..": "..H._zDEFAULT.."["..text_to_add[#text_to_add].."]")
                                -- else -- if H.gIs_LEAN_MODE then
                                  -- if #GroupStartLine > 10 and #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                                    -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                                  -- end
                                end
                                H.Report("","    -- REMOVED line 1 of NAMED_SECTION: ".."["..text_to_add[1].."]"..H.extraKWinfo)
                                H.Report("","           and line "..#text_to_add..": ".."["..text_to_add[#text_to_add].."]")
                                -- remove 1st AND last line
                                text_to_add[1] = "NIL"
                                text_to_add[#text_to_add] = "NIL"                                
                                text_to_add = H.refreshTable(text_to_add)
                              else
                                print(">>> "..H.gcWARNING.." [WARNING] Remove HBOS operation aborted, no 'saved' section to edit! "..H._zDEFAULT)
                                H.Report("","Remove HBOS operation aborted, no 'saved' section to edit!","WARNING")
                                break
                              end
                            end
                            
                            H.DEBUG_SEC_print("@@@@@   B ==> Found sec_add_named ["..tostring(sec_add_named).."] with length = "..#text_to_add)
                            H.DEBUG_TextToAdd_print("=== B: text_to_add = [\n"..tostring(text_to_add[1])..H._zBRIGHTGREEN.."_..._"..H._zDEFAULT..tostring(text_to_add[#text_to_add]).."] of type '"..type(text_to_add).."' after UseSectionName")
                          end
                        end

                        if text_to_add[1] and strfind(text_to_add[1],[[">]],1,true) then
                          if My.IsExml_id then
                            if strfind(text_to_add[1],[[ _id=]],1,true) == nil then
                              print(H._zBRIGHTORANGE..[[>>> Added _id="]]..H.exml_id..[["]]..H._zDEFAULT)
                              H.Report("",[[>>> Added _id="]]..H.exml_id..[["]])
                              text_to_add[1] = strgsub(text_to_add[1], [[">]], [[" _id="]]..H.exml_id..[[">]])
                            else
                              print(H._zBRIGHTORANGE..[[>>> _id="..." already exist]]..H._zDEFAULT)
                              H.Report("",[[>>> _id="..." already exist]])
                            end
                          end
                          if My.IsExml_index then
                            if not H.IsReplaceWholeSECTION and strfind(text_to_add[1],[[ _index=]],1,true) == nil then
                              print(H._zBRIGHTORANGE..[[>>> Added _index="]]..H.exml_index..[["]]..H._zDEFAULT)
                              H.Report("",[[>>> Added _index="]]..H.exml_index..[["]])
                              text_to_add[1] = strgsub(text_to_add[1], [[">]], [[" _index="]]..H.exml_index..[[">]])
                            else
                              print(H._zBRIGHTORANGE..[[>>> _index="..." already exist]]..H._zDEFAULT)
                              H.Report("",[[>>> _index="..." already exist]])
                            end
                          end
                          
                          if My.IsExml_flags then
                            if H.IsEXMLflagOVERWRITE then
                              if strfind(text_to_add[1],[[ _overwrite="true"]],1,true) == nil then
                                print(H._zBRIGHTORANGE..[[>>> Added _overwrite="true"]]..H._zDEFAULT)
                                H.Report("",[[>>> Added _overwrite="true"]])
                                text_to_add[1] = strgsub(text_to_add[1], [[">]], [[" _overwrite="true">]])
                              else
                                print(H._zBRIGHTORANGE..[[>>> _overwrite="true" already exist]]..H._zDEFAULT)
                                H.Report("",[[>>> _overwrite="true" already exist]])
                              end
                            end
                            
                            -- if H.IsEXMLflagREMOVE then
                              -- print([[>>> Added _remove="true"]])
                              -- text_to_add[1] = strgsub(text_to_add[1], [[">]], [[" _remove="true">]])
                            -- end
                          end
                        end
                        
                        if H.gDEBUG_TestLineCount then H.TestLineCount(text_to_add,"A text_to_add:") end
                        -- if H.WDEBUG then H.WFAK() end
                        -- local _,linecount = strgsub(text_to_add,"\n","")
                        local linecount = #text_to_add
                        if linecount == 0 then
                          linecount = 1
                        end
                        
                        -- ***************************************************************************************************
                        -- handle NameHash generation
                        local F = {}
                        if My.IsAuto_GNH and #text_to_add > 0 then
                          -- printf("@@@@  ENTERING AUTO_GNH section")

                          -- find all sections where NAME="NAMEHASH" is found
                          F.linesNumFound = {}
                          F.uniqueState = 0 -- not found
                          F.lineNumber = nil
                          
                          F.s = [[Y NAME="NAMEHASH"]]
                          
                          F.text = table.concat(text_to_add):upper()
                          --fastest way!!! --gsub and gmatch take too long
                          F.firstPosStart,F.firstPosEnd = strfind(F.text,F.s)
                          
                          if F.firstPosEnd then
                            F._,F.lineNumber = F.text:sub(1,F.firstPosEnd):gsub('>','>',-1)
                            F.linesNumFound[#F.linesNumFound + 1] = F.lineNumber + 1
                            
                            F.secondPos,F.nextPos = strfind(F.text,F.s,F.firstPosEnd + 1)
                            
                            if F.secondPos == nil then
                              F.uniqueState = 1
                            else
                              F.uniqueState = 2
                              
                              F.PreviouslineNumber = F.lineNumber
                              F.PreviousPosEnd = F.firstPosEnd + 1
                              
                              _,F.lineNumber = F.text:sub(F.PreviousPosEnd,F.nextPos):gsub('>','>',-1)
                              F.linesNumFound[#F.linesNumFound + 1] = F.PreviouslineNumber + F.lineNumber + 1
                              
                              while F.nextPos do
                                F.nextPos,F.endPos = strfind(F.text,F.s,F.nextPos + 1)
                                if F.nextPos then
                                  _,F.lineNumber = F.text:sub(F.PreviousPosEnd,F.endPos):gsub('>','>',-1)
                                  F.linesNumFound[#F.linesNumFound + 1] = F.PreviouslineNumber + F.lineNumber + 1
                                  
                                  F.nextPos = F.endPos + 1
                                  F.PreviousPosEnd = F.nextPos
                                  F.PreviouslineNumber = F.PreviouslineNumber + F.lineNumber
                                end
                              end
                            end
                          end
                          -- printf("#F.linesNumFound = %d",#F.linesNumFound)
                          
                          F.newGSL = {}
                          F.newGEL = {}
                          F.newSKL = {}
                          
                          for p = 1,#F.linesNumFound do
                            -- if strfind(strupper(text_to_add[F.linesNumFound[p]]),F.s) then -- because FastCheckUniqueness() sometimes returns extra lines (a lua BUG ??)
                              -- this is always inside a section
                              F.newGSL[#F.newGSL+1] = H.GoUPToOwnerStart(text_to_add,F.linesNumFound[p])
                              F.newGEL[#F.newGEL+1] = H.GoDownToOwnerEnd(text_to_add,F.linesNumFound[p])
                              F.newSKL[#F.newSKL+1] = F.linesNumFound[p] -- points to NAMEHASH line
                            -- end
                          end
                          
                          -- for i=1,#F.newGSL do
                            -- printf("%d: %d-%d (%d)",i,F.newGSL[i],F.newGEL[i],F.newSKL[i])
                          -- end
                          -- print("")
                          
                          -- look for [[NAME="NAME"]] in these sections containing NAMEHASH
                          F.createdNHcount = 0
                          for i=1,#F.newGSL do
                            -- printf("i = %d",i)
                            -- printf("  %d: %d-%d (%d)",i,F.newGSL[i],F.newGEL[i],F.newSKL[i])
                            for j=F.newGSL[i],F.newGEL[i] do
                              F.tmpName = text_to_add[j]:upper()
                              if strfind(F.tmpName,[[NAME="NAME"]],1,true) then
                                F.posB = strfind(F.tmpName,[[VALUE="]],1,true)
                                if F.posB then
                                  F.name = strsub(text_to_add[j],F.posB+7,strfind(text_to_add[j],[[" />]],1,true)-1)
                                  -- printf("  %d: F.name = %s",j,F.name)
                                  F.nameHash = H.GNH(F.name)
                                  -- printf("  %d: F.nameHash = %s",j,F.nameHash)
                                  text_to_add[F.newSKL[i]] = strsub(text_to_add[F.newSKL[i]],1,strfind(text_to_add[F.newSKL[i]]:upper(),[["NAMEHASH"]],1,true))..[[NameHash" value="]]..F.nameHash..[[" />]]..H.modCHANGED
                                  -- printf("  %d: === text_to_add: GNH = %s: [%s]",F.newSKL[i],F.nameHash,text_to_add[F.newSKL[i]])
                                  F.createdNHcount = F.createdNHcount + 1
                                  break -- go to next found section
                                end
                              end
                            end -- for j=F.newGSL[i],F.newGEL[i] do
                          end -- for i=1,#F.newGSL do
                        end -- if My.IsAuto_GNH and #text_to_add > 0 then
                        -- END: handle NameHash generation
                        -- ***************************************************************************************************
                        
                        H.DEBUG_TextToAdd_print("=== text_to_add: linecount = "..linecount)
                        H.DEBUG_TextToAdd_print("=== text_to_add: #TextFileTable BEFORE = "..#TextFileTable)
                        H.DEBUG_TextToAdd_print("=== text_to_add: type(TextFileTable) = "..type(TextFileTable))
                        
                        if type(text_to_add) == "table" then
                          H.DEBUG_TextToAdd_print("==A text_to_add:    using table, insert at pos "..(iGLine + 1))
                          H.DEBUG_TextToAdd_print("==B text_to_add:    #text_to_add = "..#text_to_add)
                          H.DEBUG_TextToAdd_print("==C text_to_add:    from "..(iGLine + 1).." to "..(#TextFileTable + #text_to_add))
                          
                          if H.gDEBUG_TestLineCount then H.TestLineCount(text_to_add,"B1 text_to_add:") end
                          if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"B2 TextFileTable:") end
                          
                          -- **************  auto-adjust INDENTATION to match the previous line  **************
                          text_to_add = H.AutoAdjustIndentation(TextFileTable,text_to_add,iGLine)
                
                          -- -- H.printf(H._zWHITEonDARKCYAN.."At "..H.dClock().." auto-adjust indentation "..H._zDEFAULT,"")
                          -- -- get current indent size only from MXMLs or from SAVED_SECTIONS
                          -- My.currentIndentSize = 0
                          
                          -- if TextFileTable[iGLine] and H.trim(TextFileTable[iGLine]) ~= "" then
                            -- My.spaceNumLineBeforeInsertPoint = #TextFileTable[iGLine] - #H.ltrim(TextFileTable[iGLine])
                          -- else
                            -- My.spaceNumLineBeforeInsertPoint = 0
                          -- end
                          -- -- H.printf("My.spaceNumLineBeforeInsertPoint = [%d] spaces at line %d",My.spaceNumLineBeforeInsertPoint,iGLine)
                                                  
                          -- if type(TextFileTable[1]) == "string" and H.ltrim(TextFileTable[1]):sub(1,5) == [[<?xml]] then
                            -- -- print("FOUND AN MXML file")
                            -- My.DataFound = false
                            
                            -- for w = 1, #TextFileTable do
                              -- if not My.DataFound and H.ltrim(TextFileTable[w]):sub(1,5) == [[<Data]] then
                                -- My.DataFound = true
                              -- end
                              
                              -- if My.DataFound and H.trim(TextFileTable[w+1]) ~= "" then
                                -- local s = H.TABtoSPACES(TextFileTable[w+1])
                                -- My.currentIndentSize = #s - #H.ltrim(s)
                                -- -- H.printf("My.currentIndentSize = [%s]",My.currentIndentSize)
                                -- break
                              -- end
                            -- end
                          -- else                        
                            -- -- this is not a MXML file
                            -- -- -- get indentation just before the insertion point
                            -- -- My.currentIndentSize = My.spaceNumLineBeforeInsertPoint
                          -- end
                          
                          -- -- now make it a string
                          -- My.currentIndentSize = ""..strrep(" ",My.currentIndentSize)
                          -- if My.currentIndentSize == "" or My.currentIndentSize == " " then
                            -- My.currentIndentSize = "  "
                          -- end
                          -- -- H.printf("My.currentIndentSize = [%s]",My.currentIndentSize)
                          
                          -- My.indentLevel = 0
                          
                          -- if My.spaceNumLineBeforeInsertPoint > 0 then
                            -- My.currentSpacing = strsub(TextFileTable[iGLine],1,My.spaceNumLineBeforeInsertPoint)
                            -- -- H.printf("My.currentSpacing = [%s]",My.currentSpacing)

                            -- if strfind(TextFileTable[iGLine],[[">]],1,true) then
                              -- -- adjust in case of HOS in MXML
                              -- My.indentLevel = My.indentLevel + 1
                            -- end
                            
                            -- for w = 1, #text_to_add do
                              -- My.tmp = H.trim(text_to_add[w]) -- trimming BOTH side
                              -- -- H.printf("=== [%s]",My.tmp)
                              -- My.endOfFirstAddLine = [[">]]
                              -- if strfind(text_to_add[w],[[/>]],1,true) then
                                -- My.endOfFirstAddLine = [[/>]]
                              -- elseif strfind(text_to_add[w],[[y>]],1,true) then
                                -- My.endOfFirstAddLine = [[y>]]
                              -- end
                              -- -- H.printf("My.endOfFirstAddLine = [%s]",My.endOfFirstAddLine)
                              -- -- H.printf("My.indentLevel = %d",My.indentLevel)
                              
                              -- if My.endOfFirstAddLine == [[/>]] or My.tmp == "" or My.tmp:sub(1,2) == "--" then
                                -- -- this is a normal line, indent does not change
                                -- text_to_add[w] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp
                              -- elseif My.endOfFirstAddLine == [[y>]] then
                                -- -- this is a </Property>
                                -- My.indentLevel = My.indentLevel - 1
                                -- text_to_add[w] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp
                              -- elseif My.endOfFirstAddLine == [[">]] then
                                -- -- this is a HOS line
                                -- text_to_add[w] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp
                                -- My.indentLevel = My.indentLevel + 1
                              -- end                              
                              -- -- H.printf("--- [%s]",text_to_add[w])
                            -- end
                            -- -- H.printf("  TextFileTable[iGLine] = [%s]",TextFileTable[iGLine])
                            -- -- H.printf("text_to_add[1] = [%s]",text_to_add[1])

                          -- end
                          -- -- H.printf(H._zWHITEonDARKCYAN.."At "..H.dClock().." END: auto-adjust indentation "..H._zDEFAULT,"")
                          -- -- **************  END: auto-adjust INDENTATION to match the previous line  **************
                          
                          if secadd_comment and secadd_comment ~= "" and type(secadd_comment) == "string" then
                            My.spaceNum = #text_to_add[1] - #H.ltrim(text_to_add[1])

                            -- format mxml_comment: <!--spacer Table-->
                            table.insert(text_to_add,1,strrep(" ",My.spaceNum)..[[<!--]]..secadd_comment:gsub([[\n]],""):gsub([[\r]],"")..[[-->]])
                            -- text_to_add[1] = text_to_add[1]..[[ <!--]]..secadd_comment:gsub([[\n]],""):gsub([[\r]],"")..[[-->]]
                            H.printf("text_to_add[1] = [%s]",text_to_add[1])
                          end

                          -- grow TextFileTable by #text_to_add, moving the insertion pos down
                          table.move(TextFileTable,iGLine + 1,#TextFileTable + #text_to_add,iGLine + 1 + #text_to_add)
                          H.DEBUG_TextToAdd_print("==D text_to_add:    TextFileTable grows to = "..#TextFileTable)
                          
                          -- insert text_to_add into TextFileTable
                          table.move(text_to_add,1,#text_to_add,iGLine + 1,TextFileTable)
                          -- H.DEBUG_TextToAdd_print("=== text_to_add:    final #TextFileTable = "..#TextFileTable)
                          
                        else -- "string"
                          print(">>> "..H.gcERROR..[[ [BUG] "ADD" cannot NOT be a 'string' here, please report ]]..H._zDEFAULT)
                        end
                        
                        if H.gDEBUG_TestLineCount then H.TestLineCount(TextFileTable,"C TextFileTable:") end
                        H.DEBUG_TextToAdd_print("==E text_to_add: #TextFileTable  AFTER = "..#TextFileTable)
                        
                        My.tmp = "ADD"
                        if My.IsUseSection_add_named then
                          My.tmp = sec_add_named
                        end
                        
                        if F.createdNHcount then
                          if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                            print("               >>> Created "..F.createdNHcount.." NameHash")
                          end
                          H.Report("","               >>> Created "..F.createdNHcount.." NameHash")                        
                        end
                        
                        if linecount > 1 then
                          if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                            print(H._zBRIGHTGREEN.."    -- Lines "..(iGLine + 1).." - "..(iGLine + linecount)..H._zDEFAULT.." "..H._zBRIGHTORANGE.."ADDED using text in"..H._zDEFAULT.." ["..H._zBRIGHTGREEN.."\""..My.tmp.."\""..H._zDEFAULT.."]"..H.extraKWinfo)
                          -- else -- if H.gIs_LEAN_MODE then
                            -- if #GroupStartLine > 10 and #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                              -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                            -- end
                          end
                          H.Report("","    -- Lines "..(iGLine + 1).." - "..(iGLine + linecount).." ADDED using text in [\""..My.tmp.."\"]"..H.extraKWinfo)
                        else
                          if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                            print(H._zBRIGHTGREEN.."    -- Line "..(iGLine + 1)..H._zDEFAULT.." "..H._zBRIGHTORANGE.."ADDED using text in"..H._zDEFAULT.." ["..H._zBRIGHTGREEN.."\""..My.tmp.."\""..H._zDEFAULT.."]"..H.extraKWinfo)
                          -- else -- if H.gIs_LEAN_MODE then
                            -- if #GroupStartLine > 10 and #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                              -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                            -- end
                          end
                          H.Report("","    -- Line "..(iGLine + 1).." ADDED using text in [\""..My.tmp.."\"]"..H.extraKWinfo)
                        end
                        
                        if not H.IsAddNeedsRemove then
                          --in case we have to replace ALL
                          GroupEndLine[thisGroup] = #TextFileTable --make sure we get to the new last line of the file
                          ADDcount = ADDcount + 1
                          repl_done = true
                          
                          iGLine = iGLine + linecount -- - 1 --point to the last line inserted
                        else
                          --we have a REMOVE to do, reset iGLine
                          if H.IsReplaceATLINE and VCTvalue == "IGNORE" then
                            -- we use the found line iGLine
                          else
                            iGLine = GroupStartLine[thisGroup]
                          end
                        end
                        
                      end --if My.IsTextToAdd then
                      -- print("EXIT My.IsTextToAdd")
                      
                      if My.IsToRemove or H.IsAddNeedsRemove then
                        -- print("My.IsToRemove or H.IsAddNeedsRemove")
                        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." IN: if REMOVE SECTION (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                        local tmpAtLine = iGLine
                        CurrentLine = iGLine --so we remember
                        
                        -- -- if true then
                          -- -- print("")
                          -- -- print(" + IN My.IsToRemove or H.IsAddNeedsRemove...")
                          -- -- print(" +                 IsReplace: ["..tostring(IsReplace).."]               IsReplaceRAW: ["..tostring(IsReplaceRAW).."]")
                          -- -- print(" +       IsPrecedingKeyWords: ["..tostring(H.IsPrecedingKeyWords).."]         IsSpecialKeyWords: ["..tostring(IsSpecialKeyWords).."]")
                          -- -- print(" +    IsOnePrecedingWordOnly: ["..tostring(H.IsOnePrecedingWordOnly).."]")
                          -- -- print(" +FirstPrecedingWordNotEmpty: ["..H.FirstPrecedingWordNotEmpty.."]            IsReplaceFOLLOWING: ["..tostring(IsReplaceFOLLOWING).."]")
                          -- -- print(" +              IsReplaceALL: ["..tostring(IsReplaceALL).."]".."             IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
                          -- -- print(" +     IsReplaceAllInSection: ["..tostring(IsReplaceAllInSection).."]")
                          -- -- print(" +      IsPrecedingFirstTRUE: ["..tostring(IsPrecedingFirstTRUE))
                          -- -- print(" +            My.IsTextToAdd: ["..tostring(My.IsTextToAdd)
                                    -- -- .."]  IsReplaceADDAFTERSECTION: ["..tostring(H.IsReplaceADDAFTERSECTION)
                                    -- -- .."]         IsReplaceADDAFTERLINE: ["..tostring(H.IsReplaceADDAFTERLINE)
                                    -- -- .."]     IsReplaceATLINE: ["..tostring(H.IsReplaceATLINE)
                                    -- -- .."]     IsReplaceWholeSECTION: ["..tostring(H.IsReplaceWholeSECTION).."]")
                          -- -- print(" +             My.IsToRemove: ["..tostring(My.IsToRemove)
                                    -- -- .."]            My.IsToRemoveLINE: ["..tostring(My.IsToRemoveLINE)
                                    -- -- .."]      My.IsToRemoveSECTION: ["..tostring(My.IsToRemoveSECTION)
                                    -- -- .."] My.IsToRemoveHBOS: ["..tostring(My.IsToRemoveHBOS).."]")
                          -- -- print(" +       IsValueMatchOptions: ["..tostring(IsValueMatchOptions).."]        value_match_options: ["..value_match_options.."]")
                          -- -- print(" +           IsWhereKeyWords: ["..tostring(IsWhereKeyWords).."]           H.IsSectionActive: ["..tostring(H.IsSectionActive).."]")
                          -- -- print(" +My.IsAllTheSameChangeTable: ["..tostring(My.IsAllTheSameChangeTable).."]")
                          -- -- print(" +              IsLineOffset: ["..tostring(IsLineOffset).."]")
                          -- -- print(" +               IsKWpattern: ["..tostring(H.IsKWpattern).."]")
                          -- -- print("")
                        -- -- end
                        
                        H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  BEFORE = "..#TextFileTable)
                        -- H.pv("    -- My.IsToRemove starting line: " .. iGLine)
                        
                        if My.IsToRemoveSECTION then
                          -- IsLineOffset is irrelevant
                          -- H.pv("    -- Removing SECTION at line: " .. iGLine)
                          -- print(TextFileTable[CurrentLine])
                          
                          local top = GroupStartLine[thisGroup] --the top of this section
                          local bottom = GroupEndLine[thisGroup] --the end of this ssection
                          
                          -- Hmm, always auto-create a HOES???
                          if My.IsCreateHOESTRUE then
                            -- remember top line and make it a HOES
                            My.topLineHOES = TextFileTable[top]:gsub([[">]],[[" />]])..H.modCHANGED
                          end
                          
                          -- print(H.dClock().." "..top.."-"..bottom)
                          --delete section from exml
                          My.abortedRemove = false
                          if bottom > #TextFileTable or top > #TextFileTable then
                            My.abortedRemove = true
                            print(">>> "..H.gcWARNING.." [WARNING] Remove operation aborted, lines "..top.."-"..bottom.." are out of range! "..H._zDEFAULT)
                            H.Report("","Remove operation aborted, lines "..top.."-"..bottom.." are out of range!","WARNING")
                          else
                          -- H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  BEFORE_2 = "..#TextFileTable)
                          -- -- H.WriteToFile(H.ConvertLineTableToText(TextFileTable),[[BEFORE_2.lua]])
                          -- H.WriteToFile(TextFileTable,[[BEFORE_2.lua]])
                          -- for m = 1,10 do
                            -- H.printf("& %4d: [%s]",m,TextFileTable[m])
                          -- end
                          -- print(" = = = = = = &")
                            for m = top,bottom do
                              -- H.printf("* %d: %s",m,TextFileTable[m])
                              TextFileTable[m] = "NIL"
                            end
                            -- print(" = = = = = = *")
                                                  -- DPType("H.EXMLmodTable[H.NMSPathFileLessEXML]",H.EXMLmodTable[H.NMSPathFileLessEXML])
                                                  -- DPType("My.TextFileTable_bak",My.TextFileTable_bak)
                                                  -- DPType("TextFileTable",TextFileTable)
                                                  -- print("before refresh: "..tostring(TextFileTable[top]))
                            -- H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  BEFORE_3 = "..#TextFileTable)
                            -- -- H.WriteToFile(H.ConvertLineTableToText(TextFileTable),[[BEFORE_3.lua]])
                            -- H.WriteToFile(TextFileTable,[[BEFORE_3.lua]])
                            
                            local clonedTextFileTable = H.cloneArray(TextFileTable)
                            H.DEBUG_TextToRemove_print("=== text_to_remove: #clonedTextFileTable  BEFORE_3 = "..#clonedTextFileTable)
                            
                            -- for m = 1,10 do
                              -- H.printf("# %4d: [%s]",m,TextFileTable[m])
                            -- end
                            -- print(" = = = = = = #")
                            
                            TextFileTable = H.refreshTable(TextFileTable)
                            -- print(" = = = = = = H.refreshTable")
                            
                            -- for m = 1,#clonedTextFileTable do
                              -- if clonedTextFileTable[m] ~= TextFileTable[m] then
                                -- H.printf("! %4d: [%s] ~= [%s]",m,clonedTextFileTable[m],TextFileTable[m])
                              -- end
                            -- end
                            -- print(" = = = = = = !")
                                                  -- print("after refresh: "..tostring(TextFileTable[top]))
                            -- H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  AFTER_1 = "..#TextFileTable)
                            -- H.WFAKD()
                            if not IsEditSection then
                              -- refresh the modded table because TextFileTable is a new table
                              H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                              H.TextFileTableCheck = TextFileTable
                              TextFileTable_bak = TextFileTable
                              -- DPType("H.EXMLmodTable[H.NMSPathFileLessEXML]",H.EXMLmodTable[H.NMSPathFileLessEXML])
                              -- DPType("My.TextFileTable_bak",My.TextFileTable_bak)
                              -- DPType("TextFileTable",TextFileTable)
                            else
                              -- NOT DOING THAT: we are in SEC_EDIT
                              -- refresh the modded table because TextFileTable is a new table
                              -- H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                              -- My.TextFileTable_bak = TextFileTable
                            end
                            H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  AFTER_2 = "..#TextFileTable)
                          end
                          -- H.WFAK()                          
                          
                          if not My.abortedRemove then
                            if not H.gIs_LEAN_MODE then 
                              -- printf("         H.gIs_DEV_MODE = %s",tostring(H.gIs_DEV_MODE))
                              -- printf("        H.gIs_FULL_MODE = %s",tostring(H.gIs_FULL_MODE))
                              -- printf("IsLargeNumOfGroupsFound = %s",tostring(IsLargeNumOfGroupsFound))
                              -- printf("IsLargeNumOfReplacement = %s",tostring(IsLargeNumOfReplacement))
                              -- H.WFAK()
                              if (H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE then
                                print(H._zBRIGHTGREEN.."    -- Lines "..top.." - "..bottom..H._zBRIGHTORANGE.." REMOVED"..H._zDEFAULT..H.extraKWinfo)
                              end
                            -- else
                              -- if #GroupStartLine > 10 and #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                                -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                              -- end
                            end
                            H.Report("","    -- Lines "..top.." - "..bottom.." REMOVED"..H.extraKWinfo)
                            H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." JUST AFTER: if REMOVE SECTION (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))

                            -- Hmm, always auto-create a HOES???
                            if My.IsCreateHOESTRUE then
                              -- insert the HOES line
                              table.insert(TextFileTable,top,My.topLineHOES)
                              My.IsHOESCreated = true
                              print("    -- Created HOES "..H._zBRIGHTGREEN.."at line "..top..H._zDEFAULT..H.extraKWinfo)
                              H.Report("","    -- Created HOES at line "..top..H.extraKWinfo)
                            end                          
                          end
                          H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  AFTER_3 = "..#TextFileTable)
                          
                        elseif My.IsToRemoveLINE then
                          iGLine = tonumber(SpecialKeyWordLine[thisGroup])
                          if iGLine == nil and IsEditSection then
                            iGLine = 1
                          elseif iGLine == nil and not (IsEditSection or H.IsReplaceATLINE) then
                            -- should not happen
                            print(">>> "..H.gcERROR..[[ [BUG] "SpecialKeyWordLine[thisGroup] == nil and not (IsEditSection or IsReplaceATLINE)" ]]..H._zDEFAULT)
                            H.Report("",[=[>>> [[BUG]] "SpecialKeyWordLine[thisGroup] == nil and not (IsEditSection or IsReplaceATLINE)"]=])
                          end
                          H.pv("    -- Removing LINE at line: " .. tostring(iGLine))
                          
                          if IsLineOffset then
                            --we offset from the line found by the keywords
                            H.pv("    -- line before applying offset: " .. tostring(iGLine))
                            if offset_sign == "+" then
                              iGLine = iGLine + offset
                              if iGLine > #TextFileTable then
                                iGLine = #TextFileTable - 1
                              end
                            elseif offset_sign == "-" then
                              iGLine = iGLine - offset
                              if not IsEditSection and iGLine < 3 then
                                iGLine = 3 --it must be after the header at least
                              end
                            end
                            H.pv("    -- line after applying offset: " .. tostring(iGLine))
                          end
                          
                          H.pv("    -- Removing LINE at line: " .. tostring(iGLine))
                          
                          if H.IsReplaceATLINE then
                            --we need to adjust older iGLine
                            iGLine = tmpAtLine
                            if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                              print(H._zBRIGHTGREEN.."    -- Original line "..iGLine..H._zBRIGHTORANGE.." REMOVED"..H._zDEFAULT..H.extraKWinfo)
                            -- else -- if H.gIs_LEAN_MODE then
                              -- if #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                                -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                              -- end
                            end
                            H.Report("","    -- Original line "..iGLine.." REMOVED"..H.extraKWinfo)
                          else
                            if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                              print(H._zBRIGHTGREEN.."    -- Line "..iGLine..H._zBRIGHTORANGE.." REMOVED"..H._zDEFAULT..H.extraKWinfo)
                            -- else -- if H.gIs_LEAN_MODE then
                              -- if #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                                -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                              -- end
                            end
                            H.Report("","    -- Line "..iGLine.." REMOVED"..H.extraKWinfo)
                          end
                          
                          --delete line iGLine from exml
                          if #TextFileTable >= iGLine then
                            -- table.remove(TextFileTable,iGLine)
                            TextFileTable[iGLine] = "NIL"
                            TextFileTable = H.refreshTable(TextFileTable)

                            if not IsEditSection then
                              -- refresh the modded table because TextFileTable is a new table
                              H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                              H.TextFileTableCheck = TextFileTable
                              TextFileTable_bak = TextFileTable
                            end
                          else
                            print(">>> "..H.gcWARNING.." [WARNING] Remove operation aborted, line "..iGLine.." is out of range! "..H._zDEFAULT)
                            H.Report("","Remove operation aborted, line "..iGLine.." is out of range!","WARNING")
                            break
                          end
                          
                        elseif My.IsToRemoveHBOS then
                          -- trim top and bottom lines of section
                          if IsEditSection then
                            -- TextFileTable holds the scetion
                            if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                              print(H._zBRIGHTGREEN.."    -- REMOVED line 1 of NAMED_SECTION: "..H._zDEFAULT.."["..TextFileTable[1].."]"..H.extraKWinfo)
                              print(H._zBRIGHTGREEN.."           and line "..#TextFileTable..": "..H._zDEFAULT.."["..TextFileTable[#TextFileTable].."]")
                            -- else -- if H.gIs_LEAN_MODE then
                              -- if #GroupStartLine > 10 and thisGroup%(#GroupStartLine//10) == 0 then
                                -- print("    -- "..thisGroup..[[/]]..#GroupStartLine)
                              -- end
                            end
                            H.Report("","    -- REMOVED line 1 of NAMED_SECTION: ".."["..TextFileTable[1].."]"..H.extraKWinfo)
                            H.Report("","           and line "..#TextFileTable..": ".."["..TextFileTable[#TextFileTable].."]")
                            -- table.remove(TextFileTable,1)
                            -- table.remove(TextFileTable) -- same as table.remove(TextFileTable,#TextFileTable)
                            TextFileTable[1] = "NIL"
                            TextFileTable[#TextFileTable] = "NIL"
                            TextFileTable = H.refreshTable(TextFileTable)
                            
                            -- NOT DOING THAT: we are in SEC_EDIT
                            -- refresh the modded table because TextFileTable is a new table
                            -- H.EXMLmodTable[H.NMSPathFileLessEXML] = TextFileTable
                            -- My.TextFileTable_bak = TextFileTable
                            
                          else
                            print(">>> "..H.gcWARNING.." [WARNING] Remove HBOS operation aborted, no 'saved' section to edit! "..H._zDEFAULT)
                            H.Report("","Remove HBOS operation aborted, no 'saved' section to edit!","WARNING")
                            break
                          end
                        end
                        
                        H.DEBUG_TextToRemove_print("=== text_to_remove: #TextFileTable  AFTER = "..#TextFileTable)
                        
                        iGLine = CurrentLine --point to the next line to process
                        
                        REMOVEcount = REMOVEcount + 1
                        repl_done = true
                        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." JUST after DONE REMOVE SECTION (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                        H.Dprintf(H._zWHITEonDARKCYAN.."=== === === ==="..H._zDEFAULT,nil)
                      end --if My.IsTextToAdd then AND if My.IsToRemove then
                      
                      if H.gIs_LEAN_MODE or IsLargeNumOfReplacement then
                        My.dotCount = My.dotCount + 1
                        if My.dotCount%10 == 0 then
                          if My.IsdotOn then
                            My.IsdotOn = false
                              print(H._zUpOneLine..[[ / ]])
                          else
                            My.IsdotOn = true
                            print(H._zUpOneLine..[[ \ ]])
                          end
                        end
                      end
                      
                    end --if My.IsTextToAdd or My.IsToRemove then
                    
                  else
                    --no match_type
                    --REMARKED to reduce clutter in output
                    -- H.Report("","Line "..iGLine..", ["..VCTproperty.."] with a value of ["..exstring.."] does not match a ["..value_match_type..
                              -- "] like ["..value.."], XXXXX this value not replaced XXXXX","WARNING")
                    if exstring and iGLine ~= 1 then
                      -- iGLine ~= 1: not the 1st line of the group
                      if not H.gIs_LEAN_MODE then print("      -- Line "..iGLine..","..H.gcWARNING.." ["..exstring.."] type does not match a ["..value_match_type.."] "..H._zDEFAULT) end
                    end
                  end --value_match_type == type(value) or empty
                  
                end --value_match == value or empty
              end --we found THE line in the EXML file
            end --if IsReplaceRAW then
            
            local pr = function() end
            if gDEBUG_repl_done then
              pr = print
            end
            
            -- if H.gIs_LEAN_MODE or IsLargeNumOfReplacement then
            if H.gIs_LEAN_MODE or IsLargeNumOfGroupsFound then
              My.dotCount = My.dotCount + 1
              if My.dotCount%10 == 0 then
                if My.IsdotOn then
                  My.IsdotOn = false
                    print(H._zUpOneLine.." * ")
                else
                  My.IsdotOn = true
                  print(H._zUpOneLine.."  *")
                end
              end
            end
            
            -- ###################  DONE SECTION ####################
            
            -- collectgarbage("step",0)
            -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." FORCED collectgarbage (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
            H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." JUST BEFORE repl_done (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
            if repl_done then
              H.Dprintf(" ==> In repl_done")
              AtLeastOneReplacementDone = true
              IsOneReplacementDoneThisValue = true
              if not (My.IsTextToAdd or My.IsToRemove) then
                if VCTvalue == "IGNORE" then
                  local spacer = "    "
                  local part1 = "-> On line "..(iGLine - My.negOffset)..", SKIPPED this line"
                  H.Report("",spacer..part1)
                  if not H.gIs_LEAN_MODE then print(H._zBRIGHTGREEN.."      -- Line "..(iGLine - My.negOffset)..H._zDEFAULT..", SKIPPED this line") end
                  
                else
                  local spacer = "      "
                  local spacer1 = "    "
                  local spacer2 = spacer1
                  local part = H.trim(line):gsub(H.modFlag..[[.*]],"") --for Report and cmd
                  
                  --for Report
                  local Rpart1 ="-> On line "..(iGLine - My.negOffset)..", exchanged:" .. spacer1 .. "[" .. part .. "]"
                  local Rpart3 = H.trim(TextFileTable[iGLine]):gsub(H.modFlag..[[.*]],"")
                  -- if strfind(line,[[<Property name=]],1,true) and strfind(line,[[value=]],1,true) then
                    -- if not IsReplaceRAW then
                      -- --we can cut out that part
                      -- local pos = strfind(part3,[[value=]],1,true)
                      -- if pos then
                        -- Rpart3 = H._zBRIGHTGREEN.."... "..H._zDEFAULT..strsub(Rpart3,pos)
                      -- end
                    -- else
                      -- Rpart3 = strsub(part3,1,200)..[[\n..trimmed..\n]]..strsub(Rpart3,-200)
                   -- end
                  -- end
                  
                  --everything full length
                  H.Report("",spacer..Rpart1 .. spacer1 .. "with: " .. spacer2 .. "[" .. Rpart3 .. "]")
                  
                  if H.numChangeTableRepl < H.gMaxReplNumber then
                    --for cmd
                    if #part > 100 then
                      part = strsub(part,1,30)..H._zBRIGHTGREEN..[[ ..trimmed.. ]]..H._zDEFAULT..H.ltrim(strsub(part,-30))
                    end
                    
                    local part2 = H._zBRIGHTGREEN.."-> On line "..(iGLine - My.negOffset)..H._zDEFAULT..", exchanged:" .. spacer1 .. "[" .. part .. "]"
                    if #part2 < 86 then
                      spacer1 = strrep(" ",86 - #part2 + #spacer1)
                    end
                    
                    local part4 = Rpart3 --for cmd
                    if not H.gIs_LEAN_MODE and ((H.gIs_DEV_MODE and not (IsLargeNumOfGroupsFound or IsLargeNumOfReplacement)) or H.gIs_FULL_MODE) then
                      if not IsReplaceRAW then
                        if #part4 > 100 then
                          part4 = strsub(part4,1,30)..H._zBRIGHTGREEN..[[ ..trimmed.. ]]..H._zDEFAULT..H.ltrim(strsub(part4,-30))
                        end
                      else
                        if #part4 > 200 then
                          part4 = strsub(part4,1,50)..H._zBRIGHTGREEN..[[ ..trimmed.. ]]..H._zDEFAULT..H.ltrim(strsub(part4,-50))
                        end
                      end
                      print(spacer..part2 .. spacer1 .. "with: " .. spacer2 .. "[" .. part4 .. "]")
                    end
                  else --ReplNumber >= H.gMaxReplNumber
                    if not IsLargeNumOfReplacement and not H.gIs_LEAN_MODE then
                      IsLargeNumOfReplacement = true
                      print(H._zBRIGHTGREEN..">>> "..H._zYELLOW.."LARGE number"..H._zDEFAULT..H._zBRIGHTGREEN.." of similar replacements detected "..H._zYELLOW.."(limiting log.lua output)"..H._zDEFAULT)
                      print(H._zYELLOW.."               BE PATIENT"..H._zDEFAULT..", the output may only seem to stop at times...")
                    end
                  end
                  
                  if (iGLine > EndLine) or ((iGLine - My.negOffset) < StartLine) then
                    -- if not IsReplaceFOLLOWING then
                      if H.numChangeTableRepl < H.gMaxReplNumber then
                        print(">>> "..H.gcNOTICE.." [NOTICE] -???- Replacement(s) outside of the search group: "..My.SearchGroupRange..".  Could be Ok, you decide... -???- "..H._zDEFAULT)
                      end
                      H.Report("","-???- Replacement(s) outside of the search group: "..My.SearchGroupRange..".  Could be Ok, you decide... -???-","NOTICE")
                    -- end
                    --update 'EndLine' so we do not repeat this NOTICE
                    EndLine = GroupEndLine[thisGroup]
                    StartLine = GroupStartLine[thisGroup]
                  end
                  
                  H.numChangeTableRepl = H.numChangeTableRepl + 1
                  ReplNumber = ReplNumber + 1
                end
                
                -- local IsWholeFileSearch = (not H.IsPrecedingKeyWords and not IsSpecialKeyWords) or IsReplace and (not IsReplaceAllInGroup)
                
                if not H.IsListOfValues and (My.IsAllTheSameChangeTable or My.IsAllChangeTableIGNORE) then -- ??? but not "IGNORE"
                  --when #val_change_table > 1 and the val_change_table[H.jVCT][1] are all the same 'name' (like "Bonus" for instance)
                  --we need to auto-advance the line counter
                  H.DEBUG_LoopBreak_print("A0: My.IsAllTheSameChangeTable = "..tostring(My.IsAllTheSameChangeTable))
                  H.DEBUG_LoopBreak_print("A0: AUTO_advancing GroupStartLine by one")
                  GroupStartLine[thisGroup] = iGLine + 1 --this is going to be the new GroupStartLine for ThisGroup when processing the next VALUE_CHANGE
                  H.DEBUG_LoopBreak_print("A0: changed GroupStartLine["..thisGroup.."] to "..GroupStartLine[thisGroup])
                -- elseif My.IsAllChangeTableIGNORE then
                  -- --when #val_change_table > 1 and the val_change_table[H.jVCT][1] are all 'IGNORE'
                  -- --we need to auto-advance the line counter
                  -- H.DEBUG_LoopBreak_print("A1: My.IsAllChangeTableIGNORE = "..tostring(My.IsAllChangeTableIGNORE))
                  -- H.DEBUG_LoopBreak_print("A1: AUTO_advancing GroupStartLine by one")
                  -- GroupStartLine[thisGroup] = iGLine + 1 --this is going to be the new GroupStartLine for ThisGroup when processing the next VALUE_CHANGE
                  -- H.DEBUG_LoopBreak_print("A1: changed GroupStartLine["..thisGroup.."] to "..GroupStartLine[thisGroup])
                end

                if My._mISxxx then
                  print(" x x x x x x x x x")
                  print(" + DONE: BEFORE Loop/Break (NOT ADD/REMOVE)")
                  print(" +                IsLineOffset: ["..tostring(IsLineOffset).."]")
                  print(" +                   IsReplace: ["..tostring(IsReplace).."]")
                  print(" +                IsReplaceRAW: ["..tostring(IsReplaceRAW).."]")
                  print(" +               IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
                  print(" +  IsReplaceONCEInsideSection: ["..tostring(IsReplaceONCEInsideSection).."]")
                  print(" +                IsReplaceALL: ["..tostring(IsReplaceALL).."]")
                  print(" +       IsReplaceAllInSection: ["..tostring(IsReplaceAllInSection).."]")
                  print(" +   IsReplaceAllInsideSection: ["..tostring(IsReplaceAllInsideSection).."]")
                  print(" +          IsReplaceFOLLOWING: ["..tostring(IsReplaceFOLLOWING).."]")
                  print(" +   My.IsOrgReplace_typeEmpty: ["..tostring(My.IsOrgReplace_typeEmpty).."]")
                  print(" +  My.IsAllTheSameChangeTable: ["..tostring(My.IsAllTheSameChangeTable).."]")
                  print(" x x x x x x x x x")
                end
                
                --==================================================================================
                --here we decide if we continue down the file or break for a new val_change_table combo
                if IsReplaceRAW then
                  --because we want to continue replacing values down the file until GroupEndLine[thisGroup]
                  --Note: if ADD was used, we already point to the last line inserted
                  H.DEBUG_LoopBreak_print("RAW: Looping in this group to continue replacing values down the file until GroupEndLine[thisGroup] = "..GroupEndLine[thisGroup])
                  
                elseif IsReplaceAllInSection then
                  -- IsReplaceAllInSection == (replace_type == "ALLINSECTION") or IsReplaceAllInsideSection
                  IsLineOffset = false --turning line offset off to process the next line                  
                  H.DEBUG_LoopBreak_print("A1: Looping in this group to continue replacing values down the section")
                  
                elseif H.IsListOfValues then
                  break
                  
                elseif My.IsAllTheSameChangeTable then --when IGNORE is not used
                  -- and it was not a ReplaceAll action
                  
                  -- when #val_change_table > 1 and the val_change_table[H.jVCT][1] are all the same 'name' (like "Bonus" for instance)
        
                  -- why we need to auto-advance the line counter? because offset was not turned on by IGNORE
                  GroupStartLine[thisGroup] = iGLine + 1 --this is going to be the new GroupStartLine for thisGroup when processing the next VALUE_CHANGE in this group
                  H.DEBUG_LoopBreak_print("B: GroupStartLine["..thisGroup.."] = "..GroupStartLine[thisGroup].." and current line iGLine = "..iGLine)
                  H.DEBUG_LoopBreak_print("B: break out of this group on My.IsAllTheSameChangeTable to next group to continue replacing ALL value down the file from "..LastReplacementLine.." until GroupEndLine[thisGroup] = "..GroupEndLine[thisGroup])
                  break
                  
                elseif IsReplaceONCE then
                  -- IsReplaceONCE == (replace_type == "ONCE") or IsReplaceONCEInsideSection
  
                  H.DEBUG_LoopBreak_print("C: break out of this group on IsReplaceONCE to next VCT entry to continue replacing ONE value down the file from "..iGLine.." until GroupEndLine[thisGroup] = "..GroupEndLine[thisGroup])
                  break
                  
                elseif IsReplaceALL or My.IsOrgReplace_typeEmpty then
                  -- because we want to continue replacing values
                  -- Note: if ADD was used, we already point to the last line inserted
                  H.DEBUG_LoopBreak_print("D: Looping in this group to continue replacing values down the file")
                  
                elseif not IsReplaceALL then
                  -- our replacement is done, we exit this group
                  H.DEBUG_LoopBreak_print("E: break out of this group on 'not IsReplaceALL' to next group")
                  break
                  
                else
                  -- not an approved word for replace_type maybe
                  -- ANYWAY, we are done for this bunch
                  -- should NOT happen
                  print("F: [BUG] break out of this group on not an approved replace_type to next group")
                  break
                end
                
              else -- My.IsTextToAdd or My.IsToRemove
                if My._mISxxx then
                  print(" x x x x x x x x x")
                  print(" + DONE: BEFORE Loop/Break on ADD/REMOVE")
                  print(" +                IsLineOffset: ["..tostring(IsLineOffset).."]")
                  print(" +                   IsReplace: ["..tostring(IsReplace).."]")
                  print(" +                IsReplaceRAW: ["..tostring(IsReplaceRAW).."]")
                  print(" +               IsReplaceONCE: ["..tostring(IsReplaceONCE).."]")
                  print(" +  IsReplaceONCEInsideSection: ["..tostring(IsReplaceONCEInsideSection).."]")
                  print(" +                IsReplaceALL: ["..tostring(IsReplaceALL).."]")
                  print(" +       IsReplaceAllInSection: ["..tostring(IsReplaceAllInSection).."]")
                  print(" +   IsReplaceAllInsideSection: ["..tostring(IsReplaceAllInsideSection).."]")
                  print(" +          IsReplaceFOLLOWING: ["..tostring(IsReplaceFOLLOWING).."]")
                  print(" +   My.IsOrgReplace_typeEmpty: ["..tostring(My.IsOrgReplace_typeEmpty).."]")
                  print(" +  My.IsAllTheSameChangeTable: ["..tostring(My.IsAllTheSameChangeTable).."]")
                  print(" x x x x x x x x x")
                end
                
                -- get to next section
                H.DEBUG_LoopBreak_print("G: break out of this group on My.IsTextToAdd or My.IsToRemove to next group")
                break
              end
              
              -- My.linesNumFound[1] = nil -- reset for next iGLine for now...  should break out of while loop when only one found
              
            else
              --no repl_done on 'this line'
              if IsSpecialKeyWords and not IsPrecedingFirstTRUE and IsOnlyOnePreceding then
                --lets go down until we find VALUE_CHANGE_TABLE, even outside the bottom of the section
                H.DEBUG_LoopBreak_print("on line "..iGLine..": No repl_done, but IsSpecialKeyWordsand not IsPrecedingFirstTRUE and IsOnlyOnePreceding, so continuing down in the group...")
                
                if iGLine == GroupEndLine[thisGroup] and not IsOneReplacementDoneThisValue then
                  --we are at the end of the group and did not find a replacement
                  --we can try to go down to the end of file
                  
                  --Wbertro: this could instead go up one level in the EXML
                  
                  H.DEBUG_LoopBreak_print(">>> reached end of this group and 'No repl_done', so setting GroupEndLine["..thisGroup.."] to end of file...")
                  GroupEndLine[thisGroup] = #TextFileTable
                end
              end
              
            end -- if repl_done then
            -- ###################  END: DONE SECTION ####################
            
          end -- while iGLine <= (GroupEndLine[thisGroup] - 1) and (#My.linesNumFound > 0 or My.IsTextToAdd or My.IsToRemove or IsReplaceRAW or VCTproperty == "IGNORE") do (each line in a group)
          
          H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." DONE ALL lines (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
          H.DEBUG_LoopBreak_print(">>> Done ALL lines, exited 'inner' <<lines in group(thisGroup)>> while and looking for next Group")
          H.DEBUG_LoopBreak_print("    >>> was GroupStartLine[thisGroup] - GroupEndLine[thisGroup] = "..GroupStartLine[thisGroup].." - "..GroupEndLine[thisGroup])
          
          -- if IsReplaceFOLLOWING and GroupEndLine[thisGroup] == #TextFileTable then
            -- H.DEBUG_LoopBreak_print("W: break out of 'ALL' Groups on IsReplaceFOLLOWING to next VCT entry")
            -- -- --restore group 'end line' for next VALUE_CHANGE
            -- -- GroupEndLine[thisGroup] = EndLineBackup
            -- break
          -- end
          
        end -- while thisGroup <= #GroupStartLine - 1 do (looping lines in a group)
        H.DEBUG_LoopBreak_print(">>> Done ALL groups, exited 'groups while', now looking for next VALUE_CHANGE")

        if not My.IsHOSCreated and not IsOneReplacementDoneThisValue then
          if IsNotice_off then
            print(">>> "..H.gcNOTICE.." NO Replacement done "..H._zDEFAULT)
            H.Report("","'                    NO Replacement done'","")
          else
            print(">>> "..H.gcNOTICE.." [NOTICE] NO Replacement done.  Could be Ok, you decide... "..H._zDEFAULT)
            H.Report("","NO Replacement done.  Could be Ok, you decide...","NOTICE")
          end
        elseif IsLargeNumOfGroupsFound then
          print(H._zBRIGHTGREEN..">>> Possible large number of Actions were done"..H._zDEFAULT)
        end
        
      end -- while H.jVCT <= (#val_change_table - 1) do (looping each VCT entry)
      H.DEBUG_LoopBreak_print(">>> Done ALL VCT entries: exited 'val_change_table outer' while")
      
      H.DEBUG_SEC_print("@@@@@     E: AtLeastOneReplacementDone = "..tostring(AtLeastOneReplacementDone))
      H.DEBUG_SEC_print("@@@@@     E:        My.IsSaveSectionTo = "..tostring(My.IsSaveSectionTo))
      H.DEBUG_SEC_print("@@@@@     E:        My.IsKeepSection = "..tostring(My.IsKeepSection))
      H.DEBUG_SEC_print("@@@@@     E:        IsEditSection = "..tostring(IsEditSection))
      H.DEBUG_SEC_print("@@@@@     E:        IsEmptySection = "..tostring(IsEmptySection))
      
      if AtLeastOneReplacementDone and (My.IsSaveSectionTo or My.IsKeepSection or IsEditSection) then
        --saving the section with changes
        
        H.DEBUG_SEC_print("@@@@@     E: ["..TextFileTable[1].."]")
        if type(TextFileTable[1]) == "string" and H.trim(TextFileTable[1]):sub(1,5) == [[<?xml]] then
          H.DEBUG_SEC_print("@@@@@     E: >>> ActiveFile is a full MXML")
          if My.IsKeepSection then
            --save the first section found to a file in the TOOLS\SavedSections folder using the SEC_EDIT name.xml
            --we overwrite any existing file with that name
            --we save internally
            --we save it with changes done
            -- H.thisSection = ""
            -- for m=GroupStartLine[1],GroupEndLine[1] do
              -- local line = TextFileTable[m]
              -- H.thisSection = H.thisSection..line.."\n"
            -- end
            if My.IsSaveSectionTo then
              if TextFileTable[GroupStartLine[1]] then
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: #TextFileTable = "..#TextFileTable)
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: For section "..GroupStartLine[1].."-"..GroupEndLine[1])
                -- get section and remove the _id/_index
                
                H.thisSection = ""
                if H.IsEXMLflagUPDATESECTION then
                  H.thisSection = table.concat(TextFileTable,"\n",GroupStartLine[1],GroupEndLine[1]):gsub(H.modFlag.." %w*","")
                else
                  H.thisSection = table.concat(TextFileTable,"\n",GroupStartLine[1],GroupEndLine[1]):gsub([[ _.-=".-"]], ""):gsub(H.modFlag.." %w*","")
                end
                
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: H.thisSection = ("..#H.thisSection..") ["..strsub(H.thisSection,1,300).."...]")
                
                H.DEBUG_SEC_print([[@@@@@ KEEP_SECTION: Writing SEC_save_to a file in the TOOLS\SavedSections folder after changes]])
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: sec_save_to = <"..sec_save_to..">")
                
                H.WriteToFile(H.thisSection,H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..sec_save_to..[[.xml]])
                
                -- ALWAYS save it internally!!!
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: Saving content of SEC_save_to in the internal gSection list (just after GROUPS defined)")
                H.gSection[sec_save_to] = H.thisSection
                -- IsOneReplacementDoneThisValue = true
              end
            else
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: #TextFileTable = "..#TextFileTable)
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: For the whole EXML")
                H.thisSection = table.concat(TextFileTable,"\n"):gsub(H.modFlag.." %w*","")
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: H.thisSection = ["..strsub(H.thisSection,1,200).."]")
                
                H.DEBUG_SEC_print([[@@@@@ KEEP_SECTION: Writing SEC_save_to a file in the TOOLS\SavedSections folder after changes]])
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: sec_save_to = <"..H.GetFilenameFromFilePath(file)..">")
                
                H.WriteToFile(H.thisSection,H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..H.GetFilenameFromFilePath(file)..[[.xml]])
                
                -- ALWAYS save it internally!!!
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: Saving content of SEC_save_to in the internal gSection list (just after GROUPS defined)")
                H.gSection[sec_save_to] = H.thisSection
                -- IsOneReplacementDoneThisValue = true
            end
          end
          
        else --if GroupStartLine[1] and H.trim(GroupStartLine[1]):sub(1,5) ~= [[<?xml]] then
          H.DEBUG_SEC_print("@@@@@     E: >>> ActiveFile is a saved section")
          -- if IsUpdateSection then
          if IsEditSection or My.IsKeepSection then
            --save ALL of TextFileTable to a file in theTOOLS\SavedSections folder using the SEC_SAVE_TO name.xml
            --we overwrite any existing file with that name
            --we save internally
            --we save it with changes done

            -- H.thisSection = ""
            -- for m=1,#TextFileTable do
              -- local line = TextFileTable[m]
              -- H.thisSection = H.thisSection..line.."\n"
            -- end
            
            -- H.tmp = H.modADDED.." Z8"
            for i=1,#TextFileTable do
              if strfind(TextFileTable[i],H.modFlag,1,true) == nil then
                TextFileTable[i] = TextFileTable[i]..H.modADDED -- .." Z8"
              end
            end
            
            -- H.thisSection = table.concat(TextFileTable,H.tmp.."\n")..H.tmp
            H.thisSection = table.concat(TextFileTable,"\n")
            H.DEBUG_SEC_print("@@@@@ EDIT_SECTION: H.thisSection = ["..strsub(H.thisSection,1,200).."...]")
            
            -- ALWAYS save it internally!!!
            H.DEBUG_SEC_print("@@@@@ EDIT_SECTION: Saving content of SEC_edit in the internal gSection list (just after GROUPS defined)")
            H.gSection[sec_edit] = H.thisSection
            -- IsOneReplacementDoneThisValue = true

            if My.IsKeepSection then
              if sec_save_to ~= "" then
                H.DEBUG_SEC_print([[@@@@@ KEEP_SECTION: Writing to file in the TOOLS\SavedSections folder after changes]])
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: writing to file <"..sec_save_to..">")
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: #TextFileTable = "..#TextFileTable.." lines")
                
                H.WriteToFile(H.thisSection,H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..sec_save_to..[[.xml]])
              
              elseif sec_edit ~= "" then
                H.DEBUG_SEC_print([[@@@@@ KEEP_SECTION: Writing to file in the TOOLS\SavedSections folder after changes]])
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: writing to file <"..sec_edit..">")
                H.DEBUG_SEC_print("@@@@@ KEEP_SECTION: #TextFileTable = "..#TextFileTable.." lines")
                
                H.WriteToFile(H.thisSection,H.gMASTER_FOLDER_PATH..[[TOOLS\SavedSections\]]..sec_edit..[[.xml]])
              end
            end
          end
        end
      end
      
      if SaveSectionDone then
        ReplNumber = ReplNumber + 1
      end
      
      -- H.printf("AtLeastOneReplacementDone = %s",tostring(AtLeastOneReplacementDone))
      -- H.DEBUG_SEC_print("@@@@@ F: not AtLeastOneReplacementDone and not SaveSectionDone = "..tostring(not AtLeastOneReplacementDone and not SaveSectionDone))
      if not AtLeastOneReplacementDone and not SaveSectionDone then
        --replacement NOT done
        print("")
        print(">>> "..H.gcWARNING.." [WARNING] No action done! "..H._zDEFAULT)
        H.Report("","No action done!","WARNING")
      else
        -- this is done by the calling function
        -- H.pv("Saving changes to "..file)
        -- -- H.WriteToFile(H.ConvertLineTableToText(TextFileTable), file)
        -- H.WriteToFile(TextFileTable, file)
      end
      
    else
      -- -- H.Report(VCTproperty,"Could not find PRECEDING_KEY_WORDS or SPECIAL_KEY_WORDS!","WARNING")
    end
  
    H.mPKW = H.mPKW + 1
  until H.mPKW > #H.prec_key_words

  -- ShowLocals()
  -- H.WFAK()

  H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." EXITING: ExchangePropertyValue() (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- H.Report_flush(true)
  return TextFileTable, ReplNumber, ADDcount, REMOVEcount, My.IsFUNCexist
  -- looping to next MXML_CHANGE_TABLE
end -- END: ExchangePropertyValue()

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

--***************************************************************************
function GetLASTsections(SectionsTable)
  --all the LAST group of sections
  local LASTSections = {}
  
  --all other sections
  local OtherSections = {}
  
  local LASTtoken = string.sub(SectionsTable[#SectionsTable],1,6)
  
  for j=1,#SectionsTable do
    if string.find(SectionsTable[j],LASTtoken,1,true) then
      --the LAST group of sections
      LASTSections[#LASTSections+1] = SectionsTable[j]
    else
      --lines without the LASTtoken
      OtherSections[#OtherSections+1] = SectionsTable[j]
    end
  end
  return LASTSections,OtherSections
end
--***************************************************************************

-- *************************************** handles SECTION_ACTIVE ***********************************
function ProcessSECTION_ACTIVE(GSL,GEL,SKWL,SectionActive,TextFileTable,KWinfo)
  --ACTIVE groups
  local GSLA = {}
  local GELA = {}
  local SKWLA = {}
  local KWinfoA = {}
  
  --INACTIVE groups
  local GSLI = {}
  local GELI = {}
  local SKWLI = {}
  local KWinfoI = {}
  
  if #SectionActive == 0 then
    --all groups are active
    return GSL,GEL,SKWL,KWinfo,GSLI,GELI,SKWLI,KWinfoI,false,false
  end
  
  -- handle LAST
  for i=1,#SectionActive do
    if SectionActive[i] == math.huge then
      SectionActive[i] = #GSL - 1 -- because _index starts at 0
    end
  end
  
  -- remove duplicates
  for i=#GSL,2,-1 do
    if GSL[i] == GSL[i-1] then
      -- remove the current one
      GSL[i] = nil
      GEL[i] = nil
      SKWL[i] = nil
      KWinfo[i] = nil
    end
  end
  
  local IsSkipped = false
  -- local IsListOfValues = false

  -- for i=1,#GSL do
    -- check if 1st group is a list of values (LoV)
    
    local IsListOfValues = false
    -- H.printf("GSL[1] = [%s]",GSL[1])
    -- H.printf("TextFileTable[GSL[1]] = [%s]",tostring(TextFileTable[GSL[1]]))
    if GSL[1] ~= 0 then
      local name = string.match(TextFileTable[GSL[1]],[["(.-)"]])
      -- H.printf("WWW name = [%s]",name)
      -- for j=GSL[i] + 1 ,GEL[i] do
        -- H.printf("WWW name in TextFileTable = [%s], [%s]",tostring(string.match(TextFileTable[j],[["(.*)"]])),tostring(string.match(TextFileTable[j],[[/>]])))
        local nextLine = TextFileTable[GSL[1] + 1]
        if name == string.match(nextLine,[["(.-)"]]) and string.match(nextLine,[[/>]])  and string.match(nextLine,name..[[" />]]) == nil then
          -- we assume that all groups are LoV
          IsListOfValues = true
          -- break
        end
      -- end
    end
  -- end
  
  if IsListOfValues then
    -- check SECTION_ACTIVE is in the range of the section
    for i=1,#GSL do
      local activeRange = GEL[i] - GSL[i] - 1 -- from 0 to x
      for j=1,#SectionActive do
        if SectionActive[j] >= 0 and SectionActive[j] < activeRange then
          -- valid value
        else
          return GSL,GEL,SKWL,KWinfo,GSLI,GELI,SKWLI,KWinfoI,false,true
        end
      end

      -- all valid values
      GSLA[#GSLA+1] = GSL[i]
      GELA[#GELA+1] = GEL[i]
      SKWLA[#SKWLA+1] = SKWL[i]
      KWinfoA[#KWinfoA+1] = KWinfo[i]
    end
    
  else
    for i=1,#SectionActive do
      local secActive = SectionActive[i] + 1 -- because _index starts at 0
      if secActive <= #GSL then
        GSLA[#GSLA+1] = GSL[secActive]
        GELA[#GELA+1] = GEL[secActive]
        SKWLA[#SKWLA+1] = SKWL[secActive]
        KWinfoA[#KWinfoA+1] = KWinfo[secActive]
      else
        IsSkipped = true
      end
    end
    
    if IsSkipped and #GSLA == 0 then
      --ALL SECTION_ACTIVE were skipped
      --all groups are active
      return GSL,GEL,SKWL,KWinfo,GSLI,GELI,SKWLI,KWinfoI,false,false
    end
    
    for i=1,#GSL do
      local IsActive = false
      for j=1,#GSLA do
        if GSL[i] == GSLA[j] then
          --an active group
          IsActive = true
          break
        end
      end
      if not IsActive then
        GSLI[#GSLI+1] = GSL[i]
        GELI[#GELI+1] = GEL[i]
        SKWLI[#SKWLI+1] = SKWL[i]
        KWinfoI[#KWinfoI+1] = KWinfo[i]
      end
    end
  end
  
  return GSLA,GELA,SKWLA,KWinfoA,GSLI,GELI,SKWLI,KWinfoI,true,IsListOfValues
end
-- *************************************** END: handles SECTION_ACTIVE ******************************

--***************************************************************************************************
function ReportLPKISresults(SectionStartLine, SectionEndLine, PrecKeyWordLine, tStartLine, tEndLine, tSpecialLine, numRecord)
  -- DOES NOT TOUCH KWinfo
  H.DEBUG_FindGroup_print("")
  if #tStartLine == 0 then
    H.DEBUG_FindGroup_print("  >>> XXXX No section found XXXX")
    --return the whole file
    SectionStartLine[1] = tStartLine[1]
    SectionEndLine[1] = tEndLine[1]
    PrecKeyWordLine[1] = 0
  else
    H.DEBUG_FindGroup_print("  >>> "..#tStartLine.." section(s) found so far")
    H.DEBUG_FindGroup_print("  *** this section FINAL values ***")
    for i=numRecord + 1,#tStartLine do
      H.DEBUG_FindGroup_print("  *** "..tostring(tStartLine[i]).." - "..tostring(tEndLine[i]).." ("..tostring(tSpecialLine[i])..")")
    end
    H.DEBUG_FindGroup_print("")
  end
end
--***************************************************************************************************

--***************************************************************************************************
function HandleLists(H, TextFileTable, TopLine, BottomLine, PrecKeyWordLine)
  if true then
    -- do we remove the top section?
    -- H.printf("In HandleLists: %d",#TopLine)
    -- H.printf("TopLine[%d] = %s",1,tostring(TopLine[1]))
    -- H.printf("TextFileTable[TopLine[%d]] = [%s]",1,tostring(TextFileTable[TopLine[1]]))
    -- H.printf("TextFileTable[TopLine[%d]+1] = [%s]",1,tostring(TextFileTable[TopLine[1]+1]))

    local p,v = H.GetPropertyNameValue(TextFileTable[TopLine[1]])
    local p1,v1 = H.GetPropertyNameValue(TextFileTable[TopLine[1]+1])

    -- H.printf(" p = [%s]",tostring(p))
    -- H.printf("p1 = [%s]",tostring(p1))

    if p and p == p1 then
      -- a LIST: remove top section
      -- H.printf(" ==>> In HandleLists: TopLine[%d] = %s, REMOVING TOP ENTRY of LIST [%s]",1,tostring(TopLine[1]),p)
      
      print("     >>> Removing 1st section found, the Owner of this List")
      H.Report("","     >>> Removing 1st section found, the Owner of this List")
      
      table.remove(TopLine,1)
      table.remove(BottomLine,1)
      table.remove(PrecKeyWordLine,1)
    end
    -- H.printf("In HandleLists after: %d",#TopLine)
  end
end
--************************************* END: HandleLists() *********************************
  
--***************************************************************************************************
-- RECURSIVE
--locate all Sections pointed to by PrecedingKeywords inside given section recursively
-- local function LocatePrecKeywordsInSection(TextFileTable,prec_key_words,index,StartLine,EndLine,level,IsQuit,groupId,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsCreateHOSTRUE,PossibleHOStable) -- recursive
function LocatePrecKeywordsInSection(TextFileTable,prec_key_words,index,StartLine,EndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine,level,IsQuit,groupId,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsAfterKeyWords,IsCreateHOSTRUE) -- recursive
  -- DOES NOT TOUCH KWinfo
  H.DEBUG_FindGroup_print("  +++ Entering LocatePrecKeywordsInSection() RECURSIVE\n")
  if groupId == nil then groupId = "" end
  local currentLevel = level
  local hosFound = false
  -- local hosLevel = level
  
  H.DEBUG_FindGroup_print("")
  H.DEBUG_FindGroup_print("*** IN values for groupSection #"..tostring(groupId))
  H.DEBUG_FindGroup_print("   IsQuit = "..tostring(IsQuit).." ")
  H.DEBUG_FindGroup_print("    level = "..tostring(level).." ")
  H.DEBUG_FindGroup_print("StartLine = "..tostring(StartLine).." ")
  H.DEBUG_FindGroup_print("  EndLine = "..tostring(EndLine).." ")
  H.DEBUG_FindGroup_print("    index = "..tostring(index)..", looking for ["..tostring(prec_key_words[index]).."] ")
  H.DEBUG_FindGroup_print("")
  
  local IsBreakOnOUT = false
  local n = StartLine - 1
  -- for n = StartLine,EndLine do
  while n <= EndLine - 1 do
    n = n + 1
    local line = string.upper(TextFileTable[n])
    H.DEBUG_FindGroup_print("   Looking at: "..n..", ["..line.."]")
    -- print("   Looking at: "..n..", ["..line.."]")
    
    if string.find(line,[[">]],1,true) then -- a HOS
      H.DEBUG_FindGroup_print("A   in: "..line)
      -- causes infinite loop in some cases
      -- if strfind(line,[[">]],1,true) or strfind(line,[[/>]],1,true) then
      
      -- could be a replacement for line above
      -- if strfind(line,[[" ?/?>]]) then
    
      --a StartOfSection line
      --let us find ALL sections at level
      level = level + 1
      -- H.DEBUG_FindGroup_print("level + 1 = "..level.." at "..n.." ["..line.."] ")
      
      H.DEBUG_FindGroup_print("A   level: "..level..", currentLevel: "..currentLevel)
      if level >= currentLevel then
        H.DEBUG_FindGroup_print("   in level >= currentLevel")
        local j = index
        local s = [["]]..prec_key_words[j]..[["]]
        if string.find(line,[[Y NAME=]]..s) or string.find(line,[[Y VALUE=]]..s) then
          H.DEBUG_FindGroup_print(string.rep(" ",80).."level "..tostring(level)..", line "..n..": Found 'existing' HOS: ["..tostring(prec_key_words[j]).."] ")
          --found a line inside this section
          
          if j == #prec_key_words then
            --we found the last prec_key_words in this section
            --this is a GOOD section pointed by these prec_key_words
            --record Section Start/End lines --and level
            H.DEBUG_FindGroup_print(string.rep(" ",100).."line "..n..": Found LAST PK word ")
            hosFound = true
            -- hosLevel = level
            
            local SectionNum = #PrecKeyWordLine + 1
            PrecKeyWordLine[SectionNum] = n
            SectionStartLine[SectionNum] = n
            SectionEndLine[SectionNum]   = H.GoDownToOwnerEnd(TextFileTable,n+1)
            
            H.DEBUG_FindGroup_print(string.rep(" ",120).."*** OUT values: "..tostring(SectionStartLine[SectionNum]).." - "..tostring(SectionEndLine[SectionNum]).." ("..tostring(PrecKeyWordLine[SectionNum])..") ")
            
            if j > 1 then -- and j == #prec_key_words
              --on j == 1 we do NOT break so we can go down the file to the end
              H.DEBUG_FindGroup_print("_BREAK_ on OUT values")
              IsBreakOnOUT = true
              break -- while n <= EndLine - 1 do
            end
            
          else
            --not the last word, continue searching using the next keyword
            j = j + 1
            
            local thisEndLine = EndLine -- as before
            -- printf("%d: prec_key_words[j]=%s  prec_key_words[j-1]=%s",j,prec_key_words[j],prec_key_words[j-1])
            if prec_key_words[j] ~= prec_key_words[j-1] then
              -- Wbertro:  NEW
              -- reset EndLine to End of H.thisSection
              -- print(" ==> Stop at end of section")
              thisEndLine = H.GoDownToOwnerEnd(TextFileTable,n+1) -- EndLine
            end
            -- H.printf(" thisEndLine = %d",thisEndLine)
            
            H.DEBUG_FindGroup_print("      'j' index is now = "..tostring(j).." ")
            H.DEBUG_FindGroup_print("      continuing search recursively...")
            
            IsQuit = LocatePrecKeywordsInSection(TextFileTable, prec_key_words, j, n + 1, thisEndLine, SectionStartLine, SectionEndLine, PrecKeyWordLine, level, IsQuit, groupId, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsAfterKeyWords, IsCreateHOSTRUE) -- recursive
            -- IsQuit = LocatePrecKeywordsInSection(TextFileTable, prec_key_words, j, SectionEndLine[SectionNum] + 1, thisEndLine, level, IsQuit, groupId, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsCreateHOSTRUE) -- recursive
            
            H.DEBUG_FindGroup_print("  --- STILL in LocatePrecKeywordsInSection() RECURSIVE\n")
            
            -- Wbertro: Shouldn't that be:
            index = j
            -- and:
            if SectionEndLine[#SectionEndLine] then
              n = SectionEndLine[#SectionEndLine]
            else
              index = 1 -- reset to first keyword
              -- continue down the section
            end
            
            -- index = 1 -- reset to first keyword
            H.DEBUG_FindGroup_print("      reset to keyword #"..index.." (still not out of mother function)")
            
            H.DEBUG_FindGroup_print("   IsQuit = "..tostring(IsQuit).." ")
            H.DEBUG_FindGroup_print("    level = "..tostring(level).." ")
            -- H.DEBUG_FindGroup_print("StartLine = "..tostring(StartLine).." ")
            -- H.DEBUG_FindGroup_print("  EndLine = "..tostring(EndLine).." ")
            H.DEBUG_FindGroup_print("    index = "..tostring(index)..", looking for ["..tostring(prec_key_words[index]).."] ")
            H.DEBUG_FindGroup_print("")

            if n == nil or level == 0 or IsQuit then
              --we are done, end of file
              H.DEBUG_FindGroup_print("_BREAK_ on level == 0 or IsQuit")
              break -- while n <= EndLine - 1 do
            end
          end
        end
      end --if level >= currentLevel then
      
    elseif string.find(line,[[Y>]]) then
      --this is a </Property> line
      H.DEBUG_FindGroup_print("B   in: "..line)
      level = level - 1
      -- H.DEBUG_FindGroup_print("level - 1 = "..level.." | currentLevel = "..currentLevel.." at "..n.." ")
      
      if level < currentLevel and index == 1 then
        H.DEBUG_FindGroup_print("_BREAK_ on level < currentLevel and index == 1 at "..n.." ") --used
        break -- for n = StartLine,EndLine do
      end
      
      if n == EndLine then        
        if level < currentLevel then
          --level is smaller, let us quit this section and continue the search with index=1
          -- could there be other sub-sections meeting the prec_key_words?
          index = 1 -- reset to first keyword
          H.DEBUG_FindGroup_print("      could not find next word, reset to 1st keyword...")
          currentLevel = level
        end
        
        if level <= 0 then
          --we are done, end of file
          IsQuit = true
          H.DEBUG_FindGroup_print("_BREAK_ on level <= 0 and "..tostring(n).." == "..tostring(EndLine).." ")
          break
        end
      end
      
    elseif not hosFound and IsCreateHOSTRUE and index == #prec_key_words and string.find(line,[[/>]]) then -- WBERTRO
    -- elseif not hosFound and IsCreateHOSTRUE and not IsAfterKeyWords and index == #prec_key_words and string.find(line,[[/>]]) then
    -- elseif IsCreateHOSTRUE and index == #prec_key_words and (not hosFound or (hosFound and level + 1 < hosLevel)) and strfind(line,[[/>]]) then
      -- line is a possible HOES
      H.DEBUG_FindGroup_print("C   in possible HOES: ["..line.."]")
      if not IsPrecedingFirstTRUE or (IsPrecedingFirstTRUE and not IsSpecialKeyWords) then
        local s = [["]]..prec_key_words[index]..[["]]
        if string.find(line,[[Y NAME=]]..s) or string.find(line,[[Y VALUE=]]..s) then
          H.DEBUG_FindGroup_print("                                                >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  line "..n.." creating a HOS: ["..line.."]")
          -- line matches prec_key_words[#prec_key_words]
          --print("                  >>> HOES found at line "..n)
          level = level + 1
          
          -- PossibleHOStable[#PossibleHOStable + 1 ] = n
          
          -- make HOES into a HOS (HeadOfSection)
          TextFileTable[n] = TextFileTable[n]:gsub([[ />]],[[>]])
          
          -- insert an end of section line, preserve spacing
          -- USE table.insert here because it performs the shifting
          table.insert(TextFileTable, n+1, string.match(line,[[(%s*)<]])..[[</Property>]])
          
          local SectionNum = #PrecKeyWordLine + 1
          PrecKeyWordLine[SectionNum] = n
          SectionStartLine[SectionNum] = n
          SectionEndLine[SectionNum]   = n + 1
          
          IsHOSCreated = true
          
          -- -- IF USED WILL CAUSE BAD EXML IN SOMW CASES, good for testing MBINCompiler with NPC Outfit Variety.lua
          -- hosFound = true
        end
      end        
    end -- if strfind(line,[[">]]) then
  end -- while n <= EndLine - 1 do
  
  if IsBreakOnOUT then
    H.DEBUG_FindGroup_print("  --- IsBreakOnOUT")
  end
  
  H.DEBUG_FindGroup_print("  --- Leaving LocatePrecKeywordsInSection() RECURSIVE\n")
  -- H.printf("END:  LocatePrecKeywordsInSection.IsHOSCreated = %s",tostring(IsHOSCreated))
  -- return IsQuit,SectionStartLine,SectionEndLine,PrecKeyWordLine,PossibleHOStable -- IsHOSCreated
  return IsQuit,SectionStartLine,SectionEndLine,PrecKeyWordLine,IsHOSCreated
end

--********************************* PrecKeywordsSections() *******************************************
--locate all Sections pointed to by ALL PREC_KEY_WORDS inside these groups
-- local function PrecKeywordsSections(TextFileTable,prec_key_words,GroupStartLine,GroupEndLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsCreateHOSTRUE,KWinfo,IsFirst,PossibleHOStable)
function PrecKeywordsSections(TextFileTable,prec_key_words,GroupStartLine,GroupEndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsAfterKeyWords,IsCreateHOSTRUE,KWinfo,IsFirst)
  -- TOUCH KWinfo
  H.DEBUG_FindGroup_print("  Entering PrecKeywordsSections()\n")

  local tempStartLine = {}
  local tempEndLine = {}
  local tempSpecialLine = {}
  -- local PossibleHOStable = {}
  
  local OutputKWinfo = {}
  
  -- if H.IsKWpattern then
    if not IsFirst then
      -- printf("PKW1: #KWinfo = %d",#KWinfo)
      for i=#KWinfo,1,-1 do
        if KWinfo[i] == "" then
          KWinfo[i] = "NIL"
        end
      end
      
      KWinfo = H.refreshTable(KWinfo)
      if KWinfo[1] == nil then
        -- nothing was previously found, just return
        -- return tempStartLine,tempEndLine,tempSpecialLine,PossibleHOStable,KWinfo
        return tempStartLine,tempEndLine,tempSpecialLine,IsHOSCreated,KWinfo
      end
    end
    
    -- printf("PKW2: #KWinfo = %d",#KWinfo)
    -- for i=1,#KWinfo do
      -- printf("  PK-GROUPS: %d: [%s]",i,KWinfo[i])
    -- end
    -- printf("PK-GROUPS: #GroupStartLine = %d",#GroupStartLine)
  -- end
  
  H.DEBUG_FindGroup_print("  #PK-GROUPS = "..#GroupStartLine)
  local m = 1
  for i=1,#GroupStartLine do
    if KWinfo[i] ~= "" then -- maybe nil or ~= ""
      --try to find the sections pointed to by the PREC_KEY_WORDS in this GroupSection
      local index = 1 --we start with the first PREC_KEY_WORDS
      local level = 0 --we say this GroupSection is at level 0
      
      local numRecord = #tempStartLine
      
      if GroupStartLine[i] == 1 then
        -- for SEC_EDIT sections
        GroupStartLine[i] = 0
      end
      
      local _,tStartLine,tEndLine,tSpecialLine,IsHOSCreated =
      -- local _,tStartLine,tEndLine,tSpecialLine,PossibleHOStable =
            -- LocatePrecKeywordsInSection(TextFileTable, prec_key_words, index, GroupStartLine[i]+1, GroupEndLine[i], level, false, i, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsCreateHOSTRUE, PossibleHOStable)
            LocatePrecKeywordsInSection(TextFileTable, prec_key_words, index, GroupStartLine[i]+1, GroupEndLine[i], SectionStartLine, SectionEndLine, PrecKeyWordLine, level, false, i, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsAfterKeyWords, IsCreateHOSTRUE)
            
      ReportLPKISresults(SectionStartLine, SectionEndLine, PrecKeyWordLine, tStartLine, tEndLine, tSpecialLine, numRecord)
      H.DEBUG_FindGroup_print(" LPKIS-RESULTS #= "..#tStartLine.." for PK-group #"..i)
      
      for line=numRecord + 1,#tStartLine do
        tempStartLine[#tempStartLine+1] = tStartLine[line]
        tempEndLine[#tempEndLine+1] = tEndLine[line]
        tempSpecialLine[#tempSpecialLine+1] = tSpecialLine[line]

        -- if H.IsKWpattern then
          if tSpecialLine[line] == 0 then
            -- no section was found for that SKW section
            KWinfo[i] = ""
          elseif IsFirst then
            -- PKW is first to process
            OutputKWinfo[#OutputKWinfo+1] = TextFileTable[tSpecialLine[line]]..":"
          else
            if KWinfo[i] then
              OutputKWinfo[m] = KWinfo[i]..TextFileTable[tSpecialLine[line]]..":"
            else
              OutputKWinfo[m] = TextFileTable[tSpecialLine[line]]..":"
            end
            m = m + 1
          end
        -- end
        
      end
    else
      printf("==== KWinfo[%d] = [%s]",i,tostring(KWinfo[i]))
    end
  end
  
  H.DEBUG_FindGroup_print("")
  H.DEBUG_FindGroup_print("  All PK-GROUPS RESULTS #= "..#tempStartLine)
  for i=1,#tempStartLine do
    H.DEBUG_FindGroup_print("  >>> "..tostring(tempStartLine[i]).." - "..tostring(tempEndLine[i]).." ("..tostring(tempSpecialLine[i])..")")
  end
  
  if #tempStartLine == 0 then
    H.DEBUG_FindGroup_print("  >>> No sections found")
  end
  H.DEBUG_FindGroup_print("  END RESULTS for PrecKeywordsSections()\n")
  H.DEBUG_FindGroup_print("")
  
  -- H.printf("END:  PrecKeywordsSections.IsHOSCreated = %s",tostring(IsHOSCreated))
  -- return tempStartLine,tempEndLine,tempSpecialLine,PossibleHOStable,OutputKWinfo
  return tempStartLine,tempEndLine,tempSpecialLine,IsHOSCreated,OutputKWinfo
end
--********************************* END: PrecKeywordsSections() *******************************************

--********************************* ShowSection(() for DEBUG *******************************************
function ShowDebugSections(GroupStartLine,GroupEndLine,KeyWordLine,ComesFrom)
  for i=1,#GroupStartLine do
    print(ComesFrom..": === "..tostring(GroupStartLine[i]).."-"..tostring(GroupEndLine[i]).." ("..tostring(KeyWordLine[i])..")")
  end
end
--********************************* END: ShowSection(() for DEBUG *******************************************

--#############################################################################################
--**************************************** FindGroup() ***********************************
function FindGroup(H, TextFileTable, WholeTextFileTable, prec_key_words, IsPrecedingFirstTRUE
                  ,IsSpecialKeyWords, spec_key_words, section_up_special, section_up_preceding
                  ,IsAfterKeyWords, IsEditSection, IsReplaceONCE, IsCreateHOSTRUE, IsHOSCreated, KWinfo)
  
  -- NOTE: if IsAfterKeyWords == false: IsCreateHOSTRUE is processed
  --          IsAfterKeyWords ==  true: IsCreateHOSTRUE is NOT processed
  
  local tFindGroup = os.clock()
  local tt = tFindGroup
  
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strrep = string.rep
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  local My = {}
  
  My.DEBUG_CheckUniqueness = H.gDEBUG_CheckUniqueness
  -- My.H.DEBUG_FindGroup_print = H.DEBUG_FindGroup_print
  -- My.H.DEBUG_FindGroup_timing_print = H.DEBUG_FindGroup_timing_print
  
  local SectionStartLine = {}
  local SectionEndLine = {}
  local PrecKeyWordLine = {}
  
  --***************************************************************************************************
  local function IsPrec_key_wordsExist(prec_key_words)
    -- DOES NOT TOUCH KWinfo
    local SearchPrec = false
    for i=1,#prec_key_words do
      if prec_key_words[i] and prec_key_words[i] ~= "" then
        SearchPrec = true
        break
      end
    end
    return SearchPrec
  end
  
  --***************************************************************************************************
  local function FindKeywordsInLine(H,text)
    -- DOES NOT TOUCH KWinfo
    local KeywordsInLineTable = {}
    
    local p,v = H.GetPropertyNameValue(s)
    if p and v then
      KeywordsInLineTable[#KeywordsInLineTable+1] = {}
      KeywordsInLineTable[#KeywordsInLineTable][1] = strupper(p)
      KeywordsInLineTable[#KeywordsInLineTable][2] = strupper(v)
    end

    return KeywordsInLineTable
  end
  --*********************************** END: FindKeywordsInLine() *************************************
  
  --***************************************************************************************************
  --locate all Sections pointed to by SpecialKeywords at index, index+1
  local function LocateSpecialKeywordsSections(TextFileTable,index,spec_key_words,StartLine,EndLine,kwLine)
    -- DOES NOT TOUCH KWinfo
    local SectionNum = 0
    local SectionStartLine = {}
    local SectionEndLine = {}
    local SpecialKeyWordLine = {}
    
    H.DEBUG_FindGroup_print("\n                LSKS: index = "..tostring(index)..", ["..tostring(spec_key_words[index]).."],["..tostring(spec_key_words[index+1]).."] using ("..tostring(StartLine).."-"..tostring(EndLine)..") ("..tostring(kwLine)..")")
    
    --prepare line to search
    local bothIGNORE = false
    local searchThis = ""
    if spec_key_words[index] ~= "IGNORE" and spec_key_words[index+1] ~= "IGNORE" then
      searchThis = [[E="]]..spec_key_words[index]..[[" VALUE="]]..spec_key_words[index+1]..[["]]
    elseif spec_key_words[index] == "IGNORE" and spec_key_words[index+1] ~= "IGNORE" then
      searchThis = [[" VALUE="]]..spec_key_words[index+1]..[["]]
    elseif spec_key_words[index] ~= "IGNORE" and spec_key_words[index+1] == "IGNORE" then
      searchThis = [[E="]]..spec_key_words[index]..[[" VALUE="]]
    else
      --both are IGNORE, skip
      bothIGNORE = true
    end
    
    if not bothIGNORE then
      H.DEBUG_FindGroup_print("  LSKS: *** searching ["..searchThis.."]")
      for n = StartLine,EndLine do
        local line = strupper(TextFileTable[n])
        -- H.DEBUG_FindGroup_print("LSKS: *** line = ["..line.."]")
        
        if n ~= kwLine and strfind(line,searchThis) then -- do not record the same line twice
          H.DEBUG_FindGroup_print("  LSKS: *** FOUND at "..n)
          
        -- local KeywordsInLineTable = FindKeywordsInLine(H,line)
        -- if #KeywordsInLineTable > 0 then
          -- -- H.DEBUG_FindGroup_print("  ["..KeywordsInLineTable[1][1].."]  ["..KeywordsInLineTable[1][2].."]")
          -- if (spec_key_words[index] == KeywordsInLineTable[1][1] or spec_key_words[index] == "IGNORE")
                -- and (spec_key_words[index+1] == KeywordsInLineTable[1][2] or spec_key_words[index+1] == "IGNORE") then
                
                
            -- print("found SKW at "..n)
            --found a requested SpecialKeywords line,
            --record Section Start/End lines --and level
            SectionNum = SectionNum + 1
            SpecialKeyWordLine[SectionNum] = n

            if strfind(line,[[">]],1,true) then
              --this is the start of a section
              SectionStartLine[SectionNum] = n
              --let us find the end of this section, not its parent
              SectionEndLine[SectionNum]   = H.GoDownToOwnerEnd(TextFileTable,n+1)
            else
              --let us find the start and end of the parent section
              SectionStartLine[SectionNum] = H.GoUPToOwnerStart(TextFileTable,n)
              SectionEndLine[SectionNum]   = H.GoDownToOwnerEnd(TextFileTable,n)
            end
          -- end
        end
      end
    end
    
    if SectionNum == 0 then
      H.DEBUG_FindGroup_print("  LSKS: XXXX No sub-section found with pair XXXX")
      --no Section found for requested pair
      --return the passed section
      SectionStartLine[1] = StartLine
      SectionEndLine[1] = EndLine
      SpecialKeyWordLine[1] = 0
    else
      H.DEBUG_FindGroup_print("  LSKS:   >>> "..SectionNum.." section(s) found")
    end
    
    for i=1,#SectionStartLine do
      H.DEBUG_FindGroup_print("  LSKS:    "..SectionStartLine[i].." - "..SectionEndLine[i].." ("..SpecialKeyWordLine[i]..")")
    end
    
    return SectionStartLine,SectionEndLine,SpecialKeyWordLine
  end
  
  --***************************************************************************************************
  --locate all Sections pointed to by ALL SPECIAL_KEY_WORDS after the 1st pair
  local function SpecialKeywordsSections(TextFileTable,spec_key_words,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
    -- TOUCH KWinfo
    local SK_GROUPS = #spec_key_words // 2
    H.DEBUG_FindGroup_print("\n              SK:       processing SK_GROUPS = "..SK_GROUPS)
    
    -- if H.IsKWpattern then
      -- printf("#KWinfo = %d",#KWinfo)
      -- for i=1,#KWinfo do
        -- printf("SK: %d: [%s]",i,KWinfo[i])
      -- end
      -- printf("SK: #GroupStartLine = %d",#GroupStartLine)
    -- end
    
-- printf("SpecialKeywordsSections: #KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
    -- for each pair of SPECIAL_KEY_WORDS (1st pair already found by FastCheckUniqueness)
    -- start at 2nd pair
    for j=3,#spec_key_words,2 do
      H.DEBUG_FindGroup_print("SK: processing pair #"..((j+1)//2))
      local savedKWinfo = H.cloneArray(KWinfo)
    
      local tempStartLine = {}
      local tempEndLine = {}
      local tempSpecialLine = {}
      local tempKWinfo = {}
      
      -- for i=1,#GroupStartLine do
      local m = 0
      for i=1,#savedKWinfo do
        if savedKWinfo[i] ~= "" then
          --  OK to continue searching for section
          m = m + 1
          -- printf("     savedKWinfo[%d] = %s on pair = %d",i,savedKWinfo[i],(j+1)//2)
          local StartLine,EndLine,SpecialLine = LocateSpecialKeywordsSections(TextFileTable,j,spec_key_words,GroupStartLine[m],GroupEndLine[m],SpecialKeyWordLine[m])
          
          H.DEBUG_FindGroup_print("SK:  LSKS-RESULTS #= "..#StartLine.." for SK_group "..(j+1)//2)
          
          H.DEBUG_FindGroup_print("SK: >>> Found pair "..(j+1)//2)
          for line=1,#StartLine do
            H.DEBUG_FindGroup_print("SK: >>> Keep section "..StartLine[line].."-"..EndLine[line].." ("..SpecialLine[line]..")")
            tempStartLine[#tempStartLine+1] = StartLine[line]
            tempEndLine[#tempEndLine+1] = EndLine[line]
            tempSpecialLine[#tempSpecialLine+1] = SpecialLine[line]
            
            -- if H.IsKWpattern then
              if SpecialLine[line] == 0 then
                -- remove this savedKWinfo reference to section
                -- printf([[     - info: savedKWinfo[%d] = "" on pair = %d]],i,(j+1)//2)
                savedKWinfo[i] = ""
              else
                if KWinfo[i] then
                  tempKWinfo[i] = savedKWinfo[i]..TextFileTable[SpecialLine[line]]..":"
                else
                  tempKWinfo[i] = TextFileTable[SpecialLine[line]]..":"
                end
                -- printf("     + info: KWinfo[%d] = %s on pair = %d",i,KWinfo[i],(j+1)//2)
              end
            -- end
            
          end
        else
          -- printf([[      ==> skip KWinfo[%d] == "" on pair = %d]],i,(j+1)//2)
        end
      end -- for i=1,#GroupStartLine do

      GroupStartLine = {}
      GroupEndLine = {}
      SpecialKeyWordLine = {}
      KWinfo = {}
      
      H.DEBUG_FindGroup_print("\n               SK: B-RESULTS #= "..#tempStartLine)
      for line=1,#tempStartLine do
        H.DEBUG_FindGroup_print("SK: tempSpecialLine["..line.."] = "..tempSpecialLine[line])
        if tempSpecialLine[line] > 0 then
          -- H.DEBUG_FindGroup_print(">>> Keep section")
          GroupStartLine[#GroupStartLine+1] = tempStartLine[line]
          GroupEndLine[#GroupEndLine+1] = tempEndLine[line]
          SpecialKeyWordLine[#SpecialKeyWordLine+1] = tempSpecialLine[line]
          if tempKWinfo[line] then
            KWinfo[#KWinfo+1] = tempKWinfo[line]
          else
            -- use last one
            if #KWinfo > 0 then
              KWinfo[#KWinfo+1] = KWinfo[#KWinfo]
            else
              KWinfo[#KWinfo+1] = ""
            end
          end
-- printf("SpecialKeywordsSections: SK: B-RESULTS tempStartLine[%d] = %d, tempKWinfo[%d] = %s",line,tempStartLine[line],line,tempKWinfo[line])
        end
      end
-- printf("SpecialKeywordsSections: SK: B-RESULTS #KWinfo = %d, #GroupStartLine = %d",#KWinfo,#GroupStartLine)

    end -- for j=3,#spec_key_words,2 do
    
    H.DEBUG_FindGroup_print("SK: All SK_GROUPS RESULTS #= "..#GroupStartLine)
    for i=1,#GroupStartLine do
      H.DEBUG_FindGroup_print("   "..tostring(GroupStartLine[i]).." - "..tostring(GroupEndLine[i]).." ("..tostring(SpecialKeyWordLine[i])..")")
    end
    
    if #GroupStartLine == 0 then
      H.DEBUG_FindGroup_print("SK: >>> No sections found in SpecialKeywordsSections()")
      GroupStartLine = {3}
      GroupEndLine = {#TextFileTable}
      SpecialKeyWordLine = {0}
      KWinfo = {""}
    end
    H.DEBUG_FindGroup_print("SK: END RESULTS for SpecialKeywordsSections()")
    H.DEBUG_FindGroup_print("")
    
    return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
  end
  
  --**************************************** CreateSectionsFromFastCheckUniqueness() ***********************************
  local function CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,PKWstartline,searchFor,KWinfo,IsFirst,currentSectionNumber)
    -- TOUCH KWinfo
    local newGSL = {}
    local newGEL = {}
    local newSKL = {}
    if IsFirst then
      KWinfo = {}
    end
    
    if PKWstartline == nil then PKWstartline = 0 end
    -- if My.DEBUG_CheckUniqueness then H.pv("--- searchFor = ["..searchFor.."]") end
    
    for p = 1,#linesNumFound do
      local thisLine = PKWstartline + linesNumFound[p]
      if My.DEBUG_CheckUniqueness then H.pv("--- CreateSectionsFromFastCheckUniqueness found line: "..(thisLine)) end
      if My.DEBUG_CheckUniqueness then H.pv("--- CreateSectionsFromFastCheckUniqueness line = ["..TextFileTable[thisLine].."]") end
      
      if strfind(strupper(TextFileTable[thisLine]),searchFor) then -- because FastCheckUniqueness() sometimes returns extra lines (a lua BUG ??)
        if strfind(TextFileTable[thisLine],[[">]],1,true) then
          -- this is the top of a section
          newGSL[#newGSL+1] = thisLine
          newGEL[#newGEL+1] = H.GoDownToOwnerEnd(TextFileTable,thisLine + 1) -- to stay inside this section
        else
          -- this is inside a section
          newGSL[#newGSL+1] = H.GoUPToOwnerStart(TextFileTable,thisLine)
          newGEL[#newGEL+1] = H.GoDownToOwnerEnd(TextFileTable,thisLine)
        end
        newSKL[#newSKL+1] = thisLine

        if thisLine == 0 then
          -- no section was found for that SKW section
          KWinfo[currentSectionNumber] = ""
        elseif IsFirst then
          -- SKW is first to process
          KWinfo[#KWinfo+1] = TextFileTable[thisLine]..":"
        elseif KWinfo[currentSectionNumber] then
          KWinfo[currentSectionNumber] = KWinfo[currentSectionNumber]..TextFileTable[thisLine]..":"
        end
      -- else
        -- if My.DEBUG_CheckUniqueness then H.pv("--- ==> Skipping this line: "..(thisLine)) end
      end
    end

    return newGSL,newGEL,newSKL,KWinfo
  end
  --************************************* END: CreateSectionsFromFastCheckUniqueness() *********************************
  
  --***************************************************************************************************
  local function FastCheckUniqueness(WholeTextFile,spec_key_words) -- ,IsWholeFile
    -- DOES NOT TOUCH KWinfo
    -- if My.DEBUG_CheckUniqueness then print("In FastCheckUniqueness: #SKW = "..#spec_key_words) end
    -- if My.DEBUG_CheckUniqueness then print("  #WholeTextFile = "..#WholeTextFile) end
    local linesNumFound = {}
    local uniqueState = 0 -- not found
    local lineNumber = nil
    
    -- this is HINTS proof
    
    -- if My.DEBUG_CheckUniqueness then print(strsub(WholeTextFile,1,500)) end
    
-- print(GetSpecKeyWordsInfo(H,spec_key_words))

    local p = ""
    if spec_key_words[1] ~= "IGNORE" then
      p = [[<PROPERTY NAME="]]..spec_key_words[1]
    end
    local v = ""
    if spec_key_words[2] ~= "IGNORE" then
      v = [[" VALUE="]]..spec_key_words[2]
    end

    -- local s = H.makeRegExUppercase(p..v)..[["]] -- strupper(p..v)..[["]] --the end could be [[ />]] or [[>]]
    local s = p..v..[["]] --the end could be [[ />]] or [[>]]
    -- if My.DEBUG_CheckUniqueness then print("  Check for ["..s.."]") end
    
    -- if IsWholeFile then
      -- -- maybe we can use an alternate method?
    -- end
    
    --fastest way!!! --gsub and gmatch take too long
    local firstPosStart,firstPosEnd = strfind(WholeTextFile,s)
-- if firstPosStart ~= nil and firstPosEnd ~= nil then
  -- printf("firstPosEnd = %d, #WholeTextFile = %d, [%s]",firstPosEnd,#WholeTextFile,strsub(WholeTextFile,firstPosStart,firstPosEnd))
-- else
  -- printf("firstPosStart = %s, firstPosEnd = %s: [%s]",tostring(firstPosStart),tostring(firstPosEnd),s)
-- end
    
    if firstPosEnd then
      -- if My.DEBUG_CheckUniqueness then print("  firstPosEnd = "..firstPosEnd) end
      local _,lineNumber = WholeTextFile:sub(1,firstPosEnd):gsub('>','>',-1)
      linesNumFound[#linesNumFound + 1] = lineNumber + 1
      -- if My.DEBUG_CheckUniqueness then print("  A: lineNumber = "..linesNumFound[#linesNumFound]) end
      
      local secondPos,nextPos = strfind(WholeTextFile,s,firstPosEnd + 1)
      -- if My.DEBUG_CheckUniqueness then print("  nextPos = "..tostring(nextPos)) end
      
      if secondPos == nil then
        uniqueState = 1
        -- if My.DEBUG_CheckUniqueness then print("  FastCheckUniqueness: Unique") end
      else
        uniqueState = 2
        
        local PreviouslineNumber = lineNumber
        local PreviousPosEnd = firstPosEnd + 1
        
        -- if My.DEBUG_CheckUniqueness then print("  FastCheckUniqueness: More than one") end
        _,lineNumber = WholeTextFile:sub(PreviousPosEnd,nextPos):gsub('>','>',-1)
        linesNumFound[#linesNumFound + 1] = PreviouslineNumber + lineNumber + 1
        -- if My.DEBUG_CheckUniqueness then print("  B: lineNumber = "..linesNumFound[#linesNumFound]) end
        
-- tU = os.clock()
-- H.DEBUG_FindGroup_timing_print("        > ".." uniqueState_2 START at "..H.dClock())

        while nextPos do
          nextPos,endPos = strfind(WholeTextFile,s,nextPos + 1)
          if nextPos then
            _,lineNumber = WholeTextFile:sub(PreviousPosEnd,endPos):gsub('>','>',-1)
            linesNumFound[#linesNumFound + 1] = PreviouslineNumber + lineNumber + 1
            -- if My.DEBUG_CheckUniqueness then print("  C: lineNumber = "..linesNumFound[#linesNumFound]) end
            
            nextPos = endPos + 1
            PreviousPosEnd = nextPos
            PreviouslineNumber = PreviouslineNumber + lineNumber
          end
        end
        
-- tU = os.clock() - tU
-- H.DEBUG_FindGroup_timing_print("        > ".." uniqueState_2 ENDING in "..H.dClock(tU))
      end
    -- else
      -- if My.DEBUG_CheckUniqueness then print("  FastCheckUniqueness: NOT found") end
    end
    -- if My.DEBUG_CheckUniqueness then printf("  count = %d, lineFound = %s, [%s]",uniqueState,tostring(linesNumFound[1]),s) end
    return uniqueState,linesNumFound,s
  end
  --************************************* END: FastCheckUniqueness() *********************************

  --###################################################################################################
  --###################  Start of main FindGroup() code  ##############################################
  --###################################################################################################
  H.gVerbose = true
  
  if H.gDEBUG_GROUPS then
    print("    >>> Starting FindGroup()\n")
    print("    === IsReplaceONCE        = "..tostring(IsReplaceONCE))
    print("    === IsCreateHOSTRUE      = "..tostring(IsCreateHOSTRUE))
    print("    === IsHOSCreated         = "..tostring(IsHOSCreated))
    print("    === IsEditSection        = "..tostring(IsEditSection))
    print("    === IsPrecedingFirstTRUE = "..tostring(IsPrecedingFirstTRUE))
    print("    === IsSpecialKeyWords    = "..tostring(IsSpecialKeyWords))
    print("    === section_up_special   = "..tostring(section_up_special))
    print("    === section_up_preceding = "..tostring(section_up_preceding))
    print("    === IsAfterKeyWords      = "..tostring(IsAfterKeyWords))
    print("    === #KWinfo              = "..tostring(#KWinfo))
    print("    === #TextFileTable       = "..tostring(#TextFileTable))
  end
  
  -- make them always UPPERCASE for FastCheckUniqueness and search
  local UPPERspec_key_words = H.ReturnUpperCaseKwTable(spec_key_words)
  -- H.DEBUG_FindGroup_print("UPPERspec_key_words[1] = "..tostring(UPPERspec_key_words[1]))
  -- H.DEBUG_FindGroup_print("UPPERspec_key_words[2] = "..tostring(UPPERspec_key_words[2]))
  local UPPERprec_key_words = H.ReturnUpperCaseKwTable(prec_key_words)
  local KeepOuterSections = true --we will see if this needs to be an option in the future
  
  -- local NumFoundGroups = 0
  
  local GroupStartLine = {3}
  
  if IsEditSection then
    GroupStartLine = {1}
  end
  
  local GroupEndLine = {#TextFileTable}
  local SpecialKeyWordLine = {0}
  local SectionsTable = {}
  
  local All_Words_Found = false
  local All_SpecialWords_Found = false
  local All_PrecedingWords_Found = false
  
  local IsOnlyOnePreceding = false
  
  if #TextFileTable == 0 or WholeTextFileTable == "" then
    -- big problem
    -- return All_Words_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, KWinfo, PossibleHOStable
    return All_Words_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, IsHOSCreated, KWinfo
  end
  
  local IsPrec_key_words = IsPrec_key_wordsExist(prec_key_words)
  
  -- H.DEBUG_FindGroup_print("IsPrecedingFirstTRUE = "..tostring(IsPrecedingFirstTRUE))
  -- H.DEBUG_FindGroup_print("IsSpecialKeyWords = "..tostring(IsSpecialKeyWords))
  -- H.DEBUG_FindGroup_print("IsPrec_key_words = "..tostring(IsPrec_key_words))
  
  if not IsSpecialKeyWords then
    --let us do as if IsPrecedingFirstTRUE was true
    IsPrecedingFirstTRUE = true
    -- H.DEBUG_FindGroup_print("   >>> no SpecialKeywords so: IsPrecedingFirstTRUE is now = "..tostring(IsPrecedingFirstTRUE))
  end
  
  if not IsPrecedingFirstTRUE then
    --*******************  process SpecialKeyWords FIRST if any  *********************************
-- print("==> "..GetSpecKeyWordsInfo(H,UPPERspec_key_words))
-- print("==> "..GetPrecKeyWordsInfo(UPPERprec_key_words))  
    if IsSpecialKeyWords then
      local Info = GetSpecKeyWordsInfo(H,spec_key_words)
      H.DEBUG_FindGroup_print("\n"..[[  SK     >>> Trying to locate Group Start/End lines based on SPECIAL_KEY_WORDS ]]..Info.."\n")
      
      local count,linesNumFound,searchFor = FastCheckUniqueness(WholeTextFileTable[1], UPPERspec_key_words)
      -- printf("+++++ FastCheckUniqueness: %d %d %s",count,#linesNumFound,searchFor)
      -- for Z=1,#linesNumFound do
        -- printf("FastCheckUniqueness: - [%s]",linesNumFound[Z])
      -- end
      
      if count == 1 then
        --count == 1 >>> unique, good (SCRIPTBUILDER guaranties uniqueness, user do not)
        --    record range info
        H.DEBUG_FindGroup_print("\n  SK     >>> count == 1, Looking for SPECIAL_KEY_WORDS between lines "..GroupStartLine[1].." and "..GroupEndLine[1].."\n")
        
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H, linesNumFound, TextFileTable, 0, searchFor, KWinfo, true, 0)
        -- printf("+++++ %d %d %d %d",#GroupStartLine,#GroupEndLine,#SpecialKeyWordLine,#KWinfo)
        
        -- assert(#linesNumFound == #GroupStartLine,"SK FindGroup() #linesNumFound ~= #GroupStartLine")
        -- assert(#KWinfo == #GroupStartLine,"SK FindGroup() #KWinfo ~= #GroupStartLine")
        -- for Z=1,#KWinfo do
          -- printf("C1: - [%s]",KWinfo[Z])
        -- end
        
        if #UPPERspec_key_words > 2 then
          -- UNIQUE: we pass the FOUND section already pointed to by the 1st pair of SKW
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = SpecialKeywordsSections(TextFileTable, UPPERspec_key_words, GroupStartLine, GroupEndLine, SpecialKeyWordLine, KWinfo)
          -- printf("+++++ %d %d %d %d",#GroupStartLine,#GroupEndLine,#SpecialKeyWordLine,#KWinfo)
-- printf("SK1 #KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
          -- assert(#KWinfo == #GroupStartLine,"SK1 FindGroup() #KWinfo ~= #GroupStartLine")
        end
        
        -- for Z=1,#KWinfo do
          -- printf("C2: - [%s]",KWinfo[Z])
        -- end
        
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SK1",SectionsTable)
        
        --**************************************** handle SECTION_UP_SPECIAL ***********************************
        if section_up_special > 0 then
          H.DEBUG_FindGroup_print("   Found SECTION_UP_SPECIAL = "..section_up_special)
          GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up_special)
          SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UPS",SectionsTable)
          -- assert(#KWinfo == #GroupStartLine,"SK UPS FindGroup() #KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: handle SECTION_UP_SPECIAL ***********************************
        
        -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine))
        -- H.DEBUG_FindGroup_print(#SpecialKeyWordLine)
        -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine[1]))
        if SpecialKeyWordLine[1] and SpecialKeyWordLine[1] > 0 then
          -- NumFoundGroups = NumFoundGroups + 1
          -- All_Words_Found = true
          All_SpecialWords_Found = true
          H.DEBUG_FindGroup_print("\n  SK     count = 1, Found SPECIAL_KEY_WORDS between lines "..GroupStartLine[1].." and "..GroupEndLine[1].."\n")
        end
        
        H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." UNIQUE SKW in "..H.dClock(os.clock() - tFindGroup))
        tFindGroup = os.clock()
        
        if All_SpecialWords_Found then
          if IsPrec_key_words then
            H.DEBUG_FindGroup_print("\n  SKPK     >>> count = 1, Now looking for PREC_KEY_WORDS\n")
            --lets try with all the PREC_KEY_WORDS
            --here: only 1 section to search
            
            TopLine,BottomLine,PrecKeyWordLine,IsHOSCreated,KWinfo = PrecKeywordsSections(TextFileTable,UPPERprec_key_words,GroupStartLine,GroupEndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsAfterKeyWords,IsCreateHOSTRUE,KWinfo,false)
            -- TopLine,BottomLine,PrecKeyWordLine,PossibleHOStable,KWinfo = PrecKeywordsSections(TextFileTable,UPPERprec_key_words,GroupStartLine,GroupEndLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsCreateHOSTRUE,KWinfo,false,PossibleHOStable)
            -- H.printf("A:  AFTER PrecKeywordsSections().IsHOSCreated = %s",tostring(IsHOSCreated))
            All_PrecedingWords_Found = (#TopLine > 0)
            
            -- assert(#KWinfo == #TopLine,"SK FindGroup() #KWinfo ~= #TopLine")
            
            --All_PrecedingWords_Found,TopLine,BottomLine = LocatePrecKeywordsWithTreeMap(FILE_LINE,TREE_LEVEL,KEY_WORDS,GroupStartLine[1],GroupEndLine[1])
            
            if All_PrecedingWords_Found then
              -- if #TopLine > 1 and #UPPERprec_key_words == 1 and H.IsSectionActive then
              if #TopLine > 1 and H.IsSectionActive then
                HandleLists(H, TextFileTable, TopLine, BottomLine, PrecKeyWordLine)
              end
              
              GroupStartLine = TopLine
              GroupEndLine = BottomLine
              SpecialKeyWordLine = PrecKeyWordLine
              
              SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKPK1",SectionsTable)
              H.DEBUG_FindGroup_print("\n  SKPK     >>> count = 1, Found PREC_KEY_WORDS between lines "..GroupStartLine[1].." and "..GroupEndLine[1].."\n")
              
            else
              if #UPPERprec_key_words == 1 and UPPERprec_key_words[#UPPERprec_key_words] ~= "" then
                H.DEBUG_FindGroup_print("\n  SKPK     >>> count = 1, Only one PREC_KEY_WORDS AND was NOT found in section")
                --we have a single PRECEDING_KEY_WORDS
                --let us try to find it in the current section
                
                local newStartLine = {}
                local newEndLine = {}
                local newKWLine = {}
                local newKWinfo = {}
                
                for m = 1,#GroupStartLine do
                  -- look for the last prec_key_words line in the SpecialWords range
                  for n = GroupStartLine[m], GroupEndLine[m] do
                    local line = strupper(TextFileTable[n])
                    if strfind(line,[["]]..UPPERprec_key_words[#UPPERprec_key_words]..[["]]) then
                      --found the line, replace the Group Start/End lines
                      newKWLine[m] = n -- 'the' line
                      if n == GroupStartLine[m] then
                        newStartLine[m] = n -- the top of the section
                        newEndLine[m] = H.GoDownToOwnerEnd(TextFileTable,n+1)
                      else
                        newStartLine[m] = H.GoUPToOwnerStart(TextFileTable,n)
                        newEndLine[m] = H.GoDownToOwnerEnd(TextFileTable,newStartLine[m]+1)
                      end
                      newKWinfo = TextFileTable[n]
                      
                      H.DEBUG_FindGroup_print("newKWLine[m] = "..newKWLine[m])
                      H.DEBUG_FindGroup_print("\n  SKPK     >>> count = 1, Found last PREC_KEY_WORDS "..[["]]..prec_key_words[#prec_key_words]..[["]].." at line "..newKWLine[m].."\n")
                      
                      All_PrecedingWords_Found = true
                      IsOnlyOnePreceding = true
                      
                      break
                    end
                  end
                end
                
                GroupStartLine = newStartLine
                GroupEndLine = newEndLine
                SpecialKeyWordLine = newKWLine
                KWinfo = newKWinfo

                if not All_PrecedingWords_Found then
                  print("")
                  print(">>> "..H.gcWARNING.." [WARNING] PRECEDING_KEY_WORDS ".."["..prec_key_words[#prec_key_words].."] NOT found in the current section, IGNORING IT "..H._zDEFAULT)
                  H.Report("","PRECEDING_KEY_WORDS ".."["..prec_key_words[#prec_key_words].."] NOT found in the current section, IGNORING IT","WARNING")
                  
                  -- --let us just do as if prec_key_words was not there
                  -- All_PrecedingWords_Found = true
                else
                  --update sections
                  SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKPKL",SectionsTable)
                end
                
              else --multiple prec_key_words NOT FOUND
                print("")
                print(">>> "..H.gcWARNING.." [WARNING] PRECEDING_KEY_WORDS NOT found in the current section, IGNORING THEM "..H._zDEFAULT)
                H.Report("","PRECEDING_KEY_WORDS NOT found in the current section, IGNORING THEM","WARNING")
              end
            end
            
            -- assert(#KWinfo == #GroupStartLine,"SKPK FindGroup() #KWinfo ~= #GroupStartLine")
            
            --**************************************** handle SECTION_UP_PRECEDING ***********************************
            if section_up_preceding > 0 then
              H.DEBUG_FindGroup_print("   Found SECTION_UP_PRECEDING = "..section_up_preceding)
              GroupStartLine,GroupEndLine,PrecKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,PrecKeyWordLine,section_up_preceding)
              SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,PrecKeyWordLine,"UPP",SectionsTable)
            end
            --**************************************** end: handle SECTION_UP_PRECEDING ***********************************
            
            H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." UNIQUE SKW-PKW in "..H.dClock(os.clock() - tFindGroup))
            tFindGroup = os.clock()
          end
          
        else
          local Info = GetSpecKeyWordsInfo(H,spec_key_words)
          H.Report("",[[Should have found SPECIAL_KEY_WORDS: ]]..Info,"WARNING")
          print("\n"..H.gcWARNING..[[>>> [WARNING] Should have found SPECIAL_KEY_WORDS: ]]..Info.." "..H._zDEFAULT)
        end
        -- assert(#KWinfo == #GroupStartLine,"Ending SK = 1 FindGroup() #KWinfo ~= #GroupStartLine")
        
      elseif count > 1 then
        --count > 1 >>> not unique, maybe good or bad (not a SCRIPTBUILDER script)
        H.DEBUG_FindGroup_print("\n  SK     >>> count > 1 (NOT UNIQUE), SPECIAL_KEY_WORDS ["..spec_key_words[1].."] and ["..spec_key_words[2].."] are not unique in file!\n")
        
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,0,searchFor,KWinfo,true,0)
-- printf("SK: #KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
-- ShowDebugSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,"CreateSectionsFromFastCheckUniqueness")

        -- assert(#KWinfo == #GroupStartLine,"SK > 1 FindGroup() #KWinfo ~= #GroupStartLine")
        -- for Z=1,#KWinfo do
          -- printf("D1: %d - [%s]",Z,KWinfo[Z])
        -- end
        
        if #UPPERspec_key_words > 2 then
          GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = SpecialKeywordsSections(TextFileTable,UPPERspec_key_words,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
-- printf("Y: #KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
          -- assert(#KWinfo == #GroupStartLine,"SK > 1 pair FindGroup() #KWinfo ~= #GroupStartLine")
        end
        
        -- for Z=1,#KWinfo do
          -- printf("D2: %d - [%s]",Z,KWinfo[Z])
        -- end
        
        GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KeepOuterSections,"B",KWinfo)
-- printf("B: #KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
        -- assert(#KWinfo == #GroupStartLine,"SK B FindGroup() #KWinfo ~= #GroupStartLine")
        
        -- for Z=1,#KWinfo do
          -- printf("D3: %d - [%s]",Z,KWinfo[Z])
        -- end
        
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKx",SectionsTable)
        -- ShowSections(H,SectionsTable)
        
        --**************************************** handle SECTION_UP_SPECIAL ***********************************
        if section_up_special > 0 then
          H.DEBUG_FindGroup_print("   Found SECTION_UP_SPECIAL = "..section_up_special)
          GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up_special)
          SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UPS",SectionsTable)
          -- assert(#KWinfo == #GroupStartLine,"SK UPS FindGroup() #KWinfo ~= #GroupStartLine")
        end
        --**************************************** end: handle SECTION_UP_SPECIAL ***********************************
        
        H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." MULTIPLE SKW in "..H.dClock(os.clock() - tFindGroup))
        tFindGroup = os.clock()
        
        -- --here we have all the sections (or the whole file) pointed by the spec_key_words
        -- H.pv(">>> BASED on SPECIAL_KEY_WORDS, #Sections = "..#GroupStartLine)
        -- for i=1,#GroupStartLine do
          -- H.pv("   "..i..": "..GroupStartLine[i].."-"..GroupEndLine[i]..", "..SpecialKeyWordLine[i])
        -- end
        
        local IsFoundOneSKW = false
        for i=1,#SpecialKeyWordLine do
          if SpecialKeyWordLine[i] and SpecialKeyWordLine[i] > 0 then
            IsFoundOneSKW = true
          end
        end
        
        if IsFoundOneSKW then
          -- at least one section found somewhere
          All_SpecialWords_Found = true
          
          if IsPrec_key_words then
            local tmpGroupStartLine = {}
            local tmpGroupEndLine = {}
            local tmpSpecialKeyWordLine = {}
            
            All_PrecedingWords_Found = false
            
            local savedKWinfo = H.cloneArray(KWinfo)

        -- for Z=1,#KWinfo do
          -- printf("E1: %d - [%s]",Z,KWinfo[Z])
        -- end
        
            --lets try with all the PREC_KEY_WORDS
            TopLine,BottomLine,PrecKeyWordLine,IsHOSCreated,KWinfo = PrecKeywordsSections(TextFileTable, UPPERprec_key_words, GroupStartLine, GroupEndLine, SectionStartLine, SectionEndLine,PrecKeyWordLine, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsAfterKeyWords, IsCreateHOSTRUE, KWinfo, false)
            -- TopLine,BottomLine,PrecKeyWordLine,PossibleHOStable,KWinfo = PrecKeywordsSections(TextFileTable, UPPERprec_key_words, GroupStartLine, GroupEndLine, IsPrecedingFirstTRUE, IsSpecialKeyWords, IsCreateHOSTRUE, KWinfo, false, PossibleHOStable)
            -- assert(#KWinfo == #TopLine,"SKW-PKW FindGroup() #KWinfo ~= #TopLine")
            -- H.printf("B:  AFTER PrecKeywordsSections().IsHOSCreated = %s",tostring(IsHOSCreated))
-- print("#TopLine = "..#TopLine)
            
        -- for Z=1,#KWinfo do
          -- printf("E2: %d - [%s]",Z,KWinfo[Z])
        -- end
        
            -- printf("===== #TopLine = %d, %s",#TopLine,tostring(next(TopLine)))
            -- for i=1,#TopLine do
              -- printf(" - TopLine[%d] = %s",i,tostring(TopLine[i]))
            -- end
            
            All_PrecedingWords_Found = (#TopLine > 0)
            
           --All_PrecedingWords_Found,TopLine,BottomLine = LocatePrecKeywordsWithTreeMap(FILE_LINE,TREE_LEVEL,KEY_WORDS,GroupStartLine[i],GroupEndLine[i])
           
            if All_PrecedingWords_Found then
              H.DEBUG_FindGroup_print("        >A1: Found "..#GroupStartLine.." SKW-PKW")
              tt = os.clock()
              
              -- if #TopLine > 1 and #UPPERprec_key_words == 1 and H.IsSectionActive then
              if #TopLine > 1 and H.IsSectionActive then
                HandleLists(H, TextFileTable, TopLine, BottomLine, PrecKeyWordLine)
              end
              
              for j=1,#TopLine do
                tmpGroupStartLine[#tmpGroupStartLine+1] = TopLine[j]
                tmpGroupEndLine[#tmpGroupEndLine+1] = BottomLine[j]
                tmpSpecialKeyWordLine[#tmpSpecialKeyWordLine+1] = PrecKeyWordLine[j]
                -- H.DEBUG_FindGroup_print("  SKPK     >>> count > 1, Found PREC_KEY_WORDS between lines "..tmpGroupStartLine[j].." and "..tmpGroupEndLine[j])
              end
              
              SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKxPKx",SectionsTable)
              
              H.DEBUG_FindGroup_timing_print("        >A1: ".."  found "..#GroupStartLine.." SKW-PKW in "..H.dClock(os.clock() - tt))
              tt = os.clock()
              
            else
              H.DEBUG_FindGroup_print("        >A2: NOT found "..#GroupStartLine.." SKW-PKW")
              
              -- restore KWinfo
              KWinfo = savedKWinfo
              
              if #UPPERprec_key_words == 1 and UPPERprec_key_words[#UPPERprec_key_words] ~= "" then
                tt = os.clock()
                
                --look for the last prec_key_words line in that range
                --for all sections found
                for i=1,#GroupStartLine do
                  local IsFound = false
                  for n = GroupStartLine[i], GroupEndLine[i] do
                    local line = strupper(TextFileTable[n])
                    if strfind(line,[["]]..UPPERprec_key_words[#UPPERprec_key_words]..[["]]) then
                      --found the line with this PKW word, save the Group Start/End lines
                      -- printf(">>at %d: [%s] ==> [%s]",n,line,[["]]..UPPERprec_key_words[#UPPERprec_key_words]..[["]])
                      tmpSpecialKeyWordLine[#tmpSpecialKeyWordLine+1] = n -- 'the' line

                      if n == GroupStartLine[i] then -- the top of the section
                        tmpGroupStartLine[#tmpGroupStartLine+1] = n -- stay in this section
                        tmpGroupEndLine[#tmpGroupEndLine+1] = H.GoDownToOwnerEnd(TextFileTable, tmpGroupStartLine[#tmpGroupStartLine]+1, GroupEndLine[i]) -- to the end of the section defined by SPECIAL_KEYWORDS
                      else
                        tmpGroupStartLine[#tmpGroupStartLine+1] = H.GoUPToOwnerStart(TextFileTable ,n ,GroupStartLine[i])
                        tmpGroupEndLine[#tmpGroupEndLine+1] = H.GoDownToOwnerEnd(TextFileTable, tmpGroupStartLine[#tmpGroupStartLine], GroupEndLine[i]) -- to the end of the section defined by SPECIAL_KEYWORDS
                      end
                      -- tmpGroupEndLine[#tmpGroupEndLine+1] = H.GoDownToOwnerEnd(TextFileTable,n + 1,GroupEndLine[i]) -- to the end of the section defined by SPECIAL_KEYWORDS
                      IsFound = true
                      All_PrecedingWords_Found = true
                      H.DEBUG_FindGroup_print("  SKPK     >>> count > 1, Found last PREC_KEY_WORDS "..[["]]..prec_key_words[#prec_key_words]..[["]].." at line "..tmpGroupStartLine[#tmpGroupStartLine].."-"..tmpGroupEndLine[#tmpGroupEndLine])
                      -- print("  SKPK     >>> count > 1, Found last PREC_KEY_WORDS "..[["]]..prec_key_words[#prec_key_words]..[["]].." at line "..tmpGroupStartLine[#tmpGroupStartLine].."-"..tmpGroupEndLine[#tmpGroupEndLine])
                      
                      IsOnlyOnePreceding = true
                      break
                    end
                  end
                  
                  -- if H.IsKWpattern then
                    if IsFound then
                      KWinfo[i] = KWinfo[i]..TextFileTable[tmpSpecialKeyWordLine[#tmpSpecialKeyWordLine]]..":"
                    else
                      KWinfo[i] = ""
                    end
                  -- end
                  
                end --for i=1,#GroupStartLine do
                
                -- assert(#KWinfo == #GroupStartLine,"SK B FindGroup() #KWinfo ~= #GroupStartLine")
                SectionsTable = AddSectionsIntoTable(H,tmpGroupStartLine,tmpGroupEndLine,tmpSpecialKeyWordLine,"SKxPKL",SectionsTable)
                
                if All_PrecedingWords_Found then
                  --at least one section was found
                else
                  SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKxPK0",SectionsTable)
                  ShowSections(H,SectionsTable)
                  
                  print(">>> "..H.gcWARNING.." [WARNING] PRECEDING_KEY_WORDS NOT found in any section, IGNORING IT "..H._zDEFAULT)
                  H.Report("","PRECEDING_KEY_WORDS NOT found in any section, IGNORING IT","WARNING")
                end
                
              else
                SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"SKxPK00",SectionsTable)
                ShowSections(H,SectionsTable)
                
                print("")
                print(">>> "..H.gcWARNING.." [WARNING] ALL PRECEDING_KEY_WORDS NOT found in any section, IGNORING THEM "..H._zDEFAULT)
                H.Report("","ALL PRECEDING_KEY_WORDS NOT found in any section, IGNORING THEM","WARNING")
              end
              
              H.DEBUG_FindGroup_timing_print("        >B: ".."  found "..#GroupStartLine.." SKW-PKW in "..H.dClock(os.clock() - tt))
              tt = os.clock()
              
            end
            
            tt = os.clock()
            
            -- GroupStartLine,GroupEndLine,SpecialKeyWordLine = SectionsTableToLines(H,SectionsTable)
            if #tmpSpecialKeyWordLine > 0 then
              -- print("SKxPKL sections found = "..#tmpSpecialKeyWordLine)
                -- for i=1,10 do
                  -- print("1: === "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..SpecialKeyWordLine[i]..")")
                -- end
                
              --remove old sections
              SpecialKeyWordLine = {}
              GroupStartLine = {}
              GroupEndLine = {}
              
              --add the new sections
              for j=1,#tmpSpecialKeyWordLine do
                SpecialKeyWordLine[#SpecialKeyWordLine+1] = tmpSpecialKeyWordLine[j]
                GroupStartLine[#GroupStartLine+1] = tmpGroupStartLine[j]
                GroupEndLine[#GroupEndLine+1] = tmpGroupEndLine[j]
              end
              -- for i=1,10 do
                -- print("2: === "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..SpecialKeyWordLine[i]..")")
              -- end
            else
              --just keep the old tables
            end
            
            --**************************************** handle SECTION_UP_PRECEDING ***********************************
            if section_up_preceding > 0 then
              H.DEBUG_FindGroup_print("   Found SECTION_UP_PRECEDING = "..section_up_preceding)
              GroupStartLine,GroupEndLine,PrecKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,PrecKeyWordLine,section_up_preceding)
              SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,PrecKeyWordLine,"UPP",SectionsTable)
            end
            --**************************************** end: handle SECTION_UP_PRECEDING ***********************************
            
            H.DEBUG_FindGroup_timing_print("        >C: ".."  found "..#GroupStartLine.." SKW-PKW in "..H.dClock(os.clock() - tt))
            
          end --if IsPrec_key_words then
          -- print([[FindGroup() "SKxPKL", Sanity check: ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]]..#SpecialKeyWordLine..[[ ]])
          
        else
          if #SpecialKeyWordLine == 0 then
            print(H.gcERROR.."\n"..[[>>>  [ERROR] Should have found all SPECIAL_KEY_WORDS ]]..H._zDEFAULT)
            H.Report("",[[Should have found all SPECIAL_KEY_WORDS]],"ERROR")
            -- ReturnInfo = true
          end
        end
-- printf("#KWinfo = %d, #GroupStartLine= %d",#KWinfo,#GroupStartLine)
        -- assert(#KWinfo == #GroupStartLine,"SKPK > 1 Ending FindGroup() #KWinfo ~= #GroupStartLine")
        
      else --count = 0 >>> not found, problem (not a SCRIPTBUILDER script)
        --    user has a problem with his/her script spec_key_words (SCRIPTBUILDER guaranties it can be found)
        --    Report WARNING, skip this change
        print("\n"..">>> "..H.gcWARNING.." [WARNING] Some SPECIAL_KEY_WORDS cannot be found.  Skipping this change! "..H._zDEFAULT)
        H.Report("","Some SPECIAL_KEY_WORDS cannot be found.  Skipping this change!","WARNING")
        All_SpecialWords_Found = false
        -- ReturnInfo = true
      end --if count...
    end
    
  else -- PRECEDING_FIRST = "True" or NO SKW
    --*******************  process PrecedingKeyWords FIRST if any  *********************************
-- print("==> "..GetPrecKeyWordsInfo(UPPERprec_key_words))  
-- print("==> "..GetSpecKeyWordsInfo(H,UPPERspec_key_words))
    if IsPrec_key_words then
      H.DEBUG_FindGroup_print("  PK     >>> INTO: PRECEDING_FIRST: find all SECTIONs with ALL PRECEDING_KEY_WORDS...\n")
      
      --lets try with all the PREC_KEY_WORDS
      TopLine,BottomLine,PrecKeyWordLine,IsHOSCreated,KWinfo = PrecKeywordsSections(TextFileTable,UPPERprec_key_words,GroupStartLine,GroupEndLine,SectionStartLine,SectionEndLine,PrecKeyWordLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsAfterKeyWords,IsCreateHOSTRUE,KWinfo,true)
      -- TopLine,BottomLine,PrecKeyWordLine,PossibleHOStable,KWinfo = PrecKeywordsSections(TextFileTable,UPPERprec_key_words,GroupStartLine,GroupEndLine,IsPrecedingFirstTRUE,IsSpecialKeyWords,IsCreateHOSTRUE,KWinfo,true,PossibleHOStable)
      -- assert(#KWinfo == #TopLine,"PK FindGroup() #KWinfo ~= #TopLine")
      -- H.printf("C:  AFTER PrecKeywordsSections().IsHOSCreated = %s",tostring(IsHOSCreated))
      All_PrecedingWords_Found = (#TopLine > 0)
      
      -- for Z=1,#KWinfo do
        -- printf("E1_0: - [%s]",KWinfo[Z])
      -- end
      -- print("")
      
      if All_PrecedingWords_Found then
        -- if #TopLine > 1 and #UPPERprec_key_words == 1 and H.IsSectionActive then
        if #TopLine > 1 and H.IsSectionActive then
          HandleLists(H, TextFileTable, TopLine, BottomLine, PrecKeyWordLine)
        end
        
        GroupStartLine = TopLine
        GroupEndLine = BottomLine
        SpecialKeyWordLine = PrecKeyWordLine
        
      else
        --let us just do as if prec_key_words was not there
        -- print("")
        -- print(">>> "..H.gcWARNING.." [WARNING] NOT found ALL PRECEDING_KEY_WORDS "..GetPrecKeyWordsInfo(prec_key_words).." in the current section, IGNORING IT "..H._zDEFAULT)
        -- H.Report("","NOT found ALL PRECEDING_KEY_WORDS "..GetPrecKeyWordsInfo(prec_key_words).." in the current section, IGNORING IT","WARNING")
        
        -- --we should check if this PrecedingKeyWord points to a range that includes our SpecialKeyWords
        -- --if yes we can ignore it
        -- --if not we should report it to the user as a WARNING
        -- All_Words_Found = true
      end
      
      GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = RemoveDuplicateGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
      SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"PK",SectionsTable)
      
      GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KeepOuterSections,"C",KWinfo)
      SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"PKx",SectionsTable)

      if not All_PrecedingWords_Found then
        local Info = GetPrecKeyWordsInfo(prec_key_words)
        print(">>> "..H.gcNOTICE.." [NOTICE] -- >>>>> Could not find [\"PRECEDING_KEY_WORDS\"] = "..Info.." <<<<< "..H._zDEFAULT)
        H.Report("","       >>>>> Could not find [\"PRECEDING_KEY_WORDS\"] = "..Info.." <<<<<","NOTICE")
      end
      
      --**************************************** handle SECTION_UP_PRECEDING ***********************************
      if section_up_preceding > 0 then
        H.DEBUG_FindGroup_print("   Found SECTION_UP_PRECEDING = "..section_up_preceding)
        GroupStartLine,GroupEndLine,PrecKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,PrecKeyWordLine,section_up_preceding)
        SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,PrecKeyWordLine,"UP",SectionsTable)
        -- assert(#KWinfo == #GroupStartLine,"PK UP FindGroup() #KWinfo ~= #GroupStartLine")
      end
      --**************************************** end: handle SECTION_UP_PRECEDING ***********************************
      
      H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." PKW in "..H.dClock(os.clock() - tFindGroup))
      tFindGroup = os.clock()
    end

    -- for m=1,#GroupStartLine do
      -- printf("GroupStartLine[%d] = %s",m,tostring(GroupStartLine[m]))
    -- end
    
    if All_PrecedingWords_Found then
      -- print("QQQQQ #GroupStartLine = "..#GroupStartLine)
      
      if IsSpecialKeyWords then
        --now find the SpecialKeyWords inside that Section pointed to by the PRECEDING_KEY_WORDS

        -- -- even if multiple sections where found by PKW
        -- --   ONLY the 1st section found will be processed by SKW
        
        local newStartLine = {}
        local newEndLine = {}
        local newSKWLine = {}
        
        local IsAtleastOneSectionsSKWFound = false
        
        for m=1,#GroupStartLine do
          H.DEBUG_FindGroup_print("\n"..[[  PKSK     >>> From PRECEDING_KEY_WORDS sections, trying to locate Group Start/End lines based on SPECIAL_KEY_WORDS ]]..GetSpecKeyWordsInfo(H,spec_key_words).."\n")
-- printf("For GroupStartLine[%d]",m)

          local PKWstartline = GroupStartLine[m]
          -- printf("PKWstartline = %s",tostring(PKWstartline))
          
          local count,linesNumFound,searchFor = FastCheckUniqueness(strupper(table.concat(TextFileTable,"",GroupStartLine[m],GroupEndLine[m])),UPPERspec_key_words)
          
          if count == 1 then
            --count = 1 >>> unique, good (SCRIPTBUILDER guaranties uniqueness, user do not)
            --    record range info
            H.DEBUG_FindGroup_print("\n  PKSK    >>> count = 1, Looking for SPECIAL_KEY_WORDS between lines "..GroupStartLine[m].." and "..GroupEndLine[m].."\n")
            
            -- GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,PKWstartline - 1,searchFor,KWinfo,false)
            local StartLine,EndLine,SKWLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,PKWstartline - 1,searchFor,KWinfo,false,m)
            
            -- for Z=1,#KWinfo do
              -- printf("F: - [%s]",KWinfo[Z])
            -- end
            -- print("")
            
            for i=1,#StartLine do
              newStartLine[#newStartLine+1] = StartLine[i]
              newEndLine[#newEndLine+1] = EndLine[i]
              newSKWLine[#newSKWLine+1] = SKWLine[i]
            end
            
            if #UPPERspec_key_words > 2 then
              -- UNIQUE: we pass the FOUND section already pointed to by the 1st pair of SKW
              -- GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = SpecialKeywordsSections(TextFileTable,UPPERspec_key_words,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
             newStartLine,newEndLine,newSKWLine,KWinfo = SpecialKeywordsSections(TextFileTable,UPPERspec_key_words,newStartLine,newEndLine,newSKWLine,KWinfo)
            -- assert(#KWinfo == #newStartLine,"PKSK > 1 pair FindGroup() #KWinfo ~= #newStartLine")
            end
          
            -- for Z=1,#newStartLine do
              -- printf("newStartLine[%d] = %d",Z,newStartLine[Z])
            -- end
            
            SectionsTable = AddSectionsIntoTable(H,newStartLine,newEndLine,newSKWLine,"PKSK1",SectionsTable)
            -- --GroupStartLine,GroupEndLine,SpecialKeyWordLine = SectionsTableToLines(H,SectionsTable)
            
            -- -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine))
            -- -- H.DEBUG_FindGroup_print(#SpecialKeyWordLine)
            -- -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine[1]))
            -- -- if SpecialKeyWordLine[m] > 0 then
            -- if newSKWLine[1] and newSKWLine[1] > 0 then
              -- -- NumFoundGroups = NumFoundGroups + 1
              -- -- All_Words_Found = true
              -- All_SpecialWords_Found = true
              -- H.DEBUG_FindGroup_print("  PKSK    >>> count = 1, Found SPECIAL_KEY_WORDS between lines "..newStartLine[1].." and "..newEndLine[1])
            -- end
            
            -- if not All_SpecialWords_Found then
              -- local Info = GetSpecKeyWordsInfo(H,spec_key_words)
              -- H.Report("",[[Should have found SPECIAL_KEY_WORDS: ]]..Info,"WARNING")
              -- print("\n"..H.gcWARNING..[[>>> [WARNING] Should have found SPECIAL_KEY_WORDS: ]]..Info.." "..H._zDEFAULT)
            -- end
            
            -- --**************************************** handle SECTION_UP_SPECIAL ***********************************
            -- if section_up_special > 0 then
              -- H.DEBUG_FindGroup_print("   Found SECTION_UP_SPECIAL = "..section_up_special)
              -- -- GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up_special)
              -- -- SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UPS",SectionsTable)
              -- newStartLine,newEndLine,newSKWLine = Process_SectionUP(H,TextFileTable,newStartLine,newEndLine,newSKWLine,section_up_special)
              -- SectionsTable = AddSectionsIntoTable(H,newStartLine,newEndLine,newSKWLine,"UPS",SectionsTable)
            -- end
            -- --**************************************** end: handle SECTION_UP_SPECIAL ***********************************
            
            IsAtleastOneSectionsSKWFound = true
            H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." PKW-UNIQUE-SKW in "..H.dClock(os.clock() - tFindGroup))
            tFindGroup = os.clock()
            
          elseif count > 1 then
            --count > 1 >>> not unique, maybe good or bad (not a SCRIPTBUILDER script)
            H.DEBUG_FindGroup_print("\n  PKSK    >>> count > 1, SPECIAL_KEY_WORDS ["..spec_key_words[1].."] and ["..spec_key_words[2].."] are not unique in file!\n")
            
            -- GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,PKWstartline - 1,searchFor,KWinfo,false,m)
            local StartLine,EndLine,SKWLine,KWinfo = CreateSectionsFromFastCheckUniqueness(H,linesNumFound,TextFileTable,PKWstartline - 1,searchFor,KWinfo,false,m)
            -- assert(#linesNumFound == #StartLine,"SK FindGroup() #linesNumFound ~= #StartLine")
            -- assert(#KWinfo == #StartLine,"PKSK > 1 FindGroup() #KWinfo ~= #StartLine")
            
-- for Z=1,#KWinfo do
  -- printf("H: - [%s]",KWinfo[Z])
-- end
-- print("")
            
            for i=1,#StartLine do
              newStartLine[#newStartLine+1] = StartLine[i]
              newEndLine[#newEndLine+1] = EndLine[i]
              newSKWLine[#newSKWLine+1] = SKWLine[i]
            end
            
            if #UPPERspec_key_words > 2 then
              -- GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = SpecialKeywordsSections(TextFileTable,UPPERspec_key_words,GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
              newStartLine,newEndLine,newSKWLine,KWinfo = SpecialKeywordsSections(TextFileTable,UPPERspec_key_words,newStartLine,newEndLine,newSKWLine,KWinfo)
              -- assert(#KWinfo == #newStartLine,"PKSK > 1 pair FindGroup() #KWinfo ~= #newStartLine")
            end
            
-- for Z=1,#KWinfo do
  -- printf("I: - [%s]",KWinfo[Z])
-- end
-- print("")
            
            H.DEBUG_FindGroup_print([[A ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]]..#SpecialKeyWordLine)
            newStartLine,newEndLine,newSKWLine,KWinfo = PurgeOverlappingSections(newStartLine,newEndLine,newSKWLine,KeepOuterSections,"D",KWinfo)
            -- assert(#KWinfo == #newStartLine,"PKSKx FindGroup() #KWinfo ~= #newStartLine")
            
            SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"PKSKx",SectionsTable)
            -- --GroupStartLine,GroupEndLine,SpecialKeyWordLine = SectionsTableToLines(H,SectionsTable)
            
            -- --here we have all the sections (or the whole file) pointed by the spec_key_words
            -- H.DEBUG_FindGroup_print("  PKSK    >>> BASED on SPECIAL_KEY_WORDS, #Sections = "..#GroupStartLine)
            -- for i=1,#GroupStartLine do
              -- H.DEBUG_FindGroup_print("   "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..SpecialKeyWordLine[i]..")")
            -- end
            
            -- if SpecialKeyWordLine[1] and SpecialKeyWordLine[1] > 0 then
              -- -- NumFoundGroups = #SpecialKeyWordLine
              -- -- All_Words_Found = true
              -- All_SpecialWords_Found = true
              
            -- else
              -- if #SpecialKeyWordLine == 0 then
                -- print(H.gcERROR.."\n"..[[>>>  [ERROR] Should have found all SPECIAL_KEY_WORDS ]]..H._zDEFAULT)
                -- H.Report("",[[Should have found all SPECIAL_KEY_WORDS]],"ERROR")
                -- -- ReturnInfo = true
              -- end
            -- end
            
            -- --**************************************** handle SECTION_UP_SPECIAL ***********************************
            -- if section_up_special > 0 then
              -- H.DEBUG_FindGroup_print("   Found SECTION_UP_SPECIAL = "..section_up_special)
              -- GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up_special)
              -- SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UPS",SectionsTable)
            -- end
            -- --**************************************** end: handle SECTION_UP_SPECIAL ***********************************
            IsAtleastOneSectionsSKWFound = true
            
          else
            --count = 0 >>> not found, problem (not a SCRIPTBUILDER script)
            if H.IsKWpattern then
              KWinfo[m] = ""
            end
          end --if count...
          
          H.DEBUG_FindGroup_timing_print("        > ".."  found "..#GroupStartLine.." PKW-MULTIPLE-SKW in "..H.dClock(os.clock() - tFindGroup))
          tFindGroup = os.clock()
        end -- for m=1,#GroupStartLine do
        
        if not IsAtleastOneSectionsSKWFound and not H.IsKWpattern then
          --    user has a problem with his/her script spec_key_words (SCRIPTBUILDER guaranties it can be found)
          --    Report WARNING, skip this change
          print("\n"..">>> "..H.gcWARNING.." [WARNING] These SPECIAL_KEY_WORDS cannot be found.  Skipping this change! "..H._zDEFAULT)
          H.Report("","These SPECIAL_KEY_WORDS cannot be found.  Skipping this change!","WARNING")
        end
        
        GroupStartLine = newStartLine
        GroupEndLine = newEndLine
        SpecialKeyWordLine = newSKWLine
        
        -- SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"PKSKx",SectionsTable)
        --GroupStartLine,GroupEndLine,SpecialKeyWordLine = SectionsTableToLines(H,SectionsTable)
        
        -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine))
        -- H.DEBUG_FindGroup_print(#SpecialKeyWordLine)
        -- H.DEBUG_FindGroup_print(type(SpecialKeyWordLine[1]))

        --here we have all the sections (or the whole file) pointed by the spec_key_words
        H.DEBUG_FindGroup_print("  PKSK    >>> BASED on SPECIAL_KEY_WORDS, #Sections = "..#GroupStartLine)
        for i=1,#GroupStartLine do
          H.DEBUG_FindGroup_print("   "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..SpecialKeyWordLine[i]..")")
        end
        
        for i=1,#SpecialKeyWordLine do
          if SpecialKeyWordLine[i] and SpecialKeyWordLine[i] > 0 then
            -- only need ONe to exist
            All_SpecialWords_Found = true
            break
          end
        end
        
        if not All_SpecialWords_Found then
          local Info = GetSpecKeyWordsInfo(H,spec_key_words)
          H.Report("",[[Should have found SPECIAL_KEY_WORDS: ]]..Info,"WARNING")
          print("\n"..H.gcWARNING..[[>>> [WARNING] Should have found SPECIAL_KEY_WORDS: ]]..Info.." "..H._zDEFAULT)
        end
        
        --**************************************** handle SECTION_UP_SPECIAL ***********************************
        if section_up_special > 0 then
          H.DEBUG_FindGroup_print("   Found SECTION_UP_SPECIAL = "..section_up_special)
          -- GroupStartLine,GroupEndLine,SpecialKeyWordLine = Process_SectionUP(H,TextFileTable,GroupStartLine,GroupEndLine,SpecialKeyWordLine,section_up_special)
          -- SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"UPS",SectionsTable)
          newStartLine,newEndLine,newSKWLine = Process_SectionUP(H,TextFileTable,newStartLine,newEndLine,newSKWLine,section_up_special)
          SectionsTable = AddSectionsIntoTable(H,newStartLine,newEndLine,newSKWLine,"UPS",SectionsTable)
        end
        --**************************************** end: handle SECTION_UP_SPECIAL ***********************************
        
      end --if IsSpecialKeyWords then
    end --if All_PrecedingWords_Found then
  end --if not IsPrecedingFirstTRUE then
  
  H.DEBUG_FindGroup_print("")
  H.DEBUG_FindGroup_print([[FindGroup() "ending", Sanity check: ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]]..#SpecialKeyWordLine..[[ ]])
  -- print([[FindGroup() "pre-ending", Sanity check: ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]]..#SpecialKeyWordLine..[[ ]])
  GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo = PurgeOverlappingSections(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KeepOuterSections,"E",KWinfo)
  -- print([[FindGroup() "ending", Sanity check: ]]..#GroupStartLine..[[ ]]..#GroupEndLine..[[ ]]..#SpecialKeyWordLine..[[ ]])
  
  -- SectionsTable = AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,"Using ",SectionsTable)
  
  All_Words_Found = false
  if IsSpecialKeyWords then
    if All_SpecialWords_Found then
      if IsPrec_key_words then
        if All_PrecedingWords_Found then
          All_Words_Found = true
        end
      else
        All_Words_Found = true
      end
    end
  else
    if IsPrec_key_words and All_PrecedingWords_Found then
      All_Words_Found = true
    end
  end
  
  if H.TestNoNil("FindGroup()",All_Words_Found,GroupStartLine[1],GroupEndLine[1],SpecialKeyWordLine[1]) then
    H.DEBUG_FindGroup_print("")
    H.DEBUG_FindGroup_print("Found all Key_Words: "..tostring(All_Words_Found)..", First line: "..GroupStartLine[1]..", Last line: "..GroupEndLine[1])
    H.DEBUG_FindGroup_print("Found all SPECIAL_KEY_WORDS: "..tostring(All_SpecialWords_Found))
    H.DEBUG_FindGroup_print("Found all PRECEDING_KEY_WORDS: "..tostring(All_PrecedingWords_Found))
  else
    H.DEBUG_FindGroup_print("")
    H.DEBUG_FindGroup_print(" === FindGroup() returns some NIL values ===")
  end
  
-- H.WFAK("FindGroup End...")

  H.DEBUG_FindGroup_print("\n"..H.THIS.."Ending FindGroup()\n")
  H.gVerbose = false
  -- return All_Words_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, KWinfo, PossibleHOStable
  return All_Words_Found, GroupStartLine, GroupEndLine, SpecialKeyWordLine, SectionsTable, IsOnlyOnePreceding, IsHOSCreated, KWinfo
end
--**************************************** END: FindGroup() ***********************************
--#############################################################################################

--***************************************************************************************************
-- compress adjacent groups into one
function CompressGroups(GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo)
  if #GroupStartLine > 1 then
    local Gsl = {}
    local Gel = {}
    local Gll = {}
    local Ginfo = KWinfo
    
    local top = GroupStartLine[1]
    local skl = SpecialKeyWordLine[1]
    -- H.printf("CG: top = %d",top)
    
    local i = 1
    repeat
      if GroupEndLine[i]+1 ~= GroupStartLine[i+1] or i == #GroupStartLine then
        Gsl[#Gsl+1] = top
        Gel[#Gel+1] = GroupEndLine[i]
        Gll[#Gll+1] = skl

        top = GroupStartLine[i+1]
        skl = SpecialKeyWordLine[i+1]
      end
      i = i + 1
    until i > #GroupStartLine

    -- for i=1,#Gsl do
      -- H.printf("  ==> CG: %d - %d (%d)",Gsl[i],Gel[i],Gll[i])
    -- end

    return Gsl,Gel,Gll,Ginfo
  end
  
  return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
end

--***************************************************************************************************
-- make sure order is from top to bottom
function AscGroupsOrder(Gs,Ge,Gl,KWinfo)
  -- order the Groups in increasing order
  if #Gs > 1 then
    local GsClone = H.cloneArray(Gs)
    table.sort(GsClone)
    
    -- create fast table
    local fastGs = {}
    for i=1,#Gs do
      fastGs[Gs[i]] = i
    end
    
    local Gsl = {}
    local Gel = {}
    local Gll = {}
    local Ginfo = {}

    for i=1,#GsClone do -- ascending
      local index = fastGs[GsClone[i]]
      
      Gsl[#Gsl+1] = Gs[index]
      Gel[#Gel+1] = Ge[index]
      Gll[#Gll+1] = Gl[index]
      Ginfo[#Ginfo+1] = KWinfo[index]
    end
    return Gsl,Gel,Gll,Ginfo
  end
  return Gs,Ge,Gl,KWinfo
end

--***************************************************************************************************
-- reversing the order of the Groups
-- so that we add or remove from the bottom up
function ReverseGroupsOrder(Gs,Ge,Gl,KWinfo)
  -- order the Groups in increasing order
  -- so that we can safely reverse order to add or remove from the bottom up
  if #Gs > 1 then
    local GsClone = H.cloneArray(Gs)
    table.sort(GsClone)
    
    -- create fast table
    local fastGs = {}
    for i=1,#Gs do
      fastGs[Gs[i]] = i
    end
    
    local Gsl = {}
    local Gel = {}
    local Gll = {}
    local Ginfo = {}

    for i=#GsClone,1,-1 do -- descending
      local index = fastGs[GsClone[i]]
      
      Gsl[#Gsl+1] = Gs[index]
      Gel[#Gel+1] = Ge[index]
      Gll[#Gll+1] = Gl[index]
      Ginfo[#Ginfo+1] = KWinfo[index]
    end
    return Gsl,Gel,Gll,Ginfo
  end
  return Gs,Ge,Gl,KWinfo
end
--******************************* END: ReverseGroupsOrder *******************************************

--***************************************************************************************************
-- for each section in reverse order (because we remove unwanted ones)
-- remove overlapping ones
function PurgeOverlappingSections(GroupStartLine,GroupEndLine,KeyWordLine,KeepOuterSections,CalledFrom,KWinfo)
  if KeepOuterSections == nil then KeepOuterSections = true end
  local ToDelete = {}

-- print("BBBBBBBBBBB ==> "..CalledFrom)
-- for i=1,#GroupStartLine do
  -- H.printf("%d: %d - %d",i,GroupStartLine[i],GroupEndLine[i])
-- end
-- print("BBBBBBBBBBB")

  local tmpGel = GroupEndLine[1]
  -- for i=1,#GroupStartLine do
    -- print("PURGE: === "..GroupStartLine[i].."-"..GroupEndLine[i].." ("..KeyWordLine[i]..")")
  -- end
  -- print(string.format("PURGE: %s, initial tmpGel = %d with %d section(s)",CalledFrom,tmpGel,#GroupStartLine))
  
  if KeepOuterSections then
    --keep outer sections only
    for i=2,#GroupStartLine do
      if GroupStartLine[i] <= tmpGel then
        --section i is inside section i-1
        --flag section i
        -- print("PURGE: "..GroupStartLine[i].." <= "..tmpGel.." removed inner = "..GroupStartLine[i])
        ToDelete[i] = true
      else
        ToDelete[i] = false
        tmpGel = GroupEndLine[i]
      end
    end
    
  -- else
    -- NOT USED
  end
  
  for i=#GroupStartLine,1,-1 do
    if ToDelete[i] then
      -- H.printf("%d: remove %d",i,GroupStartLine[i])
      table.remove(GroupStartLine,i)
      table.remove(GroupEndLine,i)
      table.remove(KeyWordLine,i)

-- THIS BELOW COULD BUG !!!  use "Testing script FOR kINFO BUG.lua" to debug further
      if KWinfo[i] then
        table.remove(KWinfo,i)
      end
    end
  end
  
  return GroupStartLine,GroupEndLine,KeyWordLine,KWinfo
end
--****************************** END: PurgeOverlappingSections ******************************************************************

--***************************** RemoveDuplicateGroups() **********************************************
-- recreate Group List and remove duplicates
function RemoveDuplicateGroups(GSL,GEL,SKWL,KWinfo)
  local GroupStartLine = {}
  local GroupEndLine = {}
  local SpecialKeyWordLine = {}
  local newKWinfo = {}
  
  if #GSL == 1 then
    GroupStartLine[1] = GSL[1]
    GroupEndLine[1] = GEL[1]
    SpecialKeyWordLine[1] = SKWL[1]
    newKWinfo[1] = KWinfo[1]
    
  elseif #GSL > 1 then
    local tmp = {}
    for i=1,#GSL do
      if tmp[GSL[i]] then
        -- already exist, skip it
      else
        -- does not exist, record it
        tmp[GSL[i]] = true
        
        GroupStartLine[#GroupStartLine+1] = GSL[i]
        GroupEndLine[#GroupEndLine+1] = GEL[i]
        SpecialKeyWordLine[#SpecialKeyWordLine+1] = SKWL[i]
        newKWinfo[#newKWinfo+1] = KWinfo[i]
      end
    end
    
  end
  
  return GroupStartLine,GroupEndLine,SpecialKeyWordLine,KWinfo
end
--***************************** END: RemoveDuplicateGroups() **********************************************

--**********************************  ShowSections()  **************************************
--prints SectionsTable to cmd window if options are ON
function ShowSections(H,SectionsTable,tag)
  -- print("_mSHOWSECTIONS = "..H._mSHOWSECTIONS)
  if H.gIs_LEAN_MODE then return end     

  if tag == nil then tag = "" end

  if H.IsShowSections then
    if #SectionsTable ~= 0 then
      local stripUSING = "Using "
      local spacer = "      "
      
      -- --DEBUG
      -- for i=1,#SectionsTable do
        -- local st = H.trim(SectionsTable[i])
        -- print("ShowSections A:                "..spacer..st)
      -- end
      
      -- local sinfo = ""
      print("")
      print(tag.."    Section(s) found: ")
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." Start ShowSections (%.0fKb)",collectgarbage("count")) -- 7.433

      local tTable = {}
      for i=1,#SectionsTable do -- was #SectionsTable-1
        tTable[#tTable+1] = H.trim(SectionsTable[i])
      end
      
      --remove duplicate sections
      local sTable = {}

      local tmp = {}
      for i=1,#tTable do
        if tmp[tTable[i]] then
          -- already exist, skip it
        else
          -- does not exist, record it
          tmp[tTable[i]] = true
          sTable[#sTable+1] = tTable[i]
        end
      end
      
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." End 1st ForLoop, remove duplicates, start 2nd ForLoop (%.0fKb)",collectgarbage("count")) -- 8.474
      
      local j = 1
      for i=1,#sTable do
        local st = H.trim(sTable[i])
        if not string.find(st,"Using") then
          if H._mSHOWEXTRASECTIONS == "Y" then
            print(string.format("X%3d:                "..spacer..st,i))
          end
        else
          -- printf("H.KWinfo[%d] = [%s]",j,tostring(H.KWinfo[j]))
          local info = H.KWinfo[j]
          if info == nil or not H.IsKWpattern then
            info = ""
          end
          st = string.gsub(st,stripUSING,"")
          local space = "                    "
          print(space..spacer..st..string.rep(" ",#space + #spacer +6 - #st)..info)
          j = j + 1
        end
      end
      H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." End ShowSections (%.0fKb)",collectgarbage("count")) -- 12.882
    end
  end
end
--**********************************  END: ShowSections()  **************************************

-- --**************************************** SectionsTableToLines() ***********************************
-- --extracts GroupStartLine,GroupEndLine from SectionsTable
-- -- NOT USED
-- function SectionsTableToLines(H,SectionsTable)
  -- H.pv("In SectionsTableToLines()")
  -- local GroupStartLine = {}
  -- local GroupEndLine = {}
  -- local KeyWordLine = {}
  
  -- for i=1,#SectionsTable do
    -- local st = H.trim(SectionsTable[i])
    -- --now remove any text before the number
    -- while string.sub(st,1,1) ~= " " do
      -- st = string.sub(st,2)
    -- end
    
    -- st = H.trim(st)
    -- H.pv("["..st.."]")
    
    -- GroupStartLine[#GroupStartLine+1] = tonumber(string.sub(st,1,string.find(st," - ")-1))
    -- GroupEndLine[#GroupEndLine+1] = tonumber(string.sub(st,string.find(st," - ")+3,string.find(st,"(")-1))
    -- KeyWordLine[#KeyWordLine+1] = tonumber(string.sub(st,string.find(st,"(")+1,string.find(st,")")-1))
  -- end
  
  -- return GroupStartLine,GroupEndLine,KeyWordLine
-- end
-- --**************************************** END: SectionsTableToLines() ***********************************

--************************************ AddSectionsIntoTable() **************************************
--updates SectionsTable with "Tag GroupStartLine - GroupEndLine"
function AddSectionsIntoTable(H,GroupStartLine,GroupEndLine,SpecialKeyWordLine,Tag,SectionsTable)
  H.DEBUG_AddSectionsIntoTable_print("In AddSectionsIntoTable()")
  if Tag == nil then Tag = "" end
  
  --adding groups
  if GroupStartLine[1] and GroupStartLine[1] ~= "" then
    -- local GroupRange = GroupStartLine[1].." - "..GroupEndLine[1]
    -- H.DEBUG_AddSectionsIntoTable_print("    Current section(s): "..Tag..GroupRange)
    local GroupRange
    for i=1,#GroupStartLine do
      if SpecialKeyWordLine[i] == "" then
        GroupRange = string.format("%10d",GroupStartLine[i]).." - "..string.format("%-1d",GroupEndLine[i])
      else
        GroupRange = string.format("%10d",GroupStartLine[i]).." - "..string.format("%-1d",GroupEndLine[i]).." ("..SpecialKeyWordLine[i]..")"
      end
      -- H.DEBUG_AddSectionsIntoTable_print("                        ".."  "..GroupRange)
      SectionsTable[#SectionsTable+1] = Tag..string.rep(" ",7 - #Tag).." "..GroupRange
      H.DEBUG_AddSectionsIntoTable_print("  === Added to SectionTable: "..Tag..string.rep(" ",7 - #Tag).." "..GroupRange)
    end
  end
  
  return SectionsTable
end
--************************************ END: AddSectionsIntoTable() **************************************

function TranslateMathOperatorCommandAndGetValue(H,TextFileTable, SearchKeyProperty, pos, direction)
  -- H.printf("<%s> <%d> <%s>",SearchKeyProperty,pos,direction)
  if direction == "forward" then
    for line = pos,#TextFileTable,1 do
      if (string.find(TextFileTable[line], [["]]..SearchKeyProperty..[["]]) or (SearchKeyProperty == "IGNORE")) then
        -- return H.StripInfo(TextFileTable[line],[[ue="]],[["]])
        return H.GetValue(TextFileTable[line])
      end
    end
    -- if not found try "backward"
    for line = pos,1,-1 do
      if (string.find(TextFileTable[line], [["]]..SearchKeyProperty..[["]]) or (SearchKeyProperty == "IGNORE")) then
        return H.GetValue(TextFileTable[line])
      end
    end
  end
  if direction == "backward" then
    for line = pos,1,-1 do
      if (string.find(TextFileTable[line], [["]]..SearchKeyProperty..[["]]) or (SearchKeyProperty == "IGNORE")) then
        return H.GetValue(TextFileTable[line])
      end
    end
    -- if not found try "forward"
    for line = pos,#TextFileTable,1 do
      if (string.find(TextFileTable[line], [["]]..SearchKeyProperty..[["]]) or (SearchKeyProperty == "IGNORE")) then
        return H.GetValue(TextFileTable[line])
      end
    end
  end
  -- print("[ERROR] in TranslateMathOperatorCommandAndGetValue()")
end

function CheckValueType(value,IsInteger_to_floatFORCE,IsOriginal)
  local n = tonumber(value)
  -- H.printf("value = %s",tostring(n))
  -- H.printf("==> math.type(value) = %s",tostring(math.type(value)))
  -- H.printf("==> math.type(tonumber(value)) = %s",tostring(math.type(n)))
  local ValueTypeIsNumber = (type(n) == "number") -- value could be a number as a string
  if not ValueTypeIsNumber then
    return false,false
  end
  -- H.printf("ValueTypeIsNumber = %s",tostring(ValueTypeIsNumber))
  
  IsOriginal = IsOriginal or false
  
  local ValueIsInteger = false
  
  if not IsInteger_to_floatFORCE then
    if n > math.maxinteger or n < math.mininteger then
      -- say it is an integer then
      ValueIsInteger = true
      -- H.printf("d: ValueIsInteger = %s",tostring(ValueIsInteger))      
    else

      ValueIsInteger = math.type(n) == "integer"
      -- H.printf("a: ValueIsInteger = %s",tostring(ValueIsInteger))

      local v = math.tointeger(value)
      -- H.printf("value = %s",tostring(value))
      -- H.printf("v = %s",tostring(v))

      if v then
        ValueIsInteger = true
      end
      -- H.printf("b: ValueIsInteger = %s",tostring(ValueIsInteger))
      
      -- need to preserve type when the value is the original value
      if IsOriginal and ValueIsInteger then
        if math.type(n) == "float" then
          ValueIsInteger = false
        end
      end
      -- H.printf("c: ValueIsInteger = %s",tostring(ValueIsInteger))      
    end
    -- NOTE:
      -- if 2000 == 2000.0 then
        -- print("2000 == 2000.0") --> prints
      -- end
      -- But Flooring floating-point relies on binary representation of numbers, which is not always precise.
      -- if value == math.floor(value) then -- if value is 2000.0, comparison is FALSE
        -- print("value == math.floor(value)") --> never printed
      -- end
  end
  return ValueTypeIsNumber, ValueIsInteger
end

function IntegerIntegrity(number,IsValueInteger)
  if IsValueInteger then
    return math.floor(number + 0.5)
  end
  return number
end

function ExecuteMathOperation(H,math_operation,operand1,operand2)
  -- print("Ex:  math_operation = ["..tostring(math_operation).."]")
  -- print("Ex:        operand1 = ["..tostring(operand1).."]")
  -- print("Ex:        operand2 = ["..tostring(operand2).."]")
  if operand1 == nil then
    -- print("%% operand1 is nil")
    --subtitute 0, error was already reported
    operand1 = 0
  end
  if operand2 == nil then
    -- print("%% operand2 is nil")
    --subtitute 0, error was already reported
    operand2 = 0
  end
  
  -- print("&& ["..tonumber(operand1).."]")
  -- print("&& ["..tonumber(operand2).."]")
  -- print("&& ["..math_operation.."]")
  
  local tmp = nil
  if math_operation == "*" then
    tmp = tonumber(operand1)*tonumber(operand2)
  elseif math_operation == "+" then
    tmp = tonumber(operand1)+tonumber(operand2)
  elseif math_operation == "-" then
    tmp = tonumber(operand1)-tonumber(operand2)
  elseif math_operation == "/" then
    tmp = tonumber(operand1)/tonumber(operand2)
  elseif math_operation == "//" then
    tmp = tonumber(operand1)//tonumber(operand2)
  elseif math_operation == "%" then
    tmp = tonumber(operand1)%tonumber(operand2)
  elseif math_operation == "^" then
    tmp = tonumber(operand1)^tonumber(operand2)
  else
    print(">>> "..H.gcWARNING.." [WARNING] Unknown MATH_OPERATION: ["..math_operation.."]  Please check your script! "..H._zDEFAULT)
    H.Report(math_operation,"Unknown MATH_OPERATION.  Please check your script!","WARNING")
    return 1
  end
  
  if tmp == math.tointeger(tmp) then
    --this could still be a REAL integer not a float
    tmp = math.tointeger(tmp)
  end
  
  return tmp
end

--################  BELOW: USERSCRIPT PROCESSING  ###############################

--***************************************************************************************************
-- NOT USED
-- function SerializeScript(H,object,multiline,name)
  -- local r = H.serializeObject(object,multiline,0,name) --from Loadhelpers
  
  -- local t = {}
  -- for w in string.gmatch(r,"[^\n]+") do
    -- t[#t+1] = w
  -- end
  
  -- --cleanup strings
  -- for i=1,#t do
    -- local text = t[i]
    -- if H.trim(text) == "" then
      -- --remove empty lines
      -- t[i] = ""
    -- end
    -- --remove trailing whitespace
    -- t[i] = H.rtrim(text)
  -- end
  
  -- local w = {}
  -- for i=1,#t do
    -- if t[i] ~= "" then
      -- w[#w+1] = t[i]
    -- end
  -- end
  -- t = w
  -- --end cleanup strings
  
  -- local i = 1
  -- repeat
    -- -- print(i.."["..t[i].."]")
    -- if string.find(t[i],"VALUE_CHANGE_TABLE",1,true) then
      -- -- print(i.."A["..t[i].."]")
      -- i = i + 2
      -- while H.trim(t[i]) ~= "}," do
        -- -- print(i.."B["..t[i].."]")
        -- t[i] = t[i]..H.trim(t[i+1])..H.trim(t[i+2])..H.trim(t[i+3])
        -- t[i+1] = ""
        -- t[i+2] = ""
        -- t[i+3] = ""
        -- i = i + 4
      -- end
      -- i = i + 1
    -- elseif string.find(t[i],"SPECIAL_KEY_WORDS",1,true) then
      -- if H.trim(t[i+1]) == "{" then
        -- --a table
        -- local anchorLine = i
        -- t[anchorLine] = t[anchorLine].." "..H.trim(t[anchorLine+1])
        -- t[anchorLine+1] = ""
        -- local pointer = 2
        -- repeat
          -- t[anchorLine] = t[anchorLine]..H.trim(t[anchorLine+pointer])
          -- t[anchorLine+pointer] = ""
          -- pointer = pointer + 1
        -- until H.trim(t[anchorLine+pointer]) == "},"
        -- t[anchorLine] = t[anchorLine]..H.trim(t[anchorLine+pointer])
        -- t[anchorLine+pointer] = ""
        -- i = i + pointer
      -- end
      -- i = i + 1
    -- elseif string.find(t[i],"PRECEDING_KEY_WORDS",1,true) then
      -- if H.trim(t[i+1]) == "{" then
        -- --a table
        -- local anchorLine = i
        -- t[anchorLine] = t[anchorLine].." "..H.trim(t[anchorLine+1])
        -- t[anchorLine+1] = ""
        -- local pointer = 2
        -- repeat
          -- t[anchorLine] = t[anchorLine]..H.trim(t[anchorLine+pointer])
          -- t[anchorLine+pointer] = ""
          -- pointer = pointer + 1
        -- until H.trim(t[anchorLine+pointer]) == "},"
        -- t[anchorLine] = t[anchorLine]..H.trim(t[anchorLine+pointer])
        -- t[anchorLine+pointer] = ""
        -- i = i + pointer
      -- end
      -- i = i + 1
    -- else
      -- i = i + 1
    -- end
  -- until i > #t
  
  -- r = {}
  -- for i=1,#t do
    -- if t[i] ~= "" then
      -- r[#r+1] = t[i]
    -- end
  -- end
  
  -- return r
-- end

--***************************************************************************************************
function AnalyzeScript(H, script,scriptTable, scriptFilename, scriptFilenamePath, scriptSizeDiff) --, DelayedReportData
  local problemFound = false
  local InternalFunctionProblem = false
  local possibleProblemFound = false
  local AnalysingStart = os.clock()
  
  print("")
  print("   @@@ ********** "..H._zBRIGHTGREEN.."Analysing script..."..H._zDEFAULT.." **********")
  
  if script == nil then return true end
  
  -- +++++++++ _mLUAC ++++++++
  print("")
  print("   @@@ Checking script using LUAC...")
  local tmpScriptLUACFileName = "LUAC_"..scriptFilename
  local resultFileName = "LastScriptCheckResults_LUAC.lua"
  
  -- just to prevent luac from complaining about bad escape sequences and reverting string.char(1)
  local scriptLUAC = string.gsub(script,[[\\]],[[/]]):gsub(string.char(1),[[\"]])
  -- local scriptLUAC = string.gsub(script,string.char(1),[[\"]]) -- just to prevent luac from complaining about bad escape sequences
  
  -- H.WriteToFileAppend(scriptLUAC,tmpScriptLUACFileName) --script to the tmp file
  H.WriteToFileAppend(script,tmpScriptLUACFileName) --script to the tmp file
  
  local cmd = [[]]..H._mLUAC..[[ -p "]]..tmpScriptLUACFileName..[["2>"]]..resultFileName..[["]]
  -- print("["..cmd.."]")
  local r,s,n = H.NewThread(cmd)
  
  local LUACerrorTable = H.ParseTextFileIntoTable(resultFileName)
  
  problemFound = (#LUACerrorTable > 0)
  
  for i=1,#LUACerrorTable do
    local text = string.gsub(LUACerrorTable[i],H._mLUAC,"")
    tmp = string.sub(text,8)
    local firstPos = string.find(tmp,":",1,true)
    if firstPos then
      tmp = string.sub(tmp,1,firstPos-1).." line "..string.sub(tmp,firstPos+1)
    else
      firstPos = string.find(text,":",1,true)
      if firstPos then
        text = string.sub(text,firstPos + 1 )
      end
    end
    print(H.gcERROR.."       - "..text.." "..H._zDEFAULT)
    local err = "ERROR"
    local msg = "LUAC.exe detected: "
    if firstPos == nil then
      err = ""
      msg = ".                  "
    end
    H.SetReportData(H.DelayedReportData,"",msg..text,err)
  end
-- H.WFAK()
  
  if problemFound then
    local spacer
    if #scriptFilename - 8 > 0 then
      spacer = string.rep(" ",#scriptFilename - 8)
    else
      spacer = "        "
    end
    print([[   @@@ ]]..spacer..[[line number above ^ refers to ]]..H._zBRIGHTORANGE..[[TOOLS\ModScriptCheck\]]..string.gsub(scriptFilename,"%.lua",""):gsub("%.LUA","")..[[.LUAC_Script.lua]]..H._zDEFAULT)
    print("   @@@ Done but found problem(s)")
    -- copy LUAC_ script for user (* required to indicate a file)
    H.CopyFile(tmpScriptLUACFileName,[[..\TOOLS\ModScriptCheck\]]..string.gsub(scriptFilename,"%.lua",""):gsub("%.LUA","")..[[.LUAC_Script.lua*]])
  else
    print("   @@@ Done without problem")
  end
  print("")
  os.remove(tmpScriptLUACFileName)
  -- +++++++++ END: _mLUAC ++++++++
  
  -- +++++++++ Scanning script for container ++++++++
  -- if Container_info == nil then dofile("Container_info.lua") end
  
  --let us try to find the start and end of NMS_MOD_DEFINITION_CONTAINER
  local containerStartLine = 0 --easy
  local containerEndLine = 0   --harder if some code after with tables in it
  
  -- local scriptTable = H.ParseTextFileIntoTable(scriptFilenamePath)
  
  -- if #scriptTable == 1 then
    -- H.pv("       > This script file is encoded with CR only, special handling invoked!")
    -- local filehandle = io.open(scriptFilenamePath,"rb")
    -- if filehandle then
      -- local lines = filehandle:read("l")
      -- scriptTable = lines:splitB("\r")
      -- filehandle:close()
    -- end
    -- script = string.gsub(script,"\r","\n")
  -- end
  
  -- H.printf("#scriptTable = %d",#scriptTable)
  for i=1,#scriptTable do
    local t = H.trim(scriptTable[i])
    -- if string.find(t,"NMS_MOD_DEFINITION_CONTAINER",1,true) then
      -- print(i,t)
    -- end
    if string.find(t,"NMS_MOD_DEFINITION_CONTAINER",1,true) == 1 then
      containerStartLine = i
      break
    end
  end
  
  -- local S_msg_floor_division = false --NMS_MOD_DEFINITION_CONTAINER["S_FLOOR_DIV"]
  -- for i=1,#scriptTable do
    -- local t = H.trim(scriptTable[i])
    -- if string.find(t,"AMUMSS_SUPPRESS_MSG",1,true) == 1 then
      -- if string.find(t,"SUPPRESS_FLOOR_DIV",1,true) == 1 then
        -- S_msg_floor_division = true
      -- end
    -- end
  -- end
  
  local openBracketCount = 0
  local closeBracketCount = 0
  -- local BracketLevel = 0
  local foundContainer = false
  local modified = false
  
  print("   @@@ Scanning script for container...")
  
  --***************************************************************************************************
  local function isBalanced(s,t)
    --Lua pattern matching has a 'balanced' pattern that matches sets of balanced characters.
    --Any two characters can be used.
    checkFor = '%b'..t
    print(checkFor)
    print(s:gsub(checkFor,'')=='')
    return s:gsub(checkFor,'')=='' and true or false
  end
  --***************************************************************************************************
  
  -- local IsScriptSingleQuotesBalanced = isBalanced(script,[['']])
  -- print(string.format([[       Are script '' balanced? %s]],IsScriptSingleQuotesBalanced))
  -- local IsScriptDoubleQuotesBalanced = isBalanced(script,[[""]])
  -- print(string.format([[       Are script "" balanced? %s]],IsScriptDoubleQuotesBalanced))
  -- local IsScriptSquareBalanced = isBalanced(script,"[]")
  -- print(string.format("       Are script [] balanced? %s",IsScriptSquareBalanced))
  -- local IsScriptCurlyBalanced = isBalanced(script,"{}")
  -- print(string.format("       Are script {} balanced? %s",IsScriptCurlyBalanced))
  -- print("")
  
  local S_msg_floor_division = false
  local S_msg_multiple_statements = false
  local S_msg_unused_variable = false
  local S_msg_undefined_variable = false
  local S_msg_mixed_table = false
  H.S_msg_number_to_string = false
  
  -- for i=containerStartLine,#scriptTable do
    -- local t = H.trim(scriptTable[i])
    -- if string.find(t,"AMUMSS_SUPPRESS_MSG",1,true) then
      -- if string.find(t,"SUPPRESS_FLOOR_DIV",1,true) then
        -- S_msg_floor_division = true
      -- end
      -- if string.find(t,"MULTIPLE_STATEMENTS",1,true) then
        -- S_msg_multiple_statements = true
      -- end
    -- end
  -- end
  
  local longCommentFound = false
  local numOfEqualSign = 0
  for i=containerStartLine,#scriptTable do
    local skip = false
    if scriptTable[i] then
      local t = H.trim(scriptTable[i]):upper()
      
      if longCommentFound then
        --a long comment start was found, were does it end
        
        --does it ends on this line?
        local searchSign = "]"..string.rep("=",numOfEqualSign).."]" --to match the opening one
        if string.find(t,searchSign,1,true) then
          --long comment ending on this line
          longCommentFound = false
          -- print("         ending ]] at line "..i..": <"..t..">")
          
          local commentEndCol = string.find(t,searchSign,1,true) + #searchSign + 2
          t = string.sub(t,commentEndCol)
          
        else
          --skip the line, it is still part of the long comment
          skip = true
        end
        
      else
        -- if string.find(t,"--%[") then
          -- print("A: is it '--[' at line "..i..": <"..t..">")
        -- end
        if string.find(t,"%-%-%[=*%[") then
          --start of a long comment on this line
          -- print("A: detected '--[[' at line "..i..": <"..t..">")
          
          --how many '=' are there?
          numOfEqualSign = #string.match(t,"%-%-%[(=*)%[")
          -- H.printf("     numOfEqualSign = %d",numOfEqualSign)
          
          --does it ends on the same line?
          local searchSign = "]"..string.rep("=",numOfEqualSign).."]" --to match the opening one
          if not string.find(t,searchSign,1,true) then
            --not ending on the same line
            --signal to look for the end of the long comment down the file
            longCommentFound = true
          end
          
          --no skip, we still check if we find brackets before the comment
          local commentStartCol = string.find(t,"--",1,true)
          t = string.sub(t,1,commentStartCol - 1)
          -- print("A: t = ["..t.."] on line "..i)
        end
      end
      
      if not longCommentFound then
        if string.sub(t,1,2) == "--" then
          --a short comment at the start of the line, skip line
          skip = true
          
        elseif string.find(t,"--",1,true) then
          --there is a short comment somewhere in this line, remove from the comment to end of line
          local commentStartCol = string.find(t,"--",1,true)
          t = string.sub(t,1,commentStartCol - 1)
        end
      end
      
      if not skip then
        --how many { and } on this line?
        local _,n = string.gsub(t,"{","{")
        -- print("B: { = ["..n.."] on line "..i)
        openBracketCount = openBracketCount + n
        
        local _,n = string.gsub(t,"}","}")
        -- print("B: } = ["..n.."] on line "..i)
        closeBracketCount = closeBracketCount + n
        
        if not foundContainer and (openBracketCount > 0 and (closeBracketCount == openBracketCount)) then
          --we have reach the end of the container or the container is malformed
          foundContainer = true
          containerEndLine = i
          print("       > CONTAINER found at lines "..containerStartLine.."-"..containerEndLine.." (found "..closeBracketCount.." {} pairs)")
          print("       > CONTAINER will be further analyzed...")
        end
        
        if string.find(t,"AMUMSS_SUPPRESS_MSG",1,true) then
          if string.find(t,"SUPPRESS_FLOOR_DIV",1,true) then
            S_msg_floor_division = true
          end
          if string.find(t,"MULTIPLE_STATEMENTS",1,true) then
            S_msg_multiple_statements = true
          end
          if string.find(t,"UNUSED_VARIABLE",1,true) then
            S_msg_unused_variable = true
          end
          if string.find(t,"UNDEFINED_VARIABLE",1,true) then
            S_msg_undefined_variable = true
          end
          if string.find(t,"MIXED_TABLE",1,true) then
            S_msg_mixed_table = true
          end
          if string.find(t,"NUMBERTOSTRING",1,true) then
            H.S_msg_number_to_string = true
          end
        end
        
      end
    end
  end
  
  if openBracketCount == 0 then
    --we have reach the end of the file and not found the container
    print("       > CONTAINER starts at line "..containerStartLine)
    print("       > CONTAINER not found!")
    H.SetReportData(H.DelayedReportData,"","CONTAINER starts at line "..containerStartLine)
    H.SetReportData(H.DelayedReportData,"","CONTAINER end not found","WARNING")
    problemFound = true
  end
  
  if openBracketCount > 0 and (closeBracketCount ~= openBracketCount) then
    --we have reach the end of the file and the container is malformed
    print("       > Ended file scan with "..openBracketCount.." '{' and "..closeBracketCount.." '}' brackets")
    H.SetReportData(H.DelayedReportData,"","Ended file scan with "..openBracketCount.." '{' and "..closeBracketCount.." '}' brackets")
    if openBracketCount > closeBracketCount then
      print(H._zBRIGHTRED.."       > Check for some missing '}' or extra '{' "..H._zDEFAULT)
      H.SetReportData(H.DelayedReportData,"","Check for some missing '}' or extra '{'","WARNING")
    else
      print(H._zBRIGHTRED.."       > Check for some missing '{' or extra '}' "..H._zDEFAULT)
      H.SetReportData(H.DelayedReportData,"","Check for some missing '{' or extra '}'","WARNING")
    end
    print(H._zBRIGHTRED.."       > CONTAINER starts at line "..containerStartLine.."-(ending uncertain)"..H._zDEFAULT)
    print(H._zBRIGHTRED.."       > CONTAINER is malformed!"..H._zDEFAULT)
    H.SetReportData(H.DelayedReportData,"","CONTAINER starts at line "..containerStartLine.."-(ending uncertain)")
    H.SetReportData(H.DelayedReportData,"","CONTAINER is malformed!","WARNING")
    
  end
  
  if containerEndLine == 0 then
    -- modified = true
  end
  print("   @@@ Done")
  print("")
  -- +++++++++ END: Scanning script for container ++++++++
  
  print("   @@@ Basic Syntax Analysis...")
  
  -- check if special function are defined/used
  --  GUIF()
  --  dofile()
  --  GNH()
  
  --***************************************************************************************************
  local function CheckIfRedefined(H,fun)
    if s:sub(1,2) ~= "--" then
      -- not a comment
      s = s:gsub("%s+","") --remove all spaces
      if s:find("localfunction"..fun.."(",1,true) or s:find("function"..fun.."(",1,true) then
        print(H.gcERROR.."       > [ERROR] Redefine of "..fun.."() internal function found, it cannot be defined in your script! "..H._zDEFAULT)
        H.SetReportData(H.H.DelayedReportData,"","Redefine of "..fun.."() internal function found, it cannot be defined in your script!","ERROR")
        return true
      end
    end
    return false
  end
  --***************************************************************************************************
  
  for i=1,#scriptTable do
    local s = H.trim(scriptTable[i])
    if string.find(s,"GUIF",1,true) then
      InternalFunctionProblem = CheckIfRedefined(H,"GUIF")
    elseif string.find(s,"GNH",1,true) then
      InternalFunctionProblem = CheckIfRedefined(H,"GNH")
    elseif string.find(s,"dofile",1,true) then
      InternalFunctionProblem = CheckIfRedefined(H,"dofile")
    elseif string.find(s,"WFAK",1,true) then
      InternalFunctionProblem = CheckIfRedefined(H,"WFAK")
    end
    if InternalFunctionProblem then
      break
    end
  end
  
  -- +++++++++ selene ++++++++
  -- H.printf("type(script) = %s",type(script))
  -- H.printf("#script = %d",#script)
  -- H.printf("#scriptTable = %d",#scriptTable)
  
  if #script > 15000000 then
    print("   @@@ Very Large script detected, skipping Selene checks...")
    H.SetReportData(H.DelayedReportData,"","Very Large script detected, skipping Selene checks...")
  else  
    local tmpScriptFileName = "UserLoadedScript.lua"
    local resultFileName = "UserLoadedScriptCheckResults.lua"
    
    --reset files
    os.remove(tmpScriptFileName)
    os.remove(resultFileName)
    
    H.WriteToFile([[--# selene: allow(unscoped_variables)]].."\n",tmpScriptFileName) --global, adding to block warning: not local in whole file
    H.WriteToFileAppend([[--# selene: allow(shadowing)]].."\n",tmpScriptFileName) --global, adding to block warning: not local in whole file
    --H.WriteToFileAppend([[--# selene: allow(incorrect_standard_library_use)]].."\n",tmpScriptFileName) --global, adding to block warning: not local in whole file
    --H.WriteToFileAppend([[--# selene: allow(unused_variable)]].."\n",tmpScriptFileName) --global, adding to block warning: unused variable in whole file
    
    H.WriteToFileAppend([[-- selene: allow(unused_variable)]].."\n",tmpScriptFileName) --adding to block warning: not used for NMS_MOD_DEFINITION_CONTAINER
    H.WriteToFileAppend([[NMS_MOD_DEFINITION_CONTAINER = {}]].."\n",tmpScriptFileName) --needed for preceding selene block to work
    
    --extra lines in file due to selene
    H.seleneExtraLines = 4
    local extraLines = H.seleneExtraLines + scriptSizeDiff
    -- H.printf("scriptSizeDiff = %d",scriptSizeDiff)
    -- H.printf("    extraLines = %d",extraLines)
    
    -- we do this because selene cannot handle the " - " correctly in a file name, it thinks it is an options flag
    H.WriteToFileAppend(script,tmpScriptFileName) -- script to the tmp file
    
    -- local cmd = [[selene.exe  --display-style="quiet" --config="selene.toml" "]]..tmpScriptFileName..[[">"]]..resultFileName..[["]]
    local cmd = [[selene.exe  --display-style="quiet" "]]..tmpScriptFileName..[[">"]]..resultFileName..[["]]
    -- -- print("["..cmd.."]")
    local r,s,n = os.execute(cmd)
    
    if r == nil then
      local OnFirst = true
      --we need to removed the extra lines from the results file
      local rs = H.ParseTextFileIntoTable(resultFileName)
      
          --***************************************************************************************************
          local function reportSeleneMsg(msg)
            if _mDEBUG then
              print(H._zBRIGHTGREEN.."DEBUG: DISABLED selene msg: "..msg..H._zDEFAULT)
            end
            msg = ""
            return msg
          end
          --***************************************************************************************************
          
      for i=1,#rs - H.seleneExtraLines do --skip last selene lines
        local text = rs[i]
        -- print("rs[i] = <"..rs[i]..">")
        local pos = string.find(text,":",1,true)
        if pos then
          local nAfterFirstColon = pos + 1
          local nLineLength = string.find(string.sub(text,nAfterFirstColon),":",1,true) - 1
          local sLineNum = string.sub(text,nAfterFirstColon,nAfterFirstColon + nLineLength - 1)
          local lineNum = tonumber(sLineNum) - extraLines
          -- print("lineNum = <"..lineNum..">")
          
          local nextPart = string.sub(text,nAfterFirstColon + nLineLength + 1)
          -- print("nextPart = <"..nextPart..">")
          -- rs[i] = string.sub(text,1,nAfterFirstColon - 1)..lineNum..nextPart
          -- print("rs[i] = ["..rs[i].."]")
          
          local nColLength = string.find(string.sub(nextPart,1),":",1,true) - 1
          local sColNum = string.sub(nextPart,1,nColLength)
          -- print("sColNum = <"..sColNum..">")
          local msg = string.sub(nextPart,nColLength + 3)
          -- print("msg = <"..msg..">")
          
          -- disable these
          local IsDisabled = H.gDisableSelene[msg] -- located in LoadHelpers.lua
          -- print("msg = <"..msg..">")
          -- print("IsDisabled = "..tostring(IsDisabled))
          
          if IsDisabled then
            msg = reportSeleneMsg(msg)
          end
          -- END: disable these
          
          -- change these
          if string.find(msg,"notice[unused_variable]: DOFILE is defined, but never used",1,true) then
            msg = "notice[undefined_variable]: Detected 'DOFILE'"
          end
          
          msg = string.gsub(msg,"error%[if_same_then_else%]:","warning[if_same_then_else]:")
          
          if string.find(msg,"error[incorrect_standard_library_use]: ",1,true) then
            msg = string.gsub(msg,"error%[incorrect_standard_library_use%]: use of standard_library function","notice[incorrect_standard_library_use]: maybe argument of another type is more appropriate for")
            msg = string.gsub(msg," is incorrect","")
          end
          
          if string.find(msg,"warning[unused_variable]:",1,true) then
            if not os.getenv("_mUnusedVariable") and S_msg_unused_variable then
              msg = ""
            else
              msg = string.gsub(msg,"warning%[unused_variable%]:","notice[unused_variable]:")
            end
          end
          
          if string.find(msg,"warning[multiple_statements]: only one statement per line is allowed",1,true) then
            if S_msg_multiple_statements then
              msg = ""
            else
              msg = string.gsub(msg,"warning%[multiple_statements%]: only one statement per line is allowed","notice[multiple_statements]: only one statement per line is preferred for debugging clarity")
            end
          end
          
          if string.find(msg,"warning[must_use]:",1,true) then
            -- if S_msg_must_use then
              -- msg = ""
            -- else
              msg = string.gsub(msg,"warning%[must_use%]:","notice[should_use]:")
            -- end
          end
          
          if string.find(msg,"error[undefined_variable]:",1,true) then
            if S_msg_undefined_variable then
              msg = ""
            else
              msg = string.gsub(msg,"error%[undefined_variable%]:","notice[undefined_variable]:")
            end
          end
          
          if string.find(msg,"warning[mixed_table]: mixed tables are not allowed",1,true) then
            if S_msg_mixed_table then
              msg = ""
            else
              msg = string.gsub(msg,"warning%[mixed_table%]: mixed tables are not allowed","notice[mixed_table]: mixed tables can lead to bugs")
            end
          end
          
          if string.find(msg,"error[duplicate_keys]: key `AMUMSS_SUPPRESS_MSG` is already declared",1,true) then
            msg = ""
          end          
          
          -- if string.find(msg,"error[parse_error]: unexpected token `/`",1,true) then
            -- if S_msg_floor_division then
              -- msg = ""
            -- else
              -- msg = string.gsub(msg,"error%[parse_error%]: unexpected token `/`","notice[unexpected token `/`]: please ignore if '//' is really the floor division operator")
            -- end
          -- end
          -- END: change these
          
          if string.find(msg,"error",1,true) then
            possibleProblemFound = true
          end
          
          if msg ~= "" then
            if lineNum > 0 then
              if OnFirst then
                OnFirst = false
                print([[   @@@ Detected these other syntax problems, see also TOOLS\ModScriptCheck folder...]])
                
                if not os.getenv("_mUnusedVariable") then
                  if S_msg_unused_variable then
                    print(H._zBRIGHTGREEN.."       > [unused_variable] detection reporting is OFF"..H._zDEFAULT)
                  end
                else
                  print(H._zBRIGHTGREEN.."       > DEBUG: [unused_variable] detection reporting ENABLED"..H._zDEFAULT)
                end
                -- print("")
              end
              
              print(H._zBRIGHTRED.."       > line "..lineNum..", col "..sColNum..[[: "]]..msg..[["]]..H._zDEFAULT)
              local msgType = string.upper(string.sub(msg,1,string.find(msg,"[",1,true)-1))
              -- print("msgType = <"..msgType..">")
              H.SetReportData(H.DelayedReportData,"","Selene detected @ line "..lineNum..", col "..sColNum..": [["..msg.."]]",msgType)
              
              if string.find(msg,"javascript",1,true) then
                H.SetReportData(H.DelayedReportData,"","'javascript' means a problem happened when the script was copied from a NexusMods POSTS or forums",msgType)
                H.SetReportData(H.DelayedReportData,"","Try to get the script from another source or retry to download the script...",msgType)
              end
            else
              -- probable msg coming from dofile()
            end
          end
        end
      end
      
      -- H.WriteToFile(H.ConvertLineTableToText(rs),[[..\TOOLS\ModScriptCheck\]]..scriptFilename..[[.selene.txt]])
      H.WriteToFile(rs,[[..\TOOLS\ModScriptCheck\]]..scriptFilename..[[.selene.txt]])
      -- H.WFAK("after selene")
    else
      print("   @@@ No other syntax problem detected")
    end
    
    print("   @@@ Done")
    print("")
    printf("   @@@ ********** All done in %s **********",H.dClock(os.clock()-AnalysingStart))
    
    -- os.remove(tmpScriptFileName)
    -- os.remove(resultFileName)
  end
  -- +++++++++ END: selene ++++++++
  
  return problemFound,possibleProblemFound,InternalFunctionProblem,modified,H.DelayedReportData
end

--***************************************************************************************************
function SerializeLoadedScript(H,itemName,thisTable,outTable,  indentLevel,tName,tNameLevel,cMOD,cMCT,cECT,cMFS,IsNewProcessing) -- recursive, tName is needed (even if it is the same as itemName at start)
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strrep = string.rep
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  local tmp = ""
  
  local MOD = ""
  local MCT = ""
  local ECT = ""
  local MFS = ""
  
  local A1 = ""
  local A2 = ""
  local D  = ""
  local F  = ""
  local none = ""
  
  local dP = false -- for DEBUG
  
  if dP then
    A1 = "A1"
    A2 = "A2"
    D  = "D "
    F  = "F "
    none = "  "
  end
  
  indentLevel = indentLevel or 1
  tName = tName or itemName
  tNameLevel = tNameLevel or 1

  cMOD = cMOD or 0
  cMCT = cMCT or 0
  cMFS = cMFS or 0
  cECT = cECT or 0
  
  IsNewProcessing = IsNewProcessing or 0
  
  if dP then outTable[#outTable+1] = "                                                                                                                  1: ==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..itemName.." / "..tName end
  
  local item = ""
  if tonumber(itemName) then
    if tName == "MXML_CHANGE_TABLE" then
      item = " -- item["..itemName.."]"
      cECT = tonumber(itemName)
    elseif tName == "MBIN_CHANGE_TABLE" then
      cMCT = tonumber(itemName)
      cMFS = 1 -- reset
      cECT = 1 -- reset
    elseif tName == "MODIFICATIONS" then
      cMOD = tonumber(itemName)
      cMCT = 1 -- reset
      cMFS = 1 -- reset
      cECT = 1 -- reset
    end
  end

  -- handles '{' only
  if not tonumber(itemName) then
    if itemName == "MBIN_FILE_SOURCE" then
      if IsNewProcessing == 0 then
        -- cMFS = cMFS + 1
        IsNewProcessing = 1 -- mark as found
      else
        IsNewProcessing = 0 -- reset
      end
      if dP then outTable[#outTable+1] = "                                                                                                                  2D:==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..itemName.." / "..tName..": "..IsNewProcessing end
    end
    
    tName = itemName -- to remember the current table name
    tNameLevel = indentLevel -- to rememeber the current table name level
    
    -- processing MODIFICATIONS[1][144][1][1], please wait...
    -- processing MODIFICATIONS["..modificationIndex.."]["..MBINchangeTableIndex.."]["..EXMLchangeTableIndex.."]["..item.."]
    --  MOD    modificationIndex           ,n
    --  MCT    MBINchangeTableIndex        ,m
    --  ECT    EXMLchangeTableIndex        ,u
    --         EXMLchangeTable[item]       ,i

    if tName == "MODIFICATIONS" then
      cMOD = cMOD + 1
      if dP then outTable[#outTable+1] = "                                                                                                                  2A:==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..itemName.." / "..tName end
    
    elseif tName == "MBIN_CHANGE_TABLE" then
      -- cMCT = cMCT + 1
      cMFS = 1 -- reset
      if dP then outTable[#outTable+1] = "                                                                                                                  2B:==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..itemName.." / "..tName end
    
    elseif tName == "MXML_CHANGE_TABLE" and itemName == "MXML_CHANGE_TABLE" then      
      if IsNewProcessing == 0 then
        -- cMFS = cMFS + 1
        IsNewProcessing = 1 -- mark as found
      else
        IsNewProcessing = 0 -- reset
     end
     if dP then outTable[#outTable+1] = "                                                                                                                  2C:==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..itemName.." / "..tName..": "..IsNewProcessing end
    end
    
    if tName == "MXML_CHANGE_TABLE" then
      -- create a processing line between each sub-table of MXML_CHANGE_TABLE with peocessing info        
      MOD = "["..cMOD.."]"
      MCT = "["..cMCT.."]"
      MFS = "["..cMFS.."]"
      ECT = "["..cECT.."]"
      outTable[#outTable+1] = A1..strrep(" --",indentLevel - 2).." -- processing"..MOD..MCT..ECT -- ..MFS)
    end
    
    outTable[#outTable+1] = A2..strrep(".  ",indentLevel - 2)..itemName.." = {"
    indentLevel = indentLevel + 1
    
    if type(thisTable) == "table" then
      if type(thisTable[1]) == "table" then
        -- a TABLE OF TABLES
        indentLevel = indentLevel + 1
      end
    end
    
  else
    if tonumber(itemName) > cMFS then
      cMFS = tonumber(itemName)
    end
    
    indentLevel = indentLevel - 2
    outTable[#outTable+1] = D..strrep(".  ",indentLevel - 2).."{"..item -- "{  --+++")
  end
  -- END: handles '{' only
  
  -- handles all fields
  for key,v in pairs(thisTable) do
    local info = ""
    if not tonumber(key) then
      info = key.." = "
    end

    local tv = type(v)
    if tv == "table" then
      indentLevel = indentLevel + 1
      cMOD,cMCT,cECT,cMFS = SerializeLoadedScript(H,key,v,outTable,  indentLevel,tName,tNameLevel,cMOD,cMCT,cECT,cMFS,IsNewProcessing) --recursive
      indentLevel = indentLevel - 1

    elseif tv == "nil" then
        outTable[#outTable+1] = none..strrep(".  ",indentLevel-1)..info.."nil,"
        
    elseif tv == "string" then
        v = strgsub(v,[[\\]],[[\]]) --remove \\ in [[...]] strings
-- outTable[#outTable+1] = "==> v = <"..v..">"
        
        local text_to_add = H.stringToTable(v:gsub([[\\]],[[\]])) -- change \\ to \ in the string
        if #text_to_add > 0 then
          -- handle long-strings
-- outTable[#outTable+1] = "==> <going into pqr loop>"
          outTable[#outTable+1] = none..strrep(".  ",indentLevel-1)..info.."[["
          for pqr=1,#text_to_add do
-- outTable[#outTable+1] = "==> <"..pqr..">: <"..text_to_add[pqr]..">"
            outTable[#outTable+1] = none..text_to_add[pqr]
          end
          outTable[#outTable+1] = none..strrep(".  ",indentLevel-1).."]],"
        
        else
          outTable[#outTable+1] = none..strrep(".  ",indentLevel-1)..info.."[["..v.."]],"
        end

        if key == "MBIN_FILE_SOURCE" and tName == "MBIN_CHANGE_TABLE" then
          if IsNewProcessing == 0 then
            -- cMFS = cMFS + 1
            IsNewProcessing = 1 -- mark as found
          else
            IsNewProcessing = 0 -- reset
          end
          if dP then outTable[#outTable+1] = "                                                                                                                  3B:==> cMOD= "..cMOD.." cMCT= "..cMCT.." cECT= "..cECT.." cMFS= "..cMFS.." | "..key.." / "..itemName.." / "..tName..": "..IsNewProcessing end
        end
      
    elseif tv == "number" then
        outTable[#outTable+1] = none..strrep(".  ",indentLevel-1)..info..tostring(v)..","
      
    elseif tv == "boolean" then
        local value
        if v then
          value = "[[true]],"
        else
          value = "[[false]],"
        end
        outTable[#outTable+1] = none..strrep(".  ",indentLevel-1)..info..value
    end
      
  end
  -- END: handles all fields
  
  -- handles '}' only
  if H.trim(tmp) == "}," then
    indentLevel = indentLevel - 1
  end
  
  if type(thisTable) == "table" then
    if type(thisTable[1]) == "table" then
      -- a TABLE OF TABLES
      indentLevel = indentLevel - 2
    end
  end
  
  outTable[#outTable+1] = F..strrep(".  ",indentLevel - 2).."}," --"}, --<<<")
  -- END: handles '}' only
  
  return cMOD,cMCT,cECT,cMFS,IsNewProcessing
end
--*************** END: SerializeLoadedScript  *******************************************************

--***************************************************************************************************
function PostProcessing(H,outTable)
  -- H.printf("In PostProcessing, #outTable = %d",#outTable)
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strrep = string.rep
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  --***************************************************************************************************
  local function concatenate_1(outTable,i,IsConcatenate,offset)
    -- do
      -- return i
    -- end
-- printf("   offset = %s",tostring(offset))
-- H.DPType("offset",offset)
    
    -- H.printf("In concatenate_1: line %d <%s>",i, outTable[i])
    local Start = os.clock()
    -- a table of strings
    -- H.printf("      %2d: outTable[i] = [%s]",i,outTable[i])
    local offset = offset or 0
-- printf("   offset = %s",tostring(offset))
-- H.DPType("offset",offset)
        
    if IsConcatenate == nil then
      IsConcatenate = true
    end
    
    local ss = ""
    if IsConcatenate then
-- print("a0:   remove eol")
      ss = outTable[i]:sub(1,-1) -- remove eol
      -- if ss == "  " then
        -- ss = ""
      -- end
-- printf("a0:   ss = <%s>",tostring(ss))
    else
      ss = outTable[i].."\n"
    end
    
    -- print("ss = ["..ss.."]")
    local nextLine = false
    local lineNum = i
    
    -- print(" ~ ~ ~ ~ ~")
    -- for j=i+1,#outTable do
      -- printf("%d: <%s>",j,outTable[j])
    -- end
    -- print(" ~ ~ ~ ~ ~")
    
    for j=i+1,#outTable do
      local tt = outTable[j]

-- printf("b0:   tt = <%s> on line %d",tostring(tt),j)
      if tt == "  " then
        tt = ""
      end
-- printf("b0:   tt = <%s>",tostring(tt))

      if tt:find("},",1,true) then
        -- end of the table
        if IsConcatenate then
          outTable[i] = ss:sub(1,-1).."},"
        else
-- printf("   offset = %s",tostring(offset))
-- H.DPType("offset",offset)
-- offset = math.ceil(offset)
-- printf("   offset = %s",tostring(offset))
-- H.DPType("offset",offset)
          outTable[i] = ss:sub(1,-1)..strrep("  .",offset).."  },"
        end
        -- blank the line
        outTable[j] = ""
        lineNum = j
        break
        
      else
        -- all other lines
        if IsConcatenate then
          ss = ss..tt:gsub(".  ",""):sub(1,-1)
-- printf("b1:   ss = <%s>",tostring(ss))
          -- ss = ss:gsub("{  ","{"):gsub(",  ",", ")
-- printf("b1:   ss = <%s>",tostring(ss))
        else
          ss = ss..tt.."\n"
          ss = ss:gsub("{  ","{"):gsub(",  ",", ")
        end
        -- blank the line
        outTable[j] = ""
      end
    end
    -- H.printf("           >>> end concatenate_1 in "..H.dClock(os.clock() - Start))
    return lineNum
  end
  --***************************************************************************************************
  
  -- local Start = os.clock()

  -- print(" ~ ~ ~ ~ ~")
  -- for j=1,#outTable do
    -- printf("%d: <%s>",j,outTable[j])
  -- end
  -- print(" ~ ~ ~ ~ ~")
  
  local i = 1
  repeat
    local s = outTable[i]
    if s ~= "" then
      -- H.printf("%4d, outTable[i] = #%s#",i,s)
      if s:find("SPECIAL_KEY_WORDS = {") or s:find("SKW = {") then
        i = concatenate_1(outTable,i)
      end
      
      if s:find("PRECEDING_KEY_WORDS = {") or s:find("PKW = {") then
        i = concatenate_1(outTable,i)
      end
      
      if s:find("SECTION_ACTIVE = {") then
        i = concatenate_1(outTable,i)
      end
      
      if s:find("MBIN_FILE_SOURCE = {") or s:find("MBIN_FS = {") then
        if outTable[i+1]:find("{",1,true) then
          -- a table of sub-tables, process next lines
          repeat
            i = concatenate_1(outTable,i+1)
            -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
          until strsub(outTable[i+1],-1) ~= "{"
        else
          -- a table of strings
          if s:find("MBIN_FILE_SOURCE = {") then
            local offset = math.ceil((s:find("MBIN_FILE_SOURCE = {") - 3) / 3)
-- printf("offset = %s",tostring(offset))
-- H.DPType("offset",offset)
            i = concatenate_1(outTable,i,true,offset)
          elseif s:find("MBIN_FS = {") then
            local offset = math.ceil((s:find("MBIN_FS = {") - 3) / 3)
            i = concatenate_1(outTable,i,true,offset)
          end
        end
      end
      
      if s:find("DATA = {") then
        -- if outTable[i+1]:find("{",1,true) then
          -- a table of sub-tables, process next lines
          repeat
            i = concatenate_1(outTable,i+1)
            -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
          until strsub(outTable[i+1],-1) ~= "{"
        -- else
          -- -- a table of strings
          -- local offset = math.ceil((s:find("EXML_DATA = {") - 3) / 3)
-- -- printf("offset = %s",tostring(offset))
-- -- H.DPType("offset",offset)
          -- i = concatenate_1(outTable,i,false,offset)
        -- end
      end
      
      if s:find("VALUE_CHANGE_TABLE = {") or s:find("VCT = {") then
        -- a table of sub-tables, process next lines
        repeat
          -- H.printf("   %4d: outTable[i+1] = <%s>",i,outTable[i+1])
          i = concatenate_1(outTable,i+1)
          -- H.printf("   %4d: outTable[i+1] = <%s>, strsub(outTable[i+1],-1) = <%s>",i,outTable[i+1],strsub(outTable[i+1],-1))
        until i == #outTable or strsub(outTable[i+1],-1) ~= "{"
      end
      
      if s:find("WHERE_IN_SECTION = {") or s:find("WIS = {") then
        -- a table of sub-tables, process next lines
        repeat
          i = concatenate_1(outTable,i+1)
          -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
        until i == #outTable or strsub(outTable[i+1],-1) ~= "{"
      end
      
      if s:find("WHERE_IN_SUBSECTION = {") or s:find("WISS = {") then
        -- a table of sub-tables, process next lines
        repeat
          i = concatenate_1(outTable,i+1)
          -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
        until i == #outTable or strsub(outTable[i+1],-1) ~= "{"
      end
      
      if s:find("FOREACH_SKW_GROUP = {") or s:find("FSKWG = {") then
        -- a table of sub-tables, process next line
        repeat
          i = concatenate_1(outTable,i+1)
          -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
        until i == #outTable or strsub(outTable[i+1],-1) ~= "{"
      end
      
      -- Wbertro: no need to format ADD_FILES
      -- if s:find("ADD_FILES = {") then
        -- -- a table of sub-tables, process next lines
        -- repeat
          -- i = concatenate_1(outTable,i+1)
          -- -- H.printf("   %4d: outTable[i+1] = [%s], strsub(outTable[i+1],-1) = [%s]",i,outTable[i+1],strsub(outTable[i+1],-1))
        -- until i == #outTable or strsub(outTable[i+1],-1) ~= "{"
      -- end
      
    end
    
    i = i + 1
  until i > #outTable
  
  -- print(" = = = = =")
  -- for j=1,#outTable do
    -- printf("%d: <%s>",j,outTable[j])
  -- end
  -- print(" = = = = =")
  
  -- H.printf("           >>> end loop in "..H.dClock(os.clock() - Start))
  -- refresh outTable
  local tmp = {}
  for i=1,#outTable do
    local s = outTable[i]
    if s ~= "" and s then
      tmp[#tmp+1] = ( s:gsub([[%.  ]],[[   ]]) )
    end
  end
  
  -- print(" - - - - -")
  -- for j=1,#tmp do
    -- printf("%d: <%s>",j,tmp[j])
  -- end
  -- print(" - - - - -")
  
  return tmp
end
--************* END: PostProcessing ******************************************************************

--********************************  OpenUserScript()  *************************************************
function OpenUserScript(H)
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strmatch = string.match
    local strupper = string.upper
    local strrep = string.rep
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  local success = false
  
  --***************************************************************************************************
  local function load_conf(x)
    local env = {
      GetEnvInfo = H.GetEnvInfo,
      GNH = H.GNH,
      GUIF = H.GUIF,
      NormalizePath = H.NormalizePath,
      WFAK = H.WFAK,
      GetLargeHex = H.GetLargeHex,
      printf = H.printf, --function(s,...) print(string.format(s,...)) end,
      lfs = {currentdir=lfs.currentdir,attributes=lfs.attributes,dir=lfs.dir,},
      assert = assert,
      coroutine = coroutine,
      getmetatable = getmetatable ,
      io = {open=io.open,type=io.type,input=io.input,read=io.read,close=io.close,lines=io.lines,},
      ipairs = ipairs,
      math = math,
      next = next,
      os = {clock=os.clock,date=os.date,difftime=os.difftime,time=os.time,tmpname=os.tmpname,getenv=os.getenv,},
      pairs = pairs,
      pcall = pcall,
      print = print,
      select = select,
      setmetatable = setmetatable,
      string = string,
      table = table,
      tonumber = tonumber,
      tostring = tostring,
      type = type,
      xpcall = xpcall,
    } --user can use anything inside this new environment in the user script
    
    if x then
      env.DPType = H.DPType
      env.H = H
    end
    
-- for k,v in pairs(env) do
  -- printf("k=<%s>, v=<%s>",k,v)
-- end

    local scriptFilenamePath = H.LoadFileData("CurrentModScript.txt")
    local scriptFilename = H.GetFilenameFromFilePath(scriptFilenamePath)
    
    os.remove([[..\TOOLS\ModScriptCheck\]]..scriptFilename..[[.selene.txt]]) --try to delete the last analysis
    
    local script = H.LoadFileData(scriptFilenamePath) -- loaded as one string
    local scriptORG = script
    
    --for backward compatibility
    script = strgsub(script,[[REPLACE_AFTER_ENTRY]],[[PRECEDING_KEY_WORDS]])
    script = strgsub(script,[[ADDSECTION]],[[ADDAFTERSECTION]])
    
    --***************************************************************************************************
    local function CorrectEscape(script)
      -- WARNING: causes side-effect for some strings like COMMENT, MBIN_FS and inside user comments
      
      -- makes \ inside a "" a \\ if used by the user (bad usage)
      -- unless it is for "\"" which we change to string.char(1)
      -- reverts any doubling of double \\
      -- VERY FAST version
      -- return strgsub(script,[[\]],[[\\]]):gsub([[\\\\]],[[\\]])
      return strgsub(script,[[\"]],string.char(1)):gsub([[\]],[[\\]]):gsub([[\\\\]],[[\\]])
    end
    --***************************************************************************************************
    
    script = CorrectEscape(script)
    
    -- end-of-line encoding: DOS = \r\n, MAC = \r, Unix = \n
    local scriptTable = strgsub(script,"\r\n","\n"):gsub("\r","\n"):splitB("\n")
    -- H.printf("#scriptTable = %d",#scriptTable)
    local scriptSizeBefore = #scriptTable
    -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." $$$ #scriptTable = "..#scriptTable.." (%.0fKB)",collectgarbage("count"))
    
    -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." $$$ START dofile() processing".." (%.0fKB)",collectgarbage("count"))
    -- search for dofile()
    local IsFoundDO_FILE = false
    local DO_FILEcount = 0
    
    printQ = function() end
    -- printQ = print
    repeat -- kind-of-recursive
      local i = 0
      IsFoundDO_FILE = false
      while i ~= #scriptTable do
        i = i + 1
        -- A) anchor to beginning of line
        -- B) allow only spaces before dofile(...)
        -- C) allow spaces in path and filename
        local helperScript = scriptTable[i]:match("^%s*dofile%([\'\"%[]+([%g%s]-)[\'\"%]]+%)")
        local state = ""
        
        if helperScript then
          helperScript = strgsub(strgsub(helperScript,[[%%AMUMSS_PATH%%]],H.gMASTER_FOLDER_PATH),[[/]],[[\]])
          
          local thisDOFILEexist = true
          printQ("QQQQQQ_0 scriptTable[i] = ["..scriptTable[i].."]")
          IsFoundDO_FILE = true
          DO_FILEcount = DO_FILEcount + 1
          
          local defaultPath = [[..\ModScript\ModHelperScripts\]]
          if helperScript:find(".:") then
            -- use provided full path
            state = "_F"
            printQ("   QQQQQQ_1 Using FULL path = ["..helperScript.."]")
            defaultPath = ""
            thisDOFILEexist = H.IsFileExist(helperScript)
            
          else
            printQ("   QQQQQQ_2 Using RELATIVE path")
            -- CurrentPath is always AMUMSS\MODBUILDER
            
            local scriptPath = H.GetFolderPathFromFilePath(H.LoadFileData("CurrentModScript.txt"))..[[\]]
            printQ("                scriptPath = ["..scriptPath.."]")
            
            if H.IsFileExist(scriptPath..helperScript) then
              -- path is relative to script
              state = "_S"
              printQ("      QQQQQQ_2A Using RELATIVE path to script = ["..helperScript.."]")
              defaultPath = scriptPath
              printQ("                new defaultPath = ["..defaultPath..helperScript.."]")
            
            elseif H.IsFileExist(scriptPath..[[ModHelperScripts\]]..helperScript) then
              -- path is relative to scriptPath in ModHelperScripts folder
              state = "_M"
              printQ("      QQQQQQ_2B Using RELATIVE path to ModFolder\\ModHelperScripts = ["..scriptPath..[[ModHelperScripts\]]..helperScript.."]")
              defaultPath = scriptPath..[[ModHelperScripts\]]
              printQ("                new defaultPath = ["..defaultPath..helperScript.."]")
            
            elseif H.IsFileExist(defaultPath..helperScript) then
              -- path is relative to defaultPath
              state = "_D"
              printQ("      QQQQQQ_2C Using RELATIVE path to ModScript\\ModHelperScripts = ["..defaultPath..helperScript.."]")
            
            else
              -- cannot find file, issue WARNING
              printQ("      QQQQQQ_3 file not found")
              thisDOFILEexist = false
            end
          end
          
          if thisDOFILEexist then
            scriptTable[i] = "-- Loaded"..state.." <"..defaultPath..helperScript..">\n"..CorrectEscape(H.LoadFileData(defaultPath..helperScript)).."\n-- END: <"..defaultPath..helperScript..">"
            print("    - Loaded ("..state..") <"..defaultPath..helperScript..">")
          else
            scriptTable[i] = "-- Could NOT LOAD/FIND dofile() file: <"..scriptTable[i].."> SKIPPING"
            print(">>> "..H.gcWARNING.." [WARNING] "..strsub(scriptTable[i],4).." "..H._zDEFAULT)
            H.SetReportData(H.DelayedReportData,"",strsub(scriptTable[i],4),"WARNING")
          end
        end
      end
      
      if IsFoundDO_FILE then
        -- unwind script to get recursive effect
        scriptTable = table.concat(scriptTable,"\n"):gsub("\r\n","\n"):gsub("\r","\n"):splitB("\n")
      end
    until not IsFoundDO_FILE
    
-- H.printf("#scriptTable = %d",#scriptTable)
    local scriptSizeAfter = #scriptTable
    local scriptSizeDiff = scriptSizeAfter - scriptSizeBefore
    -- H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." $$$ END dofile() processing (%.0fKb)",collectgarbage("count"))

-- print(" = = = = = = =")
-- for i=1,#scriptTable do
  -- printf("%d: [%s]",i,scriptTable[i])
-- end    
-- print(" = = = = = = =")

    -- reintegrate all parts into the script string
    script = table.concat(scriptTable,"\n")
    script = CorrectEscape(script)
        
    --prevent the use of :write in the script (prevent injection)
    -- io.write is already blocked by 'env' table
    if strfind(script,[[:write]],1,true) then
      -- local scriptTable = script:splitB("\n")
      for i=1,#scriptTable do
        if strfind(scriptTable[i],[[:write]],1,true) then
          if strsub(H.trim(scriptTable[i]),1,2) ~= [[--]] then
            return {}, "XXXXX <not allowed> Lua keyword in used on line "..i.." of the script XXXXX"
          end
        end
      end
    end
    
    local problemFound = false
    local possibleProblemFound = false
    local InternalFunctionProblem = false
    local modified = false
    
    if x then
      print()
      print(H._zWHITEonDARKCYAN.."$$$$$$$$$$$$$$$$$  DEBUG_ON"..H._zDEFAULT)
      env.DPType = H.DPType
      env.H = H
      
      if strfind(script,[[H.]],1,true) then
        print("   "..H.gcWARNING.." [WARNING] Script may be using 'H.functions'! "..H._zDEFAULT)
        beep(1000,150)
        beep(250,250)
      end
    end
    
    if H._bTestScript then
      problemFound,possibleProblemFound,InternalFunctionProblem,modified = --,H.DelayedReportData
          AnalyzeScript(H, script, scriptTable, scriptFilename, scriptFilenamePath, scriptSizeDiff) --,H.DelayedReportData
    else
      print("   "..H.gcNOTICE.." SKIPPED testing script! "..H._zDEFAULT)
      H.SetReportData(H.DelayedReportData,"","SKIPPED testing script!","")
    end
    
-- print(" @ @ @ @ @ @ @")
-- for i=1,#scriptTable do
  -- printf("%d: [%s]",i,scriptTable[i])
-- end    
-- print(" @ @ @ @ @ @ @")

    if problemFound or possibleProblemFound then
      print("")
      print("  "..H.gcNOTICE.." [NOTICE] Some problem/warning found by analyzing the script (see above)... "..H._zDEFAULT)
      if modified then
        print("  "..H.gcNOTICE.."         We may have MODIFIED the script to help pinpoint the problem "..H._zDEFAULT)
        print("  "..H.gcNOTICE.."         Please retry it to get further guidance! "..H._zDEFAULT)
      else
        print("  "..H.gcNOTICE.."         You could need to correct it and retry! "..H._zDEFAULT)
      end
      print("")
    end
    
    -- Save script extended version as .luax
    H.WriteToFile(script: gsub(string.char(1),[[\"]]):gsub([[\\]],[[\]]), scriptFilenamePath.."x") -- .luax
    -- H.WFAK("Created .luax in script folder...")

    -- To be used if you want to inspect the loaded script
    if _mDEBUG then
      print("WWW _mDEBUG is ACTIVE MMM")
      print(lfs.currentdir())
      H.WriteToFile(script, [[..\TempScript.lua]]) -- same content as 'scriptname'.luax without :gsub([[\\]],[[\]])
      H.WriteToFile(scriptORG, [[.\ScriptsORG\]]..scriptFilename) -- EXACT same content as the ORIGINAL 'scriptname'.lua
      H.WriteToFile(script:gsub([[\\]],[[\]]), [[.\ScriptsUsed\]]..scriptFilename) -- same content as 'scriptname'.luax with :gsub([[\\]],[[\]])
      H.WFAKD([[ ==> script (..\TempScript.lua), scriptORG (.\ScriptsORG\scriptFilename) and script (.\ScriptsUsed\scriptFilename) created]])
    end
    
    -- if not problemFound then
      -- print(">>> Creating script Hash...")
      -- local sha1 = require 'sha1'
      -- Hash = sha1.hex(strsub(script,1,#script - 40))
      
      -- H.gSCRIPTBUILDERscript = (Hash == strsub(script,#script - 39))
      -- if H.gSCRIPTBUILDERscript then print("A SCRIPTBUILDER script!") end
    -- end
    
    local scriptStringName = "User Script"
    
    --***************************************************************************************************
    local function MyErrHandler(x)
      -- copy raw script for user (* required to indicate a file)
      H.CopyFile("UserLoadedScript.lua",[[..\TOOLS\ModScriptCheck\]]..strgsub(scriptFilename,"%.lua",""):gsub("%.LUA","")..[[.RawScript.lua*]])
      
      local line = tostring(tonumber(strmatch(x,":(%d+):")) + H.seleneExtraLines)
      local g = strgsub(x,"^(.-:).-(:.-)$","%1"..line.."%2")

      -- -- print("")
      -- local y1 = strsub(x,13 + #scriptStringName)
      -- -- printf("y1 = <%s>",y1)
      -- local p = strfind(y1,":",1,true)
      -- if p then
        -- -- printf(" p = <%d>",p)
        -- local z = strsub(y1,1,p-1)
        -- -- printf("z = <%s>",z)
        -- if tonumber(z) then
          -- local y2 = strsub(y1,p)
          -- -- printf("y2 = <%s>",y2)
          -- z = tostring(tonumber(z) + H.seleneExtraLines)
          -- x = "[string "..scriptStringName.."]:"..z..y2
        -- end
      -- end
      
      print(H.gcERROR.." Lua Script error: "..g.." "..H._zDEFAULT)
      print("                       "..H.gcNOTICE..[[ line number above ^ refers to TOOLS\ModScriptCheck\]]..strgsub(scriptFilename,"%.lua",""):gsub("%.LUA","")..[[.RawScript.lua ]]..H._zDEFAULT)
      H.SetReportData(H.DelayedReportData,"","Lua Script error: "..x,"ERR")
      -- print(debug.traceback(nil,0))
      -- H.Report("", debug.traceback(nil,0),"ERR")
      H.LuaEndedOk(H.THIS)
    end
    --***************************************************************************************************
    
    -- --***************************************************************************************************
    -- local function GetScript()
      -- return load(script,"User Script",'t',env)
    -- end
    
    H.scriptInternalCodeStart = os.clock()
    if not problemFound and not InternalFunctionProblem then
      print("\n>>> Loading script...")

      H.scriptInternalCodeStart = os.clock()
      print("\n"..H._zBRIGHTGREEN.."    vvvvvvvv Running "..H._zBRIGHTORANGE.."script internal code..."..H._zDEFAULT)
      
      -- revert before load
      script = strgsub(script,string.char(1),[[\"]])
      
      success, chunk = xpcall(load(script, scriptStringName, 't', env), MyErrHandler) --better
      -- local chunk, failure = load(script,"User Script",'t',env)
      
      if success then
          -- chunk()
      elseif chunk then
        print("")
        print("Lua is reporting: "..chunk)
        H.Report("","Lua is reporting: "..chunk,"ERR")
      else
        -- print("Problem Loading script")
      end
    else
      success = false
    end
    
    return env, chunk, success, InternalFunctionProblem
  end
  --***************************************************************************************************
  
  --###################  MAIN CODE  ###################################
  local load_start = os.clock()
  local conf,status,success,InternalFunctionProblem = load_conf(DEBUG_ON)
  local internalTime = H.dClock(os.clock() - H.scriptInternalCodeStart)
  printf(H._zBRIGHTGREEN.."    ^^^^^^^^ Done running "..H._zBRIGHTORANGE.."script internal code in %s"..H._zDEFAULT.."\n",internalTime)
  H.SetReportData(H.DelayedReportData,"","    ^^^^^^^^ Done running script internal code in "..internalTime)
  
  if success then
    if not conf.NMS_MOD_DEFINITION_CONTAINER or conf.NMS_MOD_DEFINITION_CONTAINER == "" or type(conf.NMS_MOD_DEFINITION_CONTAINER) ~= "table" or next(conf.NMS_MOD_DEFINITION_CONTAINER) == nil then
      success = false
    end
  end
  
  -- if status == nil or status == false then --only use this if not using pcall above
  if success then --use this if using pcall above
    local msg1 = "USER"
    if H.gSCRIPTBUILDERscript then
      msg1 = "SCRIPTBUILDER"
    end
    
    print(">>> [INFO]"..H._zBRIGHTGREEN.." Success loading "..H._zDEFAULT..msg1..H._zBRIGHTGREEN.." script in "..H.dClock(os.clock() - load_start)..H._zDEFAULT)
    -- we only keep the CONTAINER
    NMS_MOD_DEFINITION_CONTAINER = conf.NMS_MOD_DEFINITION_CONTAINER
    
    if not H.gIs_LEAN_MODE and H._mSerializeScript == "Y" then
      -- this serializes ALL scripts, when requested by the OPTION      
      SerializingStart = os.clock()
      local scriptFilenamePath = H.LoadFileData("CurrentModScript.txt")
      local scriptFilename = H.GetFilenameFromFilePath(scriptFilenamePath)
      
      print(">>> [INFO]"..H._zBRIGHTGREEN..[[ Creating ]]..H._zBRIGHTORANGE..strsub(scriptFilename,1,-5)..[[.serial.lua]]..H._zBRIGHTGREEN..[[ in TOOLS\ModScriptCheck and TOOLS\MODDER_Helper\<ThisMod> folders, please wait...]]..H._zDEFAULT)
      -- print("")
      -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      local outTable = {}
      local itemName = "NMS_MOD_DEFINITION_CONTAINER"
      
      SerializeLoadedScript(H,itemName,NMS_MOD_DEFINITION_CONTAINER,outTable)
      outTable[#outTable] = strsub(outTable[#outTable],1,-2) -- remove last ,
      -- -- H.WriteToFile(H.ConvertLineTableToText(outTable), [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.raw.lua]])
      -- H.WriteToFile(outTable, [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.raw.lua]])
      -- H.printf("           >>> done in "..H.dClock(os.clock() - SerializingStart))

      -- SerializingStart = os.clock()
      outTable = PostProcessing(H,outTable)
      -- H.WriteToFile(H.ConvertLineTableToText(outTable), [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.serial.lua]])
      H.WriteToFile(outTable, [[..\TOOLS\ModScriptCheck\]]..strsub(scriptFilename,1,-5)..[[.serial.lua]])
      
      if H.gIs_MODSfolderNameScript then
        -- mod folder does not exist yet
        H.mkdir([[..\TOOLS\MODDER_Helper\]]..strsub(scriptFilename,1,-5))
        
        -- keep only the script name
        H.WriteToFile(outTable, [[..\TOOLS\MODDER_Helper\]]..strsub(scriptFilename,1,-5)..[[\]]..strsub(scriptFilename,1,-5)..[[.serial.lua]])
      else
        local mod_filename = NMS_MOD_DEFINITION_CONTAINER["MOD_FILENAME"]
        if mod_filename == nil or mod_filename == "" then
          mod_filename = "GENERIC"
        end
        mod_filename = string.gsub(mod_filename,"%.pak",""):gsub("%.PAK","")

        -- mod folder does not exist yet
        H.mkdir([[..\TOOLS\MODDER_Helper\]]..mod_filename)
        
        H.WriteToFile(outTable, [[..\TOOLS\MODDER_Helper\]]..mod_filename..[[\]]..strsub(scriptFilename,1,-5)..[[.serial.lua]])
      end
      
      H.printf("           >>> done in "..H.dClock(os.clock() - SerializingStart))
      
      -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      -- print("")
    end
    
    -- if H._bScriptCounter == H._bTotalNumberScripts then
      -- -- we are at the last script (or maybe the only script)
      -- -- this serialize only this script, when requested by main folder file trigger
      -- if H._mSERIALIZING == "Y" then
        -- print(">>> [INFO]"..H._zBRIGHTGREEN.." Serializing loaded script, please wait..."..H._zDEFAULT)
        -- local scriptTable = SerializeScript(H,NMS_MOD_DEFINITION_CONTAINER,true,"NMS_MOD_DEFINITION_CONTAINER")
        -- -- H.WriteToFile(H.ConvertLineTableToText(scriptTable), "..\\SerializedScript.lua")
        -- H.WriteToFile(scriptTable, "..\\SerializedScript.lua")
      -- end
    -- end
    -- print(">>> [INFO]"..H._zBRIGHTGREEN.." Executing now..."..H._zDEFAULT)
    print(">>>       "..H._zBRIGHTGREEN.." Executing now..."..H._zDEFAULT)
    -- H.pv("["..Hash.."]")
    print("")
    
  else
    NMS_MOD_DEFINITION_CONTAINER = ""
    -- print("")
    -- print(status)
    print("    "..H.gcATTENTION.." XXXXX Error loading USER script! XXXXX "..H._zDEFAULT)
    print("")
    H.WriteToFile("", "LoadScriptAndFilenamesERROR.txt")
    if status then
      H.Report(H.LoadFileData("CurrentModScript.txt"),tostring(status))
    end
    
  end
  
  if type(NMS_MOD_DEFINITION_CONTAINER) == "table" then
    dofile("CheckContainer.lua")
    
    if (os.getenv("-SHOWSimpleContainer") == "Y") then
      print("                     + NMS_MOD_DEFINITION_CONTAINER")
      H.DisplayScriptStructure(NMS_MOD_DEFINITION_CONTAINER,1)
      print("")
    end  
  end
  
  return NMS_MOD_DEFINITION_CONTAINER,H.DelayedReportData,InternalFunctionProblem,conf
end
--****************************  END: OpenUserScript()  **********************************************

--***************************************************************************************************
-- USED only for DEBUG
-- function LookAt_MOD_PAK_SOURCE_content(H,flag)
  -- print(flag)
  -- local temp_MOD_PAK_SOURCE = H.ParseTextFileIntoTable("MOD_PAK_SOURCE.txt")
  -- for i=1,#temp_MOD_PAK_SOURCE do
    -- print("   ["..temp_MOD_PAK_SOURCE[i].."]")
  -- end
-- end

--***************************************************************************************************
function TestScript(H, NMS_MOD_DEFINITION_CONTAINER, IsCOMBINE_MODS_flag)
  local MaxPakNameLength = H._bMaxPakNameLength
  if H.IsSkipCreatingPAK == nil then H.IsSkipCreatingPAK = false end
  -- H.printf("H.IsSkipCreatingPAK = %s",tostring(H.IsSkipCreatingPAK))
  
  local MOD_tmp = NMS_MOD_DEFINITION_CONTAINER["MOD_AUTHOR"]
  if MOD_tmp == nil then MOD_tmp = "" end
  H.WriteToFile(MOD_tmp, "MOD_AUTHOR.txt")
  
  MOD_tmp = NMS_MOD_DEFINITION_CONTAINER["LUA_AUTHOR"]
  if MOD_tmp == nil then MOD_tmp = "" end
  H.WriteToFile(MOD_tmp, "LUA_AUTHOR.txt")
  
  MOD_tmp = NMS_MOD_DEFINITION_CONTAINER["MOD_MAINTENANCE"]
  if MOD_tmp == nil then MOD_tmp = "" end
  H.WriteToFile(MOD_tmp, "MOD_MAINTENANCE.txt")
  
  local mod_filename = NMS_MOD_DEFINITION_CONTAINER["MOD_FILENAME"]
  if mod_filename == nil or mod_filename == "" then
    mod_filename = "GENERIC"
    
    -- alias
    if NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CT"] then
      NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CHANGE_TABLE"] = NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CT"]
      -- NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CT"] = nil -- kept so that script can refer to it
    end
    
    if NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"] and NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CHANGE_TABLE"] then
      if type(NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"][1]["MBIN_CHANGE_TABLE"][1]["EXML_CHANGE_TABLE"]) == "table" then
        print("   "..H.gcWARNING.." [WARNING] MOD_FILENAME not found, using 'GENERIC' as name "..H._zDEFAULT)
        H.Report("","MOD_FILENAME not found, using 'GENERIC' as name","WARNING")
      elseif H.gIsGlobalIndividual then
        print("   "..H.gcNOTICE.." [NOTICE] MOD_FILENAME and MXML_CHANGE_TABLE not found, skipping mod creation "..H._zDEFAULT)
        H.Report("","MOD_FILENAME and MXML_CHANGE_TABLE not found, skipping mod creation","NOTICE")
        H.IsSkipCreatingPAK = true
      end
    end
  end
  
  -- if mod_filename == nil or mod_filename == "" then
    -- mod_filename = "GENERIC"
    -- print("   "..H.gcWARNING.." [WARNING] Missing MOD_FILENAME, using 'GENERIC' as name "..H._zDEFAULT)
    -- H.Report("","Missing MOD_FILENAME, using 'GENERIC' as name","WARNING")
  -- end

  H.DEBUG_ScriptContent_print("mod_filename to MOD_FILENAME.txt = ["..mod_filename.."]")
  H.WriteToFile(mod_filename, "MOD_FILENAME.txt")
  
  local mod_batchname = NMS_MOD_DEFINITION_CONTAINER["MOD_BATCHNAME"]
  if mod_batchname == nil then
    mod_batchname = ""
  end
  
  if mod_batchname ~= "" and string.upper(string.sub(mod_batchname,-4)) ~= ".PAK" then
    mod_batchname = string.sub(mod_batchname,1,MaxPakNameLength)
    -- mod_batchname = mod_batchname..".pak"
    -- print("   "..H.gcNOTICE.." [NOTICE] Added .pak extension to MOD_BATCHNAME "..H._zDEFAULT)
    -- H.Report("","Added .pak extension to MOD_BATCHNAME","NOTICE")
  else
    mod_batchname = string.sub(mod_batchname,1,#mod_batchname-4)
    mod_batchname = string.sub(mod_batchname,1,MaxPakNameLength)
    -- mod_batchname = mod_batchname..".pak"
  end
  
  if mod_batchname ~= "" then
    if string.upper(mod_batchname) == "AMUMSS COMBINE" then
      mod_batchname = [[AMUMSS Combine_999]]
    end
    if not H.gIs_LEAN_MODE then
      print(">>> [INFO] Current 'MOD_BATCHNAME' set to "..H._zBRIGHTORANGE.."'"..mod_batchname.."'"..H._zDEFAULT)
      print("")
    end
    H.Report(""," Current MOD_BATCHNAME set to '"..mod_batchname.."'")
    H.WriteToFile(mod_batchname, "MOD_BATCHNAME.txt")
    
  -- elseif H.gIsGlobalIndividual and not IsCOMBINE_MODS_flag then
    -- --clear BATCHNAME
    -- print("gIsGlobalIndividual = "..tostring(H.gIsGlobalIndividual))
    -- print("IsCOMBINE_MODS_flag = "..tostring(IsCOMBINE_MODS_flag))
    -- print(H._zBRIGHTGREEN..">>> [INFO] Clearing 'MOD_BATCHNAME'"..H._zDEFAULT)
    -- H.Report(""," Clearing 'MOD_BATCHNAME'")
    -- H.WriteToFile("", "MOD_BATCHNAME.txt")
  end
  
  local NewMBIN_FILES = {}
  --***************************************************************************************************
  local function IsNewMBIN_File(H, NewMBIN_FILES,candidate)
    local answer = false
    for i=1,#NewMBIN_FILES do
      if candidate == NewMBIN_FILES[i] then
        answer = true
        break
      end
    end
    return answer
  end
  --***************************************************************************************************
  
  local MODIFICATIONS = NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"]
  local abortProcessing = false
  
  if MODIFICATIONS then
    if type(MODIFICATIONS) ~= "table" then
      print("   "..H.gcATTENTION.." [ATTENTION] MODIFICATIONS is not a table.  Check your script! "..H._zDEFAULT)
      H.Report("","MODIFICATIONS is not a table.  Check your script!","ATTENTION")
      abortProcessing = true
    else
      local WordWrap1 = "\n"
      local WordWrap2 = "\n"
      -- print("@@@ type(MODIFICATIONS) = "..type(MODIFICATIONS))
      -- print("@@@ #MODIFICATIONS = "..#MODIFICATIONS)
      
      if #MODIFICATIONS == 0 then
        print("   "..H.gcATTENTION.." [ATTENTION] MODIFICATIONS table is empty OR not a table of sub-tables.  Check script... "..H._zDEFAULT)
        H.Report("","MODIFICATIONS table is empty OR not a table of sub-tables.  Check script...","ATTENTION")
        H.WriteToFile("", "MOD_MBIN_SOURCE.txt")
        H.WriteToFile("", "MOD_PAK_SOURCE.txt")
        --abortProcessing = true
      else
        for n=1,#MODIFICATIONS do
          if n == #MODIFICATIONS then WordWrap1 = "" end
          
          local ConflictTable = {}
          
          -- alias
          if MODIFICATIONS[n]["MBIN_CT"] then
            MODIFICATIONS[n]["MBIN_CHANGE_TABLE"] = MODIFICATIONS[n]["MBIN_CT"]
            -- MODIFICATIONS[n]["MBIN_CT"] = nil -- kept so that script can refer to it
          end
          
          local MBIN_CHANGE_TABLE = MODIFICATIONS[n]["MBIN_CHANGE_TABLE"]
          -- print("@@@ type(MBIN_CHANGE_TABLE) = "..type(MBIN_CHANGE_TABLE))
          -- print("@@@ #MBIN_CHANGE_TABLE = "..#MBIN_CHANGE_TABLE)
          
          if MBIN_CHANGE_TABLE == nil or type(MBIN_CHANGE_TABLE) ~= "table" then
            print("   "..H.gcATTENTION.." [ATTENTION] MBIN_CHANGE_TABLE is not a table.  Check your script! "..H._zDEFAULT)
            H.Report("","MBIN_CHANGE_TABLE is not a table.  Check your script!","ATTENTION")
            MBIN_CHANGE_TABLE = {}
            abortProcessing = true
            break
          end
          
          if #MBIN_CHANGE_TABLE == 0 then
            print("   "..H.gcATTENTION.." [ATTENTION] MBIN_CHANGE_TABLE is empty OR not a table of sub-tables.  Cannot process.  Check your script! "..H._zDEFAULT)
            H.Report("","MBIN_CHANGE_TABLE is empty OR not a table of sub-tables.  Cannot process.  Check your script!","ATTENTION")
            abortProcessing = true
          else
            for m=1,#MBIN_CHANGE_TABLE do
              -- alias
              -- printf("#MBIN_CHANGE_TABLE = %d",#MBIN_CHANGE_TABLE)
              -- printf("type(MBIN_CHANGE_TABLE[%d]) = %s",m,type(MBIN_CHANGE_TABLE[m]))
              -- printf("MBIN_CHANGE_TABLE[%d] = %s",m,tostring(MBIN_CHANGE_TABLE[m]))
              if type(MBIN_CHANGE_TABLE[m]) ~= "table" then
                local tmp = type(MBIN_CHANGE_TABLE[m])
                print("   "..H.gcERROR.." [ERROR] MBIN_FILE_SOURCE["..m.."] contains a '"..tmp.."'.  Check your script! "..H._zDEFAULT)
                H.Report("","MBIN_FILE_SOURCE["..m.."] contains a '"..tmp.."'.  Check your script!","ERROR")
                MBIN_FILE_SOURCE = ""
                abortProcessing = true
                break
              end
              
              if MBIN_CHANGE_TABLE[m]["MBIN_FS"] then
                MBIN_CHANGE_TABLE[m]["MBIN_FILE_SOURCE"] = MBIN_CHANGE_TABLE[m]["MBIN_FS"]
                MBIN_CHANGE_TABLE[m]["MBIN_FS"] = nil
              end
              
              local MBIN_FILE_SOURCE = MBIN_CHANGE_TABLE[m]["MBIN_FILE_SOURCE"]
              -- print("@@@ type(MBIN_FILE_SOURCE) = "..type(MBIN_FILE_SOURCE))
              -- print("@@@ #MBIN_FILE_SOURCE = "..#MBIN_FILE_SOURCE)
              
              if not MBIN_CHANGE_TABLE[m]["EXT_FUNC"] and (MBIN_FILE_SOURCE == nil or MBIN_FILE_SOURCE == "") then
                print("   "..H.gcATTENTION.." [ATTENTION] MBIN_FILE_SOURCE is empty.  Check your script! "..H._zDEFAULT)
                H.Report("","MBIN_FILE_SOURCE is empty.  Check your script!","ATTENTION")
                MBIN_FILE_SOURCE = ""
                abortProcessing = true
                break
              end
              
              if type(MBIN_FILE_SOURCE) == "table" then
                if type(MBIN_FILE_SOURCE[1]) == "table" then
                  --alternate syntax #3: a table of sub-table(s) of STRINGs
                  H.pv("DETECTED a table of tables MBIN_FILE_SOURCE")
                  for kMBIN=1,#MBIN_FILE_SOURCE do
                    -- H.printf("kMBIN = %d, type(MBIN_FILE_SOURCE[kMBIN]) == %s",kMBIN,type(MBIN_FILE_SOURCE[kMBIN]))
                    
                    if type(MBIN_FILE_SOURCE[kMBIN]) ~= "table" then
                      print(H.gcWARNING.."    [WARNING] ["..MBIN_FILE_SOURCE[kMBIN].."] 'is not a sub-table' error, skipping.  Check your script! "..H._zDEFAULT)
                      H.Report(""," ["..MBIN_FILE_SOURCE[kMBIN].."] 'is not a sub-table' error, skipping.  Check your script!","WARNING")
                      abortProcessing = true
                   
                    elseif type(MBIN_FILE_SOURCE[kMBIN][1]) == "table" then
                      print(H.gcWARNING.."    [WARNING] MBIN_FILE_SOURCE[kMBIN][1] 'is a table' error, skipping.  Check your script! "..H._zDEFAULT)
                      H.Report(""," MBIN_FILE_SOURCE[kMBIN][1] 'is a table' error, skipping.  Check your script!","WARNING")
                      abortProcessing = true
                      
                    else
                      if H.GetExtensionFromFilePath(MBIN_FILE_SOURCE[kMBIN][1]) == nil then
                        -- no file extension, let us try .MBIN
                        MBIN_FILE_SOURCE[kMBIN][1] = MBIN_FILE_SOURCE[kMBIN][1]..[[.MBIN]]
                        print("   "..H.gcNOTICE.." [NOTICE] ["..tostring(MBIN_FILE_SOURCE[kMBIN][1]).."] is missing an extension, trying .MBIN "..H._zDEFAULT)
                        H.Report("","["..tostring(MBIN_FILE_SOURCE[kMBIN][1]).."] is missing an extension, trying .MBIN","NOTICE")
                      end
                      
                      if H.GetExtensionFromFilePath(MBIN_FILE_SOURCE[kMBIN][2]) == nil then
                        -- no file extension, let us try .MBIN
                        MBIN_FILE_SOURCE[kMBIN][2] = MBIN_FILE_SOURCE[kMBIN][2]..[[.MBIN]]
                        print("   "..H.gcNOTICE.." [NOTICE] ["..tostring(MBIN_FILE_SOURCE[kMBIN][2]).."] is missing an extension, trying .MBIN "..H._zDEFAULT)
                        H.Report("","["..tostring(MBIN_FILE_SOURCE[kMBIN][2]).."] is missing an extension, trying .MBIN","NOTICE")
                      end
                      
                      -- H.printf("   MBIN_FILE_SOURCE[kMBIN][1] = %s",tostring(MBIN_FILE_SOURCE[kMBIN][1]))
                      -- H.printf("   MBIN_FILE_SOURCE[kMBIN][2] = %s",tostring(MBIN_FILE_SOURCE[kMBIN][2]))

                      MBIN_FILE_SOURCE[kMBIN][1] = H.NormalizePath(MBIN_FILE_SOURCE[kMBIN][1])
                      MBIN_FILE_SOURCE[kMBIN][2] = H.NormalizePath(MBIN_FILE_SOURCE[kMBIN][2])
                      
                      H.pv("Writing to MOD_MBIN_SOURCE.txt, MBIN_FILE_SOURCE["..kMBIN.."][1] "..MBIN_FILE_SOURCE[kMBIN][1])
                      NewMBIN_FILES[#NewMBIN_FILES+1] = MBIN_FILE_SOURCE[kMBIN][2]
                      
                      if not IsNewMBIN_File(H, NewMBIN_FILES,MBIN_FILE_SOURCE[kMBIN][1]) then
                        if m==#MBIN_CHANGE_TABLE and n == #MODIFICATIONS and kMBIN==#MBIN_FILE_SOURCE then --last one of the table
                          WordWrap2 = ""
                        end
                        if n==1 and m==1 and kMBIN==1 then --first time only
                          H.WriteToFile(MBIN_FILE_SOURCE[kMBIN][1]..WordWrap2,"MOD_MBIN_SOURCE.txt")
                        else
                          H.WriteToFileAppend(MBIN_FILE_SOURCE[kMBIN][1]..WordWrap2,"MOD_MBIN_SOURCE.txt")
                        end
                      end
                    end
                  end
                  
                else
                  --alternate syntax #2: a table of STRINGs
                  H.pv("DETECTED a normal MBIN_FILE_SOURCE table")
                  for kMBIN=1,#MBIN_FILE_SOURCE do
                    MBIN_FILE_SOURCE[kMBIN] = H.NormalizePath(MBIN_FILE_SOURCE[kMBIN])
                    H.pv("MBIN_FILE_SOURCE["..kMBIN.."] "..MBIN_FILE_SOURCE[kMBIN])
                    
                    if not IsNewMBIN_File(H, NewMBIN_FILES,MBIN_FILE_SOURCE[kMBIN]) then
                      H.pv("Writing to MOD_MBIN_SOURCE.txt, MBIN_FILE_SOURCE[kMBIN] = "..MBIN_FILE_SOURCE[kMBIN])
                      if m==#MBIN_CHANGE_TABLE and n==#MODIFICATIONS and kMBIN==#MBIN_FILE_SOURCE then --last one of the table
                        WordWrap2 = ""
                      end
                      if n==1 and m==1 and kMBIN==1 then --first time only
                        H.WriteToFile(MBIN_FILE_SOURCE[kMBIN]..WordWrap2,"MOD_MBIN_SOURCE.txt")
                      else
                        H.WriteToFileAppend(MBIN_FILE_SOURCE[kMBIN]..WordWrap2,"MOD_MBIN_SOURCE.txt")
                      end
                    end
                  end
                end
                
              else
                --alternate syntax #1: a STRING
                H.pv("DETECTED MBIN_FILE_SOURCE as a string or nil")
                MBIN_FILE_SOURCE = H.NormalizePath(MBIN_FILE_SOURCE)
                if MBIN_FILE_SOURCE == nil or MBIN_FILE_SOURCE == "" then
                  if not MBIN_CHANGE_TABLE[m]["EXT_FUNC"] then
                    print("   "..H.gcATTENTION.." [ATTENTION] MBIN_FILE_SOURCE["..n.."]["..m.."] is empty.  Check your script! "..H._zDEFAULT)
                    H.Report("","MBIN_FILE_SOURCE["..n.."]["..m.."] is empty.  Check your script!","ATTENTION")
                    MBIN_FILE_SOURCE = ""
                    abortProcessing = true
                  else
                    MBIN_FILE_SOURCE = ""
                  end
                else
                  H.pv("MBIN_FILE_SOURCE["..n.."]["..m.."] "..MBIN_FILE_SOURCE)
                end
                
                if not IsNewMBIN_File(H, NewMBIN_FILES,MBIN_FILE_SOURCE) then
                  H.pv("Writing to MOD_MBIN_SOURCE.txt, MBIN_FILE_SOURCE = "..MBIN_FILE_SOURCE)
                  if m==#MBIN_CHANGE_TABLE and n==#MODIFICATIONS then
                    WordWrap2 = ""
                  end
                  if n==1 and m==1 then --first time only
                    H.WriteToFile(MBIN_FILE_SOURCE..WordWrap2,"MOD_MBIN_SOURCE.txt")
                  else
                    H.WriteToFileAppend(MBIN_FILE_SOURCE..WordWrap2,"MOD_MBIN_SOURCE.txt")
                  end
                end
              end
            end
          end
        end
      end
      
      if not abortProcessing then
        -- CleanUP MOD_MBIN_SOURCE.txt
        local MBIN_SOURCE = H.ParseTextFileIntoTable("MOD_MBIN_SOURCE.txt")
        
        -- remove duplicates
        for i=1,#MBIN_SOURCE do
          for j=i+1,#MBIN_SOURCE do
            if MBIN_SOURCE[i] == MBIN_SOURCE[j] then
              MBIN_SOURCE[j] = ""
            end
          end
        end
        
        local MBIN_SOURCE_temp = {}
        for i=1,#MBIN_SOURCE do
          if MBIN_SOURCE[i] ~= "" then
            MBIN_SOURCE_temp[#MBIN_SOURCE_temp+1] = MBIN_SOURCE[i]
          end
        end
        
        -- H.WriteToFile(H.ConvertLineTableToText(MBIN_SOURCE_temp),"MOD_MBIN_SOURCE.txt")
        H.WriteToFile(MBIN_SOURCE_temp,"MOD_MBIN_SOURCE.txt")
        MBIN_Source = MBIN_SOURCE_temp
        -- END: remove duplicates
        
        -- print("__________________________________________")
        local ModScript_pak_list = H.ParseTextFileIntoTable("ModScript_pakContent_list.txt")
        -- print("ModScript_pak_list = "..#ModScript_pak_list)
        
        -- check PAK_SOURCE for each MBIN_FILE_SOURCE
        local missingPak = {}
        for i=1,#MBIN_Source do
          local TempMBIN = MBIN_Source[i]
          local found = false
          --check if this file is already in MODBUILDER\MOD
          local TempEXML = string.gsub(MBIN_Source[i],[[.MBIN.PC]],[[.MBIN]])
          TempEXML = string.gsub(TempEXML,[[.MBIN]],[[.MXML]])
          
          if H.IsFileExist([[.\MOD\]]..TempEXML) then
            found = true
          else
            TempMBIN = string.gsub(MBIN_Source[i],[[\]],[[/]])
            -- in case the user used .MXML instead of .MBIN
            TempMBIN = string.gsub(TempMBIN,[[.MXML]],[[.MBIN]])
            for j=1,#ModScript_pak_list do
              -- print("["..ModScript_pak_list[j].."]")
              if H.trim(ModScript_pak_list[j]) == "FROM MODS" then
                -- print(">>> break on FROM MODS")
                break
              else
                if string.find(ModScript_pak_list[j],TempMBIN,1,true) then
                  -- this MBIN is in one of the ModScript paks
                  -- print(">>> Found "..TempMBIN.." in ModScript_pakContent_list.txt at "..j)
                  found = true
                  break
                end
              end
            end
          end
          
          if not found then
            -- this MBIN is not in any of the ModScript paks
            -- can we find it in NMS PCBANKS paks?
            -- local found,Pak_File = LocateMOD_PAK_SOURCE(string.gsub(MBIN_Source[i],[[.MXML]],[[.MBIN]]))
            local Pak_File = H.LocatePAK(string.gsub(MBIN_Source[i],[[.MXML]],[[.MBIN]]))
            
            -- print("this "..Pak_File)
            if Pak_File == nil then
              print(H.gcWARNING.."[WARNING] NMS PAK not found for ["..MBIN_Source[i].."], skipping. Check your file path/name! "..H._zDEFAULT)
              H.Report("","NMS PAK not found for ["..MBIN_Source[i].."], skipping. Check your file path/name!","WARNING")
              missingPak[#missingPak+1] = true
            end
          else
            missingPak[#missingPak+1] = false
          end
        end
        
        local allTrue = true
        for i=1,#missingPak do
          if not missingPak[i] then
            allTrue = false
            break
          end
        end
        
        if allTrue and #missingPak > 0 then
          abortProcessing = true
        end
        
        -- LookAt_MOD_PAK_SOURCE_content(H,"- BBBBB before cleanup")
        -- CleanUP MOD_PAK_SOURCE.txt duplicates
        local PAK_Source = H.ParseTextFileIntoTable("MOD_PAK_SOURCE.txt")

        local PAK_Source_temp = {}
        local tmp = {}
        for i=1,#PAK_Source do
          if tmp[PAK_Source[i]] then
            -- already exist, skip it
          else
            -- does not exist, record it
            tmp[PAK_Source[i]] = true
            PAK_Source_temp[#PAK_Source_temp+1] = PAK_Source[i]
          end
        
          -- for j=i+1,#PAK_Source do
            -- if PAK_Source[i] == PAK_Source[j] then
              -- PAK_Source[j] = ""
            -- end
          -- end
        end
        
        -- -- for i=1,#PAK_Source do
          -- -- if PAK_Source[i] ~= "" then
            -- -- PAK_Source_temp[#PAK_Source_temp+1] = PAK_Source[i]
          -- -- end
        -- -- end
        
        -- H.WriteToFile(H.ConvertLineTableToText(PAK_Source_temp),"MOD_PAK_SOURCE.txt")
        H.WriteToFile(PAK_Source_temp,"MOD_PAK_SOURCE.txt")
        
        --LookAt_MOD_PAK_SOURCE_content(H,"- AAAAA finally")
      end
    end
  else
    --MODIFICATIONS == nil
  end
  
  if abortProcessing then
    H.WriteToFile("", "MOD_MBIN_SOURCE.txt")
    H.WriteToFile("", "MOD_PAK_SOURCE.txt")
    -- H.WriteToFile("", "MOD_FILENAME.txt")
  end
  
  return abortProcessing,H.IsSkipCreatingPAK,H.DelayedReportData,mod_filename
end
--*************************  END: TestScript()  *******************************************************

-- ****************************************************
function CreateCompositeModName(H, start, last)
  -- Windows accepts a max of 260 char for drive/path/filename/ext length
  -- NMS accepts only 110 char + .pak = 114
  -- we need to leave room for '_(9)' so 110-4 = 106 + .pak
  local MaxPakNameLength = H._bMaxPakNameLength
  
  local allNames = ""
  for m=start,last do
    local s = H.gModScriptLuaDirList[m][1]
    local RelPathToScript = H.GetRelPathToScript(s)
    
    --NOTE: may not work with every folder name due to pattern not escaped
    -- local cleanScriptName = string.gsub(s,RelPathToScript,"")
    
    local cleanScriptName = string.sub(s,#RelPathToScript + 1)
    cleanScriptName = string.gsub(cleanScriptName,".lua",""):gsub("%.LUA","")
    
    if #allNames < MaxPakNameLength then
      allNames = allNames..cleanScriptName.."+"
    end

    -- print("Y: s = ["..s.."]")
    -- print("Y: RelPathToScript = ["..RelPathToScript.."]")
    -- print("Y: cleanScriptName = ["..cleanScriptName.."]")
    
    -- if #allNames > MaxPakNameLength then
      -- break
    -- end
  end
  
  -- allNames = string.gsub(allNames,"%.lua",""):gsub("%.LUA","") --removes .lua from all script names
  allNames = string.sub(allNames,1,-2) --removes the last +
  allNames = string.sub(allNames,1,MaxPakNameLength)
  if string.sub(allNames,-1) == "+" then
    allNames = string.sub(allNames,1,#allNames - 1) --removes the last +, if any
  end
  -- print("Y: allNames = ["..allNames.."]")
  
  --reset Composite_MOD_FILENAME
  H.DEBUG_ScriptContent_print("Resetting Composite_MOD_FILENAME.txt")
  local filename = [[Composite_MOD_FILENAME.txt]]
  os.remove(filename)
  
  H.DEBUG_ScriptContent_print("new Composite_MOD_FILENAME = ["..allNames.."]")
  H.WriteToFile(allNames,filename)
end
-- ****************************************************

-- ****************************************************
function CreateCompositePakName(H)
  -- Windows accepts a max of 260 char for drive/path/filename/ext length
  -- NMS accepts only 110 char + .pak = 114
  -- we need to leave room for '_(9)' so 110-4 = 106 + .pak
  local MaxPakNameLength = H._bMaxPakNameLength
  
  local allNames = ""

  local pakContent = H.ParseTextFileIntoTable("ModScript_pak_list.txt")
  for i=1,#pakContent do
    local pakName = string.gsub(pakContent[i],[[..\ModScript\]],"")
    pakName = string.gsub(pakName,[[%.pak]],""):gsub([[%.PAK]],"")
    allNames = allNames..pakName.."+"

    if #allNames > MaxPakNameLength then
      break
    end
  end

  -- allNames = string.gsub(allNames,".pak","") --removes .pak from all pak names
  allNames = string.sub(allNames,1,-2) --removes the last +
  allNames = string.sub(allNames,1,MaxPakNameLength)
  if string.sub(allNames,-1) == "+" then
    allNames = string.sub(allNames,1,#allNames - 1) --removes the last +, if any
  end
  -- print("Y: allNames = ["..allNames.."]")
  
  --reset Composite_PAK_FILENAME
  H.DEBUG_ScriptContent_print("Resetting Composite_PAK_FILENAME.txt")
  local filename = [[Composite_PAK_FILENAME.txt]]
  os.remove(filename)
  
  H.DEBUG_ScriptContent_print("new Composite_PAK_FILENAME = ["..allNames.."]")
  H.WriteToFile(allNames,filename)
end
-- ****************************************************

-- --***************************************************************************************************
-- function SwitchToOtherMBINCompiler(H)
  -- -- SWITCH TO THE OTHER MBINCOMPILER
  -- if not H.IsFileExist([[VersionPublic.txt]]) then
    -- -- we are currently using LATEST, switch to PUBLIC

    -- H.CopyFile([[MBINCompiler.public.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
    -- -- activate FLAG PUBLIC
    -- H.WriteToFile("",[[VersionPublic.txt]])
    
    -- H.DeleteFile([[MBINCompilerVersion.txt]])
    -- local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
    -- H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
    
    -- if not H.gIs_LEAN_MODE then
      -- print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." to 'public' MBINCompiler "..sV)
    -- end
    -- H.Report("","Switched to 'public' MBINCompiler "..sV)
  -- else
    -- -- we are currently using PUBLIC, switch to LATEST
    -- H.CopyFile([[MBINCompiler.latest.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
    -- -- activate FLAG LATEST
    -- H.DeleteFile([[VersionPublic.txt]])
    
    -- H.DeleteFile([[MBINCompilerVersion.txt]])
    -- local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
    -- H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
    
    -- if not H.gIs_LEAN_MODE then
      -- print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." to 'most recent' MBINCompiler "..sV)
    -- end
    -- H.Report("","Switched to 'most recent' MBINCompiler "..sV)
  -- end
-- end
-- --***************************************************************************************************

--***************************************************************************************************
function SwitchBackToDeclaredMBINCompiler(H, IsQuiet)
  -- SWITCH BACK TO USER DECLARED MBINCOMPILER
  if H.IsFileExist([[DeclaredVersionPublic.txt]]) then
    if not H.IsFileExist([[VersionPublic.txt]]) then
      -- we are currently using LATEST, switch to PUBLIC
      H.CopyFile([[MBINCompiler.public.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
      -- activate FLAG PUBLIC
      H.WriteToFile("",[[VersionPublic.txt]])
      
      H.DeleteFile([[MBINCompilerVersion.txt]])
      local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
      H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
      
      if not H.gIs_LEAN_MODE then
        if not IsQuiet then
          print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." back to declared 'public' MBINCompiler "..sV)
        end
      end
      H.Report("","Switched back to declared 'public' MBINCompiler "..sV)
    end
  elseif H.IsFileExist([[VersionPublic.txt]]) then
    -- we are currently using PUBLIC, switch to LATEST
    H.CopyFile([[MBINCompiler.latest.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
    -- activate FLAG LATEST
    H.DeleteFile([[VersionPublic.txt]])
    
    H.DeleteFile([[MBINCompilerVersion.txt]])
    local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
    H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
    
    if not H.gIs_LEAN_MODE then
      if not IsQuiet then
        print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." back to declared 'most recent' MBINCompiler "..sV)
      end
    end
    H.Report("","Switched back to declared 'most recent' MBINCompiler "..sV)
  end
end
--***************************************************************************************************

--***************************************************************************************************
function ProcessScript(H, NMS_MOD_DEFINITION_CONTAINER, IsMulti_pak, _bScriptName, IsCOMBINE_MODS_flag, IsFirstCOMBINE_MODS_flag, IsEndCOMBINE_MODS_flag, conf) 
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strmatch = string.match
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  --Wbertro, maybe
  --edge case involving combining and a certain type of scripts
  --need to signal GetFreshSources to threat REMOVE files differently
  --   if REMOVE, open fresh copy in ALT folder
  --   if REMOVE, file in ALT is to be used by TestScript above then deleted
  
  -- print(">>> [INFO] Checking MBIN_FILE_SOURCE validity...")
  if not H.gIs_LEAN_MODE then
    print(">>> [INFO] "..H._zBRIGHTGREEN.."Checking CONTAINER validity..."..H._zDEFAULT)
  end
  
  -- Call TestScript()
  abortProcessing,H.IsSkipCreatingPAK,H.DelayedReportData,mod_filename = TestScript(H,NMS_MOD_DEFINITION_CONTAINER,IsCOMBINE_MODS_flag)
  -- H.printf("A0: ==> mod_filename = [%s]",mod_filename)
  -- H.printf("A0: ==> H._bScriptName = [%s]",H._bScriptName)
  
  local MODIFICATIONS = NMS_MOD_DEFINITION_CONTAINER["MODIFICATIONS"]
  local ADD_FILES = NMS_MOD_DEFINITION_CONTAINER["ADD_FILES"]
  
  if not abortProcessing then
    H.MOD_AUTHOR = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_AUTHOR"])
    if H.MOD_AUTHOR ~= "nil" and H.MOD_AUTHOR ~= "" then
      H.MOD_A = "Mod by "..H.MOD_AUTHOR
    else
      H.MOD_A = "Unknown MOD author"
    end
    
    H.LUA_AUTHOR = tostring(NMS_MOD_DEFINITION_CONTAINER["LUA_AUTHOR"])
    if H.LUA_AUTHOR ~= "nil" and H.LUA_AUTHOR ~= "" then
      H.LUA_A = " (script by "..H.LUA_AUTHOR..")"
    else
      H.LUA_A = " (Unknown script author)"
    end

    H.NMS_VERSION = tostring(NMS_MOD_DEFINITION_CONTAINER["NMS_VERSION"])
    if H.NMS_VERSION ~= "nil" and H.NMS_VERSION ~= "" then
      H.NMS_V = ", version "..H.NMS_VERSION
    else
      H.NMS_V = ", Unknown version"
    end
    
    if not H.gIs_LEAN_MODE then
      print(">>>        Able to process CONTAINER of type: "..H.GetTableType(NMS_MOD_DEFINITION_CONTAINER))
      print("    "..H._zBRIGHTORANGE..">>>>> "..H.MOD_A..H.LUA_A..H.NMS_V.." <<<<<"..H._zDEFAULT)
    end
    H.Report("",">>> "..H.MOD_A..H.LUA_A..H.NMS_V)
    
    if MODIFICATIONS or ADD_FILES then
      local global_integer_to_float = NMS_MOD_DEFINITION_CONTAINER["GLOBAL_INTEGER_TO_FLOAT"]
      
      -- H._bGlobalCOMBINE_MOD_TYPE:
      --    in general, a mod is named by the script MOD_FILENAME field
      --       in ModBackups and BuildHistory: modname.pak.author
      --       in IncrementalBuilds: modname_(x).pak.author
      
      -- == 0, an Individual mod => modname == script MOD_FILENAME (modname.pak)
      --       or, if a patch mod, modname == ~PatchMod.pak
      -- == 1, a generic combined mod with the current DATE-TIME suffix: modname == CombinedMod_DATE-TIME.pak
      -- == 2, a distinct combined mod with a NUMERIC suffix: modname == CombinedMod_(x).pak
      -- == 3, a COMPOSITE combined mod with the name being like: modname == Mod1+Mod2+Mod3.pak
      
      H.IsEXML_CREATE_GLOBAL = IsEXMLcreate(H, NMS_MOD_DEFINITION_CONTAINER["EXML_CREATE"])
      -- H.printf("H.IsEXML_CREATE_GLOBAL = [%s]",tostring(H.IsEXML_CREATE_GLOBAL))
      
      --we do this for each script in the combined pak
      if not H.gIsGlobalIndividual or IsCOMBINE_MODS_flag then
      
        H.WriteToFileAppend("\n=====================\n",[[COMBINED_CONTENT_LIST.txt]])
        H.WriteToFileAppend("Original information:\n",[[COMBINED_CONTENT_LIST.txt]])
        
        H.WriteToFileAppend("         SCRIPT NAME: ".._bScriptName.."\n",[[COMBINED_CONTENT_LIST.txt]])
        
        local MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_FILENAME"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("        MOD FILENAME: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])

        if IsCOMBINE_MODS_flag then
          -- the list of all the MOD_FILENAME, less ext, in this combine
          local tmp = H.GetExtensionFromFilePath(MOD_tmp) or ""
-- H.printf("FFF tmp = [%s]",tostring(tmp))
          H.combinedScriptList[#H.combinedScriptList+1] = MOD_tmp:gsub(H.escapeMagicString(tmp),"")
        end
        
        -- MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_FOLDER"])
        -- if MOD_tmp then
          -- H.WriteToFileAppend("   MOD FOLDER: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
        -- end
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_BATCHNAME"])
        if MOD_tmp then
          H.WriteToFileAppend("       MOD BATCHNAME: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
        end
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_AUTHOR"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("          MOD AUTHOR: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["LUA_AUTHOR"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("          LUA AUTHOR: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_MAINTENANCE"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("     MOD MAINTENANCE: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_DESCRIPTION"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("     MOD DESCRIPTION: <<<"..MOD_tmp..">>>\n",[[COMBINED_CONTENT_LIST.txt]])
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["MOD_CONTRIBUTORS"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("MOD MOD_CONTRIBUTORS: <<<"..MOD_tmp..">>>\n",[[COMBINED_CONTENT_LIST.txt]])
        
        MOD_tmp = tostring(NMS_MOD_DEFINITION_CONTAINER["NMS_VERSION"])
        if MOD_tmp == nil then
          MOD_tmp = "Unknown"
        end
        H.WriteToFileAppend("         NMS VERSION: "..MOD_tmp.."\n",[[COMBINED_CONTENT_LIST.txt]])
      end
      
      -- *****************   global_integer_to_float section   ********************
      global_integer_to_float = H.ReturnStringFrom(global_integer_to_float)
      global_integer_to_float = strupper(global_integer_to_float)
      
      local IsGlobalInteger_to_floatDeclared = (global_integer_to_float ~= "")
      local IsGlobalInteger_to_floatPRESERVE = (global_integer_to_float == "PRESERVE")
      local IsGlobalInteger_to_floatFORCE = (global_integer_to_float == "FORCE")
      
      if IsGlobalInteger_to_floatDeclared then
        -- print("")
        -- print(H.gcNOTICE..[[>>> [NOTICE] GLOBAL_INTEGER_TO_FLOAT is "]]..global_integer_to_float..[[" ]]..H._zDEFAULT)
        -- H.Report(global_integer_to_float,[[>>> GLOBAL_INTEGER_TO_FLOAT is]],"NOTICE")
      end
      
      if IsGlobalInteger_to_floatDeclared and not (IsGlobalInteger_to_floatPRESERVE or IsGlobalInteger_to_floatFORCE) then
        print(H.gcWARNING..[[>>> [WARNING] GLOBAL_INTEGER_TO_FLOAT value is incorrect, should be "", "FORCE" or "PRESERVE" ]]..H._zDEFAULT)
        H.Report(global_integer_to_float,[[>>> GLOBAL_INTEGER_TO_FLOAT value is incorrect, should be "", "FORCE" or "PRESERVE"]],"WARNING")
        
        global_integer_to_float = "" --not used until corrected
      end
      -- *****************   END: global_integer_to_float section   ********************
      
      -- -- *****************   compress_pak section   ********************
      -- local compress_pak = NMS_MOD_DEFINITION_CONTAINER["COMPRESS_PAK"]
      -- compress_pak = H.ReturnStringFrom(compress_pak)
      -- compress_pak = strupper(compress_pak)
      
      -- local IsCompress_PAK = (compress_pak ~= "")
      
      -- H.IsCompress_PAKTRUE = (compress_pak == "TRUE")
      -- local IsCompress_PAKFALSE = (compress_pak == "FALSE") --only used on next line
      -- if IsCompress_PAK and not (H.IsCompress_PAKTRUE or IsCompress_PAKFALSE) then
        -- print(">>> "..H.gcWARNING..[[ [WARNING] COMPRESS_PAK value is incorrect, should be "", "TRUE" or "FALSE" ]]..H._zDEFAULT)
        -- H.Report(My.IsCompress_PAK,[[>>> COMPRESS_PAK value is incorrect, should be "", "TRUE" or "FALSE"]],"WARNING")
        -- H.IsCompress_PAKTRUE = true
      -- end
      
      -- if not IsCompress_PAK then
        -- H.IsCompress_PAKTRUE = true
      -- end
      
      -- if H.gCompress_PAK ~= "S" then
        -- H.IsCompress_PAKTRUE = (H.gCompress_PAK == "Y")
      -- elseif not H.IsCompress_PAKTRUE then
        -- print(">>> "..H.gcNOTICE..[[ Created PAK will NOT be compressed ]]..H._zDEFAULT)
        -- H.Report("",[[>>> Created PAK will NOT be compressed]])
      -- end
      -- -- *****************   END: compress_pak section   ********************
      
      if not H.gIs_LEAN_MODE then
        print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
      end
      
      if MODIFICATIONS and #MODIFICATIONS ~= 0 then
        H.Report_flush(true,H.THIS)
        
        -- =======================  START GETFRESHSOURCES  ==============================
        -- already, GlobalMEFTI/MEFTI files are in MODBUILDER\MOD
        
        local GetFreshSourcesStart = os.clock()

        local useGetFreshSources_bat = H.nV < H.gMBINCompilerVersionMin
        
        if useGetFreshSources_bat then
          -- ####################### GETFRESHSOURCES.bat
          -- doing PREVIOUS code for older MBINCompiler
          
          if not os.execute([[cmd /c GetFreshSources.bat]]) then
            print(H.gcERROR.."    [ERROR] GetFreshSources.bat ended unexpectedly "..H._zDEFAULT)
            H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": ".._bScriptName..": GetFreshSources.bat ended unexpectedly"
          end
          
          --reset
          H.LuaStarting()
          if not H.gIs_LEAN_MODE then
            printf("   >>> done in "..H.dClock(os.clock() - GetFreshSourcesStart))
          end
          
        else
          -- ####################### NEW GETFRESHSOURCES code
          -- local H.paramFiles = [[/s /y /h /j /r]] --with folders and sub-folders
          -- H.paramFiles = [[/y /h /j /r /EXCLUDE:xcopy_exclude_vscode.txt]]
          
          -- H.WFAK("Stop BEFORE NEW GETFRESHSOURCES...")

          -- we are in MODBUILDER folder
          if not H.IsDirExist([[.\_TEMP]]) then
            -- print("%%%%%%%%%%%%%%%%%%  HAD TO RE_CREATE _TEMP !!!  %%%%%%%%%%%%%%%%%%")
            H.mkdir([[.\_TEMP]])
          end
          
          if not H.IsDirExist([[.\_TEMP\DECOMPILED]]) then
            -- print([[%%%%%%%%%%%%%%%%%%  HAD TO RE_CREATE _TEMP\DECOMPILED !!!  %%%%%%%%%%%%%%%%%%]])
            H.mkdir([[.\_TEMP\DECOMPILED]])
          end
          
          if not H.IsDirExist([[.\_TEMP\EXTRACTED]]) then
            -- print([[%%%%%%%%%%%%%%%%%%  HAD TO RE_CREATE _TEMP\EXTRACTED !!!  %%%%%%%%%%%%%%%%%%]])
            H.mkdir([[.\_TEMP\EXTRACTED]])
          end
          
          -- clear files
          H.WriteToFile("",[[ExtractFromNMSPaks.xml]])
          H.WriteToFile("",[[Extract_NMSPaksResult.txt]])
          H.WriteToFile("",[[ExtractFromModScriptPaks.xml]])
          H.WriteToFile("",[[Extract_ModScriptPaksResult.txt]])
          
          -- This DO-END section is NOT REDUNDANT, also see below
          do -- copy all loose ModScript EXML files in main folder to MODBUILDER\MOD regardless if not referenced in scripts
            local ModScriptEXML_table = H.ParseTextFileIntoTable("ModScript_EXML_list.txt")
            -- print("ModScriptEXML_table = "..#ModScriptEXML_table)
            
            for i=1,#ModScriptEXML_table do
              H.CopyFile([[..\ModScript\]]..ModScriptEXML_table[i],[[.\MOD\]]..ModScriptEXML_table[i]..[[*]],H.paramFiles)
            end
          end
          -- END: This DO-END is NOT REDUNDANT, also see below
          
          -- get list of MBIN files to process
          local MBIN_table = H.ParseTextFileIntoTable("MOD_MBIN_SOURCE.txt")
          if H.gDEBUG_EXT_FUNC then printf("#MBIN_table = %d",#MBIN_table) end
          
          H.ProcessMBINtable(MBIN_table,IsCOMBINE_MODS_flag,_bScriptName,"AMUMSS")
          
          if H.IsFetching and not H.gIs_LEAN_MODE then
            print("   >>> done in "..H.dClock(os.clock() - GetFreshSourcesStart))
          end
          -- H.WFAK("$$$ END of NEW GetFreshSources code")
          -- #######################
          
        end -- if useGetFreshSources_bat then
        -- =======================  END GETFRESHSOURCES  ==============================
        
      end -- if MODIFICATIONS and #MODIFICATIONS ~= 0 then
      
      
      -- @@@@ SCRIPT PROCESSING @@@@
      HandleModScript(H,NMS_MOD_DEFINITION_CONTAINER,IsMulti_pak,global_integer_to_float,conf,_bScriptName)
      
      -- if H.CustomDateTimeFormat then
        -- print("")
        -- print(">>> [INFO]"..H._zBRIGHTGREEN.." Using custom DateTime format!"..H._zDEFAULT)
        -- H.Report("")
        -- H.Report("","Using custom DateTime format!")
      -- end
      
      -- @@@@ CREATE MOD @@@@
      
-- Dprint = print
-- Dprint = function() end
      --***************************************************************************************************
      local function CreateMod(H, _bScriptName, scriptIndex, NMS_MOD_DEFINITION_CONTAINER)
        -- Save/Discard in MODBUILDER\MOD folder: delete unchanged EXML files        
        local cleanupStart = os.clock()
        print("")
        print(">>>  "..H._zBRIGHTGREEN.."'Saving to disk'/'Discarding unchanged' MXML file(s) in MOD folder"..H._zDEFAULT)
        H.Report("","'Saved to disk'/'Discarded unchanged' MXML file(s) in MOD folder")

        if H.gDEBUG_CheckTables then H.CheckTables("LISTING: BEFORE Saving/Discarding: ") end

        local EXML_list = {}
        EXML_list = H.ListDir(EXML_list,[[MOD\]],false,true) -- MOD\ makes it easier to remove later on
        
        -- print(" = = = = = List of files in MOD")
        -- for i=1,#EXML_list do
          -- printf(" - [%s]",EXML_list[i])
        -- end
        -- print(" = = = = =")

        -- 1st process the files already in MODBUILDER\MOD
        for i=1,#EXML_list do
          local fileMOD = EXML_list[i]
          if strfind(fileMOD,".MXML",1,true) then            
            -- printf("-  fileMOD = %3d: %s",i,fileMOD)
            local fileEXML = string.gsub(fileMOD,[[MOD\\]],""):gsub([[/]],[[\]])
            local fileLessEXML = strsub(fileEXML,1,-6)
            
            if H.linkedFiles[fileLessEXML] then
              -- silently delete the file
              H.DeleteFile([[.\]]..fileMOD,false)
            end
            
            if H.EXMLorgTable[fileLessEXML] and H.EXMLmodTable[fileLessEXML] then
              -- H.printf("    fileEXML = %3d: %s",i,fileEXML)
              -- H.printf("fileLessEXML = %3d: %s",i,fileLessEXML)

              if H.EXMLmodTable[fileLessEXML][1] == "REMOVE" then -- looks like this is NOT USED
                print("       "..H._zBRIGHTGREEN..">>> "..H._zBRIGHTORANGE.."Discarding "..H._zBRIGHTGREEN..fileEXML..H._zDEFAULT)
                H.Report("","    'Discarded': "..fileEXML)
                H.DeleteFile([[.\]]..fileMOD,false)
                if H.WDEBUG then H.WFAK("REMOVE: Set EXMLmodTable to NIL") end
                H.EXMLmodTable[fileLessEXML] = nil

              elseif table.concat(H.EXMLorgTable[fileLessEXML]) == table.concat(H.EXMLmodTable[fileLessEXML]) then
                print("       "..H._zBRIGHTGREEN.."==> "..H._zBRIGHTORANGE.."Discarding "..H._zBRIGHTGREEN..fileEXML..H._zDEFAULT)
                H.Report("","    'Discarded': "..fileEXML)
                H.DeleteFile([[.\]]..fileMOD,false)
                if H.WDEBUG then H.WFAK("EXMLorg == EXMLmod: Set EXMLmodTable to NIL") end
                H.EXMLmodTable[fileLessEXML] = nil

              else
                if not H.gIs_LEAN_MODE then
                  print("       "..H._zBRIGHTGREEN.."==>     "..H._zBRIGHTORANGE.."Saving "..H._zBRIGHTGREEN..fileEXML..H._zDEFAULT)
                end
              
                -- clone for MXMLtoEXML
                H.clonedMXMLmodTable[fileLessEXML] = H.cloneArray(H.EXMLmodTable[fileLessEXML])
                
                if not H.gIs_IncludeTagsInEXML_MXML then
                  -- remove FLAGS
                  for i=1,#H.EXMLmodTable[fileLessEXML] do
                    -- local s = H.EXMLmodTable[fileLessEXML][i]
                    H.EXMLmodTable[fileLessEXML][i] = H.EXMLmodTable[fileLessEXML][i]:gsub(H.modFlag..".*","")
                    -- if H.EXMLmodTable[fileLessEXML][i] ~= s then
                      -- H.printf("%d: [%s]",i,H.EXMLmodTable[fileLessEXML][i])
                    -- end
                  end
                end
                -- H.WFAK("A:")
                
                -- handle GLOBALS also in root
                -- MBIN in root, EXML in globals folder              
                if strfind(fileMOD,[[GLOBALS\]],1,true) and H.GetExtensionFromFilePath(fileMOD):upper() == ".MXML" then
                  H.WriteToFile(H.EXMLmodTable[fileLessEXML], [[.\]]..fileMOD:gsub([[GLOBALS\]],""))
                  -- remove copy from GLOBALS folder
                  H.DeleteFile(fileMOD,false,true)
                  -- remove GOLBALS folder, if empty
                  lfs.rmdir([[.\MOD\GLOBALS]])
                else
                  H.WriteToFile(H.EXMLmodTable[fileLessEXML], [[.\]]..fileMOD)
                end
                
                if H.WDEBUG then H.WFAK("Saved to disk: Set EXMLmodTable to NIL") end
                H.EXMLmodTable[fileLessEXML] = nil
                
                H.Report("","    ==>        'Saved': "..fileEXML)
              end
            end
          end
        end -- for i=1,#EXML_list do
        
        -- 2nd, now save/discard those remaining in H.EXMLmodTable that where not in MODBUILDER\MOD
        --   these are script created files (new files AND files copied from original NMS files)
        print(">>>  "..H._zBRIGHTGREEN.."'Saving to disk'/'Discarding unchanged' MXML file(s) in memory"..H._zDEFAULT)
        H.Report("","'Saved to disk'/'Discarded unchanged' MXML file(s) in memory")
        for k,v in pairs(H.EXMLmodTable) do
-- H.printf("SAVE/DISCARD CUSTOM    k = [%s]",k)
          if v then
-- H.printf("    v = [%s]",v)
            local kExt = k..H.EXMLorgExtTable[k]

            if v == "REMOVE" then -- looks like this is NOT USED
              print("       "..H._zBRIGHTGREEN.."--> "..H._zBRIGHTORANGE.."Discarding "..H._zBRIGHTGREEN..kExt..H._zDEFAULT)
              H.Report("","    'Discarded': "..kExt)
              H.DeleteFile([[.\MOD\]]..kExt,false)
            
            else
              if not H.gIs_LEAN_MODE then
                print("       "..H._zBRIGHTGREEN.."-->     "..H._zBRIGHTORANGE.."Saving "..H._zBRIGHTGREEN..kExt..H._zDEFAULT)
              end
              H.mkdir([[.\MOD\]]..H.GetFolderPathFromFilePath(kExt))
              
              -- Wbertro: NOT necessary for these script created files
              -- clone for MXMLtoEXML
              -- H.clonedMXMLmodTable[k] = H.cloneArray(H.EXMLmodTable[k])
              
              if not H.gIs_IncludeTagsInEXML_MXML then
                -- remove FLAGS
                for i=1,#v do
                  -- local s = v[i]
                  v[i] = v[i]:gsub(H.modFlag..".*","")
                  -- if v[i] ~= s then
                    -- H.printf("%d: [%s]",i,v[i])
                  -- end
                end
              end
              -- H.WFAK("B:")
              
              -- handle CUSTOM LANGUAGE files
              -- if not H.gFastPAKlist[kExt] then
                -- a CUSTOM file
                if strfind(k,[[LANGUAGE\]],1,true) then
                  -- a CUSTOM LANGUAGE file, record it
                  H.customLanguageFiles[#H.customLanguageFiles+1] = k
                end
              -- end
              
              -- handle GLOBALS also in root
              -- MBIN in root, EXML in globals folder
              if strfind(kExt,[[GLOBALS\]],1,true) and H.GetExtensionFromFilePath(kExt):upper() == ".MXML" then
                -- write it to root
                H.WriteToFile(v, [[.\MOD\]]..kExt:gsub([[^GLOBALS\]],""))
                -- no need to remove the file and the GLOBALS folder, it was never there (just in memory)
              else
                H.WriteToFile(v, [[.\MOD\]]..kExt)
              end
              
              H.Report("","    -->        'Saved': "..kExt)
            end
          end
        end
        
-- -- debug
-- print("CCC CCC CCC CCC CCC")
-- for k in pairs(H.clonedMXMLmodTable) do
  -- H.printf("Cloned: [%s]",k)
-- end
-- print("CCC CCC CCC CCC CCC")

        -- we do not need these anymore
        H.EXMLmodTable = {}
        
        printf(">>>    Done in %s",H.dClock(os.clock()-cleanupStart))
        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." After Saving (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
        -- END: Save/Discard in MODBUILDER\MOD folder: delete unchanged EXML files
        -- H.WFAK("  BEFORE Compiling...")
        
        H.Report()
        H.Report("","Starting final MBINCompiler and MOD creation phase...")
        H.Report()
        
        print("")
        print(">>>  "..H._zBRIGHTGREEN.."Compiling MXML file(s) in MOD folder"..H._zDEFAULT)
        print(">>>  MBINCompiler working...")
        
        -- XXXXXXXXXXXXXXXX  MBINCompiler.exe  XXXXXXXXXXXXXXXXXX
        if H.WDEBUG then H.WFAK("Just before calling MBINCompiler_C") end
        -- local status,result = H.MBINCompiler_C([[.\MOD]],H.gIs_LEAN_MODE)
        local status,result = H.MBINCompiler_C([[.\MOD]],true)
        
        H.switchBACK = false
        if status ~= "OK" and not gIsCompilerVersionsEqual then
          if H.UpdateMODDER_Helper then
            -- for MODDERS
            -- arg MUST be global
            arg[1] = "..\\" -- path to REPORT.lua
            arg[2] = "" -- path to MODBUILDER
            arg[3] = "Compiling" -- a message
            arg[4] = "keepOpen" -- do NOT close Report
            arg[6] = nil

            if IsEndCOMBINE_MODS_flag then
              arg[6] = scriptFileList
            end
            
            dofile("CheckMBINCompilerLOG.lua")
          end

          H.SwitchToOtherMBINCompiler(H,"AMUMSS")
          status,result = H.MBINCompiler_C([[.\MOD]],true)
          H.switchBACK = true
          -- SwitchBackToDeclaredMBINCompiler(H,false)
        end
        
        if status ~= "OK" then
          print(H.gcERROR.."@@@ MBINCompiler reported ERRORs... "..H._zDEFAULT)
          local scriptName = _bScriptName
          if IsCOMBINE_MODS_flag or not H.gIsGlobalIndividual then
            local BATCHNAME = H.LoadFileData("MOD_BATCHNAME.txt")
            if BATCHNAME == "" then
              BATCHNAME = "AMUMSS Combine_999"
            end
            if BATCHNAME ~= "" and H._bTotalNumberScripts > 1 then
              scriptName = BATCHNAME
            else
              local compFILENAME = H.LoadFileData("Composite_MOD_FILENAME.txt")
              if compFILENAME ~= "" then
                scriptName = compFILENAME..".pak"
              else
                -- generic message
                scriptName = "Check Report"
              end
            end
          end
          H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": "..scriptName..[[: Failed to compile some/all files in MODBUILDER\MOD]]
        end
        
        --always check the log, arg MUST be global
        arg[1] = "..\\" -- path to REPORT.lua
        arg[2] = "" -- path to MODBUILDER
        arg[3] = "Compiling" -- a message
        arg[4] = "keepOpen" -- do NOT close Report
        arg[6] = nil

        -- H.printf("P: IsEndCOMBINE_MODS_flag = %s",tostring(IsEndCOMBINE_MODS_flag))
        if IsEndCOMBINE_MODS_flag then
          arg[6] = scriptFileList
        end
        
        dofile("CheckMBINCompilerLOG.lua")
        
        if H.switchBACK then
          SwitchBackToDeclaredMBINCompiler(H,false)
        end
        
        -- this file is never needed
        H.DeleteFile([[.\MOD\LocTable.MBIN]])
        --***************** MBINCOMPILER is DONE ***************************
        H.Dprintf(H._zWHITEonDARKCYAN.."At "..H.dClock().." After MBINCompiler (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
                  
        -- --we should be able to get these from the CONTAINER
        -- --    see TestScript()
        -- --may have to pre-process the info
        -- local _cMOD_AUTHOR = NMS_MOD_DEFINITION_CONTAINER["MOD_AUTHOR"]
        -- if _cMOD_AUTHOR == nil then _cMOD_AUTHOR = "" end
        -- if strsub(_cMOD_AUTHOR,1,1) == "+" then
          -- --we will use it in the final mod name, '+' becomes '.'
          -- _cMOD_AUTHOR = string.gsub(_cMOD_AUTHOR,"%+",".",1)
        -- else
          -- _cMOD_AUTHOR = ""
        -- end
        
        if H.gDEBUG_ScriptTypeName then
          print("Z: ===> BEFORE selecting _cMOD_FILENAME type")
          print("Z:                 _bScriptName = [".._bScriptName.."]")
          print("Z:          IsCOMBINE_MODS_flag = ["..tostring(IsCOMBINE_MODS_flag).."]")
          print("Z:   H._bGlobalCOMBINE_MOD_TYPE = ["..H._bGlobalCOMBINE_MOD_TYPE.."]")
          print("Z:        H.gIsGlobalIndividual = ["..tostring(H.gIsGlobalIndividual).."]")
          print("Z:                    H.IsPATCH = ["..tostring(H.IsPATCH).."]")
          print("Z:          H._bCombinedModType = ["..tostring(H._bCombinedModType).."]")
          print("Z:                H._bCOPYtoNMS = ["..H._bCOPYtoNMS.."]")
        end

        -- ========================
        -- ADJUST the mod name
        local _cMOD_FILENAME = string.gsub(mod_filename,"%.pak",""):gsub("%.PAK","")
        -- H.printf("A: ==> _cMOD_FILENAME = [%s]",_cMOD_FILENAME)
        -- H.printf("A: ==> H._bScriptName = [%s]",H._bScriptName)
        
        if H.gIs_MODSfolderNameScript then
          -- keep only tha script name
          _cMOD_FILENAME = H.trim(string.gsub(H.GetFilenameFromFilePath(H._bScriptName,false),"%.lua",""):gsub("%.LUA",""))
        end
        -- H.printf("B: ==> _cMOD_FILENAME = [%s]",_cMOD_FILENAME)
        
        if H.gDEBUG_ScriptTypeName then
          print("A0: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
        end
        H.DEBUG_ScriptContent_print("A: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
        -- H._bGlobalCOMBINE_MOD_TYPE:
        --    in general, a mod is named by the script MOD_FILENAME field
        --       in ModBackups and BuildHistory: modname.pak.author
        --       in IncrementalBuilds: modname_(x).pak.author
        
        -- == 0, treat as an Individual mod => modname == script MOD_FILENAME (modname.pak)
        --       or, if a patch mod, modname == ~PatchMod.pak
        -- == 1, treat as a generic combined mod with the current DATE-TIME suffix: modname == CombinedMod_DATE-TIME.pak
        -- == 2, treat as a distinct combined mod with a NUMERIC suffix: modname == CombinedMod_(x).pak
        -- == 3, treat it as an Individual mod, a COMPOSITE combined mod with the name being like: modname == Mod1+Mod2+Mod3.pak
        --
        -- If a PatchMod, use Composite_PAK_FILENAME.txt
        
        if IsCOMBINE_MODS_flag or not H.gIsGlobalIndividual then
          _cMOD_AUTHOR = "" --no author for all other types
        end
        
        local _cName = "CombinedMod_" --default name
        if H.IsPATCH then
          -- it is a patch if (PAK_MBIN defined and #SCRIPT > 0)
          -- PAK_MBIN is defined if (#PAK > 0 or #MBIN > 0)
          
          local combined = ""
          if IsCOMBINE_MODS_flag then
            combined = "COMBINED_"
          end
          
          CreateCompositePakName(H)
          _cName = "~PatchMod_"..combined..H.LoadFileData("Composite_PAK_FILENAME.txt")

          if H._bCOPYtoNMS == "SOME" then
            H._bCOPYtoNMS = "ALL"
          end
        else
          if not IsCOMBINE_MODS_flag then
            _cName = _cMOD_FILENAME
          end
        end
        
        if H.gDEBUG_ScriptTypeName then
          print("A1:         _cName = [".._cName.."]")
        end
        
        -- if IsCOMBINE_MODS_flag then
          -- _cMOD_FILENAME = H.LoadFileData("Composite_MOD_FILENAME.txt")
        -- elseif not H.gIsGlobalIndividual then
          -- if H._bGlobalCOMBINE_MOD_TYPE == 1 then _cMOD_FILENAME = _cName.."_".._cDateTime..".pak" end
          -- if H._bGlobalCOMBINE_MOD_TYPE == 2 then _cMOD_FILENAME = _cName..".pak" end
          -- if H._bGlobalCOMBINE_MOD_TYPE == 3 then _cMOD_FILENAME = H.LoadFileData("Composite_MOD_FILENAME.txt") end
        -- end
        
        local modType = H._bGlobalCOMBINE_MOD_TYPE
        if IsCOMBINE_MODS_flag then
          if H.gDEBUG_ScriptTypeName then
            H.printf("Y:    IsCOMBINE_MODS_flag = [%s]",tostring(IsCOMBINE_MODS_flag))
            H.printf("Y:                modType = [%s]",modType)
            H.printf("Y:      _bCombinedModType = [%s]",H._bCombinedModType)
          end
          if modType == 0 then
            modType = H._bCombinedModType -- 3
          end
        end
        
        if modType == 1 then
          modType = 3
        end
        
        if IsCOMBINE_MODS_flag or not H.gIsGlobalIndividual then
          if not H.IsPATCH then
            -- if modType == 1 then _cMOD_FILENAME = _cName.."_".._cDateTime..".pak" end
            if modType == 2 then
              _cMOD_FILENAME = _cName..tostring(scriptIndex)..".pak"
            end
            if modType == 3 then
              _cMOD_FILENAME = H.LoadFileData("Composite_MOD_FILENAME.txt")..".pak"
            end
          end
        end
        
        if H.gDEBUG_ScriptTypeName then
          print("A2: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
        end
        
        if not IsCOMBINE_MODS_flag and H.gIsGlobalIndividual and not H.IsPATCH then
          _cMOD_FILENAME = _cName..".pak"
        end
          -- H.printf("_cMOD_FILENAME = [%s]",_cMOD_FILENAME)
        
        if H.gDEBUG_ScriptTypeName then
          print("A3: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
        end
        
        if IsCOMBINE_MODS_flag or not H.gIsGlobalIndividual then
          -- MOD_BATCHNAME overrides all other mod names EXCEPT PatchMod
          if not H.IsPATCH then
            local _cMOD_BATCHNAME = H.LoadFileData("MOD_BATCHNAME.txt")
            if _cMOD_BATCHNAME == "" then
              _cMOD_BATCHNAME = "AMUMSS Combine_999"
            end
            if _cMOD_BATCHNAME ~= "" then
              if H._bTotalNumberScripts > 1 then
                _cMOD_FILENAME = _cMOD_BATCHNAME
              end
            end
          else
            _cMOD_FILENAME = _cName..".pak"
          end
        end
        -- END: ADJUST the mod name

        if H.gDEBUG_ScriptTypeName then
          print("A4: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
          print("W: ===> AFTER 'ADJUST the mod name'")
          print("W:    _bGlobalCOMBINE_MOD_TYPE = ["..H._bGlobalCOMBINE_MOD_TYPE.."]")
          print("W:         IsCOMBINE_MODS_flag = ["..tostring(IsCOMBINE_MODS_flag).."]")
          print("W:                     modType = ["..modType.."]")
        end
        -- ========================

        H.DEBUG_ScriptContent_print("Before get list of files in MODBUILDER\\MOD")
        -- check in MOD if we really have something to pak beside the script
        local fileList = {}
        fileList = H.ListDir(fileList,[[.\MOD]],nil,true,false)
        
        local foundFilesTopak = false
        if #fileList > 0 then
          local sFileList = table.concat(fileList)
          -- printf("#fileList = %d",#fileList)
          -- printf("#sFileList = %d",#sFileList)
          -- printf("sFileList = %s",sFileList)
          H.DEBUG_ScriptContent_print("After getting list of files in MODBUILDER\\MOD")
          -- first one of these EXT found, we are ok to create pak
          local searchFor = {".MBIN",".DDS",".WEM",".BIN",".JSON",".H",".FNT",".MXML",".PNG",".TTC",".TTF",".XML",".CVS"}
          for i=1,#searchFor do
            local _,n = string.gsub(sFileList,searchFor[i],"",1)
            if n > 0 then
              foundFilesTopak = true
              break
            end
          end
        end
        -- END: check in MOD if we really have something to pak beside the script
        
        H.createdMODName = ""
        if not foundFilesTopak then
          if not H.IsArguments then
            print("")
            print("   "..H.gcNOTICE.." [NOTICE] Nothing to create. Not creating MOD for this script "..H._zDEFAULT)
            -- print("   "..H.gcNOTICE.."        Make sure all your file extensions are UPPERCASE        "..H._zDEFAULT)
            H.Report("","Nothing to create. Not creating MOD for this script","NOTICE")
            -- H.Report("",".         Make sure all your file extensions are UPPERCASE")
            H.Report()
          end
        else --foundFilesTopak
          -- @@@@ _cMOD_FILENAME == modname.pak @@@@
          local prefix = "________________" -- used to help keep backup folders on top of explorer display
          
          H.backupEXT = ".pak"
          H.CopyFlag = [[*]]
          if H.BackupType == "PAK" then
            H.backupEXT = ".pak"
          elseif H.BackupType == "7Z" then
            H.backupEXT = ".7z"
          elseif H.BackupType == "ZIP" then
            H.backupEXT = ".zip"
          elseif H.BackupType == "NONE" then
            -- always a folder
            H.backupEXT = ""
            H.CopyFlag = [[\]]
          else
            print(H.gcWARNING.."@@@ Bad -BackupType option in BUILDMOD_AUTO.bat, using PAK "..H._zDEFAULT)
            H.Report("","Bad -BackupType option in BUILDMOD_AUTO.bat, using PAK","WARNING")
          end
          -- H.printf("H.backupEXT = [%s]",H.backupEXT)
          -- H.printf("H.CopyFlag  = [%s]",H.CopyFlag)
          
          local _cDestination = [[..\ModBackups\]]..prefix..[[IncrementalBuilds]]
          -- remove .pak
          local _cFilename = string.gsub(_cMOD_FILENAME,"%.pak",""):gsub([[%.PAK]],"")
          -- H.printf("_cFilename = [%s]",_cFilename)
          -- @@@@ _cFilename == modname @@@@
          H.DEBUG_ScriptContent_print("B: _cMOD_FILENAME = [".._cMOD_FILENAME.."]")
          H.DEBUG_ScriptContent_print("B: _cFilename = [".._cFilename.."]")
          
          -- ***** HANDLE IncrementalBuilds maxIncrementalBuilds versions
          local maxIncrementalBuilds = tonumber(os.getenv("-IncrementalBuilds")) ~= nil
          if maxIncrementalBuilds then
            maxIncrementalBuilds = tonumber(os.getenv("-IncrementalBuilds")) - 1
          else
            maxIncrementalBuilds = 2 -- it means there will be 1 current and 2 previous builds
          end
          if maxIncrementalBuilds <= 0 then
            maxIncrementalBuilds = 2
          end
          H.nextFilenameNum = maxIncrementalBuilds
          
          -- print("current dir = ["..lfs.currentdir().."]")
          local newestMaxFilename = _cDestination..[[\]].._cFilename.."_("..maxIncrementalBuilds..")"..H.backupEXT --.._cMOD_AUTHOR
          -- H.printf("A: newestMaxFilename = [%s]",newestMaxFilename)

          if (H.backupEXT == "" and H.IsDirExist(newestMaxFilename)) or H.IsFileExist(newestMaxFilename) then
            -- the (maxIncrementalBuilds) file exist
            -- we need to delete (0 is oldest) and move all others down maxIncrementalBuilds->0
            -- to make room for the new (maxIncrementalBuilds is newest)
            
            if H.backupEXT == "" then
              H.DeleteDir(_cDestination..[[\]].._cFilename.."_(0)")
            else
              H.DeleteFile(_cDestination..[[\]].._cFilename.."_(0)"..H.backupEXT) --.._cMOD_AUTHOR
            end
            -- H.printf("A: Deleted = [%s]",_cDestination..[[\]].._cFilename.."_(0)"..H.backupEXT.."]") --.._cMOD_AUTHOR
            -- H.WFAK("A:...")
            
            --    rename all others paks from 1->maxIncrementalBuilds to 0->maxIncrementalBuilds-1
            for i=0,maxIncrementalBuilds-1 do
              local nextFilename = _cDestination..[[\]].._cFilename..[[_(]]..(i+1)..[[)]]..H.backupEXT --.._cMOD_AUTHOR
              
              if (H.backupEXT == "" and H.IsDirExist(nextFilename)) or H.IsFileExist(nextFilename) then
                -- H.printf("A:      nextFilename = [%s]",nextFilename)
                -- H.DeleteFile(_cFilename..[[_(]]..i..[[).pak]]) --.._cMOD_AUTHOR
                -- rename i+1 to i
                local cmd = [[ren "]]..nextFilename..[[" "]].._cFilename..[[_(]]..i..[[)]]..H.backupEXT --..[[" 1>NUL 2>NUL]] --.._cMOD_AUTHOR
                -- print("A: cmd = ["..cmd.."]")
                H.NewThread(cmd)
-- H.WFAK("Just renamed cmd: ["..cmd.."]")            
              else
                break
              end
            end
            
          else
            -- print("B: ["..newestMaxFilename.."] does not exist")
            -- we just need to find the last one
            H.nextFilenameNum = 0
            for i=0,maxIncrementalBuilds do
              local nextFilename = _cDestination..[[\]].._cFilename..[[_(]]..i..[[)]]..H.backupEXT --.._cMOD_AUTHOR
              -- print("B:      nextFilename = ["..nextFilename.."]")
              if (H.backupEXT == "" and H.IsDirExist(nextFilename)) or H.IsFileExist(nextFilename) then
                -- print("                  exist")
                H.nextFilenameNum = i + 1
              else
                break
              end
            end
          end
          -- H.printf("C: H.nextFilenameNum = [%s]",H.nextFilenameNum)
          
          local nextFnum = H.nextFilenameNum + 1
          local nextF = _cDestination..[[\]].._cFilename..[[_(]]..nextFnum..[[)]]..H.backupEXT  --.._cMOD_AUTHOR
          while (H.backupEXT == "" and H.IsDirExist(nextF)) or H.IsFileExist(nextF) do
            -- H.printf("C: nextF = [%s]",nextF)
            if H.backupEXT == "" then
              H.DeleteDir(nextF)
            else
              H.DeleteFile(nextF)
            end
            nextFnum = nextFnum + 1
            nextF = _cDestination..[[\]].._cFilename..[[_(]]..nextFnum..[[)]]..H.backupEXT --.._cMOD_AUTHOR
          end
          -- H.WFAK("END: HANDLE IncrementalBuilds")            
          -- ***** END: HANDLE IncrementalBuilds maxIncrementalBuilds versions
          
          local pakDestPathFromMODfolder = [[..\]].._cDestination
          H.DEBUG_ScriptContent_print(" pakDestPathFromMODfolder = ["..pakDestPathFromMODfolder.."]")
          
          local pakFilename = _cFilename..H.backupEXT --.._cMOD_AUTHOR
          
          local pakFilenameInc = _cFilename..[[_(]]..H.nextFilenameNum..[[)]]..H.backupEXT -- .._cMOD_AUTHOR
          
          if _cFilename == "CombinedMod_" then
            local index = 0
            pakFilenameInc = _cFilename..tostring(index)..[[_(]]..H.nextFilenameNum..[[)]]..H.backupEXT -- .._cMOD_AUTHOR
            
            -- make sure we do not have 2 CombineMod_ with the same name
            while true do
              if H.IsFileExist([[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc) then
                index = index + 1
                pakFilenameInc = _cFilename..tostring(index)..[[_(]]..H.nextFilenameNum..[[)]]..H.backupEXT -- .._cMOD_AUTHOR
              else
                break
              end
            end
          end
          -- H.printf("G:    pakFilename = [%s]",pakFilename)
          -- H.printf("G: pakFilenameInc = [%s]",pakFilenameInc)
          
          -- H.Dprintf("BEFORE  create BACKUP "..H.dClock())
          -- H.WFAK()

          print("")
          -- ****************  creates the not/compressed backup in ModBackups  *****************
          local function CreateCompressedBackup(H, FileName, DestPathFromMODfolder)            
            -- H.printf("CB==> DestPathFromMODfolder = [%s]",DestPathFromMODfolder)
            -- H.printf("CB==>              FileName = [%s]",FileName)
            -- H.printf("CB==>          H.BackupType = [%s]",H.BackupType)
            -- H.printf("CB==>           H.backupEXT = [%s]",H.backupEXT)
            
            if not H.DEBUG_PSARC then
              print(">>>  Creating backup file")
              H.Report("",">>>  Created backup file")
            end

            if H.BackupType == "PAK" then
              local status = H.psarc_CL("CREATE", [[..\ModBackups\]]..prefix..[[BuildHistory\]], FileName, true, (H.gIs_LEAN_MODE or not H.DEBUG_PSARC))
              if status ~= "OK" then
                print(H.gcWARNING.."@@@ psarc reported: "..status.." "..H._zDEFAULT)
                -- H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": ".._bScriptName..[[: Failed to pack files in MODBUILDER\MOD]]
              end
             
            elseif H.BackupType == "7Z" then
              H.DeleteFile([[..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName..[[.7z]],false)
              local cmd = [[7z.exe a "..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName..[[" "..\CreatedMODS\]]..FileName:gsub(H.GetExtensionFromFilePath(FileName),"")..[[\" 1>nul 2>nul]]
              -- H.printf("CB==> cmd = [%s]",cmd)
              local state,str,num = os.execute(cmd) --fast and same output as batch
              local success = ""
              if state then
                success = "OK"
              else
                success = "zipError"
              end
              if success ~= "OK" then
                print(H.gcWARNING..[[@@@ 7z.exe could not create backup .7z to ModBackups\]]..prefix..[[BuildHistory\]]..FileName:gsub(H.GetExtensionFromFilePath(FileName),"")..[[ ]]..H._zDEFAULT)
              end
              
            elseif H.BackupType == "ZIP" then
              H.DeleteFile([[..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName..[[.zip]],false)
              local cmd = [[7z.exe a "..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName..[[" "..\CreatedMODS\]]..FileName:gsub(H.GetExtensionFromFilePath(FileName),"")..[[\" 1>nul 2>nul]]
              -- H.printf("CB==> cmd = [%s]",cmd)
              local state,str,num = os.execute(cmd) --fast and same output as batch
              local success = ""
              if state then
                success = "OK"
              else
                success = "zipError"
              end
              if success ~= "OK" then
                print(H.gcWARNING..[[@@@ 7z.exe could not create backup .zip to ModBackups\]]..prefix..[[BuildHistory\]]..FileName:gsub(H.GetExtensionFromFilePath(FileName),"")..[[ ]]..H._zDEFAULT)
              end
              
            elseif H.BackupType == "NONE" then
              H.DeleteDir([[..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName)
              H.mkdir([[..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName)
              H.CopyFile([[..\CreatedMODS\]]..FileName, [[..\ModBackups\]]..prefix..[[BuildHistory\]]..FileName..[[\]], [[/s /y /h /j /EXCLUDE:xcopy_excludeMXML.txt]]) -- with folders and sub-folders
              
            end
            print("")
            -- H.Dprintf("AFTER  create BACKUP "..H.dClock())
          end
          -- ****************  END: creates the not/compressed backup in ModBackups  *****************

          -- H._bGlobalCOMBINE_MOD_TYPE:
          --    in general, a mod is named by the script MOD_FILENAME field
          --       in ModBackups and BuildHistory: modname.pak.author
          --       in IncrementalBuilds: modname_(x).pak.author
          
          -- == 0, treat as an Individual mod => modname == script MOD_FILENAME (modname.pak)
          --       or, if a patch mod, modname == PatchMod.pak
          -- == 1, treat as a generic combined mod with the current DATE-TIME suffix: modname == CombinedMod_DATE-TIME.pak
          -- == 2, treat as a distinct combined mod with a NUMERIC suffix: modname == CombinedMod_(x).pak
          -- == 3, treat it as an Individual mod, a COMPOSITE combined mod with the name being like: modname == Mod1+Mod2+Mod3.pak
          
          -- source is from ModBackups\IncrementalBuilds
          -- local _cDestination = [[..\ModBackups\]]..prefix..[[IncrementalBuilds]]
          local _cDestination = [[..\ModBackups\]]..prefix..[[BuildHistory]]
          local source = _cDestination..[[\]]..pakFilename
          
          -- A: AMUMSS\MODBUILDER\MOD: content of the MOD
          -- B: AMUMSS\CreatedMODS: folder of the MOD
          -- C: AMUMSS\ModBackups\]]..prefix..[[BuildHistory: packed version of B:
          -- D: AMUMSS\ModBackups\]]..prefix..[[IncrementalBuilds: packed incremental versions of B:

          -- new MODS: remove extension if any for folder
          local ext = H.GetExtensionFromFilePath(pakFilename)
          if ext then
            H.pakFilenameLessEXT = pakFilename:gsub(ext, "")
          else
            H.pakFilenameLessEXT = pakFilename
          end
          
          ext = H.GetExtensionFromFilePath(pakFilenameInc)
          if ext then
            H.pakFilenameIncLessEXT = pakFilenameInc:gsub(ext, "")
          else
            H.pakFilenameIncLessEXT = pakFilenameInc
          end
          
          -- H.createdMODName = [[..\CreatedMODS\]]..H.pakFilenameLessEXT
          -- H.mkdir(H.createdMODName)

          -- new MODS: copy NODBUILDER\MOD loose files to this new folder
          -- MOD->CreatedMODS->modFolder
          if strfind(H.pakFilenameLessEXT,"AMUMSS Combine",1,true) then
            local N = 999
            while H.IsDirExist(H.gNMS_MODS_FOLDER..H.pakFilenameLessEXT) do
              H.pakFilenameLessEXT = strsub(H.pakFilenameLessEXT,1,strfind(H.pakFilenameLessEXT,[[_]]))..N
              N = N - 1
            end
            pakFilename = H.pakFilenameLessEXT..ext
          end
          
          if H.UpdateMODDER_Helper then
            -- we need to copy the ORIGINAL _TEMP\DECOMPILED files for this mod into TOOLS\MODDER_Helper\{thismod}\_ORG_MXML
            local ListFiles = H.ListDir(ListFiles, [[.\MOD]], true, true)
            for i=1,#ListFiles do
              -- H.printf("===>> ListFiles[%d] = [%s]",i,ListFiles[i])
              local ext = H.GetExtensionFromFilePath(ListFiles[i]):upper()
              
              if ext == ".MXML" or ext == ".EXML" or ext == ".MBIN" then
                local tmp = ListFiles[i]:gsub([[.\MOD\]],""):gsub([[%.MXML]],[[.MBIN]]):gsub([[%.EXML]],[[.MBIN]]) 
                if strfind(tmp,"GLOBALS.",1,true) or strfind(tmp,".GLOBAL.",1,true) then
                  tmp = [[GLOBALS\]]..tmp
                end
                -- H.printf("   tmp = [%s]",tmp)
                if H.gFastPAKlist[tmp] then
                  tmp = tmp:gsub([[.EXML]],[[.MXML]]):gsub([[.MBIN]],[[.MXML]])
                  -- H.printf(" - ListFiles[%d] = [%s]",i,tmp)
                  -- H.printf("source = [%s]",[[..\MODBUILDER\_TEMP\DECOMPILED\]]..tmp)
                  -- H.printf("  dest = [%s]",[[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\_ORG_MXML\]]..tmp..[[*]])
                  H.CopyFile([[..\MODBUILDER\_TEMP\DECOMPILED\]]..tmp, [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\_ORG_MXML\]]..tmp..[[*]],H.paramFilesDir)
                end
              end              
            end -- for i=1,#ListFiles do
          end -- if H.UpdateMODDER_Helper then
          
          -- ==================  FOR EVERY TYPE  ==========================
          if H.UpdateMODDER_Helper then
            print([[>>>  Copying files to TOOLS\MODDER_Helper...]])
            H.CopyFile(H.gPathToModbuilderMod, [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\]], H.paramFilesDir) -- with folders and sub-folders, exclude .vscode
            -- cleanup MOD\LocTable.txt
            -- H.DeleteFile(H.gPathToModbuilderMod..[[\LocTable.txt]],false,true)
          end
          
          -- copy ALL files in MODBUILDER\MOD to CreatedMODS mod sub-folder
          H.CopyFile(H.gPathToModbuilderMod, [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]], H.paramExcMXML) -- with folders and sub-folders, exclude MXML, .vscode

          -- create EXMLs and copy to TOOLS\MODDER_Helper and CreatedMODS mod sub-folder (deleting the MBIN)
          -- *********************  Create EXML files

                  -- print("==> H.clonedMXMLmodTable:")
                  -- for k,v in pairs(H.clonedMXMLmodTable) do
                    -- H.printf("[%s] = [%s]",k,v)
                  -- end
                  
                  -- print("==> H.EXMLorgTable:")
                  -- for k,v in pairs(H.EXMLorgTable) do
                    -- H.printf("[%s] = [%s]",k,v)
                  -- end
          
                  -- print("==> H.EXMLcreate:")
                  -- for k,v in pairs(H.EXMLcreate) do
                    -- H.printf("[%s] = [%s]",k,v)
                  -- end

          -- ================  Handling of script LocTable.txt  =================================================================
          -- path to a possible LocTable.txt in the script folder
          local scriptTxtPath = [[..\ModScript\]]..H.GetFolderPathFromFilePath(_bScriptName)..[[\LocTable.txt]]
          -- H.printf("==>> scriptTxtPath = [%s]",scriptTxtPath)
          if H.IsFileExist(scriptTxtPath) then
            -- a script LocTable.txt exist
            print("      -> Found a LocTable.txt in script folder")
            if H.IsFileExist([[.\MOD\LocTable.txt]]) then
              -- a MOD\LocTable.txt already exist, probably created by the script code
              print("      -> Found an existing LocTable.txt file in MOD")
              
              scriptTxt = H.LoadFileData(scriptTxtPath)
              -- H.printf("==>> Appending scriptTxt = [%s]",scriptTxt)
              H.WriteToFileAppend([[\n]]..scriptTxt,[[.\MOD\LocTable.txt]])
            else
              -- copy script LocTable.txt to MODBUILDER\MOD
              -- print("      -> File NOT in MOD, copying to MOD")
              H.CopyFile(scriptTxtPath, [[.\MOD\LocTable.txt*]], H.paramFiles)
            end
          end

          -- path to a possible LocTable.MXML in the script folder
          local scriptTxtPathmxml = [[..\ModScript\]]..H.GetFolderPathFromFilePath(_bScriptName)..[[\LocTable.mxml]]
          local scriptTxtPath = [[..\ModScript\]]..H.GetFolderPathFromFilePath(_bScriptName)..[[\LocTable.MXML]]
          
          os.rename(scriptTxtPathmxml,scriptTxtPath)
-- H.WFAK()          
          -- H.printf("==>> scriptTxtPath = [%s]",scriptTxtPath)
          if H.IsFileExist(scriptTxtPath) then
            -- a script LocTable.MXML exist
            print("      -> Found a LocTable.MXML in script folder")
            local txtTable = H.CreateLocTableTXTFromXML(H.ParseTextFileIntoTable([[.\MOD\LocTable.MXML]]),"")
            
            if H.IsFileExist([[.\MOD\LocTable.txt]]) then
              -- a MOD\LocTable.txt already exist, probably created by the script code
              print("      => Found an existing LocTable.txt file in MOD")
              
              H.WriteToFileAppend(txtTable,[[.\MOD\LocTable.txt]])
            else
              -- create script LocTable.MXML as a LocTable.txt to MODBUILDER\MOD
              -- print("      -> File NOT in MOD, creating to MOD")
              H.WriteToFile(txtTable,[[.\MOD\LocTable.txt]])
            end
          end
          -- H.WFAK("==>> END: Handling script LocTable.txt")
          -- ================  END: Handling of script LocTable.txt  =============================================================
          
          -- *********************  Create EXML files
          local EXMLcreateI = H.DictKeysToArray(H.EXMLcreate) -- so that we always do it in the same order
          -- for k,v in pairs(H.EXMLcreate) do
          for i=1,#EXMLcreateI do
            local k = EXMLcreateI[i]
            local v = H.EXMLcreate[k]
            
-- H.printf("k: - [%s]",k)
            -- H.printf("v: - [%s]",v)
            
            -- H.printf("H.linkedFiles[k]: [%s]",H.linkedFiles[k])
            -- H.printf("H.clonedMXMLmodTable[k]: [%s]",H.clonedMXMLmodTable[k])

            if H.linkedFiles[k] == nil and H.clonedMXMLmodTable[k] then
              -- NOT a linked file and in the clonedMXMLmodTable, OK to proceed
-- H.printf("   v = [%s]",v)
              -- H.printf([=[   path = [%s]]=],H.gPathToModbuilderMod..strgsub(k,[[GLOBALS\]],"")..[[.MBIN]])
              if H.IsFileExist(H.gPathToModbuilderMod..strgsub(k,[[GLOBALS\]],"")..[[.MBIN]]) then
                -- the MXML file is a valid one
                if H.gFastPAKlist[v:gsub([[%.MXML]],[[.MBIN]])] then
                  -- a genuine NMS file
                  H.printf(">>>  "..H._zBRIGHTORANGE.."Creating"..H._zDEFAULT.." EXML from file: "..H._zBRIGHTGREEN.."%s"..H._zDEFAULT,v)
                  H.Report("","=== Created EXML from file: ["..v.."]")
                  
                  local exml, IsValidExml = H.MXMLtoEXML(H.clonedMXMLmodTable[v:gsub([[%.MXML]],"")], H.EXMLorgTable[v:gsub([[%.MXML]],"")])

                  if exml ~= "" then
                    if not H.gIs_IncludeTagsInEXML_MXML then
                      for i=1,#exml do
                        exml[i] = exml[i]:gsub(H.modFlag..".*","")
                      end
                    end
                    
                    local tmp3 = [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\_MXMLtoEXML\]]..k..[[.EXML]]
-- H.printf("  tmp3 = [%s]",tmp3)
                    -- always try to create the folder
                    H.mkdir(H.GetFolderPathFromFilePath(tmp3))
                    H.WriteToFile(exml, tmp3)
                    
                    -- local tmp6 = [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\LANGUAGE\]]..k..[[.MXML]]
-- H.printf("  tmp6 = [%s]",tmp6)
                    if strfind(tmp3,[[\_MXMLtoEXML\LANGUAGE\]],1,true) then
                    -- if strfind(tmp6,[[\LANGUAGE\]],1,true) then
                      -- found a LANGUAGE file: make it a LocTable.txt instead
                      
                      local txt = H.CreateLocTableTXTFromXML(exml,"")
                      
                      local tmp5 = [[.\MOD\LocTable.txt]]
                      -- H.printf("  tmp5 = [%s]",tmp5)
                      
                      if H.IsFileExist(tmp5) then
                        H.WriteToFileAppend(txt, tmp5)
                      else
                        H.WriteToFile(txt, tmp5)
                      end
                      -- H.WFAK()
                      
                    else
                      
                      local tmp4 = [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..k..[[.EXML]]
                      -- H.printf("  tmp4 = [%s]",tmp4)

                      H.mkdir(H.GetFolderPathFromFilePath(tmp4))
                      H.WriteToFile(exml, tmp4)                      
                    end

                    if IsValidExml then
                      -- delete the MBIN in CreatedMODS
                      if strfind(v,"GLOBALS.",1,true) or strfind(v,".GLOBAL.",1,true) then
                        -- this is a GLOBALS
                        H.DeleteFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..k:gsub([[GLOBALS\]],"")..[[.MBIN]],false,true)
                      else
                        H.DeleteFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..k..[[.MBIN]],false,true)
                      end
                    else
                      if strfind(v,"GLOBALS.",1,true) or strfind(v,".GLOBAL.",1,true) then
                        -- this is a GLOBALS
                        H.DeleteFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..k:gsub([[GLOBALS\]],"")..[[.EXML]],false,true)
                      else
                        H.DeleteFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..k..[[.EXML]],false,true)
                      end
                      print(">>> "..H.gcNOTICE..[[ [NOTICE] Could not create a valid EXML, keeping MBIN in CreatedMODS ]]..H._zDEFAULT)
                      H.Report("",[[>>> Could not create a valid EXML, keeping MBIN in CreatedMODS]],"NOTICE")
                    end
                    -- TODO ???: check if ModScript\modderFolder\modNameFolder\_MXMLtoEXML_REFERENCE exist
                    
                  else
                    print(">>> "..H.gcNOTICE..[[ [NOTICE] Created EXML is empty! ]]..H._zDEFAULT)
                    H.Report("",[[>>> Created EXML is empty!]],"NOTICE")
                  end
                end
              end
            end
          end -- for k,v in pairs(H.EXMLcreate) do
          -- print("END: CREATE THESE EXML:")
          print("")
          -- *********************  END: Create EXML files
-- H.WFAK("WAITING before <Create LocTable.MXML from LocTable.txt>")
          -- Create LocTable.MXML from LocTable.txt
          if H.IsFileExist([[.\MOD\LocTable.txt]]) then
            print("")
            print("==> Found LocTable.txt, "..H._zBRIGHTORANGE.."creating"..H._zDEFAULT..H._zBRIGHTGREEN.." LocTable.MXML"..H._zDEFAULT.."...")
            print("")
            H.Report("","==> Found LocTable.txt, created LocTable.MXML...")
          
            if H.IsFileExist([[.\MOD\LocTable.MXML]]) then
              -- file must have been created by the script
              -- we need to append this LocTable.MXML to our LocTable.txt
              local txt = H.CreateLocTableTXTFromXML(H.ParseTextFileIntoTable([[.\MOD\LocTable.MXML]]),"")
              H.WriteToFileAppend(txt,[[.\MOD\LocTable.txt]])
            end
            
            -- HERE, ALL info has been appended in the LocTable.txt, we can create the MXML
            
            local locTableTxt = H.ParseTextFileIntoTable([[.\MOD\LocTable.txt]])
            -- H.printf("==>> #locTableTxt = %d",#locTableTxt)
            
            local loc = H.CreateLocTableMXMLfromTXT(locTableTxt)
            
-- print()
-- print("== == == == == ==")
-- for i=1,#loc do
  -- H.printf("%s",loc[i])
-- end
-- print("== == == == == ==")
-- print()
-- H.WFAK([[WAITING before <writing to .\MOD\LocTable.MXML>]])
            
            H.WriteToFile(loc, [[.\MOD\LocTable.MXML]])
            
            -- recreate the final LocTable.txt from the MXML
            local txt = H.CreateLocTableTXTFromXML(loc)
            H.WriteToFile(txt,[[.\MOD\LocTable.txt]])
            
          elseif H.IsFileExist([[.\MOD\LocTable.MXML]]) then
            -- no LocTable.txt exist: let us create a LocTable.txt from this LocTable.MXML
            local txt = H.CreateLocTableTXTFromXML(H.ParseTextFileIntoTable([[.\MOD\LocTable.MXML]]))
            H.WriteToFile(txt,[[.\MOD\LocTable.txt]])
          end
          
          -- -- FOR DEBUG ONLY
            -- H.CopyFile(H.gPathToModbuilderMod..[[LocTable.txt]], [[..\TOOLS\MODDER_Helper\LocTable.txt*]], H.paramFiles) -- only ALL files
            -- H.CopyFile(H.gPathToModbuilderMod..[[LocTable.MXML]], [[..\TOOLS\MODDER_Helper\LocTable.MXML*]], H.paramFiles) -- only ALL files
          
          -- handle LocTable exception

            -- local tmp6 = [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\LANGUAGE\]]..k..[[.MXML]]
-- H.printf("  tmp6 = [%s]",tmp6)
            -- if strfind(tmp6,[[\LANGUAGE\]],1,true) then
            
-- H.WFAK("WAITING before <Checking if CreatedMODS/modname/LANGUAGE folder exist>")
            if H.IsDirExist([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\LANGUAGE\]]) then
H.printf("bbb #H.customLanguageFiles = %d, [%s]",#H.customLanguageFiles,tostring(H.IsEXML_CREATE_GLOBAL))
              if #H.customLanguageFiles == 0 and H.IsEXML_CREATE_GLOBAL then
                -- we do not need this folder, remove LANGUAGE sub-folder from CreatedMODS mod folder
                H.DeleteDir([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\LANGUAGE]])
                
              else
  -- WBERTRO: THIS IS NOT DONE
                -- if LANGUAGE file is in H.EXMLcreate[H.NMSPathFileLessEXML] then
                --    it can be removed from CreatedMODS\LANGUAGE
                
                -- if all LANGUAGE files are removed, we can delete the folder
                
                -- elseif H.IsEXMLcreateTRUE then
                      -- local tmp3 = [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\_MXMLtoEXML\]]..k..[[.EXML]]
  -- H.printf("  tmp3 = [%s]",tmp3)
                      -- -- always try to create the folder
                      -- H.mkdir(H.GetFolderPathFromFilePath(tmp3))
                      -- H.WriteToFile(exml, tmp3)
                      
                      -- -- local tmp6 = [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\LANGUAGE\]]..k..[[.MXML]]
  -- -- H.printf("  tmp6 = [%s]",tmp6)
                      -- if strfind(tmp3,[[\_MXMLtoEXML\LANGUAGE\]],1,true) then

                  -- -- We should check if each individual LANGUAGE file is 
-- H.printf("H.customLanguageFiles = %d",#H.customLanguageFiles)
                -- H.CopyFile([[Enable MXML Output]], [[..\CreatedMODS\]]..H.AMUMSSstring..[[EnableMXMLOutput\]],H.paramFilesDir)
                
              end
            end
-- H.WFAK("WAITING after <Checking if CreatedMODS/modname/LANGUAGE folder exist>")
            
            H.CopyFile(H.gPathToModbuilderMod..[[LocTable.txt]], [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\LocTable.txt*]], H.paramFiles) -- only ALL files
            H.CopyFile(H.gPathToModbuilderMod..[[LocTable.txt]], [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\LocTable.txt*]], H.paramFiles) -- only ALL files

            H.CopyFile(H.gPathToModbuilderMod..[[LocTable.MXML]], [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\LocTable.MXML*]], H.paramFiles) -- only ALL files
            H.CopyFile(H.gPathToModbuilderMod..[[LocTable.MXML]], [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\LocTable.MXML*]], H.paramFiles) -- only ALL files
          -- END: handle LocTable exception
          
          if H.EXPORTED then
            if not H.IsDirExist([[..\CreatedMODS\Enable MXML Output\]]) then
              -- TURN ON NMS EXPORTED FEATURE
              H.CopyFile([[Enable MXML Output]], [[..\CreatedMODS\]]..H.AMUMSSstring..[[EnableMXMLOutput\]],H.paramFilesDir)
            end
            
            local ListFiles = H.ListDir(ListFiles, [[..\CreatedMODS\]]..H.pakFilenameLessEXT, true, true)
            for i=1,#ListFiles do
              local ext = H.GetExtensionFromFilePath(ListFiles[i]):upper()
              if ext == ".MBIN" or ext == ".EXML" then
                local tmp = ListFiles[i]:gsub(H.escapeMagicString([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]),""):gsub([[%.EXML]],[[.MBIN]])
                if not strfind(tmp,[[^GLOBALS\]]) and (strfind(tmp,"GLOBALS.",1,true) or strfind(tmp,".GLOBAL.",1,true)) then
                  tmp = [[GLOBALS\]]..tmp
                end
                if H.gFastPAKlist[tmp] then
                  tmp = tmp:gsub([[%.MBIN]],[[.EXML]])
                  -- H.printf(" - ListFiles[%d] = [%s]",i,tmp)
                  -- H.printf("  dest = [%s]",[[..\CreatedMODS\]]..H.AMUMSSstring..[[EXPORT_THESE\]]..tmp..[[*]])
                  H.CopyFile([[.\MODDER_Snippets\TEMPLATE.EXML]], [[..\CreatedMODS\]]..H.AMUMSSstring..[[EXPORT_THESE\]]..tmp..[[*]], H.paramFiles)
                end
              end
            end
-- H.WFAK("END of EXPORTED ENABLED")
          end
          
          -- MOD->ModBackups->modFolder
          H.DeleteDir([[..\ModBackups\]]..H.pakFilenameLessEXT)
          H.CopyFile(H.gPathToModbuilderMod, [[..\ModBackups\]]..H.pakFilenameLessEXT..[[\]], H.paramExcMXML)
          -- ==================  END: FOR EVERY TYPE  ==========================
          
          -- if H._bGlobalCOMBINE_MOD_TYPE == 2 and not IsCOMBINE_MODS_flag then --like CombinedMod_(x).pak
          if IsCOMBINE_MODS_flag and modType == 2 then --like CombinedMod_(x).pak
            -- H.printf("A: saving Content for %s","Distinct")
            -- H.printf("A: pakFilenameInc = [%s]",pakFilenameInc)

            -- Mod pak content required when distinct combined
            H.CopyFile("COMBINED_CONTENT_LIST.txt", [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
            
            if H.UpdateMODDER_Helper then
              H.CopyFile("COMBINED_CONTENT_LIST.txt", [[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
            end
            
            CreateCompressedBackup(H, pakFilename, [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]])

            H.CopyFile(source,[[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc..H.CopyFlag,H.paramFiles)              
            -- H.CopyFile(source,[[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilenameInc..H.CopyFlag,H.paramFiles)
            
            -- Mod pak content required when distinct combined
            H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc..[[_content.txt*]],H.paramFiles)
            H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename..[[_content.txt*]],H.paramFiles)
            
            -- if H.IsFileExist([[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename) then
              -- print(">>> Created this MOD: "..H._zBRIGHTORANGE.."'"..H.pakFilenameLessEXT.."'"..H._zDEFAULT)
              -- H.Report("")
              -- H.Report("","Created this MOD: '"..H.pakFilenameLessEXT.."'")
            -- end
            
          elseif IsCOMBINE_MODS_flag and modType == 1 then --like CombinedMod_DATE-TIME_(x).pak
            -- H.printf("A: saving Content for %s","Generic")
            -- H.printf("A: pakFilenameInc = [%s]",pakFilenameInc)

            -- Mod pak content required when distinct combined
            H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
            
            if H.UpdateMODDER_Helper then
              H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
            end
            
            CreateCompressedBackup(H, pakFilename, [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]])

            H.CopyFile(source,[[..\ModBackups\]]..prefix..[[IncrementalBuilds]]..pakFilenameInc..H.CopyFlag,H.paramFiles)              
            -- H.CopyFile(source,[[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilenameInc..H.CopyFlag,H.paramFiles)
            
            -- Mod pak content required when distinct combined
            H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc..[[_content.txt*]],H.paramFiles)
            H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename..[[_content.txt*]],H.paramFiles)
            
            -- if H.IsFileExist([[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename) then
              -- print(">>> Created this MOD: "..H._zBRIGHTORANGE.."'"..H.pakFilenameLessEXT.."'"..H._zDEFAULT)
              -- H.Report("")
              -- H.Report("","Created this MOD: '"..H.pakFilenameLessEXT.."'")
            -- end
            
          else --Individual or combined mods type 0 or 3
            -- H.printf("B: saving Content for %s","Individual, Patch, Composite or FLAG combine")
            -- H.printf("B: pakFilenameInc = [%s]",pakFilenameInc)
            
            if IsCOMBINE_MODS_flag then
              -- new MODS
              H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
              
              if H.UpdateMODDER_Helper then
                H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\TOOLS\MODDER_Helper\]]..H.pakFilenameLessEXT..[[\]]..H.pakFilenameLessEXT..[[_content.txt*]],H.paramFiles)
              end
            end
            
            CreateCompressedBackup(H, pakFilename, [[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[\]])

            H.CopyFile(source,[[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc..H.CopyFlag,H.paramFiles) -- ,false
            
            -- if H._bGlobalCOMBINE_MOD_TYPE == 1 or H._bGlobalCOMBINE_MOD_TYPE == 3 or IsCOMBINE_MODS_flag then
            if IsCOMBINE_MODS_flag then
              -- Mod pak content required when combined
              H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[IncrementalBuilds\]]..pakFilenameInc..[[_content.txt*]],H.paramFiles)
              H.CopyFile("COMBINED_CONTENT_LIST.txt",[[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename..[[_content.txt*]],H.paramFiles)
            end
            
            -- if H.IsFileExist([[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename) then
              -- print(">>> Created this MOD: "..H._zBRIGHTORANGE.."'"..H.pakFilenameLessEXT.."'"..H._zDEFAULT)
              -- H.Report("")
              -- H.Report("","Created this MOD: '"..H.pakFilenameLessEXT.."'")
            -- end
          end
          
          if H.IsFileExist([[..\ModBackups\]]..prefix..[[BuildHistory\]]..pakFilename) then
            print(">>> Created this MOD: "..H._zBRIGHTORANGE.."'"..H.pakFilenameLessEXT.."'"..H._zDEFAULT)
            H.Report("")
            H.Report("","Created this MOD: '"..H.pakFilenameLessEXT.."'")
          end
          
          --***** COPYING or NOT to MODS *****
          -- H.DEBUG_ScriptContent_print("=== Copying or not to MODS")
          -- print("__---__ COPYtoNMS: ["..H._bCOPYtoNMS.."]")
          if H._bCOPYtoNMS ~= "NONE" then
            local destFolder = H.gNMS_MODS_FOLDER
            
            if H._bCOPYtoNMS == "ALL" then
-- H.printf("R: H.pakFilenameLessEXT = [%s]",destFolder..[[\]]..H.pakFilenameLessEXT)
-- H.WFAK("R0:...")
              H.DeleteDir(destFolder..[[\]]..H.pakFilenameLessEXT)
-- H.WFAK("R9:...")
              if #H.combinedScriptList > 0 then
                -- this is a combine mod, let us delete all MODS folders that are in this mod
                for i=1,#H.combinedScriptList do
                  if H.combinedScriptList[i] ~= "" then
                    -- H.printf("H.combinedScriptList[%d] = [%s]",i,H.combinedScriptList[i])
                    H.DeleteDir(destFolder..[[\]]..H.combinedScriptList[i])
                  end
                end
              end
              
              H.CopyFile([[..\CreatedMODS\*.*]], destFolder..[[\]], H.paramFilesDir)
-- H.WFAK("R10:...")
              
              if not H.gIs_LEAN_MODE then
                print("")
                print(H._zBRIGHTGREEN..[[>>> Copying this MOD to NMS GAMEDATA\MODS folder...]]..H._zDEFAULT)
                -- print("")
              end
              H.Report("",[[Copied this MOD to NMS GAMEDATA\MODS folder...]])
              
              if H.IsPATCH then
                if not H.gIs_LEAN_MODE then
                  print(H._zBRIGHTGREEN..[[>>> PATCH mod: copying original MOD to NMS GAMEDATA\MODS folder...]]..H._zDEFAULT)
                  print(H.gcERROR.."      >>> You SHOULD verify that the LOAD ORDER is CORRECT! "..H._zDEFAULT)
                  -- print("")
                end
                H.Report("")
                H.Report("",[[Copied original MOD to NMS GAMEDATA\MODS folder...]],"PATCH MOD")
                H.Report("","[[>>> You SHOULD verify that the LOAD ORDER is CORRECT!]]","PATCH MOD")
                
                --H.param = [[/y /h /j]] --no /s (no folders and sub-folders)
                
                for i=1,#H.gModScriptPakDirList do
                  H.CopyFile(H.gModScriptPakDirList[i][1], destFolder..[[\]],H.paramFiles)
-- H.printf("S: H.gModScriptPakDirList[%d][1] = [%s]",i,H.gModScriptPakDirList[i][1])
                end
              end
              
            elseif H._bCOPYtoNMS == "SOME" and not IsCOMBINE_MODS_flag then
              local answer = H.AChoice(" "..H._zBLACKonYELLOW.." ??? Would you like to copy this created mod to your game folder "..H._zDEFAULT,"yn")
              if answer == "Y" then
                -- print(H._zBRIGHTGREEN..">>> Copying PAK to NMS MOD folder..."..H._zDEFAULT)
                -- H.Report("","Copied PAK to NMS MOD folder...")
                
                if not H.gIs_LEAN_MODE then
                  print("")
                  print(H._zBRIGHTGREEN..">>> Copying this MOD to NMS MOD folder..."..H._zDEFAULT)
                  -- print("")
                end
                H.Report("",[[Copied this MOD to NMS MOD folder]])
                
                if #H.combinedScriptList > 0 then
                  -- this is a combine mod, let us delete all MODS folders that are in this mod
                  for i=1,#H.combinedScriptList do
                    if H.combinedScriptList[i] ~= "" then
                      -- H.printf("H.combinedScriptList[%d] = [%s]",i,H.combinedScriptList[i])
                      H.DeleteDir(destFolder..[[\]]..H.combinedScriptList[i])
                    end
                  end
                end

                if modType == 2 then -- CopyCOMBINEDDISTINCTMODS           -- PROBABLY OBSOLETE
                  H.DeleteDir(destFolder..[[\]]..pakFilenameInc)
-- H.printf("P: pakFilenameInc = [%s]",destFolder..[[\]]..pakFilenameInc)
-- H.WFAK("P:...")
                  H.CopyFile([[..\CreatedMODS\]]..pakFilenameInc, destFolder..[[\]],H.paramExcMXML)
                  H.CopyFile([[..\CreatedMODS\]]..pakFilenameInc..[[_content.txt]], destFolder..[[\]],H.paramExcMXML)
                else
                  H.DeleteDir(destFolder..[[\]]..H.pakFilenameLessEXT)
-- H.printf("Q: H.pakFilenameLessEXT = [%s]",destFolder..[[\]]..H.pakFilenameLessEXT)
-- H.WFAK("Q:...")
                  H.CopyFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT, destFolder..[[\]],H.paramExcMXML)
                  if IsCOMBINE_MODS_flag then
                    H.CopyFile([[..\CreatedMODS\]]..H.pakFilenameLessEXT..[[_content.txt]], destFolder..[[\]],H.paramExcMXML)
                  end
                end
                -- handle LocTable.MXML exception
                H.CopyFile([[..\CreatedMODS\LocTable.MXML]], destFolder..[[\LocTable.MXML*]], H.paramFiles)
              end --if answer == "Y" then
            end --elseif H._bCOPYtoNMS == "SOME" and not IsCOMBINE_MODS_flag then
            
            print(H._zBRIGHTORANGE..[[    REMINDER: YOU may have to cleanup sub-folders from previous runs in GAMEDATA\MODS]]..H._zDEFAULT)
            print("")
            H.Report("",[[REMINDER: YOU may have to delete sub-folders from previous runs in GAMEDATA\MODS]])
          end  --if H._bCOPYtoNMS ~= "NONE" then
        end --if not foundFilesTopak then
        return H.createdMODName
      end
      --******************************** END: CreateMod() *************************************************************
      
      --******************************** UnpackDecompilePak() *************************************************************
      -- OBSOLETE for EXT_FUNC: probably
      -- could be good to generaly unpack/decompile a pak
      local function UnpackDecompilePak(H, CreatedPak)
        -- extract ALL files from paks in ModScript to MODBUILDER\MOD
        printf("   >>> Extracting ALL files from: "..H._zBRIGHTGREEN.."%s"..H._zDEFAULT,CreatedPak)
        H.Report("")
        H.Report("","Extracting ALL files from: "..CreatedPak,"")
        
        local destination = [[.\MOD]]
        local success = H.psarc_E([[]], CreatedPak, destination, "", "-y -q")
        -- printf("success = [%s]",success)
        if success ~= "OK" then
          print(">>> "..H.gcWARNING.." [WARNING] Could not extract ALL files from MOD "..H._zDEFAULT)
          H.Report("","Could not extract ALL files from MOD","WARNING")
        end                  
        
        -- remove all .txt, .cs files (like AMUMSS.vW.X.Y.Z.txt)
        H.DeleteFile(destination..[[\*.txt]])
        H.DeleteFile(destination..[[\*.cs]])
        
        -- decompile MBIN files (they may not be in MBIN_table and would be deleted at the end)
        local status,result = H.MBINCompiler_D(destination,false,false,true,"     @@@ decompiling MBINs from mods...",true)
        -- H.printf("status = [%s], result = [%s]",status,result)

        -- NOW check the log
        arg[1] = "..\\" -- path to REPORT.lua
        arg[2] = "" -- path to MODBUILDER
        arg[3] = "Decompiling" -- a message
        arg[4] = "keepOpen" -- do NOT close Report
        arg[5] = "quiet" -- no message
        dofile("CheckMBINCompilerLOG.lua")
        -- print(">>> AFTER CheckMBINCompilerLOG")
        
        H.switchBACK = false
        if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
          if not gIsCompilerVersionsEqual then
            -- print("     Trying the other MBINCompiler...")
            H.SwitchToOtherMBINCompiler(H,"AMUMSS")
            
            -- decompile MBIN files (they may not be in MBIN_table and would be deleted at the end)
            local status,result = H.MBINCompiler_D(destination,false,false,true,"     @@@ decompiling MBINs from mods...",true)
            -- H.printf("status = [%s], result = [%s]",status,result)
            
            H.switchBACK = true
            -- SwitchBackToDeclaredMBINCompiler(H,true)
            
            -- NOW check the log
            arg[1] = "..\\" -- path to REPORT.lua
            arg[2] = "" -- path to MODBUILDER
            arg[3] = "Decompiling" -- a message
            arg[4] = "keepOpen" -- do NOT close Report
            arg[5] = "quiet" -- no message
            dofile("CheckMBINCompilerLOG.lua")
            -- print(">>> AFTER CheckMBINCompilerLOG")                      
          end -- if not gIsCompilerVersionsEqual then
          
          if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
            print("     @@@ "..H._zBRIGHTRED.." MBINCompiler reported problems decompiling files from "..H._zDEFAULT..H._zBRIGHTGREEN.." "..CreatedPak.." "..H._zDEFAULT)
            print(H.gcWARNING..[[>>>      [WARNING] The mod will not affect the game as it is supposed to ]]..H._zDEFAULT)
            print(H.gcNOTICE..[[>>> A script should be created to handle the changes in the failed MBINs ]]..H._zDEFAULT)

            H.Report("","MBINCompiler reported problems decompiling files",CreatedPak,"")                      
            H.Report("",[[The mod will not affect the game as it is supposed to]],"   WARN")
            H.Report("",[[A script should be created to handle the changes in the failed MBINs]],"   WARN")
          end
        end -- if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
        -- all files decompiled ok
      end

      if H.switchBACK then
        SwitchBackToDeclaredMBINCompiler(H,true)
      end      
      --******************************** END: UnpackDecompilePak() *************************************************************
      
      if H.gDEBUG_ScriptTypeName then
        print("X: ===> BEFORE CreateMod now OR wait")
        print("X:                 _bScriptName = [".._bScriptName.."]")
        print("X:            H._bScriptCounter = ["..H._bScriptCounter.."]")
        print("X:       H._bTotalNumberScripts = ["..H._bTotalNumberScripts.."]")
        print("X:        H.gIsGlobalIndividual = ["..tostring(H.gIsGlobalIndividual).."]")
        print("X:          IsCOMBINE_MODS_flag = ["..tostring(IsCOMBINE_MODS_flag).."]")
        print("X:       IsEndCOMBINE_MODS_flag = ["..tostring(IsEndCOMBINE_MODS_flag).."]")
        print("X:          H.IsSkipCreatingPAK = ["..tostring(H.IsSkipCreatingPAK).."]")
      end

      if H.gIsGlobalIndividual and not IsCOMBINE_MODS_flag then
        -- an Individual mod
        -- create mod after each script is processed
        if not H.IsSkipCreatingPAK then
          if not H.gIs_LEAN_MODE then
            print(">>> [INFO]"..H._zBRIGHTGREEN.." Building MOD now..."..H._zDEFAULT)
          end
          
          H.createdMODName = CreateMod(H,_bScriptName,H._bScriptCounter,NMS_MOD_DEFINITION_CONTAINER)
          -- print(" = = = CLEANING EXML TABLES = = =")
          H.EXMLorgTable = {} -- BECAUSE sometimes a script does a Copying/renaming to the name of an original EXML
          H.EXMLorgExtTable = {}
          H.EXMLmodTable = {}
          H.EXMLcreate = {}
          H.clonedMXMLmodTable = {}
          H.customLanguageFiles = {}
          
          -- H.IsExFunc does NOT need to create a pak anymore, so no unpack
          -- if H.IsExFunc and H.createdMODName ~= "" then
            -- UnpackDecompilePak(H, H.createdMODName)
          -- end
          
        else
          print(">>> [INFO]"..H._zBRIGHTGREEN.." Skipping Building MOD, no MXML_CHANGE_TABLE to process"..H._zDEFAULT)
          print("")
          H.Report("","Skipping MOD creation, no MXML_CHANGE_TABLE to process")
        end
        
        if not H.IsSkipCreatingPAK then
          H.Report("")
          H.Report("","Ending MBIN/MOD phase...")
        end
        
       elseif H._bScriptCounter == H._bTotalNumberScripts or IsEndCOMBINE_MODS_flag then
        --H._bTotalNumberScripts is OK to use for global combine
        --otherwise, if a local folder combine, it must be the last script in this folder
        -- all other types of mod: (generic in name), (distinct in name) and Mod1+Mod2+Mod3.pak type mods
        if not H.gIs_LEAN_MODE then
          print(">>> [INFO] Reached LAST script of Combined Mod: "..H._zBRIGHTGREEN.."Building MOD now..."..H._zDEFAULT)
        end
        
        H.createdMODName = CreateMod(H,_bScriptName,H._bScriptCounter,NMS_MOD_DEFINITION_CONTAINER)
        -- print(" = = = CLEANING EXML TABLES = = =")
        H.EXMLorgTable = {} -- BECAUSE sometimes a script does a Copying/renaming to the name of an original EXML
        H.EXMLorgExtTable = {}
        H.EXMLmodTable = {}
        H.EXMLcreate = {}
        H.clonedMXMLmodTable = {}
        H.customLanguageFiles = {}

        -- H.IsExFunc does NOT need to create a pak anymore, so no unpack
        -- if H.IsExFunc and H.createdMODName ~= "" then
          -- UnpackDecompilePak(H, H.createdMODName)
        -- end
        
        H.Report("")
        H.Report("","Ending MBIN/MOD phase...")
        
      --*****************************************
      else
        if not H.gIs_LEAN_MODE then
          print(">>> [INFO] Combined Mod ACTIVE: "..H._zBRIGHTGREEN.."Delaying Building MOD..."..H._zDEFAULT)
          print("")
        end
        H.Report("","Combined Mod ACTIVE: Delaying Building MOD...")
      end
    end
    
  else
    --on abortProcessing
    print("")
    print(">>> [INFO]"..H._zBRIGHTRED.." Processing aborted..."..H._zDEFAULT)
    H.Report("","Processing aborted...")
    H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": ".._bScriptName..": Problem while testing script"
    
    if IsEndCOMBINE_MODS_flag then
      print(H.gcWARNING..[[>>> [WARNING] NO MOD was created ]]..H._zDEFAULT)
      H.Report("","NO MOD was created!","WARNING")
      H.gModScriptFailed[#H.gModScriptFailed] = H._bScriptCounter..": "..H.gModScriptFailed[#H.gModScriptFailed]..", NO MOD was created"
    end
    
    H.WriteToFile("", "MOD_FILENAME.txt")
  end

-- if IsEndCOMBINE_MODS_flag then
  -- -- make CheckMBINCompilerLog.lua report scripts that used that EXML
  -- local tmp = {}
  -- for k,v in pairs(scriptFileList) do
    -- for i=1,#scriptFileList[k] do
      -- -- printf(" - [%s] used by: [%s]",k,scriptFileList[k][i])
      -- tmp[#tmp+1] = string.format(" - [%s] used by: [%s]",k,scriptFileList[k][i])
    -- end
  -- end
  -- table.sort(tmp)
  -- print(" ~ ~ ~ ~ ~")
  -- for i=1,#tmp do
    -- printf(tmp[i])
  -- end
  -- print(" ~ ~ ~ ~ ~")
-- end


end --ProcessScript(H,NMS_MOD_DEFINITION_CONTAINER,IsMulti_pak,_bScriptName,IsCOMBINE_MODS_flag,IsEndCOMBINE_MODS_flag)
--################  end ProcessScript  ###############################

-- ****************************************************
function SetupGENERIC_lua(H)
  local DoThis = true
  
  if H._bTotalNumberScripts == 0 then
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTGREEN.."  No script found and one or more EXMLs are in ModScript: Creating a generic script..."..H._zDEFAULT)
    end
    H._bTotalNumberScripts = H._bTotalNumberScripts + 1
  -- elseif H.IsFileExist(H.gPathToModScriptFromModbuilder..[[\GENERIC.lua]]) then
    -- print(H._zBRIGHTGREEN.."  One or more EXMLs are in ModScript: Re-creating a generic script..."..H._zDEFAULT)
  else
    --at least one script and no GENERIC.lua
    --we assume we don't need GENERIC.lua
    DoThis = false
  end
  
  if DoThis then
    local generic = H.ParseTextFileIntoTable([[GENERIC_template.lua]])
    for i=1,#generic do
      if strfind(generic[i],"MBIN_FILE_SOURCE",1,true) then
        -- get all EXML in ModScript with path
        H.gModScriptEXMLDirList = H.GetFilesWithExt(".MXML",false)
        
        local insertAfterLine = i + 2
        
        for j=1,#H.gModScriptEXMLDirList do
          local tmp = string.gsub(H.gModScriptEXMLDirList[j][1],".MXML$",".MBIN")
          generic[#generic+1] = insertAfterLine,[["]]..tmp..[[",]]
          insertAfterLine = insertAfterLine + 1
        end
        break
      end
    end
    -- H.WriteToFile(H.ConvertLineTableToText(generic),H.gPathToModScriptFromModbuilder..[[\GENERIC.lua]])
    H.WriteToFile(generic,H.gPathToModScriptFromModbuilder..[[\GENERIC.lua]])
    
    --refresh Script List
    H.gModScriptLuaDirList = H.GetFilesWithExt(".lua")
    
    H._bTotalNumberScripts = #H.gModScriptLuaDirList
  end
end --SetupGENERIC_lua()

-- ****************************************************
function pre_processScripts(H)
  -- H.gModScriptLuaDirList[i][x] comes from
  --      H.gScriptList[i][1]: filename and path
  --      H.gScriptList[i][2]: path string -- folderTooDeep
  --      H.gScriptList[i][3]: bool -- pathTooLong
  --      H.gScriptList[i][4]: string -- auto-combine
  --      H.gScriptList[i][5]: bool -- MEFTI exist
  
  H.dLeftOffset = math.tointeger(H.WinW // 2)
  H.dRightOffset = math.tointeger(H.dLeftOffset // 3)

  if H.IsArguments then
    H.gModScriptLuaDirList = {}
    
    local count = 0
    for i=1,#H.arguments do
      -- printf(">>> H.arguments[%d] = %s",i,H.arguments[i])
      if H.arguments[i] == "DONOTCOPYTOMOD" then
        H._bCOPYtoNMS = "NONE"
        H.IsSkipCreatingPAK = true
      else
        count = count + 1
        H.gIsGlobalIndividual = true
        
        H.gModScriptLuaDirList[count] = {}
        H.gModScriptLuaDirList[count][1] = string.rep(" ",20)..H.arguments[i]
        H.gModScriptLuaDirList[count][2] = ""
        H.gModScriptLuaDirList[count][3] = false
        H.gModScriptLuaDirList[count][4] = "N"
        H.gModScriptLuaDirList[count][5] = false
      end
    end
    H._bTotalNumberScripts = count
    print("")
    printf(" "..H._zBLACKonYELLOW.." >>>   [INFO] AUTO-Refreshing %d useful scripts, one moment..."..H._zDEFAULT,count)
    
  else
    print("")
    print(">>> Number of scripts to build: "..H._bTotalNumberScripts.." ('*' indicates that MEFTI is present)")
  end
  
  --****************************************************************************
  -- ==================  we could re-order the scripts to process based on
  -- ==================  the order in H.MODSreportList (order that came from GCMODSETTINGS),
  -- ==================  putting the (new) mods (not in H.MODSreportList) at the top (like NMS does)
  -- ==================  in script load order
  -- ==================  For now, we will use the script name order as usual
  --****************************************************************************
  
  --****************************  list scripts to process  *********************
  print("")
  local cutPoint = #(H.gMASTER_FOLDER_PATH..[[ModScript\]])
  if H.IsArguments then
    cutPoint = 0
  end
  for i=1,#H.gModScriptLuaDirList do
    local IsMEFTI = H.gModScriptLuaDirList[i][5]
    local MEFTIindicator = " "
    if IsMEFTI then
      MEFTIindicator = "*"
    end
    local typeLen = #H.gModScriptLuaDirList[i][4]
    local spacer = ""
    if typeLen == 1 then
      spacer = " "
    end
    
    local size = #(tostring(#H.gModScriptLuaDirList))
    print("    - "..string.format([[%]]..size..[[u]],i).." <"..MEFTIindicator..H.gModScriptLuaDirList[i][4]..spacer.."> ["..string.sub(H.trim(H.gModScriptLuaDirList[i][1]),cutPoint + 1).."]")
  end
  --****************************  END: list scripts to process  *********************
  
  if not H.gIsGlobalIndividual then
    -- we need to clean IsMEFTIexist_flag for all 'M' and 'Z'
    --   so we do not need to copy MEFTI files more than once
    for i=1,H._bTotalNumberScripts do
      if H.gModScriptLuaDirList[i][4] == "M" or H.gModScriptLuaDirList[i][4] == "Z" then
        H.gModScriptLuaDirList[i][5] = false
      end
    end
  end
  
  -- ****************************************************
  local function PrepareCombinedContent(H)
    local filename = [[COMBINED_CONTENT_LIST.txt]]
    os.remove(filename)
    
    if H.IsPATCH then
      H.WriteToFile("This PatchMod was created from:\n",filename)
      local pakContent = H.ParseTextFileIntoTable("ModScript_pak_list.txt")
      for i=1,#pakContent do
        local pakName = string.gsub(pakContent[i],[[..\ModScript\]],"")
        H.WriteToFileAppend(" - "..pakName.."\n",filename)
      end
      H.WriteToFileAppend("\nAnd modded by these scripts:\n",filename)
    else
      H.WriteToFile("This mod contains:\n",filename)
    end    
  end
  -- ****************************************************

  --***************************************************************************************************
  -- ############# Get ModScript paks file to MOD ##################
  -- doing this only once per COMBINE run
  local function HandleModScriptPakFiles(H)
    -- 1st: we try to unpack the files from the paks in ModScript, if any
    
    -- get list of paks in ModScript
    local ModScript_pakNames_table = H.ParseTextFileIntoTable("ModScript_pak_list.txt")
    -- print("#ModScript_pakNames_table = "..#ModScript_pakNames_table)
    
    if #ModScript_pakNames_table > 0 then
      -- some paks exist in ModScript
      if not H.gIs_LEAN_MODE then
        print()
        print(H._zBRIGHTGREEN.."   Found paks in ModScript"..H._zDEFAULT)
      end
      
      -- extract ALL files from paks in ModScript to MODBUILDER\MOD
      for i=1,#ModScript_pakNames_table do
        
        printf("   >>> Extracting ALL files from: "..H._zBRIGHTGREEN.."%s"..H._zDEFAULT,ModScript_pakNames_table[i])
        H.Report("")
        H.Report("","Extracting ALL files from: "..ModScript_pakNames_table[i],"")
        local success = H.psarc_E([[]], ModScript_pakNames_table[i], [[.\MOD]], "", "-y -q")
        -- printf("success = [%s]",success)
        if success ~= "OK" then
          print(">>> "..H.gcWARNING.." [WARNING] Could not extract ALL files from pak "..H._zDEFAULT)
          H.Report("","Could not extract ALL files from pak","WARNING")
        end                  
        
        -- remove all .txt, .cs files (like AMUMSS.vW.X.Y.Z.txt)
        H.DeleteFile([[.\MOD\*.txt]])
        H.DeleteFile([[.\MOD\*.cs]])
        
        -- decompile MBIN files (they may not be in MBIN_table and would be deleted at the end)
        local status,result = H.MBINCompiler_D([[.\MOD]],false,false,true,"     @@@ decompiling MBINs from paks...",true)
        -- H.printf("status = [%s], result = [%s]",status,result)

        -- NOW check the log
        arg[1] = "..\\" -- path to REPORT.lua
        arg[2] = "" -- path to MODBUILDER
        arg[3] = "Decompiling" -- a message
        arg[4] = "keepOpen" -- do NOT close Report
        arg[5] = "quiet" -- no message
        dofile("CheckMBINCompilerLOG.lua")
        -- print(">>> AFTER CheckMBINCompilerLOG")
        
        H.switchBACK = false
        if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
          if not gIsCompilerVersionsEqual then
            -- print("     Trying the other MBINCompiler...")
            H.SwitchToOtherMBINCompiler(H,"AMUMSS")
            
            -- decompile MBIN files (they may not be in MBIN_table and would be deleted at the end)
            local status,result = H.MBINCompiler_D([[.\MOD]],false,false,true,"     @@@ decompiling MBINs from paks...",true)
            -- H.printf("status = [%s], result = [%s]",status,result)
            
            H.switchBACK = true
            -- SwitchBackToDeclaredMBINCompiler(H,true)
            
            -- NOW check the log
            arg[1] = "..\\" -- path to REPORT.lua
            arg[2] = "" -- path to MODBUILDER
            arg[3] = "Decompiling" -- a message
            arg[4] = "keepOpen" -- do NOT close Report
            arg[5] = "quiet" -- no message
            dofile("CheckMBINCompilerLOG.lua")
            -- print(">>> AFTER CheckMBINCompilerLOG")                      
          end
          
          if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
            print("     @@@ "..H._zBRIGHTRED.." MBINCompiler reported problems decompiling files from "..H._zDEFAULT..H._zBRIGHTGREEN.." "..ModScript_pakNames_table[i].." "..H._zDEFAULT)
            print(H.gcWARNING..[[>>>      [WARNING] The pak will not affect the game as it is supposed to ]]..H._zDEFAULT)
            print(H.gcNOTICE..[[>>> A script should be created to handle the changes in the failed MBINs ]]..H._zDEFAULT)

            H.Report("","MBINCompiler reported problems decompiling files",ModScript_pakNames_table[i],"")                      
            H.Report("",[[The pak will not affect the game as it is supposed to]],"   WARN")
            H.Report("",[[A script should be created to handle the changes in the failed MBINs]],"   WARN")
         end
        else
          -- all files decompiled ok
        end
        
        if H.switchBACK then
          SwitchBackToDeclaredMBINCompiler(H,true)
        end
        
      end -- for i=1,#ModScript_pakNames_table do
      
    else
      -- NO paks exist in ModScript
      -- nothing to do here
      if not H.gIs_LEAN_MODE then
        print(H._zBRIGHTGREEN.."   NO paks in ModScript"..H._zDEFAULT)
      end
    end
  end
  --***************************************************************************************************

  --***************************************************************************************************
  -- ############# Copy 'main' EXTRA files to MOD ##################
  -- doing this only once per AMUMSS run, this is the global EXTRA files
  local function HandleGlobalMEFTI(H, IsFirstCOMBINE_MODS_flag)
    -- H.printf("==> In HandleGlobalMEFTI %s","")    
    --get list of files in ModScript\GlobalMEFTI
    local FilePathSource = [[..\ModScript\GlobalMEFTI]]

    H.DeleteFile(FilePathSource..[[\]]..H.gUSE_name,true)
    H.DeleteFile(FilePathSource..[[\]]..H.gCOMBINE_name,true)
    
    local cmd = [[robocopy ]]..FilePathSource..[[\. ]]..FilePathSource..[[\. *.* /S /V /L /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12]]
    local mainMEFTIlist = H.GetList(cmd,true)

    table.sort(mainMEFTIlist)
    
    if #mainMEFTIlist > 0 then
      if not H.gIs_LEAN_MODE then
        print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
        print(">>> [INFO] Found files in '"..H._zBRIGHTGREEN..[[ModScript\GlobalMEFTI]]..H._zDEFAULT..H._zYELLOW..[[', including them in pak]]..H._zDEFAULT)
      end
      H.Report("",[[>>> Found files in 'ModScript\GlobalMEFTI', including them in pak]])

      if IsFirstCOMBINE_MODS_flag then
        local cutPoint = #(string.sub(mainMEFTIlist[1],1,string.find(mainMEFTIlist[1],[[GlobalMEFTI\]])+12))
    
        for i=1,#mainMEFTIlist do
          local exmlName = string.sub(H.trim(mainMEFTIlist[i]),cutPoint):gsub(".MBIN$",".MXML")
          -- printf("* exmlName[%d] = %s",i,exmlName)          
          -- fill list
          if not scriptFileList[exmlName] then
            scriptFileList[exmlName] = {}
          end
          scriptFileList[exmlName][#scriptFileList[exmlName]+1] = "Loaded From GLobalMEFTI"
        end
      end
    end
    
    if not H.gIs_LEAN_MODE then
      --clean up spaces and print list
      local cutPoint = #(H.gMASTER_FOLDER_PATH..[[ModScript\GlobalMEFTI\]])
      local printLimit = 15
      for i=1,#mainMEFTIlist do
        if i <= printLimit then
          if H.trim(mainMEFTIlist[i]) ~= "" then
            print("           - ["..string.sub(H.trim(mainMEFTIlist[i]),cutPoint + 1).."]")
          end
        else
          print(H._zBRIGHTGREEN..">>> "..H._zYELLOW.."LARGE number"..H._zDEFAULT..H._zBRIGHTGREEN.." of files ("..#mainMEFTIlist..") detected "..H._zYELLOW.."(limiting log.lua output)"..H._zDEFAULT)
          print(H._zYELLOW.."               BE PATIENT"..H._zDEFAULT..", the output may only seem to stop at times...")
          break
        end
        --we could add the names of the ModScript\GlobalMEFTI files to the CONTENT
        --H.WriteToFileAppend("\ModScript\GlobalMEFTI: "..string.sub(H.trim(mainMEFTIlist[i]),cutPoint + 1),[[COMBINED_CONTENT_LIST.txt]])
      end
    end
    H.WriteToFileAppend([[Found files in 'ModScript\GlobalMEFTI', including them in pak]].."\n",[[COMBINED_CONTENT_LIST.txt]])
    
    H.CopyFile([[..\ModScript\GlobalMEFTI\*.*]],"MOD",H.paramFilesDir) -- ,false for debug
    -- H.WFAK("End of HandleGlobalMEFTI()")
  end
  -- ############# END: Copy 'main' EXTRA files to MOD ##################
  --***************************************************************************************************
  
  --***************************************************************************************************
  --                               Handle Extra Files In MEFTI
  local function HandleMEFTI(H, _bScriptName, IsFirstCOMBINE_MODS_flag)
    -- H.printf("==> In HandleMEFTI %s","")    
    local _bScriptNamePath = H.GetFolderPathFromFilePath(_bScriptName)
    --this is a custom folder and ((it is the 1st script and the user asked to combine) or (auto-combine is active))
    
    --only for backward compatibility
    --check if oldname sub-folder GlobalMEFTI exist instead of sub-folder MEFTI
    local oldFilePathSource = [[..\ModScript\]].._bScriptNamePath..[[\GlobalMEFTI]]
    local FilePathSource = [[..\ModScript\]].._bScriptNamePath..[[\MEFTI]]
    if H.IsDirExist(oldFilePathSource) then
      --directory name changed to MEFTI
      os.rename(oldFilePathSource,FilePathSource)
    end
    --END: only for backward compatibility
    
    -- print("FilePathSource = ["..FilePathSource.."]")
    
    H.DeleteFile(FilePathSource..[[\]]..H.gUSE_name,true)
    H.DeleteFile(FilePathSource..[[\]]..H.gCOMBINE_name,true)
    
    --get list of files in this MEFTI
    local cmd = [[robocopy "]]..FilePathSource..[[\." "]]..FilePathSource..[[\." *.* /S /V /L /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12]]
    local MEFTIlist = H.GetList(cmd,true)

    table.sort(MEFTIlist)
    
    if #MEFTIlist > 0 then
      local cutPoint = #(string.sub(MEFTIlist[1],1,string.find(MEFTIlist[1],[[MEFTI\]])+6))
    
      if not H.gIs_LEAN_MODE then
        print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
        print([[>>> [INFO] Found files in custom folder ']]..H._zBRIGHTGREEN..[[MEFTI]]..H._zDEFAULT..H._zYELLOW..[[', including them in pak]]..H._zDEFAULT)
      end
      H.Report("",[[>>> Found files in custom folder 'MEFTI', including them in pak]])

      if IsFirstCOMBINE_MODS_flag then
        for i=1,#MEFTIlist do
          local exmlName = string.sub(H.trim(MEFTIlist[i]),cutPoint):gsub(".MBIN$",".MXML")
          -- printf("* exmlName[%d] = %s",i,exmlName)          
          
          -- fill list
          if not scriptFileList[exmlName] then
            scriptFileList[exmlName] = {}
          end
          scriptFileList[exmlName][#scriptFileList[exmlName]+1] = "Loaded From MEFTI"
        end
      end
    end
    
    if not H.gIs_LEAN_MODE then
      --clean up spaces and print list
      local cutPoint = #(H.gMASTER_FOLDER_PATH..[[ModScript\]])
      local printLimit = 15
      for i=1,#MEFTIlist do
        if i <= printLimit then
          print("   - ["..string.sub(H.trim(MEFTIlist[i]),cutPoint + 1).."]")
        else
          print(H._zBRIGHTGREEN..">>> "..H._zYELLOW.."LARGE number"..H._zDEFAULT..H._zBRIGHTGREEN.." of files ("..#MEFTIlist..") detected "..H._zYELLOW.."(limiting log.lua output)"..H._zDEFAULT)
          print(H._zYELLOW.."               BE PATIENT"..H._zDEFAULT..", the output may only seem to stop at times...")
          break
        end
        --we could add the names of the MEFTI files to the CONTENT
        --H.WriteToFileAppend("\nMEFTI: "..string.sub(H.trim(MEFTIlist[i]),cutPoint + 1),[[COMBINED_CONTENT_LIST.txt]])
      end
    end
    H.WriteToFileAppend("Found files in custom folder 'MEFTI', including them in pak\n",[[COMBINED_CONTENT_LIST.txt]])
    
    --copy the files to MODBUILDER\MOD excluding
    --   if destination file exists and is the same date or newer than the source - dont bother to overwrite it
    FolderPath = [[.\MOD]]
    local cmd = [[ROBOCOPY /s /j /XN "]]..FilePathSource..[[" "]]..FolderPath..[[" 1>NUL 2>NUL]]
    -- print("cmd = ["..cmd.."]")
    H.NewThread(cmd)
    
  end  --local function
  --                        END: Handle Extra Files In MEFTI
  --***************************************************************************************************
  
  --***************************************************************************************************
  local function HandleAllExtraFiles(H, _bScriptNamePath, IsCOMBINE_MODS_flag, IsFirstCOMBINE_MODS_flag, IsMEFTIexist_flag, IsFirstScriptInSubFolder_flag)
    -- H.printf("==> In HandleAllExtraFiles %s","")    
    local answer = "N"
    if H._mIncludeLuaScriptInPak == "ASK" then
      answer = H.AChoice(" "..H._zBLACKonYELLOW.." Do you want to include this lua script in the MOD? "..H._zDEFAULT,"YN")
    end
    if H._mIncludeLuaScriptInPak == "Y" or answer == "Y" then
      if not H.gIs_LEAN_MODE then
        print([[>>> Including lua script source in MOD]])
      end
      H.Report("",[[>>> Including lua script source in MOD]])
      
      --copy script to MOD folder
      local FilePathSource = H.LoadFileData("CurrentModScript.txt")

      local FolderPath = [[.\MOD\]]..H.GetFilenameFromFilePath(FilePathSource,false)
      
      local ext = ""
      if H.IsFileExist(FilePathSource.."x") then
        -- script extended version exist
        ext = "x"
      end
      
      local cmd = [[copy ]]..[[/y]]..[[ "]]..FilePathSource..ext..[[" "]]..FolderPath..[["]].." 1>NUL 2>NUL"
      os.execute(cmd)
      -- always delete the .luax file if it exists
      H.DeleteFile(FilePathSource.."x")

      -- -- if it exist, also needed to recreate this mod
      -- H.CopyFile(H.GetFolderPathFromFilePath(FilePathSource)..[[\LocTable.txt]], [[.\MOD\LocTable.txt*]], H.paramFiles) -- only ALL files    
    end
    
    -- copy AMUMSS version in MOD
    local AMUMSSVersion = H.LoadFileData("AMUMSSVersion.txt"):gsub("(.*)%c*.+","%1")
    H.WriteToFile("",[[.\MOD\AMUMSS_v]]..AMUMSSVersion..[[.txt]])
    
    if _bScriptNamePath ~= "" then
      if H._bExtraFilesInPAK == "Y" then
        -- include the files in ModScript\GlobalMEFTI
        
        local IsGlobalMEFTIAlreadyDone = false
        if H.gIsGlobalIndividual then
          -- building Individual paks:
          if not IsCOMBINE_MODS_flag then
            -- scripts in ModScript and in sub-folders without COMBINE_FLAG:
            -- we need to do it for each script
            HandleGlobalMEFTI(H)
          else
            -- scripts in sub-folders with COMBINE_FLAG:
            if IsFirstCOMBINE_MODS_flag or H._bScriptCounter == 1 then
              -- only needed for the 1st script
              HandleGlobalMEFTI(H,IsFirstCOMBINE_MODS_flag)
            else
              IsGlobalMEFTIAlreadyDone = true
            end
          end
          
        else
          -- Global Combined pak: we only do it on the 1st script
          if H._bScriptCounter == 1 then
            HandleGlobalMEFTI(H)
          else
            IsGlobalMEFTIAlreadyDone = true
          end
        end
        
        if IsGlobalMEFTIAlreadyDone then
          if not H.gIs_LEAN_MODE then
            print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
            print([[>>> [INFO] Found files in ']]..H._zBRIGHTGREEN..[[ModScript\GlobalMEFTI]]..H._zDEFAULT..H._zYELLOW..[[', already included in pak]]..H._zDEFAULT)
          end
          H.Report("",[[>>> Found files in 'ModScript\GlobalMEFTI', already included in pak]])
        end
      end
      
      local IsMEFTIAlreadyDone = false
      if IsMEFTIexist_flag then
        if H.gIsGlobalIndividual then
          -- building Individual paks:
          if not IsCOMBINE_MODS_flag then
            -- scripts in ModScript and in sub-folders without COMBINE_FLAG:
            -- we need to do it for each script
            HandleMEFTI(H,H._bScriptName)
          else
            -- scripts in sub-folders with COMBINE_FLAG:
            if IsFirstCOMBINE_MODS_flag or H._bScriptCounter == 1 then
              -- only needed for the 1st script
              HandleMEFTI(H,H._bScriptName,IsFirstCOMBINE_MODS_flag)
            else
              IsMEFTIAlreadyDone = true
            end
          end
          
        else
          -- Global Combined pak: we only do it on the 1st script
          if IsFirstScriptInSubFolder_flag or H._bScriptCounter == 1 then
            HandleMEFTI(H,H._bScriptName)
          else
            IsMEFTIAlreadyDone = true
          end
        end
        
        if IsMEFTIAlreadyDone then
          if not H.gIs_LEAN_MODE then
            print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
            print([[>>> [INFO] Found files in custom folder ']]..H._zBRIGHTGREEN..[[MEFTI]]..H._zDEFAULT..H._zYELLOW..[[', already included in pak]]..H._zDEFAULT)
          end
          H.Report("",[[>>> Found files in custom folder 'MEFTI', already included in pak]])
        end
        
      end
    end
    -- H.WFAK("End of HandleAllExtraFiles()")
  end
  --***************************************************************************************************

  --***************************************************************************************************
  local function ShowProgressBar(H)
    if H._bTotalNumberScripts > 1 then
      local d = tonumber(H._bScriptCounter) / tonumber(H._bTotalNumberScripts)
      -- printf("d = %f, H.dLeftOffset = %d, H.dRightOffset = %d",d,H.dLeftOffset,H.dRightOffset)
      local dSize = math.ceil((H.WinW - H.dLeftOffset - H.dRightOffset) * d)
      if dSize <= 0 then dSize = 1 end
      print("")
      -- printf("%d %d %d",H.dLeftOffset,H.dRightOffset,dSize)
      print(string.rep(" ",H.dLeftOffset).."==>"..H._zWHITEonYELLOW..string.rep(" ",dSize)..H._zDEFAULT..H._zWHITEonBLUE..string.rep(" ",H.WinW - dSize - H.dLeftOffset - H.dRightOffset)..H._zDEFAULT.."<== "..string.format("%3.1f",d * 100).."%")
    end
  end
  --***************************************************************************************************
            
  -- local cutPoint = #(H.gMASTER_FOLDER_PATH..[[ModScript\]])
  
  -- local totalAccumulatedTime = 0
  local IsCOMBINE_MODS_flag = false -- includes H.gModScriptLuaDirList[i][4] == "M" and == "N"
  
  for i=1,H._bTotalNumberScripts do
    local startScriptProcessingTime = os.clock()
    collectgarbage()

    H._bScriptCounter = i
    H._bScriptName = H.trim(string.sub(H.gModScriptLuaDirList[i][1],cutPoint + 1))
    
    H.WriteToFile(H.gMASTER_FOLDER_PATH..[[ModScript\]]..H._bScriptName, "CurrentModScript.txt")
    H.WriteToFile(H._bScriptName, "CurrentModScript_Short.txt")
    
    print("")
    print(" "..H._zBLACKonYELLOW.." >>> 'Starting to process script' #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." ['"..H._bScriptName.."'] at "..H.dClock().." "..H._zDEFAULT)
    print("")
    print(">>> Opening User Lua Script, Please wait...")
    
    -- -- to estimate if the script generates a HUGE NMS_MOD_DEFINITION_CONTAINER table
    -- local mem_before = collectgarbage("count")
    -- -- print(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." "..mem_before)
    
    --*************************************************
    gNMS_MOD_DEFINITION_CONTAINER,H.DelayedReportData,InternalFunctionProblem,conf = OpenUserScript(H)
    --*************************************************

    -- -- local mem_after = collectgarbage("count")
    -- -- print(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT.." "..mem_after)
    -- local mem_diff = collectgarbage("count") - mem_before
    -- -- print("mem_diff = "..mem_diff)
    
    -- if _mWbertro and gNMS_MOD_DEFINITION_CONTAINER and mem_diff < 300000 then
      -- H.SaveTable("..\\TempTable.txt",gNMS_MOD_DEFINITION_CONTAINER,"NMS_MOD_DEFINITION_CONTAINER")
    -- end
    
    --setup type of script
    local IsFirstScriptInSubFolder_flag = false
    local IsFirstCOMBINE_MODS_flag = false
    local IsEndCOMBINE_MODS_flag = false
    local IsMEFTIexist_flag = H.gModScriptLuaDirList[i][5]
    
    -- Wbertro: this section below can be simplified maybe
    
    if H.gIsGlobalIndividual then
      if H.gDEBUG_ScriptTypeName then
        print("*** IN: H.gIsGlobalIndividual == true")
      end
      --user asked for INDIVIDUAL
      --but it can be overridden if flag COMBINE exist in the folder/sub-folder
      
      -- H.gModScriptLuaDirList[i][x] comes from
      --      H.gScriptList[i][1]: filename and path
      --      H.gScriptList[i][2]: path string -- folderTooDeep
      --      H.gScriptList[i][3]: bool -- pathTooLong
      --      H.gScriptList[i][4]: string -- auto-combine
      --      H.gScriptList[i][5]: bool -- MEFTI exist
      
      -- handled by CleanModScriptDirList()
      -- if H.gModScriptLuaDirList[i][4] == "F" and i == H._bTotalNumberScripts then
        -- -- special case: only one script in auto-combine
        -- H.gModScriptLuaDirList[i][4] = "FE"
      -- end
      -- ==========      
      if H.gModScriptLuaDirList[i][4] == "F" or H.gModScriptLuaDirList[i][4] == "E" or H.gModScriptLuaDirList[i][4] == "FE" then
        IsCOMBINE_MODS_flag = true
      end

      if H.gModScriptLuaDirList[i][4] == "F" or H.gModScriptLuaDirList[i][4] == "FE" then
        --this script is flagged as AUTO_COMBINE
        IsFirstScriptInSubFolder_flag = true
        IsFirstCOMBINE_MODS_flag = true
        
        --it is the FIRST of the COMBINED group
        --we need to reset COMBINED_CONTENT_LIST
        PrepareCombinedContent(H)
        
        --we could add the names of the ModScript\GlobalMEFTI files to the CONTENT
        --not real code
        -- for n = 1,#GlobalMEFTI do
          -- H.WriteToFileAppend("\nOriginal information:\n",[[COMBINED_CONTENT_LIST.txt]])
        -- end
        
        --reset Composite_MOD_FILENAME
        H.DEBUG_ScriptContent_print("Resetting Composite_MOD_FILENAME.txt")
        local filename = [[Composite_MOD_FILENAME.txt]]
        os.remove(filename)
        
      elseif H.gModScriptLuaDirList[i][4] == "A" or H.gModScriptLuaDirList[i][4] == "AZ" then
        --1st script in a sub-folder and not auto-combine
        --we need to handle EXTRA files
        IsFirstScriptInSubFolder_flag = true --to indicate this is the 1st script in this sub-folder
        IsCOMBINE_MODS_flag = false
        
      elseif H.gModScriptLuaDirList[i][4] == "C" then
        --2nd or more of the COMBINED script
        IsCOMBINE_MODS_flag = true
      end
      -- ==========
      if H.gModScriptLuaDirList[i][4] == "Z" or H.gModScriptLuaDirList[i][4] == "AZ" then
        --it is the last script of this sub-folder WITHOUT a COMBINED_FLAG
        IsCOMBINE_MODS_flag = false
        --IsEndCOMBINE_MODS_flag = true --to trigger building the mod pak for this sub-folder
      end
      -- ==========
      if H.gModScriptLuaDirList[i][4] == "E" or H.gModScriptLuaDirList[i][4] == "FE" or (H.gModScriptLuaDirList[i][4] == "C" and i == H._bTotalNumberScripts) then
        --it is the last script of this sub-folder (or the last of the list) WITH a COMBINE_FLAG
        IsCOMBINE_MODS_flag = true
        IsEndCOMBINE_MODS_flag = true --to trigger building the mod pak for this sub-folder
        
        --we need to build a COMPOSITE name for this pak
        local firstAutoCombine = i
        if H.gModScriptLuaDirList[i][4] == "FE" then
          firstAutoCombine = i
        else
          for m = i-1,1,-1 do
            if H.gModScriptLuaDirList[m][4] == "F" then
              --then m is the first of this bunch
              firstAutoCombine = m
              break
            end
          end
          -- print("Y: firstAutoCombine = ["..firstAutoCombine.."], i = ["..i.."]")
        end
        -- print("Y: gModScriptLuaDirList[firstAutoCombine][1] = ["..H.gModScriptLuaDirList[firstAutoCombine][1].."]")
        
        CreateCompositeModName(H, firstAutoCombine, i)
      end
      -- ==========
    else
      if H.gDEBUG_ScriptTypeName then
        print("*** IN: H.gIsGlobalIndividual == false")
      end
      --user asked for COMBINED (auto-combine is superseded)
      
      --we will wait for the last script to create the mod pak
      if H.gModScriptLuaDirList[i][4] == "A" or H.gModScriptLuaDirList[i][4] == "AZ" then
        --1st script in a sub-folder and not auto-combine
        IsFirstScriptInSubFolder_flag = true --to indicate this is the 1st script in this sub-folder
        IsCOMBINE_MODS_flag = false
      end
      -- ==========
      if H.gModScriptLuaDirList[i][4] == "F" or H.gModScriptLuaDirList[i][4] == "E" or H.gModScriptLuaDirList[i][4] == "FE" then
        --this script is flagged as AUTO_COMBINE
        IsFirstScriptInSubFolder_flag = true --to indicate this is the 1st script in this sub-folder
        IsFirstCOMBINE_MODS_flag = true
        IsCOMBINE_MODS_flag = true
      end
      if H.gModScriptLuaDirList[i][4] == "E" or H.gModScriptLuaDirList[i][4] == "FE" then
        IsEndCOMBINE_MODS_flag = true
      end
      -- ==========
      if H._bScriptCounter == 1 then
        --on the FIRST of the COMBINE group
        --we need to reset COMBINED_CONTENT_LIST
        PrepareCombinedContent(H)
        
        --we could add the names of the ModScript\GlobalMEFTI files to the CONTENT
        --not real code
        -- for n = 1,#GlobalMEFTI do
          -- H.WriteToFileAppend("\nOriginal information:\n",[[COMBINED_CONTENT_LIST.txt]])
        -- end
      end
      -- ==========
      if H._bGlobalCOMBINE_MOD_TYPE == 3 then
        --user asked for COMPOSITE
        CreateCompositeModName(H,1,#H.gModScriptLuaDirList)
      end
      if H._bGlobalCOMBINE_MOD_TYPE == 2 or H._bGlobalCOMBINE_MOD_TYPE == 3 then
        IsCOMBINE_MODS_flag = true
      end
    end
    
    if H._bTotalNumberScripts == 1 then
      IsCOMBINE_MODS_flag = false
    end
    
    if H.IsPATCH then
      IsCOMBINE_MODS_flag = true
    end
    
    if H.gDEBUG_ScriptTypeName then
      print("Y: ===> AFTER detecting type of script")
      print("Y: on i = ["..i.."]      _bScriptName = ["..H._bScriptName.."]")
      print("Y:        H.gIsGlobalIndividual = ["..tostring(H.gIsGlobalIndividual).."]")
      print("Y:   H._bGlobalCOMBINE_MOD_TYPE = ["..H._bGlobalCOMBINE_MOD_TYPE.."]")
      print("Y:            H._bScriptCounter = ["..H._bScriptCounter.."]")
      print("Y:IsFirstScriptInSubFolder_flag = ["..tostring(IsFirstScriptInSubFolder_flag).."]")
      print("Y:          IsCOMBINE_MODS_flag = ["..tostring(IsCOMBINE_MODS_flag).."]")
      print("Y:     IsFirstCOMBINE_MODS_flag = ["..tostring(IsFirstCOMBINE_MODS_flag).."]")
      print("Y:       IsEndCOMBINE_MODS_flag = ["..tostring(IsEndCOMBINE_MODS_flag).."]")
      print("Y:                     fullpath = ["..H.gModScriptLuaDirList[i][1].."]")
      print("Y:                folderTooDeep = ["..H.gModScriptLuaDirList[i][2].."]")
      print("Y:                  pathTooLong = ["..tostring(H.gModScriptLuaDirList[i][3]).."]")
      print("Y:                 combine type = ["..H.gModScriptLuaDirList[i][4].."]")
      print("Y:            IsMEFTIexist_flag = ["..tostring(H.gModScriptLuaDirList[i][5]).."]")
      -- H.WFAK("Waiting...")
    end
    --END: setup type of script
    
    if IsFirstCOMBINE_MODS_flag then
      -- reset list
      scriptFileList = {}
    end

    -- local IsBadContainer = false
    -- local CONTAINER_type = H.GetTableType(gNMS_MOD_DEFINITION_CONTAINER)
    -- if CONTAINER_type ~= "Dictionary" then
      -- IsBadContainer = true
      -- printf("==> CONTAINER_type is [%s]",CONTAINER_type)
      -- print(">>> "..H.gcERROR.." [ERROR] NMS_MOD_DEFINITION_CONTAINER is not a pure 'Dictionnary'.  Please correct your script! "..H._zDEFAULT)
      -- H.Report("","CONTAINER_type is ["..CONTAINER_type.."]","")
      -- H.Report("","NMS_MOD_DEFINITION_CONTAINER is not a pure 'Dictionnary'.  Please correct your script!","ERROR")
    -- end
    
    if type(gNMS_MOD_DEFINITION_CONTAINER) == "table" then      
      if H._bAllowMapFileTreeCreator == "Y" then
        if H._bTotalNumberScripts > 0 then
          if not H.IsFileExist("MapFileTreeSharedList.txt") then
            --must be created
            H.WriteToFile("","MapFileTreeSharedList.txt")
          end
          
          local ProcessInfo = os.capture([[tasklist /FI "ImageName eq luaM.exe"]])
          local _,numUsedSlots = string.gsub(ProcessInfo,"luaM.exe","",-1)
          if numUsedSlots == 0 then
            --should only be this instance
            -- print("ZZZZZZZZZZZ "..[[dofile("CreateMapFileTreeStarter.lua")]])
            dofile("CreateMapFileTreeStarter.lua")
          else
            --otherwise CreateMapFileTreeStarter.lua is running
          end
        end
      end
      
      if H._bScriptCounter == 1 or (H.gIsGlobalIndividual and ((not IsCOMBINE_MODS_flag and H.gIsGlobalIndividual) or (IsCOMBINE_MODS_flag and IsFirstCOMBINE_MODS_flag))) then
        --Always Cleaning MOD directory before first script
        --  If INDIVIDUAL MODs: Cleaning MOD directory each time
        --  If COMBINED MODs: Only Cleaning MOD directory before first script
        if not H.gIs_LEAN_MODE then
          print(">>> [INFO]"..H._zBRIGHTGREEN..[[ Cleaning 'MODBUILDER\MOD']]..H._zDEFAULT)
        end
        local cmd = [[CleanMod.bat]]
        H.NewThread(cmd)
        
        -- reset list
        H.combinedScriptList = {}

        -- should reset MOD_BATCHNAME here
        if not H.gIs_LEAN_MODE then
          print(">>> [INFO]"..H._zBRIGHTGREEN.." Resetting 'MOD_BATCHNAME'"..H._zDEFAULT)
        end
        H.Report("","Resetting 'MOD_BATCHNAME'")
        H.WriteToFile("", "MOD_BATCHNAME.txt")
        
        if H.LoadFileData("MOD_BATCHNAME.txt") ~= "" then
          print(H.gcWARNING..[[>>> [WARNING] 'MOD_BATCHNAME.txt' could not be reset ]]..H._zDEFAULT)
          H.Report("",[['MOD_BATCHNAME.txt' could not be reset]],"WARNING")
        end

        if H.IsPATCH then
          -- do once for all scripts, this is a PatchMod
          HandleModScriptPakFiles(H)
          -- H.WFAK("AFTER HandleModScriptPakFiles()...")  
        end
      end
      
      if type(gNMS_MOD_DEFINITION_CONTAINER[1]) == "table" then
        --multi-table container
        local Container = gNMS_MOD_DEFINITION_CONTAINER
        
        for i=1,#Container do
          -- IsBadContainer = H.ReportInvalidTableContent(Container[i],"NMS_MOD_DEFINITION_CONTAINER["..i.."]")
          
          if i > 1 then
            -- print("")
            print(" "..H._zBLACKonYELLOW.." >>> Still processing script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." "..H._zDEFAULT)
            print("")
            
            H.Report("")
            H.Report("","========================================================================================")
            H.Report("","Still processing script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts)
          else
            H.Report("")
            H.Report("","========================================================================================")
            H.Report("","Processing script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts)
          end
          
          local startSubScriptProcessingTime = os.clock()
          
          print(H._zBRIGHTGREEN.."              ++++++++++  A Multi-MOD script  ++++++++++"..H._zDEFAULT)
          print("             "..H._zBLACKonYELLOW.." >>> Processing sub-script #"..i..[[ of ]]..#Container.." ['"..H._bScriptName.."''] at "..H.dClock().." "..H._zDEFAULT)
          print("")
          
          H.Report("","              ++++++++++  A Multi-MOD script  ++++++++++")
          H.Report("","              >>> Processing sub-script #"..i..[[ of ]]..#Container.." [["..H._bScriptName.."]] {")
          
          H.DelayedCONTAINERdata = H.ReportDelayedInfo(H.DelayedCONTAINERdata,"H.DelayedCONTAINERdata")
          H.DelayedReportData = H.ReportDelayedInfo(H.DelayedReportData,"H.DelayedReportData")
          
          if IsCOMBINE_MODS_flag then
            if not H.gIs_LEAN_MODE then
              print(H._zBRIGHTORANGE.."    Auto-combine flag detected"..H._zDEFAULT)
            end
            H.Report("","Auto-combine flag detected")
          end
          
          local IsBadContainer = false
          local CONTAINER_type = H.GetTableType(Container[i])
          if CONTAINER_type ~= "Dictionary" then
            IsBadContainer = true
            printf("==> SUB-CONTAINER type is [%s]",CONTAINER_type)
            print(">>> "..H.gcERROR.." [ERROR] NMS_MOD_DEFINITION_CONTAINER sub-table["..i.."] is not a pure 'Dictionnary'.  Please correct your script! "..H._zDEFAULT)
            H.Report("","SUB-CONTAINER type is ["..CONTAINER_type.."]","")
            H.Report("","NMS_MOD_DEFINITION_CONTAINER sub-table["..i.."] is not a pure 'Dictionnary'.  Please correct your script!","ERROR")
          end
          
          if not IsBadContainer then
            HandleAllExtraFiles(H,_bScriptNamePath,IsCOMBINE_MODS_flag,IsFirstCOMBINE_MODS_flag,IsMEFTIexist_flag,IsFirstScriptInSubFolder_flag)
            os.rename([[.\MOD\LocTable.mxml]],[[.\MOD\LocTable.MXML]])
            
            if not H.gIs_LEAN_MODE then
              print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
            end
            -->>>>>>>>>>>>>>>>>>>>>>>>
            ProcessScript(H, Container[i], True, H._bScriptName, IsCOMBINE_MODS_flag, IsFirstCOMBINE_MODS_flag, IsEndCOMBINE_MODS_flag, conf) -- , H._bScriptCounter
            -->>>>>>>>>>>>>>>>>>>>>>>>
          end
          
          H.Report("","Ended sub-script "..i.." of [["..H._bScriptName.."]] in "..H.dClock(os.clock() - startSubScriptProcessingTime))
          if i == #Container then
            endedInDelta = os.clock() - startScriptProcessingTime
            -- totalAccumulatedTime = totalAccumulatedTime + endedInDelta
            print(" "..H._zBLACKonYELLOW.." >>> Ended script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." ['"..H._bScriptName.."'] in "..H.dClock(endedInDelta).." "..H._zDEFAULT)
            
            ShowProgressBar(H)
            
            H.Report("","Ended script [["..H._bScriptName.."]] in "..H.dClock(endedInDelta))
          end
          H.Report("","========================================================================================}")
          
          --spacing for sub-script
          print("")
          H.Report("")
          
          if H.gDEBUG_StopAfterScript then H.WFAK("go for next script...") end
        end --for i=1,#Container do
        
      else
        --only one table in container
        H.Report("")
        H.Report("","========================================================================================")
        H.Report("","Starting to process script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." [["..H._bScriptName.."]] {")
        -- if H._bExtraFilesInPAK == "Y" then
          -- H.Report("",[[Copying ModScript\GlobalMEFTI content to MODBUILDER\MOD...]])
        -- end
        
        print(H._zBRIGHTGREEN.."              ++++++++++  A Single-MOD script  ++++++++++"..H._zDEFAULT)
        
        H.DelayedCONTAINERdata = H.ReportDelayedInfo(H.DelayedCONTAINERdata,"H.DelayedCONTAINERdata")
        H.DelayedReportData = H.ReportDelayedInfo(H.DelayedReportData,"H.DelayedReportData")
        
        if IsCOMBINE_MODS_flag then
          if not H.gIs_LEAN_MODE then
            print(H._zBRIGHTORANGE.."    Auto-combine flag detected"..H._zDEFAULT)
          end
          H.Report("","Auto-combine flag detected")
        end
        
        print("")
        
        local IsBadContainer = false
        local CONTAINER_type = H.GetTableType(gNMS_MOD_DEFINITION_CONTAINER)
        if CONTAINER_type ~= "Dictionary" then
          IsBadContainer = true
          printf("==> "..H.gcNOTICE.." CONTAINER_type is <%s> "..H._zDEFAULT,CONTAINER_type)
          print(">>> "..H.gcERROR.." [ERROR] NMS_MOD_DEFINITION_CONTAINER is not a pure 'Dictionnary'.  Please correct your script! "..H._zDEFAULT)
          H.Report("","CONTAINER_type is <"..CONTAINER_type..">","")
          H.Report("","NMS_MOD_DEFINITION_CONTAINER is not a pure 'Dictionnary'.  Please correct your script!","ERROR")
        end

        if not IsBadContainer then
          HandleAllExtraFiles(H,_bScriptNamePath,IsCOMBINE_MODS_flag,IsFirstCOMBINE_MODS_flag,IsMEFTIexist_flag,IsFirstScriptInSubFolder_flag)
          os.rename([[.\MOD\LocTable.mxml]],[[.\MOD\LocTable.MXML]])
          
          if not H.gIs_LEAN_MODE then
            print(H._zBRIGHTORANGE.."--------------------------------------------------------------------------------------"..H._zDEFAULT)
          end
          -->>>>>>>>>>>>>>>>>>>>>>>>
          ProcessScript(H, gNMS_MOD_DEFINITION_CONTAINER, false, H._bScriptName, IsCOMBINE_MODS_flag, IsFirstCOMBINE_MODS_flag, IsEndCOMBINE_MODS_flag, conf) -- , H._bScriptCounter
          -->>>>>>>>>>>>>>>>>>>>>>>>
        end
        
        local endedInDelta = os.clock() - startScriptProcessingTime
        -- totalAccumulatedTime = totalAccumulatedTime + endedInDelta
        print(" "..H._zBLACKonYELLOW.." >>> Ended script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." ['"..H._bScriptName.."'] in "..H.dClock(endedInDelta).." "..H._zDEFAULT)
        
        ShowProgressBar(H)
        
        H.Report("","Ended script [["..H._bScriptName.."]] in "..H.dClock(endedInDelta))
        H.Report("","========================================================================================}")
        
        if H.gDEBUG_StopAfterScript then H.WFAK("for next script...") end
      end
    else
      --BAD NMS_MOD_DEFINITION_CONTAINER
      H.Report("")
      H.Report("","========================================================================================")
      H.Report("","Starting to process script #"..H._bScriptCounter.."/"..H._bTotalNumberScripts.." [["..H._bScriptName.."]] {")
      
      H.DelayedCONTAINERdata = H.ReportDelayedInfo(H.DelayedCONTAINERdata,"H.DelayedCONTAINERdata")
      H.DelayedReportData = H.ReportDelayedInfo(H.DelayedReportData,"H.DelayedReportData")
      
      -- remove extended script .luax
      H.DeleteFile(H.LoadFileData("CurrentModScript.txt").."x")
      
      H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": "..H._bScriptName..": Could not load NMS_MOD_DEFINITION_CONTAINER"
      
      H.WriteToFile("", "MOD_MBIN_SOURCE.txt")
      H.WriteToFile("", "MOD_PAK_SOURCE.txt")
      H.WriteToFile("", "MOD_FILENAME.txt")
      H.WriteToFile("", "MOD_AUTHOR.txt")
      H.WriteToFile("", "LUA_AUTHOR.txt")
      H.WriteToFile("", "MOD_MAINTENANCE.txt")
      H.WriteToFile("", "LoadScriptAndFilenamesERROR.txt")
      
      if InternalFunctionProblem then
        print(">>> "..H.gcERROR.." [ERROR] A function name conflicts with an internal one, this script has a problem! "..H._zDEFAULT)
        print("")
        H.Report("","Impossible to load USER script!","ERROR")
        H.Report("","A function name conflicts with an internal one, this script has a problem!","  >>>")
        H.Report("","Check the 'Analysis section' of the cmd window or the log.lua file for info }","  >>>")
      -- elseif IsBadContainer then
        -- print(">>> "..H.gcERROR.." [ERROR] NMS_MOD_DEFINITION_CONTAINER is a mixed table, this script has a problem! "..H._zDEFAULT)
        -- print("")
        -- H.Report("","Impossible to load USER script!","ERROR")
        -- H.Report("","NMS_MOD_DEFINITION_CONTAINER is a mixed table, this script has a problem!","  >>>")
      else
        print(">>> "..H.gcERROR.." [ERROR] NMS_MOD_DEFINITION_CONTAINER is not a valid table or is empty, this script has a problem! "..H._zDEFAULT)
        print("")
        H.Report("","Impossible to load USER script!","ERROR")
        H.Report("","NMS_MOD_DEFINITION_CONTAINER is not a valid table or is empty, this script has a problem!","  >>>")
        H.Report("","Check the 'Analysis section' of the cmd window or the log.lua file for info }","  >>>")
      end

      ShowProgressBar(H)
    end
    
    --save H._bScriptCounter for batch
    H.WriteToFile(tostring(H._bScriptCounter), "ScriptCounter.txt")
    
    if gDEBUG_NamedValue then
      print(">>>>>>>>>>>>>>>>> Saved Values still available in following scripts <<<<<<<<<<<<<<<<<")
      for key,v in pairs(H.gSavedValues) do
        print("   >>> ["..key.."] = ["..v.."]")
      end
      print("            >>>>>>>>>>>>>>>>>>>> END <<<<<<<<<<<<<<<<<<<<<<")
    end
    
    print("")
    -- print(H._zDARKGRAY.."-----------------------------------------------------------"..H._zDEFAULT)
    print("          "..H._zWHITEonDARKCYAN.."        Scripts processed: "..H._bScriptCounter.." "..H._zDEFAULT)
    print("          "..H._zWHITEonDARKCYAN.." Total scripts to process: "..H._bTotalNumberScripts.." "..H._zDEFAULT)
    -- print(H._zDARKGRAY.."-----------------------------------------------------------"..H._zDEFAULT)
    
    if not H.gIsGlobalIndividual then
      --when combined mod
      if H._bTotalNumberScripts == H._bScriptCounter then
        if not H.gIs_LEAN_MODE then
          print("")
          print(H._zBRIGHTGREEN..">>> Done building ALL scripts"..H._zDEFAULT)
        end
        H.Report("","Done building ALL scripts")
        
        --is this required?
        -- if H._bCOPYtoNMS ~= "NONE" then
          -- print(H._zBRIGHTGREEN..">>> Copying PAK to NMS MOD folder..."..H._zDEFAULT)
          -- H.Report("","Copied PAK to NMS MOD folder...")
        -- end
      end
    end
  end -- for i=1,H._bTotalNumberScripts do
  
  -- printf("TOTAL ACCUMULATED TIME = %s",H.dClock(totalAccumulatedTime))

  -- print("@@@ Before H.gModScriptFailed handling")
  if H.IsFileExist("FailedScriptList.txt") then
    for i=1,#H.gModScriptFailed do
      H.WriteToFileAppend(H.gModScriptFailed[i].."\n","FailedScriptList.txt")
    end
  end
  -- printf("IsCOMBINE_MODS_flag = [%s]",tostring(IsCOMBINE_MODS_flag))
  return IsCOMBINE_MODS_flag
end --pre_processScripts()

function IsCompilerVersionsEqual(H)
  local sLV,nLV = H.GetMBINCompilerVersion([[MBINCompiler.latest.exe]])
  local sPV,nPV = H.GetMBINCompilerVersion([[MBINCompiler.public.exe]])
  if sLV == sPV then
    return true
  end
  return false
end

-- ****************************************************
--        MAIN            MAIN          MAIN
-- ****************************************************
--          WE ARE IN MODBUILDER folder

local startLAEM = os.clock()

local _mWbertro = os.getenv("_mWbertro")
_mDEBUG = os.getenv("_mDEBUG")

if H == nil then dofile("LoadHelpers.lua") end
if _mWbertro and _mDEBUG then dofile("LoadHelpers_2.lua") end

-- H.ShowLocals(2) -- show locals here
local H = H
H.DEBUG_PSARC = (os.getenv("_mPSARC") == "Y")

-- print("Local H.")
-- for key,v in pairs(H) do
  -- H.printf("%40s = %s",key,tostring(v))
-- end
-- print("END: Local H.")

H.prn = H.pv --print
printf = H.printf
DPType = H.DPType

if _mDEBUG then
  print("WWW _mDEBUG is ACTIVE MMM")
  H.WFAK()
end

-- LDebug = true
if LDebug then print("***     STARTING LoadAndExecuteModScript.lua") end

H.gfilePATH = "..\\" --for Report()

H.THIS = "In LoadAndExecuteModScript: "

if false then H.WFAK("Starting LoadAndExecuteModScript") end

-- xml2lua
      -- print("")
      -- local xml2lua = dofile([[.\xml2lua\xml2lua.lua]])
      -- print("==> xml2lua v" .. xml2lua._VERSION.."\n")

      -- local handler = dofile([[.\xml2lua\xmlhandler\tree.lua]])

      -- -- local parser = xml2lua.parser(handler)
      -- -- parser:parse(H.LoadFileData(H.gNMS_SETTINGS_FOLDER_PATH..[[GCMODSETTINGS.MXML]]))
      -- local xml = H.ParseTextFileIntoTable(H.gNMS_SETTINGS_FOLDER_PATH..[[GCMODSETTINGS.MXML]])
      -- table.remove(xml,1)
      -- local xmlString = table.concat(xml)

      -- local xmlHandler = handler:new()
      -- local xmlParser = xml2lua.parser(xmlHandler)
      -- xmlParser:parse(xmlString)
      -- xml2lua.printable(xmlHandler.root)

      -- H.WFAK()
-- END: xml2lua

-- TESTING package types
    -- local backupFolder = [[..\TEST PAKS\]]
    -- local zip = [[___TEST 02 ext_func_(2).zip]]
    -- local _7z = [[___TEST 02 ext_func_(2).7z]]
    -- local pak = [[___TEST 02 ext_func_(2).pak]]

    -- local nmsFolder = [[C:\SteamLibrary\steamapps\common\No Man's Sky\GAMEDATA\PCBANKS\]]
    -- local hgpak = [[NMSARC.globals.pak]]

    -- -- H.printf("pakTypeZIP = [%s]",H.GetPakType(backupFolder..zip))
    -- -- H.printf("pakType7Z = [%s]",H.GetPakType(backupFolder.._7z))
    -- -- H.printf("pakTypePSAR = [%s]",H.GetPakType(backupFolder..pak))
    -- -- H.printf("pakTypeHGPAK = [%s]",H.GetPakType(nmsFolder..hgpak))
    -- -- H.WFAK()

    -- local success,result = H.psarc_CL("LIST", backupFolder, pak)
    -- H.printf("PAK result = [%s]",result)
    -- -- Listing ..\TEST PAKS\\___TEST 02 ext_func_(2).pak
    -- -- 02 ext_func processing.lua (405/643 62%)
    -- -- AMUMSS.v5.0.0.0W.txt (0/0 100%)
    -- -- METADATA/REALITY/CATALOGUECRAFTING.MBIN (1702/7560 22%)
    -- H.WFAK()

    -- local success,result = H.psarc_CL("LIST", nmsFolder, hgpak)
    -- H.printf("HGPAK result = [%s]",result)
    -- H.WFAK()

    -- local success,result = H.psarc_CL("LIST", backupFolder, zip)
    -- H.printf("ZIP result = [%s]",result)
    -- H.WFAK()

    -- local success,result = H.psarc_CL("LIST", backupFolder, _7z)
    -- H.printf("7z result = [%s]",result)
    -- H.WFAK(" === STOP HERE ===")
-- END: TESTING package types

-- H.gMASTER_FOLDER_PATH = string.gsub(lfs.currentdir(),[[MODBUILDER]],"")

if lfs.currentdir() ~= H.gMASTER_FOLDER_PATH..[[MODBUILDER]] then
  print()
  print(H.gcERROR.." [ERROR]                AMUMSS main folder is not correctly positioned!               "..H._zDEFAULT)
  print(H.gcERROR.."   [ERR]    Make sure you are executing BUILDMOD.bat from the main AMUMSS root folder "..H._zDEFAULT)
  print(H.gcERROR.."   [ERR]        Not from inside MODBUILDER or a sub-folder, for example               "..H._zDEFAULT)
  print()
  
  H.Report("","AMUMSS main folder is not correctly positioned!","ERROR")
  H.Report("","Make sure you are executing BUILDMOD.bat from the main AMUMSS root folder","  >>>")
  H.Report("","Not from inside MODBUILDER or a sub-folder, for example","  >>>")
  
  H.WriteToFile("BADAMUMSSFOLDER",[[exitCode.txt]])  
  H.Report_flush(false,H.THIS)
  -- skip BUG reporting
  H.LuaEndedOk(H.THIS)
  -- H.WriteToFile("", "LoadScriptAndFilenamesERROR.txt")
  H.WFAK()
  os.exit(-1)
end

-- Test if NMS version is of the right type paks
local pakToTest = ""

if H.IsFileExist(H.gNMS_PCBANKS_FOLDER_PATH.."NMSARC.globals.pak") then
  -- new style
  pakToTest = H.gNMS_PCBANKS_FOLDER_PATH.."NMSARC.globals.pak"
else
  -- old style
  pakToTest = H.gNMS_PCBANKS_FOLDER_PATH.."NMSARC.59B126E2.pak"
end
 
local pakType = H.GetPakType(pakToTest)
if pakType == "HGPAK" then
  -- OK to proceed
else
  if pakType == "PSARC" then
    print(H.gcERROR.." [ERROR] PCBANKS pak type is wrong for this AMUMSS version, you need to use AMUMSS prior to v5 "..H._zDEFAULT)
    H.Report("","PCBANKS pak type is wrong for this AMUMSS version, you need to use AMUMSS prior to v5","ERROR")    
  else
    print(H.gcERROR.." [ERROR] UNKNOWN PCBANKS pak type for this AMUMSS version "..H._zDEFAULT)
    H.Report("","UNKNOWN PCBANKS pak type this AMUMSS version","ERROR")    
  end

  H.WriteToFile("BADPAKTYPE",[[exitCode.txt]])
  H.Report_flush(false,H.THIS)
  H.LuaEndedOk(H.THIS)
  H.WFAK()
  os.exit(-1)
end
-- END: Test if NMS version is of the right type paks

H.gPathToModbuilderMod = [[.\MOD\]] --was [[MODBUILDER\MOD\]]
--in case it does not yet exist
H.mkdir(H.gPathToModbuilderMod)

H.gPathToModScriptFromModbuilder = [[..\ModScript]]

-- H.gCurrentMBINCompilerPath = [[MBINCompiler.exe]]

-- gMEFTI_name = [[MEFTI]]

H.gSCRIPTBUILDERscript = false

--to print them
--GetLuaCurrentKeyWordsAndAll(_G,"",true)

--Get all environment variables once

--all the LUA exe
H._mLUA = os.getenv("_mLUA") -- general use
H._mLUAM = os.getenv("_mLUAM") -- used by CreateMapFileTreeStarter.lua
H._mLUAS = os.getenv("_mLUAS") -- used by CreateMapFileTree.lua with runThisJob.exe
H._mLUAC = os.getenv("_mLUAC") -- used by H.THIS
-- if not H._mLUA or not H._mLUAM or not H._mLUAS or not H._mLUAC then
  -- print("_mLUA  = "..tostring(H._mLUA))
  -- print("_mLUAM = "..tostring(H._mLUAM))
  -- print("_mLUAS = "..tostring(H._mLUAS))
  -- print("_mLUAC = "..tostring(H._mLUAC))
  -- print("[WARNING] _mLUAx does not exist!")
  -- H.WFAK()
-- end

H.gMaxNumberOfGroups = 50

H.gIs_FULL_MODE = (os.getenv("_DEV_MODE") == "F")
if H.gIs_FULL_MODE then
  -- # of replacments to start limiting similar output in cmd window
  H.gMaxReplNumber = math.maxinteger
end

H.gIs_DEV_MODE = (os.getenv("_DEV_MODE") == "D")
if H.gIs_DEV_MODE then
  -- # of replacments to start limiting similar output in cmd window
  H.gMaxReplNumber = 15
end

H.gIs_LEAN_MODE = (os.getenv("_DEV_MODE") == "L")
if H.gIs_LEAN_MODE then
  -- # of replacments to start limiting similar output in cmd window
  H.gMaxReplNumber = 0
end

H.gIs_MODSfolderNameScript = (os.getenv("-MODSfolderNameScript") == "Y")
if H.gIs_MODSfolderNameScript == nil then
  H.gIs_MODSfolderNameScript = false
end

H._bScriptName = os.getenv("_bScriptName")
H._bExtraFilesInPAK = os.getenv("_bExtraFilesInPAK")
H._bTestScript = (os.getenv("-TestScript") == "Y")

H._bGlobalCOMBINE_MOD_TYPE = tonumber(os.getenv("_bCOMBINE_MOD_TYPE"))
H.gIsGlobalIndividual = (os.getenv("-CombineModPak") == "N")

H._bCombinedModType = tonumber(os.getenv("-CombinedModType"))
if not H._bCombinedModType then
  H._bCombinedModType = 3 -- when nil (ASK), default to 3
end
if _mDEBUG then
  printf('==================================================>>> os.getenv("-CombinedModType") = [%s]',os.getenv("-CombinedModType"))
  printf('==================================================>>>             _bCombinedModType = [%s]',H._bCombinedModType)
end

H.gGUIF_AllowRequests = os.getenv("-GUIF_AllowRequests")
if H.gGUIF_AllowRequests == "ASK" then
  H.gGUIF_AllowRequests = H.AChoice(" "..H._zBLACKonYELLOW.." Do you want to globally allow user input requests from scripts? "..H._zDEFAULT,"YN",3)
end

GUIF_AllowRequests = (H.gGUIF_AllowRequests == "Y")

if not GUIF_AllowRequests then
  print(" "..H.gcNOTICE.." >>> GUIF processing is globally disabled "..H._zDEFAULT)
  H.Report("",">>> GUIF processing is globally disabled")
elseif H.GUIF_delayMult ~= 1 then
  print(" "..H.gcNOTICE.." >>> GUIF global multiplier set to "..H.GUIF_delayMult.." "..H._zDEFAULT)
  H.Report("",">>> GUIF global multiplier set to "..H.GUIF_delayMult)
end

H.IsPATCH = (os.getenv("_bPATCH") == "1")
-- printf("WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW   H.IsPATCH = %s",tostring(H.IsPATCH))

H._mIncludeLuaScriptInPak = os.getenv("-IncludeLuaScriptInPak")

H.gIs_IncludeTagsInEXML_MXML = (os.getenv("-IncludeTagsInEXML_MXML") == "Y")
if H.gIs_IncludeTagsInEXML_MXML == nil then
  H.gIs_IncludeTagsInEXML_MXML = true
end

H._bCOPYtoNMS = os.getenv("_bCOPYtoNMS")
-- print("LAEMS: _bCOPYtoNMS = ["..H._bCOPYtoNMS.."]")

H._bAllowMapFileTreeCreator = os.getenv("_bAllowMapFileTreeCreator")

H._bCreateMapFileTree = os.getenv("_bCreateMapFileTree") --internal only
H._bReCreateMapFileTree = os.getenv("-ReCreateMapFileTree") --from OPTIONS

H._mUSE_TXT_MAPFILETREE = (os.getenv("-MAPFILETREE") == "TXT") or (os.getenv("-MAPFILETREE") == "TXTPLUS")
H._mUSE_LUA_MAPFILETREE = (os.getenv("-MAPFILETREE") == "LUA") or (os.getenv("-MAPFILETREE") == "LUAPLUS")

H._mUSE_TXTPLUS_MAPFILETREE = os.getenv("-MAPFILETREE") == "TXTPLUS"
H._mUSE_LUAPLUS_MAPFILETREE = os.getenv("-MAPFILETREE") == "LUAPLUS"

H._bMaxPakNameLength = tonumber(os.getenv("_bMaxPakNameLength"))

-- H.UpdateMODDER_Helper = os.getenv("-MODDER_HELPER") == "Y" or false
H.UpdateMODDER_Helper = true

H.EXPORTED = os.getenv("-EXPORTED") == "Y" or false

--default date format
H._mDateTimeFormat = "%Y/%m/%d-%H:%M:%S"
H.CustomDateTimeFormat = false

-- make date format configurable
if H.IsFileExist([[..\CONFIG\DateTimeFormat.txt]]) then
  local tmpDTF = H.LoadFileData([[..\CONFIG\DateTimeFormat.txt]])
  if tmpDTF and tmpDTF ~= H._mDateTimeFormat then
    H._mDateTimeFormat = tmpDTF
    H.CustomDateTimeFormat = true
  end
end

local now = os.date(H._mDateTimeFormat)
-- H.WriteToFile(now,[[DateTime.txt]]) --file used by ???

local cleanedNow = now:gsub([[/]],[[]]):gsub([[\]],[[]]):gsub([[:]],[[]]):gsub([[*]],[[]]):gsub([[?]],[[]]):gsub([["]],[[]]):gsub([[<]],[[]]):gsub([[>]],[[]]):gsub([[|]],[[]])
H.WriteToFile(cleanedNow,[[cleanedDateTime.txt]]) --file only used by CreateMod.bat
-- END: default date format

-- _bOS_bitness = os.getenv("_bOS_bitness")
-- _bCPU = os.getenv("_bCPU")
-- _bMinCPU = os.getenv("_bMinCPU")

H.S_msg_report_new_equal_old_value = H.IsFileExist([[..\WOPT_CheckNewOldValue.txt]])

H._mSHOWSECTIONS = os.getenv("-SHOWSECTIONS")
if H.gIs_LEAN_MODE then
  H._mSHOWSECTIONS = "N"
end
H.IsShowSections = H._mSHOWSECTIONS == "Y"

H._mSHOWEXTRASECTIONS = os.getenv("-SHOWEXTRASECTIONS")
if H.gIs_LEAN_MODE then
  H._mSHOWEXTRASECTIONS = "N"
end

H._mSERIALIZING = os.getenv("_mSERIALIZING") -- by main folder file trigger
H._mSerializeScript = os.getenv("-SerializeScript") -- by OPTIONS
if H.gIs_LEAN_MODE then
  H._mSerializeScript = "N"
end

H.IsEXT_FUNC_Helper = os.getenv("-EXT_FUNC_Helper") == "Y"

-- H.gCompress_PAK = os.getenv("-CompressPAK")
-- if H.gCompress_PAK == "N" then
  -- print(" "..H.gcNOTICE.." >>> GLOBAL created PAK compression is OFF "..H._zDEFAULT)
  -- H.Report("",">>> GLOBAL created PAK compression is OFF ")
-- elseif H.gCompress_PAK == "Y" then
  -- print(" "..H.gcNOTICE.." >>> GLOBAL created PAK compression is ON "..H._zDEFAULT)
  -- H.Report("",">>> GLOBAL created PAK compression is ON ")
-- elseif H.gCompress_PAK == "S" then
  -- print(" "..H.gcNOTICE.." >>> Compression of created PAKs can be controlled by scripts, defaults to ON "..H._zDEFAULT)
  -- H.Report("",">>> Created PAK compression can be controlled by scripts, defaults to ON ")
-- end
H.Report("")
--END: Get all environment variables once

--always remove/reset it
os.remove(H.gPathToModScriptFromModbuilder..[[\GENERIC.lua]])

-- print("***************************************************************************************    arguments")
-- printf("type(arg) = %s",type(arg))
-- for i=1,#arg do
  -- printf("***************************************************************************************    arg[%d] = %s",i,tostring(arg[i]))
-- end

-- printf(" %s H.A... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startLAEM),H._zDEFAULT)
-- ****************************************************************************************
--refresh Script List
if #arg == 0 and #H.gModScriptValidContent == 0 then
  -- print("preparing the Script list...")
  print("  >>> Fetching list of active scripts, one moment...")
  H.GetModScriptValidContent(H.gPathToModScriptFromModbuilder)
end
-- printf(" %s H.B... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startLAEM),H._zDEFAULT)

--***
-- H.gModScriptLuaDirList[i][x] comes from
--      H.gScriptList[i][1]: filename and path
--      H.gScriptList[i][2]: path string -- folderTooDeep
--      H.gScriptList[i][3]: bool -- pathTooLong
--      H.gScriptList[i][4]: string -- auto-combine
--      H.gScriptList[i][5]: bool -- MEFTI exist
H.gModScriptLuaDirList = {}

-- refresh ScriptList to remove 'too deep' and 'too long path' if any
for i=1,#H.gScriptList do
  -- print("=== "..i..": ["..tostring(H.gScriptList[i][2]).."] "..tostring(H.gScriptList[i][3]).." ["..H.gScriptList[i][1].."]")
  if H.gScriptList[i][2] == "" and not H.gScriptList[i][3] then
    H.gModScriptLuaDirList[#H.gModScriptLuaDirList+1] = H.gScriptList[i]
  end
end
-- print("#H.gModScriptLuaDirList = "..#H.gModScriptLuaDirList)

if #arg == 0 then
  -- Report 'too deep' and 'too long path'
  -- NOTE: print versions have ALREADY been shown
  local First = true
  local info = ""
  for i=1,#H.gModScriptValidContent do
    -- print("=== "..i..": ["..tostring(H.gModScriptValidContent[i][2]).."] "..tostring(H.gModScriptValidContent[i][3]).." ["..H.gModScriptValidContent[i][1].."]")
    if H.gModScriptValidContent[i][2] ~= "" then
      if First then
        First = false
        H.Report("")
      end
      if info ~= H.gModScriptValidContent[i][2] then
        if info == "" or H.gModScriptValidContent[i][2]:sub(1,#info) ~= info then
          H.Report("",[[>>> ModScript sub-folder >>>]]..H.gModScriptValidContent[i][2]..[[<<< (and its sub-folders) are too deep and will not be used.]],"NOTICE")
          info = H.gModScriptValidContent[i][2]
        end
      end
    end
    if H.gModScriptValidContent[i][3] then
      if First then
        First = false
        H.Report("")
      end
      H.Report("",[[>>> Path is probably too long (> 260 char): >>>]]..H.gModScriptValidContent[i][1]..[[<<< You should correct that!]],"WARNING")
    end
  end
  if not First then
    H.Report("")
  end
end
-- ****************************************************************************************
H._bTotalNumberScripts = #H.gModScriptLuaDirList
if LDebug then print("XXXXX INIT _bTotalNumberScripts = "..H._bTotalNumberScripts) end

--***
H.gModScriptPakDirList = {}
H.gModScriptPakDirList = H.GetFilesWithExt(".pak",true)

-- NOT USED
H._bTotalNumberPAKs = #H.gModScriptPakDirList
-- print("XXXXX INIT    _bTotalNumberPAKs = "..H._bTotalNumberPAKs)

--***
H._bScriptCounter = 0
H.WriteToFile("", "ScriptCounter.txt")

H.gModScriptFailed = {}
H.gModScriptEXMLDirList = {}

local _bEXML = os.getenv("_bEXML")
if _bEXML == "Y" then
  --************ an EXML was detected
  SetupGENERIC_lua(H)
end

H.BackupType = string.upper(os.getenv("-BackupType"))

  -- H.gVerbose = true
  -- H.pv("H.gVerbose is ON")

_,H.nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
-- H.printf("MBINCompiler current version: H.nV = [%f]",H.nV)
-- -- older versions do not support some command line arguments
-- H.gMBINCompilerVersionMin = 3.8401
-- -- minimum version for --typed
-- H.gMBINCompilerVersionTyped = 6.1301
  
--DEBUGGING
H.DEBUG_print = function(...) print(H._zWHITEonDARKCYAN.."At "..H.dClock()..H._zDEFAULT..": "..(...)) end

-- ALL DISABLED
H.Dprintf = function() end
function H.DEBUG_SavingToDisk_print() end
function H.DEBUG_StopAtEachProcessing_print() end
function H.DEBUG_ScriptContent_print() end
function H.DEBUG_GROUPS_print() end
function H.DEBUG_WIS_print() end
function H.DEBUG_WISS_print() end
function H.DEBUG_LoopBreak_print() end
function H.DEBUG_VCTproperty_print() end
function H.DEBUG_INLINEmath_op_print() end
function H.DEBUG_NamedValue_print() end
function H.DEBUG_TableToStringCount_print() end
function H.DEBUG_CurrentLine_print() end
function H.DEBUG_AddSectionsIntoTable_print() end
function H.DEBUG_ReplaceRAW_print() end
function H.DEBUG_TextToAdd_print() end
function H.DEBUG_TextToRemove_print() end
function H.DEBUG_SEC_print() end
function H.DEBUG_FindGroup_print() end
function H.DEBUG_FindGroup_timing_print() end

H.WDEBUG = false -- if false: no print

H.gDEBUG_StopAfterScript = false
H.gDEBUG_ScriptTypeName = false

local gDEBUG_TIMINGS = false
local gDEBUG_SavingToDisk = false
H.gDEBUG_StopAtEachProcessing = false
local gDEBUG_ScriptContent = false

H._mISxxx = false
H.gDEBUG_EXTRA_BEHAVIOR = false
H.gDEBUG_EXT_FUNC = false
H.gDEBUG_CheckTables = false
H.gDEBUG_TestLineCount = false
H.gDEBUG_GROUPS = false
local gDEBUG_WIS = false
local gDEBUG_WISS = false
local gDEBUG_VCTproperty = false
local gDEBUG_INLINEmath_op = false
local gDEBUG_NamedValue = false
local gDEBUG_TableToStringCount = false
H.gDEBUG_Before_Value_match = false
local gDEBUG_repl_done = false
local gDEBUG_LoopBreak = false
local gDEBUG_CurrentLine = false -- @@@
local gDEBUG_AddSectionsIntoTable = false
local gDEBUG_ReplaceRAW = false
local gDEBUG_TextToAdd = false
local gDEBUG_TextToRemove = false
local gDEBUG_SEC = false
local gDEBUG_FindGroup = false
local gDEBUG_FindGroup_timing = false
H.gDEBUG_CheckUniqueness = false --no print
local gDEBUG_CheckPoint = false

DEBUG_ON = true

-- UNCOMMENT
if _mWbertro == nil then
  DEBUG_ON = false
end

if DEBUG_ON then
  local y,Y = true,true
  local n,N = false,false
  
  H.WDEBUG =                       N -- SHOWS before and AFTER SAVING, will WFAK
  H.WFAKD = H.WFAK                   -- in case we really want to use it
  -- H.WFAK = print                     -- will NOT WFAK in THIS file if active
                                   
  --general                        
  gDEBUG_TIMINGS =                 N -- H.Dprintf()   <==
                                   
  H.gDEBUG_StopAfterScript =       N
  H.gDEBUG_ScriptTypeName =        N
                                   
  -- for ExchangePropertyValue     
  gDEBUG_SavingToDisk =            N
  H.gDEBUG_StopAtEachProcessing =  N -- comment H..WFAK = print above
  gDEBUG_ScriptContent =           N
                                   
  H._mISxxx =                      N -- REPLACE_TYPE <==
                                   
  H.gDEBUG_EXTRA_BEHAVIOR =        N
  H.gDEBUG_EXT_FUNC =              N
  H.gDEBUG_CheckTables =           N
  H.gDEBUG_TestLineCount =         N
  H.gDEBUG_GROUPS =                N
  gDEBUG_WIS =                     N
  gDEBUG_WISS =                    N
  gDEBUG_VCTproperty =             N
  gDEBUG_INLINEmath_op =           N
  gDEBUG_NamedValue =              N
  gDEBUG_TableToStringCount =      N -- ###  ----
  H.gDEBUG_Before_Value_match =    N
  gDEBUG_repl_done =               N
  gDEBUG_LoopBreak =               N
  gDEBUG_CurrentLine =             N -- @@@
  gDEBUG_AddSectionsIntoTable =    N
  gDEBUG_ReplaceRAW =              N -- @@@
  gDEBUG_TextToAdd =               N -- ===
  gDEBUG_TextToRemove =            N
  gDEBUG_SEC =                     N
  gDEBUG_CheckPoint =              N -- optional WOPT_ file to allow display
  
  -- for FindGroup
  gDEBUG_FindGroup =               N -- <==
  gDEBUG_FindGroup_timing =        N -- includes PROCESSORDER
  H.gDEBUG_CheckUniqueness =       N
  
  -- check if needs activation
  if gDEBUG_TIMINGS then H.Dprintf = H.printf end
  if gDEBUG_SavingToDisk then H.DEBUG_SavingToDisk_print = H.DEBUG_print end
  if H.gDEBUG_StopAtEachProcessing then H.DEBUG_StopAtEachProcessing_print = H.DEBUG_print end
  if gDEBUG_ScriptContent then H.DEBUG_ScriptContent_print = H.DEBUG_print end
  if H.gDEBUG_GROUPS then H.DEBUG_GROUPS_print = H.DEBUG_print end
  if gDEBUG_WIS then H.DEBUG_WIS_print = H.DEBUG_print end
  if gDEBUG_WISS then H.DEBUG_WISS_print = H.DEBUG_print end
  if gDEBUG_VCTproperty then H.DEBUG_VCTproperty_print = H.DEBUG_print end
  if gDEBUG_INLINEmath_op then H.DEBUG_INLINEmath_op_print = H.DEBUG_print end
  if gDEBUG_NamedValue then H.DEBUG_NamedValue_print = H.DEBUG_print end
  if gDEBUG_TableToStringCount then H.DEBUG_TableToStringCount_print = H.DEBUG_print end
  if gDEBUG_LoopBreak then H.DEBUG_LoopBreak_print = H.DEBUG_print end
  if gDEBUG_CurrentLine then H.DEBUG_CurrentLine_print = H.DEBUG_print end
  if gDEBUG_AddSectionsIntoTable then H.DEBUG_AddSectionsIntoTable_print = H.DEBUG_print end
  if gDEBUG_ReplaceRAW then H.DEBUG_ReplaceRAW_print = H.DEBUG_print end
  if gDEBUG_TextToAdd then H.DEBUG_TextToAdd_print = H.DEBUG_print end
  if gDEBUG_TextToRemove then H.DEBUG_TextToRemove_print = H.DEBUG_print end
  if gDEBUG_SEC then H.DEBUG_SEC_print = H.DEBUG_print end
  if gDEBUG_FindGroup then H.DEBUG_FindGroup_print = H.DEBUG_print end
  if gDEBUG_FindGroup_timing then H.DEBUG_FindGroup_timing_print = H.DEBUG_print end
end

--END: DEBUGGING

if not gDEBUG_CheckPoint then
  H.CheckPoint = function() end
end

H.CheckPoint(0)

collectgarbage()

H.CheckPoint(1)

-- for DEBUGGING
-- DeleteDir([[_TEMP]])
-- print("    $$$$$$$$$$$$$$$$$$   _TEMP was DELETED!    $$$$$$$$$$$$$$$")

gIsCompilerVersionsEqual = IsCompilerVersionsEqual(H)

local IsTestColor = true
if IsTestColor then
  print("")
  print(">>> "..H.gcERROR..    " Example   [ERROR]   message "..H._zDEFAULT)
  print(">>> "..H.gcWARNING..  " Example  [WARNING]  message "..H._zDEFAULT)
  print(">>> "..H.gcNOTICE..   " Example  [NOTICE]   message "..H._zDEFAULT)
  print(">>> "..H.gcATTENTION.." Example [ATTENTION] message "..H._zDEFAULT)
  
  -- print("")
  -- print("[38;2;255;0;255m[48;2;255;165;0m Hello world "..H._zDEFAULT)
  -- print("[38;5;201m[48;5;214m Hello world "..H._zDEFAULT)
  -- H.WFAK()
end

-- H.deepdump(_G,false,"_G")
-- H.deepdump(H,true,"H")

-- -- print("=== VARDUMP() -----")
-- -- H.vardump(H,"H") -- NOT informational, better use deepdump
-- -- print("=== EDN: VARDUMP() -----")

-- -- H.ShowLocals(1) -- show ShowLocals() var
-- H.ShowLocals(2) -- show locals here
-- -- H.ShowLocals(3) -- show var with no name
-- print("")
-- H.WFAK("=== END: ShowLocals() -----")

-- -- print("=== vardump(H.gModScriptValidContent) -----")
-- -- H.vardump(H.gModScriptValidContent)
-- -- H.WFAK("=== END: vardump(H.gModScriptValidContent)")

-- print("")
-- printf(" %s Ready to rock... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startLAEM),H._zDEFAULT)

if #arg == 0 then
  -- list paks in MODS
  H.Report("",[[>>> list of mods from GAMEDATA\MODS based on most recent GCMODSETTINGS.MXML...]])
  H.Report("",[[    key: #: ModPriority, ++: Enabled/EnabledVR: ModName]])
  H.Report("",[[         ?: Unknown at this time (run game to resolve)]])

  H.MODSreportList = H.ParseTextFileIntoTable("MODS_Report_list.txt")
  
  if #H.MODSreportList > 0 then
    for mpl=1,#H.MODSreportList do
      H.Report("",H.MODSreportList[mpl])
    end
  else
    H.Report("","*** NONE ***")
  end
  H.Report()
  -- END: list paks in MODS
end

--  = = = = = globals for all sub-scripts  = = = = =
H.gSection = {}

--global for all values
H.gSavedValues = {}

-- to remember the list of MBINs in MOD that came from GlobalMEFTI/MEFTI
MBIN_list = {}

-- to remember opened EXMLs during the whole time
--   key: pathfilename of the MBIN/EXML
-- value: the EXML as a table of strings
H.EXMLorgTable = {}

-- -- to remember syntax #3 EXMLs
-- H.EXML_NEWorgTable = {}

-- to remember opened files extension
--   key: pathfilename of the MBIN/EXML
-- value: the original extension as a table of strings
H.EXMLorgExtTable = {}
-- H.EXML_NEWorgExtTable = {}

-- --   key: pathfilename of the MBIN/EXML
-- -- value: the EXML as one string
-- EXMLorgStringTable = {}

-- to remember modded MXMLs during the whole time until CreateMod()
--   key: pathfilename of the MBIN/MXML
-- value: the MXML as a table of strings
H.EXMLmodTable = {}

-- to remember if this MXML should be an EXML according to the script EXML_CREATE = true
--   key: pathfilename of the MBIN/MXML
-- value: boolean
H.EXMLcreate = {}

-- a list to remember CUSTOM LANGUAGE files that need to be copied to CreatedMODS mod folder
H.customLanguageFiles = {}

-- to remember CUSTOM LANGUAGE file's parents
--   NOTE: the parent of the CUSTOM file could be another CUSTOM file, we need to go up the chain to a NMS LANGUAGE file
--   key: the pathfilename of the CUSTOM file
-- value: the LANGUAGE file this CUSTOM file is child of
H.parentOfCustomLanguageFiles = {}

-- -- a list of ENTITY files using linked=""
-- -- key: pathfilename of the ENTITY file
-- -- value: boolean
-- H.EntityFilesUsingLinked = {}

-- a list of files referenced in linked="" of an ENTITY file
-- key: pathfilename of the linked value
-- value: boolean
H.linkedFiles = {}

-- to remember modded MXMLs until a EXML is created
-- key: pathfilename of the MBIN/MXML
-- value: the MXML as a table of strings
H.clonedMXMLmodTable = {}

-- key: NMSpathfilename of the MBIN/EXML
-- value: a table of strings: the scripts using that file
scriptFileList = {}

-- key: name of table
-- value: a table of strings: the names of ReturnedData from EXT_FUNC functions
H.returnedTables = {}
-- END: = = = = = globals for all sub-scripts  = = = = =

-- printf("==> WinWxH = %s",os.getenv("_WinWxH"))
H.WinWxH = os.getenv("_WinWxH")
if H.WinWxH then
  H.WinW,H.WinH = string.match(H.WinWxH,"(%d+)x(%d+)")
else
  H.WinW,H.WinH = 150,45 -- wild guess
end
-- printf("==> WinSixe = %sx%s",H.WinW,H.WinH)

-- s = [[    <Property name="CameraShakeTable" value="GcCameraShakeData" _index="30"> # ADDED
      -- <Property name="Name" value="LARGECREATUREWA" /> # CHANGED # ADDED
      -- <Property name="TimeStart" value="0.000000" /> # ADDED]]
-- print()
-- print("["..s.."]")
-- print()

-- s = s:gsub(">[#%s%w]*\n",">"..H.modREPLACED.."\n")
-- print("["..s.."]")
-- print()

-- t = s:splitB("\n")

-- for i=1,#t do
  -- H.printf("%d: [%s]",i,t[i])
-- end
-- H.WFAK()

--################## MAIN #########################################
    -- H.IsCreateModPak = false
    H.IsArguments = false
    H.arguments = {}
    for i = 1, #arg do
      if arg[i] then
        if H.IsFileExist(arg[i]) then
          H.IsArguments = true
          H.arguments[#H.arguments+1] = arg[i]
        elseif arg[i] == "DONOTCOPYTOMOD" then
          H.arguments[#H.arguments+1] = arg[i]
        end
      end
    end
    H.IsCOMBINE_MODS = pre_processScripts(H)
--#################################################################

H.CheckPoint(98)

-- print(" = = = = = = =")
-- H.KVprint(H.EXMLmodTable)
-- print(" = = = = = = =")

-- BackupRepots
H.maxNumBackupReports = tonumber(os.getenv("-BackupReports"))
if not H.maxNumBackupReports then
  H.maxNumBackupReports = 1
end
if H.maxNumBackupReports < 0 then
  H.maxNumBackupReports = 1
end

local reportsTable = H.GetFileCreationByDate([[..\TOOLS\REPORTS_BACKUP]])

-- for i=1,#reportsTable do
  -- print(reportsTable[i])
-- end

if #reportsTable >= H.maxNumBackupReports * 2 then
  local count = #reportsTable
  if count > 2 then
    while count > (H.maxNumBackupReports-1) * 2 do
      H.DeleteFile([[..\TOOLS\REPORTS_BACKUP\]]..reportsTable[count],false,true)
      H.DeleteFile([[..\TOOLS\REPORTS_BACKUP\]]..reportsTable[count-1],false,true)
      count = count - 2
    end
  end
end
-- END: BackupRepots

H.Report_flush(false,H.THIS)

H.CheckPoint(99)
H.pv(H.THIS.."ending")
H.LuaEndedOk(H.THIS)
if LDebug then print("***     ENDING LoadAndExecuteModScript.lua") end

H.exitCode = 0
if H.IsCOMBINE_MODS then
  H.exitCode = 1
end

-- H.WFAK()

os.exit(H.exitCode)
