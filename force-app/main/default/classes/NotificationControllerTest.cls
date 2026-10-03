@isTest
private class NotificationControllerTest {

    @testSetup
    static void setup() {
        Notification__c note = new Notification__c(
            User__c = UserInfo.getUserId(),
            Message__c = 'Your performance review has been finalized.',
            Sent_Date__c = Datetime.now(),
            Is_Read__c = false
        );
        insert note;
    }

    @isTest
    static void testGetMyNotifications() {
        Test.startTest();
        List<NotificationController.NotificationWrapper> results = NotificationController.getMyNotifications();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the one notification created in setup');
        System.assertEquals(false, results[0].isRead, 'Notification should start unread');
    }

    @isTest
    static void testGetUnreadCount() {
        Test.startTest();
        Integer count = NotificationController.getUnreadCount();
        Test.stopTest();

        System.assertEquals(1, count, 'Should count the one unread notification');
    }

    @isTest
    static void testMarkAsRead() {
        Notification__c note = [SELECT Id FROM Notification__c LIMIT 1];

        Test.startTest();
        NotificationController.markAsRead(note.Id);
        Test.stopTest();

        Notification__c updated = [SELECT Is_Read__c FROM Notification__c WHERE Id = :note.Id];
        System.assertEquals(true, updated.Is_Read__c, 'Notification should now be marked as read');
    }

    @isTest
    static void testMarkAsReadMissingId() {
        Boolean errorThrown = false;
        try {
            NotificationController.markAsRead(null);
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when no notification id is given');
    }
}