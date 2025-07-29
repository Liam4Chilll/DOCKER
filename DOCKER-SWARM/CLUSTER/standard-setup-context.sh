#!/bin/bash
# Script de configuration SSH mutuelle et contextes Docker pour cluster Swarm
# Exécution depuis master avec configuration SSH inter-VMs sécurisée

# Configuration des VMs du cluster
declare -A CLUSTER_VMS=(
  ["master"]="192.168.1.50"
  ["s1"]="192.168.1.51" 
  ["s2"]="192.168.1.52"
)

DEFAULT_USER="user"

echo "[INFO] Configuration SSH mutuelle et contextes Docker depuis master..."
echo ""

# Demande sécurisée du mot de passe SSH
echo -n "[INPUT] Mot de passe SSH pour les VMs workers : "
read -s SSH_PASSWORD
echo ""

if [ -z "$SSH_PASSWORD" ]; then
   echo "[ERREUR] Mot de passe requis pour continuer."
   exit 1
fi

echo "[INFO] Mot de passe saisi, démarrage de la configuration..."
echo ""

# Installation sshpass si nécessaire
if ! command -v sshpass &> /dev/null; then
  echo "[INFO] Installation de sshpass..."
  sudo apt update && sudo apt install -y sshpass
fi

# Génération de la clé SSH si elle n'existe pas
if [ ! -f ~/.ssh/id_rsa ]; then
  echo "[INFO] Génération de la clé SSH..."
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
  echo "[OK] Clé SSH générée."
else
  echo "[INFO] Clé SSH existante trouvée."
fi

# Fonction de copie de clé SSH
copy_ssh_key() {
  local vm_name=$1
  local vm_ip=$2
  
  echo "[INFO] Copie de la clé SSH vers $vm_name ($vm_ip)..."
  
  sshpass -p "$SSH_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$DEFAULT_USER@$vm_ip" >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
      echo "[OK] Clé SSH copiée vers $vm_name."
      return 0
  else
      echo "[ERREUR] Échec copie clé SSH vers $vm_name."
      return 1
  fi
}

# Fonction de test connectivité SSH sans mot de passe
test_ssh_connection() {
  local vm_name=$1
  local vm_ip=$2
  
  ssh -o ConnectTimeout=5 -o BatchMode=yes "$DEFAULT_USER@$vm_ip" "exit" >/dev/null 2>&1
  return $?
}

# Fonction de création contexte Docker
create_docker_context() {
  local vm_name=$1
  local vm_ip=$2
  
  echo "[INFO] Création du contexte Docker pour $vm_name..."
  
  docker context create "$vm_name" \
      --docker "host=ssh://$DEFAULT_USER@$vm_ip" \
      --description "Docker context for $vm_name ($vm_ip)" \
      >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
      echo "[OK] Contexte $vm_name créé."
  else
      echo "[WARN] Contexte $vm_name existe déjà."
  fi
}

# Configuration SSH mutuelle pour toutes les VMs
echo "[INFO] === PHASE 1: Configuration SSH mutuelle ==="

for vm_name in "${!CLUSTER_VMS[@]}"; do
  vm_ip="${CLUSTER_VMS[$vm_name]}"
  
  # Skip master (local)
  if [ "$vm_name" = "master" ]; then
      continue
  fi
  
  echo "[INFO] Configuration SSH vers $vm_name ($vm_ip)..."
  
  # Copie de la clé SSH
  if copy_ssh_key "$vm_name" "$vm_ip"; then
      # Test de la connexion sans mot de passe
      if test_ssh_connection "$vm_name" "$vm_ip"; then
          echo "[OK] Connexion SSH sans mot de passe vers $vm_name réussie."
      else
          echo "[ERREUR] Connexion SSH sans mot de passe vers $vm_name échouée."
      fi
  fi
done

# Effacement sécurisé du mot de passe de la mémoire
unset SSH_PASSWORD

# Création des contextes Docker
echo ""
echo "[INFO] === PHASE 2: Création contextes Docker ==="

# Contexte local pour master
echo "[INFO] Création du contexte local master..."
docker context create master \
  --docker "host=unix:///var/run/docker.sock" \
  --description "Local Docker context for master node" \
  >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[OK] Contexte master (local) créé."
else
  echo "[WARN] Contexte master existe déjà."
fi

# Contextes pour les workers
for vm_name in "${!CLUSTER_VMS[@]}"; do
  vm_ip="${CLUSTER_VMS[$vm_name]}"
  
  # Skip master (déjà traité)
  if [ "$vm_name" = "master" ]; then
      continue
  fi
  
  if test_ssh_connection "$vm_name" "$vm_ip"; then
      create_docker_context "$vm_name" "$vm_ip"
  else
      echo "[ERREUR] Impossible de créer le contexte pour $vm_name (SSH non fonctionnel)."
  fi
done

# Définir master comme contexte par défaut
docker context use master >/dev/null 2>&1

echo ""
echo "[INFO] === RÉSULTATS ==="
echo "[INFO] Contextes Docker disponibles :"
docker context ls

echo ""
echo "[INFO] Test accès Docker sur chaque nœud :"
for vm_name in "${!CLUSTER_VMS[@]}"; do
  echo -n "[$vm_name] "
  docker --context "$vm_name" system info --format "{{.Name}} - {{.Swarm.LocalNodeState}}" 2>/dev/null || echo "Erreur accès Docker"
done

echo ""
echo "[INFO] Statut cluster Swarm :"
docker node ls 2>/dev/null || echo "[ERREUR] Cluster Swarm non accessible"

echo ""
echo "[INFO] Utilisation des contextes :"
echo "  docker context use master         # Manager du cluster"
echo "  docker context use s1             # Worker s1"
echo "  docker context use s2             # Worker s2"
echo "  docker --context s1 ps            # Conteneurs sur s1"
echo "  docker --context s2 system df     # Ressources s2"

# Vérification exécution depuis master
current_ip=$(hostname -I | awk '{print $1}')
if [ "$current_ip" = "192.168.1.50" ]; then
  echo ""
  echo "[OK] Configuration terminée depuis VM Manager (master - $current_ip)"
else
  echo ""
  echo "[WARN] Script non exécuté depuis master (IP: $current_ip)"
fi
