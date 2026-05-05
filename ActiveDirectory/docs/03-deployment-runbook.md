# Runbook de deploiement AD coeur

## Etape 1 - Promotion DC primaire
1. Preparer un serveur Windows avec IP fixe et DNS local.
2. Executer `ActiveDirectory/scripts/03-Deploy/Install-PrimaryDomainController.ps1`.
3. Redemarrer le serveur.
4. Verifier que le role AD DS est operationnel.

## Etape 2 - Promotion DC secondaire
1. Joindre le serveur secondaire au domaine.
2. Executer `ActiveDirectory/scripts/03-Deploy/Install-SecondaryDomainController.ps1`.
3. Redemarrer le serveur.
4. Verifier la replication initiale.

## Etape 3 - Validation coeur AD
Executer `ActiveDirectory/scripts/03-Deploy/Test-AdCoreHealth.ps1` puis confirmer:
- replication sans erreur (`repadmin /replsummary`);
- DNS AD sain (`dcdiag /test:DNS /v`);
- services AD critiques demarres sur les deux DC;
- NTP coherent (PDC fiable + resync ok).

## Points de controle obligatoires
- Chaque DC utilise l'autre DC comme DNS secondaire.
- Les roles FSMO sont connus et documentes.
- Une sauvegarde system state a ete executee apres mise en service.
