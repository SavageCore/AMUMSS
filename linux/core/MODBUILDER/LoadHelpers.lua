-- local startH = os.clock()

-- and selects the first value if it evaluates to false else the second value.
-- or selects the first value if it evaluates to true else the second value.

local string = string
  local strsub = string.sub
  local strgsub = string.gsub
  local strfind = string.find
  local strmatch = string.match
  local strgmatch = string.gmatch
  local strlen = string.len -- much better to use #, if you can
  local strupper = string.upper
  local strrep = string.rep
  local strformat = string.format
local print = print
local tostring = tostring
local tonumber = tonumber
local type = type
local table = table
local math = math
local os = os

local LDebug = LDebug

local gReportFilehandle = nil

local gIOstderr = io.stderr -- same for use
local gIOstdout = io.stdout -- same for use

package.path = "?.lua;./MODBUILDER/?.lua;../?.lua;"..package.path
local bint = require 'bint'(256)

H = {}
H.LH_Version = "5.5"

H.lanes = require "lanes".configure()

H.gMASTER_FOLDER_PATH = string.gsub(lfs.currentdir(),[[MODBUILDER]],"")
H.g_TEMP_DECOMPILED_PATH = H.gMASTER_FOLDER_PATH..[[\MODBUILDER\_TEMP\DECOMPILED\]]

-- https://stackoverflow.com/questions/4252176/exclude-in-xcopy-just-for-a-file-type
H.paramFiles = [[ /y /h /j /r]] -- only ALL files, no sub-folder
H.paramMExcBINFiles = [[ /y /h /j /r /EXCLUDE:xcopy_excludeMBIN.txt]] -- only files, no sub-folder, exclude .MBIN
H.paramExcMXML = [[ /s /y /h /j /r /EXCLUDE:xcopy_excludeMXML.txt]] -- with folders and sub-folders, exclude MXML, .vscode
H.paramFilesDir = [[ /s /y /h /j /r /EXCLUDE:xcopy_exclude_vscode.txt]] -- with folders and sub-folders, exclude .vscode

H.AMUMSSstring = [[__________AMUMSS_]]

H.modFlag = [[ !#]]
H.modCHANGED = H.modFlag..[[ CHANGED]]
H.modADDED = H.modFlag..[[ ADDED]]
H.modREPLACED = H.modFlag..[[ REPLACED]]
H.modLINKED = H.modFlag..[[ LINKED]]
H.modKEEP = H.modFlag..[[ KEEP]]

-- MBINCompiler.exe
H.gCurrentMBINCompilerPath = [[MBINCompiler.exe]]

-- older versions do not support some command line arguments
H.gMBINCompilerVersionMin = 3.8401
-- minimum version for --typed
H.gMBINCompilerVersionTyped = 6.1301

--***************************************************************************************************
-- numberStr: string representation of a seed
-- returns: hex string of the numberStr
-- ref: https://github.com/edubart/lua-bint
--      https://edubart.github.io/lua-bint/
function H.GetLargeHex(numberStr)
  return string.format("%016X",tostring(bint(numberStr)-bint("18446744073709551616")))
end

--***************************************************************************************************
-- can be used to redirect all print to a file
function H.printIO(...)
  local arg={...}
  local s=""
  for i=1,#arg do
          io.write(s,tostring(arg[i]))
          s="\t"
  end
  io.write("\n")
end

--***************************************************************************************************
-- print s with formatstring
-- s = the formatstring
-- ... = the arguments for s
--
-- return: nothing
function H.printf(s,...)
  print(strformat(s,...))
end

--***************************************************************************************************
-- DEBUG printf()
-- s = the formatstring
-- ... = the arguments for s
--
-- return: none
function H.Dprintf(s,...)
  print(string.format(s,...))
end

--***************************************************************************************************
-- DEBUG print type, value of a variable
--     s = the string name of a variable
--   var = the variable to inspect
-- level = indentation to use (NOT IMPLEMENTED)
-- return: none
function H.DPType(s,var,level)
  local maxLength = 300
  local prefix = H._zWHITEonDARKCYAN.."DEBUG:"..H._zDEFAULT.." ==> type("
  local tVar = type(var)
  local level = level or 0
  
  if tVar == "table" then
    if var[1] then
      if type(var[1]) == "string" then
        if #var[1] > maxLength then
          H.printf("     ==> %s, type("..s..") = <%s>, %s[1] = (%s)",tostring(var),tVar,s,strsub(var[1],1,maxLength).."...")
        else
          H.printf("     ==> %s, type("..s..") = <%s>, %s[1] = (%s)",tostring(var),tVar,s,var[1])
        end
      else
        H.printf(prefix..s..") = %s, <%s>, %s[1] = (%s)",tostring(var),tVar,s,tostring(var[1]))
      end
    else
      local nextVar = next(var)
      if type(nextVar) == "string" then
        if #nextVar > maxLength then
          H.printf("     ==> %s, type("..s..") = <%s>, %s = (%s)",tostring(var),tVar,"nextVar",strsub(nextVar,1,maxLength).."...")
        else
          H.printf("     ==> %s, type("..s..") = <%s>, %s = (%s)",tostring(var),tVar,"nextVar",nextVar)
        end
      else
        H.printf(prefix..s..") = %s, <%s>, nextVar = (%s)",tostring(var),tVar,tostring(nextVar))
      end
    end
  elseif tVar == "string" then
    if #var > maxLength then
      H.printf("     ==> type("..s..") = <%s>, %s = (%s)",tVar,s,strsub(var,1,maxLength).."...")
    else
      H.printf("     ==> type("..s..") = <%s>, %s = (%s)",tVar,s,var)
    end
  elseif tVar == "number" or tVar == "boolean" or tVar == "nil" then
    H.printf(prefix..s..") = <%s>, %s = (%s)",tVar,s,tostring(var))
  else
    H.printf(prefix..s..") = <%s>",tVar)  
  end
end

--***************************************************************************************************
-- DEBUG print table content -- recursive
function H.DprintTable(t,count,tableName)
  if type(count) ~= "number" and type(count) == "string" then
    tableName = ", ("..count..")"
    count = false
  
  elseif not tableName then
    tableName = ""
  else
    tableName = ", ("..tostring(tableName)..")"
  end
  
  if not count then count = false end
  local c = 0
  if #t > 0 then
    print(" = = = = = = ARRAY: "..#t.." records"..tableName)
    for i=1,#t do
      print(" - "..strsub(tostring(t[i]),1,350))
      if type(t[i]) == "table" then
        H.DprintTable(t[i],count) -- recursive
      end
      c = c + 1
      if count then
        if c >= count then
          print(" - ... count limit")
          break
        end
      end
    end
    print([[ \ = = = = = ]]..c)
  else
    print(" * * * * * * NOT_INDEX"..tableName)
    for k,v in pairs(t) do
      H.printf(" - [%s] = [%s]",k,strsub(tostring(v),1,350))
      if type(v) == "table" then
        H.DprintTable(v,count) -- recursive
      end
      c = c + 1
      if count then
        if c >= count then
          print(" - ... count limit")
          break
        end
      end
    end
    print([[ \ * * * * * ]]..c)
  end
end

--***************************************************************************************************
-- print key, value pairs of a table
--   t = a table
--
-- return: none
function H.KVprint(t,ShowChildren)
  print(" + + + + +")
  for k,v in pairs(t) do
    if type(v) == "string" then
      H.printf(" S- [%s] = [%s]",k,strsub(v,1,150))
    elseif type(v) == "table" then
      if ShowChildren then
        -- skip
      else
        H.printf(" T- [%s] = [%s]",k,tostring(v))
      end
    else
      H.printf(" O- [%s] = [%s]",k,tostring(v))
    end
  end
  print([[ \ + + + +]])
end

local luaTable = {
        assert = true,
collectgarbage = true,
     coroutine = true,
         debug = true,
        dofile = true,
         error = true,
  getmetatable = true,
            io = true,
        ipairs = true,
           lfs = true,
          load = true,
      loadfile = true,
          math = true,
          next = true,
            os = true,
       package = true,
         pairs = true,
         pcall = true,
         print = true,
      rawequal = true,
        rawget = true,
        rawlen = true,
        rawset = true,
       require = true,
        select = true,
  setmetatable = true,
        string = true,
         table = true,
      tonumber = true,
      tostring = true,
          type = true,
          utf8 = true,
          warn = true,
        xpcall = true,
            _G = true,
      _VERSION = true,
  }
  
-- lua keywords that prevent proper folding
H.luaKeywords = {
  [' if '] = " If ",
  [' function '] = " Function ",
  [' repeat '] = " Repeat ",
}

--***************************************************************************************************
-- luaKW: the lua keywords to correct
-- s: the string to correct
function H.correctFolding(luaKW,s)
  for k,v in pairs(luaKW) do
    strgsub(s," "..k.." "," "..v.." ")
  end
  return s
end

--***************************************************************************************************
-- printout content of a variable
function H.vardump(value, name, depth, key) -- recursive
  local linePrefix = ""
  local spaces = ""
  
  if name then
    H.printf("== VARDUMP of %s",name)
    name = nil
  end
  
  if key ~= nil then
    linePrefix = "["..key.."] = "
  end
  
  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do spaces = spaces .. "  " end
  end
  
  if type(value) == 'table' then
    mTable = getmetatable(value)
    if mTable == nil then
      print(spaces ..linePrefix.."(table) ")
    else
      print(spaces .."(metatable) ")
        value = mTable
    end		
    for tableKey, tableValue in pairs(value) do
      H.vardump(tableValue, name, depth, tableKey) -- recursive
    end
  elseif type(value) == 'function' or type(value)	== 'thread' or type(value) == 'userdata' or value == nil then
    print(spaces.."["..tostring(value).."]")
  else
    print(spaces..linePrefix.."("..type(value)..") ["..tostring(value).."]")
  end
end

--***************************************************************************************************
-- deep dumps the contents of the table and it's contents' contents
function H.deepdump(tbl,IsDoInnerDump,name,IsKeepLUA)
  if IsKeepLUA == nil then IsKeepLUA = false end
  
  local luaTable = luaTable
    
  if IsDoInnerDump == nil then IsDoInnerDump = true end
  local checklist = {}
  local list = {}
  local count = 0
  
  local function innerdump( tbl, indent, parent, name ) -- recursive
    checklist[ tostring(tbl) ] = true
    if parent == nil then
      parent = ""
    else
      parent = parent.."."
    end
    for k,v in pairs(tbl) do
      if type(k) ~= "number" and parent ~= "gFastPAKlist." then
        count = count + 1
        list[k] = string.format("%s(%8s) [%70s] = <%s>",indent,type(v),name.."."..parent..k,tostring(v)) -- ,checklist[ tostring(tbl) ]
        if IsDoInnerDump then
          if (type(v) == "table" and not checklist[ tostring(v) ]) then
            innerdump(v,indent.."",k,name) -- recursive
          end
        end
      end
    end
  end

  print("=== DEEPDUMP "..name.." -----")
  checklist[ tostring(tbl) ] = true
  innerdump( tbl, "", nil, name )
  
  -- if not IsDoInnerDump then    
    -- ***************************************
    local function f(a,b)
      return tostring(a):upper() < tostring(b):upper()
    end
    -- ***************************************
    
    -- ***************************************
    local function pairsByKeys(t,f)
      local a = {}
      for n in pairs(t) do
        a[#a+1] = n
      end
      
      table.sort(a,f)
      
      -- ***************************************
      local i = 0
      
      local iter = function()
        i = i + 1
        if a[i] == nil then
          return nil
        else
          return a[i], t[a[i]]
        end
      end
      -- ***************************************
      
      return iter
    end
    -- ***************************************
    
    for k,v in pairsByKeys(list,f) do
      if not IsKeepLUA then
        if not luaTable[H.trim(k)] then -- remove lua words
         print(v)
        end
      else
        -- keep LUA words
        print(v)
      end
    end
    
  -- else
    -- for _,v in pairs(list) do
      -- print(v)
    -- end
  -- end
  
  print("=== END: DEEPDUMP "..name.." ("..count..") -----")
end

--***************************************************************************************************
-- https://gist.github.com/Aedda/f7ce73e567636a3b7c90
function H.simpleDumpTable(t,depth)
  if depth == nil then depth = 0 end
  if depth > 50 then
    print("Quitting: Depth > 50")
    return
  end
  for k,v in pairs(t) do
    if (type(v) == "table") then
      print(string.rep("  ", depth)..k..":")
      H.simpleDumpTable(v, depth+1)
    else
      print(string.rep("  ", depth)..k..": ",v)
    end
  end
end

--***************************************************************************************************
-- https://gist.github.com/balaam/9302863
-- Call PrintTable on a table to print a nicely formated lua table to the console.
-- The print table can also be overloaded with a different type of printer to output the table in a new representation
-- like a blob.

do --   function H.PrintTable(t)
  local TabSize 	= 4
  local DataType 	= {
    Key			= "Key",
    Value		= "Value",
    ArrayEntry	= "ArrayEntry",
  }

  local DefaultPrinter = {}
  --
  -- value 	-	the current type being written out
  -- stack 	-	the stack of tables, representing the position in the data structure that the
  --				printer is printing.
  -- output	-	the table of strings that represents the output (better the basic string concatination)
  -- datatype -	the type of value being in, a key, value or array entry.
  --				[key] 	- an object that points to a value in a table
  --				[value]	- an object that is indexed by a key object
  --				[array entry] - 	if keys in a table are consecutive numbers starting from 1 lua
  --									optimizes the table and the keys are not explicitly stored.
  --
  function DefaultPrinter:_printType(value, stack, output, dataType)
    if dataType ~= DataType.Value then
      table.insert(output, string.rep(" ", #stack * TabSize))
    end

    if dataType == DataType.Key then
      table.insert(output, string.format("[%s]", tostring(value)))
    else
      table.insert(output, tostring(value))
      table.insert(output, ",\n")
    end
  end

  DefaultPrinter.number		= DefaultPrinter._printType
  DefaultPrinter['function'] 	= DefaultPrinter._printType
  DefaultPrinter.boolean		= DefaultPrinter._printType
  DefaultPrinter.thread		= DefaultPrinter._printType

  function DefaultPrinter:string(str, ...)
    self:_printType(string.format('%q', str), ...)
  end

  function DefaultPrinter:userdata(value, stack, output, dataType)
    -- An extra look up will be needed here using Type instead of type
    self:_printType(value, stack, output, dataType)
  end

  function DefaultPrinter:OpenTable(t, stack, output, dataType)
    if not next(t) then
      -- Empty table
      if dataType ~= DataType.Value then
        table.insert(output, string.rep(" ", #stack * TabSize))
      end

      if dataType == DataType.Key then
        table.insert(output, "[{")
      else
        table.insert(output, "{")
      end
      return
    end

    if dataType == DataType.Value then
      table.insert(output, "\n")
    end
    table.insert(output, string.rep(" ", #stack * TabSize))
    if dataType == DataType.Key then
      table.insert(output, "[")
    end
    table.insert(output, "{\n")
  end

  function DefaultPrinter:CloseTable(t, stack, output, dataType)
    if next(t) then
      table.insert(output, string.rep(" ", #stack * TabSize))
    end
    table.insert(output, "}")
    if dataType == DataType.Key then
      table.insert(output, "]")
    else
      table.insert(output, ",\n")
    end
  end

  function DefaultPrinter:KeyPairAssign(output)
    table.insert(output, " = ")
  end

  function DefaultPrinter:HitLoop(t, stack, output, dataType)
    table.insert(output, "[LOOP]\n")
  end


  local function IterTable(t, stack, output, dataType, printer)
    local _stack	= stack or {}
    local _data		= output or {}
    local _dataType	= dataType or DataType.Value
    local _printer 	= printer or DefaultPrinter
    _printer.table 	= function(self, ...) IterTable(...) end

    -- Do a check for recursion
    for _, v in ipairs(_stack) do
      if v == t then
        _printer:HitLoop(v, _stack, _data, DataType.ArrayEntry, _printer)
        return
      end
    end

    _printer:OpenTable(t, _stack, _data, _dataType)
    -- Push table to visited-stack
    table.insert(_stack, t)

    local _ipairsKey = {}
    for k, v in ipairs(t) do
      _ipairsKey[k] = v
      _printer[type(v)](_printer, v, _stack, _data, DataType.ArrayEntry, _printer)
    end

    for k, v in pairs(t) do
      if _ipairsKey[k] ~= v then
        _printer[type(k)](_printer, k, _stack, _data, DataType.Key, _printer)
        _printer:KeyPairAssign(_data)
        _printer[type(v)](_printer, v, _stack, _data, DataType.Value, _printer)
      end
    end

    table.remove(_stack)
    _printer:CloseTable(t, _stack, _data, _dataType)

    if not next(_stack) then
      return table.concat(_data)
    end
  end

  function H.PrintTable(t)
    if type(t) ~= "table" then
      print(tostring(t))
    end
    print(IterTable(t, nil, nil, DefaultPrinter))
  end
end

--***************************************************************************************************
-- https://gist.github.com/marcotrosi/163b9e890e012c6a460a
--[[
A simple function to print tables or to write tables into files.
Great for debugging but also for data storage.
When writing into files the 'return' keyword will be added automatically,
so the tables can be loaded with 'dofile()' into a variable.
The basic datatypes table, string, number, boolean and nil are supported.
The tables can be nested and have number and string indices.
This function has no protection when writing files without proper permissions and
when datatypes other then the supported ones are used.
--]]

-- t = table
-- f = filename [optional]
function H.tablePrintSave(t, f, name)
  local indent = "  "
  
  -- ****************
  local function printTableHelper(obj, cnt) -- recursive
    local cnt = cnt or 0
    if type(obj) == "table" then
      -- io.write("\n", string.rep(indent, cnt), "{\n")
      io.write("{\n")
      cnt = cnt + 1
      for k,v in pairs(obj) do
        if type(k) == "string" then
          -- io.write(string.rep(indent,cnt), '["'..k..'"]', ' = ')
          io.write(string.rep(indent,cnt), k, ' = ')
        end
        if type(k) == "number" then
          -- io.write(string.rep(indent,cnt), "["..k.."]", " = ")
          io.write(string.rep(indent,cnt), k, " = ")
        end
        printTableHelper(v, cnt) -- recursive
        io.write(",\n")
      end
      cnt = cnt-1
      io.write(string.rep(indent, cnt), "}")
    
    elseif type(obj) == "string" then
      -- io.write("%A%")
      local s = string.format("%q", obj)
      s = strgsub(s,'^"','[[')
      s = strgsub(s,'\"','"')
      s = strgsub(s,'"$',']]')
      io.write(s)
    
    else
      io.write(tostring(obj))
    end 
  end
  -- ****************

  if f == nil then
    printTableHelper(t)
    print("")
  else
    io.output(f)
    if not name then
      name = "TABLE = "
    else
      name = name..[[ = ]]
    end
    io.write(name)
    printTableHelper(t)
    -- reset
    io.output(io.stdout)
  end
end

--***************************************************************************************************
function H.ShowLocals(level)

  -- level = 1 shows this function
  -- level = 2 shows calling function
  if level == nil then level = 2 end
  
  local funcLevel = ""
  if level == 1 then
    funcLevel = " (THIS function ShowLocals() locals) NOT VERY USEFUL"
  elseif level == 2 then
    funcLevel = " (Calling function's locals)"
  elseif level == 3 then
    funcLevel = " (variables with no known names)"
  end
  
  print("")
  print("MMMMMMMMMMMMMMMM ShowLocals @level = "..level..funcLevel)
  
  --******************************************
  local function sorter(k1,k2)
    return strupper(k1) < strupper(k2)
  end
  --******************************************

  --******************************************
  local function pairsByKeys(t,f)
    local a = {}
    for n in pairs(t) do a[#a+1] = n end
    table.sort(a,f)
    local i = 0
    local iter = function ()
      i = i + 1
      if a[i] == nil then
        return nil
      else
        return a[i], t[a[i]]
      end
    end
    return iter
  end
  --******************************************

  local localCount = 1
  local tmpLocal = {}
  repeat
    kLocal, vLocal = debug.getlocal(level, localCount)
    if kLocal then
      local extra = ""
      
      if type(vLocal) == "table" then
        local fieldCount = 0
        for _ in pairs(vLocal) do
          fieldCount = fieldCount + 1
        end
        extra = " ("..fieldCount.." fields)"
      elseif #(tostring(vLocal)) > 100 then
        extra = " ..."
      end
      if not tmpLocal[kLocal] and strsub(kLocal,1,1) ~= "(" then
        tmpLocal[kLocal] = strsub(tostring(vLocal),1,100)..extra
      else
        tmpLocal[kLocal.."_"..localCount] = strsub(tostring(vLocal),1,100)..extra
      end
      localCount = localCount + 1
    end
  until kLocal == nil

  for k,v in pairsByKeys(tmpLocal,sorter) do
    print(string.format("(%8s) [%70s] = <%s>","",k,v))
  end
  print("WWWWWWWWWWWWWWWW   localCount = "..(localCount-1))
end

local IsNoGUIFWait = os.getenv("_mNoGUIFWait") ~= nil
--************************************
-- internal
local function KeyPressTimeOut(waitUntil)
  -- print("IN KeyPressTimeOut()")
  if waitUntil == nil then return true end
  if IsNoGUIFWait then return false end
  local endTime = os.clock() + waitUntil
  while true do
    if io.read("h") then
      return true
    elseif os.clock() >= endTime then
      return false
    end
  end
end
--************************************

--***************************************************************************************************
-- waits for a valid keypress or beeps on wrong key
-- prompt: string, what to say
--   keys: string, which keys are valid Choices
--   waitUntil: float, wait for keypress or return default after waitUntil sec
-- prints: the uppercase key that was choosen on the same line as the prompt
-- return: the uppercase key that was choosen
function H.AChoice(prompt,keys,waitUntil)
  -- print("IN Choice()")
  local answer = ""  
  if keys == nil then keys = "" end
  local keys = strupper(keys)
  
  local prompt = "'"..prompt.."'"
  
  local keyList = ""
  local keyTable = {}
  for i=1,#keys do
    keyList = keyList..strsub(keys,i,i)..","
    keyTable[#keyTable+1] = strsub(keys,i,i)
  end
  
  --clean pending keypresses
  io.read("f")
  
  --now wait for the right key
  local keyLen = #keyTable
  if keyLen == 0 then
    --output prompt and stay on same line
    --io.stdout:write(prompt.." ")
    --io.stderr:write(prompt.." ")
    gIOstderr:setvbuf("no")
    gIOstderr:write(prompt.." ")
  
    if KeyPressTimeOut(waitUntil) then
      io.read("g") --wait for any keypress
    end
    print()
  else
    --output prompt, keys and stay on same line
    --io.stdout:write(prompt.." ["..strsub(keyList,1,-2)..[=[]? ]=])
    --io.stderr:write(prompt.." ["..strsub(keyList,1,-2)..[=[]? ]=])
    gIOstderr:setvbuf("no")
    gIOstderr:write(prompt.." ["..strsub(keyList,1,-2)..[=[]? ]=])

    --H.NewThread([[<nul set /p="]]..prompt.." ["..strsub(keyList,1,-2)..[=[]? "]=])
    
    --wait for a valid keypress
    local endRepeat = false
    repeat
      if not KeyPressTimeOut(waitUntil) then
        answer = keyTable[1]
        break
      end
      
      local input = strupper(strsub(io.read("g"),-1))

      for i=1,keyLen do
        --print(input,keyTable[i])
        if input == keyTable[i] then
          answer = input
          endRepeat = true
          break
        end
      end
      if not endRepeat then
        if os.getenv("_SOUND") == "Y" then
          beep(800,150)
        end
      end
    until endRepeat
    
    print(answer)
  end
  
  return answer
end

--***************************************************************************************************
function H.WaitForAnyKey(msg,waitUntil)
  if msg == nil or msg == "" then msg = "AMUMSS waiting for any key to continue . . ." end
  H.AChoice(msg,"",waitUntil)
end

H.WFAK = H.WaitForAnyKey
H.WFAKD = print

--***************************************************************************************************
function H.IsWildcardsExist(pathname)
  return (strfind(pathname,"[%*%?]+") ~= nil)
end

--***************************************************************************************************
-- escape all MAGIC lua Patterns characters ^$()%.[]*+-? in string
function H.escapeMagicString(s)
  if type(s) == "string" then
    -- just escape ALL punctuation characters
    s = s:gsub("%p", "%%%1")
  end
  return s
end

--***************************************************************************************************
-- escape all MAGIC lua Patterns characters ^$()%.[]*+-? in table
-- return same table
function H.escapeMagicTable(t)
  for i=1,#t do
    local s = t[i]
    if type(s) == "string" then
      if not (strfind(s,"<?",1,true) or strfind(s,"<!",1,true) or strfind(s,"?>",1,true)) then
        -- just escape ALL punctuation characters
        t[i] = s:gsub("%p", "%%%1")
      end
    end
  end
  return t
end

--***************************************************************************************************
-- unescape all MAGIC lua Patterns characters ^$()%.[]*+-? in table
-- return same table
function H.unescapeMagicTable(t) 
  for i=1,#t do
    local s = t[i]
    if type(s) == "string" then
      if not (strfind(s,"<?",1,true) or strfind(s,"<!",1,true) or strfind(s,"?>",1,true)) then
        -- just escape ALL punctuation characters
        t[i] = s:gsub("%%", "")
      end
    end
  end
  return t
end

--***************************************************************************************************
-- because string.gsub pattern does not work with all folder names (ex.: ".")
function H.stripBfromA(A,B)
  if string.find(A, B,1,true) then
    local start = string.find(A, B,1,true)
    return string.sub(A,1,start - 1)..string.sub(A, #B + start)
  end
  return A
end

--***************************************************************************************************
-- plain: bool, optional, true if no wildcard
function H.IsFileExist(pathname,plain)
-- print("IsFileExist.pathname = ["..pathname.."]")
  if pathname == nil or pathname == "" then return false end
  local plain = plain or false
  -- H.printf("plain = %s",tostring(plain))
  if not plain and H.IsWildcardsExist(pathname) then
    -- print("WildCard!")
    local path = H.getPath(pathname)
    return H.IsDirExist(path)
  end
  -- print("NO wildcard!")
  -- if strfind(pathname,[[frigate_ecm_shock_missile]],1,true) then
    -- local filehandle = assert(io.open(pathname,"rb"),"io.open: Cannot open file to get file size: "..pathname)
  -- else
    local filehandle = io.open(pathname,"rb")
  -- end
  local Exist = (filehandle ~= nil)
  if Exist then filehandle:close() end
  return Exist
end

H.gVerbose = H.IsFileExist([[..\WOPT_VERBOSE_LUA.txt]]) or os.getenv("_gVERBOSE") == "Y"

if H.gVerbose then print("   [==[LUA Verbose ON]==]") end

H.gfilePATH = ".\\" --for Report()
if strfind(lfs.currentdir(),[[\MODBUILDER]]) then
  H.gfilePATH = "..\\" --for Report()
end

H.gpak_listTable = {}
H.gFastPAKlist = {}
H.gFastMainFolderList = {}

H.MXMLwithArray_sizeInfo = {}

H.gfullpak_listTable = {}

-- Full script list with additional info
H.gScriptList = {}

-- ModScript folder content
--   minus ('___DONOTUSE.txt' folders) and (those in 'ModHelperScripts'+'Disabled scripts and paks'+'GlobalMEFTI')
--   minus 'too deep'and 'too long path'
H.gModScriptValidContent = {}
H.gMEFTI_name = [[MEFTI]]

--***************************************************************************************************
-- returns the file content as a string
-- binary == "b" if you want binary ON, optional
function H.LoadFileData(pathname,binary)
  -- if LDebug then print("*** H.LoadFileData("..pathname..")") end
  local data = ""
  local filehandle
  if not binary then
    -- filehandle = assert(io.open(pathname,"r"),"io.open: Cannot open file to load: "..pathname)
    filehandle = io.open(pathname,"r")
  elseif binary == "b" then
    -- filehandle = assert(io.open(pathname,"rb"),"io.open: Cannot open binary file to load: "..pathname)
    filehandle = io.open(pathname,"rb")
  end
  -- data = assert(filehandle:read("a"),"read: cannot read file: "..pathname)
  if filehandle then
    data = filehandle:read("a")
    if strfind(pathname,".MXML",1,true) then
      data = H.TABtoSPACES(data)
    end
    filehandle:close()
  end
  return data
end

local NMS_FOLDER = H.LoadFileData([[..\CONFIG\NMS_FOLDER.txt]]):gsub("\n","") --remove line break if any

H.PCBanks_LISTdateTime = "PCBanks_listDateTime.txt"
H.PAK_LIST_CREATED = "PAK_LIST_CREATED.txt"
H.NMS_VERSION_CREATED = "NMS_VERSION_CREATED.txt"

H.gNMS_Binary_PATH = NMS_FOLDER..[[\Binaries\NMS.exe]]
H.gNMS_SETTINGS_FOLDER_PATH = NMS_FOLDER..[[\Binaries\SETTINGS\]]
H.gNMS_GAMEDATA_FOLDER_PATH = NMS_FOLDER..[[\GAMEDATA\]]
H.gNMS_PCBANKS_FOLDER_PATH = H.gNMS_GAMEDATA_FOLDER_PATH..[[PCBANKS\]]
H.gNMS_MODS_FOLDER = H.gNMS_GAMEDATA_FOLDER_PATH..[[MODS\]]

-- old
H.gNMS_PCBANKS_MODS_FOLDER = H.gNMS_PCBANKS_FOLDER_PATH..[[MODS\]]

H.MODSETTINGS_PATH = H.gNMS_SETTINGS_FOLDER_PATH.."GCMODSETTINGS.MXML"

-- using repos\selene version 0.26.1: 
--    Main Cargo.toml modded to: fullmoon = { version = "0.19.0", features = ["lua53"] }
--    do a local build with: cargo build -r  --no-default-features
--                in folder: C:\Users\Robert\source\repos\selene
-- SEE: Wbertro-update.txt
H.gDisableSelene = {
["error[undefined_variable]: `lfs` is not defined"] = true,
["error[undefined_variable]: `WFAK` is not defined"] = true,
["error[undefined_variable]: `NormalizePath` is not defined"] = true,
["error[undefined_variable]: `GUIF` is not defined"] = true,
["error[undefined_variable]: `GNH` is not defined"] = true,
["error[undefined_variable]: `printf` is not defined"] = true,
["error[undefined_variable]: `H` is not defined"] = true,
["error[undefined_variable]: `GetEnvInfo` is not defined"] = true,
["warning[shadowing]: shadowing variable `self`"] = true,
}

--***************************************************************************************************
H.gUSE_name = ""
if H.gUSE_name == nil or H.gUSE_name == "" then
  H.gUSE_name = "___USE.txt"
end

H.gDONOTUSE_name = ""
if H.gDONOTUSE_name == nil or H.gDONOTUSE_name == "" then
  H.gDONOTUSE_name = "___DONOTUSE.txt"
end

H.gCOMBINE_name = ""
if H.gCOMBINE_name == nil or H.gCOMBINE_name == "" then
  H.gCOMBINE_name = "___COMBINE.txt"
end

--***************************************************************************************************
-- returns:
--    optional delta, msg
-- or current os.clock()
function H.dClock(delta,msg)
  if msg then
    msg = " "..msg
  else
    msg = ""
  end
  if not delta then
    delta = os.clock()
  end
  if delta > 60 then
    x,y = math.modf(delta / 60)
    return string.format("%3.3f sec (%d:%02d)%s",delta,x,math.floor(y * 60),msg)
  else
    return string.format("%3.3f sec%s", delta,msg)
  end
end

--***************************************************************************************************
H.gTracing = ""
if not H.gVerbose then
  function H.pv(...)
    if H.gVerbose then
      local temp = ""
      local num = select("#",...)
      for i=1,num do
        local text = select(i,...)
        if text == nil then
          text = "nil"
        elseif type(text) == "boolean" then
          if text then
            text = "True"
          else
            text = "False"
          end
        end
        temp = temp..text
      end
      if temp ~= "" then
        temp = "<=>"..temp.." <=>"
      end
      if H.gTracing ~= "" then
        temp = temp.."   T: "..H.gTracing
        H.gTracing = ""
      end
      
      temp = H.dClock()..": "..temp
      print(temp)
    end
  end
else
  function H.pv()
  end
end 

H.pv(">>>     In LoadHelpers.lua")

do -- Color definitions
  --                                 [info]
  --                                 name = AMUMSS_colors
  --                                 author = Wbertro
  --                                 CONFIG\AMUMSS_colors.ini
  --  FG	  BG	  NAME               [table]
  -- [30m	 [40m	  Black              DARK_BLACK     =           12,12,12    -- default background
  -- [31m	 [41m	  Red                DARK_RED       =           197,15,31
  -- [32m	 [42m	  Green              DARK_GREEN     =           19,161,14
  -- [33m	 [43m	  Yellow             DARK_YELLOW    =           193,156,0
  -- [34m	 [44m	  Blue               DARK_BLUE      =           255,174,50  -- now Orange -- 0,55,218
  -- [35m	 [45m	  Magenta            DARK_MAGENTA   =           136,23,152
  -- [36m	 [46m	  Cyan               DARK_CYAN      =           58,150,221
  -- [37m	 [47m	  Gray               DARK_WHITE     =           204,204,204
  -- [90m	 [100m	Dark Gray          BRIGHT_BLACK   =           118,118,118
  -- [91m	 [101m	Bright Red         BRIGHT_RED     =           231,72,86
  -- [92m	 [102m	Bright Green       BRIGHT_GREEN   =           22,198,12
  -- [93m	 [103m	Bright Yellow      BRIGHT_YELLOW  =           249,241,165
  -- [94m	 [104m	Bright Blue        BRIGHT_BLUE    =           59,120,255
  -- [95m	 [105m	Bright Magenta     BRIGHT_MAGENTA =           180,0,158
  -- [96m	 [106m	Bright Cyan        BRIGHT_CYAN    =           97,214,214
  -- [97m	 [107m	White              BRIGHT_WHITE   =           242,242,242

  -- Set _RESET  = [0m

  -- [1m make Bold or increase intensity
  -- [2m make Faint, decrease intensity or dim
  -- [3m italic  -- ???
  -- [4m underline
  -- [5m does not work
  -- [6m does not work
  -- [7m invert
  -- [9m strikethru -- ???
end

local gIsColors = (os.getenv("-UseColors") == "Y")
local gIsColorConfig = (os.getenv("-UseColorConfig") == "Y")

if lfs.currentdir() == [[G:\AMUMSS\MODBUILDER\MBINCompilerDownloader]] then
  gIsColors = false
end

do -- if gIsColors then
  -- if H.IsFileExist("GetAMUMSS_colors.lua") then
    -- dofile([[GetAMUMSS_colors.lua]])
  -- elseif H.IsFileExist([[MODBUILDER\GetAMUMSS_colors.lua]]) then
    -- dofile([[MODBUILDER\GetAMUMSS_colors.lua]])
  -- end

  -- -- print("")
  -- -- for k,v in pairs(colors) do
    -- -- H.printf("  %15s = %s",k,v)
    -- -- local tmp = string.gsub(v,",",";").."m "..k.." "
    -- -- print("                   ==> ["..fgPrefix..tmp..reset.."]")
    -- -- print("                   ==> ["..bgPrefix..tmp..reset.."]")
  -- -- end
  -- -- print("")
  
  -- colorsTmp = {}
  -- for k,v in pairs(colors) do
    -- colorsTmp[#colorsTmp + 1] = [[fg]]..string.gsub(k,"_","").."="..fgPrefix..string.gsub(v,",",";")..[[m"]]
    -- print(colorsTmp[#colorsTmp])
    -- colorsTmp[#colorsTmp + 1] = [[bg]]..string.gsub(k,"_","").."="..bgPrefix..string.gsub(v,",",";")..[[m"]]
    -- print(colorsTmp[#colorsTmp])
  -- end
-- end
-- H.WFAK()
end

if gIsColors then
  if gIsColorConfig then
    -- see BUILDMOD.bat for definitions
    -- print("@@@ USING Colors Definitions")
    H._zBRIGHTRED       = os.getenv("_zBRIGHTRED")
    H._zDARK_MAGENTA    = os.getenv("_zDARK_MAGENTA")
    H._zBRIGHTGREEN     = os.getenv("_zBRIGHTGREEN") 
    H._zYELLOW          = os.getenv("_zYELLOW")  
    H._zBRIGHTORANGE    = os.getenv("_zBRIGHTORANGE") 
    H._zBRIGHTYELLOW    = os.getenv("_zBRIGHTYELLOW")
    H._zBLUE            = os.getenv("_zBLUE") 
    H._zBRIGHTBLUE      = os.getenv("_zBRIGHTBLUE")
    H._zDARKGRAY        = os.getenv("_zDARKGRAY")   
                       
    H._zWHITEonDARKCYAN = os.getenv("_zWHITEonDARKCYAN")
    H._zWHITEonYELLOW   = os.getenv("_zWHITEonYELLOW")
    H._zWHITEonBLUE     = os.getenv("_zWHITEonBLUE")
    H._zBLUEonDARKGRAY  = os.getenv("_zBLUEonDARKGRAY")
    H._zBLACKonYELLOW   = os.getenv("_zBLACKonYELLOW")
    H._zBLUEonYellow    = os.getenv("_zBLUEonYellow")
    
  else
    -- use defaults
    -- print("@@@ USING Default Colors")
    H._zBRIGHTRED       ="[1;91m[1m" 
    H._zDARK_MAGENTA    ="[1;35m[1m"
    H._zBRIGHTGREEN     ="[1;92m[1m"
    H._zYELLOW          ="[1;33m[1m"
    H._zBRIGHTORANGE    ="[1;91m[1m"
    H._zBRIGHTYELLOW    ="[1;93m[1m"
    H._zBLUE            ="[1;34m[1m"
    H._zBRIGHTBLUE      ="[1;94m[1m"
    H._zDARKGRAY        ="[1;90m[1m"

    H._zWHITEonDARKCYAN ="[1;46m[1m"
    H._zWHITEonYELLOW   ="[1;43m[1m"
    H._zWHITEonBLUE     ="[1;44m[1m"
    H._zBLUEonDARKGRAY  ="[34;47m"
    H._zBLACKonYELLOW   ="[7;93m"
    H._zBLUEonYellow    ="[34;43m"
    
  end
  
  H._zUnderline       ="[1;4m[1m"

  -- _zBLINK         ="[5m" --does not work
  H._zBGintense       ="[100m"
  H._zINVERSE         ="[7m"
  H._zDEFAULT         ="[0m"

else
  -- print("@@@ NOT USING Colors")
  H._zBRIGHTRED        =""
  H._zDARK_MAGENTA     =""
  H._zBRIGHTGREEN      =""
  H._zYELLOW           =""
  H._zBRIGHTORANGE     =""
  H._zBRIGHTYELLOW     =""
  H._zBLUE             =""
  H._zBRIGHTBLUE       =""
  H._zDARKGRAY         =""
  H._zWHITEonDARKCYAN  =""
  
  H._zWHITEonYELLOW    =""
  H._zWHITEonBLUE      =""
  H._zBLUEonDARKGRAY   =""
  H._zBLACKonYELLOW    =""
  H._zBLUEonYellow     =""

  H._zUnderline        =""

  H._zBGintense        =""
  H._zINVERSE          =""
  H._zDEFAULT          =""  
end

if gIsColors then
  if gIsColorConfig then
    H.gcERROR     = os.getenv("gcERROR")
    H.gcWARNING   = os.getenv("gcWARNING")
    H.gcNOTICE    = os.getenv("gcNOTICE")
    H.gcATTENTION = os.getenv("gcATTENTION")
  else
    -- use defaults
    H.gcERROR     = "[33;41m[1m"
    H.gcWARNING   = "[95;44m[1m"
    H.gcNOTICE    = "[97;104m[1m"
    H.gcATTENTION = "[7;33m[1m"
  end
else
  H.gcERROR     = ""
  H.gcWARNING   = ""
  H.gcNOTICE    = ""
  H.gcATTENTION = ""
end

-- always used
H._zUpOneLine     ="[F"
H._zUpOneLineErase="[F[K"

function H.CheckPoint(num)
  H.printf(H._zWHITEonDARKCYAN.."At "..H.dClock().." Check point #"..num.." (%.0fKb)"..H._zDEFAULT,collectgarbage("count"))
  -- H.WFAK(H._zWHITEonDARKCYAN.."At "..H.dClock().." Check point #"..num.." press a key"..H._zDEFAULT)
end

--***************************************************************************************************
--local cmd = [[...]]
--H.NewThread(cmd[,silent])
--if silent == true: no output to console
--will wait for cmd to complete
function H.NewThread(cmd,silent)
  if silent == nil then silent = false end
  local hideOutput = ""
  if silent then
    hideOutput = " 1>NUL 2>NUL"
  end
  -- /B /wait "" /MIN: order is important for it to work on win7 and early win10 version
  local state,sResult,nResult = os.execute([[START /B /wait "" /MIN cmd /c ]]..cmd..hideOutput)
  return state,sResult,nResult
end

--***************************************************************************************************
function os.capture(cmd, raw)
  if raw == nil then raw = true end
  local f = io.popen(cmd, 'r')
  local s = f:read('a')
  f:close()
  if raw then return s end
  s = strgsub(s, '^%s+', '') --strip leading spaces
  s = strgsub(s, '%s+$', '') --strip trailing spaces
  -- s = strgsub(s, '[\r\n]+', ' ') --make crlf into spaces
  return s
end

H.DelayedReportData = {}
-- H.printf("H.DelayedReportData = %s (ORIGINAL TABLE)",H.DelayedReportData)
    
-- H.DelayedCONTAINERdata = {}
-- H.printf("H.DelayedCONTAINERdata = %s (ORIGINAL TABLE)",H.DelayedReportData)
    
--***************************************************************************************************
    --[1] = ""
    --[2] = message
    --[3] = "WARNING" or "ERROR"
function H.SetReportData(DelayedReportData,a,b,c)
  -- H.printf("H.SetReportData(): DelayedReportData = %s (Function %s)",DelayedReportData,(debug.getinfo(2,"n").name))
  DelayedReportData[#DelayedReportData + 1] = {}
  DelayedReportData[#DelayedReportData][1] = a
  DelayedReportData[#DelayedReportData][2] = b
  DelayedReportData[#DelayedReportData][3] = c
end

--***************************************************************************************************
function H.ReportDelayedInfo(DelayedReportData,msg)
  local msg = msg or ""
  if DelayedReportData and #DelayedReportData > 0 then
    -- H.Report(msg.." ",(debug.getinfo(2,"n").name).." "..(debug.getinfo(2,"l").currentline),tostring(DelayedReportData))
    for m=1,#DelayedReportData do
      H.Report(DelayedReportData[m][1],DelayedReportData[m][2],DelayedReportData[m][3])
    end
    -- H.Report(msg.." BEFORE RESET",(debug.getinfo(2,"n").name),tostring(DelayedReportData))
    -- H.printf("%s H.ReportDelayedInfo(): DelayedReportData = %s (Function %s) (OLD TABLE)",msg,DelayedReportData,(debug.getinfo(2,"n").name))
    -- DelayedReportData = {} -- reset DOES NOT WORK
    return {}
    -- H.Report(msg.." AFTER RESET",(debug.getinfo(2,"n").name),tostring(DelayedReportData))
    -- H.printf("%s H.ReportDelayedInfo(): DelayedReportData = %s (Function %s) (NEW TABLE)",msg,DelayedReportData,(debug.getinfo(2,"n").name))
  end
  return DelayedReportData
end

local delayMult = tonumber(os.getenv("-GUIF_delayMult"))
H.GUIF_delayMult = 1
if type(delayMult) == "number" then
  H.GUIF_delayMult = math.abs(delayMult)
end

--***************************************************************************************************
--    var: table
--   waitUntil: optional, float, wait for keypress or return default after waitUntil sec
--output prompt and stay on same line
--  return: a user value of the same type as var[1]
--          or var[1]
function H.GUIF(var,waitUntil)
  if GUIF_AllowRequests == nil then GUIF_AllowRequests = true end
  -- print("GUIF: GUIF_AllowRequests = "..tostring(GUIF_AllowRequests))
  
  if GUIF_AllowRequests then
    if waitUntil and type(waitUntil) == "number" then
      waitUntil = waitUntil * H.GUIF_delayMult
    else
      waitUntil = nil
    end
    --clean pending keypresses
    io.read("f")
    
    if type(var) == "table" then
      local z = var[1]
      local org = z
      if z ~= nil then
        local vType = type(z)
        local expecting = ""
        
        if vType == "string" and (strupper(z) == "TRUE" or strupper(z) == "FALSE") then
          z = (strupper(z) == "TRUE")
          org = z
          vType = "boolean"
        end

        local tellWaitLength = ""
        if waitUntil ~= nil  then
          tellWaitLength = "(waiting "..waitUntil.." sec) "
        end
        
        if vType == "number" then
          expecting = "Enter Num: "
        elseif vType == "string" then
          expecting = "Enter Str: "
          -- check it is a number as a string
          local tmp = strgsub(z,[["]],"")
          if tmp then
            if type(tonumber(tmp)) == "number" then
              --probably less confusing for the user
              expecting = "Enter Num: "
              vType = "number"
            end
          end
        elseif vType == "boolean" then
          expecting = "Enter Y/N: "
        else
          print(">>> "..H.gcWARNING.." [WARNING] GUIF: variable of unexpected type: "..vType.." "..H._zDEFAULT)
          H.SetReportData(H.DelayedReportData,"","GUIF: variable of unexpected type: "..vType,"WARNING")
          -- H.Report("","GUIF: variable of unexpected type: "..vType,"WARNING")
        end

        if os.getenv("_SOUND") == "Y" then
          beep(800,150)
        end
        
        gIOstderr:setvbuf("no")
        gIOstderr:write("\n "..H._zBLACKonYELLOW.." >>> "..H._zDEFAULT.." "..var[2]..H._zWHITEonDARKCYAN.." "..tellWaitLength..expecting..H._zDEFAULT.." ")

        local TimedOut = ""
        local ReportTimedOut = ""
        if vType == "number" then
          if KeyPressTimeOut(waitUntil) then
            local s = io.read()
            if s then
              local v = tonumber(s) -- get a real number
              if v then
                z = v
              end
            end
          else
            TimedOut = " ["..H._zUnderline..H._zYELLOW.."TIMED OUT"..H._zDEFAULT.."]"
            ReportTimedOut = " [TIMED OUT]"
          end
        elseif vType == "string" then
          if KeyPressTimeOut(waitUntil) then
            local s = io.read()
            if s then
              local v = tostring(s) -- get a real string
              if v and v ~= "" then
                z = v
              end
            end
          else
            TimedOut = " ["..H._zUnderline..H._zYELLOW.."TIMED OUT"..H._zDEFAULT.."]"
            ReportTimedOut = " [TIMED OUT]"
          end
        elseif vType == "boolean" then
          if KeyPressTimeOut(waitUntil) then
            local s = H.trim(strupper(io.read()))
            if s then
              if s == "Y" then
                z = true
              elseif s == "N" then
                z = false
              end
            end
          else
            TimedOut = " ["..H._zUnderline..H._zYELLOW.."TIMED OUT"..H._zDEFAULT.."]"
            ReportTimedOut = " [TIMED OUT]"
          end
        end

        local ending = ""
        if tostring(z) == tostring(org) then
          ending = " (default)"
        end
        if vType == "boolean" then
          local ztmp = "N"
          if z then
            ztmp = "Y"
          end
          H.SetReportData(H.DelayedReportData,"","    'Prompt'"..ReportTimedOut.." [["..var[2].."]]: ["..ztmp.."]"..ending)
          -- H.Report("","    'Prompt'"..ReportTimedOut.." ["..var[2].."]: ["..ztmp.."]"..ending)
          print("===>> User input:"..TimedOut.." ["..ztmp.."]"..ending)
        else
          H.SetReportData(H.DelayedReportData,"","    'Prompt'"..ReportTimedOut.." [["..var[2].."]]: ["..tostring(z).."]"..ending)
          -- H.Report("","    'Prompt'"..ReportTimedOut.." ["..var[2].."]: ["..tostring(z).."]"..ending)
          print("===>> User input:"..TimedOut.." ["..tostring(z).."]"..ending)
        end
        
        -- if IsTimedOut then
          -- print(">>> H.GUIF() "..H._zBRIGHTGREEN.."TIMED OUT"..H._zDEFAULT)
          -- H.Report("","H.GUIF() TIMED OUT","")
        -- end
        print("")
        -- var[1] = z
  -- print("z = "..tostring(z).." "..type(z))
        return z
      else
        print(">>> "..H.gcWARNING.." [WARNING] GUIF: Variable is NIL "..H._zDEFAULT)
        H.SetReportData(H.DelayedReportData,"","GUIF: Variable is NIL","WARNING")
        -- H.Report("","GUIF: Variable is NIL","WARNING")
      end
    else
      print(">>> "..H.gcWARNING.." [WARNING] GUIF: Variable is not a 'table' "..H._zDEFAULT)
      H.SetReportData(H.DelayedReportData,"","GUIF: Variable is not a 'table'","WARNING")
      -- H.Report("","GUIF: Variable is not a 'table'","WARNING")
    end
  else
    return var[1]
  end
end

--***************************************************************************************************
-- GNH() is short for GetNameHash()
-- this is based on: https://en.wikipedia.org/wiki/Jenkins_hash_function
-- name: string
-- return: hash as string
function H.GNH(name)
  if name then
    local c = {string.byte(name:upper(), 1, #name)}
    local hash = 0
    for i = 1, #c do
      -- print(c[i],string.char(c[i]))
      hash = (hash + c[i]) & 0xffffffff
      hash = (hash + (hash << 10)) & 0xffffffff
      hash = (hash ~ (hash >> 6))   -- & 0xffffffff
    end
    hash = (hash + (hash << 3)) & 0xffffffff
    hash = (hash ~ (hash >> 11))    -- & 0xffffffff
    return tostring( (hash + (hash << 15)) & 0xffffffff )
  else
    return ""
  end
end

--***************************************************************************************************
-- reverseGNH()
-- may not be possible in all cases, NOT DEBUGGED
function reverseGNH(hash)
  local name = hash * 0x3FFF8001 -- inverse of hash += hash << 15;
  name = name ^ ((name >> 11) ^ (name >> 22))
  name = name * 0x38E38E39  -- inverse of hash += hash << 3;
  local i = #hash -- length;
  while i > 0 do
    name = name ^ ((name >> 6) ^ (name >> 12) ^ (name >> 18) ^ (name >> 24) ^ (name >> 30))
    name = name * 0xC00FFC01 -- // inverse of hash += hash << 10;
    name = name - key[i-1]  -- key[--i];
  end
  return name
end

--***************************************************************************************************
-- ??? return varname of field
-- NOT USED
function getField(field)
  local t = _ENV -- start with the table of globals
  local v = nil
  for w, d in string.gmatch(field, "([%w_]+)(.?)") do
    print(tostring(w),tostring(d))
    if d == "." then -- not last field?
      t[w] = t[w] or {} -- create table if absent
      t = t[w] -- get the table
    else -- last field
      v = t[w] -- do the assignment
    end
  end
  return v
end

--***************************************************************************************************
function H.IsDirExist(path)
  local result = false
  path = strgsub(path,[[/]],[[\]])
  if strsub(path,#path-1) == [[\]] then
    --removing last \
    path = strsub(path,1,-2)
  end
  -- print(">>> "..path)
  if lfs.attributes(path,'mode') == "directory" then
    result = true
  end
  return result  
end

--***************************************************************************************************
function H.IsFile2Newest(file1,file2)
  os.remove("NewerFile.txt")
  
  if not H.IsFileExist(file1) then
    -- H.printf("Missing %s",file1)
    return false
  end
  
  if not H.IsFileExist(file2) then
    -- H.printf("Missing %s",file2)
    return false
  end
  
  -- while H.IsFileExist("NewerFile.txt") do
    -- print("Waiting for NewerFile.txt to be deleted")
    -- H.WFAK("In H.IsFile2Newest")
    -- H.sleep(1)
  -- end
  
  -- H.pv("IsFile2Newest: ["..file1.."]")
  -- H.pv("IsFile2Newest: ["..file2.."]")
  
  -- local cmd = [[xcopy.exe /DYLR "]]..file1..[[" "]]..file2..[[*" | findstr /BC:"0" >nul && echo|set /p="]]..file2..[[ is newer">"NewerFile.txt"]]
  -- with                                                 *  the result can be wrong when the extension is .py   
  local cmd = [[xcopy.exe /DYLR "]]..file1..[[" "]]..file2..[[" | findstr /BC:"0" >nul && echo|set /p="]]..file2..[[ is newer">"NewerFile.txt"]]
  os.execute(cmd)

  local File2IsNewest = H.IsFileExist("NewerFile.txt")
  -- H.WFAK("Check NewerFile.txt")
  os.remove("NewerFile.txt")
  return File2IsNewest
end
--***************************************************************************************************

--Wbertro: it is slow????
function H.GetFileSize(pathname)
  -- local filehandle = assert(io.open(pathname,"r"),"io.open: Cannot open file to get file size: "..pathname)
  local filehandle = io.open(pathname,"r")
  local size = filehandle:seek("end")    -- get file size
  filehandle:close()
  return size
end

--***************************************************************************************************
function H.GetFileCreationDate(pathname)
  local filehandle = io.popen( "dir "..pathname.." /T:W", "r" )
  local LineTable = {}
  -- local line = assert(filehandle:read("l"),"read: cannot read line from file: "..pathname)
  local line = filehandle:read("l")
  while line do
    -- print(line,pathname)
    if tonumber(strsub(line,1,1)) then
      LineTable[#LineTable+1] = line
    end
    line = filehandle:read("l")
  end

  filehandle:close()
  return LineTable
end

--***************************************************************************************************
function H.GetFileCreationByDate(dirPath)
  local IsFileExist = false  
  if lfs.attributes(dirPath, "mode") == "directory" then
    for file in lfs.dir(dirPath) do
      if file ~= "." and file ~= ".." then
        if lfs.attributes(dirPath..'/'..file, 'mode') == 'file' then
          IsFileExist = true
          break
        end
      end
    end
  end
  local LineTable = {}
  if IsFileExist then
    -- otherwise, this command sends "File not found" to the console
    local filehandle = io.popen( [[dir "]]..dirPath..[[" /O:-D /T:W /A:-D /B]], "r")
    local line = filehandle:read("l")
    while line do
      LineTable[#LineTable+1] = line
      line = filehandle:read("l")
    end

    filehandle:close()
  end
  return LineTable
end

local _TABtoSPACES = os.getenv("-TABtoSPACES")
if _TABtoSPACES == nil then
  _TABtoSPACES = 2 -- default
end
H.TtoS = strrep(" ",tonumber(_TABtoSPACES))

--***************************************************************************************************
-- s = the string to convert
-- return a string with all TAB converted to SPACES
function H.TABtoSPACES(s)
  return strgsub(s,"\t",H.TtoS)
end

--***************************************************************************************************
-- NOT EASY TO ONLY TARGET SPACES AT THE START OF LINES IN A STRING OF LINES
-- s = the string to convert
-- return a string with the left most SPACES converted to TAB
function H.SPACEStoTAB(s)
  -- match zero or more repetitions of 2 spaces from the start of the line
  return s:gsub("%f[^\n]() +()", function(i, j) return ("\t"):rep((j-i)//#H.TtoS) end)
end

--***************************************************************************************************
-- create, write and close
-- does NOT create the folders
function H.WriteToFile(output,pathname,binary)
  local out = output
  if binary ~= "b" then
    if type(output) == "table" then
        out = H.ConvertLineTableToText(output)
    end    
    if strfind(pathname,".MXML",1,true) then
      -- change left SPACES to TAB
      out = H.SPACEStoTAB(out)
    end
  end
  
  -- Invalid argument	22: means the pathname is malformed
  local filehandle = nil
  -- print("["..pathname.."]")
  if binary == "b" then
    -- print(io.open(pathname,"wb")) --wbertro: for debug
    -- filehandle = assert(io.open(pathname,"wb"),"io.open: Cannot open binary file to write: "..pathname) -- +
    filehandle = io.open(pathname,"wb")
  else
    -- print(io.open(pathname,"w")) --wbertro: for debug
    -- filehandle = assert(io.open(pathname,"w"),"io.open: Cannot open file to write: "..pathname) -- +
    filehandle = io.open(pathname,"w")
  end
  if filehandle then
    filehandle:write(out)
    filehandle:flush()
    filehandle:close()
  end
end

--***************************************************************************************************
-- create, write and close
-- does NOT create the folders
function H.WriteToFileDictionary(output,pathname)
  local out = output
  if type(output) == "table" then
    local tableType = H.GetTableType(output)
    if tableType == "Array" then
      out = H.ConvertLineTableToText(output)
    elseif tableType == "Dictionary" then
      out = {}
      for k,v in pairs(output) do
        out[#out+1] = k..": "..tostring(v)
      end
      out = table.concat(out,"\n")
    end
  end
    
  if strfind(pathname,".MXML",1,true) then
    -- change left SPACES to TAB
    out = H.SPACEStoTAB(out)
  end
  
  -- Invalid argument	22: means the pathname is malformed
  local filehandle = nil
  -- print("["..pathname.."]")
  -- print(io.open(pathname,"w")) --wbertro: for debug
  -- filehandle = assert(io.open(pathname,"w"),"io.open: Cannot open file to write: "..pathname) -- +
  filehandle = io.open(pathname,"w")
  if filehandle then
    filehandle:write(out)
    filehandle:flush()
    filehandle:close()
  end
end

--***************************************************************************************************
-- NOT USED
-- create and return filehandle
function H.WriteToFileEXT(pathname,binary)
  local filehandle = nil
  -- print("["..pathname.."]")
  if binary == "b" then
    -- print(io.open(pathname,"wb")) --wbertro: for debug
    -- filehandle = assert(io.open(pathname,"wb"),"io.open: Cannot open file to write: "..pathname)
    filehandle = io.open(pathname,"wb")
  else
    -- print(io.open(pathname,"w")) --wbertro: for debug
    -- filehandle = assert(io.open(pathname,"w"),"io.open: Cannot open file to write: "..pathname)
    filehandle = io.open(pathname,"w")
  end
  return filehandle
end

--***************************************************************************************************
-- append and close
function H.WriteToFileAppend(output,pathname)
  local out = output
  if type(output) == "table" then
      out = H.ConvertLineTableToText(output)
  end    
  if strfind(pathname,".MXML",1,true) then
    -- change left SPACES to TAB
    out = H.SPACEStoTAB(out)
  end
  
  local filehandle = io.open(pathname,"a+")
  local count = 0
  
  while filehandle == nil and count < 10 do
    count = count + 1
    H.sleep(1)
    -- filehandle = assert(io.open(pathname,"a+"),"io.open: Cannot open file to append: "..pathname)
    filehandle = io.open(pathname,"a+")
  end
  
  if filehandle then
    filehandle:write(out)
    filehandle:flush()
    filehandle:close()
  end
end

--***************************************************************************************************
-- NOT USED
-- append and close
function H.WriteToFileAppendEXT(pathname,...)
  -- local filehandle = assert(io.open(pathname,"a+"),"io.open: Cannot open file to append: "..pathname)
  local filehandle = io.open(pathname,"a+")
  if filehandle then
    filehandle:write(...)
    filehandle:write("\n")
    filehandle:flush()
    filehandle:close()
  end
end

--***************************************************************************************************
-- LineTable: a table of lines
-- return: a string
function H.ConvertLineTableToText(LineTable)
	return table.concat(LineTable, "\n") --:upper() -- for debug
end

--***************************************************************************************************
-- returns: - the file content as a table of strings
--          - msg = "ERROR" on failure
--function H.ParseTextFileIntoTable(pathname,t)
function H.ParseTextFileIntoTable(pathname,IsStripTypeInfo)
  -- print("*** H.ParseTextFileIntoTable([["..pathname.."]])")
  -- print("*** current folder = ["..lfs.currentdir().."]")
  
  local msg = ""
  local LineTable = {}
-- H.printf("H.IsFileExist(%s) = %s",pathname,tostring(H.IsFileExist(pathname)))
  if H.IsFileExist(pathname) then
    local filehandle = assert(io.open(pathname,"r"),"io.open: Cannot open file to parse: "..pathname)
    -- local filehandle = io.open(pathname,"r")
    if filehandle then
      local lines = filehandle:read("a")
      if strfind(pathname,".MXML$",1,true) or strfind(pathname,".EXML$",1,true) then
        lines = H.TABtoSPACES(lines)
      end
      
      if IsStripTypeInfo then
        if strfind(lines,[[ array_size=]],1,true) then
          -- this original MXML has array_size info
          -- if not H.MXMLwithArray_sizeInfo[pathname] then
            H.MXMLwithArray_sizeInfo[pathname] = true
            -- print("         >>>>> Array Information is available")
          -- end
          -- print("==>>>>>>>>>>  Stripping type information")
          lines = strgsub(lines,[[ array_size=".-"]],"")
        end
      end
      
      -- end-of-line encodings: Unix = \n, WINDOWS = \r\n, MAC = \r
      if strfind(lines,"\r\n") then
        LineTable = lines:splitB("\r\n")
      elseif strfind(lines,"\r") then
        LineTable = lines:splitB("\r")
      else
        -- all "\n" and other files
        LineTable = lines:splitB("\n")
      end
      
      filehandle:close()
    else
      msg = "ERROR H.ParseTextFileIntoTable(): ["..lfs.currentdir().."] - ["..pathname.."]" --DO NOT CHANGE
    end
  else
      msg = "ERROR H.ParseTextFileIntoTable(): ["..lfs.currentdir().."] - ["..pathname.."]" --DO NOT CHANGE
  end
  return LineTable,msg
end
--***************************************************************************************************

--***************************************************************************************************
-- NOT USED, NOT COMPLETED
-- t = a table of an EXML section
-- returns: FAST table
function H.ConvertSectionToFastTable(t)
  local ft = {}
  for i=1,#t do
    local s = t[i]
    if string.sub(ltrim(s),1,2) ~= "--" then
      -- returns: in ORIGINAL CASE
      --   p, v as 'Property name=', 'value='
      --   p, nil as 'Property name=', nil
      --   nil, v as nil, 'Property value='
      --   nil, nil if not found
      local p,v = H.GetPropertyNameValue(s)
      if string.find(s,"/>",1,true) then
        -- like:   <Property name="TextTouchScrollCap" value="0.1" />
      elseif string.find(s,[[">]],1,true) then
        -- like:   <Property name="TouchButtonChargeIndicatorColour" value="Colour"> -- .xml
      end
    end
  end
  return ft
end

--***************************************************************************************************
-- NOT USED, NOT COMPLETED
-- ft = a FAST table of an EXML section
-- returns: a table as an EXML section
function H.ConvertFastTableToSection(ft)
  local t = {}
  return t
end

--****************************************************************
-- t = any var type
-- returns: - type of table: "Array" or "Dictionary"
--   or "notTable" if NOT a table
--   or "Empty" if empty table
function H.GetTableType(t)
  if type(t) == "table" then
    if next(t) == nil then
      return "Empty"
    end

    local isArray = true
    local isDictionary = true
    for k, _ in next, t do
      if type(k) == "number" and k%1 == 0 and k > 0 then
        isDictionary = false
      else
        isArray = false
      end
      if not isDictionary and not isArray then
        break
      end
    end
    if isArray then
      return "Array"
    elseif isDictionary then
      return "Dictionary"
    else
      return "Mixed"
    end
  end
  return "notTable"
end

--****************************************************************
-- t = any var type
-- returns true if Invalid
function H.ReportInvalidTableContent(t,tName)
  if H.GetTableType(t) ~= "Array" then
    print(">>> "..H.gcWARNING.." [WARNING] Unexpected content in table "..tName.." or empty.  Please correct your script! "..H._zDEFAULT)
    H.Report("","Unexpected content in table "..tName.." or empty.  Please correct your script!","WARNING")
    return true
  end
  return false
end

--****************************************************************
function H.DisplayScriptStructure(t,level) -- recursive on a sub-table
  local dot = string.char(0x3E) -- 0x16, 0xAF
  if type(t) == "table" then
    local Type = H.GetTableType(t)
    if Type == "Array" then
      for k,v in ipairs(t) do
        if type(v) == "table" then
          H.printf("                     %s+ #%s",string.rep("-  ",level),k)
          level = level + 1
          H.DisplayScriptStructure(v,level) -- recursive on a sub-table
          level = level - 1
        elseif type(v) == "string" then
          local line = string.match(v,"^(.-)%c")
          if line then
            line = line:gsub([[\\]],[[\]]).." ..."
          else
            line = v:gsub([[\\]],[[\]])
          end
          H.printf("                     %s%s %s = [[%s]]",string.rep("-  ",level),dot,k,string.sub(line,1,100))
        else
          H.printf("                     %s+ %s = <%s>",string.rep("-  ",level),k,tostring(v))
        end
      end
    elseif Type == "Dictionary" then
      for k,v in pairs(t) do
        if type(v) == "table" then
          H.printf("                     %s+ %s",string.rep("-  ",level),k)
          level = level + 1
          H.DisplayScriptStructure(v,level) -- recursive on a sub-table
          level = level - 1
        elseif type(v) == "string" then
          local line = string.match(v,"^(.-)%c")
          if line then
            line = line:gsub([[\\]],[[\]]).." ..."
          else
            line = v:gsub([[\\]],[[\]])
          end
          H.printf("                     %s+ %s = [[%s]]",string.rep("-  ",level),k,string.sub(line,1,100))
        else
          H.printf("                     %s+ %s = <%s>",string.rep("-  ",level),k,tostring(v))
        end
      end
    else
      H.printf("==> Table is of type %s",Type)
    end
    
  end

end

--****************************************************************
  --   key = t[i][1]
  -- value = t[i][2]
  -- return a new FAST table from table t
function H.fastTable(t)
  local ft = {}
  for i=1,#t do
    ft[t[i][1]] = t[i][2]
  end
  return ft
end

--****************************************************************
  --   keys are 1,2,3,...
  -- value = t[i]
  -- return a new FAST table from table t
function H.ipairsFastTable(t)
  local ft = {}
  for k,v in ipairs(t) do
    ft[v] = k
  end
  return ft
end

--***************************************************************************************************
function H.getPath(str)
  -- return str:gsub('\\','/'):match('.*/')
  return string.match(strgsub(str,[[/]],[[\]]),[[.*\]])
end

--***************************************************************************************************
--changes all \\ to \
--changes all / to \
function H.NormalizePath(pathname,IsStripExtension,IsUpper)
  local _IsUpper = true
  if IsUpper ~= nil then
    _IsUpper = IsUpper
  end
  if pathname == nil then return pathname end
  if IsStripExtension then
    local ext = H.GetExtensionFromFilePath(pathname)
    if ext then
      pathname = strgsub(pathname,ext,"")
    end
  end
  repeat
    pathname = strgsub(pathname,[[/]],[[\]])
    pathname = strgsub(pathname,[[\\]],[[\]])
  until not strfind(pathname,[[/]],1,true) and not strfind(pathname,[[\\]],1,true)
  if _IsUpper then
    return pathname:upper()
  else
    return pathname
  end
end

--***************************************************************************************************
--used by H.NormalizePathExt()
local WholeDirFile = ""

-- NOT USED, also maybe BUGGY
function H.NormalizePathExt(path)
  if path == nil then return path end
  path = strgsub(path,[[/]],[[\]])
  path = strgsub(path,[[\\]],[[\]])
  
  local _,NumberOfBackslash = strgsub(path,[[\]],[[\]],-1)
  if NumberOfBackslash > 0 then
    return strupper(path) --standard use of \,\\ or /
  end

  --there was no \ found, so no path or dots are part of the path
  local _,NumberOfDots = strgsub(path,[[.]],[[.]],-1)
  if NumberOfDots == 0 then
    --bad path
    return path
  else --some dots exist in the path
    --check if tempPath is valid
    local found = false
    if WholeDirFile == "" then
      WholeDirFile = H.LoadFileData("pak_UniqueDir.txt") --for speed searching
    end
    local WDF = WholeDirFile
    for i=1,NumberOfDots do
      local tempPathExt = strgsub(path,[[.]],[[\]],NumberOfDots - i)
      -- local tempPath = strsub(tempPathExt,1,)
      -- local tempExt = ""
                        --                                                        **** recheck NormalizePath usage
      --search for it 
      local firstPosStart,firstPosEnd = strfind(WDF,tempPath.."]",1,true)
      if firstPosEnd then
        found = true
        break
      end
    end
    if found then
      return tempPath..tempExt
    else
      --no path or bad path
      return path
    end
  end
end

--***************************************************************************************************
function H.GetFilenameFromFilePath(pathname,IsUpper)
  local pname = H.NormalizePath(pathname,nil,IsUpper) or pathname
  local tmp = string.match(pname,[[^.+\(.+)$]])
  if tmp then
    return tmp
  end
  return pathname
end

--***************************************************************************************************
function H.GetExtensionFromFilePath(pathname)
  -- local pathname = H.NormalizePath(pathname)
  local filename = H.GetFilenameFromFilePath(pathname)
-- H.printf("FFF filename = %s [%s]",filename,pathname)
  return filename:match([[^.+(%..+)$]])
end

--***************************************************************************************************
function H.GetFolderPathFromFilePath(pathname)
	if pathname then
    pathname = strgsub(pathname,[[/]],[[\]])
    local _,count = strgsub(pathname,[[\]],"",-1)
    if count == 0 then
      return ""
    elseif count == 1 then
      return strsub(pathname,1,strfind(pathname,[[\]]) - 1)
    end
    local temp1 = strgsub(pathname,[[\]],"X_TEMP_X",count-1)
    local temp2 = strsub(temp1,1,strfind(temp1,[[\]])-1)
    return strgsub(temp2,"X_TEMP_X",[[\]])
  else
    return pathname
  end
end

--***************************************************************************************************
-- default param:
--  /y no prompt when overwriting
--  /h all types of file
--  -- /v verify
--  /i assume dest is a folder if dest does not exist
--  /j use unbuffered I/O
--  /r overwrite read-only files
--
-- missing: /s Copy folders and subfolders
--
-- if silent == false then xcopy output is sent to xcopy_output.txt
-- WILL NOT RENAME A FILE
function H.CopyFile(src,dest,param,IsSilent)
  local IsNotSilent = false
  local xcopy_output = "xcopy_output.txt"
  if IsSilent == nil or IsSilent then
    silent = [[ 1>NUL 2>NUL]]
  else
    IsNotSilent = true
    H.DeleteFile(xcopy_output)
    silent = " >"..xcopy_output
  end
  if param == nil then param = "/y /h /i /j /r /EXCLUDE:xcopy_exclude_vscode.txt" end
  local cmd = [[xcopy.exe ]]..param..[[ "]]..src..[[" "]]..dest..[["]]..silent
  local success,sResult,nResult = os.execute(cmd)
  if IsNotSilent then
    local data = H.LoadFileData(xcopy_output)
    if tonumber(strsub(data,1,strfind(data," File(s) copied",1,true))) == 0 then
      success = nil
      sResult = "0 File(s) copied"
    end
  end
  return success,sResult,nResult
end

--***************************************************************************************************
-- if silent == false then xcopy output is sent to Robocopy_output.txt
function H.RobocopyDir(src,dest,param,IsSilent)
  local IsNotSilent = false
  local Robocopy_output = "Robocopy_output.txt"
  if IsSilent == nil or IsSilent then
    silent = [[ 1>NUL 2>NUL]]
  else
    IsNotSilent = true
    H.DeleteFile(Robocopy_output)
    silent = " >"..Robocopy_output
  end
  if param == nil then param = "/S /V /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12" end
  -- local cmd = [[robocopy ]]..FilePathSource..[[\. ]]..FilePathSource..[[\. *.* /S /V /L /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12]]
  local cmd = [[Robocopy.exe "]]..src..[[" "]]..dest..[[" ]]..param..silent
  local success,sResult,nResult = os.execute(cmd)
  if IsNotSilent then
    local data = H.LoadFileData(Robocopy_output)
    if tonumber(strsub(data,1,strfind(data," File(s) copied",1,true))) == 0 then
      success = nil
      sResult = "0 File(s) copied"
    end
  end
  return success,sResult,nResult  
end

--***************************************************************************************************
-- if silent == false then xcopy output is sent to Robocopy_output.txt
-- NOT USED
function H.RobocopyFile(src,dest,file,param,IsSilent)
  local IsNotSilent = false
  local Robocopy_output = "Robocopy_output.txt"
  if IsSilent == nil or IsSilent then
    silent = [[ 1>NUL 2>NUL]]
  else
    IsNotSilent = true
    H.DeleteFile(Robocopy_output)
    silent = " >"..Robocopy_output
  end
  if param == nil then param = "/S /V /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12" end
  -- local cmd = [[robocopy ]]..FilePathSource..[[\. ]]..FilePathSource..[[\. *.* /S /V /L /R:1 /NS /NDL /NP /NC /NJS /NJH /MT:12]]
  local cmd = [[Robocopy.exe "]]..src..[[" "]]..dest..[[" ]]..param..silent
  local success,sResult,nResult = os.execute(cmd)
  if IsNotSilent then
    local data = H.LoadFileData(Robocopy_output)
    if tonumber(strsub(data,1,strfind(data," File(s) copied",1,true))) == 0 then
      success = nil
      sResult = "0 File(s) copied"
    end
  end
  return success,sResult,nResult  
end

--***************************************************************************************************
function H.DeleteFile(pathname,IsDeleteInSub,IsSilent)
  --os.remove(OLDfilepathname)    --don't use, can get stuck
  if IsDeleteInSub == nil then
    IsDeleteInSub = true
  end
  
  if IsSilent == nil or IsSilent then
    silent = [[ 1>NUL 2>NUL]]
  else
    silent = ""
  end

  local options = " /f /q "
  if IsDeleteInSub then
    options = options.."/s "
  end
  -- /B /wait "" /MIN: order is important for it to work on win7 and early win10 version
  os.execute([[START /B /wait "" /MIN cmd /c Del]]..options..[["]]..pathname..[["]]..silent)    
end

--***************************************************************************************************
function H.MoveFileDirectory(src,dest)
  local success,errmsg = os.rename(src,dest)
  if success then
    -- if os.remove(src) == nil then
      -- print("Could not remove source file "..src)
    -- end
  else
    print("Could not move/rename file "..src.." to "..dest.." ("..errmsg..")")
  end
  return success,errmsg
end

--***************************************************************************************************
-- NOT USED
function RenameMBINs(IsMBINtoXMBIN)
  -- now rename all .MBIN to .XMBIN
  --   so that they are not deleted by GetFreshSources()
  local MBIN_list = H.ListDir(MBIN_list,[[MOD\]],false,true) -- MOD\ makes it easier to remove later on
  
  local IsFound = false
  for i=1,#MBIN_list do
    local tmp = MBIN_list[i]
    if IsMBINtoXMBIN then
      if string.find(tmp,[[.MBIN]],1,true) then
        IsFound = true
        H.MoveFileDirectory(tmp,string.gsub(tmp,[[.MBIN]],[[.XMBIN]]))
      end
    else
      if string.find(tmp,[[.XMBIN]],1,true) then
        IsFound = true
        H.MoveFileDirectory(tmp,string.gsub(tmp,[[.XMBIN]],[[.MBIN]]))
      end
    end
  end
  
  if IsFound then
    if IsMBINtoXMBIN then
      print(H._zBRIGHTORANGE.."   Renaming .MBIN to .XMBIN"..H._zDEFAULT)
    else
      print(H._zBRIGHTORANGE.."     Renaming .XMBIN to .MBIN"..H._zDEFAULT)
    end
  end  
end

--***************************************************************************************************
function H.mkdir(path)
  local sep = strsub(package.config,1,1)
  local pStr = ""
  for dir in string.gmatch(path,"[^" .. sep .. "]+") do
    pStr = pStr .. dir .. sep
    lfs.mkdir(pStr)
  end
end

--***************************************************************************************************
function H.DeleteDir(dir) --recursive
  for file in lfs.dir(dir) do
    local file_path = dir..'/'..file
    if file ~= "." and file ~= ".." then
      if lfs.attributes(file_path, 'mode') == 'file' then
        --print('remove file',file_path)
        os.remove(file_path)
      elseif lfs.attributes(file_path, 'mode') == 'directory' then
        --print('dir', file_path)
        H.DeleteDir(file_path) --recursive
      end
    end
  end
  --print('remove dir',dir)
  lfs.rmdir(dir)
end

--***************************************************************************************************
--path: string, where to look
--IsStripPath: bool, true to remove the path from the files
--returns: table of main folders in path
function H.GetMainDirList(path,IsStripPath)
  if IsStripPath == nil then IsStripPath = false end
  local list = {}
  for file in lfs.dir(path) do
    -- H.printf(" - [%s]",file)
    if file ~= "." and file ~= ".." then
      local f = path..[[\]]..file
      local attr,msg = lfs.attributes(f)
      
      if attr then
        if attr.mode == "directory" then
          if IsStripPath then
            list[#list+1] = file
          else
            list[#list+1] = f
          end
        end
      end
    end
  end
  return list
end

--***************************************************************************************************
--generic function
--DirList: a table where the found filenames are saved
--path: string, where to look
--IsStripPath: bool, true to remove the path from the files
--IsSubDir: bool, true to go recurse into sub-directories
--IsPathLengthOK: bool, true if all path length are ok
--
--return DirList, a table with all files in path
--return IsPathLengthOK
function H.ListDir(DirList, path, IsStripPath, IsSubDir, IsPathLengthOK) -- recursive
  if DirList == nil then DirList = {} end
  if IsPathLengthOK == nil then IsPathLengthOK = true end
  
  --unremarked if we want to abort early
  -- if not IsPathLengthOK then
    -- return DirList,IsPathLengthOK
  -- end
  
  if IsStripPath == nil then IsStripPath = false end
  if IsSubDir == nil then IsSubDir = false end
  
  if IsSubDir then IsStripPath = false end
  
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." and file ~= "EXPORTED" and strmatch(file,H.AMUMSSstring) == nil then
      local f = path..[[\]]..file
      local attr,msg = lfs.attributes(f)
      
      if attr then      
        -- assert(type(attr) == "table")

        if attr.mode == "file" and not strfind(file,".lnk",1,true) then
          if IsStripPath then
            DirList[#DirList+1] = file
          else
            DirList[#DirList+1] = f
          end
        end
        
        if IsSubDir and attr.mode == "directory" then
          DirList,IsPathLengthOK = H.ListDir(DirList,f,IsStripPath,IsSubDir,IsPathLengthOK) -- recursive
        else
          --nothing for now
        end
      else
        -- print("attrIsNIL ("..#f..") ["..msg.."]")
        IsPathLengthOK = false
      end
    end
  end

-- for i=1,#DirList do
  -- printf("DirList = %s",DirList[i])
-- end          
  return DirList,IsPathLengthOK
end

--***************************************************************************************************
-- ==== INTERNAL ====
--get a sub-list of files matching extension (.ext) from DirList table
local function GetDirList(ModScriptValidContent,extension,IsModScriptfolderOnly)
  if IsModScriptfolderOnly == nil then IsModScriptfolderOnly = false end
  -- print("- ModScriptValidContent total entries = "..#ModScriptValidContent)
  -- print("                 @@@        extension = ["..extension.."]")

  local EXT = strupper(extension)
  if strsub(EXT,1,1) ~= "." then
    EXT = "."..EXT
  end
  
  local cutPoint = #H.gMASTER_FOLDER_PATH

  -- now only keep valid files with EXT, ModScript included -- and remove fullpath
  local tempList = {}
  -- local cutPoint = #(H.gMASTER_FOLDER_PATH..[[ModScript\]])
  -- print()
  -- print(#H.gMASTER_FOLDER_PATH)
  -- print(#(strgsub(lfs.currentdir(),[[MODBUILDER]],""))
  -- print("cutPoint = ["..cutPoint.."]")
-- print("--->")
-- for j=1,#ModScriptValidContent do
  -- H.printf("---> [%s]",ModScriptValidContent[j][1])
-- end
  for i=1,#ModScriptValidContent do
    -- if strupper(strsub(ModScriptValidContent[i][1],-1 * #EXT)) == EXT then
    
    -- Note: it is allowed to have .author (or any other extension like .txt) AFTER the .lua
    
    if IsModScriptfolderOnly then
      -- for .MXML, .MBIN, .MBIN.PC and .pak (with .author) (no sub-folders) but not .xyz0 for example
      if strfind(strupper(ModScriptValidContent[i][1]),EXT..".",1,true) or strsub(strupper(ModScriptValidContent[i][1]),-#EXT) == EXT then
        local thisPath = H.GetRelPathToScript(ModScriptValidContent[i][1])
        -- print("thisPath = ["..thisPath.."] for "..EXT)
        
        local shortPath = strsub(H.trim(thisPath),cutPoint + 1)
        -- print("    shortPath = ["..shortPath.."]")
        
        local _,n = strgsub(shortPath,[[\]],"",-1)
        if n == 1 then
          -- this file is directly in ModScript folder
          -- H.printf("  - %s",ModScriptValidContent[i][1])
          tempList[#tempList+1] = ModScriptValidContent[i]
        end
      end

    else
      -- for .lua in Modscript and sub-folders
      -- ALLOW for the use of .AUTHOR after the .pak
--       -- if strfind(strupper(ModScriptValidContent[i][1]),EXT,1,true) then
      -- finds .lua, .lua.xyz but not .lua0 for example
      if strfind(strupper(ModScriptValidContent[i][1]),EXT..".",1,true) or strsub(strupper(ModScriptValidContent[i][1]),-#EXT) == EXT then
        -- print(" * ModScriptValidContent[i][1] =["..ModScriptValidContent[i][1].."]")
        -- print("     ModScriptValidContent[i][2] =["..ModScriptValidContent[i][2].."]")
        -- print("     ModScriptValidContent[i][3] =["..tostring(ModScriptValidContent[i][3]).."]")
        -- if ModScriptValidContent[i][2] == "" and not ModScriptValidContent[i][3] then
          -- -- not 'too deep' and not 'too long path'

        local thisPath = H.GetRelPathToScript(ModScriptValidContent[i][1])
        -- print("thisPath = ["..thisPath.."] for "..EXT)
        
        local shortPath = strsub(H.trim(thisPath),cutPoint + 1)
        -- print("    shortPath = ["..shortPath.."]") -- ex.: shortPath = [ModScript\3DeepTest\3Deep\_MOD_DUD_AtmosphereBurnFX\]
        
        local _,n = strgsub(shortPath,[[\]],"",-1)
        if n < 5 then -- sub-folder depth
           tempList[#tempList+1] = ModScriptValidContent[i]
        end
      end
    end
  end
-- print("-->")
-- for j=1,#tempList do
  -- H.printf("--> [%s]",tempList[j][1])
-- end
  return tempList
end

--***************************************************************************************************
-- returns: a table of folder/files names
function H.GetList(cmd,IsRaw)
  local robocopyResult = os.capture(cmd,IsRaw)
  if #robocopyResult == 0 then return "" end
  
  -- end-of-line encoding: DOS = \r\n, MAC = \r, Unix = \n
  local eofString
  if strfind(robocopyResult,"\r\n") then
    eofString = "\r\n"
  elseif strfind(robocopyResult,"\r") then
    eofString = "\r"
  -- elseif strfind(robocopyResult,"\n") then
    -- eofString = "\n"
  else
    eofString = "\n"
  end

  -- remove those nul characters and make one entry per line
  robocopyResult = strgsub(robocopyResult,"\0","")
  local Drive = strsub(lfs.currentdir(),1,2)
  robocopyResult = strgsub(robocopyResult,Drive,eofString..Drive)
  robocopyResult = string.gsub(robocopyResult,"%s*"..eofString,eofString)
  robocopyResult = string.gsub(robocopyResult,eofString..eofString,eofString)
  
  return robocopyResult:splitB(eofString)
end  

--***************************************************************************************************
-- called when #H.gModScriptValidContent == 0, to initialize it
-- H.gModScriptValidContent[i][1]: filename and path
-- H.gModScriptValidContent[i][2]: path string -- folderTooDeep or ""
-- H.gModScriptValidContent[i][3]: bool -- pathTooLong
-- H.gModScriptValidContent[i][4]: string -- auto-combine
-- return: H.gModScriptValidContent
function H.GetModScriptValidContent(pathToModScript,IsVerbose)
  local p = function(...) return end --to disable
  -- p = print --active
  local IsDEV = false
  
  local maxFolderDepthAllowed = 3
  
  --All files in ModScript and sub-directories
  p()
  p("         @@@       currentdir = ["..lfs.currentdir().."]")  
  p("         @@@  pathToModScript = ["..pathToModScript.."]")

  --***************************************************************************************************
  -- table DirList = a list of paths and filenames
  -- normally disableThisSubFolderName = "___DONOTUSE.txt"
  local function CleanModScriptDirList(DirList,pathToModScript,DONOTUSE_name,COMBINE_name)
    local p = function(...) return end --to disable
    local LDebug = false
    if LDebug then p = print end --active
    
    local ScriptList = {}
    local ScriptTypeList = {}
    local MEFTI_list = {}
    local CombineFlagList = {}
    
    local IsModScriptDONOTUSE = false
    
    if IsDEV then print("================================") end
    if IsDEV then print(" A:- DirList total entries in ModScript folder = "..#DirList) end
    
    -- DirList contains all files in ModScript
    if #DirList > 0 then
      -- blank folders where DONOTUSE_name exist, except for ModScript folder itself
      for i=1,#DirList do
        local d = H.trim(DirList[i])
        if d ~= "" and strfind(d,DONOTUSE_name,1,true) then
          local DNU_folder = strgsub(d,DONOTUSE_name,"")
          -- print("DNU_folder = ["..DNU_folder.."]")
          -- print("H.gMASTER_FOLDER_PATH = ["..H.gMASTER_FOLDER_PATH.."]")
          if H.gMASTER_FOLDER_PATH..[[ModScript\]] == DNU_folder then
            -- skip, this folder IS ModScript AND the DONOTUSE flag is set
            -- print("SKIPPING ModScript folder")
            IsModScriptDONOTUSE = true
          else
            for j=1,#DirList do
              if strfind(DirList[j],DNU_folder,1,true) then
                DirList[j] = ""
              end
            end
          end
        end
      end
      -- DirList contains all 'IN_USE' files and ModScript files
      
      if IsModScriptDONOTUSE then
        -- we need to purge ALL ModScript files
        for i=1,#DirList do
          local d = strupper(H.GetRelPathToScript(DirList[i]))
          local _,count = strgsub(d,[[MODSCRIPT\]],[[MODSCRIPT\]],-1)
          if strsub(d,-10) == [[MODSCRIPT\]] and count == 1 then
            -- H.printf("   ==> to empty: [%s]    [%s]",d,DirList[i])
            DirList[i] = ""
          end
        end
      end
      
      if IsDEV then print("     we are in ["..lfs.currentdir().."]") end

      local cutPoint = #H.gMASTER_FOLDER_PATH

      -- if IsDEV then print("================================") end
      -- remove all 'MEFTI' folders, 'ModHelperScripts'+'Disabled scripts and paks'+'GlobalMEFTI' folder content
      for i=1,#DirList do
        local d = H.trim(DirList[i])
        if d ~= "" and not strfind(d,[[\]]..H.gMEFTI_name..[[\]],1,true)
            and not strfind(d,"Disabled scripts and paks",1,true)
            and not strfind(d,"GlobalMEFTI",1,true)
            and not strfind(d,"ModHelperScripts",1,true) then
          ScriptList[#ScriptList+1] = d
        end
      end      
      -- if IsDEV then print("================================") end
-- H.GetFilenameFromFilePath(pathname)      
      --***************************************************************************************************
      local function dirListSort(a,b)
        return strupper(a) > strupper(b) -- to reverse the order to match NMS load order
      end
      --***************************************************************************************************
      table.sort(ScriptList,dirListSort)
      
-- print("---->")
-- for j=1,#ScriptList do
  -- H.printf("----> [%s]",ScriptList[j])
-- end
      DirList = ScriptList
      -- DirList and ScriptList contains all 'IN_USE' files less files in: 'MEFTI' folders, 'ModHelperScripts', 'Disabled scripts and paks' and 'GlobalMEFTI' folder
      
      if IsDEV then print("") end
      if IsDEV then print(" C:- ScriptList total entries = "..#ScriptList) end
            
      -- Script List types:
      -- N  = Normal (i.e individual in Modscript, when no COMBINE flag)
      
      -- Without COMBINE_FLAG
          -- NOTE: These could be COMBINE if user said to COMBINE
      -- Used when the scripts are in a sub-folder
      -- A  = 1st one in this sub-folder (COMBINE or NOT)
      -- M  = in the middle of the list of scripts in a sub-folder (COMBINE or NOT)
      -- Z or AZ = last in this sub-folder (only when user said to COMBINE) (AZ = 1st and last)
      
      -- With COMBINE_FLAG
          -- NOTE: in ModScript or the sub-folder, these are forced to COMBINE
      -- F  = 1st one in this sub-folder
      -- C  = in the middle of the list of scripts in a sub-folder
      -- E or FE = last of this sub-folder (FE = 1st and last)

      -- 1st pass, find sub-folders
      local previousPath = ""
      
      for i=1,#ScriptList do
        local fullPath = ScriptList[i]
        
        local thisPath = H.GetRelPathToScript(fullPath)
        
        if thisPath == previousPath then
          -- if IsDEV then print("    skip it") end

        else
          previousPath = thisPath
          
          if IsDEV then print("=====") end
          if IsDEV then print("  fullPathName    = ["..fullPath.."] on i = "..i) end
          if IsDEV then print("    thisPath full = ["..thisPath.."]") end

          local meftiPath = [[..\]]..strsub(H.trim(thisPath),cutPoint + 1)..[[MEFTI]]
          if IsDEV then print("    meftiPath     = ["..meftiPath.."]") end
          
          local IsMEFTIexist = false -- MEFTI folder in ModScript is never used
          if meftiPath ~= [[..\ModScript\MEFTI]] then
            IsMEFTIexist = H.IsDirExist(meftiPath)
          end
          if IsDEV then print("        %%% 1: IsMEFTIexist = ["..tostring(IsMEFTIexist).."]") end
          
          local ISCombineFlagExist = H.IsFileExist([[..\]]..strsub(H.trim(thisPath),cutPoint + 1)..COMBINE_name)
          if IsDEV then print("        %%% 1: ISCombineFlagExist = ["..tostring(ISCombineFlagExist).."]") end
          
          local IsFirstEncounter = false
          local IsNextEncounter = false
          
          -- doing as if no COMBINE flag exist in any sub-folder
          for j=1,#ScriptList do
            -- print("ScriptList[j] = ["..ScriptList[j].."]")
            if ScriptTypeList[j] == nil then
              local EXT = strupper(strsub(ScriptList[j],-4))
              -- this entry has not been processed yet
              
              local d = H.GetRelPathToScript(ScriptList[j])
              -- if IsDEV then print("    d full = ["..thisPath.."]") end
              
              -- print("["..strupper(strsub(d,-10)).."]")
              if not ISCombineFlagExist and strupper(strsub(d,-10)) == [[MODSCRIPT\]] and  EXT == ".LUA" then
                -- if not H.IsFileExist([[..\]]..strsub(H.trim(thisPath),cutPoint + 1)..DONOTUSE_name) then
                  -- print("DONOTUSE_name = ["..[[..\]]..strsub(H.trim(thisPath),cutPoint + 1)..DONOTUSE_name.."]")
                  -- if ISCombineFlagExist then
                    -- scriptType = "F"
                  -- else
                    ScriptTypeList[j] = "N" -- this entry is in ModScript folder, mark as Normal (i.e. individual)
                  -- end
                  MEFTI_list[j] = IsMEFTIexist
                  if IsDEV then print("            N - on i, j ["..i..", "..j.."] mark as ["..ScriptTypeList[j].."] ".."["..ScriptList[j].."] "..tostring(MEFTI_list[j])) end
                -- end
              else
                -- look for the first encounter of thisPath in full
                -- local subD = H.GetRelPathToScript(ScriptList[j])
                -- if IsDEV then print("    subD = ["..subD.."]") end
                
                -- if not IsFirstEncounter and strfind(ScriptList[j],thisPath,1,true) then
                if not IsFirstEncounter and d == thisPath and EXT == ".LUA" then
                  --we found the first script in thisPath
                  IsFirstEncounter = true
                  -- print("IsFirstEncounter = ["..tostring(IsFirstEncounter).."]")
                end

                if IsFirstEncounter then
                  -- if IsDEV then print("        IsFirstEncounter = ["..d.."]") end
                  -- if strfind(ScriptList[j],thisPath,1,true) then
                  if d == thisPath then
                    if EXT == ".LUA" then
                      -- either way, mark MEFTI flag as detected before
                      MEFTI_list[j] = IsMEFTIexist
                      if IsDEV then print("            %%% B: MEFTI_list["..j.."] = ["..tostring(MEFTI_list[j]).."]") end

                      if not IsNextEncounter then
                        IsNextEncounter = true
                        -- this is the 1st one in this sub-folder                      
                        local scriptType = "A"
                        if ISCombineFlagExist then
                          scriptType = "F"
                        end
                        
                        ScriptTypeList[j] = scriptType --mark as first of list
                        if IsDEV then print("            A/F - on i, j ["..i..", "..j.."] mark as ["..ScriptTypeList[j].."] ".."["..ScriptList[j].."] "..tostring(MEFTI_list[j])) end
                      else
                        -- this is one of the following ones (could be the last one, we will correct later)
                        local scriptType = "M"
                        if ISCombineFlagExist then
                          scriptType = "C"
                        end
                        
                        ScriptTypeList[j] = scriptType -- mark next ones as Middle
                        if IsDEV then print("            M/C - on i, j ["..i..", "..j.."] mark as ["..ScriptTypeList[j].."] ".."["..ScriptList[j].."] "..tostring(MEFTI_list[j])) end
                      end                      
                    end
                    
                  else
                    if IsDEV then print("        OUT of thisPath") end
                    -- we are no longer in thisPath, go back and mark previous script as the end of this sub-folder list
                    if H.GetRelPathToScript(ScriptList[j-1]) ~= thisPath then
                      -- preceding is not in this sub-folder
                      if ScriptTypeList[j] == "A" then
                        -- this one is also the end
                        ScriptTypeList[j] = "AZ" -- first and end of list
                        if IsDEV then print("            AZ/Z - on i, j ["..i..", "..j.."] forced to ["..ScriptTypeList[j].."] ".."["..ScriptList[j].."] "..tostring(MEFTI_list[j])) end
                      elseif ScriptTypeList[j] == "F" then
                        -- this one is also the end
                        ScriptTypeList[j] = "FE" -- first and end of list
                        if IsDEV then print("            FE/F - on i, j ["..i..", "..j.."] forced to ["..ScriptTypeList[j].."] ".."["..ScriptList[j].."] "..tostring(MEFTI_list[j])) end
                      end
                    else
                      for k=j-1,1,-1 do
                        -- test for lua script only
                        local da = H.GetRelPathToScript(ScriptList[k])
                        if da == thisPath then
                          if strupper(strsub(ScriptList[k],-4)) == ".LUA" then
                            if ScriptTypeList[k] == "A" then
                              -- special case: only one script in this sub-folder
                              -- the 1st is also the last and only one
                              ScriptTypeList[k] = "AZ" -- first and end of list
                              if IsDEV then print("            AZ/Z - on i, k ["..i..", "..k.."] corrected it to ["..ScriptTypeList[k].."] ".."["..ScriptList[k].."] "..tostring(MEFTI_list[k])) end
                            elseif ScriptTypeList[k] == "F" then
                              -- special case: only one script in this sub-folder
                              -- the 1st is also the last and only one
                              ScriptTypeList[k] = "FE" -- first and end of list
                              if IsDEV then print("            FE/F - on i, k ["..i..", "..k.."] corrected it to ["..ScriptTypeList[k].."] ".."["..ScriptList[k].."] "..tostring(MEFTI_list[k])) end
                              -- must be a "M" or a "C"
                            elseif ScriptTypeList[k] == "M" then
                              ScriptTypeList[k] = "Z" -- end auto-combine
                              if IsDEV then print("            M - on i, k ["..i..", "..k.."] corrected it to ["..ScriptTypeList[k].."] ".."["..ScriptList[k].."] "..tostring(MEFTI_list[k])) end
                            elseif ScriptTypeList[k] == "C" then
                              ScriptTypeList[k] = "E" -- end auto-combine
                              if IsDEV then print("            C - on i, k ["..i..", "..k.."] corrected it to ["..ScriptTypeList[k].."] ".."["..ScriptList[k].."] "..tostring(MEFTI_list[k])) end
                            end
                            
                            break
                          end
                        end
                      end -- for k=j-1,1,-1 do
                    end
                    
                    break
                  end --if strfind(ScriptList[j],thisPath,1,true) then
                else
                  -- if IsDEV then print("      >>> still not 1st encounter") end
                end --if IsFirstEncounter then
              end --if strupper(strsub(d,-10)) == [[MODSCRIPT\]] then
            end --if ScriptTypeList[j] == nil then
          end --for j=1,#ScriptList do
        end --if thisPath == previousPath then
      end --for j=1,#ScriptList do
      
      if IsDEV then print(" > > > > >") end
      if IsDEV then print("RAW ScriptList with info:") end
      for i=1,#ScriptList do
        if IsDEV then print(">>> "..i..": "..tostring(ScriptTypeList[i]).." "..tostring(MEFTI_list[i]).." ["..ScriptList[i].."]") end
      end      
      if IsDEV then print(" > > > > >") end

      -- here all ScriptList entries are scripts
      local tmpK = {}
      local tmpS = {}
      local tmpM = {}
      
      if IsDEV then print(" + + + + +") end
      -- H.printf("A: IsModScriptDONOTUSE = %s",tostring(IsModScriptDONOTUSE))
      for i=1,#ScriptList do
        if ScriptTypeList[i] then 
          -- if ScriptTypeList[i] ~= "N" then
            tmpK[#tmpK+1] = ScriptList[i]
            tmpS[#tmpS+1] = ScriptTypeList[i]
            tmpM[#tmpM+1] = MEFTI_list[i]
            if IsDEV then print("+++ "..i..": "..tostring(ScriptTypeList[i]).." "..tostring(MEFTI_list[i]).." ["..ScriptList[i].."]") end
          -- elseif not IsModScriptDONOTUSE then
            -- H.printf("B: IsModScriptDONOTUSE = %s",tostring(IsModScriptDONOTUSE))
            -- tmpK[#tmpK+1] = ScriptList[i]
            -- tmpS[#tmpS+1] = ScriptTypeList[i]
            -- tmpM[#tmpM+1] = MEFTI_list[i]
            -- p(i..": "..tostring(ScriptTypeList[i]).." "..tostring(MEFTI_list[i]).." ["..ScriptList[i].."]")
         -- end
        end
      end      
      if IsDEV then print(" + + + + +") end
      
      ScriptList = tmpK
      ScriptTypeList = tmpS
      MEFTI_list = tmpM
      
      -- re-check if last script entry is OK or adjust type
      if IsDEV then print("\n>>> A: test last script") end
      local k = #ScriptTypeList
      if k > 0 then
        if ScriptTypeList[k] == "A" then -- or ScriptTypeList[k] == "AZ" then
          ScriptTypeList[k] = "AZ" -- end of list
        elseif ScriptTypeList[k] == "M" then
          ScriptTypeList[k] = "Z" -- end of list
        elseif ScriptTypeList[k] == "F" then
          ScriptTypeList[k] = "FE" -- end of list
        elseif ScriptTypeList[k] == "C" then -- or ScriptTypeList[k] == "E" then
          ScriptTypeList[k] = "E" -- end of list
        -- else
          -- print(">>> "..H.gcERROR..[[ [BUG] Last ScriptTypeList type is NOT a known type, please report ]]..H._zDEFAULT)
        end
        if IsDEV then print("      Last Script is ["..ScriptTypeList[k].."] ".."["..ScriptList[k].."] "..tostring(MEFTI_list[k])) end
      end
      
    end --if #DirList > 0 then

    if IsDEV then print(" = = = = =") end
    if IsDEV then print("RAW ScriptList with info:") end
    for i=1,#ScriptList do
      if IsDEV then print("=== "..i..": "..tostring(ScriptTypeList[i]).." "..tostring(MEFTI_list[i]).." ["..ScriptList[i].."]") end
    end      
    if IsDEV then print(" = = = = =") end
    
    if IsDEV then H.WFAK() end
    
    return DirList,ScriptList,ScriptTypeList,MEFTI_list
  end --  local function CleanModScriptDirList(DirList,pathToModScript,DONOTUSE_name,COMBINE_name)
  --***************************************************************************************************

  -- local startCMSD = os.clock()
-- H.printf(" %s A: before Robocopy... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startCMSD,"start"),H._zDEFAULT)
  local cmd = [[robocopy ]]..pathToModScript..[[\. ]]..pathToModScript..[[\. *.* /S /V /R:0 /L /NP /NS /NC /NDL /NJH /NJS /MT:12]]
  
  local dirList = H.GetList(cmd,true)

  if IsVerbose then
    H.printf("   Found %d files",#dirList)
  end
    
-- for i=#dirList,1,-1 do
  -- if H.trim(dirList[i]) == "" then
    -- table.remove(dirList,i)
  -- end
-- end
-- print("         @@@ A: Found = "..#dirList.." files in MODSCRIPT")
-- -- print("----->")
-- for j=1,#dirList do
  -- H.printf("-----> [%s]",dirList[j])
-- end
-- H.WFAK()

  --keep only files where ModScript sub-folder does not contain DONOTUSE_name and not those in 'ModHelperScripts'+'Disabled scripts and paks'+'GlobalMEFTI'
  local ScriptList = {}
  local ScriptTypeList = {}
  -- local MEFTI_list = {}
-- H.printf(" %s B: done Robocopy... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startCMSD,"elapsed"),H._zDEFAULT)
  dirList,ScriptList,ScriptTypeList,MEFTI_list = CleanModScriptDirList(dirList,pathToModScript,H.gDONOTUSE_name,H.gCOMBINE_name)
-- H.printf(" %s C: done dirList... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startCMSD,"elapsed"),H._zDEFAULT)
-- print("         @@@ B: Found = "..#dirList.." files in MODSCRIPT after removing folders containing "..H.gDONOTUSE_name)

-- print(robocopyResult)
-- H.WFAK()
  
  --    dirList: the full list of 'IN_USE' files
  -- ScriptList: the list of 'LUA' scripts
  --   ScriptTypeList: the type of these scripts
  --       MEFTI_list: the info on MEFTI folder presence
  
  -- now set info on 'too deep' sub-folders and 'too long path'
  --   like: Test_Combine_vs_Invividual\PubMods2\BAD_SUB_FOLDER
  
  local KeepThis = {}
  -- local info = ""
  for i=1,#ScriptList do
    ScriptList[i] = H.trim(ScriptList[i])
    p("ScriptList["..i.."] = ["..ScriptList[i].."]")

    --cannot do code line below, some path could contain pattern magic characters
    --local tmp = strgsub(dirlist[i],H.gMASTER_FOLDER_PATH..[[ModScript\]],"")
    
    -- do this instead
    local pos = strfind(strupper(ScriptList[i]),[[MODSCRIPT\]],1,true)
    if pos then
      local tmp = strsub(ScriptList[i],pos + 10)
      local _,n = strgsub(tmp,[[\]],"",-1)

      KeepThis[#KeepThis+1] = {}
      KeepThis[#KeepThis][1] = ScriptList[i]
      KeepThis[#KeepThis][2] = "" --default, folderTooDeep
      KeepThis[#KeepThis][3] = false --default, pathTooLong
      KeepThis[#KeepThis][4] = ScriptTypeList[i] --"N", "C" or ("AZ"|"A"|"Z") or ("FE"|"F"|"E")
      KeepThis[#KeepThis][5] = MEFTI_list[i] --default, true if MEFTI exist in this folder

      if n > maxFolderDepthAllowed then
        -- folderTooDeep
        -- if info ~= H.GetRelPathToScript(tmp) then
          -- info = H.GetRelPathToScript(tmp)
        -- end
        KeepThis[#KeepThis][2] = H.GetRelPathToScript(tmp)
      end
    else
      -- BIG PROBLEM 
      print([[A: Cannot find 'MODSCRIPT\' in <]]..strupper(dirList[i])..">")
    end
    
    if #ScriptList[i] > 260 then
      -- pathTooLong
      KeepThis[#KeepThis][3] = true
    end    
  end

  -- full list of valid scripts with additional info
  H.gScriptList = KeepThis

  -- finally refresh the full dir list with info on 'too deep' and 'too long path'
  local KeepThis = {}
  -- local info = ""
  for i=1,#dirList do
    dirList[i] = H.trim(dirList[i])
    -- print("dirList["..i.."] = ["..dirList[i].."]")

    KeepThis[#KeepThis+1] = {}
    KeepThis[#KeepThis][1] = dirList[i]
    KeepThis[#KeepThis][2] = "" --default, folderTooDeep
    KeepThis[#KeepThis][3] = false --default, pathTooLong

    --cannot do that below, some path could contain pattern magic characters
    --local tmp = strgsub(dirlist[i],H.gMASTER_FOLDER_PATH..[[ModScript\]],"")
    
    -- do this instead
    local pos = strfind(strupper(dirList[i]),[[MODSCRIPT\]],1,true)
    if pos then
      local tmp = strsub(dirList[i],pos + 10)
      local _,n = strgsub(tmp,[[\]],"",-1)

      if n > maxFolderDepthAllowed then
        -- folderTooDeep
        -- if info ~= H.GetRelPathToScript(tmp) then
          -- info = H.GetRelPathToScript(tmp)
        -- end
        KeepThis[#KeepThis][2] = H.GetRelPathToScript(tmp)
      end
    else
      -- BIG PROBLEM: skip
      -- print([[B: Cannot find 'MODSCRIPT\' in <]]..strupper(dirList[i])..">")
    end
    
    if #dirList[i] > 260 then
      -- pathTooLong
      KeepThis[#KeepThis][3] = true
    end    
  end

  -- full path/filename list of valid files with all extensions and 'too deep', 'too long path' still included
  H.gModScriptValidContent = KeepThis
-- H.printf(" %s D: done gModScriptValidContent... (%s) %s",H.gcWARNING,H.dClock(os.clock()-startCMSD,"elapsed"),H._zDEFAULT)
end

--***************************************************************************************************
--return a list of files with extension EXT in ModScript and sub-folders
--   that do not have a file DONOTUSE_name in the folder
--   nor are inside "ModHelperScripts"+"Disabled scripts and paks"+"GlobalMEFTI" folder
function H.GetFilesWithExt(EXT,IsModScriptfolderOnly)
  if IsModScriptfolderOnly == nil then
    IsModScriptfolderOnly = false
  end
  --clean and keep only EXT files
  local dirList = GetDirList(H.gModScriptValidContent,EXT,IsModScriptfolderOnly)
  return dirList
end

--***************************************************************************************************
--return a list of files with extension EXT in Folder
--   that do not have a file DONOTUSE_name in the folder
--   nor are inside "ModHelperScripts"+"Disabled scripts and paks"+"GlobalMEFTI" folder
function H.GetFilesWithExtInFolder(Folder,EXT)
  --clean and keep only EXT files
  local dirList = GetDirList(H.gModScriptValidContent,EXT)
  
  local tmp = {}
  for i=1,#dirList do
-- print(" - "..dirList[i])
    if strfind(dirList[i],Folder,1,true) then
      tmp[#tmp+1] = dirList[i]
    end
  end
  -- print("         @@@ D: Found = ["..#tmp.."] files with EXT = ["..EXT.."] in ["..Folder.."]")
  
  return tmp
end

--***************************************************************************************************  
function H.GetRelPathToScript(scriptPath)
  --we only keep the path where the script came from
  local IsSubFolder = false
  local scriptSourcePath = H.getPath(scriptPath)
  if scriptSourcePath == nil then
    scriptSourcePath = ""
    IsSubFolder = true
  end
-- print("X: GetRelPathToScript:          === FOR bScriptName = ["..scriptPath.."]")
-- print("X: GetRelPathToScript:          === FOR scriptSourcePath = ["..scriptSourcePath.."]")
  return scriptSourcePath,IsSubFolder
end

--***************************************************************************************************
do --To retrieve a table from a text file
  function table.load( sfile )
    local ftables,err = loadfile( sfile )
    if err then return _,err end
    local tables = ftables()
    for idx = 1,#tables do
       local tolinki = {}
       for i,v in pairs( tables[idx] ) do
          if type( v ) == "table" then
            tables[idx][i] = tables[v[1]]
          end
          if type( i ) == "table" and tables[i[1]] then
            tolinki[#tolinki+1] = { i,tables[i[1]] }
          end
       end
       -- link indices
       for _,v in ipairs( tolinki ) do
          tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
       end
    end
    return tables[1]
  end

  local function basicSerialize(o)
    if type(o) == "number" then
      return tostring(o)
    else   -- assume it is a string
      return string.format("%q", o)
    end
    -- return string.format([["%s"]], o)
  end

  --To save a table to a text file
  function table.save(filename, value, saved)
    saved = saved or {}       -- initial value
    io.write(filename, " = ")
    if type(value) == "number" or type(value) == "string" then
      io.write(basicSerialize(value), "\n")
    elseif type(value) == "table" then
      if saved[value] then    -- value already saved?
        io.write(saved[value], "\n")  -- use its previous filename
      else
        saved[value] = filename   -- save filename for next time
        io.write("{}\n")     -- create a new table
        for k,v in pairs(value) do      -- save its fields
          local fieldfilename = string.format("%s[%s]", filename, basicSerialize(k))
          table.save(fieldfilename, v, saved)
        end
      end
    elseif type(value) == "boolean" then
      io.write(tostring(value), "\n")
    else
      print("cannot save value "..value.." as a "..type(value))
    end
  end
end

--***************************************************************************************************
function H.SaveTable(filename,MyTable,TableName)
  io.output(filename)
  local name = strsub(filename,1,strfind(filename,".",1,true)-1)
  io.write(TableName)
  table.save(name, MyTable)
  io.close()
end

--***************************************************************************************************
function H.ReturnUpperCaseKwTable(thisTable)
  local newTable = {}
  if type(thisTable) == "table" then
    for i=1,#thisTable do
      -- and remove leading ^ and trailing $
      newTable[#newTable + 1 ] = H.makeRegExUppercase(thisTable[i]) -- strupper(thisTable[i])
      
      if strsub(newTable[#newTable],1,1) == "^" then
        newTable[#newTable] = strsub(newTable[#newTable],2)
      end
      if strsub(newTable[#newTable],-1,-1) == "$" then
        newTable[#newTable] = strsub(newTable[#newTable],-2)
      end
    end
    return newTable
  end
  return thisTable
end

--***************************************************************************************************
function H.GetTableSize(mod_def)
  local count = 0
  count = count + #mod_def["ADD_FILES"]
  H.printf("#mod_def[MODIFICATIONS] = %d",#mod_def["MODIFICATIONS"])
  for i = 1, #mod_def["MODIFICATIONS"] do
    H.printf("#mod_def[MODIFICATIONS][%d][MBIN_CHANGE_TABLE] = %d",i,#mod_def["MODIFICATIONS"][i]["MBIN_CHANGE_TABLE"])
    for j = 1, #mod_def["MODIFICATIONS"][i]["MBIN_CHANGE_TABLE"] do
      H.printf("#mod_def[MODIFICATIONS][%d][MBIN_CHANGE_TABLE][%d][EXML_CHANGE_TABLE] = %d",i,j,#mod_def["MODIFICATIONS"][i]["MBIN_CHANGE_TABLE"][j]["EXML_CHANGE_TABLE"])
      count = count + #mod_def["MODIFICATIONS"][i]["MBIN_CHANGE_TABLE"][j]["EXML_CHANGE_TABLE"]
    end
  end
  return count
end

--***************************************************************************************************
function H.GetTableCount(t)
  local tType = H.GetTableType(t)
  local count = 0
  if tType == "Array" then
    return #t
  elseif tType == "Dictionary" then
    for _ in pairs(t) do
      count = count + 1
    end
    return count
  end
  
  if tType == "Mixed" then
    return count + #t
  end
  return 0
end

--***************************************************************************************************
-- table.move(a, 1, #a, #b + 1, b) APPENDS all elements from list a to the end of list b.

-- table.move(a, 1, #a, 1, {}) returns a CLONE of list a 

-- clone an ARRAY table
function H.cloneArray(t)
  return table.move(t, 1, #t, 1, {})
  
  -- local function up(t)
    -- return {table.unpack(t)}
  -- end
  
  -- local success,tab = pcall(up,t)
  -- if success then
    -- return tab
  -- else
    -- -- we have probably hit the table.unpack limit, do the longer way
    -- local clone = {}
    -- for k,v in ipairs(t) do
         -- clone[k] = v
    -- end
    -- return clone
  -- end
end

--***************************************************************************************************
-- clone a DICTIONARY table
function H.cloneDict(t1)
  local t2 = {}
  for k,v in pairs(t1) do
    t2[k] = v
  end
  return t2
end

--***************************************************************************************************
-- returns union of two tables
-- if IsNewTable then
--  into clone of first table
-- else
--  into first table
-- end
function H.tableUnion(IsNewTable,t1,t2)
  local t
  if IsNewTable then
    if #t1 > 0 then
      t = H.cloneArray(t1)
    else
      t = H.cloneDict(t1)
    end
  else
    t = t1
  end
  if #t1 > 0 and #t2 > 0 then
    -- two ARRAY tables
    for i=1,#t2 do
      t[#t+1] = t2[i]
    end
  elseif #t1 > 0 then
    -- t1 is an ARRAY table
    -- t2 is DICTIONARY table
    for _,v in pairs(t2) do
      -- we keep the returned table an ARRAY table, not MIXED
      t[#t+1] = v
    end
  else
    -- t1 and t2 are DICTIONARY tables
    for k,v in pairs(t2) do
      -- we keep the returned table as a DICTIONARY table, not MIXED
      t[k] = v
    end
  end
  return t
end
--***************************************************************************************************

--***************************************************************************************************
-- transform a DICTIONARY table "values" into an Array
function H.DictValuesToArray(t1)
  local t2 = {}
  for _,v in pairs(t1) do
    t2[#t2+1] = v
  end
  return t2
end
--***************************************************************************************************

--***************************************************************************************************
-- transform a DICTIONARY table "keys" into an Array
function H.DictKeysToArray(t1)
  local t2 = {}
  for k in pairs(t1) do
    t2[#t2+1] = k
  end
  return t2
end
--***************************************************************************************************

--***************************************************************************************************
-- t: the ARRAY table to refresh
-- IsKeepOrder: bool, true->tmpI, false->tmp
-- returns: a new refreshed table
--    tmp: THE ORDER is NOT PRESERVED, INDEXES are consecutive
--   tmpI: THE ORDER is PRESERVED, INDEXES are consecutive (DEFAULT)
--         WARNING, a DICTIONARY table will always return an empty tmpI
function H.refreshTable(t,IsKeepOrder)
  if IsKeepOrder == nil then
    IsKeepOrder = true
  end
  
  if #t == 0 and not next(t) then
    -- same empty table
    return t
  end
  
  if #t == 0 then
    -- DICTIONARY table
    IsKeepOrder = false
  end
  
  if IsKeepOrder then
    -- for ARRAY table
    local tmpI = {}
    local index = 1
    for i=1,#t do
      if t[i] ~= "NIL" then
        tmpI[index] = t[i]
        index = index + 1
      end
    end
    return tmpI
    
  else
    -- for NON-INDEX table
    local tmp = {}
    local index = 1
    for k,v in pairs(t) do
      tmp[index] = v
      index = index + 1
    end    
    return tmp
  end  
end
--***************************************************************************************************

--***************************************************************************************************
-- based on https://gist.github.com/qizhihere/cb2a14432d9bf65693ad?permalink_comment_id=4104319
-- input: all the tables to merge
-- returns: the merged table
function H.tablesMergeGeneric(...) -- recursive
  local tables_to_merge = { ... }
  -- assert(#tables_to_merge > 1, "There should be at least two tables to merge them")

  -- for k, t in ipairs(tables_to_merge) do
    -- assert(type(t) == "table", string.format("Expected a table as function parameter %d", k))
  -- end

  local result = tables_to_merge[1]

  for i = 2, #tables_to_merge do
    local from = tables_to_merge[i]
    for k, v in pairs(from) do
      local typeK = type(k)
      if typeK == "number" then
        result[#result+1] = v
      elseif typeK == "string" then
        if type(v) == "table" then
          result[k] = result[k] or {}
          result[k] = tablesMergeGeneric(result[k], v) -- recursive
        else
          result[k] = v
        end
      end
    end
  end
  return result
end--***************************************************************************************************

--***************************************************************************************************
-- serialize ~ by YellowAfterlife
-- https://yal.cc/lua-serializer/
-- Converts value back into according Lua presentation
-- Accepts strings, numbers, boolean values, and tables.
-- Table values are serialized recursively, so tables linking to themselves or
-- linking to other tables in "circles". Table indexes can be numbers, strings,
-- and boolean values.
-- Created under https://creativecommons.org/licenses/by-nc-sa/3.0/
-- Changes made by Wbertro:
  --padding reduced to '  '
  --adapted to 'understand' a AMUMSS script
function H.serializeObject(object,multiline,depth,name) --recursive
	depth = depth or 0
	if multiline == nil then multiline = true end
	local padding = string.rep('  ', depth) -- can use '\t' if printing to file
	local r = padding -- result string
	local NextLine = '\n'
  -- if depth == 0 then
    -- NextLine = ''
  -- end
  
  if name then -- should start from name
    -- enclose in brackets if not string or not a valid identifier
    -- thanks to Boolsheet from #love@irc.oftc.net for string pattern
    local test1 = (type(name) ~= 'string' or strfind(name,'^([%a_][%w_]*)$') == nil)
    local test2 = ( (type(name) == 'string') and string.format('%q', name) or tostring(name) )
    local test3 = ( test1 and ('['..test2..']') or tostring(name) )
    prefix = ""
    suffix = ""
    if depth ~= 0 then
      prefix = "[\""
      suffix = "\"]"
    end
		r = r..prefix..test3..suffix..' = '
    NextLine = ''
    if depth == 0 then
      --only on first run
      NextLine = '\n'
    end
	end
	
  if type(object) == 'table' then --we need to go into that table
    if depth == 0 then
      --only on first run
      r = r..(multiline and '\n' or '')..'{'..(multiline and NextLine or '')
    else
      r = r..(multiline and '\n' or '')..padding..'{'..(multiline and '\n' or ' ')
		end
    
    local length = 0
    for i, v in ipairs(object) do
			r = r..H.serializeObject(v, multiline, multiline and (depth + 1) or 0)..','..(multiline and '\n' or ' ') --recursive
			length = i
		end
		
    for i, v in pairs(object) do
			local itype = type(i) -- convert type into something easier to compare:
			itype =(itype == 'number')  and 1
          or (itype == 'string')  and 2
          or (itype == 'boolean') and 3
          or error('Unsupported index type "' .. itype .. '"')
          
			-- detect if item should be skipped
      local test4 = ( (itype == 1) and (i%1 == 0) and (i >= 1) and (i <= length) ) -- ipairs part
      local test5 = ( (itype == 2) and (strsub(i, 1, 1) == '_') ) -- prefixed string
      local skip = test4 or test5
			if not skip then
				r = r ..H.serializeObject(v, multiline, multiline and (depth + 1) or 0, i)..','..(multiline and '\n' or ' ') --recursive
			end
		end
		
    r = r..(multiline and padding or '')..'}'
	
  elseif type(object) == 'string' then
		-- r = r .. string.format('%q', object)
    if not strfind(object,"\n",1,true) then
      r = r..[["]]..object..[["]] --puts "" around values
    else
		r = r .."[["..object.."]]" --puts [[]] around long string
    end
	
  elseif type(object) == 'number' or type(object) == 'boolean' then
		r = r..tostring(object) --writes a number or a boolean
	
  elseif object == nil then
		r = r..[[nil]]
	
  else
		error('Unserializeable value "'..tostring(object)..'"')
	end
	
  return r --a string
end

--***************************************************************************************************
function H.iif(test, true_part, false_part)
  if (test) then
    return true_part
  else
    return false_part
  end
end

--this becomes a new lua 'Basic function'
-- NOT USED
_G.switch = function(param, case_table)
    local case = case_table[param]
    -- print("case = "..tostring(case))
    if case then return case() end
    local def = case_table['default']
    -- print("def = "..tostring(def))
    return def and def() or nil
end
--**********  END: switch statement  *****************************************************************************************

--***************************************************************************************************
-- NOT USED
--[[
get(t, 'a', 2, 'c') -> t.a?[2]?.c?
get the keys or nil if any are missing.
]]
H.get = (function(t, ...)
  local len = select('#', ...)
  for i=1,len-1 do
    t = t[select(i, ...)]
    if t == nil then return end
  end
  return t[select(len, ...)]
end)

--***************************************************************************************************
-- NOT USED
function H.sizeint()
   return ( ( 1 << 32 > 0 ) and 8 or 4 )
end

--***************************************************************************************************
-- NOT USED
function H.is64()
   return sizeint() == 8 and true or false;
end

--***************************************************************************************************
-- NOT USED
function H.is32()
   return sizeint() == 4 and true or false;
end

--***************************************************************************************************
-- NOT USED
local function Round(number)
  return math.floor(number+0.5)
end

--***************************************************************************************************
-- INTERNAL
local function math_sign(v)
	return (v >= 0 and 1) or -1
end

--***************************************************************************************************
-- INTERNAL
local function math_round(v, multi)
	multi = multi or 1
	return math.floor((v/multi) + (math_sign(v) * 0.5)) * multi
end

--***************************************************************************************************
-- https://gist.github.com/yi/01e3ab762838d567e65d
function H.fromHex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

--***************************************************************************************************
-- https://gist.github.com/yi/01e3ab762838d567e65d
function H.toHex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

--***************************************************************************************************
function H.string_round(value)
  local dotPosition = strfind(value,".",1,true)
  if dotPosition == nil then return value end
  local afterDotString  = strsub(value,dotPosition+1)
  if strfind(afterDotString,"0000",1,true) or strfind(afterDotString,"9999",1,true) then
    value = tostring(math_round(tonumber(value),0.001))
  end
  return value
end

--***************************************************************************************************
-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
-- modified, slowest
function H.trim(s)
  if s then
    -- using () to force return of 1st arg only
    return (strgsub(s,"^%s*(.-)%s*$", "%1"))
  end
  return s
end

--***************************************************************************************************
-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
-- modified, faster than H.trim()
function H.rtrim(s)
  -- using () to force return of 1st arg only
  local n = #s
  while n > 0 and strfind(s,"^%s", n) do n = n - 1 end
  return strsub(s,1, n)
  -- return s:match('^(.*%S)%s*$')
end

--***************************************************************************************************
-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
-- modified, faster than H.rtrim()
function H.ltrim(s)
  -- using () to force return of 1st arg only
  return (strgsub(s,"^%s*", ""))
end

--***************************************************************************************************
-- string find from right to left
-- NOT USED
function H.LFind(str,pattern,init)
  if init == nil then
    init = 1
  end
  local b,f = str:reverse():find(pattern:reverse(), init)
  if b and f then
    return #str-f, #str-b
  end
  return nil,nil
end

--***************************************************************************************************
--Returns a table splitting the string (relies on a delimiter)
--from https://gist.github.com/GabrielBdeC/b055af60707115cbc954b0751d87ec23
--Changes to enhance the code from https://gist.github.com/jaredallard/ddb152179831dd23b230
function string:splitB(delimiter) -- FASTEST
  local result = {}
  local from = 1
  local delim_from, delim_to = strfind(self,delimiter, from, true)
  while delim_from do
    if delim_from ~= 1 then
      result[#result+1] = strsub(self,from, delim_from-1)
    end
    from = delim_to + 1
    delim_from, delim_to = strfind(self,delimiter, from, true)
  end
  if from <= #self then
    result[#result+1] = strsub(self,from)
  end
  return result
end

-- s: a MXML string to be split
-- suffix: a string added to the end of each line unless the line ends in --> (a commented line)
-- Returns a table splitting an EXML long string
--  removes EMPTY lines
function H.stringToTable(s,suffix) -- GOOD, does not rely on '\n'
    if s == "" then return {""} end
    local suffix = suffix or ""
    local result = {}
    for w in strgmatch(s,"[ ]-%b<>") do
      if w ~= "" then
        if strfind(w,[[<!]],1,true) then
          result[#result+1] = w
        else
          result[#result+1] = w..suffix
        end
      end
    end
    return result
end

-- Inhibit Regular Expression magic characters ^$()%.[]*+-?
-- NOT USED
function H.MakeStringNormal(str)
  -- Prefix every non-alphanumeric character (%W) with a % escape character, 
  -- where %% is the % escape, and %1 is original character
  return strgsub(str,"(%W)","%%%1")
end

--***************************************************************************************************
--expr = string to check
--returns IsRegularExpression = true if expr is a regular expression
function H.IsExpressionRegular(expr)
  --check if we are using LUA regular strings to search for this string
  if (strsub(expr,1,1) == "{" and strsub(expr,1,3) ~= "{:}") and (strsub(expr,-1,-1) == "}"  and strsub(expr,-1,-3) ~= "{:}") then
    return true
  end

  local magicChar = "^$()%[]*+-?)"
  for i=1,#magicChar do
    local pos = strfind(expr,strsub(magicChar,i,i),1,true)
    if pos and (pos > 1 and strsub(expr,pos-1,pos-1) ~= "%" ) then
      return true
    end
  end
  return false
end

--***************************************************************************************************
--expression = string
--returns IsRegular = true if expr is a regular expression
--returns uppercase normal or regular expression without <>
function H.makeRegExUppercase(expr)
  local p = function(...) end
  -- local p = print

  -- p("expr = ["..tostring(expr).."]")
  local IsRegular = H.IsExpressionRegular(expr)
  -- p("IsRegular = ["..tostring(IsRegular).."]")
  if IsRegular then
    local skipNext = false
    for i=1,#expr do
      if strsub(expr,i,i) == "%" then
        skipNext = true
      elseif skipNext then
        skipNext = false
      else
        if i < #expr then
          expr = strsub(expr,1,i-1)..strupper(strsub(expr,i,i))..strsub(expr,i+1)
        else
          expr = strsub(expr,1,i-1)..strupper(strsub(expr,i,i))
        end
      end
    end
    --remove the {}, if any
    if strsub(expr,1,1) == "{" and strsub(expr,-1,-1) == "}" then
      expr = strsub(expr,2,-2)
    end
  else
    expr = strupper(expr)
  end
  
  return expr, IsRegular
end

--***************************************************************************************************
--return first 's' as 'string'
function H.ReturnStringFrom(s)
  if s == nil then return "" end
  local ss = s
  local sType = type(s)
  if sType == 'table' then
    ss = s[1]
    sType = type(ss)
  end
  if sType == 'string' then return ss end
  if sType == 'number' or sType == 'boolean' then return tostring(ss) end
  if sType == 'table' then return "sub-table" end
  --for other types like "function", "thread" and "userdata"
  return "error"
end

--***************************************************************************************************
-- remove all space characters after > and before crlf
-- make sure all > have a crlf
-- remove crlf from lines ending in -->
-- add back crlf from lines ending in )--> (protect 2nd line of an EXML)
-- remove double crlf and empty lines
function H.NormalizeStrEndlines(str)
  -- print("str = ["..str.."]")
  -- return str:gsub('>%s*\n','>\n'):gsub('>','>\n'):gsub("%-%->\n","-->"):gsub("%)%-%->",")-->\n"):gsub("\n%s*\n","\n")
  return strgsub(strgsub(strgsub(strgsub(strgsub(str,'>%s*\n','>\n') ,'>','>\n') ,"%-%->\n","-->") ,"%)%-%->",")-->\n") ,"\n%s*\n","\n")
end

--***************************************************************************************************
-- **************  auto-adjust indentation to match the previous line  **************
-- FileTable: table where the text_to_add will be inserting eventually
-- text_to_add: the table that is being inserted
-- insertPoint: where in FileTable that text_to_add is inserted
-- returns: re-indented text_to_add to match FileTable insertPoint indentation
function H.AutoAdjustIndentation(FileTable,text_to_add,insertPoint)
  -- H.printf(H._zWHITEonDARKCYAN.."At "..H.dClock().." auto-adjust indentation "..H._zDEFAULT,"")
  -- get current indent size only from EXMLs (no need to do that for SAVED_SECTIONS)
  
  if type(FileTable[1]) == "string" and H.ltrim(FileTable[1]):sub(1,5) == [[<?xml]] then
    -- this is an EXML or pseudo EXML file
    -- print(" - FOUND AN EXML")
    local My = {}
    
    My.currentIndentSize = 0
    My.currentIndentSizeZero = false
    My.IsDataFound = false
    My.IsSameFile = FileTable == text_to_add
    -- H.printf(" - My.IsSameFile = [%s]",tostring(My.IsSameFile))
    -- H.printf(" -   insertPoint = [%s]",tostring(insertPoint))
    
    My.w = 1
    for w = 1, #FileTable do
      if not My.IsDataFound and H.ltrim(FileTable[w]):sub(1,5) == [[<Data]] then
        My.IsDataFound = true
      end
      
      if My.IsDataFound and H.trim(FileTable[w+1]) ~= "" then
        -- force indent of line after <Data to be H.TtoS size
        My.currentIndentSize = #H.TtoS -- #FileTable[w+1] - #H.ltrim(FileTable[w+1])
        -- local s = H.TABtoSPACES(FileTable[w+1])
        -- My.currentIndentSize = #s - #H.ltrim(s)
        My.w = w

        if insertPoint == 1 then
          insertPoint = w
        end

        break
      end
    end
    
    if My.currentIndentSize <= 1 then -- was == 0
      My.currentIndentSizeZero = true
      My.currentIndentSize = 2
    end
    
    -- now make it a string
    My.currentIndentSize = strrep(" ",My.currentIndentSize)
    -- H.printf(" - My.currentIndentSize = [%s]",My.currentIndentSize)
    
    local s = H.TABtoSPACES(FileTable[insertPoint])
    My.spaceNumLineBeforeInsertPoint = #s - #H.ltrim(s)
    -- H.printf("A: My.spaceNumLineBeforeInsertPoint = [%s]",My.spaceNumLineBeforeInsertPoint)
    
    if My.spaceNumLineBeforeInsertPoint == 0 then
      -- when the file is a full EXML
      My.spaceNumLineBeforeInsertPoint = #My.currentIndentSize
    end
    -- H.printf("B: My.spaceNumLineBeforeInsertPoint = [%s]",My.spaceNumLineBeforeInsertPoint)
  
    if My.spaceNumLineBeforeInsertPoint > 0 then
      
      -- NOT USED
      -- My.currentIndentSizeMultiplier = My.spaceNumLineBeforeInsertPoint // #My.currentIndentSize
      -- H.printf("My.currentIndentSizeMultiplier = [%s]",My.currentIndentSizeMultiplier)
      
      -- if My.IsDataFound and insertPoint == 1 then
        -- -- when the file is a full EXML
        -- insertPoint = My.w + 1
      -- end
      -- H.printf("C:   insertPoint = [%s]",tostring(insertPoint))
      
      My.currentSpacing = strsub(FileTable[insertPoint],1,My.spaceNumLineBeforeInsertPoint)
      My.currentSpacing = strrep(" ",#My.currentSpacing) -- to be sure it is only spaces

      if My.currentIndentSizeZero then
        -- special case
        My.currentSpacing = "  "  -- ""
      end
      
      My.indentLevel = 0
      if not My.IsDataFound and strfind(FileTable[insertPoint],[["%s->]]) then
        -- adjust in case of HOS in MXML
        My.indentLevel = My.indentLevel + 1
      end
      -- if H.rtrim(FileTable[insertPoint]):sub(-2) == [[">]] then
        -- -- adjust in case of HOS in EXML
        -- My.indentLevel = My.indentLevel + 1
      -- end
      
      if My.IsSameFile then
        My.start = My.w + 1 -- was 2
      else
        My.start = 1
      end
      
-- print("XXX === === === ===")
-- H.printf("XXX                insertPoint = [%d]",insertPoint)
-- if insertPoint > 1 then
  -- H.printf("XXX FileTable[insertPoint - 1] = [%s]",FileTable[insertPoint-1])
-- end
-- H.printf("XXX     FileTable[insertPoint] = [%s]",FileTable[insertPoint])
-- H.printf("XXX          My.currentSpacing = [%s]",My.currentSpacing)
-- H.printf("XXX       My.currentIndentSize = [%s]",My.currentIndentSize)
-- H.printf("XXX             My.indentLevel = [%d]",My.indentLevel)
-- H.printf("XXX                   My.start = [%d]",My.start)
-- if My.start > 1 then
  -- H.printf("XXX  text_to_add[My.start - 1] = [%s]",H.trim(text_to_add[My.start-1]))
-- end
-- H.printf("XXX      text_to_add[My.start] = [%s]",H.trim(text_to_add[My.start]))
      
      for i = My.start, #text_to_add do
        My.tmp1 = H.trim(text_to_add[i]):gsub([["%s->]],[[">]]):gsub([[/%s->]],[[/>]])
        
        if i < #text_to_add then
          My.tmp2 = H.trim(text_to_add[i+1]):gsub([["%s->]],[[">]]):gsub([[/%s->]],[[/>]])
        else
          My.tmp2 = nil
        end
        
        -- determine what type of endOfLine we are dealing with
        My.endOfFirstAddLine = 1 -- [[/>]]
        if strfind(My.tmp1,[[">]],1,true) then
          if strmatch(My.tmp1:upper(),[[ _I]]) and My.tmp2 and strfind(My.tmp2,[[">]],1,true) and strmatch(My.tmp2:upper(),[[ _I]]) then
            -- next line is also ending in ">
            -- and having _id/_index: THIS is a value of a ListOfValues
            My.endOfFirstAddLine = 1 -- case of a listofValues
          else
            My.endOfFirstAddLine = 2 -- [[">]]
          end
        elseif strfind(My.tmp1,[[</]],1,true) then
          My.endOfFirstAddLine = 3 -- [[</]]
        end
-- H.printf(" - My.endOfFirstAddLine = [%d]",My.endOfFirstAddLine)
        -- END: determine what type of endOfLine we are dealing with
        
        if My.endOfFirstAddLine == 1 or My.tmp1 == "" or My.tmp1:sub(1,2) == "--" then
-- print("   ==> type 1")
          -- most lines: this is a normal, empty or comment line, indent does not change
          text_to_add[i] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp1 -- trimming right side also
        elseif My.endOfFirstAddLine == 2 then
-- print("   ==> type 2")
          -- this is a HOS line
          text_to_add[i] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp1 -- trimming right side also
          My.indentLevel = My.indentLevel + 1
        elseif My.endOfFirstAddLine == 3 then
-- print("   ==> type 3")
          My.indentLevel = My.indentLevel - 1
          if strsub(My.tmp1,1,3) == [[</P]] then
            -- this is </Property>
            text_to_add[i] = My.currentSpacing..strrep(My.currentIndentSize,My.indentLevel)..My.tmp1 -- trimming right side also
          else
            -- this is </Data>
            text_to_add[i] = strrep(My.currentIndentSize,My.indentLevel)..My.tmp1 -- trimming right side also
          end
        end                              
      end
      -- H.printf(" - FileTable[insertPoint] = [%s]",FileTable[insertPoint])
      -- H.printf(" -         text_to_add[1] = [%s]",text_to_add[1])

    end
    
    -- IF I want to re-use this, I need to re-write "Discarding logic" to do the table.concat starting with "<Data template" line
    -- if My.IsDataFound and My.IsSameFile then
      -- table.insert(text_to_add, My.w, [[<!--File indented by AMUMSS v.]]..H.LoadFileData("AMUMSSVersion.txt")..[[-->]])
    -- end
    
  end -- this is an EXML file
  -- H.printf(H._zWHITEonDARKCYAN.."At "..H.dClock().." END: auto-adjust indentation "..H._zDEFAULT,"")
  
  return text_to_add
end
--***************************************************************************************************

--***************************************************************************************************
-- t: EXML/SavedSection file table
-- msg: a string message
function H.TestLineCount(t,msg)
  local s = table.concat(t):upper()
  local _,lineCount = strgsub(s,'>','>')
  if lineCount ~= #t then
    H.printf(">>> %s"..H.gcWARNING..[[ [WARNING] Line count(%d) does not match number of line endings ">"(%d) ]]..H._zDEFAULT,msg,lineCount,#t)
    H.WFAKD()
  end
end
  
--***************************************************************************************************
function H.StripInfo(Info,cut1,cut2)
  -- BEST way: test for number, otherwise a string
  if type(Info) == "number" then
    Info = tostring(Info)
  end

  local _,stop = strfind(Info,cut1,1,true)
  if stop == nil then
    return Info
  end

  local result = strsub(Info,stop+1)
  if cut2 then
    local start = strfind(result,cut2,1,true)
    if start then
      return strsub(result,1,start-1)
    else
      return Info
    end
  end
  return result
end

--***************************************************************************************************
-- line = a line from the EXML
-- returns: in ORIGINAL CASE
--   p, v as 'Property name=', 'value='
--   p, nil as 'Property name=', nil
--   nil, v as nil, 'Property value='
--   nil, nil if not found
function H.GetPropertyNameValue(line)
  local pattern = [["(.-)".-"(.-)"]]
  local strmatch = string.match
  -- p = Property name/value
  -- v = value
  local p,v = strmatch(line,pattern)
  if p and v then
    -- found Property name= AND value=
    return p,v
  else
    pattern = [["(.-)"]]
    local p = strmatch(line,pattern)
    
    if p then
      if strfind(line,"me=",1,true) then
        -- Property is name=
        return p,nil
      else
        -- Property is value=
        return nil,p
      end
    end
  end 
  return nil,nil
end

--***************************************************************************************************
-- line = a line from the EXML (made UPPERCASE internally)
-- returns: in UPPER and ORIGINAL CASE
--   pnv, v as 'Property name=', 'value='
--   pnv as 'Property value='
--   nil if not found
function H.GetPropertyValue(line)
  local pattern = [["(.-)".-"(.-)"]]
  local strmatch = string.match
  -- pnv = Property name/value
  -- v = value
  local pnv,v = strmatch(strupper(line),pattern)
  if pnv then
    local pnvL,vL = strmatch(line,pattern)
    return pnv,v,pnvL,vL
  else
    pattern = [["(.-)"]]
    pnv = strmatch(strupper(line),pattern)
    if pnv then
      local pnvL = strmatch(line,pattern)
      return nil,pnv,nil,pnvL
    else
      return nil,nil,nil,nil
    end
  end 
end

--***************************************************************************************************
-- line = a line from the EXML
-- returns: in ORIGINAL CASE
--   pnv as 'Property name or Property value'
--   line if not found
function H.GetProperty(line)
  local m = string.match(line,[["(.-)"]])
  if m then
    return m
  end
  return line
end

--***************************************************************************************************
-- line = a line from the EXML
-- returns: in ORIGINAL CASE
--   v as 'value'
--   line if not found
function H.GetValue(line)
  local m = string.match(line,[[ue="(.-)"]])
  if m then
    return m
  end
  return line
end

--***************************************************************************************************
-- line = a line from the EXML
-- returns:
--  linesFound: a table of line numbers in this group matching "PROPERTY"
function H.GetPropertyEXT(property,IsRegular,FileTable,startIndex,endIndex)
  -- find how many lines has this property in this group?
  H.DEBUG_VCTproperty_print("### START: In H.GetPropertyEXT()")
  H.DEBUG_VCTproperty_print("###   #FileTable = "..#FileTable)
  H.DEBUG_VCTproperty_print("###     property = ["..property.."] the 'original'")
  H.DEBUG_VCTproperty_print("###    IsRegular = ["..tostring(IsRegular).."]")
  
  local prop = property
  if IsRegular then
    if (strsub(property,1,1) == "^") then
      prop = [["]]..strsub(property,2) -- start with " and remove the ^
    end
    if (strsub(property,-1,-1) == "$") then
      prop = strsub(prop,-2)..[["]] -- remove the $ and ends with "
    end
  else
    -- it is as if we had used ^...$
    prop = [["]]..prop..[["]] -- starts and ends with "
  end
  H.DEBUG_VCTproperty_print("###         prop = ["..prop.."] the 'searchedFor'")
  
  local linesNumFound = {}
  
  if startIndex < 0 then startIndex = 0 end
  
  if startIndex + 1 > endIndex then
    linesNumFound[#linesNumFound+1] = startIndex
    return linesNumFound
  end
  
  local section = strupper(table.concat(FileTable,"",startIndex + 1,endIndex))
  H.DEBUG_VCTproperty_print("### section string size = ["..#section.."] for FileTable index "..(startIndex + 1).." to "..tostring(endIndex))
  
  --***************************************************************************************************
  -- need to check if the 'original' property of found line is ok to keep
  local function IsCheckProperty(FileTable,tableIndex,property)
    local line = strupper(FileTable[tableIndex])
    if H.GetProperty(line) ~= line then
      -- a valid property, is it one we are searching?
      return (strfind(p,property,1,false) ~= nil)
    end
    return false
  end
  --***************************************************************************************************

  local firstPosEnd = nil
  local lineNumber = nil

  _,firstPosEnd = strfind(section,prop,1,not IsRegular)
  H.DEBUG_VCTproperty_print(string.format("### prop=[%s] IsRegular=(%s) %d-%d",prop,tostring(IsRegular),(startIndex+1),endIndex))
  
  if firstPosEnd then
    _,lineNumber = strgsub(strsub(section,1,firstPosEnd),'>','>',-1)
    local tableIndex = startIndex + 1 + lineNumber
    H.DEBUG_VCTproperty_print("### A: Line Found ("..tostring(lineNumber)..") using table.concat: ["..FileTable[tableIndex].."] at "..(tableIndex))    
    
    if not IsRegular or IsCheckProperty(FileTable,tableIndex,property) then
      H.DEBUG_VCTproperty_print("###   A: Using ["..FileTable[tableIndex].."] at "..(tableIndex))
      linesNumFound[#linesNumFound+1] = tableIndex
    end

    --local secondPos = nil
    local nextPos = nil
    _,nextPos = strfind(section,prop,firstPosEnd+1,not IsRegular)
    
    if nextPos then
      _,lineNumber = strgsub(strsub(section,1,nextPos),'>','>',-1)
      tableIndex = startIndex + 1 + lineNumber
      H.DEBUG_VCTproperty_print("### B: linesNumFound ("..tostring(lineNumber)..") using table.concat: ["..FileTable[tableIndex].."] at "..(tableIndex))

      if not IsRegular or IsCheckProperty(FileTable,tableIndex,property) then
        H.DEBUG_VCTproperty_print("###   B: Using ["..FileTable[tableIndex].."] at "..(tableIndex))
        linesNumFound[#linesNumFound+1] = tableIndex
      end
      
      H.DEBUG_VCTproperty_print("### >>> before while")
      local currentPos = nextPos
      H.DEBUG_VCTproperty_print("###   starting tableIndex = "..tableIndex..", currentPos = "..currentPos)
      
      while nextPos do
        nextPos,endPos = strfind(section,prop,currentPos+1,not IsRegular) -- always very fast
        H.DEBUG_VCTproperty_print("###     out find at endPos = "..tostring(endPos).."  into gsub")
        
        if nextPos then
          H.DEBUG_VCTproperty_print("###     into gsub at currentPos = "..currentPos..", endPos = "..endPos)
          _,lineNumber = strgsub(strsub(section,currentPos,endPos),'>','>',-1) -- slow has endPos increases if section is too big
          
          currentPos = endPos
          tableIndex = tableIndex + lineNumber
          H.DEBUG_VCTproperty_print("###     out gsub: with lineNumber = "..lineNumber..", currentPos = "..currentPos.." to insert: "..(tableIndex))
          
          if not IsRegular or IsCheckProperty(FileTable,tableIndex,property) then
            H.DEBUG_VCTproperty_print("###        C: Using ["..tostring(FileTable[tableIndex]).."] at "..(tableIndex))
            linesNumFound[#linesNumFound+1] = tableIndex
          end
                    
          nextPos = endPos + 1
        end
      end
      H.DEBUG_VCTproperty_print("### <<< after while")

    end
  end
H.DEBUG_VCTproperty_print("### END: In H.GetPropertyEXT()")
  return linesNumFound
end

--***************************************************************************************************
-- NOT USED, see H.GetFilenameFromFilePath(pathname)
function H.StripPath(filename,cutter)
  local start,stop = strfind(filename,cutter,1,true)
  local result = strsub(filename,stop+1)
  return result
end

-- nms languages list
H.languages = {
	EN = 'English',
	FR = 'French',
	IT = 'Italian',
	DE = 'German',
	ES = 'Spanish',
	RU = 'Russian',
	PL = 'Polish',
	NL = 'Dutch',
	PT = 'Portuguese',
	LA = 'LatinAmericanSpanish',
	BR = 'BrazilianPortuguese',
	Z1 = 'SimplifiedChinese',
	ZH = 'TraditionalChinese',
	Z2 = 'TencentChinese',
	KO = 'Korean',
	JA = 'Japanese',
	US = 'USEnglish'
}

H.languagesEXT = {}
for k,v in pairs(H.languages) do
  H.languagesEXT[v] = k
end

-- example
-- LocTable.MXML = [[
--[[ <?xml version="1.0" encoding="utf-8"?>
-- <Data template="cTkLocalisationTable">
  -- <Property name="Table">
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="UI_TIMEDUST_SYM"/>
      -- <Property name="English" value="Љ"/>
      -- <Property name="French" value="Љ"/>
    -- </Property>
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="VEHICLE_BUILDING_NPC"/>
      -- <Property name="English" value="Racial Monuments"/>
    -- </Property>
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="UI_TIP_SHIP_WOVEN2"/>
      -- <Property name="English" value="Woven Excellence"/>
    -- </Property>
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="UI_SHIPGUN_ROBO_NAME"/>
      -- <Property name="English" value="PREVALENCE GUN"/>
    -- </Property>
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="UI_SGUNK2_SYM"/>
      -- <Property name="English" value="Ψ"/>
    -- </Property>
    -- <Property value="TkLocalisationEntry.xml">
      -- <Property name="Id" value="UI_TIP_SHIP_POLYNESIA"/>
      -- <Property name="English" value="Polynesian Interlocks"/>
    -- </Property>
  -- </Property>
-- </Data>]]
--]]

H.entity = {
    {'&', '&amp;'}, -- must be first
    {'<', '&lt;'},
    {'>', '&gt;'},
    {'"', '&quot;'},
    {"'", '&apos;'},
    {'|NL|','&#xA;'},
    {'|CR|','&#xD;'}
  }

--***************************************************************************************************
-- from lMonk#7949: neat little code for LANGUAGE files
-- https://discord.com/channels/215514623384748034/215514674869829633/1088554918056562799
function H.CharEntitiesInsert(s)
  for _,e in ipairs(H.entity) do
    s = s:gsub(e[1], e[2])
  end
  return s
end

--***************************************************************************************************
-- from lMonk#7949: neat little code for LANGUAGE files
-- https://discord.com/channels/215514623384748034/215514674869829633/1088554918056562799
function H.CharEntitiesReverse(s)
  for _,e in ipairs(H.entity) do
    s = s:gsub(e[2], e[1])
  end
  return s
end

--***************************************************************************************************
-- NOT USED
-- name as string
-- returns: SpookyHash of name as string

-- {"Key":"Iis","Value":"RealityIndex"},
-- {"Key":"dZj","Value":"VoxelX"},
-- {"Key":"IyE","Value":"VoxelY"},
-- {"Key":"uXE","Value":"VoxelZ"},
-- {"Key":"vby","Value":"SolarSystemIndex"},
function H.HashName(name)
    -- SpookyConst = 0xDEADBEEFDEADBEEF
    -- var output = new byte[3]
    -- var message = Encoding.UTF8.GetBytes(name)
    -- var hash = message.SpookyHash128(0, message.Length, 8268756125562466087, 8268756125562466087) -- 0x72c085e2ee7c6f27

    -- -- Character set starts at '0' UTF-8, 68 characters, with an offset of +6 after 'Z'
    -- -- Character set: "0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxy"
    -- output[0] = (byte)(hash.UHash1 % 68 + '0')
    -- output[1] = (byte)((hash.UHash1 >> 21) % 68 + '0')
    -- output[2] = (byte)((hash.UHash1 >> 42) % 68 + '0')

    -- for i=1,#output do --(var i = 0; i < output.Length; i++)
        -- if output[i] > 'Z' then
            -- output[i] = output[i] + 6
        -- end
    -- end
    -- return -- return the ascii representation of the 3 bytes -- Encoding.UTF8.GetString(output)
end

-- INTERNAL
local gReportTable = {}

-- local reportFilehandle = io.open(H.gfilePATH.."REPORT.lua","a+")
-- if not reportFilehandle then
  -- print(H.gcERROR.."       > [ERROR] MISSING REPORT.lua filehandle, no REPORT.lua will be produced! "..H._zDEFAULT)
-- end

--***************************************************************************************************
  -- the output order is: msgType..msg..Info
  -- msgType default is (0 spaces)[INFO], otherwise it is (4 spaces)[msgType]
        -- [INFO] is currently ""
  -- Info will appear inside [], any space before the first letter is transferred to front of the []
  -- msg will appear without change  
function H.Report(Info,msg,msgType)
  --if Info == nil then return end
  if (Info == nil or Info == "") and msg == nil then
    msgType = "" --to force a blank line to output
  end
  if Info == nil then Info = "" end --will ouput a \n
  if msg == nil then msg = "" end

  if msgType == nil then
--    msgType = "[INFO] "
    msgType = ""
  elseif msgType ~= "" then
    local pre = "    ["
    local suf = "] "
    if msgType == "BUG" or msgType == "ERROR" or msgType == "WARNING" or msgType == "NOTICE" then
      pre = "   [["
      suf = "]] "    
    elseif msgType == "CONFLICT" then
      pre = "  [["
      suf = "]] "    
    end
    msgType = pre..msgType..suf
  end
  
  -- local FileName = ""
  -- if gReport_ext then
    -- FileName = "-"..gReport_ext
  -- end
  
  local chain = "" --derived from Info
  local say = "" --final complete message
  local typeInfo = type(Info)
  if typeInfo == "table" then
    for z=1,#Info do
      chain = chain..Info[z]..[[, ]]
    end		
  elseif typeInfo == "string" then
    chain = Info
  elseif typeInfo == "boolean" then
    if Info then
      chain = "true"
    else
      chain = "false"
    end
  else
    chain = "???"
    say = "ERROR: in Report(): type(Info) is "..typeInfo
    print(say)
  end
  if chain ~= "" then
    local spacer = string.match(chain,"^%s*")
    if spacer == nil then spacer = "" end
    chain = " "..spacer.."["..H.trim(chain).."]"
  end
  -- if msg ~= "" then
    -- msg = " "..msg
  -- end
  say = msgType..msg..chain
  -- print("***** "..say.." *****")

  -- if H.gfilePATH == "..\\" and FileName == "" then
    -- -- this is the standard REPORT.lua file
    -- if gReportFilehandle == nil then
      -- gReportFilehandle = io.open(H.gfilePATH.."REPORT"..FileName..".txt","a+")
    -- end
    
    -- gReportFilehandle:write([[.]]..say.."\n")
    -- -- gReportFilehandle:flush()
    
  -- else

  --if FileName == "" then
    gReportTable[#gReportTable+1] = say
  -- elseif reportFilehandle then
    -- -- H.WriteToFileAppend(say.."\n", H.gfilePATH.."REPORT"..FileName..".lua")
    -- reportFilehandle:write(say.."\n")
  -- end
  -- end
end

--***************************************************************************************************
function H.Report_flush(keepOpen,this)
  --H.WriteToFileAppend(table.concat(gReportTable, "\n").."\n", H.gfilePATH.."REPORT.lua")
  
  -- print("Report_flush() called by "..this)
  
  if not reportFilehandle then
    reportFilehandle = io.open(H.gfilePATH.."REPORT.lua","a+")
    if not reportFilehandle then
      print(H.gcERROR.."       > [ERROR] MISSING REPORT.lua filehandle, no REPORT.lua will be produced! "..H._zDEFAULT)
    end
  end

  if reportFilehandle then
    reportFilehandle:write(table.concat(gReportTable, "\n").."\n")
    reportFilehandle:flush()
 
    if keepOpen then
      gReportTable = {}
    else
      -- print("Closing Report.lua handle")
      reportFilehandle:close()
    end
  end
end

--***************************************************************************************************
-- block: an EXML (long) string
-- x: # of spaces to indent each line
-- returns: block
-- NOT USED
function H.AddSpaces(block,x)
  return strgsub(block,"<",string.rep(" ",x).."<")
end

--***************************************************************************************************
function H.ShowTime(Time)
  return os.date("%H:%M:%S",Time)
end

--***************************************************************************************************
function H.TestNoNil(Info,...)
  local FoundNoNil = true
  local args = { n = select("#", ...), ... }
  for i=1,args.n do
    if args[i] == nil then
      FoundNoNil = false
      -- print("BUG: "..Info..", arg["..i.."] is nil")
      break
    end
  end
  return FoundNoNil
end

--***************************************************************************************************
-- NOT USED
function H.boolToString(Bool)
  local s = "false"
  if Bool then s = "true" end
  return s
end

--***************************************************************************************************
function H.sleep(s)
  -- s==2 =>> 1 second delay
	if s==nil then s=1 end
  s = math.tointeger(s+1)
  --localhost was 127.0.0.1
  local command = [[PING -n ]]..s..[[ localhost>nul]]
	--H.NewThread(command)
	os.execute(command)
end

--***************************************************************************************************
-- NOT USED
function H.pause()
  io.stdin:flush()
  print("Press Enter to continue...")
  io.stdin:read([[l]]) -- was *l
end

--***************************************************************************************************
-- NOT USED
function H.UpdateTimes(location)
  if location == nil then location = "" end
  local updateTime = os.time()
  H.WriteToFileAppend(updateTime.." "..location,[[Times.txt]])
end

--***************************************************************************************************
function H.ShowElapsedTime(msg,startTime)
  print(string.format(msg.." >>> %.2f sec",(os.clock() - startTime)))
end

--***************************************************************************************************
function H.LocateAnyFileInPAK(pathname)
  -- H.pv("In H.LocateAnyFileInPAK()")
  local Pak_FileName = ""
  if pathname == nil or pathname == "" then
    return Pak_FileName
  end
  
  local filename = H.NormalizePath(pathname)
  -- H.pv("["..filename.."]")
  
  if #H.gfullpak_listTable == 0 then
    H.gfullpak_listTable = H.ParseTextFileIntoTable("Full_pak_list.txt")
  end
  
  local fullpak_listTable = H.gfullpak_listTable
  -- H.pv(#pak_listTable.." lines")
  local found = false
  for i=1,#fullpak_listTable,1 do
		local line = fullpak_listTable[i]
		if line then
      if strfind(line,"Listing ",1,true) then
        local start,stop = strfind(line,"Listing ",1,true)
        --remember Pak_FileName for when we find the filename
        Pak_FileName = strsub(line, stop+1)
        -- H.pv("["..Pak_FileName.."]")
      else
        if strfind(line,filename,1,true) then
          found = true
          break
        end
      end
		end
	end
  if found then
    return Pak_FileName
  else
    return ""
  end
end

--***************************************************************************************************
-- fills H.gFastMainFolderList table
--  creates a fast lookup
--  to determine if the folder anme is a NMS Main folder
do -- ALWAYS EXECUTED
  local MainFolders = H.ParseTextFileIntoTable("NMSMainFolders.txt")
  for i=1,#MainFolders do
    H.gFastMainFolderList[MainFolders[i]] = true
  end
end

--***************************************************************************************************
-- fills H.gFastPAKlist table
--  creates a fast PAKlist lookup
--  to locate PAKname of any .MBIN file
do -- ALWAYS EXECUTED
  if #H.gpak_listTable == 0 then
    -- load up table gpak_listTable
    local cDir = lfs.currentdir()..[[\]]
    if not string.find(cDir,[[MODBUILDER]]) then
      cDir = cDir..[[MODBUILDER\]]
    end
    H.gpak_listTable = H.ParseTextFileIntoTable(cDir.."pak_list.txt")
    -- H.gpak_listTable,msg = H.ParseTextFileIntoTable(cDir.."pak_list.txt")
    -- print("msg = "..msg)
  end
  -- print("       #H.gpak_listTable = ["..tostring(#H.gpak_listTable).."]")

  -- re-create table gFastPAKlist
  local NMSPAKname = ""
  for i=1,#H.gpak_listTable do
    local line = H.gpak_listTable[i]
    if line and line ~= " " then
      if strfind(line,"Listing ",1,true) then
        local start,stop = strfind(line,"Listing ",1,true)
        NMSPAKname = strsub(line, stop+1)
      else
        -- local file = strgsub(strsub(line,1,strfind(line," (",1,true)-1),[[/]],[[\]])
        -- local file = strgsub(strsub(line,1,strfind(line," ",1,true)-1),[[/]],[[\]])
        local file = strgsub(line,[[/]],[[\]])
        H.gFastPAKlist[file] = NMSPAKname
      end
    else
      NMSPAKname = ""
    end
  end
end

--***************************************************************************************************
-- locate any .MBIN file in NMS PAKs
function H.LocatePAK(filename)
  filename = strgsub(filename,[[%.MXML]],[[.MBIN]])
  filename = strgsub(filename,[[\]],[[/]])
  -- H.pv("["..filename.."]")
  
  local Pak_FileName = H.gFastPAKlist[filename]
  
  if Pak_FileName == nil then
    if #H.gpak_listTable == 0 then
      H.gpak_listTable = H.ParseTextFileIntoTable("pak_list.txt")
    end
    local pak_listTable = H.gpak_listTable
    
    -- H.pv(#pak_listTable.." lines")
    for i=1,#pak_listTable,1 do
      local line = pak_listTable[i]
      if line then
        if strfind(line,"Listing ",1,true) then
          local start,stop = strfind(line,"Listing ",1,true)
          --remember Pak_FileName for when we find the filename
          Pak_FileName = strsub(line, stop+1)
          -- H.pv("["..Pak_FileName.."]")
        else
          if strfind(line,filename,1,true) then
            break
          end
        end
      end
    end
  end

  if Pak_FileName then
    H.WriteToFileAppend("\n"..Pak_FileName.."\n", "MOD_PAK_SOURCE.txt")
  end
  
  return Pak_FileName
end

--***************************************************************************************************  
-- NOT USED
do -- function LocateMOD_PAK_SOURCE(file)
  -- local TempMBIN = strgsub(file,[[\]],[[/]])
  
  -- local Pak_FileName = H.gFastPAKlist[TempMBIN]
  -- local found = false
  
  -- --LookAt_MOD_PAK_SOURCE_content("- DDDDD before finding source")

  -- if Pak_FileName == nil then
    -- if #H.gpak_listTable == 0 then
      -- H.gpak_listTable = H.ParseTextFileIntoTable("pak_list.txt")
    -- end
    -- local pak_listTable = H.gpak_listTable
    
    -- -- print("TempMBIN = "..TempMBIN)
    -- -- print("pak_list.txt = "..#pak_listTable)
    -- for i=1,#pak_listTable,1 do
      -- local line = pak_listTable[i]
      -- if line then
        -- if strfind(line,"Listing ",1,true) then
          -- local start,stop = strfind(line,"Listing ",1,true)
          -- Pak_FileName = strsub(line, stop+1)
          -- -- print("["..Pak_FileName.."]")
        -- elseif strfind(line,TempMBIN,1,true) then
          -- found = true
          -- --added "\n".. as a work around for strange bug
          -- --without, the entries would not be on separate lines all the time
          -- H.WriteToFileAppend("\n"..Pak_FileName.."\n", "MOD_PAK_SOURCE.txt")
          -- break
        -- end
      -- end
    -- end
  -- else
    -- found = true
    -- --added "\n".. as a work around for strange bug
    -- --without, the entries would not be on separate lines all the time
    -- H.WriteToFileAppend("\n"..Pak_FileName.."\n", "MOD_PAK_SOURCE.txt")
  -- end
  -- --LookAt_MOD_PAK_SOURCE_content("- CCCCC after finding source")
  -- return found,Pak_FileName
-- end
end

--***************************************************************************************************
-- make all extensions into .MBIN
-- handle adding GLOBALS\ sub-folder
function H.MXML_PC_EXMLtoMBIN(s)
  -- printf("s = [%s]",s)
  local tmp = H.NormalizePath(s):gsub(".MXML$",".MBIN"):gsub(".MBIN.PC$",".MBIN"):gsub(".EXML$",".MBIN")
  if strfind(tmp,"[\\/]") == nil then
    -- adjust for missing GLOBALS sub-folder
    tmp = [[GLOBALS\]]..tmp
  end
  -- printf("tmp = [%s]",tmp)
  return tmp
end
--***************************************************************************************************

--***************************************************************************************************  
function H.GetMBINCompilerVersion(EXEpathname)
  local cmd = EXEpathname..[[ version -q]]
  local sV = os.capture(cmd,false)
  -- print("MBINCompiler sV_0 = "..tostring(sV))
  -- sV = "Active code page: 65001\r\n5.2.0.2"
  -- print("this "..strmatch(sV,"^.-\r\n(.+)"))
  if strfind(sV,"^Active code page:") then
    sV = strmatch(sV,"^.-%c+(.+)")
    -- print("MBINCompiler sV_1 = "..tostring(sV))
  end
  
  local version = strgsub(sV,"%.",",",1) --1st . to ,
  version = strgsub(version,"%.","") --all . to ""
  version = strgsub(version,",",".",1) --, to .
  local nV = tonumber(version)
  -- print("MBINCompiler nV_0 = "..tostring(nV))
  return sV,nV
end

--***************************************************************************************************  
-- parses GCMODSETTINGS.MXML
function H.GetModsSettings()
  local ModSettingsXML = H.ParseTextFileIntoTable(H.MODSETTINGS_PATH)

  -- print("=== GCMODSETTINGS.MXML content")
  -- for i=1,#ModSettingsXML do
    -- H.printf("%s",ModSettingsXML[i])
  -- end
  -- H.WFAK()
  -- print("=== END: GCMODSETTINGS.MXML content")

  local j = 0
  repeat
    j = j + 1
    if ModSettingsXML[j] == nil then break end
  until string.find(ModSettingsXML[j],[[Data]],1,true)

  local ModSettings = {}
  local ModGeneralSettings = {}

  -- For reference: H.GetPropertyNameValue()
  --   p, v as 'Property name=', 'value='
  --   p, nil as 'Property name=', nil
  --   nil, v as nil, 'Property value='
  --   nil, nil if not found

  local IsModSection = false
  local ModName = ""
  while j < #ModSettingsXML do
    j = j + 1
-- H.printf("ModSettingsXML[j] = [%s]",tostring(ModSettingsXML[j]))
    local p,v = H.GetPropertyNameValue(ModSettingsXML[j])
-- H.printf("   p = [%s], v = [%s]",tostring(p),tostring(v))
    if p ~= nil then
      if v ~= nil and p ~= "Data" and IsModSection then
        local v = H.CharEntitiesReverse(v)
-- H.printf("A: %d: p = [%s], v = [%s]",j,tostring(p),tostring(v))
        if p == "Name" and ModSettings[v] == nil then
          -- print("A0:")
          ModSettings[v] = {}
          ModName = v
        end
        
        if Modname ~= "" then
          -- print("A1:")
          ModSettings[ModName][p] = v
        end
      end
      if not IsModSection then
        if p == "Data" and v ~= nil then
          -- print("B0:")
          -- next line is inside a MOD section
          IsModSection = true
          -- print("IsModSection = true")
        elseif p ~= nil and v ~= nil then
          -- print("B1:")
          -- a standalone field
          ModGeneralSettings[p] = v
        end
      end
    else
      IsModSection = false -- reset
      -- print("A: IsModSection = false")
    end
  end
  -- H.WFAK()

  -- print(" = = = = = = =")
  -- for k,v in pairs(ModSettings) do
    -- H.printf("k = [%s], v = [%s]",tostring(k),tostring(v))
    -- if type(v) == "table" then
      -- for k,v in pairs(v) do
        -- H.printf("    k = [%s], v = [%s]",tostring(k),tostring(v))
      -- end
    -- end
  -- end
  -- H.WFAK()
  
  return ModSettings, ModGeneralSettings
end

--***************************************************************************************************  
--action = Compile
  -- sourcePath = where the EXML files are relative to MODBUILDER
  -- IsWithThreads = bool optional, 
--
--returns: string: success
function H.MBINCompiler_C(sourcePath,IsWithThreads)
  if IsWithThreads == nil then IsWithThreads = true end
  local threadInfo = "(multi-thread)"
  local withThreads = ""
  if not IsWithThreads then
    withThreads = "--no-threads"
    threadInfo = "(single-thread, due to MBINCompiler buggy log in multi-thread)"
  end
  
  local success = ""

  --clear .log
  local cmd = [[del MBINCompiler.log 1>NUL 2>NUL]]
  os.execute(cmd)

  local start = os.clock()
  print(H._zBRIGHTGREEN.."     @@@ creating MBIN files "..threadInfo.."..."..H._zDEFAULT)
  local cmd = [[MBINCompiler.exe -q -y -f -iMXML --exclude=";LocTable.MXML;" ]]..withThreads..[[ "]]..sourcePath --..[["]]
  -- local cmd = [[MBINCompiler.exe -y -f -iMXML --exclude=";" ]]..withThreads..[[ "]]..sourcePath --..[["]]

  local state,str,num = os.execute(cmd) --fast and same output as batch
-- H.WFAK("Inspect log...")  
  local delta = os.clock() - start
  print(H._zBRIGHTGREEN.."      - done in "..H.dClock(delta)..H._zDEFAULT)
  
  if state then
    success = "OK"
  else
    -- print("@@@ MBINCompiler returned: "..str..", "..tostring(num))
    success = "ERROR"
  end

  return success
end

--***************************************************************************************************  
--action = Decompile
  -- sourcePath = where the MBIN files are relative to MODBUILDER
  -- IsHideVersionInfo = bool optional, Hide version info in EXML header
  -- IsStream = bool optional, streams output instead of creating a file
  -- IsSilent = bool optional, adds -q flag 
  -- msg = string message to display
--returns: string: all the EXML files decompiled
function H.MBINCompiler_D(sourcePath, IsHideVersionInfo, IsStream, IsSilent, msg, IsTyped)
  local success = ""
  local result = ""

  --clear .log
  local cmd = [[del MBINCompiler.log 1>NUL 2>NUL]]
  os.execute(cmd)

  local sHideVersionInfo = ""
  if ISHideVersionInfo == nil then IsHideVersionInfo = false end
  if IsHideVersionInfo then
    sHideVersionInfo = " --no-version"
  end
  
  local sStream = " "
  if IsStream == nil then IsStream = false end
  if IsStream then
    sStream = " --stream"
  end
  
  local sTyped = ""
  _,H.nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
  if H.nV >= H.gMBINCompilerVersionTyped then
    if IsTyped == nil then IsTyped = false end
    if IsTyped then
      sTyped = " --typed"
    end
  end
  
  local sSilent = ""
  if IsSilent == nil then IsSilent = false end
  if IsSilent then
    sSilent = [[ -q]]
  end
  
  if not msg then
    print("     @@@ decompiling...")
  else
    print(msg)
  end
  local cmd = [[MBINCompiler.exe -y -f -iMBIN]]..sSilent..sHideVersionInfo..sStream..sTyped..[[ --exclude=";" "]]..sourcePath --..[["]]
  -- H.printf("cmd = [%s]",cmd)

  --Capture the output sent to cmd window
  result = os.capture(cmd,true)
-- H.WFAK("Inspect log...")  
  -- H.printf("result = [%s]",result)
  if IsSilent or (result and result ~= "") then
    success = "OK"
  end
  
  return success,result
end

--***************************************************************************************************
-- pakNamePath: .pak path and filename
-- returns: a string: pakType
function H.GetPakType(pakNamePath)
  local HGPAK = "HGPA"
  local PSARC = "PSAR"
  local ZIP = "PK"..string.char(0x03,0x04) -- "PK♥♦" 0x504b0304
  local _7z = "7z"..string.char(0xbc,0xaf) -- "7zbcaf271c" 0x377ABCAF 271C

  local pakType = ""
  local filehandle = io.open(pakNamePath,"rb")
  if filehandle then
    local header = filehandle:read(4)
    if header == HGPAK then
      pakType = "HGPAK"
    elseif header == PSARC then
      pakType = "PSARC"
    elseif header == ZIP then
      pakType = "ZIP"
    elseif header == _7z then
      pakType = "7Z"
    end
    filehandle:close()
   end
  return pakType
end

--***************************************************************************************************  
--action = CREATE (only works with psarc.exe), LIST (works with psarc.exe, HGPAKTool.exe and 7z.exe)
--  CREATE >>> works from MODBUILDER\MOD folder
  --  local pakDestPathFromMOD = [[..\..\ModBackups\BuildHistory\IncrementalBuilds]] --no ending \
  --  local pakFilename = [[Test_PSARC.pak]] --%_cFilename%(%_ca%).pak%_cMOD_AUTHOR%
--  LIST >>> works everywhere
  --  local pakDestPathFromMOD = [[..\..\ModBackups\BuildHistory\IncrementalBuilds]] --no ending \
  --  local pakFilename = [[Test_PSARC.pak]] --%_cFilename%(%_ca%).pak%_cMOD_AUTHOR%
-- IsCompress = true (default)
-- silent = false (default), if true: no feedback
function H.psarc_CL(action,pakDestPathFromMOD,pakFilename,IsCompress,silent)
  local success = ""
  local result = ""
  
  action = strupper(action)
  if action == "CREATE" then -- Creates psarc paks
    local compress = ""
    if not IsCompress then
      compress = "-N"
    end
    
    if silent == nil then silent = false end
    
    if silent then
      -- if pakType == "PSARC" then 
        -- print("@@@ psarc creating pak...")
      -- end
      silent = [[ 1>NUL 2>NUL]]
    else
      silent = ""
    end
    
    -- lfs.chdir([[.\MOD]]) --into MODBUILDER\MOD
    lfs.chdir([[..\CreatedMODS]]) -- out of MODBUILDER into CreatedMODS
    
    --used to strip this path from the pak files (only if 'input.txt' have it)
    --may not be required since ListDir() below does not include it
    local _STRIP_PATTERN = lfs.currentdir()
    _STRIP_PATTERN = strsub(_STRIP_PATTERN,4) -- remove C:\
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[\]],[[/]]) --change \ to /
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%(]],[[\(]]) --escape (
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%)]],[[\)]]) --escape )
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%+]],[[\+]]) --escape +

    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%$]],[[\$]]) --escape $
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%^]],[[\^]]) --escape ^
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%[]],[[\[]]) --escape [
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,"%]","\\]") --escape ]
    _STRIP_PATTERN = strgsub(_STRIP_PATTERN,[[%{]],[[\{]]) --escape {
    -- print(" === ".._STRIP_PATTERN)

    --create input.txt: list of all files to pak from MOD folder
    local fileList = {}
    fileList = H.ListDir(fileList,[[.]],false,true)

    local modName = pakFilename:gsub(H.GetExtensionFromFilePath(pakFilename),"")
    -- H.printf("modName = [%s]",modName)
    for i=#fileList,1,-1 do
      if strfind(fileList[i],modName,1,true) ~= nil then
        -- H.printf(" - [%s]",fileList[i])
      else
        table.remove(fileList,i)
      end
    end

    if #fileList > 0 then
      local tmp = {}
      for i=1,#fileList do
        if not strfind(fileList[i],".MXML",1,true) or strfind(fileList[i]:upper(),"LOCTABLE.MXML",1,true) then
          --when other than .MXML or LocTable.MXML, retain the info
          --remove '.\'
          tmp[#tmp+1] = strsub(fileList[i],3)
        end
      end
      
      fileList = tmp
      
      if #fileList == 0 then
        print("@@@ No file to pak: tmp")
        success = "NoFileToPak"
      else      
        -- OLD STYLE USING psarc.exe
        local sFileList = H.ConvertLineTableToText(fileList)
        
        local _input = [[..\MODBUILDER\input.txt]] --to be used by psarc.exe
        H.WriteToFile(sFileList,_input)

        --local cmd = [[psarc.exe create --overwrite --skip-missing-files --strip="%_STRIP_PATTERN%" --inputfile=..\input.txt --output="%_cDestination%\%_cFilename%(%_ca%).pak%_cMOD_AUTHOR%"]]
        local cmd = [[..\MODBUILDER\psarc.exe create ]]..compress..[[ --overwrite --skip-missing-files --strip="]].._STRIP_PATTERN..[[" --inputfile=]].._input..[[ --output="]]..pakDestPathFromMOD..[[\]]..pakFilename..[["]]..silent
        local state,str,num = os.execute(cmd) --fast and same output as batch
        if state then
          success = "OK"
        else
          -- print("@@@ psarc returned: "..str..", "..tostring(num))
          success = "psarcError"
        end
      end
    else
      print("@@@ No file to pak: fileList")
      success = "NoFileToPak"
    end
    
    -- lfs.chdir([[..\]]) --back to MODBUILDER    
    lfs.chdir([[..\MODBUILDER]]) -- out of CreatedMODS into MODBUILDER

  elseif action == "LIST" then
    local pakType = H.GetPakType(pakDestPathFromMOD..[[\]]..pakFilename)
    H.printf("psarc_CL LIST: pakType = [%s]",pakType)
    
    H.DeleteFile("PAK_FILE_CONTENT.txt",false,true)
    
    local cmd = ""
    if pakType == "PSARC" then
      -- Listing ..\TEST PAKS\\___TEST 02 ext_func_(2).pak
      -- 02 ext_func processing.lua (405/643 62%)
      -- AMUMSS.v5.0.0.0W.txt (0/0 100%)
      -- METADATA/REALITY/CATALOGUECRAFTING.MBIN (1702/7560 22%)

      H.printf("PSARC pakType = [%s]",pakType)    
      if pakFilename == "" then
        cmd = [[psarc.exe list "]]..pakDestPathFromMOD..[[" >"PAK_FILE_CONTENT.txt"]]
      else
        cmd = [[psarc.exe list "]]..pakDestPathFromMOD..[[\]]..pakFilename..[[" >"PAK_FILE_CONTENT.txt"]]
      end
      H.printf("cmd = [%s]",cmd)    
      -- result = os.capture(cmd)
      result = os.execute(cmd)
      if result and result ~= "" then
        success = "OK"
      end
          
    elseif pakType == "HGPAK" then
      H.printf("HGPAK pakType = [%s]",pakType)
      -- says 'in console': Listing ==> the name of the pak
      -- output in "PAK_FILE_CONTENT.txt"
      -- NO FURTHER PROCESSING NEEDED
      
      -- Listing NMSARC.globals.pak
      -- GLOBALS/GCAISPACESHIPGLOBALS.GLOBAL.MBIN
      -- GLOBALS/GCUIGLOBALS.GLOBAL.MBIN
      -- ...
      -- GLOBALS/GCVEHICLEGLOBALS.GLOBAL.MBIN
      -- GLOBALS/PRECACHE.TXT
      -- GLOBALS/SHADERPRELOADEXPORT.CSV

      if pakFilename == "" then
        cmd = [[hgpaktool.exe --upper -L -p -O"PAK_FILE_CONTENT.txt" "]]..pakDestPathFromMOD..[["]]
      else
        cmd = [[hgpaktool.exe --upper -L -p -O"PAK_FILE_CONTENT.txt" "]]..pakDestPathFromMOD..[[\]]..pakFilename..[["]]
      end
      H.printf("cmd = [%s]",cmd)    
      -- result = os.capture(cmd)
      result = os.execute(cmd)
      if result and result ~= "" then
        success = "OK"
      end
          
    elseif pakType == "ZIP" or pakType == "7Z" then
      -- 7-Zip 24.09 (x64) : Copyright (c) 1999-2024 Igor Pavlov : 2024-11-29

      -- Scanning the drive for archives:
      -- 1 file, 5483 bytes (6 KiB)

      -- Listing archive: ..\TEST PAKS\\___TEST 02 ext_func_(2).zip -- OR .7z

      -- --
      -- Path = ..\TEST PAKS\\___TEST 02 ext_func_(2).zip
      -- Type = zip
      -- Physical Size = 5483

         -- Date      Time    Attr         Size   Compressed  Name
      -- ------------------- ----- ------------ ------------  ------------------------
      -- 2025-01-21 21:02:08 D....            0            0  MOD
      -- 2025-01-21 21:02:05 ....A          643          398  MOD\02 ext_func processing.lua
      -- 2025-01-21 21:02:08 ....A            0            0  MOD\AMUMSS.v5.0.0.0W.txt
      -- 2025-01-21 21:02:08 D....            0            0  MOD\METADATA
      -- 2025-01-21 21:02:08 D...A            0            0  MOD\METADATA\REALITY
      -- 2025-01-21 21:02:08 ....A         7560         1660  MOD\METADATA\REALITY\CATALOGUECRAFTING.MBIN
      -- 2025-01-21 21:02:08 ....A        25261         2263  MOD\METADATA\REALITY\CATALOGUECRAFTING.MXML
      -- ------------------- ----- ------------ ------------  ------------------------
      -- 2025-01-21 21:02:08              33464         4321  4 files, 3 folders

      H.printf("ZIP-7Z pakType = [%s]",pakType)    
      if pakFilename == "" then
        cmd = [[7z.exe l "]]..pakDestPathFromMOD..[[\*" >"PAK_FILE_CONTENT.txt"]]
      else
        cmd = [[7z.exe l "]]..pakDestPathFromMOD..[[\]]..pakFilename..[[" >"PAK_FILE_CONTENT.txt"]]
      end
      H.printf("cmd = [%s]",cmd)    
      -- result = os.capture(cmd)
      result = os.execute(cmd)
      if result and result ~= "" then
        success = "OK"
      end
      -- we need to process the result
      result = H.ParseTextFileIntoTable("PAK_FILE_CONTENT.txt")
      local r = {}
      local i = 1
      while i < #result do
        local pos = strfind(result[i],"Name$")
        if pos then
          i = i + 2
          while strfind(result[i],"---",1,true) ~= 1 do
            r[#r+1] = strsub(result[i],pos)
            i = i + 1
          end
          break
        end
        i = i + 1
      end
      result = table.concat(r,"\n")
    end

  else
    print("@@@ Bad action: ["..action.."]")
  end
  return success, result
end

--***************************************************************************************************  
--only action = EXTRACT 'one' source file from pakName pak
--  EXTRACT >>> works everywhere
  --  pakPath = where the pak is, like H.gMASTER_FOLDER_PATH --with ending \
  --  pakName = the name of the pak to EXTRACT from: like [[Test_PSARC.pak]] --%_cFilename%(%_ca%).pak%_cMOD_AUTHOR%
  --  destPath = where to send the EXTRACTed file(s): like [[..\..\ModBackups\BuildHistory\IncrementalBuilds]] --no ending \
  --  source = the 'path and filename' of the exact file to EXTRACT || empty if EXTRACT ALL
  --  options = (default = overwrite)
  --  IsSilent = true, output goes to NUL
  --  BUG: always outputs 'psarc error: Could not find 0 in archive!', even when successful: use IsSilent = true
function H.psarc_E(pakPath,pakName,destPath,source,options,IsSilent)
  --this is EXTRACT
  
  --%%~nxG = filename.ext
  --%%A = NMS path + filename.ext
  --from user mod, no '/': ..\psarc.exe extract "..\..\ModScript\%%~nxG" --to="..\..\ModScript\EXTRACTED_PAK" -y "%%A" 1>NUL 2>NUL
  --from user mod, w/ '/': ..\psarc.exe extract "..\..\ModScript\%%~nxG" --to="..\..\ModScript\EXTRACTED_PAK" -y "/%%A" 1>NUL 2>NUL
  
  -- %%H = PCBANK file name
  --from NMS PCBANKS: ..\psarc.exe extract "%_gNMS_PCBANKS_FOLDER%%%H" "%1" --to="!CD!\EXTRACTED" -y 1>NUL 2>NUL
  
  if source ~= "" then
    source = [["]]..source..[["]]
  end
  
  if options == nil or options == "" then
    options = "-y"
  end
  
  local silent = ""
  if IsSilent then
    silent = [[ 1>NUL 2>NUL]]
  end
  
  local success = ""
  
  local pakType = H.GetPakType(pakPath..pakName)
  
  local cmd = ""
  if pakType == "PSARC" then
    --extract (--input=FILE || the first file argument) (--to=DIRECTORY || 'default' current directory) source(the exact name to extract)
    cmd = [[psarc.exe extract "]]..pakPath..pakName..[[" --to="]]..destPath..[[" ]]..source..[[ ]]..options..silent
  elseif pakType == "HGPAK" then
    cmd = [[hgpaktool.exe -U --upper -A -O "]]..destPath..[[" -f ]]..source..[[ "]]..pakPath..pakName..[[" ]]
  elseif pakType == "ZIP" then
    -- cmd = [[hgpaktool.exe -U --upper -O "]]..destPath..[[" -f ]]..source..[[ "]]..pakPath..pakName..[[" ]]
  elseif pakType == "7z" then
    -- cmd = [[hgpaktool.exe -U --upper -O "]]..destPath..[[" -f ]]..source..[[ "]]..pakPath..pakName..[[" ]]
  end
  -- print("@@@ EXTRACT: cmd = ["..cmd.."]")
  local state,sResult,nResult = os.execute(cmd)
  -- print("@@@ EXTRACT: result = ["..string.format("%s, %s (%d)",state,sResult,nResult).."]")
  
  if state then
    success = "OK"
  else
    -- print("@@@ psarc returned: "..str..", "..tostring(num))
    success = "psarcError"
  end
  return success
end

--***************************************************************************************************  
-- NOT USED
--only action = EXTRACT pak files using input.txt list
--  EXTRACT >>> works everywhere
  --  pakPath = where the paks are, like H.gMASTER_FOLDER_PATH --with ending \
  --  pakName = the name of the pak to EXTRACT from: like [[Test_PSARC.pak]] --%_cFilename%(%_ca%).pak%_cMOD_AUTHOR%
  --  destPath = where to send the EXTRACTed file(s): like [[..\..\ModBackups\BuildHistory\IncrementalBuilds]] --no ending \
  --  source = the input.txt file

function H.psarc_E_EXT(pakPath,pakName,destPath,source)
  --this is EXTRACT using input.txt list
  
  --%%~nxG = filename.ext
  --%%A = NMS path + filename.ext
  --from user mod, no '/': ..\psarc.exe extract "..\..\ModScript\%%~nxG" --to="..\..\ModScript\EXTRACTED_PAK" -y "%%A" 1>NUL 2>NUL
  --from user mod, w/ '/': ..\psarc.exe extract "..\..\ModScript\%%~nxG" --to="..\..\ModScript\EXTRACTED_PAK" -y "/%%A" 1>NUL 2>NUL
  
  -- %%H = PCBANK file name
  --from NMS PCBANKS: ..\psarc.exe extract "%_gNMS_PCBANKS_FOLDER%%%H" "%1" --to="!CD!\EXTRACTED" -y 1>NUL 2>NUL
  

        -- 'start creating Explorer_psarc_xml
        -- file.WriteLine("<psarc>")

        -- Dim PakName As String = ""
        -- For Each item As ListViewItem In itemCollection
            -- Dim currentPAk = item.SubItems(0).Text
            -- Dim currentFile = item.SubItems(1).Text

            -- If currentFile.Contains(".MBIN") Then
                -- Debug.WriteLine(currentPAk + ": " + currentFile)

                -- If Not String.Equals(PakName, currentPAk) Then
                    -- If Not String.Equals(PakName, "") Then
                        -- 'close section
                        -- file.WriteLine("  </extract>")
                    -- End If
                    -- 'start of new section
                    -- PakName = currentPAk
                    -- 'use true NOT True
                    -- file.WriteLine("  <extract archive=""" + NMS_PCBANKS_path + "\" + currentPAk + """ to=""" + ResultsEXML_path + """ overwrite=""true"" >")
                -- End If
                -- 'use true NOT True
                -- file.WriteLine("    <file archivepath=""" + currentFile + """ skipifmissing=""true"" />")
            -- End If
        -- Next

        -- file.WriteLine("  </extract>")
        -- file.WriteLine("</psarc>")
        -- 'end creating Explorer_psarc_xml

        -- REM pass xml list to psarc.exe
        -- Dim command As String

        -- 'command = "cmd /k """ + pak_listFileName_path + "MODBUILDER\psarc.exe""" + " --help"
        -- command = "cmd /c """ + pak_listFileName_path + "MODBUILDER\psarc.exe""" + " --xml=" + Explorer_psarc_xml
        -- Debug.WriteLine(command)

        -- 'we have to wait for psarc.exe to do its job here
        -- Dim id As Integer = Shell(command, AppWinStyle.NormalFocus, True)


-- <psarc>
	-- <extract archive="???" to="???" stripall="true/false" skipmissingfiles="true/false" overwrite="true/false">
		-- <file archivepath="???" skipifmissing="false" />
	-- </extract>
-- </psarc>

-- <psarc>
	-- <extract archive="C:\psarctests\source files\test.psarc" to="C:\psarctests\by_file" stripall="true" skipmissingfiles="false" overwrite="true">
		-- <file archivepath="dummy.txt" skipifmissing="true" />
		-- <file archivepath="PNGfolder1/PNGfolder2/PNGfolder3/Image3.png" />
	-- </extract>
-- </psarc>

-- psarc.exe --xml="c:\psarctests\EXTRACT_by_file.xml"

  if source ~= "" then
    source = [["]]..source..[["]]
  end
  
  local success = ""
  
  --extract (--input=FILE || the first file argument) (--to=DIRECTORY || 'default' current directory) source(the exact name to extract)
  local cmd = [[psarc.exe extract "]]..pakPath..pakName..[[" --to="]]..destPath..[[" ]]..source..[[ -y]]
  print("@@@ EXTRACT: cmd = ["..cmd.."]")
  local state,sResult,nResult = os.execute(cmd)
  print("@@@ EXTRACT: result = ["..string.format("%s, %s (%d)",state,sResult,nResult).."]")
  
  if state then
    success = "OK"
  else
    -- print("@@@ psarc returned: "..str..", "..tostring(num))
    success = "psarcError"
  end
  
  return success
end

-- Only used by H.IsEXMLtoBeSaved()
H.SAVE_ON = {
  VALUE_CHANGE_TABLE = true,
  VCT = true, -- alias
  ADD = true,
  REMOVE = true,
  SEC_ADD_NAMED = true,
  SEC_PASTE = true, -- alias
  CREATE_HOS = true,
  REGEXAFTER = true,
}

-- Only used by H.IsEXMLtoBeSaved()
H.SAVE_OFF = {
  SEC_EDIT = true,
  MBIN_FS_DISCARD = true,
}

--***************************************************************************************************
-- thanks @lyravega
-- EXML_CT in one of the sub-tables in a MBIN_CT
-- returns true if one of the command appears in SAVE_ON
--              AND commands in SAVE_OFF are not present
function H.IsEXMLtoBeSaved(EXML_CT)
  local IsTBS = true
  for _, EXML_CT_SUB in next, EXML_CT do
    for k in next, EXML_CT_SUB do
      -- H.printf("   %s",k)
      if H.SAVE_ON[k] then
        -- H.printf("      %s -> ON",k)
        IsTBS = true -- found ON in this sub
        
        for m in next, EXML_CT_SUB do
          if H.SAVE_OFF[m] then
            -- H.printf("      %s -> OFF",m)
            IsTBS = false -- found OFF in this sub
            break
          end
        end
        
        if not IsTBS then
          break -- skip this SUB, goto next
        else
          -- print("      EXIT on found a SUB that says SAVE! -> true")  
          return true -- we found one SUB that says SAVE!
        end
      end
    end
  end
  -- case: no EXML_CT_SUB
  -- H.printf("      EXIT on last SUB or empty -> %s",tostring(IsTBS))  
  return IsTBS
end

--***************************************************************************************************
function H.GetEnvInfo()
  local AMUMSSVer = H.LoadFileData("AMUMSSVersion.txt")
  local MBINCompilerVer = H.LoadFileData("MBINCompilerCurrentVersion.txt")
  local NMSVerId = H.LoadFileData("NMS_versionId.txt")
  local PublicExp = "P"
  if not H.IsFileExist([[VersionPublic.txt]]) then
    PublicExp = "E"
  end
  
  return { ["AMUMSSVer"]=AMUMSSVer , ["NMSVerId"]=NMSVerId ,["MBINCompilerVer"]=MBINCompilerVer ,["PublicExp"]=PublicExp ,}
end

--***************************************************************************************************
-- ONLY USED in DEBUGGING
function H.CheckTables(msg,IsNilEmpty)
  msg = H.gcNOTICE..msg..H._zDEFAULT
  
  if H.EXMLorgTable then
    print(msg.." = = = = = EXMLorgTable")
    local orgCount = 0
    for k,v in pairs(H.EXMLorgTable) do
      orgCount = orgCount + 1
      if IsNilEmpty then
        if #v == 0 or v[1] == nil or v[1] == "REMOVE" then
          H.printf(" - [%s] = ["..H._zYELLOW.."%s"..H._zDEFAULT.."] (%d)",k,string.sub(tostring(v[1]),1,150),#v)
        end
      else
        H.printf(" - [%s] = ["..H._zYELLOW.."%s"..H._zDEFAULT.."] (%d)",k,string.sub(tostring(v[1]),1,150),#v)
      end
    end
    print(" END: "..msg.." = = = = = "..orgCount)
  else
    print(msg.." = = = = = EXMLorgTable is NIL")
  end
  
  if H.EXMLmodTable then
    print(msg.." = = = = = EXMLmodTable")
    local modCount = 0
    for k,v in pairs(H.EXMLmodTable) do
      modCount = modCount + 1
      if IsNilEmpty then
        if #v == 0 or v[1] == nil or v[1] == "REMOVE" then
          H.printf(" - [%s] = ["..H._zYELLOW.."%s"..H._zDEFAULT.."] (%d)",k,string.sub(tostring(v[1]),1,150),#v)
        end
      else
        H.printf(" - [%s] = ["..H._zYELLOW.."%s"..H._zDEFAULT.."] (%d)",k,string.sub(tostring(v[1]),1,150),#v)
      end
    end
    print(" END: "..msg.." = = = = = "..modCount)
  else
    print(msg.." = = = = = EXMLmodTable is NIL")
  end
  
  if orgCount ~= modCount then
    H.printf(msg.."                                     ++++++ #EXMLorgTable ~= #EXMLmodTable (%d<->%d)",orgCount,modCount)
    assert(orgCount == modCount,"ERROR, stop")
  end

end

--***************************************************************************************************
function H.GetTopOfMXML(t)
  --skipping a few lines at Top
  local Top = 0
  repeat
    Top = Top + 1
  until string.find(t[Top],[[te=]],1,true)
  
  if Top == #t then
    print(" ==> Missing 'Data template'")
  end
  -- Top points to Data template
  return Top
end

--***************************************************************************************************
function H.GetBottomOfMXML(t)
  -- check bottom
  local Bottom = #t + 1
  repeat
    Bottom = Bottom - 1
  until string.find(t[Bottom],[[</Data>]],1,true)
  return Bottom
end

--***************************************************************************************************
-- returns: Boolean, True if sections a equal
-- returns: Boolena, True if section is using 'linked='
function H.IsSectionsEqual(mod, sectionMod, org, sectionOrg) -- , IsTestLinked
-- for i=sectionMod[1],sectionMod[2] do
  -- H.printf(" - %s",tostring(mod[i]))
-- end
-- H.WFAK("Z: ")
  local cleanMod = {}
  for i=sectionMod[1],sectionMod[2] do
    if H.trim(mod[i]:gsub("<!.->","")) ~= "" then
      -- always removed empty lines and comment lines
      -- before comparing
      cleanMod[#cleanMod+1] = mod[i]
    end
  end
  local m = table.concat(cleanMod)
      -- WARNING: this can be very heavy on OS file creation
      -- H.WriteToFile(m,saveTo..[[MOD_]]..sectionMod[1].."-"..sectionMod[2]..[[.EXML]])
  local o = table.concat(org,"",sectionOrg[1],sectionOrg[2])
      -- WARNING: this can be very heavy on OS file creation
      -- H.WriteToFile(o,saveTo..[[ORG]]..sectionOrg[1].."-"..sectionOrg[2]..[[.EXML]])
  
  -- to compare sections on the same basis
  --   Mod file could be missing OR NOT 'linked="xyz"' (depends on how the modder did the script)
  return m:gsub([[ linked=".-"]],"") == o:gsub([[ linked=".-"]],"")
end

--***************************************************************************************************
-- TextFileTable: a table of the file to search
-- lineInSection: a line number in the section
-- FirstLineOfSection: (optional) the line number of the 1st line of the section
-- return: integer, 1st line of the section
function H.GoUPToOwnerStart(TextFileTable,lineInSection,FirstLineOfSection)
  local level = 0
  local OwnerStartLine = 0
  for i=lineInSection-1,1,-1 do
    local Orgline = TextFileTable[i]
    if string.find(Orgline,[[/>]],1,true) then
      --skip this line, never an owner
    else
      if string.find(Orgline,[[">]],1,true) then
        level = level - 1
        if level == -1 then
          --owner start line found
          OwnerStartLine = i
          break
        end
      elseif string.find(Orgline,[[</P]],1,true) then
        --always the end of a group
        level = level + 1
      end
    end
  end
  if FirstLineOfSection and OwnerStartLine < FirstLineOfSection then
    OwnerStartLine = FirstLineOfSection
  end
  return OwnerStartLine
end

--***************************************************************************************************
-- TextFileTable: a table of the file to search
-- lineInSection: a line number in the section
-- LastLineOfSection: (optional) the line number of the last line of the section
-- return: integer, the last line of the section
function H.GoDownToOwnerEnd(TextFileTable,lineInSection,LastLineOfSection)
  local level = 0
  local OwnerEndLine = 0
  -- H.pv("      D.lineInSection = "..lineInSection)
  for i=lineInSection,#TextFileTable do
    local Orgline = TextFileTable[i]
    if string.find(Orgline,[[/>]],1,true) then
      --skip this line, never an owner
    else
      if string.find(Orgline,[[</P]],1,true) then
        --always the end of a group
        level = level - 1
        if level == -1 then
          --owner end line found
          OwnerEndLine = i
          break
        end
      elseif string.find(Orgline,[[">]],1,true) then
        level = level + 1
      end
    end
  end
  if LastLineOfSection and OwnerEndLine > LastLineOfSection then
    OwnerEndLine = LastLineOfSection
  end
  if OwnerEndLine == 0 then OwnerEndLine = #TextFileTable end
  return OwnerEndLine
end

--***************************************************************************************************
-- pathfilename of file to check if OK to EXMLize
-- returns: boolean true if OK
function H.IsEXMLType(s)
  local badTypes = {
    "%.ANIM%.",
    "%.DESCRIPTOR%.",
    "%.GEOMETRY%.",
    "%.MATERIAL%.",
    "%.PARTICLE%.",
    "%.SCENE%.",
    [[^UI\]],
    [[^%.\MOD\UI\]],
    [[^MOD\\UI\]],
    -- "%.TEXTURE%.", -- for test only
  }
  for i=1,#badTypes do
    -- H.printf("%s %s %s",s,badTypes[i],tostring(strmatch(s,badTypes[i])))
    if strmatch(s,badTypes[i]) then
      return false
    end
  end
  return true
end
--***************************************************************************************************
            
--***************************************************************************************************
function H.GetSavePath(filepath,destinationFolder)
  local destinationFolder = destinationFolder or "."
  
  local filename = ""
  
  local MainFolders = H.ParseTextFileIntoTable("NMSMainFolders.txt")
  if #MainFolders > 0 then
    -- extract relative file path
    local extraPath = ""
    for j=1,#MainFolders do
      local pos = string.find(filepath,[[\]]..MainFolders[j],1,true)
      if pos then
        extraPath = string.sub(filepath,1,pos - 1)..[[\]]
        break
      end
    end
    
    if extraPath == "" then
      -- could be a global
      filename = H.GetFilenameFromFilePath(filepath)
    else
      filename = string.sub(filepath,#extraPath + 1)
    end
  else
    -- this should not happen, handled by calling app console
    print("MISSING MainFolders List!")
  end
  -- H.printf("       filename = [%s]",filename)
  
  return destinationFolder..[[\]]..string.gsub(filename,[[%.MXML]],[[.EXML]])
end

--***************************************************************************************************
-- s: string to be corrected for proper _overwrite="true" format
-- returns corrected string
function H.CheckOverwriteFormat(s)
  -- possible ways: _overwrite="xxx", _overwrite="" or _overwrite
  local overwrite = [[_overwrite="true"]]
  if strfind(s,overwrite,1,true) then
    return s
  end
  if strmatch(s,[[_overwrite=".-"]]) then
    return strgsub(s,[[_overwrite=".-"]], overwrite)
  else
    return strgsub(s,[[_overwrite]], overwrite)
  end
end
    
-- =============================
                                    H.DEBUG_EXML = false
                                    H.DEBUG_EXML_WAIT = false
                                    H.DEBUG_WAITatEND = false
-- =============================

--***************************************************************************************************
-- MXML_org, MXML_mod = table
-- scrubLevel = integer, max level to perform the scrubbing
-- returns:
--  MXML_org, MXML_mod after scrubbing
function H.ScrubMXMLs(MXML_org, MXML_mod, scrubLevel)
  local IsDebugWriteToFile = H.DEBUG_EXML -- DEBUG
  local IsDebugAnalyzeXML = H.DEBUG_EXML -- DEBUG
  local saveTo = [[..\TOOLS\EXML_Testing\]]

  -- H.printf(" Scrub level = %d",scrubLevel)

  --***************************************************************************************************
  local function GetLevels(MXML,scrubLevel)
    local t = {}
    local ti = {}
    local sections = {}
    local parents = {} -- so we target the right sections on duplicate name/value lines

    local level = 0
    
    for i=1,#MXML do
      local parent
      local mxmlText
      -- local extraKey = 0
      
      local s = MXML[i]

      if H.trim(s) ~= "" and not strmatch(s,"^%s*<[!?]") then -- skip lines that start with a comment / are empty
        if strfind(s,[[</]],1,true) then
          -- </Property> and </Data>
          level = level - 1
          -- H.printf(" At %d, lower level to %d",i,level)

          if level < scrubLevel then
            -- remove last entry
            -- H.printf(" At %d, remove last parent [%s]",i,parents[#parents])
            table.remove(parents)
          end

        else
          if strfind(s,[[/>]],1,true) == nil then
            -- ALL lines ending in "> (NOT ending in />)
            level = level + 1
            
            -- if parent == nil then
              -- parents[#parents+1] = s
            -- end
            
            if level <= scrubLevel then
              -- H.printf(" At %d, processing [%s]",i,s)
              -- get current parents
              parent = table.concat(parents, "|", 2) -- we start with the 2nd one,1st parent is always the same
              -- H.printf(" At %d,   parent = [%s]",i,parent)
              
              -- add this parent for next sub-sections
              parents[#parents+1] = s
              
              if parent ~= "" then
                mxmlText = parent.."|"..s
              else
                mxmlText = s
              end
              -- H.printf(" At %d, mxmlText = [%s]",i,mxmlText)
              
              if t[mxmlText] then
                -- a "Duplicate Key" --> create a new key
                -- printfALT("DUPLICATE: [%s]",mxmlText)
                local extraKey = 0
                repeat
                  extraKey = extraKey + 1
                until t[mxmlText.."_"..extraKey] == nil
                mxmlText = mxmlText.."_"..extraKey
              end
              
              t[mxmlText] = "A"
              ti[#ti+1] = mxmlText
              sections[mxmlText] = {i, H.GoDownToOwnerEnd(MXML, i + 1, #MXML - 1)}
              -- printfALT("[%s] %4d-%-4d >>%4d: [%s]",t[ti[#ti]],sections[ti[#ti]][1],sections[ti[#ti]][2], i,ti[#ti])
              -- H.printf("[%s] %4d-%-4d >>%4d: [%s]",t[ti[#ti]],sections[ti[#ti]][1],sections[ti[#ti]][2], i,ti[#ti])
            
            end -- if level < scrubLevel then
          end -- if strfind(s,[[/>]],1,true) == nil then
        end -- if strfind(s,[[</]],1,true) then
      end -- if not strmatch(s,[[^%s*<!]]) then -- skip comments
    end    
    return t, ti, sections
  end
  --***************************************************************************************************

  -- stripOrgD: not used
  local stripOrgD, stripOrgI, sectionsOrgD = GetLevels(MXML_org, scrubLevel)

  -- if IsDebugWriteToFile then H.WriteToFile(cOrg,saveTo..[[clonedORG.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFileDictionary(stripOrgD,saveTo..[[S1_Scrub_stripOrgD.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFile(stripOrgI,saveTo..[[S1_Scrub_stripOrgI.EXML]]) end
  -- WFAK("WAITING: 0: ")

        if IsDebugAnalyzeXML then
          local savePath = saveTo..[[S1_clonedORG_1.EXML]]
          path = strgsub(savePath,[[%.EXML]],[[.Scrub_stripOrgD.EXML]])
          local tmp = {}
          for i=1,#stripOrgI do
            tmp[#tmp+1] = stripOrgI[i].." --> "..sectionsOrgD[stripOrgI[i]][1].."-"..sectionsOrgD[stripOrgI[i]][2]
          end
          H.WriteToFile(tmp,path)
        end
  if IsDebugWriteToFile then
    print("\n==> S1_ saved")
  end

  -- stripModI: not used
  local stripModD, stripModI, sectionsModD = GetLevels(MXML_mod, scrubLevel)

  -- if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[clonedMod.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFileDictionary(stripModD,saveTo..[[S2_Scrub_stripModD.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFile(stripModI,saveTo..[[S2_Scrub_stripModI.EXML]]) end
  -- WFAK("WAITING: 0: ")

        if IsDebugAnalyzeXML then
          local savePath = saveTo..[[S2_clonedMod_1.EXML]]
          path = strgsub(savePath,[[%.EXML]],[[.Scrub_stripModD.EXML]])
          local tmp = {}
          for i=1,#stripModI do
            tmp[#tmp+1] = stripModI[i].." --> "..sectionsModD[stripModI[i]][1].."-"..sectionsModD[stripModI[i]][2]
          end
          H.WriteToFile(tmp,path)
        end
  if IsDebugWriteToFile then
    print("\n==> S2_ saved")
  end
  
  -- mark lines for removal when sections are equal
  local IsSomeRemoved = false
  -- for k in pairs(stripOrgD) do
  for i=1,#stripOrgI do
    local k = stripOrgI[i]
    if stripModD[k] then
      -- Org parent also exists in Mod
      -- let us compare the 2 sections
      if H.IsSectionsEqual(MXML_mod, sectionsModD[k], MXML_org, sectionsOrgD[k]) then
        -- these 2 sections are identical, we can remove them from both Org and Mod
        -- H.printf("==> Section [%s] equal in both Org and Mod, marking to remove in both",k)
        IsSomeRemoved = true
        for i=sectionsModD[k][1],sectionsModD[k][2] do
          MXML_mod[i] = "r"
        end
        for i=sectionsOrgD[k][1],sectionsOrgD[k][2] do
          MXML_org[i] = "r"
        end
      end
    end
  end
  -- END: mark lines for removal when sections are equal
  
  -- remove lines and correct for HOES: turn them into HOS with nothing in the section
  local cOrg_scrubbed = {}
  for i=1,#MXML_org do
    if MXML_org[i] ~= "r" then
      local s = MXML_org[i]
      if strfind(s,[[/>]],1,true) and strfind(s,[[ue=]],1,true) == nil then
        -- change the line ending
        s = strgsub(s,[["%s-/>]],[[">]])
        -- printfALT_2("%4d: s = [%s]",i,s)
        cOrg_scrubbed[#cOrg_scrubbed + 1] = s

        local spacesBefore, stuffAfterEnding = strmatch(s,[[^(%s-)<.-">(.*)]]) -- or ""
        -- printfALT_2("  stuffAfterEnding = [%s]",stuffAfterEnding)
        -- insert </Property> with spaces on the next line
        cOrg_scrubbed[#cOrg_scrubbed + 1] = spacesBefore..[[</Property>]]..stuffAfterEnding
      else
        cOrg_scrubbed[#cOrg_scrubbed + 1] = s
      end      
    end
  end
  
  local cMod_scrubbed = {}
  for i=1,#MXML_mod do
    if MXML_mod[i] ~= "r" then
      local s = MXML_mod[i]
      if strfind(s,[[/>]],1,true) and strfind(s,[[ue=]],1,true) == nil then
        -- change the line ending
        s = strgsub(s,[["%s-/>]],[[">]])
        -- printfALT_2("%4d: s = [%s]",i,s)
        cMod_scrubbed[#cMod_scrubbed + 1] = s

        local spacesBefore, stuffAfterEnding = strmatch(s,[[^(%s-)<.-">(.*)]]) -- or ""
        -- printfALT_2("  stuffAfterEnding = [%s]",stuffAfterEnding)
        -- insert </Property> with spaces on the next line
        cMod_scrubbed[#cMod_scrubbed + 1] = spacesBefore..[[</Property>]]..stuffAfterEnding
      else
        cMod_scrubbed[#cMod_scrubbed + 1] = s
      end      
    end
  end
  -- END: remove lines and correct for HOES: turn them into HOS with nothing in the section
  
  return cOrg_scrubbed, cMod_scrubbed, IsSomeRemoved
end

--***************************************************************************************************
-- creates a top-bottom only barebone XML file
-- debugInfo = string
-- IsStripFlagOverwrite = true (to strip _overwrite)
-- IsShowDebugInfo = optional, true (to show debugInfo)
-- returns:
--   t: the barebone Dict table, parents as key
--   ti: array of parents in t
--   sections: Dict table of top-bottom line numbers of each HOS/HOES section
function H.AnalyzeXML(debugInfo, XMLtable, top, IsStripFlagOverwrite, IsShowDebugInfo)
  local DEBUG = H.DEBUG_EXML
  local IsDebugInfo = (#XMLtable > 200000) or false
  local IsReporting = false
  
  local printfALT
  local printfALT_2
  local WFAK

  if DEBUG then
    printfALT = H.printf
    printfALT_2 = H.printf
  else
    -- when NOT DEBUGGING
    printfALT = function() end
    printfALT_2 = function() end
  end
  
  if H.DEBUG_EXML_WAIT then
    WFAK = H.WFAK
  else
    WFAK = function() end
  end
  
  printALT = print
  
  local IsStripFlagOverwrite = IsStripFlagOverwrite or false

  local t = {}
  local ti = {}
  local sections = {}
  local parents = {} -- so we target the right sections on duplicate name/value lines
  
  if IsShowDebugInfo == false then
    IsDebugInfo = false
  end
  
  if IsDebugInfo then
    print(H.gcNOTICE..">>>>> AnalyzeXML "..debugInfo.." <<<<<"..H._zDEFAULT)
  end

  XMLtable = H.AutoAdjustIndentation(XMLtable,XMLtable,1)
  
  local count = 0
  local previousTime
  local IsTimeToShowInfo = false
  local tt = os.clock()
  
  for i=top,#XMLtable do
    local parent
    local mxmlText
    
    if previousTime == nil then
      previousTime = os.clock()
    end
    
    if i%1000 == 0 then
      collectgarbage("collect")
    end
    
    if IsReporting and i%10000 == 0 then
      H.printf("- %8d %s (count = %d) #parents = %d",i,H.dClock(os.clock() - previousTime),count,#parents)
      -- for j=1,#parents do
        -- print("    - ["..parents[j].."]")
      -- end

      -- H.printf("%d bytes",collectgarbage("count")*1024)
      -- collectgarbage("collect")
      -- H.printf("%d bytes",collectgarbage("count")*1024)

      previousTime = os.clock()
      IsTimeToShowInfo = true
    end
    
    local s = strgsub(strgsub(XMLtable[i],H.modCHANGED,""),H.modADDED,"")
    
    if H.trim(s) ~= "" and not strmatch(s,"^%s*<[!?]") then -- skip lines that start with a comment / are empty
      if strfind(s,[[</]],1,true) then
        -- </Property> and </Data>
        -- remove last entry
        table.remove(parents)
        
      else
        if IsStripFlagOverwrite then
          s = strgsub(s,[[ _overwrite="true"]],"")
        end
        
        if strfind(s,[[/>]],1,true) == nil then
          -- ALL lines NOT ending in />
          -- get current parents
          parent = table.concat(parents, "|", 2) -- we start with the 2nd one,1st parent is always the same
-- if IsTimeToShowInfo then
  -- H.printf("parent = [%s]",parent)
-- end

          -- add this parent for next sub-sections
          parents[#parents+1] = s
          
          if parent ~= "" then
            mxmlText = parent.."|"..s
          else
            mxmlText = s
          end
          
    -- if IsTimeToShowInfo then
      -- H.printf("J0: t[mxmlText] = %s in %s",tostring(t[mxmlText]),H.dClock(os.clock() - tt))
    -- end
    
          if t[mxmlText] then
            -- a "Duplicate Key" --> create a new kwy
            -- printfALT("DUPLICATE: [%s]",mxmlText)
            local extraKey = 0
            repeat
              extraKey = extraKey + 1
            until t[mxmlText.."_"..extraKey] == nil
            mxmlText = mxmlText.."_"..extraKey
    -- if IsTimeToShowInfo then
      -- print("J1: "..H.dClock(os.clock() - tt))
    -- end
          end
          
          count = count + 1
          t[mxmlText] = "A_analyze"
          ti[#ti+1] = mxmlText
          sections[mxmlText] = {i, H.GoDownToOwnerEnd(XMLtable, i + 1, #XMLtable - 1)}
    -- if IsTimeToShowInfo then
      -- print("J2: "..H.dClock(os.clock() - tt))
      -- tt = os.clock()
      -- IsTimeToShowInfo = false
    -- end
          -- printfALT("[%s] %4d-%-4d >>%4d: [%s]",t[ti[#ti]],sections[ti[#ti]][1],sections[ti[#ti]][2], i,ti[#ti])
          -- H.printf("[%s] %4d-%-4d >>%4d: [%s]",t[ti[#ti]],sections[ti[#ti]][1],sections[ti[#ti]][2], i,ti[#ti])
          
        else -- if strfind(s,[[/>]],1,true) then
          -- ALL lines ending in />
          if strmatch(s:upper(),[[ _I]]) then
            -- and having _id/_index: THIS is a value of a ListOfValues
            -- get current parents
            parent = table.concat(parents, "|", 2) -- we start with the 2nd one,1st parent is always the same

            if parent ~= "" then
              mxmlText = parent.."|"..s
            else
              mxmlText = s
            end
            
    -- if IsTimeToShowInfo then
      -- H.printf("K0: t[mxmlText] = %s in %s",tostring(t[mxmlText]),H.dClock(os.clock() - tt))
    -- end

            if t[mxmlText] then
              -- a "Duplicate Key" --> create a new kwy
              -- printfALT("DUPLICATE: [%s]",mxmlText)
              local extraKey = 0
              repeat
                extraKey = extraKey + 1
              until t[mxmlText.."_"..extraKey] == nil
              mxmlText = mxmlText.."_"..extraKey
    -- if IsTimeToShowInfo then
      -- print("K1: "..H.dClock(os.clock() - tt))
    -- end
            end

            count = count + 1
            t[mxmlText] = "B_analyze"
            ti[#ti+1] = mxmlText
            sections[mxmlText] = {i, i}
    -- if IsTimeToShowInfo then
      -- print("K2: "..H.dClock(os.clock() - tt))
      -- tt = os.clock()
      -- IsTimeToShowInfo = false
    -- end
            -- printfALT("[%s] %4d-%-4d >>%4d: [%s]",t[ti[#ti]],sections[ti[#ti]][1],sections[ti[#ti]][2], i,ti[#ti])
          
          end
        end
      end
    end -- if not strmatch(s,[[^%s*<!]]) then -- skip comments
  end -- for i=top,#XMLtable do    

  return t, ti, sections, XMLtable
end

--***************************************************************************************************
-- returns: the EXML table of the MXML table
--          IsValidExml == true if EXML is valid
function H.MXMLtoEXML(MXMLmod, MXMLorg) -- , IsFileUsingLinked NOT USED
  local DEBUG = H.DEBUG_EXML
  
  local fileSize = 200000
  local CheckTimings = (#MXMLmod > fileSize) or DEBUG
  
  local prf
  local printfALT
  local printALT = print
  local WFAK
  
  local saveTo = [[..\TOOLS\EXML_Testing\]]

  local A0, A1, B0, B1, C0 = "", "", "", "", ""               
  if DEBUG then
    print("LoadHelper v"..H.LH_Version)
    A0 = " ==> A0"
    A1 = " ==> A1"
    B0 = " ==> B0"
    B1 = " ==> B1"
    C0 = " ==> C0"
  end
  
  if DEBUG then
    CheckTimings = true
    prf = H.printf
    printfALT = H.printf
    printALT = print
  else
    -- when NOT DEBUGGING
    prf = function() end
    printALT = function() end

    printfALT = function() end
  end
  local IsDebugAnalyzeXML = true -- DEBUG
  local IsDebugWriteToFile = true -- DEBUG
  
  if H.DEBUG_EXML_WAIT then
    WFAK = H.WFAK
  else
    WFAK = function() end
  end
  
  if CheckTimings then
    printALT = print
  end
  
  local printALTspacer = "      "
  
  -- ==============================  
  local function sortTableAsc(a,b)
    return a[1] < b[1]
  end

  -- ==============================  
  local function sortTableDesc(a,b)
    return a[1] > b[1]
  end

  -- ==============================  
  local function sortTableDescEXT(a,b)
    -- H.printf("   * a[1] = %4d, b[1] = %4d ==> a[1] > b[1] == %s",a[1],b[1],tostring(a[1] > b[1]))
    if a[1] == b[1] then
      return a[2] > b[2]
    else
      return a[1] > b[1]
    end
  end

  -- ==============================  
  -- tC is receiving the KEEP flag
  local function SetKeepFlag(k,tD,tC,keep)
    if tD[k] then -- because it could be nil if the section does not exist
      for i=tD[k][1],tD[k][2] do
        if not strmatch(tC[i],keep) then
          tC[i] = tC[i]..keep
        end
      end
    end
  end

  -- ==============================  
  local function CheckStructure(exml,msg)
    -- Check if exml is structurally valid
    local msg = msg or ""
    local exmlString = table.concat(exml,"\n")
    local _,numHOS = strgsub(exmlString,[[">]],[[">]],-1)
    local _,numProperty = strgsub(exmlString,[[</Pro]],[[</Pro]],-1)
    local IsValidExml = true
    if numHOS - 1 ~= numProperty then -- exclude <Data...>
      H.printf(H.gcWARNING..[[>>> [WARNING] created EXML is invalid: #HOS (%d ~= %d) #/Property %s]]..H._zDEFAULT,numHOS - 1 ,numProperty,msg)
      IsValidExml = false
    end
    return IsValidExml
  end
    
  -- MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  
  local start = os.clock()
  local endTime = start
  local finalize = os.clock()
  
  local largeFile = ""
  if #MXMLmod > fileSize then
    largeFile = " LARGE file, be patient"
  end
  print(printALTspacer..H._zBRIGHTORANGE.."Processing"..largeFile.."... "..H._zDEFAULT)
  
  -- ==============================  
  local cOrg = H.cloneArray(MXMLorg)
  local cMod = H.cloneArray(MXMLmod)
  
  if IsDebugWriteToFile then H.WriteToFile(cOrg,saveTo..[[0_cOrg.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[0_cMod.EXML]]) end

  local clone = os.clock()
  printALT("          in "..H.dClock(clone - start).." --> CLONE cOrg ("..#cOrg.." lines) and cMod ("..#cMod.." lines) "..H._zDEFAULT)
  
  local cOrg_scrubbed
  local cMod_scrubbed
  local IsSomeRemoved
  
  -- COULD add a 2nd pass for nothing, and with a LARGE file that means longer time MAYBE
  -- local level = 1
  -- repeat
    -- level = level + 1
    -- cOrg_scrubbed, cMod_scrubbed, IsSomeRemoved = H.ScrubMXMLs(cOrg, cMod, level) -- was level 2
    -- cOrg = cOrg_scrubbed
    -- cMod = cMod_scrubbed
  -- until not IsSomeRemoved
  local scrubLevel = 3 -- was level 2
  cOrg_scrubbed, cMod_scrubbed, IsSomeRemoved = H.ScrubMXMLs(cOrg, cMod, scrubLevel)
  cOrg = cOrg_scrubbed
  cMod = cMod_scrubbed

  local IsValidExml = CheckStructure(cOrg,"at A:")
  local IsValidExml = CheckStructure(cMod,"at B:")
  
  if IsDebugWriteToFile then H.WriteToFile(cOrg_scrubbed,saveTo..[[1_cOrg_scrubbed.EXML]]) end
  if IsDebugWriteToFile then H.WriteToFile(cMod_scrubbed,saveTo..[[1_cMod_scrubbed.EXML]]) end
  if DEBUG then
    print("\n==> 1_ saved")
  end
  
  local scrub = os.clock()
  printALT("          in "..H.dClock(scrub - clone).." --> SCRUB cOrg ("..#cOrg_scrubbed.." lines) and cMod ("..#cMod_scrubbed.." lines) with HOES expanded (some removed = "..tostring(IsSomeRemoved)..")"..H._zDEFAULT)
  
-- H.WFAK()
  
  local IsOkToProcess = false

  -- if what is left of cOrg is only empty sections, then we have nothing more to do: cMod IS the EXMl
  local IsOrgEmpty = true
  for i=1,#cOrg do
    local s = cOrg[i]
    if H.trim(s) ~= "" and not strmatch(s,"^%s*<[!?]") then
      if strfind(s,"/>",1,true) then
        IsOrgEmpty = false
        break
      end
    end
  end
  
  local exml = {}
  
  if not IsOrgEmpty then
    local TopOrg = H.GetTopOfMXML(cOrg)
    local stripOrgD, stripOrgI, sectionsOrgD, cOrg = H.AnalyzeXML("with #1 ORG with linked (if present)",cOrg,TopOrg)
    
    if DEBUG then
      H.printf("        #cOrg = %d",H.GetTableCount(cOrg))
      H.printf("   #stripOrgD = %d",H.GetTableCount(stripOrgD))
      H.printf("   #stripOrgI = %d",H.GetTableCount(stripOrgI))
      H.printf("#sectionsOrgD = %d",H.GetTableCount(sectionsOrgD))
    end

    if IsDebugWriteToFile then H.WriteToFile(cOrg,saveTo..[[2_clonedORG.EXML]]) end
    if IsDebugWriteToFile then H.WriteToFileDictionary(stripOrgD,saveTo..[[2_stripOrgD.EXML]]) end
    if IsDebugWriteToFile then H.WriteToFile(stripOrgI,saveTo..[[2_stripOrgI.EXML]]) end
    -- WFAK("WAITING: 0: ")

          if IsDebugAnalyzeXML then
            -- printfALT("   TopOrg = %d",TopOrg)
            local savePath = saveTo..[[2_clonedORG_1.EXML]]
            path = strgsub(savePath,[[%.EXML]],[[.stripOrgD.EXML]])
            local tmp = {}
            for i=1,#stripOrgI do
              tmp[#tmp+1] = stripOrgI[i].." --> "..sectionsOrgD[stripOrgI[i]][1].."-"..sectionsOrgD[stripOrgI[i]][2]
            end
            H.WriteToFile(tmp,path)
          end
  if DEBUG then
    print("\n==> 2_ saved")
  end
    
    local step_cORG = os.clock()
    printALT(printALTspacer..H._zBRIGHTORANGE.."Step V0"..H._zDEFAULT.." in "..H.dClock(step_cORG - scrub).." --> cOrg AnalyzeXML")

    -- ==============================  
    -- for cMod only: correct for possible bad _overwrite formating in the script
    for i=1,#cMod do
      local s = cMod[i]
      if strmatch(s:upper(),[[ _I]]) then
        -- only when detecting _id/_index, otherwise _overwrite comes last
        if strfind(s,"[ _]overwrite") then
          cMod[i] = H.CheckOverwriteFormat(s)
        end
      end
    end

    local checkOverwrite_cMod = os.clock()
    printALT("          in "..H.dClock(checkOverwrite_cMod - step_cORG).." --> check overwrite format "..H._zDEFAULT)
    
    local TopMod = H.GetTopOfMXML(cMod)
    local stripModD, stripModI, sectionsModD, cMod = H.AnalyzeXML("with #1 MOD WITH _overwrite and linked",cMod,TopMod,false)

    if DEBUG then
      H.printf("        #cMod = %d",H.GetTableCount(cMod))
      H.printf("   #stripModD = %d",H.GetTableCount(stripModD))
      H.printf("   #stripModI = %d",H.GetTableCount(stripModI))
      H.printf("#sectionsModD = %d",H.GetTableCount(sectionsModD))
    end

    if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[3_clonedMOD.EXML]]) end
    if IsDebugWriteToFile then H.WriteToFileDictionary(stripModD,saveTo..[[3_stripModD.EXML]]) end
    if IsDebugWriteToFile then H.WriteToFile(stripModI,saveTo..[[3_stripModI.EXML]]) end
    -- WFAK("WAITING: 1: ")

          if IsDebugAnalyzeXML then
            -- printfALT("   TopMod = %d",TopMod)
            local savePath = saveTo..[[3_clonedMOD_1.EXML]]

            local path = strgsub(savePath,[[%.EXML]],[[.stripModD.EXML]])
            local tmp = {}
            for i=1,#stripModI do
              tmp[#tmp+1] = stripModI[i].." --> "..sectionsModD[stripModI[i]][1].."-"..sectionsModD[stripModI[i]][2]
            end
            H.WriteToFile(tmp,path)
          end
  if DEBUG then
    print("\n==> 3_ saved")
  end
      
    local IsValidExml = CheckStructure(cOrg,"at C:")
    local IsValidExml = CheckStructure(cMod,"at D:")
    
    local step_cMOD = os.clock()
    printALT(printALTspacer..H._zBRIGHTORANGE.."Step V1"..H._zDEFAULT.." in "..H.dClock(step_cMOD - checkOverwrite_cMod).." --> cMod AnalyzeXML WITH _overwrite")

    -- ==============================  
    -- compare full files
    IsOkToProcess = true
    printfALT("                      MOD %d-%d <=> %d-%d ORG",sectionsModD[stripModI[1]][1],sectionsModD[stripModI[1]][2], sectionsOrgD[stripOrgI[1]][1],sectionsOrgD[stripOrgI[1]][2])
    if H.IsSectionsEqual(cMod, sectionsModD[stripModI[1]], cOrg, sectionsOrgD[stripOrgI[1]]) then
      print("==> Files are identical, no need to make an EXML FROM this MXML file")
      H.Report("","==> Files are identical, no need to make an EXML FROM this MXML file")
      IsOkToProcess = false
    else
      printfALT(" >>>>>  NOT identical  <<<<< %s","")
    end
    
    local step2 = os.clock()
    printALT(printALTspacer..H._zBRIGHTORANGE.."Step V2"..H._zDEFAULT.." in "..H.dClock(step2 - step_cMOD).." --> checking if MOD and ORG are identical")
    -- WFAK("WAITING: A: ")

    -- ==============================  
    if IsOkToProcess then
      printALT("       ==> OK to create EXML... ")
      
      -- look for _overwrite OR linked= sections: these sections NEED to be KEPT
      -- <Property name="Table" value="GcPurchaseableSpecial" _id="BANNER_PEEP" _overwrite="true" />
      local IsKeepFlagAdded = false
      for i=1,#stripModI do
        local k = stripModI[i]
        if strmatch(k," _overwrite") or strmatch(k,[[ linked="]]) then
          -- set the KEEP flag
          
          -- printfALT(H.gcNOTICE.." [NOTICE]"..H._zDEFAULT.." Section %d-%d of MOD has been marked '# KEEP' for _overwrite/linked=",sectionsModD[k][1],sectionsModD[k][2])
          
          -- this section is marked with _overwrite in MOD by the script or it is a linked= section
          SetKeepFlag(k, sectionsModD, cMod, H.modKEEP)

          -- strip _overwrite from ORG because ORG does not have _overwrite
          --     linked= is not a problem because both ORG and MOD have linked=
          SetKeepFlag(k:gsub([[ _overwrite="true"]],""), sectionsOrgD, cOrg, H.modKEEP)
          
          IsKeepFlagAdded = true
        end
      end
      
      local IsValidExml = CheckStructure(cOrg,"at E:")
      local IsValidExml = CheckStructure(cMod,"at F:")
      
      if IsKeepFlagAdded then
        -- redo the tables
        TopMod = H.GetTopOfMXML(cMod)
        stripModD, stripModI, sectionsModD, cMod = H.AnalyzeXML("with #2 MOD WITH KEEP + linked minus _overwrite",cMod,TopMod,true)
        
        if DEBUG then
          H.printf("        #cMod = %d",H.GetTableCount(cMod))
          H.printf("   #stripModD = %d",H.GetTableCount(stripModD))
          H.printf("   #stripModI = %d",H.GetTableCount(stripModI))
          H.printf("#sectionsModD = %d",H.GetTableCount(sectionsModD))
        end
        
        printfALT("==> cMod: AnalyzeXML redone WITH KEEP + linked minus _overwrite %s","")

        if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[4_KeepMod.EXML]]) end
        if IsDebugWriteToFile then H.WriteToFileDictionary(stripModD,saveTo..[[4_KeepModD.EXML]]) end
        if IsDebugWriteToFile then H.WriteToFile(stripModI,saveTo..[[4_KeepModI.EXML]]) end
        -- WFAK("WAITING: 0: ")

              if IsDebugAnalyzeXML then
                -- printfALT("   TopMod = %d",TopMod)
                local savePath = saveTo..[[4_KeepMod.EXML]]
                path = strgsub(savePath,[[%.EXML]],[[.KeepModD.EXML]])
                local tmp = {}
                for i=1,#stripModI do
                  tmp[#tmp+1] = stripModI[i].." --> "..sectionsModD[stripModI[i]][1].."-"..sectionsModD[stripModI[i]][2]
                end
                H.WriteToFile(tmp,path)
              end
        if DEBUG then
          print("\n==> 4_ saved")
        end
        
        TopOrg = H.GetTopOfMXML(cOrg)
        stripOrgD, stripOrgI, sectionsOrgD, cOrg = H.AnalyzeXML("with #2 ORG WITH KEEP + linked",cOrg,TopOrg)

        if DEBUG then
          H.printf("        #cOrg = %d",H.GetTableCount(cOrg))
          H.printf("   #stripOrgD = %d",H.GetTableCount(stripOrgD))
          H.printf("   #stripOrgI = %d",H.GetTableCount(stripOrgI))
          H.printf("#sectionsOrgD = %d",H.GetTableCount(sectionsOrgD))
        end

        printfALT("==> cOrg: AnalyzeXML redone after KEEP flag added%s","")

        if IsDebugWriteToFile then H.WriteToFile(cOrg,saveTo..[[5_KeepORG.EXML]]) end
        if IsDebugWriteToFile then H.WriteToFileDictionary(stripOrgD,saveTo..[[5_KeepOrgD.EXML]]) end
        if IsDebugWriteToFile then H.WriteToFile(stripOrgI,saveTo..[[5_KeepOrgI.EXML]]) end
        -- WFAK("WAITING: 0: ")

              if IsDebugAnalyzeXML then
                -- printfALT("   TopOrg = %d",TopOrg)
                local savePath = saveTo..[[5_KeepORG.EXML]]
                path = strgsub(savePath,[[%.EXML]],[[.KeepOrgD.EXML]])
                local tmp = {}
                for i=1,#stripOrgI do
                  tmp[#tmp+1] = stripOrgI[i].." --> "..sectionsOrgD[stripOrgI[i]][1].."-"..sectionsOrgD[stripOrgI[i]][2]
                end
                H.WriteToFile(tmp,path)
              end
        if DEBUG then
          print("\n==> 5_ saved")
        end
        
      end
      
      local IsValidExml = CheckStructure(cOrg,"at E1:")
      local IsValidExml = CheckStructure(cMod,"at F1:")
      
      if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[6_clonedMODafterKeep.EXML]]) end
      if IsDebugWriteToFile then H.WriteToFile(cOrg,saveTo..[[6_clonedORGafterKeep.EXML]]) end
      if DEBUG then
        print("\n==> 6_ saved")
      end
      WFAK("WAITING: AFTER '# KEEP'")

      -- ==============================  
      local step3 = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V3"..H._zDEFAULT.." in "..H.dClock(step3 - step2).." --> SetKeepFlag")
      -- look for removed sections compared to ORG
      -- <Property name="Table" value="GcPurchaseableSpecial" _id="BANNER_PEEP" _remove="true" />
      -- <Property name="Table" value="GcPurchaseableSpecial" _id="BANNER_PEEP" _overwrite="true" />

      -- ==============================  
      -- identify removed sections from ORG
      -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@ THIS only need to strip a clone of stripModD of _overwrite
      printfALT("==> Create clonedstripModD from stripModD %s","")
      if IsDebugWriteToFile then H.WriteToFileDictionary(stripModD,saveTo..[[7_stripModD.EXML]]) end
      if DEBUG then
        print("\n==> 7_ saved")
      end
      
      if DEBUG then
        H.printf("      #stripModD = %d",H.GetTableCount(stripModD))
      end
      
      clonedstripModD = H.cloneDict(stripModD)

      if DEBUG then
        H.printf("#clonedstripModD = %d",H.GetTableCount(clonedstripModD))
      end
      
      if IsDebugWriteToFile then H.WriteToFileDictionary(clonedstripModD,saveTo..[[8_clonedstripModD.EXML]]) end
      if DEBUG then
        print("\n==> 8_ saved")
      end
      WFAK("WAITING: AFTER 'Create clonedstripModD'")

      printfALT("==> Strip _overwrite from clonedstripModD %s","")      
      local t = {}
      for k,v in pairs(clonedstripModD) do
        t[k:gsub([[ _overwrite="true"]],"")] = v
      end
      clonedstripModD = t

      if DEBUG then
        H.printf("#clonedstripModD = %d",H.GetTableCount(clonedstripModD))
      end
      
      if IsDebugWriteToFile then H.WriteToFileDictionary(clonedstripModD,saveTo..[[9_clonedstripModD_less_overwrite.EXML]]) end
      if DEBUG then
        print("\n==> 9_ saved")
      end
      WFAK("WAITING: AFTER 'Strip _overwrite from clonedstripModD'")
      
      printfALT("==> Identify removed sections from ORG %s","")
      local removedSections = {}
      local removedSectionsString = {}
      for i=1,#stripOrgI do
      -- for k in pairs(stripOrgD) do
        local k = stripOrgI[i]
        prf("qqq [%s]",k)
        if not clonedstripModD[k] then
          if strfind(cOrg[sectionsOrgD[k][1]]:upper()," _I",1,true) then
            -- looking only at those sections with _index or _id that where removed
            prf("rrr [%s]",k)
            removedSections[#removedSections+1] = {sectionsOrgD[k][1], sectionsOrgD[k][2], k}
            removedSectionsString[#removedSectionsString+1] = strformat("%4d-%-4d >> [%s]",removedSections[#removedSections][1], removedSections[#removedSections][2],k)
          end
        else
          prf("    ==> Not in clonedstripModD %s","")
        end
      end
      
      if DEBUG then
        H.printf("BEFORE sort: #removedSectionsString = %d",H.GetTableCount(removedSectionsString))
      end
      
      if DEBUG then
        table.sort(removedSectionsString)
        for i=1,#removedSectionsString do
          prf("%s",removedSectionsString[i])
        end
      end
      
      if DEBUG then
        H.printf(" AFTER sort: #removedSectionsString = %d",H.GetTableCount(removedSectionsString))
      end
      
      if IsDebugWriteToFile then H.WriteToFile(removedSectionsString,saveTo..[[10_removedSectionsString.EXML]]) end
      if DEBUG then
        print("\n==> 10_ saved")
      end
    
      -- END: identify removed sections from ORG
      WFAK("WAITING: AFTER 'discovering REMOVED sections'")
        
      local step4 = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V4"..H._zDEFAULT.." in "..H.dClock(step4 - step3).." --> discovering REMOVED sections")
      
      -- 1 - order for sorting (to keep original order from ORG)
      -- 2 = line # to be inserted at in cMod
      -- 3 = the line to insert
      -- 4 = keyToFind (NOT USED ??)
      -- {sortOrder, insertLine, keys[#keys], keyToFind}
      local toBeInserted = {}
      
      -- Insert stub in MOD for each removed section
      if #removedSections > 0 then
        -- sort in ascending order
        table.sort(removedSections,sortTableAsc)
        
        -- prf("HHH HHH HHH HHH ==> removedSections in ORG, ascending")
        -- for i=1,#removedSections do
          -- prf("%3d: %d - %d",i,removedSections[i][1],removedSections[i][2])
        -- end
        -- prf("HHH HHH HHH HHH ==> END: removedSections in ORG, ascending")
      
        -- Purge overlapping sections
        local Delete = {}
        local sectionEnd = removedSections[1][2]
        for i=2,#removedSections do
          if removedSections[i][1] <= sectionEnd then
            Delete[i] = true
          else
            Delete[i] = false
            sectionEnd = removedSections[i][2]
          end
        end
        
        for i=#removedSections,1,-1 do
          if Delete[i] then
            table.remove(removedSections,i)
          end
        end
      
        -- sort in descending order
        table.sort(removedSections,sortTableDesc)
        
        if DEBUG then
          prf("QQQ QQQ QQQ QQQ ==> Listing removedSections in ORG, purged, descending")
          for i=1,#removedSections do
            prf("%3d: %4d - %4d  ==> cOrg[removedSections[%d][1]] = [%s]", i, removedSections[i][1], removedSections[i][2], i, cOrg[removedSections[i][1]])
          end
          prf("QQQ QQQ QQQ QQQ ==> END: Listing removedSections in ORG, purged, descending")
        end
        WFAK("WAITING: BEFORE <processing removedSections>")
        
        -- removedSections DO NOT have '# KEEP'  !!!
        -- we need to refresh removedSections[x][3]
        
        local prfInsert
        if DEBUG then
          prfInsert = H.printf
        else
          prfInsert = function() end
        end
        
        for i=1,#removedSections do
          -- this section was in ORG, need to mark it _remove in MOD    
          prfInsert(H.gcNOTICE.." [NOTICE]"..H._zDEFAULT..": ORG %d-%d removed from MOD",removedSections[i][1],removedSections[i][2])

          -- only if the ORG section has an_index or _id
          --    we can ADD in MOD the HOS of ORG: <Property name="xyz" value="xyz" _index="X" _remove />
          --    and mark all lines in the section as "r"
          prfInsert("  ==> cOrg[removedSections[%d][1]] = [%s], removedSections[%d][1] = %d",i,cOrg[removedSections[i][1]],i,removedSections[i][1])
          
          local k = removedSections[i][3]
          prfInsert("  ORG = [%s]",k)
          
          local keys = k:splitB("|")
          
          for i=1,#keys do
            prfInsert("    ==> %3d: [%s]",i,keys[i])
          end
          
          local keyToFindFull = table.concat(keys,"|",1,#keys)

          local IsDone = false
          local keyIndex = 0
          if #keys > 0 then
            repeat
              local keyToFind = table.concat(keys,"|",1,#keys - keyIndex)
              prfInsert("    +  keyIndex = [%d]",keyIndex)
              prfInsert("    + keyToFind = [%s]",keyToFind)
              
              if sectionsModD[keyToFind] then
                local insertLine = sectionsModD[keyToFind][1] + 1
                prfInsert(H.gcNOTICE.."  In MOD,"..H._zDEFAULT.." insert at line %d ",insertLine)
                
                local insertOffset = 0
                for m = #keys - keyIndex +1, #keys -1 do
                  prfInsert("  Pre_Inserting keys[%d] at %d: [%s]", m, insertLine + insertOffset, keys[m]..H.modADDED..B0) -- B0 tag
                  toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[m]..H.modADDED..B0, ""}
                  insertOffset = insertOffset + 1
                end
                
                if strmatch(keys[#keys],H.modKEEP) then
                  -- a KEEP line
                  if strmatch(keys[#keys],[[">]]) then
                    -- prfInsert("  Inserting HOS KEEP line: [%s]",keys[#keys])                
                    -- toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[#keys], keyToFind}
                    
                    prfInsert(H.gcWARNING.." [WARNING]"..H._zDEFAULT.." Other KEEP lines may need to be inserted too, section is missing in MOD: [%s]","")                
                    
                    -- if DEBUG then
                      -- H.printf("        #cOrg = %d",H.GetTableCount(cOrg))
                      -- H.printf("   #stripOrgD = %d",H.GetTableCount(stripOrgD))
                      -- H.printf("   #stripOrgI = %d",H.GetTableCount(stripOrgI))
                      -- H.printf("#sectionsOrgD = %d",H.GetTableCount(sectionsOrgD))
                    -- end
                    
                    -- local lineToFind = table.concat(keys,"|",1,#keys) -- strgsub(keys[#keys],H.modKEEP,"")
                    -- prfInsert("+++ stripOrgD[%s] = %d-%d",lineToFind, sectionsOrgD[lineToFind][1], sectionsOrgD[lineToFind][2])
                    
                    -- for j=sectionsOrgD[lineToFind][1],sectionsOrgD[lineToFind][2] do
                      -- prfInsert("  Inserting missing section KEEP line: [%s]",cOrg[j])                
                      -- toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, cOrg[j], keyToFind}
                      -- insertOffset = insertOffset + 1
                    -- end
                    
                  else
                    prfInsert("  Pre_Inserting KEEP line at %d: [%s]", insertLine + insertOffset, keys[#keys])
                    toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[#keys], keyToFind}
                  end
                  
                else
                  -- local toBeInserted = {sortOrder, insertLine, keys[#keys], keyToFind}
                  --    1 - order for sorting (to keep original order from ORG)
                  --    2 = line # to be inserted at in cMod
                  --    3 = the line to insert
                  --    4 = keyToFind (NOT USED ??)
                  
                  if strmatch(keys[#keys],[[">]]) then
                    prfInsert("  Pre_Inserting _remove line at %d: [%s]", insertLine + insertOffset, keys[#keys]:gsub([[">]],[[" _remove="true" />]]..H.modCHANGED..A0)) -- A0 tag
                    toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[#keys]:gsub([[">]],[[" _remove="true" />]]..H.modCHANGED..A0), keyToFind}
                  else
                    -- this is a ListOfValues entry
                    prfInsert("  Pre_Inserting _remove line at %d: [%s]", insertLine + insertOffset, keys[#keys]:gsub([[ />]],[[ _remove="true" />]]..H.modCHANGED)..A1) -- A1 tag
                    toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[#keys]:gsub([[ />]],[[ _remove="true" />]]..H.modCHANGED..A1), keyToFind}

                    -- could _overwrite also works here ??
                    -- prfInsert("  Inserting _remove line: [%s]",keys[#keys]:gsub([[ />]],[[ _overwrite="true" />]]..H.modCHANGED)..A1)
                    -- toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset, keys[#keys]:gsub([[ />]],[[ _overwrite="true" />]]..H.modCHANGED..A1), keyToFind}
                  end
                end
                
                prfInsert("      insertOffset = [%d]",insertOffset)
                for j=1,insertOffset do
                  prfInsert("  Pre_Inserting [</Property>] sortOrder (%4d) at line %d", removedSections[i][1], insertLine + insertOffset + j)
                  -- prfInsert("  Pre_insertOffset = [%d]",insertLine + insertOffset + j)
                  local spacer = strmatch(toBeInserted[#toBeInserted][2],"^(%s*)")
                  toBeInserted[#toBeInserted+1] = {removedSections[i][1], insertLine + insertOffset + j, strrep(" ",#spacer-2).."</Property>"..H.modADDED..B1, ""} -- B1 tag
                end

                IsDone = true
                prfInsert("  IsDone = [%s]",tostring(IsDone))
              else
                -- prfInsert("  NOT found %s","")
                -- back up by one key for next try
                keyIndex = keyIndex + 1
              end
            until IsDone or keyIndex >= #keys
          else
            prfInsert("=====================>>>>    "..H.gcWARNING.." [WARNING]"..H._zDEFAULT.." NO keys to process %s","")
          end -- if #keys > 0 then
          
          -- if not IsDone then
          if IsDone == false then
            H.printf("===>>>>"..H.gcWARNING.." [WARNING] "..H._zDEFAULT.." Key of removed section does not exist in MOD: [%s]",keyToFindFull)
            H.Report("","Key of removed section does not exist in MOD: ["..tostring(keyToFindFull).."]",[[WARNING]])

            if strmatch(cOrg[removedSections[i][1]],H.modKEEP) then
              local keyToFindPartial = table.concat(keys,"|",1,#keys-1)
              prfInsert("keyToFindPartial = [%s]",keyToFindPartial:gsub(H.modKEEP,""))
              if sectionsModD[keyToFindPartial:gsub(H.modKEEP,"")] then
                local insertLine = sectionsModD[keyToFindPartial:gsub(H.modKEEP,"")][1] + 1
                prfInsert("  In MOD, insert missing section from ORG at line %d",insertLine)
              end
            end
          end
        end -- for i=1,#removedSections do
        
        -- local toBeInserted = {sortOrder, insertLine, keys[#keys], keyToFind}
        --    1 - order for sorting (to keep original order from ORG)
        --    2 = line # to be inserted at in cMod
        --    3 = the line to insert
        --    4 = keyToFind (NOT USED ??)
      
        prf("RRR RRR RRR RRR ==> Listing toBeInserted = "..#toBeInserted)
        for i=1,#toBeInserted do
          prf("%3d: sortOrder (%4d) to be inserted at %4d: [%s]",i,toBeInserted[i][1],toBeInserted[i][2],toBeInserted[i][3])
        end
        prf("RRR RRR RRR RRR END: ==> Listing toBeInserted = "..#toBeInserted)
        WFAK("WAITING: BEFORE <processing toBeInserted>")
        
        if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[11_cModBeforeToBeInserted.EXML]]) end
        if DEBUG then
          print("\n==> 11_ saved")
        end
        if #toBeInserted > 0 then
          prfInsert("  #toBeInserted = [%d]",#toBeInserted)
          
          table.sort(toBeInserted,sortTableDescEXT)
          prfInsert("  toBeInserted sorted descending","")

          prf("SSS SSS SSS SSS ==> Listing toBeInserted sorted descending")
          for i=1,#toBeInserted do
            prf("%3d: sortOrder (%4d) at %4d: [%s]",i,toBeInserted[i][1],toBeInserted[i][2],toBeInserted[i][3])
          end
          prf("SSS SSS SSS SSS ==> END: Listing toBeInserted sorted descending")

          WFAK("WAITING: BEFORE <inserting into cMod>")
          for i=1,#toBeInserted do
            local IsOkToInsert = true
            local IsOkToOverwrite = false
            
            -- is this a ListOfValues section?
            local IsListOfValues = false
            
            if cMod[toBeInserted[i][2]] then
              local name = strmatch(cMod[toBeInserted[i][2]],[[name="(.-)"]])
              if name then
                prfInsert("==> Property name = [%s]",name)
                if strmatch(cMod[toBeInserted[i][2]-1],[[name="(.-)"]]) == name or strmatch(cMod[toBeInserted[i][2]+1],[[name="(.-)"]]) == name then
                  prfInsert("   *** ListOfValues section detected ***","")
                  IsListOfValues = true
                end
              end              
            -- else
              -- prfInsert("#cMod = %d",#cMod)
              -- prfInsert(" @@@@@@@ cMod[toBeInserted[%d][2]] == nil (toBeInserted[%d][2] = %d)", i, i, toBeInserted[i][2])
            end
            
            local partialLine,index
            if IsListOfValues then
              partialLine,index = strmatch(toBeInserted[i][3],[[^(.+ue=").+_index="(%d+)"]])
            else
              partialLine,index = strmatch(toBeInserted[i][3],[[^(.+_index=")(%d+)"]])
            end
            prfInsert("* %3d: trying to insert at %d [%s]",i,toBeInserted[i][2],toBeInserted[i][3])
            
            if partialLine and index and toBeInserted[i][2] < #cMod then
              prfInsert("         partialLine = [%s]",partialLine)
              prfInsert("               index = [%d], searching in section containing line %d of cMod",index,toBeInserted[i][2])
              prfInsert("        cMod section = %d-%d",H.GoUPToOwnerStart(cMod,toBeInserted[i][2]),H.GoDownToOwnerEnd(cMod,toBeInserted[i][2]))
              for j = H.GoUPToOwnerStart(cMod,toBeInserted[i][2]), H.GoDownToOwnerEnd(cMod,toBeInserted[i][2]) do
                prfInsert("      cMod[%6d] = [%s]",j,cMod[j])
                if cMod[j] == nil then
                  break
                end
                if strfind(cMod[j],partialLine,1,true) then
                  local ind = strmatch(cMod[j],[[ _index="(%d+)"]])
                  if ind then
                    prfInsert("                ind = [%s]",ind)
                    if ind == index then
                      if IsListOfValues then
                        -- cMod line is already ok, nothing to do
                        IsOkToInsert = false
                        IsOkToOverwrite = false
                        break
                      else
                        -- script probably used CREATE_HOES or changed the value of a ListOfValues, overwrite the line
                        toBeInserted[i][2] = j
                        IsOkToInsert = false
                        IsOkToOverwrite = true
                        break
                      end
                    elseif ind > index then
                      toBeInserted[i][2] = j
                      break
                    end
                  end
                end
              end -- for j = H.GoUPToOwnerStart(cMod,toBeInserted[i][2]), H.GoDownToOwnerEnd(cMod,toBeInserted[i][2]) do
            end
            
            if IsOkToInsert then
              prfInsert("    #cMod = %d",#cMod)
              if toBeInserted[i][2] >= #cMod then
                -- insert just before </Data>
                -- cMod[#cMod+1] = toBeInserted[i][3]
                prfInsert("    %3d: inserting at %d [%s]",i,#cMod - 1,toBeInserted[i][3])
                table.insert(cMod, #cMod - 1, toBeInserted[i][3])
              else
                prfInsert("    %3d: inserting at %d [%s]",i,toBeInserted[i][2],toBeInserted[i][3])
                table.insert(cMod, toBeInserted[i][2], toBeInserted[i][3])
              end
            end
            if IsOkToOverwrite then
              if toBeInserted[i][2] >= #cMod then
                -- insert just before </Data>
                -- cMod[#cMod+1] = toBeInserted[i][3]
                prfInsert("    %3d: PROBABLY SHOULD NOT HAPPEN, overwriting at %d [%s]",i,#cMod - 1,toBeInserted[i][3])
                table.insert(cMod, #cMod - 1, toBeInserted[i][3])
              else
                prfInsert("    %3d: overwriting at %d with [%s]",i,toBeInserted[i][2],toBeInserted[i][3])
                cMod[toBeInserted[i][2]] = toBeInserted[i][3]
              end
            end
          end -- for i=1,#toBeInserted do
          
          -- redo the cMod table
          TopMod = H.GetTopOfMXML(cMod)
          prfInsert("==> cMod AnalyzeXML redone after toBeInserted %s","")
          stripModD, stripModI, sectionsModD, cMod = H.AnalyzeXML("with MOD AFTER toBeInserted",cMod,TopMod)
          
          if DEBUG then
            H.printf("        #cMod = %d",H.GetTableCount(cMod))
            H.printf("   #stripModD = %d",H.GetTableCount(stripModD))
            H.printf("   #stripModI = %d",H.GetTableCount(stripModI))
            H.printf("#sectionsModD = %d",H.GetTableCount(sectionsModD))
          end
          
          prfInsert("  DONE #toBeInserted > 0%s","")
        end
      else
        printALT("       ==> NO removed sections")
      end -- if #removedSections > 0 then
      
      if IsDebugWriteToFile then H.WriteToFile(cMod,saveTo..[[12_cModAfterToBeInserted.EXML]]) end
      if DEBUG then
        print("\n==> 12_ saved")
      end
      WFAK("WAITING: END <Processing REMOVED SECTIONS>")
      
      local step5 = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V5"..H._zDEFAULT.." in "..H.dClock(step5 - step4).." Processed REMOVED SECTIONS")
      -- check each Mod sections against Org
      
      -- clone to endMod (we are using cMOD inside the loop)
      local endMod = H.cloneArray(cMod)
      
      local IsValidExml = CheckStructure(endMod,"at G:")
      
      -- These could be ListOfValues sections
      local moddedSections = {}
      
      for k,v in pairs(stripModD) do
        -- printf("%s",strsub(k,1,50).." ... "..strsub(k,-50))
        
        -- if strfind(v,"Multi") then
          -- printfALT(H.gcWARNING.." [WARNING]"..H._zDEFAULT.." Section %d-%d of MOD is: %s",sectionsModD[k][1],sectionsModD[k][2],v)
          -- -- WFAK()
        -- end
        
        if stripOrgD[k] and H.trim(k) ~= "</Data>" then
          -- section exist in both Mod and Org
          if H.IsSectionsEqual(cMod, sectionsModD[k], cOrg, sectionsOrgD[k]) then
            -- sections ARE equal
            -- ModSection == OrgSection --> mark Mod section for removal
            -- printALT("                          ==> MOD == ORG")
            
            if strmatch(endMod[sectionsModD[k][1]],[[ linked=]]) then
              -- if a linked section, disregard KEEP and remove the section
              for i=sectionsModD[k][1],sectionsModD[k][2] do
                endMod[i] = "r" -- signal remove
              end
            else
              -- remove section if not KEEP
              for i=sectionsModD[k][1],sectionsModD[k][2] do
                if not strmatch(endMod[sectionsModD[k][1]],H.modKEEP) then
                  endMod[i] = "r" -- signal remove
                end
              end
            end

          else
            -- sections NOT equal
            -- ModSection ~= OrgSection --> keep Mod section (default)
            
            if strmatch(endMod[sectionsModD[k][1]],[[ linked=]]) then
              -- this is a 'linked' section
              -- 1)  the 'linked="xyz"' must be removed
              endMod[sectionsModD[k][1]] = endMod[sectionsModD[k][1]]:gsub([[ linked=".-"]],"")..H.modLINKED

              -- ALREADY done by SetKeepFlag() above
              -- -- 2) this section to be keep as a linked section
              -- for i=sectionsModD[k][1] + 1, sectionsModD[k][2] do
                -- endMod[i] = endMod[i]..H.modKEEP.."_B"
              -- end
            
            -- elseif strmatch(endMod[sectionsModD[k][1]],"[ _]overwrite") then
              -- -- this section to be kept as an _overwrite section
              -- for i=sectionsModD[k][1] + 1, sectionsModD[k][2] do
                -- endMod[i] = endMod[i]..H.modKEEP.."_B"
              -- end
              
            else
              -- printfALT("         ==> MOD ~= ORG: %d-%d <=> %d-%d",sectionsModD[k][1],sectionsModD[k][2], sectionsOrgD[k][1],sectionsOrgD[k][2])
              moddedSections[#moddedSections+1] = {sectionsModD[k], sectionsOrgD[k]}
            end
            
          end -- if H.IsSectionsEqual(cMod, sectionsModD[k], cOrg, sectionsOrgD[k]) then
          
        -- else
          -- -- section only exist in Mod, keep it (default)
          -- -- printfALT("                          ==> NEW section in MOD: %d-%d",sectionsModD[k][1],sectionsModD[k][2])
        end -- if stripOrgD[k] and k ~= "</Data>" then 
      end -- for k,v in pairs(stripModD) do
      
      if IsDebugWriteToFile then H.WriteToFile(endMod,saveTo..[[13_endModWithRemoveFlag_1.EXML]]) end
      if DEBUG then
        print("\n==> 13_ saved")
      end
      -- WFAK("WAITING: ")

      -- prf("    BEFORE cleaning #endMod = %d",#endMod)
      -- cleanup current "removed" lines
      local tmp = {}
      for i=1,#endMod do
        if endMod[i] ~= "r" then -- NOT remove
          tmp[#tmp+1] = endMod[i]
        end
      end
      endMod = tmp
      if IsDebugWriteToFile then H.WriteToFile(endMod,saveTo..[[14_endModCleaned.EXML]]) end
      if DEBUG then
        print("\n==> 14_ saved")
      end
      -- prf("     AFTER cleaning #endMod = %d",#endMod)
      
      -- need to check leftover " />" fields under <Data template...
      
      -- prf("    BEFORE cleaning #cOrg = %d",#cOrg)
      
      -- create a list of field entry lines
      local cleanMXMLorg = {}
      for i=1,#cOrg do
        local s = cOrg[i]
        if strfind(s,[[/>]],1,true) then
          -- prf("[%s]",s)
          -- keep only these field entry lines
          cleanMXMLorg[s] = i
        end
      end
      
      local step6 = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V6"..H._zDEFAULT.." in "..H.dClock(step6 - step5).." --> 1st removed lines ")
      
      local IsValidExml = CheckStructure(endMod,"at H:")
      
      for i=1,#endMod do
        local s = endMod[i]
        -- printf(" * [%s]",s)
        if strfind(s,[[/>]],1,true) then
          if strfind(s,H.modFlag,1,true) == nil and strfind(s,H.modKEEP,1,true) == nil then
            if cleanMXMLorg[s] then
              -- this field is the same in both Mod and Org
              -- prf("==> Found [%s] in ORG at %d",s,i)
              endMod[i] = "r" -- signal remove
            end
          end
        end
      end
      
      local step7 = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V7"..H._zDEFAULT.." in "..H.dClock(step7 - step6).." --> 2nd removed lines, #endMod = "..#endMod)
      if IsDebugWriteToFile then H.WriteToFile(endMod,saveTo..[[15_endModWithRemoveFlag_2.EXML]]) end
      
      -- cleanup "removed" lines and unchanged field entry lines
      --   remove KEEP flag
      -- 1st use of "exml" table
      for i=1,#endMod do
        if endMod[i] ~= "r" then -- NOT removed
          exml[#exml+1] = endMod[i]:gsub(H.modKEEP,"") -- remark gsub for DEBUG
        end
      end
      
      -- cleanup empty sections in what is left
      finalize = os.clock()
      printALT(printALTspacer..H._zBRIGHTORANGE.."Step V8"..H._zDEFAULT.." in "..H.dClock(finalize - step7).." --> cleanup lines, EXML is "..#exml.." lines long")
    end -- if IsOkToProcess then
    
  else
    finalize = os.clock()
    printALT("          --- Org is now considered an empty section")
    -- then we have nothing more to do: cMod IS the EXMl
    exml = cMod
    
  end -- if not IsOrgEmpty then
  
  local IsValidExml = CheckStructure(exml,"at I:")
  
  if IsOrgEmpty or IsOkToProcess then
    -- finalize the exml
    printALT("       ==> Finalizing...")
    -- local IsAllDone = false
    -- local pass = 0
    -- while not IsAllDone do
      local i = 1
      -- pass = pass + 1
      -- printALT("    --- pass "..pass)
      
      -- IsAllDone = true
      local interval = math.floor(#exml / 1000000) * 100000
      -- printALT(interval)
      while i<#exml-1 do
        if exml[i] ~= "r" then
          if interval > 0 and i % interval == 0 then
            printALT(" - "..i)
          end
          
          if strmatch(exml[i],[["ResHandle"]]) then
            -- a special remove for a NEVER used section
                -- <Property name="ResHandle" value="GcResource">
                  -- <Property name="ResourceID" value="0" />
                -- </Property>
            exml[i] = "r"
            exml[i+1] = "r"
            exml[i+2] = "r"
            i = i + 2
            -- IsAllDone = false
          end

          if strfind(exml[i],[[">]],1,true) and strfind(exml[i+1],[[</]],1,true) then
            -- an empty section
            if strfind(exml[i],[[ue=]],1,true) == nil then
              -- type A) like:
                  -- <Property name="XYZ">
                  -- </Property>
              -- create HOES here like: <Property name="XYZ" />  
              exml[i] = exml[i]:gsub([[">]],[[" />]])
              
            else
              -- type B) like:
                  -- <Property name="XYZ" value="ABC">
                  -- </Property>
              if strfind(exml[i],H.modADDED,1,true) then
                -- create HOES here like: <Property name="PartModifiers" />  
                exml[i] = exml[i]:gsub([[">]],[[" />]])
              else
                exml[i] = "r" -- remove the HOES
              end
            end
            
            exml[i+1] = "r" -- remove the </Property> line
            i = i + 1
            -- IsAllDone = false
          end
        end        
        i = i + 1
      end
      
      -- if not IsAllDone then
        -- printALT("    --- In AllDone...")
        
        -- TOO SLOW: table.remove(exml,i)
        
        local tmp = {}
        for i=1,#exml do
          if exml[i] ~= "r" then
            tmp[#tmp+1] = exml[i]
          end
        end
        exml = tmp
      -- end
    -- end

    local IsValidExml = CheckStructure(exml,"at J:")
  
    if strfind(table.concat(exml),[[te="cTkLocalisationTable"]],1,true) then
      -- a LANGUAGE file, check if the [[="Id"]] lines are there, if not create them
      -- H.printf("FOUND a LANGUAGE file...","")
      local IsAddedId = false
      for i=#exml,1,-1 do -- in reverse order so we can add lines
        if strfind(exml[i],[[ue="TkLocalisationEntry"]],1,true) and strfind(exml[i],[[ _id=]],1,true) then
          -- H.printf("FOUND _id...","")
          if strfind(exml[i+1],[[="Id"]],1,true) == nil then
            -- H.printf([[NO ="Id"...]],"")
            -- next line does NOT contain [[="Id"]]
            local Id = strmatch(exml[i],[[ _id="(.*)"]])
            local indentation = strmatch(exml[i+1],[[^(%s*)]])
            table.insert(exml,i+1,indentation..[[<Property name="Id" value="]]..Id..[[" />]]..H.modADDED..C0)
            -- H.printf("ADDED in line %d: [%s]",i+1,indentation..[[<Property name="Id" value="]]..Id..[[" />]])
            IsAddedId = true
          end
        end
      end
      if IsAddedId then
        printALT("       -- Added Id info to LANGUAGE file")
      end
      -- H.WFAK()
    end
  
    table.insert(exml, H.GetTopOfMXML(exml), [[<!--EXML Created by AMUMSS v.]]..H.LoadFileData("AMUMSSVersion.txt"):gsub("\n",""):gsub("\r","")..[[-->]])
    
    local IsValidExml = CheckStructure(exml,"at Y:")
    
    -- REFORMAT exml
    exml = H.AutoAdjustIndentation(exml,exml,1)
    
    local IsValidExml = CheckStructure(exml,"at Z:")
    
    endTime = os.clock()
    printALT(printALTspacer..H._zBRIGHTORANGE.."Step V9"..H._zDEFAULT.." in "..H.dClock(endTime - finalize).." --> final removed lines, EXML is "..#exml.." lines long")
    -- printALT("  ===================  END  ===========================")
  end -- if IsOkToProcess then

  print(H._zBRIGHTGREEN.."        - done in "..H.dClock(endTime - start)..H._zDEFAULT)  
  
  if H.DEBUG_WAITatEND then
    H.WFAK("==>> Reached end of EXML creation, WAITING:")
  end
  
  return exml, IsValidExml
end

--***************************************************************************************************
-- xml: an EXML/MXML LANGUAGE table
-- prefix: optional, string to insert before the table
-- returns: TABLE, in the LocTable.txt style
function H.CreateLocTableTXTFromXML(xml,prefix)
  -- H.printf("==> From H.CreateLocTableTXTFromXML %s","")
  local t = {}

  if prefix then
    t[1] = prefix
  end
  
  local IsFound_id = false
  for i=1,#xml do
    local s = xml[i]
    if strfind(s," _id=",1,true) then
      local ss = strmatch(s,[[ _id="(.-)"]])
      if ss ~= "" then
        t[#t+1] = "="..ss
        IsFound_id = true
      end
    end
    if not IsFound_id and strfind(s,[[="Id"]],1,true) then -- needed if the XML was created by a script without the _id
      t[#t+1] = "="..strmatch(s,[[ue="(.-)"]])
      IsFound_id = false
    end
    
    local lang = H.languagesEXT[strmatch(s,[[me="(.-)"]])]
    if lang then
      t[#t+1] = lang.." ="..strmatch(s,[[ue="(.-)"]])
    end
  end
  return t
end

--***************************************************************************************************
-- locTableTxt: LocTable.txt as a TABLE
-- returns: TABLE, the LocTable.MXML
function H.CreateLocTableMXMLfromTXT(locTableTxt)
  -- H.printf("==> From H.CreateLocTableMXMLfromTXT %s","")
  -- pre-process LocTable.txt
  
  local locId = {}
  local locIdI = {}
  local currentId = ""
  local IsNewLanguage = false
  for i=1,#locTableTxt do
    local line = locTableTxt[i]
-- H.printf("[%s]",line)
    if H.trim(line) == "" and not IsNewLanguage then
      -- skip line
      print("   Skipping line")
    elseif strfind(line,"=",1,true) then
      local left,right = strmatch(line,[[^%s*(.-)%s*=(.-)$]])
      if left == "" then
        -- this is an Id
-- H.printf("      Id = [%s]",right)
        if not locId[right] then
          locId[right] = {}
          locIdI[#locIdI + 1] = right
        end
        currentId = right
        IsNewLanguage = false
      else
        -- this is a language like EN or FR ...
        if right ~= "" then
-- H.printf("         >>> [%s]",line)
          locId[currentId][#locId[currentId] + 1] = line
          IsNewLanguage = true
        end
      end
    else
      -- another line for this currenId language
-- H.printf("         === [%s]",line)
      locId[currentId][#locId[currentId] + 1] = line
    end
  end
  -- locId table now has all the most recent Ids and languages
  
  -- -- debug
  -- print("LLL LLL LLL LLL")
  -- for i=1,#locIdI do
    -- local Id = locIdI[i]
    -- H.printf("Language = [%s]",Id)
    -- for j=1,#locId[Id] do
      -- H.printf("  - %s",locId[Id][j])
    -- end
  -- end
  -- print("LLL LLL LLL LLL")
  
  local mainHeader = {
    [[<?xml version="1.0" encoding="utf-8"?>]],
    [[<!--EXML Created by AMUMSS v.]]..H.LoadFileData("AMUMSSVersion.txt"):gsub("\n",""):gsub("\r","")..[[-->]],
    [[<Data template="cTkLocalisationTable">]],
    [[  <Property name="Table">]],
    }
  local mainFooter = {
    [[  </Property>]],
    [[</Data>]],
    }
  
  local header = [[    <Property name="Table" value="TkLocalisationEntry">]]
  local footer = [[    </Property>]]
    
  -- example
  -- <?xml version="1.0" encoding="utf-8"?>
  -- <Data template="cTkLocalisationTable">
    -- <Property name="Table">
      -- <Property name="Table" value="TkLocalisationEntry">
        -- <Property name="Id" value="UI_TIMEDUST_SYM"/>
        -- <Property name="English" value="Љ"/>
        -- <Property name="French" value="Љ"/>
      -- </Property>
    -- </Property>
  -- </Data>]]
  
  local loc = {}
  for i=1,#mainHeader do
    loc[#loc+1] = mainHeader[i]
  end

  local language = ""
  local t = ""
  local IsFirstId = true
  local left,right
  local j = 0
  
  -- H.printf("","")
  for i=1,#locIdI do
    local Id = locIdI[i]
    loc[#loc+1] = header
    loc[#loc+1] = [[      <Property name="Id" value="]]..Id..[[" />]]

    -- H.printf("==> processing %d: [%s] (%d)",i,Id,#locId[Id])

    language = ""
    t = ""
    
    local tmpLine = ""
    for j=1,#locId[Id] do
      -- H.printf("locId[%s][%d] = [%s]",Id,j,locId[Id][j])
      -- H.printf("==> [%s] [%s]",H.trim(locId[Id][j]),locId[Id][j])
      if H.trim(locId[Id][j]) == "" then
        -- H.printf("==> adding newline at %d",j)
        tmpLine = '|NL|'
      else
        local left,right = strmatch(locId[Id][j],[[^%s*(.-)%s*=(.-)$]])
        
        if left and left ~= "" then  
          -- H.printf("  - [%s] = [%s]",tostring(left),tostring(right))
          if H.languages[left] then
            -- a valid language
            if language ~= "" then
              -- 1st: terminate the previous text
              -- H.printf("       terminating previous text [%s]",t)
              loc[#loc+1] = [[      <Property name="]]..language..[[" value="]]..H.CharEntitiesInsert(H.CharEntitiesReverse(t))..[[" />]]
              t = ""
              language = ""
            end
            
            language = H.languages[left]                    
            -- H.printf("       found language [%s]",language)
          end
          -- start the new text
          t = right or ""
          -- H.printf("       starting text [%s]",t)
        
        else
          -- the continuation on a newline of the text for this language
          t = t..'|NL|'..tmpLine..locId[Id][j]
          tmpLine = "" -- reset
          -- H.printf("       adding to text [%s]",t)
        end -- if left ~= "" then
        
      end -- if H.trim(line) == "" then
    end
    
    -- print("*** At end of this section")
    --   doing Reverse and then Insert because string could be already like &lt;SPECIAL&gt;anomalous&lt;&gt;
    loc[#loc+1] = [[      <Property name="]]..language..[[" value="]]..H.CharEntitiesInsert(H.CharEntitiesReverse(t))..[[" />]]
    loc[#loc+1] = footer
  end -- for i=1,#locIdLine do

  for i=1,#mainFooter do
    loc[#loc+1] = mainFooter[i]
  end
  -- print("*** At end of ALL sections")
  
  return loc
end

--***************************************************************************************************
function H.CreateFastArrayInfoTable(filename)
  if H.IsFileExist(filename) then
    print("   >>> Creating fast ArrayInfo table...")
    local t = H.ParseTextFileIntoTable(filename)
    -- H.printf("array_data.txt = %d",#t)
    -- for i=1,#t do
      -- H.printf(" $$$ %s",t[i])
    -- end
    
    local fT = {}
    -- skip 1st two and last lines
    local count = 0
    for i=3,#t do
      local class,field,type,size = strmatch(t[i],"^(%a-)%.([%a%d]-) (%a-) (%d+)")
      class = class:upper()
      field = field:upper()
      -- H.printf("$$$ %70s = (%s) %d",class.."."..field, type, tonumber(size))
      if not fT[class] then
        fT[class] = {}
      end
      -- fT[class][#fT[class]+1] = {}
      -- fT[class][#fT[class]][field] = tonumber(size)
      fT[class][field] = tonumber(size)
      count = count + 1
    end
    H.printf("       - %d entries",count)

    -- -- DEBUG
    -- local function CreateArrayTable(t,msg)
      -- local msg = msg or "arrayt"
      -- local arrayt = {}
      -- for k in pairs(t) do
        -- arrayt[#arrayt+1] = k
      -- end
      -- H.printf("==================>> INFO: %s = %d",msg,#arrayt)
      -- table.sort(arrayt)
      -- return arrayt
    -- end

    -- -- create sorted table by class
    -- local fTI = CreateArrayTable(fT,"#fT")

    -- print("=== === === ARRAY INFO")
    -- local count2 = 0
    -- for i = 1, #fTI do
      -- local class = fTI[i]
      -- local class_data = fT[class]

      -- for field,size in pairs(class_data) do
        -- -- H.printf("type(field) = %s",type(field))
        -- -- H.printf(" type(size) = %s",type(size))
        -- H.printf("- %s.%s = %d",class,field,size)
        -- count2 = count2 + 1
      -- end
    -- end
    -- H.printf("=== === === END: ARRAY INFO (%d/%d)",count2,count)
    -- -- END: DEBUG

    return fT
  end
end

--***************************************************************************************************
--  H.FastArrayInfo: Always execute once to prepare
if not IsLightLoadHelper and H.FastArrayInfo == nil then
  H.FastArrayInfo = {}
  H.FastArrayInfo = H.CreateFastArrayInfoTable("array_data.txt")
end
  
--***************************************************************************************************
function H.SwitchToOtherMBINCompiler(H,whichReport)
  -- SWITCH TO THE OTHER MBINCOMPILER
  if not H.IsFileExist([[VersionPublic.txt]]) then
    -- we are currently using LATEST, switch to PUBLIC

    H.CopyFile([[MBINCompiler.public.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
    -- activate FLAG PUBLIC
    H.WriteToFile("",[[VersionPublic.txt]])
    
    H.DeleteFile([[MBINCompilerVersion.txt]])
    local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
    H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
    
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." to 'public' MBINCompiler "..sV)
    end
    if whichReport == "AMUMSS" then
      H.Report("","Switched to 'public' MBINCompiler "..sV)
    end
  else
    -- we are currently using PUBLIC, switch to LATEST
    H.CopyFile([[MBINCompiler.latest.exe]],[[MBINCompiler.exe]],[[/y /h /j /r]],true)
    -- activate FLAG LATEST
    H.DeleteFile([[VersionPublic.txt]])
    
    H.DeleteFile([[MBINCompilerVersion.txt]])
    local sV,nV = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
    H.WriteToFile(sV,[[MBINCompilerVersion.txt]])
    
    if not H.gIs_LEAN_MODE then
      print(H._zBRIGHTORANGE.."   Switched"..H._zDEFAULT.." to 'most recent' MBINCompiler "..sV)
    end
    if whichReport == "AMUMSS" then
      H.Report("","Switched to 'most recent' MBINCompiler "..sV)
    end
  end
end

--***************************************************************************************************
function H.ProcessMBINtable(MBIN_table, IsCOMBINE_MODS_flag, _bScriptName, whichReport)
  local string = string
    local strsub = string.sub
    local strgsub = string.gsub
    local strfind = string.find
    local strupper = string.upper
    local strgmatch = string.gmatch
    local strmatch = string.match
  local print = print
  local tostring = tostring
  local tonumber = tonumber
  local type = type
  local table = table
  local math = math
  local os = os
  
  --************************************************
  -- discover array_size flags and purge file
  local function HandleArraySize(file)
    local s = H.LoadFileData(file)
    if strfind(s,[[array_size=]],1,true) then
      -- record those array_size with template info and field
      local template = strmatch(s,[[template="()"]])
      for f,a in strgmatch(s,[[]]) do
      end
    end
  end
  --************************************************

  -- change .MBIN.PC to .MBIN
  -- change .MXML to .MBIN when the user is referencing .MXML files instead of .MBIN in the script
  for i=1,#MBIN_table do
    MBIN_table[i] = H.MXML_PC_EXMLtoMBIN(MBIN_table[i])
  end
    
  -- CAN we list where the paks came from???
  
  if IsCOMBINE_MODS_flag then
    -- print("=========================== for script: ".._bScriptName)
    for i=1,#MBIN_table do
      -- printf("   K0: MBIN_table[%d] = <%s>",i,MBIN_table[i])
      local exmlName = MBIN_table[i]:gsub(".MBIN$",".MXML")
      
      -- fill list
      if not scriptFileList[exmlName] then
        scriptFileList[exmlName] = {}
      end
      scriptFileList[exmlName][#scriptFileList[exmlName]+1] = _bScriptName
    end
  end

  H.IsFetching = false
  if not H.gIs_LEAN_MODE and #MBIN_table > 0 then
    print("   >>> Fetching already extracted/decompiled files...")
    H.IsFetching = true
  end
  
  -- print("A: =========================== "..#MBIN_table)
  -- for i=1,#MBIN_table do
    -- printf("A0: MBIN_table[%d] = <%s>",i,tostring(MBIN_table[i]))
  -- end
  -- print("===========================")

  -- here all files with extension .MXML, .MXML.PC and .EXML end in .MBIN or other extensions that cannot be decompiled
  -- print("BEFORE .MXML EXIST in ModScript or MOD: MBIN_table = "..#MBIN_table)
  for i=#MBIN_table,1,-1 do
    -- make all .MBIN into .MXML
    local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
    
    -- This is NOT REDUNDANT, also see above
    -- for when the user puts an .MXML or other file like .BIN in ModScript and is referenced in the scripts
    local IsInModScript = false
    if H.IsFileExist([[..\ModScript\]]..EXML_FILE) then
      H.CopyFile([[..\ModScript\]]..EXML_FILE, [[.\MOD\]]..EXML_FILE..[[*]], H.paramFiles)
      IsInModScript = true
    end
    -- END: This is NOT REDUNDANT, also see above
    
    if H.IsFileExist([[.\MOD\]]..EXML_FILE) then
      -- table.remove(MBIN_table,i) -- done already
      MBIN_table[i] = "NIL"
      
      if IsInModScript then
        if not H.gIs_LEAN_MODE then
          print("      "..H._zBRIGHTORANGE..">>> "..EXML_FILE.." already exist in ModScript and will be used to COMBINE "..H._zDEFAULT)
        end
        if whichReport == "AMUMSS" then
          H.Report("",EXML_FILE.." already exist in ModScript and will be used to COMBINE")
        end
      else
        if not H.gIs_LEAN_MODE then
          print("      >>> "..EXML_FILE..[[ already exist in MODBUILDER\MOD and will be COMBINED]])
        end
        if whichReport == "AMUMSS" then
          H.Report("",EXML_FILE..[[ already exist in MODBUILDER\MOD and will be COMBINED]])
        end
      end
    end
  end -- for i=1,#MBIN_table do
-- H.WFAK("A:")

  -- print("X: =========================== "..#MBIN_table)
  -- for i=1,#MBIN_table do
    -- printf("X0: MBIN_table[%d] = <%s>",i,tostring(MBIN_table[i]))
  -- end
  -- print("===========================")
  
  MBIN_table = H.refreshTable(MBIN_table)
  
  -- print("Y0: =========================== "..#MBIN_table)
  -- for i=1,#MBIN_table do
    -- printf("Y1: MBIN_table[%d] = <%s>",i,tostring(MBIN_table[i]))
  -- end
  -- print("===========================")
  
  -- print(".before trying to EXTRACT from NMS paks: #MBIN_table = "..#MBIN_table)
  -- here all end in .MBIN or .MBIN.PC
  if #MBIN_table > 0 then
    -- 2nd: some still not found, find them in NMS paks
    
    local extractInfo = {}
    local extractCommand = {}

    for i=#MBIN_table,1,-1 do
      if MBIN_table[i] then
        local PCExt = ""
        if strfind(MBIN_table[i],".GEOMETRY.",1,true) then
          -- to remember it was a .MBIN.PC file
          PCExt = [[.PC]]
        end

        -- printf("C0: MBIN_table[%d] = <%s>",i,MBIN_table[i]..PCExt)
        local lessEXML = strsub(MBIN_table[i],1,-6)
        if H.EXMLorgTable[lessEXML] then
          -- this file has already been opened, we can use it
          -- table of strings in H.EXMLmodTable
          if not H.gIs_LEAN_MODE then
            print("     === Retrieving file ["..MBIN_table[i].."] from clone of original table")
          end
          -- printf("^v^v^v^v^v A0: lessEXML = [%s]",lessEXML)
          -- printf("^v^v^v^v^v A1: #H.EXMLorgTable[lessEXML] = %d",#H.EXMLorgTable[lessEXML])
          H.EXMLmodTable[lessEXML] = H.cloneArray(H.EXMLorgTable[lessEXML]) -- a clone of the original
          -- printf("^v^v^v^v^v A2: #H.EXMLmodTable[lessEXML] = %d",#H.EXMLmodTable[lessEXML])
          
          if H.GetExtensionFromFilePath(MBIN_table[i]) == ".MBIN" then
            -- printf("D3: MBIN_table[%d] = <%s>",i,MBIN_table[i])
            -- this one was already decompiled, delete the .MBIN so we do not decompile it again
            -- all other extension files we keep
            H.DeleteFile([[.\MOD\]]..MBIN_table[i])
          end
          
          -- print(MBIN_table[i].." BEFORE nil "..i)
          MBIN_table[i] = "NIL"
          
        else
          if H.IsFileExist([[.\MOD\]]..MBIN_table[i]..PCExt) then
          -- printf("C1: MBIN_table[%d] = <%s>",i,MBIN_table[i])
            -- file came from a pak, skip
          else
            if not H.IsFileExist([[.\_TEMP\EXTRACTED\]]..MBIN_table[i]..PCExt) then
              -- printf("C2 MBIN_table[%d]..PCExt = <%s>",i,MBIN_table[i]..PCExt)
              -- find it in NMS_PCBANKS paks
              
              -- in which NMSpak?
              local Pak_FileName = H.gFastPAKlist[MBIN_table[i]..PCExt]
              
              if Pak_FileName then
                extractInfo[#extractInfo+1] = {}
                extractInfo[#extractInfo][1] = Pak_FileName
                extractInfo[#extractInfo][2] = MBIN_table[i]..PCExt
                print("   Looking for <"..MBIN_table[i].."> in "..Pak_FileName)
              -- else
                -- print("  <"..MBIN_table[i].."> not found in NMS paks")
              end
              
            else
              -- printf("C3: MBIN_table[%d] = <%s>",i,MBIN_table[i])
              -- file already exists in _TEMP\EXTRACTED
              -- make them all into .MXML
              -- print("X: MBIN_table[i] = ["..MBIN_table[i].."]")
              local EXML_FILE = MBIN_table[i]:gsub(".MBIN",".MXML")
              -- printf("C4:      EXML_FILE = <%s>",EXML_FILE)
              -- print("X:     EXML_FILE = ["..EXML_FILE.."]")
              -- local tmp = [[.\_TEMP\DECOMPILED\]]..EXML_FILE
              -- print([[.\_TEMP\DECOMPILED\]]..EXML_FILE,tmp)
              -- printf([=[H.IsFileExist([[.\_TEMP\DECOMPILED\]]..EXML_FILE) = %s]=],tostring(H.IsFileExist(tmp)))
              if not H.IsFileExist([[.\_TEMP\DECOMPILED\]]..EXML_FILE) then
                -- printf("D1: MBIN_table[%d] = <%s>",i,MBIN_table[i])
                print("   >>> Already extracted, copying to MOD: "..MBIN_table[i])
                H.CopyFile([[.\_TEMP\EXTRACTED\]]..MBIN_table[i]..PCExt,[[.\MOD\]]..MBIN_table[i]..PCExt..[[*]],H.paramFiles)
              else
                -- printf("D2: MBIN_table[%d] = <%s>",i,MBIN_table[i])
                -- print("   >>> Already decompiled, copying to MOD: "..EXML_FILE)
                H.CopyFile([[.\_TEMP\DECOMPILED\]]..EXML_FILE,[[.\MOD\]]..EXML_FILE..[[*]],H.paramFiles)

                -- MAYBE we could open it from DECOMPILED instead of copying to MOD

                if H.GetExtensionFromFilePath(MBIN_table[i]) == ".MBIN" then
                  -- printf("D3: MBIN_table[%d] = <%s>",i,MBIN_table[i])
                  -- this one was already decompiled, delete the .MBIN so we do not decompile it again
                  -- all other extension files we keep
                  H.DeleteFile([[.\MOD\]]..MBIN_table[i]..PCExt)
                end
                -- table.remove(MBIN_table,i)
                -- print(MBIN_table[i].." BEFORE nil "..i)
                MBIN_table[i] = "NIL"
              end -- if not H.IsFileExist([[.\_TEMP\DECOMPILED\]]..EXML_FILE) then
            end -- if not H.IsFileExist([[.\_TEMP\EXTRACTED\]]..MBIN_table[i]) then
          end -- if H.IsFileExist([[.\MOD\]]..MBIN_table[i]) then
        end --if H.EXMLorgTable[strsub(MBIN_table[i]1,-6)] then
      end -- if MBIN_table[i] then
    end -- if #MBIN_table > 0 then
-- H.WFAK("B:")

    MBIN_table = H.refreshTable(MBIN_table)

    -- print(" = = = = = "..#MBIN_table)
    -- -- for i=1,#MBIN_table do
    -- for k,v in pairs(MBIN_table) do
      -- printf("E0: MBIN_table[%d] = <%s>",k,tostring(v))
    -- end
    -- print(" = = = = =")

    -- print("#extractInfo = "..#extractInfo)
    if #extractInfo > 0 then
      print("   >>> Extracting files...")
      -- print("prepare ExtractFromNMSPaks.xml file for psarc.exe extract")
      --    with all the still missing files
      local input = {}
      -- input[#input+1] = "<psarc>"
      input[#input+1] = "{"
      local currentPakName = ""
      for i=1,#extractInfo do
        -- local IsNew = false
        if extractInfo[i][1] ~= "" and currentPakName ~= extractInfo[i][1] then
          -- a new archive
          -- IsNew = true
          currentPakName = extractInfo[i][1]
          -- input[#input+1] = [[    <extract archive="]]..H.gNMS_PCBANKS_FOLDER_PATH..currentPakName..[[" to=".\_TEMP\EXTRACTED" stripall="false" skipmissingfiles="true" overwrite="false">]]
          -- printf("H.gNMS_PCBANKS_FOLDER_PATH = %s",H.gNMS_PCBANKS_FOLDER_PATH)
          -- printf("currentPakName = %s",currentPakName)
          local tmp = (H.gNMS_PCBANKS_FOLDER_PATH..currentPakName):gsub([[/]],[[\]]):gsub([[\]],[[\\]])
          -- printf("tmp = %s",tmp)
          input[#input+1] = [[  "]]..tmp..[=[": []=]
          -- printf("input[#input] = %s",input[#input])
          
          for j=1,#extractInfo do
            if extractInfo[j][1] ~= "" and extractInfo[j][1] == currentPakName then
              -- input[#input+1] = [[        <file archivepath="]]..extractInfo[j][2]..[[" skipifmissing="true" />]]
              -- input[#input+1] = [[    "]]..extractInfo[j][2]:gsub([[/]],[[\]]):gsub([[\]],[[\\]])..[[",]]
              input[#input+1] = [[    "]]..extractInfo[j][2]:gsub([[\]],[[/]]):gsub([[//]],[[/]]):gsub([[GLOBALS/]],[[]])..[[",]]
              extractInfo[j][1] = "" -- to prevent re-use
            end
          end
          
          -- -- input[#input+1] = "    </extract>"
          input[#input] = strsub(input[#input],1,-2) -- remove last ,
          input[#input+1] = "  ],"
        else
          currentPakName = ""
        end
      end -- for i=1,#extractInfo do
      -- input[#input+1] = "</psarc>"
      input[#input] = strsub(input[#input],1,-2) -- remove last ,
      input[#input+1] = "}"

      -- H.WriteToFile(H.ConvertLineTableToText(input),[[ExtractFromNMSPaks.json]])
      H.WriteToFile(input,[[ExtractFromNMSPaks.json]])
      
      -- now use input file to try extracting from ModScript paks
      -- local cmd = [[cmd /c psarc.exe --xml=ExtractFromNMSPaks.xml >Extract_NMSPaksResult.txt]]
      local cmd = [[hgpaktool.exe -U --upper -A -O ".\_TEMP\EXTRACTED" "ExtractFromNMSPaks.json"]]
      local state,sResult,nResult = os.execute(cmd)
      
      -- psarc error (BUG): XML error on line #113, error = 0x80420005 = -2143158267
      --              that is on line with </extract>
      --    no error WHEN at least one file is extracted !!!
      
      -- print("@@@ EXTRACT_B: result = ["..string.format("%s, %s (%d)",state,sResult,nResult).."]")
      -- H.WFAK()
    end
    
    -- print("=========================== "..#MBIN_table)
    -- for i=1,#MBIN_table do
      -- printf("E1: MBIN_table[%d] = <%s>",i,tostring(MBIN_table[i]))
    -- end
    -- print("===========================")
    
    -- local IsDoingDecompile = (#MBIN_table > 0)
    -- printf("A: IsDoingDecompile = %s",tostring(IsDoingDecompile))

    -- print("BEFORE checking if files where extracted: MBIN_table = "..#MBIN_table)
    -- NOT SURE: here all end in .MBIN or .MBIN.PC
    for i=#MBIN_table,1,-1 do
      if MBIN_table[i] then
        local PCExt = ""
        if strfind(MBIN_table[i],".GEOMETRY.",1,true) then
          -- to remember it was a .MBIN.PC file
          PCExt = [[.PC]]
        end

        if H.IsFileExist([[.\_TEMP\EXTRACTED\]]..MBIN_table[i]..PCExt) then
          -- printf("E1: MBIN_table[%d] = <%s>",i,MBIN_table[i])
          H.CopyFile([[.\_TEMP\EXTRACTED\]]..MBIN_table[i]..PCExt,[[.\MOD\]]..MBIN_table[i]..PCExt..[[*]],H.paramFiles)
        end

        if not H.IsFileExist([[.\MOD\]]..MBIN_table[i]..PCExt) then
          print(">>> "..H.gcWARNING.." [WARNING] Could not EXTRACT "..MBIN_table[i]..PCExt.." "..H._zDEFAULT)
          if whichReport == "AMUMSS" then
            H.Report("","Could not EXTRACT "..MBIN_table[i]..PCExt,"WARNING")
          end
        else
          if H.GetExtensionFromFilePath(MBIN_table[i]) ~= ".MBIN" then
            -- this one has an extension that we do not decompile, delete the entry in the table
            -- table.remove(MBIN_table,i)
            MBIN_table[i] = "NIL"
          end
        end
      end
    end -- for i=#MBIN_table,1,-1 do
-- H.WFAK("C:")
    
    MBIN_table = H.refreshTable(MBIN_table)
  
    -- if there are some .MBIN left, it means they were not already decompiled...
    -- presume some files are to be decompiled
    --    NOTE: some MBIN could have been in MEFTI and GlobalMEFTI
    
    --WBERTRO: if change test here to take into account the MEFTI MBINs that were added
    --  that means to also remove code XMBIN, but set a flag or a count indicating there are some
    --  to force the decompiling here
    --  then RenameMBINs are no longer required
    -- test with TEST_SCRIPTS\Test_MBIN_in_MEFTI

    local IsDoingDecompile = (#MBIN_table > 0)
    -- printf("B: IsDoingDecompile = %s",tostring(IsDoingDecompile))
    
    -- if IsDoingDecompile then
      -- for i=1,#MBIN_table do
        -- printf("Y0: MBIN_table[%d] = <%s>",i,MBIN_table[i])
      -- end
    -- end
-- H.WFAKD()            
    if IsDoingDecompile then
      -- print(">>> BEFORE 1st MBINCompiler_D")
      local status,result = H.MBINCompiler_D([[.\MOD]],false,false,true,"",true)
      -- H.printf("status = [%s], result = [%s]",status,result)
      -- print(">>> AFTER 1st MBINCompiler_D")
    end
-- H.WFAKD()            
    
    -- check if all files are decompiled
    for i=#MBIN_table,1,-1 do
      if MBIN_table[i] then
        local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
        if H.IsFileExist([[.\MOD\]]..EXML_FILE) then
          -- printf("Y1: MBIN_table[%d] = <%s>",i,MBIN_table[i])
          
-- discover array_size flags and purge file
HandleArraySize([[.\MOD\]]..EXML_FILE)
          
          H.CopyFile([[.\MOD\]]..EXML_FILE,[[.\_TEMP\DECOMPILED\]]..EXML_FILE..[[*]],H.paramFiles)
          
          local count = 0
          while not H.IsFileExist([[.\_TEMP\DECOMPILED\]]..EXML_FILE) and count < 10 do
            printf("Waiting for %s to exist",EXML_FILE)
            count = count + 1
            H.sleep(1)
          end
          if count >= 10 then
            print(">>> "..H.gcWARNING.." [WARNING] It seems we have a problem copying "..[[.\MOD\]]..EXML_FILE.." "..H._zDEFAULT)
            print(">>> "..H.gcWARNING.."           - Is your drive out of space! "..H._zDEFAULT)
            print(">>> "..H.gcWARNING.."           - Is your path to AMUMSS folder to long! "..H._zDEFAULT)
            print(">>> "..H.gcWARNING.."           - Is there a lock on the folder/file being copied! "..H._zDEFAULT)
          end
          
          -- this one was decompiled, delete the .MBIN
          H.DeleteFile([[.\MOD\]]..MBIN_table[i])
          -- table.remove(MBIN_table,i) -- done already
          MBIN_table[i] = "NIL"
        end
      end
    end
-- H.WFAK("D:")
    
    MBIN_table = H.refreshTable(MBIN_table)
    
    H.switchBACK = false
    if not gIsCompilerVersionsEqual then
      if #MBIN_table > 0 then
        if H.UpdateMODDER_Helper then
          -- for MODDERS
          -- arg MUST be global
          arg[1] = "..\\" -- path to REPORT.lua
          arg[2] = "" -- path to MODBUILDER
          arg[3] = "Decompiling" -- a message
          arg[4] = "keepOpen" -- do NOT close Report
          dofile("CheckMBINCompilerLOG.lua")
        end
        
        -- retry with the other MBINCompiler
        -- print(".BEFORE switch to other MBINCompiler")
        H.SwitchToOtherMBINCompiler(H,whichReport)
        
        -- print(">>> BEFORE 2nd MBINCompiler_D")
        -- now 2nd try to decompile the .MBIN in MOD
        status = H.MBINCompiler_D([[.\MOD]],false,false,true,"",true)
        -- print(">>> AFTER 2nd MBINCompiler_D")
        H.switchBACK = true
        -- SwitchBackToDeclaredMBINCompiler(H,false)
      end
    end
    
    -- H.WFAK("A: Stop BEFORE checking the log...")
    if IsDoingDecompile then
      if not H.gIs_LEAN_MODE then
        print("     >>> Checking MBINCompiler.log...")
      end
      
      -- NOW check the log
      arg[1] = "..\\" -- path to REPORT.lua
      arg[2] = "" -- path to MODBUILDER
      arg[3] = "Decompiling" -- a message
      arg[4] = "keepOpen" -- do NOT close Report
      dofile("CheckMBINCompilerLOG.lua")
      -- print(">>> AFTER CheckMBINCompilerLOG")
      
      if H.IsFileExist([[MBINCompiler_log_BAD.txt]]) then
        -- print(H.gcERROR.."@@@ MBINCompiler reported ERRORs... "..H._zDEFAULT)
        print("     @@@ MBINCompiler reported ERRORs... ")
        local scriptName = _bScriptName
        -- printf("A: scriptName = %s",scriptName)
        if IsCOMBINE_MODS_flag or not H.gIsGlobalIndividual then
          local BATCHNAME = H.LoadFileData("MOD_BATCHNAME.txt")
          if BATCHNAME == "" then
            BATCHNAME = "AMUMSS Combine_999"
          end
          if BATCHNAME ~= "" and H._bTotalNumberScripts > 1 then
            scriptName = BATCHNAME
            -- printf("B: scriptName = %s",scriptName)
          else
            local compFILENAME = H.LoadFileData("Composite_MOD_FILENAME.txt")
            if compFILENAME ~= "" then
              scriptName = compFILENAME..".pak"
              -- printf("C: scriptName = %s",scriptName)
            else
              -- generic message
              if whichReport == "AMUMSS" then
                scriptName = "Check Report"
              elseif whichReport == "CheckMODS" then
                scriptName = "Check Log above"
              else
                scriptName = "Check Info above"
              end
            end
          end
        end
        -- printf("D: scriptName = %s",scriptName)
        H.gModScriptFailed[#H.gModScriptFailed+1] = H._bScriptCounter..": "..scriptName..[[: Failed to decompile some/all files in MODBUILDER\MOD]]
      end
      
      if H.switchBACK then
        SwitchBackToDeclaredMBINCompiler(H,false)
      end
      
      -- for i=1,#MBIN_table do
        -- printf("Z0: MBIN_table[%d] = <%s>",i,MBIN_table[i])
      -- end
      -- print(".after trying to DECOMPILE .MBIN in MOD: MBIN_table = "..#MBIN_table)
      -- here all end in .MBIN or .MBIN.PC
      for i=#MBIN_table,1,-1 do
        if MBIN_table[i] then
          local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
          if not H.IsFileExist([[.\MOD\]]..EXML_FILE) then
            -- reporting handled by CheckMBINCompilerLOG.lua above
            -- print(">>> "..H.gcWARNING.." [WARNING] Could not DECOMPILE "..MBIN_table[i].." "..H._zDEFAULT)
            -- H.Report("","Could not DECOMPILE "..MBIN_table[i],"WARNING")
            
          else
            local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
            -- print([[.before trying to copy .MXML in MOD to _TEMP\DECOMPILED when they came from NMS paks: ]]..EXML_FILE)
            
-- discover array_size flags and purge file
HandleArraySize([[.\MOD\]]..EXML_FILE)
          
            H.CopyFile([[.\MOD\]]..EXML_FILE,[[.\_TEMP\DECOMPILED\]]..EXML_FILE..[[*]],H.paramFiles)
            
            -- this one was decompiled, delete the .MBIN
            H.DeleteFile([[.\MOD\]]..MBIN_table[i])
            -- table.remove(MBIN_table,i) -- done already
            MBIN_table[i] = "NIL"
          end
        end
      end
-- H.WFAK("E:")
      
      MBIN_table = H.refreshTable(MBIN_table)
  
      -- H.WFAK([[Stop BEFORE #MBIN_table > 0...]])
      
      -- for i=1,#MBIN_table do
        -- printf("Z1: MBIN_table[%d] = <%s>",i,MBIN_table[i])
      -- end
      if #MBIN_table > 0 then
        -- check if all MBINs in the list where decompiled
        local IsStillMissing = false
        -- here all end in .MBIN or .MBIN.PC
        for i=#MBIN_table,1,-1 do
          local PCExt = ""
          if strfind(MBIN_table[i],".GEOMETRY.",1,true) then
            PCExt = [[.PC]]
          end

          local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
          if not H.IsFileExist([[.\MOD\]]..EXML_FILE) then
            print(">>> "..H.gcWARNING.." [WARNING] Could not DECOMPILE "..MBIN_table[i]..PCExt.." "..H._zDEFAULT)
            if whichReport == "AMUMSS" then
              H.Report("","Could not DECOMPILE "..MBIN_table[i]..PCExt,"WARNING")
            end
            IsStillMissing = true
            
          else
            local EXML_FILE = MBIN_table[i]:gsub(".MBIN$",".MXML")
            -- print([[.before trying to copy .MXML in MOD to _TEMP\DECOMPILED when they came from NMS paks: ]]..EXML_FILE)
            
-- discover array_size flags and purge file
HandleArraySize([[.\MOD\]]..EXML_FILE)
          
            H.CopyFile([[.\MOD\]]..EXML_FILE, [[.\_TEMP\DECOMPILED\]]..EXML_FILE..[[*]], H.paramFiles)
            
            -- this one was decompiled, delete the .MBIN
            H.DeleteFile([[.\MOD\]]..MBIN_table[i])
            -- table.remove(MBIN_table,i) -- done already
            MBIN_table[i] = "NIL"
          end
        end
      end
-- H.WFAK("F:")
      
      MBIN_table = H.refreshTable(MBIN_table)
  
      if #MBIN_table > 0 then
        -- still some MBIN not decompiled
        print(">>> "..H.gcWARNING.." [WARNING] Some MBIN files could not be found at all! "..H._zDEFAULT)
        if whichReport == "AMUMSS" then
          H.Report("","Some MBIN files could not be found at all!","WARNING")
        end
        -- print(".before FINALLY DeleteFile *.MBIN in MOD")
        -- FINALLY, delete any MBIN left in the list
        for i=1,#MBIN_table do
          H.DeleteFile([[.\MOD\]]..MBIN_table[i])
        end
      end
    end              
    
    -- H.WFAK("Stop BEFORE Delete ALL MBIN in MOD...")

    -- THIS SHOULD BE AT THE END OF GETFRESHSOURCES
    --    we should handle all MBINs (from (GLobal)MEFTI) as if they were fresh ones
    -- RenameMBINs(false)

    -- WBERTRO: and we could try to decompile them
    --    but it involves a lot of jugling with older MBINCompilers

  end -- trying to EXTRACT from NMS paks
-- H.WFAK("G:")

  -- HERE, all MBINs that could be decompiled are in MODBUILDER\MOD and have been copied to MODBUILDER\_TEMP\DECOMPILED
end

--***************************************************************************************************
--handles LuaEndedOk.txt
do -- ALWAYS EXECUTED
  local path = ""
  local MasterPath = os.getenv("_bMASTER_FOLDER_PATH")
  if MasterPath == nil then
    -- print("MasterPath is nil")
    -- H.WFAK()
    MasterPath = lfs.currentdir()
  end
  if strfind(MasterPath,[[\MODBUILDER]],1,true) == nil then
    path = MasterPath..[[MODBUILDER\]]
  end
  -- H.pv("LuaStarting path: ["..path.."]")
  function H.LuaStarting()
    -- H.pv("      +++++++++  LuaStarting  +++++++++")
    if os.remove(path..[[LuaEndedOk.txt]]) then
      -- H.pv("       LuaEndedOk.txt removed")
    end
  end

  function H.LuaEndedOk(Info)
    if Info == nil then Info = "" end
    -- H.pv("       --------  H.LuaEndedOk   -------- "..Info)
    -- H.printf("LuaEndeOk path = [%s] [%s]",path,lfs.currentdir())
    H.WriteToFile("",path..[[LuaEndedOk.txt]])
  end

  if FlagLua == nil then
    H.LuaStarting()
  else
    -- H.pv("FlagLua used!")
  end
end

-- ShowLocals()
-- H.WFAK()

-- H.printf("END H: %s",H.dClock(os.clock()-startH))

-- CurrentKeyWordsAndAll = {}

--[[ do
  -- local seen={}
  -- function H.GetLuaCurrentKeyWordsAndAll(t,tab,AllInfo,parent)
    -- seen[t]=true
    -- local s={}
    -- local n=0
    -- for k in pairs(t) do
      -- n=n+1
      -- s[n]=k
    -- end
    -- table.sort(s)

    -- for k,v in ipairs(s) do
      -- if AllInfo then
        -- parent = parent or ""
        -- print("["..parent..v.."]")
      -- else
        -- print("["..v.."]")
      -- end
      -- table.insert(CurrentKeyWordsAndAll,v)
      -- local possibleParent = v
      -- v=t[v]
      -- if type(v)=="table" and not seen[v] then
        -- if AllInfo then
          -- -- if parent == "" then
            -- parent = possibleParent.."."
          -- -- end
          -- H.GetLuaCurrentKeyWordsAndAll(v,tab.."\t",AllInfo,parent)
          -- parent = ""
        -- end
      -- end
    -- end
  -- end
-- end
--]]
