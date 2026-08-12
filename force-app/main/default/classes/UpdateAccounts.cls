/**
 * Classe de service centralisant le recalcul du chiffre d'affaires (CA)
 * des comptes (Account.Chiffre_d_affaire__c), à partir des commandes (Order)
 * dont le statut est "Activated".
 *
 * Réutilisée par :
 *  - UpdateAccountCA.trigger (recalcul ciblé, quand une commande passe à
 *    "Activated")
 *  - UpdateAllAccounts.cls (recalcul en masse, par exemple lors d'une
 *    migration de données)
 *
 * Le CA est recalculé par agrégation (SUM) sur les commandes "Activated"
 * existantes, et non par incrémentation ligne à ligne. Cela évite les
 * doublons/erreurs de cumul (ex : trigger exécuté deux fois) et garantit
 * qu'une modification ultérieure du prix d'un produit n'a aucun impact sur
 * le CA des commandes déjà finalisées : Order.TotalAmount est calculé à
 * partir du prix figé sur chaque OrderItem au moment de la commande, il
 * n'est jamais recalculé rétroactivement quand le Pricebook change.
 */
public without sharing class UpdateAccounts {

    private static final String STATUS_ACTIVATED = 'Activated';

    public static void recalculateChiffreAffaires(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> totalByAccountId = new Map<Id, Decimal>();
        for (AggregateResult result : [
            SELECT AccountId accId, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds
            AND Status = :STATUS_ACTIVATED
            GROUP BY AccountId
        ]) {
            totalByAccountId.put((Id) result.get('accId'), (Decimal) result.get('total'));
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            accountsToUpdate.add(new Account(
                Id = accountId,
                Chiffre_d_affaire__c = totalByAccountId.containsKey(accountId)
                    ? totalByAccountId.get(accountId)
                    : 0
            ));
        }

        update accountsToUpdate;
    }
}
