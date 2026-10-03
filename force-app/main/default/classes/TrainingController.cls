/**
 * TrainingController
 * Powers the Training tab of the Employee mobile app:
 *   - list of training this employee has been assigned / completed
 *   - list of training courses they can request
 *   - list of requests they've already submitted
 *   - submitting a new training request
 *   - marking an assigned training as complete
 */
public with sharing class TrainingController {

    @AuraEnabled(cacheable=true)
    public static Employee__c getCurrentEmployee() {
        List<Employee__c> emps = [
            SELECT Id, First_Name__c, Last_Name__c
            FROM Employee__c
            WHERE Salesforce_User__c = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (emps.isEmpty()) {
            throw new AuraHandledException('No Employee record is linked to your login. Please contact HR.');
        }
        return emps[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Employee_Training__c> getMyTrainings(Id employeeId) {
        return [
            SELECT Id, Course__r.Name, Course__r.Duration_Hours__c,
                   Status__c, Assigned_Date__c, Completion_Date__c
            FROM Employee_Training__c
            WHERE Employee__c = :employeeId
            WITH USER_MODE
            ORDER BY Assigned_Date__c DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Training_Course__c> getAvailableCourses() {
        return [
            SELECT Id, Name, Description__c, Duration_Hours__c, Category__c
            FROM Training_Course__c
            WHERE Is_Active__c = true
            WITH USER_MODE
            ORDER BY Category__c, Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Training_Request__c> getMyTrainingRequests(Id employeeId) {
        return [
            SELECT Id, Course__r.Name, Status__c, Request_Date__c, Justification__c
            FROM Training_Request__c
            WHERE Employee__c = :employeeId
            WITH USER_MODE
            ORDER BY Request_Date__c DESC
        ];
    }

    @AuraEnabled
    public static Id submitTrainingRequest(Id employeeId, Id courseId, String reason) {
        if (employeeId == null || courseId == null) {
            throw new AuraHandledException('Employee and course are required.');
        }

        Training_Request__c req = new Training_Request__c();
        req.Employee__c = employeeId;
        req.Course__c = courseId;
        req.Justification__c = reason;
        req.Status__c = 'Submitted';
        req.Request_Date__c = Date.today();

        try {
            insert as user req;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not submit your request: ' + e.getMessage());
        }

        return req.Id;
    }

    @AuraEnabled
    public static void markTrainingComplete(Id employeeTrainingId) {
        if (employeeTrainingId == null) {
            throw new AuraHandledException('A training assignment must be specified.');
        }

        // Minimal record: only the fields being changed, never touching
        // Employee__c or Course__c (master-detail/lookup fields we don't
        // need to re-send, consistent with the lesson learned elsewhere
        // in this project).
        Employee_Training__c updateRecord = new Employee_Training__c(
            Id = employeeTrainingId,
            Status__c = 'Completed',
            Completion_Date__c = Date.today()
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not mark this training as complete: ' + e.getMessage());
        }

        AuditService.log(
            'Training Completed',
            'Employee_Training__c',
            employeeTrainingId,
            'Employee marked a training assignment as complete on ' + Date.today().format() + '.'
        );
    }
}