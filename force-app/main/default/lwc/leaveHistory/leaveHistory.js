import { LightningElement, wire } from 'lwc';
import getCurrentEmployee from '@salesforce/apex/EmployeeController.getCurrentEmployee';
import getMyLeaveRequests from '@salesforce/apex/EmployeeController.getMyLeaveRequests';

export default class LeaveHistory extends LightningElement {
    employeeId;
    requests = [];

    @wire(getCurrentEmployee)
    wiredEmployee({ data }) {
        if (data) {
            this.employeeId = data.Id;
            this.loadRequests();
        }
    }

    loadRequests() {
        getMyLeaveRequests({ employeeId: this.employeeId }).then((result) => {
            this.requests = result.map((r) => ({
                ...r,
                statusClass: 'gcr-badge gcr-badge-' + r.Status__c.toLowerCase().replace(/ /g, '-')
            }));
        });
    }

    get hasRequests() {
        return this.requests.length > 0;
    }
}