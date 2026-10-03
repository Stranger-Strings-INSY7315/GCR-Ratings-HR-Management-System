import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAllTrainingRequests from '@salesforce/apex/TrainingAdminController.getAllTrainingRequests';
import actionTrainingRequest from '@salesforce/apex/TrainingAdminController.actionTrainingRequest';
import getEmployeeOptions from '@salesforce/apex/TrainingAdminController.getEmployeeOptions';
import getActiveCourseOptions from '@salesforce/apex/TrainingAdminController.getActiveCourseOptions';
import assignTrainingDirectly from '@salesforce/apex/TrainingAdminController.assignTrainingDirectly';

export default class TrainingRequestManager extends LightningElement {
    requests = [];
    wiredRequestsResult;
    employeeOptions = [];
    courseOptions = [];

    selectedEmployeeId;
    selectedCourseId;
    isAssigning = false;

    @wire(getAllTrainingRequests)
    wiredRequests(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.requests = result.data.map((r) => ({
                id: r.requestId,
                employeeName: r.employeeName,
                courseName: r.courseName,
                status: r.status,
                requestDate: r.requestDate,
                justification: r.justification,
                isPending: r.status === 'Submitted',
                badgeClass: this.getBadgeClass(r.status),
            }));
        } else if (result.error) {
            this.showError('Could not load training requests', result.error);
        }
    }

    @wire(getEmployeeOptions)
    wiredEmployees({ data, error }) {
        if (data) {
            this.employeeOptions = data.map((e) => ({ label: e.employeeName, value: e.employeeId }));
        } else if (error) {
            this.showError('Could not load employees', error);
        }
    }

    @wire(getActiveCourseOptions)
    wiredCourses({ data, error }) {
        if (data) {
            this.courseOptions = data.map((c) => ({ label: c.courseName, value: c.courseId }));
        } else if (error) {
            this.showError('Could not load courses', error);
        }
    }

    getBadgeClass(status) {
        if (status === 'Approved') {
            return 'slds-badge slds-theme_success';
        }
        if (status === 'Rejected') {
            return 'slds-badge slds-theme_error';
        }
        return 'slds-badge slds-theme_warning';
    }

    handleEmployeeChange(event) {
        this.selectedEmployeeId = event.detail.value;
    }

    handleCourseChange(event) {
        this.selectedCourseId = event.detail.value;
    }

    get isAssignDisabled() {
        return this.isAssigning || !this.selectedEmployeeId || !this.selectedCourseId;
    }

    async handleApprove(event) {
        await this.handleAction(event.target.dataset.id, true);
    }

    async handleReject(event) {
        await this.handleAction(event.target.dataset.id, false);
    }

    async handleAction(requestId, approve) {
        try {
            await actionTrainingRequest({ requestId, approve });
            this.showToast(
                approve ? 'Request approved' : 'Request rejected',
                approve ? 'The employee has been assigned this training.' : 'The employee has been notified.',
                'success'
            );
            await refreshApex(this.wiredRequestsResult);
        } catch (error) {
            this.showError('Could not update this request', error);
        }
    }

    async handleAssignDirectly() {
        this.isAssigning = true;
        try {
            await assignTrainingDirectly({
                employeeId: this.selectedEmployeeId,
                courseId: this.selectedCourseId,
            });
            this.showToast('Training assigned', 'The employee has been assigned this course.', 'success');
            this.selectedEmployeeId = undefined;
            this.selectedCourseId = undefined;
        } catch (error) {
            this.showError('Could not assign this training', error);
        } finally {
            this.isAssigning = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.showToast(title, message, 'error');
    }
}