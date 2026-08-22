/**
 * Classe utilitaire pour la création de données de test réutilisables
 * (comptes, produits, commandes) dans les classes de test Apex du projet.
 * Centraliser la création de données évite la duplication de code entre
 * les classes de test et facilite l'écriture de nouveaux scénarios.
 */
@isTest
public class TestDataFactory {

    /**
     * Crée un compte de test minimal, prêt à recevoir des commandes.
     */
    public static Account createAccount(String accountName) {
        Account acc = new Account(Name = accountName);
        insert acc;
        return acc;
    }

    /**
     * Crée un produit de test et son entrée dans le Price Book standard, au
     * prix unitaire demandé. Nécessaire pour pouvoir créer des OrderItem
     * (une commande ne peut pas avoir de ligne sans PricebookEntry associée).
     */
    public static PricebookEntry createStandardPricebookEntry(Decimal unitPrice) {
        Product2 product = new Product2(Name = 'Chemise Verte longue XYX', Family = 'Chemise');
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    /**
     * Crée `numberOfOrders` commandes pour un compte donné, chacune avec une
     * ligne de commande (Quantity x UnitPrice), et les active si demandé.
     * Permet notamment de simuler des lots de plus de 100 commandes pour
     * les tests de non-régression sur la bulkification.
     */
    public static List<Order> createOrdersWithItems(
        Id accountId,
        Id pricebookEntryId,
        Integer numberOfOrders,
        Decimal unitPrice,
        Integer quantity,
        Boolean shouldActivate
    ) {
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < numberOfOrders; i++) {
            orders.add(new Order(
                AccountId = accountId,
                Pricebook2Id = Test.getStandardPricebookId(),
                Status = 'Draft',
                EffectiveDate = Date.today()
            ));
        }
        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        for (Order o : orders) {
            items.add(new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = pricebookEntryId,
                Quantity = quantity,
                UnitPrice = unitPrice
            ));
        }
        insert items;

        if (shouldActivate) {
            for (Order o : orders) {
                o.Status = 'Activated';
            }
            update orders;
        }

        return orders;
    }
}
