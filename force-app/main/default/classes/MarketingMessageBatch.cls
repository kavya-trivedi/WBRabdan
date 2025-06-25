public with sharing class MarketingMessageBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful{
    public List<WB_Marketing_campaign_member__c> campaignMember ;
    public List<Chat__c> chatsToUpdate = new List<Chat__c>();
    public String memberId;

    public MarketingMessageBatch(List<WB_Marketing_campaign_member__c> cm) {
        campaignMember = cm;
    }

    
    /*
    *********************************************************
    @description     : This method is used to start the batch process and send whatsapp message.
    @param           : bc - Batchable context 
    @return          : Database.QueryLocator - query to fetch all the chat records
    ********************************************************
    */
    // public Database.QueryLocator start(Database.BatchableContext bc) {
    //     try {
    
    //         return Database.getQueryLocator(campaignMember);
    //     } catch (Exception e) {
    //         return Database.getQueryLocator([SELECT Id FROM Chat__c WHERE Id = null]);
    //     }
    // }
    public Iterable<WB_Marketing_campaign_member__c> start(Database.BatchableContext bc) {
        return campaignMember; // Return the list as an Iterable
    }

    /*
    *********************************************************
    @description     : This method is used to execute the batch process.
    @param           : bc - Batchable context
    @param           : scope - Scope of the batch process
    ********************************************************
    */
    public void execute(Database.BatchableContext bc, List<WB_Marketing_campaign_member__c> marketingMemberList) {
        try {
            WB_Marketing_campaign_member__c member = new WB_Marketing_campaign_member__c();

            if(marketingMemberList.size() > 0){
                member = marketingMemberList[0];
            }

            memberId = member.Id;
            if (String.isBlank(member.Member_Phone__c)) {
                throw new AuraHandledException('Member does not have a phone number.');
            }

            // Perform the callout first
            Map<String, Object> tempData = WhatsAppMessageBatch.getTemplateData(
                member.WB_Marketing_Campaign_Group__r.WB_Template__c,
                member.Member_Phone__c,
                member.WB_Marketing_Campaign__r.Object_Name__c
            );

            System.debug('tempData: ' + tempData);

            // Generate the payload and send the WhatsApp message
            String jsonData = WhatsAppMessageBatch.generatePayloadFromTemplateData(tempData, member.Member_Phone__c);
            List<Chat__c> sentChats = WhatsAppMessageBatch.sendWhatsAppMessage(member.Chat_Record_Id__c, jsonData);

            // List<Chat__c> sentChats = chatsToUpdate;
            System.debug('sentChats: ' + sentChats);
            if(sentChats.size() > 0){
                this.chatsToUpdate.add(sentChats[0]);
            }

        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppMessageBatch', 'finish' => 'execute', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' =>  e.getMessage(), 'apiResponse' => null});
        }
    }

    /*
    *********************************************************
    @description     : This method is used to finish the batch process and update the chat records.
    @param           : bc - Batchable context
    @return          : void
    ********************************************************
    */
    
    public void finish(Database.BatchableContext bc) {
        try {
            if (this.chatsToUpdate.size() > 0) {
                Database.update(this.chatsToUpdate, false, AccessLevel.USER_MODE);
            }
    
            if(memberId != null){
                WB_Marketing_campaign_member__c mcm = new WB_Marketing_campaign_member__c(Id = this.memberId);
                mcm.Status__c = 'Completed';
                Database.update(mcm, false, AccessLevel.USER_MODE);
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppMessageBatch', 'methodName' => 'getTemplateData', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' =>  e.getMessage(), 'apiResponse' => null});
        }
    }

}