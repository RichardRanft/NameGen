-- Utilities
utilities = {};

-- utilities.DEBUG output options
utilities.SCRIPT_TEST = false;		-- test mode - generally, print commands instead of executing them.
utilities.DEBUG = false;			-- generally only prints function entry with parameters.
utilities.DEBUGCMD = false;			-- prints actual command strings sent used in utilities functions.
utilities.DEBUGLOG = false;			-- true to send to log file, false to log to console.
utilities.TIMESTAMP = true;			-- true to add timestamps before each log message.
utilities.LOGACTIVE = false;		-- tracks whether the log system is active
utilities.LOGOUTPUT = {};			-- table containing all log output
utilities.LOGFILENAME = "log.txt";	-- default logfile name
utilities.LOGFILEHANDLE = nil;		-- file handle for the log.

function utilities.getOS()
	local separator = package.config:sub(1,1);
	if separator == "/" then 
		return "Linux";
	end
	return "Windows";
end

function utilities.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count;
end

function utilities.list_iter(t)
    local i = 0
    local n = utilities.tablelength(t)
    return function()
        i = i + 1
        if i <= n then return t[i] end
    end
end

function utilities.evalCmdLine(cmdArg, minArgs, maxArgs)
    local listArgs = {};
	if cmdArg == nil then 
		return;
	end
	if utilities.tablelength(cmdArg) > 0 then
		for i = 1, utilities.tablelength(cmdArg), 1 do
			if cmdArg[i] ~= nil then
				listArgs[i] = cmdArg[i];
			end
		end
	end
	if utilities.tablelength(listArgs) < minArgs then
        utilities.logPrint("Too few arguments");
        for i = 1, utilities.tablelength(arg), 1 do
            utilities.logPrint(listArgs[i]);
        end
        return nil;
    end
    if utilities.tablelength(listArgs) >= minArgs and utilities.tablelength(listArgs) > maxArgs then
		utilities.logPrint("Too many arguments");
		for i = 1, utilities.tablelength(listArgs), 1 do
			utilities.logPrint(listArgs[i]);
		end
		return nil;
    end
    return 0;
end

function utilities.startLog(filename)
	if filename ~= nil then
		utilities.LOGFILENAME = filename;
		utilities.LOGFILEHANDLE = io.open(filename, "a+");
		if utilities.LOGFILEHANDLE ~= nil then
			utilities.LOGACTIVE = true;
		end
	end
end

function utilities.logPrint(msg)
	local message = tostring(msg);
	print(" - " .. os.date() .. " " .. message);
	if not utilities.LOGACTIVE then
		return;
	end
    if utilities.LOGACTIVE and utilities.LOGFILEHANDLE ~= nil then
        if utilities.TIMESTAMP then
            utilities.LOGOUTPUT[utilities.tablelength(utilities.LOGOUTPUT) + 1] = os.date() .. " - " ..  message .. "\n";
			utilities.LOGFILEHANDLE:write(utilities.LOGOUTPUT[utilities.tablelength(utilities.LOGOUTPUT)]);
        else
            utilities.LOGOUTPUT[utilities.tablelength(utilities.LOGOUTPUT) + 1] = message .. "\n";
			utilities.LOGFILEHANDLE:write(utilities.LOGOUTPUT[utilities.tablelength(utilities.LOGOUTPUT)]);
        end
		utilities.LOGFILEHANDLE:flush();
    else
		local text = ""
        if utilities.TIMESTAMP then
            text = " --- " .. os.date() .. " ";
        end
        print(text .. msg);
    end
end

function utilities.closeLog()
	if not utilities.LOGACTIVE then
		return;
	end
	if utilities.LOGFILEHANDLE ~= nil then
		utilities.LOGFILEHANDLE:flush();
		utilities.LOGFILEHANDLE:close();
		utilities.LOGACTIVE = false;
	end
end

function utilities.dumpLog()
	if utilities.LOGOUTPUT ~= nil then
		local logdump =  io.open("dump_" .. utilities.LOGFILENAME, "w+");
		for i = 1, utilities.tablelength(utilities.LOGOUTPUT) do
			logdump:write(utilities.LOGOUTPUT[i]);
		end
		logdump:flush();
		logdump:close();
	else
		print(" - No log buffer present.");
	end
end

function utilities.checkLogFile(fileName)
    local LOGFILEHANDLE = io.open(fileName, "r");
    local result = 0;
    if LOGFILEHANDLE == nil then
        abort(" --- Error: unable to open log " .. fileName, 1);
    end
    for line in LOGFILEHANDLE:lines() do
        if line ~= nil then
            if string.find(line, "()0 errors()") == nil and string.find(line, "()Error()") ~= nil then
                result = 2;
            end
        end
    end

    return result;
end

function utilities.dumpOutput(fileHandle, message, filtertbl)
    if message ~= nil then
        utilities.logPrint("" .. tostring(message));
    end
    local result = 0;
    local errorFound = false;
    for line in fileHandle:lines() do
        if line ~= nil then
			if filtertbl ~= nil then
				for filter in utilities.list_iter(filtertbl) do
					if string.find(line, "()" .. tostring(filter) .. "()") ~= nil then
						utilities.logPrint(tostring(filter) .. " found - ");
						errorFound = true;
						result = 2;
					end
				end
			else
				if string.find(line, "()Error()") ~= nil or string.find(line, "()failed()") ~= nil then
					errorFound = true;
					result = 2;
				end
			end
			if string.find(line, "()%c()") == nil then
				utilities.logPrint(" --- " .. tostring(line));
			end
        end
    end
    return result;
end

function utilities.checkError(fileHandle, filtertbl)
    local result = 0;
    local errorFound = false;
    for line in fileHandle:lines() do
        if line ~= nil then
			if filtertbl ~= nil then
				for filter in utilities.list_iter(filtertbl) do
					if string.find(line, "()" .. tostring(filter) .. "()") ~= nil then
						utilities.logPrint(tostring(filter) .. " found - ");
						errorFound = true;
						result = 2;
					end
				end
			else
				if string.find(line, "()Error()") ~= nil or string.find(line, "()failed()") ~= nil then
					errorFound = true;
					result = 2;
					break;
				end
			end
        end
    end
    if errorFound then
        utilities.logPrint(" --- " .. line);
        utilities.abort(" --- " .. line, result);
    end
    return result;
end

function utilities.checkResult(result, message)
    if result ~= true and result ~= 0 then
        if message == nil then
            message = "empty message: nil";
        end
        utilities.abort(" --- " .. message .. " step failed", result);
    end
end

function utilities.abort(reason, code)
    utilities.logPrint(reason);
    if utilities.DEBUGLOG and utilities.LOGFILEHANDLE ~= nil then
        utilities.LOGFILEHANDLE:flush();
        utilities.LOGFILEHANDLE:close();
    end

    os.exit(code, true);
end

function utilities.executeCmd(command)
    if utilities.DEBUGCMD then
        utilities.logPrint(command);
    end
    local handle, msg, err = io.popen(command);
    local result = 0;
    if handle ~= nil then
        if utilities.DEBUGCMD then
            result = utilities.dumpOutput(handle, command);
        else
            result = utilities.checkError(handle);
        end
	else
		utilities.logPrint("Command failed: " .. tostring(err) .. " " .. tostring(msg));
    end
    return result;
end

function utilities.getFileList(path, filter)
    if path == nil then
        path = "./";
    end
	if filter == nil then
		filter = "*";
	end
    if utilities.DEBUG then
        utilities.logPrint("getFileList(" .. path .. ")");
    end
	local environment = utilities.getOS();
    local command = ""
	if environment == "Linux" then
		command = "ls " .. path .. filter;
	else
		commmand = "dir " .. path .. filter;
	end
    if utilities.DEBUGCMD then
        utilities.logPrint(command);
    end
    local handle = io.popen(command);
    local result = 0;
    local fileList = {};
    local i = 1;
    if handle ~= nil then
        for line in handle:lines() do
            if line ~= nil then
                if utilities.DEBUG then
                    utilities.logPrint("" .. line);
                end
                fileList[i] = line;
                i = i + 1;
            end
        end
    end
    return fileList;
end

function utilities.getFiles(path)
	utilities.logPrint("getFiles(\"" .. path .. "\")...");
	-- want only files, but not "bare" so we can get file dates
	local dirCmd = "if exist " .. path .. " dir /a:-d " .. path;
	if OperatingSystem == nil then
		OperatingSystem = utilities.getOS();
	end
	if OperatingSystem == "Linux" then
		dirCmd = "ls -l " .. path .. " | awk \'{print $9}\'";
	end
	--print(dirCmd);
	local filelist = {};
	local dirs = io.popen(dirCmd);
	if dirs ~= nil then
		if OperatingSystem == "Windows" then
			local currentLine = 0;
			for line in dirs:lines() do
				--print(line);
				currentLine = currentLine + 1;
				if currentLine > 5 then
					local begin = string.sub(line, 1, 2);
					if string.len(line) > 0 and string.find(begin, "%s") == nil then
						local parts = utilities.split(line, "[%.%-_/:%w]+");
						--local partcount = 0;
						--for part in utilities.list_iter(parts) do
							--partcount = partcount + 1;
							--print(tostring(partcount) .. " : " .. part);
						--end
						local file = parts[utilities.tablelength(parts)];
						local fileentry = {};
						fileentry["File"] = file;
						fileentry["Path"] = path .. "\\" .. file;
						fileentry["Folder"] = path;
						fileentry["Date"] = parts[1];
						fileentry["Time"] = parts[2] .. " " .. parts[3];
						table.insert(filelist, fileentry);
					end
				end
			end
		else
			for file in dirs:lines() do
				if file ~= nil and string.len(file) > 0 then
					local index = utilities.tablelength(filelist) + 1;
					fileentry = {};
					fileentry["File"] = file;
					fileentry["Path"] = path .. file;
					fileentry["Folder"] = path;
					table.insert(filelist, fileentry);
				end
			end
		end
	end
	utilities.logPrint("getFiles() done.");
	return filelist;
end

function utilities.findFiles(path, filter)
	utilities.logPrint("findFiles(\"" .. path .. "\")...");
	-- want only files, but not "bare" so we can get file dates
	local dirCmd = "if exist " .. path .. " dir /a:-d /s " .. path .. "\\" .. filter;
	if OperatingSystem == nil then
		OperatingSystem = utilities.getOS();
	end
	if OperatingSystem == "Linux" then
		dirCmd = "ls -l " .. path .. " | awk \'{print $9}\'";
	end
	--print(dirCmd);
	local filelist = {};
	local currentPath = "";
	local buffer = io.popen(dirCmd);
	if buffer ~= nil then
		if OperatingSystem == "Windows" then
			local currentLine = 0;
			for line in buffer:lines() do
				--print(line);
				currentLine = currentLine + 1;
				if currentLine > 3 and line ~= nil and string.len(line) > 0 then
					if string.find(line, " Directory of ") ~= nil then
						local path = string.gsub(line, " Directory of ", "");
						if path ~= currentPath then
							currentPath = path;
						end
					else
						local begin = string.sub(line, 1, 2);
						if string.len(line) > 0 and string.find(begin, "%s") == nil then
							local parts = utilities.split(line, "[%.%-_/:%w]+");
							--local partcount = 0;
							--for part in utilities.list_iter(parts) do
								--partcount = partcount + 1;
								--print(tostring(partcount) .. " : " .. part);
							--end
							local file = parts[utilities.tablelength(parts)];
							local fileentry = {};
							fileentry["File"] = file;
							fileentry["Path"] = currentPath .. "\\" .. file;
							fileentry["Folder"] = currentPath;
							fileentry["Date"] = parts[1];
							fileentry["Time"] = parts[2] .. " " .. parts[3];
							table.insert(filelist, fileentry);
						end
					end
				end
			end
		else
			for file in dirs:lines() do
				if file ~= nil and string.len(file) > 0 then
					local index = utilities.tablelength(filelist) + 1;
					fileentry = {};
					fileentry["File"] = file;
					fileentry["Path"] = path .. file;
					fileentry["Folder"] = path;
					table.insert(filelist, fileentry);
				end
			end
		end
	end
	utilities.logPrint("findFiles() done.");
	return filelist;
end

function utilities.getSubDirs(path)
	utilities.logPrint("getSubDirs(" .. path .. ")");
	local dirCmd = "if exist " .. path .. " dir /a:d " .. path;
	--print(dirCmd);
	--utilities.logPrint("get subdirectories for : " .. path);
	local dirlist = {};
	local dirs = io.popen(dirCmd);
	if dirs ~= nil then
		for line in dirs:lines() do
			local begin = string.sub(line, 1, 2);
			if string.len(line) > 0 and string.find(begin, "%s") == nil then
				local parts = utilities.split(line, "[%.%-_/:%w]+");
				local folder = parts[utilities.tablelength(parts)];
				if folder ~= "." and folder ~= ".." then
					folderInfo = {};
					folderInfo["Folder"] = folder;
					folderInfo["Path"] = path .. "\\" .. folder;
					folderInfo["Date"] = parts[1];
					folderInfo["Time"] = parts[2] .. " " .. parts[3];
					table.insert(dirlist, folderInfo);
					--utilities.logPrint("add folder : " .. line);
				end
			end
		end
	end
	return dirlist;
end

function utilities.wait(seconds)
    if seconds == nil then
        utilities.logPrint("wait() - seconds is nil");
        return 29;
    end
    if utilities.DEBUG then
        utilities.logPrint("wait() : " .. seconds);
    end
    os.execute("sleep " .. tonumber(seconds));
    return 0;
end

function utilities.split(text, pattern)
    local count = 1;
    local wordList = {};
    if pattern == nil then
        pattern = "[_%w]+";
    end
    for w in string.gmatch(text, pattern) do
        wordList[count] = w;
        --print(wordList[count]);
        count = count + 1;
    end
    return wordList;
end

function utilities.file_exists(name)
	local f = io.open(name,"r")
	if f ~= nil then 
		io.close(f);
		--print("file_exists: " .. name .. " found.");
		return true;
	else 
	--print("file_exists: " .. name .. " not found.");
	end
	return false;
end

-- <param: source> - if path has spaces, include quotes.
-- <param: target> - if path has spaces, include quotes.
-- <param: flags> - Additional flags, like /s, /e, or others.
-- <param: files> - files to include.  Must be "" if you wish to use exclusions.
-- <param: exclusions> - files to exclude.
-- <returns> - true if successful, false if there are errors.
function utilities.robocopy(source, target, flags, files, exclusions)
	local opt = " /z /np /njh /xo";
	local needSourceQuotes = (string.find(source, "%w") ~= nil and string.find(source, "()\"()") == nil);
	if needSourceQuotes then
		source = "\"" .. source .. "\"";
	end
	local needTargetQuotes = (string.find(target, "%w") ~= nil and string.find(target, "()\"()") == nil);
	if needTargetQuotes then
		target = "\"" .. target .. "\"";
	end
	local cmd = "robocopy " .. source .. " " .. target;
	if files ~= nil and string.len(files) > 0 then
		cmd = cmd .. " " .. files;
	end
	cmd = cmd .. opt;
	if exclusions ~= nil and string.len(exclusions) > 0 then
		cmd = cmd .. " /xf " .. exclusions;
	end
	cmd = cmd .. " /r:20 ";
	if flags ~= nil then
		cmd = cmd .. flags;
	end
	cmd = cmd .. " 2>&1";
	local success = true;
	local status = {};
	if utilities.SCRIPT_TEST then
		utilities.logPrint("utilities.Robocopy() --");
		utilities.logPrint(cmd);
		status["Total"] = 0;
		status["Copied"] = 0;
		status["Skipped"] = 0;
		status["Failed"] = 0;
		return success, status;
	end
	local handle, msg, err = io.popen(cmd);
	local buffer = {};
	if handle ~= nil then
		if msg ~= nil then
			utilities.logPrint(tostring(msg));
		end
		if err ~= nil then --and err >= 4 then
			utilities.logPrint("Robocopy encountered an issue: " .. tostring(err) .. " " .. tostring(msg));
			success = false;
		end
		for line in handle:lines() do
			if string.find(line, "ERROR") ~= nil and string.find(line, "%(0x00") ~= nil then
				local parts = utilities.split(line);
				err = tonumber(parts[8]);
				utilities.logPrint("Robocopy encountered an issue: " .. tostring(err) .. " " .. tostring(line));
				if err >= 2 then
					success = false;
				end
			end
			table.insert(buffer, line);
		end
	else
		if msg ~= nil then
			utilities.logPrint(tostring(msg));
		end
		if err ~= nil then --and err >= 4 then
			utilities.logPrint("Robocopy encountered an issue: " .. tostring(err) .. " " .. tostring(msg));
			success = false;
		end
		utilities.logPrint("Error copying " .. source .. " to " .. target .. ".");
		os.exit(1, true);
	end
	for line in utilities.list_iter(buffer) do
		if success then
			if string.find(line, "Files :") ~= nil then
				--print(line);
				utilities.logPrint("-------");
				utilities.logPrint(source ..  " > " .. target);
				local parts = utilities.split(line);
				utilities.logPrint("Total   : " .. tonumber(parts[2]));
				status["Total"] = tonumber(parts[2]);
				utilities.logPrint("Copied  : " .. tonumber(parts[3]));
				status["Copied"] = tonumber(parts[3]);
				utilities.logPrint("Skipped : " .. tonumber(parts[4]));
				status["Skipped"] = tonumber(parts[4]);
				utilities.logPrint("Failed  : " .. tonumber(parts[6]));
				status["Failed"] = tonumber(parts[6]);
				utilities.logPrint("-------");
			end
		else
			utilities.logPrint(line);
		end
	end
	if not success then
		utilities.logPrint("Robocopy encountered an issue: " .. tostring(err) .. " " .. tostring(msg));
		utilities.logPrint("Error copying " .. source .. " to " .. target .. ".");
	end
	return success, status;
end

function utilities.directory_exists( sPath )
	if type( sPath ) ~= "string" then return false end

	local response = os.execute( "cd " .. sPath )
	if response == 0 or response then
		return true
	end
	return false
end

function utilities.getEnvironment()
	local cmd = "set";
	if utilities.getOS() == "Linux" then
		cmd = "env";
	end
    local handle, msg, err = io.popen(cmd);
	local env = {};
	if handle ~= nil then
		for line in handle:lines() do
			local parts = utilities.split(line, "[^=]+");
			if utilities.tablelength(parts) > 1 then
				local label = parts[1];
				local value = parts[2];
				env[label] = value;
			end
		end
	end
	local keys={};
	local n=0

	for k,v in pairs(env) do
	  n=n+1
	  keys[n]=k
	end
	table.sort(keys);
	return env, keys;
end

return utilities;