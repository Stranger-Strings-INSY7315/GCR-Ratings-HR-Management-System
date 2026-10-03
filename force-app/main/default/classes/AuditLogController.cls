/**
 * AuditLogController
 * Read-only access to the audit trail for the HR/Admin portal.
 * Unlike AuditService (which writes on behalf of any user and bypasses
 * FLS by design), this controller is exposed to the UI and enforces FLS
 * normally, since it only ever reads data back for an HR user to view.
 */
public with sharing class AuditLogController {

    public class AuditLogWrapper {
        @AuraEnabled public Id auditLogId;
        @AuraEnabled public String userName;
        @AuraEnabled public String action;
        @AuraEnabled public String objectType;
        @AuraEnabled public String recordId;
        @AuraEnabled public String details;
        @AuraEnabled public Datetime timestampValue;
    }

    @AuraEnabled(cacheable=true)
    public static List<AuditLogWrapper> getAllAuditLogs() {
        List<Audit_Log__c> logs = [
            SELECT Id, User__r.Name, Action__c, Object_Type__c, Record_Id__c,
                   Details__c, Timestamp__c
            FROM Audit_Log__c
            WITH USER_MODE
            ORDER BY Timestamp__c DESC
            LIMIT 200
        ];

        List<AuditLogWrapper> results = new List<AuditLogWrapper>();
        for (Audit_Log__c log : logs) {
            AuditLogWrapper w = new AuditLogWrapper();
            w.auditLogId = log.Id;
            w.userName = log.User__c != null ? log.User__r.Name : 'Unknown';
            w.action = log.Action__c;
            w.objectType = log.Object_Type__c;
            w.recordId = log.Record_Id__c;
            w.details = log.Details__c;
            w.timestampValue = log.Timestamp__c;
            results.add(w);
        }
        return results;
    }
}