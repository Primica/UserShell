# Architecture cible AD redondee

## Topologie
- 2 DC minimum: `DC1` (site principal) et `DC2` (site secondaire).
- DNS integre AD actif sur les deux DC.
- Sites AD et sous-reseaux definis pour controler la replication.
- NTP autoritaire configure sur le DC detenant le role PDC Emulator.

## Structure OU
- `OU=CORP`
  - `OU=Tier0`
  - `OU=Tier1`
  - `OU=Tier2`
  - `OU=Users`
  - `OU=Groups`
    - `OU=Global`
    - `OU=DomainLocal`
    - `OU=Admin`
  - `OU=ServiceAccounts`
  - `OU=Workstations`
  - `OU=Servers`

## Modele de groupes (AGDLP)
- Comptes utilisateurs -> groupes globaux `GG_*`.
- Groupes globaux -> groupes locaux de domaine `DL_*`.
- Groupes locaux de domaine -> ACL ressources.
- Groupes admin dedies: `ADM_Tier0_AD`, `ADM_Tier1_Servers`, `ADM_Tier2_Helpdesk`.

## Delegation recommandee
- Tier0: gestion AD DS, DNS et GPO sensibles.
- Tier1: gestion serveurs membres.
- Tier2: operations helpdesk (reset mot de passe, unlock, gestion attributs standards).
- Interdire l'usage quotidien des comptes privilegies (separation compte user/admin).

## Script de provisioning
Utiliser `ActiveDirectory/scripts/02-Design/New-AdTargetArchitecture.ps1` pour creer:
- OUs principales et sous-OUs.
- Groupes AGDLP de base.
- Sites et subnets AD.
- Liens de groupes d'exemple pour les ACL.
