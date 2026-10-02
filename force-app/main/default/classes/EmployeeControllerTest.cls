@isTest
private class EmployeeControllerTest {

    @testSetup
    static void setup() {
        Employee__c emp = new Employee__c(
            First_Name__c = 'Test',
            Last_Name__c  = 'Employee',
            Email__c      = 'test.employee@example.com',
            Hire_Date__c  = Date.today(),
            Status__c     = 'Active',
            Salesforce_User__c = UserInfo.getUserId()
        );
        insert emp;

        Leave_Type__c lt = new Leave_Type__c(
            Name = 'Annual Leave',
            Annual_Allowance__c = 21,
            Requires_Approval__c = true
        );
        insert lt;

        Leave_Balance__c bal = new Leave_Balance__c(
            Employee__c   = emp.Id,
            Leave_Type__c = lt.Id,
            Remaining_Days__c = 15,
            Used_Days__c      = 6,
            Year__c           = 2026
        );
        insert bal;
    }

    @isTest
    static void testGetCurrentEmployee() {
        Test.startTest();
        Employee__c result = EmployeeController.getCurrentEmployee();
        Test.stopTest();
        System.assertEquals('Test', result.First_Name__c, 'Should return the logged-in test user\'s Employee record');
    }

    @isTest
    static void testGetLeaveBalances() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Test.startTest();
        List<Leave_Balance__c> balances = EmployeeController.getLeaveBalances(emp.Id);
        Test.stopTest();
        System.assertEquals(1, balances.size(), 'Should return exactly one balance record');
    }

    @isTest
    static void testGetMyLeaveRequestsEmptyInitially() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Test.startTest();
        List<Leave__c> requests = EmployeeController.getMyLeaveRequests(emp.Id);
        Test.stopTest();
        System.assertEquals(0, requests.size(), 'No leave requests should exist yet');
    }

    @isTest
    static void testGetActiveLeaveTypes() {
        Test.startTest();
        List<Leave_Type__c> types = EmployeeController.getActiveLeaveTypes();
        Test.stopTest();
        System.assertEquals(1, types.size(), 'Should return the one Leave Type created in setup');
    }

    @isTest
    static void testSubmitLeaveRequestSuccess() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Leave_Type__c lt = [SELECT Id FROM Leave_Type__c LIMIT 1];

        Test.startTest();
        Id newId = EmployeeController.submitLeaveRequest(
            emp.Id, lt.Id, Date.today(), Date.today().addDays(3), 'Family trip'
        );
        Test.stopTest();

        System.assertNotEquals(null, newId, 'A new Leave record should have been created');
        Leave__c created = [SELECT Status__c FROM Leave__c WHERE Id = :newId];
        System.assertEquals('Submitted', created.Status__c);
    }

    @isTest
    static void testSubmitLeaveRequestInvalidDatesThrows() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Leave_Type__c lt = [SELECT Id FROM Leave_Type__c LIMIT 1];
        Boolean errorThrown = false;

        Test.startTest();
        try {
            EmployeeController.submitLeaveRequest(
                emp.Id, lt.Id, Date.today(), Date.today().addDays(-1), 'End before start'
            );
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assert(errorThrown, 'Submitting with end date before start date should throw an error');
    }
}