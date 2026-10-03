/**
 * PerformanceReviewController
 * Powers Performance Reviews on both sides of the system:
 *   - Employee app: the employee's own finalized reviews (read-only)
 *   - HR/Admin portal: create, edit (while still a draft), and finalize reviews
 *
 * A review starts life as a Draft so an HR manager can write it over time
 * without the employee seeing an unfinished review. Finalizing it is what
 * makes it visible on the employee's side.
 */
public with sharing class PerformanceReviewController {

    // Wrapper so both the employee view and the HR view get exactly the
    // fields they need, including names that live on related records.
    public class ReviewWrapper {
        @AuraEnabled public Id reviewId;
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public Id reviewerId;
        @AuraEnabled public String reviewerName;
        @AuraEnabled public Date reviewDate;
        @AuraEnabled public Decimal rating;
        @AuraEnabled public String comments;
        @AuraEnabled public String status;
    }

    // Simple id/name pair, used to populate the "which employee is this
    // review for" picklist on the HR side.
    public class EmployeeOption {
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
    }

    // ---------- Employee self-view ----------

    @AuraEnabled(cacheable=true)
    public static List<ReviewWrapper> getMyReviews() {
        Id myEmployeeId = getCurrentEmployeeId();

        List<Performance_Review__c> reviews = [
            SELECT Id, Employee__c, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Reviewer__c, Reviewer__r.First_Name__c, Reviewer__r.Last_Name__c,
                   Review_Date__c, Rating__c, Comments__c, Status__c
            FROM Performance_Review__c
            WHERE Employee__c = :myEmployeeId
              AND Status__c = 'Finalized'
            WITH USER_MODE
            ORDER BY Review_Date__c DESC
        ];

        return wrapRecords(reviews);
    }

    // ---------- HR / Manager view ----------

    @AuraEnabled(cacheable=true)
    public static List<ReviewWrapper> getAllReviews() {
        List<Performance_Review__c> reviews = [
            SELECT Id, Employee__c, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Reviewer__c, Reviewer__r.First_Name__c, Reviewer__r.Last_Name__c,
                   Review_Date__c, Rating__c, Comments__c, Status__c
            FROM Performance_Review__c
            WITH USER_MODE
            ORDER BY Review_Date__c DESC
        ];

        return wrapRecords(reviews);
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

    @AuraEnabled
    public static Id createReview(Id employeeId, Date reviewDate, Decimal rating, String comments) {
        if (employeeId == null) {
            throw new AuraHandledException('Please select which employee this review is for.');
        }
        if (reviewDate == null) {
            throw new AuraHandledException('Please choose a review date.');
        }

        Id myEmployeeId = getCurrentEmployeeId();

        Performance_Review__c newReview = new Performance_Review__c(
            Employee__c = employeeId,
            Reviewer__c = myEmployeeId,
            Review_Date__c = reviewDate,
            Rating__c = rating,
            Comments__c = comments,
            Status__c = 'Draft'
        );

        try {
            insert as user newReview;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not create this review: ' + e.getMessage());
        }

        return newReview.Id;
    }

    @AuraEnabled
    public static void updateReview(Id reviewId, Date reviewDate, Decimal rating, String comments) {
        if (reviewId == null) {
            throw new AuraHandledException('A review must be specified.');
        }

        // Minimal record: only the fields being changed. Employee__c is a
        // master-detail field and can never be edited through "as user" DML,
        // even when its value isn't changing - see LeaveApprovalController
        // for the same lesson learned there.
        Performance_Review__c updateRecord = new Performance_Review__c(
            Id = reviewId,
            Review_Date__c = reviewDate,
            Rating__c = rating,
            Comments__c = comments
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not update this review: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void finalizeReview(Id reviewId) {
        if (reviewId == null) {
            throw new AuraHandledException('A review must be specified.');
        }

        Performance_Review__c updateRecord = new Performance_Review__c(
            Id = reviewId,
            Status__c = 'Finalized'
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not finalize this review: ' + e.getMessage());
        }
    }

    // ---------- Shared helper ----------

    private static List<ReviewWrapper> wrapRecords(List<Performance_Review__c> reviews) {
        List<ReviewWrapper> results = new List<ReviewWrapper>();
        for (Performance_Review__c pr : reviews) {
            ReviewWrapper w = new ReviewWrapper();
            w.reviewId = pr.Id;
            w.employeeId = pr.Employee__c;
            w.employeeName = pr.Employee__r.First_Name__c + ' ' + pr.Employee__r.Last_Name__c;
            w.reviewerId = pr.Reviewer__c;
            w.reviewerName = pr.Reviewer__c != null
                ? pr.Reviewer__r.First_Name__c + ' ' + pr.Reviewer__r.Last_Name__c
                : null;
            w.reviewDate = pr.Review_Date__c;
            w.rating = pr.Rating__c;
            w.comments = pr.Comments__c;
            w.status = pr.Status__c;
            results.add(w);
        }
        return results;
    }

    // Looks up the Employee__c record linked to whoever is currently logged
    // in - used both to find "my reviews" and to record who conducted one.
    private static Id getCurrentEmployeeId() {
        List<Employee__c> emps = [
            SELECT Id
            FROM Employee__c
            WHERE Salesforce_User__c = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (emps.isEmpty()) {
            throw new AuraHandledException('No Employee record is linked to your login. Please contact an administrator.');
        }
        return emps[0].Id;
    }
}