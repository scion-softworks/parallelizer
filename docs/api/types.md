## `SerializableValues`
```luau
number | boolean | string | Vector3 | Vector3int16 | Vector2 | Vector2int16 | CFrame | Color3
```

## `SharedTableValues`
```luau
Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | buffer
```

## `DataType`
```luau
'u8' | 'u16' | 'u32' | 'i8' | 'i16' | 'i32' | 'f32' | 'f64' | 'bool' | 'str' | 'cframe' | 'v3' | 'v3i16' | 'v2' | 'v2i16' | 'color3' | 'color3u8'
```

## `PacketDefinition`
```luau
{ {DataType | string} }
```

## `TaskMetaData`
```luau
{ 
	packet: PacketDefinition;
	localMemory: SharedTable
}
```

## `Task`
```luau
{
	taskName: string;
	packetDef: PacketDefinition;
	packetBytesNeeded: number
}
```

## `TaskCoordinator`
```luau
{
	actors: {Actor};
	actorCount: number;

	DefineTask: (
		self: TaskCoordinator, 
		taskName: string, 
		taskMetaData: TaskMetaData
	) -> Task;
	
	DispatchTask: (
		self: TaskCoordinator, 
		taskObject: Task, 
		threadCount: number, 
		batchSize: number,
		callback: (any) -> (), 
		returnMergedRawBuffer: boolean?,
		...SharedTableValues
	) -> ();

	DispatchTaskEqually: (
		self: TaskCoordinator, 
		taskObject: Task, 
		threadCount: number, 
		callback: (any) -> (), 
		returnMergedRawBuffer: boolean?,
		...SharedTableValues
	) -> ()

	Destroy: (self: TaskCoordinator) -> ();
}
```