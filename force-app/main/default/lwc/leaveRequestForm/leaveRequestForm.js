import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentEmployee from '@salesforce/apex/EmployeeController.getCurrentEmployee';
import getActiveLeaveTypes from '@salesforce/apex/EmployeeController.getActiveLeaveTypes';
import submitLeaveRequest from '@salesforce/apex/EmployeeController.submitLeaveRequest';

export default class LeaveRequestForm extends LightningElement {
    employeeId;
    leaveTypeOptions = [];
    selectedLeaveTypeId;
    startDate;
    endDate;
    reason = '';
    isSubmitting = false;

    @wire(getCurrentEmployee)
    wiredEmployee({ data }) {
        if (data) {
            this.employeeId = data.Id;
        }
    }

    @wire(getActiveLeaveTypes)
    wiredLeaveTypes({ data }) {
        if (data) {
            this.leaveTypeOptions = data.map((lt) => ({ label: lt.Name, value: lt.Id }));
        }
    }

    handleLeaveTypeChange(event) {
        this.selectedLeaveTypeId = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.detail.value;
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    handleSubmit() {
        if (!this.selectedLeaveTypeId || !this.startDate || !this.endDate) {
            this.showToast('Missing information', 'Please fill in leave type, start date and end date.', 'error');
            return;
        }

        this.isSubmitting = true;
        submitLeaveRequest({
            employeeId: this.employeeId,
            leaveTypeId: this.selectedLeaveTypeId,
            startDate: this.startDate,
            endDate: this.endDate,
            reason: this.reason
        })
            .then(() => {
                this.showToast('Success', 'Your leave request has been submitted.', 'success');
                this.resetForm();
                this.dispatchEvent(new CustomEvent('leavesubmitted'));
            })
            .catch((error) => {
                const message = error.body ? error.body.message : 'Something went wrong submitting your request.';
                this.showToast('Error submitting request', message, 'error');
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    resetForm() {
        this.selectedLeaveTypeId = undefined;
        this.startDate = undefined;
        this.endDate = undefined;
        this.reason = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}