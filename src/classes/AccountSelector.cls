/**
 * Selector class for Account object providing query methods
 * Uses with sharing to respect record visibility rules
 */
public with sharing class AccountSelector {
    /**
     * Retrieves Account records by their IDs
     * @param accountIds Set of Account IDs to query
     * @return Map of Account IDs to Account records with Type field
     */
    public static Map<Id, Account> getAccountsByIds(Set<Id> accountIds) {
        // Return empty map if no IDs provided
        if (accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }
        // Query accounts with the provided IDs and return as a map
        return new Map<Id, Account>([SELECT Id, Type FROM Account WHERE Id IN :accountIds]);
    }
}