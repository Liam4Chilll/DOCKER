# Docker Swarm - Service Discovery

## Le défi de la communication entre services

Imaginez que vous gérez une grande entreprise avec plusieurs départements. Chaque département déménage régulièrement dans de nouveaux bureaux, change de numéros de téléphone, et parfois certains départements ferment temporairement. Comment les autres départements peuvent-ils toujours joindre celui dont ils ont besoin ?

C'est exactement le problème que rencontrent vos conteneurs dans un cluster Swarm. Contrairement à votre environnement Docker traditionnel où vous connaissez les adresses IP fixes, dans Swarm les conteneurs apparaissent et disparaissent constamment, changent d'adresses IP, et se répartissent sur différents nœuds. Le Service Discovery résout ce casse-tête de communication.

## L'annuaire téléphonique automatique

Le Service Discovery fonctionne comme un annuaire téléphonique intelligent qui se met à jour automatiquement. Quand vous créez un service nommé "api", Swarm enregistre immédiatement ce nom dans son annuaire interne. Tous les autres services du cluster peuvent alors contacter "api" par son nom, sans jamais connaître son adresse IP réelle.

C'est la différence fondamentale avec Docker standalone où vous deviez gérer manuellement les liens entre conteneurs ou utiliser des adresses IP. Avec Swarm, vous pensez en termes de noms de services, pas d'adresses techniques.

## Comment fonctionne la résolution de noms

Quand un conteneur veut contacter un autre service, il fait appel au serveur DNS intégré de Swarm. Ce serveur spécial connaît tous les services du cluster et leurs emplacements actuels. Voici ce qui se passe étape par étape :

Un conteneur de votre service "frontend" veut appeler votre service "api". Il demande au DNS "où se trouve api ?". Le DNS de Swarm consulte son registre interne et répond avec l'adresse IP virtuelle (VIP) du service "api". Cette VIP ne change jamais, même si les conteneurs du service bougent.

```
frontend → DNS Swarm : "Où est api ?"
DNS Swarm → frontend : "api est à l'adresse 10.0.0.3"
frontend → 10.0.0.3 : "Bonjour api !"
```

La beauté de ce système est que "10.0.0.3" reste constant même si les conteneurs de "api" redémarrent ou se déplacent sur d'autres nœuds.

## Les adresses IP virtuelles (VIP)

Les VIP constituent le cœur du Service Discovery. Quand vous créez un service, Swarm lui attribue automatiquement une adresse IP virtuelle unique qui sert de "façade" permanente. Derrière cette façade, plusieurs conteneurs peuvent répondre au trafic.

Cette approche résout le problème classique des adresses IP qui changent. Même si vos 3 répliques de "api" tournent sur des nœuds différents avec des adresses IP différentes, elles partagent toutes la même VIP. Vos autres services n'ont qu'une seule adresse à retenir.

## Portée et isolation des noms

Un aspect crucial à comprendre est que les noms de services ne sont visibles que dans le même réseau. Si vous créez un réseau overlay appelé "frontend-network", seuls les services connectés à ce réseau peuvent se voir mutuellement.

Cette isolation est comparable aux départements d'une entreprise : le département comptabilité peut avoir son propre annuaire interne, différent de celui du département technique. Dans Swarm, chaque réseau overlay maintient son propre espace de noms DNS.

| Réseau | Services visibles | Communication possible |
|--------|------------------|----------------------|
| frontend-net | web, nginx | web ↔ nginx |
| backend-net | api, database | api ↔ database |
| app-net | web, api | web ↔ api |

## Découverte automatique des tâches

Au-delà des noms de services, Swarm propose aussi la découverte des tâches individuelles. Chaque réplique de votre service reçoit un nom unique qui combine le nom du service et le slot de la tâche.

Si votre service "api" a 3 répliques, vous pouvez les contacter individuellement :
- api.1.unique-id pour la première réplique
- api.2.unique-id pour la deuxième réplique  
- api.3.unique-id pour la troisième réplique

Cette granularité permet des patterns avancés comme le routage vers des instances spécifiques pour le debugging ou la maintenance.

## Intégration avec les réseaux overlay

Le Service Discovery ne fonctionne que sur les réseaux overlay, pas sur les réseaux bridge classiques. Cette limitation n'est pas un bug mais une caractéristique : les réseaux overlay sont conçus pour la communication multi-hôtes, exactement ce dont vous avez besoin dans un cluster.

Quand vous attachez un service à un réseau overlay, Swarm configure automatiquement tous les éléments DNS nécessaires. Vous n'avez rien à configurer manuellement, tout se fait de manière transparente.

## Cas d'usage pratiques

### Application web classique

Considérons une application avec un frontend, une API et une base de données. Avec le Service Discovery, votre code frontend peut simplement faire des appels HTTP vers "http://api:3000" sans jamais connaître l'adresse IP réelle de l'API.

```javascript
// Dans votre frontend
fetch('http://api:3000/users')
  .then(response => response.json())
```

Cette simplicité révolutionne la façon dont vous architecturez vos applications distribuées.

### Microservices communicants

Dans une architecture microservices, chaque service doit pouvoir communiquer avec plusieurs autres. Le Service Discovery élimine la complexité de la gestion des adresses IP et permet à vos services de se concentrer sur leur logique métier.

Un service "order" peut appeler "payment", "inventory" et "notification" par leurs noms, sans configuration supplémentaire. Si vous ajoutez des répliques ou redéployez un service, la communication continue de fonctionner transparemment.

## Les limitations à connaître

### Résolution externe

Le Service Discovery de Swarm ne résout que les noms internes au cluster. Si votre application doit contacter des services externes (APIs tierces, bases de données hébergées), vous devez utiliser les DNS classiques ou des solutions complémentaires.

### Cache DNS

Les résolutions DNS sont mises en cache par les conteneurs, ce qui peut créer de légers délais lors des changements de topologie. Si un service redémarre, il peut falloir quelques secondes avant que tous les autres services voient le changement.

### Nomenclature

Les noms de services doivent respecter les conventions DNS standard : pas d'espaces, pas de caractères spéciaux, uniquement des lettres, chiffres et tirets. Un nom comme "my_api_service" ne fonctionnera pas, mais "my-api-service" fonctionne parfaitement.

## Observer le Service Discovery en action

Vous pouvez explorer le fonctionnement du Service Discovery avec quelques commandes simples :

```bash
# Créer un réseau overlay
docker network create --driver overlay mon-reseau

# Déployer deux services sur ce réseau
docker service create --name api --network mon-reseau nginx
docker service create --name frontend --network mon-reseau alpine sleep 3600

# Tester la résolution depuis un conteneur
docker exec -it <container-frontend> nslookup api
```

Cette expérience vous montre concrètement comment un conteneur peut résoudre le nom d'un autre service.

## Dépannage courant

### Service non trouvé

Si un service ne peut pas en contacter un autre par son nom, vérifiez d'abord qu'ils sont sur le même réseau overlay. C'est l'erreur la plus fréquente : deux services sur des réseaux différents ne peuvent pas se voir.

### Résolution lente

Une résolution DNS anormalement lente indique souvent des problèmes de connectivité réseau entre les nœuds. Le Service Discovery s'appuie sur la communication inter-nœuds pour fonctionner efficacement.

## Conclusion pédagogique

Le Service Discovery transforme la complexité de la communication inter-services en simplicité. Au lieu de jongler avec des adresses IP qui changent, vous travaillez avec des noms stables et significatifs. Cette abstraction vous permet de concevoir des architectures distribuées robustes sans vous préoccuper de l'infrastructure sous-jacente.

Maîtriser le Service Discovery ouvre la porte aux architectures microservices modernes et facilite grandement la maintenance de vos applications distribuées. C'est un outil qui grandit avec vos besoins : simple pour commencer, puissant pour les cas d'usage avancés.