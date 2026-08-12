/**
 * Trigger : calcule le montant net (Order.NetAmount__c) de chaque commande,
 * avant sa mise à jour. NetAmount__c = TotalAmount - ShipmentCost__c.
 *
 * Remplace l'ancien "CalculMontant.trigger". Bug corrigé : l'ancienne
 * version ne traitait que la première commande du contexte
 * (Order newOrder = trigger.new[0];), ce qui fait que seule la première
 * ligne était recalculée lors d'une mise à jour groupée (ex : import
 * multi-lignes avec Data Loader) — exactement le bug remonté par Fasha.
 *
 * Le trigger boucle maintenant sur l'ensemble de Trigger.new, quel que soit
 * le nombre de commandes traitées dans la transaction.
 */
trigger OrderNetAmountTrigger on Order (before update) {

    for (Order currentOrder : Trigger.new) {
        Decimal totalAmount = currentOrder.TotalAmount == null ? 0 : currentOrder.TotalAmount;
        Decimal shipmentCost = currentOrder.ShipmentCost__c == null ? 0 : currentOrder.ShipmentCost__c;
        currentOrder.NetAmount__c = totalAmount - shipmentCost;
    }
}
