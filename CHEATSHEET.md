### EXECUTION

1. **Créer et démarrer un container interactif**:
   ```
   docker run -it --name my_interactive_container ubuntu /bin/bash
   ```
   - `-it` : Mode interactif avec allocation d'un tty (terminal).
   - `--name` : Nomme le container pour une référence facile.
   - `ubuntu` : Image Docker à utiliser.
   - `/bin/bash` : Commande pour démarrer un shell bash dans le container.

2. **Exécuter une commande dans un container interactif existant**:
   ```
   docker exec -it my_interactive_container /bin/bash
   ```
   - Permet de se connecter à un shell dans un container déjà en cours d'exécution.

3. **Démarrer un container interactif avec un volume monté**:
   ```
   docker run -it -v /host/path:/container/path --name my_container_with_volume ubuntu /bin/bash
   ```
   - `-v /host/path:/container/path` : Monte un volume du système hôte dans le container pour un accès persistant aux données.

4. **Démarrer un container interactif avec une variable d'environnement**:
   ```
   docker run -it -e MY_VAR=my_value --name my_env_container ubuntu /bin/bash
   ```
   - `-e MY_VAR=my_value` : Définit une variable d'environnement `MY_VAR` dans le container.

5. **Démarrer un container interactif dans un réseau spécifique**:
   ```
   docker run -it --network=my_network --name my_network_container ubuntu /bin/bash
   ```
   - `--network=my_network` : Connecte le container à un réseau Docker existant pour faciliter la communication entre containers.

6. **Démarrer un container interactif en exposant des ports**:
   ```
   docker run -it -p 8080:80 --name my_port_container ubuntu /bin/bash
   ```
   - `-p 8080:80` : Mappe le port 80 du container au port 8080 de l'hôte, permettant l'accès externe au service.

7. **Démarrer un container interactif avec une limite de ressources**:
   ```
   docker run -it --cpus=".5" --memory="256m" --name my_resource_limited_container ubuntu /bin/bash
   ```
   - `--cpus=".5"` et `--memory="256m"` : Limite les ressources CPU et mémoire du container.

8. **Attacher à un container interactif déjà en cours**:
   ```
   docker attach my_interactive_container
   ```
   - Permet de se reconnecter à la session interactive d'un container déjà en cours.

9. **Démarrer un container interactif avec un utilisateur spécifique**:
   ```
   docker run -it --user=1000 --name my_user_container ubuntu /bin/bash
   ```
   - `--user=1000` : Démarre le container en utilisant l'ID utilisateur spécifié, utile pour des raisons de sécurité et de permissions.

10. **Démarrer un container interactif en mode détaché puis y attacher une session interactive**:
   ```
   docker run -d --name my_detached_container ubuntu
   docker exec -it my_detached_container /bin/bash
   ```
   - Commence par démarrer le container en mode détaché (`-d`), puis utilise `docker exec` pour attacher une session interactive. Cela est utile pour ajouter l'interactivité à des containers initialement démarrés en arrière-plan.
   

### Containers

1. **Exécuter en limitant les ressources**:
   - `docker run --cpus=".5" --memory="1g" nginx`: Lance un container Nginx limité à 0.5 CPU et 1GB de mémoire.

2. **Définir une politique de redémarrage**:
   - `docker run --restart=on-failure:5 nginx`: Redémarre le container si le processus sort avec un code d'erreur, jusqu'à 5 tentatives.

3. **Exécuter avec un réseau spécifique**:
   - `docker run --network=my-network nginx`: Lance un container dans le réseau `my-network`.

4. **Publier des ports**:
   - `docker run -p 80:80 nginx`: Mappe le port 80 du container au port 80 de l'hôte.

5. **Montage de volume**:
   - `docker run -v /host/path:/container/path nginx`: Monte un volume du système hôte dans le container.

6. **Executer une commande dans un container actif**:
   - `docker exec -it my-container bash`: Exécute une session bash dans un container en cours.

7. **Copier des fichiers vers/depuis un container**:
   - `docker cp my-container:/path/in/container /host/path`: Copie des fichiers du container vers l'hôte.

8. **Afficher les logs d'un container**:
   - `docker logs -f my-container`: Affiche et suit les logs d'un container.

9. **Inspecter un container**:
   - `docker inspect my-container`: Affiche des informations détaillées sur un container en format JSON.

10. **Lister les ports exposés par un container**:
    - `docker port my-container`: Liste tous les ports exposés et leurs mappings.

### Images

11. **Construire une image**:
    - `docker build -t my-image .`: Construit une image Docker à partir d'un Dockerfile dans le répertoire courant.

12. **Lister les images**:
    - `docker images`: Affiche toutes les images locales.

13. **Supprimer une image**:
    - `docker rmi my-image`: Supprime une image spécifique.

14. **Taguer une image**:
    - `docker tag my-image my-repo/my-image:tag`: Taguer une image pour le push dans un registre.

15. **Push une image dans un registre**:
    - `docker push my-repo/my-image:tag`: Pousse une image vers un registre Docker.

16. **Sauvegarder une image dans un fichier**:
    - `docker save my-image > my-image.tar`: Sauvegarde l'image dans un fichier tar.

17. **Charger une image depuis un fichier**:
    - `docker load < my-image.tar`: Charge une image depuis un fichier tar.

### Réseaux

18. **Créer un réseau**:
    - `docker network create my-network`: Crée un réseau personnalisé.

19. **Lister les réseaux**:
    - `docker network ls`: Liste tous les réseaux Docker.

20. **Inspecter un réseau**:
    - `docker network inspect my-network`: Affiche des informations détaillées sur un réseau.

21. **Connecter un container à un réseau**:
    - `docker network connect my-network my-container`: Connecte un container existant à un réseau.

22. **Déconnecter un container d'un réseau**:
    - `docker network disconnect my-network my-container`: Déconnecte un container d'un réseau.

### Volumes

23. **Créer un volume**:
    - `docker volume create my-volume`: Crée un volume pour la persistance des données.

24. **Lister les volumes**:
    - `docker volume ls`: Affiche tous les volumes Docker.

25. **Inspecter un volume**:
    - `docker volume inspect my-volume`: Affiche des informations détaillées sur un volume.

26. **Supprimer un volume**:
    - `docker volume rm my-volume`: Supprime un volume spécifique.

### Sécurité et Monitoring

27. **Scanner une image pour des vulnérabilités**:
    - `docker scan my-image`: Analyse une image Docker à la recherche de vulnérabilités.

28. **Afficher l'utilisation des ressources par les containers**:
    - `docker stats`: Affiche l'utilisation des ressources en temps réel par les containers.

29. **Configurer les logs d'un container**:
    - `docker run --log-driver=syslog --log-opt syslog-address=udp://1.2.3.4 nginx`: Lance un container avec la configuration des logs personnalisée.

30. **Utiliser Docker en mode Swarm pour la gestion d'orchestration**:
    - `docker swarm init`: Initialise un cluster Docker Swarm.

31. **Déployer un service dans Docker Swarm**:
    - `docker service create --name my-service --replicas 3 nginx`: Déploie un service avec 3 répliques.

32. **Mettre à l'échelle un service dans Docker Swarm**:
    - `docker service scale my-service=5`: Ajuste le nombre de répliques d'un service à 5.

33. **Inspecter un service dans Docker Swarm**:
    - `docker service inspect my-service`: Affiche des informations détaillées sur un service.

34. **Lister les tâches d'un service dans Docker Swarm**:
    - `docker service ps my-service`: Liste les tâches (containers) d'un service.

35. **Retirer un service dans Docker Swarm**:
    - `docker service rm my-service`: Supprime un service.

36. **Configurer des secrets Docker**:
    - `echo "secret" | docker secret create my-secret -`: Crée un secret dans Docker.

37. **Assigner un secret à un service**:
    - `docker service create --name my-service --secret my-secret nginx`: Lance un service qui utilise un secret.

38. **Utiliser des configs pour gérer la configuration**:
    - `echo "config" | docker config create my-config -`: Crée une configuration dans Docker.

39. **Assigner une config à un service**:
    - `docker service create --name my-service --config my-config nginx`: Lance un service qui utilise une configuration.

40. **Afficher les logs d'un service**:
    - `docker service logs my-service`: Affiche les logs d'un service dans Docker Swarm.

### Optimisation et Best Practices

41. **Minimiser les couches dans les Dockerfiles**:
    - Combinez les commandes `RUN`, `COPY`, `ADD` pour réduire le nombre de couches dans une image.

42. **Utiliser des images multi-stage pour la construction**:
    - Permet de séparer les environnements de build et d'exécution pour minimiser la taille des images.

43. **Nettoyer les ressources non utilisées**:
    - `docker system prune`: Supprime les containers arrêtés, les volumes non utilisés, les réseaux non utilisés, et les images suspendues.

44. **Utiliser le fichier `.dockerignore`**:
    - Excluez les fichiers et répertoires inutiles pour la construction de l'image avec un fichier `.dockerignore`.

45. **Configurer des health checks dans les Dockerfiles**:
    - `HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1`: Ajoute un contrôle de santé à une image.

46. **Utiliser des variables d'environnement pour la configuration**:
    - `docker run -e "ENV_VAR_NAME=value" nginx`: Passe des variables d'environnement à un container.

47. **Optimiser l'utilisation des ressources**:
    - Limitez les ressources (CPU, mémoire) au niveau du container pour éviter l'impact sur l'hôte.

48. **Sécuriser la communication entre les containers**:
    - Utilisez des réseaux Docker personnalisés avec des règles de firewall et des stratégies de sécurité.

49. **Isoler les containers**:
    - Utilisez des user namespaces et des cgroups pour isoler les containers et limiter leurs permissions.

50. **Audit et conformité**:
    - `docker history my-image`: Affiche l'historique de construction d'une image pour l'audit et la conformité.


[[SYSADMIN]]
[[DOCKER]]
