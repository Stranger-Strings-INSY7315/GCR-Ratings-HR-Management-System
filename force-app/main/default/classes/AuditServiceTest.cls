@isTest
private class AuditServiceTest {

    @isTest
    static void testLogCreatesRecord() {
        Test.startTest();
        AuditService.log('Test Action', 'Test_Object__c', null, 'Some test details');
        Test.stopTest();

        List<Audit_Log__c> logs = [
            SELECT Id, Action__c, Object_Type__c, Details__c, User__c
            FROM Audit_Log__c
            WHERE Action__c = 'Test Action'
        ];

        System.assertEquals(1, logs.size(), 'Expected exactly one audit log record to be created');
        System.assertEquals('Test_Object__c', logs[0].Object_Type__c);
        System.assertEquals('Some test details', logs[0].Details__c);
        System.assertEquals(UserInfo.getUserId(), logs[0].User__c);
    }

    @isTest
    static void testLogWithBlankActionDoesNothing() {
        Test.startTest();
        AuditService.log('', 'Test_Object__c', null, 'Some test details');
        Test.stopTest();

        List<Audit_Log__c> logs = [SELECT Id FROM Audit_Log__c];
        System.assertEquals(0, logs.size(), 'Expected no audit log record when action is blank');
    }

    @isTest
    static void testLogWithBlankObjectTypeDoesNothing() {
        Test.startTest();
        AuditService.log('Test Action', '', null, 'Some test details');
        Test.stopTest();

        List<Audit_Log__c> logs = [SELECT Id FROM Audit_Log__c];
        System.assertEquals(0, logs.size(), 'Expected no audit log record when object type is blank');
    }
}