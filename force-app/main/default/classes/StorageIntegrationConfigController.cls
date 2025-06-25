/** 
* Class Name: getConfiguration 
* Test Class:
* @description: Used in storageIntegration LWC components
* Date: 19/03/2025
* Created By: Kavya Trivedi
*/
public without sharing class StorageIntegrationConfigController {

    /** 
    * Method Name : getConfiguration 
    * @description : get AWS Configuration
    * @return AWS_Config__c record
    * @throws SecurityException If the user does not have permission to access AWS_Config__c
    */
    @AuraEnabled
    public static AWS_Config__c getConfiguration() {
        if (!Schema.sObjectType.AWS_Config__c.isAccessible()) {
            throw new SecurityException('You do not have permission to access AWS configuration.');
        }

        AWS_Config__c config = new AWS_Config__c();
        try {
            List<AWS_Config__c> configList = [
                SELECT Id, AWS_Access_Key__c, AWS_Secret_Access_Key__c, 
                       S3_Bucket_Name__c, S3_Region_Name__c, 
                       CreatedDate, LastModifiedDate
                FROM AWS_Config__c LIMIT 1
            ];
            if (!configList.isEmpty()) {
                config = configList[0];
            } else {
                config.AWS_Access_Key__c = '';
                config.AWS_Secret_Access_Key__c = '';
                config.S3_Bucket_Name__c = '';
                config.S3_Region_Name__c = '';
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'StorageIntegrationConfigController','methodName' => 'getConfiguration','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
        return config;
    }

    /** 
    * Method Name : saveConfiguration 
    * @description : save AWS Configuration
    * @return success/error
    * @throws SecurityException If the user does not have permission to access AWS_Config__c
    */
    @AuraEnabled
    public static String saveConfiguration(String accessKey, String secretAccessKey, String bucketName, String regionName) {
        // if (!Schema.sObjectType.AWS_Config__c.isAccessible()) {
        //     throw new SecurityException('You do not have permission to access AWS configuration.');
        // }
        // if (!Schema.sObjectType.AWS_Config__c.isUpdateable() || !Schema.sObjectType.AWS_Config__c.isCreateable()) {
        //     throw new SecurityException('You do not have permission to modify AWS configuration.');
        // }

        try {
            List<AWS_Config__c> configList = [
                SELECT Id, AWS_Access_Key__c, AWS_Secret_Access_Key__c, 
                       S3_Bucket_Name__c, S3_Region_Name__c, 
                       CreatedDate, LastModifiedDate
                FROM AWS_Config__c LIMIT 1
            ];
            
            AWS_Config__c config;
            if (!configList.isEmpty()) {
                config = configList[0];
            } else {
                config = new AWS_Config__c();
            }

            config.AWS_Access_Key__c = accessKey;
            config.AWS_Secret_Access_Key__c = secretAccessKey;
            config.S3_Bucket_Name__c = bucketName;
            config.S3_Region_Name__c = regionName;

            if (Schema.sObjectType.AWS_Config__c.fields.AWS_Access_Key__c.isUpdateable() && Schema.sObjectType.AWS_Config__c.fields.AWS_Access_Key__c.isAccessible() && Schema.sObjectType.AWS_Config__c.fields.AWS_Secret_Access_Key__c.isUpdateable() && Schema.sObjectType.AWS_Config__c.fields.AWS_Secret_Access_Key__c.isAccessible() && Schema.sObjectType.AWS_Config__c.fields.S3_Bucket_Name__c.isUpdateable() && Schema.sObjectType.AWS_Config__c.fields.S3_Bucket_Name__c.isAccessible() && Schema.sObjectType.AWS_Config__c.fields.S3_Region_Name__c.isUpdateable() && Schema.sObjectType.AWS_Config__c.fields.S3_Region_Name__c.isAccessible()){
                upsert config;
            }

            return 'Success';
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'StorageIntegrationConfigController','methodName' => 'saveConfiguration','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
            return 'Error';
        }
    }

    /** 
    * Method Name : deleteRecordByAccessKey 
    * @description : delete AWS Configuration
    * @throws SecurityException If the user does not have permission to access AWS_Config__c
    * @throws IllegalArgumentException If record is not found
    */
    @AuraEnabled
    public static void deleteRecordByAccessKey(String accessKey) {
        if (!Schema.sObjectType.AWS_Config__c.isDeletable()) {
            throw new SecurityException('You do not have permission to delete records.');
        }
        if (!Schema.sObjectType.AWS_Config__c.fields.AWS_Access_Key__c.isAccessible()) {
            throw new SecurityException('You do not have permission to access this field.');
        }
        
        try {
            List<AWS_Config__c> records = [
                SELECT Id FROM AWS_Config__c 
                WHERE AWS_Access_Key__c = :accessKey
                LIMIT 1
            ];

            if (!records.isEmpty()) {
                delete records[0];
            } else {
                throw new IllegalArgumentException('Record not found');
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'StorageIntegrationConfigController','methodName' => 'deleteRecordByAccessKey','exceptionObj' => e,'isApiException' => false,'statusCode' => null,'chatId' => null,'moreDetails' => e.getMessage(),'apiResponse' => null});
        }
    }    
}