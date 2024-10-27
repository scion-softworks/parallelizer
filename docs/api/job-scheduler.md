# Job Scheduler
Manages handling of the job scripts/workers and thread dispatches
## Properties

---

### `Actors`
- `{Actor}`<br>
A list of actors, each with its own job script

### `PacketBindable` 
- `BindableEvent`<br>
The bindable event to serve as the parallel bridge

## Methods

---

### `DispatchAsync`
!!! note
    This method is __asynchronous__!

!!! danger
    You cannot have more than 1 dispatches going on at once, as it would collide with the other dispatch

Defers the dispatch that will go through all actors, if the threadCount is bigger than the actorCount, then it will cycle back. A connection to the bindable is made that will piece together the packets into one table, which will be sent to the callback

__Parameters__

- __threadName:__ `string`<br>
The unique string identifier bound to the actors by [`Parallelizer.CreateThread`](/api/#createthread) 
- __threadCount:__ `number`<br>
The number of threads to be dispatched across the actors. Usually, this is the number of data you want to compute. For example, for a 100x100 renderer, the `threadCount` will be `100*100`
- __batchSize:__ `number`<br>
How many threads should one actor process
- __callback:__ `(result: {any}) -> void`<br>
The callback to be called after all workers has finished sending their work
- __instData:__ [`InstructionData`](/api/types/#instructiondata)<br>
The instruction data to be sent to the actors

__Returns__

- `thread`

---

### `DispatchEquallyAsync`
!!! note
    This method is __asynchronous__!

!!! danger
    You cannot have more than 1 dispatches going on at once, as it would collide with the other dispatch

A proxy to [`DispatchAsync`](#dispatchasync), batchSize will be calculated automatically

__Parameters__

- __threadName:__ `string`<br>
The unique string identifier bound to the actors by [`Parallelizer.CreateThread`](/api/#createthread) 
- __threadCount:__ `number`<br>
The number of threads to be dispatched across the actors. Usually, this is the number of data you want to compute. For example, for a 100x100 renderer, the `threadCount` will be `100*100`
- __callback:__ `(result: {any}) -> void`<br>
The callback to be called after all workers has finished sending their work
- __instData:__ [`InstructionData`](/api/types/#instructiondata)<br>
The instruction data to be sent to the actors

__Returns__

- `void`

---

### `Destroy`
Disposes the actors and bindables, and destroys the [Job Scheduler](#)

__Parameters__

__Returns__

- `void`