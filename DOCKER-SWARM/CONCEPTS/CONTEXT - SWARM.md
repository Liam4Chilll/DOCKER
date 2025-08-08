Les contextes servent à scinder les containers en terme d'administration.
Plusieurs node peuvent faire parti d'un même contexte mais pour éviter les erreurs de manipulation, on peux scinder chacun des noeud dans un environnement distant (similaire à pyenv)


**Renomer un contexte :** 
1. **Exporter l’ancien contexte et le recréer sous un autre nom :**
    'docker context inspect desktop-linux > tmp-context.json 
	'docker context create macbook --from desktop-linux' 
	'docker context rm desktop-linux'

➡️ La commande `docker context create --from` permet de cloner 

**Check du contexte**
`docker context show`

**Changer de contexte** 
`docker context use 'nom du context'
