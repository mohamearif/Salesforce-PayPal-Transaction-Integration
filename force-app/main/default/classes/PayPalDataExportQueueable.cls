public class PayPalDataExportQueueable implements Queueable, Database.AllowsCallouts {

    public String startDateStr {get; set;}
    public String endDateStr {get; set;}
    public Integer page {get; set;}
    public Integer pageSize {get; set;}
    public Boolean excludeAccountContactProcessing {get; set;}

    public PayPalDataExportQueueable(String sDateTime, String eDateTime, Integer currentPage, Integer pageSize, Boolean excludeAccountContactProcessing) {
        this.startDateStr = sDateTime;
        this.endDateStr = eDateTime;
        this.page = currentPage;
        this.pageSize = pageSize;
        this.excludeAccountContactProcessing = excludeAccountContactProcessing;
    }

    public void execute(QueueableContext context) {
        try{
            // Construct the PayPal API endpoint and request headers
            String endPointDomain = [SELECT Id, Endpoint, DeveloperName FROM NamedCredential Where DeveloperName = 'PayPal_Named_Credential' Limit 1].Endpoint;
            endPointDomain = endPointDomain.split('.com/')[0]+'.com';
            String paypalApiEndpoint = endPointDomain + '/v1/reporting/transactions';
            String authHeader = 'Bearer ' + getPayPalAccessToken(); // Implement a method to get the access token

            HttpRequest request = new HttpRequest();
            request.setEndpoint(paypalApiEndpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', authHeader);
            request.setHeader('Content-Type', 'application/json');

            // Construct the query parameters for date filtering
            request.setEndpoint(paypalApiEndpoint + '?fields=transaction_info,payer_info,shipping_info,auction_info,cart_info,incentive_info,store_info&'+ 'page_size=' + pageSize + '&page=' + page +'&start_date=' + startDateStr + '&end_date=' + endDateStr);

            // Execute the request and handle the response
            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() == 200) {
                // Parse the PayPal transaction data from the response and process it
                String responseBody = response.getBody();
                
                // Create a new ContentVersion object
                // ContentVersion cv = new ContentVersion();
                // cv.VersionData = Blob.valueOf(responseBody);
                // cv.Title = 'MyFile.txt'; // Specify the file name
                // cv.PathOnClient = 'MyFile.txt'; // Specify the file name again
                // cv.FirstPublishLocationId = UserInfo.getUserId(); // Set the owner
                // insert cv;

                PayPalTransactionData transactionData = (PayPalTransactionData)JSON.deserialize(responseBody, PayPalTransactionData.class);
                transactionData.page_size = pageSize;
                transactionData.start_datetime = startDateStr;
                transactionData.end_datetime = endDateStr;
                transactionData.excludeAccountContactProcessing = excludeAccountContactProcessing;
                if(!Test.isRunningTest()) {
                    System.enqueueJob(new PayPalDataProcessorQueueable(transactionData));
                }
            }
        } catch(Exception ex) {
            PayPalDataProcessorQueueable.errorEmail('Error on PayPalDataExportQueueable', ex.getStackTraceString());
        }
    }
    
    private String getPayPalAccessToken() {
        // Implement logic to obtain and return the PayPal access token
        String namedCredential = 'PayPal_Named_Credential'; // Replace with the API name of your named credential
    
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + namedCredential); // Use callout to reference the named credential
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Accept-Language', 'en_US');
        request.setBody('grant_type=client_credentials'); // Use 'client_credentials' grant type
    
        Http http = new Http();
        HttpResponse response = http.send(request);
    
        if (response.getStatusCode() == 200) {
            Map<String, Object> tokenInfo = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String accessToken = (String) tokenInfo.get('access_token');
            return accessToken;
        } else {
            // Handle token retrieval error
            PayPalDataProcessorQueueable.errorEmail('Error on PayPalDataExportQueueable', 'Error getting PayPal access token');
            return null;
        }
    }

}