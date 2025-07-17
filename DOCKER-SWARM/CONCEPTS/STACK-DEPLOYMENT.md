# Docker Swarm - Stack Deployment

## De la complexité à la simplicité

Imaginez que vous dirigez un orchestre avec des dizaines de musiciens. Plutôt que de donner des instructions individuelles à chaque musicien ("violon, joue cette note", "piano, commence maintenant"), vous utilisez une partition globale que tout le monde peut lire simultanément. C'est exactement ce que fait le Stack Deployment : il remplace des dizaines de commandes `docker service create` par un seul fichier de configuration élégant.

Quand vous avez découvert Docker Compose pour vos environnements de développement, vous avez probablement apprécié la simplicité de décrire toute votre application dans un fichier YAML. Les stacks étendent cette philosophie aux clusters Swarm, en ajoutant les capacités de production comme la haute disponibilité, la mise à l'échelle et l'orchestration distribuée.

## L'évolution naturelle de Compose

Un Stack n'est pas un concept entièrement nouveau : c'est Docker Compose enrichi pour la production. Votre fichier `docker-compose.yml` de développement peut souvent devenir un stack Swarm avec quelques ajustements. Cette continuité facilite grandement la transition entre développement local et déploiement en cluster.

La différence fondamentale réside dans la section `deploy` qui n'existe que dans les stacks. Cette section contient toutes les informations spécifiques à Swarm : nombre de répliques, contraintes de placement, politiques de mise à jour. Votre configuration de développement reste intacte, vous ajoutez simplement les aspects production.

```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:  # Cette section n'existe que pour les stacks
      replicas: 3
      placement:
        constraints:
          - node.role == worker
```

## Anatomie d'un stack complet

Un stack réel ressemble à une recette de cuisine détaillée qui décrit non seulement les ingrédients (services) mais aussi comment les préparer ensemble (réseaux, volumes, secrets). Prenons l'exemple d'une application web classique avec frontend, API et base de données.

Chaque service de votre stack peut avoir ses propres spécifications : image à utiliser, ports à exposer, volumes à monter, secrets à injecter. Le gestionnaire de stack orchestre automatiquement le déploiement de tous ces éléments dans l'ordre approprié et avec les bonnes dépendances.

```yaml
version: '3.8'
services:
  frontend:
    image: myapp/frontend:latest
    ports:
      - "80:80"
    networks:
      - frontend-net
    deploy:
      replicas: 2
      
  api:
    image: myapp/api:latest
    networks:
      - frontend-net
      - backend-net
    secrets:
      - db_password
    deploy:
      replicas: 3
      
  database:
    image: postgres:13
    networks:
      - backend-net
    volumes:
      - db_data:/var/lib/postgresql/data
    secrets:
      - db_password
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.storage == ssd

networks:
  frontend-net:
    driver: overlay
  backend-net:
    driver: overlay

volumes:
  db_data:
    driver: local

secrets:
  db_password:
    external: true
```

## Déploiement et gestion du cycle de vie

Le déploiement d'un stack se fait avec une seule commande, mais derrière cette simplicité se cache une orchestration complexe. Swarm analyse votre fichier YAML, crée tous les objets nécessaires (réseaux, volumes, secrets), puis déploie les services dans l'ordre optimal.

Cette approche déclarative signifie que vous décrivez l'état final souhaité plutôt que les étapes pour y arriver. Si votre stack doit avoir 3 répliques de l'API, Swarm s'assure qu'il y en a toujours 3, peu importe les pannes ou les redémarrages.

La mise à jour d'un stack suit la même philosophie : vous modifiez votre fichier YAML et redéployez. Swarm compare automatiquement l'état actuel avec la nouvelle configuration et n'applique que les changements nécessaires.

## Versioning et rollback

Une fonctionnalité puissante des stacks concerne la gestion des versions. Chaque déploiement crée une nouvelle version de votre stack, et Swarm conserve l'historique des changements. Cette traçabilité permet des rollbacks rapides en cas de problème.

Imaginez que votre nouvelle version de l'API contient un bug critique. Au lieu de paniquer et chercher frénétiquement la version précédente, vous pouvez simplement revenir à l'état stable précédent avec une commande simple.

| Version | Date | Changements | Statut |
|---------|------|-------------|--------|
| v1.0 | 2024-01-15 | Déploiement initial | Stable |
| v1.1 | 2024-01-20 | Ajout monitoring | Stable |
| v1.2 | 2024-01-25 | Nouvelle API | Rollback |
| v1.1 | 2024-01-25 | Retour version stable | Actuel |

## Gestion des dépendances

Dans une application multi-services, l'ordre de démarrage des services peut être critique. Votre API ne peut pas démarrer avant que la base de données ne soit prête, et votre frontend ne sert à rien sans l'API. Les stacks gèrent automatiquement ces dépendances.

Bien que les stacks ne proposent pas de `depends_on` fonctionnel comme Docker Compose, ils offrent des mécanismes plus robustes pour la production. Les health checks et les politiques de redémarrage permettent aux services de gérer leurs dépendances de manière résiliente.

Votre API peut être configurée pour retenter sa connexion à la base de données jusqu'à ce que celle-ci soit disponible. Cette approche, plus robuste qu'une simple dépendance au démarrage, gère aussi les cas où la base de données redémarre pendant que l'API fonctionne.

## Environnements multiples

Un avantage majeur des stacks réside dans leur capacité à gérer plusieurs environnements avec le même fichier de base. Vous pouvez avoir un fichier `docker-stack.yml` commun et des fichiers d'override spécifiques à chaque environnement.

```bash
# Environnement de développement
docker stack deploy -c docker-stack.yml -c docker-stack.dev.yml myapp-dev

# Environnement de production  
docker stack deploy -c docker-stack.yml -c docker-stack.prod.yml myapp-prod
```

Cette approche maintient la cohérence entre environnements tout en permettant des configurations spécifiques (nombre de répliques, ressources allouées, secrets différents).

## Monitoring et observabilité

Les stacks offrent une visibilité excellente sur l'état de votre application complète. Une seule commande vous montre l'état de tous vos services, leurs répliques, et leur santé globale.

```bash
# Vue d'ensemble du stack
docker stack services myapp

# Détails de tous les conteneurs
docker stack ps myapp

# Logs agrégés de tous les services
docker service logs myapp_api
```

Cette vue unifiée simplifie grandement le debugging et le monitoring. Plutôt que de jongler entre plusieurs commandes pour différents services, vous avez une perspective holistique de votre application.

## Stratégies de mise à jour

Les stacks supportent plusieurs stratégies de mise à jour selon vos besoins de disponibilité. La mise à jour rolling (par défaut) remplace progressivement les anciennes instances par les nouvelles, maintenant le service disponible pendant tout le processus.

Pour des applications critiques, vous pouvez configurer des mises à jour très conservatrices qui remplacent une instance à la fois avec des pauses entre chaque remplacement. Pour des applications moins critiques, vous pouvez accélérer le processus en remplaçant plusieurs instances simultanément.

```yaml
deploy:
  update_config:
    parallelism: 1        # Une instance à la fois
    delay: 30s           # Attendre 30s entre chaque
    failure_action: rollback  # Rollback automatique si échec
    monitor: 60s         # Surveiller 60s après chaque mise à jour
```

## Intégration avec l'écosystème

Les stacks s'intègrent naturellement avec tous les autres concepts Swarm. Ils utilisent les mêmes réseaux overlay, partagent les mêmes secrets, et bénéficient du même service discovery. Cette cohérence évite les surprises et facilite l'apprentissage.

Un stack peut utiliser des réseaux créés en dehors de lui, partager des volumes avec d'autres stacks, ou utiliser des secrets globaux du cluster. Cette flexibilité permet des architectures complexes tout en gardant chaque stack focalisé sur sa responsabilité.

## Cas d'usage avancés

### Applications modulaires

Pour des applications très complexes, vous pouvez diviser votre architecture en plusieurs stacks spécialisés : un stack pour les services frontend, un autre pour les APIs, un troisième pour les données. Cette séparation facilite la maintenance et permet des cycles de déploiement indépendants.

### Blue-Green deployment

Bien que Swarm ne propose pas nativement le blue-green deployment, vous pouvez l'implémenter avec des stacks multiples et un load balancer externe. Déployez votre nouvelle version sur un stack parallèle, testez-la, puis basculez le trafic.

## Debugging et troubleshooting

Quand un stack ne se déploie pas correctement, Swarm fournit des informations détaillées sur chaque étape du processus. Les événements du cluster, les logs des services, et l'état des tâches vous donnent une vision complète pour identifier et résoudre les problèmes.

La commande `docker stack ps` avec l'option `--no-trunc` révèle souvent les messages d'erreur complets qui expliquent pourquoi un service ne démarre pas ou redémarre en boucle.

## Conclusion pédagogique

Les stacks représentent l'aboutissement naturel de votre apprentissage Docker. Ils combinent la simplicité de Compose avec la robustesse de Swarm, créant un outil puissant pour déployer et gérer des applications complexes en production.

Maîtriser les stacks vous donne la capacité de penser vos applications comme des ensembles cohérents plutôt que comme des collections de conteneurs isolés. Cette perspective change fondamentalement votre approche de l'architecture et de l'opérationnel, vous rapprochant des pratiques DevOps modernes.