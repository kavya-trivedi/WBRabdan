@isTest
private class ChatGeminiHandlerTest {
    
    // Mock callout for WhatsApp API
    class WhatsAppMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            System.debug('endpoint:- '+ req.getEndpoint());
            // Simulate a valid WhatsApp media download response
            if (req.getEndpoint().contains('graph.facebook.com')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"messages":[{"id":"wamid.mock-id-123"}]}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('https://generativelanguage.googleapis.com')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"candidates":[{"content":{"parts":[{"text":"Test Gemini response"}]}}]}');
                res.setStatusCode(200);
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Invalid endpoint"}');
            }

            return res;
        }

    }

    @isTest
    static void testProcessChat() {
        // Insert test User Preference
        User_Theme_Preference__c pref = new User_Theme_Preference__c(Auto_Response__c = true);
        insert pref;

        // Insert Chat record
        Chat__c chat = new Chat__c(
            Message__c = 'Hi, what services do you offer?',
            Phone__c = '919999999999',
            Type_of_Message__c = 'Inbound Messages',
            Message_Status__c = 'Delivered'
        );
        insert chat;

        // Register mock for Gemini API
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        // Set up input for invocable method
        ChatGeminiHandler.InvocableInput input = new ChatGeminiHandler.InvocableInput();
        input.chatId = chat.Id;

        Test.startTest();
        ChatGeminiHandler.processChat(new List<ChatGeminiHandler.InvocableInput>{ input });
        Test.stopTest();

        // Verify new chat created and status updated
        List<Chat__c> chats = [SELECT Id, Type_of_Message__c, Message_Status__c FROM Chat__c WHERE Phone__c = :chat.Phone__c];
        System.assertEquals(2, chats.size(), 'There should be 2 chat records after processing.');
        Boolean hasOutbound = false;
        for (Chat__c c : chats) {
            if (c.Type_of_Message__c == 'Outbound Messages') {
                hasOutbound = true;
                // System.assertEquals('Failed', c.Message_Status__c); // Initially set before WhatsApp response
            }
        }
        // System.assert(hasOutbound, 'Outbound message should be created.');
    }
}