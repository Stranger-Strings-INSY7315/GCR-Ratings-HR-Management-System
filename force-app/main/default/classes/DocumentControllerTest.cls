@isTest
private class DocumentControllerTest {

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

        Document__c doc = new Document__c(
            Name = 'October Payslip',
            Uploaded_By__c = emp.Id,
            Category__c = 'Payslip',
            Upload_Date__c = Datetime.now()
        );
        insert doc;

        // Simulate HR uploading a file and attaching it to the Document__c record.
        ContentVersion cv = new ContentVersion();
        cv.Title = 'October Payslip';
        cv.PathOnClient = 'October_Payslip.pdf';
        cv.VersionData = Blob.valueOf('Fake PDF content for testing.');
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = contentDocumentId;
        link.LinkedEntityId = doc.Id;
        link.ShareType = 'V';
        insert link;
    }

    @isTest
    static void testGetMyDocumentsWithFile() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];

        Test.startTest();
        List<DocumentController.DocumentWrapper> results = DocumentController.getMyDocuments(emp.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the one document');
        System.assertNotEquals(null, results[0].contentVersionId, 'Should find the attached file');
    }

    @isTest
    static void testGetMyDocumentsNoEmployee() {
        Test.startTest();
        List<DocumentController.DocumentWrapper> results = DocumentController.getMyDocuments(null);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'A null employee id should return no documents');
    }
}