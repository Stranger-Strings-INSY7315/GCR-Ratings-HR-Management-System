/**
 * TrainingAdminController
 * Powers Training Management on the HR/Admin portal:
 *   - creating and editing training courses
 *   - viewing and actioning (approve/reject) employee training requests
 *   - directly assigning a course to an employee (no request required)
 * Approving a request or directly assigning a course both create an
 * Employee_Training__c record, notify the employee, and write an audit
 * trail entry.
 */
public with sharing class TrainingAdminController {

    public class CourseWrapper {
        @AuraEnabled public Id courseId;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal durationHours;
        @AuraEnabled public String category;
        @AuraEnabled public Boolean isActive;
    }

    public class TrainingRequestWrapper {
        @AuraEnabled public Id requestId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String courseName;
        @AuraEnabled public String status;
        @AuraEnabled public Date requestDate;
        @AuraEnabled public String justification;
    }

    public class EmployeeOption {
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
    }

    public class CourseOption {
        @AuraEnabled public Id courseId;
        @AuraEnabled public String courseName;
    }

    // ---------- Course management ----------

    @AuraEnabled(cacheable=true)
    public static List<CourseWrapper> getAllCourses() {
        List<Training_Course__c> courses = [
            SELECT Id, Name, Description__c, Duration_Hours__c, Category__c, Is_Active__c
            FROM Training_Course__c
            WITH USER_MODE
            ORDER BY Category__c, Name
        ];

        List<CourseWrapper> results = new List<CourseWrapper>();
        for (Training_Course__c c : courses) {
            CourseWrapper w = new CourseWrapper();
            w.courseId = c.Id;
            w.name = c.Name;
            w.description = c.Description__c;
            w.durationHours = c.Duration_Hours__c;
            w.category = c.Category__c;
            w.isActive = c.Is_Active__c;
            results.add(w);
        }
        return results;
    }

    @AuraEnabled
    public static Id createCourse(String name, String description, Decimal durationHours, String category, Boolean isActive) {
        if (String.isBlank(name)) {
            throw new AuraHandledException('Please provide a course name.');
        }

        Training_Course__c newCourse = new Training_Course__c(
            Name = name,
            Description__c = description,
            Duration_Hours__c = durationHours,
            Category__c = category,
            Is_Active__c = isActive
        );

        try {
            insert as user newCourse;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not create this course: ' + e.getMessage());
        }

        AuditService.log(
            'Training Course Created',
            'Training_Course__c',
            newCourse.Id,
            'Course "' + name + '" was created.'
        );

        return newCourse.Id;
    }

    @AuraEnabled
    public static void updateCourse(Id courseId, String name, String description, Decimal durationHours, String category, Boolean isActive) {
        if (courseId == null) {
            throw new AuraHandledException('A course must be specified.');
        }
        if (String.isBlank(name)) {
            throw new AuraHandledException('Please provide a course name.');
        }

        Training_Course__c updateRecord = new Training_Course__c(
            Id = courseId,
            Name = name,
            Description__c = description,
            Duration_Hours__c = durationHours,
            Category__c = category,
            Is_Active__c = isActive
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not update this course: ' + e.getMessage());
        }

        AuditService.log(
            'Training Course Updated',
            'Training_Course__c',
            courseId,
            'Course "' + name + '" was updated.'
        );
    }

    // ---------- Training request approval ----------

    @AuraEnabled(cacheable=true)
    public static List<TrainingRequestWrapper> getAllTrainingRequests() {
        List<Training_Request__c> requests = [
            SELECT Id, Employee__r.First_Name__c, Employee__r.Last_Name__c,
                   Course__r.Name, Status__c, Request_Date__c, Justification__c
            FROM Training_Request__c
            WITH USER_MODE
            ORDER BY Request_Date__c DESC
        ];

        List<TrainingRequestWrapper> results = new List<TrainingRequestWrapper>();
        for (Training_Request__c r : requests) {
            TrainingRequestWrapper w = new TrainingRequestWrapper();
            w.requestId = r.Id;
            w.employeeName = r.Employee__r.First_Name__c + ' ' + r.Employee__r.Last_Name__c;
            w.courseName = r.Course__r.Name;
            w.status = r.Status__c;
            w.requestDate = r.Request_Date__c;
            w.justification = r.Justification__c;
            results.add(w);
        }
        return results;
    }

    @AuraEnabled
    public static void actionTrainingRequest(Id requestId, Boolean approve) {
        if (requestId == null) {
            throw new AuraHandledException('A training request must be specified.');
        }

        List<Training_Request__c> matches = [
            SELECT Id, Employee__c, Employee__r.Salesforce_User__c, Course__c, Course__r.Name, Status__c
            FROM Training_Request__c
            WHERE Id = :requestId
            WITH USER_MODE
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            throw new AuraHandledException('That training request could not be found.');
        }
        Training_Request__c req = matches[0];

        String newStatus = approve ? 'Approved' : 'Rejected';
        Training_Request__c updateRecord = new Training_Request__c(
            Id = req.Id,
            Status__c = newStatus
        );

        try {
            update as user updateRecord;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not update this request: ' + e.getMessage());
        }

        if (approve) {
            Employee_Training__c assignment = new Employee_Training__c(
                Employee__c = req.Employee__c,
                Course__c = req.Course__c,
                Status__c = 'Assigned',
                Assigned_Date__c = Date.today()
            );
            try {
                insert as user assignment;
            } catch (DmlException e) {
                throw new AuraHandledException('Request was approved, but the training could not be assigned: ' + e.getMessage());
            }
        }

        if (req.Employee__r.Salesforce_User__c != null) {
            String message = approve
                ? 'Your training request for "' + req.Course__r.Name + '" has been approved and assigned to you.'
                : 'Your training request for "' + req.Course__r.Name + '" has been rejected.';
            NotificationService.notify(req.Employee__r.Salesforce_User__c, message);
        }

        AuditService.log(
            approve ? 'Training Request Approved' : 'Training Request Rejected',
            'Training_Request__c',
            req.Id,
            'Training request for "' + req.Course__r.Name + '" was ' + newStatus.toLowerCase() + '.'
        );
    }

    // ---------- Direct assignment ----------

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
    public static List<CourseOption> getActiveCourseOptions() {
        List<Training_Course__c> courses = [
            SELECT Id, Name
            FROM Training_Course__c
            WHERE Is_Active__c = true
            WITH USER_MODE
            ORDER BY Name
        ];

        List<CourseOption> options = new List<CourseOption>();
        for (Training_Course__c c : courses) {
            CourseOption opt = new CourseOption();
            opt.courseId = c.Id;
            opt.courseName = c.Name;
            options.add(opt);
        }
        return options;
    }

    @AuraEnabled
    public static void assignTrainingDirectly(Id employeeId, Id courseId) {
        if (employeeId == null || courseId == null) {
            throw new AuraHandledException('Please select both an employee and a course.');
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

        List<Training_Course__c> courseMatches = [
            SELECT Id, Name
            FROM Training_Course__c
            WHERE Id = :courseId
            WITH USER_MODE
            LIMIT 1
        ];
        if (courseMatches.isEmpty()) {
            throw new AuraHandledException('That course could not be found.');
        }

        Employee_Training__c assignment = new Employee_Training__c(
            Employee__c = employeeId,
            Course__c = courseId,
            Status__c = 'Assigned',
            Assigned_Date__c = Date.today()
        );

        try {
            insert as user assignment;
        } catch (DmlException e) {
            throw new AuraHandledException('Could not assign this training: ' + e.getMessage());
        }

        if (matches[0].Salesforce_User__c != null) {
            NotificationService.notify(
                matches[0].Salesforce_User__c,
                'You have been assigned a new training course: "' + courseMatches[0].Name + '".'
            );
        }

        AuditService.log(
            'Training Assigned',
            'Employee_Training__c',
            assignment.Id,
            'Course "' + courseMatches[0].Name + '" was directly assigned by HR.'
        );
    }
}