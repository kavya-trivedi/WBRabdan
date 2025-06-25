/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 04-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public without sharing class AutomationConfigTriggerHandler {
    private List<Chat__c> recordNewList = new List<Chat__c>();
    private List<Chat__c> recordOldList = new List<Chat__c>();
    private Map<Id, Chat__c> recordNewMap = new Map<Id, Chat__c>();
    private Map<Id, Chat__c> recordOldMap = new Map<Id, Chat__c>();
    private Boolean isInsert;
    private Boolean isUpdate;
    private Boolean isDelete = false;
    private Boolean isUndelete = false;
    private static final String CLASS_NAME = 'AutomationConfigTriggerHandler';
    public static List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values();
    
    public AutomationConfigTriggerHandler( List<Chat__c> newList,  List<Chat__c> oldList, Map<Id, Chat__c> newMap, Map<Id, Chat__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete) {
        this.recordNewList = newList;
        this.recordOldList = oldList;
        this.recordNewMap = newMap;
        this.recordOldMap = oldMap;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;
    }
    
    public void filterAndProcessValidChats() {
        try {
            List<Chat__c> validChats = new List<Chat__c>();
            Set<Id> replyToIds = new Set<Id>();
            
            for (Chat__c newChat : (List<Chat__c>)recordNewList) {
                if (newChat.Type_of_Message__c == 'Inbound Messages' && newChat.Reply_to__c != null) {
                    replyToIds.add(newChat.Reply_to__c);
                }
            }
            
            Map<Id, Chat__c> parentChatMap = new Map<Id, Chat__c>();
            if (!replyToIds.isEmpty()) {
                for (Chat__c parent : [ SELECT Id, Whatsapp_Template__r.WBButton_Body__c, Reply_to__c FROM Chat__c WHERE Id IN :replyToIds]) {
                    parentChatMap.put(parent.Id, parent);
                }
            }
            
            for (Chat__c newChat : (List<Chat__c>)recordNewList) {
                if (isValidAutomationChat(newChat, parentChatMap.get(newChat.Reply_to__c))) {
                    validChats.add(newChat);
                }
            }
            
            if (!validChats.isEmpty()) {
                processAutomationConfiguration(validChats);
            } else {
                System.debug('No valid messages found (Button/Interactive & Inbound Message). Exiting trigger.');
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'filterAndProcessValidChats','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
    }
    
    private Boolean isValidAutomationChat(Chat__c newChat, Chat__c parentChat) {
        try {
            if (newChat.Type_of_Message__c != 'Inbound Messages') {
                System.debug('Not an Inbound Message. Exiting. ' + newChat.Message__c + 'ID = ' + newChat.Id);
                return false;
            }
            
            String buttonType = null;
            
            if (newChat.Reply_to__c != null && parentChat != null && parentChat.Whatsapp_Template__r != null) {
                try {
                    String buttonBody = parentChat.Whatsapp_Template__r.WBButton_Body__c;
                    buttonType = getButtonTypeByText(buttonBody, newChat.Message__c);
                    System.debug('Button Type: ' + buttonType);
                } catch (Exception e) {
                    System.debug('Error parsing button JSON: ' + e.getMessage());
                }
            }
            
            return buttonType == 'QUICK_REPLY' || newChat.Message_Type__c == 'interactive';
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'isValidAutomationChat','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return null;
        }
    }
    
    public static String getButtonTypeByText(String jsonInput, String buttonText) {
        try {
            // Deserialize JSON into a raw List of Objects
            List<Object> rawButtons = (List<Object>) JSON.deserializeUntyped(jsonInput);
            
            // Iterate and safely cast each item to Map<String, Object>
            for (Object rawBtn : rawButtons) {
                Map<String, Object> btn = (Map<String, Object>) rawBtn;
                
                if (btn.containsKey('text') && btn.get('text') == buttonText) {
                    return (String) btn.get('type'); // Return the button type
                }
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'getButtonTypeByText','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return null;
        }
        return 'Not Found'; // Return "Not Found" if no matching text is found
    }
    
    public static void processAutomationConfiguration(List<Chat__c> newChats) {
        System.debug('Handler method called');
        try {   
            // Step 1: Collect context message IDs and filter relevant chats
            Set<String> contextMessageIds = new Set<String>();
            List<Chat__c> potentialPathReplies = new List<Chat__c>();
            
            for (Chat__c newChat : newChats) {
                // if (String.isNotBlank(newChat.WhatsAppContextMessageID__c)) {
                    contextMessageIds.add(newChat.WhatsAppContextMessageID__c);
                    if (String.isNotBlank(newChat.Message__c) || String.isNotBlank(newChat.Flow_Response_JSON__c)) {
                        System.debug('Adding to potentialPathReplies: ' + newChat.Flow_Response_JSON__c);
                        if(String.isNotBlank(newChat.Flow_Response_JSON__c)){
                            System.debug('Adding contextMessageId: ' + newChat.Reply_To__c);
                            Chat__c contextMessageId = [SELECT Id, WhatsAppMessageId__c FROM Chat__c WHERE Id = :newChat.Reply_to__c];
                            System.debug('Adding contextMessageId: ' + contextMessageId);
                            contextMessageIds.add(contextMessageId.WhatsAppMessageId__c);
                        }
                        potentialPathReplies.add(newChat);
                    }
                // }
            }
            
            if (contextMessageIds.isEmpty() || potentialPathReplies.isEmpty()) {
                System.debug('No valid replies found, exiting.');
                return;
            }
            System.debug('ContextMessageIds and PotentialPathReplies found');
            
            // Step 2: Get original messages and extract template IDs
            Map<String, Chat__c> originalChatsMap = fetchOriginalChats(contextMessageIds);
            Set<String> templateIdsToCheck = extractTemplateIds(originalChatsMap);
            
            if (templateIdsToCheck.isEmpty()) {
                System.debug('No templates found, exiting.');
                return;
            }
            System.debug('Template found on orginal messages.');
            
            // Step 3: Map Templates to Automation IDs
            Map<String, List<Id>> templateIdToAutomationIdMap = fetchAutomationMappings(templateIdsToCheck);
            if (templateIdToAutomationIdMap.isEmpty()) {
                System.debug('No matching Automations found, exiting.');
                return;
            }
            System.debug('Matching Automation records found.');
            System.debug('TemplateIdToAutomationIdMap: ' + templateIdToAutomationIdMap);
            
            // Step 4: Fetch Automation Paths
            Map<Id, Map<String, Automation_Path__c>> automationPathsMap = fetchAutomationPaths(templateIdToAutomationIdMap);
            if (automationPathsMap.isEmpty()) {
                System.debug('No Automation Paths found.');
            }
            System.debug('Automation Path records found.');
            
            // Step 5: Process matching chats and send responses
            processMatchingChats(potentialPathReplies, originalChatsMap, templateIdToAutomationIdMap, automationPathsMap);
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'processAutomationConfiguration','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
    }
    
    private static Map<String, Chat__c> fetchOriginalChats(Set<String> contextMessageIds) {
        try{
            System.debug('Fetching original chats for context message IDs: ' + contextMessageIds);
            Map<String, Chat__c> originalChatsMap = new Map<String, Chat__c>();
            
            for (Chat__c originalChat : [ SELECT Id, Whatsapp_Template__c, WhatsAppMessageId__c FROM Chat__c WHERE WhatsAppMessageId__c IN :contextMessageIds]) {
                if (originalChat.Whatsapp_Template__c != null) {
                    System.debug('Adding to originalChatsMap: ' + originalChat.WhatsAppMessageId__c);
                }
                if (originalChat.WhatsAppMessageId__c != null) {
                    originalChatsMap.put(originalChat.WhatsAppMessageId__c, originalChat);
                }
            }
            return originalChatsMap;
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'fetchOriginalChats','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return null;
        }
    }
    
    private static Set<String> extractTemplateIds(Map<String, Chat__c> originalChatsMap) {
        Set<String> templateIdsToCheck = new Set<String>();
        
        for (Chat__c chat : originalChatsMap.values()) {
            if (String.isNotBlank(chat.Whatsapp_Template__c)) {
                templateIdsToCheck.add(chat.Whatsapp_Template__c);
            }
        }
        return templateIdsToCheck;
    }
    
    private static Map<String, List<Id>> fetchAutomationMappings(Set<String> templateIdsToCheck) {
        try{
            Map<String, List<Id>> templateIdToAutomationIdMap = new Map<String, List<Id>>();
            for (Automation__c automation : [ SELECT Id, WB_Template__c FROM Automation__c WHERE WB_Template__c IN :templateIdsToCheck]) {
                if (automation.WB_Template__c != null) {
                    String templateId = automation.WB_Template__c;
                    System.debug(templateId + ' => ' + automation.Id);
                    
                    if (!templateIdToAutomationIdMap.containsKey(templateId)) {
                        templateIdToAutomationIdMap.put(templateId, new List<Id>());
                    }
                    templateIdToAutomationIdMap.get(templateId).add(automation.Id);
                }
            }
            return templateIdToAutomationIdMap;
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'fetchAutomationMappings','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return null;
        }
    }
    
    private static Map<Id, Map<String, Automation_Path__c>> fetchAutomationPaths(Map<String, List<Id>> templateIdToAutomationIdMap) {
        try{
            System.debug('Fetching Automation Paths for template IDs: ' + templateIdToAutomationIdMap);
            Map<Id, Map<String, Automation_Path__c>> automationPathsMap = new Map<Id, Map<String, Automation_Path__c>>();
            
            Set<Id> relevantAutomationIds = new Set<Id>();
            for (List<Id> automationIds : templateIdToAutomationIdMap.values()) {
                relevantAutomationIds.addAll(automationIds);
            }
            System.debug('Relevant Automation IDs: ' + relevantAutomationIds);
            
            for (Automation_Path__c path : [ SELECT Id, Automation__c, Button_Value__c, Action_Template__c, Action_Type__c, Action_Email_Template__c, Object_Name__c, Field_Mapping__c FROM Automation_Path__c WHERE Automation__c IN :relevantAutomationIds]) {
                System.debug('Adding to automationPathsMap: ' + path);

                if (path.Automation__c != null) {
                    if (!automationPathsMap.containsKey(path.Automation__c)) {
                        automationPathsMap.put(path.Automation__c, new Map<String, Automation_Path__c>());
                    }

                    // If Button_Value__c is provided, use it
                    if (String.isNotBlank(path.Button_Value__c)) {
                        String normalizedButtonValue = path.Button_Value__c.toLowerCase().trim();
                        automationPathsMap.get(path.Automation__c).put(normalizedButtonValue, path);
                    }

                    // Always map 'interactive' if Create a Record path with field mapping
                    if (path.Action_Type__c == 'Create a Record' && String.isNotBlank(path.Field_Mapping__c)) {
                        automationPathsMap.get(path.Automation__c).put('interactive', path);
                    }
                }
            }
            return automationPathsMap;
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'fetchAutomationPaths','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return null;
        }
    }
    
    private static void processMatchingChats(List<Chat__c> potentialPathReplies, Map<String, Chat__c> originalChatsMap, Map<String, List<Id>> templateIdToAutomationIdMap, Map<Id, Map<String, Automation_Path__c>> automationPathsMap) {
        try{
            for (Chat__c newChat : potentialPathReplies) {
                Chat__c originalChat = new Chat__c();
                
                if(newChat.Message_Type__c == 'interactive'){
                    System.debug('Message Type is interactive. Exiting.');
                    Chat__c contextMessageId = [SELECT Id, WhatsAppMessageId__c FROM Chat__c WHERE Id = :newChat.Reply_to__c];
                    originalChat = originalChatsMap.get(contextMessageId.WhatsAppMessageId__c);
                } else{
                    originalChat = originalChatsMap.get(newChat.WhatsAppContextMessageID__c);
                }
                
                if (originalChat != null && String.isNotBlank(originalChat.Whatsapp_Template__c)) {
                    List<Id> automationIds = templateIdToAutomationIdMap.get(originalChat.Whatsapp_Template__c);
                    System.debug('Automation ID: ' + automationIds);
                    System.debug('automationPathsMap: ' + automationPathsMap);
                    for (Id automationId : automationIds) {
                        System.debug('automationpathmap.containsKey(automationId): ' + automationPathsMap.containsKey(automationId));
                        
                        if (automationId != null && automationPathsMap.containsKey(automationId)) {
                            String normalizedMessageBody = '';
                            if(newChat.Message_Type__c == 'interactive'){
                                normalizedMessageBody = 'interactive';
                            } else{
                                normalizedMessageBody = newChat.Message__c.toLowerCase().trim();
                            }

                            // Contact contactRecord = [SELECT Id FROM Contact WHERE Phone = :newChat.Phone__c LIMIT 1];
                            // Id contactId = contactRecord != null ? contactRecord.Id : null; //try removing this line
                            
                            Map<String, Automation_Path__c> pathsForThisAutomation = automationPathsMap.get(automationId);
                            
                            if (pathsForThisAutomation.containsKey(normalizedMessageBody)) {
                                // *** If ALL CONDITIONS MET ***
                                Automation_Path__c matchingPath = pathsForThisAutomation.get(normalizedMessageBody);
                                
                                System.debug('Matched Path Id: ' + matchingPath.Id);
                                System.debug('Matched Path: ' + matchingPath);
                                // System.debug('Chat ID (inserting) is a reply to Template (' + originalChat.Whatsapp_Template__c + ') with Automation (' + automationId + ') and matching Path (' + matchingPath.Id + ') found via Button Value (' + matchingPath.Button_Value__c + ').');
                                
                                if (matchingPath.Action_Type__c == 'Send Message') {
                                    List<Template_Variable__c> tempvar = [SELECT Id, Name, Field_Name__c, Object_Name__c, Type__c, Alternate_Text__c FROM Template_Variable__c WHERE Template__c = :matchingPath.Action_Template__c LIMIT 1];
                                    
                                    MVWB__Object_Config__mdt configMdt = [SELECT MVWB__ChatWindowConfigInfo__c FROM MVWB__Object_Config__mdt WHERE DeveloperName = 'objectConfigInfo' LIMIT 1];
                                    
                                    Map<String, Object> tempData;

                                    String phoneNumber = newChat.Phone__c;
                                    // Step 2: Parse JSON
                                    Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(configMdt.MVWB__ChatWindowConfigInfo__c);
                                    if (!tempvar.isEmpty()) {
                                        Map<String, Object> objectApiName = (Map<String, Object>) (configMap.get(tempvar[0].Object_Name__c));
                                        String phoneField = (String) objectApiName.get('phoneField');
                                        
                                        // Step 3: Build dynamic query
                                        String soql = 'SELECT Id FROM ' + tempvar[0].Object_Name__c + ' WHERE ' + phoneField + ' = \'' + phoneNumber + '\' LIMIT 1';
                                        
                                        // Step 4: Execute dynamic SOQL
                                        SObject result = Database.query(soql);
                                        Id objectId = result != null ? result.Id : null;
                                        
                                        tempData = getTemplateData(matchingPath.Action_Template__c, objectId, tempvar[0].Object_Name__c);
                                    } else {
                                        System.debug('No template variables found for the template ID: ' + matchingPath.Action_Template__c);
                                        // String objectName;
                                        // if (!configMap.isEmpty()) {
                                        //     objectName = configMap.keySet().iterator().next(); // Gets the first (and only) key
                                        // }
                                        // System.debug('objectName = ' + objectName);
                                        
                                        // Optional: Get inner field values
                                        // Map<String, Object> fieldMap = (Map<String, Object>) configMap.get(objectName);
                                        // System.debug('fieldMap = ' + fieldMap);
                                        // String phoneField = (String) fieldMap.get('phoneField');

                                        // Map<String, String> objectApiName = (Map<String,String>) (configMap.get(tempvar.Object_Name__c));
                                        // String phoneField = (String) objectApiName.get('phoneField');
                                        
                                        // Step 3: Build dynamic query
                                        // System.debug('newChat.Phone__c = ' + phoneNumber);
                                        // String soql = 'SELECT Id FROM ' + objectName + ' WHERE ' + phoneField + ' = \'' + phoneNumber + '\' LIMIT 1';

                                        // SObject result = Database.query(soql);
                                        // Id objectId = result != null ? result.Id : null;
                                        
                                        tempData = getTemplateData(matchingPath.Action_Template__c, '', '');
                                    }
                                    
                                    System.debug('tempData = ' + tempData);
                                    String jsonData = generatePayloadFromTemplateData(tempData, newChat.Phone__c);
                                    System.debug('jsonData = ' + jsonData);
                                    // String phone = '' + newChat.Phone__c;
                                    // String actionTemplate = matchingPath.Action_Template__c;
                                    Map<String, String> chatData = new Map<String, String>();
                                    chatData.put('message', '');
                                    chatData.put('templateId', String.valueOf(matchingPath.Action_Template__c));
                                    chatData.put('messageType', 'Template');
                                    chatData.put('replyToChatId', '');
                                    chatData.put('phoneNumber', String.valueOf(newChat.Phone__c));
                                    Chat__c newChatRecord = createChat(chatData);
                                    System.debug('newChatRecord = ' + newChatRecord);
                                    sendWhatsAppMessage(jsonData, newChatRecord.Id);
                                    Chat__c chatToUpdate = new Chat__c(
                                        Id = newChatRecord.Id,
                                    Date_of_Message__c = Date.today(),
                                    Message_Status__c = 'Sent',
                                    Message_Sent_Time__c = System.now()
                                        );
                                    update chatToUpdate;
                                // } else if (matchingPath.Action_Type__c == 'Send Email') {
                                //     Contact contactRecord1 = [SELECT Id, Email FROM Contact WHERE Phone = :newChat.Phone__c LIMIT 1];
                                    
                                //     if (contactRecord1 != null && String.isNotBlank(contactRecord1.Email) && String.isNotBlank(matchingPath.Action_Email_Template__c)) {
                                //         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                //         email.setToAddresses(new String[] { contactRecord1.Email });
                                //         email.setTemplateId(matchingPath.Action_Email_Template__c);
                                //         email.setTargetObjectId(contactRecord1.Id);
                                //         email.setTreatTargetObjectAsRecipient(true);
                                //         email.setSaveAsActivity(false);
                                        
                                //         try {
                                //             Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                                //             System.debug('Email sent to: ' + contactRecord1.Email);
                                //         } catch (Exception e) {
                                //             System.debug('Failed to send email: ' + e.getMessage());
                                //         }
                                //     } else {
                                //         System.debug('Email or TemplateId missing. Cannot send email.');
                                //     }
                                } else if (matchingPath.Action_Type__c == 'Create a Record') {
                                    String flowResponseJson = newChat.Flow_Response_JSON__c;
                                    String fieldMappingJson = matchingPath.Field_Mapping__c;
                                    String objectName = matchingPath.Object_Name__c;
                                    
                                    if (String.isNotBlank(flowResponseJson) && String.isNotBlank(fieldMappingJson) && String.isNotBlank(objectName)) {
                                        try {
                                            // Parse flow response and field mapping
                                            Map<String, Object> flowResponse = (Map<String, Object>) JSON.deserializeUntyped(flowResponseJson);
                                            Map<String, Object> fieldMapping = (Map<String, Object>) JSON.deserializeUntyped(fieldMappingJson);
                                            
                                            // Dynamically create SObject instance
                                            SObject recordToInsert = (SObject) Type.forName('Schema.' + objectName).newInstance();
                                            
                                            // Loop through flow fields and set values to corresponding object fields
                                            for (String flowField : fieldMapping.keySet()) {
                                                if (flowResponse.containsKey(flowField)) {
                                                    Object fieldValue = flowResponse.get(flowField);
                                                    Object mappingValue = fieldMapping.get(flowField);
                                            
                                                    // If fieldValue is a list but the object field expects string, convert to string
                                                    if (fieldValue instanceof List<Object>) {
                                                        fieldValue = String.join((List<Object>) fieldValue, ', ');
                                                    }
                                            
                                                    if (mappingValue instanceof List<Object>) {
                                                        List<Object> objectFields = (List<Object>) mappingValue;
                                                        for (Object field : objectFields) {
                                                            String objectField = String.valueOf(field);
                                                            recordToInsert.put(objectField, fieldValue);
                                                            System.debug('recordToInsert in for loop: ' + recordToInsert);
                                                        }
                                                    } else {
                                                        String objectField = String.valueOf(mappingValue);
                                                        recordToInsert.put(objectField, fieldValue);
                                                    }
                                                }
                                            }                                        
                                            
                                            System.debug('recordToInsert before insert: ' + recordToInsert);
                                            insert recordToInsert;
                                            System.debug('Record of type ' + objectName + ' inserted successfully: ' + recordToInsert);
                                        } catch (Exception e) {
                                            System.debug('Error processing flow response for record creation: ' + e.getMessage());
                                        }
                                    } else {
                                        System.debug('Missing required data: Flow Response, Field Mapping, or Object Name');
                                    }
                                }
                            } else {
                                System.debug('No matching path found for message: "' + newChat.Message__c + '"');
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler','methodName' => 'processMatchingChats','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
    }

    public static Map<String, object> getTemplateData(String templateId, String recordId, String objectApiName){
        try {
            Map<String, Object> templateData = new Map<String, Object>();
            List<Template__c> templates = new List<Template__c>();
            
            // Fetch templates with matching child variables
            Set<Id> matchingTemplateIds = new Set<Id>();

            if (!String.isBlank(objectApiName)) {
                for (Template_Variable__c tv : [SELECT Template__c FROM Template_Variable__c WHERE Object_Name__c = :objectApiName]) {
                    matchingTemplateIds.add(tv.Template__c);
                }
            }
            
            // Fetch template details
            if (!matchingTemplateIds.isEmpty()) {
                templates.addAll([
                    SELECT Id, Template_Name__c, WBButton_Body__c, WBFooter_Body__c, WBHeader_Body__c, Header_Type__c, Language__c, WBTemplate_Body__c, Template_Category__c, Template_SubCatagory__c, Template_Type__c, Template_Variable__c,
                        (SELECT Id, Name, Field_Name__c, Object_Name__c, Type__c, Alternate_Text__c FROM WB_Template_Variables__r) FROM Template__c WHERE Id = :templateId AND Id IN :matchingTemplateIds
                ]);
            }
            
            // Fetch templates without child variables
            List<Template__c> templatesWithoutVariables = [
                SELECT Id, Template_Name__c, WBButton_Body__c, WBFooter_Body__c, WBHeader_Body__c, Header_Type__c, Language__c, WBTemplate_Body__c, Template_Category__c, Template_SubCatagory__c, Template_Type__c, Template_Variable__c,
                    (SELECT Id, Name, Field_Name__c, Object_Name__c, Type__c, Alternate_Text__c FROM WB_Template_Variables__r) FROM Template__c WHERE Id = :templateId
            ];
            templates.addAll(templatesWithoutVariables);
            
            if(templates.size() > 0 && templates[0].Template_Variable__c>0){
                Template__c template= templates[0];
                Set<String> fieldSelectionCause = new Set<String>();
                for (Template_Variable__c tv : template.WB_Template_Variables__r) {
                    if (tv.Object_Name__c == objectApiName) {
                        // If the object matches the queried object, add only the field name
                        fieldSelectionCause.add(tv.Field_Name__c);
                    } else {
                        try {
                            // Check if the object supports relationships before adding related fields
                            fieldSelectionCause.add(tv.Object_Name__c + '.' + tv.Field_Name__c);
                        } catch (Exception ex) {
                            System.debug('Invalid relationship: ' + tv.Object_Name__c + ' for ' + objectApiName);
                        }
                    }
                }
                
                if(fieldSelectionCause.size() < 1){
                    templateData.put('template', templates[0]);
                    return templateData;
                }
                
                String query = 'SELECT ' + String.join(fieldSelectionCause, ', ') + ' FROM ' + objectApiName + ' WHERE Id =:recordId';
                List<sObject> records = Database.query(String.escapeSingleQuotes(query));
                List<Object> headerVariables = new List<Object>();
                List<Object> bodyVariables = new List<Object>();
                if(records.size() > 0){
                    sObject record = records[0];
                    for (Template_Variable__c tv: template.WB_Template_Variables__r) {
                        Object valueToReplace = '';
                        if (tv.Object_Name__c == objectApiName) {
                            // If the object matches the queried object (Lead, Contact, etc.), get the field directly
                            valueToReplace = record.get(tv.Field_Name__c);
                        } else {
                            // Check if the object supports relationships before querying related fields
                            try {
                                SObject relatedRecord = record.getSObject(tv.Object_Name__c);
                                valueToReplace = (relatedRecord != null) ? relatedRecord.get(tv.Field_Name__c) : null;
                            } catch (Exception ex) {
                                System.debug('Invalid relationship: ' + tv.Object_Name__c + ' for ' + objectApiName);
                                valueToReplace = null;
                            }
                        }
                        if (tv.Type__c == 'Header') {
                            headerVariables.add(valueToReplace != null ? valueToReplace.toString() : (tv.Alternate_Text__c!= null ? tv.Alternate_Text__c : ' '));
                            template.WBHeader_Body__c = template.WBHeader_Body__c.replace(tv.Name , valueToReplace != null ? valueToReplace.toString() : (tv.Alternate_Text__c!= null ? tv.Alternate_Text__c : ' ') );
                        } else if(tv.Type__c == 'Body'){
                            bodyVariables.add(valueToReplace != null ? valueToReplace.toString() : (tv.Alternate_Text__c!= null ? tv.Alternate_Text__c : ' '));
                            template.WBTemplate_Body__c = template.WBTemplate_Body__c.replace(tv.Name , valueToReplace != null ? valueToReplace.toString() : (tv.Alternate_Text__c!= null ? tv.Alternate_Text__c : ' ') );
                        }
                    }
                }
                templateData.put('template', template);
                templateData.put('headerParams', headerVariables);
                templateData.put('bodyParams', bodyVariables);
                // templateData.put('template', templates[0]);
                return templateData;
            } else if (templates.size() > 0 && templates[0].Template_Variable__c < 1){
                templateData.put('template', templates[0]);
                return templateData;
            } else {
                return null;
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler', 'methodName' => 'getTemplateData', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' =>  e.getMessage(), 'apiResponse' => null});
        }
        return null;
    }
    
    // Method to Call createJSONBody Using Template Data
    public static String generatePayloadFromTemplateData(Map<String, Object> templateData, String to) {
        try {
            Template__c template = (Template__c)templateData.get('template'); // Cast to Template__c
            Map<String, Object> data = new Map<String, Object>();
            
            data.put('templateName', template.Template_Name__c);
            data.put('languageCode', template.Language__c);
            data.put('headerImageURL', template.WBHeader_Body__c);
            data.put('headerType', template.Header_Type__c);
            data.put('headerParameters', (List<Object>)templateData.get('headerParams'));
            data.put('bodyParameters', (List<Object>)templateData.get('bodyParams'));

            if(template.WBButton_Body__c != null){
                // data.put('buttonValue', (List<Map<String, Object>>)JSON.deserializeUntyped(template.WBButton_Body__c));
                Object rawData = JSON.deserializeUntyped(template.WBButton_Body__c);
                List<Object> dataList = (List<Object>) rawData;
                
                // Convert each entry to a Map<String, Object>
                List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                for (Object item : dataList) {
                    finalList.add((Map<String, Object>) item);
                }
                
                System.debug(finalList);
                data.put('buttonValue', finalList);
            } else {
                data.put('buttonValue', null);
            }
            return createJSONBody(to, 'template', data);
        } catch (Exception e) {
            // throw new AuraHandledException('Exception in generatePayloadFromTemplateData - ' + e.getMessage());
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler', 'methodName' => 'generatePayloadFromTemplateData', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => '', 'chatId' => null, 'moreDetails' => '', 'apiResponse' => '' });
            return null;
        }
    }
    
    public static String createJSONBody(String to, String type, Map<String, Object> data) {
        try {
            // Base Payload Structure
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('messaging_product', 'whatsapp');
            payload.put('to', to);
            payload.put('type', type);
            
            Map<String, Object> template = new Map<String, Object>();
            template.put('name', (String)data.get('templateName'));
            template.put('language', new Map<String, Object>{ 'code' => (String)data.get('languageCode') });
            
            List<Map<String, Object>> components = new List<Map<String, Object>>();
            
            // Header Parameters (Text)
            List<Object> headerParameters = (List<Object>)data.get('headerParameters');
            if (headerParameters != null && !headerParameters.isEmpty()) {
                List<Map<String, Object>> headerParams = new List<Map<String, Object>>();
                
                for (Object param : headerParameters) {
                    headerParams.add(new Map<String, Object>{ 'type' => 'text', 'text' => (String)param });
                }
                
                components.add(new Map<String, Object>{ 'type' => 'header', 'parameters' => headerParams });
            }
            
            // Header Type (Media)
            String headerType = (String)data.get('headerType');
            String headerImageURL = (String)data.get('headerImageURL');
            if (headerType != null && headerImageURL != null && headerType.toLowerCase() != 'text') {
                components.add(new Map<String, Object>{
                    'type' => 'header',
                    'parameters' => new List<Map<String, Object>>{
                        new Map<String, Object>{ 'type' => headerType.toLowerCase(), headerType.toLowerCase() => new Map<String, Object>{ 'link' => headerImageURL } }
                    }
                });
            }
            
            // Body Parameters
            List<Object> bodyParameters = (List<Object>)data.get('bodyParameters');
            if (bodyParameters != null && !bodyParameters.isEmpty()) {
                List<Map<String, Object>> bodyParams = new List<Map<String, Object>>();
                
                for (Object param : bodyParameters) {
                    bodyParams.add(new Map<String, Object>{ 'type' => 'text', 'text' => (String)param });
                }
                
                components.add(new Map<String, Object>{ 'type' => 'body', 'parameters' => bodyParams });
            } else if((String)data.get('templateType') == 'Authentication'){
                Integer randomCode = Math.abs(Math.mod(Crypto.getRandomInteger(), 900000)) + 100000;
                String randomCodeStr = String.valueOf(randomCode);
                components.add(new Map<String, Object>{
                    'type' => 'body',
                    'parameters' => new List<Map<String, Object>>{
                        new Map<String, Object>{ 'type' => 'text', 'text' => randomCodeStr }
                    }
                });
            }
            
            // Button Parameters
            List<Map<String, Object>> buttonValue = (List<Map<String, Object>>)data.get('buttonValue');
            if (buttonValue != null && !buttonValue.isEmpty()) {
                Integer index = 0;
                for (Map<String, Object> button : buttonValue) {
                    String buttonType = ((String)button.get('type')).toUpperCase();
                    switch on buttonType {
                        when 'PHONE_NUMBER' {
                            components.add(new Map<String, Object>{
                                'type' => 'button',
                                'sub_type' => 'voice_call',
                                'index' => index,
                                'parameters' => new List<Map<String, Object>>{
                                    new Map<String, Object>{ 'type' => 'text', 'text' => (String)button.get('phone_number') }
                                }
                            });
                        }
                        when 'COPY_CODE', 'COUPON_CODE' {
                            components.add(new Map<String, Object>{
                                'type' => 'button',
                                'sub_type' => 'copy_code',
                                'index' => index,
                                'parameters' => new List<Map<String, Object>>{
                                    new Map<String, Object>{ 'type' => 'coupon_code', 'coupon_code' => (String)button.get('example') }
                                }
                            });
                        }
                        when 'OTP' {
                            Integer randomCode = Math.abs(Math.mod(Crypto.getRandomInteger(), 900000)) + 100000;
                            String randomCodeStr = String.valueOf(randomCode);
                            components.add(new Map<String, Object>{
                                'type' => 'button',
                                'sub_type' => 'url',
                                'index' => index,
                                'parameters' => new List<Map<String, Object>>{
                                    new Map<String, Object>{ 'type' => 'text', 'text' => randomCodeStr }
                                }
                            });
                        }
                        when 'FLOW' {
                            components.add(new Map<String, Object>{
                                'type' => 'button',
                                'sub_type' => 'flow',
                                'index' => index,
                                'parameters' => new List<Map<String, Object>>{
                                    new Map<String, Object>{ 'type' => 'payload', 'payload' => 'PAYLOAD' }
                                }
                            });
                        }
                    }
                    index++;
                }
            }
            
            // Add Components to Template
            if (!components.isEmpty()) {
                template.put('components', components);
            }
            
            payload.put('template', template);
            return JSON.serialize(payload);
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppMessageBatch', 'methodName' => 'createJSONBody', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => '', 'chatId' => null, 'moreDetails' => '', 'apiResponse' => '' });
            return null;
        }
    }
    
    @future(callout=true)
    public static void sendWhatsappMessage(String jsonData, String chatId) {
        Map<String, Object> resultMap = new Map<String, Object>{};
        Chat__c chat = new Chat__c(Id = chatId);
        try {
            HttpRequest httpReq = new HttpRequest();
            resultMap.put('errorMessage', null);
            // List<WBConnect_Configuration__mdt> wbConfig = WBConnect_Configuration__mdt.getAll().values();
            if(wbConfig==null || wbConfig.isEmpty()){
                update chat;
                resultMap.put('errorMessage', 'METADATA_ERROR');
                resultMap.put('chat', chat);
                // return resultMap;
            }
            String accessToken = wbConfig[0].MVWB__Access_Token__c;
            String endpoint = wbConfig[0].MVWB__API_Endpoint__c + '/' + wbConfig[0].MVWB__API_Version__c + '/' + wbConfig[0].MVWB__Phone_Number_Id__c + '/messages';

            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
            httpReq.setBody(jsonData);
            Http http = new Http();
            HttpResponse response = http.send(httpReq);
            Integer statusCode = response.getStatusCode();
            if(response != null && statusCode == 200){
                String responseBody = response.getBody();
                Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                List<Object> messages = (List<Object>)jsonMap.get('messages');
                Map<String, Object> firstMessage = (Map<String, Object>)messages[0];
                String whatsAppMessageID = (String) firstMessage.get('id');
                System.debug('WhatsApp Message ID: ' + whatsAppMessageID);
                Chat__c chatToSend = [SELECT Id, Type_of_Message__c, WhatsAppMessageId__c, Message__c, Message_Status__c, Message_Type__c, Reply_To__c, Reaction__c, Whatsapp_Template__c, Whatsapp_Template__r.Name, CreatedDate, Last_Interaction_Date__c, Phone__c FROM Chat__c WHERE Id =:chatId LIMIT 1];
                chatToSend.Message_Status__c = 'Sent';
                chatToSend.WhatsAppMessageId__c = whatsAppMessageID;
                update chatToSend;
                Chat_Message__e newChatEvent = new Chat_Message__e();
                newChatEvent.Chat_Data__c = JSON.serialize(chatToSend);
                newChatEvent.Type__c = 'new';
                // newChatEvent.ContactId__c = whatsappChat.Contact__c;
                EventBus.publish(newChatEvent);
            } else {
                System.debug('Error sending WhatsApp Message: '+response.getBody());
                ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler', 'methodName' => 'sendWhatsappMessage', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => statusCode, 'chatId' => chatId, 'moreDetails' => 'API Exception while sending a message', 'apiResponse' => JSON.serialize(response.getBody()) });
            }
            
            update chat;
            chat = [SELECT Id, Type_of_Message__c, WhatsAppMessageId__c, Message__c, Message_Status__c, Message_Type__c, Reply_To__c, Reaction__c, Whatsapp_Template__c, Whatsapp_Template__r.Template_Name__c, CreatedDate, Last_Interaction_Date__c FROM Chat__c WHERE Id =:chat.Id];
            resultMap.put('chat', chat);
            // return resultMap;
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler', 'methodName' => 'sendWhatsappMessage', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => chatId, 'moreDetails' => e.getMessage(), 'apiResponse' => null });
        }
        resultMap.put('chat', chat);
        // return resultMap;
    }
    
    public static Chat__c createChat(Map<String, String> chatData ){
        try {
            String message = chatData.get('message');
            String templateId = chatData.get('templateId');
            String messageType = chatData.get('messageType');
            String replyToChatId = chatData.get('replyToChatId');
            String phoneNumber = chatData.get('phoneNumber');
            
            Chat__c chat = new Chat__c();
            chat.Message__c = message;
            chat.Whatsapp_Template__c = templateId;
            chat.Phone__c = phoneNumber;
            chat.Type_of_Message__c	= 'OutBound Messages';
            chat.Message_Status__c = 'Sent';
            chat.Message_Type__c = messageType;
            // chat.Reply_To__c = replyToChatId;
            
            insert chat;
            System.debug('chat:- '+chat.Id);
            chat = [SELECT Id, Type_of_Message__c, WhatsAppMessageId__c, Message__c, Message_Status__c, Message_Type__c, Reply_To__c, Reaction__c, Whatsapp_Template__c, Whatsapp_Template__r.Template_Name__c, CreatedDate, Last_Interaction_Date__c FROM Chat__c WHERE Id =:chat.Id];
            System.debug('chat:- '+chat);
            return chat;
        } catch (Exception e) {
            // if(e.getMessage().contains('STORAGE_LIMIT_EXCEEDED')){
                // throw new AuraHandledException('STORAGE_LIMIT_EXCEEDED');
            // }
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'AutomationConfigTriggerHandler', 'methodName' => 'createChat', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' =>  e.getMessage(), 'apiResponse' => null});
            return null;
        }
    }
}