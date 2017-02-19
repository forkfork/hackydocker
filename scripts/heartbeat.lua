local this_ip = KEYS[1]
local service = KEYS[2]
local version = KEYS[3]
local slot = KEYS[4]

local this_version = service .. ':' .. version
local this_slot = service .. ':' .. version .. ':' .. slot

local services = redis.call('lrange', 'services', 0, -1)
local stable_service = redis.call('get', service .. ':stable')
local canary_service = redis.call('get', service .. ':canary')
local desired = redis.call('get', service .. ':desired')

if stable_service ~= version and canary_service ~= version then
  -- our version has been rolled out
  return { 'shutdown', 'rolledoff' }
end

if slot > desired then
  return { 'shutdown', 'scaledown' }
end

local my_slot_value = redis.call('get', this_slot)

if my_slot_value == this_ip then
  -- we are happy, just poke the heartbeat
  redis.call('set', this_version, this_ip)
  return { 'heartbeat', this_slot .. ':' .. this_ip }

else
  if my_slot_value then
    return { 'alarm', 'replaced by ' .. my_slot_value }
  else
    return { 'alarm', 'expired' }
  end
   
end
