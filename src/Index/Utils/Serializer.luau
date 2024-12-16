--!native
--!optimize 2
local Types = require(script.Parent.Parent.types)

local Serializer = {}

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

    size = math.max(size * growthFactor, size + minStep)

    size -= 1
    size = bit32.bor(size, bit32.rshift(size, 1))
    size = bit32.bor(size, bit32.rshift(size, 2))
    size = bit32.bor(size, bit32.rshift(size, 4))
    size = bit32.bor(size, bit32.rshift(size, 8))
    size = bit32.bor(size, bit32.rshift(size, 16))
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
	local writeValue: any = value -- god damn it i cant get typechecking to work

	local function alloc()
		buf, size = Serializer.alloc(buf, cursor, bytes, size)
	end

	local function writeNoAlloc<T>(callback: (buffer, number, T, number?) -> nil, cursorOffsetBytes: number?)
		callback(buf, cursor, writeValue)
		cursor += cursorOffsetBytes or bytes
	end

	if not dontAlloc then alloc() end

	--> Primitive Types
	if dataType == 'u8' then
		writeNoAlloc(writeu8)
	elseif dataType == 'u16' then
		writeNoAlloc(writeu16)
	elseif dataType == 'u32' then
		writeNoAlloc(writeu32)
	elseif dataType == 'i8' then
		writeNoAlloc(writei8)
	elseif dataType == 'i16' then
		writeNoAlloc(writei16)
	elseif dataType == 'i32' then
		writeNoAlloc(writei32)
	elseif dataType == 'f32' then
		writeNoAlloc(writef32)
	elseif dataType == 'f64' then
		writeNoAlloc(writef64)
	elseif dataType == 'bool' then
		writeValue = if value then 1 else 0
		writeNoAlloc(writeu8)
	elseif dataType == 'str' then
		assert(type(value) == 'string')

		local len = #value
		writeValue = len
		writeNoAlloc(writeu32, 4)
		writeValue = value
		writeNoAlloc(writestring, len)
	elseif dataType == 'v3' then --> Non-primitive types
		assert(typeof(value) == 'Vector3', 'Must be a Vector3')

		writeValue = value.X
		writeNoAlloc(writef64, 8)
		writeValue = value.Y
		writeNoAlloc(writef64, 8)
		writeValue = value.Z
		writeNoAlloc(writef64, 8)
	elseif dataType == 'v3i16' then
		assert(typeof(value) == 'Vector3' or typeof(value) == 'Vector3int16', 'Must be a Vector3 or Vector3int16')

		writeValue = value.X
		writeNoAlloc(writei16, 2)
		writeValue = value.Y
		writeNoAlloc(writei16, 2)
		writeValue = value.Z
		writeNoAlloc(writei16, 2)
	elseif dataType == 'v2' then
		assert(typeof(value) == 'Vector2', 'Must be a Vector2')

		writeValue = value.X
		writeNoAlloc(writef64, 8)
		writeValue = value.Y
		writeNoAlloc(writef64, 8)
	elseif dataType == 'v2i16' then
		assert(typeof(value) == 'Vector2' or typeof(value) == 'Vector2int16', 'Must be a Vector2 or Vector2int16')

		writeValue = value.X
		writeNoAlloc(writei16, 2)
		writeValue = value.Y
		writeNoAlloc(writei16, 2)
	elseif dataType == 'cframe' then
		assert(typeof(value) == 'CFrame', 'Must be a CFrame')

		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesXYZ()

		writeValue = x
		writeNoAlloc(writef64, 8)
		writeValue = y
		writeNoAlloc(writef64, 8)
		writeValue = z
		writeNoAlloc(writef64, 8)

		writeValue = rx
		writeNoAlloc(writef64, 8)
		writeValue = ry
		writeNoAlloc(writef64, 8)
		writeValue = rz
		writeNoAlloc(writef64, 8)
	elseif dataType == 'color3' then
		assert(typeof(value) == 'Color3', 'Must be a Color3')

		local r, g, b = value.R, value.G, value.B
		
		writeValue = r
		writeNoAlloc(writef64, 8)
		writeValue = g
		writeNoAlloc(writef64, 8)
		writeValue = b
		writeNoAlloc(writef64, 8)
	elseif dataType == 'color3u8' then
		assert(typeof(value) == 'Color3', 'Must be a Color3')

		local r, g, b = value.R * 255, value.G * 255, value.B * 255

		writeValue = r
		writeNoAlloc(writeu8, 1)
		writeValue = g
		writeNoAlloc(writeu8, 1)
		writeValue = b
		writeNoAlloc(writeu8, 1)
	else
		error(`Invalid data type: "{dataType}"`)
	end

	return buf, cursor, size
end

return Serializer