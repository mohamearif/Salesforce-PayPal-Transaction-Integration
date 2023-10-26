global class PostInstallClass implements InstallHandler {
    global void onInstall(InstallContext context) {
        //Adding Scheduled job
        List<AsyncApexJob> everyDay3AMJob = new List<AsyncApexJob>();
        everyDay3AMJob = [SELECT Id, Status, ApexClass.Name, JobType, CronTrigger.CronJobDetail.Name FROM AsyncApexJob WHERE JOBTYPE = 'ScheduledApex' and ApexClass.Name = 'PayPalDataScheduler' and CronTrigger.CronJobDetail.Name = 'PayPalDataScheduler - Everyday 3AM'];
        if (everyDay3AMJob.isEmpty()) {
            String everyDayAt3AM = '0 0 3 * * ?';  //Everyday at 3AM
            PayPalDataScheduler pds = new PayPalDataScheduler(); 
            System.schedule('PayPalDataScheduler - Everyday 3AM', everyDayAt3AM, pds);
        }
    }
}