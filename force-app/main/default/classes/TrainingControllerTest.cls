@isTest
private class TrainingControllerTest {

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

        Training_Course__c course = new Training_Course__c(
            Name = 'Workplace Ethics',
            Description__c = 'Mandatory annual compliance training.',
            Duration_Hours__c = 2,
            Category__c = 'Compliance',
            Is_Active__c = true
        );
        insert course;

        Employee_Training__c assigned = new Employee_Training__c(
            Employee__c = emp.Id,
            Course__c = course.Id,
            Status__c = 'Assigned',
            Assigned_Date__c = Date.today()
        );
        insert assigned;
    }

    @isTest
    static void testGetCurrentEmployee() {
        Test.startTest();
        Employee__c result = TrainingController.getCurrentEmployee();
        Test.stopTest();
        System.assertEquals('Test', result.First_Name__c, 'Should return the linked employee');
    }

    @isTest
    static void testGetMyTrainings() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Test.startTest();
        List<Employee_Training__c> results = TrainingController.getMyTrainings(emp.Id);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one assigned training');
    }

    @isTest
    static void testGetAvailableCourses() {
        Test.startTest();
        List<Training_Course__c> results = TrainingController.getAvailableCourses();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one active course');
    }

    @isTest
    static void testSubmitTrainingRequest() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Training_Course__c course = [SELECT Id FROM Training_Course__c LIMIT 1];

        Test.startTest();
        Id newId = TrainingController.submitTrainingRequest(emp.Id, course.Id, 'I need this for my role.');
        Test.stopTest();

        Training_Request__c created = [SELECT Status__c, Justification__c FROM Training_Request__c WHERE Id = :newId];
        System.assertEquals('Pending', created.Status__c, 'New requests should default to Pending');
    }

    @isTest
    static void testGetMyTrainingRequests() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Training_Course__c course = [SELECT Id FROM Training_Course__c LIMIT 1];
        TrainingController.submitTrainingRequest(emp.Id, course.Id, 'Career development.');

        Test.startTest();
        List<Training_Request__c> results = TrainingController.getMyTrainingRequests(emp.Id);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one submitted request');
    }

    @isTest
    static void testSubmitTrainingRequestMissingData() {
        Boolean errorThrown = false;
        try {
            TrainingController.submitTrainingRequest(null, null, 'No ids');
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when required ids are missing');
    }
}