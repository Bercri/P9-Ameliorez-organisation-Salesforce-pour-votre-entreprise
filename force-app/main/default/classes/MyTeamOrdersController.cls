/**
 * Contrôleur Apex du composant LWC "accountOrdersSummary" (anciennement
 * "orders"), affiché sur la page du compte.
 *
 * Bug corrigé : la méthode sommait le TotalAmount de TOUTES les commandes
 * de l'organisation, quel que soit le compte affiché
 * ([SELECT SUM(TotalAmount) total FROM Order] sans filtre). Elle prend
 * maintenant en paramètre l'Id du compte affiché et ne somme que ses
 * commandes au statut "Activated".
 *
 * "without sharing" remplacé par "with sharing" : le contrôleur respecte
 * désormais les règles de partage de l'utilisateur connecté (bonne
 * pratique de sécurité Salesforce).
 */
public with sharing class MyTeamOrdersController {

    @AuraEnabled(cacheable=true)
    public static Decimal getSumOrdersByAccount(Id accountId) {
        AggregateResult groupedResult = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE AccountId = :accountId
            AND Status = 'Activated'
        ];

        Decimal total = (Decimal) groupedResult.get('total');
        return total == null ? 0 : total;
    }
}
