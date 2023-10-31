# Salesforce PayPal Transactions Integration

This repository provides a lightweight outbound integration from Salesforce to PayPal using Scheduled and Queueable Apex. It asynchronously retrieves transactions from PayPal's Transactions REST API endpoint [here](https://developer.paypal.com/docs/api/transaction-search/v1/#search_get) and pushes them into a Salesforce custom object called 'PayPal_Transaction__c' as records.

In addition, implementing record-based flow or trigger on 'PayPal_Transaction__c' will enable you to seamlessly transform the incoming data into your standard/custom object records, allowing you to tailor the integration to meet your specific business requirements.

## Table of Contents

- [Important Notes](#important-notes)
- [Helpful Tips and Considerations](#helpful-tips-and-considerations)
- [Getting Started](#getting-started)
  - [Step 1: Clone the Project and Open in Visual Studio Code](#step-1-clone-the-project-and-open-in-visual-studio-code)
  - [Step 2: Enable Custom Address Field in Salesforce Org](#step-2-enable-custom-address-field-in-salesforce-org)
  - [Step 3: Deploy the Integration](#step-3-deploy-the-integration)
  - [Step 4: Schedule the Data Retrieval](#step-4-schedule-the-data-retrieval)
  - [Step 5: Follow through the steps on Setup, Customize and Data Export Page internally on your salesforce org](#step-5-follow-through-the-rest-of-the-few-steps-on-setup-customize-and-data-export-page-internally-on-your-salesforce-org)

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
sf project deploy start --manifest manifest/package.xml -l RunSpecifiedTests -t PayPalDataExportQueueableTest PayPalDataProcessorQueueableTest PayPalDataSchedulerTest PayPalTransactionDataTest PostInstallClassTest
```
### Step 4: Schedule the Data Retrieval

After deploying the integration, run the post-deployment script to schedule the `PayPalDataScheduler` Apex Class to run automatically every day at 3 AM. Also, add the 'PayPal_Data_Permissions' Permission Set to all system administrator users. Customize the PostDeploymentScript Apex script as needed.

```shell
sfdx force:apex:execute -f scripts/apex/PostDeploymentScript.apex
```

### Step 5: Follow through the rest of the few steps on Setup, Customize and Data Export Page internally on your salesforce org

  1. Setup Section (Required): PayPal Connection Configuration, NamedCredential and Send Error Emails Configuration Setup.
  2. Customize Section (Optional): Learn the available customize options and possibly customize according to you need.
  3. Data Export Section (Optional): If you have existing transactions in your PayPal account that you want to export to Salesforce then follow those steps.