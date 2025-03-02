public with sharing class TransporterSelector {
        public static List<Delivery_Rate__c> getDeliveryRatesWithTransporterIds(Set<String> countries) {
            if (countries.isEmpty()) {
                return new List<Delivery_Rate__c>();
            }
            return [
                SELECT Transporter__c, Price__c, Delivery_time__c, Country__c
                FROM Delivery_Rate__c
                WHERE Country__c IN :countries
            ];
        }
}