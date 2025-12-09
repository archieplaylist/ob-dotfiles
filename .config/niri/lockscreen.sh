#!/bin/sh

# 1. Take a screenshot
niri msg action screenshot-screen --path /tmp/lockscreen.png

# 2. Blur the screenshot (Faster method: resize down, blur, resize up)
# Adjust 20% and 500% for faster/slower blurring.
# Adjust 0x2.5 for blur strength.
convert /tmp/lockscreen.png -resize 20% -blur 0x2.5 -resize 500% /tmp/lockscreen_blurred.png

# 3. Lock the screen with the blurred image
swaylock -i /tmp/lockscreen_blurred.png