--!native
local Types = require(script.Parent.Parent.types)
local Deserializer = {}

function Deserializer.deserialize(buf: buffer, cursor: number, dataType: string): (Types.SerializableValues, number)
	local value: Types.SerializableValues

	if dataType == 'u8' then
		value = buffer.readu8(buf, cursor)
		cursor += 1
	elseif dataType == 'u16' then
		value = buffer.readu16(buf, cursor)
		cursor += 2
	elseif dataType == 'u32' then
		value = buffer.readu32(buf, cursor)
		cursor += 4
	elseif dataType == 'i8' then
		value = buffer.readi8(buf, cursor)
		cursor += 1
	elseif dataType == 'i16' then
		value = buffer.readi16(buf, cursor)
		cursor += 2
	elseif dataType == 'i32' then
		value = buffer.readi32(buf, cursor)
		cursor += 4
	elseif dataType == 'f32' then
		value = buffer.readf32(buf, cursor)
		cursor += 4
	elseif dataType == 'f64' then
		value = buffer.readf64(buf, cursor)
		cursor += 8
	elseif dataType == 'bool' then
	  	value = buffer.readu8(buf, cursor) ~= 0
		cursor += 1
	elseif dataType == 'str' then
		local len = buffer.readu32(buf, cursor)
		cursor += 4
		value = buffer.readstring(buf, cursor, len)
		cursor += len
	elseif dataType == 'v3' then
		local x = buffer.readf64(buf, cursor)
		cursor += 8
		local y = buffer.readf64(buf, cursor)
		cursor += 8
		local z = buffer.readf64(buf, cursor)
		cursor += 8
		value = Vector3.new(x, y, z)
	elseif dataType == 'v3i16' then
		local x = buffer.readi16(buf, cursor)
		cursor += 2
		local y = buffer.readi16(buf, cursor)
		cursor += 2
		local z = buffer.readi16(buf, cursor)
		cursor += 2
		value = Vector3.new(x, y, z)
	elseif dataType == 'v2' then
		local x = buffer.readf64(buf, cursor)
		cursor += 8
		local y = buffer.readf64(buf, cursor)
		cursor += 8
		value = Vector2.new(x, y)
	elseif dataType == 'v2i16' then
		local x = buffer.readi16(buf, cursor)
		cursor += 2
		local y = buffer.readi16(buf, cursor)
		cursor += 2
		value = Vector2.new(x, y)
	elseif dataType == 'cframe' then
		local x = buffer.readf64(buf, cursor)
		cursor += 8
		local y = buffer.readf64(buf, cursor)
		cursor += 8
		local z = buffer.readf64(buf, cursor)
		cursor += 8

		local rx = buffer.readf64(buf, cursor)
		cursor += 8
		local ry = buffer.readf64(buf, cursor)
		cursor += 8
		local rz = buffer.readf64(buf, cursor)
		cursor += 8
		value = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
	end

	return value, cursor
end

function Deserializer.deserializeToTable(buf: buffer, cursor: number, dataType: string, data: {Types.SerializableValues?})
	local value; value, cursor = Deserializer.deserialize(buf, cursor, dataType)
	table.insert(data, value)

	return cursor
end

return Deserializer
