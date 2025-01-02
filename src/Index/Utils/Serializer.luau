--!native
--!optimize 2
local Types = require(script.Parent.Parent.types)

local Serializer = {}

local floor = math.floor
local max = math.max

local rshift = bit32.rshift
local lshift = bit32.lshift
local bor = bit32.bor

local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32
local writei8 = buffer.writei8
local writei16 = buffer.writei16
local writei32 = buffer.writei32
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local writestring = buffer.writestring

function Serializer.getAlloc(cursor: number, bytes: number, size: number)
    local requiredSize = cursor + bytes
    if requiredSize <= size then
        return size
    end

    debug.profilebegin("buffer size allocation")

    local growthFactor = 4 -- Step multiplier
    local minStep = 64 -- Minimum growth step in bytes

    size = max(size * growthFactor, size + minStep)

    size -= 1
    size = bor(size, rshift(size, 1))
    size = bor(size, rshift(size, 2))
    size = bor(size, rshift(size, 4))
    size = bor(size, rshift(size, 8))
    size = bor(size, rshift(size, 16))
    size += 1

    if size < requiredSize then
        size = requiredSize
    end

    debug.profileend()
    return size
end

function Serializer.alloc(buf: buffer, cursor: number, bytes: number, size: number)
	debug.profilebegin('buffer allocation')

	if cursor + bytes > size then
		size = Serializer.getAlloc(cursor, bytes, size)

		local newBuf = buffer.create(size)
		buffer.copy(newBuf, 0, buf)

		buf = newBuf
	end

	debug.profileend()

	return buf, size
end

function Serializer.SerializeToBuffer(value: Types.SerializableValues, dataType: string, cursor: number, buf: buffer, size: number, bytes: number, dontAlloc: boolean?)
	local function alloc()
		buf, size = Serializer.alloc(buf, cursor, bytes, size)
	end

	local function writeNoAlloc<T>(callback: (buffer, number, T, number?) -> nil, writeValue: T, cursorOffsetBytes: number?)
		callback(buf, cursor, writeValue)
		cursor += cursorOffsetBytes or bytes
	end

	if not dontAlloc then alloc() end

	--> Primitive Types
	if dataType == 'u8' then
		writeNoAlloc(writeu8, value :: number)
	elseif dataType == 'u16' then
		writeNoAlloc(writeu16, value :: number)
	elseif dataType == 'u32' then
		writeNoAlloc(writeu32, value :: number)
	elseif dataType == 'i8' then
		writeNoAlloc(writei8, value :: number)
	elseif dataType == 'i16' then
		writeNoAlloc(writei16, value :: number)
	elseif dataType == 'i32' then
		writeNoAlloc(writei32, value :: number)
	elseif dataType == 'f32' then
		writeNoAlloc(writef32, value :: number)
	elseif dataType == 'f64' then
		writeNoAlloc(writef64, value :: number)
	elseif dataType == 'bool' then
		writeNoAlloc(writeu8, if value then 1 else 0)
	elseif dataType == 'str' then
		assert(type(value) == 'string')

		local len = #value
		writeNoAlloc(writeu32, len, 4)
		writeNoAlloc(writestring, value, len)
	elseif dataType == 'v3' then --> Non-primitive types
		assert(typeof(value) == 'Vector3', 'Must be a Vector3')

		writeNoAlloc(writef64, 8, value.X)
		writeNoAlloc(writef64, 8, value.Y)
		writeNoAlloc(writef64, 8, value.Z)
	elseif dataType == 'v3i16' then
		assert(typeof(value) == 'Vector3' or typeof(value) == 'Vector3int16', 'Must be a Vector3 or Vector3int16')

		writeNoAlloc(writei16, 2, value.X)
		writeNoAlloc(writei16, 2, value.Y)
		writeNoAlloc(writei16, 2, value.Z)
	elseif dataType == 'v2' then
		assert(typeof(value) == 'Vector2', 'Must be a Vector2')

		writeNoAlloc(writef64, 8, value.X)
		writeNoAlloc(writef64, 8, value.Y)
	elseif dataType == 'v2i16' then
		assert(typeof(value) == 'Vector2' or typeof(value) == 'Vector2int16', 'Must be a Vector2 or Vector2int16')

		writeNoAlloc(writei16, 2, value.X)
		writeNoAlloc(writei16, 2, value.Y)
	elseif dataType == 'cframe' then
		assert(typeof(value) == 'CFrame', 'Must be a CFrame')

		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesXYZ()

		writeNoAlloc(writef64, 8, x)
		writeNoAlloc(writef64, 8, y)
		writeNoAlloc(writef64, 8, z)

		writeNoAlloc(writef64, 8, rx)
		writeNoAlloc(writef64, 8, ry)
		writeNoAlloc(writef64, 8, rz)
	elseif dataType == 'color3' then
		assert(typeof(value) == 'Color3', 'Must be a Color3')

		local r, g, b = value.R * 255, value.G * 255, value.B * 255

		writeNoAlloc(writeu8, 1, r)
		writeNoAlloc(writeu8, 1, g)
		writeNoAlloc(writeu8, 1, b)
	elseif dataType == 'color3b16' then
		assert(typeof(value) == 'Color3', 'Must be a Color3')

		local r = floor(value.R * 31) -- (5-bit scaling)
		local g = floor(value.G * 63) -- (6-bit scaling, more precision since the human eye is more sensitive to green)
		local b = floor(value.B * 31) -- (5-bit scaling)

		local rgb565 = bor(lshift(r, 11), lshift(g, 5), b)
		writeNoAlloc(writeu16, 2, rgb565)
	elseif dataType == 'buffer' then
		assert(typeof(value) == 'buffer', 'Must be a buffer')
		writeNoAlloc(writeu16, 2, bytes)
		buffer.copy(value, 0, buf, cursor, bytes)
		cursor += bytes
	else
		error(`Invalid data type: "{dataType}"`)
	end

	return buf, cursor, size
end

return Serializer