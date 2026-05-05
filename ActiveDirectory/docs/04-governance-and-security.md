# Gouvernance AD et baseline securite

## Groupes d'administration
- `ADM_Tier0_AD`: administration AD DS, DNS, GPO critiques.
- `ADM_Tier1_Servers`: administration serveurs membres.
- `ADM_Tier2_Helpdesk`: support utilisateurs standard (reset password, unlock).

## Baseline GPO
Script: `ActiveDirectory/scripts/04-Governance/Set-AdSecurityBaseline.ps1`

GPO creees et liees:
- `GPO_Domain_PasswordAndLockout` (niveau domaine)
- `GPO_Domain_AdvancedAuditing` (niveau domaine)
- `GPO_Workstations_Hardening` (OU Workstations)
- `GPO_Servers_Hardening` (OU Servers)

## Delegation OU
Script: `ActiveDirectory/scripts/04-Governance/Set-AdOuDelegation.ps1`

Principes:
- Pas d'usage quotidien de `Domain Admins`.
- Delegations par OU et par role.
- Droits explicites et auditables.

## Sequence d'application
1. Provisionner l'architecture OU/groupes.
2. Appliquer la baseline GPO.
3. Appliquer la delegation OU.
4. Forcer la mise a jour policy (`gpupdate /force`) sur pilote.
5. Valider impact avant extension globale.
