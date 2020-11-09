-- RuntimeGMA by Artemking4
-- A library for runtime .gma creation

local f = file

local RTG = { }
RTG.Identity = "GMAD"
RTG.FileDesc = [=[{
	"description": "Description",
	"type": "gamemode",
	"tags": []
}]=]

-- Write a null-terminated string
local function WriteString(file, string)
	file:Write(string)
	file:WriteByte(0)
end

local function RandomString(length, charset)
	charset = charset or "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
	length = length or 16

	math.randomseed(os.clock() ^ 3)

	local out = ""
	for i = 1, #charset do
		out = out .. charset[math.random(1, #charset)]
	end

	return out
end

--[[
	Create a .gma file in garrysmod/data
	name	- path, filename (nil for random name)
	files	- files to write into the addon, format: { ["path/to/file"] = "file contents" }
	title	- Addon title, nil for random
	description	- Addon description, "Generated by RuntimeGMA" by default
]]--
function RTG.Create(name, files, title)
	name = name or RandomString()
	title = title or RandomString()

	local file = file.Open(name, "wb", "DATA")
	if not file then return error("Failed to open file!") end

	file:Write(RTG.Identity)
	file:WriteByte(3) -- Version

	-- SteamID [Unused] --
	file:WriteULong(0)
	file:WriteULong(0)

	-- Timestamp --
	file:WriteULong(os.time())
	file:WriteULong(0)

	file:WriteByte(0) -- Required content, 0 = nothing

	WriteString(file, title)
	WriteString(file, RTG.FileDesc) -- description json
	WriteString(file, "Author Name")

	file:WriteLong(1) -- int32 addon version [Unused]

	-- Now write file records
	local fileNum = 0
	for k,v in pairs(files) do
		if #v == 0 then return error("Empty file!") end

		fileNum = fileNum + 1
		--print(fileNum)
		file:WriteULong(fileNum)
		WriteString(file, k)
		file:WriteULong(string.len(v))
		file:WriteULong(0)
		file:WriteULong(tonumber(util.CRC(v))) -- CRC32
	end
	file:WriteULong(0)

	for k,v in pairs(files) do
		file:Write(v)
	end

	file:Flush()
	file:Close()

	local tmpf = f.Open(name, "r", "DATA")
	local contents = tmpf:Read(tmpf:Size())

	file = f.Open(name, "ab", "DATA")
	file:WriteULong(tonumber(util.CRC(contents))) -- And thats a hack!
end

return RTG
