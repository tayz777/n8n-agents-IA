# n8n local sur Mac

Ce dossier permet de lancer n8n facilement sur un Mac.

## Première installation

1. Télécharge et installe [Docker Desktop pour Mac](https://www.docker.com/products/docker-desktop/).
2. Ouvre **Docker Desktop**.
3. Attends que Docker indique qu'il est prêt.

## Lancer n8n

1. Ouvre l'application **Terminal** sur ton Mac.
2. Écris `sh ` dans le Terminal, sans appuyer sur Entrée.
3. Fais glisser le fichier **DEMARRER.command** dans la fenêtre du Terminal.
4. Appuie sur **Entrée**.

Au premier lancement, attends quelques minutes pendant le téléchargement. Le navigateur s'ouvrira automatiquement lorsque n8n sera prêt.

## Se connecter

- Adresse : <http://localhost:5678>
- E-mail : `admin@local.test`
- Mot de passe : `Admin123`

## Arrêter n8n

Fais la même chose avec le fichier **ARRETER.command** :

1. Ouvre **Terminal**.
2. Écris `sh `.
3. Fais glisser **ARRETER.command** dans le Terminal.
4. Appuie sur **Entrée**.

Tes automatisations resteront enregistrées pour le prochain lancement.

> Cette installation est prévue uniquement pour une utilisation locale sur ton Mac.
