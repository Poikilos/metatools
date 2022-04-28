--[[
--  Metadata Tools
--
--  A mod providing write and read access to a nodes' metadata using commands
--  (c) 2015-2016 ßÿ Lymkwi/LeMagnesium/Mg and Paly2; (c) 2017-2022 Poikilos
--  License: [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/)
--
--  Version: Poikilos fork of 1.2.2
--
]]--


local function isArray(t)
	-- Check if a table only contains sequential values.
	-- by kikito
	-- [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)
	-- answered May 21, 2011 at 7:22
	-- edited Mar 2, 2014 at 17:13
	-- <https://stackoverflow.com/a/6080274/4541104>
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then return false end
	end
	return true
end


function yamlSerializeTable(val, name, depth)
	-- Make a table into a string.
	-- (c) 2011 Henrik Ilgen, 2022 Poikilos
	-- [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)
	-- answered May 21 '11 at 12:14 Henrik Ilgen
	-- edited May 13, 2019 at 9:10
	-- on <https://stackoverflow.com/a/6081639>
	-- Only the first argument is required.
	-- Get the object back from the string via:
	-- a = loadstring(s)()
	depth = depth or 0

	local tmp = string.rep("  ", depth)

	if name then
		if name == "METATOOLS_ARRAY_ELEMENT" then
			tmp = tmp .. "- "
		else
			tmp = tmp .. name .. ": "
		end
	end

	if type(val) == "table" then
		if isArray(val) then
			tmp = tmp .. "\n"
			for k, v in pairs(val) do
				tmp =  tmp .. yamlSerializeTable(v, "METATOOLS_ARRAY_ELEMENT", depth + 1) .. "\n"
			end
			-- tmp = tmp .. string.rep("  ", depth)
		else
			tmp = tmp .. "\n"  -- Newline is after <name>: for tables.
			for k, v in pairs(val) do
				tmp =  tmp .. yamlSerializeTable(v, k, depth + 1) .. "\n"
			end
			-- tmp = tmp .. string.rep("  ", depth)
		end
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
	end
	return tmp
end

function serializeTable(val, name, skipnewlines, depth)
	-- Make a table into a string.
	-- (c) 2011 Henrik Ilgen
	-- [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)
	-- answered May 21 '11 at 12:14 Henrik Ilgen
	-- edited May 13, 2019 at 9:10
	-- on <https://stackoverflow.com/a/6081639>
	-- Only the first argument is required.
	-- Get the object back from the string via:
	-- a = loadstring(s)()
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then tmp = tmp .. name .. " = " end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
	end

	return tmp
end

local function token_indices(haystack, needle)
	local results = {}
	for i = 1, #haystack do
		local try = haystack:sub(i,i + needle:len() - 1)
		if try == needle then
			table.insert(results, i)
		end
	end
	return results
end

local function split_and_keep_token(s, needle)
	local results = {}
	local indices = token_indices(s, needle)
	local start = 1
	for k, v in pairs(indices) do
		table.insert(results, s:sub(start, v))
		start = v + 1
	end
	if start < #s then
		table.insert(results, s:sub(start))
	end
	return results
end

local function delimit(table, tab, delimiter)
	if not tab then
		tab = ""
	end
	if not table then
		return tab .. "nil"
	end
	if not delimiter then
		delimiter = " "
	end
	local ret = ""
	if delimiter ~= "\n" then
		ret = tab
	end
	for k, v in pairs(table) do
		if delimiter == "\n" then
			ret = ret .. tab .. k .. ":" .. v .. "\n"
		else
			ret = ret .. k .. ":" .. v .. "\n"
		end
	end
return ret
end

local function delimit_sequence(table, tab, delimiter)
	if not tab then
		tab = ""
	end
	if not table then
		return tab .. "nil"
	end
	if not delimiter then
		delimiter = " "
	end
	local ret = ""
	if delimiter ~= "\n" then
		ret = tab
	end
	for k, v in pairs(table) do
		if delimiter == "\n" then
			ret = ret .. tab .. v .. delimiter
		else
			ret = ret .. v .. delimiter
		end
	end
	return ret
end

local function send_messages_sequence(username, table, tab)
	if not tab then
		tab = ""
	end
	if not table then
		minetest.chat_send_player(username, tab .. "nil")
		return
	end
	for k, v in pairs(table) do
		minetest.chat_send_player(username, tab .. v .. ",")
	end

end

local function inv_to_tables(inv)
	-- see bones mod
	results = {}
	for i = 1, inv:get_size("main") do
		local stk = inv:get_stack("main", i)
		table.insert(results, stk:to_table())
		-- to_table shows everything:
		--   meta:
		--   metadata: ""
		--   count:1
		--   name:"default:sapling"
		--   wear:0
	end
	return results
end

local function inv_to_table(inv, blank)
	-- see bones mod
	local results = {}
	for i = 1, inv:get_size("main") do
		local stk = inv:get_stack("main", i)
		local stk_s = stk:to_string()
		if #stk_s > 0 or blank then
			table.insert(results, stk_s)
		end
	end
	return results
end

local function send_messages(username, table, tab, blank)
	if not tab then
		tab = ""
	end
	if not table then
		minetest.chat_send_player(username, tab .. "nil")
		return
	end
	for k, v in pairs(table) do
		if blank or ((v ~= nil) and (dump(v) ~= "") and (dump(v) ~= "\"\"")) then
			if type(v) == "table" then
				minetest.chat_send_player(username, tab .. k .. ":")
				send_messages(username, v, tab.."\t")
			elseif k == "formspec" then
				minetest.chat_send_player(username, tab .. k .. ":")
				local chunks = split_and_keep_token(v, "]")
				send_messages_sequence(username, chunks, tab.."\t")
			else
				minetest.chat_send_player(username, tab..k..":"..dump(v))
			end
		end
	end
end

local function get_nodedef_field(nodename, fieldname)
	if not minetest.registered_nodes[nodename] then
		-- print("metatools.get_nodedef_field: no registered node named " .. nodename)
		return nil
	end
	-- print("metatools.get_nodedef_field: checking " .. nodename .. " for " .. fieldname .. " in " .. dump(minetest.registered_nodes[nodename]))
	-- print("* result:" .. dump(minetest.registered_nodes[nodename][fieldname]))
	return minetest.registered_nodes[nodename][fieldname]
end

metatools = {} -- Public namespace
metatools.contexts = {}
metatools.playerlocks = {} -- Selection locks of the players
local version = "1.2.2"
local nodelock = {}

local modpath = minetest.get_modpath("metatools")
dofile(modpath .. "/assertions.lua")
dofile(modpath .. "/chatcommands.lua")

minetest.register_craftitem("metatools:stick",{
	description = "Meta stick",
	inventory_image = "metatools_stick.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local username = user:get_player_name()
		local userpos = user:get_pos()
		if pointed_thing.type == "nothing" then
			minetest.chat_send_player(
				username,
				"[metatools::stick] You pointed at nothing."
			)
			return
		elseif pointed_thing.type == "object" then
			local pointedObjRef = pointed_thing.ref
			-- local objAsStr = minetest.serialize(pointedObjRef)
			-- ^ if param is pointed_thing or pointed_thing.ref, minetest.serialize causes "2021-11-14 16:45:39: ERROR[Main]: ServerError: AsyncErr: ServerThread::run Lua: Runtime error from mod 'metatools' in callback item_OnUse(): /home/owner/minetest/bin/../builtin/common/serialize.lua:151: Can't serialize data of type userdata"
			--   - even yamlSerializeTable returns [inserializeable datatype:userdata]
			-- unrelated note: minetest.serialize(nil) returns "return nil"
			-- TODO:
			-- Show ObjectRef armor groups (See <https://git.minetest.org/minetest/minetest/src/branch/master/doc/lua_api.txt#L1825>)
			-- documentation for ObjectRef: <https://git.minetest.org/minetest/minetest/src/branch/master/doc/lua_api.txt#L1825>
			local objAsStr = yamlSerializeTable(pointedObjRef)
			minetest.chat_send_player(
				username,
				"[metatools::stick] You pointed at an object (" .. objAsStr .. ")"
			)
			local pointedObjRef = pointed_thing.ref
			-- if pointed_thing.ref.get_hp then
			minetest.chat_send_player(
				username,
				"[metatools::stick] pointed_thing.ref:get_hp(): " .. pointedObjRef:get_hp()
			)
			-- end
			-- minetest.log("action", "[metatools] You pointed at an object: " .. objAsStr)
			local luaEntity = pointedObjRef:get_luaentity()
			-- INFO: For player name, use user:get_player_name()
			minetest.chat_send_player(
				username,
				"[metatools::stick] LuaEntity name: " .. luaEntity.name
			)
			-- ^ This is the entity name such as namespace:sheep_black where namespace is a mod name.
			minetest.chat_send_player(
				username,
				"[metatools::stick] LuaEntity: " .. yamlSerializeTable(luaEntity)
			)
			local animation = pointedObjRef:get_animation()
			minetest.chat_send_player(
				username,
				"[metatools::stick] LuaEntity.ref:get_animation():" .. yamlSerializeTable(animation)
			)
			-- Hmm, animation.range, animation['range'] are nil
			-- (same for other variables),
			-- so API documentation is unclear:
			-- `get_animation()`: returns `range`, `frame_speed`, `frame_blend` and
			-- `frame_loop`.
			-- yamlSerializeTable(animation) only gets:
			--   y: 65
			--   x: 35
			-- minetest.chat_send_player(
			-- 	username,
			-- 	yamlSerializeTable(animation.range, "  range")
			-- )
		-- else type is usually "node"
		end
		local nodepos  = pointed_thing.under
		-- >   * `under` refers to the node position behind the pointed face
		-- >   * `above` refers to the node position in front of the pointed face.
		-- -<https://git.minetest.org/minetest/minetest/src/branch/master/doc/lua_api.txt>
		if not nodepos or not minetest.get_node(nodepos) then return end
		local nodename = minetest.get_node(nodepos).name
		local node = minetest.registered_nodes[nodename]
		local meta = minetest.get_meta(nodepos)
		local metalist = meta:to_table()

		minetest.chat_send_player(
			username,
			"[metatools::stick] You pointed at the '" .. nodename .. "':"
		)
		minetest.chat_send_player(
			username,
			"[metatools::stick]   pos:"
			.. minetest.pos_to_string(nodepos)
		)
		-- minetest.chat_send_player(
		-- 	username,
		-- 	"[metatools::stick]   drawtype:"
		-- 	.. get_nodedef_field(nodename, "drawtype")
		-- )
		-- minetest.chat_send_player(
		-- 	username,
		-- 	"[metatools::stick]   sunlight_propagates:"
		-- 	.. (get_nodedef_field(nodename, "sunlight_propagates") and 'true' or 'false')
		-- )

		if #metalist > 0 then
			minetest.chat_send_player(
				username,
				"[metatools::stick]   metadata: "
				--.. delimit(meta:to_table()["fields"], "", "\n")
			)
			send_messages(username, metalist)
			-- send_messages(username, meta:to_table()["fields"])
			-- minetest.chat_send_player(
				-- username,
				-- "[metatools::stick]   inventory: "
				-- --.. delimit(meta:to_table()["fields"], "", "\n")
			-- )
		end
		if meta["get_inventory"] then
			local inventory = meta:get_inventory()
			if inventory then  -- this is never true for some reason
				local this_inv_table = inv_to_table(inventory, true)
				if #this_inv_table > 0 then
					minetest.chat_send_player(username, "get_inventory():")
					send_messages(username, this_inv_table, "  ")
				end
			-- else
				-- minetest.chat_send_player(username, "\tnil")
			end
		-- else
			-- minetest.chat_send_player(username, "get_inventory:nil")
		end
		-- node is nil at this point if the node is an "unknown node"!
		if node and node.frame_contents then
			-- frames mod
			local frame_contents = node.frame_contents
			if frame_contents then
				minetest.chat_send_player(username, "frame_contents: "..frame_contents)
			-- else
				-- minetest.chat_send_player(username, "\tnil")
			end
		-- else
			-- minetest.chat_send_player(username, "get_inventory:nil")
		end
		if meta:get_string("item") ~= "" then
			-- itemframes mod or xdecor:itemframe
			local frame_contents = meta:get_string("item")
			if frame_contents then
				minetest.chat_send_player(username, "meta item: "..frame_contents)
			-- else
				-- minetest.chat_send_player(username, "\tnil")
			end
		-- else
			-- minetest.chat_send_player(username, "get_inventory:nil")
		end
		local airname = minetest.get_name_from_content_id(minetest.CONTENT_AIR)
		-- local litnode = nil
		local litpos = nil
		local litdist = nil
		local litwhy = "unknown"
		local litmsg = ""
		local litid = nil
		local litwhat = nil
		local litindent = ""
		local foundPointed = false
		local offsets = {
			[0] = {["x"] = 0, ["y"] = 0, ["z"] = 0},
			[1] = {["x"] = 0, ["y"] = 1, ["z"] = 0},
			[2] = {["x"] = 0, ["y"] = -1, ["z"] = 0},
			[3] = {["x"] = 1, ["y"] = 0, ["z"] = 0},
			[4] = {["x"] = -1, ["y"] = 0, ["z"] = 0},
			[5] = {["x"] = 0, ["y"] = 0, ["z"] = 1},
			[6] = {["x"] = 0, ["y"] = 0, ["z"] = -1},
		}
		-- local touching = {}
		for key, value in pairs(offsets) do
			local trydist = nil
			local trywhy = nil
			local trypos = vector.new(
				nodepos.x + value.x,
				nodepos.y + value.y,
				nodepos.z + value.z
			)
			-- touching[key] = trypos
			local trynode = minetest.get_node(trypos)
			local tryid = nil
			local tryname = nil
			if (trynode) then
				tryname = trynode.name
				tryid = minetest.get_content_id(tryname)

				-- print("tryname:" .. tryname)
				-- print("trynode.name:" .. trynode.name)
				-- if (tryid == minetest.CONTENT_AIR) then
				if trynode.name == airname then
					-- found:
					if (userpos) then
						trydist = vector.distance(userpos, trypos)
					else
						-- dummy value for "found" state:
						trydist = vector.distance(nodepos, trypos)
					end
					trywhy = "air"
				else
					-- local trygroup = minetest.get_item_group(trynode.name, "air")
					-- local drawtype = get_nodedef_field(tryname, "drawtype")
					if (get_nodedef_field(tryname, "drawtype") == "airlike") then
						trywhy = "airlike"
					elseif (get_nodedef_field(tryname, "sunlight_propagates") == true) then
						trywhy = "sunlight_propagates"
					else
						trynode = nil
						-- print("[metatools::stick] " .. key .. ": "..tryname.." is not airlike, no sunlight_propagates")
					end
					if (trynode) then
						-- found:
						if (userpos) then
							trydist = vector.distance(userpos, trypos)
						else
							-- dummy value for "found" state:
							trydist = vector.distance(nodepos, trypos)
						end
					end
					-- if trydef.sunlight_propagates
				end
			else
				trywhy = "non-node"
				-- (non-node pos should work for the later light check)
				-- found:
				if (userpos) then
					trydist = vector.distance(userpos, trypos)
				else
					-- dummy value for "found" state:
					trydist = vector.distance(nodepos, trypos)
				end
			end
			if (trydist) then
				if (litpos == nil) or (trydist < litdist) then
					litdist = trydist
					litpos = trypos
					litid = tryid  -- nil if trywhy == "non-node"
					litwhy = trywhy
					if (key > 0) then
						litwhat = "neighbor:"
						litindent = "  "
					else
						foundPointed = true
						-- is the pointed node
						break  -- always use pointed node if lightable
					end
				end
			end
		end
		local nodelightsource = get_nodedef_field(nodename, "light_source")
		if (nodelightsource) and (nodelightsource > 0) then
			if not foundPointed then
				litmsg = "  # next to pointed light_source=" .. nodelightsource
			end
		end


		-- litnode = minetest.find_node_near(nodepos, 1, minetest.get_name_from_content_id(minetest.CONTENT_AIR))
		if (litpos) then
			if (litwhat) then
				minetest.chat_send_player(
					username,
					"[metatools::stick]   nearby lit:  #"..minetest.pos_to_string(litpos)
				)
			end
			minetest.chat_send_player(
				username,
				"[metatools::stick]   "..litindent.."why lit:" .. litwhy .. litmsg
			)
			minetest.chat_send_player(
				username,
				"[metatools::stick]   "..litindent.."light:" .. minetest.get_node_light(litpos)
			)
		else
			minetest.chat_send_player(
				username,
				"[metatools::stick]   nearby lit: ~  # no air/propogator for determining lighting"
			)
		end
		minetest.log("action","[metatools] Player " .. username .. " saw metadatas of node at " .. minetest.pos_to_string(nodepos))

	end,
})

-- Useful callbacks
minetest.register_on_dignode(function(pos, node, digger)
	local spos = minetest.pos_to_string(pos)
	local ctxid = metatools.get_context_from_pos(pos)
	if ctxid then
		if not metatools.get_context_owner(ctxid) then
			metatools.alert_users("Node at " .. spos .. " dug by " .. (digger:get_player_name() or " a drone ") .. " : context " .. ctxid .. " closed")
			metatools.close_node(ctxid)
		else
			local owner = metatools.get_context_owner(ctxid)
			if owner == digger:get_player_name() then
				metatools.alert_users(owner .. " dug themselves out of node at " .. spos .. " : context " .. ctxid .. "closed")
				metatools.close_node(ctxid)
			else
				minetest.chat_send_player(digger:get_player_name() or "", "- meta - You are not allowed to dig the present node at " .. spos .. " : someone is operating on it")
				minetest.chat_send_player(metatools.get_context_owner(ctxid), "- meta - " .. digger:get_player_name() .. " tried to dig the node you are operating on")
				return true
			end
		end
	end
end)

-- Functions
function metatools.get_version() return version end

function metatools.get_context_from_pos(pos)
	for id, ctx in pairs(metatools.contexts) do
		if minetest.pos_to_string(ctx.position) == minetest.pos_to_string(pos) then
			return id
		end
	end
end

function metatools.alert_users(msg)
	for name, _ in pairs(metatools.playerlocks) do
		minetest.chat_send_player(name, ("- meta::alert - ALERT: %s"):format(msg))
	end
end

function metatools.build_param_str(table, index, separator)
	local str = table[index]
	for newindex = 1, #table-index do
		str = str .. (separator or ' ') .. table[newindex+index]
	end
	return str
end

function metatools.get_player_selection(name)
	return metatools.playerlocks[name]
end

function metatools.player_select(name, ctxid)
	metatools.playerlocks[name] = ctxid
	return true, ("context %d selected"):format(ctxid)
end

function metatools.player_unselect(name)
	metatools.playerlocks[name] = nil
	return true, "context unselected"
end

function metatools.switch(contextid)
	local ctx = metatools.contexts[contextid]
	if ctx.mode == "inventory" then
		ctx.mode = "fields"
	else
		ctx.mode = "inventory"
	end
	ctx.list = ""
	return true, "switched to mode " .. ctx.mode
end

function metatools.get_context_owner(ctxid)
	for name, id in pairs(metatools.playerlocks) do
		if id == ctxid then
			return name
		end
	end
end

function assign_context(pos, mode, owner)
	local i = 1
	while metatools.contexts[i] do i = i + 1 end

	metatools.contexts[i] = {
		owner = owner or "",
		position = pos,
		list = "",
		mode = mode
	}

	nodelock[minetest.pos_to_string(pos)] = owner or ""

	return i
end

function free_context(contextid)
	nodelock[minetest.pos_to_string(metatools.contexts[contextid].position)] = nil
	metatools.contexts[contextid] = nil
	return true
end

function dump_normalize(dmp)
	return dump(dmp):gsub('\n', ''):gsub('\t', ' ')
end

--function meta_assertion(assert_type, params)

function meta_exec(struct)
	if not struct.scope then
		struct.scope = "meta"
	end

	if not struct.func then
		return
	end

	if struct.required then
		-- will call meta_assertion from here
		for category, req in pairs(struct.required) do
			if category == "position" and not assert_pos(req) then
				return false, ("- %s - Failure : Invalid position : %s"):format(struct.scope, dump_normalize(req))

			elseif category == "contextid" and not assert_contextid(req) then
				return false, ("- %s - Failutre : Invalid contextid : %s"):format(struct.scope, dump_normalize(req))

			elseif category == "no_nodelock" then
				if not assert_pos(req) then
					return false, ("- %s - Failure : Invalid pos : %s"):format(struct.scope, dump_normalize(req))
				end
				local npos = req
				if type(npos) == "table" then
					npos = minetest.pos_to_string(npos)
				end
				if nodelock[npos] then
					return false, ("- %s - Failure : Nodelock on %s"):format(struct.scope, dump_normalize(req))
				end

			elseif category == "open_mode" and not assert_mode(req) then
				return false, ("- %s - Failure : Invalid mode %s"):format(struct.scope, dump_normalize(req))

			elseif category == "ownership" then
				if type(req) ~= "table" or not req.name then
					return false, ("- %s - Failure : Requirement of ownership invalid or missing a 'name' field"):format(struct.scope)
				end

				if req.contextid then
					if not assert_contextid(req.contextid) then
						return false, ("- %s - Failure : Invalid context id %s"):format(struct.scope, req.contextid)
					end
					if not assert_ownership(req.contextid, req.name) then
						return false, ("- %s - Failure : Context %d is not owner by %s"):format(struct.scope, req.contextid, req.name)
					end
				else
					return false, ("- %s - Failure : No context selected"):format(struct.scope)
				end

			elseif category == "no_ownership" then
				if not assert_contextid(req) then
					return false, ("- %s - Failure : Invalid context id %s"):format(struct.scope, dump_normalize(req))
				elseif metatools.get_context_owner(req) then
					return false, ("- %s - Failure : Node already owned"):format(struct.scope)
				end

			elseif category == "some_ownership" and (not req or not metatools.playerlocks[req]) then
				return false, ("- %s - Failure : No context owned at the moment"):format(struct.scope)

			elseif category == "specific_open_mode" then
				if not req or not req.mode or not req.contextid then
					return false, ("- %s - Failure : Invalid specific open mode requirement"):format(struct.scope)
				end

				if not assert_contextid(req.contextid) then
					return false, ("- %s - Failure : Invalid context id : %s"):format(struct.scope, dump_normalize(req.contextid))
				end

				if not metatools.contexts[req.contextid].mode == req.mode then
					return false, ("- %s - Failure : Invalid mode, %s is required"):format(struct.scope, dump_normalize(req.mode))
				end
			end
		end
	end

	local ret, msg = struct.func(unpack(struct.params))
	if ret then
		if struct.success then
			struct.success(struct.params, {ret, msg})
		end
		return true, ("- %s - Success : %s"):format(struct.scope, msg)
	else
		return false, ("- %s - Failure : %s"):format(struct.scope, msg)
	end
end

function metatools.contexts_summary()
	local ctxs = {}
	for ctxid, ctx in pairs(metatools.contexts) do
		table.insert(ctxs, 1, {
			id = ctxid,
			pos = ctx.position,
			owner = metatools.get_context_owner(ctxid) or "nobody",
			mode = ctx.mode,
		})
	end
	return true, ctxs
end

function metatools.open_node(pos, mode, owner)
	local id = assign_context(pos, mode)
	if owner then
		metatools.playerlocks[owner] = id
	end
	return true, "opened node " .. minetest.get_node(pos).name .. " at " .. minetest.pos_to_string(pos) .. " in context ID " .. id
end

function metatools.close_node(contextid)--, closer)
	free_context(contextid)
	return true, "node closed"
end

function metatools.show(contextid)
	if not assert_contextid(contextid) then
		return false, "invalid or missing context id"
	end
	local ctx = metatools.contexts[contextid]
	local metabase = minetest.get_meta(ctx.position):to_table()[ctx.mode]
	if assert_specific_mode(contextid, "inventory") and ctx.list ~= "" then
		metabase = metabase[ctx.list]
	end

	return true, metabase
end

function metatools.list_enter(contextid, listname)
	if not assert_contextid(contextid) then
		return false, "invalid contexid " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode required"
	end

	if not listname then
		return false, "no list name provided"
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list ~= "" then
		return false, "unable to reach another list until leaving the current one"
	end

	local _, metabase = metatools.show(contextid)
	if not metabase[listname] or type(metabase[listname]) ~= "table" then
		return false, "inexistent or invalid list called " .. dump_normalize(listname)
	end

	metatools.contexts[contextid].list = listname
	return true, "entered list " .. listname
end

function metatools.list_leave(contextid)
	if not assert_contextid(contextid) then
		return false, "invalid contextid " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode required"
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list == "" then
		return false, "cannot leave, not in a list"
	end

	ctx.list = ""
	return true, "left list"
end

function metatools.set(contextid, varname, varval)
	if not varname or varname == "" then
		return false, "invalid or empty variable name"
	end

	if not varval then
		return false, "missing value, use unset to set variable to nil"
	end

	local ctx = metatools.contexts[contextid]
	local meta = minetest.get_meta(ctx.position)

	meta:set_string(varname, ("%s"):format(varval))
	return true, "value of field " .. varname .. " set to " .. varval
end

function metatools.unset(contextid, varname)
	if not varname or varname == "" then
		return false, "invalid or empty variable name"
	end

	minetest.get_meta(metatools.contexts[contextid].position):set_string(varname, nil)
	return true, "field " .. varname .. " unset"
end

function metatools.purge(contextid)
	local ctx = metatools.contexts[contextid]
	local meta = minetest.get_meta(ctx.position)
	if ctx.mode == "inventory" then
		local inv = meta:get_inventory()
		inv:set_lists({})
		return true, "inventory purged"

	else
		meta:from_table(nil)
		return true, "fields purged"
	end
end

function metatools.prune()
	for id, ctx in pairs(metatools.contexts) do
		if not metatools.get_context_owner(id) then
			metatools.close_node(id)
		end
	end
	return true, "contexts pruned"
end

function metatools.list_init(contextid, listname, size)
	if not listname or listname == "" then
		return false, "missing or empty list name"
	end

	if not size or not assert_integer(size) or tonumber(size) < 0 then
		return false, "invalid size " .. dump_normalize(size)
	end

	local inv = minetest.get_meta(metatools.contexts[contextid].position):get_inventory()
	inv:set_list(listname, {})
	inv:set_size(listname, tonumber(size))

	return true, "list " .. listname .. " of size " .. size .. " created"
end

function metatools.list_delete(contextid, listname)
	if not assert_contextid(contextid) then
		return false, "invalid context id " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode is required"
	end

	if not listname or listname == "" then
		return false, "missing or empty list name"
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list == listname then
		ctx.list = ""
	end

	local inv = minetest.get_meta(ctx.position):get_inventory()
	inv:set_list(listname, {})
	inv:set_size(listname, 0)

	return true, "list " .. listname .. " deleted"
end

function metatools.itemstack_erase(contextid, index)
	if not assert_contextid(contextid) then
		return false, "invalid context id " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode required"
	end

	if not assert_integer(index) or tonumber(index) < 0 then
		return false, "invalid index"
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list == "" then
		return false, "your presence is required in a list"
	end

	local inv = minetest.get_meta(ctx.position):get_inventory()
	if tonumber(index) > inv:get_size(ctx.list) then
		return false, "index value higher than list size"
	end
	inv:set_stack(ctx.list, tonumber(index), nil)
	return true, "itemstack at index " .. index .. " erased"
end

function metatools.itemstack_write(contextid, index, data)
	if not assert_contextid(contextid) then
		return false, "invalid context id " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode required"
	end

	if not assert_integer(index) or tonumber(index) < 0 then
		return false, "invalid index"
	end

	local stack = ItemStack(data)
	if not stack then
		return false, "invalid itemstack representation " .. dump_normalize(data)
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list == "" then
		return false, "your presence is required in a list"
	end

	local inv = minetest.get_meta(ctx.position):get_inventory()
	if tonumber(index) > inv:get_size(ctx.list) then
		return false, "index value higher than list size"
	end
	inv:set_stack(ctx.list, tonumber(index), stack)
	return true, "itemstack at index " .. index .. " written"
end

function metatools.itemstack_add(contextid, data)
	if not assert_contextid(contextid) then
		return false, "invalid context id " .. dump_normalize(contextid)
	end

	if not assert_specific_mode(contextid, "inventory") then
		return false, "invalid mode, inventory mode required"
	end

	local stack = ItemStack(data)
	if not stack then
		return false, "invalid itemstack representation " .. dump_normalize(data)
	end

	local ctx = metatools.contexts[contextid]
	if ctx.list == "" then
		return false, "your presence is required in a list"
	end

	local inv = minetest.get_meta(ctx.position):get_inventory()
	inv:add_item(ctx.list, stack)
	return true, "added " .. data .. " in list " .. ctx.list
end

-- Main chat command
minetest.register_chatcommand("meta", {
	privs = {server=true},
	params = "help | version | open (x,y,z) {mode} | show | enter <name> | leave | set <name> <value> | unset <name> | purge | list <init/delete> <name> <size>| itemstack <write/erase> <index> <data> | close",
	description = "Metadata manipulation command",
	func = function(name, paramstr)
		-- name : Ingame name of the manipulating player
		-- paramstr : string with all parameters

		if paramstr == "" then
			return true, "- meta - Consult '/meta help' for a better understanding of the meta command"
		end

		local params = paramstr:split(' ')

		-- meta version
		if params[1] == "version" then
			return true, "- meta::version - Metatools version " .. metatools.get_version()

		-- meta help
		elseif params[1] == "help" then
			return true, "- meta::help - Help : \n" ..
				"- meta::help - /meta version : Prints out the version\n" ..
				"- meta::help - /meta help : This very command\n" ..
				"- meta::help - /meta open <(x,y,z) [mode] : Open not at (x,y,z) with mode 'mode' (either 'fields' or 'inventory'; default is 'fields')\n" ..
				"- meta::help - /meta select <contextid> : Select the node with context <contextid> for operations\n" ..
				"- meta::help - /meta unselect : Unselect the context you are currently in\n" ..
				"- meta::help - /meta contexts : Show all open contexts with id, operator, position and open mode\n" ..
				"- meta::help - /meta switch : Switch open mode in the current context\n" ..
				"- meta::help - /meta close : Close the currently selected node\n" ..
				"- meta::help - /meta prune : Close all currently unoperated nodes\n" ..
				"- meta::help - /meta show : Show you the fields/lists available\n" ..
				"- meta::help - /meta set <name> <value> : Set variable 'name' to 'value', overriding any existing data\n" ..
				"- meta::help - /meta unset <name> : Set variable 'name' to nil, ignoring whether it exists or not\n" ..
				"- meta::help - /meta purge : Purge all metadata variables or inventory lists (depending on the open mode)\n" ..
				"- meta::help - /meta list : List manipulation :\n" ..
				"- meta::help - /meta list enter <name> : Enter in list <name>\n" ..
				"- meta::help - /meta list leave : Go back to the top level of inventory data\n" ..
				"- meta::help - /meta list init <name> <size> : Initialize list 'name' of size 'size', overriding any existing data\n" ..
				"- meta::help - /meta list delete <name> : Delete list 'name', ignoring whether it exists or not\n" ..
				"- meta::help - /meta itemstack : ItemStack manipulation :\n" ..
				"- meta::help - /meta itemstack write <index> <data> : Write an itemstack represented by 'data' at index 'index' of the list you are in\n" ..
				"- meta::help - /meta itemstack add <data> : Add items of an itemstack represented by 'data' in the list you are in\n" ..
				"- meta::help - /meta itemstack erase <index> : Remove itemstack at index 'index' in the current inventory, regardless of whether it exists or not\n" ..
				"- meta::help - End of Help"

		-- meta context
		elseif params[1] == "contexts" then
			local _, ctxs = metatools.contexts_summary()
			local retstr = ""
			for _, summ in pairs(ctxs) do
				retstr = retstr .. ("- meta::contexts : %d: [%s] Node at %s owner by %s\n"):
					format(summ.id, summ.mode, minetest.pos_to_string(summ.pos), summ.owner)
			end
			return true, retstr .. ("- meta::contexts - %d contexts"):format(#ctxs)

		-- meta open (x,y,z) [fields|inventory]
		elseif params[1] == "open" then

			-- Call the API function
			if not params[3] then
				params[3] = "fields"
			end
			return meta_exec({
				scope = "meta::open",
				func = metatools.open_node,
				params = {minetest.string_to_pos(params[2]), params[3], name},
				required = {
					mode = params[3],
					no_nodelock = params[2],
				},
				success = function(fparams)
					metatools.alert_users(name .. " opened node at " .. minetest.pos_to_string(fparams[1]))
				end
			})

		-- meta close
		elseif params[1] == "close" then
			-- Call the API function
			return meta_exec({
				scope = "meta::close",
				func = metatools.close_node,
				params = {metatools.get_player_selection(name)},
				required = {
					ownership = {
						contextid = metatools.get_player_selection(name),
						name = name
					}
				},
				success = function(fparams)
					metatools.alert_users(name .. " closed node of id " .. fparams[1])
				end
			})

		-- meta select <contextid>
		elseif params[1] == "select" then
			return meta_exec({
				scope = "meta::select",
				func = metatools.player_select,
				params = {name, tonumber(params[2])},
				required = {
					no_ownership = tonumber(params[2]),
				},
				success = function(fparams)
					metatools.alert_users(name .. " selected context of id " .. fparams[1])
				end
			})

		-- meta unselect
		elseif params[1] == "unselect" then
			return meta_exec({
				scope = "meta::unselect",
				func = metatools.player_unselect,
				params = {name},
				required = {
					some_ownership = name,
				},
				success = function(fparams)
					metatools.alert_users(name .. " unselected their context")
				end
			})

		-- meta prune
		elseif params[1] == "prune" then
			return meta_exec({
				scope = "meta::prune",
				func = metatools.prune,
				params = {},
				success = function()
					metatools.alert_users(name .. " is pruning contexts!")
				end
			})

		-- meta switch
		elseif params[1] == "switch" then
			return meta_exec({
				scope = "meta::switch",
				func = metatools.switch,
				params = {metatools.get_player_selection(name)},
				required = {
					some_ownership = name,
				},
				success = function(fparams)
					metatools.alert_users(name .. " switched context (ID=" .. fparams[1] .. ")'s open mode")
				end
			})

		-- meta show
		elseif params[1] == "show" then
			return meta_exec({
				scope = "meta::show",
				func = function()
					local status, fieldlist = metatools.show(metatools.get_player_selection(name))
					if not status then
						return status, fieldlist
					else
						local retstr = "Output :\n"
						for name, field in pairs(fieldlist) do
							local rpr
							if type(field) == "table" then
								rpr = ("-> {...} (size %s)"):format(#field)
							elseif type(field) == "string" then
								rpr = ("= %s"):format(dump_normalize(field))
							elseif type(field) == "userdata" then
								if field.get_name and field.get_count then
									rpr = ("= ItemStack({name='%s', count=%d, metadata='%s'})"):
										format(field:get_name(), field:get_count(), field:get_metadata())
								else
									rpr = ("= %s"):format(dump_normalize(field))
								end
							else
								rpr = ("= %s"):format(field)
							end
							retstr = retstr .. ("- meta::show -     %s %s\n"):format(name, rpr)
						end
						return true, retstr .. "- meta::show - End of output"
					end
				end,
				params = {},
				required = {
					some_ownership = name
				}
			})

		-- meta set <varname> <value>
		elseif params[1] == "set" then
			return meta_exec({
				scope = "meta::set",
				func = metatools.set,
				params = {metatools.get_player_selection(name), params[2], metatools.build_param_str(params, 3, ' ')},
				required = {
					some_ownership = name,
					specific_open_mode = {
						mode = "fields",
						contextid = metatools.get_player_selection(name)
					}
				}
			})


		-- meta unset <varname>
		elseif params[1] == "unset" then
			return meta_exec({
				scope = "meta::unset",
				func = metatools.unset,
				params = {metatools.get_player_selection(name), params[2]},
				required = {
					some_ownership = name,
					specific_open_mode = {
						mode = "fields",
						contextid = metatools.get_player_selection(name)
					}
				}
			})

		-- meta purge
		elseif params[1] == "purge" then
			return meta_exec({
				scope = "meta::purge",
				func = metatools.purge,
				params = {metatools.get_player_selection(name)},
				required = {
					some_ownership = name,
				},
				success = function(fparams)
					metatools.alert_users(name .. " purged context " .. fparams[1])
				end
			})

		-- meta list...
		elseif params[1] == "list" then
			if not params[2] then
				return false, "- meta::list - Subcommand needed, consult '/meta help' for help"
			end

			-- meta list enter <listname>
			if params[2] == "enter" then
				return meta_exec({
					scope = "meta::list::enter",
					func = metatools.list_enter,
					params = {metatools.get_player_selection(name), params[3]},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						},
					}
				})

			-- meta list leave
			elseif params[2] == "leave" then
				return meta_exec({
					scope = "meta::list::leave",
					func = metatools.list_leave,
					params = {metatools.get_player_selection(name)},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			-- meta list init <name> <size>
			elseif params[2] == "init" then
				return meta_exec({
					scope = "meta::list::init",
					func = metatools.list_init,
					params = {metatools.get_player_selection(name), params[3], params[4]},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			-- meta list delete <name>
			elseif params[2] == "delete" then
				return meta_exec({
					scope = "meta::list::delete",
					func = metatools.list_delete,
					params = {metatools.get_player_selection(name), params[3]},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			else
				return false, "- meta::list - Unknown subcommand '" .. params[2] .. "', please consult '/meta help' for help"
			end

		-- meta itemstack...
		elseif params[1] == "itemstack" then
			if not params[2] then
				return false, "- meta::itemstack - Subcommand needde, consult '/meta help' for help"
			end

			-- meta itemstack erase <index>
			if params[2] == "erase" then
				return meta_exec({
					scope = "meta::itemstack::erase",
					func = metatools.itemstack_erase,
					params = {metatools.get_player_selection(name), params[3]},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			-- meta itemstack write <index> <itemstack>
			elseif params[2] == "write" then
				return meta_exec({
					scope = "meta::itemstack::write",
					func = metatools.itemstack_write,
					params = {metatools.get_player_selection(name), params[3], metatools.build_param_str(params, 4, ' ')},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			-- meta itemstack add <itemstack>
			elseif params[2] == "add" then
				return meta_exec({
					scope = "meta::itemstack::write",
					func = metatools.itemstack_add,
					params = {metatools.get_player_selection(name), metatools.build_param_str(params, 3, ' ')},
					required = {
						some_ownership = name,
						specific_open_mode = {
							contextid = metatools.get_player_selection(name),
							mode = "inventory",
						}
					}
				})

			else
				return false, "- meta::itemstack - Unknown subcommand " .. params[2]
			end

		else
			return false, "- meta - Unknown command " .. params[1]
		end
	end,
})
