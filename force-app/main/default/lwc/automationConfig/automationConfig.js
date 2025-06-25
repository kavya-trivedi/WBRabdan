import { LightningElement, track } from 'lwc';
import getAllAutomations from '@salesforce/apex/AutomationConfigController.getAllAutomations';
import getTemplates from '@salesforce/apex/AutomationConfigController.getTemplates';
import saveAutomations from '@salesforce/apex/AutomationConfigController.saveAutomations';
// import updateAutomations from '@salesforce/apex/AutomationConfigController.updateAutomations';
import deleteAutomations from '@salesforce/apex/AutomationConfigController.deleteAutomations';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class AutomationConfig extends NavigationMixin(LightningElement) {
    @track automationData = [];
    // @track originalAutomationData = [];
    // @track data = [];
    @track paginatedData = [];
    @track isLoading = true;
    @track isModalOpen = false;
    @track templateOptions = [];
    @track name = '';
    @track description = '';
    @track selectedTemplateId = '';
    @track recordId = null;
    @track showLicenseError = false;
    @track currentPage = 1;
    @track pageSize = 15;
    @track visiblePages = 5;

    // @track isEditMode = false;

    get showNoRecordsMessage() {
        return this.automationData.length === 0;
    }

    get totalItems() {
        return this.automationData.length;
    }
    
    get totalPages() {
        return Math.ceil(this.totalItems / this.pageSize);
    }
    
    get pageNumbers() {
        try {
            const totalPages = this.totalPages;
            const currentPage = this.currentPage;
            const visiblePages = this.visiblePages;

            let pages = [];

            if (totalPages <= visiblePages) {
                for (let i = 1; i <= totalPages; i++) {
                    pages.push({
                        number: i,
                        isEllipsis: false,
                        className: `pagination-button ${i === currentPage ? 'active' : ''}`
                    });
                }
            } else {
                pages.push({
                    number: 1,
                    isEllipsis: false,
                    className: `pagination-button ${currentPage === 1 ? 'active' : ''}`
                });

                if (currentPage > 3) {
                    pages.push({ isEllipsis: true });
                }

                let start = Math.max(2, currentPage - 1);
                let end = Math.min(currentPage + 1, totalPages - 1);

                for (let i = start; i <= end; i++) {
                    pages.push({
                        number: i,
                        isEllipsis: false,
                        className: `pagination-button ${i === currentPage ? 'active' : ''}`
                    });
                }

                if (currentPage < totalPages - 2) {
                    pages.push({ isEllipsis: true });
                }

                pages.push({
                    number: totalPages,
                    isEllipsis: false,
                    className: `pagination-button ${currentPage === totalPages ? 'active' : ''}`
                });
            }
            return pages;
        } catch (error) {
            this.showToast('Error', 'Error in pageNumbers->' + error, 'error');
            return null;
        }
    }
    
    get isFirstPage() {
        return this.currentPage === 1;
    }
    
    get isLastPage() {
        return this.currentPage === Math.ceil(this.totalItems / this.pageSize);
    }
    
    async connectedCallback() {
        try {
            
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            if(this.pageRef){
                this.objectApiName = this.pageRef.attributes.objectApiName;
            }
            this.fetchAutomations();
            this.fetchTemplates();
        } catch (error) {
            console.error('Error in connectedCallback:::', e.message);
        }
    }

    async checkLicenseStatus() {
        try {
            const isLicenseValid = await checkLicenseUsablility();
            if (!isLicenseValid) {
                this.showLicenseError = true;
            }
        } catch (error) {
            console.error('Error checking license:', error);
        }
    }

    updateShownData() {
        try {
            const startIndex = (this.currentPage - 1) * this.pageSize;
            const endIndex = Math.min(startIndex + this.pageSize, this.totalItems);
            this.paginatedData = this.automationData.slice(startIndex, endIndex);
        } catch (error) {
            this.showToast('Error', 'Error updating shown data', 'error');
        }
    }

    handlePrevious() {
        try{
            if (this.currentPage > 1) {
                this.currentPage--;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error navigating to previous page', 'error');
        }
    }

    handleNext() {
        try{
            if (this.currentPage < this.totalPages) {
                this.currentPage++;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error navigating pages', 'error');
        }
    }

    handlePageChange(event) {
        try{
            const selectedPage = parseInt(event.target.getAttribute('data-id'), 10);
            if (selectedPage !== this.currentPage) {
                this.currentPage = selectedPage;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error navigating pages', 'error');
        }
    } 

    /** 
    * Method Name: fetchAutomations 
    * @description: fetches all automation records to display on the UI  
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    fetchAutomations() {
        this.isLoading = true;
        getAllAutomations()
            .then(data => {
                this.originalAutomationData = data.map((record, index) => ({
                    id: record.Id,
                    srNo: index + 1,
                    name: record.Name,
                    description: record.MVWB__Description__c,
                    template: record.MVWB__WB_Template__r ? record.MVWB__WB_Template__r.MVWB__Template_Name__c : '',
                    templateType: record.MVWB__WB_Template__r ? record.MVWB__WB_Template__r.MVWB__Template_Type__c : ''
                }));
                // console.log('this.automationData =', JSON.stringify(this.originalAutomationData));

                this.automationData = [...this.originalAutomationData];
                this.updateShownData();

            })
            .catch(error => {
                console.error('Error fetching automation records:', error);
                this.automationData = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /** 
    * Method Name: fetchTemplates 
    * @description: fetches all templates for picklist  
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    fetchTemplates() {
        getTemplates()
            .then(data => {
                const filteredTemplates = data.filter(template => {
                    const buttons = JSON.parse(template.MVWB__WBButton_Body__c || '[]');
                    return buttons.some(button => button.type === "QUICK_REPLY" || button.type === "FLOW");
                });
                this.templateOptions = filteredTemplates
                .map(template => ({
                    label: template.MVWB__Template_Name__c,
                    value: template.Id
                }));
            })
            .catch(error => {
                console.error('Error fetching templates:', error);
            });
    }

    /**
    * Method Name: handleChange
    * @description: Updates fields based on field change
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    handleChange(event) {
        const fieldName = event.target.label;
        if (fieldName === 'Name') {
            this.name = event.target.value;
        } else if (fieldName === 'Description') {
            this.description = event.target.value || '';
        } else if (fieldName === 'Template') {
            this.selectedTemplateId = event.target.value;
        }
    }

    /**
    * Method Name: handleSave 
    * @description: Saves automation records based on create/edit mode  
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    handleSave() {
        if (!this.name || !this.selectedTemplateId) {
            this.showToast('Error', 'Please fill necessary fields before saving.', 'error');
            return;
        }

        const automationRecord = {
            // Id: this.isEditMode ? this.recordId : undefined,
            Name: this.name,
            MVWB__Description__c: this.description,
            MVWB__WB_Template__c: this.selectedTemplateId
        };

        // console.log('Automation Record:', JSON.stringify(automationRecord));

        // const apexMethod = this.isEditMode ? updateAutomations : saveAutomations;

        saveAutomations({ automations: [automationRecord] })
        .then((result) => {
            this.showToast('Success', `Automation saved successfully.`, 'success');
            this.closeModal();

            const savedRecordId = result[0].Id;

            getAllAutomations()
            .then(data => {
                this.originalAutomationData = data.map((record, index) => ({
                    id: record.Id,
                    srNo: index + 1,
                    name: record.Name,
                    description: record.MVWB__Description__c,
                    template: record.MVWB__WB_Template__r ? record.MVWB__WB_Template__r.MVWB__Template_Name__c : '',
                    templateType: record.MVWB__WB_Template__r ? record.MVWB__WB_Template__r.MVWB__Template_Type__c : ''
                }));
                // console.log('this.automationData =', JSON.stringify(this.originalAutomationData));
                this.automationData = [...this.originalAutomationData];

                // console.log('this.automationData in handleSave =', JSON.stringify(this.automationData));

                const savedAutomation = this.automationData.find(auto => auto.id === savedRecordId);
                // console.log('savedRecordId:', savedRecordId, 'savedAutomation:', JSON.stringify(savedAutomation));

                if (savedAutomation) {
                    let cmpDef = {
                        componentDef : 'MVWB:automationPath',
                        attributes: {
                            recordId: savedAutomation.id,
                            templateType: savedAutomation.templateType
                        }
                    };

                    // console.log('Record ID:', savedAutomation.id, 'Template Type:', savedAutomation.templateType);

                    let encodedDef = btoa(JSON.stringify(cmpDef));
                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: {
                            url: "/one/one.app#" + encodedDef
                        }
                    });
                } else {
                    console.warn('Saved automation not found in automationData.');
                }
            })
            .catch(error => {
                console.error('Error fetching automation records:', error);
                this.automationData = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
        })
        .catch(error => {
            const message = error.body && error.body.message ? error.body.message : JSON.stringify(error);
            console.error(`Error saving record:`, message);
            this.showToast('Error', `Failed to save automation: ${message}`, 'error');
        });        
    }

    get modalTitle() {
        return 'New Automation';
    }

    /**
    * Method Name: handleSearch 
    * @description: Searches automation records  
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    handleSearch(event) {
        // console.log('Search term:', event.target.value);
        const searchTerm = event.target.value.toLowerCase().trim();
        this.automationData = this.originalAutomationData.filter(auto =>
            (auto.name || '').toLowerCase().includes(searchTerm) ||
            (auto.description || '').toLowerCase().includes(searchTerm) ||
            (auto.template || '').toLowerCase().includes(searchTerm)
        );
        
        this.updateShownData();
        // console.log('Filtered Data:', this.automationData);
    }

    handleNew() {
        this.isModalOpen = true;
        this.name = '';
        this.description = '';
        this.selectedTemplateId = '';
        // this.isEditMode = false;
    }

    closeModal() {
        this.isModalOpen = false;
        // this.isEditMode = false;
        this.recordId = null;
        this.name = '';
        this.description = '';
        this.selectedTemplateId = '';
    }

    /**
    * Method Name: handleEdit 
    * @description: Opens edit modal for selected automation record  
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    handleEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        const templateType = event.currentTarget.dataset.templateType;
        // const selectedRecord = this.automationData.find(auto => auto.id === recordId);

        // if (selectedRecord) {
        //     this.isEditMode = true;
        //     this.isModalOpen = true;
        //     this.recordId = recordId;
        //     this.name = selectedRecord.name;
        //     this.description = selectedRecord.description;
        //     this.selectedTemplateId = this.templateOptions.find(option => option.label === selectedRecord.template)?.value || '';
        // }

        let cmpDef = {
            componentDef : 'MVWB:automationPath',
            attributes: {
                recordId: recordId,
                templateType: templateType
            }
        };
        // console.log('Record ID:', recordId, 'Template Type:', templateType);
        let encodedDef = btoa(JSON.stringify(cmpDef));
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/one/one.app#" + encodedDef
            }
        });
    }

    /**
    * Method Name: handleDelete 
    * @description: Deletes selected automation record
    * Date: 27/03/2025
    * Created By: Kavya Trivedi
    */
    handleDelete(event) {
        const recordId = event.currentTarget.dataset.id;
        if (!recordId) return;
    
        deleteAutomations({ recordIds: [recordId] })
        .then(() => {
            this.showToast('Success', 'Automation deleted successfully.', 'success');
            this.fetchAutomations();
        })
        .catch(error => {
            console.error('Error deleting record:', error);
            this.showToast('Error', 'Error deleting automation.', 'error');
        });
    }    

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}