global with sharing class PLMSController {
    
    @AuraEnabled
    global static void getPLMSValidity() {
        List<MVWB__LicenseConfig__c> configList = [SELECT Id, MVWB__Client_Id__c, MVWB__Client_Secret__c, MVWB__Is_License_Valid__c, MVWB__Expiration_Date__c, MVWB__Next_Callout_Date__c, MVWB__Password__c, MVWB__Username__c FROM MVWB__LicenseConfig__c LIMIT 1];
        MVWB__LicenseConfig__c config = new MVWB__LicenseConfig__c();
        if(configList != null && configList.size() > 0){
            config = configList[0];
        } else {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'getPLMSValidity', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => null, 'chatId' => null, 'moreDetails' => 'No License Config Found', 'apiResponse' => null});
            return;
        }
        try {
            // Define your Salesforce OAuth credentials
            String clientId = config.MVWB__Client_Id__c;  // Consumer Key from Connected App
            String clientSecret = config.MVWB__Client_Secret__c;  // Consumer Secret from Connected App
            String username = config.MVWB__Username__c;
            String password = config.MVWB__Password__c;
            String authEndpoint = 'https://login.salesforce.com/services/oauth2/token';
    
            // Step 1: Get Access Token
            HttpRequest req = new HttpRequest();
            req.setEndpoint(authEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(
                'grant_type=password' +
                '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
                '&username=' + EncodingUtil.urlEncode(username, 'UTF-8') +
                '&password=' + EncodingUtil.urlEncode(password, 'UTF-8')
            );
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200) {
                Map<String, Object> authResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) authResponse.get('access_token');
    
                String currentOrgId = UserInfo.getOrganizationId();
                System.debug(currentOrgId);
                String soql = 'SELECT Id, Org_Id__c, Expiration_DateTime__c ' +
                            'FROM Product_Subscriber__c ' +
                            'WHERE Product__r.Name = \'WBConnect\' ' +
                            'AND Org_Id__c = \'' + currentOrgId + '\'' +
                            'ORDER BY CreatedDate DESC ' +
                            ' LIMIT 1';
    
                HttpRequest productReq = new HttpRequest();
                productReq.setEndpoint('https://mvcloudsprivatelimited.my.salesforce.com/services/data/v60.0/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
                productReq.setMethod('GET');
                productReq.setHeader('Authorization', 'Bearer ' + accessToken);
    
                HttpResponse productRes = http.send(productReq);
    
                if (productRes.getStatusCode() == 200) {
                    // Parse the response JSON
                    Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(productRes.getBody());
                    List<Object> records = (List<Object>) jsonBody.get('records');
    
                    if (records!= null &&!records.isEmpty()) {
                        Map<String, Object> firstRecord = (Map<String, Object>) records[0];
                        String expirationStr = (String) firstRecord.get('Expiration_DateTime__c');
    
                        if(expirationStr != null && expirationStr != ''){
                            // Remove timezone offset (e.g., +0000)
                            if (expirationStr.contains('+')) {
                                expirationStr = expirationStr.substringBefore('+');
                            }

                            // Remove milliseconds and replace 'T' with space
                            expirationStr = expirationStr.replace('T', ' ');
                            if (expirationStr.contains('.')) {
                                expirationStr = expirationStr.substringBefore('.');
                            }

                            DateTime userExpirationDateTime = DateTime.valueOf(expirationStr);
                            config.Expiration_Date__c = userExpirationDateTime;

                            if(userExpirationDateTime < Date.today()){
                                config.MVWB__Is_License_Valid__c = false;
                            } else if(userExpirationDateTime.date() == Date.today()){
                                config.MVWB__Is_License_Valid__c = true;
                            } else {
                                config.MVWB__Is_License_Valid__c = true;
                                DateTime userNextCalloutTime = (userExpirationDateTime.date() <= Date.today().addMonths(1)) ? userExpirationDateTime : Date.today().addMonths(1);
                                config.MVWB__Next_Callout_Date__c = userNextCalloutTime;

                                String cronExpression = '0 ' + userNextCalloutTime.minute() + ' ' + userNextCalloutTime.hour() + ' ' + userNextCalloutTime.day() + ' ' + userNextCalloutTime.month() + ' ? ' + userNextCalloutTime.year();
                                String jobName = 'PLMS_Validity_Check_' + System.currentTimeMillis();
                                System.schedule(jobName, cronExpression, new PLMSValidityScheduler());
                            }

                            upsert config;
                        } else {
                            setNextSchedule();
                        }
                    } else {
                        ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'getPLMSValidity', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => productRes.getStatusCode(), 'chatId' => null, 'moreDetails' => 'Failed to fetch Expiration Date for Org Id ' + UserInfo.getOrganizationId(), 'apiResponse' => productRes.getBody()});
                        setNextSchedule();
                    }
                } else {
                    ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'getPLMSValidity', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => productRes.getStatusCode(), 'chatId' => null, 'moreDetails' => 'Failed to fetch Product_Subscriber__c record for Org Id ' + UserInfo.getOrganizationId(), 'apiResponse' => productRes.getBody()});
                    setNextSchedule();
                }
            } else {
                ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'getPLMSValidity', 'exceptionObj' => null, 'isApiException' => true, 'statusCode' => res.getStatusCode(), 'chatId' => null, 'moreDetails' => 'Unable to authorize to Production Org', 'apiResponse' => res.getBody()});
                setNextSchedule();
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'getPLMSValidity', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            setNextSchedule();
        }
    }

    @AuraEnabled
    public static Boolean checkLicenseUsablility(){
        try {
            List<MVWB__LicenseConfig__c> config = [SELECT Id, MVWB__Is_License_Valid__c, MVWB__Expiration_Date__c FROM MVWB__LicenseConfig__c LIMIT 1];
            if(config != null && config.size() > 0 && config[0].MVWB__Is_License_Valid__c && config[0].MVWB__Expiration_Date__c != null && config[0].MVWB__Expiration_Date__c > Date.today()){
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'checkLicenseUsablility', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
            return false;
        }
    }

    public static void setNextSchedule(){
        try {
            List<MVWB__LicenseConfig__c> configList = [SELECT Id, MVWB__Client_Id__c, MVWB__Client_Secret__c, MVWB__Is_License_Valid__c, MVWB__Expiration_Date__c, MVWB__Next_Callout_Date__c, MVWB__Password__c, MVWB__Username__c FROM MVWB__LicenseConfig__c LIMIT 1];
            MVWB__LicenseConfig__c config = new MVWB__LicenseConfig__c();
            if(configList != null && configList.size() > 0){
                config = configList[0];
                config.MVWB__Is_License_Valid__c = true;
                config.MVWB__Expiration_Date__c = Date.today().addDays(1);
                config.MVWB__Next_Callout_Date__c = Date.today().addDays(1);
                upsert config;

                DateTime userNextCalloutTime = Date.today().addDays(1);
                String cronExpression = '0 ' + userNextCalloutTime.minute() + ' ' + userNextCalloutTime.hour() + ' ' + userNextCalloutTime.day() + ' ' + userNextCalloutTime.month() + ' ? ' + userNextCalloutTime.year();
                String jobName = 'PLMS_Validity_Check_' + System.currentTimeMillis();
                System.schedule(jobName, cronExpression, new PLMSValidityScheduler());

                sendEmail(null, true);
            }
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'setNextSchedule', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
        }
    }

    public static void sendEmail(DateTime expirationDate, Boolean isException){
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> emails = new List<String>{'wbconnect-support@mvclouds.com'};
            String[] to = emails;
            String emailBody = isException ? '<div style="font-family:Verdana;">Hello WBConnect Team,<br/><br/>This is the PLMS Validity email, An exception encountered while fetching PLMS validity. Please find the details below:<br/><br/><b>Org Id:</b> ' + UserInfo.getOrganizationId() + '<br/><br/>Please verify the expiration date with records & Kindly follow up with the package installer.</div>' : '<div style="font-family:Verdana;">Hello WBConnect Team,<br/><br/>This is the PLMS Validity email for the package in one of the subscriber orgs has been expired. Please find the details below:<br/><br/><b>Org Id:</b> ' + UserInfo.getOrganizationId() + '<br/><b>Expiration Date:</b> ' + expirationDate + '<br/><br/>Please verify the expiration date with records.</div>';
            email.setToAddresses(to);
            email.setSubject(isException ? 'WBConnect Package PLMS Expiry' : 'WBConnect Package PLMS Validity exception email');
            email.setHtmlBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            ExceptionHandler.logException(new Map<String, Object>{'className' => 'PLMSController', 'methodName' => 'sendEmail', 'exceptionObj' => e, 'isApiException' => false, 'statusCode' => null, 'chatId' => null, 'moreDetails' => e.getMessage(), 'apiResponse' => null});
        }
    }
}