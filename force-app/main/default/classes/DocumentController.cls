/**
 * DocumentController
 * Powers the Documents tab of the Employee mobile app.
 * Each Document__c record may have a Salesforce File (ContentVersion) attached to it.
 * We look that file up via ContentDocumentLink, which is the standard Salesforce
 * object that connects any record to any file attached to it.
 */
public with sharing class DocumentController {

    // A simple wrapper so the LWC gets the Document__c fields AND the file's
    // ContentVersion Id (needed to build the download link) in one response.
    public class DocumentWrapper {
        @AuraEnabled public Id documentId;
        @AuraEnabled public String documentName;
        @AuraEnabled public String documentType;
        @AuraEnabled public Datetime uploadDate;
        @AuraEnabled public Id contentVersionId; // null if no file has been attached yet
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getMyDocuments(Id employeeId) {
        List<Document__c> docs = [
            SELECT Id, Name, Category__c, Upload_Date__c
            FROM Document__c
            WHERE Uploaded_By__c = :employeeId
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
            w.documentType = d.Category__c;
            w.uploadDate = d.Upload_Date__c;
            w.contentVersionId = recordIdToContentVersionId.get(d.Id);
            results.add(w);
        }
        return results;
    }
}