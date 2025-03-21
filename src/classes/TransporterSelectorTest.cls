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
private class TransporterSelectorTest {

    @testSetup
    static void setupTestData() {
          // Créer d'abord les transporteurs
    List<Transporter__c> transporters = new List<Transporter__c>{
        new Transporter__c(Name = 'Fast Delivery'),
        new Transporter__c(Name = 'Budget Delivery'),
        new Transporter__c(Name = 'Euro Express')
    };
    
    insert transporters;
  // Puis créer les tarifs avec références aux transporteurs
    List<Delivery_Rate__c> deliveryRates = new List<Delivery_Rate__c>{
            new Delivery_Rate__c(
                Country__c = 'France',
                Transporter__c = transporters[0].Id, // Fast Delivery
                Price__c = 15,
                Delivery_time__c = 2
            ),
            new Delivery_Rate__c(
                Country__c = 'France',
                Transporter__c = transporters[1].Id, // Budget Delivery
                Price__c = 8,
                Delivery_time__c = 5
            ),
            new Delivery_Rate__c(
                Country__c = 'France',
                Transporter__c = transporters[2].Id, // Euro Express
                Price__c = 12,
                Delivery_time__c = 3
            ),
            new Delivery_Rate__c(
                Country__c = 'Luxembourg',
                Transporter__c = transporters[2].Id, // Euro Express
                Price__c = 12,
                Delivery_time__c = 5
            )
    };

    insert deliveryRates;
    }
    @isTest
    static void testGetCheapestTransporter() {
        Test.startTest();
         Delivery_Rate__c  bestRate= TransporterSelector.getCheapestTransporter('France');
        Test.stopTest();
        System.assertEquals('Budget Delivery', bestRate.Transporter__r.Name, 'Should be Budget Delivery');
    }
    
    
    @isTest
    static void testGetFastestTransporter() {
        Test.startTest();
         Delivery_Rate__c  bestRate= TransporterSelector.getFastestTransporter('France');
        Test.stopTest();

        System.assertEquals('Fast Delivery', bestRate.Transporter__r.Name, 'Should be Fast Delivery');
    }

    @isTest
    static void testGetDeliverTransporter_Success() {
        // Récupérer un transporteur existant de 'Fast Delivery'
        Transporter__c fastDelivery = [SELECT Id FROM Transporter__c WHERE Name = 'Fast Delivery' LIMIT 1];

        // Création d'une commande avec un transporteur et un pays correspondant
        Order order = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ShippingCountry = 'France',
            Transporter__c = fastDelivery.Id
        );
        
        // Exécution de la méthode testée
        Test.startTest();
        Delivery_Rate__c result = TransporterSelector.getDeliverTransporter(order);
        Test.stopTest();

        // Vérification des résultats
        System.assertNotEquals(result, null, 'A delivery rate should be returned.');
        System.assertEquals(result.Price__c, 15, 'The price should match the inserted data.');
        System.assertEquals(result.Delivery_time__c, 2, 'The delivery time should match.');
    }

}