# Cadrage et prerequis AD

## Perimetre identites
- Utilisateurs internes: employes, stagiaires, alternants.
- Utilisateurs externes: prestataires avec date d'expiration obligatoire.
- Comptes de service: comptes applicatifs nominatifs interdits.
- Comptes admin: comptes separes des comptes bureautiques.
- Objets machine: postes clients et serveurs membres.

## Prerequis infrastructure
- Deux serveurs Windows Server pour les controleurs de domaine (DC1, DC2).
- Resolution DNS interne dediee au domaine AD.
- Synchronisation NTP fiable (PDC Emulator vers source de temps autoritaire).
- Sauvegarde system state quotidienne des DC.
- Supervision des services AD DS, DNS, replication et espace disque.

## Standards de nommage
- Domaine: `corp.contoso.local` (a adapter via `ActiveDirectory/config/ad-scope.psd1`).
- Utilisateurs: `prenom.nom` ou `idRH`.
- Groupes:
  - Globaux metier: `GG_<RoleOrTeam>`
  - Locaux de domaine ACL: `DL_<Ressource>_<Niveau>`
  - Admin: `ADM_<Perimetre>`
- GPO: `GPO_<Perimetre>_<Objectif>`.
- OU: `OU_<Type>_<Perimetre>`.

## Exigences securite minimales
- MFA obligatoire pour les comptes privilegies.
- Principe du moindre privilege et delegation par OU.
- Tiering administratif Tier0/Tier1/Tier2.
- Journalisation avancee (logon, changements AD, GPO, privileged use).
- Revue trimestrielle des groupes a privilege.

## Sortie attendue du cadrage
- Portee fonctionnelle validee.
- Matrice des roles administratifs.
- Validation des prerequis techniques.
- Validation du modele de gouvernance securite.
