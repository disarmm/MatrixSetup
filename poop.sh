#!/bin/bash
if [ -z "$(pgrep gman)" ]
        then
                echo "gman is stopped"
        else
                echo "gman is still running" && lb && echo "Killing gman" && kill -9 $(pgrep gman)
        fi
