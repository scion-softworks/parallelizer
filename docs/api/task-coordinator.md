Manages handling of thread dispatches, caching, and serialization/deserialization
## Properties

---

### `actors`
- `{Actor}`<br>
A list of actors, each with its own worker script

### `actorCount` 
- `number`<br>
The bindable event to serve as the parallel bridge

## Methods

---

### `DefineTask`

!!! warning
    The `taskName` can't end with `-parallelizer-internal-def` nor `-parallelizer-internal-mem` as they are reserved for internal use

Sends the serialized type definition and local memory specified under the message `taskName-parallelizer-internal-def` and `taskName-parallelizer-internal-mem` respectively

__Parameters__

- __taskName:__ `string`<br>
- __taskMetaData:__ [`Types.TaskMetaData`](/parallelizer/api/types#taskmetadata)<br>

__Returns__

- [`Task`](/parallelizer/api/types#task)

---

### `DispatchTaskEqually`

A proxy to [`DispatchTask`](#dispatchtask), batchSize will be calculated automatically

__Parameters__

- __taskObject__:__ [`Task`](/parallelizer/api/types#task)<br>
- __threadCount:__ `number`<br>
- __callback:__ `(result: {Types.SerializableValues}) -> void`<br>
- __useMergedBuffer:__ `boolean?`<br>
- __...:__ `Types.SharedTableValues`<br>

__Returns__

- `void`

---

### `DispatchTask`

Creates a PreSimulation connection to deserialize the packets and dispatches the appropriate actors to the task. The callback will be called once the packets are gathered together. You can also choose to return the merged buffer instead of a table.

__Parameters__

- __taskObject__: [`Task`](/parallelizer/api/types#task)<br>
- __threadCount:__ `number`<br>
- __batchSize:__ `number`<br>
- __callback:__ `(result: {Types.SerializableValues}) -> void`<br>
- __useMergedBuffer:__ `boolean?`<br>
- __...:__ `Types.SharedTableValues`<br>

__Returns__

- `void`

---

### `Destroy`

Disposes the ongoing dispatch connections and the actors

__Parameters__

__Returns__

- `void`