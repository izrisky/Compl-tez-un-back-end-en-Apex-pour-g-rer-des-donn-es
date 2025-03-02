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
private class AccountSelectorTest {
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
    }
    @isTest
    static void testGetAccountsByIds() {
        // Récupérer les comptes créés
        List<Account> accounts = [SELECT Id FROM Account];
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        Map<Id, Account> accountMap = AccountSelector.getAccountsByIds(accountIds);
        Test.stopTest();
        
        System.assertEquals(2, accountMap.size(), 'Should return 2 accounts');
        System.assert(accountMap.containsKey(accounts[0].Id), 'First account should be in map');
        System.assert(accountMap.containsKey(accounts[1].Id), 'Second account should be in map');
    }
    
    @isTest
    static void testGetAccountsByIdsEmpty() {
        Test.startTest();
        Map<Id, Account> accountMap = AccountSelector.getAccountsByIds(new Set<Id>());
        Test.stopTest();
        
        System.assertEquals(0, accountMap.size(), 'Should return empty map for empty input');
    }
    
}