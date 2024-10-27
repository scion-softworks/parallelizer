# Parallelizer
Contains constructor methods to instantiate classes

## Properties

---

## Functions

---

### `CreateThread`
!!! note
    You may only use this function in the Job Script!

Creates a new message bind to the actor, which has a middleware for handling `batchSize`. The return value of the callback will be sent via the bindable event to be put back together by the [Job Scheduler](/api/job-scheduler.md)

__Parameters__

- __actor:__ `Actor`<br>
The actor to bind the message 
- __callback:__ `(threadId: number, instructionTable: SharedTable) -> any`<br>
A callback with threadId as the index order of the thread and a SharedTable for constants, or can be used as a shared memory/resource

__Returns__

- `void`

---

### `CreateJobScheduler`
Create a new population of actors alongside the Job Script and creates a new [Job Scheduler](/api/job-scheduler.md)

__Parameters__

- __jobScript:__ `Script | LocalScript`<br>
The script that will be cloned across the actors
- __actorCount:__ `number`<br>
How many actors will be created, ideally should be a power of 2. Refer to [Multithreading Best Practices](https://create.roblox.com/docs/scripting/multithreading#best-practices:~:text=Use%20the%20Right%20Number%20of%20Actors) to determine the right number of actors
- __actorStorage:__ `Instance`<br>
Where to store the actors along with the Job Scripts once created.

__Returns__

- [`Job Scheduler`](/api/job-scheduler.md)

---

### `CreateInstructionData`
Creates a new container to store the SharedTable version of your data

__Parameters__

- __data:__ [`InstructionTableData`](/api/types#instructiontabledata)<br>
The data to store as a SharedTable, only certain types are allowed

__Returns__

- [`InstructionData`](/api/instruction-data.md)