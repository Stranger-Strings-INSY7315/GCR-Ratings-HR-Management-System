/**
 * LeaveApprovalController
 * Powers the Leave Approvals tab of the HR/Admin web portal:
 *   - list of all leave requests waiting for a decision
 *   - approving a request (and deducting the days from that employee's balance)
 *   - rejecting a request (with a reason)
 */
public with sharing class LeaveApprovalController {

    // Wrapper so the front end gets exactly the fields it needs,
    // including the employee's name (which lives on a related record).
    public class LeaveRequestWrapper {
        @AuraEnabled public Id leaveId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String leaveTypeName;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String reason;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime submittedDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<LeaveRequestWrapper> getPendingLeaveRequests() {
        List<Leave__c> requests = [
            SELECT Id, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Leave_Type__r.Name, Start_Date__c, End_Date__c,
                   Reason__c, Status__c, Submitted_Date__c
            FROM Leave__c
            WHERE Status__c = 'Submitted'
            WITH USER_MODE
            ORDER BY Submitted_Date__c ASC
        ];

        List<LeaveRequestWrapper> results = new List<LeaveRequestWrapper>();
        for (Leave__c lv : requests) {
            LeaveRequestWrapper w = new LeaveRequestWrapper();
            w.leaveId = lv.Id;
            w.employeeName = lv.Employee__r.First_Name__c + ' ' + lv.Employee__r.Last_Name__c;
            w.leaveTypeName = lv.Leave_Type__r.Name;
            w.startDate = lv.Start_Date__c;
            w.endDate = lv.End_Date__c;
            w.reason = lv.Reason__c;
            w.status = lv.Status__c;
            w.submittedDate = lv.Submitted_Date__c;
            results.add(w);
        }
        return results;
    }

    @AuraEnabled
    public static void approveLeave(Id leaveRequestId) {
        if (leaveRequestId == null) {
            throw new AuraHandledException('A leave request must be specified.');
        }

        List<Leave__c> matches = [
            SELECT Id, Employee__c, Leave_Type__c, Start_Date__c, End_Date__c, Status__c
            FROM Leave__c
            WHERE Id = :leaveRequestId
            WITH USER_MODE
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            throw new AuraHandledException('That leave request could not be found.');
        }
        Leave__c lv = matches[0];

        Id approverEmployeeId = getCurrentApproverEmployeeId();

        // Build a minimal record with only the fields we're changing, so the
        // DML statement never touches Employee__c (a master-detail field,
        // which Salesforce blocks from being edited this way even though
        // we never actually change its value).
        Leave__c updateRecord = new Leave__c(
            Id = lv.Id,
            Status__c = 'Approved',
            Approver__c = approverEmployeeId,
            Approved_Date__c = Date.today()
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not approve this request: ' + e.getMessage());
        }

        // Deduct the days taken from this employee's leave balance for that
        // leave type and year, if a balance record exists for them.
        Integer daysTaken = lv.Start_Date__c.daysBetween(lv.End_Date__c) + 1;
        Integer leaveYear = lv.Start_Date__c.year();

        List<Leave_Balance__c> balances = [
            SELECT Id, Remaining_Days__c, Used_Days__c
            FROM Leave_Balance__c
            WHERE Employee__c = :lv.Employee__c
              AND Leave_Type__c = :lv.Leave_Type__c
              AND Year__c = :leaveYear
            WITH USER_MODE
            LIMIT 1
        ];

        if (!balances.isEmpty()) {
            Leave_Balance__c bal = balances[0];
            Leave_Balance__c balanceUpdate = new Leave_Balance__c(
                Id = bal.Id,
                Remaining_Days__c = (bal.Remaining_Days__c == null ? 0 : bal.Remaining_Days__c) - daysTaken,
                Used_Days__c = (bal.Used_Days__c == null ? 0 : bal.Used_Days__c) + daysTaken
            );
            try {
                update as user balanceUpdate;
            } catch (DmlException e) {
                throw new AuraHandledException('Leave was approved, but the balance could not be updated: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void rejectLeave(Id leaveRequestId, String rejectionReason) {
        if (leaveRequestId == null) {
            throw new AuraHandledException('A leave request must be specified.');
        }
        if (String.isBlank(rejectionReason)) {
            throw new AuraHandledException('Please provide a reason for rejecting this request.');
        }

        List<Leave__c> matches = [
            SELECT Id, Status__c
            FROM Leave__c
            WHERE Id = :leaveRequestId
            WITH USER_MODE
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            throw new AuraHandledException('That leave request could not be found.');
        }
        Leave__c lv = matches[0];

        Id approverEmployeeId = getCurrentApproverEmployeeId();

        Leave__c updateRecord = new Leave__c(
            Id = lv.Id,
            Status__c = 'Rejected',
            Approver__c = approverEmployeeId,
            Rejection_Reason__c = rejectionReason
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not reject this request: ' + e.getMessage());
        }
    }

    // Looks up the Employee__c record linked to whoever is currently logged in,
    // so we can record them as the approver.
    private static Id getCurrentApproverEmployeeId() {
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