import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getTodayStatus from '@salesforce/apex/AttendanceController.getTodayStatus';
import getMyAttendanceHistory from '@salesforce/apex/AttendanceController.getMyAttendanceHistory';
import clockIn from '@salesforce/apex/AttendanceController.clockIn';
import clockOut from '@salesforce/apex/AttendanceController.clockOut';

export default class MyAttendance extends LightningElement {
    todayStatus;
    wiredStatusResult;

    history = [];
    wiredHistoryResult;

    isProcessing = false;

    @wire(getTodayStatus)
    wiredStatus(result) {
        this.wiredStatusResult = result;
        if (result.data) {
            this.todayStatus = result.data;
        } else if (result.error) {
            this.showError('Could not load today\'s attendance status', result.error);
        }
    }

    @wire(getMyAttendanceHistory)
    wiredHistory(result) {
        this.wiredHistoryResult = result;
        if (result.data) {
            this.history = result.data;
        } else if (result.error) {
            this.showError('Could not load your attendance history', result.error);
        }
    }

    get hasClockedIn() {
        return this.todayStatus ? this.todayStatus.hasClockedIn : false;
    }

    get hasClockedOut() {
        return this.todayStatus ? this.todayStatus.hasClockedOut : false;
    }

    get showClockInButton() {
        return !this.hasClockedIn;
    }

    get showClockOutButton() {
        return this.hasClockedIn && !this.hasClockedOut;
    }

    get hasHistory() {
        return this.history.length > 0;
    }

    async handleClockIn() {
        this.isProcessing = true;
        try {
            await clockIn();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Clocked in',
                    message: 'Have a great day at work!',
                    variant: 'success',
                })
            );
            await Promise.all([refreshApex(this.wiredStatusResult), refreshApex(this.wiredHistoryResult)]);
        } catch (error) {
            this.showError('Could not clock in', error);
        } finally {
            this.isProcessing = false;
        }
    }

    async handleClockOut() {
        this.isProcessing = true;
        try {
            await clockOut();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Clocked out',
                    message: 'See you next time!',
                    variant: 'success',
                })
            );
            await Promise.all([refreshApex(this.wiredStatusResult), refreshApex(this.wiredHistoryResult)]);
        } catch (error) {
            this.showError('Could not clock out', error);
        } finally {
            this.isProcessing = false;
        }
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}