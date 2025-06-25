/**
 * Class Name: CreateTemplateWrapper
 * Test Class: 
 * @description: Used in WBTemplateController Apex Class to create request body for template creation.
 * Date: 26/11/2024
 * Created By: Kajal Tiwari
 */
 /***********************************************************************
 MODIFICATION LOG*
 * Last Update Date : 12/12/2024
 * Updated By : Kajal Tiwari
 * Name of methods changed (Comma separated if more then one) : handleSuccessResponse
 * Change Description : Store actual variable {{1}} in the name field of template variable.
 ***********************************************************************/

 public without sharing class CreateTemplateWrapper {
    /*
    *********************************************************
    @description     : Main method to build overall payload to pass in create template
    @param           : templateWrapper - {TemplateWrapper} - It is wrapper class that pass from WBTemplateController contain all data need to create template.
    @return          : payload - {Map<String, Object>} - Complete body to create template.
    ********************************************************
    */
    // public static Map<String, Object> buildPayload(TemplateWrapper templateWrapper) {
    //     try {
    //         Map<String, Object> payload = new Map<String, Object>();
    //         payload.put('name', templateWrapper.templateName);
    //         payload.put('language', templateWrapper.tempLanguage);
    //         payload.put('category', templateWrapper.templateCategory);

    //         List<Map<String, Object>> components = new List<Map<String, Object>>();
    //         components.addAll(buildMarketingOrUtilityComponents(templateWrapper));

    //         if (!components.isEmpty()) {
    //             payload.put('components', components);
    //         }
    //         if(templateWrapper.templateCategory == 'Authentication' || templateWrapper.templateCategory == 'Utility'){
    //             if (templateWrapper.expireTime != null) {
    //                 payload.put('message_send_ttl_seconds', templateWrapper.expireTime);
    //             } else {
    //                 payload.put('message_send_ttl_seconds', 300); // Default to 5 mins if not set
    //             }
    //         }
    //         return payload;

    //     } catch (Exception e) {
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'buildPayload', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
    //     }
    //     return new Map<String, Object>(); 
    // }

     /*
    **********************************************************
    @description     : Method to create component for template catagory of type marketing or utility.
    @param           : templateWrapper - {TemplateWrapper} - It is wrapper class that pass from WBTemplateController contain all data need to create template.
    @return          : components - {Map<String, Object>} - Return component use to create payload.
    ********************************************************
    */
    // private static List<Map<String, Object>> buildMarketingOrUtilityComponents(TemplateWrapper templateWrapper) {
    //     try {
    //         List<Map<String, Object>> components = new List<Map<String, Object>>();
    //         Map<String, Object> headerComponent = buildHeaderComponent(templateWrapper);
    //         if (!headerComponent.isEmpty()) {
    //             components.add(headerComponent);
    //         }
    
    //         if ((templateWrapper.templateBody != null ) ) {
                
    //             components.add(buildBodyComponent(templateWrapper));
    //         }
    
    //         if (templateWrapper.tempFooterText != null) {
    //             components.add(new Map<String, Object>{
    //                 'type' => 'FOOTER',
    //                 'text' => templateWrapper.tempFooterText
    //             });
    //         }  else if (templateWrapper.templateCategory == 'Authentication' && templateWrapper.isCodeExpiration){
    //             System.debug('templateWrapper.expireTime ::: '+templateWrapper.expireTime);
    //             Integer expirationMinutes = (Integer)Math.floor(templateWrapper.expireTime / 60);
    //             components.add(new Map<String, Object>{
    //                 'type' => 'FOOTER',
    //                 'code_expiration_minutes' => expirationMinutes
    //             });
    //         }
    
    //         List<Map<String, Object>> buttonComponents = buildButtonComponent(templateWrapper);
    //         if (!buttonComponents.isEmpty()) {
    //             components.add(new Map<String, Object>{
    //                 'type' => 'BUTTONS',
    //                 'buttons' => buttonComponents
    //             });
    //         }
    //         return components;

    //     } catch (Exception e) {
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'buildMarketingOrUtilityComponents', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
    //     }
    //     return new List<Map<String, Object>>(); 
    // }

     /*
    *********************************************************
    @description     : Method to create header for template component.
    @param           : templateWrapper - {TemplateWrapper} - It is wrapper class that pass from WBTemplateController contain all data need to create template.
    @return          : headerComponent - {Map<String, Object>} - Return header component use to create header.
    ********************************************************
    */
    // private static Map<String, Object> buildHeaderComponent(TemplateWrapper templateWrapper) {
    //     Map<String, Object> headerComponent = new Map<String, Object>();
        
    //     try {
    //         if (templateWrapper.tempHeaderFormat == null || templateWrapper.tempHeaderFormat=='None' ) {
    //             return headerComponent;
    //         }  
    //         headerComponent.put('type', 'HEADER'); 
    //         headerComponent.put('format', templateWrapper.tempHeaderFormat);
                      
    //         if (templateWrapper.tempHeaderFormat == 'Text' && templateWrapper.tempHeaderText != null) {
    //             headerComponent.put('text', templateWrapper.tempHeaderText);
                
    //             if (templateWrapper.tempHeaderExample != null && !templateWrapper.tempHeaderExample.isEmpty()) {
    //                 headerComponent.put('example', new Map<String, Object>{
    //                     'header_text' => templateWrapper.tempHeaderExample
    //                 });
    //             }
    //             return headerComponent;
    //         }            
    //         if (((templateWrapper.tempHeaderFormat == 'Image')||(templateWrapper.tempHeaderFormat == 'Video')||((templateWrapper.tempHeaderFormat == 'Document'))) && templateWrapper.tempHeaderHandle != null) {
    //             headerComponent.put('example', new Map<String, Object>{
    //                 'header_handle' => templateWrapper.tempHeaderHandle
    //             });
    //             return headerComponent;
    //         }
    //     } catch (Exception e) {
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'buildHeaderComponent', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
    //     }
    //     return headerComponent;
    // }
    
      /*
    *********************************************************
    @description     : Method to create body for template component.
    @param           : templateWrapper - {TemplateWrapper} - It is wrapper class that pass from WBTemplateController contain all data need to create template.
    @return          : bodyComponent - {Map<String, Object>} - Return body component use to create body.
    ********************************************************
    */
    // private static Map<String, Object> buildBodyComponent(TemplateWrapper templateWrapper) {
    //     try {

    //         Map<String, Object> bodyComponent;
    //         if (templateWrapper.templateCategory == 'Authentication') {
    //             bodyComponent = new Map<String, Object>{
    //                 'type' => 'BODY',
    //                 'add_security_recommendation' => templateWrapper.isSecurityRecommedation
    //             };
    //         } else {
    //             bodyComponent = new Map<String, Object>{
    //                 'type' => 'BODY',
    //                 'text' => templateWrapper.templateBody.replace('\\n', '\n')
    //             };
    //         }
    
    //         if ((templateWrapper.templateBodyText != null) && (templateWrapper.templateBodyText.size() > 0)) {
                
    //             bodyComponent.put('example', new Map<String, Object>{
    //                 'body_text' => new List<List<String>>{templateWrapper.templateBodyText}
    //             });
    //         }
            
    //         return bodyComponent;
    //     } catch (Exception e) {
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'buildBodyComponent', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
    //     }
    //     return new Map<String, Object>(); 
    // }

       /*
    *********************************************************
    @description     : Method to build buttons of different type for template component.
    @param           : templateWrapper - {TemplateWrapper} - It is wrapper class that pass from WBTemplateController contain all data need to create template.
    @return          : buttonComponents - {Map<String, Object>} - Return buttons use to create payload.
    ********************************************************
    */
    // private static List<Map<String, Object>> buildButtonComponent(TemplateWrapper templateWrapper) {
    //     List<Map<String, Object>> buttonComponents = new List<Map<String, Object>>();
    
    //     try {
    //         // Force OTP button for Authentication category
    //         if (templateWrapper.templateCategory == 'Authentication') {
    //             Map<String, Object> buttonComponent = new Map<String, Object>{
    //                 'type' => 'OTP',
    //                 'text' => 'Verify Code', // Plain text without variables or emojis
    //                 'otp_type' => 'COPY_CODE' // Use 'COPY_CODE' or 'ONE_TAP' as needed
    //             };
    //             buttonComponents.add(buttonComponent);
    //             return buttonComponents; // Return immediately to prevent adding other buttons
    //         }
    
    //         // Handle other categories
    //         if (String.isBlank(templateWrapper.typeOfButton)) {
    //             return buttonComponents;
    //         }
    
    //         List<Object> untypedList;
    //         try {
    //             untypedList = (List<Object>) JSON.deserializeUntyped(templateWrapper.typeOfButton);
    //         } catch (Exception e) {
                
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper','methodName' => 'handleSuccessResponse','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
    //             throw new IllegalArgumentException('Invalid JSON format for typeOfButton: ' + e.getMessage());
    //         }
    //         // Loop through buttons for non-Authentication categories
    //         for (Object item : untypedList) {
    //             // if (buttonComponents.size() >= 1) {
    //             //     break; // Limit to 1 button if required
    //             // }
                
                
    //             Map<String, Object> button = (Map<String, Object>) item;
    //             String actionType = (String) button.get('selectedActionType');
    //             String customActionType = (String) button.get('selectedCustomType');
    //             String phoneNumber = (String) button.get('selectedCountryType') + ' ' + (String) button.get('phonenum');
    //             Map<String, Object> buttonComponent = new Map<String, Object>();
    //             if ('PHONE_NUMBER'.equals(actionType)) {
    //                 buttonComponent.put('type', 'PHONE_NUMBER');
    //                 buttonComponent.put('text', (String) button.get('btntext'));
    //                 buttonComponent.put('phone_number', phoneNumber);
    //             } else if ('QUICK_REPLY'.equals(customActionType) || 'Marketing opt-out'.equals(customActionType)) {
    //                 buttonComponent.put('type', 'QUICK_REPLY');
    //                 buttonComponent.put('text', (String) button.get('Cbtntext'));
    //                 if('Marketing opt-out'.equals(customActionType)){
    //                     templateWrapper.marketingOptText = (String) button.get('Cbtntext');
    //                 }
    //             } else if ('URL'.equals(actionType)) {
    //                 buttonComponent.put('type', 'URL');
    //                 buttonComponent.put('text', (String) button.get('btntext'));
    //                 buttonComponent.put('url', (String) button.get('webURL'));
    //             } else if ('COPY_CODE'.equals(actionType)) {
    //                 buttonComponent.put('type', 'COPY_CODE');
    //                 buttonComponent.put('text', 'Copy offer code');
    //                 buttonComponent.put('example', (String) button.get('offercode'));
    //             }
    //             else if ('Flow'.equals(actionType)) {
    //                 Map<String,Object> selectedFlowMap= new Map<String,Object>();
    //                 selectedFlowMap = (Map<String,Object>) JSON.deserializeUntyped(templateWrapper.selectedFlow);
    //                 buttonComponent.put('type', 'FLOW');
    //                 buttonComponent.put('text', (String) button.get('btntext'));
    //                 buttonComponent.put('flow_id', (String) selectedFlowMap.get('id'));
    //             }
    //             if (!buttonComponent.isEmpty()) {
    //                 buttonComponents.add(buttonComponent);
    //             }
    //         }
    
    //     } catch (Exception e) {
    //         ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper','methodName' => 'buildButtonComponent','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
    //     }
    
    //     return buttonComponents;
    // }
    
    
    /*
    *********************************************************
    @description     : Handle response and store all in the template and template variable record.
    @param           : res,payload,response,templateWrapper - {HttpResponse,Map<String, Object>,Map<String, Object>,TemplateWrapper} 
    @return          : templateId of created template records.
    ********************************************************
    */

    public static Id handleSuccessResponse(String metaTempId, String metaTemplateStatus, Map<String, Object> payload, TemplateWrapper templateWrapper) {
        Map<String, Object> response = new Map<String, Object>();
        Id templateId = null;
        try {
            // Deserialize the payload
            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload));
            
            // List<Map<String, String>> buttonDetails;
            String buttonDetails;
            String templatename = (String) payloadMap.get('name');
            Template__c whatsAppTemplate;


            List<Template__c> allTemplates = [
                SELECT Id, Name, Template_Name__c, Template_Id__c 
                FROM Template__c
                WITH SECURITY_ENFORCED
            ];
            List<Template__c> whatsAppTemplateList = new List<Template__c>();
            for (Template__c template : allTemplates) {
                if (template.Template_Name__c == (String) payloadMap.get('name')) {
                    whatsAppTemplateList.add(template);
                }
            }


            if (whatsAppTemplateList.isEmpty()) {
                whatsAppTemplate = new Template__c();
            } else {
                whatsAppTemplate = whatsAppTemplateList[0];
                if (whatsAppTemplate.Template_Id__c != null) {
                    whatsAppTemplate.Template_Id__c = metaTempId != null ? metaTempId : whatsAppTemplate.Template_Id__c;
                }
            }
            
            // Populate Template__c fields dynamically
            String status = metaTemplateStatus;
            whatsAppTemplate.Template_Id__c = metaTempId != null ? metaTempId : whatsAppTemplate.Template_Id__c;
            whatsAppTemplate.Status__c = (status == null || status == '') ? 'In-Review' : (status == 'PENDING') ? 'In-Review' : 
                                         (status == 'REJECTED') ? 'Rejected' : 
                                         (status == 'APPROVED') ? 'Active-Quality Pending' : '';
            whatsAppTemplate.Template_Name__c = (String) payloadMap.get('name');
            whatsAppTemplate.Template_Category__c = (String) payloadMap.get('category');
            whatsAppTemplate.Language__c = (String) payloadMap.get('language');
            whatsAppTemplate.Template_Type__c = templateWrapper.templateType;
            whatsAppTemplate.Template_Miscellaneous_Data__c = templateWrapper.templateMiscellaneousData;

            // Initialize variables for components
            List<Template_Variable__c> variableRecords = new List<Template_Variable__c>();
            List<Object> components = (List<Object>) payloadMap.get('components');
            List<String> headAlternateTexts = templateWrapper.headAlternateTexts; 
            List<String> varAlternateTexts = templateWrapper.varAlternateTexts;   

            Integer headerIndex = 0;
            Integer variableIndex = 0; 
            String headerMergeText = '';
    
            // Process components
            for (Object comp : components) {
                if (!(comp instanceof Map<String, Object>)) {
                    continue;
                }
                Map<String, Object> component = (Map<String, Object>) comp;
                String type = (String) component.get('type');
                Map<String, Object> example = (Map<String, Object>) component.get('example');

            

                if(whatsAppTemplate.Template_Category__c == 'Authentication'){
                    component.put('text',templateWrapper.templateBody);
                }

    
                // HEADER Component
                if (type == 'HEADER') {
                    whatsAppTemplate.Header_Type__c = (String) component.get('format');
                    if (((String) component.get('format') == 'IMAGE')||(((String) component.get('format') == 'VIDEO'))||(((String) component.get('format') == 'DOCUMENT'))) {
                        whatsAppTemplate.WBHeader_Body__c = templateWrapper.tempImgUrl;
                        whatsAppTemplate.File_Name__c = templateWrapper.tempImgName;
                        whatsAppTemplate.WBImage_Header_Handle__c = templateWrapper.tempHeaderHandle;
                    } else {
                        whatsAppTemplate.WBHeader_Body__c = (String) component.get('text');
                        
                    }
                    if (example != null && example.containsKey('header_text') && example.get('header_text') instanceof List<Object>) {
                        List<Object> headerExampleObj = (List<Object>) example.get('header_text');
                        Pattern pattern = Pattern.compile('\\{\\{(\\d+)\\}\\}');
                        Matcher matcher = pattern.matcher((String) component.get('text'));

                        if (!headerExampleObj.isEmpty()) {
                            while (matcher.find()) {
                                String placeholder = matcher.group();  
                                headerMergeText = (String) headerExampleObj[0];
                                headerMergeText = headerMergeText.replace('{{', '').replace('}}', '');
                                List<String> parts = headerMergeText.split('\\.');
                                if (parts.size() == 2) {
                                    List<Template_Variable__c> existingHeaderVar = [
                                        SELECT Id, Name
                                        FROM Template_Variable__c
                                        WHERE Template__c = :whatsAppTemplate.Id
                                        AND Type__c = 'Header'
                                    ];
                
                                    if (!existingHeaderVar.isEmpty()) {
                                        delete existingHeaderVar;
                                    }

                                    if (headerIndex < headAlternateTexts.size()) {
                                        Template_Variable__c headerVariable = new Template_Variable__c(
                                            Name = placeholder,
                                            Object_Name__c = parts[0],
                                            Field_Name__c = parts[1],
                                            Type__c = 'Header',
                                            Alternate_Text__c = headAlternateTexts[headerIndex]
                                        );
                                        variableRecords.add(headerVariable);
                                        headerIndex++;
                                    }                           
                                   
                                    headerIndex++;
                                }
                            }
                        }
                    }
                }
                // BODY Component
                else if (type == 'BODY') {
                    Map<String, Object> result = handleBodyComponent(whatsAppTemplate.Template_Category__c, component, example);
                    
                    if(((String) result.get('bodyText')) != null){
                        whatsAppTemplate.WBTemplate_Body__c = String.isNotBlank((String) result.get('bodyText')) ? (String) result.get('bodyText') : '';

                        if(whatsAppTemplate.Template_Category__c != 'Authentication'){
                            List<Map<String, String>> parsedFields = (List<Map<String, String>>) result.get('parsedFields');
                            String bodyMergeText = (String) result.get('bodyMergeText');
        
                            Pattern pattern = Pattern.compile('\\{\\{(\\d+)\\}\\}');
                            Matcher matcher = pattern.matcher((String) result.get('bodyText'));
                            Set<String> processedBodyPlaceholders = new Set<String>();
        
                            List<Template_Variable__c> existingBodyVars = [
                                SELECT Id, Name
                                FROM Template_Variable__c
                                WHERE Template__c = :whatsAppTemplate.Id
                                AND Type__c = 'Body'
                            ];
        
                            if (!existingBodyVars.isEmpty()) {
                                delete existingBodyVars;
                            }
        
                            while (matcher.find()) {
                                String placeholder = matcher.group();
        
                                if (!processedBodyPlaceholders.contains(placeholder)) {
                                    processedBodyPlaceholders.add(placeholder);
                            
                                    if ((variableIndex < varAlternateTexts.size())) {
                                        Template_Variable__c bodyVariable ;
                                        bodyVariable = new Template_Variable__c(
                                            Name = placeholder,
                                            Object_Name__c = parsedFields[variableIndex].get('objectName'),
                                            Field_Name__c = parsedFields[variableIndex].get('fieldName'), 
                                            Type__c = 'Body',
                                            Alternate_Text__c = varAlternateTexts[variableIndex]
                                        );
                                        variableRecords.add(bodyVariable);
                                    }
                                    variableIndex++; 
                                }
                            }
                        }
                    }
                }
                // FOOTER Component
                else if (type == 'FOOTER') {
                    whatsAppTemplate.WBFooter_Body__c = (String) component.get('text');
                }
                // BUTTONS Component
                else if (type == 'BUTTONS') {
                    List<Object> buttons = (List<Object>) component.get('buttons');
                    for (Object buttonObj : buttons) {
                        if (buttonObj instanceof Map<String, Object>) {
                            Map<String, Object> button = (Map<String, Object>) buttonObj;
                            String buttonType = (String) button.get('type');
                            String buttonText = (String) button.get('text');
        
                            // ✅ Correct check for marketing opt-out
                            if (buttonText == templateWrapper.marketingOptText) {
                                button.put('isMarketingOpt', true);
                            }
                        }
                    }
                    buttonDetails = handleButtonComponent(component);
                    whatsAppTemplate.WBButton_Body__c = buttonDetails;
                    
                }
            }
    
            upsert whatsAppTemplate;
            templateId = whatsAppTemplate.Id;

            for (Template_Variable__c variable : variableRecords) {
                variable.Template__c = whatsAppTemplate.Id;
            }

            if (!variableRecords.isEmpty()) {
                upsert variableRecords;
            }

            // Success response
            response.put('success', true);
            response.put('templateId', templateId);
    
        } catch (Exception e) {
            // Error response handling
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper','methodName' => 'handleSuccessResponse','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
        return templateId; 
    }
    
     /*
    *********************************************************
    @description     : Handle body to get the alternate text.
    @param           : category,component,example - {String,Map<String, Object>,Map<String, Object>} 
    @return          : result - contain the body text, parsefields use to create Template_Variable record.
    ********************************************************
    */
    private static Map<String, Object> handleBodyComponent(String category, Map<String, Object> component, Map<String, Object> example) {
        Map<String, Object> result = new Map<String, Object>(); 
        try {
            String bodyText = (String) component.get('text');
            String bodyMergeText = '';  
            List<Map<String, String>> parsedFields = new List<Map<String, String>>(); 
    
            if (example != null && example.containsKey('body_text')) {
                Object bodyTextObj = example.get('body_text');
    
                if (bodyTextObj instanceof List<Object>) {
                    List<Object> outerList = (List<Object>) bodyTextObj;
    
                    if (!outerList.isEmpty() && outerList[0] instanceof List<Object>) {
                        List<Object> innerList = (List<Object>) outerList[0];
                        List<String> stringList = new List<String>();
    
                        for (Object obj : innerList) {
                            if (obj instanceof String) {
                                String fieldRef = (String) obj;
                                stringList.add(fieldRef);
    
                                if (fieldRef.contains('.')) {
                                    fieldRef = fieldRef.replace('{{', '').replace('}}', '');
                                    List<String> parts = fieldRef.split('\\.');
                                    Map<String, String> fieldMap = new Map<String, String>();
                                    fieldMap.put('objectName',parts[0]);
                                    fieldMap.put('fieldName', parts[1]); 
                                    parsedFields.add(fieldMap);
                                }
                            }
                        }
    
                        if (!stringList.isEmpty()) {
                            bodyMergeText = String.join(stringList, ',');
                        }
                    }
                }
            }
    
            result.put('bodyText', bodyText);
            result.put('bodyMergeText', bodyMergeText);
            result.put('parsedFields', parsedFields); 
    
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'handleBodyComponent', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            result.put('bodyText', '');  
            result.put('bodyMergeText', '');
            result.put('parsedFields', new List<Map<String, String>>()); 
        }
    
        return result; 
    }

      /*
    *********************************************************
    @description     : Handle buttons for different type of buttons.
    @param           : component - {Map<String, Object> 
    @return          : buttonDetails - contain type ,label and value of different buttons.
    ********************************************************
    */
    private static String handleButtonComponent(Map<String, Object> component) {
        String buttonList = '';
        try {
            List<Object> buttons = (List<Object>) component.get('buttons');
    
            if (buttons != null) {
                buttonList = (String) JSON.serialize(buttons);
                
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'CreateTemplateWrapper', 'methodName' => 'handleButtonComponent', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
        }
        return buttonList; 
    }
    
      /*
    *********************************************************
    @description     : Used to format text
    @param           : bodyText - text that need to format.
    @return          : bodyText (String) - formatted bodytext.
    ********************************************************
    */
    

    public class TemplateWrapper {      
        @AuraEnabled public String templateName;
        @AuraEnabled public String templateCategory;
        @AuraEnabled public String templateType;
        @AuraEnabled public String tempHeaderFormat;
        @AuraEnabled public String tempHeaderHandle;
        @AuraEnabled public String tempLanguage;
        @AuraEnabled public String tempHeaderText;
        @AuraEnabled public List<String> tempHeaderExample;
        @AuraEnabled public List<String> headAlternateTexts;
        @AuraEnabled public List<String> varAlternateTexts;
        @AuraEnabled public String templateBody;
        @AuraEnabled public List<String> templateBodyText;
        @AuraEnabled public String tempFooterText;
        @AuraEnabled public String typeOfButton;
        @AuraEnabled public String url;
        @AuraEnabled public String tempImgUrl;
        @AuraEnabled public String tempImgName;
        @AuraEnabled public String tempImgId;
        @AuraEnabled public Integer expireTime;
        
        @AuraEnabled public Boolean autofillCheck;  
        @AuraEnabled public List<String> packagename;  
        @AuraEnabled public List<String> signaturename;  
        @AuraEnabled public String marketingOptText;  
        @AuraEnabled public String templateMiscellaneousData;
        
        @AuraEnabled public String selectedFlow;
        @AuraEnabled public Boolean isSecurityRecommedation;
        @AuraEnabled public Boolean isCodeExpiration;
        
    }

}