# Runbooks d'exploitation AD

## Onboarding
1. Creer le compte utilisateur dans `OU=Users`.
2. Affecter les groupes globaux metier (`GG_*`).
3. Verifier la propagation AGDLP vers les groupes `DL_*`.
4. Forcer changement de mot de passe a la premiere connexion.

## Offboarding
1. Desactiver le compte immediatement.
2. Retirer des groupes privilegies et applicatifs.
3. Deplacer vers OU quarantaine.
4. Supprimer selon politique de retention.

## Incidents usuels
- Reset mot de passe: delegation Tier2.
- Unlock compte: delegation Tier2.
- Incident replication AD: `repadmin /replsummary`, `dcdiag`.
- Incident GPO: `gpresult /r`, `Get-GPResultantSetOfPolicy`.

## Supervision minimale
- Disponibilite services `NTDS`, `DNS`, `KDC`, `Netlogon`.
- Erreurs replication AD.
- Croissance journal securite.
- Echecs d'authentification anormaux.

## Sauvegarde et restauration
- Sauvegarde system state quotidienne de chaque DC.
- Test de restauration en environnement isole chaque trimestre.
- Script de controle: `ActiveDirectory/scripts/06-Operations/Test-AdRestoreReadiness.ps1`.

## Audits periodiques
- Script trimestriel: `ActiveDirectory/scripts/06-Operations/Invoke-AdQuarterlyAudit.ps1`.
- Rapports attendus:
  - comptes inactifs;
  - membres des groupes privilegies;
  - inventaire GPO.
