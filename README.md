# edge-net-hub

The network centre of [Edge-NET](https://github.com/jackwaddington/edge-net). A Raspberry Pi 4 (1GB) running [OpenBSD](https://www.openbsd.org/), acting as a WiFi access point, DHCP server, and MQTT broker for all nodes on the network.

## Hardware

- [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/specifications/) (1GB RAM)
- Ethernet uplink to home network (optional — network works without it)
- WiFi used as access point for nodes to connect to

## What it does

| Service | Role |
| ------- | ---- |
| pf (packet filter) | Firewall and traffic control between nodes |
| hostapd | WiFi access point — nodes connect here |
| dhcpd | Assigns IP addresses to nodes |
| Mosquitto | MQTT broker — the message bus for all nodes |

## Network plan

### Address space

Using `10.1.x.x` (RFC 1918). Each physical network gets its own /24 — only the third octet changes per network.

| Network | Subnet | Interface | Notes |
| ------- | ------ | --------- | ----- |
| WiFi AP (Edge-NET) | `10.1.1.0/24` | `athn0` (or similar) | All nodes connect here |
| Ethernet uplink | DHCP from home router | `em0` | Optional — standalone works without it |
| Reserved | `10.1.2.0/24` | — | Future ethernet interface |
| Reserved | `10.1.3.0/24` | — | Future use |

### Node addresses (WiFi — `10.1.1.0/24`)

Assigned by dhcpd via MAC reservation, so addresses are predictable.

| Address | Node | Hardware | OS |
| ------- | ---- | -------- | -- |
| `10.1.1.1` | hub (gateway) | Pi 4 | OpenBSD |
| `10.1.1.10` | edge-net-keybow | Pi Zero W | Linux |
| `10.1.1.11` | edge-net-automation | Pi 3A | Linux |
| `10.1.1.20` | edge-net-gfx | Pi Pico W | microcontroller |
| `10.1.1.21` | edge-net-plasma | Plasma Stick 2040W | microcontroller |
| `10.1.1.50–99` | — | — | Reserved (future nodes) |
| `10.1.1.100–199` | — | — | DHCP dynamic pool |

Linux SBCs get `.10`–`.19`, microcontrollers get `.20`–`.29`. Microcontrollers may run MicroPython or C++ — the distinguishing factor is no OS, flash via USB.

### pf intent

| Source | Destination | Ports | Action | Reason |
| ------ | ----------- | ----- | ------ | ------ |
| any | `10.1.1.1:1883` | TCP | pass | All nodes reach MQTT broker |
| `10.1.1.10–19` | `10.1.1.0/24` | any | pass | Linux Pis can SSH to each other |
| `10.1.1.20–29` | `10.1.1.1:1883` | TCP | pass | Microcontrollers: MQTT only |
| `10.1.1.20` (gfx) | `<k3s-node>:<port>` | TCP | pass | GFX → Prometheus/Grafana on home network |
| any | any (internet) | any | block | No internet access |

> `<k3s-node>:<port>` — to be filled once the home network subnet and k3s node IP are confirmed.

## pf / firewall

OpenBSD's pf is the packet filter. It controls what traffic is allowed between nodes on the WiFi network and what is permitted out to the home network via the ethernet uplink. This means node-to-node communication can be explicitly allowed or blocked at the network level, independently of the application code on each node.

When the ethernet uplink is disconnected, the network operates in standalone mode — nodes can still communicate with each other via MQTT, but traffic to the home network (e.g. Prometheus/Grafana) is unavailable.

## MQTT

Mosquitto runs as a broker. All nodes connect to it on the standard MQTT port (1883). Nodes publish and subscribe to topics — no direct node-to-node connections are needed.

## References

- [OpenBSD PF — Firewall example](https://www.openbsd.org/faq/pf/example1.html)
- [OpenBSD Handbook — Simple router](https://www.openbsdhandbook.com/howto/simple_router)
- [Book of PF](https://nostarch.com/pf3)
- [Absolute OpenBSD](https://nostarch.com/obenbsd2e)

## Part of Edge-NET

See [Edge-NET](https://github.com/jackwaddington/edge-net) for the full architecture and list of nodes.
