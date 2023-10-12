//***************************************************************************************************************/
// THIS IS A SCRIPT THAT HELPS YOU INITIALLY PULL ALL OF YOUR PAST TRANSACTIONS FROM.
// SET startDate and endDate according to your need.
// PLEASE NOTE THAT THIS SCRIPT WILL CHAIN MANY QUEUEABLE APEX TO EXPORT YOUR DATA, NUMBER OF QUEUEABLE CHAINED IS DETERMINED BASED ON THE STARTDATE AND ENDDATE
// RUNNING CHAIN CAN BE KILLED AT ANY MOMENT BY SETTING THIS CUSTOM METADATA: Salesforce_PayPal_Transaction_Settings.KillCurrentDataMigrationFailSafe TO true
// RUN  sfdx force:apex:execute -f scripts/apex/ExistingDataExportToSalesforce.apex
// THEN GO TO SETUP > APEX JOBS, AND MAKE SURE ALL THE JOBS ARE COMPLETE IF NOT LOOK AT THE LOGS TO MODIFY THE BELOW DATES ACCORDINGLY AND RUN AGAIN
//***************************************************************************************************************/

Datetime startDate = Date.newInstance(2020, 10, 01).addDays(1); //Specify the startDate to indicate the date from which you wish to begin migrating your PayPal transactions into Salesforce.
Datetime endDate = Date.newInstance(2023, 10, 31).addDays(1); //Specify the endDate to indicate the date at which you want to conclude the migration of your PayPal transactions to Salesforce.
System.enqueueJob(new PayPalDataExportQueueable(true, startDate, endDate, 1, 200, false));