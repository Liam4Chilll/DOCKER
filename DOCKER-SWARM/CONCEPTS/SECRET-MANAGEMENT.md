# Docker Swarm - Secrets Management

## Le problème des données sensibles

Imaginez que vous devez donner la clé de votre coffre-fort à plusieurs employés, mais vous ne voulez pas qu'ils puissent la copier ou la voir clairement. En plus, si un employé quitte l'entreprise, vous voulez pouvoir révoquer son accès instantanément. C'est exactement le défi que pose la gestion des mots de passe, clés API et certificats dans vos applications Docker.

Traditionnellement, vous avez peut-être mis des mots de passe directement dans vos Dockerfiles ou fichiers de configuration. Cette approche fonctionne en développement, mais devient dangereuse en production : les mots de passe se retrouvent en clair dans vos images, vos logs, et peuvent être visibles par quiconque a accès au conteneur.

## Le coffre-fort intelligent de Swarm

Le système Secrets de Docker Swarm fonctionne comme un coffre-fort ultra-sécurisé avec un majordome intelligent. Vous déposez vos secrets (mots de passe, clés) dans ce coffre-fort centralisé, et le majordome les distribue de manière sécurisée uniquement aux conteneurs qui en ont besoin, au moment où ils en ont besoin.

Le secret n'existe jamais en clair sur le disque dur des nœuds workers. Il voyage chiffré sur le réseau, se déchiffre uniquement en mémoire du conteneur autorisé, et disparaît automatiquement quand le conteneur s'arrête. C'est comme si le majordome murmurait le secret à l'oreille de l'employé, et que ce dernier l'oubliait instantanément en partant.

## Cycle de vie d'un secret

La gestion d'un secret suit un processus en plusieurs étapes qui garantit la sécurité à chaque moment. D'abord, vous créez le secret en le fournissant au manager Swarm. Ce dernier le chiffre immédiatement avec les clés du cluster et le stocke dans la base de données Raft distribuée.

Quand vous attachez ce secret à un service, Swarm ne le distribue qu'aux nœuds qui hébergent réellement des conteneurs de ce service. Sur ces nœuds, le secret reste chiffré jusqu'au moment précis où un conteneur autorisé démarre.

```
Création → Chiffrement → Stockage Raft → Distribution ciblée → Montage temporaire → Suppression automatique
```

Cette chaîne garantit que le secret passe le minimum de temps possible sous forme déchiffrée, et uniquement là où c'est absolument nécessaire.

## Comment les conteneurs accèdent aux secrets

Depuis l'intérieur de votre conteneur, un secret ressemble à un fichier ordinaire monté dans `/run/secrets/`. Cette simplicité cache la complexité sécuritaire : ce "fichier" existe uniquement en mémoire et n'est jamais écrit sur le disque dur.

Votre application lit ce fichier comme n'importe quel autre fichier, sans savoir qu'il s'agit d'un secret géré par Swarm. Cette transparence permet d'adapter facilement des applications existantes sans modifier leur code.

```python
# Dans votre application Python
with open('/run/secrets/db_password', 'r') as f:
    password = f.read().strip()

# Utiliser le mot de passe pour se connecter à la base
connection = database.connect(password=password)
```

## Types de secrets et cas d'usage

### Mots de passe de base de données

Le cas d'usage le plus courant concerne les mots de passe de bases de données. Au lieu de les coder en dur dans vos images ou de les passer via des variables d'environnement visibles, vous les stockez comme secrets et les montez dans vos conteneurs d'application.

### Clés API et tokens

Les clés d'APIs tierces (Stripe, AWS, services de paiement) représentent un autre usage critique. Ces clés changent rarement mais sont extrêmement sensibles. Le système de secrets permet de les centraliser et de contrôler précisément quels services y ont accès.

### Certificats TLS

Les certificats SSL/TLS et leurs clés privées constituent des secrets particulièrement critiques. Swarm peut gérer à la fois le certificat public et la clé privée, en s'assurant que seuls les services web autorisés y ont accès.

| Type de secret | Fréquence de changement | Criticité | Exemple d'usage |
|----------------|------------------------|-----------|-----------------|
| Mot de passe DB | Moyenne | Haute | Connexion PostgreSQL |
| Clé API | Faible | Très haute | Paiement Stripe |
| Certificat TLS | Faible | Haute | HTTPS nginx |
| JWT Secret | Faible | Haute | Signature tokens |

## Rotation et mise à jour des secrets

La rotation des secrets représente un aspect crucial de la sécurité. Contrairement aux variables d'environnement qui nécessitent un redémarrage complet des conteneurs, les secrets peuvent être mis à jour de manière plus élégante.

Swarm permet de créer une nouvelle version d'un secret et de mettre à jour progressivement les services qui l'utilisent. Cette approche minimise les interruptions de service tout en maintenant la sécurité. Vous pouvez même maintenir temporairement deux versions d'un secret pendant la transition.

## Permissions et contrôle d'accès

Chaque secret dans Swarm est associé à des services spécifiques. Un secret ne peut pas "fuiter" vers un service non autorisé, même si ce service tourne sur le même nœud. Cette isolation s'appuie sur les mécanismes de sécurité du kernel Linux et les namespaces.

De plus, seuls les managers Swarm peuvent créer, modifier ou supprimer des secrets. Les nœuds workers ne voient que les secrets dont ils ont absolument besoin pour faire tourner leurs conteneurs assignés. Cette séparation de privilèges limite les risques en cas de compromission d'un nœud worker.

## Différence avec les variables d'environnement

Les variables d'environnement semblent plus simples au premier abord, mais elles posent plusieurs problèmes de sécurité. Elles sont visibles dans la liste des processus, sauvegardées dans l'historique des commandes, et souvent loggées involontairement par les applications.

Les secrets, eux, n'apparaissent jamais dans `docker inspect`, ne sont pas visibles via `ps aux`, et ne risquent pas d'être accidentellement loggués. Cette protection passive évite de nombreuses fuites de données accidentelles.

```bash
# ❌ Visible par tous
docker service create --env DB_PASSWORD=secret123 myapp

# ✅ Sécurisé et invisible
docker service create --secret db_password myapp
```

## Mise en pratique étape par étape

Pour comprendre concrètement le fonctionnement, créons un exemple simple avec une application web et sa base de données. D'abord, nous créons le secret contenant le mot de passe de la base :

```bash
echo "motdepasse_super_secret" | docker secret create db_password -
```

Ensuite, nous déployons notre base de données en utilisant ce secret :

```bash
docker service create \
  --name postgres \
  --secret db_password \
  --env POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
  postgres:13
```

Enfin, notre application web peut aussi utiliser le même secret pour se connecter à la base. Les deux services partagent le secret sans que celui-ci ne soit jamais visible en dehors des conteneurs autorisés.

## Bonnes pratiques et pièges à éviter

### Secrets minimaux

Créez des secrets avec les privilèges minimums nécessaires. Si votre application n'a besoin que d'un accès lecture à une base de données, créez un utilisateur dédié avec ces permissions limitées plutôt que d'utiliser le compte administrateur.

### Rotation régulière

Établissez un calendrier de rotation pour vos secrets critiques. Même si Swarm facilite cette rotation, elle nécessite une planification et des tests réguliers pour s'assurer que vos applications gèrent correctement les changements.

### Éviter les secrets dans les logs

Configurez vos applications pour qu'elles ne loggent jamais le contenu des secrets, même partiellement. Un simple log de debug peut compromettre des mois d'efforts sécuritaires.

## Limitations et alternatives

Le système de secrets de Swarm, bien que robuste, présente certaines limitations. Il ne gère pas nativement la rotation automatique basée sur des politiques temporelles. Pour des besoins plus avancés, vous pourriez avoir besoin d'outils spécialisés comme HashiCorp Vault ou AWS Secrets Manager.

De plus, les secrets Swarm sont liés au cluster. Si vous déployez sur plusieurs environnements (dev, staging, production), vous devez gérer les secrets séparément pour chaque cluster.

## Surveillance et audit

Swarm maintient un audit trail des opérations sur les secrets : création, modification, suppression. Ces logs sont essentiels pour la conformité et le debugging. Vous pouvez les consulter via les événements du cluster :

```bash
docker system events --filter type=secret
```

Cette traçabilité permet de comprendre qui a fait quoi et quand, aspect crucial pour la sécurité en production.

## Conclusion pédagogique

Le système Secrets de Docker Swarm transforme la gestion des données sensibles d'un casse-tête sécuritaire en processus maîtrisé. En comprenant ses mécanismes, vous pouvez construire des applications plus sûres sans sacrifier la simplicité opérationnelle.

La sécurité n'est plus un ajout complexe à votre architecture, mais une fonctionnalité native qui protège automatiquement vos données les plus critiques. Cette approche vous permet de vous concentrer sur votre logique métier tout en respectant les meilleures pratiques sécuritaires.