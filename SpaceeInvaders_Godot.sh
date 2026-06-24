#!/bin/sh
printf '\033c\033]0;%s\a' SpaceInvaders_Godot
base_path="$(dirname "$(realpath "$0")")"
"$base_path/SpaceeInvaders_Godot.arm64" "$@"
