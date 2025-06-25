/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 

 * @last modified on  : 12-23-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class WhatsAppConfigurationController {

    @AuraEnabled
    public static MVWB__WBConnect_Configuration__mdt getConfiguration(){

        MVWB__WBConnect_Configuration__mdt config = new MVWB__WBConnect_Configuration__mdt();
        try {
            List<MVWB__WBConnect_Configuration__mdt> Configlist = [SELECT Id, DeveloperName, MasterLabel, MVWB__Access_Token__c, MVWB__Application_Id__c, MVWB__Business_Account_Id__c, MVWB__Phone_Number_Id__c FROM MVWB__WBConnect_Configuration__mdt LIMIT 1];
            if(!Configlist.isEmpty()){
                config = Configlist[0];
            } else{
                config.MVWB__Access_Token__c = '';
                config.MVWB__Phone_Number_Id__c = '';
                config.MVWB__Application_Id__c = '';
                config.MVWB__Business_Account_Id__c = '';
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{ 'className' => 'WhatsAppConfigurationController', 'methodName' => 'getConfiguration', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null });
        }
        return config;
    }

    @AuraEnabled
    public static String saveConfiguration(String WBAccountId, String AppId ,String AccessToken, String PhoneNumberId) {

        try {
            
            String devName = 'WBConnect_Configuration';
            String masterLabel = 'WBConnect_Configuration';
            List<MVWB__WBConnect_Configuration__mdt> configList = [SELECT Id, DeveloperName, MasterLabel, MVWB__Access_Token__c, MVWB__Application_Id__c, MVWB__Business_Account_Id__c, MVWB__Phone_Number_Id__c FROM MVWB__WBConnect_Configuration__mdt LIMIT 1];
            MVWB__WBConnect_Configuration__mdt config = new MVWB__WBConnect_Configuration__mdt();
            if (!configList.isEmpty()) {
                config = configList[0];
                devName = config.DeveloperName;
                masterLabel = config.MasterLabel;
            }
            Metadata.CustomMetadata mdata = new Metadata.CustomMetadata();
            mdata.fullName = 'MVWB__WBConnect_Configuration__mdt.' + devName; 
            mdata.label = masterLabel;
            
            Metadata.CustomMetadataValue instance1 = new Metadata.CustomMetadataValue();
            instance1.field = 'MVWB__Access_Token__c';
            instance1.value = AccessToken;
            mdata.values.add(instance1);
            
            Metadata.CustomMetadataValue instance2 = new Metadata.CustomMetadataValue();
            instance2.field = 'MVWB__Phone_Number_Id__c';
            instance2.value = PhoneNumberId;
            mdata.values.add(instance2);
            
            Metadata.CustomMetadataValue instance3 = new Metadata.CustomMetadataValue();
            instance3.field = 'MVWB__Business_Account_Id__c';
            instance3.value = WBAccountId;
            mdata.values.add(instance3);
            
            Metadata.CustomMetadataValue instance4 = new Metadata.CustomMetadataValue();
            instance4.field = 'MVWB__Application_Id__c';
            instance4.value = AppId;
            mdata.values.add(instance4);

            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(mdata);
            
            Metadata.Operations.enqueueDeployment(container, null);

            return 'Success';
        }
        catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{ 'className' => 'WhatsAppConfigurationController', 'methodName' => 'saveConfiguration', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null });
            return 'Error';
        }
    }
}