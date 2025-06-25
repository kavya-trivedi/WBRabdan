public with sharing class PLMSValidityScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        PLMSController.getPLMSValidity();
    }
}