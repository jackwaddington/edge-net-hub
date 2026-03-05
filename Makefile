include .env

HUB = $(HUB_USER)@$(HUB_IP)

.PHONY: pull push reload

pull:
	scp $(HUB):/etc/hostname.em0     etc/
	scp $(HUB):/etc/hostname.athn0   etc/
	scp $(HUB):/etc/pf.conf          etc/
	scp $(HUB):/etc/dhcpd.conf       etc/
	scp $(HUB):/etc/rc.conf.local    etc/

push:
	scp etc/hostname.em0     $(HUB):/etc/
	scp etc/hostname.athn0   $(HUB):/etc/
	scp etc/pf.conf          $(HUB):/etc/
	scp etc/dhcpd.conf       $(HUB):/etc/
	scp etc/rc.conf.local    $(HUB):/etc/
	@sed 's/$${WIFI_SSID}/$(WIFI_SSID)/g; s/$${WIFI_PASSWORD}/$(WIFI_PASSWORD)/g' \
		etc/hostapd.conf.template \
		| ssh $(HUB) "doas tee /etc/hostapd.conf > /dev/null"

reload: push
	ssh $(HUB) "doas pfctl -f /etc/pf.conf"
	ssh $(HUB) "doas rcctl restart dhcpd"
	ssh $(HUB) "doas rcctl restart hostapd"
	ssh $(HUB) "doas rcctl restart mosquitto"
