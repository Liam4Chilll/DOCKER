# Docker Swarm - Routing Mesh expliqué

## Concept fondamental

Le **Routing Mesh** est le mécanisme de Docker Swarm qui rend un service accessible sur tous les nœuds du cluster, même si les conteneurs ne tournent que sur certains nœuds.
C'est un mécanisme fondamental de Swarm qui permet une distribution transparente du trafic sans configuration supplémentaire.

## Pourquoi le Visualizer est accessible sur 3 URLs ?

### Situation concrète
```bash
# Le visualizer tourne UNIQUEMENT sur le manager
docker service ps swarm-visualizer
# Résultat : 1 task sur swarm-manager seulement

# Mais accessible depuis tous les nœuds
curl http://192.168.1.50:8080  # Manager (conteneur réel)
curl http://192.168.1.51:8080  # Worker1 (redirection)
curl http://192.168.1.52:8080  # Worker2 (redirection)
```

### Mécanisme de redirection
```
Client → 192.168.1.51:8080 (worker1)
         ↓
    Routing Mesh (IPVS)
         ↓
192.168.1.50:8080 (manager - conteneur réel)
```

## Architecture du Routing Mesh

### 1. Ingress Network
- Réseau overlay automatique créé par Swarm
- Connecte tous les nœuds du cluster
- Gère la distribution du trafic entrant

### 2. IPVS (IP Virtual Server)
- Load balancer intégré au noyau Linux
- Redirige automatiquement le trafic vers les bonnes tasks
- Invisible pour l'utilisateur final

### 3. Publication de port
```bash
--publish 8080:8080
```
**Signification :** "Rendre le port 8080 accessible sur TOUS les nœuds du cluster"

## Vérification technique

### Voir les règles IPVS
```bash
# Depuis n'importe quel nœud
sudo ipvsadm -L -n
# Montre les règles de load balancing actives
```

### Inspection du réseau ingress
```bash
# Lister les réseaux
docker network ls | grep ingress

# Inspecter le réseau ingress
docker network inspect ingress
```

### Tester la redirection
```bash
# Ces 3 requêtes arrivent au MÊME conteneur
curl -I http://192.168.1.50:8080  # Direct
curl -I http://192.168.1.51:8080  # Redirigé vers manager
curl -I http://192.168.1.52:8080  # Redirigé vers manager

# Toutes retournent la même réponse
```

## Exemple avec load balancing réel

### Service avec plusieurs répliques
```bash
# Créer un service nginx avec 3 répliques
docker service create \
  --name nginx-demo \
  --replicas 3 \
  --publish 80:80 \
  nginx

# Vérifier la répartition
docker service ps nginx-demo
```

### Résultat attendu
```
ID      NAME          NODE            DESIRED STATE   CURRENT STATE
abc123  nginx-demo.1  swarm-manager   Running         Running
def456  nginx-demo.2  swarm-worker1   Running         Running  
ghi789  nginx-demo.3  swarm-worker2   Running         Running
```

### Load balancing en action
```bash
# Requêtes vers n'importe quel nœud
curl http://192.168.1.50/  # Peut aller vers n'importe quel conteneur
curl http://192.168.1.51/  # Peut aller vers n'importe quel conteneur
curl http://192.168.1.52/  # Peut aller vers n'importe quel conteneur

# Le routing mesh distribue automatiquement
```

## Cas particuliers

### Services avec contraintes
```bash
# Service contraint sur un seul nœud
docker service create \
  --name app-backend \
  --constraint node.role==manager \
  --publish 3000:3000 \
  myapp:latest

# Accessible sur tous les nœuds mais tourne sur 1 seul
```

### Services sans publication de port
```bash
# Service interne (pas de --publish)
docker service create \
  --name internal-db \
  postgres:13

# Accessible UNIQUEMENT via réseau overlay
# PAS accessible depuis l'extérieur
```

## Avantages du Routing Mesh

### 1. Simplicité d'accès
- Un seul point d'entrée par service
- Pas besoin de connaître l'emplacement exact des conteneurs
- Load balancing automatique

### 2. Haute disponibilité
- Si un nœud tombe, les autres restent accessibles
- Redistribution automatique du trafic
- Pas de point de défaillance unique

### 3. Évolutivité transparente
- Ajout/suppression de répliques sans impact
- Scaling automatique du load balancing
- Pas de reconfiguration manuelle

## Limitations à connaître

### 1. Load balancing basique
- Round-robin simple
- Pas de session affinity (sticky sessions)
- Pas de health checks avancés

### 2. Performance
- Overhead du routage réseau
- Latence supplémentaire sur les redirections
- Impact sur les applications haute performance

### 3. Debugging complexe
- Masque la localisation réelle des conteneurs
- Logs distribués sur plusieurs nœuds
- Traçabilité des requêtes compliquée

## Points clés

1. **Port published = accessible partout** dans le cluster
2. **Routing mesh ≠ load balancer externe** (c'est intégré)
3. **1 service peut avoir N répliques** réparties sur N nœuds
4. **IPVS gère la redirection** au niveau noyau
5. **Ingress network** est créé automatiquement par Swarm

## Commandes de diagnostic

### Vérifier le routing mesh
```bash
# État des services
docker service ls

# Répartition des tasks
docker service ps <service-name>

# Règles IPVS
sudo ipvsadm -L -n

# Réseau ingress
docker network inspect ingress
```

### Tester la connectivité
```bash
# Depuis chaque nœud
for ip in 192.168.1.50 192.168.1.51 192.168.1.52; do
  echo "Test depuis $ip:"
  curl -s http://$ip:8080 | head -5
done
```

