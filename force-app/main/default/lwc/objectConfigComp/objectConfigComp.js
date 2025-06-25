import { LightningElement, track } from 'lwc';
import getRequiredFields from '@salesforce/apex/ObjectConfigController.getRequiredFields';
import getTextAndPhoneFields from '@salesforce/apex/ObjectConfigController.getTextAndPhoneFields';
import getUserConfig from '@salesforce/apex/ObjectConfigController.getUserConfig';
import saveUserConfig from '@salesforce/apex/ObjectConfigController.saveUserConfig';
import getObjectsWithPhoneField from '@salesforce/apex/ObjectConfigController.getObjectsWithPhoneField';
import getRecordName from '@salesforce/apex/ObjectConfigController.getRecordName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';

export default class ObjectConfigComp extends LightningElement {
    @track selectedObject = 'Contact';
    @track requiredFields = [];
    @track phoneFields = [];
    @track phoneFieldsForChatConfig = []
    @track textFields = [];
    @track objectOptions = [];
    @track availableObjectOptions = [];
    @track chatWindowRows = [];
    @track chatConfigCounter = 0;
    @track selectedWebhookPhoneField = '';
    @track selectedPhoneFieldVal = '';
    @track selectedPhoneFieldLabel = '';
    @track activeSectionName = 'webhookConfig'; // Default open section
    @track isWebhookConfigEdit = false;
    @track isChatWindowConfigEdit = false;
    @track isLoading = false;
    @track jsonData = '';
    @track configJson = '';
    @track warningMessage = false;
    @track showLicenseError = false;
    @track showPopup = false;
    @track showPopupWBConfig = false;
    @track showPopupChatConfig = false;

    // Fetch saved metadata on load
    async connectedCallback(){
        try {
            this.showSpinner = true;
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            
        this.loadSavedValues();
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

    // Load previously saved configuration
    loadSavedValues() {
        try {
            this.isLoading = true;
            getUserConfig()
                .then(data => {
                    const config = JSON.parse(data.ObjectConfigInfo);
                    
                    if(config != '{}'){
                        this.selectedObject = this.capitalizeFirstLetter(config.objectApiName) || 'Contact';
                        this.selectedWebhookPhoneField = config?.phoneField || '';
                        
                        // Store field values in an object
                        let savedFieldValues = config.requiredFields?.reduce((acc, field) => {
                            acc[field.name] = field.value;
                            return acc;
                        }, {});
        
                        this.loadRequiredFields(savedFieldValues);
                    } else {
                        this.isWebhookConfigEdit = true;
                    }

                    const chatConfig = JSON.parse(data.ChatWindowConfigInfo);
                    if(chatConfig != '{}'){
                        this.chatWindowRows = Object.keys(chatConfig).map((objectName) => {
                            const row = {
                                id: this.chatConfigCounter,
                                selectedObject: objectName,
                                selectedNameField: chatConfig[objectName].nameField,
                                selectedPhoneField: chatConfig[objectName].phoneField,
                                nameFieldOptions: [], // Will be populated after fetch
                                phoneFieldOptions: [], // Will be populated after fetch
                                objectOptions: [], // Row-specific options
                                isNameFieldDisabled: false,
                                isPhoneFieldDisabled: false
                            };
                            this.fetchFieldsForObject(row.id, objectName); // Fetch fields for pre-loaded rows
                            this.chatConfigCounter++;
                            return row;
                        });
                        this.updateRowObjectOptions();
                        if (this.chatWindowRows.length === 0) {
                            this.handleAddRow(); // Add one row if no config exists
                        }
                    } else {
                        this.isChatWindowConfigEdit = true;
                        this.handleAddRow();
                    }

                })
                .catch(error => {
                    console.error('Error fetching saved values:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                    if(this.objectOptions.length <= 0){
                        this.fetchObjects();
                    }
                });
        } catch (error) {
            console.error('Exception in loading saved values : ' , error);
        }
    }

    // fetches objects for picklist
    fetchObjects() {
        try {
            getObjectsWithPhoneField()
                .then(data => {
                    this.objectOptions = data.map(obj => ({
                        label: obj.label,  // Show friendly name
                        value: obj.value   // API name
                    }));
                    this.availableObjectOptions = [...this.objectOptions];
                    if(this.requiredFields.length <= 0){
                        this.loadRequiredFields();
                    }
                    this.updateRowObjectOptions();
                })
                .catch(error => {
                    console.error('Error fetching objects:', error);
                });
        } catch (error) {
            console.error('Exception in fetching objects : ' , error);
        }
    }

    // Load required fields based on the selected object and prefill saved values
    loadRequiredFields(savedFieldValues = {}) {
        try {
            this.isLoading = true;
            getRequiredFields({ objectName: this.selectedObject })
                .then(data => {
                    this.textFields = data[0]?.textFields;
                    
                    const apexPhoneField = this.selectedWebhookPhoneField;

                    this.phoneFields = data[0]?.phoneFields.map(field => {
                        return {
                            ...field,
                            isSelected: false
                        };
                    });
                    // Determine which phone field to select
                    let selectedField = null;
                    
                    if (apexPhoneField && this.phoneFields.some(field => field.value === apexPhoneField)) {
                        selectedField = this.phoneFields.find(field => field.value === apexPhoneField);
                    } else if (this.phoneFields.some(field => field.value === 'Phone')) {
                        selectedField = this.phoneFields.find(field => field.value === 'Phone');
                    } else {
                        selectedField = this.phoneFields[0] || null;
                    }
                    
                    // this.selectedPhoneFieldVal = this.phoneFields.find(field => field.value === 'Phone')?.value || this.phoneFields[0]?.value || '';
                    // const selectedField = this.phoneFields.find(field => field.value === 'Phone') || this.phoneFields[0] || null;
                    if (selectedField) {
                        this.selectedPhoneFieldVal = selectedField.value;
                        this.selectedPhoneFieldLabel = selectedField.label;
                        // Update isSelected based on selectedPhoneFieldVal
                        this.phoneFields = this.phoneFields.map(field => {
                            return {
                                ...field,
                                isSelected: field.value === this.selectedPhoneFieldVal
                            };
                        });
                    } else {
                        this.selectedPhoneFieldVal = '';
                        this.selectedPhoneFieldLabel = '';
                    }
                    this.phoneFieldsForChatConfig = [...this.phoneFields];

                    this.requiredFields = data[0]?.requiredFields.map(field => ({
                        apiName: field.name,
                        label: field.label,
                        type: this.capitalizeFirstLetter(field.type),
                        value: field.type === 'BOOLEAN' 
                                ? (savedFieldValues[field.name] !== undefined ? savedFieldValues[field.name] : false)
                                : field.type === 'DATE' 
                                    ? (savedFieldValues[field.name] || field.value || new Date().toISOString().split('T')[0])
                                    : field.type === 'DATETIME' 
                                        ? (savedFieldValues[field.name] || field.value || new Date().toISOString())
                                        : field.type === 'INTEGER' || field.type === 'DOUBLE' || field.type === 'CURRENCY'
                                            ? (savedFieldValues[field.name] || field.value || 0) 
                                            : (savedFieldValues[field.name] || field.value || ''),
                        picklistValues: field?.picklistValues,
                        relatedObject: field?.relatedObject,
                        relatedRecordName: field?.relatedRecordName,
                        isString: field.type === 'STRING',
                        isNumber: field.type === 'INTEGER' || field.type === 'DOUBLE' || field.type === 'CURRENCY',
                        isDate: field.type === 'DATE',
                        isDateTime: field.type === 'DATETIME',
                        isBoolean: field.type === 'BOOLEAN',
                        isPicklist: field.type === 'PICKLIST',
                        isReference: field.type === 'REFERENCE',
                        isTextArea: field.type === 'TEXTAREA'
                    }));
                    this.populateReferenceNames();
                })
                .catch(error => {
                    console.error('Error fetching required fields:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } catch (error) {
            console.error('Exception in loading required fields : ' , error);
        }
    }

    capitalizeFirstLetter(str) {
        if (!str) return str; // Handle null or undefined
        return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
    }

    // Handle object selection change
    handleObjectChange(event) {
        try {
            this.selectedObject = event.target.value;
            this.loadRequiredFields(); // Load fields for the new object
        } catch (error) {
            console.error('Error in object change : ' , error);
        }
    }

    populateReferenceNames() {
        try {
            const referenceFields = this.requiredFields.filter(field => 
                field.isReference && field.value && field.relatedObject
            );
    
            const namePromises = referenceFields.map(field =>
                getRecordName({ recordId: field.value, objectApiName: field.relatedObject })
                    .then(name => ({ apiName: field.apiName, name }))
                    .catch(error => {
                        console.error(`Error fetching name for ${field.apiName}:`, error);
                        return { apiName: field.apiName, name: '' }; // Default to empty on error
                    })
            );
    
            Promise.all(namePromises)
                .then(results => {
                    this.requiredFields = this.requiredFields.map(field => {
                        const result = results.find(r => r.apiName === field.apiName);
                        return result && field.isReference && !field.relatedRecordName
                            ? { ...field, relatedRecordName: result.name }
                            : field;
                    });
                })
                .catch(error => {
                    console.error('Error in Promise.all:', error);
                });
        } catch (error) {
            console.error('Exception in populating reference names:', error);
        }
    }

    // Handle input changes and update `requiredFields`
    handleInputChange(event) {
        try {
            const fieldName = event.target.dataset.field;
            const fieldIndex = this.requiredFields.findIndex(f => f.apiName === fieldName);
            if (fieldIndex !== -1) {
                this.requiredFields[fieldIndex].value = event.target.value;
            }
        } catch (error) {
            console.error('Error in input : ' , error);
        }
    }

    handleCheckboxChange(event) {
        try {
            const fieldName = event.target.dataset.field;
            const fieldIndex = this.requiredFields.findIndex(f => f.apiName === fieldName);
    
            if (fieldIndex !== -1) {
                this.requiredFields[fieldIndex].value = event.target.checked;
            }
        } catch (error) {
            console.error('Error in checkbox value change : ', error);
        }
    }

    handleRecordSelection(event){
        try {
            const fieldName = event.target.dataset.field;
            const selectedRecord = event.detail;

            if (selectedRecord?.recordId != null) {
                this.requiredFields = this.requiredFields.map(field =>
                    field.apiName === fieldName
                        ? { ...field, value: selectedRecord?.recordId }
                        : field
                );
            } else {
                this.requiredFields = this.requiredFields.map(field =>
                    field.apiName === fieldName
                        ? { ...field, value: '', relatedRecordName: '' }
                        : field
                );
            }
        } catch (error) {
            console.error('Error in record selection : ' ,  error);
        }
    }

    handleSelectionChange(event) {
        try {
            this.selectedPhoneFieldVal = event.target.value;
    
            const selectedField = this.phoneFields.find(field => field.value === this.selectedPhoneFieldVal);
            if (selectedField) {
                this.selectedPhoneFieldVal = selectedField.value;
                this.selectedPhoneFieldLabel = selectedField.label;
                
                // Update isSelected for all fields
                this.phoneFields = this.phoneFields.map(field => {
                    return {
                        ...field,
                        isSelected: field.value === this.selectedPhoneFieldVal
                    };
                });
            }
        } catch (error) {
            console.error('Error in selection change : ' ,  error);
        }
    }

    handleEdit(){
        this.isWebhookConfigEdit = true;
    }

    handleEditChatConfig(){
        this.isChatWindowConfigEdit = true;
    }

    handleCancel(){
        this.isLoading = true;
        this.loadSavedValues();
        this.isWebhookConfigEdit = false;
        this.isChatWindowConfigEdit = false;
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.activeSectionName = openSections;
    }

    handleSave() {
        try {
            const invalidFields = this.requiredFields.filter(field => 
                !field.isBoolean &&
                (field.isString || field.isNumber || field.isDate || field.isDateTime || field.isPicklist || field.isReference || field.isTextArea) &&
                (field.value === '' || field.value === null || field.value === undefined)
            );
    
            if (invalidFields.length > 0) {
                const fieldNames = invalidFields.map(field => field.apiName).join(', ');
                this.showToast('Error', `Please fill all required fields: ${fieldNames}`, 'error');
                return;
            }
    
            this.jsonData = JSON.stringify({
                objectApiName: this.selectedObject,
                phoneField: this.selectedPhoneFieldVal,
                requiredFields: this.requiredFields.map(field => ({
                    name: field.apiName,
                    value: field.value.toString(),
                    type: field.type
                }))
            });

            const config = {};
            this.chatWindowRows.forEach(row => {
                if (row.selectedObject && row.selectedNameField && row.selectedPhoneField) {
                    config[row.selectedObject] = {
                        nameField: row.selectedNameField,
                        phoneField: row.selectedPhoneField
                    };
                }
            });
            this.configJson = JSON.stringify(config);
            this.validatePhoneFieldMismatch(this.jsonData, this.configJson, 'webhook');

            if(!this.warningMessage){
                this.saveWebhookConfigCall();
            }
        } catch (error) {
            console.error('Exception in saving configuration: ', error);
        }
    }

    // Add a new row with preselected first available object, name, and phone
    async handleAddRow() {
        try {
            const availableOptions = this.getAvailableObjectOptions();
            const preselectedObject = availableOptions.length > 0 ? availableOptions[0].value : '';
    
            const newRow = {
                id: this.chatConfigCounter++,
                selectedObject: preselectedObject,
                selectedNameField: '',
                selectedPhoneField: '',
                nameFieldOptions: [],
                phoneFieldOptions: [],
                objectOptions: [...this.availableObjectOptions],
                isNameFieldDisabled: !preselectedObject,
                isPhoneFieldDisabled: !preselectedObject
            };
    
            this.chatWindowRows = [...this.chatWindowRows, newRow];
    
            if (preselectedObject) {
                await this.fetchFieldsForObject(newRow.id, preselectedObject);
                // Preselect first Name and Phone fields after fetching
                this.chatWindowRows = this.chatWindowRows.map(row => {
                    if (row.id === newRow.id) {
                        return {
                            ...row,
                            selectedNameField: row.nameFieldOptions.length > 0 ? row.nameFieldOptions[0].value : '',
                            selectedPhoneField: row.phoneFieldOptions.length > 0 ? row.phoneFieldOptions[0].value : ''
                        };
                    }
                    return row;
                });
            }
            this.updateRowObjectOptions(); // Update options for all rows
        } catch (error) {
            console.error('Error in adding new row', error);
        }
    }

    // Get available object options
    updateRowObjectOptions() {
        try {
            const availableOptions = this.getAvailableObjectOptions();
            this.chatWindowRows = this.chatWindowRows.map(row => {
                const rowOptions = [
                    { label: row.selectedObject, value: row.selectedObject }, // Include the selected object
                    ...availableOptions.filter(opt => opt.value !== row.selectedObject) // Add remaining available options
                ].filter(opt => opt.value); // Remove undefined/null options
                return { ...row, objectOptions: rowOptions };
            });
            this.availableObjectOptions = availableOptions;
        } catch (error) {
            console.error('Error in row objct option selection : ' , error);
        }
    }

    // Get available object options excluding selected objects
    getAvailableObjectOptions() {
        const selectedObjects = this.chatWindowRows.map(row => row.selectedObject).filter(obj => obj);
        return this.objectOptions.filter(option => !selectedObjects.includes(option.value));
    }

    // Fetch fields for the selected object
    async fetchFieldsForObject(rowId, objectName) {
        try {
            const result = await getTextAndPhoneFields({ objectName });
            const data = result[0];
            this.textFields = data.textFields || [];
            this.phoneFieldsForChatConfig = data.phoneFields || [];

            this.chatWindowRows = this.chatWindowRows.map(row => {
                if (row.id === parseInt(rowId)) {
                    return {
                        ...row,
                        nameFieldOptions: this.textFields.map(field => ({ label: field.label, value: field.value })),
                        phoneFieldOptions: this.phoneFieldsForChatConfig.map(field => ({ label: `${field.label} (${field.value})`, value: field.value }))
                    };
                }
                return row;
            });
        } catch (error) {
            console.error('Error fetching fields:', error);
        }
    }

    // Handle object selection
    async handleObjectChangeForChat(event) {
        try {
            const rowId = event.target.dataset.rowId;
            const selectedObject = event.target.value;
    
            this.chatWindowRows = this.chatWindowRows.map(row => {
                if (row.id === parseInt(rowId)) {
                    return {
                        ...row,
                        selectedObject,
                        selectedNameField: '', // Reset until fetched
                        selectedPhoneField: '', // Reset until fetched
                        nameFieldOptions: [],
                        phoneFieldOptions: [],
                        isNameFieldDisabled: false,
                        isPhoneFieldDisabled: false
                    };
                }
                return row;
            });
    
            if (selectedObject) {
                await this.fetchFieldsForObject(rowId, selectedObject);
                // Preselect first Name and Phone fields for this row only
                this.chatWindowRows = this.chatWindowRows.map(row => {
                    if (row.id === parseInt(rowId)) {
                        return {
                            ...row,
                            selectedNameField: row.nameFieldOptions.length > 0 ? row.nameFieldOptions[0].value : '',
                            selectedPhoneField: row.phoneFieldOptions.length > 0 ? row.phoneFieldOptions[0].value : ''
                        };
                    }
                    return row;
                });
            }
            this.updateRowObjectOptions();
        } catch (error) {
            console.error('Error in changing objects : ' , error);
        }
    }

    // Handle Name field selection
    handleNameFieldChange(event) {
        try {
            const rowId = event.target.dataset.rowId;
            const selectedNameField = event.target.value;
            this.chatWindowRows = this.chatWindowRows.map(row => {
                if (row.id === parseInt(rowId)) {
                    return { ...row, selectedNameField };
                }
                return row;
            });
        } catch (error) {
            console.error('Error in change Name picklist : ' , error);
        }
    }

    // Handle Phone field selection
    handlePhoneFieldChange(event) {
        try {
            const rowId = event.target.dataset.rowId;
            const selectedPhoneField = event.target.value;
            this.chatWindowRows = this.chatWindowRows.map(row => {
                if (row.id === parseInt(rowId)) {
                    return { ...row, selectedPhoneField };
                }
                return row;
            });
        } catch (error) {
            console.error('Error in changing Phone picklist : ' , error);
        }
    }

    // Handle row removal
    handleRemoveRow(event) {
        try {
            const rowId = event.target.dataset.rowId;
            this.chatWindowRows = this.chatWindowRows.filter(row => row.id !== parseInt(rowId));
            this.updateRowObjectOptions();
        } catch (error) {
            console.error('Error in removing row : ', error);
        }
    }

    // Save the configuration
    async handleSaveChatWindowConfig() {
        try {
            if(this.chatWindowRows.length === 0) {
                this.showToast('Error', 'At least one object row must be configured.', 'error');
                return;
            }

            // Validate all rows have required fields
            const invalidRows = this.chatWindowRows.filter(row => 
                !row.selectedObject || !row.selectedNameField || !row.selectedPhoneField
            );

            if (invalidRows.length > 0) {
                this.showToast('Error', 'All rows must have an Object, Name, and Phone field selected.', 'error');
                return; // Exit if validation fails
            }
            const config = {};
            this.chatWindowRows.forEach(row => {
                if (row.selectedObject && row.selectedNameField && row.selectedPhoneField) {
                    config[row.selectedObject] = {
                        nameField: row.selectedNameField,
                        phoneField: row.selectedPhoneField
                    };
                }
            });
            this.configJson = JSON.stringify(config);

            this.jsonData = JSON.stringify({
                objectApiName: this.selectedObject,
                phoneField: this.selectedPhoneFieldVal,
                requiredFields: this.requiredFields.map(field => ({
                    name: field.apiName,
                    value: field.value.toString(),
                    type: field.type
                }))
            });
            this.validatePhoneFieldMismatch(this.jsonData, this.configJson, 'chat');

            if(!this.warningMessage){
                this.saveChatConfigCall();
            }
        } catch (error) {
            this.showToast('Error', 'Error saving configuration: ' + error.body.message, 'error');
        }
    }

    validatePhoneFieldMismatch(jsonData, configJson, configType) {
        const config = JSON.parse(configJson);
        const jsonDataConfig = JSON.parse(jsonData);

        const objName = jsonDataConfig.objectApiName;
        const jsonPhoneField = jsonDataConfig.phoneField;
        
        if (config.hasOwnProperty(objName)) {
            const configPhoneField = config[objName].phoneField;

            if (jsonPhoneField !== configPhoneField) {
                this.warningMessage = true;
                this.showPopup = true;
                if(configType === 'webhook') {
                    this.showPopupWBConfig = true;
                } else if(configType === 'chat') {
                    this.showPopupChatConfig = true;
                }
                // this.showToast('Warning', `Warning: Phone field mismatch for ${objName}. Expected '${configPhoneField}', but got '${jsonPhoneField}'.`, 'warning');
                return;
            }
        }
    }

    handleSaveWBConfigPopup(){
        this.showPopupWBConfig = false;
        this.warningMessage = false;
        this.showPopup = false;
        this.saveWebhookConfigCall();
    }

    handleSaveChatConfigPopup(){
        this.showPopupChatConfig = false;
        this.warningMessage = false;
        this.showPopup = false;
        this.saveChatConfigCall();
    }

    handleCloseOnPopup(){
        this.showPopupWBConfig = false;
        this.showPopupChatConfig = false;
        this.showPopup = false;
        this.warningMessage = false;
        this.isLoading = false;
    }

    saveWebhookConfigCall(){
        this.isLoading = true;
        console.log(this.jsonData);
        
        saveUserConfig({ jsonData : this.jsonData })
            .then(response => {
                if(response == 'Success'){
                    this.showToast('Success', 'Configuration saved successfully', 'success');
                    this.populateReferenceNames();
                    this.isWebhookConfigEdit = false;
                } else {
                    this.showToast('Error', response, 'error');
                }
            })
            .catch(error => {
                console.error('Error saving config:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    saveChatConfigCall(){
        this.isLoading = true;
        saveUserConfig({ jsonDataForChat : this.configJson })
            .then(response => {
                if(response == 'Success'){
                    this.showToast('Success', 'Configuration saved successfully', 'success');
                    this.isChatWindowConfigEdit = false;
                } else {
                    this.showToast('Error', response, 'error');
                }
            })
            .catch(error => {
                console.error('Error saving config:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({title, message, variant}));
    }
}