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
        // // Création des comptes de test
        // Account individualAccount = new Account(
        //     Name = 'Test Individual',
        //     Type = 'Particulier'
        // );
        
        // Account businessAccount = new Account(
        //     Name = 'Test Business',
        //     Type = 'Professionnel'
        // );
        
        // insert new List<Account>{individualAccount, businessAccount};
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
                Country__c = 'Suisse',
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
    static void testGetDeliveryRatesByCountries() {
        Set<String> countries = new Set<String>{'France', 'Suisse'};
        
        Test.startTest();
        List<Delivery_Rate__c> rates = TransporterSelector.getDeliveryRatesWithTransporterIds(countries);
        Test.stopTest();
        
        System.assertEquals(3, rates.size(), 'Should return 3 delivery rates');
        
        // Vérifier que les deux pays sont représentés
        Set<String> returnedCountries = new Set<String>();
        for(Delivery_Rate__c rate : rates) {
           if(!returnedCountries.contains(rate.Country__c)) returnedCountries.add(rate.Country__c);
        }
        System.assertEquals(2, returnedCountries.size(), 'Should return rates for both countries');
        System.assert(returnedCountries.contains('France'), 'Should include France');
        System.assert(returnedCountries.contains('Suisse'), 'Should include Suisse');
    }
    
    @isTest
    static void testGetDeliveryRatesByCountriesEmpty() {
        Test.startTest();
        List<Delivery_Rate__c> rates = TransporterSelector.getDeliveryRatesWithTransporterIds(new Set<String>());
        Test.stopTest();
        
        System.assertEquals(0, rates.size(), 'Should return empty list for empty input');
    }
}