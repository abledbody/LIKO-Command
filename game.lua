local vector = Library("vector")
local class = Library("class")

cursor("normal")

local objects = {}

----------DATA----------

local animations = {}
--The animations table contains sets.
--Each set contains the different animations available.
--Each animation has a timing key, which is a set of delays between each frame.
--It can also contain any number of other arbitrary keys with data in them.

animations.infantry = {
 idle = {
  timing = {0.1,},
  sprite = {1,  },
 },
 moving = {
  timing =	{0.07, 0.07, 0.07, },
  sprite =	{2,    3,		  1,    },
  events = {function() SFX(0, 1) end}
 },
 attacking = {
  timing = {0.05, 0.05, },
  sprite = {1,    4,    },
  events = {function() SFX(1, 1) end}
 },
 flying_dead = {
  timing = {0.1,},
  sprite = {5,  },
 },
 dead = {
  timing = {0.1,},
  sprite = {6,  },
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
local anim_state = {}
anim_state.__index = anim_state

function anim_state:new(animation_set, default_animation)
 local o = {
  --The current frame index
  frame = 1,
  --How much time until the next frame
  remaining = animation_set[default_animation].timing[1],
  --The name of the current animation
  animation = default_animation,
  --The current set of animations
  animation_set = animation_set,
  --What to do when the animation is done
  on_finish = subject(),
 }
 
 setmetatable(o, self)
 
 return o
end

function anim_state:fetch(key)
 return self.animation_set[self.animation][key][self.frame]
end

function anim_state:update(step)
 local keys = self.animation_set[self.animation]
 local timing = keys.timing
 local events = keys.events
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
  
  --If there's something in the events key,
  --try to call it like a function.
  if events and events[self.frame] then
   events[self.frame]()
  end
  
  self.remaining = self.remaining + timing[self.frame]
 end
end

function anim_state:set_animation(animation)
 self.animation = animation
 self.frame = 1
 self.remaining = self.animation_set[animation].timing[1]
end

local function apply_velocity(self, rate)
 self.position = self.position + self.velocity * rate
end

--Calculates a velocity
local function move_to_target(position, destination, constraints)
 local relative_pos = destination - position
 
 if relative_pos:len() < constraints.max_destination_distance then
  return vector(0, 0), true
 else
  return relative_pos:normalized() * constraints.movement_speed, false
 end
end

local function new_movement_constraints(movement_speed, max_destination_distance)
 return {
  movement_speed = movement_speed,
  max_destination_distance = max_destination_distance,
 }
end

local direct_movement = {}
direct_movement.__index = direct_movement

function direct_movement:move(position)
 local velocity, destination_reached = move_to_target(position, self.destination, self.constraints)
 
 if self.at_destination then
  if not destination_reached then
   self.on_movement_start:invoke()
  end
 elseif destination_reached then
  self.on_destination_reached:invoke()
 end
 
 self.at_destination = destination_reached
 
 return velocity
end

function direct_movement:new(constraints, x, y)
 local o = {
  constraints = constraints,
  at_destination = true,
  on_destination_reached = subject(),
  on_movement_start = subject(),
  destination = vector(x, y),
 }
 
 setmetatable(o, self)
 
 return o
end

--------UNITS--------

local infantry = {}
infantry.__index = infantry

function infantry:new(x, y)
 local o = {
  position = vector(x, y),
  velocity = vector(0, 0),
  x_scale = 1,
  direct_movement = direct_movement:new(new_movement_constraints(32, 1), x, y),
  anim_state = anim_state:new(animations.infantry, "idle"),
 }
 
 o.direct_movement.on_movement_start:subscribe(function() o.anim_state:set_animation("moving") end)
 o.direct_movement.on_destination_reached:subscribe(function() o.anim_state:set_animation("idle") end)
 
 setmetatable(o, self)
 table.insert(objects, o)
 
 return o
end

function infantry:update(dt)
 self.anim_state:update(dt)
 self.velocity = self.direct_movement:move(self.position)
 
 if self.velocity.x ~= 0 then
  self.x_scale = self.velocity.x >= 0 and 1 or -1
 end
 
 self.position = self.position + self.velocity * dt
end

function infantry:draw()
 Sprite(self.anim_state:fetch("sprite"), self.position.x - 4 * self.x_scale, self.position.y - 8, 0, self.x_scale )
end

local new_infantry = infantry:new(10, 10)
--TESTING ANIMATION SYSTEM
new_infantry.destination = vector(20, 30)
new_infantry.anim_state:set_animation("idle")


--------LIKO-12--------

function _mousepressed(x, y, button)
 if button == 1 then
  new_infantry.direct_movement.destination = vector(x, y)
 end
end

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