local vector = Library("vector")

local objects = {}

----------DATA----------

local animations = {}
--animations contains animation sets
--each animation set contains the different animations available
--each animation has a timing key, which is a set of delays between each frame.
--it can also contain any number of other arbitrary keys with data in them.

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

--------PROGRAM---------

--This creates a callback
local function subject()
	return {
  --subscribers are functions that
  --have been provided by other
  --systems.
		_subscribers = {}, 
		subscribe = function(self, func)
			table.insert(self._subscribers, func)
		end,
  --All subscribers are called
  --when the subject is invoked.
		invoke = function(self)
			for _, func in pairs(self._subscribers) do
				func()
			end
		end,
	}
end

--anim_state keeps track of all the
--necessary parts of an animation
--system.
local anim_state = {
	frame = 1,
}
anim_state.__index = anim_state

function anim_state:new(animation_set, default_animation)
	local o = {
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
	
 --Can handle if the step skips over multiple frames
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
--TESTING ANIMATION SYSTEM
new_infantry.anim_state.animation = "moving"


--------LIKO-12--------

function _update(dt)
 --We're not using a for loop
 --here because we increment i
 --conditionally.
	local i = 1
	while i <= #objects do
		local object = objects[i]
  
		if object.update then
			object:update(dt)
		end
  
  --We don't want to increment
  --if the object was removed
  --from the objects table.
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