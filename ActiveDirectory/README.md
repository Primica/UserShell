# Active Directory Deployment Kit

Ce dossier fournit une implementation complete du plan de deploiement AD centralise:

- `config/`: parametres de cadrage et standards.
- `docs/`: documentation par etape (cadrage, architecture, deploiement, gouvernance, migration, exploitation).
- `scripts/`: scripts PowerShell par phase pour industrialiser le deploiement.
- `data/`: templates pour migration.
- `reports/`: sorties d'audit (genere a l'execution).

## Ordre d'execution recommande
1. `scripts/03-Deploy/Install-PrimaryDomainController.ps1`
2. `scripts/03-Deploy/Install-SecondaryDomainController.ps1`
3. `scripts/03-Deploy/Test-AdCoreHealth.ps1`
4. `scripts/02-Design/New-AdTargetArchitecture.ps1`
5. `scripts/04-Governance/Set-AdSecurityBaseline.ps1`
6. `scripts/04-Governance/Set-AdOuDelegation.ps1`
7. `scripts/05-Migration/Invoke-AdMigration.ps1`
8. `scripts/05-Migration/Test-AdPilotValidation.ps1`
9. `scripts/06-Operations/Invoke-AdQuarterlyAudit.ps1`

## Notes importantes
- Les scripts sont idempotents autant que possible.
- Executer avec un compte approprie au niveau de privilege requis.
- Tester d'abord en preproduction.
