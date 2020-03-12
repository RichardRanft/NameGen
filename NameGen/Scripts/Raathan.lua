-- Raathan
require "utilities"

-- general name generation
Raathan = {};

Raathan["Syllables"] = {};
Raathan["ClanNames"] = {};
Raathan["ClanParts"] = {};

function Raathan.GetName(namecount)
	if namecount == nil then
		namecount = 1;
		--csLog.LogInfo("Raathan.lua", "namecount is nil, setting to 1");
	end
	if utilities.tablelength(Raathan.Syllables) < 1 then
		Raathan.loadSyllables();
	end
	if utilities.tablelength(Raathan.ClanNames) < 1 then
		Raathan.loadClanNames();
	end
	if utilities.tablelength(Raathan.ClanParts) < 1 then
		Raathan.loadClanParts();
	end
	local names = {};
	for i = 1, namecount do
		--csLog.LogInfo("Raathan.lua", "GetName() generating " .. tostring(i));
		local first = Raathan.GetPersonalName();
		first = first:gsub("^%l", string.upper); -- uppercase first character
		local last = Raathan.GetClanName();
		last = last:gsub("^%l", string.upper); -- uppercase first character
		local name = tostring(first) .. " " .. tostring(last);
		table.insert(names, name);
	end
	--csLog.LogInfo("Raathan.lua", "GetName() returning " .. tostring(utilities.tablelength(names)) .. " names");
	return names;
end

function Raathan.GetPersonalName()
	local name = "";
	local count = utilities.tablelength(Raathan.Syllables);
	local scount = math.random(2, 3);
	for i = 1, scount do
		name = name .. Raathan.Syllables[math.random(1, count)];
	end
	return name;
end

function Raathan.GetClanName()
	local count1 = utilities.tablelength(Raathan.ClanNames[1]);
	local count2 = utilities.tablelength(Raathan.ClanNames[2]);
	local clan1 = Raathan.ClanNames[1][math.random(1, count1)];
	local clan2 = Raathan.ClanNames[2][math.random(1, count2)];
	if string.find(clan1, "%[") ~= nil then
		clan1 = Raathan.ClanParts[clan1][math.random(1, utilities.tablelength(Raathan.ClanParts[clan1]))];
		while string.find(clan2, "%[") ~= nil do
			clan2 = Raathan.ClanNames[2][math.random(1, count2)];
		end
	elseif string.find(clan2, "%[") ~= nil then
		clan2 = Raathan.ClanParts[clan2][math.random(1, utilities.tablelength(Raathan.ClanParts[clan2]))];
		while string.find(clan1, "%[") ~= nil do
			clan1 = Raathan.ClanNames[1][math.random(1, count1)];
		end
	end
	local clan = clan1 .. clan2;
	return clan;
end

function Raathan.loadSyllables()
	local handle, msg, err = io.open("data\\CSV_Illuminan_Syllables.csv");
	math.randomseed(tonumber(os.time()));
	if handle == nil then
		csLog.LogError("Raathan.lua", "Unable to open data\\CSV_Illuminan_Syllables.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local buffer = handle:read();
		handle:close();
		Raathan.Syllables = utilities.split(buffer, '[^,]+');
	end
end

function Raathan.loadClanNames()
	local handle, msg, err = io.open("data\\CSV_Illuminan_Clans.csv");
	if handle == nil then
		csLog.LogError("Raathan.lua", "Unable to open data\\CSV_Illuminan_Clans.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		for line in handle:lines() do
			local entries = utilities.split(line, '[^,]+');
			table.insert(Raathan.ClanNames, entries);
		end
		handle:close();
	end
end

function Raathan.loadClanParts()
	--csLog.LogInfo("Raathan.lua", "loadClanParts()");
	local handle, msg, err = io.open("data\\CSV_Illuminan_Clan_Parts.csv");
	if handle == nil then
		csLog.LogError("Raathan.lua", "Unable to open data\\CSV_Illuminan_Clan_Parts.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local currTable = "";
		for line in handle:lines() do
			if string.find(line, "%[") ~= nil then
				currTable = line;
				Raathan.ClanParts[currTable] = {};
				--csLog.LogInfo("Raathan.lua", "loadClanParts() - Adding table " .. currTable);
			else
				local entries = utilities.split(line, '[^,]+');
				for entry in utilities.list_iter(entries) do
					--csLog.LogInfo("Raathan.lua", "loadClanParts() - Adding " .. tostring(entry) .. " to " .. tostring(currTable));
					table.insert(Raathan.ClanParts[currTable], entry);
				end
			end
		end
		handle:close();
	end
end

return Raathan;