minetest.register_chatcommand("howlight", {
	description = "Show the light level of the ground below you",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local player_pos = vector.round(player:get_pos())
			-- local pos = vector.new(player_pos.x, player_pos.y - 1 , player_pos.z)
			local pos = player_pos
			-- underground, light is always zero, so z-1 doesn't work.
			local pos_string = minetest.pos_to_string(pos)
			minetest.chat_send_player(name, "Light level at " .. pos_string .. " is " .. minetest.get_node_light(pos) .. ".")
			return true
		else
			return false, "You are not connected to minetestserver."
		end
	end
})
