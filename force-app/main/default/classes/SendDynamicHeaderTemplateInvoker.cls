public with sharing class SendDynamicHeaderTemplateInvoker {
    @future(callout=true)
    public static List<InvocableResult> sendWhatsappMessage(List<InvocableInput> inputList) {
        List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values(); 
        List<InvocableResult> results = new List<InvocableResult>();
        if(wbConfig.size() > 0){
            for (InvocableInput input : inputList) {

                System.debug('The Input Data is :: '+ input);
                Map<String, Object> resultMap = new Map<String, Object>();
                MVWB__Chat__c chat = new MVWB__Chat__c();
                chat.MVWB__Whatsapp_Template__c = input.templateId;
                chat.MVWB__Type_of_Message__c	= 'OutBound Messages';
                chat.MVWB__Message_Status__c = null;
                chat.MVWB__Message_Type__c = 'Template';
                chat.MVWB__WhatsAppContextMessageID__c = input.contextId;
                chat.MVWB__Phone__c = input.recipientPhone;
                try {
                    HttpRequest httpReq = new HttpRequest();
                    String accessToken = wbConfig[0].MVWB__Access_Token__c;
                    String endpoint = wbConfig[0].MVWB__API_Endpoint__c + '/' + wbConfig[0].MVWB__API_Version__c + '/' + wbConfig[0].MVWB__Phone_Number_Id__c + '/messages';
                    httpReq.setEndpoint(endpoint);
                    httpReq.setMethod('POST');
                    httpReq.setHeader('Content-Type', 'application/json');
                    httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
                    httpReq.setBody(input.jsonData);
                    Http http = new Http();
                    HttpResponse response = http.send(httpReq);
                    Integer statusCode = response.getStatusCode();
                    if(response != null && statusCode == 200){
                        String responseBody = response.getBody();
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
    }
    
    public class InvocableResult {
        @InvocableVariable(label='Chat Record')
        public MVWB__Chat__c chat;
    }

    public static String generatePublicPdfUrl(Id recordId) {
        // 1. Render VF page as PDF
        PageReference pdfPage = Page.OfferToPurchasePdf;
        pdfPage.getParameters().put('id', recordId);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // 2. Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'GeneratedPDF';
        cv.PathOnClient = 'GeneratedPDF.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        // 3. Query for ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // 4. Create ContentDistribution
        ContentDistribution dist = new ContentDistribution();
        dist.Name = 'PDF Link';
        dist.ContentDocumentId = cv.ContentDocumentId;
        dist.PreferencesAllowViewInBrowser = true;
        dist.PreferencesAllowOriginalDownload = true;
        dist.PreferencesVisibleToGuestUser = true;
        insert dist;

        // 5. Return Public URL
        return dist.DistributionPublicUrl;
    }
}