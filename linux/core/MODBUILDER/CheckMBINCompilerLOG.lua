--arg[1] == path to REPORT.lua
--arg[2] == path to MODBUILDER
--arg[3] == a message
--arg[4] = something, do NOT close Report
--arg[5] = (nil == print message) (something == quiet)
--arg[6] = scriptFileList (Sorted)

if H == nil then dofile(arg[2]..[[LoadHelpers.lua]]) end --in MODBUILDER
H.pv(">>>     In CheckMBINCompilerLOG.lua")
H.gfilePATH = arg[1] --for Report()
THIS = "In CheckMBINCompilerLOG: "

local LogTable = H.ParseTextFileIntoTable(arg[2]..[[MBINCompiler.log]])

--starting folder varies
local MASTER_FOLDER_PATH = string.gsub(lfs.currentdir(),[[\MODBUILDER]],"")..[[\]] -- \ required because we are in AMUMSS folder
--local MASTER_FOLDER_PATH = H.LoadFileData(arg[2]..[[MASTER_FOLDER_PATH.txt]])
local MODfolderPath = MASTER_FOLDER_PATH..[[MODBUILDER\MOD\]]
-- H.printf("==> MODfolderPath = [%s]",MODfolderPath)

-- sometimes arg[3] may have MASTER_FOLDER_PATH..[[MODBUILDER\MOD\]] in front of the message/filename
local say = H.stripBfromA(arg[3], MODfolderPath)

local Compiling = true
local MessageStart = 10
if string.sub(say,1,1) == "D" then
  --we are Decompiling
    Compiling = false
    MessageStart = 12
end

local scriptFileList = arg[6]

-- if Compiling and scriptFileList then
  -- print(" ~ ~ ~ ~ ~ ~")
  -- for k,v in pairs(scriptFileList) do
    -- for i=1,#scriptFileList[k] do
      -- printf(" - [%s] used by: [%s]",k,scriptFileList[k][i])
    -- end
  -- end
  -- print(" ~ ~ ~ ~ ~ ~")
-- end

local sayMore = string.sub(say,MessageStart)
if string.find(sayMore,"%",1,true) then
  sayMore = ""
end

-- H.printf("A: #LogTable = %d",#LogTable)
-- clean log file
local endLine = #LogTable
for i=#LogTable,1,-1 do
  if string.sub(LogTable[i],1,7) == "[INFO]:" and not string.find(string.upper(LogTable[i]),"GUID:",1,true) and not string.find(LogTable[i]," converted.",1,true) then
    table.remove(LogTable,i)
  end
end

-- H.printf("B: #LogTable = %d",#LogTable)
-- remove end of log
for i=#LogTable,1,-1 do
  if string.find(LogTable[i]," converted.",1,true) then
    endLine = i
    break
  end
end

for i=#LogTable,endLine,-1 do
  table.remove(LogTable,i)
end

-- H.printf("C: #LogTable = %d",#LogTable)

-- print("-------------   ---------------------   ---------------------")
-- for i=1,#LogTable do
  -- H.printf("%5d [%s]",i,LogTable[i])
-- end
-- print("-------------   ---------------------   ---------------------")
-- -- H.WFAK("AFTER LogTable cleanup")

local warningCount = 0
local errorCount = 0

-- reset some ERRORs to be WARNINGs
for i=1,#LogTable do
  if string.find(LogTable[i],"[WARN]",1,true) then
    warningCount = warningCount + 1
  end
  if string.find(LogTable[i],"[ERROR]",1,true) then
    if string.find(LogTable[i],"[ERROR]: No valid files found!",1,true) then
      LogTable[i] = string.gsub(LogTable[i],"ERROR","WARN")
      
      if Compiling then
        LogTable[i] = string.gsub(LogTable[i],"files","MXML files")
      else
        LogTable[i] = string.gsub(LogTable[i],"files","MBIN files")
      end
      warningCount = warningCount + 1
    else
      errorCount = errorCount + 1
    end
  end
end  

local IsWarning = false

if warningCount > 0 then
  if arg[5] == nil then
    if Compiling then
      H.Report("","Trying to compile... "..sayMore)
    else
      H.Report("","Trying to decompile... "..sayMore)
    end
  end
  
  local Found = false
  local previousInfo = ""
  for i=1,#LogTable do
    local info = LogTable[i]
    info = string.gsub(info,"%[%[","[")
    if not Found and string.find(info,"[WARN]",1,true) then
      local use = true
      
      -- we need to do this because the log is not always sequential
      -- for j=1,#LogTable do
-- H.printf("LogTable[i+2] = %s",tostring(string.find(LogTable[i+2],"guid:",1,true) ~= nil))
-- H.printf("LogTable[i+3] = %s",tostring(string.find(LogTable[i+3],"[EXPECTED INFO]: GUID:",1,true) ~= nil))
        if LogTable[i+2] and LogTable[i+3] and string.find(LogTable[i+2],"guid:",1,true) and string.find(LogTable[i+3],"[EXPECTED INFO]: GUID:",1,true) then
          -- skip
          use = false
        end
        if LogTable[i+1] and LogTable[i+2] and string.find(LogTable[i+1],"guid:",1,true) and string.find(LogTable[i+2],"[EXPECTED INFO]: GUID:",1,true) then --because, sometimes the filename line is dropped!!!
          -- skip
          use = false
        end
        -- if H.trim(LogTable[i+j]) == "" then
          -- break
        -- end
      -- end
      
      if use then
        -- NOT a GUID mismatch
        Found = true
        -- local info = LogTable[i+3] --print filepath+name
        -- print(info)
        local start,ending = string.find(info,"[WARN] [",1,true)
        if ending then
          info = string.sub(info,ending+1,#info-2)
        end
        
        if info ~= previousInfo then
          IsWarning = true
          previousInfo = H.ltrim(info)
          print("----------------------------------------")
          -- print(H._zBRIGHTRED..i.."    [WARNING] MBINCompiler = "..info.." => check your script!"..H._zDEFAULT)
          print(H._zBRIGHTORANGE.."    [WARNING] MBINCompiler = "..H.stripBfromA(info, MODfolderPath).." => check your script!"..H._zDEFAULT)
          H.Report("")
          H.Report("","MBINCompiler = "..H.stripBfromA(info, MODfolderPath).." => check your script!","WARNING")
        end
      end
    elseif Found then  
      -- if info == nil or H.trim(info) == "" 
      if string.find(info," converted.",1,true)
            or string.find(info," WARNINGS.",1,true)
            or string.find(info," TIME:",1,true)
            or string.find(info,"[FILE]",1,true)
            or string.find(info,"at System.",1,true)
            or string.find(info,"at libMBIN.",1,true)
            or string.find(info,"at MBINCompiler.",1,true)
            or string.find(info,"at Microsoft.",1,true) then
        --skip it
      -- elseif string.find(info,"EXPECTED INFO",1,true) then
        -- H.printf("%2d    [WARN]    MBINCompiler = %s",i,info)
        -- -- H.printf("    [WARN]    MBINCompiler = %s",info)
        -- H.Report("","   MBINCompiler = "..info,"WARN")
      elseif H.trim(info) == "" then
        Found = false
      -- elseif string.sub(info,1,7) == "[INFO]:" then
        -- Found = false
      -- elseif string.find(info,"FILES FAILED.",1,true) then
        -- --done, rest of the file is irrelevant
        -- break
      else
        -- H.printf("%2d    [WARN]    MBINCompiler = %s",i,info)
        H.printf("    [WARN]    MBINCompiler = %s",H.stripBfromA(info, MODfolderPath))
        H.Report("","   MBINCompiler = "..H.stripBfromA(info, MODfolderPath),"WARN")

        if scriptFileList then
          if string.find(info,[[.MXML]],1,true) then
            local exmlName = string.match(info,[[(%a:\.+)]])
            -- printf("lfs.currentdir() = [%s]",lfs.currentdir())
            exmlName = string.gsub(exmlName,lfs.currentdir()..[[\MOD\]],"")
            -- printf("===   exmlName = [%s]",tostring(exmlName))
            local scriptNames = scriptFileList[exmlName]
            -- printf("=== scriptNames = [%s]",tostring(scriptNames))
            if scriptNames then
              for i=1,#scriptNames do
                print("                                 Used by: "..scriptNames[i])
                H.Report("","                  Used by: "..scriptNames[i],"ERR")
              end
            end
          end
        end
        
      end
    end

    -- if string.find(info," converted.",1,true) then
      -- -- no need to process the rest of the file
      -- -- it would only duplicate the info
      -- break
    -- end
  end
  --H.WFAK()
end

local IsError = false

if errorCount > 0 then
  if arg[5] == nil then
    if Compiling then
      H.Report("","Trying to compile... "..sayMore)
    else
      H.Report("","Trying to decompile... "..sayMore)
    end
  end
  
  local Found = false
  for i=1,#LogTable do
    local info = LogTable[i]
    info = string.gsub(info,"%[%[","[")
    
    if not Found and string.find(info,"[ERROR]",1,true) then
      Found = true
      -- local info = LogTable[i+3] --print filepath+name
      -- print(info)
      local start,ending = string.find(info,"[ERROR]: [",1,true)
      if ending then
        info = string.sub(info,ending,#info-1)
      end
      
      IsError = true
      print("----------------------------------------")
      print(H._zBRIGHTRED.."      - [ERROR]  MBINCompiler = "..H.stripBfromA(info, MODfolderPath).." => check your script!"..H._zDEFAULT)
      print(H._zBRIGHTRED.."      -   [ERR]  The MOD will not include this/these MXML"..H._zDEFAULT)
      
      H.Report("")
      H.Report("","MBINCompiler = "..H.stripBfromA(info, MODfolderPath).." => check your script!","ERROR")
      H.Report("","The MOD will not include this/these EXML","ERR")
      
    elseif Found then  
            -- or string.find(info,"[ERROR]",1,true)
            -- or string.find(info,"[WARN]",1,true)
            -- or string.find(info,"at libMBIN.",1,true)
     if info == nil or H.trim(info) == "" 
            or string.find(info," converted.",1,true)
            or string.find(info," FAILED.",1,true)
            or string.find(info," TIME:",1,true)
            or string.find(info,"[FILE]",1,true)
            or string.find(info,"at System.",1,true)
            or string.find(info,"at MBINCompiler.",1,true)
            or string.find(info,"at Microsoft.",1,true) then
        --skip it
      -- elseif H.trim(info) == "" then
        -- Found = false
      -- elseif string.sub(info,1,7) == "[INFO]:" then
        -- Found = false
      elseif string.find(info,"at libMBIN.",1,true) then
        Found = false
      else
-- H.printf("==> info = [%s]",info)
        print("      -   [ERR]  MBINCompiler = "..H.stripBfromA(info, MODfolderPath))
        H.Report("","  MBINCompiler = "..H.stripBfromA(info, MODfolderPath),"ERR")
        
        if scriptFileList then
          if string.find(info,[[.MXML]],1,true) then
            local exmlName = string.match(info,[[(%a:\.+)]])
            -- printf("lfs.currentdir() = [%s]",lfs.currentdir())
            exmlName = string.gsub(exmlName,lfs.currentdir()..[[\MOD\]],"")
            -- printf("===   exmlName = [%s]",tostring(exmlName))
            local scriptNames = scriptFileList[exmlName]
            -- printf("=== scriptNames = [%s]",tostring(scriptNames))
            if scriptNames then
              for i=1,#scriptNames do
                print("                                 Used by: "..scriptNames[i])
                H.Report("","                  Used by: "..scriptNames[i],"ERR")
              end
            end
          end
        end
        
      end
    end

    -- if string.find(info," converted.",1,true) then
      -- -- no need to process the rest of the file
      -- -- it would only duplicate the info
      -- break
    -- end
  end --for i=1,#LogTable do
  --H.WFAK()
end

if not (IsError or IsWarning) then
  H.Report("","   DONE "..say)
  H.DeleteFile([[MBINCompiler_log_BAD.txt]])
else
  H.WriteToFile("",[[MBINCompiler_log_BAD.txt]])
  
        -- Convert.cs
        -- public static void ConvertFile( string inputPath, string fileIn, string fileOut, FormatType inputFormat, FormatType outputFormat ) {
            -- fileOut = ChangeFileExtension( fileOut, outputFormat );
            -- Logger.LogMessage(null, "INFO", inputPath); // this is the line: [INFO]: G:\AMUMSS\MODBUILDER\MOD\GLOBALS\GCPLAYERGLOBALS.GLOBAL.MXML


  print("   "..H.gcNOTICE.." [NOTICE] Currently, due to the way MBINCompiler logging works                       "..H._zDEFAULT)
  print("   "..H.gcNOTICE.."          it is sometimes impossible to pinpoint the problem to the exact MXML above "..H._zDEFAULT)
  
  H.Report("","    Currently, due to the way MBINCompiler logging works","NOTICE")
  H.Report("","     it is sometimes impossible to pinpoint the problem to the exact MXML above"," NOTE:")
  
  -- if warningCount > 0 then
    -- print("   "..H.gcNOTICE.." [NOTICE] Possible bad file produced after "..say..", check the file!"..H._zDEFAULT)
    -- print()
    -- H.Report("","   Possible bad file produced after "..say..", check the file!","NOTICE")    
    -- -- local currentModScript = H.LoadFileData(arg[2]..[[CurrentModScript_Short.txt]])
    -- --H.WriteToFileAppend(currentModScript..": Possible failed "..say.."\n", arg[2]..[[FailedScriptList.txt]])
  -- end
  -- if errorCount > 0 then
    -- H.Report("","   Failed "..say..", check the file!","ERROR")    
    -- -- local currentModScript = H.LoadFileData(arg[2]..[[CurrentModScript_Short.txt]])
    -- -- H.WriteToFileAppend(currentModScript..": Failed "..say.."\n", arg[2]..[[FailedScriptList.txt]])
  -- end
end

H.Report_flush(arg[4],THIS)

H.LuaEndedOk(THIS)

--                        Logger.LogMessage( null, "INFO", $"{CommandLine.GetFileInfo( mbin )}" );

