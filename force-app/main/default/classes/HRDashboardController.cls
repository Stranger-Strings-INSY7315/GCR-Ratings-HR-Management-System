public with sharing class HRDashboardController {

    public class DashboardStats {
        @AuraEnabled public Integer totalEmployees;
        @AuraEnabled public Integer activeEmployees;

        @AuraEnabled public Integer totalLeaveRequests;
        @AuraEnabled public Integer pendingLeaveRequests;
        @AuraEnabled public Integer approvedLeaveRequests;
        @AuraEnabled public Integer rejectedLeaveRequests;

        @AuraEnabled public Integer totalTrainingAssignments;
        @AuraEnabled public Integer assignedTraining;
        @AuraEnabled public Integer inProgressTraining;
        @AuraEnabled public Integer completedTraining;
        @AuraEnabled public Integer overdueTraining;
        @AuraEnabled public Decimal trainingCompletionRate;

        @AuraEnabled public Integer totalReviews;
        @AuraEnabled public Integer finalizedReviews;
        @AuraEnabled public Decimal averageRating;

        @AuraEnabled public Integer attendanceRecordsThisMonth;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();

        // ===== Employee stats =====
        List<AggregateResult> empResults = [
            SELECT Status__c statusValue, COUNT(Id) total
            FROM Employee__c
            WITH USER_MODE
            GROUP BY Status__c
        ];
        Integer totalEmp = 0;
        Integer activeEmp = 0;
        for (AggregateResult ar : empResults) {
            String status = (String) ar.get('statusValue');
            Integer cnt = (Integer) ar.get('total');
            totalEmp += cnt;
            if (status == 'Active') {
                activeEmp = cnt;
            }
        }
        stats.totalEmployees = totalEmp;
        stats.activeEmployees = activeEmp;

        // ===== Leave stats =====
        List<AggregateResult> leaveResults = [
            SELECT Status__c statusValue, COUNT(Id) total
            FROM Leave__c
            WITH USER_MODE
            GROUP BY Status__c
        ];
        Integer totalLeave = 0;
        Integer pendingLeave = 0;
        Integer approvedLeave = 0;
        Integer rejectedLeave = 0;
        for (AggregateResult ar : leaveResults) {
            String status = (String) ar.get('statusValue');
            Integer cnt = (Integer) ar.get('total');
            totalLeave += cnt;
            if (status == 'Submitted' || status == 'Under Review' || status == 'Info Requested') {
                pendingLeave += cnt;
            } else if (status == 'Approved' || status == 'Active' || status == 'Completed') {
                approvedLeave += cnt;
            } else if (status == 'Rejected') {
                rejectedLeave += cnt;
            }
        }
        stats.totalLeaveRequests = totalLeave;
        stats.pendingLeaveRequests = pendingLeave;
        stats.approvedLeaveRequests = approvedLeave;
        stats.rejectedLeaveRequests = rejectedLeave;

        // ===== Training stats =====
        List<AggregateResult> trainingResults = [
            SELECT Status__c statusValue, COUNT(Id) total
            FROM Employee_Training__c
            WITH USER_MODE
            GROUP BY Status__c
        ];
        Integer totalTraining = 0;
        Integer assignedTraining = 0;
        Integer inProgressTraining = 0;
        Integer completedTraining = 0;
        Integer overdueTraining = 0;
        for (AggregateResult ar : trainingResults) {
            String status = (String) ar.get('statusValue');
            Integer cnt = (Integer) ar.get('total');
            totalTraining += cnt;
            if (status == 'Assigned') {
                assignedTraining = cnt;
            } else if (status == 'In Progress') {
                inProgressTraining = cnt;
            } else if (status == 'Completed') {
                completedTraining = cnt;
            } else if (status == 'Overdue') {
                overdueTraining = cnt;
            }
        }
        stats.totalTrainingAssignments = totalTraining;
        stats.assignedTraining = assignedTraining;
        stats.inProgressTraining = inProgressTraining;
        stats.completedTraining = completedTraining;
        stats.overdueTraining = overdueTraining;
        stats.trainingCompletionRate = totalTraining > 0
            ? ((Decimal) completedTraining / (Decimal) totalTraining * 100).setScale(1)
            : 0;

        // ===== Performance review stats =====
        List<AggregateResult> reviewResults = [
            SELECT Status__c statusValue, COUNT(Id) total, AVG(Rating__c) avgRating
            FROM Performance_Review__c
            WITH USER_MODE
            GROUP BY Status__c
        ];
        Integer totalReviews = 0;
        Integer finalizedReviews = 0;
        Decimal avgRating = 0;
        for (AggregateResult ar : reviewResults) {
            String status = (String) ar.get('statusValue');
            Integer cnt = (Integer) ar.get('total');
            totalReviews += cnt;
            if (status == 'Finalized') {
                finalizedReviews = cnt;
                Double avg = (Double) ar.get('avgRating');
                avgRating = avg != null ? Decimal.valueOf(avg).setScale(1) : 0;
            }
        }
        stats.totalReviews = totalReviews;
        stats.finalizedReviews = finalizedReviews;
        stats.averageRating = avgRating;

        // ===== Attendance stats =====
        Date today = Date.today();
        Date monthStart = Date.newInstance(today.year(), today.month(), 1);

        stats.attendanceRecordsThisMonth = [
            SELECT COUNT()
            FROM Attendance__c
            WHERE Attendance_Date__c >= :monthStart
            WITH USER_MODE
        ];

        return stats;
    }
}