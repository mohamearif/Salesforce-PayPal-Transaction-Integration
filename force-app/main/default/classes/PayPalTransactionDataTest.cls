@isTest
public class PayPalTransactionDataTest {
	@isTest
    static void testTransactionData() {
        // Create a test instance of TransactionData
        PayPalTransactionData transactionData = new PayPalTransactionData();
        
        // Set some sample values
        transactionData.account_number = 'TestAccount123';
        transactionData.last_refreshed_datetime = Datetime.now().format('yyyy-mm-dd');
        transactionData.total_items = 1;
        transactionData.total_pages = 1;
        transactionData.links = new List<PayPalTransactionData.Links>();
        transactionData.page = 1;
        transactionData.page_size = 1;
        transactionData.start_datetime = Datetime.now().addDays(-3).format('yyyy-MM-dd')+'T00:00:00.000Z';
        transactionData.end_datetime = Datetime.now().format('yyyy-MM-dd')+'T23:59:59.999Z';
        transactionData.excludeAccountContactProcessing = false;
        transactionData.dataMigrationMode = false;
        transactionData.sDateTime = Datetime.now();
        transactionData.eDateTime = Datetime.now();
        // Create a Transaction_details object
        PayPalTransactionData.Transaction_details transactionDetails = new PayPalTransactionData.Transaction_details();
        transactionData.transaction_details = new List<PayPalTransactionData.Transaction_details>();
        
        // Set values for transactionDetails
        transactionDetails.transaction_info = new PayPalTransactionData.Transaction_info();
        transactionDetails.transaction_info.paypal_account_id = 'Paypal123';
        transactionDetails.transaction_info.transaction_id = 'Transaction123';
        transactionData.transaction_details.add(transactionDetails);
        
        String jsonBody = [SELECT Body FROM StaticResource WHERE Name = 'Paypal_Transaction_Data' ].Body.toString();
        transactionData = new PayPalTransactionData();
        transactionData.transaction_details = new List<PayPalTransactionData.Transaction_details>();
        transactionData = (PayPalTransactionData)JSON.deserialize(jsonBody, PayPalTransactionData.class);
        // Perform assertions
        System.assertEquals('K9GMNS5J4PASA', transactionData.account_number);
        System.assertEquals(1, transactionData.page);
        System.assertEquals(7, transactionData.transaction_details.size());
    }
}