# UserShell

Shell modulaire PowerShell pour la gestion des utilisateurs et groupes locaux Windows.

## Description

UserShell est un outil en ligne de commande avec une architecture orientée objet (POO) qui permet de gérer facilement les utilisateurs et groupes locaux sur Windows. Il offre une interface interactive avec des commandes simples et intuitives.

## Prérequis

- Windows 10 ou Windows Server 2016 ou supérieur
- PowerShell 5.1 ou supérieur
- Privilèges administrateur

## Architecture

Le projet est organisé de manière modulaire :

```
UserShell/
├── UserShell.ps1           # Point d'entrée principal
├── Modules/                # Modules fonctionnels
│   ├── Logger.psm1         # Gestion des logs
│   ├── UserManager.psm1    # Gestion des utilisateurs
│   ├── GroupManager.psm1   # Gestion des groupes
│   └── ShellCore.psm1      # Moteur du shell
└── Logs/                   # Fichiers de log
```

## Installation

1. Cloner ou télécharger le projet
2. Ouvrir PowerShell en tant qu'administrateur
3. Naviguer vers le dossier UserShell
4. Exécuter le script :

```powershell
.\UserShell.ps1
```

## Utilisation

### Démarrage

```powershell
# Démarrage normal
.\UserShell.ps1

# Démarrage en mode debug
.\UserShell.ps1 -Debug
```

### Commandes disponibles

#### Commandes générales

- `help` - Afficher l'aide complète
- `exit` ou `quit` - Quitter le shell
- `clear` ou `cls` - Effacer l'écran

#### Gestion des utilisateurs

- `user-list` - Lister tous les utilisateurs locaux
- `user-show <nom>` - Afficher les détails d'un utilisateur
- `user-create` - Créer un nouvel utilisateur (mode interactif)
- `user-modify <nom>` - Modifier les propriétés d'un utilisateur
- `user-delete <nom>` - Supprimer un utilisateur
- `user-enable <nom>` - Activer un compte utilisateur
- `user-disable <nom>` - Désactiver un compte utilisateur
- `user-password <nom>` - Changer le mot de passe d'un utilisateur

#### Gestion des groupes

- `group-list` - Lister tous les groupes locaux
- `group-show <nom>` - Afficher les détails d'un groupe
- `group-create` - Créer un nouveau groupe (mode interactif)
- `group-modify <nom>` - Modifier la description d'un groupe
- `group-delete <nom>` - Supprimer un groupe
- `group-addmember <groupe>` - Ajouter un membre à un groupe
- `group-removemember <groupe>` - Retirer un membre d'un groupe

## Exemples

### Créer un utilisateur

```
UserShell> user-create
Nom d'utilisateur: testuser
Mot de passe: ********
Nom complet (optionnel): Test User
Description (optionnel): Utilisateur de test
Le mot de passe n'expire jamais? (O/N): O
L'utilisateur ne peut pas changer le mot de passe? (O/N): N
```

### Lister tous les utilisateurs

```
UserShell> user-list
```

### Désactiver un utilisateur

```
UserShell> user-disable testuser
```

### Ajouter un utilisateur à un groupe

```
UserShell> group-addmember Utilisateurs
Nom du membre a ajouter: testuser
```

## Fonctionnalités

### Architecture Modulaire

- **Logger** : Classe pour la journalisation avec niveaux de gravité
- **UserManager** : Module de gestion des utilisateurs avec méthodes CRUD
- **GroupManager** : Module de gestion des groupes avec gestion des membres
- **ShellCore** : Moteur du shell avec traitement des commandes et interface utilisateur

### Journalisation

Tous les événements sont enregistrés dans le dossier `Logs/` avec horodatage. Les logs sont organisés par jour : `usershell_YYYYMMDD.log`

Niveaux de log :
- INFO : Informations générales
- SUCCESS : Opérations réussies
- WARNING : Avertissements
- ERROR : Erreurs
- DEBUG : Informations de débogage (mode debug uniquement)

### Sécurité

- Vérification des privilèges administrateur au démarrage
- Mots de passe gérés via SecureString
- Confirmation requise pour les opérations destructives
- Logs détaillés de toutes les opérations

## Personnalisation

### Ajouter de nouvelles commandes

1. Ouvrir `Modules/ShellCore.psm1`
2. Ajouter une méthode dans la classe `ShellCore`
3. Ajouter le case correspondant dans la méthode `ProcessCommand()`
4. Mettre à jour la méthode `ShowHelp()`

## Dépannage

### Erreur de privilèges

```
ERREUR: Ce script necessite des privileges administrateur.
```

**Solution** : Exécuter PowerShell en tant qu'administrateur (clic droit > Exécuter en tant qu'administrateur)

### Erreur de version PowerShell

```
ERREUR: PowerShell 5.1 ou superieur est requis.
```

**Solution** : Mettre à jour PowerShell vers la version 5.1 ou supérieure

### Modules non chargés

```
ERREUR: Impossible de charger les modules
```

**Solution** : Vérifier que tous les fichiers .psm1 sont présents dans le dossier Modules/

## Limitations

- Fonctionne uniquement sur Windows
- Gestion des utilisateurs et groupes locaux uniquement (pas Active Directory)
- Nécessite PowerShell 5.1 minimum
- Requiert des privilèges administrateur

## Licence

Projet libre d'utilisation et de modification.

## Notes techniques

- Les modules utilisent des classes PowerShell avec typage objet pour la compatibilité
- Tous les retours de fonctions utilisent des PSCustomObject pour éviter les dépendances de types
- Le chargement des modules se fait dans l'ordre : Logger, UserManager, GroupManager, ShellCore
- Les logs sont automatiquement horodatés et organisés par jour