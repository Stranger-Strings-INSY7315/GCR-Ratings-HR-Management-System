@isTest
private class TrainingAdminControllerTest {

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

        Training_Request__c req = new Training_Request__c(
            Employee__c = emp.Id,
            Course__c = course.Id,
            Status__c = 'Submitted',
            Request_Date__c = Date.today(),
            Justification__c = 'Need this for my role.'
        );
        insert req;
    }

    @isTest
    static void testGetAllCourses() {
        Test.startTest();
        List<TrainingAdminController.CourseWrapper> results = TrainingAdminController.getAllCourses();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one course');
    }

    @isTest
    static void testCreateCourse() {
        Test.startTest();
        Id newId = TrainingAdminController.createCourse('New Course', 'Description', 3, 'Technical', true);
        Test.stopTest();

        Training_Course__c created = [SELECT Name, Is_Active__c FROM Training_Course__c WHERE Id = :newId];
        System.assertEquals('New Course', created.Name);
        System.assertEquals(true, created.Is_Active__c);
    }

    @isTest
    static void testCreateCourseMissingName() {
        Boolean errorThrown = false;
        try {
            TrainingAdminController.createCourse('', 'Description', 3, 'Technical', true);
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when name is missing');
    }

    @isTest
    static void testUpdateCourse() {
        Training_Course__c course = [SELECT Id FROM Training_Course__c LIMIT 1];

        Test.startTest();
        TrainingAdminController.updateCourse(course.Id, 'Updated Name', 'Updated Desc', 4, 'Leadership', false);
        Test.stopTest();

        Training_Course__c updated = [SELECT Name, Is_Active__c, Category__c FROM Training_Course__c WHERE Id = :course.Id];
        System.assertEquals('Updated Name', updated.Name);
        System.assertEquals(false, updated.Is_Active__c);
        System.assertEquals('Leadership', updated.Category__c);
    }

    @isTest
    static void testGetAllTrainingRequests() {
        Test.startTest();
        List<TrainingAdminController.TrainingRequestWrapper> results = TrainingAdminController.getAllTrainingRequests();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one request');
    }

    @isTest
    static void testApproveTrainingRequest() {
        Training_Request__c req = [SELECT Id FROM Training_Request__c LIMIT 1];
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];

        Test.startTest();
        TrainingAdminController.actionTrainingRequest(req.Id, true);
        Test.stopTest();

        Training_Request__c updated = [SELECT Status__c FROM Training_Request__c WHERE Id = :req.Id];
        System.assertEquals('Approved', updated.Status__c);

        List<Employee_Training__c> assignments = [SELECT Id, Status__c FROM Employee_Training__c WHERE Employee__c = :emp.Id];
        System.assertEquals(1, assignments.size(), 'Approving should create an Employee_Training__c record');
        System.assertEquals('Assigned', assignments[0].Status__c);
    }

    @isTest
    static void testRejectTrainingRequest() {
        Training_Request__c req = [SELECT Id FROM Training_Request__c LIMIT 1];

        Test.startTest();
        TrainingAdminController.actionTrainingRequest(req.Id, false);
        Test.stopTest();

        Training_Request__c updated = [SELECT Status__c FROM Training_Request__c WHERE Id = :req.Id];
        System.assertEquals('Rejected', updated.Status__c);

        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        List<Employee_Training__c> assignments = [SELECT Id FROM Employee_Training__c WHERE Employee__c = :emp.Id];
        System.assertEquals(0, assignments.size(), 'Rejecting should not create an Employee_Training__c record');
    }

    @isTest
    static void testActionTrainingRequestMissingId() {
        Boolean errorThrown = false;
        try {
            TrainingAdminController.actionTrainingRequest(null, true);
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when request id is missing');
    }

    @isTest
    static void testGetEmployeeOptions() {
        Test.startTest();
        List<TrainingAdminController.EmployeeOption> results = TrainingAdminController.getEmployeeOptions();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one employee');
    }

    @isTest
    static void testGetActiveCourseOptions() {
        Test.startTest();
        List<TrainingAdminController.CourseOption> results = TrainingAdminController.getActiveCourseOptions();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one active course');
    }

    @isTest
    static void testAssignTrainingDirectly() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Training_Course__c course = [SELECT Id FROM Training_Course__c LIMIT 1];

        Test.startTest();
        TrainingAdminController.assignTrainingDirectly(emp.Id, course.Id);
        Test.stopTest();

        List<Employee_Training__c> assignments = [SELECT Id, Status__c FROM Employee_Training__c WHERE Employee__c = :emp.Id];
        System.assertEquals(1, assignments.size(), 'Should create one Employee_Training__c record');
        System.assertEquals('Assigned', assignments[0].Status__c);
    }

    @isTest
    static void testAssignTrainingDirectlyMissingIds() {
        Boolean errorThrown = false;
        try {
            TrainingAdminController.assignTrainingDirectly(null, null);
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when ids are missing');
    }
}