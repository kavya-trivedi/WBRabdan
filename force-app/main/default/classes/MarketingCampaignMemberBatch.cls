global class MarketingCampaignMemberBatch implements Database.Batchable<SObject>, Database.Stateful {
    private List<Id> memberIds;

    // Constructor to accept member IDs
    public MarketingCampaignMemberBatch(List<Id> memberIds) {
        this.memberIds = memberIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query only the campaign members with the provided IDs
        return Database.getQueryLocator([
            SELECT Id, Member_Name__c, Member_Phone__c, Schedule_Date__c, 
                   WB_Marketing_Campaign_Group__r.WB_Template__c, 
                   WB_Marketing_Campaign_Group__r.Days_After__c, 
                   WB_Marketing_Campaign_Group__r.Time_To_Send__c, 
                   WB_Marketing_Campaign_Group__r.Is_Send_immediately__c, 
                   WB_Marketing_Campaign__r.Name, 
                   WB_Marketing_Campaign__r.Marketing_Campaign_Description__c,
                   WB_Marketing_Campaign__r.Object_Name__c,
                   Status__c , Chat_Record_Id__c
            FROM WB_Marketing_campaign_member__c
            WHERE Id IN :memberIds AND Status__c = 'Pending'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<WB_Marketing_campaign_member__c> scope) {
        try {
            for (WB_Marketing_campaign_member__c member : scope) {
                try {
                    System.debug('Processing member: ' + member);
    
                    if (String.isNotBlank(member.Member_Phone__c)) {
                        String phone = member.Member_Phone__c;
    
                        // Build the dynamic query for the related object
                        // String query = 'SELECT Id, ' + member.WB_Marketing_Campaign__r.Object_Name__c + 
                        //                ' FROM ' + member.WB_Marketing_Campaign__r.Object_Name__c + 
                        //                ' WHERE ' + member.WB_Marketing_Campaign__r.Object_Name__c + ' =: phone LIMIT 1';
    
                        // System.debug('Dynamic query: ' + query);
                        // List<SObject> records = Database.query(String.escapeSingleQuotes(query));
                        String objectName = member.WB_Marketing_Campaign__r.Object_Name__c; // e.g., 'Contact'
                        String query = 'SELECT Id FROM ' + objectName + ' WHERE Phone = :phone LIMIT 1';

                        System.debug('Dynamic query: ' + query);
                        List<SObject> records = Database.query(query);
                        if (!records.isEmpty()) {
                            // Call getTemplateData with the required parameters
                            Map<String, Object> tempData = WhatsAppMessageBatch.getTemplateData(
                                member.WB_Marketing_Campaign_Group__r.WB_Template__c,
                                records[0].Id,
                                member.WB_Marketing_Campaign__r.Object_Name__c
                            );
    
                            // Generate the payload and send the WhatsApp message
                            String jsonData = WhatsAppMessageBatch.generatePayloadFromTemplateData(tempData, phone);
                            List<Chat__c> sentChats = WhatsAppMessageBatch.sendWhatsAppMessage(member.Chat_Record_Id__c, jsonData);
    
                            if (!sentChats.isEmpty()) {
                                // Update the member's status to 'Completed'
                                member.Status__c = 'Completed';
                                member.Chat_Record_Id__c = sentChats[0].Id;
                            } else {
                                member.Status__c = 'Pending';
                            }
                        } else {
                            System.debug('No related records found for phone: ' + phone);
                            member.Status__c = 'Pending';
                        }
                    } else {
                        System.debug('Member does not have a phone number: ' + member.Id);
                        member.Status__c = 'Pending';
                    }
                } catch (Exception e) {
                    System.debug(e.getLineNumber());
                    System.debug('Error processing member: ' + member.Id + ' - ' + e.getMessage());
                    member.Status__c = 'Pending';
                }
            }
    
            // Perform DML operations to update the members
            if (!scope.isEmpty()) {
                update scope;
            }
        } catch (Exception e) {
            System.debug('Error in batch execution: ' + e.getLineNumber());
            System.debug('Error in execute method: ' + e.getMessage());
        }
    }
    global void finish(Database.BatchableContext bc) {
        // Optional: Add logic for post-batch processing
        System.debug('Batch processing completed for member IDs: ' + memberIds);
    }
}