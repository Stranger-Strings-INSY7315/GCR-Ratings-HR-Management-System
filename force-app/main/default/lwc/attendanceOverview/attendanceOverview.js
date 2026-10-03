import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllAttendance from '@salesforce/apex/AttendanceController.getAllAttendance';

export default class AttendanceOverview extends LightningElement {
    records = [];

    @wire(getAllAttendance)
    wiredAttendance({ data, error }) {
        if (data) {
            this.records = data.map((row) => ({
                ...row,
                hoursWorkedLabel: row.hoursWorked != null ? `${row.hoursWorked} hrs` : 'In progress',
            }));
        } else if (error) {
            const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not load attendance records',
                    message,
                    variant: 'error',
                })
            );
        }
    }

    get hasRecords() {
        return this.records.length > 0;
    }
}