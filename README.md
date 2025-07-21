![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![ARM64](https://img.shields.io/badge/ARM64-0091BD?style=for-the-badge&logo=arm&logoColor=white)



## Objectif du repository

Ce dépôt documente l'ensemble de mes recherches, expérimentations et configurations Docker dans le contexte de mon homelab. Il centralise les connaissances acquises et les solutions développées pour différents cas d'usage.

### Contenu

- **Configurations Docker Swarm** : Orchestration multi-nœuds
- **Déploiements applicatifs** : Stacks et services
- **Networking** : Réseaux overlay et bridge
- **Persistance** : Gestion des volumes et données
- **Sécurité** : Secrets, certificats et bonnes pratiques
- **Monitoring** : Solutions de supervision et logging
- **Automatisation** : Scripts et CI/CD

### Infrastructure de test

**Cluster Docker Swarm 3 nœuds**  
- Ubuntu 24.04 LTS ARM64
- Réseau 192.168.1.0/24
- 1 Manager + 2 Workers (.50 + .51, .52)

## Utilisation

Les configurations et procédures documentées sont optimisées pour un environnement homelab mais respectent les standards de production. Chaque solution inclut les commandes, fichiers de configuration et notes techniques nécessaires à sa reproduction.
