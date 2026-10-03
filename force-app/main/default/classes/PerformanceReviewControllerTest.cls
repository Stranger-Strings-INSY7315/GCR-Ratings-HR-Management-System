@isTest
private class PerformanceReviewControllerTest {

    // One employee plays double duty as both "the logged-in user" (so
    // getCurrentEmployeeId() resolves) and the reviewer on records they
    // create - same approach used in LeaveApprovalControllerTest.
    // A second employee is the one being reviewed.
    @testSetup
    static void setup() {
        Employee__c reviewer = new Employee__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Manager',
            Email__c = 'test.manager@example.com',
            Hire_Date__c = Date.today(),
            Status__c = 'Active',
            Salesforce_User__c = UserInfo.getUserId()
        );
        insert reviewer;

        Employee__c reviewee = new Employee__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Employee',
            Email__c = 'test.employee@example.com',
            Hire_Date__c = Date.today(),
            Status__c = 'Active'
        );
        insert reviewee;

        // A finalized review for the employee (should show up in their self-view)
        Performance_Review__c finalizedReview = new Performance_Review__c(
            Employee__c = reviewee.Id,
            Reviewer__c = reviewer.Id,
            Review_Date__c = Date.today().addDays(-30),
            Rating__c = 4,
            Comments__c = 'Solid quarter overall.',
            Status__c = 'Finalized'
        );
        insert finalizedReview;

        // A draft review (should NOT show up in the employee's self-view)
        Performance_Review__c draftReview = new Performance_Review__c(
            Employee__c = reviewee.Id,
            Reviewer__c = reviewer.Id,
            Review_Date__c = Date.today(),
            Rating__c = 3,
            Comments__c = 'Still being written.',
            Status__c = 'Draft'
        );
        insert draftReview;
    }

    @isTest
    static void testGetAllReviews() {
        Test.startTest();
        List<PerformanceReviewController.ReviewWrapper> results = PerformanceReviewController.getAllReviews();
        Test.stopTest();

        System.assertEquals(2, results.size(), 'HR view should see both the draft and the finalized review');
    }

    @isTest
    static void testGetEmployeeOptions() {
        Test.startTest();
        List<PerformanceReviewController.EmployeeOption> options = PerformanceReviewController.getEmployeeOptions();
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Should return both employees created in setup');
    }

    @isTest
    static void testCreateReview() {
        Employee__c reviewee = [SELECT Id FROM Employee__c WHERE Last_Name__c = 'Employee' LIMIT 1];

        Test.startTest();
        Id newReviewId = PerformanceReviewController.createReview(reviewee.Id, Date.today(), 5, 'Excellent progress this cycle.');
        Test.stopTest();

        Performance_Review__c created = [
            SELECT Status__c, Rating__c, Comments__c, Employee__c, Reviewer__c
            FROM Performance_Review__c
            WHERE Id = :newReviewId
        ];
        System.assertEquals('Draft', created.Status__c, 'A newly created review should start as Draft');
        System.assertEquals(5, created.Rating__c, 'Rating should be saved');
        System.assertEquals(reviewee.Id, created.Employee__c, 'Should be linked to the selected employee');
        System.assertNotEquals(null, created.Reviewer__c, 'Reviewer should be set to the current user\'s employee record');
    }

    @isTest
    static void testCreateReviewMissingEmployee() {
        Boolean errorThrown = false;
        try {
            PerformanceReviewController.createReview(null, Date.today(), 4, 'Test comment');
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown, 'Should throw when no employee is specified');
    }

    @isTest
    static void testUpdateReview() {
        Performance_Review__c draft = [SELECT Id FROM Performance_Review__c WHERE Status__c = 'Draft' LIMIT 1];

        Test.startTest();
        PerformanceReviewController.updateReview(draft.Id, Date.today(), 2, 'Updated comments after a follow-up discussion.');
        Test.stopTest();

        Performance_Review__c updated = [SELECT Rating__c, Comments__c, Status__c FROM Performance_Review__c WHERE Id = :draft.Id];
        System.assertEquals(2, updated.Rating__c, 'Rating should be updated');
        System.assertEquals('Updated comments after a follow-up discussion.', updated.Comments__c, 'Comments should be updated');
        System.assertEquals('Draft', updated.Status__c, 'Updating should not change the status');
    }

    @isTest
    static void testFinalizeReview() {
        Performance_Review__c draft = [SELECT Id FROM Performance_Review__c WHERE Status__c = 'Draft' LIMIT 1];

        Test.startTest();
        PerformanceReviewController.finalizeReview(draft.Id);
        Test.stopTest();

        Performance_Review__c updated = [SELECT Status__c FROM Performance_Review__c WHERE Id = :draft.Id];
        System.assertEquals('Finalized', updated.Status__c, 'Review should now be Finalized');
    }

    @isTest
    static void testGetMyReviews() {
        Test.startTest();
        List<PerformanceReviewController.ReviewWrapper> results = PerformanceReviewController.getMyReviews();
        Test.stopTest();

        // getCurrentEmployeeId() resolves to the "Test Manager" record (the
        // one linked to the running user), who has no reviews of their own
        // in this data set - so this should come back empty. This confirms
        // the Draft/Finalized filtering logic runs without error.
        System.assertEquals(0, results.size(), 'The running user has no performance reviews of their own in this data set');
    }
}