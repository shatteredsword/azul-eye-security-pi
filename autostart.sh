VIEW=shippingdock3
SERVER=azuleye2
VLC=true
VERTICAL=false
RESOLUTION=720p
USER=blueuser
PASSWORD=pa$$word
REFRESH=20m
PORT=81
DOMAIN=example.net

PAGE="http://$SERVER.$DOMAIN:$PORT/mjpg/$VIEW/video.mjpg?user=$USER&pw=$PASSWORD"

if [ "$RESOLUTION" = 1080p ]; then
    WIDTH=1920
    HEIGHT=1080
elif [ "$RESOLUTION" = 720p ]; then
    WIDTH=1280
    HEIGHT=720
else
    WIDTH=1280
    HEIGHT=720
fi

if [ "$VERTICAL" = true ]; then
    ORIENTATION=right
    RATIO="9:16"
    STREAM=2
else
    ORIENTATION=normal
    RATIO="16:9"
    STREAM=1
fi

export DISPLAY=:0
xrandr -s "${WIDTH}x${HEIGHT}" -o $ORIENTATION

FILE="$(mktemp /tmp/XXXXXXXXXXXXXX.m3u)"
tee -a $FILE > /dev/null <<EOF
rtsp://$SERVER.$DOMAIN:$PORT/$VIEW?stream=$STREAM
EOF


if [ "$VLC" = true ]; then
    while true
    do
        DISPLAY=:0 vlc --qt-minimal-view --loop --rtsp-user=$USER --rtsp-pwd=$PASSWORD --no-video-title --crop $RATIO --width $WIDTH --height $HEIGHT --no-qt-video-autoresize --vout mmal_vout $FILE &
        sleep "$REFRESH"
        pkill vlc
    done
else
    if [ $(dpkg-query -W -f='${Status}' unclutter 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt install -y unclutter
    fi
    if [ $(dpkg-query -W -f='${Status}' xdotool 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt install -y xdotool
    fi
    DISPLAY=:0 chromium-browser --kiosk --noerrdialogs --incognito --disable-site-isolation-trials --enable-low-end-device-mod --force-device-scale-factor=1.5 --app=$PAGE &
    while ps -aux | grep -v grep | grep "chromium-browser";
    do
        sleep "$REFRESH"
        DISPLAY=:0 xdotool key ctrl+F5
    done
fi
