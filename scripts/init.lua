#!/bin/bash

# initially for testing

redis-cli flushall >/dev/null

redis-cli lpush services helloworld >/dev/null
redis-cli set helloworld:desired 2 >/dev/null
redis-cli set helloworld:stable v1 >/dev/null
redis-cli set helloworld:canary v2 >/dev/null

# Startup mode
while true
do

  eval set -- $(redis-cli --eval startup.lua `hostname`)
  STARTUPCMD=$1
  STARTUPDETAILS=$2
  if [ "$STARTUPCMD" == "set" ]; then
    echo "Starting service $STARTUPDETAILS"
  else
    echo "no work"
  fi

  sleep 1

done

IFS=: eval set -- $STARTUPDETAILS
SERVICE=$1
VERSION=$2
SLOTNUM=$3

# Heartbeat mode
while true
do
  eval set -- $(redis-cli --eval heartbeat.lua $SERVICE $VERSION $SLOTSUM `hostname`)
done
