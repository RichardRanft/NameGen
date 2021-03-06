-- generic
require "utilities"

-- general name generation
generic = {};

generic["FirstNames"] = {};
generic["LastNames"] = {};

function generic.GetName(namecount)
	if namecount == nil then
		namecount = 1;
	end
	if utilities.tablelength(generic.FirstNames) < 1 then
		generic.loadFirstNames();
	end
	if utilities.tablelength(generic.LastNames) < 1 then
		generic.loadLastNames();
	end

	local fcount = utilities.tablelength(generic.FirstNames);
	--csLog.LogInfo("generic.lua", tostring(count) .. " first names...");
	local lcount = utilities.tablelength(generic.LastNames);
	--csLog.LogInfo("generic.lua", tostring(count) .. " last names...");
	local names = {};
	for i = 1, namecount do
		local first = generic.FirstNames[math.random(1, fcount)];
		local last = generic.LastNames[math.random(1, lcount)];
		local name = tostring(first) .. " " .. tostring(last);
		table.insert(names, name);
	end
	return names;
end

function generic.loadFirstNames()
	local handle, msg, err = io.open("data\\CSV_Database_of_First_Names.csv");
	math.randomseed(tonumber(os.time()));
	if handle == nil then
	else
		local buffer = handle:read();
		handle:close();
		generic.FirstNames = utilities.split(buffer, '[^,]+');
	end
end

function generic.loadLastNames()
	local handle, msg, err = io.open("data\\CSV_Database_of_Last_Names.csv");
	if handle == nil then
	else
		local buffer = handle:read();
		handle:close();
		generic.LastNames = utilities.split(buffer, '[^,]+');
	end
end

return generic;