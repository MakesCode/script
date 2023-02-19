#!/bin/bash

# Fonction qui écrit la date et l'heure dans un fichier texte
function write_to_file {
    echo "$(date) : $1" >> wifi_log.txt
}

# Boucle infinie pour exécuter le script en continu
while true; do
    # Récupère les informations de la connexion Wi-Fi
    ssid="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print $2}')"
    signal_strength="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/agrCtlRSSI/ {print $2}') dBm"
    tx_rate="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/lastTxRate/ {print $2}') Mbps"
    rx_rate="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/lastRxRate/ {print $2}') Mbps"
    latency="$(ping -c 1 -t 1 $(/sbin/ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}') | awk '/time=/ {print $7}' | cut -d '=' -f 2)"
    gateway_ip="$(netstat -nr | grep default | grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" -o)"
    
    # Vérifie si la connexion Wi-Fi est perdue
    if [ -z "$gateway_ip" ]; then
        write_to_file "Perte de connexion Wi-Fi."
        last_disconnect=$(date +%s)
        while [ -z "$gateway_ip" ]; do
            sleep 1
            gateway_ip="$(netstat -nr | grep default | grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" -o)"
        done
        current_time=$(date +%s)
        time_diff=$((current_time - last_disconnect))
        write_to_file "Connexion Wi-Fi rétablie après $time_diff secondes."
    fi
    
    # Écrit les informations de la connexion Wi-Fi dans le terminal et dans un fichier texte
    echo "SSID: $ssid"
    echo "Force du signal: $signal_strength"
    echo "Débit d'émission: $tx_rate"
    echo "Débit de réception: $rx_rate"
    echo "Latence: $latency ms"
    echo "Adresse IP de la passerelle: $gateway_ip"
    echo ""
    write_to_file "SSID: $ssid, Force du signal: $signal_strength, Débit d'émission: $tx_rate, Débit de réception: $rx_rate, Latence: $latency ms, Adresse IP de la passerelle: $gateway_ip"
    
    # Attente de 10 secondes avant de récupérer les informations de nouveau
    sleep 10
done
