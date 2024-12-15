local Types = require(script.types)
local TaskCoordinator = require(script.Class.TaskCoordinator)

local Serializer = require(script.Utils.Serializer)
local Deserializer = require(script.Utils.Deserializer)

local Index = {}

function Index.ListenToTask(actor: Actor, taskName: string, callback: (taskId: number, memory: SharedTable?, ...Types.SharedTableValues) -> {Types.SerializableValues}, cacheLocalMemory: boolean)
	assert(taskName:match('%-parallelizer-internal%-.+$') == nil, 'Task name cannot end with "-parallelizer-internal-..."')
	
	-->> Internal Local Memory
	local packetDefData: {string} = {}
	local strLengthData: {number} = {}

	-->> User Local Memory
	local userMemory: SharedTable

	if cacheLocalMemory then
		actor:BindToMessageParallel(`{taskName}-parallelizer-internal-mem`, function(memory: SharedTable)
			userMemory = memory
		end)
	end

	actor:BindToMessageParallel(`{taskName}-parallelizer-internal-def`, function(packetDefBuf: buffer, packetDefCount: number, strLengthBuf: buffer, strLenCount: number)
		local packetDefCursor = 0
		local strLenCursor = 0
		
		debug.profilebegin('deserialize packet def buffer')

		for _ = 1, packetDefCount do
			packetDefCursor = Deserializer.deserializeToTable(packetDefBuf, packetDefCursor, 'str', packetDefData)
		end

		debug.profileend()

		debug.profilebegin('deserialize str length buffer')

		for _ = 1, strLenCount do
			strLenCursor = Deserializer.deserializeToTable(strLengthBuf, strLenCursor, 'u32', strLengthData)
		end

		debug.profileend()
	end)

	actor:BindToMessageParallel(taskName, function(startingTaskId: number, dispatchBuf: buffer, result: SharedTable, ...: Types.SharedTableValues)
		local threadCount = buffer.readu32(dispatchBuf, 0)
		local batchSize = buffer.readu32(dispatchBuf, 4)

		debug.profilebegin('batch task callback fire')
		
		local responses = {}
		for taskId = startingTaskId, math.min(startingTaskId + (batchSize - 1), threadCount) do
			local res = callback(taskId, userMemory, ...)
			
			if type(res) ~= 'table' then
				error("Task Callback must return a table value")
			else
				table.insert(responses, res)
			end
		end

		task.desynchronize()
		
		debug.profileend()

		-- TODO: optimize big batches of data
		debug.profilebegin('packet batch buffer serialization')
		
		local cursor = 0
		local size = 1024
		local batchBuf: buffer = buffer.create(size)
		
		for _, data in responses do
			local strCount = 0

			for dataIndex, v in data do
				local dataType: string = packetDefData[dataIndex]
				
				assert(dataType ~= nil, 'Task return callback value out of bounds')
				
				local len: number?
				if dataType == 'str' then
					strCount += 1
					len = tonumber(strLengthData[strCount])

					assert(len, 'String length data not found')
				end
												
				batchBuf, cursor, size = Serializer.SerializeToBuffer(v, dataType, cursor, batchBuf, size, len)
			end
		end
		
		debug.profileend()

		result[((startingTaskId-1) // batchSize)+1] = buffer.tostring(batchBuf)
	end)
end

function Index.CreateTaskCoordinator(workerScript: Script & LocalScript, actorStorage: Instance, actorCount: number)
	local actors: {Actor} = table.create(actorCount)

	for _ = 1, actorCount do
		local actor = Instance.new('Actor')
		local worker = workerScript:Clone()
		worker.Parent = actor
		worker.Enabled = true
		actor.Parent = actorStorage

		table.insert(actors, actor)
	end

	return table.freeze(setmetatable({
		actorCount = actorCount;
		actors = actors;
	}, {__index = TaskCoordinator}))
end

local DataTypeFolder = script.DataTypes
local DataType = {}

DataType.u8 = require(DataTypeFolder.u8)
DataType.u16 = require(DataTypeFolder.u16)
DataType.u32 = require(DataTypeFolder.u32)
DataType.i8 = require(DataTypeFolder.i8)
DataType.i16 = require(DataTypeFolder.i16)
DataType.i32 = require(DataTypeFolder.i32)
DataType.f32 = require(DataTypeFolder.f32)
DataType.f64 = require(DataTypeFolder.f64)
DataType.bool = require(DataTypeFolder.bool)
DataType.str = require(DataTypeFolder.str)
DataType.cframe = require(DataTypeFolder.cframe)
DataType.vector3 = require(DataTypeFolder.vector3)
DataType.vector3i16 = require(DataTypeFolder.vector3i16)
DataType.vector2 = require(DataTypeFolder.vector2)
DataType.vector2i16 = require(DataTypeFolder.vector2i16)

Index.DataType = DataType

return Index