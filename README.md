0. Prereqs
[install-prereqs](./scripts/install-prereqs.sh)

## Filesystem

1. Create a directory for images and containers

```sh
mkdir -p ~/ship/{images,containers}
```

2. Get some rootfs image

Alternate 1. Copy from host machine

[host-fs](./scripts/host-fs.sh)

Alternate 2. Get an OCI Bundle

```sh
docker pull alpine
CID=$(docker run -d alpine true)
docker export $CID > alpine.tar
mkdir -p ~/ship/images/alpine
tar -xf alpine.tar -C ~/ship/images/alpine
```

### Overlay2 Storage Driver (Union File System)
[Ref](https://docs.docker.com/storage/storagedriver/overlayfs-driver/#how-the-overlay2-driver-works)

Docker actually uses overlay file-systems for containers at `/var/lib/docker/overlay2/`.
We can watch changes on docker's FS when we modify files on containers

```sh
sudo apt install inotify-tools
sudo inotifywait -m -r -e modify,create,delete,move /var/lib/docker/overlay2/

# Another terminal
docker pull hello-world
docker inspect --format='{{json .GraphDriver.Data}}' hello-world | jq
sudo tree -a /var/lib/docker/overlay2/ -I 'merged'
```

### You can also create a new overlayFS on the fly

Create overlay using [my-overlay](./scripts/my-overlay.sh)

```sh
sudo find . -type f -printf "\n%p\n" -exec cat {} \;

pushd /home/vagrant/ship/overlay/
# Create a new file in merged
echo "_new_" > /home/vagrant/ship/overlay/merged/new.txt
ls -l /home/vagrant/ship/overlay/{lower,merged,upper}

# Delete a common file in merged
rm /home/vagrant/ship/overlay/merged/in_both.txt
ls -l /home/vagrant/ship/overlay/{lower,merged,upper}

sudo umount /home/vagrant/ship/overlay/merged
popd
```

[Docker Storage Drivers](https://docs.docker.com/storage/storagedriver/)
[Docker Storage Driver Types](https://docs.docker.com/storage/storagedriver/select-storage-driver/)

### Create a Container from the Image

```sh
mkdir -p ~/ship/containers
cp -r ~/ship/images/alpine ~/ship/containers/bottle
touch ~/ship/containers/bottle/made_of_glass
```

### Chroot

Chroot restricts the filesystem view of a process to some subdirectory.

```sh
sudo chroot ~/ship/containers/bottle /bin/sh

# In the container
env # Inherited from the host

ps
mount -t proc proc /proc # Mount namespace is shared
ps
ip a # Network namespace is shared
pkill top # PID namespace is shared
exit

# Alternatively, We can mount the host's procfs during chroot
sudo chroot ~/ship/containers/bottle /bin/sh --mount-proc

# Only difference is /etc/mtab keeps track of the mount.
sudo umount ~/ship/containers/bottle/proc
```

### Namespaces

```sh
sudo unshare --mount --uts --ipc --net --pid --fork bash

# In the container
pstree
mount -t proc proc /proc
pstree
ip a

chroot /home/vagrant/ship/containers/bottle sh
mount -t proc proc /proc
```

### Network


#### Naming the network namespace of a process

[Ref](https://unix.stackexchange.com/a/645834/222748)

```sh
sudo ip netns add dummy && sudo ip netns delete dummy
sudo touch /run/netns/bottle
sudo chmod 0 /run/netns/bottle
sudo mount --bind /proc/$(pgrep unshare)/ns/net /run/netns/bottle
```

#### Setting up the network connection

```sh
BRIDGE_IP="172.17.0.1"
CON_IP="172.17.0.100"
BRIDGE_NAME="docker0"
PREFIX_LEN="/24"

# Let's check the network configuration of a container created using docker
docker run -d --name moby alpine sleep 100000
docker exec -it moby sh
cat /etc/resolv.conf

# Let's create a veth pair
sudo ip link add c-bottle type veth peer name h-bottle

sudo ip link set c-bottle netns bottle

sudo ip link set h-bottle master ${BRIDGE_NAME}

sudo ip netns exec bottle ip link set lo up
sudo ip netns exec bottle ip link set c-bottle up
sudo ip link set h-bottle up

sudo ip netns exec bottle ip addr add ${CON_IP}${PREFIX_LEN} dev c-bottle
sudo ip netns exec bottle ip route add default via ${BRIDGE_IP}


# Get the DNS information from the host
systemd-resolve --status | grep "DNS Server"

# replace 192.168.1.1 with the DNS server from the output above. 
echo 'nameserver 192.168.1.1' > /etc/resolv.conf # In the container

# Alternatively, copy the DNS configuration from a docker container (/etc/resolv.conf) to our container

```