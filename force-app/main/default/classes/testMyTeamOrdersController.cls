/**
 * Tests du contrôleur MyTeamOrdersController (utilisé par le LWC
 * accountOrdersSummary).
 */
@isTest
private class testMyTeamOrdersController {

    @isTest
    static void testReturnsZeroWhenNoActivatedOrders() {
        Account acc = TestDataFactory.createAccount('Sans Commande');

        Test.startTest();
        Decimal total = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(0, total, 'Doit retourner 0 quand le compte n\'a aucune commande Activated.');
    }

    @isTest
    static void testReturnsSumOfActivatedOrdersOnly() {
        Account acc = TestDataFactory.createAccount('Avec Commandes');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(100);

        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 2, 100, 1, true);  // 2 commandes Activated = 200
        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 1, 100, 1, false); // 1 commande Draft, ignorée

        Test.startTest();
        Decimal total = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(200, total,
            'Seules les commandes Activated du compte doivent être sommées.');
    }
}
