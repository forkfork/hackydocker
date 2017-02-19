#!/bin/sh

redis-cli flushall >/dev/null

redis-cli lpush services helloworld >/dev/null
redis-cli set helloworld:desired 2 >/dev/null
redis-cli set helloworld:stable v1 >/dev/null
redis-cli set helloworld:canary v2 >/dev/null

# startup, box claims helloworld v1 instance 1
O=$(redis-cli --eval startup.lua 10.0.0.1)
E="set
helloworld:v1:1"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# startup, box claims helloworld v1 instance 2
O=$(redis-cli --eval startup.lua 10.0.0.1)
E="set
helloworld:v1:2"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# startup, box claims helloworld v2 instance 1
O=$(redis-cli --eval startup.lua 10.0.0.1)
E="set
helloworld:v2:1"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# startup, box claims helloworld v2 instance 2
O=$(redis-cli --eval startup.lua 10.0.0.1)
E="set
helloworld:v2:2"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# startup, no work needs to happen
O=$(redis-cli --eval startup.lua 10.0.0.1)
E="nowork"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# heartbeat, success
O=$(redis-cli --eval heartbeat.lua 10.0.0.1 helloworld v1 1)
E="heartbeat
helloworld:v1:1:10.0.0.1"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# heartbeating a higher instance than desired
O=$(redis-cli --eval heartbeat.lua 10.0.0.1 helloworld v1 3)
E="shutdown
scaledown"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

# heartbeating a version that doesn't exist
O=$(redis-cli --eval heartbeat.lua 10.0.0.1 helloworld v3 1)
E="shutdown
rolledoff"
if [ "$O" != "$E" ]; then echo "FAILED got $O expected $E"; exit 1; fi

echo "Redis script tests PASSED"
