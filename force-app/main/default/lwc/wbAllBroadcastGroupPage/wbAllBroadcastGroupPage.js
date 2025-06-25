import { LightningElement, track } from 'lwc';
import getBroadcastGroups from '@salesforce/apex/BroadcastMessageController.getBroadcastGroups';
import deleteBroadcastGroup from '@salesforce/apex/BroadcastMessageController.deleteBroadcastGroup';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';

export default class WbAllBroadcastGroupPage extends LightningElement {
    @track data = [];
    @track filteredData = [];
    @track paginatedData = [];
    @track currentPage = 1;
    @track pageSize = 15;
    @track visiblePages = 5;
    @track isLoading = false;
    @track isNewBroadcast = false;
    @track isAllGroupPage = false;
    @track showLicenseError = false;

    broadcastGroupId = null;

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
    
    async connectedCallback(){
        try {
            this.isLoading = true;
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            this.isAllGroupPage = true;
        this.loadBroadcastGroups();
        } catch (e) {
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

    loadBroadcastGroups() {
        this.isLoading = true;
        getBroadcastGroups()
            .then(result => {
                this.data = result.map((item, index) => ({
                    ...item,
                    index : index + 1,
                }));
                this.filteredData = [...this.data];
                this.updateShownData();
            })
            .catch(() => {
                this.showToast('Error', 'Error loading records', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
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

            this.filteredData = this.data.filter((item) => 
                (item.Name?.toLowerCase() ?? '').includes(
                    (event.detail.value.toLowerCase() ?? ''))
            );
            
            this.updateShownData();
        } catch (error) {
            this.showToast('Error', 'Error searching records', 'error');
        }
    }
    
    handlePrevious() {
        try{
            if (this.currentPage > 1) {
                this.currentPage--;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error navigating pages', 'error');
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

    handleEditGroup(event){
        const recordId = event.currentTarget.dataset.id;
        this.broadcastGroupId = recordId;
        this.isAllGroupPage = false;
        this.isNewBroadcast = true;
        this.isLoading = true;
    }

    handleDeleteGroup(event) {
        const recordId = event.currentTarget.dataset.id;
        this.isLoading = true; // Show spinner
    
        deleteBroadcastGroup({ groupId: recordId })
            .then(() => {
                this.showToast('Success', 'Broadcast Group deleted successfully', 'success');
    
                // Remove the deleted record from both lists
                this.data = this.data.filter(item => item.Id !== recordId);
                this.filteredData = this.filteredData.filter(item => item.Id !== recordId);
    
                // Update paginatedData to reflect the changes
                this.updateShownData();
            })
            .catch(() => {
                this.showToast('Error', 'Failed to delete Broadcast Group', 'error');
            })
            .finally(() => {
                this.isLoading = false; // Hide spinner
            });
    }


    handleNewBroadcastCreation(){
        this.isAllGroupPage = false;
        this.isNewBroadcast = true;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}