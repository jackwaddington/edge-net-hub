include .env

HUB = $(HUB_USER)@$(HUB_IP)

.PHONY: pull push reload

pull:
	scp $(HUB):/etc/hostname.bse0          etc/
	scp $(HUB):/etc/pf.conf                etc/
	scp $(HUB):/etc/dhcpd.conf             etc/
	scp $(HUB):/etc/rc.conf.local          etc/
	scp $(HUB):/etc/mosquitto/mosquitto.conf etc/mosquitto/

push:
	scp etc/hostname.bse0           $(HUB):/tmp/
	scp etc/pf.conf                 $(HUB):/tmp/
	scp etc/dhcpd.conf              $(HUB):/tmp/
	scp etc/rc.conf.local           $(HUB):/tmp/
	scp etc/mosquitto/mosquitto.conf $(HUB):/tmp/mosquitto.conf
	@sed 's/$${WIFI_SSID}/$(WIFI_SSID)/g; s/$${WIFI_PASSWORD}/$(WIFI_PASSWORD)/g' \
		etc/hostname.bwfm0 > /tmp/hostname.bwfm0.rendered
	scp /tmp/hostname.bwfm0.rendered $(HUB):/tmp/hostname.bwfm0
	ssh -t $(HUB) "doas mv /tmp/hostname.bse0 /tmp/hostname.bwfm0 /tmp/pf.conf /tmp/dhcpd.conf /tmp/rc.conf.local /etc/ && doas mv /tmp/mosquitto.conf /etc/mosquitto/mosquitto.conf"

reload: push
	ssh $(HUB) "doas pfctl -f /etc/pf.conf"
	ssh $(HUB) "doas rcctl restart dhcpd"
	ssh $(HUB) "doas rcctl restart mosquitto"
