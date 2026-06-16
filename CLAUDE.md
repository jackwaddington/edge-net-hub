# Edge-NET Hub — Claude Context

This repo configures the Edge-NET hub: a Pi 4 running OpenBSD, acting as WiFi AP, DHCP server, and MQTT broker for all edge-net nodes.

## Access

| Thing | Value |
|---|---|
| Hub home network IP | `192.168.0.145` |
| Hub SSH alias | `ssh hub` (if configured) |
| Hub user | `jack` |
| Edge-NET subnet | `10.1.1.0/24` |
| Hub edge-net IP | `10.1.1.1` |
| Hub OS | OpenBSD — uses `doas` not `sudo` |

Secrets (WiFi SSID, password) are in `.env` — not committed. If `.env` is missing, pull from the private secrets repo:

```bash
gh repo clone jackwaddington/edge-net-secrets /tmp/edge-net-secrets
cp /tmp/edge-net-secrets/edge-net-hub/.env .env
```

## Node IPs

| IP | Node | Hardware | SSH user | Status |
|---|---|---|---|---|
| `10.1.1.1` | hub | Pi 4 | `jack` | live |
| `10.1.1.10` | edge-net-keybow | Pi Zero W | `edge` | configured, not verified |
| `10.1.1.12` | edge-net-automation | Pi 3A | `edge` | live |
| `10.1.1.20` | edge-net-gfx | Pi Pico W | n/a | configured, not verified |
| `10.1.1.21` | edge-net-plasma | Plasma Stick | n/a | configured, not verified |

SSH to nodes goes via hub: `ssh jack@192.168.0.145` then `ssh edge@10.1.1.x`. Hub has a passwordless ed25519 key (`~/.ssh/id_ed25519`) authorized on all Linux nodes.

## The `edge` user

All Linux nodes have a local `edge` user. This is the standard user for hub-initiated SSH and for running edge-net services. No password — key auth only.

To create `edge` on a new node (run on the node as `jack`):

```bash
sudo useradd -m -s /bin/bash edge
sudo mkdir -p /home/edge/.ssh
sudo cp ~/.ssh/authorized_keys /home/edge/.ssh/authorized_keys
sudo chown -R edge:edge /home/edge/.ssh
sudo chmod 700 /home/edge/.ssh && sudo chmod 600 /home/edge/.ssh/authorized_keys
```

Then verify from hub: `ssh edge@10.1.1.x`

## Conventions

- Linux SBCs: fixed IPs `.10`–`.19`, SSH as `edge`, no password
- Microcontrollers: fixed IPs `.20`–`.29`, no SSH (flash via USB)
- Config files in this repo map 1:1 to `/etc/` on the hub
- Deploy: `scp` file to hub then `doas rcctl restart <service>`

## Key files

| Repo path | Hub path | Purpose |
|---|---|---|
| `etc/hostname.bwfm0` | `/etc/hostname.bwfm0` | WiFi AP — SSID/password (templated from `.env`) |
| `etc/dhcpd.conf` | `/etc/dhcpd.conf` | Fixed IPs by MAC for each node |
| `etc/pf.conf` | `/etc/pf.conf` | Firewall rules |
| `etc/mosquitto/mosquitto.conf` | `/etc/mosquitto/mosquitto.conf` | MQTT broker config |

## Adding a new node

1. Get MAC address — `arp -a` on hub after node connects, or check home router
2. Add fixed DHCP entry to `etc/dhcpd.conf` with MAC and chosen IP (`.10`–`.19` for Linux SBCs)
3. Deploy and restart: `scp etc/dhcpd.conf jack@192.168.0.145:/etc/dhcpd.conf && ssh jack@192.168.0.145 "doas rcctl restart dhcpd"`
4. Connect node to WiFi — SSID and password from `.env`
5. Node gets assigned IP — SSH in as `jack`, create `edge` user (see above)
6. From hub, verify: `ssh edge@10.1.1.x` — should be passwordless

## WiFi

AP runs on `bwfm0`. SSID and password set in `/etc/hostname.bwfm0`, templated from `.env`. To change credentials, update `.env`, re-run `make deploy` (or manually sed the file on hub), then `doas sh /etc/netstart bwfm0`. WPA2 password must be 8–63 characters.

## MQTT

Broker on hub at `10.1.1.1:1883`. No auth currently — all nodes on the WiFi subnet can publish/subscribe.
