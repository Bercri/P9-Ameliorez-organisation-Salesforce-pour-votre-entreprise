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

    // start() : définit le périmètre du batch. Database.QueryLocator permet
    // de traiter potentiellement des millions d'enregistrements, découpés
    // automatiquement en lots (scope) par le moteur Batch Apex.
    global Database.QueryLocator start(Database.BatchableContext context) {
        // Seuls les comptes ayant au moins une commande "Activated" ont besoin d'être recalculés.
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Order WHERE Status = 'Activated')
        ]);
    }

    // execute() : appelé une fois par lot (scope), avec un sous-ensemble des
    // comptes retournés par start(). On délègue tout le calcul à
    // UpdateAccounts.recalculateChiffreAffaires, qui reste bulkifié à
    // l'intérieur de chaque lot (1 requête + 1 DML par lot, pas par compte).
    global void execute(Database.BatchableContext context, List<Account> scope) {
        Set<Id> accountIds = (new Map<Id, Account>(scope)).keySet();
        UpdateAccounts.recalculateChiffreAffaires(accountIds);
    }

    // finish() : appelé une seule fois, après le traitement de tous les
    // lots. Rien à faire ici pour ce batch (pas d'email de résumé, pas de
    // chaînage vers un autre batch).
    global void finish(Database.BatchableContext context) {
    }
}
