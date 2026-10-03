@isTest
private class AttendanceControllerTest {

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
    static void testGetTodayStatusNoRecord() {
        Test.startTest();
        AttendanceController.TodayStatusWrapper status = AttendanceController.getTodayStatus();
        Test.stopTest();

        System.assertEquals(false, status.hasClockedIn, 'Should not have clocked in yet');
        System.assertEquals(false, status.hasClockedOut, 'Should not have clocked out yet');
    }

    @isTest
    static void testClockIn() {
        Test.startTest();
        AttendanceController.clockIn();
        Test.stopTest();

        Attendance__c record = [SELECT Attendance_Date__c, Clock_In__c, Clock_Out__c FROM Attendance__c LIMIT 1];
        System.assertEquals(Date.today(), record.Attendance_Date__c, 'Attendance date should be today');
        System.assertNotEquals(null, record.Clock_In__c, 'Clock in time should be set');
        System.assertEquals(null, record.Clock_Out__c, 'Clock out should still be empty');
    }

    @isTest
    static void testClockInTwiceFails() {
        AttendanceController.clockIn();
        Boolean errorThrown = false;

        Test.startTest();
        try {
            AttendanceController.clockIn();
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, errorThrown, 'Should not be able to clock in twice in the same day');
    }

    @isTest
    static void testClockOut() {
        AttendanceController.clockIn();

        Test.startTest();
        AttendanceController.clockOut();
        Test.stopTest();

        Attendance__c record = [SELECT Clock_In__c, Clock_Out__c FROM Attendance__c LIMIT 1];
        System.assertNotEquals(null, record.Clock_Out__c, 'Clock out time should now be set');
    }

    @isTest
    static void testClockOutWithoutClockInFails() {
        Boolean errorThrown = false;

        Test.startTest();
        try {
            AttendanceController.clockOut();
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, errorThrown, 'Should not be able to clock out without clocking in first');
    }

    @isTest
    static void testClockOutTwiceFails() {
        AttendanceController.clockIn();
        AttendanceController.clockOut();
        Boolean errorThrown = false;

        Test.startTest();
        try {
            AttendanceController.clockOut();
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, errorThrown, 'Should not be able to clock out twice in the same day');
    }

    @isTest
    static void testGetMyAttendanceHistory() {
        AttendanceController.clockIn();

        Test.startTest();
        List<AttendanceController.AttendanceWrapper> history = AttendanceController.getMyAttendanceHistory();
        Test.stopTest();

        System.assertEquals(1, history.size(), 'Should return the one attendance record created today');
        System.assertEquals('Test Employee', history[0].employeeName, 'Employee name should be built from first and last name');
    }

    @isTest
    static void testGetAllAttendance() {
        AttendanceController.clockIn();

        Test.startTest();
        List<AttendanceController.AttendanceWrapper> allRecords = AttendanceController.getAllAttendance();
        Test.stopTest();

        System.assertEquals(1, allRecords.size(), 'HR overview should see the one attendance record created today');
    }
}