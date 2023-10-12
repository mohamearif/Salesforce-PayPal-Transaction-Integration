# Salesforce PayPal Transactions Integration

This repository provides a lightweight outbound integration from Salesforce to PayPal using Scheduled and Queueable Apex. It asynchronously retrieves transactions from PayPal's Transactions REST API endpoint [here](https://developer.paypal.com/docs/api/transaction-search/v1/#search_get) and pushes them into a Salesforce custom object called 'PayPal_Transaction__c' as records.

In addition, implementing record-based flow or trigger 'PayPal_Transaction__c' will enable you to seamlessly transform the incoming data into your standard/custom object records, allowing you to tailor the integration to meet your specific business requirements.

## Table of Contents

- [Important Notes](#important-notes)
- [Helpful Tips and Considerations](#helpful-tips-and-considerations)
- [Getting Started](#getting-started)
  - [Step 1: Clone the Project and Open in Visual Studio Code](#step-1-clone-the-project-and-open-in-visual-studio-code)
  - [Step 2: Enable Custom Address Field in Salesforce Org](#step-2-enable-custom-address-field-in-salesforce-org)
  - [Step 3: Deploy the Integration](#step-3-deploy-the-integration)
  - [Step 4: Schedule the Data Retrieval](#step-4-schedule-the-data-retrieval)
  - [Step 5: Named Credential Update](#step-5-named-credential-update)
  - [Step 6: Permission and Configuration](#step-6-permission-and-configuration)
  - [Step 7: Existing Data Export (Optional)](#step-7-existing-data-export-optional)

## Important Notes

1. **Update Named Credential**: Update the named credential 'PayPal_Named_Credential' with your PayPal account client ID and client secret from your PayPal sandbox.

2. **Production Environment**: After successful testing in the sandbox, update the endpoint URL to the production PayPal URL ('https://api-m.paypal.com') on the 'PayPal_Named_Credential' and provide your PayPal production client ID and client secret.

## Helpful Tips and Considerations

1. **Account Deduplication**: Account records are matched and deduplicated based on the address in the PayPal transaction.

2. **Contact Deduplication**: Contacts are matched and deduplicated based on the first name, last name, and email.

3. **Data Retrieval**: The `PayPalDataScheduler` should be scheduled to retrieve records from the previous day, starting at 12 AM and ending at 11:59 PM.

4. **Customization**: The logic is implemented in the following Apex classes: `PayPalDataExportQueueable`, `PayPalDataProcessorQueueable`, and `PayPalDataScheduler`. You can modify these classes to meet your specific requirements.

## Getting Started

### Step 1: Clone the Project and Open in Visual Studio Code

1. Clone this project and open the project directory in Visual Studio Code (VSCODE).

```shell
git clone https://github.com/mohamearif/Salesforce-PayPal-Transaction-Integration.git
```

```shell
cd <project-directory>
```
### Step 2: Enable Custom Address Field in Salesforce Org

Before deploying the integration, ensure you have enabled the custom address field in your Salesforce org.

1. Navigate to `Setup > User Interface`.
2. Check the checkbox next to "Use custom address fields."

### Step 3: Deploy the Integration

Deploy the PayPal Transaction Integration using the provided `package.xml` file in the manifest folder of this project. Run the test classes to ensure everything works correctly before deploying it to your production environment.

```shell
sfdx force:source:deploy --manifest manifest/package.xml -l RunSpecifiedTests -r PayPalDataExportQueueableTest PayPalDataProcessorQueueableTest PayPalDataSchedulerTest PayPalTransactionDataTest
```
### Step 4: Schedule the Data Retrieval

After deploying the integration, run the post-deployment script to schedule the `PayPalDataScheduler` Apex Class to run automatically every day at 3 AM. Also, add the 'PayPal_Data_Permissions' Permission Set to all system administrator users. Customize the PostDeploymentScript Apex script as needed.

```shell
sfdx force:apex:execute -f scripts/apex/PostDeploymentScript.apex
```
### Step 5: Named Credential Update

Update the named credential 'PayPal_Named_Credential' with your PayPal account client ID and client secret from your PayPal sandbox. Ensure that your PayPal REST API App has access to Transactions.

### Step 6: Permission and Configuration

1. **Assign the 'PayPal_Data_Permissions' Permission Set**: Assign the 'PayPal_Data_Permissions' permission set to users who need access to the 'PayPal_Transaction__c' tab/records. This permission set grants the necessary permissions for managing PayPal transactions within Salesforce.

2. **Customize with Custom Metadata Type**:

    a. `AccountRecordTypeDeveloperName`: Set a specific Account Record Type when creating Account records during the export of PayPal Transactions to Salesforce.

    b. `ContactRecordTypeDeveloperName`: Set a specific Contact Record Type when creating Contact records during the export of PayPal Transactions to Salesforce.

    c. `ExcludeAccountContact`: This feature provides the flexibility to prevent the creation of unnecessary accounts and contacts when exporting PayPal Transactions to Salesforce. By default, this setting is configured to exclude such creations. It is important to adjust this setting to align with your specific requirements, considering the following mappings:

    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`For Account creation,` the fields that are mapped for insertion include Name, Shipping Address, and Billing Address.

    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`For Contact creation,` the fields that are mapped for insertion include FirstName, LastName, Email, Mailing Address, and Other Address.
    
    So be sure to configure this setting accordingly to ensure a smooth integration, while keeping in mind that no Account/Contact Validations should disrupt the process.

    d. `PageSize`: Adjust the 'PageSize' to set the number of records exported per API call in the Queueable Apex. This allows you to control the size of each batch of records processed.

### Step 7: Existing Data Export (Optional)

If you have existing transactions in your PayPal account that you want to export to Salesforce, follow these steps:

1. Open the file 'scripts/apex/ExistingDataExportToSalesforce.apex' in this project.
2. Review the instructions provided at the top section of the file. It contains guidance on how to export existing PayPal transactions to Salesforce.
3. Execute the necessary Apex code within the file to initiate the export process.

Please note that this step is optional and applies to cases where you have historical data in your PayPal account that you want to bring into Salesforce.