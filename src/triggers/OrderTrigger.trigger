/**
 * Trigger for the Order object
 * Executes on before insert and before update events
 */
trigger OrderTrigger on Order (before insert, before update) {
    // Validate orders based on business rules (e.g., minimum product requirements)
    OrderService.validateOrders(Trigger.new);
    
    // Assign the most appropriate transporter based on delivery method selected
    // (Faster, Cheaper, or Personalize)
    OrderService.assignBestTransporter(Trigger.new); 
}