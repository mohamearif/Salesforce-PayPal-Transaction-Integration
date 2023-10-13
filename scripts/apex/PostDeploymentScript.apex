// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

//Adding Scheduled job
List<AsyncApexJob> EveryDay3AMJob = new List<AsyncApexJob>();
EveryDay3AMJob = [SELECT Id, Status, ApexClass.Name, JobType, CronTrigger.CronJobDetail.Name FROM AsyncApexJob WHERE JOBTYPE = 'ScheduledApex' and ApexClass.Name = 'PayPalDataScheduler' and CronTrigger.CronJobDetail.Name = 'PayPalDataScheduler - Everyday 3AM'];
if (EveryDay3AMJob.isEmpty()) {
    String everyDayAt3AM = '0 0 3 * * ?';  //Everyday at 3AM
    PayPalDataScheduler pds = new PayPalDataScheduler(); 
    System.schedule('PayPalDataScheduler - Everyday 3AM', everyDayAt3AM, pds);
}

//Adding Permission Set 'PayPal_Data_Permissions' for all system adminstrator users
String permissionSetName = 'PayPal_Data_Permissions';
Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1].Id;
List<User> sysAdminUsers = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' and Id NOT IN (Select AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :permissionSetId)];
List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
for (User user : sysAdminUsers) {
    PermissionSetAssignment assignment = new PermissionSetAssignment();
    assignment.PermissionSetId = permissionSetId;
    assignment.AssigneeId = user.Id;
    assignmentsToInsert.add(assignment);
}
if (!assignmentsToInsert.isEmpty()) {
    insert assignmentsToInsert;
}