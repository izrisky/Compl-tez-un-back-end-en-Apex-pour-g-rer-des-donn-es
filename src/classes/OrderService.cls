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
        // Collect unique countries and filter for supported delivery methods
        Set<String> countries = new Set<String>();
        Set<String> deliveryMethods = new Set<String>{'Faster', 'Cheaper'};
        
        for (Order ord : orders) {
            if (ord.ShippingCountry != null && ord.Delivery_Method__c != null 
                && deliveryMethods.contains(ord.Delivery_Method__c)) {
                countries.add(ord.ShippingCountry);
            }
        }
        
        if (countries.isEmpty()) {
            return; // No applicable orders to process
        }
        
        // Retrieve delivery rates with transporters
        List<Delivery_Rate__c> deliveryRates = TransporterSelector.getDeliveryRatesWithTransporterIds(countries);
        
        // Group rates by country for efficient lookup
        Map<String, List<Delivery_Rate__c>> deliveryRatesMap = new Map<String, List<Delivery_Rate__c>>();
        for (Delivery_Rate__c rate : deliveryRates) {
            if (!deliveryRatesMap.containsKey(rate.Country__c)) {
                deliveryRatesMap.put(rate.Country__c, new List<Delivery_Rate__c>());
            }
            deliveryRatesMap.get(rate.Country__c).add(rate);
        }

        // Assign transporters to each order
        for (Order ord : orders) {
            if (ord.ShippingCountry == null || ord.Delivery_Method__c == null 
                || !deliveryMethods.contains(ord.Delivery_Method__c)) {
                continue; // Skip orders with missing info or unsupported delivery method
            }
            
            String country = ord.ShippingCountry;
            List<Delivery_Rate__c> availableRates = deliveryRatesMap.get(country);

            // Error handling for countries without delivery service
            if (availableRates == null || availableRates.isEmpty()) {
                ord.addError('No delivery service available for the country: ' + country);
                continue;
            }
            
            // Sort transporters by price and delivery time according to delivery method
            availableRates.sort(new PriceAndTimeComparator(ord.Delivery_Method__c));
            
            // Assign best transporter to order
            Delivery_Rate__c bestRate = availableRates[0];
            ord.Transporter__c = bestRate.Transporter__c;
        }
    }

    /**
     * Inner class to compare delivery rates based on price and time
     * Implements different sorting strategies based on delivery method
     */
    public class PriceAndTimeComparator implements Comparator<Delivery_Rate__c> {
        private String deliveryMethod;
        
        /**
         * Constructor
         * @param deliveryMethod The delivery method preference (Faster or Cheaper)
         */
        public PriceAndTimeComparator(String deliveryMethod) {
            this.deliveryMethod = deliveryMethod;  
        }
        
        /**
         * Compares two delivery rates based on the specified delivery method
         * @param a First delivery rate to compare
         * @param b Second delivery rate to compare
         * @return -1 if a < b, 1 if a > b, 0 if equal
         */
        public Integer compare(Delivery_Rate__c a, Delivery_Rate__c b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;

            switch on deliveryMethod {
                when 'Faster' {     
                    // Prioritize delivery time, then price if times are equal
                    if (a.Delivery_time__c < b.Delivery_time__c) return -1;
                    if (a.Delivery_time__c > b.Delivery_time__c) return 1;
                    if (a.Price__c < b.Price__c) return -1;
                    if (a.Price__c > b.Price__c) return 1;
                }   
                when 'Cheaper' {    
                    // Prioritize price, then delivery time if prices are equal
                    if (a.Price__c < b.Price__c) return -1;
                    if (a.Price__c > b.Price__c) return 1;
                    if (a.Delivery_time__c < b.Delivery_time__c) return -1;
                    if (a.Delivery_time__c > b.Delivery_time__c) return 1;
                }
                when else {         
                    return 0;
                }
            }
            return 0; // If all criteria are equal
        }
    }
}