@isTest
private class DocumentAdminControllerTest {

    @testSetup
    static void setup() {
        Employee__c emp = new Employee__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Employee',
            Email__c = 'test.employee@example.com',
            Hire_Date__c = Date.today(),
            Status__c = 'Active',
            Salesforce_User__c = UserInfo.getUserId()
        );
        insert emp;
    }

    @isTest
    static void testGetEmployeeOptions() {
        Test.startTest();
        List<DocumentAdminController.EmployeeOption> results = DocumentAdminController.getEmployeeOptions();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one employee');
    }

    @isTest
    static void testCreateDocumentRecord() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];

        Test.startTest();
        Id newId = DocumentAdminController.createDocumentRecord(emp.Id, 'October Payslip', 'Payslip');
        Test.stopTest();

        Document__c created = [SELECT Name, Category__c, Uploaded_By__c FROM Document__c WHERE Id = :newId];
        System.assertEquals('October Payslip', created.Name);
        System.assertEquals('Payslip', created.Category__c);
        System.assertEquals(emp.Id, created.Uploaded_By__c);
    }

    @isTest
    static void testCreateDocumentRecordMissingEmployee() {
        Boolean errorThrown = false;
        try {
            DocumentAdminController.createDocumentRecord(null, 'October Payslip', 'Payslip');
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when employee id is missing');
    }

    @isTest
    static void testCreateDocumentRecordMissingName() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Boolean errorThrown = false;
        try {
            DocumentAdminController.createDocumentRecord(emp.Id, '', 'Payslip');
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when document name is missing');
    }

    @isTest
    static void testGetAllDocuments() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        DocumentAdminController.createDocumentRecord(emp.Id, 'October Payslip', 'Payslip');

        Test.startTest();
        List<DocumentAdminController.DocumentWrapper> results = DocumentAdminController.getAllDocuments();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the one document');
        System.assertEquals('Test Employee', results[0].employeeName);
    }
}