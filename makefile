.PHONY: download-offline

update:
	wget https://get.kubesolo.io -O offline/install.sh && chmod +x offline/install.sh
	wget https://uninstall.kubesolo.io -O offline/uninstall.sh && chmod +x offline/uninstall.sh
