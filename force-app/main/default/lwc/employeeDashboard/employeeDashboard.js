import { LightningElement, wire } from 'lwc';
import getCurrentEmployee from '@salesforce/apex/EmployeeController.getCurrentEmployee';
import getLeaveBalances from '@salesforce/apex/EmployeeController.getLeaveBalances';

export default class EmployeeDashboard extends LightningElement {
    employee;
    balances = [];
    error;

    @wire(getCurrentEmployee)
    wiredEmployee({ data, error }) {
        if (data) {
            this.employee = data;
            this.error = undefined;
            this.loadBalances(data.Id);
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error loading your profile.';
        }
    }

    loadBalances(employeeId) {
        getLeaveBalances({ employeeId })
            .then((result) => {
                this.balances = result;
            })
            .catch((err) => {
                this.error = err.body ? err.body.message : 'Unknown error loading leave balances.';
            });
    }

    get fullName() {
        return this.employee ? `${this.employee.First_Name__c} ${this.employee.Last_Name__c}` : '';
    }

    get departmentAndPosition() {
        if (!this.employee) return '';
        const dept = this.employee.Department__r ? this.employee.Department__r.Name : '';
        const pos = this.employee.Position__r ? this.employee.Position__r.Name : '';
        return [dept, pos].filter(Boolean).join(' • ');
    }
}