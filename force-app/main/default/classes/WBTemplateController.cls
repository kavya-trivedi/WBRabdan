/**
 * Class Name: WBTemplateController
 * Test Class: 
 * @description: Used in LWC components, it used to get the template record, 
                picklist value from static resource and callout for creation of template.
 * Date: 25/11/2024
 * Created By: Kajal Tiwari
 */
 /***********************************************************************
 MODIFICATION LOG*
 * Last Update Date : 24/12/2024
 * Updated By : Kajal Tiwari
 * Name of methods changed (Comma separated if more then one) : restrictTemplates,sendPreviewTemplate
 * Change Description : 
 ***********************************************************************/

 public with sharing class WBTemplateController {
    
    // public static final MVWB__WBConnect_Configuration__mdt SETTINGS[0];
    public static List<MVWB__WBConnect_Configuration__mdt> SETTINGS = MVWB__WBConnect_Configuration__mdt.getAll().values(); 
    public static String accessToken = !SETTINGS.isEmpty() ? SETTINGS[0].MVWB__Access_Token__c : null;
    public static String uploadEndpoint;


     /*
   *********************************************************
   @description     : Used in WbAllTemplatePage to get all template record.
   @param           : 
   @return          : listName - Whatsapp Template record.
   ********************************************************
   */
 @AuraEnabled(cacheable=false)
   public static List<Template__c> getWhatsAppTemplates() {
       try {
           List<Template__c> listName = [SELECT Id, Name,Template_Name__c, Template_Category__c, toLabel(Language__c) LanguageLabel,File_Name__c,WBImage_Header_Handle__c, Status__c, LastModifiedById,LastModifiedDate, CreatedDate 

           FROM Template__c WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC];

           return listName;
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'getWhatsAppTemplates', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
           return null;
       }
   }

       /*
   *********************************************************
   @description     : trigger handle to handle limit of 5 records.
   @param           : 
   @return          : void
   ********************************************************
   */
   public static void restrictTemplates(List<Template__c> templates) {
       try {
           Integer totalTemplates = [SELECT COUNT() FROM Template__c WITH SECURITY_ENFORCED];
           
           if (totalTemplates + templates.size() > 5) {
               if (!Test.isRunningTest()) {
                   for (Template__c template : templates) {
                       template.addError('You cannot create more than 5 Template records.');
                   }
               } 
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'restrictTemplates', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
       }
   }
   
       /*
   *********************************************************
   @description     : Send preview message.
   @param           : 
   @return          : errorMessage
   ********************************************************
   */
   @AuraEnabled
   public static String sendPreviewTemplate(String jsonData) {
       String errorMessage=null;
       try {
           HttpRequest httpReq = new HttpRequest();
           List<MVWB__WBConnect_Configuration__mdt> config = MVWB__WBConnect_Configuration__mdt.getAll().values(); 
           if(config==null && config.isEmpty()){
               errorMessage='Metadata records are missing.';
               return errorMessage;
           }
           String accessToken = config[0].MVWB__Access_Token__c;
           String endpoint = config[0].MVWB__API_Endpoint__c + '/' + config[0].MVWB__API_Version__c + '/' + config[0].MVWB__Phone_Number_Id__c + '/messages';
           httpReq.setEndpoint(endpoint);
           httpReq.setMethod('POST');
           httpReq.setHeader('Content-Type', 'application/json');
           httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
           httpReq.setBody(jsonData);
           Http http = new Http();
           HttpResponse response = http.send(httpReq);
           Integer statusCode = response.getStatusCode();
           if(statusCode != 200){
               errorMessage='Failed to send Template';
               ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'sendPreviewTemplate', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => statusCode, 'chatId' => null, 'moreDetails' => 'API Exception while sending a message', 'apiResponse' => JSON.serialize(response.getBody()) });
           }

       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'sendPreviewTemplate', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null });
       }
       return errorMessage;
   }

    /*
   *********************************************************
   @description     : Used to fetch all the field related to object name
   @param           : 
   @return          : fieldNames - Return fields that query for the objectname that pass.
   ********************************************************
   */
   @AuraEnabled(cacheable=true)
   public static List<String> getObjectFields(String objectName) {
       // String objectName = 'Contact';
       List<String> fieldNames = new List<String>();
       try {
           Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
           Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
           for (String fieldName : fieldsMap.keySet()) {
               fieldNames.add(fieldsMap.get(fieldName).getDescribe().getName()); 
           }
           fieldNames.sort();
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'getObjectFields', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
       }
       return fieldNames;
   }

   /*
   *********************************************************
   @description     : Fetch records based on the object name
   @param           : 
   @return          : records - Return record that query for the objectname that pass.
   ********************************************************
   */
   @AuraEnabled(cacheable=true)
   public static List<sObject> getRecordsBySObject(String objectName) {
       String sObjectName=objectName;
       List<sObject> records = new List<sObject>();
       
       try {
           String query = 'SELECT Id, Name, Phone FROM ' + sObjectName + ' WHERE Phone != null LIMIT 200';           
           records = Database.query(query);
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'getRecordsBySObject', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
       }
       return records;
   }




   /*
   *********************************************************
   @description     : This method use to fetch template data and variable mapping done in js.
   @param           : 
   @return          : wrapper - Return wrapper that contain object name and field name from the Template Variable.
   ********************************************************
   */
   @AuraEnabled(cacheable=true)
   public static TemplateDataWrapper getDynamicObjectData(Id templateId) {
       TemplateDataWrapper wrapper = new TemplateDataWrapper();
       Set<String> objectNames = new Set<String>();
       Set<String> fieldNames = new Set<String>();
       wrapper.templateVariables = new List<Map<String, String>>();

       try {
           List<Template__c> templates = [
               SELECT Id, Name,Template_Name__c, WBButton_Body__c, Status__c,WBImage_Header_Handle__c, Template_Id__c, Button_Label__c, Button_Type__c, File_Name__c,
                   WBFooter_Body__c, WBHeader_Body__c, Header_Type__c, Language__c, WBTemplate_Body__c, 
                   Template_Category__c, Template_Type__c , Template_Miscellaneous_Data__c
               FROM Template__c 
               WHERE Id = :templateId WITH SECURITY_ENFORCED
               ORDER BY LastModifiedDate DESC
               LIMIT 1
           ];

           if (templates.isEmpty()) {
               return wrapper; 
           }

           Template__c template = templates[0];
           wrapper.template = template;

           if (template.Header_Type__c == 'Image') {
               wrapper.isImgUrl = true;
           }
           else if (template.Header_Type__c == 'Video') {
               wrapper.isImgUrl = true;
           }
           else if (template.Header_Type__c == 'Document') {
               wrapper.isImgUrl = true;
           }
           

           List<Template_Variable__c> templateVariables = [
               SELECT Name, Object_Name__c, Field_Name__c, Type__c, Alternate_Text__c
               FROM Template_Variable__c 
               WHERE Template__c = :template.Id WITH SECURITY_ENFORCED
           ];

           if (!templateVariables.isEmpty()) {
               for (Template_Variable__c variable : templateVariables) {
                   Map<String, String> mapping = new Map<String, String>();
                   mapping.put('type', variable.Type__c);
                   mapping.put('variable', variable.Name);
                   mapping.put('objName', variable.Object_Name__c);
                   mapping.put('alternateText', variable.Alternate_Text__c);
                   mapping.put('fieldName', variable.Field_Name__c);
                   wrapper.templateVariables.add(mapping);

                   objectNames.add(variable.Object_Name__c);
                   fieldNames.add(variable.Field_Name__c);
               }

               wrapper.objectNames = new List<String>(objectNames);
               wrapper.fieldNames = new List<String>(fieldNames);
           }

       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{
               'className' => 'WBTemplateController','methodName' => 'getDynamicObjectData','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null
           });
       }

       return wrapper;
   }

   /*
   *********************************************************
   @description     : Fetch records based on the dynamic object name, fieldname and recordid
   @param           : objectName, fieldNames, recordId
   @return          : resultMap {Map<String, Object>} - Return queried data.
   ********************************************************
   */
   @AuraEnabled(cacheable=true)
   public static Map<String, Object> fetchDynamicRecordData(String objectName, List<String> fieldNames, String recordId) {
       Map<String, Object> resultMap = new Map<String, Object>();

       try {
           if (String.isEmpty(objectName) || fieldNames.isEmpty() || String.isEmpty(recordId)) {
               throw new AuraHandledException('Invalid input parameters');
           }

           if (!fieldNames.contains('Phone')) {
                   fieldNames.add('Phone');
           }
           String fields = String.join(fieldNames, ',');
           
           String queryString = 'SELECT ' + fields + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';            
           List<SObject> queriedData = Database.query(queryString);

           if (!queriedData.isEmpty()) {
               resultMap.put('queriedData', queriedData[0]);  
           } else {
               resultMap.put('queriedData', null);
           }

       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'fetchDynamicRecordData', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
           resultMap.put('error', e.getMessage());
       }

       return resultMap;
   }
   
    /*
   *********************************************************
   @description     : It used to replace variable from backend to handle the sending of template variable.
   @param           : recordId
   @return          : result {Map<String, Object>} - Return the replace template content based on the template variable fields by fetching from contact object.
   ********************************************************
   */

   @AuraEnabled
   public static Map<String, Object> getTemplateDataWithReplacement(String templateId, String contactId) {
       try {
           Map<String, Object> templateData = new Map<String, Object>();
           List<Template__c> templates = [SELECT Id, Name,Template_Name__c, WBButton_Body__c, Button_Label__c, Button_Type__c,WBImage_Header_Handle__c, 
                                               WBFooter_Body__c, WBHeader_Body__c, Header_Type__c, Language__c,File_Name__c, 
                                               WBTemplate_Body__c, Template_Category__c, 
                                               Template_Type__c, Template_Variable__c, Template_Miscellaneous_Data__c,
                                               (SELECT Id, Name, Field_Name__c, Object_Name__c, Type__c, Alternate_Text__c 
                                                   FROM WB_Template_Variables__r ORDER BY Name ASC) 
                                           FROM Template__c 
                                           WHERE Id = :templateId 
                                           WITH SECURITY_ENFORCED];
           if (templates.size() > 0) {
               Template__c template = templates[0];

               if (template.Template_Variable__c > 0) {
                   List<Object> headerVariables = new List<Object>();
                   List<Object> bodyVariables = new List<Object>();

                   // Scenario 1: Contact ID is passed
                   if (String.isNotBlank(contactId)) {
                       Set<String> fieldSelectionCause = new Set<String>();
                       for (Template_Variable__c tv : template.WB_Template_Variables__r) {
                           if (tv.Object_Name__c == 'Contact') {
                               fieldSelectionCause.add(tv.Field_Name__c);
                           } else {
                               fieldSelectionCause.add(tv.Object_Name__c + '.' + tv.Field_Name__c);
                           }
                       }

                       if (fieldSelectionCause.size() > 0) {
                           String query = 'SELECT Id, ' + String.join(fieldSelectionCause, ', ') + ' FROM Contact WHERE Id =:contactId';
                           List<Contact> contacts = Database.query(query);
                           if (contacts.size() > 0) {
                               Contact contactRecord = contacts[0];
                               for (Template_Variable__c tv : template.WB_Template_Variables__r) {
                                   Object valueToReplace = '';
                                   if (tv.Object_Name__c == 'Contact') {
                                       valueToReplace = contactRecord.get(tv.Field_Name__c);
                                   } else {
                                       valueToReplace = contactRecord.getSObject(tv.Object_Name__c) != null ? 
                                                       contactRecord.getSObject(tv.Object_Name__c).get(tv.Field_Name__c) : null;
                                   }
                                   
                                   if (tv.Type__c == 'Header') {
                                       String replacement = (valueToReplace != null ? valueToReplace.toString() : 
                                                             (tv.Alternate_Text__c != null ? tv.Alternate_Text__c : ''));
                                   
                                       headerVariables.add(replacement);
                                       template.WBHeader_Body__c = template.WBHeader_Body__c.replace(tv.Name, replacement);
                                   } else if (tv.Type__c == 'Body') {
                                       String replacement = (valueToReplace != null ? valueToReplace.toString() : 
                                                             (tv.Alternate_Text__c != null ? tv.Alternate_Text__c : ''));
                                   
                                       bodyVariables.add(replacement);
                                       template.WBTemplate_Body__c = template.WBTemplate_Body__c.replace(tv.Name, replacement);
                                   }
                                   
                               }
                           }
                       }
                   } 
                   // Scenario 2: Contact ID not passed
                   else {
                       for (Template_Variable__c tv : template.WB_Template_Variables__r) {
                           if (tv.Type__c == 'Header') {
                               headerVariables.add(tv.Alternate_Text__c != null ? tv.Alternate_Text__c : '{{' + tv.Name + '}}');
                               template.WBHeader_Body__c = template.WBHeader_Body__c.replace(tv.Name, 
                                                           tv.Alternate_Text__c != null ? tv.Alternate_Text__c : '{{' + tv.Name + '}}');
                           } else if (tv.Type__c == 'Body') {
                               // bodyVariables.add(tv.Alternate_Text__c != null ? tv.Alternate_Text__c : '{{' + tv.Name + '}}');
                               bodyVariables.add(tv.Alternate_Text__c != null ? tv.Alternate_Text__c : tv.Name);
                               template.WBTemplate_Body__c = template.WBTemplate_Body__c.replace(tv.Name, 
                                                           tv.Alternate_Text__c != null ? tv.Alternate_Text__c : tv.Name);
                                                           // tv.Alternate_Text__c != null ? tv.Alternate_Text__c : '{{' + tv.Name + '}}');
                           }
                       }
                   }

                   templateData.put('template', template);
                   templateData.put('headerParams', headerVariables);
                   templateData.put('bodyParams', bodyVariables);
               } else {
                   templateData.put('template', template);
               }

               return templateData;
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'getTemplateData','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null
           });
       }
       return null;
   }
   
      /*
   *********************************************************
   @description     : Get picklist value for catagory and status used in WbAllTemplatePage to filter.
   @param           : 
   @return          : picklistValues {Map<String, List<String>>} - return picklist value for catagory and status from template object.
   ********************************************************
   */
   @AuraEnabled(cacheable=true)
   public static Map<String, List<String>> getCategoryAndStatusPicklistValues() {
       Map<String, List<String>> picklistValues = new Map<String, List<String>>();

       List<String> categoryValues = new List<String>();
       List<String> statusValues = new List<String>();

       try {
           // Fetch Category__c picklist values
           Schema.DescribeFieldResult categoryFieldResult = Template__c.Template_Category__c.getDescribe();
           for (Schema.PicklistEntry entry : categoryFieldResult.getPicklistValues()) {
               categoryValues.add(entry.getLabel());
           }

           // Fetch Status__c picklist values
           Schema.DescribeFieldResult statusFieldResult = Template__c.Status__c.getDescribe();
           for (Schema.PicklistEntry entry : statusFieldResult.getPicklistValues()) {
               statusValues.add(entry.getLabel());
           }

           picklistValues.put('categories', categoryValues);
           picklistValues.put('statuses', statusValues);

           return picklistValues;
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'getCategoryAndStatusPicklistValues', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
           return null;
       }
       
   }

   /*
   *********************************************************
   @description     : Callout to create template in the Meta and the Body creation and response handle in CreateTemplateWrapper Class.
   @param           : serializedWrapper - get serialize wrapper from the js to create template.
   @return          : response Map<String, Object> - return response with the template id.
   ********************************************************
   */
    @AuraEnabled
    public static Map<String, Object> createWhatsappTemplate(String serializedWrapper,String payloadWrapper, String templateName) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            if (String.isBlank(SETTINGS[0].MVWB__Business_Account_Id__c)) {
                response.put('success', false);
                response.put('errorMessage', 'Business Account ID is not configured in the system.');
                return response;
            }

            CreateTemplateWrapper.TemplateWrapper templateWrapper = (CreateTemplateWrapper.TemplateWrapper) JSON.deserialize(serializedWrapper, CreateTemplateWrapper.TemplateWrapper.class);

            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadWrapper);
            System.debug('payload :: '+payload);
            String endpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/' + SETTINGS[0].MVWB__Business_Account_Id__c+'/message_templates';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setBody(JSON.serialize(payload));
    
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Id templateId = CreateTemplateWrapper.handleSuccessResponse((String) responseMap.get('id'), (String) responseMap.get('status'), payload, templateWrapper);
                response.put('success', true);
                response.put('templateId', templateId); 
            } else {
                response.put('success', false);
                response.put('errorMessage', res.getBody());
                // if (String.isNotBlank(templateWrapper.tempImgId)) {
                //     ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id = :templateWrapper.tempImgId WITH SECURITY_ENFORCED LIMIT 1];
                //     if (Schema.sObjectType.ContentDocument.isDeletable()) {
                //         delete contentDoc;
                //     }
                // }

                if (String.isNotBlank(templateWrapper.tempImgId)) {
                    ContentVersion version = [
                        SELECT ContentDocument.Id 
                        FROM ContentVersion 
                        WHERE Id = :templateWrapper.tempImgId 
                        WITH SECURITY_ENFORCED 
                        LIMIT 1
                    ];

                    if (version != null && Schema.sObjectType.ContentDocument.isDeletable()) {
                        delete version.ContentDocument;
                    }
                }


                ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'createWhatsappTemplate','exceptionObj' => null,'isApiException' => true,'statusCode' => res.getStatusCode(),'chatId' => null,'moreDetails' => 'HTTP callout failed with status: ' + res.getStatusCode(),'apiResponse' => res.getBody()});
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'createWhatsappTemplate', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            if (e instanceof CalloutException && e.getMessage().containsIgnoreCase('Read timed out')) {
                response.put('success', false);
                response.put('status', 'warning');
                response.put('message', 'Template is being created, you will be notified once it is ready.');
                checkTemplateExistance(templateName, serializedWrapper, payloadWrapper);
            }
            else{
                response.put('success', false);
                response.put('status', 'error');
                response.put('message', e.getMessage());
            }
        }

        return response;
    }

    @future(callout=true)
    public static void checkTemplateExistance(String templateName, String serializedWrapper, String payloadWrapper) {
        try {
            String endpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/' + SETTINGS[0].MVWB__Business_Account_Id__c + '/message_templates?name=' + EncodingUtil.urlEncode(templateName, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> dataList = (List<Object>) responseMap.get('data');

                if (!dataList.isEmpty()) {
                    // Get the first element from the list and cast it as a Map
                    Map<String, Object> templateData = (Map<String, Object>) dataList[0];

                    // Extract values
                    String metaTemplateId = (String) templateData.get('id');
                    String metaTempStatus = (String) templateData.get('status');

                    System.debug('Template ID: ' + metaTemplateId);
                    System.debug('Status: ' + metaTempStatus);

                    CreateTemplateWrapper.TemplateWrapper templateWrapper = (CreateTemplateWrapper.TemplateWrapper) JSON.deserialize(serializedWrapper, CreateTemplateWrapper.TemplateWrapper.class);
                    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadWrapper);

                    Id templateId = CreateTemplateWrapper.handleSuccessResponse(metaTemplateId, metaTempStatus, payload, templateWrapper);

                    if(templateId != null) {
                        MVWB__Template_Update__e fetchAllTemplatesEvent = new MVWB__Template_Update__e();
                        fetchAllTemplatesEvent.MVWB__Fetch_All_Templates__c = true;
                        EventBus.publish(fetchAllTemplatesEvent);
                    } else {
                        
                    }
                }
            } else {
                System.debug('API Call failed: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred while checking template existence: ' + e.getMessage());
        }
    }

   /*
   *********************************************************
   @description     : Method to get session Id for uploading file to meta.
   @param           : fileName,fileLength,fileType - get the all parameter from the js as user select the file.
   @return          : sessionId - return sessionId to start upload file in meta.
   ********************************************************
   */
   @AuraEnabled
   public static String startUploadSession(String fileName, Integer fileLength, String fileType) {
       try {
           if (String.isBlank(SETTINGS[0].MVWB__Application_Id__c)) {
               return 'Application ID is not configured in the system.';
           }
           Map<String, Object> payload = new Map<String, Object>();
           payload.put('file_name', fileName);
           payload.put('file_length', fileLength);
           payload.put('file_type', fileType);
           uploadEndpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/'+SETTINGS[0].MVWB__Application_Id__c+'/uploads';

           HttpRequest req = new HttpRequest();
           Http http = new Http();
           req.setEndpoint(uploadEndpoint);
           req.setMethod('POST');
           req.setHeader('Content-Type', 'application/json');
           req.setHeader('Authorization', 'OAuth ' + accessToken);
           req.setBody(JSON.serialize(payload));

           HttpResponse res = http.send(req);
           if (res.getStatusCode() == 200) {
               Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
               String sessionId = (String) responseMap.get('id');
               if (sessionId != null && sessionId.startsWith('upload:')) {
                   sessionId = sessionId.replace('upload:', ''); 
               }

               return sessionId; 
           } else {

               ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'startUploadSession','exceptionObj' => null,'isApiException' => true,'statusCode' => res.getStatusCode(),'chatId' => null,'moreDetails' => 'HTTP callout failed with status: ' + res.getStatusCode(),'apiResponse' => res.getBody()});
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'startUploadSession', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
       }
       return null;
   }        

   /*
   *********************************************************
   @description     : Method to upload file to meta and get file handle which use to create body for image header.
   @param           : serializedWrapper - get serialize wrapper from the js with the detail of files.
   @return          : headerHandle - return headerHandle so that can used to build body for media template.
   ********************************************************
   */
   @AuraEnabled
   public static String uploadFileChunk(String serializedWrapper, Boolean isAWSEnabled) {
       try {
           
           FileChunkWrapper fileWrapper = (FileChunkWrapper) JSON.deserialize(serializedWrapper, FileChunkWrapper.class);

           Blob fileBlob = EncodingUtil.base64Decode(fileWrapper.fileContent);

           HttpRequest req = new HttpRequest();
           Http http = new Http();

           String endpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/' + 'upload:' + fileWrapper.uploadSessionId;
           req.setEndpoint(endpoint);
           req.setMethod('POST');            
           req.setHeader('Authorization', 'OAuth ' + accessToken);
           req.setHeader('file_offset', String.valueOf(fileWrapper.chunkStart)); 
           req.setHeader('Content-Range', 'bytes ' + fileWrapper.chunkStart + '-' + (fileWrapper.chunkStart + fileWrapper.chunkSize - 1) + '/' + fileBlob.size());            
           
           req.setBodyAsBlob(fileBlob);

           HttpResponse res = http.send(req);

           if (res.getStatusCode() == 200) {
               Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
               String headerHandle = (String) responseMap.get('h');
                return JSON.serialize(new Map<String, String>{
                    'headerHandle' => headerHandle
                });
               // return headerHandle; 
           } else {
               ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'uploadFileChunk','exceptionObj' => null,'isApiException' => true,'statusCode' => res.getStatusCode(),'chatId' => null,'moreDetails' => 'HTTP callout failed with status: ' + res.getStatusCode(),'apiResponse' => res.getBody()});
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'uploadFileChunk', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
       }
       return '';
   }
     
   /*
   *********************************************************
   @description     : Method used to delete template from meta as well as from record page.
   @param           : templateId - using that can delete template.
   @return          : Return the success or error message. 
   ********************************************************
   */
   @AuraEnabled
   public static string deleteTemplete(String templateId){
       try {
           if (String.isBlank(SETTINGS[0].MVWB__Business_Account_Id__c)) {
               return 'Business Account ID is not configured in the system.';
           }

           Template__c wbTempRec = [SELECT Id, Name,Template_Name__c FROM Template__c WHERE Id =: templateId WITH SECURITY_ENFORCED LIMIT 1];
           
           String endpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/' + SETTINGS[0].MVWB__Business_Account_Id__c+'/message_templates?name=' + wbTempRec.Template_Name__c;

           HttpRequest req = new HttpRequest();         
           req.setEndpoint(endpoint);
           req.setMethod('DELETE');
           req.setHeader('Content-Type', 'application/json');
           req.setHeader('Authorization', 'Bearer ' + accessToken);
           Http http = new Http();
           HttpResponse res = http.send(req);

           if (res.getBody() != null && res.getBody() != '') {
               Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
               Boolean success = (Boolean) jsonResponse.get('success');
               if (success) {
                   if(Template__c.sObjectType.getDescribe().isDeletable()){
                       DELETE wbTempRec;
                   }
                   return 'Template deleted successfully';
               } else {
                   ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'deleteTemplete','exceptionObj' => null,'isApiException' => true,'statusCode' => res.getStatusCode(),'chatId' => null,'moreDetails' => 'HTTP callout failed with status: ' + res.getStatusCode(),'apiResponse' => res.getBody()
                   });
                   return 'Template is not deleted';
               }
           } else {

               return 'Template is not deleted';
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'deleteTemplete', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
           return e.getMessage();
       }
   }

    /*
   *********************************************************
   @description     : Callout to edit template in the Meta and the Body creation and response handle in CreateTemplateWrapper Class.
   @param           : serializedWrapper - get serialize wrapper from the js to create template.
   @return          : response Map<String, Object> - return response with the template id.
   ********************************************************
   */
    @AuraEnabled
    public static Map<String, Object> editWhatsappTemplate(String serializedWrapper,String payloadWrapper,String templateId) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            CreateTemplateWrapper.TemplateWrapper templateWrapper = (CreateTemplateWrapper.TemplateWrapper) JSON.deserialize(serializedWrapper, CreateTemplateWrapper.TemplateWrapper.class);
            String editEndpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/'+templateId;
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadWrapper);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(editEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setBody(JSON.serialize(payload));
    
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    CreateTemplateWrapper.handleSuccessResponse((String) responseMap.get('id'), (String) responseMap.get('status'), payload, templateWrapper);
                response.put('success', true);
            } else {
                response.put('success', false);
                response.put('errorMessage', res.getBody());
                // if (String.isNotBlank(templateWrapper.tempImgId)) {
                //     ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id = :templateWrapper.tempImgId WITH SECURITY_ENFORCED LIMIT 1];
                //     if (Schema.sObjectType.ContentDocument.isDeletable()) {
                //         delete contentDoc;
                //     }
                // }
                if (String.isNotBlank(templateWrapper.tempImgId)) {
                    ContentVersion version = [
                        SELECT ContentDocument.Id 
                        FROM ContentVersion 
                        WHERE Id = :templateWrapper.tempImgId 
                        WITH SECURITY_ENFORCED 
                        LIMIT 1
                    ];

                    if (version != null && Schema.sObjectType.ContentDocument.isDeletable()) {
                        delete version.ContentDocument;
                    }
                }
                ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'editWhatsappTemplate','exceptionObj' => null,'isApiException' => true,'statusCode' => res.getStatusCode(),'chatId' => null,'moreDetails' => 'HTTP callout failed with status: ' + res.getStatusCode(),'apiResponse' => res.getBody()});
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'createWhatsappTemplate', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            response.put('status', 'error');
            response.put('message', e.getMessage());
        }
       return response;
   }

   @AuraEnabled(cacheable=true)
   public static List<Flow__c> getAllFlows() {
       try {
           return [SELECT Id,Flow_Id__c, Flow_Name__c,Flow_JSON__c, LastModifiedDate,Status__c FROM Flow__c  where Status__c =: 'Published' ORDER BY CreatedDate DESC ];
       } catch (Exception e) {
        ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController', 'methodName' => 'getWhatsAppTemplates', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
           return new List<Flow__c>();
       }
   }

   @AuraEnabled
   public static String getPreviewURLofWhatsAppFlow(String flowId) {
       try {
           List<MVWB__WBConnect_Configuration__mdt> wbConfig = MVWB__WBConnect_Configuration__mdt.getAll().values(); 

           String accessToken = wbConfig[0].MVWB__Access_Token__c;
           String endpoint = SETTINGS[0].MVWB__API_Endpoint__c + '/' + SETTINGS[0].MVWB__API_Version__c + '/' + flowId + '?fields=preview.invalidate(false)';
           HttpRequest request = new HttpRequest();
           request.setEndpoint(endpoint);
           request.setMethod('GET');
           request.setHeader('Authorization', 'Bearer ' + accessToken);
           Http http = new Http();
           HttpResponse response = http.send(request);
           
           if (response.getStatusCode() == 200) {
               Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
               Map<String, Object> previewMap = (Map<String, Object>) responseMap.get('preview');
               String previewUrl = (String) previewMap.get('preview_url');
               return previewUrl;
           } else {
               return 'failed';
           }
       } catch (Exception e) {
           ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsAppFlowController', 'methodName' => 'getPreviewURLofWhatsAppFlow', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'Could not save the embedded sign up details in the metadata!', 'apiResponse' => null });
           return 'failed';
       }
   }

   /*
    *********************************************************
    @description     : Method to get objects with phone field.
    @return          : List<Map<String, String>> - return list of objects with phone field.
    ********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getObjectsWithPhoneField() {
        List<Map<String, String>> objectList = new List<Map<String, String>>();
        
        try {
            // Query FieldDefinition to fetch all objects having at least one Phone field
            List<FieldDefinition> phoneFields = [SELECT EntityDefinition.QualifiedApiName, EntityDefinition.Label FROM FieldDefinition WHERE DataType = 'Phone' AND EntityDefinition.IsCustomizable = true AND EntityDefinition.IsApexTriggerable = true AND EntityDefinition.IsQueryable = true WITH SECURITY_ENFORCED];
            
            Set<String> processedObjects = new Set<String>();
    
            for (FieldDefinition field : phoneFields) {
                String objectName = field.EntityDefinition.QualifiedApiName;
                if (!processedObjects.contains(objectName)) {
                    objectList.add(new Map<String, String>{
                        'label' => field.EntityDefinition.Label,
                        'value' => objectName
                    });
                    processedObjects.add(objectName);
                }
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WBTemplateController','methodName' => 'getObjectsWithPhoneField','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
    
        return objectList;
    }

    @AuraEnabled(cacheable=true)
    public static String getCompanyName() {
        return [SELECT Name FROM Organization LIMIT 1].Name;
    }

   public class FileChunkWrapper {
       @AuraEnabled public String uploadSessionId;
       @AuraEnabled public String fileContent;
       @AuraEnabled public Integer chunkStart;
       @AuraEnabled public Integer chunkSize;
       @AuraEnabled public String fileName;
       @AuraEnabled public Boolean isLastChunk;
   }
   public class TemplateDataWrapper {
       @AuraEnabled public Template__c template;
       // @AuraEnabled public Object queriedData;
       @AuraEnabled public List<String> objectNames;
       @AuraEnabled public List<String> fieldNames;
       @AuraEnabled public List<Map<String, String>> templateVariables; 
       @AuraEnabled public Boolean isImgUrl;
   }
   
}