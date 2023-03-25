#!/bin/bash

ansible-playbook configure-docker.yml -i inventory.ini
ansible-playbook configure-filebrowser.yml -i inventory.ini
ansible-playbook plex-server.yml -i inventory.ini
ansible-playbook samba-server.yml -i inventory.ini
ansible-playbook wireguard-server.yml -i inventory.ini
