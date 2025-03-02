/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class OrderServiceTest {
    @testSetup
    static void setupTestData() {
        // Création des comptes de test
        Account individualAccount = new Account(
            Name = 'Test Individual',
            Type = 'Particulier'
        );
        
        Account businessAccount = new Account(
            Name = 'Test Business',
            Type = 'Professionnel'
        );
        
        insert new List<Account>{individualAccount, businessAccount};
        

// Dans setupTestData()
// Créer les transporteurs
List<Transporter__c> transporters = new List<Transporter__c>{
    new Transporter__c(Name = 'Fast Delivery', Type__c = 'Particulier'),
    new Transporter__c(Name = 'Budget Delivery', Type__c = 'Particulier'),
    new Transporter__c(Name = 'Euro Express', Type__c = 'Professionnel')
};
insert transporters;

// Puis utilisez leurs IDs
List<Delivery_Rate__c> deliveryRates = new List<Delivery_Rate__c>{
            new Delivery_Rate__c(
                Country__c = 'France',
                Transporter__c = transporters[0].Id,
                Price__c = 15,
                Delivery_time__c = 2
            ),
            new Delivery_Rate__c(
                Country__c = 'France',
                Transporter__c = transporters[1].Id,
                Price__c = 8,
                Delivery_time__c = 5
            ),
            new Delivery_Rate__c(
                Country__c = 'Suisse',
                Transporter__c = transporters[2].Id,
                Price__c = 12,
                Delivery_time__c = 3
            )
        };
        
        insert deliveryRates;
    }
    
@isTest
static void testValidateOrdersIndividualSuccess() {
    // Retrieve individual account
    Account individualAccount = [SELECT Id FROM Account WHERE Name = 'Test Individual' LIMIT 1];
    
    // Create a price book and entry for testing
    Id standardPriceBookId = Test.getStandardPricebookId();
    // Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
    // insert testProduct;
    
    List<Product2> testProducts = new List<Product2>{
        new Product2(Name = 'Test Product1', IsActive = true),
        new Product2(Name = 'Test Product2', IsActive = true),
        new Product2(Name = 'Test Product3', IsActive = true),
        new Product2(Name = 'Test Product4', IsActive = true),
        new Product2(Name = 'Test Product5', IsActive = true)};
    insert testProducts;

    List<PricebookEntry> standardPrices = new List<PricebookEntry>{
        new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProducts[0].Id,
            UnitPrice = 100,
            IsActive = true
        ),
        new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProducts[1].Id,
            UnitPrice = 100,
            IsActive = true
        ),
        new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProducts[2].Id,
            UnitPrice = 100,
            IsActive = true
        ),
        new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProducts[3].Id,
            UnitPrice = 100,
            IsActive = true
        ),
        new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProducts[4].Id,
            UnitPrice = 100,
            IsActive = true
        )
    };
    insert standardPrices;
    // Create an order
    Order order = new Order(
        AccountId = individualAccount.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = standardPriceBookId
    );
    insert order;
    
    // Create just 2 order items (below the required minimum of 3)
    List<OrderItem> orderItems = new List<OrderItem>();
    for(Integer i = 0; i < 3; i++) {
        orderItems.add(new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = standardPrices[i].Id,
            Quantity = 1,
            UnitPrice = 100
        ));
    }
    insert orderItems;
    
    // Try to activate the order
    order.Status = 'Activated';
        
        // La mise à jour devrait réussir
        Test.startTest();
        update order;
        Test.stopTest();
        
        // Vérifier que la commande a été mise à jour
        order = [SELECT Status FROM Order WHERE Id = :order.Id];
        System.assertEquals('Activated', order.Status, 'Order should be activated');
}
@isTest
static void testValidateOrdersIndividualFail() {
    // Retrieve individual account
    Account individualAccount = [SELECT Id FROM Account WHERE Name = 'Test Individual' LIMIT 1];
    
    // Create a price book and entry for testing
    Id standardPriceBookId = Test.getStandardPricebookId();
    Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
    insert testProduct;
    
    PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = standardPriceBookId,
        Product2Id = testProduct.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert standardPrice;
    
    // Create an order
    Order order = new Order(
        AccountId = individualAccount.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = standardPriceBookId
    );
    insert order;
    
    // Create just 2 order items (below the required minimum of 3)
    List<OrderItem> orderItems = new List<OrderItem>();
    for(Integer i = 0; i < 2; i++) {
        orderItems.add(new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = standardPrice.Id,
            Quantity = 1,
            UnitPrice = 100
        ));
    }
    insert orderItems;
    
    // Try to activate the order
    order.Status = 'Activated';
    
    // The update should fail
    Test.startTest();
    try {
        update order;
        System.assert(false, 'Update should have failed');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('Individual customers must order at least 3 products'),
                    'Exception message should mention minimum product requirement');
    }
    Test.stopTest();
}
@isTest
static void testAssignBestTransporterFaster() {
    // Récupérer le compte
    Account account = [SELECT Id FROM Account WHERE Name = 'Test Individual' LIMIT 1];
    
    // Récupérer l'ID du transporteur Fast Delivery
    Transporter__c fastTransporter = [SELECT Id FROM Transporter__c WHERE Name = 'Fast Delivery' LIMIT 1];
    
    // Créer une commande avec méthode de livraison rapide
    Order order = new Order(
        AccountId = account.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        ShippingCountry = 'France',
        Delivery_Method__c = 'Faster'
    );
    
    // La méthode assignBestTransporter devrait s'exécuter à l'insertion
    Test.startTest();
    insert order;
    Test.stopTest();
    
    // Vérifier que le transporteur rapide a été sélectionné
    order = [SELECT Transporter__c FROM Order WHERE Id = :order.Id];
    System.assertEquals(fastTransporter.Id, order.Transporter__c, 'Fastest transporter should have been selected');
}
@isTest
static void testAssignBestTransporterCheaper() {
    // Récupérer le compte
    Account account = [SELECT Id FROM Account WHERE Name = 'Test Individual' LIMIT 1];
    
    // Récupérer l'ID du transporteur Budget Delivery
    Transporter__c budgetTransporter = [SELECT Id FROM Transporter__c WHERE Name = 'Budget Delivery' LIMIT 1];
    
    // Créer une commande avec méthode de livraison économique
    Order order = new Order(
        AccountId = account.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        ShippingCountry = 'France',
        Delivery_Method__c = 'Cheaper'
    );
    
    Test.startTest();
    insert order;
    Test.stopTest();
    
    order = [SELECT Transporter__c FROM Order WHERE Id = :order.Id];
    System.assertEquals(budgetTransporter.Id, order.Transporter__c, 'Cheapest transporter should have been selected');
}
    
    @isTest
    static void testAssignBestTransporterNoDeliveryService() {
        // Récupérer le compte
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Individual' LIMIT 1];
        
        // Créer une commande pour un pays sans service de livraison
        Order order = new Order(
            AccountId = account.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ShippingCountry = 'Spain', // Aucun tarif pour l'Espagne
            Delivery_Method__c = 'Faster'
        );
        
        // La méthode devrait déclencher une erreur
        Test.startTest();
        try {
            insert order;
            System.assert(false, 'Insert should have failed');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No delivery service available'), 
                        'Exception should indicate no delivery service');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testPriceAndTimeComparator() {
        // Création de tarifs de test
        Delivery_Rate__c rate1 = new Delivery_Rate__c(Price__c = 10, Delivery_time__c = 3);
        Delivery_Rate__c rate2 = new Delivery_Rate__c(Price__c = 8, Delivery_time__c = 5);
        Delivery_Rate__c rate3 = new Delivery_Rate__c(Price__c = 10, Delivery_time__c = 2);
        
        // Test du comparateur en mode "Faster"
        OrderService.PriceAndTimeComparator fasterComp = 
            new OrderService.PriceAndTimeComparator('Faster');
        
        System.assertEquals(-1, fasterComp.compare(rate3, rate1), 
                          'Rate3 should come before Rate1 (faster delivery)');
        System.assertEquals(-1, fasterComp.compare(rate1, rate2), 
                          'Rate1 should come before Rate2 (faster delivery)');
        
        // Test du comparateur en mode "Cheaper"
        OrderService.PriceAndTimeComparator cheaperComp = 
            new OrderService.PriceAndTimeComparator('Cheaper');
        
        System.assertEquals(1, cheaperComp.compare(rate1, rate2), 
                          'Rate1 should come after Rate2 (higher price)');
        System.assertEquals(-1, cheaperComp.compare(rate2, rate1), 
                          'Rate2 should come before Rate1 (lower price)');
        System.assertEquals(-1, cheaperComp.compare(rate3, rate1), 
                          'Rate3 should come before Rate1 (same price, faster delivery)');
    }
}