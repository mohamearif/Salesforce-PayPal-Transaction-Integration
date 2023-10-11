# Salesforce PayPal Transactions Integration

This Package enables the salesforce orgs to be integrated with PayPal Transactions API endpoint 'https://api-m.sandbox.paypal.com/v1/reporting/transactions' asyncournously using Scheduled Queueable Apex. 

Below outlines the steps for integrating PayPal Transactions into Salesforce Object: PayPal_Transaction__c, while providing options to create Accounts and Contacts and associating them with the PayPal_Transaction__c records (Custom Metadate controlled: Salesforce_PayPal_Transaction_Settings.ExcludeAccountContact). Then PayPal_Transaction__c records could be used to trigger/flow data into your object/custom logic based on your unique need.

## IMPORTANT NOTES

1. Please update the namedCredential 'PayPal_Named_Credential' with YOUR_PAYPAL_ACCOUNT_CLIENT_ID and YOUR_PAYPAL_ACCOUNT_CLIENT_SECRET from your paypal sandbox

2. After successfull testing with PayPal/Salesforce Sandbox, while moving forward production please update the endpoint url to Production PayPay URL: https://api-m.paypal.com on NamedCredential 'PayPal_Named_Credential' and also update the PayPal_Named_Credential with PayPal Production ClientId and Client Secret.

## Helpful Tips and Considerations

1. **Account Deduplication:** Account records are matched and deduplicated based on the address on the PayPal transaction.

2. **Contact Deduplication:** Contacts are matched and deduplicated based on the FirstName, LastName, and Email.

3. **Data Retrieval:** The PayPalDataScheduler needs to be scheduled to retrieve the records from the previous day, starting at 12 AM and ending at 11:59 PM.

4. **Customization:** All of the above logic is implemented in the Apex classes PayPalDataExportQueueable, PayPalDataProcessorQueueable & PayPalDataScheduler can be modified to suit your specific requirements.

## Getting Started

### Step 1: Clone the Project and Open in Visual Studio Code

Begin by cloning this project and opening the project directory in Visual Studio Code (VSCODE).

```shell
git clone https://github.com/mohamearif/Salesforce-PayPal-Transaction-Integration.git
cd <project-directory>
```

### Step 2: Enable Custom Address Field in Salesforce Org

Before deploying the integration, ensure that you have enabled the custom address field in your Salesforce org as a pre-deployment step.

1. Navigate to `Setup > User Interface`.
2. Check the checkbox next to "Use custom address fields."

### Step 3: Deploy the Integration

Deploy the PayPal Transaction Integration using the provided `package.xml` file in the manifest folder of this project. Make sure to run the test classes to ensure everything works correctly before deploying it to your production environment.

```shell
sfdx force:source:deploy --manifest manifest/package.xml -l RunSpecifiedTests -r PayPalDataExportQueueableTest PayPalDataProcessorQueueableTest PayPalDataSchedulerTest PayPalTransactionDataTest
```
### Step 4: Schedule the Data Retrieval

After deploying the integration, run the post-deployment script to schedule the PayPalDataScheduler Apex Class to run automatically every day at 3 AM. Please take a look at the PostDeploymentScript apex script and update according to your need.

```shell
sfdx force:apex:execute -f scripts/apex/PostDeploymentScript.apex
```

This step ensures that the data retrieval process is automated, and your integration will consistently update your Salesforce instance with PayPal Transactions. 

### Step 5: Named Credential Update

Update the namedCredential 'PayPal_Named_Credential' with YOUR_PAYPAL_ACCOUNT_CLIENT_ID and YOUR_PAYPAL_ACCOUNT_CLIENT_SECRET from your paypal sandbox. Please make sure on PayPal REST API App that it has access to Transactions.

If you encounter any issues or have specific customization requirements, refer to the PayPalDataProcessorQueueable, PayPalDataScheduler & PayPalDataExportQueueable Apex classes for further adjustments.

### Step 6: Permission and Configuration

1. Assign the 'PayPal_Data_Permissions' permission set to the user who needs to access the PayPal_Transaction__c tab/records.
2. Visit manage records on custom metadata type 'Salesforce_PayPal_Transaction_Settings__mdt' to customize few of the settings such as 

    a. AccountRecordTypeDeveloperName - To set a specific Account Record Type while the Account records are created while exporting PayPal Transactions to Salesforce.

    b. ContactRecordTypeDeveloperName - To set a specific Contact Record Type while the Contact records are created while exporting PayPal Transactions to Salesforce.

    c. ExcludeAccountContact - Avoid creating accounts and contacts while exporting PayPal Transactions to Salesforce.

    d. PageSize - Setting the PageSize of the export per API call on the Queueable Apex.
