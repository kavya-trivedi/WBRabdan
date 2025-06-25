@isTest
private class SendTemplateInvokerTest {

    // Success Mock
    private class MockSuccessResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"messages":[{"id":"wamid.HBgLMjM4NDU2..."}]}');
            return res;
        }
    }

    // Failure Mock
    private class MockFailureResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Invalid request"}');
            return res;
        }
    }

    @isTest
    static void testSendWhatsappMessage_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        // Insert a template record to use a valid Id
        // MVWB__Whatsapp_Template__c template = new MVWB__Whatsapp_Template__c(
        //     Name = 'Test Template',
        //     MVWB__Template_Name__c = 'hello_world'
        // );
        // insert template;

        SendTemplateInvoker.InvocableInput input = new SendTemplateInvoker.InvocableInput();
        // input.contextId = 'contextABC';
        input.recipientPhone = '+1234567890';
        input.jsonData = '{"messaging_product":"whatsapp","to":"+1234567890","type":"template","template":{"name":"hello_world","language":{"code":"en_US"}}}';

        List<SendTemplateInvoker.InvocableInput> inputs = new List<SendTemplateInvoker.InvocableInput>{ input };

        Test.startTest();
        List<SendTemplateInvoker.InvocableResult> results = SendTemplateInvoker.sendWhatsappMessage(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Sent', results[0].chat.MVWB__Message_Status__c);
    }

    @isTest
    static void testSendWhatsappMessage_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());

        // Insert a template record to use a valid Id
        // MVWB__Whatsapp_Template__c template = new MVWB__Whatsapp_Template__c(
        //     Name = 'Test Template',
        //     MVWB__Template_Name__c = 'hello_world'
        // );
        // insert template;

        SendTemplateInvoker.InvocableInput input = new SendTemplateInvoker.InvocableInput();
        // input.contextId = 'contextXYZ';
        input.recipientPhone = '+9876543210';
        input.jsonData = '{"messaging_product":"whatsapp","to":"+9876543210","type":"template"}';

        List<SendTemplateInvoker.InvocableInput> inputs = new List<SendTemplateInvoker.InvocableInput>{ input };

        Test.startTest();
        List<SendTemplateInvoker.InvocableResult> results = SendTemplateInvoker.sendWhatsappMessage(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Failed', results[0].chat.MVWB__Message_Status__c);
    }
}