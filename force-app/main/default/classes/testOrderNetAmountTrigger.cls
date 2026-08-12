/**
 * Tests du trigger OrderNetAmountTrigger (ex CalculMontant.trigger).
 * Couvre notamment la mise à jour groupée façon Data Loader.
 */
@isTest
private class testOrderNetAmountTrigger {

    @isTest
    static void testNetAmountCalculatedForAllOrdersInBulkUpdate() {
        Account acc = TestDataFactory.createAccount('Client NetAmount');

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                ShipmentCost__c = 10
            ));
        }
        insert orders;

        Test.startTest();
        // Simule une mise à jour groupée façon Data Loader (plusieurs lignes en une seule opération DML).
        for (Order o : orders) {
            o.ShipmentCost__c = 20;
        }
        update orders;
        Test.stopTest();

        List<Order> refreshedOrders = [
            SELECT NetAmount__c, TotalAmount, ShipmentCost__c
            FROM Order
            WHERE Id IN :orders
        ];
        System.assertEquals(5, refreshedOrders.size());
        for (Order o : refreshedOrders) {
            System.assertEquals(o.TotalAmount - o.ShipmentCost__c, o.NetAmount__c,
                'Chaque commande du lot doit avoir son NetAmount__c recalculé, pas seulement la première.');
        }
    }
}
