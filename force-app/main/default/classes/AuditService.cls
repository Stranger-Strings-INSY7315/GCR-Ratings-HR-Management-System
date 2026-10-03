/**
 * AuditService
 * Internal trusted utility for writing Audit_Log__c records.
 * Deliberately "without sharing" with plain DML (not "as user"), because this
 * service logs actions on behalf of whichever user performed them, and we do
 * not want to require every caller to have Create access on Audit_Log__c.
 * Any failure here is logged but never thrown, so a failed audit write can
 * never block the real business transaction it is recording.
 */
public without sharing class AuditService {

    public static void log(String action, String objectType, Id recordId, String details) {
        if (String.isBlank(action) || String.isBlank(objectType)) {
            return;
        }

        Audit_Log__c entry = new Audit_Log__c(
            Action__c = action,
            Object_Type__c = objectType,
            Record_Id__c = recordId,
            Details__c = details,
            Timestamp__c = Datetime.now(),
            User__c = UserInfo.getUserId()
        );

        try {
            insert entry;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'AuditService could not create audit log entry: ' + e.getMessage());
        }
    }
}