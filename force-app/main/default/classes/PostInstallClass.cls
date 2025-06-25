/**
 * Class Name: PostInstallClass
 * Test Class: PostInstallClassTest
 * @description: Used to send the email to the 'wbconnect-support@mvclouds.com' to keep record of the organization which installed package 
 * Created Date: 18 Dec, 2024
 * Created By: Kevin Suvagiya
 *--------------------------------------------------------------------------------
 * Last Modified By: Kevin Suvagiya
 * Last Modified Date: 23 Dec, 2024
 * Last Modification Description: updated the static emails with the custom label
 *--------------------------------------------------------------------------------
 * Modification History:
 * Date Modified - Developer Name - Description
 * 18 Dec, 2024  - Kevin Suvagiya - Created a method to send an email with organization and user info
 **/
global class PostInstallClass implements InstallHandler {

    /*
    *********************************************************
    @description     : Method is used to send the email with organization and user info
    @param           : context - {InstallContext} - Context of the installation, can be used for versioning but not used for now
    @return          : none
    ********************************************************
    */
    global void onInstall(InstallContext context) {
        try {
            List<Profile> systemAdminProfile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];

            if(context.previousVersion() == null || Test.isRunningTest()) {
                String orgDataTable = '';
                String userDataTable = '';
                Map<String, Object> mapOfData = new Map<String, Object>();
                String orgId = context.organizationId();
                String orgDomain = URL.getOrgDomainURL().toExternalForm();
                List<Organization> orgs = [SELECT Id, Name, OrganizationType, IsSandbox FROM Organization WHERE Id =: orgId];    
                if (orgs!=null && orgs.size() > 0) {
                    Organization org = orgs[0];
                    String environment = Boolean.valueOf(org.IsSandbox) ? 'Sandbox' : 'Production';
                    mapOfData.put('Org_Id__c',org.Id);
                    mapOfData.put('Org_Name__c',org.Name);
                    mapOfData.put('Org_Type__c',org.OrganizationType);
                    mapOfData.put('Environment__c', environment);
                    mapOfData.put('Domain__c', orgDomain);
                    mapOfData.put('Expiration_DateTime__c', Date.today().addMonths(1));
                    mapOfData.put('Installed_Product__c', 'WBConnect');
                    orgDataTable = '<table border="1" style="border-collapse: collapse;text-align:left; color: black;" cellpadding="4px">' +
                                    '<tr style="text-align:center;">' +
                                        '<th colspan="2" style="font-size: 18px; color: white; background-color:#165668;">Organization Details</th>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Organization Id</th>' +
                                        '<td>' + org.Id + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Organization Name</th>' +
                                        '<td>' + org.Name + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Organization Type</th>' +
                                        '<td>' + org.OrganizationType + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Environment</th>' +
                                        '<td>' + environment + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Domain</th>' +
                                        '<td>' + orgDomain + '</td>' +
                                    '</tr>' +
                                    '</table>';
                }
                List<User> users = [SELECT Id,Address,FirstName,LastName,Username,MobilePhone,Phone,TimeZoneSidKey,Email FROM User WHERE Id =: context.installerId()];    
                if (users!=null && users.size() > 0) {
                    User u = users[0];
                    Address address = u.Address;
                    String addressString = '';
                    
                    if(address != null){
                        if (address.getStreet() != null) {
                            addressString += address.getStreet() + ', ';
                        }
                        if (address.getCity() != null) {
                            addressString += address.getCity() + ', ';
                        }
                        if (address.getState() != null) {
                            addressString += address.getState() + ', ';
                        }
                        if (address.getPostalCode() != null) {
                            addressString += address.getPostalCode() + ', ';
                        }
                        if (address.getCountry() != null) {
                            addressString += address.getCountry();
                        }
                        if (addressString.endsWith(', ')) {
                            addressString = addressString.substring(0, addressString.length() - 2);
                        }
                    }
    
                    mapOfData.put('User_Id__c', u.Id);
                    mapOfData.put('Username__c', u.Username);
                    mapOfData.put('First_Name__c', u.FirstName);
                    mapOfData.put('Last_Name__c', u.LastName);
                    mapOfData.put('Email__c', u.Email);
                    mapOfData.put('Phone__c', u.Phone);
                    mapOfData.put('Mobile_Phone__c', u.MobilePhone);
                    mapOfData.put('Address__c', addressString);
                    mapOfData.put('TimeZoneSidKey__c', u.TimeZoneSidKey);
    
                    // also need to pull the type of the org, prod or sandbox
    
                    userDataTable = '<table border="1" style="border-collapse: collapse;text-align:left; color: black;" cellpadding="4px">' +
                                    '<tr style="text-align:center;">' +
                                        '<th colspan="2" style="font-size: 18px; color: white; background-color:#165668;">User Details</th>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">User Id</th>' +
                                        '<td>' + u.Id + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">User Name</th>' +
                                        '<td>' + u.Username + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">FirstName</th>' +
                                        '<td>' + (String.isBlank(u.FirstName) ? '-' : u.FirstName) + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">LastName</th>' +
                                        '<td>' + (String.isBlank(u.LastName) ? '-' : u.LastName) + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Email</th>' +
                                        '<td>' + (String.isBlank(u.Email) ? '-' : u.Email) + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Phone</th>' +
                                        '<td>' + (String.isBlank(u.Phone) ? '-' : u.Phone) + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Mobile Phone</th>' +
                                        '<td>' + (String.isBlank(u.MobilePhone) ? '-' : u.MobilePhone) + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Address</th>' +
                                        '<td>' + (addressString!=''? addressString : '-') + '</td>' +
                                    '</tr>' +
                                    '<tr>' +
                                        '<th style="color: #165668">Time Zone SidKey</th>' +
                                        '<td>' + (String.isBlank(u.TimeZoneSidKey) ? '-' : u.TimeZoneSidKey) + '</td>' +
                                    '</tr>' +
                                    '</table>';
                }
        
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> emails = new List<String>{'productinstallationemail@v-xj3w6mezt66tmgyi1ybx4giimvh488ktt05mihoa2mya7we9f.5g-7qhe9eaa.ap59.apex.salesforce.com', 'wbconnect-support@mvclouds.com'};
                string[] to = emails;
    
                String stringToSend = JSON.serialize(mapOfData);
                
                email.setToAddresses(to);
                email.setSubject('WBConnect New Install - ' + orgId);
                email.setHtmlBody('<div style="font-family:Verdana;">Congrats WBConnect Team 🎉,<br></br><br></br>The WBConnect app has been installed in an Organization, Below are some Details about the client org.<br></br><br></br>' + orgDataTable+ '<br></br>' + userDataTable + '<br></br><br></br> <|--- BackEnd Use Only Data Start ---|>' + stringToSend +'<|--- BackEnd Use Only Data End ---|> </div>');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

                // Call the PLMS validity check
                DateTime userNextCalloutTime = Date.today().addMonths(1);
                String cronExpression = '0 ' + userNextCalloutTime.minute() + ' ' + userNextCalloutTime.hour() + ' ' + userNextCalloutTime.day() + ' ' + userNextCalloutTime.month() + ' ? ' + userNextCalloutTime.year();
                String jobName = 'PLMS_Validity_Check_' + System.currentTimeMillis();
                System.schedule(jobName, cronExpression, new PLMSValidityScheduler());

                MVWB__EmbeddedSignUpConfig__c embeddedConfig = new MVWB__EmbeddedSignUpConfig__c();
                embeddedConfig.MVWB__Client_Id__c = '514916280628381';
                embeddedConfig.MVWB__Client_Secret__c = '6e1719dde4e730a3a55e0eab8899f62b';
                embeddedConfig.MVWB__Config_Id__c = '8971126402921271';
                embeddedConfig.SetupOwnerId = systemAdminProfile[0].Id;
                insert embeddedConfig;

                MVWB__LicenseConfig__c licenseConfig = new MVWB__LicenseConfig__c();
                licenseConfig.MVWB__Client_Id__c = '3MVG9fe4g9fhX0E4o3IT3oGMiqurUSa0NG8pvAJd48VWiX4Nnuf901ij43yVCcLidSdA76x3f64HEf.e.0nLh';
                licenseConfig.MVWB__Client_Secret__c = 'CE75344BC73CEE272C81B8791E24EB6C73A9B66C68F41BA89E90CD5A3900B9E0';
                licenseConfig.MVWB__Username__c = 'insightsintegration@00d5g000007qhe9eaa.ext';
                licenseConfig.MVWB__Password__c = 'wbconnect@1';
                licenseConfig.MVWB__Is_License_Valid__c = true;
                licenseConfig.MVWB__Expiration_Date__c = Date.today().addMonths(1);
                licenseConfig.MVWB__Next_Callout_Date__c = Date.today().addMonths(1);
                insert licenseConfig;
            } else {
                List<MVWB__EmbeddedSignUpConfig__c> embeddedConfigList = [SELECT Id, MVWB__Client_Id__c, MVWB__Client_Secret__c, MVWB__Config_Id__c, SetupOwnerId FROM MVWB__EmbeddedSignUpConfig__c LIMIT 1];
                if( embeddedConfigList != null && !embeddedConfigList.isEmpty() && embeddedConfigList.size() > 0) {
                    MVWB__EmbeddedSignUpConfig__c embeddedConfig = new MVWB__EmbeddedSignUpConfig__c();
                    embeddedConfig = embeddedConfigList[0];
                    embeddedConfig.MVWB__Client_Id__c = '514916280628381';
                    embeddedConfig.MVWB__Client_Secret__c = '6e1719dde4e730a3a55e0eab8899f62b';
                    embeddedConfig.MVWB__Config_Id__c = '8971126402921271';
                    embeddedConfig.SetupOwnerId = systemAdminProfile[0].Id;
                    update embeddedConfig;
                }

                List<MVWB__LicenseConfig__c> configList = [SELECT Id, MVWB__Client_Id__c, MVWB__Client_Secret__c, MVWB__Is_License_Valid__c, MVWB__Expiration_Date__c, MVWB__Next_Callout_Date__c, MVWB__Password__c, MVWB__Username__c FROM MVWB__LicenseConfig__c LIMIT 1];
                if (configList != null && !configList.isEmpty() && configList.size() > 0) {
                    MVWB__LicenseConfig__c licenseConfig = new MVWB__LicenseConfig__c();
                    licenseConfig = configList[0];
                    licenseConfig.MVWB__Client_Id__c = '3MVG9fe4g9fhX0E4o3IT3oGMiqurUSa0NG8pvAJd48VWiX4Nnuf901ij43yVCcLidSdA76x3f64HEf.e.0nLh';
                    licenseConfig.MVWB__Client_Secret__c = 'CE75344BC73CEE272C81B8791E24EB6C73A9B66C68F41BA89E90CD5A3900B9E0';
                    licenseConfig.MVWB__Username__c = 'insightsintegration@00d5g000007qhe9eaa.ext';
                    licenseConfig.MVWB__Password__c = 'wbconnect@1';
                    licenseConfig.MVWB__Is_License_Valid__c = true;
                    licenseConfig.MVWB__Expiration_Date__c = Date.today().addMonths(1);
                    licenseConfig.MVWB__Next_Callout_Date__c = Date.today().addMonths(1);
                    update licenseConfig;
                }
            }
        } catch (Exception e) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> emails = new List<String>{'wbconnect-support@mvclouds.com'};
            string[] to = emails;

            // Enhanced error details
            String errorDetails = '<b>Error Message:</b> ' + e.getMessage() + '<br>' + '<b>Exception Type:</b> ' + 'PostInstallClass' + '<br>' + '<b>Line Number:</b> ' + e.getLineNumber() + '<br>' + '<b>Stack Trace:</b> <b>' + e.getStackTraceString() + '</b>';

            email.setToAddresses(to);
            email.setSubject('WBConnect Package Install Failed Exception Email');
            email.setHtmlBody( '<div style="font-family:Verdana;">' + '<b>Error Details:</b><br>' + errorDetails + '<br><br> <|--- BackEnd Use Only Data Start ---|>' + e  + '<|--- BackEnd Use Only Data End ---|> </div>');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}