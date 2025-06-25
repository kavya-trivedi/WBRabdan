/**
 * Class Name: NewInstallDataController
 * Test Class: -
 * @description: Used to handle the emails and store the org data
 * ****************************************************************
 * @Note: This class is not to be added to the package, it's for the handler org only
 * ****************************************************************
 * Created Date: 18 Dec, 2024
 * Created By: Kevin Suvagiya
 *--------------------------------------------------------------------------------
 * Last Modified By: Kevin Suvagiya
 * Last Modified Date: 26 Dec, 2024
 * Last Modification Description: Updated method to save the record in the WbConnect_Install__c object
 *--------------------------------------------------------------------------------
 * Modification History:
 * Date Modified - Developer Name - Description
 * 18 Dec, 2024  - Kevin Suvagiya - Created a method to handle the emails and store the org data
 * 26 Dec, 2024  - Kevin Suvagiya - Updated method to save the record in the WbConnect_Install__c object
 **/
public with sharing class NewInstallDataController implements Messaging.InboundEmailHandler{
    /*
    *********************************************************
    @description     : Method is used to handle the emails and store the org data
    @param           : email - {Messaging.InboundEmail} - Data about the email to be handled
    @param           : envelope - {Messaging.InboundEnvelope} - emails of the sender and recipient
    @return          : none
    ********************************************************
    */
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        try {
            Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
            String emailBody = email.htmlBody;
            String backendUseData = emailBody.substringAfter('<|--- BackEnd Use Only Data Start ---|>').substringBefore('<|--- BackEnd Use Only Data End ---|>');
            System.debug('emailBody '+backendUseData);
            Product_Subscriber__c newInstallData = (Product_Subscriber__c) JSON.deserialize(backendUseData, WbConnect_Install__c.class);
            String productId = [SELECT Id FROM Product__c WHERE Name = newInstallData.Installed_Product__c LIMIT 1].Id;
            newInstallData.Product__c = productId;
            System.debug('newInstallData '+newInstallData);
            insert as User newInstallData;

            Task newTask = new Task();
            newTask.ActivityDate = Date.today();
            newTask.Subject = email.subject;
            newTask.description = emailBody;
            newTask.WhatId = newInstallData.Id;
            newTask.Status = 'Completed';
            insert as User newTask;

            return result;
        } catch (Exception e) {
            System.debug('Error in handleInboundEmail :: ' + e.getMessage());
            return null;
        }
    }
//The Email Service Email for now is : newinstalldata@xu3km95o0v0e1sqwtcmzhpgmxtfy170b801sod3wb4o19psz0.dm-fn77nuab.ind136.apex.salesforce.com
}