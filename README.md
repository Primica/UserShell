# UserShell - Guide d'usage

Vue d'ensemble
UserShell est un petit shell PowerShell pour administrer les comptes locaux, les groupes et appliquer des permissions sur des dossiers.

Prérequis
- Windows PowerShell 5.1 ou supérieur
- Exécuter en tant qu'administrateur pour les opérations sur les comptes et les partages
- Pour créer des partages SMB, le module `SmbShare` doit être disponible (Windows Server 2012+ / client Windows avec fonctionnalité SMB installée)

Installation
1. Ouvrir PowerShell en mode administrateur
2. Se placer dans le dossier du projet
3. Lancer `.\UserShell.ps1` (ou appeler le script depuis votre profil)

Commandes principales du REPL
- `source <fichier.toml>` : exécuter un script TOML contenant sections `users`, `groups`, `shares`
- `share-apply` : interface interactive pour appliquer des ACL NTFS sur un ou plusieurs chemins
- `share-smb` : interface interactive pour créer un partage SMB et configurer les permissions SMB
- `ad-help` : afficher les commandes d'orchestration Active Directory
- `ad-auto-core` : automatiser le socle AD (design + baseline GPO + delegation + health checks)
- `ad-full-deploy` : assistant complet guide (confirmations par etape, mode simulation global, journal dans `Logs/`)

Gestion via TOML
Section `shares` attend une table avec les clefs suivantes.
- `paths` (obligatoire) : liste de chemins à traiter
- `identities` (optionnel) : liste d'utilisateurs ou groupes (exemple `Administrateurs`, `DOMAIN\\Equipe`)
- `access` (optionnel) : `Read`, `Modify` ou `FullControl` pour les ACL NTFS. Valeur par défaut `Read`
- `recursive` (optionnel) : boolean, appliquer récursivement les ACL
- `smb` (optionnel) : boolean, si vrai crée aussi un partage SMB pour le chemin
- `share_name` (optionnel) : nom du partage SMB; si absent, le nom du dossier sera utilisé

Exemple TOML (fichier `Scripts/example_share.toml`):

[[shares]]
paths = ["C:\\Data\\Projet", "C:\\Data\\Public"]
identities = ["DOMAIN\\Equipe", "Utilisateurs"]
access = "Modify"
recursive = true
smb = true
share_name = "Projets"

Notes et bonnes pratiques
- Les modifications d'ACL et la création de partages doivent etre realisées avec prudence. Verifier les chemins et les identites avant execution.
- La creation de partages SMB utilise `New-SmbShare` et `Grant-SmbShareAccess`. Si ces cmdlets ne sont pas presentes, la partie SMB echouera.
- Les identites peuvent etre des comptes locaux ou des groupes de domaine si la machine est jointe a un domaine.

Support
Ouvrez une issue dans le depot ou contactez l'auteur du projet pour signaler des bugs ou proposer des améliorations.

Extension Active Directory
- Un kit de deploiement AD centralise est disponible dans `ActiveDirectory/`.
- Voir `ActiveDirectory/README.md` pour l'ordre d'execution (architecture redondee, GPO, delegation, migration et exploitation).
