#!/bin/bash
# Reload kitty after wallbash color update
killall -SIGUSR1 kitty 2>/dev/null
