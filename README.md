# Ansible configuration for Proxmox VM's

## Secrets Akeyless configuration
To configure Akeyless token
First of all we have to create an account in akeyless. Then install 
```bash
pip install hvac
```
And export
```bash
export VAULT_ADDR=https://hvp.akeyless.io
```
Once we have done that, we must create an API token as is shown in the next image:
![Alt text](./images/2023-04-26%2022_46_37-README.md%20-%20ansible-proxmox-configurator%20%5BWSL_%20Ubuntu%5D%20-%20Visual%20Studio%20Code.png "Title")

Once we have don that, we can proceed to install the binary
```bash
curl -o akeyless https://akeyless-cli.s3.us-east-2.amazonaws.com/cli/latest/production/cli-linux-amd64
```
And execute it and config like this: 
![Alt text](./images/2023-04-26%2022_45_51-README.md%20-%20ansible-proxmox-configurator%20%5BWSL_%20Ubuntu%5D%20-%20Visual%20Studio%20Code.png)


Then we authenticate:
![Alt text](./images/2023-04-26%2022_46_06-README.md%20-%20ansible-proxmox-configurator%20%5BWSL_%20Ubuntu%5D%20-%20Visual%20Studio%20Code.png)

And we can  export now the variable as we have the necessary to do it:
```bash
VAULT_TOKEN=$(akeyless auth --access-id "xxx" --access-type="access_key" --access-key "xxx" --json true | awk '/token/ { gsub(/[",]/,"",$2); print $2}' > ~/.vault-token)
```

Now we should be able to create a token from the cli
![Alt text](./images/2023-04-26%2022_47_55-README.md%20-%20ansible-proxmox-configurator%20%5BWSL_%20Ubuntu%5D%20-%20Visual%20Studio%20Code.png)

It is important that we have to associate our api key to the role we want:
![Alt text](./images/2023-04-26%2022_47_06-.png)
![Alt text](./images/2023-04-26%2022_46_52-README.md%20-%20ansible-proxmox-configurator%20%5BWSL_%20Ubuntu%5D%20-%20Visual%20Studio%20Code.png)

## Description
This repository contains all the playbooks and roles necessary to deploy a Samba file sharing server, a Wireguard VPN server and Plex Server for streaming media. All these 3 services are hosted on independent VM's provisioned in proxmox via terraform all explained [in this repository](https://github.com/AntonioBriPerez/proxmox-terraform). 

## Inventory
To ensure we have access to the machines we set a public SSH key in each one of the VM's we deploy via terraform, as it is explained [in the Terraform repository](https://github.com/AntonioBriPerez/proxmox-terraform). 
## Making the HDD available to the VM
In my proxmox Server I have a 3TB HDD to store everything I need for my Plex Server and to store files via Samba, so to mount make it available without having to modify things in Proxmox on top of the Samba and Plex playbook there is the next configuration: 

``` yaml
  tasks:
    - name: Add disk to the machine
      shell: /sbin/qm set "{{ hostvars['samba']['vm_id'] }}" -virtio2 /dev/disk/by-id/ata-ST3000DM001-1CH166_Z1F4C8RS-part2
      register: shell_output
    - name: Display added HDD to VM in proxmox server
      debug:
        var: shell_output.stdout_lines
```
This fragment takes from input an inventory hosts variable (VM ID) which we can get via proxmox GUI. However, it is better to define an static VM ID when we deploy the VM via proxmox (that is what I have done). It is also important to know the ID of our Hard Drive to execute the right shell command. To know our disk ID's we can execute: 
```bash
ls -l /dev/disk/by-id/
```
There are two roles in this repository: a role for configuring Docker and a role to mount the hard drive. However, it is important to notice that when we use the role to mount the HDD we have to be aware of its name inside the VM. For example in Ubuntu 20.04 (this is our case) it is like that: 

```yaml
  tasks:
    - name: Configure hard drive mount
      include_role:
        name: hard_drive_mount
      vars:
        source_volume: /dev/vdb #In Debian11 most likely it is /dev/vda
        mount_point: /mnt/ocea
```
So we have to pass to the role the appropiate name, otherwise it will not work. 

To deploy the services, I own a repository that contains a docker-compose.yml to deploy each of the services. In the case of the samba service it is a private one due to the fact that the user/password credentials are hard coded inside the docker-compose.yml. The techinique is to clone the repo and with the docker and git Ansible extra modules make it ensuring the repo is cloned, and the container is running: 

```yaml
    - name: Copy ssh private key to remote host to download git repo
      copy:
        src: "{{ ssh_priv_key }}"
        dest: "{{ ssh_priv_key }}"
        mode: "0600" #otherwise ssh key will not work

    - name: Get samba-server repo via SSH
      git:
        repo: "{{ repo_url }}"
        dest: "{{ repo_route }}"
        key_file: "{{ ssh_priv_key }}" #we use our own SSH key to authenticate against github
        accept_hostkey: true # Otherwise the process will hang up waiting for verificate the remote host

    - name: Generate .env file for samba configuration
      copy:
        dest: "{{repo_route + '.env'}}"
        content: |
          ROOT=/mnt/ocean/antonio_hdd_3tb

    - name: "Install pip packages for deploying container"
      pip:
        name:
          - docker
          - PyYAML
        state: present

    - name: Start the container of samba service
      docker_compose:
        project_name: samba-server
        project_src: "{{ repo_route }}"
        files: docker-compose.yml
        state: present

    - name: Remove SSH private key file
      file:
        path: "{{ ssh_priv_key }}" #preventing stealing ssh key so we remove it
        state: absent

```

## Running the playbooks
The playbooks can be run like this: 

```bash
ansible-playbook plex-server.yml -i inventory.ini
ansible-playbook samba-server.yml -i inventory.ini
ansible-playbook wireguard-server.yml -i inventory.ini

```