-- Diag.lua
return function(ctx)
	local botsAmbulantes = ctx.botsAmbulantes
	task.delay(5, function()
		for model, data in pairs(botsAmbulantes) do
			local n = 0
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("Motor6D") then
					n += 1
				end
			end
			print("[Diag]", model.Name, "Motor6D=", n)
		end
	end)
end
