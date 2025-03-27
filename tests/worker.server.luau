local Actor = script:GetActor()

if not Actor then return end

local Parallelizer = require(game.ReplicatedStorage.Parallelizer)

Parallelizer.ListenToTask(Actor, 'all', function(taskId: number): {any}
	return {
		taskId, taskId, taskId, 
		-taskId, -taskId, -taskId, 
		math.random(), math.random(),
		true,
		'Hello World',
		Vector3.one,
		Vector3int16.new(2/3, 1/3, 4/3),
		Vector2.one,
		Vector2int16.new(2/3, 1/3),
		CFrame.new(2^64, 2^64, 2^64) * CFrame.Angles(math.pi, math.pi, math.pi),
		CFrame.new(2^32, 2^32, 2^32) * CFrame.Angles(math.pi, math.pi, math.pi),
		CFrame.new(2^64, 2^64, 2^64) * CFrame.Angles(math.pi, math.pi, math.pi),
		Color3.new(),
		Color3.new(1, 0.5, 0.25),
		buffer.create(16)
	}
end)
