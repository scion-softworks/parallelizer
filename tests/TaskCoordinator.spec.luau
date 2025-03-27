local RunService = game:GetService('RunService')

return function()
	local Parallelizer = require(game.ReplicatedStorage.Parallelizer)
	local DataType = Parallelizer.DataType

	local fullPacketDef = {
		DataType.u8;
		DataType.u16;
		DataType.u32;
		DataType.i8;
		DataType.i16;
		DataType.i32;
		DataType.f32;
		DataType.f64;
		DataType.bool;
		DataType.str(11);
		DataType.vector3;
		DataType.vector3i16;
		DataType.vector2;
		DataType.vector2i16;
		DataType.cframe;
		DataType.cframef32;
		DataType.cframe18;
		DataType.color3;
		DataType.color3b16;
		DataType.buffer(16);
	}

	local TaskCoordinator = Parallelizer.CreateTaskCoordinator(script.Parent.worker, script, 256)

	local all = TaskCoordinator:DefineTask('all', {
		packet = fullPacketDef
	})

	describe("TaskCoordinator", function()
		it("should be a task coordinator", function()
			expect(TaskCoordinator).to.be.a('table')
			expect(TaskCoordinator.actors).to.be.a('table')
			expect(#TaskCoordinator.actors).to.equal(256)
			expect(TaskCoordinator.connections).to.be.a('table')
		end)
	end)

	describe("Task", function()
		it("should be a task with all data types", function()
			expect(all).to.be.ok()
			expect(all.taskName).to.equal('all')
			expect(all.packetDef).to.be.a('table')
			expect(all.packetBytesNeeded).to.equal(205)
		end)
	end)

	describe("TaskCoordinator:DispatchTask", function()
		if not RunService:IsRunning() then
			SKIP() -- For some reason TestEZ companion is unable to utilize parallelism.
		end
		it("should be able to dispatch the task with all data types", function()
			local result
			TaskCoordinator:DispatchTask(all, 1024, 8, function(res) 
				result = res
			end)
			task.wait(1)
			expect(result).to.be.ok()
			expect(result).to.be.a('table')
			expect(#result).to.equal(1024 * #fullPacketDef)
		end)
	end)

	describe("TaskCoordinator:Destroy", function()
		it("should destroy itself", function()
			TaskCoordinator:Destroy()

			expect(#script:GetChildren()).to.equal(0)
			expect(#TaskCoordinator.actors).to.equal(0)
			expect(#TaskCoordinator.connections).to.equal(0)
		end)
	end)
end
