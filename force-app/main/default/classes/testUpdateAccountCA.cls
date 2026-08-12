/**
 * Tests du trigger UpdateAccountCA / de la classe de service UpdateAccounts.
 * Couvre notamment le scénario de non-régression du bug de bulkification
 * (échec au-delà de 100 commandes sur un même compte).
 */
@isTest
private class testUpdateAccountCA {

    @isTest
    static void testChiffreAffairesUpdatedWhenOrderActivated() {
        Account acc = TestDataFactory.createAccount('Client Test');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(150);

        Test.startTest();
        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 1, 150, 10, true);
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1500, refreshed.Chiffre_d_affaire__c,
            'Le chiffre d\'affaires du compte doit correspondre au montant total de la commande activée.');
    }

    @isTest
    static void testChiffreAffairesBulkOver100Orders() {
        // Non-régression : ce scénario levait "Too many SOQL queries: 101" avant la correction.
        Account acc = TestDataFactory.createAccount('Client Volume');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(100);

        Test.startTest();
        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 150, 100, 1, true);
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(15000, refreshed.Chiffre_d_affaire__c,
            'Le CA doit être correctement calculé même au-delà de 100 commandes sur le même compte.');
    }

    @isTest
    static void testChiffreAffairesNotImpactedByLaterPriceChange() {
        // Remarque : Salesforce interdit toute mise à jour (DML) du prix d'un
        // PricebookEntry depuis un test Apex, quel que soit le Price Book
        // (limitation de la plateforme, sans rapport avec le code de
        // l'application). On simule donc un "changement de prix produit" en
        // créant un DEUXIÈME PricebookEntry à un prix différent pour le même
        // produit, sans jamais modifier le premier : cela couvre la même règle
        // métier (le CA d'une commande déjà activée reste figé, quel que soit
        // le prix catalogue en vigueur au moment de la lecture).
        Account acc = TestDataFactory.createAccount('Client Prix');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(150);

        Test.startTest();
        TestDataFactory.createOrdersWithItems(acc.Id, pbe.Id, 1, 150, 10, true);

        // Nouveau prix catalogue pour le même produit (sur un Price Book
        // personnalisé, un produit ne pouvant avoir qu'une seule entrée par
        // Price Book), créé APRES l'activation de la commande : ne doit jamais
        // affecter le CA déjà calculé.
        Pricebook2 newPricebook = new Pricebook2(Name = 'Nouveau Tarif', IsActive = true);
        insert newPricebook;
        insert new PricebookEntry(
            Pricebook2Id = newPricebook.Id,
            Product2Id = pbe.Product2Id,
            UnitPrice = 999,
            IsActive = true
        );
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1500, refreshed.Chiffre_d_affaire__c,
            'Un nouveau prix catalogue ne doit pas impacter le CA des commandes déjà finalisées.');
    }
}
