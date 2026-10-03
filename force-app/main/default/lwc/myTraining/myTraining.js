import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCurrentEmployee from '@salesforce/apex/TrainingController.getCurrentEmployee';
import getMyTrainings from '@salesforce/apex/TrainingController.getMyTrainings';
import getAvailableCourses from '@salesforce/apex/TrainingController.getAvailableCourses';
import getMyTrainingRequests from '@salesforce/apex/TrainingController.getMyTrainingRequests';
import submitTrainingRequest from '@salesforce/apex/TrainingController.submitTrainingRequest';
import markTrainingComplete from '@salesforce/apex/TrainingController.markTrainingComplete';

export default class MyTraining extends LightningElement {
    employeeId;
    myTrainings = [];
    courseOptions = [];
    myRequests = [];
    wiredMyTrainingsResult;

    selectedCourseId;
    reason = '';
    isSaving = false;

    @wire(getCurrentEmployee)
    wiredEmployee({ data, error }) {
        if (data) {
            this.employeeId = data.Id;
        } else if (error) {
            this.showError('Could not load your employee record', error);
        }
    }

    @wire(getMyTrainings, { employeeId: '$employeeId' })
    wiredMyTrainings(result) {
        this.wiredMyTrainingsResult = result;
        if (result.data) {
            this.myTrainings = result.data.map((row) => ({
                id: row.Id,
                courseName: row.Course__r ? row.Course__r.Name : '',
                hours: row.Course__r ? row.Course__r.Duration_Hours__c : 0,
                status: row.Status__c,
                assignedDate: row.Assigned_Date__c,
                completionDate: row.Completion_Date__c,
                canMarkComplete: row.Status__c === 'Assigned' || row.Status__c === 'In Progress',
            }));
        } else if (result.error) {
            this.showError('Could not load your training history', result.error);
        }
    }

    @wire(getAvailableCourses)
    wiredCourses({ data, error }) {
        if (data) {
            this.courseOptions = data.map((course) => ({
                label: course.Name + ' (' + course.Duration_Hours__c + 'h - ' + course.Category__c + ')',
                value: course.Id,
            }));
        } else if (error) {
            this.showError('Could not load available courses', error);
        }
    }

    @wire(getMyTrainingRequests, { employeeId: '$employeeId' })
    wiredRequests({ data, error }) {
        if (data) {
            this.myRequests = data.map((row) => ({
                id: row.Id,
                courseName: row.Course__r ? row.Course__r.Name : '',
                status: row.Status__c,
                requestDate: row.Request_Date__c,
                reason: row.Justification__c,
            }));
        } else if (error) {
            this.showError('Could not load your training requests', error);
        }
    }

    handleCourseChange(event) {
        this.selectedCourseId = event.detail.value;
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    get isSubmitDisabled() {
        return this.isSaving || !this.selectedCourseId;
    }

    async handleSubmit() {
        this.isSaving = true;
        try {
            await submitTrainingRequest({
                employeeId: this.employeeId,
                courseId: this.selectedCourseId,
                reason: this.reason,
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Request submitted',
                    message: 'Your training request has been sent for review.',
                    variant: 'success',
                })
            );
            this.selectedCourseId = undefined;
            this.reason = '';
        } catch (error) {
            this.showError('Could not submit your request', error);
        } finally {
            this.isSaving = false;
        }
    }

    async handleMarkComplete(event) {
        const employeeTrainingId = event.target.dataset.id;
        try {
            await markTrainingComplete({ employeeTrainingId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Training marked complete',
                    message: 'Your record has been updated.',
                    variant: 'success',
                })
            );
            await refreshApex(this.wiredMyTrainingsResult);
        } catch (error) {
            this.showError('Could not mark this training as complete', error);
        }
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}