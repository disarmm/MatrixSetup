#!/bin/bash

# get paths for installation that have at least 300GB

df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 300 {print}' | awk '$4 !~/M/ {print}' | awk 'length($4) >= 4 {print}' | awk '{print $6}'
