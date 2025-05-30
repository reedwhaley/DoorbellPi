#!/bin/bash

exec 2> /var/log/doorbell.log
exec 1>&2

# GPIO Configuration (Update for your board)
button_chip="gpiochip0"
button_line=17

# RGB LED GPIO pins (adjust as needed)
rgb_chip="gpiochip0"
red=16
green=20
blue=21

# Paths (customize for your install)
sound_dir="/opt/doorbell/sounds"
silence_file="/opt/doorbell/silence.wav"
history_log="/opt/doorbell/history.log"
bluetooth_sink="bluez_output.YOUR_MAC_ADDRESS.1"
timeout=10
currEpochTime=$(date +%s)

declare -a recent_sounds=()

echo "Doorbell script started at $(date)"

pick_sound() {
    mapfile -t all_sounds < <(find "$sound_dir" -type f -iname '*.wav')

    if [ "${#all_sounds[@]}" -eq 0 ]; then
        echo "No .wav files found in $sound_dir" >&2
        return 1
    fi

    if [ "${#all_sounds[@]}" -le 2 ]; then
        echo "${all_sounds[RANDOM % ${#all_sounds[@]}]}"
        return
    fi

    while true; do
        candidate="${all_sounds[RANDOM % ${#all_sounds[@]}]}"
        if [[ ! " ${recent_sounds[@]} " =~ " ${candidate} " ]]; then
            recent_sounds+=("$candidate")
            if [ "${#recent_sounds[@]}" -gt 2 ]; then
                recent_sounds=("${recent_sounds[@]: -2}")
            fi
            echo "$candidate"
            return
        fi
    done
}

bluetooth_connected() {
    pactl list short sinks | grep -q "$bluetooth_sink"
}

random_rgb_blink() {
    while kill -0 "$1" 2>/dev/null; do
        r=$((RANDOM % 2))
        g=$((RANDOM % 2))
        b=$((RANDOM % 2))
        if [ $r -eq 0 ] && [ $g -eq 0 ] && [ $b -eq 0 ]; then
            r=1
        fi
        gpioset $rgb_chip $red=$r $green=$g $blue=$b
        sleep 0.2
    done
    gpioset $rgb_chip $red=0 $green=0 $blue=0
}

while true; do
    if [ "$(gpioget $button_chip $button_line)" -eq 0 ]; then
        newEpochTime=$(date +%s)
        if [ $((newEpochTime - currEpochTime)) -ge $timeout ]; then
            currEpochTime=$newEpochTime
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')

            sound=$(pick_sound) || continue
            echo "$timestamp - Selected: $sound"

            if bluetooth_connected; then
                paplay --device="$bluetooth_sink" "$silence_file"
                paplay --device="$bluetooth_sink" "$sound" &
                method="Bluetooth"
            else
                aplay "$silence_file"
                aplay "$sound" &
                method="Local"
            fi

            pid=$!
            random_rgb_blink "$pid"

            echo "$timestamp - $method - $sound" >> "$history_log"

            while [ "$(gpioget $button_chip $button_line)" -eq 0 ]; do
                sleep 0.1
            done
        fi
    fi
    sleep 0.1
done
