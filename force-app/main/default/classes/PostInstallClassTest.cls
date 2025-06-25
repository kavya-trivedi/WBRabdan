@isTest
public with sharing class PostInstallClassTest {

    @testSetup
    static void setupTestData() {
        // Perform User creation in a separate context
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            // Create a new user
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser@example.com',
                Username = 'testuser@example.com' + System.currentTimeMillis(),
                Alias = 'tuser',
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                Street = '123 Test Street',
                City = 'Mumbai',
                State = 'Maharashtra',
                PostalCode = '400001',
                Country = 'India'
            );

            insert testUser;
        }
    }

    @isTest
    static void testInstallScript() {
        user testuser = [SELECT Id FROM User WHERE Email = 'testuser@example.com'];
        System.runAs(testuser) {
            Test.startTest();
            PostInstallClass postinstall = new PostInstallClass();
            Test.testInstall(postinstall, null);
            Integer invocations = Limits.getEmailInvocations();
            Test.stopTest();

            system.assertEquals(1, invocations, 'An email should be sent');
        }
    }

    @IsTest
    static void testOnInstall_ExceptionCoverage() {
        user testuser = [SELECT Id FROM User WHERE Email = 'testuser@example.com'];
        System.runAs(testuser) {
            Test.startTest();

            PostInstallClass postInstall = new PostInstallClass();
            postInstall.onInstall(null);
            
            Test.stopTest();
        }
    }
}