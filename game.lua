local vector = Library("vector")

local objects = {}

------------------------

local animations = {}

animations.infantry = {
	idle = {
		timing =	{0.1},
		sprite =	{1},
	},
	moving = {
		timing =	{0.1,	0.1,	0.1},
		sprite =	{2,		3,		1},
	},
}

------------------------

local function subject()
	return {
		_subscribers = {},
		subscribe = function(self, func)
			table.insert(self._subscribers, func)
		end,
		invoke = function(self)
			for _, func in pairs(self._subscribers) do
				func()
			end
		end,
	}
end

local function new_anim_state(animation_set, default_animation)
	return {
		frame = 1,
		period = 0,
		animation = default_animation,
		animation_set = animation_set,
		on_finish = subject(),
		fetch = function(self, key)
			return self.animation_set[self.animation][key][self.frame]
		end,
	}
end

local function anim_update(anim_state, step)
	local timing = anim_state.animation.timing
	local on_finish = anim_state.on_finish
	local frames = #timing
	
	anim_state.period = anim_state.period + step
	
	while anim_state.period >= 1 do
		anim_state.frame = anim_state.frame + 1
		anim_state.period = anim_state.period - 1
		
		if anim_state.frame > frames then
			anim_state.frame = anim_state.frame - frames
			
			if on_finish then
				on_finish:invoke()
			end
		end
	end
end

local infantry = {}
infantry.__index = infantry

function infantry:draw()
	Sprite(self.anim_state:fetch("sprite"), self.position.x, self.position.y)
end

function infantry:new(x, y)
	local o = {
		position = vector(x, y),
		anim_state = new_anim_state(animations.infantry, "idle"),
	}
	
	setmetatable(o, self)
	table.insert(objects, o)
	
	return o
end

infantry:new(10, 10)

function _update(dt)
	local i = 1
	while i < #objects do
		local object = objects[i]
		if object.update then
			object:update(dt)
		end
		if object.removed then
			table.remove(objects, i)
		else
			i = i + 1
		end
	end
end

function _draw()
	clear()
	for _, object in pairs(objects) do
		if object.draw then
			object:draw()
		end
	end
end