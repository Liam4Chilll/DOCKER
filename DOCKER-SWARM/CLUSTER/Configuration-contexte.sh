#!/bin/bash

# Détecte les machines Vagrant actives et crée les contextes Docker automatiquement

echo "[INFO] Détection des machines Vagrant actives..."
VMS=$(vagrant status --machine-readable | grep ",state,running" | cut -d',' -f2)

if [ -z "$VMS" ]; then
  echo "[ERREUR] Aucune machine Vagrant active détectée."
  exit 1
fi

for VM in $VMS; do
  echo "[INFO] Récupération des infos SSH pour $VM..."
  HOST=$(vagrant ssh-config $VM | awk '/HostName/ {print $2}')
  USER=$(vagrant ssh-config $VM | awk '/User / {print $2}')
  CONTEXT_NAME=$VM

  echo "[INFO] Création du contexte Docker pour $VM..."
  docker context create "$CONTEXT_NAME" --docker "host=ssh://$USER@$HOST" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "[OK] Contexte $CONTEXT_NAME créé."
  else
    echo "[WARN] Le contexte $CONTEXT_NAME existe déjà."
  fi
done

echo "[INFO] Contextes Docker disponibles :"
docker context ls

