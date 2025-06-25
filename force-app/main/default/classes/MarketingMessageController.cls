public with sharing class MarketingMessageController {
    // @AuraEnabled
    // public static void createMarketingCampaign(String campaignData) {
    //     try {
    //         // Deserialize the JSON string into a Map
    //         Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(campaignData);
    //         System.debug('dataMap: ' + dataMap);
            
    //         // Extract basic fields
    //         String name = (String) dataMap.get('name');
    //         String description = (String) dataMap.get('description');
    //         String objectName = (String) dataMap.get('objectName');
    //         Boolean isMarketingCampaign = (Boolean) dataMap.get('isMarketingCampaign');
    //         String selectedOption = (String) dataMap.get('selectedOption');
    //         String selectedDate = (String) dataMap.get('selectedDate');
    //         String selectedDateFields = (String) dataMap.get('selectedDateFields');
    //         // List<String> groupId = (List<String>) dataMap.get('groupIdList');
    //         List<Object> rawGroupList = (List<Object>) dataMap.get('groupIdList');
    //         List<String> groupId = new List<String>();

    //         for (Object obj : rawGroupList) {
    //             Map<String, Object> groupMap = (Map<String, Object>) obj;
    //             groupId.add((String) groupMap.get('Id'));
    //         }
    //         // ✅ Fix: safely cast each item in the list to a Map
    //         List<Object> rawEmailConfigs = (List<Object>) dataMap.get('emailConfigs');
    //         List<Map<String, Object>> emailConfigs = new List<Map<String, Object>>();
            
    //         for (Object rawItem : rawEmailConfigs) {
    //             emailConfigs.add((Map<String, Object>) rawItem);
    //         }
            
    //         Map<String, SObject> phoneToObjectMapList;
    //         if(selectedOption == 'related') {
    //             // selectedDate = selectedDateFields;
    //             phoneToObjectMapList  = getObjectDetails(objectName, selectedDateFields);
    //         }else {
    //             phoneToObjectMapList = new Map<String, SObject>();
    //         }

    //         System.debug('name: ' + name);
    //         System.debug('description: ' + description);
    //         System.debug('objectName: ' + objectName);
    //         System.debug('isMarketingCampaign: ' + isMarketingCampaign);
    //         System.debug('selectedOption: ' + selectedOption);
    //         System.debug('selectedDate: ' + selectedDate);
    //         System.debug('selectedDateFields: ' + selectedDateFields);
    //         System.debug('emailConfigs: ' + emailConfigs);
    //         System.debug('groupId: ' + groupId);
    //         System.debug('phoneToObjectMapList: ' + phoneToObjectMapList);
    //         System.debug('rawGroupList: ' + String.join(groupId, ','));


    //         // Create a new Marketing Campaign record
    //         WB_Marketing_campaign__c campaign = new WB_Marketing_campaign__c(
    //             Name = name,
    //             Marketing_Campaign_Description__c = description,
    //             Object_Name__c = objectName,
    //             hasExistingMarketingCampaign__c = isMarketingCampaign,
    //             Group_Id_List__c = String.join(groupId, ',')
    //         );

    //         // Insert the Marketing Campaign record
    //         Database.insert(campaign, false, AccessLevel.USER_MODE);

           
    //         List<WB_Marketing_campaign_group__c> campaignGroups = new List<WB_Marketing_campaign_group__c>();

    //         if (emailConfigs != null && !emailConfigs.isEmpty()) {
    //             for (Map<String, Object> emailConfig : emailConfigs) {
    //                 // String templateId = (String) emailConfig.get('template');
    //                 // String daysAfter = (String) emailConfig.get('daysAfter');
    //                 // String timeToSend = (String) emailConfig.get('timeToSend');
    //                 String templateId = String.valueOf(emailConfig.get('template'));
    //                 String daysAfter = String.valueOf(emailConfig.get('daysAfter'));
    //                 String timeToSend = String.valueOf(emailConfig.get('timeToSend'));
    //                 String isSendImmediately = String.valueOf(emailConfig.get('isImmediateSelected'));
            
    //                 // Validate Days_After__c
    //                 Integer daysAfterValue = null;
    //                 if (daysAfter != null) {
    //                     try {
    //                         System.debug('daysAfter: ' + daysAfter);
    //                         daysAfterValue = Integer.valueOf(daysAfter) ;
    //                     } catch (Exception e) {
    //                         System.debug(e.getLineNumber());
    //                         throw new AuraHandledException('Invalid value for Days_After__c: ' + daysAfter);
    //                     }
    //                 }
            
    //                 // Validate Time_To_Send__c
    //                  Time timeToSendValue = null;
    //                  if (timeToSend != null && String.valueOf(timeToSend).trim() != '') {
    //                      try {
    //                         System.debug('timeToSend: ' + timeToSend);

    //                         // Split the time string (assuming format is "HH:mm:ss")
    //                         List<String> timeParts = timeToSend.split(':');

    //                         Integer hours = Integer.valueOf(timeParts[0]);
    //                         Integer minutes = Integer.valueOf(timeParts[1]);
    //                         Integer seconds = Integer.valueOf(timeParts[2]);

    //                         // Create a Time instance
    //                         timeToSendValue = Time.newInstance(hours, minutes, seconds, 0);

    //                         System.debug('timeToSendValue: ' + timeToSendValue);

    //                      } catch (Exception e) {
    //                          throw new AuraHandledException('Invalid value for Time_To_Send__c: ' + timeToSend);
    //                      }
    //                  }
    //                  System.debug('Time to send ::: ' + timeToSendValue);
                    
    //                 // Create a new Marketing Campaign Group record
    //                 WB_Marketing_campaign_group__c campaignGroup = new WB_Marketing_campaign_group__c(
    //                     WB_Marketing_campaign__c = campaign.Id,
    //                     WB_Template__c = templateId,
    //                     Status__c = 'Pending',
    //                     Days_After__c = daysAfterValue,
    //                     Time_To_Send__c = timeToSendValue,
    //                     Is_Send_immediately__c = isSendImmediately == 'true',
    //                     Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null,
    //                     Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null
    //                 );
    //                 campaignGroups.add(campaignGroup);
    //             }
    //         }
    //         System.debug('campaignGroups: ' + campaignGroups);

    //         // Insert the Marketing Campaign Group records
    //         if (!campaignGroups.isEmpty()) {
    //             // insert campaignGroups;
    //             Database.insert(campaignGroups, false, AccessLevel.USER_MODE);

    //         }

    //         for (WB_Marketing_campaign_group__c campaignGroupsVariable : campaignGroups) {
    //             Integer daysAfterValue = (campaignGroupsVariable.Days_After__c != null) ? Integer.valueOf(campaignGroupsVariable.Days_After__c) : null;
    //             Time timeToSendValue = campaignGroupsVariable.Time_To_Send__c; // Assuming Time_To_Send__c is the correct field for time
            
    //             String createChatRecord = createChatRecodsMarketing(
    //                 campaignGroupsVariable.WB_Template__c,
    //                 groupId,
    //                 selectedDate,
    //                 campaign.Id,
    //                 campaignGroupsVariable.Id,
    //                 phoneToObjectMapList,
    //                 selectedDateFields,
    //                 selectedOption,
    //                 daysAfterValue,
    //                 timeToSendValue,
    //                 campaignGroupsVariable.Is_Send_immediately__c
    //             );
    //             System.debug('createChatRecord: ' + createChatRecord);
    //         }

    //         // Return the ID of the newly created Marketing Campaign
    //         // return campaign.Id;
    //     } catch (Exception e) {
    //         // Handle any exceptions and throw a user-friendly error
    //         System.debug(e.getLineNumber());
    //         throw new AuraHandledException('Error creating Marketing Campaign: ' + e.getMessage());
    //     }
    // }
    @AuraEnabled
public static void createMarketingCampaign(String campaignData) {
    try {
        // Deserialize the JSON string into a Map
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(campaignData);
        System.debug('dataMap: ' + dataMap);

        // Extract basic fields
        String name = (String) dataMap.get('name');
        String description = (String) dataMap.get('description');
        String objectName = (String) dataMap.get('objectName');
        Boolean isMarketingCampaign = (Boolean) dataMap.get('isMarketingCampaign');
        String selectedOption = (String) dataMap.get('selectedOption');
        String selectedDate = (String) dataMap.get('selectedDate');
        String selectedDateFields = (String) dataMap.get('selectedDateFields');
        List<Object> rawGroupList = (List<Object>) dataMap.get('groupIdList');
        List<String> groupId = new List<String>();

        for (Object obj : rawGroupList) {
            Map<String, Object> groupMap = (Map<String, Object>) obj;
            groupId.add((String) groupMap.get('Id'));
        }

        List<Object> rawEmailConfigs = (List<Object>) dataMap.get('emailConfigs');
        List<Map<String, Object>> emailConfigs = new List<Map<String, Object>>();

        for (Object rawItem : rawEmailConfigs) {
            emailConfigs.add((Map<String, Object>) rawItem);
        }

        Map<String, SObject> phoneToObjectMapList;
        if (selectedOption == 'related') {
            phoneToObjectMapList = getObjectDetails(objectName, selectedDateFields);
        } else {
            phoneToObjectMapList = new Map<String, SObject>();
        }

        // Create a new Marketing Campaign record
        WB_Marketing_campaign__c campaign = new WB_Marketing_campaign__c(
            Name = name,
            Marketing_Campaign_Description__c = description,
            Object_Name__c = objectName,
            hasExistingMarketingCampaign__c = isMarketingCampaign,
            Group_Id_List__c = String.join(groupId, ',')
        );

        // Insert the Marketing Campaign record
        Database.insert(campaign, false, AccessLevel.USER_MODE);

        List<WB_Marketing_campaign_group__c> campaignGroups = new List<WB_Marketing_campaign_group__c>();

        if (emailConfigs != null && !emailConfigs.isEmpty()) {
            for (Map<String, Object> emailConfig : emailConfigs) {
                String templateId = String.valueOf(emailConfig.get('template'));
                String daysAfter = String.valueOf(emailConfig.get('daysAfter'));
                String timeToSend = String.valueOf(emailConfig.get('timeToSend'));
                String isSendImmediately = String.valueOf(emailConfig.get('isImmediateSelected'));

                Integer daysAfterValue = null;
                if (daysAfter != null) {
                    try {
                        daysAfterValue = Integer.valueOf(daysAfter);
                    } catch (Exception e) {
                        throw new AuraHandledException('Invalid value for Days_After__c: ' + daysAfter);
                    }
                }

                Time timeToSendValue = null;
                if (timeToSend != null && String.valueOf(timeToSend).trim() != '') {
                    try {
                        List<String> timeParts = timeToSend.split(':');
                        Integer hours = Integer.valueOf(timeParts[0]);
                        Integer minutes = Integer.valueOf(timeParts[1]);
                        Integer seconds = Integer.valueOf(timeParts[2]);
                        timeToSendValue = Time.newInstance(hours, minutes, seconds, 0);
                    } catch (Exception e) {
                        throw new AuraHandledException('Invalid value for Time_To_Send__c: ' + timeToSend);
                    }
                }

                WB_Marketing_campaign_group__c campaignGroup = new WB_Marketing_campaign_group__c(
                    WB_Marketing_campaign__c = campaign.Id,
                    WB_Template__c = templateId,
                    Status__c = 'Pending',
                    Days_After__c = daysAfterValue,
                    Time_To_Send__c = timeToSendValue,
                    Is_Send_immediately__c = isSendImmediately == 'true',
                    Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null,
                    Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null
                );
                campaignGroups.add(campaignGroup);
            }
        }

        if (!campaignGroups.isEmpty()) {
            Database.insert(campaignGroups, false, AccessLevel.USER_MODE);
        }

        List<Broadcast_Group__c> brGroupRecs = [SELECT Id, Name, Object_Name__c FROM Broadcast_Group__c WHERE Id IN :groupId];
        List<Broadcast_Group_Member__c> groupMembers = [SELECT Id, Name, Phone_Number__c, Broadcast_Group_ID__c FROM Broadcast_Group_Member__c WHERE Broadcast_Group_ID__c IN :groupId WITH SECURITY_ENFORCED];


        List<Chat__c> chatRecords = new List<Chat__c>();
        List<WB_Marketing_campaign_member__c> campaignMembers = new List<WB_Marketing_campaign_member__c>();

        for (WB_Marketing_campaign_group__c campaignGroup : campaignGroups) {
            Integer daysAfterValue = (campaignGroup.Days_After__c != null) ? Integer.valueOf(campaignGroup.Days_After__c) : null;
            Time timeToSendValue = campaignGroup.Time_To_Send__c;

            createChatRecodsMarketing(
                campaignGroup.WB_Template__c,
                groupId,
                selectedDate,
                campaign.Id,
                campaignGroup.Id,
                phoneToObjectMapList,
                selectedDateFields,
                selectedOption,
                daysAfterValue,
                timeToSendValue,
                campaignGroup.Is_Send_immediately__c,
                chatRecords,
                campaignMembers,
                brGroupRecs,
                groupMembers
            );
        }

        if (!chatRecords.isEmpty()) {
            Database.insert(chatRecords, false, AccessLevel.USER_MODE);
            for (Integer i = 0; i < chatRecords.size(); i++) {
                campaignMembers[i].Chat_Record_Id__c = chatRecords[i].Id; // Store Chat__c ID
            }
        }

        if (!campaignMembers.isEmpty()) {
            Database.insert(campaignMembers, false, AccessLevel.USER_MODE);
        }

    } catch (Exception e) {
        throw new AuraHandledException('Error creating Marketing Campaign: ' + e.getMessage());
    }
}

public static void createChatRecodsMarketing(
    String templateId,
    List<String> groupIds,
    String dateFieldValue,
    String campaignId,
    String campaignGroupId,
    Map<String, SObject> phoneToObjectMapList,
    String selectedDateFields,
    String selectedOption,
    Integer dayAfter,
    Time timeToSend,
    Boolean isSendImmediate,
    List<Chat__c> chatRecords,
    List<WB_Marketing_campaign_member__c> campaignMembers,
    List<Broadcast_Group__c> brGroupRecs1,
    List<Broadcast_Group_Member__c> groupMembers1    

) {
    try {
        if (groupIds.size() > 0) {
            List<Broadcast_Group__c> brGroupRecs = brGroupRecs1;
            List<Broadcast_Group_Member__c> groupMembers = groupMembers1;
            for (Broadcast_Group_Member__c member : groupMembers) {
                DateTime dateValue;
                if (selectedOption == 'related' && phoneToObjectMapList.containsKey(member.Phone_Number__c)) {
                    dateValue = (DateTime) phoneToObjectMapList.get(member.Phone_Number__c).get(selectedDateFields);
                } else {
                    Date dateFieldValueStr = Date.valueOf(dateFieldValue);
                    dateValue = DateTime.newInstance(dateFieldValueStr, Time.newInstance(0, 0, 0, 0));
                }

                if (dateValue != null) {
                    dateValue = dateValue.addDays(dayAfter != null ? dayAfter : 0);

                    if (timeToSend != null || isSendImmediate == true) {
                        DateTime combinedDateTime;
                        if (isSendImmediate == true) {
                            combinedDateTime = DateTime.now().addMinutes(1);
                        } else {
                            combinedDateTime = DateTime.newInstance(dateValue.date(), timeToSend);
                        }
                        dateValue = combinedDateTime;
                    }
                }

                if (member.Phone_Number__c != null && member.Phone_Number__c != '') {
                    Chat__c newChat = new Chat__c(
                        Whatsapp_Template__c = templateId,
                        Phone__c = member.Phone_Number__c,
                        Type_of_Message__c = 'OutBound Messages',
                        Message_Status__c = null,
                        Message_Type__c = 'Template'
                    );
                    chatRecords.add(newChat);

                    WB_Marketing_campaign_member__c campaignMember = new WB_Marketing_campaign_member__c(
                        Member_Phone__c = member.Phone_Number__c,
                        Name = member.Name,
                        Member_Name__c = member.Name,
                        Schedule_Date__c = dateValue,
                        WB_Marketing_campaign__c = campaignId,
                        WB_Marketing_campaign_group__c = campaignGroupId,
                        Chat_Record_Id__c = null,
                        Status__c = 'Pending'
                    );
                    campaignMembers.add(campaignMember);
                }
            }

        }
    } catch (Exception e) {
        throw new AuraHandledException('Error in createChatRecodsMarketing: ' + e.getMessage());
    }
}

// @AuraEnabled
// public static void updateMarketingCampaign(String campaignData) {
//     try {
//         // Deserialize the JSON string into a Map
//         Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(campaignData);
//         System.debug('dataMap: ' + dataMap);

//         // Extract basic fields
//         String campaignId = (String) dataMap.get('id');
//         String name = (String) dataMap.get('name');
//         String description = (String) dataMap.get('description');
//         String objectName = (String) dataMap.get('objectName');
//         Boolean isMarketingCampaign = (Boolean) dataMap.get('isMarketingCampaign');
//         String selectedOption = (String) dataMap.get('selectedOption');
//         String selectedDate = (String) dataMap.get('selectedDate');
//         String selectedDateFields = (String) dataMap.get('selectedDateFields');

//         // Extract and process groupIdList
//         List<Object> rawGroupList = (List<Object>) dataMap.get('groupIdList');
//         List<String> groupId = new List<String>();
//         for (Object obj : rawGroupList) {
//             groupId.add((String) obj);
//         }
//         String groupIdCommaSeparated = String.join(groupId, ',');

//         // Extract email configurations
//         List<Object> rawEmailConfigs = (List<Object>) dataMap.get('emailConfigs');
//         List<Map<String, Object>> emailConfigs = new List<Map<String, Object>>();
//         for (Object rawItem : rawEmailConfigs) {
//             emailConfigs.add((Map<String, Object>) rawItem);
//         }

//         // Fetch the existing campaign record
//         WB_Marketing_campaign__c campaign = [
//             SELECT Id, Name, Marketing_Campaign_Description__c, Object_Name__c, 
//                    hasExistingMarketingCampaign__c, Group_Id_List__c
//             FROM WB_Marketing_campaign__c
//             WHERE Id = :campaignId
//             LIMIT 1
//         ];

//         // Update the campaign fields
//         campaign.Name = name;
//         campaign.Marketing_Campaign_Description__c = description;
//         campaign.Object_Name__c = objectName;
//         campaign.hasExistingMarketingCampaign__c = isMarketingCampaign;
//         campaign.Group_Id_List__c = groupIdCommaSeparated;

//         // Update the campaign record
//         update campaign;

//         // Fetch existing campaign groups
//         Map<Id, WB_Marketing_campaign_group__c> existingGroupsMap = new Map<Id, WB_Marketing_campaign_group__c>(
//             [SELECT Id, WB_Template__c, Days_After__c, Time_To_Send__c, Is_Send_Immediately__c, 
//                     Specific_Date__c, Relate_Date_Field__c 
//              FROM WB_Marketing_campaign_group__c 
//              WHERE WB_Marketing_campaign__c = :campaignId]
//         );

//         // Prepare lists for insert, update, and delete
//         List<WB_Marketing_campaign_group__c> groupsToInsert = new List<WB_Marketing_campaign_group__c>();
//         List<WB_Marketing_campaign_group__c> groupsToUpdate = new List<WB_Marketing_campaign_group__c>();
//         Set<Id> updatedGroupIds = new Set<Id>();

//         // Process email configurations
//         for (Map<String, Object> emailConfig : emailConfigs) {
//             String groupIdValue = String.valueOf(emailConfig.get('groupId'));
//             String templateId = String.valueOf(emailConfig.get('template'));
//             String daysAfter = String.valueOf(emailConfig.get('daysAfter'));
//             String timeToSend = String.valueOf(emailConfig.get('timeToSend'));
//             String isSendImmediately = String.valueOf(emailConfig.get('isImmediateSelected'));

//             Integer daysAfterValue = (daysAfter != null) ? Integer.valueOf(daysAfter) : null;
//             Time timeToSendValue = (timeToSend != null && String.valueOf(timeToSend).trim() != '') 
//                 ? Time.newInstance(Integer.valueOf(timeToSend.split(':')[0]), Integer.valueOf(timeToSend.split(':')[1]), Integer.valueOf(timeToSend.split(':')[2]), 0) 
//                 : null;

//             if (groupIdValue != null && existingGroupsMap.containsKey(groupIdValue)) {
//                 WB_Marketing_campaign_group__c existingGroup = existingGroupsMap.get(groupIdValue);
//                 existingGroup.WB_Template__c = templateId;
//                 existingGroup.Days_After__c = daysAfterValue;
//                 existingGroup.Time_To_Send__c = timeToSendValue;
//                 existingGroup.Is_Send_immediately__c = isSendImmediately == 'true';
//                 existingGroup.Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null;
//                 existingGroup.Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null;
//                 groupsToUpdate.add(existingGroup);
//                 updatedGroupIds.add(existingGroup.Id);
//             } else {
//                 WB_Marketing_campaign_group__c newGroup = new WB_Marketing_campaign_group__c(
//                     WB_Marketing_campaign__c = campaign.Id,
//                     WB_Template__c = templateId,
//                     Status__c = 'Pending',
//                     Days_After__c = daysAfterValue,
//                     Time_To_Send__c = timeToSendValue,
//                     Is_Send_immediately__c = isSendImmediately == 'true',
//                     Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null,
//                     Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null
//                 );
//                 groupsToInsert.add(newGroup);
//             }
//         }

//         // Identify groups to delete
//         List<WB_Marketing_campaign_group__c> groupsToDelete = new List<WB_Marketing_campaign_group__c>();
//         for (Id existingGroupId : existingGroupsMap.keySet()) {
//             if (!updatedGroupIds.contains(existingGroupId)) {
//                 groupsToDelete.add(existingGroupsMap.get(existingGroupId));
//             }
//         }

//         // Perform DML operations
//         if (!groupsToInsert.isEmpty()) {
//             insert groupsToInsert;
//         }
//         if (!groupsToUpdate.isEmpty()) {
//             update groupsToUpdate;
//         }
//         if (!groupsToDelete.isEmpty()) {
//             delete groupsToDelete;
//         }

//     } catch (Exception e) {
//         throw new AuraHandledException('Error updating Marketing Campaign: ' + e.getMessage());
//     }
// }


// @AuraEnabled
// public static void updateChatRecordsMarketing(String templateId, List<String> groupIds, String dateFieldValue, String campaignId, String campaignGroupId, Map<String, SObject> phoneToObjectMapList, String selectedDateFields, String selectedOption, Integer dayAfter, Time timeToSend, Boolean isSendImmediate) {
//     try {
//         List<Chat__c> chatRecsToUpdate = new List<Chat__c>();
//         List<WB_Marketing_campaign_member__c> marketingMembersToUpdate = new List<WB_Marketing_campaign_member__c>();

//         if (groupIds.size() > 0) {
//             List<Broadcast_Group_Member__c> groupMembers = [
//                 SELECT Id, Name, Phone_Number__c, Broadcast_Group_ID__c 
//                 FROM Broadcast_Group_Member__c 
//                 WHERE Broadcast_Group_ID__c IN :groupIds WITH SECURITY_ENFORCED
//             ];

//             for (Broadcast_Group_Member__c member : groupMembers) {
//                 DateTime dateValue;
//                 if (selectedOption == 'related' && phoneToObjectMapList.containsKey(member.Phone_Number__c)) {
//                     dateValue = (DateTime) phoneToObjectMapList.get(member.Phone_Number__c).get(selectedDateFields);
//                 } else {
//                     Date dateFieldValueStr = Date.valueOf(dateFieldValue);
//                     dateValue = DateTime.newInstance(dateFieldValueStr, Time.newInstance(0, 0, 0, 0));
//                 }

//                 if (dateValue != null) {
//                     dateValue = dateValue.addDays(dayAfter != null ? dayAfter : 0);

//                     if (timeToSend != null || isSendImmediate == true) {
//                         dateValue = (isSendImmediate == true) 
//                             ? DateTime.now().addMinutes(1) 
//                             : DateTime.newInstance(dateValue.date(), timeToSend);
//                     }
//                 }

//                 if (member.Phone_Number__c != null && member.Phone_Number__c != '') {
//                     List<Chat__c> existingChats = [
//                         SELECT Id, Whatsapp_Template__c, Phone__c 
//                         FROM Chat__c 
//                         WHERE Phone__c = :member.Phone_Number__c AND Whatsapp_Template__c = :templateId 
//                         LIMIT 1
//                     ];
//                     if (!existingChats.isEmpty()) {
//                         Chat__c existingChat = existingChats[0];
//                         existingChat.Whatsapp_Template__c = templateId;
//                         chatRecsToUpdate.add(existingChat);
//                     }

//                     List<WB_Marketing_campaign_member__c> existingMembers = [
//                         SELECT Id, Member_Phone__c, Schedule_Date__c 
//                         FROM WB_Marketing_campaign_member__c 
//                         WHERE Member_Phone__c = :member.Phone_Number__c AND WB_Marketing_campaign_group__c = :campaignGroupId 
//                         LIMIT 1
//                     ];
//                     if (!existingMembers.isEmpty()) {
//                         WB_Marketing_campaign_member__c existingMember = existingMembers[0];
//                         existingMember.Schedule_Date__c = dateValue;
//                         existingMember.Status__c = 'Pending';
//                         marketingMembersToUpdate.add(existingMember);
//                     }
//                 }
//             }
//         }

//         // Perform DML operations
//         if (!chatRecsToUpdate.isEmpty()) {
//             update chatRecsToUpdate;
//         }
//         if (!marketingMembersToUpdate.isEmpty()) {
//             update marketingMembersToUpdate;
//         }

//     } catch (Exception e) {
//         throw new AuraHandledException('Error in updateChatRecordsMarketing: ' + e.getMessage());
//     }
// }

@AuraEnabled
public static void updateMarketingCampaign(String campaignData) {
    try {
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(campaignData);
        String campaignId = (String) dataMap.get('id');

        // Query campaign record
        WB_Marketing_campaign__c campaign = [
            SELECT Id, Name, Marketing_Campaign_Description__c, Object_Name__c, 
                   hasExistingMarketingCampaign__c, Group_Id_List__c
            FROM WB_Marketing_campaign__c
            WHERE Id = :campaignId
            LIMIT 1
        ];

        // Update campaign fields
        campaign.Name = (String) dataMap.get('name');
        campaign.Marketing_Campaign_Description__c = (String) dataMap.get('description');
        campaign.Object_Name__c = (String) dataMap.get('objectName');
        campaign.hasExistingMarketingCampaign__c = (Boolean) dataMap.get('isMarketingCampaign');

        // Build Group Id list string
        List<String> groupIdList = new List<String>();
        for (Object obj : (List<Object>) dataMap.get('groupIdList')) {
            groupIdList.add((String) obj);
        }
        campaign.Group_Id_List__c = String.join(groupIdList, ',');

        // Update campaign record
        update campaign;

        // Query existing groups for campaign
        Map<Id, WB_Marketing_campaign_group__c> existingGroupsMap = new Map<Id, WB_Marketing_campaign_group__c>(
            [SELECT Id, WB_Template__c, Days_After__c, Time_To_Send__c, Is_Send_immediately__c, 
                    Specific_Date__c, Relate_Date_Field__c 
             FROM WB_Marketing_campaign_group__c 
             WHERE WB_Marketing_campaign__c = :campaignId]
        );

        List<WB_Marketing_campaign_group__c> groupsToInsert = new List<WB_Marketing_campaign_group__c>();
        List<WB_Marketing_campaign_group__c> groupsToUpdate = new List<WB_Marketing_campaign_group__c>();
        Set<Id> updatedGroupIds = new Set<Id>();

        String selectedOption = (String) dataMap.get('selectedOption');
        String selectedDate = (String) dataMap.get('selectedDate');
        String selectedDateFields = (String) dataMap.get('selectedDateFields');

        List<Object> emailConfigs = (List<Object>) dataMap.get('emailConfigs');

        // Process each email config (campaign group data)
        for (Object rawItem : emailConfigs) {
            Map<String, Object> emailConfig = (Map<String, Object>) rawItem;

            String groupIdValue = String.valueOf(emailConfig.get('groupId'));
            String templateId = String.valueOf(emailConfig.get('template'));
            String daysAfter = String.valueOf(emailConfig.get('daysAfter'));
            String timeToSendStr = String.valueOf(emailConfig.get('timeToSend'));
            String isSendImmediatelyStr = String.valueOf(emailConfig.get('isImmediateSelected'));

            Integer daysAfterValue = String.isNotBlank(daysAfter) ? Integer.valueOf(daysAfter) : null;
            Time timeToSend = (String.isNotBlank(timeToSendStr) && timeToSendStr.contains(':')) ?
                Time.newInstance(
                    Integer.valueOf(timeToSendStr.split(':')[0]),
                    Integer.valueOf(timeToSendStr.split(':')[1]),
                    Integer.valueOf(timeToSendStr.split(':')[2]),
                    0
                ) : null;

            Boolean isSendImmediately = isSendImmediatelyStr == 'true';

            if (String.isNotBlank(groupIdValue) && existingGroupsMap.containsKey(groupIdValue)) {
                WB_Marketing_campaign_group__c campaignGroup = existingGroupsMap.get(groupIdValue);
                campaignGroup.WB_Template__c = templateId;
                campaignGroup.Days_After__c = daysAfterValue;
                campaignGroup.Time_To_Send__c = timeToSend;
                campaignGroup.Is_Send_immediately__c = isSendImmediately;
                campaignGroup.Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null;
                campaignGroup.Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null;
                groupsToUpdate.add(campaignGroup);
                updatedGroupIds.add(campaignGroup.Id);
            } else {
                WB_Marketing_campaign_group__c newGroup = new WB_Marketing_campaign_group__c(
                    WB_Marketing_campaign__c = campaign.Id,
                    WB_Template__c = templateId,
                    Status__c = 'Pending',
                    Days_After__c = daysAfterValue,
                    Time_To_Send__c = timeToSend,
                    Is_Send_immediately__c = isSendImmediately,
                    Specific_Date__c = (selectedOption == 'specific' && selectedDate != null) ? Date.valueOf(selectedDate) : null,
                    Relate_Date_Field__c = (selectedOption == 'related' && selectedDateFields != null) ? selectedDateFields : null
                );
                groupsToInsert.add(newGroup);
            }
        }

        // Groups to delete: existing groups not in updatedGroupIds
        List<WB_Marketing_campaign_group__c> groupsToDelete = new List<WB_Marketing_campaign_group__c>();
        for (Id existingGroupId : existingGroupsMap.keySet()) {
            if (!updatedGroupIds.contains(existingGroupId)) {
                groupsToDelete.add(existingGroupsMap.get(existingGroupId));
            }
        }

        // Bulk DML on groups
        if (!groupsToInsert.isEmpty()) insert groupsToInsert;
        if (!groupsToUpdate.isEmpty()) update groupsToUpdate;
        if (!groupsToDelete.isEmpty()) delete groupsToDelete;

        // Call updateChatRecordsMarketing to sync chat & campaign member records
        updateChatRecordsMarketing(
            campaign.Id,
            emailConfigs,
            selectedOption,
            selectedDate,
            selectedDateFields
        );

    } catch (Exception e) {
        throw new AuraHandledException('Error updating Marketing Campaign: ' + e.getMessage());
    }
}


@AuraEnabled
public static void updateChatRecordsMarketing(
    Id campaignId,
    List<Object> emailConfigs,
    String selectedOption,
    String selectedDate,
    String selectedDateFields
) {
    try {
        // Get all group IDs from emailConfigs
        Set<Id> groupIds = new Set<Id>();
        for (Object rawItem : emailConfigs) {
            Map<String, Object> emailConfig = (Map<String, Object>) rawItem;
            String groupIdStr = String.valueOf(emailConfig.get('groupId'));
            if (String.isNotBlank(groupIdStr)) {
                groupIds.add(Id.valueOf(groupIdStr));
            }
        }

        if (groupIds.isEmpty()) {
            return; // Nothing to update
        }

        // Query all group members for these groups
        List<WB_Marketing_campaign_member__c> groupMembers = [
            SELECT Id, Member_Phone__c, WB_Marketing_campaign_group__c
            FROM WB_Marketing_campaign_member__c
            WHERE WB_Marketing_campaign_group__c IN :groupIds
        ];
        System.debug('Group members: ' + groupMembers);
        // Query existing Chat records for these members and templates
        Set<String> phoneNumbers = new Set<String>();
        for (WB_Marketing_campaign_member__c m : groupMembers) {
            if (String.isNotBlank(m.Member_Phone__c)) phoneNumbers.add(m.Member_Phone__c);
        }

        System.debug('Phone numbers: ' + phoneNumbers);

        // Collect all template IDs from emailConfigs
        Set<String> templateIds = new Set<String>();
        for (Object rawItem : emailConfigs) {
            Map<String, Object> emailConfig = (Map<String, Object>) rawItem;
            String templateId = String.valueOf(emailConfig.get('template'));
            if (String.isNotBlank(templateId)) templateIds.add(templateId);
        }

        // Query existing chat records for these phones and templates
        List<Chat__c> existingChats = [
            SELECT Id, Whatsapp_Template__c, Phone__c
            FROM Chat__c
            WHERE Phone__c IN :phoneNumbers AND Whatsapp_Template__c IN :templateIds
        ];

        // Map for quick lookup: Phone + Template -> Chat__c
        Map<String, Chat__c> phoneTemplateToChatMap = new Map<String, Chat__c>();
        for (Chat__c chat : existingChats) {
            phoneTemplateToChatMap.put(chat.Phone__c + '-' + chat.Whatsapp_Template__c, chat);
        }

        System.debug('Phone numbe :: '+phoneNumbers);
        System.debug('Group Id :: '+groupIds);
        // Query existing marketing campaign members for these phones and groups
        List<WB_Marketing_campaign_member__c> existingMembers = [
            SELECT Id, Member_Phone__c, WB_Marketing_campaign_group__c, Schedule_Date__c, Status__c
            FROM WB_Marketing_campaign_member__c
            WHERE Member_Phone__c IN :phoneNumbers AND WB_Marketing_campaign_group__c IN :groupIds
        ];

        // Map for quick lookup: Phone + Group -> Member
        Map<String, WB_Marketing_campaign_member__c> phoneGroupToMemberMap = new Map<String, WB_Marketing_campaign_member__c>();
        for (WB_Marketing_campaign_member__c member : existingMembers) {
            phoneGroupToMemberMap.put(member.Member_Phone__c + '-' + String.valueOf(member.WB_Marketing_campaign_group__c), member);
        }
        System.debug('778 Existing member :: '+existingMembers);
        // Prepare lists for DML
        List<Chat__c> chatsToInsert = new List<Chat__c>();
        List<Chat__c> chatsToUpdate = new List<Chat__c>();

        List<WB_Marketing_campaign_member__c> membersToInsert = new List<WB_Marketing_campaign_member__c>();
        List<WB_Marketing_campaign_member__c> membersToUpdate = new List<WB_Marketing_campaign_member__c>();

        // Track processed members for deletion logic
        Set<String> processedPhoneGroupKeys = new Set<String>();

        // For converting selectedDate string to Date
        Date baseDate = selectedDate != null ? Date.valueOf(selectedDate) : null;

        for (Object rawItem : emailConfigs) {
            Map<String, Object> emailConfig = (Map<String, Object>) rawItem;

            String groupIdStr = String.valueOf(emailConfig.get('groupId'));
            Id groupId = (String.isNotBlank(groupIdStr)) ? Id.valueOf(groupIdStr) : null;

            String templateId = String.valueOf(emailConfig.get('template'));
            String daysAfterStr = String.valueOf(emailConfig.get('daysAfter'));
            String timeToSendStr = String.valueOf(emailConfig.get('timeToSend'));
            String isSendImmediatelyStr = String.valueOf(emailConfig.get('isImmediateSelected'));

            Integer daysAfter = String.isNotBlank(daysAfterStr) ? Integer.valueOf(daysAfterStr) : 0;
            Boolean isSendImmediate = isSendImmediatelyStr == 'true';

            Time timeToSend = (String.isNotBlank(timeToSendStr) && timeToSendStr.contains(':')) ?
                Time.newInstance(
                    Integer.valueOf(timeToSendStr.split(':')[0]),
                    Integer.valueOf(timeToSendStr.split(':')[1]),
                    Integer.valueOf(timeToSendStr.split(':')[2]),
                    0
                ) : null;

            for (WB_Marketing_campaign_member__c member : groupMembers) {
                if (member.WB_Marketing_campaign_group__c != groupId) continue;

                String phone = member.Member_Phone__c;
                if (String.isBlank(phone)) continue;

                // Calculate schedule date/time
                DateTime scheduleDateTime;

                if (isSendImmediate) {
                    scheduleDateTime = DateTime.now();
                } else if (selectedOption == 'specific' && baseDate != null) {
                    // Use specific date plus time
                    scheduleDateTime = DateTime.newInstance(baseDate, timeToSend != null ? timeToSend : Time.newInstance(0,0,0,0));
                } else if (selectedOption == 'related' && selectedDateFields != null) {
                    // Here, add logic if you have related date fields to calculate from
                    // For now, just use current datetime
                    scheduleDateTime = DateTime.now().addDays(daysAfter);
                } else {
                    // Default fallback
                    scheduleDateTime = DateTime.now().addDays(daysAfter);
                }

                // Upsert WB_Marketing_campaign_member__c
                String phoneGroupKey = phone + '-' + groupId;
                processedPhoneGroupKeys.add(phoneGroupKey);
                System.debug('840 Member to update ::: '+membersToUpdate);
                WB_Marketing_campaign_member__c memberRecord;
                if (phoneGroupToMemberMap.containsKey(phoneGroupKey)) {
                    memberRecord = phoneGroupToMemberMap.get(phoneGroupKey);
                    memberRecord.Schedule_Date__c = scheduleDateTime;
                    memberRecord.Status__c = 'Pending';
                    membersToUpdate.add(memberRecord);
                } else {
                    memberRecord = new WB_Marketing_campaign_member__c(
                        Member_Phone__c = phone,
                        WB_Marketing_campaign_group__c = groupId,
                        WB_Marketing_campaign__c = campaignId,
                        Schedule_Date__c = scheduleDateTime,
                        Status__c = 'Pending'
                    );
                    membersToInsert.add(memberRecord);
                }

                // Upsert Chat__c
                String phoneTemplateKey = phone + '-' + templateId;
                if (phoneTemplateToChatMap.containsKey(phoneTemplateKey)) {
                    Chat__c chat = phoneTemplateToChatMap.get(phoneTemplateKey);
                    // If you want to update fields, do it here
                    chatsToUpdate.add(chat);
                } else {
                    Chat__c newChat = new Chat__c(
                        Phone__c = phone,
                        Whatsapp_Template__c = templateId
                    );
                    chatsToInsert.add(newChat);
                }
            }
        }

        // Delete campaign members and chats that are no longer valid
        List<WB_Marketing_campaign_member__c> membersToDelete = new List<WB_Marketing_campaign_member__c>();
        for (WB_Marketing_campaign_member__c existingMember : existingMembers) {
            String key = existingMember.Member_Phone__c + '-' + String.valueOf(existingMember.WB_Marketing_campaign_group__c);
            if (!processedPhoneGroupKeys.contains(key)) {
                membersToDelete.add(existingMember);
            }
        }

        List<Chat__c> chatsToDelete = new List<Chat__c>();
        Set<String> validPhoneTemplateKeys = new Set<String>();
        for (Object rawItem : emailConfigs) {
            Map<String, Object> emailConfig = (Map<String, Object>) rawItem;
            String templateId = String.valueOf(emailConfig.get('template'));
            for (WB_Marketing_campaign_member__c member : groupMembers) {
                if (String.isNotBlank(member.Member_Phone__c)) {
                    validPhoneTemplateKeys.add(member.Member_Phone__c + '-' + templateId);
                }
            }
        }
        for (Chat__c chat : existingChats) {
            String key = chat.Phone__c + '-' + chat.Whatsapp_Template__c;
            if (!validPhoneTemplateKeys.contains(key)) {
                chatsToDelete.add(chat);
            }
        }

        // Perform bulk DML operations
        if (!membersToInsert.isEmpty()) insert membersToInsert;
        if (!membersToUpdate.isEmpty()) update membersToUpdate;
        if (!membersToDelete.isEmpty()) delete membersToDelete;

        if (!chatsToInsert.isEmpty()) insert chatsToInsert;
        if (!chatsToUpdate.isEmpty()) update chatsToUpdate;
        if (!chatsToDelete.isEmpty()) delete chatsToDelete;

    } catch (Exception e) {
        throw new AuraHandledException('Error updating Chat Records: ' + e.getMessage());
    }
}



    
    /*
    *********************************************************
    @description     : Generate a cron expression based on the provided DateTime
    @param           : dt - DateTime object
    @return          : String representing the cron expression
    ********************************************************
    */

    public static Map<String, SObject> getObjectDetails(String objectName, String fieldName) {
        try {
            // Check if the object and field exist
            List<MVWB__Object_Config__mdt> objectConfigList = [SELECT Id, MVWB__ObjectConfigInfo__c, MVWB__ChatWindowConfigInfo__c FROM MVWB__Object_Config__mdt LIMIT 1];
            Map<String, Object> chatConfigData = (Map<String, Object>) JSON.deserializeUntyped(objectConfigList[0].MVWB__ChatWindowConfigInfo__c);Map<String, Object> chatConfig = (Map<String, Object>) chatConfigData.get(objectName);
            String phoneField = (String) chatConfig.get('phoneField');
            // if (!Schema.getGlobalDescribe().containsKey(objectName)) {
            //     throw new AuraHandledException('Object ' + objectName + ' does not exist.');
            // }
    
            // Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            // if (!fieldMap.containsKey(fieldName)) {
            //     throw new AuraHandledException('Field ' + fieldName + ' does not exist on object ' + objectName + '.');
            // }
    
            // Build the dynamic SOQL query
            System.debug('Query ::: '+'SELECT Id,'+phoneField+' ' + fieldName + ' FROM ' + objectName);
            String query = 'SELECT Id,'+phoneField+',' + fieldName + ' FROM ' + objectName;
    
            List<SObject> getObjectList = Database.query(query);
            Map<String, SObject> phoneToObjectMap = new Map<String, SObject>();

            for (SObject objectValue : getObjectList) {
                // Assuming the phone field is named 'Phone'
                String phone = (String) objectValue.get(phoneField);
                if (phone != null && phone != '') {
                    phoneToObjectMap.put(phone, objectValue);
                }
            }

            return phoneToObjectMap;


        } catch (Exception e) {
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }

 
    @InvocableMethod(callout=true)
public static List<InvocableResult> getScheduleMessage(List<InvocableInput> inputMemberIdList) {
    List<InvocableResult> results = new List<InvocableResult>();

    try {
        System.debug('In Invocable Method');
        System.debug('memberIds: ' + inputMemberIdList);

        // Ensure the input list is not empty
        if (inputMemberIdList == null || inputMemberIdList.isEmpty()) {
            throw new AuraHandledException('No memberId provided.');
        }

        // Process each input memberId
        for (InvocableInput input : inputMemberIdList) {
            // Query the Marketing Campaign Member record
            List<WB_Marketing_campaign_member__c> member = [
                SELECT Id, Member_Name__c, Member_Phone__c, Schedule_Date__c, 
                       WB_Marketing_Campaign_Group__r.WB_Template__c, 
                       WB_Marketing_Campaign_Group__r.Days_After__c, 
                       WB_Marketing_Campaign_Group__r.Time_To_Send__c, 
                       WB_Marketing_Campaign_Group__r.Is_Send_immediately__c, 
                       WB_Marketing_Campaign__r.Name, 
                       WB_Marketing_Campaign__r.Marketing_Campaign_Description__c,
                       WB_Marketing_Campaign__r.Object_Name__c,
                       Status__c,Chat_Record_Id__c
                FROM WB_Marketing_campaign_member__c
                WHERE Id = :input.memberId
                LIMIT 1 
            ];

            System.debug('member: ' + member);

            // Validate if the member has a phone number
            if (String.isBlank(member[0].Member_Phone__c)) {
                System.debug('Member does not have a phone number.');
                // throw new AuraHandledException('Member does not have a phone number.');
            }

            MarketingMessageBatch batchJob = new MarketingMessageBatch(member);
            Database.executeBatch(batchJob, 1);


        }
    } catch (Exception e) {
        System.debug('Error in getScheduleMessage: ' + e.getMessage());
        ExceptionHandler.logException(new Map<String, Object>{
            'className' => 'MarketingMessageController',
            'methodName' => 'getScheduleMessage',
            'exceptionObj' => e,
            'isApiException' => false,
            'statusCode' => null,
            'chatId' => null,
            'moreDetails' => e.getMessage(),
            'apiResponse' => null
        });

        // Add failure result
        InvocableResult result = new InvocableResult();
        result.res = 'Error: ' + e.getMessage();
        results.add(result);

        // throw new AuraHandledException('Error in getScheduleMessage: ' + e.getMessage());
        System.debug('Error in getScheduleMessage: ' + e.getMessage());
    }

    return results;
}

    public class InvocableInput {
        @InvocableVariable(required=true label='memberId')
        public String memberId;
    }

    public class InvocableResult {
        @InvocableVariable(label='Message')
        public String res;
    }

    @AuraEnabled
public static String deleteMarketingCampaign(Id campaignId) {
    try {
        // Confirm campaign exists
        WB_Marketing_campaign__c campaign = [
            SELECT Id FROM WB_Marketing_campaign__c WHERE Id = :campaignId LIMIT 1
        ];

        // Query related members of this campaign along with Chat_Record_Id__c
        List<WB_Marketing_campaign_member__c> relatedMembers = [
            SELECT Id, Chat_Record_Id__c FROM WB_Marketing_campaign_member__c WHERE WB_Marketing_campaign__c = :campaignId
        ];

        Set<Id> chatIdsToDelete = new Set<Id>();
        List<Id> memberIdsToDelete = new List<Id>();

        for (WB_Marketing_campaign_member__c member : relatedMembers) {
            if (member.Chat_Record_Id__c != null) {
                chatIdsToDelete.add(member.Chat_Record_Id__c);
            }
            memberIdsToDelete.add(member.Id);
        }

        // Delete related chat records first
        if (!chatIdsToDelete.isEmpty()) {
            List<Chat__c> chatsToDelete = [SELECT Id FROM Chat__c WHERE Id IN :chatIdsToDelete];
            delete chatsToDelete;
        }

        // Delete campaign members
        if (!memberIdsToDelete.isEmpty()) {
            delete relatedMembers;
        }

        // Finally delete the campaign itself
        delete campaign;

        return 'Success';

    } catch (Exception e) {
        return 'Error: ' + e.getMessage();
    }
}


    @AuraEnabled
    public static String getCampaignDetails(String campaignId) {
        try {
            // Fetch the marketing campaign details
            WB_Marketing_campaign__c campaign = [
                SELECT Id, Name, Marketing_Campaign_Description__c, Object_Name__c, 
                    Start_Date__c, End_Date__c, hasExistingMarketingCampaign__c, 
                    Group_Id_List__c
                FROM WB_Marketing_campaign__c
                WHERE Id = :campaignId
                LIMIT 1
            ];


            // Fetch associated email configuration records
            List<WB_Marketing_campaign_group__c> emailConfigs = [
                SELECT Id, WB_Template__c, Days_After__c, Time_To_Send__c, 
                    Is_Send_Immediately__c, Relate_Date_Field__c, Specific_Date__c, Status__c
                FROM WB_Marketing_campaign_group__c
                WHERE WB_Marketing_campaign__c = :campaignId
            ];

            // Prepare the response data in a map
            Map<String, Object> response = new Map<String, Object>();
            List<Broadcast_Group__c	> broadcastGroup = new List<Broadcast_Group__c	>();
            System.debug('group Id List ::: '+campaign.Group_Id_List__c);
            if (String.isNotBlank(campaign.Group_Id_List__c)) {
                List<String> groupIds = campaign.Group_Id_List__c.split(',');
                broadcastGroup = [SELECT Id, Name FROM Broadcast_Group__c WHERE Id IN :groupIds];
            }
            System.debug('broadcastGroup: ' + broadcastGroup);

            // Convert the list of names into a comma-separated string
            List<String> groupNames = new List<String>();
            for (Broadcast_Group__c member : broadcastGroup) {
                groupNames.add(member.Name);
            }
            String groupNamesCommaSeparated = String.join(groupNames, ',');

            // Debugging
            System.debug('Comma-separated Group Names: ' + groupNamesCommaSeparated);

            // Add data to the response map
            response.put('groupNames', groupNamesCommaSeparated);
            // response.put('groupNa', groupNamesCommaSeparated);
            
            response.put('campaign', campaign);
            response.put('emailConfigs', emailConfigs);
            
            if (!emailConfigs.isEmpty()) {
                response.put('selectedDate', emailConfigs[0].Specific_Date__c);
                response.put('selectedDateFields', emailConfigs[0].Relate_Date_Field__c);
                response.put('selectedOption', emailConfigs[0].Relate_Date_Field__c != null ? 'related' : 'specific');
            }

            // Serialize the map to a JSON string and return it
            return JSON.serialize(response);

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching campaign details: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static List<WB_Marketing_campaign__c> getCampaignRecs() {
        return [SELECT Id, Name, Marketing_campaign_Description__c, Start_Date__c, End_Date__c, Status__c FROM WB_Marketing_campaign__c];
    }


        
    // global String templateId;
    // global List<Chat__c> chatsToProcess;
    // global String broadcastId;
    // global String objectApiName;
    public static List<Chat__c> chatsToUpdate = new List<Chat__c>();
    public static List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values(); 
    // global String phoneField;


    // @future(callout=true)
    public static void sendWhatsAppMessage(String chatId, String jsonBody) {
        try {
            List<Chat__c> chat = [SELECT Id, Phone__c, WhatsAppMessageId__c, Message_Status__c FROM Chat__c WHERE Id = :chatId LIMIT 1];
            System.debug('Chat Id ::: '+chatId);
            System.debug('Chat Phone ::: '+chat[0].Phone__c);
            System.debug('Json Body ::: '+jsonBody);
            HttpRequest httpReq = new HttpRequest();
            String accessToken = wbConfig[0].MVWB__Access_Token__c;
            String endpoint = 'https://graph.facebook.com/v21.0/' + wbConfig[0].MVWB__Phone_Number_Id__c + '/messages';
            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
            httpReq.setBody(jsonBody);
            Http http = new Http();
            HttpResponse response = http.send(httpReq);
            Integer statusCode = response.getStatusCode();
            if(response != null && statusCode == 200){
                String responseBody = response.getBody();
                Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                List<Object> messages = (List<Object>)jsonMap.get('messages');
                Map<String, Object> firstMessage = (Map<String, Object>)messages[0];
                String whatsAppMessageID = (String) firstMessage.get('id');
                chat[0].WhatsAppMessageId__c = whatsAppMessageID;
                chat[0].Message_Status__c = 'Sent';
            }else{
                chat[0].Message_Status__c = 'Failed';
                ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppMessageBatch', 'methodName' => 'sendWhatsAppMessage', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => statusCode, 'chatId' => chatId, 'moreDetails' => 'API Exception while sending a message', 'apiResponse' => JSON.serialize(response.getBody()) });
            }
            chatsToUpdate = chat;
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppMessageBatch', 'methodName' => 'sendWhatsAppMessage', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => '', 'chatId' => chatId, 'moreDetails' => '', 'apiResponse' => '' });
            // return null;
        }
    }
}