# Migration progressive et recette technique

## Strategie de migration
1. Identifier un lot pilote (utilisateurs + postes representatifs).
2. Executer la migration en mode simulation.
3. Corriger les ecarts (groupes, attributs, UPN).
4. Executer la migration reelle.
5. Valider authentification, GPO et acces ressources.
6. Generaliser lot par lot.

## Scripts utilises
- Migration: `ActiveDirectory/scripts/05-Migration/Invoke-AdMigration.ps1`
- Recette pilote: `ActiveDirectory/scripts/05-Migration/Test-AdPilotValidation.ps1`
- Template CSV: `ActiveDirectory/data/migration-users-template.csv`

## Exemple de sequence
- Simulation:
  - `Invoke-AdMigration.ps1 -UsersCsvPath .\ActiveDirectory\data\migration-users-template.csv -UsersOuDn "OU=Users,OU=CORP,DC=corp,DC=contoso,DC=local" -WhatIfMode`
- Execution:
  - `Invoke-AdMigration.ps1 -UsersCsvPath .\ActiveDirectory\data\migration-users-template.csv -UsersOuDn "OU=Users,OU=CORP,DC=corp,DC=contoso,DC=local"`
- Validation:
  - `Test-AdPilotValidation.ps1 -PilotUserSam jdupont -PrimaryDcName DC1`

## Criteres de recette
- Authentification du compte pilote reussie.
- Groupes attendus presents.
- GPO securite appliquees.
- Presence d'au moins un DC secondaire operationnel.
