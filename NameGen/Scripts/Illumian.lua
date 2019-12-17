-- Illumian
require "utilities"

-- general name generation
Illumian = {};

Illumian["Syllables"] = {};
Illumian["ClanNames"] = {};
Illumian["ClanParts"] = {};

function Illumian.GetName(namecount)
	if namecount == nil then
		namecount = 1;
		--csLog.LogInfo("Illumian.lua", "namecount is nil, setting to 1");
	end
	if utilities.tablelength(Illumian.Syllables) < 1 then
		Illumian.loadSyllables();
	end
	if utilities.tablelength(Illumian.ClanNames) < 1 then
		Illumian.loadClanNames();
	end
	if utilities.tablelength(Illumian.ClanParts) < 1 then
		Illumian.loadClanParts();
	end
	local names = {};
	for i = 1, namecount do
		--csLog.LogInfo("Illumian.lua", "GetName() generating " .. tostring(i));
		local first = Illumian.GetPersonalName();
		first = first:gsub("^%l", string.upper); -- uppercase first character
		local last = Illumian.GetClanName();
		last = last:gsub("^%l", string.upper); -- uppercase first character
		local name = tostring(last) .. " " .. tostring(first);
		table.insert(names, name);
	end
	--csLog.LogInfo("Illumian.lua", "GetName() returning " .. tostring(utilities.tablelength(names)) .. " names");
	return names;
end

function Illumian.GetPersonalName()
	local name = "";
	local count = utilities.tablelength(Illumian.Syllables);
	local scount = math.random(2, 3);
	for i = 1, scount do
		name = name .. Illumian.Syllables[math.random(1, count)];
	end
	return name;
end


function Illumian.GetClanName()
	local count1 = utilities.tablelength(Illumian.ClanNames[1]);
	local count2 = utilities.tablelength(Illumian.ClanNames[2]);
	local clan1 = Illumian.ClanNames[1][math.random(1, count1)];
	local clan2 = Illumian.ClanNames[2][math.random(1, count2)];
	if string.find(clan1, "%[") ~= nil then
		clan1 = Illumian.ClanParts[clan1][math.random(1, utilities.tablelength(Illumian.ClanParts[clan1]))];
	end
	if string.find(clan2, "%[") ~= nil then
		clan2 = Illumian.ClanParts[clan2][math.random(1, utilities.tablelength(Illumian.ClanParts[clan2]))];
	end
	local clan = clan1 .. clan2;
	return clan;
end

function Illumian.loadSyllables()
	local handle, msg, err = io.open("data\\CSV_Illuminan_Syllables.csv");
	math.randomseed(tonumber(os.time()));
	if handle == nil then
		csLog.LogError("Illumian.lua", "Unable to open data\\CSV_Illuminan_Syllables.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local buffer = handle:read();
		handle:close();
		Illumian.Syllables = utilities.split(buffer, '[^,]+');
	end
end

function Illumian.loadClanNames()
	local handle, msg, err = io.open("data\\CSV_Illuminan_Clans.csv");
	if handle == nil then
		csLog.LogError("Illumian.lua", "Unable to open data\\CSV_Illuminan_Clans.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		for line in handle:lines() do
			local entries = utilities.split(line, '[^,]+');
			table.insert(Illumian.ClanNames, entries);
		end
		handle:close();
	end
end

function Illumian.loadClanParts()
	--csLog.LogInfo("Illumian.lua", "loadClanParts()");
	local handle, msg, err = io.open("data\\CSV_Illuminan_Clan_Parts.csv");
	if handle == nil then
		csLog.LogError("Illumian.lua", "Unable to open data\\CSV_Illuminan_Clan_Parts.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local currTable = "";
		for line in handle:lines() do
			if string.find(line, "%[") ~= nil then
				currTable = line;
				Illumian.ClanParts[currTable] = {};
				--csLog.LogInfo("Illumian.lua", "loadClanParts() - Adding table " .. currTable);
			else
				local entries = utilities.split(line, '[^,]+');
				for entry in utilities.list_iter(entries) do
					--csLog.LogInfo("Illumian.lua", "loadClanParts() - Adding " .. tostring(entry) .. " to " .. tostring(currTable));
					table.insert(Illumian.ClanParts[currTable], entry);
				end
			end
		end
		handle:close();
	end
end

return Illumian;