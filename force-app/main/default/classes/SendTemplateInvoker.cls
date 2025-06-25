public without sharing class SendTemplateInvoker {
    @InvocableMethod(label='Send WhatsApp Template Message' description='Sends a WhatsApp template message via Flow')
    public static List<InvocableResult> sendWhatsappMessage(List<InvocableInput> inputList) {
        List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values(); 
        List<InvocableResult> results = new List<InvocableResult>();
        if(wbConfig.size() > 0){
            for (InvocableInput input : inputList) {

                System.debug('The Input Data is :: '+ input);
                Map<String, Object> resultMap = new Map<String, Object>();
                MVWB__Chat__c chat = new MVWB__Chat__c();
                if (!String.isBlank(input.templateId)) {
                    chat.MVWB__Whatsapp_Template__c = input.templateId;
                }
                chat.MVWB__Type_of_Message__c	= 'OutBound Messages';
                chat.MVWB__Message_Status__c = null;
                chat.MVWB__Message_Type__c = 'Template';
                chat.MVWB__WhatsAppContextMessageID__c = input.contextId;
                chat.MVWB__Phone__c = input.recipientPhone;
                System.debug('Related Record Id: ' + input.relatedRecordId);
                chat.Related_Record_Id__c = input.relatedRecordId;
                try {
                    HttpRequest httpReq = new HttpRequest();
                    // String accessToken = 'EAAJ8MKo1TSwBOwmIFIWE7ZCSs1k7irr3qNqJ5gCyMBobpXlVPRJ29W8fP0KOZBjymn6kt0dc4uy6iq6c2JMqwZAwzEZCZAnyxO35M4QSZAhDQaCgekNVRw9VZAeFeeJBejZBkXcvjPUPyE2xLt9MWnZB9Jq5tlWx4zEGKqlbrhspDOv3wkFfhWxjfT5ODIBj16hWOdgZDZD';
                    // String endpoint = 'https://graph.facebook.com/v22.0/572401672631342/messages';
                    String accessToken = wbConfig[0].MVWB__Access_Token__c;
                    String endpoint = wbConfig[0].MVWB__API_Endpoint__c + '/' + wbConfig[0].MVWB__API_Version__c + '/' + wbConfig[0].MVWB__Phone_Number_Id__c + '/messages';
                    httpReq.setEndpoint(endpoint);
                    httpReq.setMethod('POST');
                    httpReq.setHeader('Content-Type', 'application/json');
                    httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
                    httpReq.setBody(input.jsonData);
                    System.debug('HTTP Request Body: ' + input.jsonData);
                    Http http = new Http();
                    HttpResponse response = http.send(httpReq);
                    Integer statusCode = response.getStatusCode();
                    String responseBody = response.getBody();
                    System.debug('Response body: ' + responseBody);
                    if(response != null && statusCode == 200){
                        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                        List<Object> messages = (List<Object>)jsonMap.get('messages');
                        Map<String, Object> firstMessage = (Map<String, Object>)messages[0];
                        String whatsAppMessageID = (String) firstMessage.get('id');
                        chat.MVWB__WhatsAppMessageId__c = whatsAppMessageID;
                        chat.MVWB__Message_Status__c = 'Sent';
                    }else{
                        chat.MVWB__Message_Status__c = 'Failed';
                    }

                    insert as user chat;
                    chat = [SELECT Id, MVWB__Type_of_Message__c, MVWB__WhatsAppMessageId__c, MVWB__Message__c, MVWB__Message_Status__c, MVWB__Message_Type__c, MVWB__Reply_To__c, MVWB__Reaction__c, MVWB__Whatsapp_Template__c, MVWB__Whatsapp_Template__r.MVWB__Template_Name__c, CreatedDate, MVWB__Last_Interaction_Date__c, MVWB__Phone__c FROM MVWB__Chat__c WHERE Id =:chat.Id WITH SECURITY_ENFORCED];
                    resultMap.put('chat', chat);
                } catch (Exception e) {
                    chat.MVWB__Message_Status__c = 'Failed';
                    insert as user chat;
                }
                
                InvocableResult result = new InvocableResult();
                result.chat = chat;
                results.add(result);
            }
        }
        return results;
    }
    
    public class InvocableInput {
        @InvocableVariable(required=false label='Template Id')
        public String templateId;

        @InvocableVariable(required=false label='Context Id')
        public String contextId;

        @InvocableVariable(required=false label='Recipient Phone')
        public String recipientPhone;

        @InvocableVariable(required=true label='JSON Data')
        public String jsonData;
        
        @InvocableVariable(required=false label='Related Record Id')
        public String relatedRecordId;
    }
    
    public class InvocableResult {
        @InvocableVariable(label='Chat Record')
        public MVWB__Chat__c chat;
    }
}