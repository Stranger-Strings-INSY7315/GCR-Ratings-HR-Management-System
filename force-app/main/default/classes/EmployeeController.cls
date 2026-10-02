public with sharing class EmployeeController {

    @AuraEnabled(cacheable=true)
    public static Employee__c getCurrentEmployee() {
        Id currentUserId = UserInfo.getUserId();

        List<Employee__c> employees = [
            SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c,
                   Hire_Date__c, Status__c,
                   Department__c, Department__r.Name,
                   Position__c, Position__r.Name
            FROM Employee__c
            WHERE Salesforce_User__c = :currentUserId
            WITH USER_MODE
            LIMIT 1
        ];

        if (employees.isEmpty()) {
            throw new AuraHandledException('No Employee record is linked to your login. Please contact HR.');
        }
        return employees[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Leave_Balance__c> getLeaveBalances(Id employeeId) {
        return [
            SELECT Id, Leave_Type__c, Leave_Type__r.Name,
                   Remaining_Days__c, Used_Days__c, Year__c
            FROM Leave_Balance__c
            WHERE Employee__c = :employeeId
            WITH USER_MODE
            ORDER BY Leave_Type__r.Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Leave__c> getMyLeaveRequests(Id employeeId) {
        return [
            SELECT Id, Name, Leave_Type__c, Leave_Type__r.Name,
                   Start_Date__c, End_Date__c, Reason__c,
                   Status__c, Submitted_Date__c
            FROM Leave__c
            WHERE Employee__c = :employeeId
            WITH USER_MODE
            ORDER BY Submitted_Date__c DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Leave_Type__c> getActiveLeaveTypes() {
        return [
            SELECT Id, Name, Annual_Allowance__c
            FROM Leave_Type__c
            WITH USER_MODE
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static Id submitLeaveRequest(Id employeeId, Id leaveTypeId, Date startDate, Date endDate, String reason) {
        if (startDate == null || endDate == null) {
            throw new AuraHandledException('Please choose a start and end date.');
        }
        if (startDate > endDate) {
            throw new AuraHandledException('Start date cannot be after end date.');
        }

        Leave__c newRequest = new Leave__c(
            Employee__c   = employeeId,
            Leave_Type__c = leaveTypeId,
            Start_Date__c = startDate,
            End_Date__c   = endDate,
            Reason__c     = reason,
            Status__c     = 'Submitted',
            Submitted_Date__c = System.now()
        );

        insert newRequest;
        return newRequest.Id;
    }
}