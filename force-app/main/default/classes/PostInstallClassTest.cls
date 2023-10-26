@isTest
public with sharing class PostInstallClassTest {
    @isTest
    static void testInstallScript() {
        PostInstallClass postinstall = new PostInstallClass();
        Test.testInstall(postinstall, null);
        Test.testInstall(postinstall, new Version(1,0), true);
        List<AsyncApexJob> everyDay3AMJob = new List<AsyncApexJob>();
        everyDay3AMJob = [SELECT Id, Status, ApexClass.Name, JobType, CronTrigger.CronJobDetail.Name FROM AsyncApexJob WHERE JOBTYPE = 'ScheduledApex' and ApexClass.Name = 'PayPalDataScheduler' and CronTrigger.CronJobDetail.Name = 'PayPalDataScheduler - Everyday 3AM'];
        System.assertEquals(everyDay3AMJob.size(), 1, 'Every Day 3AM Job not found');
    }
}