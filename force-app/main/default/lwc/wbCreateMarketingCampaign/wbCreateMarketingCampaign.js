import getTemplatesByObject from '@salesforce/apex/BroadcastMessageController.getTemplatesByObject';
import { LightningElement, wire, track } from 'lwc';
import getDateFieldsForPicklist from '@salesforce/apex/BroadcastMessageController.getDateFieldsForPicklist';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import createMarketingCampaign from '@salesforce/apex/MarketingMessageController.createMarketingCampaign';
import updateMarketingCampaign from '@salesforce/apex/MarketingMessageController.updateMarketingCampaign';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCampaignDetails from '@salesforce/apex/MarketingMessageController.getCampaignDetails';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';


export default class WbCreateMarketingCampaign extends NavigationMixin(LightningElement) {
    @track broadcastGroupList = ['Group1', 'Group2', 'Group3'];
    @track templateOptions = []; // Will store the processed template options
    @track templateMap = new Map(); // Store the raw Map from Apex
    @track showLicenseError = false;

    
    selectedObjectName = '';
    selectedOption = 'specific';
    
    isLoading = false;
    campaignName = '';
    campaignDescription = '';
    campaignObject = '';
    isMarketingCampaign = false;
    campaignStartDate = '';
    campaignEndDate = '';
    createBrodcastPopup = false;
    isImmediateSelected = false;
    campaignId = '';


    // dateFieldOptions = [
    //     { label: 'Birthday', value: 'birthday' },
    //     { label: 'Anniversary', value: 'anniversary' },
    //     { label: 'Signup Date', value: 'signup' }
    // ];

    @track dateFieldOptions =[];

    @track groupNames = [];
    @track selectedTemplate = '';
    @track groupId = [];
    
    @track specificError = ''; // Error for the "specific" option
    @track relatedError = '';  // Error for the "related" option
    
        
    @track emailConfigs = [
        { id: 1, template: '', daysAfter: 0, timeToSend: '' , isImmediateSelected : false }
    ];
    @track selectedDateField = '';
    @track error = '';
    
    @track selectedDate = '';
    @track minDate = this.getTodayDate(); // Set the minimum date to today
    @track isTemplateVisible = false;

    // nextId = 2;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.state.c__navigationState) {
            try {
                const navigationStateString = currentPageReference.state.c__navigationState;
                const navigationState = JSON.parse(atob(navigationStateString)); // Decode the Base64 string

                // Retrieve the passed data
                if(navigationState.campaignId == '' ) {
                    this.selectedObjectName = navigationState.objectName;
                    this.broadcastGroupList = navigationState.groupNames;
                    this.groupId = navigationState.groupId;
                    console.log('Broadcast Group List:', this.broadcastGroupList);
                    this.fetchDateFields();
                }
                else{
                    this.campaignId = navigationState.campaignId;
                    console.log('Campaign ID:', this.campaignId);
                    
                    // this.loadAllTemplates();
                    this.loadCampaignDetails();
                    
                }
                this.loadAllTemplates();
                // this.campaignId = navigationState.campaignId;
                // console.log('Selected Template:', this.selectedTemplate);
            } catch (error) {
                console.error('Error decoding navigation state:', error);
            }
        }
    }
    get isSpecific() {
        return this.selectedOption === 'specific';
    }

    get isRelated() {
        return this.selectedOption === 'related';
    }

    get isEditTemplate(){
        return this.campaignId != '';
    }

    
    async connectedCallback(){
        try {
            this.isLoading = true;
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            this.isTemplateVisible = true;
            // this.isEditTemplate = true;
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

    handleOptionChange(event) {
        this.selectedOption = event.target.value;

        // Reset errors and values when switching options
        if (this.selectedOption === 'specific') {
            this.relatedError = '';
            this.selectedDateField = '';
        } else if (this.selectedOption === 'related') {
            this.specificError = '';
            this.selectedDate = '';
        }
    }

    handleImmediateSelectedClick(){
        this.isImmediateSelected = !this.isImmediateSelected;
        // console.log('isImmediateSelected:', this.isImmediateSelected);
    }

    fetchDateFields() {
        getDateFieldsForPicklist({ objectApiName: this.selectedObjectName })
            .then((result) => {
                if (result) {
                    this.dateFieldOptions = result.map((field) => ({
                        label: field.label,
                        value: field.value,
                    }));
                    console.log('Date Fields:', this.dateFieldOptions);
                } else {
                    this.dateFieldOptions = [];
                    console.warn('No date fields found for the object:', this.selectedObjectName);
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching date fields:', error);
            });
    }

    handleSelectChange(event) {
        const selectedDateField = event.detail.value;
        if (this.selectedOption === 'related') {
            if (!selectedDateField) {
                // Show error if no date field is selected
                this.relatedError = 'Please select a date field.';
                this.showError = true; // Keep the global error flag
            } else {
                this.selectedDateField = selectedDateField;
                this.relatedError = ''; // Clear the related error
                this.showError = false; // Clear the global error flag
            }
        }
    }

loadCampaignDetails() {
    if (!this.campaignId) {
        this.isLoading = false;
        console.error('Campaign ID is not available.');
        return;
    }

    getCampaignDetails({ campaignId: this.campaignId })
        .then((result) => {
            console.log('Raw Campaign Details JSON:', result);

            // Parse the JSON string into an object
            const parsedResult = JSON.parse(result);

            // Assign campaign data
            this.campaignData = parsedResult.campaign;
            this.campaignName = this.campaignData.Name;
            this.campaignDescription = this.campaignData.Marketing_Campaign_Description__c;
            this.selectedObjectName = this.campaignData.Object_Name__c;
            this.isMarketingCampaign = this.campaignData.hasExistingMarketingCampaign__c;
            this.campaignStartDate = this.campaignData.Start_Date__c;
            this.campaignEndDate = this.campaignData.End_Date__c;
            this.groupId = this.campaignData.Group_Id_List__c.split(',');

            const listOfGroups = parsedResult.groupNames;
            console.log('List of Groups:', listOfGroups);
            
            if (Array.isArray(listOfGroups)) {
                this.broadcastGroupList = listOfGroups; // Assign directly if it's already a list
            } else if (typeof listOfGroups === 'string') {
                this.broadcastGroupList = listOfGroups.split(','); // Split if it's a comma-separated string
            } else {
                this.broadcastGroupList = []; // Default to an empty array if the value is invalid
            }
            
            console.log('Processed Group Names:', this.broadcastGroupList);

            this.fetchDateFields();

            // Assign additional fields
            this.selectedDate = parsedResult.selectedDate || '';
            this.selectedDateField = parsedResult.selectedDateFields || '';
            this.selectedOption = parsedResult.selectedOption || 'specific';

            console.log('Parsed Email Configs:', parsedResult.emailConfigs);

            // Assign email configurations
            this.emailConfigs = parsedResult.emailConfigs.map((config,index) => ({
                id:index+1,
                groupId: config.Id,
                template: config.WB_Template__c,
                daysAfter: config.Days_After__c,
                timeToSend: this.convertMillisToTime(config.Time_To_Send__c),
                isImmediateSelected: config.Is_Send_Immediately__c
            }));

            console.log('Email Configs (mapped):', this.emailConfigs);

        })
        .catch((error) => {
            console.error('Error fetching campaign details:', error);
            this.showToast('Error', 'Failed to load campaign details', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
}

    // convertMillisToTime(millis) {
    //     const date = new Date(millis);
    //     let hours = date.getUTCHours(); // UTC to avoid local timezone shift
    //     let minutes = date.getUTCMinutes();
    //     let period = hours >= 12 ? 'pm' : 'am';
    
    //     hours = hours % 12;
    //     if (hours === 0) hours = 12; // 12 AM / PM edge case
    
    //     // Pad minutes to always have two digits
    //     const minuteStr = minutes.toString().padStart(2, '0');
    
    //     return `${hours}:${minuteStr} ${period}`;
    // }


    convertMillisToTime(timeString) {
        if (!timeString) return '';
    
        const [hours, minutes, secondsAndMillis] = timeString.split(':');
        const [seconds, milliseconds] = secondsAndMillis.split('.');
    
        const formattedTime = `${hours}:${minutes}:${seconds}.${milliseconds}`;
        const timeToSend = formattedTime.replace('Z', '');
    
        return timeToSend;
    }
    

    // prefillForm() {
    //     console.log('Prefilling form with campaign data:', this.campaignData);
    
    //     // Pre-fill the form fields with the campaign data
    //     this.campaignName = this.campaignData.Name;
    //     this.campaignDescription = this.campaignData.Marketing_Campaign_Description__c;
    //     this.selectedObjectName = this.campaignData.Object_Name__c;
    //     this.isMarketingCampaign = this.campaignData.hasExistingMarketingCampaign__c;
    //     this.campaignStartDate = this.campaignData.Start_Date__c;
    //     this.campaignEndDate = this.campaignData.End_Date__c;
    
    //     // Pre-fill email configurations
    //     console.log('Prefilling email configurations:', this.emailConfigs);
    //     this.emailConfigs = [...this.emailConfigs];
    // }

    loadAllTemplates() {
            this.isLoading = true;
            getTemplatesByObject()
                .then(result => {
                    // Convert the Apex Map to JavaScript Map
                    console.log('REsult :::: ',result);
                    
                    this.templateMap = new Map(Object.entries(result));
                    console.log('Template Map :::: ',this.templateMap);
                    this.updateTemplateOptions(); // Update options based on selected object
                    
                })
                .catch(error => {
                    this.showToast('Error', 'Failed to load templates', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    
        // get templateOptions() {
        //     return [
        //         { label: 'Welcome Email', value: 'welcome' },
        //         { label: 'Reminder Email', value: 'reminder' },
        //         { label: 'Follow-up Email', value: 'followup' }
        //     ];
        // }
    
        addRow() {
            if (this.hasDuplicates()) {
                this.error = 'Duplicate template with the same send time and date is not allowed.';
                return;
            }
            this.error = '';
            const nextIndex = this.emailConfigs.length + 1; // Use the current length of the array to calculate the next index
            this.emailConfigs = [
                ...this.emailConfigs,
                { id: nextIndex, template: '', daysAfter: 0, timeToSend: '', isImmediateSelected: false }
            ];
        }
    
        handleDelete(event) {
            const index = parseInt(event.target.dataset.index, 10);
            this.emailConfigs.splice(index, 1);
            this.emailConfigs = [...this.emailConfigs];
        }
    
        handleComboboxChange(event) {
            const index = parseInt(event.target.dataset.index, 10);
            this.emailConfigs[index].template = event.detail.value;
            this.validateDuplicates();
        }
    
        // handleInputChange(event) {
        //     const index = parseInt(event.target.dataset.index, 10);
        //     const field = event.target.dataset.field;
        //     // this.emailConfigs[index][field] = event.detail.value;
        //     if (field === 'isImmediateSelected') {
        //         console.log('In isImmediateSelected');
        //         console.log('isImmediateSelected:', this.emailConfigs[index][field]);
                
        //         // Toggle the isImmediateSelected field
        //         this.emailConfigs[index][field] = !this.emailConfigs[index][field];
        //     } else {
        //         // Update other fields like daysAfter, timeToSend, etc.
        //         this.emailConfigs[index][field] = event.detail.value;
        //     }
        
        //     this.validateDuplicates();
        // }
    
        validateDuplicates() {
            const seen = new Set();
            for (let row of this.emailConfigs) {
                if (!row.template || !row.timeToSend || row.daysAfter === '') continue;
                const key = `${row.template}-${row.daysAfter}-${row.timeToSend}`;
                if (seen.has(key)) {
                    this.error = 'Duplicate template with the same send time and date is not allowed.';
                    return;
                }
                seen.add(key);
            }
            this.error = ''; // Clear the error when no duplicates are found
        }
    
        hasDuplicates() {
            const seen = new Set();
            for (let row of this.emailConfigs) {
                if (!row.template || !row.timeToSend || row.daysAfter === '') continue;
                const key = `${row.template}-${row.daysAfter}-${row.timeToSend}`;
                if (seen.has(key)) return true;
                seen.add(key);
            }
            return false;
        }

        
    
        updateTemplateOptions() {
            if (!this.selectedObjectName || this.templateMap.size === 0) {
                this.templateOptions = [];
                
                return;
            }
            console.log(this.selectedObjectName);
    
            let combinedTemplates = [];
    
            // Add object-specific templates
            if (this.templateMap.has(this.selectedObjectName)) {
                combinedTemplates = [...this.templateMap.get(this.selectedObjectName)];
            }
    
            // Add Generic templates
            if (this.templateMap.has('Generic')) {
                combinedTemplates = [...combinedTemplates, ...this.templateMap.get('Generic')];
            }
    
            // Convert to combobox options format
            this.templateOptions = combinedTemplates.map(template => ({
                label: template.Template_Name__c,
                value: template.Id
            }));
    
            
        }

    // connectedCallback() {
    //     // this.minDate = this.getTodayDate();       
    //     // this.loadAllTemplates(); // Load templates on component initialization

    // }

    // Get today's date in YYYY-MM-DD format
    getTodayDate() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    // Handle date change
    // handleDateChange(event) {
    //     const selectedDate = event.target.value;
    //     console.log("Selected Date ::: ", selectedDate);
        
    //     if (this.selectedOption === 'specific') {
    //         if (!selectedDate) {
    //             // Handle empty or invalid date
    //             this.specificError = 'Please select a date.';
    //             this.showError = false; // Keep the global error flag
    //         } else if (new Date(selectedDate) < new Date()) {
    //             // Show error if the selected date is not after today
    //             this.specificError = 'Selected date must be after today.';
    //             this.showError = false; // Keep the global error flag
    //         } else {
    //             // Valid date
    //             this.selectedDate = selectedDate;
    //             this.specificError = ''; // Clear the specific error
    //             this.showError = false; // Clear the global error flag
    //         }
    //     }
    //     console.log("Selected Date ::: ", selectedDate);
    // }
    handleDateChange(event) {
        const selectedDate = event.target.value;
        console.log("Selected Date ::: ", selectedDate);
    
        if (this.selectedOption === 'specific') {
            if (!selectedDate) {
                // Handle empty or invalid date
                this.specificError = 'Please select a date.';
                this.showError = false; // Keep the global error flag
            } else {
                // Compare only the date parts
                const selected = new Date(selectedDate);
                const today = new Date();
    
                // Clear time parts
                selected.setHours(0, 0, 0, 0);
                today.setHours(0, 0, 0, 0);
    
                if (selected < today) {
                    // Show error if the selected date is before today
                    this.specificError = 'Selected date must be today or later.';
                    this.showError = false; // Keep the global error flag
                } else {
                    // Valid date
                    this.selectedDate = selectedDate;
                    this.specificError = ''; // Clear the specific error
                    this.showError = false; // Clear the global error flag
                }
            }
        }
        console.log("Selected Date ::: ", selectedDate);
    }

    // Handle input change for time and validate duplicates
    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        if (field === 'isImmediateSelected') {
            console.log('In isImmediateSelected');
            console.log('isImmediateSelected:', this.emailConfigs[index][field]);
            
            // Toggle the isImmediateSelected field
            this.emailConfigs[index][field] = !this.emailConfigs[index][field];
        } else {
            console.log('Value ::: ', value);
            
            this.emailConfigs[index][field] = value;
        }

        // Update the emailConfigs array

        // Validate for duplicate time and date
        if (field === 'timeToSend' || field === 'daysAfter' || field === 'isImmediateSelected') {
            this.validateDuplicateSchedules();
        }
    }
    handleInputChangeModal(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        if (fieldName === 'campaignName') {
            this.campaignName = fieldValue;
        } else if (fieldName === 'campaignDescription') {
            this.campaignDescription = fieldValue;
        }
    }


    handleComboboxChange(event) {
        const index = parseInt(event.target.dataset.index, 10); // Get the index from data-index
        this.emailConfigs[index].template = event.detail.value; // Update the template value
        console.log('Updated emailConfigs:', this.emailConfigs); // Debug log
        this.validateDuplicates(); // Validate for duplicates
    }

    // Validate that no two templates have the same time and date
    validateDuplicateSchedules() {
        // Clear previous errors
        this.emailConfigs = this.emailConfigs.map(config => ({
            ...config,
            errorDaysAfter: '',
            errorTimeToSend: '',
            errorTemplate: ''
        }));

        const scheduleSet = new Set();
        let hasError = false;

        for (const config of this.emailConfigs) {
            // Skip validation for rows where isImmediateSelected is true
            if (config.isImmediateSelected) {
                console.log('Skipping validation for immediate selected row');
                continue;
            }

            // Only validate rows with valid daysAfter, timeToSend, and template values
            if (config.daysAfter !== '' && config.timeToSend && config.template) {
                const scheduleKey = `${config.daysAfter}-${config.timeToSend}-${config.template}`;
                if (scheduleSet.has(scheduleKey)) {
                    // Set specific errors for duplicate fields
                    config.errorDaysAfter = 'Duplicate schedule detected.';
                    config.errorTimeToSend = 'Duplicate schedule detected.';
                    config.errorTemplate = 'Duplicate schedule detected.';
                    hasError = true;
                } else {
                    scheduleSet.add(scheduleKey);
                }
            }
        }

        if (!hasError) {
            this.error = ''; // Clear global error if no duplicates
        }

        // Trigger reactivity
        this.emailConfigs = [...this.emailConfigs];
    }

    // Show error message (you can customize this to display in the UI)
    showError(message) {
        console.error(message);
        // Optionally, set an error property to display the message in the UI
        this.error = message;
    }

    validateForm() {
        if (this.selectedOption === 'specific') {
            if (!this.selectedDate || (new Date(this.selectedDate) < new Date())) {
                this.specificError = 'Selected date must be after today.';
                return false;
            }
        } else if (this.selectedOption === 'related') {
            if (!this.selectedDateField) {
                this.relatedError = 'Please select a date field.';
                return false;
            }
        }
        this.specificError = '';
        this.relatedError = '';
        return true;
    }

    get showSpecificError() {
        return this.error && this.selectedOption === 'specific';
    }

    get showRelatedError() {
        return this.error && this.selectedOption === 'related';
    }

    validateInputs() {
        if (this.selectedOption === 'specific') {
            if (!this.selectedDate || (new Date(this.selectedDate) < new Date())) {
                this.specificError = 'Please select a valid date.';
                return false;
            } else {
                this.specificError = ''; // Clear error if valid
            }
        } else if (this.selectedOption === 'related') {
            if (!this.selectedDateField) {
                this.relatedError = 'Please select a date field.';
                return false;
            } else {
                this.relatedError = ''; // Clear error if valid
            }
        }
        return true; // Return true if all validations pass
    }

    // handleSubmit() {
    //     if (this.validateInputs()) {
    //         // Proceed with form submission
    //         console.log('Form submitted successfully!');
    //     } else {
    //         console.log('Validation failed.');
    //     }
    // }
    handlePrevclick(event){
        event.preventDefault();
        this.templateMap = [];
        this.templateOptions = [];
        this.resetValues();
            // Encode the data as query parameters
            // const navigationState = {
            //     groupNames: names,
            //     objectName : this.selectedObjectName
            // };
            // const encodedNavigationState = btoa(JSON.stringify(navigationState));

            // Navigate to the wbCreateMarketingCampaign component
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'All_Marketing_Campaign' // Replace with the API name of your Lightning Tab
                }
            });
    }

    handleOpenModal() {
        this.createBrodcastPopup = true;
    }

    handleCloseModal() {
        this.createBrodcastPopup = false;
    }

    get isSubmitDisabled() {
        // Check if any required field in emailConfigs is empty, excluding rows where isImmediateSelected is true
        const hasEmptyFields = this.emailConfigs.some(config => {
            // if (config.isImmediateSelected) {
            //     return false; // Skip validation for rows with isImmediateSelected = true
            // }
            return !config.template || !config.timeToSend || config.daysAfter == '';
        });
    
        // Check if specific or related option validations fail
        if (this.selectedOption === 'specific') {
            return hasEmptyFields || !this.selectedDate || (new Date(this.selectedDate) < new Date());
        } else if (this.selectedOption === 'related') {
            return hasEmptyFields || !this.selectedDateField;
        }
    
        return hasEmptyFields;
    }

      // Handle checkbox change
      handleCheckboxChange(event) {
        this.isMarketingCampaign = event.target.checked;
    }

    
    resetValues() {
        this.broadcastGroupList = ['Group1', 'Group2', 'Group3'];
        this.templateOptions = []; // Reset template options
        this.templateMap = new Map(); // Clear the template map
    
        this.selectedObjectName = '';
        this.selectedOption = 'specific';
    
        this.isLoading = false;
        this.campaignName = '';
        this.campaignDescription = '';
        this.campaignObject = '';
        this.isMarketingCampaign = false;
        this.campaignStartDate = '';
        this.campaignEndDate = '';
        this.createBrodcastPopup = false;
        this.isImmediateSelected = false;
        this.campaignId = '';
    
        this.emailConfigs = [
            { id: 1, template: '', daysAfter: 0, timeToSend: '', isImmediateSelected: false }
        ]; // Reset email configurations
        this.error = ''; // Clear any errors
        console.log('All values have been reset to their default state.');
    }

    navigateToAllBroadcastPage(){
        this.resetValues();
        this.createBrodcastPopup = false;
        this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'All_Marketing_Campaign' // Replace with the API name of your Lightning Tab
                    }
                });
    }

    createCampaign() {

        console.log('In createCampaign');

         // Validation: Check if any required field in emailConfigs is empty
        const hasEmptyFields = this.emailConfigs.some(config => {
            if (!config.template || !config.timeToSend || config.daysAfter === '') {
                this.showToast('Error', 'Please fill out all required fields in the email configurations.', 'error');
                return true;
            }
            return false;
        });

        if (hasEmptyFields) {
            return; // Stop execution if validation fails
        }

        // Validation: Check specific or related option validations
        if (this.selectedOption === 'specific') {
            const selected = new Date(this.selectedDate);
            const today = new Date();

            // Clear time parts
            selected.setHours(0, 0, 0, 0);
            today.setHours(0, 0, 0, 0);

            if (selected < today) {
                this.showToast('Error', 'Selected date must be today or later.', 'error');
                return;
            }
        } else if (this.selectedOption === 'related') {
            if (!this.selectedDateField) {
                this.showToast('Error', 'Please select a date field.', 'error');
                return; // Stop execution if validation fails
            }
        }
        
        const selectedDate1 = this.selectedDate.toString();
        console.log(selectedDate1);
        
        const campaignData = {
            id : this.campaignId,
            name: this.campaignName,
            description: this.campaignDescription,
            objectName: this.selectedObjectName,
            isMarketingCampaign: this.isMarketingCampaign,
            selectedOption: this.selectedOption,
            selectedDate: selectedDate1,
            selectedDateFields: this.selectedDateField,
            emailConfigs: this.emailConfigs,
            groupIdList : this.groupId
        };
        
        console.log('Campaign Data:', JSON.stringify(campaignData));
        
        // return
        if(this.campaignId){
            
            updateMarketingCampaign({ campaignData: JSON.stringify(campaignData) })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Marketing Campaign created successfully!`,
                        variant: 'success'
                    })
                );
                this.navigateToAllBroadcastPage();

            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
        }
        else{

            createMarketingCampaign({ campaignData: JSON.stringify(campaignData) })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Marketing Campaign created successfully!`,
                            variant: 'success'
                        })
                    );
                    this.navigateToAllBroadcastPage();
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
        
    }
    
    showToast(title ,message, status){
        this.dispatchEvent(new ShowToastEvent({title: title, message: message, variant: status}));
    }
}