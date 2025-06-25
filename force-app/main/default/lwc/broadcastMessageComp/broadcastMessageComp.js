import { LightningElement, api, track, wire } from 'lwc';
import getObjectConfigs from '@salesforce/apex/BroadcastMessageController.getObjectConfigs';
import getListViewsForObject from '@salesforce/apex/BroadcastMessageController.getListViewsForObject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processBroadcastMessageWithObject from '@salesforce/apex/BroadcastMessageController.processBroadcastMessageWithObject';
import getBroadcastGroupDetails from '@salesforce/apex/BroadcastMessageController.getBroadcastGroupDetails';
import getSessionId from '@salesforce/apex/BroadcastMessageController.getSessionId';
export default class BroadcastMessageComp extends LightningElement {
    @track objectOptions = [];
    @track listViewOptions = [];
    @track selectedObject = '';
    @track selectedListView = '';
    @track data = [];
    @track filteredData = []; // filtered data based on search
    @track paginatedData = [];
    @track currentPage = 1;
    @track pageSize = 15;
    @track visiblePages = 5;
    @track isLoading = false;
    @track configMap = {}; // store object -> {nameField, phoneField}
    @track searchTerm = '';
    @track selectedRecords = new Set(); // Track selected record IDs
    @track isCreateBroadcastModalOpen = false;
    @track messageText = '';
    @track broadcastGroupName = '';
    @track isCreateBroadcastComp = true;
    @track isAllBroadcastGroupPage = false;
    @track isIntialRender = true;
    @track groupMembers= [];
    @track maxLimit = 30000;
    @track fetchedResults = [];
    @track sessionId;
    @api broadcastGroupId;
    @track broadcastHeading = 'New Broadcast Group';
    @track createBtnLabel= 'Create Broadcast Group'


    /**
    * Getter Name : dynamicFieldNames
    * @description : return dynamic field names based on selected object
    * Date: 03/04/2025
    * Created By: Rachit Shah
    */
    get dynamicFieldNames() {
        if (!this.selectedObject || !this.configMap[this.selectedObject]) {
            return [];
        }
        const fields = this.configMap[this.selectedObject];
        return [
            `${this.selectedObject}.${fields.nameField}`,
            `${this.selectedObject}.${fields.phoneField}`
        ];
    }

    /**
    * Getter Name : isAllSelected
    * @description : return true if all records are selected
    * Date: 03/04/2025
    * Created By: Rachit Shah
    */
    get isAllSelected() {
        return this.paginatedData.length > 0 && 
                this.paginatedData.every(record => this.selectedRecords.has(record.Id));
    }

    get isIndeterminate() {
        return this.paginatedData.some(record => this.selectedRecords.has(record.Id)) && 
                !this.isAllSelected;
    }

    get showNoRecordsMessage() {
        return this.paginatedData.length === 0;
    }

    get isSearchDisabled() {
        return !this.selectedObject || !this.selectedListView;
    }

    get isListViewDropdownDisabled() {
        return !this.selectedObject;
    }

    get isBtnDisabled() {
        return !this.paginatedData.length;
    }

    /**
     * Getter Name : totalItems
     * @description : set the totalItems count.
     */
    get totalItems() {
        return this.filteredData.length;
    }
    
    /**
    * Getter Name : totalPages
    * @description : set the totalpages count.
    */
    get totalPages() {
        return Math.ceil(this.totalItems / this.pageSize);
    }

    /**
    * Getter Name : pageNumbers
    * @description : set the list for page number in pagination.
    */
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

        /**
    * Getter Name : isFirstPage
    * @description : check the current page is first.
    */
    get isFirstPage() {
        return this.currentPage === 1;
    }

    /**
    * Getter Name : isLastPage
    * @description : check the current page is last.
    */
    get isLastPage() {
        return this.currentPage === Math.ceil(this.totalItems / this.pageSize);
    }
    
    connectedCallback() {
        this.loadConfigs();
        this.fetchGroupDetails();
        getSessionId().then(result => this.sessionId = result);
    }


    loadConfigs() {
        this.isLoading = true;
        getObjectConfigs()
            .then(result => {
                this.objectOptions = result.objectOptions;
                this.configMap = result.configMap;
            })
            .catch(error => {
                this.showToast('Error', 'Error loading configs', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

        // Method to fetch group details (call this after your operations)
        fetchGroupDetails() {

            if (!this.broadcastGroupId) {
                return;
            }
                
            this.isLoading = true; // Show loading spinner
    
            getBroadcastGroupDetails({ groupId: this.broadcastGroupId })
                .then((result) => {
                    this.broadcastHeading = 'Edit Broadcast Group';
                    this.createBtnLabel= 'Update Broadcast Group'
                    let groupData = result.group || {};
                    
                    this.selectedObject = groupData.MVWB__Object_Name__c || '';  // Set Object Name
                    this.loadListViews();
                    this.selectedListView = groupData.MVWB__List_View__c || '';  // Set List View Name


                    this.broadcastGroupName = groupData.Name;
                    this.messageText = groupData.MVWB__Description__c;

                    this.groupMembers = result.members || [];
                    
                    getSessionId()
                    .then(result => {
                        this.sessionId = result
                        this.fetchAllListViewRecords(this.selectedListView, this.sessionId, this.maxLimit);        
                    });

                })
                .catch(() => {
                    this.showToast('Error', 'Error fetching group details', 'error');
                })
                .finally(() => {
                    this.isLoading = false; // Hide loading spinner
                });
        }

    /**
    * Method Name : updateShownData
    * @description : update the shownProcessedLisitingData when pagination is applied.
    * date: 20/08/2024
    * Created By:Vyom Soni
    */
    updateShownData() {
        try {
            const startIndex = (this.currentPage - 1) * this.pageSize;
            const endIndex = Math.min(startIndex + this.pageSize, this.totalItems);
            this.paginatedData = this.filteredData.slice(startIndex, endIndex).map(record => ({
                ...record,
                isSelected: this.selectedRecords.has(record.Id)
            }));
        } catch (error) {
            this.showToast('Error', 'Error updating shown data', 'error');
        }
    }

    /**
    * Method Name : handlePrevious
    * @description : handle the previous button click in the pagination.
    * date: 20/08/2024
    * Created By:Vyom Soni
    */
    handlePrevious() {
        try{
            if (this.currentPage > 1) {
                this.currentPage--;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error handling previous button click', 'error');
        }
    }

    /**
    * Method Name : handleNext
    * @description : handle the next button click in the pagination.
    * date: 20/08/2024
    * Created By:Vyom Soni
    */
    handleNext() {
        try{
            if (this.currentPage < this.totalPages) {
                this.currentPage++;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error handling next button click', 'error');
        }
    }

        /**
    * Method Name : handlePageChange
    * @description : handle the direct click on page number.
    * date: 20/08/2024
    * Created By:Vyom Soni
    */
    handlePageChange(event) {
        try{
            const selectedPage = parseInt(event.target.getAttribute('data-id'), 10);
            if (selectedPage !== this.currentPage) {
                this.currentPage = selectedPage;
                this.updateShownData();
            }
        }catch(error){
            this.showToast('Error', 'Error handling page change', 'error');
        }
    }

    handleBack() {
        this.cleardata();
        this.isCreateBroadcastComp = false;
        this.isAllBroadcastGroupPage = true;
        
    }

    cleardata() {
        this.selectedObject = '';
        this.selectedListView = '';
        this.data = [];
        this.filteredData = [];
        this.paginatedData = [];
        this.currentPage = 1;
        this.selectedRecords.clear(); // Clear selections
        this.broadcastGroupName = '';
        this.messageText = '';
        this.isCreateBroadcastModalOpen = false;
        this.broadcastGroupId = null;
        this.groupMembers = []; 
        this.isIntialRender = true;
    }        

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        const term = this.searchTerm.trim();
        this.filteredData = this.data.filter(item => {
            const name = item.name?.toLowerCase() || '';
            const phone = item.phone?.toLowerCase() || '';
            return !term || name.includes(term) || phone.includes(term);
        });
        this.currentPage = 1;
        this.updateShownData();    
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        switch(name) {
            case 'name':
                this.broadcastGroupName = value;
                break;
            case 'message':
                this.messageText = value;
                break;
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedListView = '';
        this.data = [];
        this.filteredData = [];
        this.paginatedData = [];
        this.currentPage = 1;
        this.selectedRecords.clear(); // Clear selections
        this.loadListViews();
    }


    loadListViews() {
        this.isLoading = true;
        getListViewsForObject({ objectApiName: this.selectedObject })
            .then(result => {
                this.listViewOptions = result.map(lv => ({
                    label: lv.Name,
                    value: lv.Id
                }));
            })
            .catch(() => {
                this.showToast('Error', 'Error loading list views', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleListViewChange(event) {
        this.selectedListView = event.detail.value;
        this.fetchAllListViewRecords(this.selectedListView, this.sessionId, this.maxLimit);        
        this.isLoading = true;
    }

    /**
    * Method Name : fetchListViewSOQL
    * @description : fetch list view records using tooling api
    * date: 24/04/2025
    * Created By:Tirth Shah
    */
    async fetchListViewSOQL(listViewId, sessionId) {
        const myHeaders = new Headers();
        myHeaders.append("Authorization", "Bearer " + sessionId);
        myHeaders.append("Content-Type", "application/json");
    
        const requestOptions = {
            method: "GET",
            headers: myHeaders,
            redirect: "follow"
        };
    
        let domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');
        let queryURL = '/services/data/v58.0/sobjects/'+this.selectedObject+'/listviews/'+this.selectedListView+'/describe';

        // const toolingQueryURL = '/services/data/v58.0/tooling/query?q=SELECT+Id,+Query+FROM+ListView+WHERE+Id='+{listViewId}+'/describe';
    
        const response = await fetch(domainURL + queryURL, requestOptions)
        const result = await response.json();
        
        if (response.status == 200) {
            const fields = this.configMap[this.selectedObject];

            let originalQuery = result.query;

            let fieldsString = `Id, ${fields.nameField}, ${fields.phoneField}`;

            // Replace everything between SELECT and FROM
            let modifiedQuery = originalQuery.replace(/SELECT(.*?)FROM/i, `SELECT ${fieldsString} FROM`);
            return modifiedQuery;
        } else {
            throw new Error("No query found for the specified ListView ID.");
        }
    }

    /**
    * Method Name : fetchAllListViewRecords
    * @description : Using tooling api to fetch records
    * date: 24/04/2025
    * Created By:Tirth Shah
    */

    fetchAllListViewRecords(listViewId, sessionId, maxLimit) {
        
        this.fetchListViewSOQL(listViewId, sessionId)
            .then(query => {
                this.isLoading = false;
                if (!query) {
                    return;
                }
                // Convert SOQL to REST Query URL
                
                const soqlQueryUrl = `/services/data/v59.0/query?q=${encodeURIComponent(query)}`;
    
                // Use your existing method
                return this.fetchRecords(soqlQueryUrl, sessionId, maxLimit);
            })
            .then(success => {
                if (success) {
                    // console.log('All fetched results:', this.fetchedResults);
                    // Do something with this.fetchedResults, e.g. render or pass to another method
                }
            });
    }

    /**
    * Method Name: fetchRecords
    * @description: Executes a SOQL query using REST API and returns records
    * @date: 24/04/2025
    * @Created By: Tirth Shah
    */
    fetchRecords(queryUrl, sessionId, maxLimit) {
        this.isLoading = false;
        const domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');

        const headers = new Headers();
        headers.append("Authorization", "Bearer " + sessionId);
        headers.append("Content-Type", "application/json");

        const requestOptions = {
            method: "GET",
            headers: headers,
            redirect: "follow"
        };

        return fetch(domainURL + queryUrl, requestOptions)
            .then(response => response.json())
            .then(result => {
                if (!this.selectedObject || !this.selectedListView) {
                            return;
                }
                
                if (result) {
                    const fields = this.configMap[this.selectedObject];                    
                    
                    this.data = result.records.map((record, index) => ({
                        index : index + 1,
                        Id: record.Id,
                        name: record[fields.nameField] ? record[fields.nameField] : '',
                        phone: record[fields.phoneField] ? record[fields.phoneField] : '',
                        isSelected: false
                    }));
                            
                    this.filteredData = [...this.data];
                    this.currentPage = 1;
        
                    // Ensure this runs only on the first render and when group members exist
                    if (this.isIntialRender && this.broadcastGroupId && this.groupMembers.length > 0) {
                        this.isIntialRender = false; // Prevent future updates from modifying selection
        
                        const memberPhoneNumbers = new Set(this.groupMembers.map(member => member.MVWB__Phone_Number__c));
        
                        this.data.forEach(record => {
                            if (memberPhoneNumbers.has(record.phone)) {
                                record.isSelected = true;
                                this.selectedRecords.add(record.Id);
                            }
                        });
                        this.filteredData = [...this.data];
                    } else {
                        this.selectedRecords.clear();
                    }
                    this.updateShownData();                    
                
                
                if (result.records && Array.isArray(result.records)) {
                    this.fetchedResults = maxLimit
                        ? result.records.slice(0, maxLimit)
                        : result.records;

                    return true;
                } else {
                    this.showToast('warning', 'No Records', 'No records were found.');
                    return false;
                }
            }
            })
            .catch(error => {
                console.error('Error fetching records:', error.message);
                this.showToast('error', 'Error', 'Failed to retrieve records');
                return false;
            });
    }


    /**
     * Handle individual record selection
     */
    handleRecordSelection(event) {
        
        const recordId = event.target.dataset.recordid;
        const recordcurrentId = event.currentTarget.dataset.recordid;
        
        const record = this.paginatedData.find(row => row.Id === recordId);
        
        if (record) {
            record.isSelected = event.target.checked;            
            if (record.isSelected) {
                this.selectedRecords.add(recordId);
            } else {
                this.selectedRecords.delete(recordId);
            }
            this.selectedRecords = new Set(this.selectedRecords);
        }
    }

    /**
     * Handle select all records
     */
    handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.paginatedData.forEach(record => {
            record.isSelected = isChecked;
            if (isChecked) {
                this.selectedRecords.add(record.Id);
            } else {
                this.selectedRecords.delete(record.Id);
            }
        });
        this.selectedRecords = new Set(this.selectedRecords);
    }

    handleModalOpen(){

        if(this.selectedRecords.size === 0){
            this.showToast('Error', 'Please select at least one record', 'error');
            return;
        }

        // Check selectedRecords for invalid phone numbers
        if (Array.from(this.selectedRecords).some(recordId => {
            const record = this.data.find(r => r.Id === recordId);
            return !record || !record.phone || record.phone.trim() === '';
        })) {
            this.showToast('Error', 'One or more selected records have invalid or missing phone numbers', 'error');
            return;
        }


        this.isCreateBroadcastModalOpen = true;
    }

    closePopUp(){
        this.isCreateBroadcastModalOpen = false;
        this.broadcastGroupName = '';
        this.messageText = '';

    }

    handleSave(){
        if(this.broadcastGroupName.trim() === ''){            
            this.showToast('Error', 'Please enter the Broadcast Group Name', 'error');
            return;
        }

        const phoneNumbers = Array.from(this.selectedRecords)
        .map(recordId => {
            const record = this.data.find(r => r.Id === recordId);
            return record ? record.phone : null;
        })
        .filter(phone => phone !== null && phone !== '');
  
            
        const isUpdate = this.broadcastGroupId != null;
        
        const phoneField = this.configMap[this.selectedObject]?.phoneField || '';

        const messageData = {
            objectApiName: this.selectedObject,
            listViewName: this.selectedListView,
            phoneNumbers: phoneNumbers,
            description: this.messageText,
            name: this.broadcastGroupName,
            isUpdate: isUpdate,
            broadcastGroupId: this.broadcastGroupId,
            phoneField: phoneField
        };

        this.isLoading = true;

        // Call the Apex method
        processBroadcastMessageWithObject({ requestJson: JSON.stringify(messageData) })
        .then(() => {
            this.showToast('Success', 'Broadcast group created successfully', 'success');
            this.closePopUp();
            this.selectedRecords.clear();
            this.updateShownData();

        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to process broadcast', 'error');
        })
        .finally(() => {
            this.isLoading = false;
            this.isCreateBroadcastComp = false;
            this.isAllBroadcastGroupPage = true;
        });;
    }

    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

}