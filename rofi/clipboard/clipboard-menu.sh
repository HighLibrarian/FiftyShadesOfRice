#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi"
theme='playground.rasi'
tmpdir=/tmp/cliphist-rofi

# clear our clipboard temp folder and create it anew
rm --recursive --force "$tmpdir"
mkdir --parents "$tmpdir"


# start our rofi clipboard manager and expose kb-custom-1 as "variable" for our actions. 
# action will be the item we select in our list menu. after we selected an item or clicked a button, an exit code will be 
# written to $? wich we'll assign to $rofireturn
action=$(cliphist list | rofi -dmenu -p "clipboard" -theme $dir/$theme -kb-custom-1 "" -display-columns 2)


# write the returncode to a text file for testing: 
# echo $rofireturn >> ~/.config/rofi/clipboard/actions.txt
# 0: clipboard is used
# 10: clipboard clear button is pressed
rofireturn=$?


case $rofireturn in
        0)
            echo "$action" | cliphist decode | wl-copy 
            ;;
        10) 
            cliphist wipe
            notify-send '   Clipboard cleaned'
            ;;
esac # OMG case spelled backwards