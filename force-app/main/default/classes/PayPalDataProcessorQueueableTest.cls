@isTest
public with sharing class PayPalDataProcessorQueueableTest {

    static user adminUser(){
        String permissionSetName = 'PayPal_Data_Permissions';
        User activeSystemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = True LIMIT 1];
        List<PermissionSetAssignment> psaCheck = new List<PermissionSetAssignment>();
        psaCheck = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = :permissionSetName AND AssigneeId = :activeSystemAdmin.Id];
        if (psaCheck.isEmpty()) {
            PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName];
            PermissionSetAssignment psAssignment = new PermissionSetAssignment(
                PermissionSetId = permissionSet.Id,
                AssigneeId = activeSystemAdmin.Id
            );
            insert psAssignment;
        }
        return activeSystemAdmin;
    }

    @isTest
    static void testQueueableJob() {
        System.runAs(adminUser()) {
            test.startTest();
            // Set up test data or configuration as needed
            String payPalTransactionDataString = [SELECT Body FROM StaticResource WHERE Name = 'Paypal_Transaction_Data' ].Body.toString();
            PayPalTransactionData transactionData = (PayPalTransactionData)JSON.deserialize(payPalTransactionDataString, PayPalTransactionData.class);
            transactionData.excludeAccountContactProcessing = false;
            transactionData.dataMigrationMode = false;
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
            //multi page - dataMigrationMode
            transactionData.excludeAccountContactProcessing = false;
            transactionData.total_pages = 2;
            transactionData.dataMigrationMode = true;
            System.enqueueJob(new PayPalDataProcessorQueueable(transactionData));
            System.assertEquals(4, [SELECT Id FROM Account].size(), 'Four Account should exist');
            System.assertEquals(2, [SELECT Id FROM Contact].size(), 'Two Contact should exist');
            System.assertEquals(7, [SELECT Id FROM PayPal_Transaction__c].size(), 'Seven PayPal Transaction should exist');
            //multi page - dataMigrationMode reset
            transactionData.excludeAccountContactProcessing = false;
            transactionData.total_pages = 2;
            transactionData.dataMigrationMode = false;
            System.enqueueJob(new PayPalDataProcessorQueueable(transactionData));
            System.assertEquals(4, [SELECT Id FROM Account].size(), 'Four Account should exist');
            System.assertEquals(2, [SELECT Id FROM Contact].size(), 'Two Contact should exist');
            System.assertEquals(7, [SELECT Id FROM PayPal_Transaction__c].size(), 'Seven PayPal Transaction should exist');
        }
    }
    @isTest
    static void testQueueableDataMigrationJob() {
        System.runAs(adminUser()) {
            test.startTest();
            // Set up test data or configuration as needed
            String payPalTransactionDataString = [SELECT Body FROM StaticResource WHERE Name = 'Paypal_Transaction_Data' ].Body.toString();
            PayPalTransactionData transactionData = (PayPalTransactionData)JSON.deserialize(payPalTransactionDataString, PayPalTransactionData.class);
            transactionData.excludeAccountContactProcessing = false;
            transactionData.dataMigrationMode = true;
            transactionData.sDateTime = Datetime.now().addDays(-32);
            transactionData.eDateTime = Datetime.now().addDays(31);
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
}