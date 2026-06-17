# 🌐 Tor IP Changer

A simple Bash-based tool that uses Tor to automatically rotate your public IP address at custom intervals. It works by repeatedly requesting new Tor circuits, giving you a new exit-node IP each time — handy for privacy testing, demonstrating IP rotation, or showing how geo-based services react to different locations.

## How It Works

Tor routes your traffic through a chain of volunteer-run relays before it reaches the internet, exiting through a randomly assigned **exit node**. Requesting a new circuit swaps that exit node, which changes the IP address — and often the apparent country/city — that websites see, without touching your actual connection.

## Features

- Rotates your Tor exit IP automatically on a timer
- Configurable interval and rotation count, including infinite rotation
- Pairs with a browser (e.g., Firefox) for a live visual demo
- Minimal dependencies — just Tor, curl, and netcat

## Prerequisites

- A Debian/Ubuntu-based Linux distribution
- `sudo` access
- Tor, curl, and `netcat-openbsd`

## Installation

**1. Install dependencies**

```bash
sudo apt update
sudo apt install tor curl netcat-openbsd -y
```

**2. Start the Tor service**

```bash
sudo systemctl enable tor@default
sudo systemctl start tor@default
sudo systemctl status tor@default
```

**3. Verify Tor is running**

```bash
curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org
```

If Tor is active, this returns an exit-node IP, e.g. `185.xxx.xxx.xxx`.

## Optional: Route Firefox Through Tor

For a visual demo, point Firefox at the local Tor proxy:

1. Open **Settings → Network Settings → Manual Proxy Configuration**
2. Set:
   - **SOCKS Host:** `127.0.0.1`
   - **Port:** `9050`
   - **SOCKS v5** selected
   - ✔️ **Proxy DNS when using SOCKS v5**
3. Save your settings.

## Usage

Make the script executable, then run it:

```bash
chmod +x ip-changer.sh
sudo ./ip-changer.sh
```

You'll be prompted for two values:

```
Enter time interval: 2
Enter number of times: 0
```

- **Time interval** — seconds between each rotation
- **Number of times** — how many rotations to perform (`0` runs indefinitely)

The script then continuously requests new circuits:

```
Requesting new Tor circuit...
New Tor IP: 185.xxx.xxx.xxx
New Tor IP: 89.xxx.xxx.xxx
New Tor IP: 93.xxx.xxx.xxx
```

## Verifying the Rotation

**Live check in a second terminal:**

```bash
watch -n 2 "curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org"
```

**In Firefox**, visit `https://api.ipify.org?format=json` and hard-refresh (`Ctrl + Shift + R`) to watch the IP change on each reload:

```json
{"ip":"185.xxx.xxx.xxx"}
{"ip":"89.xxx.xxx.xxx"}
{"ip":"93.xxx.xxx.xxx"}
```

For a richer view that also shows country, city, and location changes, try:

- [ipinfo.io](https://ipinfo.io/)
- [ipapi.co/json](https://ipapi.co/json/)

## Troubleshooting

If the script fails to rotate circuits, double-check that your Tor instance's control port setup matches what `ip-changer.sh` expects (commonly `ControlPort 9051` in `/etc/tor/torrc`), then restart the Tor service after any config change.

## Disclaimer

This tool is intended for educational purposes, privacy testing, and personal use. Tor is a legitimate anonymity network — use it responsibly, in line with the terms of service of any site you interact with and the laws of your jurisdiction.
