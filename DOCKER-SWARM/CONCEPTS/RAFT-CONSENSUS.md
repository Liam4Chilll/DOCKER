# Docker Swarm - Raft Consensus Algorithm

## Comprendre le problème à résoudre

Imaginez que vous dirigez une équipe de trois personnes et que vous devez prendre des décisions importantes. Si chacun peut décider de son côté, vous risquez d'avoir des actions contradictoires qui créent le chaos. C'est exactement le défi que rencontre Docker Swarm avec plusieurs managers.

Quand vous avez plusieurs nœuds managers dans votre cluster, ils doivent tous être d'accord sur l'état du cluster : quels services tournent, sur quels nœuds, avec combien de répliques. Sans coordination, un manager pourrait décider de créer un service pendant qu'un autre le supprime. Le résultat serait imprévisible et potentiellement catastrophique.

## L'analogie du conseil d'administration

Pensez à Raft comme à un conseil d'administration très organisé. Dans ce conseil, une seule personne peut être président à la fois (le leader), et tous les autres sont des membres votants (les followers). Le président prend toutes les décisions importantes et les communique aux autres membres, qui doivent les approuver.

Si le président devient indisponible, les membres organisent rapidement une nouvelle élection pour choisir un remplaçant. Cette organisation garantit qu'il y a toujours quelqu'un aux commandes, même en cas de problème.

## Comment fonctionne l'élection du leader

Au démarrage de votre cluster Swarm, tous les managers commencent comme des "candidats" qui veulent devenir leader. Ils s'envoient des messages pour dire "votez pour moi !". Le premier qui obtient la majorité des votes devient le leader et commence à diriger le cluster.

Cette élection se base sur des "termes", comme des mandats politiques. Chaque élection incrémente le numéro de terme. Si le leader actuel tombe en panne, les followers détectent son absence et lancent une nouvelle élection avec un terme supérieur.

```
Terme 1: Manager-A devient leader
Terme 2: Manager-A tombe en panne, Manager-B devient leader
Terme 3: Manager-B tombe en panne, Manager-C devient leader
```

## Le journal des décisions (Log Replication)

Le leader tient un journal détaillé de toutes ses décisions, comme un livre de bord. Chaque fois qu'il fait quelque chose (créer un service, modifier une configuration), il l'écrit dans ce journal avec un numéro d'ordre.

Ensuite, il envoie ces entrées aux autres managers qui doivent les copier dans leur propre journal, dans le même ordre. C'est comme si le président du conseil envoyait le compte-rendu de chaque décision aux autres membres, qui doivent tous l'enregistrer identiquement.

Une décision n'est définitivement validée que quand la majorité des managers l'ont enregistrée. Cette règle garantit que même si certains managers tombent en panne, la décision sera préservée.

## La règle magique du quorum

Le quorum est un concept fondamental que vous devez absolument comprendre. C'est le nombre minimum de managers qui doivent être d'accord pour que le cluster continue à fonctionner. La formule est simple : (nombre total de managers / 2) + 1.

| Managers totaux | Quorum nécessaire | Pannes tolérées |
|----------------|-------------------|-----------------|
| 1 | 1 | 0 |
| 3 | 2 | 1 |
| 5 | 3 | 2 |
| 7 | 4 | 3 |

Avec 3 managers, vous pouvez perdre 1 manager et continuer à fonctionner. Avec 5 managers, vous pouvez en perdre 2. Cette progression explique pourquoi on recommande toujours un nombre impair de managers.

## Ce qui se passe quand ça se complique

### Partition réseau (Split-brain)

Imaginez que votre réseau se coupe en deux, séparant vos 3 managers en deux groupes : 2 d'un côté et 1 de l'autre. Seul le groupe qui a le quorum (les 2 managers) peut continuer à prendre des décisions. L'autre manager isolé passe en mode "lecture seule" et attend que le réseau soit réparé.

Cette protection évite le "split-brain", un scénario cauchemardesque où deux parties du cluster prendraient des décisions contradictoires simultanément.

### Récupération après panne

Quand un manager redémarre après une panne, il ne connaît plus l'état actuel du cluster. Il demande alors au leader actuel de lui envoyer toutes les entrées manquantes de son journal. C'est comme un étudiant qui rattrape les cours qu'il a manqués.

Le manager récupère progressivement son retard en appliquant toutes les décisions dans l'ordre, jusqu'à être parfaitement synchronisé avec les autres.

## Implications pratiques pour votre cluster

### Pourquoi pas plus de managers ?

Vous pourriez penser que plus de managers = plus de sécurité, mais c'est faux. Chaque manager supplémentaire ralentit le processus de décision car plus de nœuds doivent se synchroniser. Au-delà de 7 managers, les performances se dégradent notablement.

Pour la plupart des cas d'usage, 3 managers suffisent amplement et offrent un excellent compromis entre haute disponibilité et performance.

### L'importance de la latence réseau

Raft est sensible à la latence réseau car les managers doivent constamment communiquer. Si vos managers sont répartis sur plusieurs continents, les élections seront lentes et les performances dégradées. Il vaut mieux garder les managers géographiquement proches.

### Observer Raft en action

Vous pouvez voir Raft travailler avec quelques commandes simples :

```bash
# Voir qui est le leader actuel
docker node ls

# Identifier le leader (celui avec le *)
docker node inspect <node-id> --format '{{ .ManagerStatus.Leader }}'
```

Quand vous déployez un service, le leader prend la décision et la propage aux autres managers. Si vous surveillez les logs, vous pouvez voir ces communications en temps réel.

## Les erreurs courantes à éviter

### Nombre pair de managers

Déployer 2 ou 4 managers est une erreur classique. Avec 2 managers, la perte d'un seul paralyse complètement le cluster car il n'y a plus de quorum. Avec 4 managers, vous avez la même tolérance aux pannes qu'avec 3, mais des performances dégradées.

### Managers sur une seule machine

Placer plusieurs managers sur la même machine physique annule complètement les bénéfices de la haute disponibilité. Si cette machine tombe en panne, vous perdez plusieurs managers d'un coup.

## Conclusion pédagogique

Raft résout un problème complexe avec une solution élégante : élire un leader unique, maintenir un journal ordonné des décisions, et exiger l'accord de la majorité pour valider les changements. Cette simplicité conceptuelle cache une robustesse remarquable qui permet à Docker Swarm de maintenir la cohérence même dans des conditions difficiles.

Comprendre Raft vous aide à mieux dimensionner vos clusters et à anticiper leur comportement lors de pannes. C'est la différence entre subir les événements et les maîtriser.