/**
 * AttendanceController
 * Powers Attendance tracking on both sides:
 *   - Employee app: clock in / clock out, and a personal attendance history
 *   - HR/Admin portal: a read-only overview of everyone's attendance
 * Every clock in and clock out also writes an audit trail entry.
 */
public with sharing class AttendanceController {

    public class AttendanceWrapper {
        @AuraEnabled public Id attendanceId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public Date attendanceDate;
        @AuraEnabled public Datetime clockIn;
        @AuraEnabled public Datetime clockOut;
        @AuraEnabled public Decimal hoursWorked;
    }

    // Tells the employee app whether to show "Clock In" or "Clock Out"
    // for today, and what time they clocked in if they already have.
    public class TodayStatusWrapper {
        @AuraEnabled public Id attendanceId;
        @AuraEnabled public Boolean hasClockedIn;
        @AuraEnabled public Boolean hasClockedOut;
        @AuraEnabled public Datetime clockIn;
    }

    // ---------- Employee self-view ----------

    @AuraEnabled(cacheable=true)
    public static TodayStatusWrapper getTodayStatus() {
        Id myEmployeeId = getCurrentEmployeeId();

        List<Attendance__c> todayRecords = [
            SELECT Id, Clock_In__c, Clock_Out__c
            FROM Attendance__c
            WHERE Employee__c = :myEmployeeId
              AND Attendance_Date__c = :Date.today()
            WITH USER_MODE
            LIMIT 1
        ];

        TodayStatusWrapper status = new TodayStatusWrapper();
        if (todayRecords.isEmpty()) {
            status.hasClockedIn = false;
            status.hasClockedOut = false;
        } else {
            Attendance__c rec = todayRecords[0];
            status.attendanceId = rec.Id;
            status.hasClockedIn = true;
            status.hasClockedOut = rec.Clock_Out__c != null;
            status.clockIn = rec.Clock_In__c;
        }
        return status;
    }

    @AuraEnabled(cacheable=true)
    public static List<AttendanceWrapper> getMyAttendanceHistory() {
        Id myEmployeeId = getCurrentEmployeeId();

        List<Attendance__c> records = [
            SELECT Id, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Attendance_Date__c, Clock_In__c, Clock_Out__c
            FROM Attendance__c
            WHERE Employee__c = :myEmployeeId
            WITH USER_MODE
            ORDER BY Attendance_Date__c DESC
            LIMIT 30
        ];

        return wrapRecords(records);
    }

    @AuraEnabled
    public static void clockIn() {
        Id myEmployeeId = getCurrentEmployeeId();

        List<Attendance__c> existing = [
            SELECT Id
            FROM Attendance__c
            WHERE Employee__c = :myEmployeeId
              AND Attendance_Date__c = :Date.today()
            WITH USER_MODE
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            throw new AuraHandledException('You have already clocked in today.');
        }

        Attendance__c newRecord = new Attendance__c(
            Employee__c = myEmployeeId,
            Attendance_Date__c = Date.today(),
            Clock_In__c = Datetime.now()
        );

        try {
            insert as user newRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not clock in: ' + e.getMessage());
        }

        AuditService.log(
            'Clock In',
            'Attendance__c',
            newRecord.Id,
            'Employee clocked in at ' + newRecord.Clock_In__c.format()
        );
    }

    @AuraEnabled
    public static void clockOut() {
        Id myEmployeeId = getCurrentEmployeeId();

        List<Attendance__c> todayRecords = [
            SELECT Id, Clock_Out__c
            FROM Attendance__c
            WHERE Employee__c = :myEmployeeId
              AND Attendance_Date__c = :Date.today()
            WITH USER_MODE
            LIMIT 1
        ];
        if (todayRecords.isEmpty()) {
            throw new AuraHandledException('You have not clocked in yet today.');
        }
        if (todayRecords[0].Clock_Out__c != null) {
            throw new AuraHandledException('You have already clocked out today.');
        }

        Datetime clockOutTime = Datetime.now();

        // Minimal record: only Clock_Out__c, never touching Employee__c
        // (a master-detail field - see PerformanceReviewController for why).
        Attendance__c updateRecord = new Attendance__c(
            Id = todayRecords[0].Id,
            Clock_Out__c = clockOutTime
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not clock out: ' + e.getMessage());
        }

        AuditService.log(
            'Clock Out',
            'Attendance__c',
            todayRecords[0].Id,
            'Employee clocked out at ' + clockOutTime.format()
        );
    }

    // ---------- HR / Admin overview ----------

    @AuraEnabled(cacheable=true)
    public static List<AttendanceWrapper> getAllAttendance() {
        List<Attendance__c> records = [
            SELECT Id, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Attendance_Date__c, Clock_In__c, Clock_Out__c
            FROM Attendance__c
            WITH USER_MODE
            ORDER BY Attendance_Date__c DESC
            LIMIT 100
        ];

        return wrapRecords(records);
    }

    // ---------- Shared helpers ----------

    private static List<AttendanceWrapper> wrapRecords(List<Attendance__c> records) {
        List<AttendanceWrapper> results = new List<AttendanceWrapper>();
        for (Attendance__c rec : records) {
            AttendanceWrapper w = new AttendanceWrapper();
            w.attendanceId = rec.Id;
            w.employeeName = rec.Employee__r.First_Name__c + ' ' + rec.Employee__r.Last_Name__c;
            w.attendanceDate = rec.Attendance_Date__c;
            w.clockIn = rec.Clock_In__c;
            w.clockOut = rec.Clock_Out__c;
            if (rec.Clock_In__c != null && rec.Clock_Out__c != null) {
                Long millisWorked = rec.Clock_Out__c.getTime() - rec.Clock_In__c.getTime();
                w.hoursWorked = (Decimal.valueOf(millisWorked) / (1000 * 60 * 60)).setScale(2);
            }
            results.add(w);
        }
        return results;
    }

    private static Id getCurrentEmployeeId() {
        List<Employee__c> emps = [
            SELECT Id
            FROM Employee__c
            WHERE Salesforce_User__c = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (emps.isEmpty()) {
            throw new AuraHandledException('No Employee record is linked to your login. Please contact an administrator.');
        }
        return emps[0].Id;
    }
}