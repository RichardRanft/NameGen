-- Raathan
require "utilities"

-- general name generation
Raathan = {};

Raathan["FirstSyllables"] = {};
Raathan["LastSyllables"] = {};

function Raathan.GetName(namecount)
	if namecount == nil then
		namecount = 1;
		--csLog.LogInfo("Raathan.lua", "namecount is nil, setting to 1");
	end
	if utilities.tablelength(Raathan.FirstSyllables) < 1 or utilities.tablelength(Raathan.LastSyllables) < 1 then
		Raathan.loadSyllables();
	end
	local names = {};
	for i = 1, namecount do
		--csLog.LogInfo("Raathan.lua", "GetName() generating " .. tostring(i));
		local first = Raathan.GetPersonalName();
		first = first:gsub("^%l", string.upper);  --uppercase first character
		local last = Raathan.GetClanName();
		last = last:gsub("^%l", string.upper);  --uppercase first character
		local name = tostring(first) .. " " .. tostring(last);
		table.insert(names, name);
	end
	--csLog.LogInfo("Raathan.lua", "GetName() returning " .. tostring(utilities.tablelength(names)) .. " names");
	return names;
end

function Raathan.GetPersonalName()
	local name = "";
	local count = tonumber(utilities.tablelength(Raathan.FirstSyllables));
	local limit = Raathan.FirstSyllables[count - 1].Count;
	local scount = math.random(2, 4);
	for i = 1, scount do
		local value = math.random(1, limit);
		local part = "";
		for i = 1, count do
			if Raathan.FirstSyllables[i].Count <= value then
				part = Raathan.FirstSyllables[i].Syllable;
			end
		end
		name = name .. part;
	end
	return name;
end

function Raathan.GetClanName()
	local name = "";
	local count = tonumber(utilities.tablelength(Raathan.LastSyllables));
	local limit = Raathan.LastSyllables[count - 1].Count;
	local scount = math.random(3, 5);
	for i = 1, scount do
		local value = math.random(1, limit);
		local part = "";
		for i = 1, count do
			if Raathan.LastSyllables[i].Count <= value then
				part = Raathan.LastSyllables[i].Syllable;
			end
		end
		name = name .. part;
	end
	return name;
end

function Raathan.loadSyllables()
	local handle, msg, err = io.open("Data\\CSV_Database_of_First_Names.xml.csv");
	math.randomseed(tonumber(os.time()));
	if handle == nil then
		csLog.LogError("Raathan.lua", "Unable to open data\\CSV_Database_of_First_Names.xml.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local buffer = handle:read();
		handle:close();
		local entries = utilities.split(buffer, '[^,]+');
		local count = 0;
		for i = 1, utilities.tablelength(entries) do
			local entry = {};
			local parts = utilities.split(entries[i], '[^:]+');
			entry["Syllable"] = parts[1];
			count = count + tonumber(parts[2]);
			entry["Count"] = count;
			table.insert(Raathan.FirstSyllables, entry);
		end
	end
	handle, msg, err = io.open("data\\CSV_Database_of_Last_Names.xml.csv");
	math.randomseed(tonumber(os.time()));
	if handle == nil then
		csLog.LogError("Raathan.lua", "Unable to open data\\CSV_Database_of_Last_Names.xml.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local buffer = handle:read();
		handle:close();
		local entries = utilities.split(buffer, '[^,]+');
		local count = 0;
		for i = 1, utilities.tablelength(entries) do
			local entry = {};
			local parts = utilities.split(entries[i], '[^:]+');
			entry["Syllable"] = parts[1];
			count = count + tonumber(parts[2]);
			entry["Count"] = count;
			table.insert(Raathan.LastSyllables, entry);
		end
	end
end

return Raathan;