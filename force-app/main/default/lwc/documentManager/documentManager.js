import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmployeeOptions from '@salesforce/apex/DocumentAdminController.getEmployeeOptions';
import getAllDocuments from '@salesforce/apex/DocumentAdminController.getAllDocuments';
import createDocumentRecord from '@salesforce/apex/DocumentAdminController.createDocumentRecord';

export default class DocumentManager extends LightningElement {
    selectedEmployeeId = null;
    documentName = '';
    selectedCategory = null;
    newDocumentId;

    employeeOptions = [];
    documents = [];
    wiredDocumentsResult;

    categoryOptions = [
        { label: 'Policy', value: 'Policy' },
        { label: 'Payslip', value: 'Payslip' },
        { label: 'Contract', value: 'Contract' },
        { label: 'Other', value: 'Other' }
    ];

    acceptedFormats = ['.pdf', '.docx', '.doc', '.png', '.jpg', '.jpeg'];

    @wire(getEmployeeOptions)
    wiredEmployeeOptions({ data, error }) {
        if (data) {
            this.employeeOptions = data.map((emp) => ({
                label: emp.employeeName,
                value: emp.employeeId
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getAllDocuments)
    wiredDocuments(result) {
        this.wiredDocumentsResult = result;
        if (result.data) {
            this.documents = result.data.map((doc) => ({
                ...doc,
                downloadUrl: '/sfc/servlet.shepherd/version/download/' + doc.contentVersionId
            }));
        } else if (result.error) {
            console.error(result.error);
        }
    }

    get showFileUpload() {
        return this.newDocumentId != null;
    }

    get hasDocuments() {
        return this.documents && this.documents.length > 0;
    }

    handleEmployeeChange(event) {
        this.selectedEmployeeId = event.detail.value;
    }

    handleNameChange(event) {
        this.documentName = event.detail.value;
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
    }

    handleCreateDocument() {
        if (!this.selectedEmployeeId || !this.documentName || !this.selectedCategory) {
            this.showToast('Error', 'Please select an employee, enter a document name, and choose a category.', 'error');
            return;
        }

        createDocumentRecord({
            employeeId: this.selectedEmployeeId,
            documentName: this.documentName,
            category: this.selectedCategory
        })
            .then((result) => {
                this.newDocumentId = result;
                this.showToast('Success', 'Document record created. Now attach the file below.', 'success');
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleUploadFinished() {
        this.showToast('Success', 'File attached successfully.', 'success');
        this.newDocumentId = null;
        this.selectedEmployeeId = null;
        this.documentName = '';
        this.selectedCategory = null;
        refreshApex(this.wiredDocumentsResult);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}