/**
 * @File Name : WhatsAppWebhook.cls
 * @Description :
 * @Author :
 * @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On : 04-21-2025
 * @Modification Log :
 *==============================================================================
 * Date Modified - Developer Name - Description
 * 18 Nov, 2024  - ChangeMeIn@UserSettingsUnder.SFDoc  -  Initial Version
 * 26 Mar, 2025  - Harsh Gandhi - Updated naming convention for files and made changes for saving files wih correct extentions
 **/
@RestResource(urlMapping = '/WBI/webhooks/v1/*')
global without sharing class WhatsAppWebhook{
    public static String currentTime = System.now().format('yyyy-MM-dd HH:mm:ss');
    public static String phoneNumberId = '';
    public static List<Object> messages = new List<Object>();
    public static List<MVWB__AWS_Config__c> configList = [SELECT Id, MVWB__AWS_Access_Key__c, MVWB__AWS_Secret_Access_Key__c, MVWB__S3_Bucket_Name__c, MVWB__S3_Region_Name__c, CreatedDate, LastModifiedDate FROM MVWB__AWS_Config__c LIMIT 1];
    public static MVWB__AWS_Config__c configData = !configList.isEmpty() ? configList[0] : null;

    @HttpGet // GET
    global static void doGet(){
        RestResponse response = RestContext.response;
        System.debug('Response ==>' + response);
        RestRequest request = RestContext.request;
        System.debug('request ==>' + request);
        if (request.params.get('hub.verify_token') == 'WHATSAPPTOKEN'){
            response.responseBody = Blob.valueOf(request.params.get('hub.challenge'));
        }
    }

    @HttpPost
    global static void doPost(){
        System.debug('InDoPost Method' + RestContext.request.headers.get('hub.verify_token'));
        System.debug('InDoPost Method2 ' + RestContext.request.params.get('hub.verify_token'));
        
        // Get WhatsApp's raw JSON data
        System.debug('InDoPost Method before Payload');
        String jsonString = RestContext.request.requestBody.toString();
        System.debug('InDoPost Method after payload:- ' + jsonString);
        try{
            processWhatsAppPayload(jsonString);
        } catch (Exception e){
            System.debug('Error processing WhatsApp payload: ' + e.getMessage());
        }
    }

    public static void processWhatsAppPayload(String jsonString){
        try{
            System.debug('jsonString: ' + jsonString);
            parseMessages(jsonString);

            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            System.debug('payload: ' + payload);

            List<Object> listofmessages = (List<Object>)payload.get('entry');
            Object messageobj = listofmessages[0];

            Map<String, Object> sender = new Map<String,Object>();
            if (messageobj != null){
                Map<String, Object> messageMap = (Map<String, Object>)messageobj;
                if (messageMap.get('changes') != null){
                    List<Object> changes = (List<Object>)messageMap.get('changes');
                    if (changes != null && !changes.isEmpty()){
                        Object changeObj = changes[0];
                        Map<String, Object> changeMap = (Map<String, Object>)changeObj;
                        Map<String, Object> value = (Map<String, Object>)changeMap.get('value');
                        Map<String, Object> metadata = (Map<String, Object>)value.get('metadata');
                        System.debug('value--->' + value);
                        // Extract the phone_number_id
                        phoneNumberId = (String) metadata.get('phone_number_id');
                        System.debug('phonenumberid -- ' + phoneNumberId);
                        messages = (List<Object>)value.get('messages');
                        List<Object> senders = new List<Object>();
                        senders = (List<Object>)value.get('contacts');
                        if(senders !=null && senders.size() > 0){
                            sender =  (Map<String, Object>) senders[0];
                        }
                    }
                }
            }

            if (messages != null){
                Map<String, Object> message = (Map<String, Object>)messages[0];
                processSingleMessage(message, sender);
            }
        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'processWhatsAppPayload', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in processWhatsAppPayload: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    private static void processSingleMessage(Map<String, Object> message, Map<String, Object> sender){

        try{
            // Boolean isLicenseValid = PLMSController.checkLicenseUsablility();
            // if(isLicenseValid == false){
            //     System.debug('License is not valid');
            //     ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'processSingleMessage', 'exceptionObj' => null, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'License Expired.', 'apiResponse' => null});
            //     return;
            // }
            String senderId = (String) message.get('from');
            String messageType = (String) message.get('type');
            String whatsAppMessageID = (String) message.get('id');
            Map<String, Object> context = (Map<String, Object>)message.get('context');
            String contextId = '';
            if (context != null){
                contextId = (String) context.get('id');
                System.debug('Context ID ==> ' + contextId);
            }
            Map<String, Object> reactionMessage = (Map<String, Object>)message.get('reaction');
            String reactToMessageId = '';
            String reactedEmoji= '';
            if (reactionMessage != null){
                reactToMessageId = (String) reactionMessage.get('message_id');
                reactedEmoji= (String) reactionMessage.get('emoji');
                System.debug('Context ID ==> ' + reactToMessageId);
            }
            Integer timestampValue = Integer.valueOf(message.get('timestamp'));
            DateTime messageTime = DateTime.newInstanceGmt(1970, 1, 1, 0, 0, 0).addSeconds(timestampValue);
            // Check if it's within the last 10 minutes
            DateTime tenMinutesAgo = DateTime.now().addMinutes(-10);

            if (messageTime >= tenMinutesAgo) {
                System.debug('✅ Timestamp is within the last 10 minutes.');
            } else {
                System.debug('❌ Timestamp is older than 10 minutes.');
                return;
            }

            DateTime currentUTCDateTime = System.now();
            Timezone tzIST = Timezone.getTimeZone('Asia/Kolkata');
            Integer offsetMillis = tzIST.getOffset(currentUTCDateTime);
            Integer offsetHours = offsetMillis / (1000 * 60 * 60);
            Integer offsetMinutes = Math.abs(offsetMillis / (1000 * 60) - offsetHours * 60);
            DateTime currentISTDateTime = currentUTCDateTime.addHours(offsetHours).addMinutes(offsetMinutes);
            String formattedTime2 = currentISTDateTime.format('h:mm a');
            System.debug(formattedTime2);
            System.debug('whatsAppMessageID ==> ' + whatsAppMessageID);
            System.debug('senderId ==> ' + senderId);
            System.debug('messageType ==> ' + messageType);

            // Query to check if the message has already been processed
            List<MVWB__Chat__c> existingChatRecords = [SELECT Id FROM MVWB__Chat__c WHERE MVWB__WhatsAppMessageId__c = :whatsAppMessageID LIMIT 1];
            if (!existingChatRecords.isEmpty()){
                System.debug('Message already processed: ' + whatsAppMessageID);
                return;
            }

            if (!senderId.contains('+')){
                senderId = '+' + senderId;
            }
            String formattedNumber = senderId.substring(0, 3) + senderId.substring(3);

            List<Lead> contacts = new List<Lead>();
            System.debug('Sender Id => ' + senderId);
            System.debug('formattedNumber Id => ' + formattedNumber);

            Map<String, Object> profile = (Map<String, Object>) sender.get('profile');
            String senderName = (String) profile.get('name');
            String senderPhone = formattedNumber;
            List<User> userRecs = [SELECT Id, Name, Phone FROM User WHERE Phone = :formattedNumber LIMIT 1];
            System.debug('userecs size : ' + userRecs.size());
            String recordId = '';
            String recordName = '';
            String recordPhone = '';
            String objectApiName = '';
            SObject record;

            // Fetch metadata record from Object_Config__mdt
            List<MVWB__Object_Config__mdt> objectConfigList = [SELECT Id, MVWB__ObjectConfigInfo__c, MVWB__ChatWindowConfigInfo__c FROM MVWB__Object_Config__mdt LIMIT 1];
            if(objectConfigList.size() <= 0) {
                System.debug('Object Config not found!');
                return;
            } else {
                // Deserialize the JSON string from ObjectConfigInfo__c
                Map<String, Object> configData = (Map<String, Object>) JSON.deserializeUntyped(objectConfigList[0].MVWB__ObjectConfigInfo__c);
                Map<String, Object> chatConfigData = (Map<String, Object>) JSON.deserializeUntyped(objectConfigList[0].MVWB__ChatWindowConfigInfo__c);
                
                System.debug('configData'+ configData);
                System.debug('chatConfigData'+ chatConfigData);
    
                // Extract values from deserialized data
                objectApiName = (String) configData.get('objectApiName'); // e.g., 'Account'
                String phoneField = (String) configData.get('phoneField'); // e.g., 'Fax'
                System.debug('phoneField'+ phoneField);
                
                Map<String, Object> chatConfig = (Map<String, Object>) chatConfigData.get(objectApiName);
                String nameField = (String) chatConfig.get('nameField'); // e.g., 'Name'
                System.debug('nameField'+ nameField);
                
                System.debug('requiredFields'+ configData.get('requiredFields'));

                List<Object> requiredFieldsList = (List<Object>) configData.get('requiredFields'); 

                Map<String, Object> requiredFieldsMap = new Map<String, Object>();
                for (Object obj : requiredFieldsList) {
                    Map<String, Object> fieldData = (Map<String, Object>) obj;
                    requiredFieldsMap.put((String) fieldData.get('name'), fieldData); // Store the entire field data including type
                }
    
                // Query the object specified in objectApiName using dynamic SOQL
                String query = 'SELECT Id, Name, ' + phoneField + ' FROM ' + objectApiName + ' WHERE ' + phoneField + ' = :formattedNumber LIMIT 1';
                List<SObject> records = Database.query(query);
                
                if (!records.isEmpty()) {
                    record = records[0];
                    recordId = (String) record.get('Id');
                    recordName = (String) record.get('Name');
                    recordPhone = (String) record.get(phoneField);
                } else if (userRecs.isEmpty()) {
                    System.debug('inside debug --- ');
                    // Create a new record for the object specified in objectApiName
                    SObject newRecord = Schema.getGlobalDescribe().get(objectApiName).newSObject();
                    
                    // Populate required fields from metadata with type conversion
                    for (String fieldName : requiredFieldsMap.keySet()) {
                        Map<String, Object> fieldData = (Map<String, Object>) requiredFieldsMap.get(fieldName);
                        String value = (String) fieldData.get('value');
                        String fieldType = (String) fieldData.get('type');

                        if (fieldType == 'Date') {
                            // Convert string to Date (assuming value is in YYYY-MM-DD format)
                            if (value != null && value != '') {
                                List<String> dateParts = value.split('-');
                                if (dateParts.size() == 3) {
                                    newRecord.put(fieldName, Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2])));
                                }
                            }
                        } else if (fieldType == 'Datetime') {
                            // Convert string to Datetime (assuming value is in ISO 8601 format, e.g., YYYY-MM-DDTHH:mm:ssZ)
                            if (value != null && value != '') {
                                newRecord.put(fieldName, Datetime.valueOf(value.replace('Z', '')));
                            }
                        } else if (fieldType == 'Boolean') {
                            // Convert string to Boolean
                            if (value != null && value != '') {
                                newRecord.put(fieldName, Boolean.valueOf(value));
                            }
                        } else {
                            // Handle String, Reference, Picklist, etc. as direct string assignment
                            newRecord.put(fieldName, value);
                        }
                    }

                    if(nameField != '' && nameField != null){
                        newRecord.put(nameField, senderName.length() > 80 ? senderName.substring(0, 80) : senderName);
                    } else {
                        newRecord.put('Name', senderName.length() > 80 ? senderName.substring(0, 80) : senderName);
                    }
                    if(phoneField != '' && phoneField != null){
                        newRecord.put(phoneField, senderPhone);
                    } else {
                        newRecord.put('Phone', senderPhone);
                    }
                    
                    insert newRecord;
                    record = newRecord;
                    
                    // Set the variables after insertion
                    recordId = (String) newRecord.get('Id');
                    recordName = (String) newRecord.get('Name');
                    recordPhone = (String) newRecord.get(phoneField);
                }
            }

            DateTime myDateTime = DateTime.now();
            // String formattedDate = myDateTime.format(' d MMM yyyy');
            Date formattedDate = myDateTime.date();

            MVWB__Chat__c whatsappChat = new MVWB__Chat__c();

            if (existingChatRecords.isEmpty()){

                if(messageType.equalsIgnoreCase('reaction')){
                    List<MVWB__Chat__c> reactToChat = [SELECT Id, MVWB__Reaction__c, MVWB__Contact__c, MVWB__Phone__c FROM MVWB__Chat__c WHERE MVWB__WhatsAppMessageId__c =:reactToMessageId];
                    if(reactToChat.size() > 0){
                        reactToChat[0].MVWB__Reaction__c = reactToChat[0].MVWB__Reaction__c!=null ? reactToChat[0].MVWB__Reaction__c : '<|USER|>';
                        reactToChat[0].MVWB__Reaction__c = reactToChat[0].MVWB__Reaction__c.split('<|USER|>')[0] + '<|USER|>' + (reactedEmoji!=null ? reactedEmoji : '');
                        reactToChat[0].MVWB__Last_Interaction_Date__c = System.now();
                        whatsappChat = reactToChat[0];
                        update whatsappChat;
                        MVWB__Chat_Message__e reactEvent = new MVWB__Chat_Message__e();
                        reactEvent.MVWB__Chat_Data__c = JSON.serialize(whatsappChat);
                        reactEvent.MVWB__Type__c = 'react';
                        // reactEvent.ContactId__c = whatsappChat.Contact__c;
                        reactEvent.MVWB__ContactId__c = whatsappChat.MVWB__Phone__c;
                        EventBus.publish(reactEvent);
                    }
                    return;
                }

                // whatsappChat.Contact__c = contact.Id;
                whatsappChat.MVWB__Phone__c = senderPhone;
                whatsappChat.MVWB__Type_of_Message__c = 'Inbound Messages';
                whatsappChat.MVWB__Message_Type__c = messageType;
                whatsappChat.MVWB__WhatsAppMessageId__c = whatsAppMessageID;
                whatsappChat.MVWB__Date_of_Message__c = formattedDate;
                List<MVWB__Chat__c> replyToChat = [SELECT Id FROM MVWB__Chat__c WHERE MVWB__WhatsAppMessageId__c != null AND MVWB__WhatsAppMessageId__c =:contextId];
                whatsappChat.MVWB__Reply_To__c = replyToChat.size() > 0 ? replyToChat[0].Id : null;

                if (messageType.equalsIgnoreCase('text')){
                    Map<String, Object> text = (Map<String, Object>) message.get('text');
                    String messageBody = '';
                    if(text != null && text.values() != null){
                        messageBody = (String) text.get('body');
                    }
                    whatsappChat.MVWB__Message__c = messageBody;
                }
                if(userRecs.isEmpty()){
                    if (messageType.equalsIgnoreCase('image')){
                        Map<String, Object> image = (Map<String, Object>) message.get('image');
                        String imageId = (String) image.get('id');
                        String mimeType = (String) image.get('mime_type');
                        // String filename = whatsAppMessageID + '-' + mimeType;
                        String fileExtension = getFileExtension(mimeType);
                        String fileDateFormat = myDateTime.format('ddMMyyyy_HHmmss');
                        String filename = 'IMG-' + fileDateFormat + fileExtension;
    
                        Blob documentBody = handleMediaAttachment(imageId);
                        Map<String, Object> filedata = new Map<String, Object>();
                        if (documentBody != null){
                            if(configData != null) {
                                String fileUrl = AWSFilesController.uploadFileToS3(fileName, documentBody, mimeType);
                                whatsappChat.MVWB__Message__c = fileUrl;
                                fileData = new Map<String, Object>{ 'fileName' => filename, 'mimeType' => mimeType };
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(filedata);
                            } else {
                                filedata = saveMediaToSalesforce(documentBody, filename, mimeType, recordId, objectApiName);
                                whatsappChat.MVWB__Message__c = '/sfc/servlet.shepherd/version/download/'+filedata.get('contentVersionId');
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(fileData);
                            }
                        }
                    }
                    if (messageType.equalsIgnoreCase('document')){
                        Map<String, Object> document = (Map<String, Object>)message.get('document');
                        String mediaId = (String) document.get('id');
                        String mimeType = (String) document.get('mime_type');
                        // String filename = whatsAppMessageID + '-' + mimeType;
                        String name = (String) document.get('filename');
                        String fileExtension = getFileExtension(mimeType);
                        String filename = name + fileExtension;

                        Blob documentBody = handleMediaAttachment(mediaId);
    
                        Map<String, Object> filedata = new Map<String, Object>();
                        if (documentBody != null){
                            if(configData != null) {
                                String fileUrl = AWSFilesController.uploadFileToS3(fileName, documentBody, mimeType);
                                whatsappChat.MVWB__Message__c = fileUrl;
                                fileData = new Map<String, Object>{ 'fileName' => filename, 'mimeType' => mimeType };
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(filedata);
                            } else {
                                filedata = saveMediaToSalesforce(documentBody, filename, mimeType, recordId, objectApiName);
                                whatsappChat.MVWB__Message__c = '/sfc/servlet.shepherd/version/download/'+filedata.get('contentVersionId');
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(fileData);
                            }
                        }
                    }
                    if (messageType.equalsIgnoreCase('video')){
                        Map<String, Object> video = (Map<String, Object>) message.get('video');
                        String videoId = (String) video.get('id');
                        String mimeType = (String) video.get('mime_type');
                        // String filename = whatsAppMessageID + '-' + mimeType;
                        String fileExtension = getFileExtension(mimeType);
                        String fileDateFormat = myDateTime.format('ddMMyyyy_HHmmss');
                        String filename = 'VID-' + fileDateFormat + fileExtension;
    
                        Blob documentBody = handleMediaAttachment(videoId);
                        Map<String, Object> filedata = new Map<String, Object>();
                        if (documentBody != null){
                            if(configData != null) {
                                String fileUrl = AWSFilesController.uploadFileToS3(fileName, documentBody, mimeType);
                                whatsappChat.MVWB__Message__c = fileUrl;
                                fileData = new Map<String, Object>{ 'fileName' => filename, 'mimeType' => mimeType };
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(filedata);
                            } else {
                                filedata = saveMediaToSalesforce(documentBody, filename, mimeType, recordId, objectApiName);
                                whatsappChat.MVWB__Message__c = '/sfc/servlet.shepherd/version/download/'+filedata.get('contentVersionId');
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(fileData);
                            }
                        }
                    }
                    if (messageType.equalsIgnoreCase('audio')){
                        Map<String, Object> video = (Map<String, Object>) message.get('audio');
                        String audioId = (String) video.get('id');
                        String mimeType = (String) video.get('mime_type');
                        // String filename = whatsAppMessageID + '-' + mimeType;
                        String fileExtension = getFileExtension(mimeType);
                        String fileDateFormat = myDateTime.format('ddMMyyyy_HHmmss');
                        String filename = 'AUD-' + fileDateFormat + fileExtension;
    
                        Blob documentBody = handleMediaAttachment(audioId);
                        Map<String, Object> filedata = new Map<String, Object>();
                        if (documentBody != null){
                            if(configData != null) {
                                String fileUrl = AWSFilesController.uploadFileToS3(fileName, documentBody, mimeType);
                                whatsappChat.MVWB__Message__c = fileUrl;
                                fileData = new Map<String, Object>{ 'fileName' => filename, 'mimeType' => mimeType };
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(filedata);
                            } else {
                                filedata = saveMediaToSalesforce(documentBody, filename, mimeType, recordId, objectApiName);
                                whatsappChat.MVWB__Message__c = '/sfc/servlet.shepherd/version/download/'+filedata.get('contentVersionId');
                                whatsappChat.MVWB__File_Data__c = JSON.serialize(fileData);
                            }
                        }
                    }
                    if (messageType.equalsIgnoreCase('button')){
                        Map<String, Object> button = (Map<String, Object>)message.get('button');
                        String payload = (String) button.get('payload');
                        String text = (String) button.get('text');
                        whatsappChat.MVWB__Message__c = text;
                        if (contextId != null && contextId != ''){
                            whatsappChat.MVWB__WhatsAppContextMessageID__c = contextId;
                        }
                        whatsappChat.MVWB__Message_Type__c = 'text';
                    }
                }

                // Rachit - WP Flow changes
                if (messageType.equalsIgnoreCase('interactive')) {
                    Map<String, Object> interactive = (Map<String, Object>)message.get('interactive');
                    System.debug('interactive: ' + interactive);
                    if (interactive != null) { 
                        String interactiveType = (String)interactive.get('type');
                        if (interactiveType == 'nfm_reply') {
                            Map<String, Object> nfmReply = (Map<String, Object>)interactive.get('nfm_reply');
                            System.debug('nfmReply : ' + nfmReply);
                            if (nfmReply != null) { 
                                String responseJson = (String)nfmReply.get('response_json');
                                System.debug('responseJson: ' + responseJson);
                                if(responseJson != null){
                                    whatsappChat.MVWB__Flow_Response_JSON__c = responseJson;
                                }
                            }
                        }
                        whatsappChat.MVWB__Message_Type__c = 'interactive';
                        if (contextId != null && contextId != ''){
                            whatsappChat.MVWB__WhatsAppContextMessageID__c = contextId;
                        }
                    }
                }
            }
            whatsappChat.MVWB__Last_Interaction_Date__c = System.now();
            insert whatsappChat;
            // System.debug('Chat__c record created: ' + whatsappChat);
            MVWB__Chat_Message__e newChatEvent = new MVWB__Chat_Message__e();
            MVWB__Chat__c chatToSend = [SELECT Id, MVWB__Type_of_Message__c, MVWB__WhatsAppMessageId__c, MVWB__Message__c, MVWB__Message_Status__c, MVWB__Message_Type__c, MVWB__Reply_To__c, MVWB__Reaction__c, MVWB__Whatsapp_Template__c, MVWB__Whatsapp_Template__r.Name, CreatedDate, MVWB__Last_Interaction_Date__c, MVWB__Contact__c, MVWB__Phone__c, MVWB__File_Data__c FROM MVWB__Chat__c WHERE Id =:whatsappChat.Id LIMIT 1];
            newChatEvent.MVWB__Chat_Data__c = JSON.serialize(chatToSend);
            newChatEvent.MVWB__Type__c = 'new';
            // newChatEvent.ContactId__c = whatsappChat.Contact__c;
            newChatEvent.MVWB__ContactId__c = whatsappChat.MVWB__Phone__c;
            EventBus.publish(newChatEvent);

            if(userRecs.isEmpty()){
                List<MVWB__Chat__c> lastSentChat = [SELECT Id, MVWB__Phone__c, CreatedById FROM MVWB__Chat__c WHERE MVWB__Phone__c = :formattedNumber AND MVWB__Type_of_Message__c = 'Outbound Messages' ORDER BY CreatedDate DESC LIMIT 1];
                if (lastSentChat.size() > 0){
                    sendNotificationForContact(recordId, objectApiName, lastSentChat[0].CreatedById);
                } else {
                    sendNotificationForContact(recordId, objectApiName, null);
                }
            }

        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'processSingleMessage', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in processSingleMessage: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    public static String getFileExtension(String mimeType){
        if (mimeType.equals('image/jpeg')){
            return '.jpeg';
        } else if (mimeType.equals('image/png')){
            return '.png';
        } else if (mimeType.equals('image/jpg')){
            return '.jpg';
        } else if (mimeType.equals('audio/mp3') || mimeType.equals('audio/mpeg')){
            return '.mp3';
        } else if (mimeType.equals('audio/aac')){
            return '.aac';
        } else if (mimeType.equals('audio/ogg; codecs=opus')){
            return '.ogg';
        } else if (mimeType.equals('video/mp4')){
            return '.mp4';
        } else if (mimeType.equals('video/3gp')){
            return '.3gp';
        } else if (mimeType.equals('application/pdf')){
            return '.pdf';
        } else if (mimeType.equals('application/msword')){
            return '.doc';
        } else if (mimeType.equals('application/vnd.openxmlformats-officedocument.wordprocessingml.document')){
            return '.docx';
        } else if (mimeType.equals('application/vnd.ms-powerpoint')){
            return '.ppt';
        } else if (mimeType.equals('application/vnd.openxmlformats-officedocument.presentationml.presentation')){
            return '.pptx';
        } else if (mimeType.equals('application/vnd.ms-excel')){
            return '.xls';
        } else if (mimeType.equals('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')){
            return '.xlsx';
        } else if (mimeType.equals('text/plain')){
            return '.txt';
        } else{
            return '.bin';
        }
    }

    // @future(callout=true)
    public static Blob handleMediaAttachment(String documentId){
        try{
            String accessToken = '';
            List<MVWB__WBConnect_Configuration__mdt> config = MVWB__WBConnect_Configuration__mdt.getAll().values();
            accessToken = config[0].MVWB__Access_Token__c;
            String mediaUrl = config[0].MVWB__API_Endpoint__c + '/' + config[0].MVWB__API_Version__c + '/' + documentId;
            
            if (accessToken != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint(mediaUrl);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                HttpResponse res;

                try{
                    Http http = new Http();
                    res = http.send(req);
                    System.debug('res:- '+res);

                    if (res.getStatusCode() == 200){
                        // Parse the metadata response
                        Map<String, Object> mediaMetadata = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                        String downloadUrl = (String) mediaMetadata.get('url'); // Retrieve download URL from metadata
                        system.debug('mediaid url===> ' + downloadUrl);

                        // Download the media content
                        return downloadMediaContent(downloadUrl, accessToken);
                    } else{
                        System.debug('Failed to retrieve media metadata. Status: ' + res.getStatus() + ', Response: ' + res.getBody());
                        return null;
                    }
                } catch (Exception e){
                    System.debug('Error in handleMediaAttachment: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
                    return null;
                }
            } else{
                System.debug('Failed fetched access token and endpoint from custom labels');
                return null;
            }
        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'processSingleMessage', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in handleMediaAttachment: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
            return null;
        }
    }

    public static Blob downloadMediaContent(String mediaUrl, String accessToken){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(mediaUrl);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        HttpResponse res;

        try{
            Http http = new Http();
            res = http.send(req);

            if (res.getStatusCode() == 200){
                // Return the binary data
                return res.getBodyAsBlob();
            } else{
                System.debug('Failed to download media. Status: ' + res.getStatus() + ', Response: ' + res.getBody());
                return null;
            }
        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'downloadMediaContent', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in downloadMediaContent: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
            return null;
        }
    }

    public static Map<String, Object> saveMediaToSalesforce(Blob mediaBlob, String filename, String mimeType, Id parentRecordId, String objectApiName){
        Map<String, Object> fileData = new Map<String, Object>();
        try{
            // Lead contact = [SELECT Id, Name, OwnerId FROM Lead WHERE Id = :parentRecordId LIMIT 1];
            // Query the object specified in objectApiName using dynamic SOQL
            String query = 'SELECT Id, CreatedById FROM ' + objectApiName + ' WHERE Id = :parentRecordId LIMIT 1';
            List<SObject> records = Database.query(query);
            SObject record = records[0];

            // Create ContentVersion with Contact's OwnerId
            System.debug('filename--> '+ filename);
            ContentVersion contentVersion = new ContentVersion(
                Title = filename, 
                VersionData = mediaBlob, 
                PathOnClient = filename, 
                ContentLocation = 'S', 
                OwnerId = (Id) record.get('CreatedById')
            );

            insert contentVersion;

            ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
            String contentDocumentId = insertedContentVersion.ContentDocumentId;

            CDLWrapper cdlWrap = new CDLWrapper((String) record.get('Id'), contentDocumentId);
            String body = JSON.Serialize(cdlWrap);

            sendEmail(body);


            System.debug('Media file saved as ContentDocument Id: ' + contentDocumentId);

            // Construct fileData object
            fileData = new Map<String, Object>{ 'fileName' => filename, 'documentId' => contentDocumentId, 'contentVersionId' => contentVersion.Id, 'mimeType' => mimeType };

        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'saveMediaToSalesforce', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in saveMediaToSalesforce: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
        return filedata;
    }

    public static void sendNotificationForContact(String recordId, String objectApiName, String addresseeId){
        try{
            String query = 'SELECT Id, Name, CreatedById FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);
            sObject record = records[0];

            List<CustomNotificationType> cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'WBConnectNotification' LIMIT 1];
            System.debug('custom notification===> ' + cnType[0]);

            // Id userId = Userinfo.getUserId();
            String messageContent = (String) record.get('Name') + ' has sent a new message. Tap to view.';
            System.debug('messageContent==> ' + messageContent);
            // Prepare the custom notification object
            Set<String> addressee = new Set<String>();
            addressee.add((Id) record.get('CreatedById'));
            if( addresseeId != null && addresseeId != ''){
                addressee.add((Id) addresseeId);
            }
            Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
            customNotificationObj.setBody(messageContent);
            customNotificationObj.setTitle('New Whatsapp Message Received');
            customNotificationObj.setNotificationTypeId(cnType[0].Id);
            customNotificationObj.setTargetId((Id) record.get('Id'));
            customNotificationObj.send(addressee);

        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'sendNotificationForContact', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in sendNotificationForContact: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    public static void parseMessages(String jsonString){
        try{
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            List<Object> entries = (List<Object>)jsonMap.get('entry');

            if (entries != null && !entries.isEmpty()){
                for (Object entryObj : entries){
                    Map<String, Object> entry = (Map<String, Object>)entryObj;
                    List<Object> changes = (List<Object>)entry.get('changes');

                    if (changes != null && !changes.isEmpty()){
                        for (Object changeObj : changes){
                            Map<String, Object> change = (Map<String, Object>)changeObj;
                            Map<String, Object> value = (Map<String, Object>)change.get('value');
                            List<Object> statuses = (List<Object>)value.get('statuses');

                            if (statuses != null && !statuses.isEmpty()){
                                for (Object statusObj : statuses){
                                    Map<String, Object> statusMap = (Map<String, Object>)statusObj;
                                    String status = (String) statusMap.get('status');
                                    String waid = statusMap!= null ? (String) statusMap.get('id') : null;

                                    List<MVWB__Chat__c> waChats = [SELECT Id, MVWB__Message_Status__c, MVWB__WhatsAppMessageId__c, MVWB__Phone__c FROM MVWB__Chat__c WHERE MVWB__WhatsAppMessageId__c = :waid LIMIT 1];
                                    if(waChats.size() > 0){
                                        MVWB__Chat__c waChat = waChats[0];
                                        if (status == 'sent' && waChat.MVWB__Message_Status__c != 'Delivered' && waChat.MVWB__Message_Status__c != 'Seen'){
                                            waChat.MVWB__Message_Status__c = 'Sent';
                                        } else if (status == 'delivered' && waChat.MVWB__Message_Status__c != 'Seen'){
                                            waChat.MVWB__Message_Status__c = 'Delivered';
                                        } else if (status == 'read'){
                                            waChat.MVWB__Message_Status__c = 'Seen';
                                        }
                                        update waChat;
                                        MVWB__Chat_Message__e statusChangeEvent = new MVWB__Chat_Message__e();
                                        statusChangeEvent.MVWB__Chat_Data__c = JSON.serialize(waChat);
                                        // statusChangeEvent.ContactId__c = waChat.Contact__c;
                                        statusChangeEvent.MVWB__ContactId__c = waChat.MVWB__Phone__c;
                                        statusChangeEvent.MVWB__Type__c = 'status';
                                        EventBus.publish(statusChangeEvent);
                                    }

                                }
                            }

                            if (value.containsKey('event')){
                                String event = (String) value.get('event');
                                String templateId = String.valueOf(value.get('message_template_id'));
                                updateWhatsAppTemplateStatus(templateId, event);
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'parseMessages', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in parseMessages: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    // @future(callout = true)
    public static void updateWhatsAppTemplateStatus(String templateId, String event){
        try{
            List<MVWB__Template__c> templates = [SELECT Id, MVWB__Status__c FROM MVWB__Template__c WHERE MVWB__Template_Id__c = :templateId LIMIT 1];

            if (!templates.isEmpty()){
                MVWB__Template__c waTemplate = templates[0];

                if (event == 'APPROVED'){
                    waTemplate.MVWB__Status__c = 'Active-Quality Pending';
                } else if (event == 'PENDING'){
                    waTemplate.MVWB__Status__c = 'In-Review';
                } else if (event == 'REJECTED'){
                    waTemplate.MVWB__Status__c = 'Rejected';
                }
                update waTemplate;

                MVWB__Template_Update__e templateStatusEvent = new MVWB__Template_Update__e();
                templateStatusEvent.MVWB__Template_Id__c = waTemplate.Id;
                templateStatusEvent.MVWB__Template_Status__c = waTemplate.MVWB__Status__c;
                EventBus.publish(templateStatusEvent);

            } else{
                System.debug('No WhatsApp Template found for Template Id: ' + templateId);
            }
        } catch (Exception e){
            System.debug('Error in updateWhatsAppTemplateStatus: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    @future(callout = true)
    public static void sendEmail(String body){
        try{
            EmailServicesAddress esa = [SELECT EmailDomainName, LocalPart FROM EmailServicesAddress WHERE Function.FunctionName =: 'EmailService_WhatsApp' LIMIT 1];
         
            Messaging.SingleEmailMessage emailNotification = new Messaging.SingleEmailMessage();        
            List<String> toAddresses = new List<String>();
            toAddresses.add(esa.LocalPart+'@' +esa.EmailDomainName);
            // if ( owea.size() > 0 ) {
            //     emailNotification.setOrgWideEmailAddressId(owea.get(0).Id);
            // }
            emailNotification.setToAddresses(toAddresses);
            emailNotification.setSubject('Three Object Form');
            emailNotification.setPlainTextBody(body);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ emailNotification });


        } catch (Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppWebhook', 'methodName' => 'sendEmail', 'exceptionObj' => e, 'isApiException' => False, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            System.debug('Error in sendEmailViaGmail: ' + e.getMessage() + '\n' + e + '\n Exception line no: ' + e.getLineNumber());
        }
    }

    public class CDLWrapper{
        public String linkedEntityId;
        public String contentDocumentId;
        public CDLWrapper(String linkedEntityId, String contentDocumentId){
            this.linkedEntityId = linkedEntityId;
            this.contentDocumentId = contentDocumentId;
        }
    }
}