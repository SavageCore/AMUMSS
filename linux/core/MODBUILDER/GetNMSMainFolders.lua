function GetNMSMainFolders(filename)
  local LineTable = H.ParseTextFileIntoTable(filename)
  -- print("#LineTable = "..#LineTable)
  
  local TempTable = {}
  
  for i=1,#LineTable do
    local text = LineTable[i]
    if string.sub(text,1,2) == "[[" then
      local endpos = string.find(text,H.gPS,1,true) - 1 
      -- print("endpos = ["..endpos.."]")
      if endpos then
        local key = string.sub(text,3,endpos)
        -- print("key = ["..key.."]")
        if not TempTable[key] then
          TempTable[key] = true
        end
      end
    end
  end
  
  local tmpTable = {}
  for k,v in pairs(TempTable) do
    tmpTable[#tmpTable+1] = k
  end
  table.sort(tmpTable)
  
  H.WriteToFile(H.ConvertLineTableToText(tmpTable), "NMSMainFolders.txt")
end

-- ****************************************************
-- main
-- ****************************************************

--we are in MODBUILDER

IsLightLoadHelper = true -- must be GLOBAL
LocalFolder = [[../]]
if H == nil then dofile("LoadHelpers.lua") end
H.pv(">>>     In GetNMSMainFolders.lua")
THIS = "In GetNMSMainFolders: "

-- H.gfilePATH = "..\\" --for Report()

THIS = "In GetNMSMainFolders: " --Check for THIS in code before changing this string

--not used
--gMASTER_FOLDER_PATH = H.LoadFileData(LocalFolder.."MASTER_FOLDER_PATH.txt")
--gMASTER_FOLDER_PATH = string.gsub(lfs.currentdir(),[[MODBUILDER]],"")

-- better to use MODBUILDER than TOOLS: the user could have changed it
GetNMSMainFolders(LocalFolder..[[MODBUILDER/pak_Dir.txtPretty.lua]])
H.LuaEndedOk(THIS)

