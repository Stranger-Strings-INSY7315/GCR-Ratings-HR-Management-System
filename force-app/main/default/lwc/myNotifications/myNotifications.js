import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getMyNotifications from '@salesforce/apex/NotificationController.getMyNotifications';
import markAsRead from '@salesforce/apex/NotificationController.markAsRead';

export default class MyNotifications extends LightningElement {
    notifications = [];
    wiredNotificationsResult;

    @wire(getMyNotifications)
    wiredNotifications(result) {
        this.wiredNotificationsResult = result;
        if (result.data) {
            this.notifications = result.data.map((n) => ({
                ...n,
                boxClass: n.isRead ? 'slds-box slds-m-bottom_small gcr-notification-box' : 'slds-box slds-m-bottom_small gcr-notification-box gcr-unread-box',
            }));
        } else if (result.error) {
            this.showError('Could not load your notifications', result.error);
        }
    }

    get hasNotifications() {
        return this.notifications.length > 0;
    }

    get unreadCount() {
        return this.notifications.filter((n) => !n.isRead).length;
    }

    get hasUnread() {
        return this.unreadCount > 0;
    }

    async handleMarkAsRead(event) {
        const notificationId = event.target.dataset.id;
        try {
            await markAsRead({ notificationId });
            await refreshApex(this.wiredNotificationsResult);
        } catch (error) {
            this.showError('Could not mark this notification as read', error);
        }
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}