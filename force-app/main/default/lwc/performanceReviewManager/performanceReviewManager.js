import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAllReviews from '@salesforce/apex/PerformanceReviewController.getAllReviews';
import getEmployeeOptions from '@salesforce/apex/PerformanceReviewController.getEmployeeOptions';
import createReview from '@salesforce/apex/PerformanceReviewController.createReview';
import updateReview from '@salesforce/apex/PerformanceReviewController.updateReview';
import finalizeReview from '@salesforce/apex/PerformanceReviewController.finalizeReview';

const RATING_OPTIONS = [
    { label: '1 - Needs Improvement', value: '1' },
    { label: '2 - Below Expectations', value: '2' },
    { label: '3 - Meets Expectations', value: '3' },
    { label: '4 - Exceeds Expectations', value: '4' },
    { label: '5 - Outstanding', value: '5' },
];

export default class PerformanceReviewManager extends LightningElement {
    reviews = [];
    wiredReviewsResult;
    employeeOptions = [];
    ratingOptions = RATING_OPTIONS;

    isProcessing = false;
    showNewForm = false;

    // New review form fields
    newEmployeeId = '';
    newReviewDate = '';
    newRating = '';
    newComments = '';

    // Inline edit state (only one row can be edited at a time)
    editingId;
    editReviewDate = '';
    editRating = '';
    editComments = '';

    @wire(getAllReviews)
    wiredReviews(result) {
        this.wiredReviewsResult = result;
        if (result.data) {
            this.reviews = result.data.map((row) => ({
                ...row,
                isDraft: row.status === 'Draft',
                isEditing: row.reviewId === this.editingId,
                ratingLabel: row.rating ? `${row.rating} / 5` : 'Not rated',
            }));
        } else if (result.error) {
            this.showError('Could not load performance reviews', result.error);
        }
    }

    @wire(getEmployeeOptions)
    wiredEmployees({ data, error }) {
        if (data) {
            this.employeeOptions = data.map((emp) => ({
                label: emp.employeeName,
                value: emp.employeeId,
            }));
        } else if (error) {
            this.showError('Could not load employee list', error);
        }
    }

    get hasReviews() {
        return this.reviews.length > 0;
    }

    // ---------- New review form ----------

    handleShowNewForm() {
        this.showNewForm = true;
    }

    handleCancelNew() {
        this.showNewForm = false;
        this.resetNewForm();
    }

    handleNewEmployeeChange(event) {
        this.newEmployeeId = event.detail.value;
    }

    handleNewDateChange(event) {
        this.newReviewDate = event.detail.value;
    }

    handleNewRatingChange(event) {
        this.newRating = event.detail.value;
    }

    handleNewCommentsChange(event) {
        this.newComments = event.detail.value;
    }

    async handleSaveNew() {
        this.isProcessing = true;
        try {
            await createReview({
                employeeId: this.newEmployeeId,
                reviewDate: this.newReviewDate,
                rating: this.newRating ? Number(this.newRating) : null,
                comments: this.newComments,
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Review created',
                    message: 'The review was saved as a draft. Finalize it when ready for the employee to see.',
                    variant: 'success',
                })
            );
            this.showNewForm = false;
            this.resetNewForm();
            await refreshApex(this.wiredReviewsResult);
        } catch (error) {
            this.showError('Could not create this review', error);
        } finally {
            this.isProcessing = false;
        }
    }

    resetNewForm() {
        this.newEmployeeId = '';
        this.newReviewDate = '';
        this.newRating = '';
        this.newComments = '';
    }

    // ---------- Inline edit (drafts only) ----------

    handleEdit(event) {
        const reviewId = event.target.dataset.id;
        const row = this.reviews.find((r) => r.reviewId === reviewId);
        this.editingId = reviewId;
        this.editReviewDate = row.reviewDate;
        this.editRating = row.rating ? String(row.rating) : '';
        this.editComments = row.comments;
        this.refreshEditingFlags();
    }

    handleCancelEdit() {
        this.editingId = undefined;
        this.refreshEditingFlags();
    }

    handleEditDateChange(event) {
        this.editReviewDate = event.detail.value;
    }

    handleEditRatingChange(event) {
        this.editRating = event.detail.value;
    }

    handleEditCommentsChange(event) {
        this.editComments = event.detail.value;
    }

    async handleSaveEdit(event) {
        const reviewId = event.target.dataset.id;
        this.isProcessing = true;
        try {
            await updateReview({
                reviewId: reviewId,
                reviewDate: this.editReviewDate,
                rating: this.editRating ? Number(this.editRating) : null,
                comments: this.editComments,
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Review updated',
                    message: 'Your changes have been saved.',
                    variant: 'success',
                })
            );
            this.editingId = undefined;
            await refreshApex(this.wiredReviewsResult);
        } catch (error) {
            this.showError('Could not update this review', error);
        } finally {
            this.isProcessing = false;
        }
    }

    async handleFinalize(event) {
        const reviewId = event.target.dataset.id;
        this.isProcessing = true;
        try {
            await finalizeReview({ reviewId: reviewId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Review finalized',
                    message: 'This review is now visible to the employee.',
                    variant: 'success',
                })
            );
            await refreshApex(this.wiredReviewsResult);
        } catch (error) {
            this.showError('Could not finalize this review', error);
        } finally {
            this.isProcessing = false;
        }
    }

    refreshEditingFlags() {
        this.reviews = this.reviews.map((row) => ({
            ...row,
            isEditing: row.reviewId === this.editingId,
        }));
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}