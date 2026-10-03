/**
 * NotificationController
 * Powers the employee-facing notification list: viewing your own
 * notifications and marking them as read.
 */
public with sharing class NotificationController {

    public class NotificationWrapper {
        @AuraEnabled public Id notificationId;
        @AuraEnabled public String message;
        @AuraEnabled public Datetime sentDate;
        @AuraEnabled public Boolean isRead;
    }

    @AuraEnabled(cacheable=true)
    public static List<NotificationWrapper> getMyNotifications() {
        List<Notification__c> notes = [
            SELECT Id, Message__c, Sent_Date__c, Is_Read__c
            FROM Notification__c
            WHERE User__c = :UserInfo.getUserId()
            WITH USER_MODE
            ORDER BY Sent_Date__c DESC
            LIMIT 20
        ];

        List<NotificationWrapper> results = new List<NotificationWrapper>();
        for (Notification__c n : notes) {
            NotificationWrapper w = new NotificationWrapper();
            w.notificationId = n.Id;
            w.message = n.Message__c;
            w.sentDate = n.Sent_Date__c;
            w.isRead = n.Is_Read__c;
            results.add(w);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getUnreadCount() {
        return [
            SELECT COUNT()
            FROM Notification__c
            WHERE User__c = :UserInfo.getUserId()
              AND Is_Read__c = false
            WITH USER_MODE
        ];
    }

    @AuraEnabled
    public static void markAsRead(Id notificationId) {
        if (notificationId == null) {
            throw new AuraHandledException('A notification must be specified.');
        }

        Notification__c updateRecord = new Notification__c(
            Id = notificationId,
            Is_Read__c = true
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not mark this notification as read: ' + e.getMessage());
        }
    }
}