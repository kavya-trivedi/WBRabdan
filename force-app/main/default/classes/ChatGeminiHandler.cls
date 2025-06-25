/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 04-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public without sharing class ChatGeminiHandler{

    public static List<User_Theme_Preference__c> userPreferences = [SELECT Auto_Response__c FROM User_Theme_Preference__c WITH SECURITY_ENFORCED];
    
    @InvocableMethod(label = 'Generate AI Response and Send WhatsApp'description = 'Calls Gemini API, sends WhatsApp message, and creates a new Chat record.')
    public static void processChat(List<InvocableInput> chats){

        User_Theme_Preference__c userPreference = !userPreferences.isEmpty() ? userPreferences[0] : null;

        if(userPreference.Auto_Response__c){
            
            InvocableInput input = chats.get(0); // Assuming the flow only passes one record at a time.
            String chatId = input.chatId;
            System.debug('chatId:- ' + chatId);
            List<MVWB__Chat__c> chatsFound = [SELECT Id, MVWB__Message_Status__c, MVWB__Message__c, MVWB__Phone__c FROM MVWB__Chat__c WHERE id = :chatId];
            if (chatsFound.isEmpty()) {
                System.debug('No chat record found for ID: ' + chatId);
                return;
            }

            MVWB__Chat__c chat = chatsFound[0];
            if (chat == null){
                System.debug('No record Found');
                return;
            } else{
                System.debug('chat Record:- ' + chat);
            }
            String message = chat.MVWB__Message__c;
            
            if (String.isBlank(message)){
                return; // No message to process.
            }
            
            try{
                List<SObject> records = new List<SObject>();
                String geminiResponse1 = callGeminiAPI(message, chat.MVWB__Phone__c, true, records); // Call Gemini API
                
                // if (String.isNotBlank(geminiResponse1)){
                //     sendWhatsAppMessage(newChat.Id, geminiResponse1); // Send WhatsApp message
                // }

                if (String.isNotBlank(geminiResponse1)) {
                    System.debug('Gemini Response: ' + geminiResponse1);
                    String rawQuery = geminiResponse1 != null ? geminiResponse1.replaceAll('(?i)```sql|```', '').trim() : null;
                    System.debug('Raw Query: ' + rawQuery);
                    String queryResult;
                    String geminiResponse2;
                    try {
                        // Dynamically run Gemini's generated SOQL
                        if (rawQuery != null && rawQuery != 'null') {
                            records = Database.query(rawQuery);
                            if (!records.isEmpty()) {
                                // Format the output string
                                geminiResponse2 = callGeminiAPI(message, chat.MVWB__Phone__c, false, records);
                            } else {
                                geminiResponse2 = 'No records found for your query.';
                            }
                        } else {
                            geminiResponse2 = 'Invalid field or relationship name. Please check your prompt.';
                        }
                    } catch (Exception ex) {
                        geminiResponse2 = 'Sorry, I encountered an error while processing your request. Please try again later.';
                        System.debug('Error executing query: ' + ex.getMessage());
                    }

                    MVWB__Chat__c newChat = new MVWB__Chat__c();
                    newChat.MVWB__Message__c = geminiResponse2;
                    newChat.MVWB__Phone__c = chat.MVWB__Phone__c;
                    newChat.MVWB__Type_of_Message__c = 'Outbound Messages'; // Assuming outbound message for now
                    newChat.MVWB__Message_Status__c = 'Failed';
                    // chat.Message_Type__c = 'Text';
                    insert newChat;

                    sendWhatsAppMessage(newChat.Id, geminiResponse2);
                }
                
            } catch (Exception e){
                System.debug('Error processing chat: ' + e.getMessage());
                // Optionally, handle the error (e.g., log it, send an alert).
            }
        }
    }

    private static String callGeminiAPI(String message, String phone, Boolean isQueryGeneration, List<SObject> queryResult){
        // Replace with your actual Gemini API endpoint and authentication details.
        String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyBDZiI4CgGbAQ_7i73Hq33jTneh2SyxZtU'; // Example: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyBDZiI4CgGbAQ_7i73Hq33jTneh2SyxZtU';
        String apiKey = 'AIzaSyBDZiI4CgGbAQ_7i73Hq33jTneh2SyxZtU'; // Replace with your actual API key.
        String model = 'gemini-2.0-flash'; //Replace with your model.
        String projectId = 'YOUR_PROJECT_ID';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        // String requestBody = generateRequestBody(message, phone);
        String queryResult2 = JSON.serialize(queryResult).replaceAll('\"', ''); // Escape double quotes for JSON string
        String requestBody = isQueryGeneration ? generateRequestBody(message, phone) : '{' +
            '"contents": [{' +
                '"parts": [{"text": "The user asked - ' + String.escapeSingleQuotes(message) + '.\nHere is the raw Salesforce data result -\n' +
                        queryResult2 + '\nPlease convert this into a clear, user-friendly WhatsApp response. Only the message and no extra text"}]' +
                '}]' +
            '}';

        System.debug('Request Body: ' + requestBody);

        // String requestBody = '{' +
        //     '"contents": [{' +
        //         '"parts": [{"text": "Act as a chat bot Assistant for a Salesforce based company named MV Clouds Pvt Lmt located in Ahmedabad for the given User Prompt also your are directly replying to the user so it should be direct and acurat response not suggestions and all. User Prompt: ' + String.escapeSingleQuotes(message) + '"}]' +
        //         // '"parts": [{"text": "Write a single outbound message response for the following inbound message. Message: ' + String.escapeSingleQuotes(message) + '"}]' +
        //     '}]' +
        // '}';

        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200){
            // Parse the JSON response from Gemini API.
            Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> candidates = (List<Object>)response.get('candidates');

            if (candidates != null && !candidates.isEmpty()){
                Map<String, Object> candidate = (Map<String, Object>)candidates.get(0);
                List<Object> parts = (List<Object>)((Map<String, Object>)candidate.get('content')).get('parts');
                if (parts != null && !parts.isEmpty()){
                    return String.valueOf(((Map<String, Object>)parts.get(0)).get('text'));
                }
            }

        } else{
            System.debug('Gemini API call failed: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        return null; // Return null if API call fails or no response is available.
    }

    public static String generateRequestBody(String message, String phone){

        Datetime twentyFourHoursAgo = System.now().addHours(-24);
        List<MVWB__Chat__c> chatHistory = [SELECT Id, MVWB__Message__c, MVWB__Type_of_Message__c FROM MVWB__Chat__c WHERE MVWB__Phone__c = :phone AND CreatedDate >= :twentyFourHoursAgo ORDER BY CreatedDate ASC LIMIT 20];
                                     
        String formattedConversation = '';
        boolean isUserTurn = true; // Start with User prompt

        for (MVWB__Chat__c chat : chatHistory){
            if (chat.MVWB__Type_of_Message__c.containsIgnoreCase('Inbound Messages')){
                if (isUserTurn){
                    formattedConversation += 'User: ' + chat.MVWB__Message__c + ', ';
                    isUserTurn = false;
                }
            } else if (chat.MVWB__Type_of_Message__c.containsIgnoreCase('Outbound Messages')){
                if (!isUserTurn){
                    formattedConversation += 'Assistant: ' + chat.MVWB__Message__c + ', ';
                    isUserTurn = true;
                }
            }
        }

        // Remove trailing comma and space
        if (formattedConversation.endsWith(', ')){
            formattedConversation = formattedConversation.substring(0, formattedConversation.length() - 2);
        }

        formattedConversation = formattedConversation.replaceAll('\"', '\'');

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Map<String, String> aliasToObject = new Map<String, String>();

        for (String objectApiName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult describe = globalDescribe.get(objectApiName).getDescribe();

            // Avoid system/internal/shared/tag/history objects
            if (objectApiName.contains('History') || objectApiName.contains('Share') || objectApiName.contains('Tag')) {
                continue;
            }

            // Always include the object label-based aliases
            String singularAlias = describe.getLabel().toLowerCase(); // e.g., "template"
            String pluralAlias = describe.getLabelPlural().toLowerCase(); // e.g., "templates"

            aliasToObject.put(singularAlias, objectApiName);
            aliasToObject.put(pluralAlias, objectApiName);

            // Add cleaned API name as alias (remove namespace and __c)
            if (objectApiName.endsWith('__c')) {
                String cleanedName = objectApiName;

                // Remove namespace if present
                if (cleanedName.contains('__')) {
                    cleanedName = cleanedName.substring(cleanedName.indexOf('__') + 2);
                }

                // Remove trailing __c
                cleanedName = cleanedName.replace('__c', '');

                // Add cleaned API name in lowercase as alias (both singular and plural)
                aliasToObject.put(cleanedName.toLowerCase(), objectApiName);
                aliasToObject.put(cleanedName.toLowerCase() + 's', objectApiName);
            } else {
                // Standard object – also allow API name directly
                aliasToObject.put(objectApiName.toLowerCase(), objectApiName);
            }
        }

        // Now build mentioned objects
        Set<String> mentionedObjects = new Set<String>();
        String normalizedMessage = normalizeText(message);

        for (String alias : aliasToObject.keySet()) {
            String normalizedAlias = normalizeText(alias);
            if (normalizedMessage.contains(normalizedAlias)) {
                mentionedObjects.add(aliasToObject.get(alias));
            }
        }

        String metadataSummary = generateCustomObjectFieldSummary(mentionedObjects);

        // String json = '{' + 
        //              '"contents": [{' + 
        //              '"parts": [{"text": "Act as a chat bot Assistant for a Salesforce based company named MVClouds Private Limited owned by Dharmik Shah and located in Ahmedabad (Look for more details of MV Clouds over the web and linkedin) for the given User Prompt also your are directly replying to the user so it should be direct and acurat response not suggestions and all. Current User Prompt: ' + String.escapeSingleQuotes(message) + ' , moreever consider the below given sets of previous converations for user and assistant to provide better answer - ' + formattedConversation + ' "}]' + 
        //              '}]' + 
        //              '}';

        String json = '{' + 
                     '"contents": [{' + 
                        '"parts": [{"text": "Act as a Salesforce SOQL expert. Use the user prompt and convert it into a SOQL query without explanation or any extra text. ONLY return a valid SOQL query without any explanation, formatting, or markdown — not even ```sql. Strictly no extra characters or wrapping. Use __c suffix for custom fields. Use __r suffix for custom relationship names when querying child records or navigating to parent records. Do not use object prefixes like Object__c.Name. Do not combine __c and __r. Refer to the available metadata below. Note - IF THE USER PROMPT INCLUDES ANY FIELD OR RELATIONSHIP OF AN OBJECT THAT ISN\'T MENTIONED BELOW, RETURN null: \n' + metadataSummary +
                            '\nCurrent User Prompt: ' + String.escapeSingleQuotes(message) + '\nMoreover, consider the below given sets of previous converations for user and assistant to provide better answer - ' + formattedConversation + '"}]' +
                        '}]' +
                     '}';

        return json;
    }

    public static String generateCustomObjectFieldSummary(Set<String> mentionedObjects) {
        String metadataSummary = '';

        for (String objectName : mentionedObjects) {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType != null) {
                Schema.DescribeSObjectResult describe = objType.getDescribe();

                // 1. List fields
                Map<String, Schema.SObjectField> fieldsMap = describe.fields.getMap();
                List<String> fieldDetails = new List<String>();

                for (Schema.SObjectField field : fieldsMap.values()) {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    String apiFieldName = fieldDescribe.getName(); // correct case
                    String dataType = fieldDescribe.getType().name(); // e.g., STRING, PICKLIST
                    fieldDetails.add(apiFieldName + ' (' + dataType + ')');
                }

                fieldDetails.sort();

                metadataSummary += 'Object: ' + describe.getName() + '\n';
                metadataSummary += 'Fields:\n';
                for (String field : fieldDetails) {
                    metadataSummary += '- ' + field + '\n';
                }

                // 2. List unique child relationships
                Set<String> seenRelationships = new Set<String>();
                List<String> childRelations = new List<String>();

                for (Schema.ChildRelationship rel : describe.getChildRelationships()) {
                    String relName = rel.getRelationshipName();
                    String childObject = rel.getChildSObject().getDescribe().getName();

                    if (relName != null && !seenRelationships.contains(relName)) {
                        seenRelationships.add(relName);

                        // Singularize only if it's a custom object
                        if (childObject.endsWith('__c')) {
                            String customRel = childObject.replace('__c', '__r');
                            childRelations.add(customRel);
                        } else {
                            childRelations.add(relName);
                        }
                    }
                }

                childRelations.sort();
                if (!childRelations.isEmpty()) {
                    metadataSummary += 'Child Relationships:\n';
                    for (String rel : childRelations) {
                        metadataSummary += '- ' + rel + '\n';
                    }
                }

                metadataSummary += '\n';
            }
        }

        return metadataSummary;
    }

    public static String normalizeText(String input) {
        if (input == null) return '';
        input = input.toLowerCase();
        input = input.replaceAll('[áàäâã]', 'a');
        input = input.replaceAll('[éèëê]', 'e');
        input = input.replaceAll('[íìïî]', 'i');
        input = input.replaceAll('[óòöôõ]', 'o');
        input = input.replaceAll('[úùüû]', 'u');
        input = input.replaceAll('[ñ]', 'n');
        input = input.replaceAll('[ç]', 'c');
        return input;
    }

    // Basic smart pluralization rules for standard object relationship names
    // private static String smartPluralize(String name) {
    //     if (name.endsWithIgnoreCase('y') && name.length() > 1 && !'aeiou'.contains(name.substring(name.length() - 2, name.length() - 1).toLowerCase())) {
    //         return name.substring(0, name.length() - 1) + 'ies';
    //     } else if (name.endsWithIgnoreCase('s') || name.endsWithIgnoreCase('x') || name.endsWithIgnoreCase('z') ||
    //             name.endsWithIgnoreCase('ch') || name.endsWithIgnoreCase('sh')) {
    //         return name + 'es';
    //     } else {
    //         return name + 's';
    //     }
    // }

    private static String formatQueryResult(List<SObject> records) {
        String output = '';

        for (SObject record : records) {
            List<String> fieldValues = new List<String>();
            Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();

            for (String field : fieldMap.keySet()) {
                Object value = fieldMap.get(field);

                if (value instanceof List<SObject>) {
                    // Handle subquery result (child relationship)
                    List<SObject> childRecords = (List<SObject>)value;
                    fieldValues.add(field + ': [');
                    for (SObject child : childRecords) {
                        List<String> childFieldValues = new List<String>();
                        Map<String, Object> childMap = child.getPopulatedFieldsAsMap();

                        for (String childField : childMap.keySet()) {
                            try {
                                childFieldValues.add(childField + ': ' + String.valueOf(child.get(childField)));
                            } catch (Exception e) {
                                // Skip fields not queried or inaccessible
                                System.debug('Error accessing field ' + childField + ' in child record: ' + e.getMessage());
                                continue;
                            }
                        }
                        fieldValues.add('  {' + String.join(childFieldValues, ', ') + '}');
                    }
                    fieldValues.add(']');
                } else {
                    fieldValues.add(field + ': ' + String.valueOf(value));
                }
            }

            output += String.join(fieldValues, ', ') + '\n';
        }

        return output.trim();
    }

    @future(callout = true)
    private static void sendWhatsAppMessage(String chatId, String message){

        List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values();
        MVWB__Chat__c chat = [SELECT Id, MVWB__Message_Status__c, MVWB__Message__c, MVWB__Phone__c FROM MVWB__Chat__c WHERE id = :chatId];
        String phoneNumber = chat.MVWB__Phone__c;
        if (phoneNumber != null && (wbConfig != null || !wbConfig.isEmpty())){

            // String JSON = '{ "messaging_product": "whatsapp", "to": "919428234735", "context":{ "message_id" : "wamid.HBgMOTE5NDI4MjM0NzM1FQIAERgSMEM3QjdBODJGMEMxQTkwRkEyAA=="}, "type": "text", "text": { "body" : "Hello, We hope that you are doing great!. This is a simple text message sent using the WhatsApp Cloud API."} }';// reply to
            // String jsonData = '{ "messaging_product": "whatsapp", "to": "'+ phoneNumber +'",  "type": "text", "text": { "body" : "'+ message +'"} }';
            String jsonData = '';
            HttpRequest httpReq = new HttpRequest();

            // Create a map to hold the JSON structure
            Map<String, Object> messageMap = new Map<String, Object>();
            messageMap.put('messaging_product', 'whatsapp');
            messageMap.put('to', phoneNumber);
            messageMap.put('type', 'text');

            // Create nested map for text
            Map<String, String> textMap = new Map<String, String>();
            textMap.put('body', message);

            messageMap.put('text', textMap);

            // Convert the map to a JSON string
            jsonData = JSON.serialize(messageMap);

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
            if (response != null && statusCode == 200){
                String responseBody = response.getBody();
                Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                List<Object> messages = (List<Object>)jsonMap.get('messages');
                Map<String, Object> firstMessage = (Map<String, Object>)messages[0];
                String whatsAppMessageID = (String) firstMessage.get('id');
                System.debug('WhatsApp Message ID: ' + whatsAppMessageID);
                // Update the chat record
                chat.MVWB__WhatsAppMessageId__c = whatsAppMessageID;
                chat.MVWB__Message_Status__c = 'Sent';
            } else{
                System.debug('Error sending WhatsApp Message: ' + response.getBody());
                chat.MVWB__Message_Status__c = 'Failed';
                ExceptionHandler.logException(new Map<String, Object>{ 'className' => 'ChatGeminiHandler', 'methodName' => 'sendWhatsappMessage', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => statusCode, 'chatId' => chat.Id, 'moreDetails' => 'API Exception while sending a message', 'apiResponse' => JSON.serialize(response.getBody()) });
            }

            update chat;

        } else{
            System.debug('Contact phone number not found.');
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true label='Template Id')
        public String chatId;
    }

}