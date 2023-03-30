#!/bin/bash

ansible-playbook ../configure-docker.yml -i ../inventory.ini
ansible-playbook ../configure-zabbix-server.yml -i ../inventory.ini
ansible-playbook ../configure-zabbix.yml -i ../inventory.ini
ansible-playbook ../plex-server.yml -i ../inventory.ini
ansible-playbook ../samba-server.yml -i ../inventory.ini
ansible-playbook ../wireguard-server.yml -i ../inventory.ini
ansible-playbook ../configure-gitlabserver.yml -i ../inventory.ini
ansible-playbook ../configure-portainer.yml -i ../inventory.ini
ansible-playbook ../configure-portainer-agent.yml -i ../inventory.ini
ansible-playbook ../configure-filebrowser.yml -i ../inventory.ini
