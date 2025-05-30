
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
- 4-pin common cathode RGB LED with current-limiting resistors wired to:
  - Red → GPIO16
  - Green → GPIO20
  - Blue → GPIO21
- Bluetooth speaker (optional)

> ⚠️ Do **not** directly connect wires from a traditional transformer-powered doorbell circuit.
> Use a separate button or an optocoupler if interfacing with high-voltage or powered systems.

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

Place `.mp3` files in `sounds/mp3/`, then run:

```bash
mkdir -p sounds
mkdir -p sounds/mp3
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
