#!/bin/bash

# ================================================
# Tor IP Changer - Reliable Version
# ================================================

if [[ "$EUID" -ne 0 ]]; then
    echo -e "\033[31mError: Script must be run as root.\033[0m"
    exit 1
fi

# Colors
ORANGE='\033[38;5;208m'
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
RESET='\033[0m'

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════╗
║                                              ║
║               IP CHANGER                     ║
║                                              ║
║        Tor Automatic IP Rotator              ║
║                                              ║
╚══════════════════════════════════════════════╝
EOF
echo -e "${GREEN}                  Automatic Tor Exit Node Rotation${RESET}\n"

# Install if needed
install_packages() {
    echo -e "${ORANGE}Installing curl and tor if needed...${RESET}"
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y curl tor
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm curl tor
    elif command -v yum &> /dev/null; then
        yum install -y curl tor
    else
        echo -e "${RED}Please install curl and tor manually.${RESET}"
        exit 1
    fi
}

if ! command -v curl &> /dev/null || ! command -v tor &> /dev/null; then
    install_packages
fi

get_ip() {
    local ip
    for site in "https://api.ipify.org" "https://checkip.amazonaws.com" "https://ifconfig.me"; do
        ip=$(curl -s --max-time 10 -x socks5h://127.0.0.1:9050 "$site" 2>/dev/null | tr -d '[:space:]')
        if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return
        fi
    done
    echo "Unknown"
}

change_ip() {
    echo -e "${ORANGE}Requesting new Tor circuit (NEWNYM)...${RESET}"
    
    # Primary method: NEWNYM via control port
    echo -e 'AUTHENTICATE ""\nSIGNAL NEWNYM\nQUIT' | nc -q 1 127.0.0.1 9051 &>/dev/null || {
        # Fallback
        echo -e "${ORANGE}Falling back to service reload...${RESET}"
        systemctl reload tor@default.service 2>/dev/null || systemctl reload tor.service
    }
    
    sleep 3
    local new_ip=$(get_ip)
    echo -e "${GREEN}New Tor IP: ${new_ip}${RESET}"
}

ensure_tor_running() {
    if ! systemctl is-active tor@default.service &> /dev/null && ! systemctl is-active tor.service &> /dev/null; then
        echo -e "${ORANGE}Starting Tor service...${RESET}"
        systemctl enable --now tor@default.service 2>/dev/null || systemctl enable --now tor.service
        sleep 8
    fi
}

ensure_tor_running
echo -e "${GREEN}Tor is ready. Current Tor IP: $(get_ip)${RESET}\n"

echo -e "${RED}⚠️  IMPORTANT:${RESET}"
echo -e "To see changing IPs on https://api.ipify.org, you must browse through Tor!"
echo -e "   • Use Tor Browser, or"
echo -e "   • Configure Firefox/Chrome with SOCKS5 proxy 127.0.0.1:9050\n"

# Main loop
while true; do
    echo -ne "${ORANGE}Enter time interval in seconds (0 for random 10-20s): ${RESET}"
    read -r interval
    
    echo -ne "${ORANGE}Enter number of times to change IP (0 for infinite): ${RESET}"
    read -r times

    if [[ "$interval" -eq 0 ]] || [[ "$times" -eq 0 ]]; then
        echo -e "${GREEN}Starting infinite IP changes...${RESET}"
        while true; do
            change_ip
            if [[ "$interval" -eq 0 ]]; then
                sleep_time=$(shuf -i 10-20 -n 1)
            else
                sleep_time="$interval"
            fi
            sleep "$sleep_time"
        done
    else
        echo -e "${GREEN}Changing IP $times times...${RESET}"
        for ((i=1; i<=times; i++)); do
            echo -e "${BLUE}[$i/$times]${RESET}"
            change_ip
            [[ $i -lt $times ]] && sleep "$interval"
        done
    fi

    echo -e "\n${ORANGE}Press Enter for new settings or Ctrl+C to quit...${RESET}"
    read -r
done