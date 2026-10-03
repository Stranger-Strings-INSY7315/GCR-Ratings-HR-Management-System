import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAllCourses from '@salesforce/apex/TrainingAdminController.getAllCourses';
import createCourse from '@salesforce/apex/TrainingAdminController.createCourse';
import updateCourse from '@salesforce/apex/TrainingAdminController.updateCourse';

const CATEGORY_OPTIONS = [
    { label: 'Compliance', value: 'Compliance' },
    { label: 'Technical', value: 'Technical' },
    { label: 'Leadership', value: 'Leadership' },
    { label: 'Onboarding', value: 'Onboarding' },
    { label: 'Other', value: 'Other' },
];

export default class TrainingCourseManager extends LightningElement {
    courses = [];
    wiredCoursesResult;
    categoryOptions = CATEGORY_OPTIONS;

    selectedCourseId; // null/undefined = creating a new course
    courseName = '';
    description = '';
    durationHours;
    category = '';
    isActive = true;
    isSaving = false;

    @wire(getAllCourses)
    wiredCourses(result) {
        this.wiredCoursesResult = result;
        if (result.data) {
            this.courses = result.data.map((c) => ({
                id: c.courseId,
                name: c.name,
                description: c.description,
                durationHours: c.durationHours,
                category: c.category,
                isActive: c.isActive,
                statusLabel: c.isActive ? 'Active' : 'Inactive',
                badgeClass: c.isActive
                    ? 'slds-badge slds-theme_success'
                    : 'slds-badge slds-theme_warning',
            }));
        } else if (result.error) {
            this.showError('Could not load training courses', result.error);
        }
    }

    get formTitle() {
        return this.selectedCourseId ? 'Edit Course' : 'New Course';
    }

    get saveButtonLabel() {
        return this.selectedCourseId ? 'Save Changes' : 'Create Course';
    }

    get isSaveDisabled() {
        return this.isSaving || !this.courseName || !this.category;
    }

    handleNameChange(event) {
        this.courseName = event.detail.value;
    }

    handleDescriptionChange(event) {
        this.description = event.detail.value;
    }

    handleDurationChange(event) {
        this.durationHours = event.detail.value;
    }

    handleCategoryChange(event) {
        this.category = event.detail.value;
    }

    handleActiveChange(event) {
        this.isActive = event.detail.checked;
    }

    handleEdit(event) {
        const courseId = event.target.dataset.id;
        const course = this.courses.find((c) => c.id === courseId);
        if (course) {
            this.selectedCourseId = course.id;
            this.courseName = course.name;
            this.description = course.description;
            this.durationHours = course.durationHours;
            this.category = course.category;
            this.isActive = course.isActive;
        }
    }

    handleCancelEdit() {
        this.resetForm();
    }

    async handleSave() {
        this.isSaving = true;
        try {
            if (this.selectedCourseId) {
                await updateCourse({
                    courseId: this.selectedCourseId,
                    name: this.courseName,
                    description: this.description,
                    durationHours: this.durationHours,
                    category: this.category,
                    isActive: this.isActive,
                });
                this.showToast('Course updated', 'The course was updated successfully.', 'success');
            } else {
                await createCourse({
                    name: this.courseName,
                    description: this.description,
                    durationHours: this.durationHours,
                    category: this.category,
                    isActive: this.isActive,
                });
                this.showToast('Course created', 'The new course is now available.', 'success');
            }
            this.resetForm();
            await refreshApex(this.wiredCoursesResult);
        } catch (error) {
            this.showError('Could not save this course', error);
        } finally {
            this.isSaving = false;
        }
    }

    resetForm() {
        this.selectedCourseId = undefined;
        this.courseName = '';
        this.description = '';
        this.durationHours = undefined;
        this.category = '';
        this.isActive = true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showError(title, error) {
        const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
        this.showToast(title, message, 'error');
    }
}