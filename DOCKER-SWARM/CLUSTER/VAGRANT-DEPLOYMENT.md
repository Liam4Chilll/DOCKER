# Déploiement Cluster Swarm avec Vagrant

## Prérequis
- Vagrant installé
- VirtualBox ou VMware Fusion
- Architecture ARM64 (Apple Silicon)

## Fichiers requis

### Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20240319.0.0"

  # Manager node
  config.vm.define "swarm-manager" do |manager|
    manager.vm.hostname = "swarm-manager"
    manager.vm.network "private_network", ip: "192.168.1.50"
    manager.vm.provider "vmware_fusion" do |v|
      v.memory = 2048
      v.cpus = 2
    end
    manager.vm.provision "shell", path: "install-docker.sh"
    manager.vm.provision "shell", path: "init-swarm.sh"
  end

  # Worker nodes
  (1..2).each do |i|
    config.vm.define "swarm-worker#{i}" do |worker|
      worker.vm.hostname = "swarm-worker#{i}"
      worker.vm.network "private_network", ip: "192.168.1.5#{i}"
      worker.vm.provider "vmware_fusion" do |v|
        v.memory = 1536
        v.cpus = 1
      end
      worker.vm.provision "shell", path: "install-docker.sh"
    end
  end
end
```

### install-docker.sh
```bash
#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Add vagrant user to docker group
usermod -aG docker vagrant

# Enable Docker service
systemctl enable docker
systemctl start docker

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### init-swarm.sh
```bash
#!/bin/bash
set -e

# Initialize Swarm on manager
docker swarm init --advertise-addr 192.168.1.50

# Save join token
docker swarm join-token worker > /vagrant/join-token.txt

echo "Swarm initialized. Join token saved to join-token.txt"
```

### join-workers.sh
```bash
#!/bin/bash
set -e

# Read join command from shared file
JOIN_CMD=$(cat /vagrant/join-token.txt | grep "docker swarm join" | tr -d '\\' | tr -d '\n')

# Execute join command
eval $JOIN_CMD

echo "Worker joined to swarm cluster"
```

## Script de déploiement

### deploy-cluster.sh
```bash
#!/bin/bash
set -e

echo "=== Déploiement du cluster Swarm ==="

# Create project directory
mkdir -p swarm-cluster
cd swarm-cluster

# Create Vagrantfile
cat > Vagrantfile << 'EOF'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20240319.0.0"

  config.vm.define "swarm-manager" do |manager|
    manager.vm.hostname = "swarm-manager"
    manager.vm.network "private_network", ip: "192.168.1.50"
    manager.vm.provider "vmware_fusion" do |v|
      v.memory = 2048
      v.cpus = 2
    end
    manager.vm.provision "shell", path: "install-docker.sh"
    manager.vm.provision "shell", path: "init-swarm.sh"
  end

  (1..2).each do |i|
    config.vm.define "swarm-worker#{i}" do |worker|
      worker.vm.hostname = "swarm-worker#{i}"
      worker.vm.network "private_network", ip: "192.168.1.5#{i}"
      worker.vm.provider "vmware_fusion" do |v|
        v.memory = 1536
        v.cpus = 1
      end
      worker.vm.provision "shell", path: "install-docker.sh"
    end
  end
end
EOF

# Create Docker installation script
cat > install-docker.sh << 'EOF'
#!/bin/bash
set -e
apt-get update -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
systemctl enable docker
systemctl start docker
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
EOF

# Create Swarm initialization script
cat > init-swarm.sh << 'EOF'
#!/bin/bash
set -e
docker swarm init --advertise-addr 192.168.1.50
docker swarm join-token worker > /vagrant/join-token.txt
echo "Swarm initialized"
EOF

# Create worker join script
cat > join-workers.sh << 'EOF'
#!/bin/bash
set -e
JOIN_CMD=$(cat /vagrant/join-token.txt | grep "docker swarm join" | tr -d '\\' | tr -d '\n')
eval $JOIN_CMD
echo "Worker joined"
EOF

chmod +x *.sh

echo "=== Démarrage des VMs ==="
vagrant up

echo "=== Attente initialisation Swarm ==="
sleep 30

echo "=== Ajout des workers ==="
vagrant ssh swarm-worker1 -c "sudo /vagrant/join-workers.sh"
vagrant ssh swarm-worker2 -c "sudo /vagrant/join-workers.sh"

echo "=== Vérification du cluster ==="
vagrant ssh swarm-manager -c "docker node ls"

echo "=== Cluster Swarm déployé avec succès ==="
echo "Manager: 192.168.1.50"
echo "Worker1: 192.168.1.51" 
echo "Worker2: 192.168.1.52"
echo ""
echo "Connexion manager: vagrant ssh swarm-manager"
```

## Utilisation

```bash
# Rendre le script exécutable
chmod +x deploy-cluster.sh

# Déployer le cluster
./deploy-cluster.sh

# Connexion au manager
cd swarm-cluster
vagrant ssh swarm-manager

# Vérifier le cluster
docker node ls
```

## Commandes de gestion

```bash
# Arrêter le cluster
vagrant halt

# Redémarrer le cluster  
vagrant up

# Détruire le cluster
vagrant destroy -f
```