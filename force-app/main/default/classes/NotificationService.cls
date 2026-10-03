/**
 * NotificationService
 * A small internal utility other controllers call to notify a user about
 * something that happened to them (their leave was approved, their review
 * was finalized, etc). Not exposed to the front end directly - it's used
 * server-side only, by other Apex classes.
 *
 * This class deliberately does NOT enforce the calling user's own object/
 * field permissions ("without sharing", plain DML). The person approving a
 * leave request or finalizing a review is creating a notification FOR
 * someone else, not for themselves - requiring every HR user to have
 * Create access on Notification just to approve leave would be an odd
 * permission to hand out. A failed notification should also never block
 * the real action (e.g. approving leave should still succeed even if, for
 * some reason, the notification couldn't be created), so errors here are
 * logged rather than thrown.
 */
public without sharing class NotificationService {

    public static void notify(Id userId, String message) {
        if (userId == null || String.isBlank(message)) {
            return;
        }

        Notification__c note = new Notification__c(
            User__c = userId,
            Message__c = message,
            Sent_Date__c = Datetime.now(),
            Is_Read__c = false
        );

        try {
            insert note;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'NotificationService could not create notification: ' + e.getMessage());
        }
    }
}