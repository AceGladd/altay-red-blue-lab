#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
curl -sOL https://packages.wazuh.com/4.7/wazuh-install.sh
bash ./wazuh-install.sh -a