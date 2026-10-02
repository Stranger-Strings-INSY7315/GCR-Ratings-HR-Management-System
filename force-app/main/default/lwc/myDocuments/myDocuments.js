import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentEmployee from '@salesforce/apex/TrainingController.getCurrentEmployee';
import getMyDocuments from '@salesforce/apex/DocumentController.getMyDocuments';

export default class MyDocuments extends LightningElement {
    employeeId;
    documents = [];

    @wire(getCurrentEmployee)
    wiredEmployee({ data, error }) {
        if (data) {
            this.employeeId = data.Id;
        } else if (error) {
            this.showError('Could not load your employee record', error);
        }
    }

    @wire(getMyDocuments, { employeeId: '$employeeId' })
    wiredDocuments({ data, error }) {
        if (data) {
            this.documents = data.map((doc) => ({
                id: doc.documentId,
                name: doc.documentName,
                type: doc.documentType,
                uploadDate: doc.uploadDate,
                downloadUrl: doc.contentVersionId
                    ? '/sfc/servlet.shepherd/document/download/' + doc.contentVersionId
                    : null,
                hasFile: !!doc.contentVersionId,
            }));
        } else if (error) {
            this.showError('Could not load your documents', error);
        }
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}