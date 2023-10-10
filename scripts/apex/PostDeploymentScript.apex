// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

List<AsyncApexJob> EveryDay3AMJob = new List<AsyncApexJob>();
EveryDay3AMJob = [SELECT Id, Status, ApexClass.Name, JobType, CronTrigger.CronJobDetail.Name FROM AsyncApexJob WHERE JOBTYPE = 'ScheduledApex' and ApexClass.Name = 'PayPalDataScheduler' and CronTrigger.CronJobDetail.Name = 'PayPalDataScheduler - Everyday 3AM'];
if (EveryDay3AMJob.isEmpty()) {
    String everyDayAt3AM = '0 00 03 ? * 2';  //Every Monday, 5AM
    PayPalDataScheduler pds = new PayPalDataScheduler(); 
    System.schedule('PayPalDataScheduler - Everyday 3AM', everyDayAt3AM, pds);
}