#!/bin/bash

if [ -z $INTERNET_IF ] || [ -z $BRIDGE_IF ] || [ -z $BRIDGE_IF_CIDR ]; then
  echo "Please set INTERNET_IF, BRIDGE_IF and BRIDGE_IF_CIDR"
  exit 1
fi

filter_rules=(
  "FORWARD -i ${BRIDGE_IF} -o ${INTERNET_IF} -j ACCEPT"
  "FORWARD -i ${INTERNET_IF} -o ${BRIDGE_IF} -m state --state RELATED,ESTABLISHED -j ACCEPT"
)

nat_rules=(
  "POSTROUTING -o ${INTERNET_IF} -j MASQUERADE"
)

case $1 in
  setup)
    sudo ip link del ${BRIDGE_IF} || true
    sudo ip link add name ${BRIDGE_IF} type bridge
    sudo ip addr add ${BRIDGE_IF_CIDR} brd + dev ${BRIDGE_IF}
    sudo ip link set ${BRIDGE_IF} up

    sudo sysctl net.ipv4.ip_forward=1
    for ((i=0; i<${#filter_rules[@]}; i++)); do
      sudo iptables -t filter -A ${filter_rules[i]}
    done
    for ((i=0; i<${#nat_rules[@]}; i++)); do
      sudo iptables -t nat -A ${nat_rules[i]}
    done
    ;;
  cleanup)
    sudo ip link del ${BRIDGE_IF} || true
    for ((i=0; i<${#filter_rules[@]}; i++)); do
      sudo iptables -t filter -D ${filter_rules[i]} || true
    done
    # for ((i=0; i<${#nat_rules[@]}; i++)); do
    #   sudo iptables -t nat -D ${nat_rules[i]} || true
    # done
    ;;
  *)
    echo "Usage: $0 setup|cleanup"
    exit 1
    ;;
esac
