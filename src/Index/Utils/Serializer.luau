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

function Serializer.SerializeToBuffer(value: Types.SerializableValues, dataType: string, cursor: number, buf: buffer, size: number, len: number?)
	local writeValue: any = value -- god damn it i cant get typechecking to work

	local function alloc(bytes: number)
		buf, size = Serializer.alloc(buf, cursor, bytes, size)
	end

	local function writeNoAlloc<T>(callback: (buffer, number, T, number?) -> nil, bytes: number, ...)
		callback(buf, cursor, writeValue, ...)
		cursor += bytes
	end

	local function allocAndWrite<T>(callback: (buffer, number, T, number?) -> nil, bytes: number, ...)
		alloc(bytes)

		callback(buf, cursor, writeValue, ...)
		cursor += bytes
	end

	debug.profilebegin('buffer serialization')

	--> Primitive Types
	if dataType == 'u8' then
		allocAndWrite(writeu8, 1)
	elseif dataType == 'u16' then
		allocAndWrite(writeu16, 2)
	elseif dataType == 'u32' then
		allocAndWrite(writeu32, 4)
	elseif dataType == 'i8' then
		allocAndWrite(writei8, 1)
	elseif dataType == 'i16' then
		allocAndWrite(writei16, 2)
	elseif dataType == 'i32' then
		allocAndWrite(writei32, 4)
	elseif dataType == 'f32' then
		allocAndWrite(writef32, 4)
	elseif dataType == 'f64' then
		allocAndWrite(writef64, 8)
	elseif dataType == 'bool' then
		value = if value then 1 else 0
		allocAndWrite(writeu8, 1)
	elseif dataType == 'str' then
		assert(type(value) == 'string', 'Must be a string')
		assert(len)

		writeValue = len
		allocAndWrite(writeu32, 4)
		writeValue = value
		allocAndWrite(writestring, len, len)
	elseif dataType == 'v3' then --> Non-primitive types
		assert(typeof(value) == 'Vector3', 'Must be a Vector3')

		alloc(24)

		writeValue = value.X
		writeNoAlloc(writef64, 8)
		writeValue = value.Y
		writeNoAlloc(writef64, 8)
		writeValue = value.Z
		writeNoAlloc(writef64, 8)
	elseif dataType == 'v3i16' then
		assert(typeof(value) == 'Vector3' or typeof(value) == 'Vector3int16', 'Must be a Vector3 or Vector3int16')

		alloc(24)

		writeValue = value.X
		writeNoAlloc(writei16, 2)
		writeValue = value.Y
		writeNoAlloc(writei16, 2)
		writeValue = value.Z
		writeNoAlloc(writei16, 2)
	elseif dataType == 'v2' then
		assert(typeof(value) == 'Vector2', 'Must be a Vector2')

		alloc(16)

		writeValue = value.X
		writeNoAlloc(writef64, 8)
		writeValue = value.Y
		writeNoAlloc(writef64, 8)
	elseif dataType == 'v2i16' then
		assert(typeof(value) == 'Vector2' or typeof(value) == 'Vector2int16', 'Must be a Vector2 or Vector2int16')

		alloc(16)

		writeValue = value.X
		writeNoAlloc(writei16, 2)
		writeValue = value.Y
		writeNoAlloc(writei16, 2)
	elseif dataType == 'cframe' then
		assert(typeof(value) == 'CFrame', 'Must be a CFrame')

		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesXYZ()

		alloc(48)

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
		
		alloc(24)

		writeValue = r
		writeNoAlloc(writef64, 8)
		writeValue = g
		writeNoAlloc(writef64, 8)
		writeValue = b
		writeNoAlloc(writef64, 8)
	else
		error(`Invalid data type: "{dataType}"`)
	end

	debug.profileend()

	return buf, cursor, size
end

return Serializer