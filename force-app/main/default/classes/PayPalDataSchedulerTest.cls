@isTest
global class PayPalDataSchedulerTest {

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
    global static void testExecute() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        String jobId = System.schedule('testPayPalDataScheduler', '0 0 0 3 9 ? 2042', new PayPalDataScheduler());
        Test.stopTest();
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
        NextFireTime
        FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals('0 0 0 3 9 ? 2042', ct.CronExpression, 'schedule should match.');
    }
}