# Installation Docker Swarm Visualizer

## Objectif
Déployer Swarm Visualizer pour avoir une interface graphique de monitoring du cluster Docker Swarm.

## Prérequis
- Cluster Swarm opérationnel
- Architecture ARM64
- Accès SSH au manager

## Procédure d'installation

### 1. Connexion au manager
```bash
ssh swarm-manager
```

### 2. Déploiement du service visualizer
```bash
docker service create \
  --name swarm-visualizer \
  --publish 8080:8080 \
  --constraint node.role==manager \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  alexellis2/visualizer-arm:latest
```

### 3. Vérification du déploiement
```bash
docker service ls
docker service ps swarm-visualizer
```

### 4. Test d'accès
- URL : `http://192.168.1.50:8080`

## Alternative Portainer

Si Swarm Visualizer ne fonctionne pas :

```bash
# Supprimer le visualizer
docker service rm swarm-visualizer

# Créer volume Portainer
docker volume create portainer_data

# Déployer Portainer
docker service create \
  --name portainer \
  --publish 9000:9000 \
  --constraint node.role==manager \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  portainer/portainer-ce:latest
```

Accès : `http://192.168.1.50:9000`

## Commandes de gestion

### Suppression
```bash
docker service rm swarm-visualizer
```

### Redémarrage
```bash
docker service update --force swarm-visualizer
```