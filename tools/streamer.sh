#!/usr/bin/env zsh

while true; do
	#echo "\n============\nRunning Camera stream"
	libcamera-vid -n -t 0 --inline --listen -o tcp://0.0.0.0:8888 > /dev/null 2>&1
	sleep 1
done

