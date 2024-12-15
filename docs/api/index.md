Contains constructor methods to instantiate classes

## Properties

---

### `DataType`
- [`{[DataType]: {DataType | string}}`](/parallelizer/api/types#datatype)<br>
Contains all the supported DataTypes for packet definitions

## Functions

---

### `ListenToTask`

Creates 3 new message binds to the actor, one will caches the packet type definitions, the other will cache the local memory, this will not be bound if `cacheLocalMemory` is `false`. The last one will process the actual task, which has a middleware that will serialize the return values of the callback and batch them accordingly.

__Parameters__

- __actor:__ `Actor`<br>

- __taskName:__ `string`<br> 

- __callback:__`(taskId: number, memory: SharedTable?, ...Types.SharedTableValues) -> {Types.SerializableValues}`<br>
- __cacheLocalMemory:__ `boolean`<br>

__Returns__

- `void`

---

### `CreateTaskCoordinator`
Create a new population of actors. The number of actors should ideally be a power of 2, refer to [Multithreading Best Practices](https://create.roblox.com/docs/scripting/multithreading#best-practices:~:text=Use%20the%20Right%20Number%20of%20Actors) to determine the right number of actors.

__Parameters__

- __workerScript:__ `Script | LocalScript`<br>
- __actorStorage:__ `Instance`<br>
- __actorCount:__ `number`<br>

__Returns__

- [`TaskCoordinator`](/parallelizer/api/task-coordinator)