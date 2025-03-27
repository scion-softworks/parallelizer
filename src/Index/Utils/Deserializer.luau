--!native
--!optimize 2

local Types = require(script.Parent.Parent.types)
local Deserializer = {}

local pi = math.pi

local band = bit32.band
local rshift = bit32.rshift

local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32
local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local readstring = buffer.readstring

function Deserializer.deserialize(buf: buffer, cursor: number, dataType: string): (Types.SerializableValues, number)
	local value: Types.SerializableValues

	if dataType == 'u8' then
		value = readu8(buf, cursor)
		cursor += 1
	elseif dataType == 'u16' then
		value = readu16(buf, cursor)
		cursor += 2
	elseif dataType == 'u32' then
		value = readu32(buf, cursor)
		cursor += 4
	elseif dataType == 'i8' then
		value = readi8(buf, cursor)
		cursor += 1
	elseif dataType == 'i16' then
		value = readi16(buf, cursor)
		cursor += 2
	elseif dataType == 'i32' then
		value = readi32(buf, cursor)
		cursor += 4
	elseif dataType == 'f32' then
		value = readf32(buf, cursor)
		cursor += 4
	elseif dataType == 'f64' then
		value = readf64(buf, cursor)
		cursor += 8
	elseif dataType == 'bool' then
	  	value = readu8(buf, cursor) ~= 0
		cursor += 1
	elseif dataType == 'str' then
		local len = readu32(buf, cursor)
		cursor += 4
		value = readstring(buf, cursor, len)
		cursor += len
	elseif dataType == 'v3' then
		local x = readf64(buf, cursor)
		cursor += 8
		local y = readf64(buf, cursor)
		cursor += 8
		local z = readf64(buf, cursor)
		cursor += 8
		value = Vector3.new(x, y, z)
	elseif dataType == 'v3i16' then
		local x = readi16(buf, cursor)
		cursor += 2
		local y = readi16(buf, cursor)
		cursor += 2
		local z = readi16(buf, cursor)
		cursor += 2
		value = Vector3.new(x, y, z)
	elseif dataType == 'v2' then
		local x = readf64(buf, cursor)
		cursor += 8
		local y = readf64(buf, cursor)
		cursor += 8
		value = Vector2.new(x, y)
	elseif dataType == 'v2i16' then
		local x = readi16(buf, cursor)
		cursor += 2
		local y = readi16(buf, cursor)
		cursor += 2
		value = Vector2.new(x, y)
	elseif dataType == 'cframe' then
		local x = readf64(buf, cursor)
		cursor += 8
		local y = readf64(buf, cursor)
		cursor += 8
		local z = readf64(buf, cursor)
		cursor += 8

		local rx = readf64(buf, cursor)
		cursor += 8
		local ry = readf64(buf, cursor)
		cursor += 8
		local rz = readf64(buf, cursor)
		cursor += 8
		value = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
	elseif dataType == 'cframef32' then
		local x = readf32(buf, cursor)
		cursor += 4
		local y = readf32(buf, cursor)
		cursor += 4
		local z = readf32(buf, cursor)
		cursor += 4
	
		local rx = readf32(buf, cursor)
		cursor += 4
		local ry = readf32(buf, cursor)
		cursor += 4
		local rz = readf32(buf, cursor)
		cursor += 4
		value = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
	elseif dataType == 'cframe18' then
		local x = readf32(buf, cursor)
		cursor += 4
		local y = readf32(buf, cursor)
		cursor += 4
		local z = readf32(buf, cursor)
		cursor += 4

		local qrx = readi16(buf, cursor)
		cursor += 2
		local qry = readi16(buf, cursor)
		cursor += 2
		local qrz = readi16(buf, cursor)
		cursor += 2

		local rx = (qrx / 65535) * (pi - (-pi)) + (-pi)
		local ry = (qry / 65535) * (pi - (-pi)) + (-pi)
		local rz = (qrz / 65535) * (pi - (-pi)) + (-pi)

		value = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
	elseif dataType == 'color3' then
		local r = readu8(buf, cursor)
		cursor += 1
		local g = readu8(buf, cursor)
		cursor += 1
		local b = readu8(buf, cursor)
		cursor += 1
		value = Color3.new(r, g, b)
	elseif dataType == 'color3b16' then
		local rgb565 = readu16(buf, cursor)
		cursor += 2

		local red = band(rshift(rgb565, 11), 0x1F)
        local green = band(rshift(rgb565, 5), 0x3F)
        local blue = band(rgb565, 0x1F)

        local r = red / 31
        local g = green / 63
        local b = blue / 31

		value = Color3.new(r, g, b)
	elseif dataType == 'buffer' then
		local len = readu16(buf, cursor)
		cursor += 2
		
		value = buffer.create(len)
		buffer.copy(value :: buffer, 0, buf, cursor, len)
		cursor += len
	end

	return value, cursor
end

function Deserializer.deserializeToTable(buf: buffer, cursor: number, dataType: string, data: {Types.SerializableValues?})
	local value; value, cursor = Deserializer.deserialize(buf, cursor, dataType)
	table.insert(data, value)

	return cursor
end

return Deserializer
