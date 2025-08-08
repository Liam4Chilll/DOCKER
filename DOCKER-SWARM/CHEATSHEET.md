## Surveillance du cluster

### État général
```bash
# État des nœuds
docker node ls

# État des services
docker service ls

# État des stacks
docker stack ls

# Utilisation des ressources
docker system df

# Événements temps réel
docker system events --since 1h


```


**Lancement d'un swarm**

`docker swarm init`

**Si la machine a plusieurs interface réseau :** 

`docker swarm init --advertise-addr < IP de l'interface>`


### Diagnostic d'un nœud
```bash
# Détails d'un nœud
docker node inspect <node-id> --pretty

# Nœuds avec problèmes
docker node ls --filter "availability!=active"

# Nœuds down
docker node ls --filter "status=down"

# Mise en maintenance
docker node update --availability drain <node-id>

# Remise en service
docker node update --availability active <node-id>

# Prendre les informations global d'un noeud**
`docker info | grep -E '(Swarm|Name|Nodes|Cluster|NodeID|Node Address).*'`

# Prendre les informations globales d'un context**
`docker -c contexte-xyz info | '(Swarm|Name|Nodes|Cluster|NodeID|Node Address).*'`
```

## Gestion des services

### Surveillance des services
```bash
# Détails d'un service
docker service inspect <service-name> --pretty

# Tasks d'un service
docker service ps <service-name>

# Tasks en échec
docker service ps <service-name> --filter "desired-state=running"

# Logs d'un service
docker service logs <service-name> --timestamps --tail 100

# Logs en temps réel
docker service logs <service-name> --follow
```

### Scaling des services
```bash
# Augmenter les répliques
docker service scale <service-name>=5

# Scaling multiple
docker service scale web=3 api=5 db=1

# Vérifier le scaling
docker service ps <service-name>
```

### Mise à jour des services
```bash
# Mise à jour image
docker service update --image <new-image> <service-name>

# Mise à jour avec rollback auto
docker service update --image <new-image> --update-failure-action rollback <service-name>

# Rollback manuel
docker service rollback <service-name>

# Forcer redéploiement
docker service update --force <service-name>
```

## Gestion des stacks

### Déploiement
```bash
# Déployer une stack
docker stack deploy -c docker-compose.yml <stack-name>

# Déployer avec variables
docker stack deploy -c docker-compose.yml --with-registry-auth <stack-name>

# Mise à jour stack
docker stack deploy -c docker-compose.yml <stack-name>
```

### Surveillance des stacks
```bash
# Services d'une stack
docker stack services <stack-name>

# Tasks d'une stack
docker stack ps <stack-name>

# Tasks en échec
docker stack ps <stack-name> --filter "desired-state=running"

# Suppression d'une stack
docker stack rm <stack-name>
```

## Résolution de problèmes

### Service qui ne démarre pas
```bash
# 1. Vérifier les constraints
docker service inspect <service-name> | grep -A5 Constraints

# 2. Vérifier les ressources
docker service inspect <service-name> | grep -A10 Resources

# 3. Vérifier les logs
docker service logs <service-name> --tail 50

# 4. Vérifier les tasks
docker service ps <service-name> --no-trunc

# 5. Forcer redéploiement
docker service update --force <service-name>
```

### Problèmes de réseau
```bash
# Lister les réseaux
docker network ls

# Inspecter un réseau
docker network inspect <network-name>
docker network inspect ingress

# Vérifier overlay
docker network ls --filter driver=overlay

# Nettoyer réseaux non utilisés
docker network prune
```

### Problèmes de volumes
```bash
# Lister les volumes
docker volume ls

# Inspecter un volume
docker volume inspect <volume-name>

# Volumes orphelins
docker volume ls --filter dangling=true

# Nettoyer volumes non utilisés
docker volume prune
```

## Maintenance préventive

### Nettoyage système
```bash
# Nettoyage général
docker system prune -f

# Nettoyage avec volumes
docker system prune -af --volumes

# Nettoyage images non utilisées
docker image prune -af

# Nettoyage par nœud
for node in $(docker node ls -q); do
  docker node inspect $node --format '{{.Description.Hostname}}'
  ssh $node "docker system prune -f"
done
```

### Surveillance des ressources
```bash
# Utilisation CPU/RAM par service
docker stats --no-stream

# Utilisation disque
docker system df

# Logs volumineux
docker service ls --format "table {{.Name}}\t{{.Replicas}}" | while read service replicas; do
  echo "=== $service ==="
  docker service logs $service --since 24h 2>&1 | wc -l
done
```

## Sauvegardes

### Backup cluster
```bash
# Backup du store Raft (sur manager)
docker swarm unlock-key > swarm-key.txt
tar -czf swarm-backup-$(date +%Y%m%d).tar.gz /var/lib/docker/swarm

# Backup des configs
docker config ls --format "{{.Name}}" | xargs -I{} docker config inspect {} > configs-backup.json

# Backup des secrets (metadata uniquement)
docker secret ls --format "{{.Name}}" > secrets-list.txt
```

### Restoration d'urgence
```bash
# Forcer nouveau cluster avec backup
docker swarm init --force-new-cluster --advertise-addr <ip>

# Restaurer depuis backup
systemctl stop docker
rm -rf /var/lib/docker/swarm
tar -xzf swarm-backup-<date>.tar.gz -C /
systemctl start docker
```

## Monitoring en production

### Métriques essentielles
```bash
# Services down
docker service ls --filter "mode=replicated" --format "{{.Name}} {{.Replicas}}" | grep "0/"

# Nœuds indisponibles
docker node ls --filter "availability!=active" --format "{{.Hostname}} {{.Status}}"

# Tasks en échec récentes
docker service ls --format "{{.Name}}" | xargs -I{} docker service ps {} --filter "desired-state=running" --format "{{.Node}} {{.CurrentState}}"

# Utilisation réseau
docker network ls --filter driver=overlay --format "{{.Name}}" | xargs -I{} docker network inspect {} --format "{{.Name}}: {{len .Containers}} containers"
```

### Alertes automatisées
```bash
# Script de monitoring (cron toutes les 5 minutes)
#!/bin/bash
# Services down
DOWN_SERVICES=$(docker service ls --filter "mode=replicated" --format "{{.Name}} {{.Replicas}}" | grep "0/" | wc -l)
if [ $DOWN_SERVICES -gt 0 ]; then
  echo "ALERT: $DOWN_SERVICES services down" | mail -s "Docker Swarm Alert" admin@company.com
fi

# Nœuds down
DOWN_NODES=$(docker node ls --filter "status=down" --format "{{.Hostname}}" | wc -l)
if [ $DOWN_NODES -gt 0 ]; then
  echo "ALERT: $DOWN_NODES nodes down" | mail -s "Docker Swarm Alert" admin@company.com
fi
```

## Opérations d'urgence

### Cluster en panne
```bash
# 1. Vérifier le quorum
docker info | grep -i swarm

# 2. Lister managers disponibles
docker node ls --filter "role=manager"

# 3. Forcer nouveau cluster (DANGER)
docker swarm init --force-new-cluster --advertise-addr <manager-ip>

# 4. Réajouter les nœuds
docker swarm join-token worker
docker swarm join-token manager

**Ajouter un worker à un context swarm défini**
`docker -c <context> swarm join-token worker`

**Élever un worker au rang de manager**
`docker node promote swarm-worker1`

```

### Service critique down
```bash
# 1. Diagnostic rapide
docker service ps <service-name> --format "{{.Node}} {{.CurrentState}} {{.Error}}"

# 2. Redémarrage forcé
docker service update --force <service-name>

# 3. Scaling d'urgence
docker service scale <service-name>=0
docker service scale <service-name>=3

# 4. Rollback si nécessaire
docker service rollback <service-name>
```

### Nœud en détresse
```bash
# 1. Évacuation d'urgence
docker node update --availability drain <node-id>

# 2. Attendre évacuation
watch docker node ps <node-id>

# 3. Maintenance du nœud
ssh <node-hostname> "systemctl restart docker"

# 4. Remise en service
docker node update --availability active <node-id>
```

## Sécurité

### Rotation des tokens
```bash
# Rotation token worker
docker swarm join-token --rotate worker

# Rotation token manager
docker swarm join-token --rotate manager

# Rotation clés auto-lock
docker swarm unlock-key --rotate
```

### Audit et logs
```bash
# Audit des actions récentes
docker system events --since 24h --filter type=service

# Logs système Docker
journalctl -u docker.service --since "1 hour ago"

# Connexions récentes
docker system events --filter event=connect --since 1h
```

## Commandes de diagnostic rapide

### One-liners utiles
```bash
# Services avec 0 répliques
docker service ls | awk '$4 ~ /0/ {print $2}'

# Top 5 services par CPU
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k2 -nr | head -5

# Nœuds avec le plus de conteneurs
docker node ls --format "{{.Hostname}}" | xargs -I{} sh -c 'echo -n "{}: "; docker node ps {} --format "{{.Name}}" | wc -l'

# Services par nœud
docker node ls --format "{{.Hostname}}" | xargs -I{} sh -c 'echo "=== {} ==="; docker node ps {} --format "{{.Name}}\t{{.Image}}"'

# Temps de démarrage des services
docker service ls --format "{{.Name}}" | xargs -I{} sh -c 'echo -n "{}: "; docker service ps {} --format "{{.RunningFor}}" | head -1'
```

### Vérifications pré-maintenance
```bash
# Checklist avant maintenance
echo "=== Pré-maintenance ==="
echo "Services actifs: $(docker service ls --format '{{.Name}}' | wc -l)"
echo "Nœuds actifs: $(docker node ls --filter 'availability=active' --format '{{.Hostname}}' | wc -l)"
echo "Tasks en échec: $(docker service ls --format '{{.Name}}' | xargs -I{} docker service ps {} --filter 'desired-state=running' --format '{{.CurrentState}}' | grep -c 'Failed')"
echo "Espace disque: $(docker system df --format '{{.Size}}')"
```

## Variables d'environnement utiles

```bash
# Configuration logging
export DOCKER_LOGGING_DRIVER=json-file
export DOCKER_LOGGING_MAX_SIZE=10m
export DOCKER_LOGGING_MAX_FILE=3

# Timeouts
export DOCKER_CLI_TIMEOUT=30
export DOCKER_DAEMON_TIMEOUT=60

# Format par défaut
export DOCKER_SERVICE_FORMAT="table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"
export DOCKER_NODE_FORMAT="table {{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}"
```

## Contacts et procédures d'escalade

```bash
# Informations cluster
CLUSTER_NAME="production-swarm"
MANAGER_NODES="prod-manager-01,prod-manager-02,prod-manager-03"
MONITORING_URL="https://monitoring.company.com/swarm"

# Procédure d'escalade
# Niveau 1: Redémarrage service
# Niveau 2: Drain/Activate nœud
# Niveau 3: Escalade équipe Dev
# Niveau 4: Escalade CTO
```
