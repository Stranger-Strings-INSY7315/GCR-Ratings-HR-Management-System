import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllAuditLogs from '@salesforce/apex/AuditLogController.getAllAuditLogs';

export default class AuditLogViewer extends LightningElement {
    logs = [];

    @wire(getAllAuditLogs)
    wiredLogs({ data, error }) {
        if (data) {
            this.logs = data;
        } else if (error) {
            this.showError('Could not load the audit trail', error);
        }
    }

    get hasLogs() {
        return this.logs.length > 0;
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}