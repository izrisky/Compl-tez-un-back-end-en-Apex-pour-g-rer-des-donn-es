public with sharing class TransporterSelector {
    // Trouver le transporteur le moins cher
    public static Delivery_Rate__c getCheapestTransporter(String country) {
        return [SELECT Id, Transporter__c, Transporter__r.Name,Price__c, Delivery_time__c 
                FROM Delivery_Rate__c 
                WHERE Country__c = :country 
                ORDER BY Price__c ASC 
                LIMIT 1];
    }
        // Trouver le transporteur le moins cher
    public static Delivery_Rate__c getFastestTransporter(String country) {
        return [SELECT Id, Transporter__c, Transporter__r.Name,Price__c, Delivery_time__c 
                FROM Delivery_Rate__c 
                WHERE Country__c = :country 
                ORDER BY Delivery_time__c ASC 
                LIMIT 1];
    }
    
    public static Delivery_Rate__c getDeliverTransporter(Order order) {
        try {
            // Exécution de la requête SOQL
            return [SELECT Id, Transporter__c, Transporter__r.Name, Price__c, Delivery_time__c 
                    FROM Delivery_Rate__c 
                    WHERE Country__c = :order.ShippingCountry AND Transporter__c = :order.Transporter__c
                    ORDER BY Delivery_time__c ASC 
                    LIMIT 1];
        } catch (QueryException e) {
            System.debug('No delivery rate found for the specified criteria: ' + e.getMessage());
            return null; // Ou lever une erreur personnalisée si nécessaire
        }
    }
}