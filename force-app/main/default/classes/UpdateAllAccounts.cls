/**
 * Batch Apex : recalcule en masse le chiffre d'affaires de tous les comptes
 * concernés, par exemple après une migration de données réalisée par un
 * système externe (commandes importées directement au statut "Activated",
 * sans passer par le trigger UpdateAccountCA).
 *
 * Bug corrigé : le batch ne faisait qu'un commentaire ("Appeler une classe
 * qui va faire la logique du code") sans logique réelle. Il délègue
 * maintenant le calcul à UpdateAccounts, la même classe de service utilisée
 * par le trigger, pour ne pas dupliquer la logique métier.
 */
global class UpdateAllAccounts implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext context) {
        // Seuls les comptes ayant au moins une commande "Activated" ont besoin d'être recalculés.
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Order WHERE Status = 'Activated')
        ]);
    }

    global void execute(Database.BatchableContext context, List<Account> scope) {
        Set<Id> accountIds = (new Map<Id, Account>(scope)).keySet();
        UpdateAccounts.recalculateChiffreAffaires(accountIds);
    }

    global void finish(Database.BatchableContext context) {
    }
}
