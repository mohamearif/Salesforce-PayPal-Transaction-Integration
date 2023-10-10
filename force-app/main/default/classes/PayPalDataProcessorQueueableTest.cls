@isTest
public with sharing class PayPalDataProcessorQueueableTest {
    @isTest
    static void testQueueableJob() {
        test.startTest();
        // Set up test data or configuration as needed
        String payPalTransactionDataString = [SELECT Body FROM StaticResource WHERE Name = 'Paypal_Transaction_Data' ].Body.toString();
        PayPalTransactionData transactionData = (PayPalTransactionData)JSON.deserialize(payPalTransactionDataString, PayPalTransactionData.class);
        transactionData.excludeAccountContactProcessing = false;
        // Enqueue the queueable job
        System.enqueueJob(new PayPalDataProcessorQueueable(transactionData));
        test.stopTest();
        System.assertEquals(4, [SELECT Id FROM Account].size(), 'Four Account should exist');
        System.assertEquals(2, [SELECT Id FROM Contact].size(), 'Two Contact should exist');
        System.assertEquals(7, [SELECT Id FROM PayPal_Transaction__c].size(), 'Seven PayPal Transaction should exist');
        //Intentional duplication
        System.enqueueJob(new PayPalDataProcessorQueueable(transactionData));
        System.assertEquals(4, [SELECT Id FROM Account].size(), 'Four Account should exist');
        System.assertEquals(2, [SELECT Id FROM Contact].size(), 'Two Contact should exist');
        System.assertEquals(7, [SELECT Id FROM PayPal_Transaction__c].size(), 'Seven PayPal Transaction should exist');
    }
}