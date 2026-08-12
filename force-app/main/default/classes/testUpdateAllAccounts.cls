/**
 * Tests du batch UpdateAllAccounts (recalcul en masse du chiffre
 * d'affaires, scénario de migration de données).
 */
@isTest
private class testUpdateAllAccounts {

    @isTest
    static void testBatchRecalculatesChiffreAffaires() {
        Account acc = TestDataFactory.createAccount('Migration Test');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(200);

        // Simule une migration : les commandes arrivent déjà au statut "Activated".
        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 5, 200, 2, true);

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts(), 200);
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(2000, refreshed.Chiffre_d_affaire__c,
            'Le batch doit recalculer le CA à partir de toutes les commandes Activated du compte.');
    }
}
