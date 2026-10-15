# Kasbah Strike (prototype Godot 4)

FPS tactique multijoueur entre amis, 100 % gratuit (Godot 4 + réseau ENet intégré).

## Lancer
1. Télécharge **Godot 4.3 ou plus récent** (gratuit) : https://godotengine.org/download
2. Ouvre Godot -> **Importer** -> choisis `project.godot` de ce dossier.
3. Appuie sur **F5** (lancer le projet).

## Jouer
- **S'entraîner en solo** : explore la map et teste le tir.
- **Héberger une partie** : un salon s'ouvre avec un **code** (ex. `K7P2X-93KQ4`).
  Envoie ce code à tes amis. Le jeu essaie d'ouvrir le port 7777 (UDP) tout seul (UPnP).
- **Rejoindre** : colle le code (ou `ip:port`) puis attends le lancement par l'hôte.
- **Amis** : liste locale pseudo + code de salon (pas de serveur central, donc pas de statut en ligne).
- Pour tester seul sur un PC : lance deux instances (Debug > Run Multiple Instances), l'une héberge, l'autre rejoint avec le code "réseau local" ou `127.0.0.1`.

Si ça ne se connecte pas (box sans UPnP, 4G...), utilisez un VPN gratuit (ZeroTier, Radmin VPN, Tailscale) :
tout le monde l'installe, puis rejoignez avec `ip_du_vpn:7777`.

## Commandes (positions physiques, donc ZQSD sur AZERTY)
Déplacement WASD/ZQSD · Espace sauter · Shift marcher · Clic tirer · R recharger · Tab scores · Échap pause/options

## Contenu
Menu principal, salon, Options (jeu, souris/clavier + touches, viseur personnalisable avec code de partage,
vidéo, qualité, audio, HUD), amis, map (générée par code), joueur, tir + dégâts + réapparition,
HUD (vie, munitions, radar, chrono/score, killfeed, zone, scoreboard), pause.

## Export (.exe pour tes amis)
Projet > Exporter > Ajouter... > Windows Desktop (Godot propose de télécharger les "export templates", gratuit)
> Exporter le projet. Envoie l'exécutable + le .pck.

## Prochaines étapes prévues
Bombe (poser/désamorcer) et manches, achat d'armes, bots, vrais modèles/escaliers/arches, sons réels.
