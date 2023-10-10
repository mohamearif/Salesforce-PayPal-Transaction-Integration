global with sharing class PayPalDataScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        String startDateStr = Datetime.now().addDays(-1).format('yyyy-MM-dd');
        startDateStr += 'T00:00:00.000Z';
        String endDateStr = Datetime.now().format('yyyy-MM-dd');
        endDateStr += 'T23:59:59.999Z';
        System.enqueueJob(new PayPalDataExportQueueable(
            startDateStr, endDateStr, 1, 
            Integer.valueOf(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('PageSize').Value__c), 
            Boolean.valueOf(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('ExcludeAccountContact').Value__c)
        ));
    }
}