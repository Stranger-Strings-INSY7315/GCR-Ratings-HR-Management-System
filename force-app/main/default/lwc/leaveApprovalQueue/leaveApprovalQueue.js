import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPendingLeaveRequests from '@salesforce/apex/LeaveApprovalController.getPendingLeaveRequests';
import approveLeave from '@salesforce/apex/LeaveApprovalController.approveLeave';
import rejectLeave from '@salesforce/apex/LeaveApprovalController.rejectLeave';

export default class LeaveApprovalQueue extends LightningElement {
    leaveRequests = [];
    wiredResult;

    // Tracks which request (if any) is currently showing the
    // "give a reason" box for rejection.
    rejectingId;
    rejectionReason = '';

    isProcessing = false;

    @wire(getPendingLeaveRequests)
    wiredLeaveRequests(result) {
        this.wiredResult = result;
        if (result.data) {
            this.leaveRequests = result.data.map((row) => ({
                id: row.leaveId,
                employeeName: row.employeeName,
                leaveTypeName: row.leaveTypeName,
                startDate: row.startDate,
                endDate: row.endDate,
                reason: row.reason,
                submittedDate: row.submittedDate,
                isRejecting: row.leaveId === this.rejectingId,
            }));
        } else if (result.error) {
            this.showError('Could not load pending leave requests', result.error);
        }
    }

    get hasRequests() {
        return this.leaveRequests.length > 0;
    }

    async handleApprove(event) {
        const leaveId = event.target.dataset.id;
        this.isProcessing = true;
        try {
            await approveLeave({ leaveRequestId: leaveId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Leave approved',
                    message: 'The request has been approved and the balance updated.',
                    variant: 'success',
                })
            );
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.showError('Could not approve this request', error);
        } finally {
            this.isProcessing = false;
        }
    }

    handleShowReject(event) {
        const leaveId = event.target.dataset.id;
        this.rejectingId = leaveId;
        this.rejectionReason = '';
        this.leaveRequests = this.leaveRequests.map((row) => ({
            ...row,
            isRejecting: row.id === leaveId,
        }));
    }

    handleCancelReject() {
        this.rejectingId = undefined;
        this.rejectionReason = '';
        this.leaveRequests = this.leaveRequests.map((row) => ({
            ...row,
            isRejecting: false,
        }));
    }

    handleReasonChange(event) {
        this.rejectionReason = event.detail.value;
    }

    async handleConfirmReject(event) {
        const leaveId = event.target.dataset.id;
        this.isProcessing = true;
        try {
            await rejectLeave({ leaveRequestId: leaveId, rejectionReason: this.rejectionReason });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Leave rejected',
                    message: 'The request has been rejected.',
                    variant: 'success',
                })
            );
            this.rejectingId = undefined;
            this.rejectionReason = '';
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.showError('Could not reject this request', error);
        } finally {
            this.isProcessing = false;
        }
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}