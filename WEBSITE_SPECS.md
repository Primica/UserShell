# UserShell - Spécifications pour le Site Web

## Vue d'ensemble du projet

UserShell est un shell modulaire PowerShell professionnel pour la gestion des utilisateurs et groupes locaux Windows avec système de scripting TOML intégré.

## Style et Design System

**Design System cible:** IBM Carbon Design System
- Esthétique professionnelle, épurée et technique
- Palette de couleurs sombre avec accents bleus/cyans
- Typographie IBM Plex (Sans, Mono)
- Animations subtiles et élégantes
- Focus sur l'accessibilité

## Structure du Site Web

### 1. Page d'Accueil (Hero Section)

**Titre principal:**
```
UserShell
Gestion Professionnelle des Utilisateurs Windows
```

**Sous-titre:**
```
Shell modulaire PowerShell avec scripting TOML intégré
pour automatiser la gestion des utilisateurs et groupes locaux
```

**Call-to-Actions:**
- Bouton secondaire: "Documentation"
- Bouton primaire: "Voir sur GitHub"

**Badges à afficher:**
- PowerShell 5.1+
- Windows 10/11 & Server
- Open Source
- Version 1.0

**Animation Hero:**
- Terminal animé montrant des commandes UserShell en action
- Effet de typing pour les commandes
- Sortie colorée simulée (cyan pour headers, vert pour success, etc.)

### 2. Section Fonctionnalités Principales

**Layout:** Grille 3 colonnes (responsive)

**Carte 1: Gestion Interactive**
- Icône: Terminal/Console
- Titre: "Shell Interactif Puissant"
- Description: "Interface en ligne de commande intuitive avec commandes simples et feedback visuel immédiat"
- Exemples de commandes:
  - `user-list`
  - `group-create`
  - `user-show alice`

**Carte 2: Scripting TOML**
- Icône: Document/Script
- Titre: "Automatisation avec TOML"
- Description: "Créez des scripts TOML pour automatiser la création, modification et suppression d'utilisateurs et groupes"
- Code snippet TOML avec syntax highlighting

**Carte 3: Export/Import**
- Icône: Database/Backup
- Titre: "Dump & Restore"
- Description: "Exportez votre configuration en TOML et restaurez-la instantanément sur d'autres machines"
- Exemple: `dump backup.toml`

**Carte 4: Logs Complets**
- Icône: Document/Logs
- Titre: "Traçabilité Totale"
- Description: "Tous les événements sont enregistrés avec horodatage pour audit et diagnostic"
- Niveaux: INFO, SUCCESS, WARNING, ERROR

**Carte 5: Architecture Modulaire**
- Icône: Puzzle/Modules
- Titre: "Design Modulaire"
- Description: "Architecture propre avec modules séparés pour logger, utilisateurs, groupes et scripts"
- Liste des modules

**Carte 6: Sécurité**
- Icône: Shield/Lock
- Titre: "Sécurisé par Design"
- Description: "Validation des entrées, confirmation pour suppressions, logs d'audit, gestion sécurisée des mots de passe"

### 4. Section Architecture

**Diagramme visuel:**
```
UserShell.ps1 (Point d'entrée)
    ↓
ShellCore (Moteur)
    ↓
┌─────────────┬──────────────┬──────────────┬──────────────┐
│   Logger    │ UserManager  │ GroupManager │ ScriptExecutor│
└─────────────┴──────────────┴──────────────┴──────────────┘
    ↓              ↓               ↓               ↓
TomlParser ←────────────────────────────────────────┘
    ↓
DumpManager
```

**Modules détaillés:**
- **Logger:** Journalisation multi-niveaux
- **UserManager:** CRUD utilisateurs
- **GroupManager:** CRUD groupes
- **TomlParser:** Parser TOML intégré
- **ScriptExecutor:** Exécution de scripts
- **DumpManager:** Export/Import TOML
- **ShellCore:** Orchestration et UI

### 5. Section Guide Rapide

**Installation:**
```powershell
# 1. Télécharger le projet
git clone https://github.com/votre-repo/UserShell

# 2. Lancer PowerShell en Administrateur
# 3. Naviguer vers le dossier
cd UserShell

# 4. Exécuter
.\UserShell.ps1
```

**Premiers Pas (accordion/tabs):**

**Tab 1: Commandes de Base**
- Lister les utilisateurs
- Créer un utilisateur
- Voir les détails
- Désactiver un compte

**Tab 2: Scripting TOML**
```toml
[[users]]
name = "alice"
password = "P@ssw0rd123"
fullname = "Alice Dupont"
groups = ["Utilisateurs", "Developers"]

[[groups]]
name = "Developers"
description = "Équipe de développement"
members = ["alice"]
```

**Tab 3: Dump & Restore**
```powershell
# Exporter la configuration
UserShell> dump backup.toml

# Sur une autre machine
UserShell> source backup.toml
```

### 6. Section Exemples de Scripts

**Carousel ou grille de cards:**

**Exemple 1: Configuration Initiale**
- Nom: "Première Installation"
- Description: "Créer utilisateurs et groupes de base"
- Fichier: `example_simple.toml`
- Lignes de code: ~40
- Temps d'exécution: ~2 secondes

**Exemple 2: Onboarding Employé**
- Nom: "Nouvel Employé"
- Description: "Automatiser l'ajout d'un nouvel employé"
- Use case: RH / IT
- Code snippet visible

**Exemple 3: Entreprise Complète**
- Nom: "Configuration Entreprise"
- Description: "Structure complète avec départements"
- Utilisateurs: 15+
- Groupes: 10+
- Fichier: `example_complex.toml`

**Exemple 4: Maintenance**
- Nom: "Opérations de Maintenance"
- Description: "Modifications, désactivations, nettoyage"
- Fichier: `example_modify.toml`

### 7. Section Commandes Complètes

**Layout:** Table ou grille avec recherche/filtre

**Catégorie: Général**
| Commande | Description | Exemple |
|----------|-------------|---------|
| help | Afficher l'aide | `help` |
| exit, quit | Quitter le shell | `exit` |
| clear, cls | Effacer l'écran | `clear` |
| source | Exécuter un script TOML | `source script.toml` |
| dump | Exporter en TOML | `dump backup.toml` |

**Catégorie: Utilisateurs**
| Commande | Description | Exemple |
|----------|-------------|---------|
| user-list | Lister tous les utilisateurs | `user-list` |
| user-show | Afficher les détails | `user-show alice` |
| user-create | Créer un utilisateur | `user-create` |
| user-modify | Modifier un utilisateur | `user-modify alice` |
| user-delete | Supprimer un utilisateur | `user-delete alice` |
| user-enable | Activer un compte | `user-enable alice` |
| user-disable | Désactiver un compte | `user-disable alice` |
| user-password | Changer le mot de passe | `user-password alice` |

**Catégorie: Groupes**
| Commande | Description | Exemple |
|----------|-------------|---------|
| group-list | Lister tous les groupes | `group-list` |
| group-show | Afficher les détails | `group-show Developers` |
| group-create | Créer un groupe | `group-create` |
| group-modify | Modifier un groupe | `group-modify Developers` |
| group-delete | Supprimer un groupe | `group-delete OldGroup` |
| group-addmember | Ajouter un membre | `group-addmember Developers` |
| group-removemember | Retirer un membre | `group-removemember Developers` |

### 8. Section Format TOML

**Titre:** "Format des Scripts TOML"

**Sous-sections (tabs ou accordion):**

**Utilisateurs:**
```toml
[[users]]
name = "nom_utilisateur"              # REQUIS
action = "create"                     # create, modify, delete, enable, disable
password = "MotDePasse123"            # Optionnel (généré si absent)
fullname = "Nom Complet"              # Optionnel
description = "Description du compte" # Optionnel
password_never_expires = true         # true ou false
cannot_change_password = false        # true ou false
groups = ["Groupe1", "Groupe2"]       # Liste de groupes
```

**Groupes:**
```toml
[[groups]]
name = "nom_groupe"                   # REQUIS
action = "create"                     # create, modify, delete, add_members, remove_members
description = "Description du groupe" # Optionnel
members = ["user1", "user2"]          # Liste de membres
```

**Actions Disponibles:**
- Utilisateurs: `create`, `modify`, `delete`, `enable`, `disable`
- Groupes: `create`, `modify`, `delete`, `add_members`, `remove_members`

### 9. Section Dump System

**Titre:** "Système de Dump TOML"

**Description:**
Exportez l'état complet de votre configuration en fichier TOML compatible avec la commande `source`.

**Commandes Dump:**
```powershell
# Dump basique (sans comptes système)
dump

# Dump avec nom de fichier
dump backup.toml

# Dump complet (inclut système)
dump backup.toml --all

# Dump sélectif
dump --users alice,bob
dump --groups Developers,Admins

# Exclure des ressources
dump --exclude-users test1,test2
```

**Caractéristiques:**
- ✓ Génération automatique de timestamp
- ✓ Filtrage des comptes système
- ✓ Export sélectif par utilisateur/groupe
- ✓ Détection automatique des groupes membres
- ✓ Commentaires pour comptes désactivés
- ✗ Mots de passe (sécurité)

**Flow Diagram:**
```
Configuration Actuelle → dump → Fichier TOML → source → Nouvelle Machine
```

### 10. Section Cas d'Usage

**Grille de cards:**

**Use Case 1: PME/PMI**
- **Problème:** Configuration manuelle répétitive
- **Solution:** Scripts TOML pour nouveaux employés
- **Gain:** 90% de temps économisé

**Use Case 2: Serveurs Multiples**
- **Problème:** Maintenir la cohérence entre serveurs
- **Solution:** Dump + source sur chaque serveur
- **Gain:** Configuration identique garantie

**Use Case 3: Disaster Recovery**
- **Problème:** Réinstallation complète après incident
- **Solution:** Restore depuis backup TOML
- **Gain:** Restauration en minutes

**Use Case 4: Testing/Staging**
- **Problème:** Recréer environnement de test
- **Solution:** Dump production → source sur test
- **Gain:** Environnement identique instantané

**Use Case 5: Audit & Compliance**
- **Problème:** Traçabilité des opérations
- **Solution:** Logs détaillés + dumps réguliers
- **Gain:** Conformité réglementaire

**Use Case 6: Formation IT**
- **Problème:** Enseigner la gestion utilisateurs
- **Solution:** Scripts d'exemple et environnement sûr
- **Gain:** Apprentissage pratique

### 11. Section Prérequis & Compatibilité

**Système d'exploitation:**
- ✓ Windows 10 (toutes éditions)
- ✓ Windows 11 (toutes éditions)
- ✓ Windows Server 2016
- ✓ Windows Server 2019
- ✓ Windows Server 2022

**PowerShell:**
- Version minimale: 5.1
- Recommandée: 7.0+

**Privilèges:**
- Administrateur local requis
- Exécution en tant qu'administrateur obligatoire

**Limitations:**
- Utilisateurs/groupes LOCAUX uniquement (pas Active Directory)
- Politique de mot de passe Windows respectée
- Pas de rollback automatique

### 12. Section Sécurité

**Bonnes Pratiques:**

1. **Mots de Passe**
   - Jamais en clair dans les commits
   - Scripts TOML dans répertoires sécurisés
   - Permissions restreintes sur les fichiers

2. **Logs**
   - Conservation pour audit
   - Archivage sécurisé
   - Rotation automatique par jour

3. **Validation**
   - Confirmation pour suppressions
   - Validation syntaxe TOML
   - Vérification existence ressources

4. **Traçabilité**
   - Toutes opérations loggées
   - Horodatage précis
   - Rapport d'exécution détaillé

### 13. Section Téléchargement

**Boutons principaux:**
- GitHub Repository (icône GitHub)
- Download Latest Release (icône download)
- View Documentation (icône book)

**Stats GitHub:**
- Stars
- Forks
- Contributors
- Latest release version
- License (afficher badge)

### 14. Footer

**Colonnes:**

**Colonne 1: Liens**
- Documentation
- GitHub
- Issues
- Releases

**Colonne 2: Ressources**
- Exemples de scripts
- Guide de démarrage
- FAQ
- Tutoriels

**Colonne 3: Communauté**
- Contribuer
- Code de conduite
- Roadmap
- Changelog

**Copyright:**
```
UserShell © 2024 - Open Source Project
Licensed under MIT License
```

## Contenu Additionnel

### Section FAQ (Accordion)

**Q: UserShell fonctionne-t-il avec Active Directory?**
A: Non, UserShell gère uniquement les utilisateurs et groupes LOCAUX. Pour Active Directory, utilisez les cmdlets PowerShell AD natifs.

**Q: Puis-je exporter les mots de passe?**
A: Non, par mesure de sécurité, les mots de passe ne sont jamais exportés dans les dumps TOML.

**Q: Le shell fonctionne-t-il sur Linux/Mac?**
A: Non, UserShell est spécifique à Windows car il utilise les cmdlets PowerShell Local*

**Q: Comment contribuer au projet?**
A: Consultez le fichier CONTRIBUTING.md sur GitHub, ouvrez des issues ou soumettez des pull requests.

**Q: Y a-t-il un support commercial?**
A: UserShell est un projet open source sans support commercial officiel. La communauté est disponible via GitHub Issues.

### Section Roadmap (Timeline visuelle)

**Version 1.0 (Actuelle):**
- ✓ Shell interactif
- ✓ Scripting TOML
- ✓ Système de dump
- ✓ Modules séparés

**Version 1.1 (Planifié):**
- Support PowerShell Core 7+
- Export CSV en plus de TOML
- Validation avancée des scripts
- Templates de scripts prédéfinis

**Version 1.2 (Future):**
- Interface Web locale (optionnelle)
- Planification de scripts (scheduler)
- Notifications email
- Rapports HTML

**Version 2.0 (Vision):**
- Support multi-serveurs
- Remote management
- Dashboard centralisé
- API REST
