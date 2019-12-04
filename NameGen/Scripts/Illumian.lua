-- Illumian
require "utilities"

-- general name generation
Illumian = {};

Illumian["Syllables"] = {};
Illumian["ClanNames"] = {};

function Illumian.GetName()
	if utilities.tablelength(Illumian.Syllables) < 1 then
		Illumian.loadSyllables();
	end
	if utilities.tablelength(Illumian.ClanNames) < 1 then
		Illumian.loadClanNames();
	end
	local first = Illumian.GetPersonalName();
	first = first:gsub("^%l", string.upper); -- uppercase first character
	local last = Illumian.GetClanName();
	last = last:gsub("^%l", string.upper); -- uppercase first character
	local name = tostring(last) .. " " .. tostring(first);
	return name;
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
	local clan = Illumian.ClanNames[1][math.random(1, count1)] .. Illumian.ClanNames[2][math.random(1, count2)];
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

return Illumian;