# Installation complète de Vagrant + VMware Fusion sur MacBook Apple Silicon

## Prérequis
- MacBook avec puce Apple Silicon (M1/M2/M3)
- macOS à jour
- Compte administrateur

## Étape 1 : Installation de Homebrew (si pas déjà installé)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Étape 2 : Installation de Vagrant
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/vagrant
```

## Étape 3 : Installation de VMware Fusion
1. Créer un compte sur le site Broadcom/VMware
2. Télécharger VMware Fusion Pro (licence personnelle gratuite)
3. Installer le fichier `.dmg` téléchargé
4. Lancer VMware Fusion et accepter la licence personnelle gratuite

## Étape 4 : Installation du plugin Vagrant VMware Desktop
```bash
vagrant plugin install vagrant-vmware-desktop
```

## Étape 5 : Téléchargement et installation du Vagrant VMware Utility
1. Aller sur : https://developer.hashicorp.com/vagrant/install/vmware
2. Télécharger le fichier `.pkg` pour macOS
3. Double-cliquer sur le fichier `.pkg` et suivre l'installation
4. Le service se lance automatiquement après installation

## Étape 6 : Configuration de la variable d'environnement
```bash
echo 'export VAGRANT_DEFAULT_PROVIDER=vmware_fusion' >> ~/.zshrc
source ~/.zshrc
```

## Étape 7 : Redémarrage obligatoire
```bash
sudo reboot
```

## Étape 8 : Vérification de l'installation
```bash
# Vérifier Vagrant
vagrant --version

# Vérifier les plugins
vagrant plugin list

# Vérifier le service VMware Utility
sudo launchctl list | grep vagrant-vmware-utility
```

## Étape 9 : Test de l'installation

### Option A : Initialisation avec box générique (puis spécification lors du up)
```bash
# Créer un répertoire de test
mkdir vagrant-test
cd vagrant-test

# Initialiser sans spécifier de box
vagrant init

# Modifier le Vagrantfile pour spécifier la box ARM64
# Puis lancer avec la box spécifiée
sudo vagrant up
```

### Option B : Initialisation directe avec box ARM64
```bash
# Créer un répertoire de test
mkdir vagrant-test
cd vagrant-test

# Initialiser directement avec une box ARM64
vagrant init gyptazy/ubuntu22.04-arm64

# Lancer la VM
sudo vagrant up
```

**Différence** : L'option A permet de créer un Vagrantfile générique puis de spécifier la box dans le fichier, tandis que l'option B configure directement la box lors de l'initialisation.

## Commandes essentielles à retenir

```bash
# Lancer des VMs spécifiques
sudo vagrant up m1 w1

# Se connecter à une VM
sudo vagrant ssh m1

# Voir l'état des VMs
sudo vagrant status

# Arrêter les VMs
sudo vagrant halt

# Détruire les VMs
sudo vagrant destroy -f

# Redémarrer les services VMware si nécessaire
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --stop
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --start
```

## Notes importantes
- **Toujours utiliser `sudo`** avec les commandes vagrant sur Apple Silicon
- Utiliser uniquement des **boxes ARM64** compatibles (gyptazy/ubuntu22.04-arm64)
- Le service VMware Utility doit être en cours d'exécution
- En cas de problème réseau, redémarrer les services VMware

## Boxes ARM64 recommandées
- `gyptazy/ubuntu22.04-arm64` (Ubuntu 22.04 Server)
- `gyptazy/ubuntu24.04-server-arm64` (Ubuntu 24.04 Server)
- `perk/ubuntu-2204-arm64` (Alternative)

L'installation est maintenant opérationnelle pour votre environnement Docker Swarm.
