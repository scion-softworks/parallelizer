!!! danger
    Messing with generally all parallel code is prone to crashes. This is due to a few reasons, the most common I've encountered being errors. Since the Job Script is cloned across the actors, if one errors, most likely the other will - which causes a chain reaction that will flood your output and potentially crash your studio.

    To avoid loss of progress, you can create a backup before running your script, or publish the place to enable auto-saving

## Prerequisites
- Basic Luau Knowledge
- We also recommend having a base understanding parallel computing concepts, such as threads and work partitioning

## What could I use this for?
One of the main goal of Parallel Processing is to reduce the strain and lag from the intense computations that you may use. Here are some examples use cases:

- Terrain Generation
- Bullet Raycast Computations
- Enemy AI

## Installation
If you haven't already installed the module, refer to [Installation](/parallelizer/guides/installation)

## Setup
For the sake of simplicity, place the module in `ReplicatedStorage` for easy access.

Before we do anything we first need to require the module
```luau
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
```

## Job Scheduler
Next, we can create a Job Scheduler to manage the workers, this allows you to communicate between the serial main thread to the many parallel threads.

To create a new Job Scheduler, you can use `Parallelizer.CreateJobScheduler`, which takes in 3 arguments in order:

1. Job Script/Worker Script ->
    This is the script that will run one or more tasks in parallel
2. Actor Count ->
    This is how many actors will be created, ideally the actor count should be a power of 2. You can refer to the [Multithreading Best Practices](https://create.roblox.com/docs/scripting/multithreading#best-practices:~:text=Use%20the%20Right%20Number%20of%20Actors) to determine the right number of actors needed. Or you can just do 256 or 64 since those usually are the magic numbers
3. Actor Storage ->
    Where should the actors be stored. If the Worker Script is a LocalScript, you must store them where they can run (such as `ReplicatedStorage`). Or if the Worker Script is a Server Script, you can store them in ServerScriptService, ServerStorage, etc..

In this example, we'll use 64 actors and store them below the script
```luau
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
local JobScheduler = Parallelizer.CreateJobScheduler(script.Job, 64, script)
```
!!! note
    If you're targeting 4-core systems, that doesn't mean you should use just 4 actors. 64 actors and more is reasonable since it allows it to distribute the work based on the capability of the underlying hardware

## Job Script
Now, since the Job Scheduler needs a Job Script, add a script under the master script. Optionally, you can disable the Job Script.

In the Job Script, we will get the active actor instance and require the module once again
```luau
local Actor = script:GetActor()

-- A safeguard to ensure it doesn't run without an actor
if not Actor then
    return
end

local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
```
Next, in the Job Script, we can make a thread dedicated to a specific task to be run in Parallel

To create a new thread, you can use `Parallelizer.CreateThread`, which takes in 3 arguments in order:

1. Actor -> The actor, duh
2. Thread Name -> An unique string identifier for the specific task you want to do
3. Callback -> The callback function to be called whenever the Job Scheduler dispatched the thread, it has 2 arguments:
    1. Thread Id -> A numerical identifier/index that goes in increasing order within the range `[1, threadCount]`. This is crucial for Parallel Tasks since it allows you to minimize the data that you need to send to the Job Script
    2. Instruction Table -> A SharedTable sent from the Job Scheduler's fourth argument, this is mostly used for constants and setting values. However you can also use this as a shared memory/resource

Here, we'll create a thread dedicated to calculating the nth root of thread id
```luau
-- ... trimmed
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)

Parallelizer.CreateThread(Actor, 'CalculateNthRoot', function(id, inst)
    local nth = inst[1]
    
    -- Example: nth of 2 is equal to square root, and nth of 3 is equal to cube root 
    return id^(1/nth)
end)
```

## Dispatching
Now that we have the Job Script set up, we can go back to the master script to dispatch the thread.

There are 2 ways to dispatch threads: `:DispatchAsync` and `:DispatchEquallyAsync`. Both of which has similar parameters, the difference being `batchSize` will be calculated automatically when you use `DispatchEquallyAsync`. For example if the `batchSize` is 2, then each actor will have to do 2 of the same thread at a time.

The Dispatch methods also has an optional parameter, that is the instruction data to be passed to parallel. To do so you need to create a new `InstructionData` object using `Parallelizer.CreateInstructionData`, that only has 1 argument, which is the data you want to send.

For simplicity, we will use `DispatchEquallyAsync`
```luau
local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
local JobScheduler = Parallelizer.CreateJobScheduler(script.Job, 64, script)

local RootInstruction = Parallelizer.CreateInstructionData({2}) -- the 2th root (square root)

-- Get the nth root from 1 to 1024
JobScheduler:DispatchEquallyAsync('CalculateNthRoot', 1024, function(result)
    print(result) -- The calculated roots up to 1024
end, RootInstruction)

print('This will run before the dispatch has finished!')
```
!!! warning
    Both of the Dispatch methods are __asynchronous__, meaning the succeeding code after dispatch will run even if the dispatch hasn't finished

!!! tip
    You can destroy the Job Scheduler to clean up memory when it's no longer used. This is achieved by calling the `:Destroy()` method, after which will dispose the actors, and the bindable event

Congratulations, you've reached the end! Now you can use this newfound knowledge and create some blazingly fast parallel computations!