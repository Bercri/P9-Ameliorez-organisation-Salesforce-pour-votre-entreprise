/**
 * Trigger : recalcule le chiffre d'affaires (Account.Chiffre_d_affaire__c)
 * du compte rattaché, quand une commande (Order) passe au statut "Activated".
 *
 * Bug corrigé (voir Notes de cadrage Fasha) : l'ancienne version exécutait
 * une requête SOQL et un DML "update" à l'intérieur d'une boucle sur chaque
 * commande du lot ([SELECT ... WHERE Id = :newOrder.AccountId] puis
 * "update acc;" pour chaque Order). Dès qu'un compte cumulait plus de 100
 * commandes mises à jour dans une même transaction (ex : import Data
 * Loader), la limite Salesforce de 100 requêtes SOQL par transaction était
 * dépassée ("Too many SOQL queries: 101").
 *
 * Le trigger est maintenant bulkifié : il se contente de repérer les
 * commandes qui viennent de passer à "Activated" dans le lot, puis délègue
 * le calcul (une seule requête agrégée + un seul DML) à UpdateAccounts.
 */
trigger UpdateAccountCA on Order (after insert, after update) {

    Set<Id> accountIdsToRecalculate = new Set<Id>();

    for (Order currentOrder : Trigger.new) {
        if (currentOrder.AccountId == null || currentOrder.Status != 'Activated') {
            continue;
        }

        Boolean isNewlyActivated = Trigger.isInsert
            || Trigger.oldMap.get(currentOrder.Id).Status != 'Activated';

        if (isNewlyActivated) {
            accountIdsToRecalculate.add(currentOrder.AccountId);
        }
    }

    if (!accountIdsToRecalculate.isEmpty()) {
        UpdateAccounts.recalculateChiffreAffaires(accountIdsToRecalculate);
    }
}
