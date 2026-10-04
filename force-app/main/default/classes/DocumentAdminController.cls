/**
 * DocumentAdminController
 * Powers Document Management on the HR/Admin portal:
 *   - viewing all documents uploaded for any employee
 *   - creating a new Document__c record for an employee (the actual file
 *     is then attached separately via the standard Salesforce file upload
 *     component, bound to the new record's Id)
 * Each Document__c record may have a Salesforce File (ContentVersion)
 * attached to it, looked up the same way DocumentController does for the
 * employee-facing view.
 */
public with sharing class DocumentAdminController {

    public class DocumentWrapper {
        @AuraEnabled public Id documentId;
        @AuraEnabled public String documentName;
        @AuraEnabled public String category;
        @AuraEnabled public String employeeName;
        @AuraEnabled public Datetime uploadDate;
        @AuraEnabled public Id contentVersionId; // null if no file has been attached yet
    }

    public class EmployeeOption {
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
    }

    @AuraEnabled(cacheable=true)
    public static List<EmployeeOption> getEmployeeOptions() {
        List<Employee__c> emps = [
            SELECT Id, First_Name__c, Last_Name__c
            FROM Employee__c
            WITH USER_MODE
            ORDER BY Last_Name__c ASC, First_Name__c ASC
        ];

        List<EmployeeOption> options = new List<EmployeeOption>();
        for (Employee__c emp : emps) {
            EmployeeOption opt = new EmployeeOption();
            opt.employeeId = emp.Id;
            opt.employeeName = emp.First_Name__c + ' ' + emp.Last_Name__c;
            options.add(opt);
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getAllDocuments() {
        List<Document__c> docs = [
            SELECT Id, Name, Category__c, Upload_Date__c,
                   Uploaded_By__r.First_Name__c, Uploaded_By__r.Last_Name__c
            FROM Document__c
            WITH USER_MODE
            ORDER BY Upload_Date__c DESC
        ];

        Set<Id> docIds = new Set<Id>();
        for (Document__c d : docs) {
            docIds.add(d.Id);
        }

        Map<Id, Id> recordIdToContentVersionId = new Map<Id, Id>();
        if (!docIds.isEmpty()) {
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :docIds
                WITH USER_MODE
            ];
            for (ContentDocumentLink link : links) {
                recordIdToContentVersionId.put(link.LinkedEntityId, link.ContentDocument.LatestPublishedVersionId);
            }
        }

        List<DocumentWrapper> results = new List<DocumentWrapper>();
        for (Document__c d : docs) {
            DocumentWrapper w = new DocumentWrapper();
            w.documentId = d.Id;
            w.documentName = d.Name;
            w.category = d.Category__c;
            w.employeeName = d.Uploaded_By__r != null
                ? d.Uploaded_By__r.First_Name__c + ' ' + d.Uploaded_By__r.Last_Name__c
                : 'Unknown';
            w.uploadDate = d.Upload_Date__c;
            w.contentVersionId = recordIdToContentVersionId.get(d.Id);
            results.add(w);
        }
        return results;
    }

    @AuraEnabled
    public static Id createDocumentRecord(Id employeeId, String documentName, String category) {
        if (employeeId == null) {
            throw new AuraHandledException('Please select an employee.');
        }
        if (String.isBlank(documentName)) {
            throw new AuraHandledException('Please provide a document name.');
        }

        List<Employee__c> matches = [
            SELECT Id, Salesforce_User__c
            FROM Employee__c
            WHERE Id = :employeeId
            WITH USER_MODE
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            throw new AuraHandledException('That employee could not be found.');
        }

        Document__c newDoc = new Document__c();
        newDoc.Name = documentName;
        newDoc.Category__c = category;
        newDoc.Uploaded_By__c = employeeId;
        newDoc.Upload_Date__c = Datetime.now();

        try {
            insert as user newDoc;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not create this document record: ' + e.getMessage());
        }

        if (matches[0].Salesforce_User__c != null) {
            NotificationService.notify(
                matches[0].Salesforce_User__c,
                'A new document, "' + documentName + '", has been added to your HR documents.'
            );
        }

        AuditService.log(
            'Document Uploaded',
            'Document__c',
            newDoc.Id,
            'Document "' + documentName + '" (' + category + ') was uploaded by HR.'
        );

        return newDoc.Id;
    }
}