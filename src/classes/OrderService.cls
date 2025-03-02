/**
 * Service class for Order object business logic
 * Handles validation rules and transporter assignment
 */
public with sharing class OrderService {
    /**
     * Validates orders against business rules before insert/update
     * Enforces minimum product requirements based on account type
     * @param orders List of Order records to validate
     */
    public static void validateOrders(List<Order> orders) {
        // Collect Account IDs from orders for efficient querying
        Set<Id> accountIds = new Set<Id>();
        for (Order ord : orders) {
            if (ord.AccountId != null) {
                accountIds.add(ord.AccountId);
            }
        }

        // Retrieve accounts using selector pattern to maintain separation of concerns
        Map<Id, Account> accountMap = AccountSelector.getAccountsByIds(accountIds);

        // Validate each order against business rules
        for (Order ord : orders) {
            if (ord.AccountId != null) {
                Account acc = accountMap.get(ord.AccountId);
                if (acc != null && ord.Status == 'Activated') {
                    // Different product count requirements based on account type
                    if (acc.Type == 'Particulier' && ord.ProductsCount__c < 3) {
                        ord.addError('Individual customers must order at least 3 products.');
                    } else if (acc.Type == 'Professionnel' && ord.ProductsCount__c < 5) {
                        ord.addError('Business customers must order at least 5 products.');
                    }
                }
            }
        }
    }

    /**
     * Assigns the best transporter to orders based on delivery method preference
     * Determines optimal transporter based on shipping country, price, and delivery time
     * @param orders List of Order records requiring transporter assignment
     */
    public static void assignBestTransporter(List<Order> orders) {
        // Assign transporters to each order
        Delivery_Rate__c bestRate=null;
        for (Order ord : orders) {
            String country = ord.ShippingCountry;
            if (country == null || ord.Delivery_Method__c == null ||ord.Delivery_Method__c == 'Personalized') {
                continue; // Skip orders with missing info or unsupported delivery method
            }
            if (ord.Delivery_Method__c == 'Cheaper')
            {
                bestRate = TransporterSelector.getCheapestTransporter(country);
            }
            if (ord.Delivery_Method__c == 'Faster')
            {
                bestRate = TransporterSelector.getFastestTransporter(country);
            }
            if (bestRate == null) {
                ord.addError('No delivery service available for the country: ' + country);
                continue;
            }
            ord.Transporter__c = bestRate.Transporter__c;
        }
    }
}