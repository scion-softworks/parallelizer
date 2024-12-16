--!native
local RunService = game:GetService('RunService')

local Types = require(script.Parent.Parent.types)

local Deserializer = require(script.Parent.Parent.Utils.Deserializer)
local Serializer = require(script.Parent.Parent.Utils.Serializer)

local TaskCoordinator = {}

function TaskCoordinator.DefineTask(
	self: Types.TaskCoordinator, 
	taskName: string, 
	taskMetaData: Types.TaskMetaData
): Types.Task
	assert(not taskName:match('%-parallelizer%-internal-def$'), 'Task name cannot end with "-parallelizer-internal"')
	assert(not taskName:match('%-parallelizer%-internal-mem$'), 'Task name cannot end with "-parallelizer-internal-mem"')

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

function TaskCoordinator.DispatchTaskEqually(
	self: Types.TaskCoordinator,
	taskObject: Types.Task,
	threadCount: number,
	callback: (any) -> nil,
	useMergedBuffer: boolean?,
	...: Types.SharedTableValues
): ()
	self:DispatchTask(taskObject, threadCount, threadCount // self.actorCount, callback, useMergedBuffer, ...)
end

function TaskCoordinator.DispatchTask(
	self: Types.TaskCoordinator,
	taskObject: Types.Task,
	threadCount: number,
	batchSize: number,
	callback: (any) -> nil,
	useMergedBuffer: boolean?,
	...: Types.SharedTableValues
)
	batchSize = math.max(batchSize, 1)

	local dispatchBuffer = buffer.create(8)
	buffer.writeu32(dispatchBuffer, 0, threadCount)
	buffer.writeu32(dispatchBuffer, 4, batchSize)

	local sharedResultSize = threadCount // batchSize
	local sharedBufferResult = SharedTable.new(table.create(sharedResultSize))
	local connection;

	connection = RunService.PreSimulation:Connect(function()
		if SharedTable.size(sharedBufferResult) == sharedResultSize then
			connection:Disconnect()

			if useMergedBuffer then
				local size = taskObject.packetBytesNeeded
				local buf = buffer.create(size)

				debug.profilebegin('packet batch buffer merging')

				local cursor = 0
				for _, bufferStringBatch in sharedBufferResult do
					local bufferBatch = buffer.fromstring(bufferStringBatch)

					buffer.copy(buf, cursor, bufferBatch)
				end

				debug.profileend()

				callback(buf)
			else
				local data = table.create(threadCount * #taskObject.packetDef)

				debug.profilebegin('packet batch deserialization')

				for _, bufferStringBatch in sharedBufferResult do
					local bufferBatch = buffer.fromstring(bufferStringBatch)
					for batch = 1, batchSize do
						local cursor = 0

						for i, dataType in taskObject.packetDef do
							cursor = Deserializer.deserializeToTable(bufferBatch, cursor, dataType[1], data)
						end
					end
				end

				debug.profileend()

				callback(data)
			end
		end
	end)

	task.defer(function(...)
		local actorIndex = 1

		for taskId = 1, threadCount, batchSize do
			self.actors[actorIndex]:SendMessage(taskObject.taskName, taskId, dispatchBuffer, sharedBufferResult, ...)

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
end

return TaskCoordinator :: Types.TaskCoordinator