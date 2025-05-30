# DoorbellPi: Smart Raspberry Pi Doorbell System

DoorbellPi is a Raspberry Pi-based smart doorbell system featuring:

- Random sound playback when the doorbell is pressed
- Output over Bluetooth or local (3.5mm) audio
- RGB LED feedback during audio playback
- Duplicate sound avoidance
- Event history logging

---

## 🔧 Hardware Requirements

- Raspberry Pi 4 or 5 (Raspberry Pi OS)
- Momentary push-button (connected between GPIO17 and GND)
- 4-pin common cathode RGB LED with three 220Ω–330Ω resistors:
  - Red → GPIO16 → resistor → Red LED leg
  - Green → GPIO20 → resistor → Green LED leg
  - Blue → GPIO21 → resistor → Blue LED leg
  - Longest leg (common cathode) → GND
- Bluetooth speaker (optional)

> ⚠️ Do **not** directly connect wires from a traditional transformer-powered doorbell circuit.
> Use a separate button or an optocoupler if interfacing with high-voltage or powered systems.

---

## 📁 Initial Folder Setup

Before running the conversion or deployment steps, create the folder structure:

```bash
mkdir -p sounds/mp3
```

Place your `.mp3` doorbell sounds in the `sounds/mp3/` directory.

---

## 🧲 GPIO Input Configuration Note

To ensure your GPIO pin correctly detects button presses (instead of constantly reading as `0`), configure the pin with an internal pull-up resistor using `/boot/firmware/config.txt`.

### Persistent Method (Recommended)

Edit the Raspberry Pi's config file:

```bash
sudo nano /boot/firmware/config.txt
```

> On older systems or legacy Pi OS, the path may be:
> ```bash
> /boot/config.txt
> ```

Add the following line at the bottom:

```bash
dtparam=gpio17=ip,pu
```

Then reboot:

```bash
sudo reboot
```

This sets GPIO17 as input (`ip`) with a pull-up resistor (`pu`), ensuring stable behavior across boots.

---

## 📶 Bluetooth Speaker Setup

To pair a Bluetooth speaker:

1. Start the Bluetooth CLI tool:

   ```bash
   bluetoothctl
   ```

2. Inside the prompt:

   ```bash
   power on
   agent on
   default-agent
   scan on
   ```

   Wait for your device to appear, then:

   ```bash
   pair XX:XX:XX:XX:XX:XX
   trust XX:XX:XX:XX:XX:XX
   connect XX:XX:XX:XX:XX:XX
   exit
   ```

3. Check the sink name for PulseAudio:

   ```bash
   pactl list short sinks
   ```

   Use the listed sink name (e.g., `bluez_output.XX_XX_XX_XX_XX_XX.a2dp-sink`) in your script as the `bluetooth_sink` value.

> Ensure the PulseAudio service is running under your user context (e.g. `pi`):
>
> ```bash
> systemctl --user start pulseaudio.service
> ```

---

## 💾 Software Installation

### 1. Clone and Install Dependencies

```bash
sudo apt update
sudo apt install -y ffmpeg alsa-utils libgpiod-utils pulseaudio-utils
sudo adduser $USER gpio

git clone https://github.com/reedwhaley/DoorbellPi.git
cd DoorbellPi
```

### 2. Convert MP3 Sounds to WAV

```bash
for f in sounds/mp3/*.mp3; do
  base=$(basename "$f" .mp3)
  ffmpeg -y -loglevel error -i "$f" "sounds/$base.wav" && rm "$f"
done
```

### 3. Generate Silence Padding

```bash
ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 0.5 silence.wav
```

### 4. Install Script and Service

```bash
sudo mkdir -p /opt/doorbell
sudo cp doorbell.sh /opt/doorbell/doorbell.sh
sudo cp silence.wav /opt/doorbell/silence.wav
sudo cp -r sounds /opt/doorbell/sounds
sudo chmod +x /opt/doorbell/doorbell.sh
```

Create systemd service:

```bash
sudo nano /etc/systemd/system/doorbell.service
```

Paste this:

```ini
[Unit]
Description=Smart Doorbell Script
After=network.target sound.target

[Service]
ExecStart=/opt/doorbell/doorbell.sh
WorkingDirectory=/opt/doorbell
StandardOutput=append:/opt/doorbell/doorbell_output.log
StandardError=append:/opt/doorbell/doorbell_error.log
Restart=always
User=pi
Environment="PULSE_RUNTIME_PATH=/run/user/1000/pulse"
Environment="XDG_RUNTIME_DIR=/run/user/1000"

[Install]
WantedBy=multi-user.target
```

Then enable it:

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable doorbell.service
sudo systemctl start doorbell.service
```

---

## 📘 GPIO Pin Reference

| Function | GPIO | Pin  |
|----------|------|------|
| Button   | 17   | 11   |
| Red LED  | 16   | 36   |
| Green LED| 20   | 38   |
| Blue LED | 21   | 40   |
| GND      | —    | 39   |

---

## 📂 Logs and History

- `/opt/doorbell/doorbell_output.log`: stdout
- `/opt/doorbell/doorbell_error.log`: errors
- `/opt/doorbell/history.log`: button events

---

## ✨ Customization

You can edit `doorbell.sh` to:

- Change GPIO pin assignments
- Modify LED behavior
- Increase button debounce timeout
- Add custom Bluetooth sink name

---

## 🛠 Contributing

Pull requests and improvements welcome! Open issues or fork the project.

---

## 📜 License

MIT License

Project maintained by [@reedwhaley](https://github.com/reedwhaley)
