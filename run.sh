#!/bin/zsh

docker run -it \
--name claude \
--network host \
-v $HOME/workspace:/home/claude/workspace \
ub24:9 
