-- args: [current host ip]
-- when a host is needed returns: { 'set', 'helloworld:v1:1' }
-- when not needed,return: { 'nowork', nil }

local this_ip = KEYS[1]

local services = redis.call('lrange', 'services', 0, -1)

local take_slot = function(service, ver, n_inst, this_ip)
  if not ver then return nil end
  for n = 1, n_inst do
    local slot = redis.call('get', service .. ':' .. ver .. ':' .. n)
    if not slot then
      redis.call('set', service .. ':' .. ver .. ':' .. n, this_ip)
      return service .. ':' .. ver .. ':' .. n
    end
  end
  return nil
end

for i = 1, #services do
  local service = services[i]
  local n_inst = redis.call('get', service .. ':desired')
  local stable_ver = redis.call('get', service .. ':stable')
  local canary_ver = redis.call('get', service .. ':canary')
  local slot
  slot = take_slot(service, stable_ver, n_inst, this_ip)
  if slot then return { 'set', slot } end
  slot = take_slot(service, canary_ver, n_inst, this_ip)
  if slot then return { 'set', slot } end
end

return {'nowork', nil}
