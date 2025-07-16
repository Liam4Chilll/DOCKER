# Docker Swarm - Guide de configuration de mon lab (évolutif)

## Architecture

**3 VMs Ubuntu 24.04 LTS Server ARM64**
- **swarm-manager** : 192.168.1.50 (Manager/Leader)
- **swarm-worker1** : 192.168.1.51 (Worker)
- **swarm-worker2** : 192.168.1.52 (Worker)

## Phase 1 : Préparation des VMs

### 1.1 Installation Ubuntu Server

**Objectif** : Créer 3 VMs identiques avec Ubuntu Server minimal

```bash
# Configuration réseau pour chaque VM
IP: 192.168.1.50/51/52
Gateway: 192.168.1.1
DNS: 8.8.8.8, 1.1.1.1
Utilisateur: docker-admin
```

**Pourquoi** : Le réseau en bridge permet aux VMs de communiquer directement entre elles et avec votre macOS.

### 1.2 Configuration réseau fixe (sur chaque VM)

Vous pouvez utilisez mon script de fixation d'IP pour allez plus vite et passer directement à l'étape 2

[SCRIPT BASH/change-ip.sh](https://github.com/Liam4Chilll/SysAdmin/blob/main/SCRIPT%20BASH/change-ip.sh)

**Vérification interface réseau**
```bash
ip addr show
```
*Identifie le nom de l'interface (généralement enp0s1 ou ens160)*

**Configuration IP fixe avec Netplan**
```bash
sudo vim /etc/netplan/01-netcfg.yaml
```

**Sur swarm-manager (192.168.1.50)**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:  # Adapter selon votre interface
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

**Sur swarm-worker1 (192.168.1.51)**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:
      dhcp4: false
      addresses:
        - 192.168.1.51/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

**Sur swarm-worker2 (192.168.1.52)**
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:
      dhcp4: false
      addresses:
        - 192.168.1.52/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

**Application de la configuration**
```bash
sudo netplan apply
```
*Active immédiatement la nouvelle configuration réseau*

**Vérification**
```bash
ip addr show
ping 8.8.8.8
```
*Confirme l'IP fixe et la connectivité internet*

**Pourquoi des IPs fixes ?** : Swarm nécessite des adresses stables pour la communication cluster et la découverte des nœuds.

### 1.3 Configuration post-installation (sur chaque VM)

**Mise à jour système**
```bash
sudo apt update && sudo apt upgrade -y
```
*Met à jour les paquets pour la sécurité et la compatibilité*

**Installation des outils essentiels**
```bash
sudo apt install -y curl wget git htop tree net-tools vim jq
```
*Outils pour le téléchargement, monitoring et debug réseau*

**Configuration hostname (sur chaque VM)**
```bash
# Sur swarm-manager
sudo hostnamectl set-hostname swarm-manager

# Sur swarm-worker1  
sudo hostnamectl set-hostname swarm-worker1

# Sur swarm-worker2
sudo hostnamectl set-hostname swarm-worker2
```
*Identifie clairement chaque nœud dans le cluster*

**Redémarrage pour activer hostname**
```bash
sudo reboot
```
*Applique définitivement le nouveau hostname*

**Fichier hosts pour résolution locale (sur chaque VM)**
```bash
sudo vim /etc/hosts
# Ajouter ces lignes après les lignes existantes :
192.168.1.50    swarm-manager
192.168.1.51    swarm-worker1
192.168.1.52    swarm-worker2
```
*Permet la communication par nom plutôt que par IP*

**Test de connectivité inter-nœuds**
```bash
# Depuis chaque VM, tester :
ping swarm-manager
ping swarm-worker1
ping swarm-worker2
```
*Vérifie la résolution DNS locale entre les nœuds*

## Phase 2 : Installation Docker

**Téléchargement et installation**
```bash
sudo apt install docker.ce
```

**Ajout de l'utilisateur au groupe Docker**

```$bash
sudo usermod -aG docker $USER
```

*Permet d'exécuter Docker sans sudo*

**Redémarrage session**
```bash
# Sortir et se reconnecter ou :
newgrp docker
```
*Active l'appartenance au groupe docker*

### 3 Création du cluster sur le manager

```bash
ssh swarm-manager
docker swarm init --advertise-addr 192.168.1.50
```

**Ce qui se passe** :
- Docker Engine passe en mode Swarm
- Le nœud devient Manager/Leader
- Génération des certificats TLS
- Création du store Raft pour le consensus
- Affichage du token de jointure

**Pourquoi `--advertise-addr`** : Spécifie l'IP que les autres nœuds utiliseront pour communiquer

### 3.1 Récupération du token worker

```bash
docker swarm join-token worker
```
*Affiche la commande complète pour joindre un worker*

### 3.2 Ajout des workers au cluster

**Sur worker1**
```bash
ssh swarm-worker1
docker swarm join --token SWMTKN-1-xxx... 192.168.1.50:2377
```

**Sur worker2**
```bash
ssh swarm-worker2  
docker swarm join --token SWMTKN-1-xxx... 192.168.1.50:2377
```

**Ce qui se passe** :
- Les workers se connectent au manager via le port 2377
- Authentification mutuelle avec les certificats TLS
- Enregistrement des nœuds dans le cluster

### 3.3 Vérification du cluster

```bash
ssh swarm-manager
docker node ls
```

**Résultat attendu** :
```
ID              HOSTNAME        STATUS    AVAILABILITY   MANAGER STATUS
abc123... *     swarm-manager   Ready     Active         Leader
def456...       swarm-worker1   Ready     Active         
ghi789...       swarm-worker2   Ready     Active         
```

## Phase 4 : Premiers tests pratiques

### 4.1 Test de service simple

**Création d'un service**
```bash
ssh swarm-manager
docker service create --name nginx-test --replicas 2 --publish 8080:80 nginx:alpine
```

**Explication** :
- `--name` : Nom du service
- `--replicas 2` : 2 instances (tasks)
- `--publish 8080:80` : Port externe:interne
- Le scheduler distribue automatiquement les tasks

**Vérification**
```bash
docker service ls
docker service ps nginx-test
```
*Montre la répartition des tasks sur les nœuds*

### 4.2 Test du load balancing

**Depuis macOS**
```bash
curl http://192.168.1.50:8080
curl http://192.168.1.51:8080  
curl http://192.168.1.52:8080
```

**Pourquoi ça marche** : Le routing mesh de Swarm redirige le trafic vers les bonnes tasks, quel que soit le nœud contacté.

### 4.3 Test du scaling

```bash
ssh swarm-manager
docker service scale nginx-test=4
docker service ps nginx-test
```
*Augmente à 4 replicas, Swarm distribue automatiquement*

### 4.4 Nettoyage

```bash
docker service rm nginx-test
```

## Phase 5 : Compréhension des réseaux overlay

### 5.1 Création d'un réseau overlay

```bash
ssh swarm-manager
docker network create --driver overlay --attachable app-network
```

**Pourquoi `--attachable`** : Permet aux conteneurs standalone de se connecter au réseau

### 5.2 Test de communication inter-services

**Création de services sur le réseau**
```bash
docker service create --name web --network app-network --replicas 2 nginx:alpine
docker service create --name api --network app-network --replicas 2 httpd:alpine
```

**Test de résolution DNS**
```bash
# Depuis un conteneur web vers api
docker exec -it $(docker ps -q --filter label=com.docker.swarm.service.name=web) ping api
```
*Les services se découvrent automatiquement par leur nom*

## Phase 6 : Gestion depuis macOS (optionnel)

### 6.1 Création d'aliases pratiques

```bash
echo 'alias swarm-status="ssh swarm-manager docker node ls"' >> ~/.zshrc
echo 'alias swarm-services="ssh swarm-manager docker service ls"' >> ~/.zshrc
echo 'alias swarm-manager="ssh swarm-manager"' >> ~/.zshrc

source ~/.zshrc
```

### 6.2 Test des aliases

```bash
swarm-status
swarm-services
```

### Gestion avancée des services

**Ajout de labels aux nœuds**
```bash
ssh swarm-manager
docker node update --label-add environment=production swarm-worker1
docker node update --label-add environment=staging swarm-worker2
docker node update --label-add type=frontend swarm-worker1
docker node update --label-add type=backend swarm-worker2
```
*Les labels permettent un placement intelligent des services*

## Points clés à retenir

**Architecture Swarm** :
- Manager : Prend les décisions, expose l'API
- Workers : Exécutent les tasks
- Services : Définition déclarative des applications
- Tasks : Instances individuelles des services

**Réseau** :
- Port 2377 : Communication management
- Port 7946 : Communication entre nœuds  
- Port 4789 : Réseau overlay (VXLAN)

**Sécurité par défaut** :
- TLS mutuel automatique
- Rotation des certificats
- Chiffrement du trafic management
