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

local anim_state = {
	frame = 1,
}
anim_state.__index = anim_state

function anim_state:new(animation_set, default_animation)
	local o = {
		frame = 1,
		remaining = animation_set[default_animation].timing[1],
		animation = default_animation,
		animation_set = animation_set,
		on_finish = subject(),
	}
	
	setmetatable(o, self)
	
	return o
end

function anim_state:fetch(key)
	return self.animation_set[self.animation][key][self.frame]
end

function anim_state:update(step)
	local timing = self.animation_set[self.animation].timing
	local on_finish = self.on_finish
	local frames = #timing
	
	self.remaining = self.remaining - step
	
	while self.remaining <= 0 do
		self.frame = self.frame + 1
		
		if self.frame > frames then
			self.frame = self.frame - frames
			
			if on_finish then
				on_finish:invoke()
			end
		end
		
		self.remaining = self.remaining + timing[self.frame]
	end
end

local infantry = {}
infantry.__index = infantry

function infantry:update(dt)
	self.anim_state:update(dt)
end

function infantry:draw()
	Sprite(self.anim_state:fetch("sprite"), self.position.x, self.position.y)
end

function infantry:new(x, y)
	local o = {
		position = vector(x, y),
		anim_state = anim_state:new(animations.infantry, "idle"),
	}
	
	setmetatable(o, self)
	table.insert(objects, o)
	
	return o
end

local new_infantry = infantry:new(10, 10)
new_infantry.anim_state.animation = "moving"

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