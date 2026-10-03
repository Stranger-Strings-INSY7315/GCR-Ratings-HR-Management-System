import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyReviews from '@salesforce/apex/PerformanceReviewController.getMyReviews';

export default class MyPerformanceReviews extends LightningElement {
    reviews = [];

    @wire(getMyReviews)
    wiredMyReviews({ data, error }) {
        if (data) {
            this.reviews = data.map((row) => ({
                ...row,
                ratingLabel: row.rating ? `${row.rating} / 5` : 'Not rated',
            }));
        } else if (error) {
            const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not load your performance reviews',
                    message,
                    variant: 'error',
                })
            );
        }
    }

    get hasReviews() {
        return this.reviews.length > 0;
    }
}