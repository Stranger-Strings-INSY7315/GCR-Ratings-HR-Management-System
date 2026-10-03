@isTest
private class NotificationServiceTest {

    @isTest
    static void testNotifyCreatesNotification() {
        Test.startTest();
        NotificationService.notify(UserInfo.getUserId(), 'Your leave request has been approved.');
        Test.stopTest();

        List<Notification__c> notes = [SELECT Message__c, Is_Read__c, User__c FROM Notification__c];
        System.assertEquals(1, notes.size(), 'A notification should have been created');
        System.assertEquals('Your leave request has been approved.', notes[0].Message__c, 'Message should match');
        System.assertEquals(false, notes[0].Is_Read__c, 'A new notification should start unread');
        System.assertEquals(UserInfo.getUserId(), notes[0].User__c, 'Notification should be linked to the given user');
    }

    @isTest
    static void testNotifyWithNullUserDoesNothing() {
        Test.startTest();
        NotificationService.notify(null, 'This should not be saved.');
        Test.stopTest();

        List<Notification__c> notes = [SELECT Id FROM Notification__c];
        System.assertEquals(0, notes.size(), 'No notification should be created without a user');
    }

    @isTest
    static void testNotifyWithBlankMessageDoesNothing() {
        Test.startTest();
        NotificationService.notify(UserInfo.getUserId(), '');
        Test.stopTest();

        List<Notification__c> notes = [SELECT Id FROM Notification__c];
        System.assertEquals(0, notes.size(), 'No notification should be created without a message');
    }
}