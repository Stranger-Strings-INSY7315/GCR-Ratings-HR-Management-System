@isTest
private class LeaveApprovalControllerTest {

    // Builds a small, self-contained set of test data: one employee acting
    // as both the requester and the approver (fine for test purposes),
    // one leave type, one balance record, and one submitted leave request.
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

        Leave_Type__c leaveType = new Leave_Type__c(
            Name = 'Annual Leave'
        );
        insert leaveType;

        Leave_Balance__c balance = new Leave_Balance__c(
            Employee__c = emp.Id,
            Leave_Type__c = leaveType.Id,
            Year__c = Date.today().year(),
            Remaining_Days__c = 15,
            Used_Days__c = 0
        );
        insert balance;

        Leave__c leave = new Leave__c(
            Employee__c = emp.Id,
            Leave_Type__c = leaveType.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            Reason__c = 'Family event',
            Status__c = 'Submitted',
            Submitted_Date__c = Datetime.now()
        );
        insert leave;
    }

    @isTest
    static void testGetPendingLeaveRequests() {
        Test.startTest();
        List<LeaveApprovalController.LeaveRequestWrapper> results = LeaveApprovalController.getPendingLeaveRequests();
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one submitted leave request');
        System.assertEquals('Test Employee', results[0].employeeName, 'Employee name should be built from first and last name');
    }

    @isTest
    static void testApproveLeave() {
        Leave__c leave = [SELECT Id FROM Leave__c LIMIT 1];

        Test.startTest();
        LeaveApprovalController.approveLeave(leave.Id);
        Test.stopTest();

        Leave__c updated = [SELECT Status__c, Approved_Date__c, Approver__c FROM Leave__c WHERE Id = :leave.Id];
        System.assertEquals('Approved', updated.Status__c, 'Leave should now be Approved');
        System.assertNotEquals(null, updated.Approved_Date__c, 'Approved date should be set');
        System.assertNotEquals(null, updated.Approver__c, 'Approver should be set');

        Leave_Balance__c balance = [SELECT Remaining_Days__c, Used_Days__c FROM Leave_Balance__c LIMIT 1];
        System.assertEquals(12, balance.Remaining_Days__c, 'Three days should have been deducted from the balance');
        System.assertEquals(3, balance.Used_Days__c, 'Three days should have been added to used days');
    }

    @isTest
    static void testRejectLeave() {
        Leave__c leave = [SELECT Id FROM Leave__c LIMIT 1];

        Test.startTest();
        LeaveApprovalController.rejectLeave(leave.Id, 'Insufficient staffing on those dates.');
        Test.stopTest();

        Leave__c updated = [SELECT Status__c, Rejection_Reason__c, Approver__c FROM Leave__c WHERE Id = :leave.Id];
        System.assertEquals('Rejected', updated.Status__c, 'Leave should now be Rejected');
        System.assertEquals('Insufficient staffing on those dates.', updated.Rejection_Reason__c, 'Rejection reason should be saved');
        System.assertNotEquals(null, updated.Approver__c, 'Approver should be set');
    }

    @isTest
    static void testRejectLeaveMissingReason() {
        Leave__c leave = [SELECT Id FROM Leave__c LIMIT 1];
        Boolean errorThrown = false;

        Test.startTest();
        try {
            LeaveApprovalController.rejectLeave(leave.Id, '');
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, errorThrown, 'Should throw when no rejection reason is given');
    }

    @isTest
    static void testApproveLeaveMissingId() {
        Boolean errorThrown = false;
        try {
            LeaveApprovalController.approveLeave(null);
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when no leave request id is given');
    }
}