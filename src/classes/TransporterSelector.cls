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
}