Sending data from serial to parallel is often costly. To optimize performance, we aim to send the smallest possible amount of data. One technique is to leverage taskId to derive other information without transmitting it explicitly.

This page will guide you through deriving various kinds of information with minimal data transmission

---

## X and Y from `taskId`
Given a grid or matrix, you can calculate the X and Y positions from the taskId and width of the grid.

```luau
local function getXYFromTaskId(taskId: number, width: number)
	return taskId // width, taskId % width -- x, y
end
```
Example usage:
```luau title="worker.server.luau"
Parallelizer.ListenToTask(Actor, 'XY', function(taskId: number, localMemory: SharedTable) 
	local x, y = GetXYFromTaskId(taskId, localMemory[1]) -- Assuming the width is stored in the local memory

	-- ... do something
end)
```

!!! info
	For this to work, the thread count dispatched needs to be equal to `width * height`