-- Illumian_b
require "utilities"

-- general name generation
Illumian_b = {};

Illumian_b["Seed"] = 0;
Illumian_b["Syllables"] = {};
Illumian_b["FirstNames"] = {};
Illumian_b["LastNames"] = {};
Illumian_b["SyllableLen"] = 3;
Illumian_b["Multiplier"] = 4096;

function Illumian_b.GetName(namecount)
	if namecount == nil then
		namecount = 1;
		--csLog.LogInfo("Illumian_b.lua", "namecount is nil, setting to 1");
	end
	if utilities.tablelength(Illumian_b.Syllables) < 1 then
		Illumian_b.loadSyllables();
	end
	if utilities.tablelength(Illumian_b.FirstNames) < 1 then
		Illumian_b.loadFirstNames();
	end
	if utilities.tablelength(Illumian_b.LastNames) < 1 then
		Illumian_b.loadLastNames();
	end
	if Illumian_b.Seed == nil then
		Illumian_b.Seed = tonumber(os.time());
	end
	math.randomseed(math.random(1, Illumian_b.Seed));
	local nameTbl = {};
	for i = 1, namecount do
		--csLog.LogInfo("Illumian_b.lua", "GetName() generating " .. tostring(i));
		local first = Illumian_b.GetPersonalName();
		local last = Illumian_b.GetClanName();
		local entry = {};
		entry["First"] = first;
		entry["Last"] = last;
		table.insert(nameTbl, entry);
	end
	--csLog.LogInfo("Illumian_b.lua", "GetName() returning " .. tostring(utilities.tablelength(names)) .. " names");
	local names = {};
	for entry in utilities.list_iter(nameTbl) do
		local name = Illumian_b.TranslateName(entry.First, entry.Last);
		--csLog.LogInfo("Illumian_b.lua", "GetName() " .. entry.First .. " " .. entry.Last .. " : " .. name);
		table.insert(names, name);
	end
	return names;
end

function Illumian_b.TranslateName(first, last)
	count = utilities.tablelength(Illumian_b.Syllables);
	local name = "";
	local scount = math.floor(string.len(first) / Illumian_b.SyllableLen) + 1;
	math.randomseed(Illumian_b.GetSeed(first));
	local fname = "";
	for i = 1, scount do
		fname = fname .. Illumian_b.Syllables[math.random(1, count)];
	end
	fname = fname:gsub("^%l", string.upper); -- uppercase first character
	scount = math.floor(string.len(last) / Illumian_b.SyllableLen) + 1;
	math.randomseed(Illumian_b.GetSeed(last));
	local lname = "";
	for i = 1, scount do
		lname = lname .. Illumian_b.Syllables[math.random(1, count)];
	end
	lname = lname:gsub("^%l", string.upper); -- uppercase first character
	return fname .. " " .. lname;
end

function Illumian_b.GetPersonalName()
	local count = utilities.tablelength(Illumian_b.FirstNames);
	local name = Illumian_b.FirstNames[math.random(1, count)];
	--csLog.LogInfo("Illumian_b.lua", "GetPersonalName() - tempName is " .. tostring(tempName));
	return name;
end


function Illumian_b.GetClanName()
	local count = utilities.tablelength(Illumian_b.LastNames);
	local name = Illumian_b.LastNames[math.random(1, count)];
	--csLog.LogInfo("Illumian_b.lua", "GetClanName() - tempName is " .. tostring(tempName));
	return name;
end

function Illumian_b.GetSeed(tempName)
	local seed = 1;
	local seedstr = string.lower(tempName);
	local seeds = {};
	local eos = i;
	local c = string.sub(seedstr, 1, 1);
	table.insert(seeds, tonumber(string.byte(tostring(c))));
	for i = 1, string.len(seedstr) do
		eos = i;
		c = string.sub(seedstr, i, eos);
		if string.len(seedstr) < Illumian_b.SyllableLen then
			table.insert(seeds, tonumber(string.byte(tostring(c))));
		elseif i%Illumian_b.SyllableLen == 0 then
			table.insert(seeds, tonumber(string.byte(tostring(c))));
		end
	end
	for s in utilities.list_iter(seeds) do
		seed = (seed / Illumian_b.SyllableLen) + seed + (s * Illumian_b.Multiplier);
	end
	return seed;
end

function Illumian_b.loadSyllables()
	local handle, msg, err = io.open("data\\CSV_Illuminan_Syllables.csv");
	Illumian_b.Seed = tonumber(os.time());
	math.randomseed(Illumian_b.Seed);
	if handle == nil then
		csLog.LogError("Illumian_b.lua", "Unable to open data\\CSV_Illuminan_Syllables.csv");
		csLog.LogError(tostring(err) .. ": ".. tostring(msg));
	else
		local buffer = handle:read();
		handle:close();
		Illumian_b.Syllables = utilities.split(buffer, '[^,]+');
	end
end

function Illumian_b.loadFirstNames()
	local handle, msg, err = io.open("data\\CSV_Database_of_First_Names.csv");
	if handle == nil then
	else
		local buffer = handle:read();
		handle:close();
		Illumian_b.FirstNames = utilities.split(buffer, '[^,]+');
	end
end

function Illumian_b.loadLastNames()
	local handle, msg, err = io.open("data\\CSV_Database_of_Last_Names.csv");
	if handle == nil then
	else
		local buffer = handle:read();
		handle:close();
		Illumian_b.LastNames = utilities.split(buffer, '[^,]+');
	end
end

return Illumian_b;