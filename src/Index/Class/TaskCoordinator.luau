--!native
--!optimize 2
local Types = require(script.Parent.Parent.types)

local Deserializer = require(script.Parent.Parent.Utils.Deserializer)
local Serializer = require(script.Parent.Parent.Utils.Serializer)

local TaskCoordinator = {}

function TaskCoordinator.DefineTask(
	self: Types.TaskCoordinator, 
	taskName: string, 
	taskMetaData: Types.TaskMetaData
): Types.Task
	assert(not taskName:match('%-parallelizer%-internal%-def$'), 'Task name cannot end with "-parallelizer-internal"')
	assert(not taskName:match('%-parallelizer%-internal%-mem$'), 'Task name cannot end with "-parallelizer-internal-mem"')

	--> Serialize Packet Definition
	local packetDef = taskMetaData.packet

	local defSize = 8
	local packetBytesSize = #packetDef * 4
	local defBuf = buffer.create(defSize)
	local packetBytesBuf = buffer.create(packetBytesSize)

	local defCursor = 0
	local packetBytesCursor = 0

	local bytesNeeded = 0

	for _, dataType in packetDef do
		local dataTypeLiteral = dataType[1]
		local bytes = tonumber(dataType[2]) :: number

		bytesNeeded += bytes

		defBuf, defCursor, defSize = Serializer.SerializeToBuffer(dataTypeLiteral, 'str', defCursor, defBuf, defSize, #dataTypeLiteral+4)
		packetBytesBuf, packetBytesCursor, packetBytesSize = Serializer.SerializeToBuffer(bytes, 'u32', packetBytesCursor, packetBytesBuf, packetBytesSize, 4)
	end

	task.defer(function()
		for _, actor: Actor in self.actors do
			actor:SendMessage(`{taskName}-parallelizer-internal-def`, defBuf, packetBytesBuf, #packetDef, bytesNeeded)
			actor:SendMessage(`{taskName}-parallelizer-internal-mem`, taskMetaData.localMemory)
		end
	end)

	return { taskName = taskName, packetDef = packetDef, packetBytesNeeded = bytesNeeded }
end

function TaskCoordinator.SetTaskLocalMemory(
	self: Types.TaskCoordinator,
	taskObject: Types.Task,
	newLocalMemory: SharedTable
): ()
	for _, actor: Actor in self.actors do
		actor:SendMessage(`{taskObject.taskName}-parallelizer-internal-mem`, newLocalMemory)
	end
end

function TaskCoordinator.DispatchTaskEqually(
	self: Types.TaskCoordinator,
	taskObject: Types.Task,
	threadCount: number,
	callback: (any) -> nil,
	returnMergedBuffer: boolean?,
	...: Types.SharedTableValues
): ()
	self:DispatchTask(taskObject, threadCount, threadCount // self.actorCount, callback, returnMergedBuffer, ...)
end

function TaskCoordinator.DispatchTask(
	self: Types.TaskCoordinator,
	taskObject: Types.Task,
	threadCount: number,
	batchSize: number,
	callback: (any) -> nil,
	returnMergedBuffer: boolean?,
	...: Types.SharedTableValues
)
	batchSize = math.max(batchSize, 1)

	local data: buffer | {any} = if returnMergedBuffer then buffer.create(taskObject.packetBytesNeeded * threadCount) else {}
	local connection;
	local count = 0

	-- TODO: try to find a faster way to do this
	connection = self.bindable.Event:Connect(function(index: number, batchBufferResult: buffer)		
		count += 1

		if returnMergedBuffer then
			buffer.copy(data :: buffer, (index-1) * taskObject.packetBytesNeeded, batchBufferResult)
		else
			local cursor = 0
			local batchData = table.create(batchSize * #taskObject.packetDef)

			-- for all batches/chunks in the batch
			for batch = 1, batchSize do
				-- for all data elements in bufferBatch within the batches/chunks
				for i, dataType in taskObject.packetDef do
					cursor = Deserializer.deserializeToTable(batchBufferResult, cursor, dataType[1], batchData)
				end
			end

			table.move(batchData, 1, #batchData, (index - 1) * #taskObject.packetDef + 1, data)
		end

		if count == threadCount // batchSize then
			connection:Disconnect()
			callback(data)
		end
	end)

	table.insert(self.connections, connection)

	task.defer(function(...)
		local actorIndex = 1

		for taskId = 1, threadCount, batchSize do
			self.actors[actorIndex]:SendMessage(taskObject.taskName, taskId, threadCount, batchSize, self.bindable, ...)

			actorIndex = (actorIndex % self.actorCount) + 1
		end
	end, ...)
end

function TaskCoordinator.Destroy(self: Types.TaskCoordinator)
	for _, connection in self.connections do
		connection:Disconnect()
	end

	for _, actor in self.actors do
		actor:Destroy()
	end

	self.bindable:Destroy()

	table.clear(self.actors)
	table.clear(self.connections)
end

return TaskCoordinator :: Types.TaskCoordinator