# edge-net-hub

The network centre of [edge-net](https://github.com/jackwaddington/edge-net). A Raspberry Pi 4 (1GB) running OpenBSD, acting as a WiFi access point, DHCP server, and MQTT broker for all nodes on the network.

## Hardware

- Raspberry Pi 4 (1GB RAM)
- Ethernet uplink to home network (optional — network works without it)
- WiFi used as access point for nodes to connect to

## What it does

| Service | Role |
| ------- | ---- |
| pf (packet filter) | Firewall and traffic control between nodes |
| hostapd | WiFi access point — nodes connect here |
| dhcpd | Assigns IP addresses to nodes |
| Mosquitto | MQTT broker — the message bus for all nodes |

## pf / firewall

OpenBSD's pf is the packet filter. It controls what traffic is allowed between nodes on the WiFi network and what is permitted out to the home network via the ethernet uplink. This means node-to-node communication can be explicitly allowed or blocked at the network level, independently of the application code on each node.

When the ethernet uplink is disconnected, the network operates in standalone mode — nodes can still communicate with each other via MQTT, but traffic to the home network (e.g. Prometheus/Grafana) is unavailable.

## MQTT

Mosquitto runs as a broker. All nodes connect to it on the standard MQTT port (1883). Nodes publish and subscribe to topics — no direct node-to-node connections are needed.

## Part of edge-net

See [edge-net](https://github.com/jackwaddington/edge-net) for the full architecture and list of nodes.
