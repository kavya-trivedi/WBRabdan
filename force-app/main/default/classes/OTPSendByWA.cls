public with sharing class OTPSendByWA {

    @InvocableMethod(label='Send By WA' description='Send By WA')
    public static void generatePublicPdfUrl(List<InvocableInput> inputList) {
        System.debug('Input List in OTPSendByWA: ' + inputList);

        // 1. Render VF page as PDF
        PageReference pdfPage = Page.OfferToPurchasePdf;
        pdfPage.getParameters().put('id', inputList[0].recordId);
        Blob pdfBlob = pdfPage.getContentAsPDF();
        System.debug('PDF Blob Size: ' + pdfBlob.size());

        // 2. Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'GeneratedPDF';
        cv.PathOnClient = 'GeneratedPDF.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        // 3. Query for ContentDocumentId
        cv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.debug('ContentDocumentId: ' + cv.ContentDocumentId);
        ContentDocument cd = new ContentDocument(Id = cv.ContentDocumentId);

        // 4. Create ContentDistribution
        ContentDistribution cd1 = new ContentDistribution();
        cd1.Name = cv.Title;
        cd1.ContentVersionId = cv.Id;
        cd1.PreferencesAllowViewInBrowser= true;
        cd1.PreferencesLinkLatestVersion=true;
        cd1.PreferencesNotifyOnVisit=false;
        cd1.PreferencesPasswordRequired=false;
        cd1.PreferencesAllowOriginalDownload= true;
        insert as user cd1;

        ContentDistribution cdRec = [SELECT Id, DistributionPublicUrl, ContentDownloadUrl FROM ContentDistribution WHERE Id = :cd1.Id];
        System.debug('ContentDistribution Record: ' + cdRec);
        
        List<Offer_to_Purchase__c> otpList = [SELECT Id, OTP_Pdf_Url__c FROM Offer_to_Purchase__c WHERE Id = :inputList[0].recordId LIMIT 1];
        System.debug('Offer_to_Purchase__c Record: ' + otpList);
        if (!otpList.isEmpty()) {
            otpList[0].OTP_Pdf_Url__c = cdRec.ContentDownloadUrl;
            update otpList[0];
        }

        sendWhatsappMessage(inputList[0].jsonData, inputList[0].recipientPhone, cdRec.ContentDownloadUrl);
        System.debug('WhatsApp message sent successfully.');
    }

    public class InvocableInput {
        @InvocableVariable(required=false label='Record Id')
        public String recordId;

        @InvocableVariable(required=false label='Recipient Phone')
        public String recipientPhone;

        @InvocableVariable(required=false label='JSON Data')
        public String jsonData;
    }

    @future(callout=true)
    public static void sendWhatsappMessage(String jsonData, String recipientPhone, String newPdfUrl) {
        // Parse the JSON
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        // Navigate to the link field and update it
        Map<String, Object> template = (Map<String, Object>) jsonMap.get('template');
        List<Object> components = (List<Object>) template.get('components');

        // Find the header component and update the link
        for (Object compObj : components) {
            Map<String, Object> comp = (Map<String, Object>) compObj;
            if (String.valueOf(comp.get('type')) == 'header') {
                List<Object> parameters = (List<Object>) comp.get('parameters');
                for (Object paramObj : parameters) {
                    Map<String, Object> param = (Map<String, Object>) paramObj;
                    if (String.valueOf(param.get('type')) == 'document') {
                        Map<String, Object> document = (Map<String, Object>) param.get('document');
                        document.put('link', newPdfUrl);
                    }
                }
            }
        }

        // Convert back to JSON
        String updatedJson = JSON.serialize(jsonMap);
        System.debug('Updated JSON: ' + updatedJson);
        List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values();
        if(wbConfig.size() > 0){

            Map<String, Object> resultMap = new Map<String, Object>();
            MVWB__Chat__c chat = new MVWB__Chat__c();
            chat.MVWB__Type_of_Message__c	= 'OutBound Messages';
            chat.MVWB__Message_Status__c = null;
            chat.MVWB__Message_Type__c = 'Template';
            chat.MVWB__Phone__c = recipientPhone;
            try {
                HttpRequest httpReq = new HttpRequest();
                String accessToken = wbConfig[0].MVWB__Access_Token__c;
                String endpoint = wbConfig[0].MVWB__API_Endpoint__c + '/' + wbConfig[0].MVWB__API_Version__c + '/' + wbConfig[0].MVWB__Phone_Number_Id__c + '/messages';
                httpReq.setEndpoint(endpoint);
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type', 'application/json');
                httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
                httpReq.setBody(updatedJson);
                Http http = new Http();
                HttpResponse response = http.send(httpReq);
                Integer statusCode = response.getStatusCode();
                System.debug('Response body: ' + response.getBody());
                if(response != null && statusCode == 200){
                    String responseBody = response.getBody();
                    Map<String, Object> jsonMap1 = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                    List<Object> messages = (List<Object>)jsonMap1.get('messages');
                    Map<String, Object> firstMessage = (Map<String, Object>)messages[0];
                    String whatsAppMessageID = (String) firstMessage.get('id');
                    chat.MVWB__WhatsAppMessageId__c = whatsAppMessageID;
                    chat.MVWB__Message_Status__c = 'Sent';
                }else{
                    chat.MVWB__Message_Status__c = 'Failed';
                }

                insert as user chat;
            } catch (Exception e) {
                chat.MVWB__Message_Status__c = 'Failed';
                insert as user chat;
            }
        }
    }
}