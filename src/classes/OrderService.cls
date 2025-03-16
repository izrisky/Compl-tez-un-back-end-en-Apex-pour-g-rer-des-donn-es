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
            // Vérifier la permission une seule fois pour toutes les commandes
    Boolean hasPermission = FeatureManagement.checkPermission('Can_create_order');
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
                    if (!hasPermission) 
                    {
                        ord.addError('Vous n\'avez pas la permission d\'envoyer cette commande.');
                    }else
                    {
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
    }
    
    /**
     * Creates a delivery record for each order
     * @param orders List of Order records
     */
    public static void createDelivery(List<Order> orders, Map<Id, Order> oldOrdersMap) { 
        List<Delivery__c> deliveries = new List<Delivery__c>();
        
        for (Order ord : orders) {
            
                    // Check if the order is new or if the Status field has changed
        if (ord.Status == 'Activated' && ord.Transporter__c != null &&
        (oldOrdersMap == null || !oldOrdersMap.containsKey(ord.Id) || 
         (oldOrdersMap.get(ord.Id) != null && oldOrdersMap.get(ord.Id).Status != ord.Status))) 
             {
                Delivery_Rate__c transporter = TransporterSelector.getDeliverTransporter(ord);   
            if (transporter != null) {
                    deliveries.add(new Delivery__c(
                        Order__c = ord.Id,
                        Delivery_Rate_Info__c = transporter.Id,
                        Statut__c = 'Pending' 
                    ));
                } else {
                    System.debug('No valid transporter found for order Id: ' + ord.Id + ' and country: ' + ord.ShippingCountry);
                }
            }
        }        
        // Log the number of deliveries to insert
        System.debug('Number of deliveries to insert: ' + deliveries.size());
    
        if (!deliveries.isEmpty()) {
            try {
                insert deliveries;
                System.debug('Deliveries inserted successfully.');
            } catch (DmlException e) {
                System.debug('Error inserting Delivery records: ' + e.getMessage());
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug('Record ' + i + ': ' + e.getDmlId(i));
                    System.debug('Errors: ' + e.getDmlMessage(i));
                }
            }
        }
    }

    /**
     * Assigns the best transporter to orders only if the order is newly created
     * or if the Delivery_Method__c field has changed
     * @param newOrders List of new Order records
     * @param oldOrdersMap Map of old Order records before update (can be null for insert operations)
     */
    public static void assignBestTransporter(List<Order> newOrders, Map<Id, Order> oldOrdersMap) {
        List<Order> ordersToUpdate = new List<Order>();
        
        for (Order ord : newOrders) {
            String country = ord.ShippingCountry;
            if (country == null || ord.Delivery_Method__c == null || ord.Delivery_Method__c == 'Personalized') {
                continue;
            }
            
            // Check if it's a new order or if Delivery_Method__c has changed
            if (oldOrdersMap == null || !oldOrdersMap.containsKey(ord.Id) || 
                oldOrdersMap.get(ord.Id).Delivery_Method__c != ord.Delivery_Method__c) {
                
                Delivery_Rate__c bestRate = null;
                if (ord.Delivery_Method__c == 'Cheaper') {
                    bestRate = TransporterSelector.getCheapestTransporter(country);
                } else if (ord.Delivery_Method__c == 'Faster') {
                    bestRate = TransporterSelector.getFastestTransporter(country);
                }
                
                if (bestRate == null) {
                    ord.addError('No delivery service available for the country: ' + country);
                    continue;
                }
                
                ordersToUpdate.add(new Order(Id = ord.Id, Transporter__c = bestRate.Transporter__c));
            }
        }
        
        update ordersToUpdate;
    }
}