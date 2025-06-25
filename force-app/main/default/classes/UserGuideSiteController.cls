public without sharing class UserGuideSiteController {
    @AuraEnabled
    public static List<Knowledge__kav> getAllUserGuides(){
        try {
            Id userGuideRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('WBConnect User Guide').getRecordTypeId();

            System.debug('The Total Size is ::: ' + [Select Count() FROM Knowledge__kav]);
            List<Knowledge__kav> userGuides = [SELECT Id, Title, UrlName, UG_Content__c,UG_Logo__c ,UG_Category__c FROM Knowledge__kav WHERE RecordTypeId =: userGuideRecordTypeId AND PublishStatus = 'Online' ORDER BY UG_Category__c, Sequence__c LIMIT 50000];
            
            return userGuides;
        } catch (Exception e) {
            system.debug('exception in getAllUserGuides : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }
}