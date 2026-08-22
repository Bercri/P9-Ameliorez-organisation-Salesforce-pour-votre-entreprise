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
        // Garde-fou : évite une requête/DML inutile si aucun compte à traiter
        // (ex : appelé depuis un trigger sans commande nouvellement activée).
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        // Coeur de la bulkification : UNE seule requête agrégée (GROUP BY),
        // quel que soit le nombre de comptes/commandes dans accountIds.
        // C'est cette requête qui remplace l'ancienne boucle
        // "1 SELECT par commande" qui dépassait la limite de gouverneur.
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

        // On reconstruit la liste à partir de accountIds (pas seulement des
        // résultats de l'agrégat) pour remettre à 0 le CA d'un compte qui
        // n'a plus aucune commande Activated (ex : commande désactivée).
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            accountsToUpdate.add(new Account(
                Id = accountId,
                Chiffre_d_affaire__c = totalByAccountId.containsKey(accountId)
                    ? totalByAccountId.get(accountId)
                    : 0
            ));
        }

        // Un seul DML pour tous les comptes du lot (au lieu d'un update par compte).
        update accountsToUpdate;
    }
}
