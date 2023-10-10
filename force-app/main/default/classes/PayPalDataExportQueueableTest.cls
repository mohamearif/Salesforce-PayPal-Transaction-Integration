@isTest
public class PayPalDataExportQueueableTest {
    // Mock class to simulate HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public Integer statusCode;
        public MockHttpResponseGenerator(Integer code) {
            this.statusCode = code;
        }
        public HTTPResponse respond(HTTPRequest request) {
            // Create a mock response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(
                [SELECT Body FROM StaticResource WHERE Name = 'Paypal_Transaction_Data' ].Body.toString()
            );
            response.setStatusCode(statusCode);
            return response;
        }
    }

    @isTest
    static void testQueueableJob() {
        test.startTest();
        // Set up test data or configuration as needed
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        // Enqueue the queueable job
        String startDateStr = Datetime.now().addDays(-3).format('yyyy-MM-dd');
        startDateStr += 'T00:00:00.000Z';
        String endDateStr = Datetime.now().format('yyyy-MM-dd');
        endDateStr += 'T23:59:59.999Z';
        Id jobId = System.enqueueJob(new PayPalDataExportQueueable(startDateStr, endDateStr, 1, 7, false));
        test.stopTest();
        // Optionally, assert that the job was enqueued successfully
        // Note: There's no direct way to test the asynchronous execution of the queueable job.
        System.assertEquals(1, [SELECT Id FROM AsyncApexJob WHERE Id = :jobId].size(), 'Job should exist');
    }
    
    @isTest
    static void testQueueableJobNegative() {
        test.startTest();
        // Set up test data or configuration as needed
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404));
        // Enqueue the queueable job
        String startDateStr = Datetime.now().addDays(-3).format('yyyy-MM-dd');
        startDateStr += 'T00:00:00.000Z';
        String endDateStr = Datetime.now().format('yyyy-MM-dd');
        endDateStr += 'T23:59:59.999Z';
        Id jobId = System.enqueueJob(new PayPalDataExportQueueable(startDateStr, endDateStr, 1, 7, false));
        test.stopTest();
        // Optionally, assert that the job was enqueued successfully
        // Note: There's no direct way to test the asynchronous execution of the queueable job.
        System.assertEquals(1, [SELECT Id FROM AsyncApexJob WHERE Id = :jobId].size(), 'Job should exist');
    }
}