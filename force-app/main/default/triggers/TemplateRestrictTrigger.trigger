trigger TemplateRestrictTrigger on Template__c (before insert) {
    WBTemplateController.restrictTemplates(Trigger.new);
}