import { LightningElement, wire } from 'lwc';
import getDashboardStats from '@salesforce/apex/HRDashboardController.getDashboardStats';

export default class HrDashboard extends LightningElement {
    stats;

    @wire(getDashboardStats)
    wiredStats({ data, error }) {
        if (data) {
            this.stats = data;
        } else if (error) {
            console.error(error);
        }
    }

    get hasStats() {
        return this.stats != null;
    }

    calcPercent(part, total) {
        if (!total || total === 0) {
            return 0;
        }
        return Math.round((part / total) * 100);
    }

    get pendingLeavePercent() {
        return this.calcPercent(this.stats?.pendingLeaveRequests, this.stats?.totalLeaveRequests);
    }
    get approvedLeavePercent() {
        return this.calcPercent(this.stats?.approvedLeaveRequests, this.stats?.totalLeaveRequests);
    }
    get rejectedLeavePercent() {
        return this.calcPercent(this.stats?.rejectedLeaveRequests, this.stats?.totalLeaveRequests);
    }

    get pendingLeaveBarStyle() {
        return `width: ${this.pendingLeavePercent}%`;
    }
    get approvedLeaveBarStyle() {
        return `width: ${this.approvedLeavePercent}%`;
    }
    get rejectedLeaveBarStyle() {
        return `width: ${this.rejectedLeavePercent}%`;
    }

    get assignedTrainingPercent() {
        return this.calcPercent(this.stats?.assignedTraining, this.stats?.totalTrainingAssignments);
    }
    get inProgressTrainingPercent() {
        return this.calcPercent(this.stats?.inProgressTraining, this.stats?.totalTrainingAssignments);
    }
    get completedTrainingPercent() {
        return this.calcPercent(this.stats?.completedTraining, this.stats?.totalTrainingAssignments);
    }
    get overdueTrainingPercent() {
        return this.calcPercent(this.stats?.overdueTraining, this.stats?.totalTrainingAssignments);
    }

    get assignedTrainingBarStyle() {
        return `width: ${this.assignedTrainingPercent}%`;
    }
    get inProgressTrainingBarStyle() {
        return `width: ${this.inProgressTrainingPercent}%`;
    }
    get completedTrainingBarStyle() {
        return `width: ${this.completedTrainingPercent}%`;
    }
    get overdueTrainingBarStyle() {
        return `width: ${this.overdueTrainingPercent}%`;
    }
}