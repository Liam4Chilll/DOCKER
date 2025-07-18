# Docker Swarm Overlay

## Définition et principe

Un réseau overlay est un réseau logique de couche 2 (liaison de données) construit au-dessus d'un réseau physique de couche 3 (réseau IP). Dans Docker Swarm, il utilise **VXLAN (Virtual eXtensible LAN)** pour créer des tunnels chiffrés entre les nœuds du cluster.

## Architecture technique

```
┌─────────────────────────────────────────────────────────────────┐
│                    Réseau Physique 192.168.1.0/24               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ Node 1      │    │ Node 2      │    │ Node 3      │         │
│  │ .50         │    │ .51         │    │ .52         │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ VXLAN Tunneling
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Réseau Overlay 10.0.0.0/24                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ Container A │    │ Container B │    │ Container C │         │
│  │ 10.0.0.3    │    │ 10.0.0.4    │    │ 10.0.0.5    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Mécanisme VXLAN

### 1. Processus d'encapsulation

1. **Encapsulation Layer 2** : Le paquet Ethernet original est encapsulé dans un header VXLAN
2. **Tunneling UDP** : Le paquet est ensuite encapsulé dans UDP (port 4789)
3. **Routage IP** : Transport via le réseau underlay (192.168.1.0/24)
4. **Décapsulation** : Le nœud destinataire extrait le paquet Layer 2 original

### 2. Structure du paquet VXLAN

```
┌─────────────────────────────────────────────────────────────────┐
│ Outer Ethernet | Outer IP | UDP | VXLAN | Inner Ethernet | Data │
│ Header         | Header   |     | Header| Header         |      │
└─────────────────────────────────────────────────────────────────┘
```

### 3. Headers VXLAN

```
VXLAN Header (8 octets)
┌─────────────────────────────────────────────────────────────────┐
│ Flags | Reserved | VNI (24 bits) | Reserved                     │
│ (8)   | (24)     | Network ID    | (8)                          │
└─────────────────────────────────────────────────────────────────┘
```

## Implémentation pratique

### Création de réseaux overlay

```bash
# Réseau overlay basique
docker network create --driver overlay production-net

# Réseau overlay avec chiffrement
docker network create --driver overlay --opt encrypted secure-net

# Réseau overlay avec sous-réseau personnalisé
docker network create \
  --driver overlay \
  --subnet 10.10.0.0/24 \
  --gateway 10.10.0.1 \
  custom-net

# Réseau overlay attachable (non recommandé en production)
docker network create --driver overlay --attachable dev-net
```

### Inspection et diagnostic

```bash
# Lister les réseaux overlay
docker network ls --filter driver=overlay

# Inspecter un réseau overlay
docker network inspect production-net

# Vérifier les interfaces VXLAN sur les nœuds
ip link show type vxlan

# Afficher les tunnels VXLAN
bridge fdb show dev vxlan0

# Vérifier les tables de routage overlay
docker exec -it <container> ip route show
```

## Configuration réseau Swarm

### Réseaux par défaut

```bash
# Ingress network (routing mesh)
docker network inspect ingress

# Bridge network (communication nœud-conteneur)
docker network inspect docker_gwbridge
```

### Exemple de configuration service

```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    networks:
      - frontend-net
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker

  backend:
    image: api:latest
    networks:
      - frontend-net
      - backend-net
    deploy:
      replicas: 3

  database:
    image: postgres:13
    networks:
      - backend-net
    deploy:
      placement:
        constraints:
          - node.labels.type == database

networks:
  frontend-net:
    driver: overlay
  backend-net:
    driver: overlay
    driver_opts:
      encrypted: "true"
```

## Sécurité et chiffrement

### Chiffrement IPSec

```bash
# Créer un réseau overlay chiffré
docker network create --driver overlay --opt encrypted secure-overlay

# Vérifier le chiffrement
docker network inspect secure-overlay | grep -i encrypt
```

### Isolation réseau

```bash
# Réseau isolé (pas d'accès externe)
docker network create \
  --driver overlay \
  --internal \
  isolated-net

# Réseau avec contrôle d'accès
docker network create \
  --driver overlay \
  --opt com.docker.network.bridge.enable_icc=false \
  restricted-net
```

## Performance et optimisation

### Métriques de performance

```bash
# Tester la latence overlay
docker run --rm --network production-net alpine ping -c 5 <target-container>

# Mesurer le throughput
docker run --rm --network production-net \
  nicolaka/netshoot iperf3 -c <target-ip>

# Analyser l'overhead VXLAN
tcpdump -i eth0 -n port 4789
```

### Optimisations MTU

```bash
# Vérifier la MTU
docker network inspect production-net | grep -i mtu

# Configurer MTU personnalisée
docker network create \
  --driver overlay \
  --opt com.docker.network.driver.mtu=1450 \
  optimized-net
```

## Troubleshooting

### Problèmes courants

#### 1. Fragmentation MTU

```bash
# Diagnostic
ping -M do -s 1472 <target-ip>

# Solution
docker network create \
  --driver overlay \
  --opt com.docker.network.driver.mtu=1450 \
  fixed-net
```

#### 2. Connectivité inter-nœuds

```bash
# Vérifier les ports VXLAN
netstat -tulpn | grep 4789

# Tester la connectivité underlay
ping 192.168.1.51

# Vérifier les règles iptables
iptables -L -n | grep 4789
```

#### 3. DNS Resolution

```bash
# Tester la résolution DNS
docker exec -it <container> nslookup <service-name>

# Vérifier la configuration DNS
docker network inspect production-net | grep -A5 "Config"
```

### Commandes de debug

```bash
# Logs réseau Docker
journalctl -u docker.service | grep -i network

# État des interfaces overlay
ip addr show

# Tables de forwarding VXLAN
bridge fdb show

# Statistiques réseau conteneurs
docker exec -it <container> cat /proc/net/dev
```

## Limitations et considérations

### Limitations techniques

1. **Overhead** : ~50 octets par paquet (headers VXLAN/UDP/IP)
2. **Performance** : Latence additionnelle due à l'encapsulation
3. **MTU** : Fragmentation possible si MTU mal configurée
4. **Debugging** : Complexité accrue pour le troubleshooting réseau

### Bonnes pratiques

1. **Segmentation** : Utiliser des réseaux séparés par couche applicative
2. **Chiffrement** : Activer pour les données sensibles
3. **Monitoring** : Surveiller les métriques réseau
4. **MTU** : Configurer correctement pour éviter la fragmentation
5. **Firewall** : Ouvrir uniquement les ports nécessaires (4789/UDP)

## Comparaison avec alternatives

### Vs Host Network

```bash
# Host network (pas d'isolation)
docker service create --network host nginx

# Overlay network (isolation complète)
docker service create --network production-net nginx
```

### Vs Bridge Network

```bash
# Bridge (single-host)
docker network create --driver bridge local-net

# Overlay (multi-host)
docker network create --driver overlay cluster-net
```

## Exemples avancés

### Multi-Tier application

```bash
# Créer les réseaux
docker network create --driver overlay --opt encrypted frontend-tier
docker network create --driver overlay --opt encrypted backend-tier
docker network create --driver overlay --opt encrypted data-tier

# Déployer les services
docker service create \
  --name web \
  --network frontend-tier \
  --publish 80:80 \
  nginx:alpine

docker service create \
  --name api \
  --network frontend-tier \
  --network backend-tier \
  app:latest

docker service create \
  --name db \
  --network backend-tier \
  --network data-tier \
  postgres:13
```

### Monitoring et alerting

```bash
# Service de monitoring réseau
docker service create \
  --name netmon \
  --network production-net \
  --constraint node.role==manager \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  nicolaka/netshoot sleep 3600

# Tester depuis le conteneur de monitoring
docker exec -it netmon.1.<task-id> ss -tulpn
```