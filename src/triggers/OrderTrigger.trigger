trigger OrderTrigger on Order (before insert, before update, after insert, after update) {
    // Validate orders before they are inserted or updated
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OrderService.validateOrders(Trigger.new);
        }
    }

    // Assign best transporter AFTER insert to ensure Order ID exists
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
          OrderService.assignBestTransporter(Trigger.new, new Map<Id, Order>());
          OrderService.createDelivery(Trigger.new, new Map<Id, Order>());
        } else if (Trigger.isUpdate) {
            OrderService.assignBestTransporter(Trigger.new, Trigger.oldMap);
            OrderService.createDelivery(Trigger.new,Trigger.oldMap);
        }
    }

}
