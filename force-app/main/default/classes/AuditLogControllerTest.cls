@isTest
private class AuditLogControllerTest {

    @testSetup
    static void setup() {
        AuditService.log('Test Action', 'Test_Object__c', null, 'Setup details');
    }

    @isTest
    static void testGetAllAuditLogs() {
        Test.startTest();
        List<AuditLogController.AuditLogWrapper> results = AuditLogController.getAllAuditLogs();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected exactly one audit log record');
        System.assertEquals('Test Action', results[0].action);
        System.assertEquals('Test_Object__c', results[0].objectType);
        System.assertEquals('Setup details', results[0].details);
        System.assertNotEquals(null, results[0].userName, 'Expected the running user\'s name to be populated');
    }
}