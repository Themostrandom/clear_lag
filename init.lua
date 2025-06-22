local interval = 300
local timer = interval
local enabled = true
local storage = minetest.get_mod_storage()

local function load_state()
	timer = tonumber(storage:get_string("timer")) or interval
	interval = tonumber(storage:get_string("interval")) or interval
	enabled = storage:get_string("enabled") ~= "false"
end

local function save_state()
	storage:set_string("timer", tostring(timer))
	storage:set_string("interval", tostring(interval))
	storage:set_string("enabled", tostring(enabled))
end

local function clear_items()
	local count = 0
	for _, obj in ipairs(minetest.get_objects_inside_radius({x = 0, y = 0, z = 0}, 10000)) do
		local ent = obj:get_luaentity()
		if ent and ent.name == "__builtin:item" then
			obj:remove()
			count = count + 1
		end
	end
	minetest.chat_send_all(minetest.colorize("#FF0000", "[ClearLag] Removed " .. count .. " items."))
end

local function warn_all(seconds)
	local msg = minetest.colorize("#FF0000", "[ClearLag] Clearing ground items in " .. seconds .. " seconds!")
	for _, player in ipairs(minetest.get_connected_players()) do
		minetest.chat_send_player(player:get_player_name(), msg)
	end
end

local acc = 0
minetest.register_globalstep(function(dtime)
	if not enabled then return end
	acc = acc + dtime
	if acc < 1 then return end
	acc = 0
	timer = timer - 1

	if timer == 30 or timer == 10 or (timer <= 5 and timer > 0) then
		warn_all(timer)
	end

	if timer <= 0 then
		clear_items()
		timer = interval
	end

	save_state()
end)

minetest.register_chatcommand("cltime", {
	params = "<seconds|help>",
	description = "Set clear lag interval or view help",
	privs = { server = true },
	func = function(name, param)
		if param == "help" then
			local msg = [[
[ClearLag Help]
Usage: /cltime <seconds>
- Sets how often items on the ground are cleared.
- Countdown messages appear at 30, 10, 5..1 seconds.
Examples:
  /cltime 300  → every 5 minutes
  /cltime 60   → every 1 minute
  /cltime 900  → every 15 minutes
]]
			return true, msg
		end

		local t = tonumber(param)
		if not t or t <= 0 then
			return false, "Usage: /cltime <seconds> (or /cltime help)"
		end

		interval = t
		timer = t
		save_state()
		minetest.chat_send_all(minetest.colorize("#FF0000", "[ClearLag] Timer set to " .. t .. " seconds by " .. name))
		return true
	end
})

minetest.register_chatcommand("cl", {
	params = "<on|off>",
	description = "Enable or disable automatic item clearing",
	privs = { server = true },
	func = function(name, param)
		if param == "on" then
			enabled = true
			timer = interval
			save_state()
			return true, "[ClearLag] Clearing enabled."
		elseif param == "off" then
			enabled = false
			save_state()
			return true, "[ClearLag] Clearing disabled."
		else
			return false, "Usage: /cl <on|off>"
		end
	end
})

load_state()

