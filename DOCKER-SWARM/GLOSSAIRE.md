# Glossaire Technique

## Acronymes et Technologies

**API** : Application Programming Interface - Interface de programmation permettant la communication entre applications.

**BGP** : Border Gateway Protocol - Protocole de routage utilisé pour échanger des informations de routage entre systèmes autonomes.

**Bridge** : Pont réseau de couche 2 qui connecte des segments de réseau.

**CIDR** : Classless Inter-Domain Routing - Méthode d'allocation d'adresses IP et de routage.

**CLI** : Command Line Interface - Interface en ligne de commande.

**CNI** : Container Network Interface - Spécification pour configurer les interfaces réseau dans les conteneurs Linux.

**CPU** : Central Processing Unit - Processeur central de l'ordinateur.

**DCA** : Docker Certified Associate - Certification Docker officielle.

**DNS** : Domain Name System - Système de noms de domaine traduisant les noms en adresses IP.

**FDB** : Forwarding Database - Base de données de transfert utilisée par les bridges pour mémoriser les adresses MAC.

**ICMP** : Internet Control Message Protocol - Protocole de messages de contrôle Internet (utilisé par ping).

**IPSec** : Internet Protocol Security - Suite de protocoles sécurisés pour l'authentification et le chiffrement IP.

**IPVS** : IP Virtual Server - Technologie de load balancing au niveau du noyau Linux.

**JSON** : JavaScript Object Notation - Format d'échange de données léger.

**LAN** : Local Area Network - Réseau local.

**MAC** : Media Access Control - Adresse physique unique d'une interface réseau.

**MTU** : Maximum Transmission Unit - Taille maximale d'un paquet de données transmis en une fois.

**OSI** : Open Systems Interconnection - Modèle de référence réseau en 7 couches.

**RAFT** : Algorithme de consensus distribué utilisé par Docker Swarm pour maintenir la cohérence du cluster.

**SSH** : Secure Shell - Protocole de communication sécurisé pour l'accès distant.

**TCP** : Transmission Control Protocol - Protocole de transport fiable avec contrôle de flux.

**TLS** : Transport Layer Security - Protocole de sécurisation des communications.

**UDP** : User Datagram Protocol - Protocole de transport sans connexion et sans garantie.

**VNI** : VXLAN Network Identifier - Identifiant unique d'un réseau VXLAN (24 bits).

**VXLAN** : Virtual eXtensible LAN - Protocole d'encapsulation pour créer des réseaux overlay.

**YAML** : YAML Ain't Markup Language - Format de sérisation de données lisible par l'homme.

## Termes Docker et Swarm

**Attachable** : Propriété d'un réseau overlay permettant aux conteneurs standalone de s'y connecter.

**Constraint** : Contrainte de placement définissant où un service peut être déployé dans le cluster.

**Driver** : Module logiciel gérant un type spécifique de ressource (réseau, volume, etc.).

**Engine** : Démon Docker responsable de la gestion des conteneurs sur un nœud.

**Gateway** : Passerelle réseau, point d'entrée/sortie d'un sous-réseau.

**Ingress** : Réseau overlay par défaut gérant le routing mesh pour les ports publiés.

**Internal** : Réseau sans accès externe, isolé d'Internet.

**Leader** : Nœud manager actif qui prend les décisions dans un cluster Swarm.

**Manager** : Nœud Swarm responsable de la gestion du cluster et de l'orchestration.

**Network** : Réseau virtuel permettant la communication entre conteneurs.

**Node** : Machine physique ou virtuelle membre d'un cluster Swarm.

**Overlay** : Type de réseau virtuel multi-hôtes utilisant l'encapsulation VXLAN.

**Placement** : Mécanisme déterminant sur quels nœuds déployer les tâches d'un service.

**Quorum** : Nombre minimum de managers requis pour maintenir le consensus du cluster.

**Replica** : Instance d'un service, copie identique déployée sur le cluster.

**Routing Mesh** : Mécanisme de load balancing automatique des requêtes entrantes.

**Service** : Définition déclarative d'une application avec son état désiré.

**Stack** : Ensemble de services déployés ensemble via Docker Compose.

**Subnet** : Sous-réseau, segment d'adresses IP dans un réseau plus large.

**Swarm** : Mode cluster de Docker permettant l'orchestration multi-nœuds.

**Task** : Instance individuelle d'un service, unité d'exécution atomique.

**Underlay** : Réseau physique sous-jacent sur lequel s'appuie le réseau overlay.

**Worker** : Nœud Swarm exécutant uniquement des tâches, sans rôle de gestion.

## Termes Réseau Avancés

**Encapsulation** : Processus d'inclusion d'un paquet dans un autre paquet avec headers additionnels.

**Forwarding** : Action de transférer un paquet d'une interface à une autre.

**Fragmentation** : Division d'un paquet IP trop large en plusieurs fragments plus petits.

**Header** : En-tête d'un paquet contenant les informations de contrôle.

**Latency** : Délai de transmission d'un paquet entre source et destination.

**Load Balancing** : Répartition du trafic entre plusieurs serveurs backend.

**Overhead** : Surcharge en termes de taille, processeur ou bande passante.

**Packet** : Unité de données formatée transmise sur un réseau.

**Port** : Numéro identifiant un service ou processus sur un hôte réseau.

**Protocol** : Ensemble de règles définissant la communication entre systèmes.

**Segmentation** : Division d'un réseau en sous-réseaux plus petits.

**Throughput** : Débit de données transmises avec succès sur un lien réseau.

**Tunnel** : Connexion point-à-point encapsulant un protocole dans un autre.

**VLAN** : Virtual LAN - Réseau local virtuel segmentant le trafic au niveau switch.

## Valeurs Critiques à Mémoriser

**Port VXLAN** : 4789/UDP

**Overhead VXLAN** : ~50 octets par paquet

**MTU Recommandée** : 1450 octets

**VNI** : 24 bits (16 777 216 réseaux maximum)

**Quorum Manager** : N/2 + 1 (minimum 3 managers pour HA)

**Ports Docker Swarm** :
- 2377/TCP : Cluster management
- 7946/TCP+UDP : Communication entre nœuds  
- 4789/UDP : Trafic réseau overlay

**Algorithmes de Placement** :
- Spread : Distribution équilibrée
- Binpack : Optimisation des ressources
- Random : Placement aléatoire
