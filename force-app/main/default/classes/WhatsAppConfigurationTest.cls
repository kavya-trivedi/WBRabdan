/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-20-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class WhatsAppConfigurationTest {

    @IsTest
    static void testSaveConfigurations() {
        Test.startTest();
        WhatsAppConfigurationController.saveConfiguration('123','123','123','123');
        Test.stopTest();
    }

    @IsTest
    static void testgetConfigurations() {
        Test.startTest();
        WhatsAppConfigurationController.getConfiguration();
        Test.stopTest();
    }
}