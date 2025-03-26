export type SerializableValues = number | boolean | string | Vector3 | Vector3int16 | Vector2 | Vector2int16 | CFrame | Color3 | buffer
export type SharedTableValues = Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | buffer
export type DataType = 'u8' | 'u16' | 'u32' | 'i8' | 'i16' | 'i32' | 'f32' | 'f64' | 'bool' | 'str' | 'cframe' | 'v3' | 'v3i16' | 'v2' | 'v2i16' | 'color3' | 'color3b16' | 'buffer'
export type PacketDefinition = { {DataType | string} }
export type TaskMetaData = { 
	packet: PacketDefinition;
	localMemory: SharedTable
}
export type Task = {
	taskName: string;
	packetDef: PacketDefinition;
	packetBytesNeeded: number;
}
export type TaskCoordinator = {
	actors: {Actor};
	actorCount: number;
	bindable: BindableEvent;
	connections: {RBXScriptConnection};

	DefineTask: (
		self: TaskCoordinator, 
		taskName: string, 
		taskMetaData: TaskMetaData
	) -> Task;

	SetTaskLocalMemory: (
		self: TaskCoordinator, 
		taskObject: Task, 
		newLocalMemory: SharedTable
	) -> ();
	
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
	) -> ();

	Destroy: (self: TaskCoordinator) -> ();
}

return 1