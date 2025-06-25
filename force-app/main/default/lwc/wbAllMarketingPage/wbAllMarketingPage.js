import { LightningElement, track } from 'lwc';
import getBroadcastRecs from '@salesforce/apex/BroadcastMessageController.getBroadcastRecs';
import getCampaignRecs from '@salesforce/apex/MarketingMessageController.getCampaignRecs';
import getBroadcastGroups from '@salesforce/apex/BroadcastMessageController.getBroadcastGroups';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getTemplatesByObject from '@salesforce/apex/BroadcastMessageController.getTemplatesByObject';
import createChatRecods from '@salesforce/apex/BroadcastMessageController.createChatRecods';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import deleteMarketingCampaign from '@salesforce/apex/MarketingMessageController.deleteMarketingCampaign';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';


export default class WbAllBroadcastPage extends NavigationMixin(LightningElement) {
    @track data = [];
    @track paginatedData = [];
    @track filteredData = [];
    @track broadcastGroups = [];
    @track filteredGroups = [];
    @track selectedGroupIds = [];
    @track currentPage = 1;
    @track pageSize = 15;
    @track visiblePages = 5;
    @track isLoading = false;
    @track showPopup = false;
    @track selectedObjectName = '';
    @track popUpFirstPage = true;
    @track showLicenseError = false;
    @track popupHeader = 'Choose Broadcast Groups';
    @track isMarketingCampaignSelected = true;
    @track isTemplateVisible = false;
    @track showLicenseError = false;
    @track selectedRecordId='';



    subscription = {};
    channelName = '/event/BroadcastUpdateEvent__e';

    get showNoRecordsMessage() {
        return this.filteredData.length === 0;
    }

    get totalItems() {
        return this.filteredData.length;
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

    get isNextDisabled() {
        return this.selectedGroupIds.length === 0;
    }

    checkActionDisabled(event){
        const status = event.target.dataset.value;
        console.log('Status ::: ',status);
        
        if(status == 'Completed'){
            return true;
        } else {
            return false;
        }
    }

    async connectedCallback(){
        try {
            this.isLoading = true;
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            this.isTemplateVisible = true;
            if (this.isMarketingCampaignSelected) {
                this.loadCampaigns();
            }
            this.subscribeToPlatformEvent();
            // this.loadAllTemplates(); // Load templates on component initialization
            
        } catch (e) {
            console.error('Error in connectedCallback:::', e.message);
        }
    }

    async checkLicenseStatus() {
        try {
            const isLicenseValid = await checkLicenseUsablility();
            console.log('isLicenseValid => ', isLicenseValid);
            if (!isLicenseValid) {
                this.showLicenseError = true;
            }
        } catch (error) {
            console.error('Error checking license:', error);
        }
    }

    disconnectedCallback(){
        this.unsubscribeFromPlatformEvent();
    }

    subscribeToPlatformEvent() {
        subscribe(this.channelName, -1, (message) => {
            
            if(message.data.payload.IsChanged__c === true){
                this.loadCampaigns();
            }            
        })
        .then((response) => {
            this.subscription = response;
        })
        .catch(() => {
            this.showToast('Error', 'Failed to subscribe to platform event.', 'error');
        });
    }

    // Method to unsubscribe from the Platform Event
    unsubscribeFromPlatformEvent() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {
            });
        }
    }

    loadBroadcastGroups() {
        // this.isLoading = true;
        getBroadcastRecs()
            .then(result => {
                console.log('Broadcast groups ::: ',result);
                
                this.data = result.map((item, index) => ({
                    ...item,
                    index : index + 1
                }));                
                console.log('Data ::: ',this.data);
                
                this.filteredData = [...this.data];
                this.updateShownData();
            })
            .catch(() => {
                this.showToast('Error', 'Failed to load broadcast groups', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadCampaigns() {
        this.isLoading = true;
        getCampaignRecs() // Replace with the actual Apex method to fetch campaigns
            .then(result => {
                this.data = result.map((item, index) => {
                    return {
                        ...item,
                        index: index + 1,
                        startDate: this.formatDate(item.Start_Date__c),
                        endDate: this.formatDate(item.End_Date__c),
                        isDisabled : item.Status__c == 'Completed' ? true : false
                    };
                });
                console.log('Campaigns ::: ',this.data);
                
                this.filteredData = [...this.data];
                this.updateShownData();
            })
            .catch(() => {
                this.showToast('Error', 'Failed to load campaigns', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const dateObj = new Date(dateStr);
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        }).format(dateObj);
    }

    updateShownData() {
        try {
            const startIndex = (this.currentPage - 1) * this.pageSize;
            const endIndex = Math.min(startIndex + this.pageSize, this.totalItems);
            this.paginatedData = this.filteredData.slice(startIndex, endIndex);
        } catch (error) {
            this.showToast('Error', 'Error updating shown data', 'error');
        }
    }

    handleSearch(event) {
        try {
            if(event.detail.value.trim().toLowerCase() != null) {
                this.filteredData = this.data.filter(item => 
                    item.Name &&
                    item.Name.toLowerCase().includes(event.detail.value.trim().toLowerCase())
                );
                this.updateShownData();
            }
        } catch (error) {
            this.showToast('Error', 'Error searching', 'error');
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

    handleSearchPopup(event) {
        const searchValue = event.target.value.trim().toLowerCase();
    
        // Filter the broadcast groups based on the search value
        this.filteredGroups = this.broadcastGroups.filter(group =>
            group.Name.toLowerCase().includes(searchValue)
        );
    
        // Ensure the IsChecked property is updated for filtered groups
        this.filteredGroups = this.filteredGroups.map(group => ({
            ...group,
            IsChecked: this.selectedGroupIds.some(selected => selected.Id === group.Id)
        }));
    }
    // Handle group selection
    handleGroupSelection(event) {
        try {
            const groupId = event.target.dataset.id;
            const selectedGroup = this.broadcastGroups.find(group => group.Id === groupId);
            console.log('Selected group ::: ',selectedGroup);
            
            if (event.target.checked) {
                // Add group ID to selected list if checked
                if (!this.selectedGroupIds.some(group => group.Id === groupId)) {
                    this.selectedGroupIds = [
                        ...this.selectedGroupIds,
                        { Id: groupId, ObjName: selectedGroup.Object_Name__c,Name:selectedGroup.Name } // Store both Id and Name
                    ];
                }
            } else {
                // Remove group ID if unchecked
                this.selectedGroupIds = this.selectedGroupIds.filter(group => group.Id !== groupId);
            }

            console.log('Selected group ids ::: ',this.selectedGroupIds);
            
    
            this.selectedObjectName = this.selectedGroupIds[0]?.ObjName || '';
            console.log('Selected object name ::: ',this.selectedObjectName);
            
    
            // Update filteredGroups to reflect selection
            this.filteredGroups = this.filteredGroups.map(group => ({
                ...group,
                IsChecked: this.selectedGroupIds.some(selected => selected.Id === group.Id)
            }));
        } catch (error) {
            this.showToast('Error', 'Error handling group selection', 'error');
        }
    }

    handleCloseOnPopup() {
        this.showPopup = false;
        this.popUpFirstPage = true;
        this.popupHeader = 'Select Groups';
    
        // Reset the selected values
        this.selectedGroupIds = [];
        this.selectedTemplate = '';
        this.selectedDateTime = '';
    
        // Reset the filteredGroups and update IsChecked property
        this.filteredGroups = this.broadcastGroups.map(group => ({
            ...group,
            IsChecked: false
        }));
    }

        newBroadcast(){
        this.showPopup = true;
        this.isLoading = true;

        getBroadcastGroups()
            .then(result => {
                this.broadcastGroups = result;
                this.filteredGroups = [...this.broadcastGroups];
            })
            .catch(() => {
                this.showToast('Error', 'Error fetching broadcast groups', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    handleNextbroadcastOnPopup(event) {
        try {
            const firstObjName = this.selectedGroupIds[0]?.ObjName;
            const allSameObjName = this.selectedGroupIds.every(group => group.ObjName === firstObjName);

            if (!allSameObjName) {
                this.showToast('Error!', 'Please select groups with the same object name', 'error');
                return;
            }

            const names = this.selectedGroupIds.map(item => item.Name); // Extract names from selectedGroupIds
            console.log('Selected template ::: ', this.selectedTemplate);
            console.log('Selected names ::: ', names);

            event.preventDefault();

            // Encode the data as query parameters
            const navigationState = {
                groupNames: names,
                objectName : this.selectedObjectName,
                groupId : this.selectedGroupIds,
                campaignId: ''
            };
            const encodedNavigationState = btoa(JSON.stringify(navigationState));
            this.showPopup = false;
            // Navigate to the wbCreateMarketingCampaign component
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'create_Marketing' // Replace with the API name of your Lightning Tab
                },
                state: {
                    c__navigationState: encodedNavigationState
                }
            });
        } catch (error) {
            console.error('Error in handleNextbroadcastOnPopup:', error);
            this.showToast('Error!', 'An error occurred while navigating', 'error');
        }
    }

    editMarketingCampaign(event){
        const campaignId = event.target.dataset.id; // Get the campaign ID from the button or element
        if (!campaignId) {
            this.showToast('Error', 'Campaign ID is missing', 'error');
            return;
        }
        const navigationState = {
            // groupNames: names,
            // objectName : this.selectedObjectName,
            // groupId : this.selectedGroupIds,
            campaignId: campaignId
        };
        const encodedNavigationState = btoa(JSON.stringify(navigationState));

        // Navigate to the wbCreateMarketingCampaign component
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'create_Marketing' // Replace with the API name of your Lightning Tab
            },
            state: {
                c__navigationState: encodedNavigationState
            }
        });
    }

    deleteMarketingCampaign(event) {
        const campaignId = event.target.dataset.id; // Get the campaign ID from the button or element
        if (!campaignId) {
            this.showToast('Error', 'Campaign ID is missing', 'error');
            return;
        }
    
        // Confirm deletion
        // if (!confirm('Are you sure you want to delete this campaign?')) {
        //     return;
        // }
    
        this.isLoading = true; // Show a loading spinner
        deleteMarketingCampaign({ campaignId })
            .then((result) => {
                if (result === 'Success') {
                    this.showToast('Success', 'Campaign deleted successfully', 'success');
                    this.loadCampaigns(); // Reload the campaigns list
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch((error) => {
                this.showToast('Error', `Failed to delete campaign: ${error.body.message}`, 'error');
            })
            .finally(() => {
                this.isLoading = false; // Hide the loading spinner
            });
    }
    
    handleNameClick(event) {
        this.selectedRecordId = event.target.dataset.recordId;
    }
    
    showToast(title ,message, status){
        this.dispatchEvent(new ShowToastEvent({title: title, message: message, variant: status}));
    }
}