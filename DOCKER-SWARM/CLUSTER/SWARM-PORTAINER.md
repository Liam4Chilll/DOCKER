
# déploiement et usage de portainer en environnement swarm

## 1. objectif

portainer fournit une interface web d’administration docker et swarm. il facilite la gestion visuelle des services, stacks, volumes, secrets et tâches au sein d’un cluster swarm.

---

## 2. commande de déploiement recommandée

```bash
docker service create \
  --name portainer \
  --publish 9000:9000 \
  --constraint 'node.role==manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  portainer/portainer-ce:2.19.5
```

### explications

- `--name portainer` : nom logique du service
- `--publish 9000:9000` : expose le port 9000 via le routing mesh swarm
- `--constraint 'node.role==manager'` : limite le déploiement aux nœuds managers
- `--mount type=bind...` : accès au socket docker de l’hôte (permet à portainer de piloter le cluster)
- `--mount type=volume...` : stockage persistant de l’état de portainer
- `portainer/portainer-ce:2.19.5` : version figée pour éviter les mises à jour implicites

---

## 3. accès à portainer

- url : `http://<ip_nœud_manager>:9000`
- création d’un compte administrateur au premier accès
- attention : ne pas exposer ce port sans authentification et tls en production

---

## 4. fonctionnalités principales

- créer, modifier ou supprimer des services swarm
- visualiser les tâches et logs en temps réel
- gérer les volumes, configs et secrets
- déployer des stacks via des fichiers yaml (compose format v3)
- consulter les métriques des containers

---

## 5. bonne pratiques

- toujours limiter le service aux nœuds managers (accès à docker.sock)
- éviter le tag `latest` en production
- sauvegarder le volume `portainer_data` avant re-déploiement
- supprimer manuellement le volume si réinitialisation souhaitée :
```bash
docker volume rm portainer_data
```

---

## 6. cas d’usage de l’agent portainer (facultatif)

- utilisé pour connecter portainer à des environnements distants
- nécessaire si portainer est déployé hors du cluster cible
- fonctionne en mode multi-nœuds avec communication tls sécurisée

---

## 7. différence entre service et stack

- un **service** est un déploiement unitaire, impératif
- une **stack** est un ensemble déclaratif de services, réseaux, volumes, configuré via yaml
- portainer privilégie les stacks pour les déploiements reproductibles
