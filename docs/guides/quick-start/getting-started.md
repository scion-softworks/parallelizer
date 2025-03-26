If you haven't already, refer to [Installation](/parallelizer/guides/quick-start/installation)

## What is a Task Coordinator?
A [Task Coordinator](/parallelizer/api/task-coordinator) is responsible for handling the dispatch of tasks, and managing the deserialization of tasks to be sent back to the main script. You can create a Task Coordinator using [`Parallelizer.CreateTaskCoordinator`](/parallelizer/api#createtaskcoordinator)
```luau title="init.server.luau"
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
local TaskCoordinator = Parallelizer.CreateTaskCoordinator(script.Worker, script, 256)
```

!!! note "Actor count does NOT mean the number of cores to use"
	Roblox will automatically spread the actor workload into the underlying hardware. So if you're targeting 4-core systems, that doesn't mean you should only use 4 actors, higher actor count may lead to better performance, but you should balance out the actor count to be around 64-256.

## Creating a Task
A task can be created using [`TaskCoordinator:DefineTask`](/parallelizer/api/task-coordinator#definetask). It contains the type definitions of what each task should return, which is used for serialization/deserialization purposes
```luau title="init.server.luau"
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
local TaskCoordinator = Parallelizer.CreateTaskCoordinator(script.Worker, script, 256)

local DataType = Parallelizer.DataType -- For easy access

local TestTask = TaskCoordinator:DefineTask('Test', {
	packet = {
		DataType.u16, DataType.str(11) -- String requires a fixed length, the worker task should return a string which should not be less or more than the length specified
	};
	localMemory = SharedTable.new({'Hello World'}) -- 'Hello World' is exactly 11 characters long, including the whitespace
})
```

## Creating the worker script
The worker script is responsible for running parallel tasks dispatched by the Task Coordinator, a worker script may have more than 1 unique tasks connected. The worker script can run the same task more than once if the thread count is higher than the actor count. To connect to a task, you can use [`Parallelizer.ListenToTask`](/parallelizer/api#listentotask)
```luau title="worker.server.luau"
local Actor = script:GetActor()
if not Actor then return end

local Parallelizer = require(game.ReplicatedStorage.Parallelizer)

Parallelizer.ListenToTask(Actor, 'Test', function(taskId, localMemory)
	return {2^taskId, localMemory[1]} -- localMemory[1] is 'Hello World'
end, true) -- true specifies that it should load and store the localMemory
```

## Dispatching the task
To dispatch a task, you can use [`TaskCoordinator:DispatchTask`](/parallelizer/api/task-coordinator#dispatchtask) or [`TaskCoordinator:DispatchTaskEqually`](/parallelizer/api/task-coordinator#dispatchtaskequally). Difference between the two are, `DispatchTask` expects a batchSize, while `DispatchTaskEqually` calculates the batchSize for you
```luau title="init.server.luau"
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
local TaskCoordinator = Parallelizer.CreateTaskCoordinator(script.Worker, script, 256)

local DataType = Parallelizer.DataType -- For easy access

local TestTask = TaskCoordinator:DefineTask('Test', {
	packet = {
		DataType.u16, DataType.str(11) -- String requires a fixed length, the task worker should return a string which should not be less or more than the length specified
	};
	localMemory = SharedTable.new({'Hello World'}) -- 'Hello World' is exactly 11 characters long, including the whitespace
})

TaskCoordinator:DispatchTask(TestTask, 1024, 8, function(result: {number, string}) -- 8 task per actor
	print(result) -- An array containing the results of the task
end)
```
!!! tip
	To maximize performance, set the [SignalBehavior](https://create.roblox.com/docs/reference/engine/enums/SignalBehavior) to Immediate in Workspace properties