# Docker Swarm - Rolling Updates

## Le défi de la mise à jour sans interruption

Imaginez que vous dirigez un restaurant très fréquenté et que vous devez changer toute la vaisselle pendant le service. Si vous fermez le restaurant pour faire le changement, vous perdez vos clients. Si vous changez toute la vaisselle d'un coup, vous risquez de casser le service. La solution ? Remplacer la vaisselle table par table, en gardant le restaurant ouvert et les clients servis.

C'est exactement le défi des mises à jour en production. Vos utilisateurs s'attendent à un service disponible 24h/24, mais vous devez régulièrement déployer de nouvelles versions de votre application. Les Rolling Updates résolvent cette équation impossible en permettant des mises à jour progressives sans interruption de service.

## La stratégie du remplacement progressif

Une Rolling Update fonctionne selon un principe simple mais élégant : remplacer progressivement les anciennes instances de votre service par de nouvelles versions, en maintenant toujours un nombre suffisant d'instances actives pour servir le trafic.

Supposons que votre service API ait 6 répliques. Au lieu de les arrêter toutes d'un coup pour les remplacer, Swarm va procéder méthodiquement : arrêter 2 anciennes instances, démarrer 2 nouvelles instances avec la nouvelle version, vérifier qu'elles fonctionnent correctement, puis passer aux 2 suivantes.

```
État initial: [v1.0] [v1.0] [v1.0] [v1.0] [v1.0] [v1.0]
Étape 1:     [v1.0] [v1.0] [v1.0] [v1.0] [v2.0] [v2.0]
Étape 2:     [v1.0] [v1.0] [v2.0] [v2.0] [v2.0] [v2.0]
Étape 3:     [v2.0] [v2.0] [v2.0] [v2.0] [v2.0] [v2.0]
```

À aucun moment le service n'est complètement indisponible, et le load balancer de Swarm dirige automatiquement le trafic vers les instances saines disponibles.

## Configuration des paramètres de mise à jour

La flexibilité des Rolling Updates réside dans leur configurabilité. Vous pouvez ajuster plusieurs paramètres pour adapter la stratégie à vos besoins spécifiques de disponibilité et de prudence.

Le parallélisme détermine combien d'instances sont remplacées simultanément. Avec un parallélisme de 1, Swarm remplace une instance à la fois (plus lent mais plus sûr). Avec un parallélisme de 3, il en remplace 3 simultanément (plus rapide mais potentiellement plus risqué).

```yaml
deploy:
  replicas: 6
  update_config:
    parallelism: 2          # Remplacer 2 instances à la fois
    delay: 30s             # Attendre 30 secondes entre chaque lot
    failure_action: rollback # Que faire en cas d'échec
    monitor: 60s           # Surveiller pendant 60s après remplacement
    max_failure_ratio: 0.3  # Tolérer 30% d'échecs avant rollback
```

Le délai entre les lots permet à votre système de se stabiliser avant de continuer. Si vous remplacez des instances de base de données, vous pourriez vouloir un délai plus long pour permettre la synchronisation. Pour des services web stateless, un délai court suffit généralement.

## Le processus de sanitation et validation

Chaque nouvelle instance ne devient pas immédiatement active dans le load balancer. Swarm attend d'abord qu'elle passe ses health checks et réponde correctement avant de lui envoyer du trafic réel. Cette période de "quarantaine" évite d'exposer les utilisateurs à des instances défaillantes.

Les health checks jouent un rôle crucial dans ce processus. Si votre nouvelle instance ne répond pas aux health checks dans le délai imparti, Swarm la considère comme défaillante et peut déclencher un rollback automatique selon votre configuration.

| Phase | Durée | Action Swarm | État Instance |
|-------|-------|--------------|---------------|
| Démarrage | 0-30s | Création conteneur | En cours |
| Health Check | 30-90s | Vérification santé | Test |
| Intégration | 90-150s | Ajout au load balancer | Active |
| Monitoring | 150-210s | Surveillance continue | Validée |

## Gestion des échecs et rollback automatique

Les Rolling Updates ne sont pas infaillibles, et Swarm intègre plusieurs mécanismes pour gérer les échecs gracieusement. Si une nouvelle instance échoue à démarrer ou ne passe pas ses health checks, Swarm peut soit retenter le déploiement, soit déclencher un rollback automatique.

Le rollback automatique constitue une sécurité essentielle. Si trop d'instances de la nouvelle version échouent (selon le seuil `max_failure_ratio`), Swarm annule automatiquement la mise à jour et restaure la version précédente. Cette protection évite qu'une mauvaise mise à jour compromette complètement votre service.

Vous gardez toujours le contrôle avec la possibilité de déclencher un rollback manuel à tout moment, même si la mise à jour semble réussir mais que vous détectez des problèmes dans les métriques ou les logs.

## Différentes stratégies selon le type de service

Tous les services ne se mettent pas à jour de la même manière. Un service web stateless peut supporter des mises à jour agressives avec un parallélisme élevé, tandis qu'une base de données nécessite une approche beaucoup plus prudente.

### Services web stateless

Pour des services comme des APIs REST ou des serveurs web, vous pouvez être relativement agressif. Un parallélisme de 50% des instances et des délais courts accélèrent le déploiement sans risquer la disponibilité.

### Services avec état (stateful)

Les bases de données, caches, ou services de session nécessitent une approche plus conservatrice. Un parallélisme de 1 instance à la fois avec des délais plus longs permet de vérifier que chaque instance se synchronise correctement avant de passer à la suivante.

### Services critiques

Pour vos services les plus critiques, vous pourriez choisir une stratégie ultra-prudente : parallélisme de 1, délais longs, health checks stricts, et seuils de tolérance aux échecs très bas.

## Health checks et monitoring

Les health checks deviennent votre ligne de défense principale pendant les Rolling Updates. Un health check bien conçu vérifie non seulement que votre application démarre, mais qu'elle fonctionne correctement : connexion à la base de données, accès aux services externes, cohérence des données.

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

Le `start_period` donne du temps à votre application pour se initialiser complètement avant que les health checks ne commencent à compter pour la validation.

## Mise à jour des secrets et configurations

Les Rolling Updates gèrent également les changements de configuration et de secrets. Si vous mettez à jour un secret utilisé par votre service, Swarm peut redéployer automatiquement les instances pour qu'elles utilisent la nouvelle version.

Cette capacité s'avère particulièrement utile pour la rotation des certificats SSL, le changement de mots de passe de base de données, ou la mise à jour de clés API. La mise à jour se fait de manière transparente avec la même stratégie progressive.

## Observabilité pendant les mises à jour

Pendant une Rolling Update, Swarm fournit une visibilité complète sur le processus. Vous pouvez suivre en temps réel quelles instances sont remplacées, lesquelles sont en cours de validation, et l'état global de la mise à jour.

```bash
# Suivre le progrès de la mise à jour
watch docker service ps myapp_api

# Voir les événements de mise à jour
docker service logs myapp_api --follow

# État détaillé du service pendant la mise à jour
docker service inspect myapp_api --pretty
```

Cette observabilité vous permet de détecter rapidement les problèmes et d'intervenir si nécessaire, même pendant que la mise à jour est en cours.

## Stratégies avancées et optimisations

### Canary deployments

Bien que Swarm ne propose pas nativement les déploiements canary, vous pouvez les simuler avec des Rolling Updates très conservatrices : commencez par remplacer une seule instance, surveillez les métriques, et continuez seulement si tout va bien.

### Blue-Green avec Rolling Updates

Vous pouvez combiner Rolling Updates avec une approche blue-green en déployant d'abord sur un sous-ensemble de nœuds, validant le comportement, puis étendant progressivement à l'ensemble du cluster.

### Coordonnation multi-services

Quand votre mise à jour implique plusieurs services interdépendants, orchestrez les Rolling Updates en séquence : mettez d'abord à jour les services de données, puis les APIs, puis les frontends.

## Cas d'échec et récupération

### Rollback d'urgence

Si vous détectez un problème critique pendant ou après une Rolling Update, le rollback d'urgence vous ramène rapidement à la version stable précédente :

```bash
# Rollback immédiat vers la version précédente
docker service rollback myapp_api
```

### Debugging des échecs

Quand une Rolling Update échoue, les logs de Swarm et des instances défaillantes contiennent généralement les informations nécessaires pour comprendre le problème. Les événements du service montrent l'historique des tentatives et leurs résultats.

## Bonnes pratiques et recommandations

### Tests préalables

Testez toujours vos Rolling Updates en environnement de staging avec la même configuration que la production. Les différences de topologie ou de charge peuvent révéler des problèmes invisibles en développement.

### Monitoring renforcé

Renforcez votre monitoring pendant les mises à jour : surveillez les métriques d'erreur, la latence, et les logs d'erreur. Une augmentation anormale de ces métriques peut indiquer des problèmes avec la nouvelle version.

### Communication d'équipe

Coordonnez les Rolling Updates avec votre équipe. Même si elles sont conçues pour être transparentes, il est important que l'équipe soit au courant et puisse surveiller les impacts potentiels.

## Conclusion pédagogique

Les Rolling Updates transforment la mise à jour en production d'un moment de stress en processus maîtrisé et prévisible. En comprenant leurs mécanismes et leurs paramètres, vous pouvez adapter votre stratégie de déploiement aux besoins spécifiques de chaque service.

Cette maîtrise vous rapproche des pratiques DevOps modernes où les déploiements fréquents et sûrs deviennent la norme plutôt que l'exception. Les Rolling Updates ne sont pas seulement un outil technique, mais un catalyseur culturel vers une approche plus agile du développement et des opérations.