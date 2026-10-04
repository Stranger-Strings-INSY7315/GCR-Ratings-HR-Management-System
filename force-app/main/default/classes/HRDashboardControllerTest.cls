@isTest
private class HRDashboardControllerTest {

    @testSetup
    static void setup() {
        Employee__c activeEmp = new Employee__c(
            First_Name__c = 'Active', Last_Name__c = 'Employee',
            Email__c = 'active.employee@example.com', Hire_Date__c = Date.today(),
            Status__c = 'Active'
        );
        Employee__c onboardingEmp = new Employee__c(
            First_Name__c = 'Onboarding', Last_Name__c = 'Employee',
            Email__c = 'onboarding.employee@example.com', Hire_Date__c = Date.today(),
            Status__c = 'Onboarding'
        );
        insert new List<Employee__c>{ activeEmp, onboardingEmp };

        Leave_Type__c leaveType = new Leave_Type__c(
            Name = 'Annual Leave', Annual_Allowance__c = 15, Requires_Approval__c = true
        );
        insert leaveType;

        List<Leave__c> leaves = new List<Leave__c>{
            new Leave__c(
                Employee__c = activeEmp.Id, Leave_Type__c = leaveType.Id,
                Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(2),
                Reason__c = 'Test leave', Status__c = 'Submitted'
            ),
            new Leave__c(
                Employee__c = activeEmp.Id, Leave_Type__c = leaveType.Id,
                Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(1),
                Reason__c = 'Test leave', Status__c = 'Approved'
            ),
            new Leave__c(
                Employee__c = activeEmp.Id, Leave_Type__c = leaveType.Id,
                Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(1),
                Reason__c = 'Test leave', Status__c = 'Rejected'
            )
        };
        insert leaves;

        Training_Course__c course = new Training_Course__c(
            Name = 'Test Course', Description__c = 'Test description',
            Duration_Hours__c = 2, Category__c = 'Technical', Is_Active__c = true
        );
        insert course;

        List<Employee_Training__c> trainings = new List<Employee_Training__c>{
            new Employee_Training__c(
                Employee__c = activeEmp.Id, Course__c = course.Id,
                Assigned_Date__c = Date.today(), Status__c = 'Assigned'
            ),
            new Employee_Training__c(
                Employee__c = onboardingEmp.Id, Course__c = course.Id,
                Assigned_Date__c = Date.today(), Completion_Date__c = Date.today(), Status__c = 'Completed'
            )
        };
        insert trainings;

        Performance_Review__c review = new Performance_Review__c(
            Employee__c = activeEmp.Id, Reviewer__c = activeEmp.Id,
            Review_Date__c = Date.today(), Rating__c = 4, Status__c = 'Finalized'
        );
        insert review;

        Attendance__c attendance = new Attendance__c(
            Employee__c = activeEmp.Id, Attendance_Date__c = Date.today(),
            Clock_In__c = Datetime.now()
        );
        insert attendance;
    }

    @isTest
    static void testGetDashboardStats() {
        Test.startTest();
        HRDashboardController.DashboardStats stats = HRDashboardController.getDashboardStats();
        Test.stopTest();

        System.assertEquals(2, stats.totalEmployees, 'Should count both employees');
        System.assertEquals(1, stats.activeEmployees, 'Should count only active employee');

        System.assertEquals(3, stats.totalLeaveRequests, 'Should count all leave requests');
        System.assertEquals(1, stats.pendingLeaveRequests, 'Should count submitted leave as pending');
        System.assertEquals(1, stats.approvedLeaveRequests, 'Should count approved leave');
        System.assertEquals(1, stats.rejectedLeaveRequests, 'Should count rejected leave');

        System.assertEquals(2, stats.totalTrainingAssignments, 'Should count all training assignments');
        System.assertEquals(1, stats.assignedTraining, 'Should count assigned training');
        System.assertEquals(1, stats.completedTraining, 'Should count completed training');
        System.assertEquals(50.0, stats.trainingCompletionRate, 'Completion rate should be 50%');

        System.assertEquals(1, stats.totalReviews, 'Should count all reviews');
        System.assertEquals(1, stats.finalizedReviews, 'Should count finalized reviews');
        System.assertEquals(4.0, stats.averageRating, 'Average rating should be 4.0');

        System.assertEquals(1, stats.attendanceRecordsThisMonth, 'Should count attendance records this month');
    }
}