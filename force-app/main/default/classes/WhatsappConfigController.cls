public class WhatsappConfigController {

    public static String whatsappBusinessAppId {get; set;}
    public static String clientId {get; set;}
    public static String configurationId {get; set;}
    public static String clientSecret {get; set;}

    // Constructor to load the metadata record
    public WhatsappConfigController() {
        // Fetch the metadata record
        List<MVWB__WBConnect_Configuration__mdt  > metaList = [SELECT MasterLabel, MVWB__Business_Account_Id__c FROM MVWB__WBConnect_Configuration__mdt WITH SECURITY_ENFORCED];
        if(metaList.size() > 0){
            whatsappBusinessAppId = metaList[0].MVWB__Business_Account_Id__c;
        }else {
            whatsappBusinessAppId = '';
        }

        List<EmbeddedSignUpConfig__c> embeddedConfig = [SELECT Id, Config_Id__c, Client_Secret__c, Client_Id__c FROM EmbeddedSignUpConfig__c WITH SECURITY_ENFORCED];
        if(embeddedConfig.size() > 0){
            clientId = embeddedConfig[0].Client_Id__c;
            clientSecret = embeddedConfig[0].Client_Secret__c;
            configurationId = embeddedConfig[0].Config_Id__c;
        }

    }

    @RemoteAction
    public static String saveFBLoginDetails(String sAccessToken, String phoneId, String wabaId, String appId){
        try{

            List<EmbeddedSignUpConfig__c> embeddedConfig = [SELECT Id, Config_Id__c, Client_Secret__c, Client_Id__c FROM EmbeddedSignUpConfig__c WITH SECURITY_ENFORCED];
            if(embeddedConfig.size() < 1){
                ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsappConfigController', 'methodName' => 'saveFBLoginDetails', 'exceptionObj' => null, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'No Embedded Sign Up Configuration Found!', 'apiResponse' => null });
                return 'Failure';
            }
            
            String tokenUrl = 'https://graph.facebook.com/v21.0/oauth/access_token?grant_type=fb_exchange_token&client_id=' + embeddedConfig[0].Client_Id__c + '&client_secret=' + embeddedConfig[0].Client_Secret__c + '&fb_exchange_token='+sAccessToken;
            HttpRequest req = new HttpRequest();
            req.setEndpoint(tokenUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseBody1 = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) responseBody1.get('access_token');
                Boolean isSuccess = saveMetaData(accessToken, phoneId, wabaId, appId);
                if(isSuccess){
                    return wabaId;
                }
            }
        }catch(Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsappConfigController', 'methodName' => 'saveFBLoginDetails', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'Could not save the embedded sign up details!', 'apiResponse' => null });
        }
        return null;
        
    }

    @RemoteAction
    public static Boolean unlinkAccount(){
        try{
            Boolean isSuccess = saveMetaData('', '', '', '');
            if(isSuccess){
                return true;
            }
        }catch(Exception e){
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsappConfigController', 'methodName' => 'unlinkAccount', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'Could not clear the configuration values!', 'apiResponse' => null });
        }
        return false;
    }
    
    
    public static Boolean saveMetaData(String accessToken, String phoneId, String wabaId, String appId){

        try {
            List<MVWB__WBConnect_Configuration__mdt  > metaList = [SELECT MasterLabel, DeveloperName FROM MVWB__WBConnect_Configuration__mdt WITH SECURITY_ENFORCED];

            Metadata.CustomMetadata mdata = new Metadata.CustomMetadata();
            if(metaList.size() > 0){
                mdata.fullName = 'MVWB__WBConnect_Configuration__mdt.' + metaList[0].DeveloperName; 
                mdata.label = metaList[0].MasterLabel;
            }else{
                mdata.fullName = 'MVWB__WBConnect_Configuration__mdt.WBConnect_Configuration'; 
                mdata.label = 'WB_Connect_Config_Details';
            }

            Metadata.CustomMetadataValue instance1 = new Metadata.CustomMetadataValue();
            instance1.field = 'MVWB__Business_Account_Id__c';
            instance1.value = wabaId;
            mdata.values.add(instance1);

            Metadata.CustomMetadataValue instance2 = new Metadata.CustomMetadataValue();
            instance2.field = 'MVWB__Phone_Number_Id__c';
            instance2.value = phoneId;
            mdata.values.add(instance2);

            Metadata.CustomMetadataValue instance3 = new Metadata.CustomMetadataValue();
            instance3.field = 'MVWB__Access_Token__c';
            instance3.value = accessToken;
            mdata.values.add(instance3);

            Metadata.CustomMetadataValue instance4 = new Metadata.CustomMetadataValue();
            instance4.field = 'MVWB__Application_Id__c';
            instance4.value = appId;
            mdata.values.add(instance4);

            Metadata.CustomMetadataValue instance5 = new Metadata.CustomMetadataValue();
            instance5.field = 'MVWB__API_Endpoint__c';
            instance5.value = 'https://graph.facebook.com';
            mdata.values.add(instance5);

            Metadata.CustomMetadataValue instance6 = new Metadata.CustomMetadataValue();
            instance6.field = 'MVWB__API_Version__c';
            instance6.value = 'v22.0';
            mdata.values.add(instance6);

            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(mdata);

            Metadata.Operations.enqueueDeployment(container, null);

            return true;
            
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsappConfigController', 'methodName' => 'saveMetaData', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'Could not save the embedded sign up details in the metadata!', 'apiResponse' => null });
            return null;
        }

    }

    @RemoteAction
    public static Boolean checkLicenseUsablility(){
        try {
            MVWB__LicenseConfig__c config = MVWB__LicenseConfig__c.getInstance();
            if(config != null && config.MVWB__Is_License_Valid__c && config.MVWB__Expiration_Date__c != null && config.MVWB__Expiration_Date__c > Date.today()){
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'WhatsappConfigController', 'methodName' => 'checkLicenseUsablility', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            return false;
        }
    }
}