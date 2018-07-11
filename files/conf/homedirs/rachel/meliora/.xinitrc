#exec startfluxbox
# Change your keymap:
xmodmap "/home/rachel/.Xmodmap"

# Fix the screen.  Otherwise it gets some lower resolution and mirrors the
# laptop screen.  This turns off the screen and sets the full resoluton.
. ~/.screenlayout/hdmi-only.sh

# Don't turn off the monitor.  I am in doubt, and using brute force:
# - set timeout and cycle to zero
xset s 0 0
# - turn of screen saver features
xset s off
# - set standby, suspend, and off timeouts to zero
xset dpms 0 0 0
# - disable dpms
xset -dpms

# Christmas!
#mplayer --no-consolecontrols --loop=0 --rootwin ~/fireplace.mp4 &
/usr/bin/xscreensaver -no-splash &

exec i3
