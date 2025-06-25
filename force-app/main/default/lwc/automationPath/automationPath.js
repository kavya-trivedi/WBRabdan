import { LightningElement, track, api } from 'lwc';
import getAutomationById from '@salesforce/apex/AutomationConfigController.getAutomationById';
import getTemplates from "@salesforce/apex/AutomationConfigController.getTemplates";
import getEmailTemplates from "@salesforce/apex/AutomationConfigController.getEmailTemplates";
import saveAutomationPaths from '@salesforce/apex/AutomationConfigController.saveAutomationPaths';
import getAutomationPathsByAutomationId from '@salesforce/apex/AutomationConfigController.getAutomationPathsByAutomationId';
import getAllObjects from '@salesforce/apex/AutomationConfigController.getAllObjects';
import getUsedObjectNamesByTemplate from '@salesforce/apex/AutomationConfigController.getUsedObjectNamesByTemplate';
import getRequiredFields from '@salesforce/apex/AutomationConfigController.getRequiredFields';
import getObjectFields from '@salesforce/apex/AutomationConfigController.getObjectFields';
import getFlowIdFromAutomation from '@salesforce/apex/AutomationConfigController.getFlowIdFromAutomation';
import getFlowFields from '@salesforce/apex/AutomationConfigController.getFlowFields';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class AutomationPath extends NavigationMixin(LightningElement) {
    @api recordId;
    @api templateType;

    @track selectedTemplateButtonId = '';
    @track selectedAction = '';
    @track searchTerm = '';
    @track selectedTemplateId = null;
    @track isFlowTemplate = false;
    // @track isScheduled = false;
    @track selectedObject = '';
    @track FlowId = '';
    @track FlowRecordId = '';
    @track isEdit = false;
    @track showLicenseError = false;
    @track isLoading = false;
    // @track isFlowAutomationCreated = false;

    // --- Data Properties ---
    @track automation = {};
    @track allWhatsAppTemplates = [];
    @track quickReplyButtons = [];
    @track automationPaths = {};
    @track allEmailTemplates = [];
    @track allObjects = [];
    @track usedObjects = [];
    @track requiredFields = [];
    @track objectFields = [];
    @track flowFields = [];
    @track chatWindowRows = [];
    @track chatWindowRows1 = [];
    @track chatWindowRows2 = [];
    // @track durationUnits = [
    //     { label: 'Minutes', value: 'minutes' },
    //     { label: 'Hours', value: 'hours' },
    //     { label: 'Days', value: 'days' }
    // ];

    typeCompatibilityMap = {
        STRING: ["TextInput", "Text"],
        PICKLIST: ["Dropdown", "CheckboxGroup", "ChipSelector", "RadioButtonsGroup"],
        NUMBER: ["TextInput"],
        DOUBLE: ["TextInput"],
        EMAIL: ["TextInput"],
        PHONE: ["TextInput"],
        CHECKBOX: ["OptIn", "Checkbox"],
        TEXTAREA: ["TextArea", "Text"],
        MULTIPICKLIST: ["CheckboxGroup", "ChipSelector", "RadioButtonsGroup"],
        DATE: ["DatePicker"],
        DATETIME: ["DateTimePicker"],
        URL: ["EmbeddedLink"]
    };


    async connectedCallback() {
        try {
            
            await this.checkLicenseStatus();
            if (this.showLicenseError) {
                return; // Stops execution if license is expired
            }
            if(this.pageRef){
                this.objectApiName = this.pageRef.attributes.objectApiName;
            }

            // console.log('Automation Path Loaded with Record ID:', this.recordId);
            // console.log('Automation Path Loaded with Template Type:', this.templateType);
    
            if (!this.recordId) return;
    
            this.isFlowTemplate = this.templateType === 'Flow';
            this.selectedAction = this.isFlowTemplate ? 'create' : 'whatsapp';
    
            // console.log('isFlowTemplate:', this.isFlowTemplate);
    
            this.isFlowTemplate
                ? (this.loadObjects(), this.loadRequiredFields(), this.setFlowId())
                : (this.fetchTemplates(), this.loadEmailTemplates());
    
            await this.fetchAutomationName();
            
        } catch (error) {
            console.error('Error in connectedCallback:::', e.message);
        }
    }

    async checkLicenseStatus() {
        try {
            const isLicenseValid = await checkLicenseUsablility();
            // console.log('isLicenseValid => ', isLicenseValid);
            if (!isLicenseValid) {
                this.showLicenseError = true;
            }
        } catch (error) {
            console.error('Error checking license:', error);
        }
    }

    loadObjects() {
        getAllObjects()
            .then(data => {
                // this.allObjects = data.map(obj => ({ label: obj, value: obj }));
                this.objects = data.sort((a, b) => a.label.localeCompare(b.label));
                this.allObjects = data.map(obj => ({
                    label: obj.label,
                    value: obj.value
                }));
            })
            .catch(error => console.error('Error fetching objects:', error));

        // console.log('this.allObjects =', JSON.stringify(this.allObjects));
    }

    loadRequiredFields(savedFieldValues = {}) {
        // console.log('LOADING REQUIRED FIELDS');
        try {
            this.isLoading = true;
            if (!this.selectedObject) {
                // console.log('No object selected');
                return;
            }
            getRequiredFields({ objectName: this.selectedObject })
                .then(data => {
                    const excludedFields = ['OwnerId', 'IsConverted', 'IsUnreadByOwner', 'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'LastViewedDate', 'LastReferencedDate'];
                    this.requiredFields = data[0]?.requiredFields
                        .filter(field => !excludedFields.includes(field.name))
                        .map(field => ({
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
                    // console.log('this.requiredFields:', JSON.stringify(this.requiredFields));

                    this.chatWindowRows1 = this.requiredFields.map((field, index) => ({
                        id: `${field.apiName}-${index}`,
                        selectedObject: this.selectedObject,
                        selectedObjectField: field.apiName,
                        selectedObjectFieldType: field.type,
                        filteredFlowFields: this.getFilteredFlowFields(field.type),
                        isObjectFieldDisabled: true,
                        isRequired: true
                    }));

                    // console.log('this.chatWindowRows1:', JSON.stringify(this.chatWindowRows1));
                    // const combinedMap = new Map(
                    //     this.chatWindowRows2.map(row => [row.selectedObjectField, row])
                    // );

                    // const mergedRows = this.chatWindowRows1.map(row => {
                    //     const match = combinedMap.get(row.selectedObjectField);
                    //     return {
                    //         ...row,
                    //         isRequired: match ? true : row.isRequired
                    //     };
                    // });

                    // Now add chatWindowRows2 items that weren't already in chatWindowRows1
                    // const existingFields = new Set(this.chatWindowRows1.map(row => row.selectedObjectField));
                    // const additionalRows = this.chatWindowRows2.filter(row => !existingFields.has(row.selectedObjectField));

                    // const finalRows = [...mergedRows, ...additionalRows];


                    //
                    // Create a map from chatWindowRows using selectedObjectField as the key
                    const isRequiredMap = new Map(
                        this.chatWindowRows1.map(row => [row.selectedObjectField, row.isRequired])
                    );
                    const isRequiredMap2 = new Map(
                        this.chatWindowRows1.map(row => [row.selectedObjectField, row.isRequired])
                    );

                    // Build the final array based on chatWindowRows2
                    var finalRows;

                    if (this.isEdit) {

                        finalRows = this.chatWindowRows2.map(row => {
                            const isRequiredOverride = isRequiredMap.get(row.selectedObjectField);
                            return {
                                ...row,
                                isRequired: isRequiredOverride !== undefined ? isRequiredOverride : row.isRequired
                            };
                        });
                    } else {
                        finalRows = this.chatWindowRows1.map(row => {
                            const isRequiredOverride = isRequiredMap.get(row.selectedObjectField);
                            return {
                                ...row,
                                isRequired: isRequiredOverride !== undefined ? isRequiredOverride : row.isRequired
                            };
                        });
                    }
                    // console.log('finalRows:', JSON.stringify(finalRows));
                    this.chatWindowRows = finalRows;
                    // console.log('CHAT WINDOW ROWS:', JSON.stringify(this.chatWindowRows));
                    // console.log('this.chatWindowRows1:', JSON.stringify(this.chatWindowRows1));

                    // this.fetchAutomationPaths();
                })
                .catch(error => {
                    console.error('Error fetching required fields:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } catch (error) {
            console.error('Exception in loading required fields : ', error);
        }
    }

    setFlowId() {
        getFlowIdFromAutomation({ automationId: this.recordId })
            .then((data) => {
                this.FlowId = data;
                // console.log('Flow Id:', this.FlowId);
                this.loadFlowFields();
            })
            .catch((error) => {
                console.error('Error setting flow Id:', error);
            });
    }

    loadFlowFields() {
        // console.log('Loading Flow Fields for Flow ID:', this.FlowId);
        getFlowFields({ flowId: this.FlowId })
            .then((jsonData) => {
                jsonData = JSON.parse(jsonData);
                // console.log('Flow JSON Data:', JSON.stringify(jsonData));
                const data = this.extractFlowFieldTypes(jsonData.screens);
                const keys = Object.keys(data);
                this.flowFields = keys.map(key => ({
                    label: key,
                    value: key,
                    type: data[key]
                }));
                // console.log('Formatted combobox options:', JSON.stringify(this.flowFields));
            })
            .catch((error) => {
                console.error('Error fetching flow JSON:', error);
            });
    }

    // extractFlowFieldTypes(screens) {
    //     const flowFieldTypes = {};

    //     screens.forEach(screen => {
    //         // console.log('Screen:', JSON.stringify(screen));
    //         const children = screen.layout?.children || [];
    //         children.forEach(child => {
    //             if (child.type === 'Form') {
    //                 child.children?.forEach(field => {
    //                     if (field.name) {
    //                         flowFieldTypes[field.name] = field.type;
    //                     }
    //                 });
    //             }
    //         });
    //     });

    //     return flowFieldTypes;
    // }

    extractFlowFieldTypes(screens) {
        const fieldTypes = {};

        screens.forEach((screen, screenIndex) => {
            const layoutChildren = screen?.layout?.children || [];

            layoutChildren.forEach(child => {
                if (child.type === 'Form' && Array.isArray(child.children)) {
                    const formElements = child.children;

                    formElements.forEach(formElement => {
                        if (formElement.type === 'Footer' && formElement['on-click-action']?.payload) {
                            const payload = formElement['on-click-action'].payload;

                            for (const fieldKey in payload) {
                                const expression = payload[fieldKey];
                                // Match pattern like ${form.Purchase_experience}
                                const match = expression.match(/\${form\.(\w+)}/);
                                if (match) {
                                    const fieldName = match[1];
                                    const matchingElement = formElements.find(el => el.name === fieldName);
                                    if (matchingElement) {
                                        const dataType = matchingElement.type;
                                        // Basic mapping UI type to general data type
                                        // const dataType = this.mapUiTypeToDataType(uiType);
                                        fieldTypes[fieldKey] = dataType;
                                    }
                                }
                            }
                        }
                    });
                }
            });

            // Additionally, check screen.data for direct type mappings
            if (screen.data) {
                for (const key in screen.data) {
                    if (!fieldTypes[key] && screen.data[key]?.type) {
                        fieldTypes[key] = screen.data[key].type;
                    }
                }
            }
        });

        return fieldTypes;
    }

    fetchTemplates() {
        getTemplates()
            .then((result) => {
                if (result) {
                    // console.log("Templates Result:", JSON.stringify(result));
                    this.allWhatsAppTemplates = result.map(template => ({
                        Id: template.Id,
                        Name: template.MVWB__Template_Name__c
                    }));
                }
            })
            .catch((error) => {
                console.error("Error fetching templates:", error);
            });
    }

    loadEmailTemplates() {
        getEmailTemplates()
            .then((data) => {
                this.allEmailTemplates = data;
            })
            .catch((error) => {
                console.error('Error fetching Email templates:', error);
                this.allEmailTemplates = [];
            });
    }

    fetchAutomationName() {
        return getAutomationById({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    this.automation = {
                        id: result.Id,
                        name: result.Name,
                        description: result.MVWB__Description__c,
                        templateId: result.MVWB__WB_Template__c || '',
                        templateName: result.MVWB__WB_Template__r?.MVWB__Template_Name__c || '',
                        templateType: result.MVWB__WB_Template__r?.MVWB__Template_Type__c || ''
                    };

                    // console.log('this.automation =', JSON.stringify(this.automation));
                    if (result.MVWB__WB_Template__r?.MVWB__WBButton_Body__c) {
                        try {
                            const buttons = JSON.parse(result.MVWB__WB_Template__r.MVWB__WBButton_Body__c);
                            // console.log('BUTTONS =', buttons);
                            this.quickReplyButtons = buttons
                                .filter(button => button.type === "QUICK_REPLY")
                                .map(button => ({
                                    id: button.text,
                                    label: button.text
                                }));

                            this.quickReplyButtons.forEach(button => {
                                this.automationPaths[button.id] = null;
                            });

                        } catch (error) {
                            console.error("Error parsing MVWB__WBButton_Body__c:", error);
                        }
                    }
                    // console.log('this.quickreplybuttons:', JSON.stringify(this.quickReplyButtons));
                    this.fetchAutomationPaths();
                }
            })
            .catch(error => {
                console.error('Error fetching automation:', error);
            });
    }

    fetchAutomationPaths() {
        if (!this.recordId) {
            return;
        }

        getAutomationPathsByAutomationId({ automationId: this.recordId })
            .then((result) => {
                // console.log('Fetched Automation Paths:', JSON.stringify(result));

                if (!this.isFlowTemplate) {

                    // console.log('this.isFlowTemplate:', this.isFlowTemplate);
                    // Convert the fetched records into a structured object
                    const automationPathsMap = {};
                    result.forEach(path => {
                        automationPathsMap[path.MVWB__Button_Value__c] = {
                            templateId: path.MVWB__Action_Template__c || path.MVWB__Action_Email_Template__c || null,
                            templateType: path.MVWB__Action_Type__c === "Send Message" ? "whatsapp" : "email"
                        };
                    });

                    // Ensure all quick reply buttons have an entry in automationPaths
                    this.quickReplyButtons.forEach(button => {
                        if (!automationPathsMap[button.id]) {
                            automationPathsMap[button.id] = null;
                        }
                    });

                    this.automationPaths = automationPathsMap;

                    this.selectedTemplateButtonId = this.quickReplyButtons[0]?.id || '';
                    this.selectedTemplateId = this.automationPaths[this.selectedTemplateButtonId]?.templateId || null;
                    this.selectedAction = this.automationPaths[this.selectedTemplateButtonId]?.templateType || 'whatsapp';
                } else {
                    const existingFlowPath = result.find(path => path.MVWB__Action_Type__c === 'Create a Record');

                    if (existingFlowPath) {

                        this.isEdit = true;

                        // console.log('Flow Path:', JSON.stringify(existingFlowPath));
                        this.FlowRecordId = existingFlowPath.Id || '';
                        this.selectedObject = existingFlowPath.MVWB__Object_Name__c || '';
                        // console.log('this.selectedObject :', this.selectedObject);

                        this.loadFlowFields();
                        // console.log('After JSON DATA');

                        // this.fetchFieldsForObject(this.selectedObject);
                        getObjectFields({ objectName: this.selectedObject })
                            .then((result) => {
                                // console.log('fetchFieldsForObjects after apex:- ', JSON.stringify(result))
                                this.objectFields = result;
                                
                                const fieldMapping = JSON.parse(existingFlowPath.MVWB__Field_Mapping__c || '{}');
                                // console.log('fieldMapping :', JSON.stringify(fieldMapping));

                                this.chatWindowRows2 = [];

                                Object.entries(fieldMapping).forEach(([flowField, objectFields], index) => {
                                    objectFields.forEach((objectField, subIndex) => {
                                        this.chatWindowRows2.push({
                                            id: `row-${index}-${subIndex}`,
                                            selectedObject: this.selectedObject,
                                            selectedObjectField: objectField,
                                            filteredFlowFields: this.getFilteredFlowFields(
                                                this.objectFields.find(field => field.value === objectField)?.type || ''
                                            ),
                                            selectedFlowField: flowField,
                                            isRequired: this.isFieldRequired(objectField),
                                            isObjectFieldDisabled: this.isFieldRequired(objectField),
                                        });
                                    });
                                });

                                this.loadRequiredFields();
                            })
                            .catch((error) => {
                                console.error('Error fetching object fields:', error);
                            });
                        // console.log('this.objectFields fetchFieldsForObject:- ', JSON.stringify(this.objectFields));

                        this.FlowId = existingFlowPath.MVWB__WB_Flow__c || '';

                    } else {
                        // No existing flow automation path found
                        this.selectedObject = '';
                        this.FlowId = '';
                        this.chatWindowRows = [];
                        this.FlowRecordId = '';
                    }
                }
            })
            .catch((error) => {
                console.error('Error fetching automation paths:', error);
                this.automationPaths = {};
            });
    }

    // getFilteredFlowFields(objectFieldType) {
    //     objectFieldType = objectFieldType.toUpperCase();
    //     // console.log('Called with objectFieldType:', objectFieldType);
    //     const compatibleTypes = (this.typeCompatibilityMap[objectFieldType] || []).map(t => t.toUpperCase());
    //     // console.log('Compatible Types:', JSON.stringify(compatibleTypes));
    //     // console.log('All Flow Fields:', JSON.stringify(this.flowFields, null, 2));
    //     // console.log('this.flowFields ::: ', JSON.stringify(this.flowFields));

    //     return this.flowFields
    //         .filter(field => {
    //             const match = compatibleTypes.includes(field.type?.toUpperCase());
    //             // console.log(`Checking field: ${field.label}, type: ${field.type}, match: ${match}`);
    //             return match;
    //         })
    //         .map(field => ({ label: field.label, value: field.value }));
    // }

    getFilteredFlowFields(objectFieldType) {
        objectFieldType = objectFieldType.toUpperCase();
        // console.log('Called with objectFieldType:', objectFieldType);

        const compatibleTypes = (this.typeCompatibilityMap[objectFieldType] || []).map(t => t.toUpperCase());

        // console.log('this.flowFields ::: ', JSON.stringify(this.flowFields));

        return this.flowFields
            .filter(field => {
                let fieldType = field.type?.toUpperCase();

                // For TextInput, adjust type based on input-type
                if (fieldType === "TEXTINPUT" && field["input-type"]) {
                    fieldType = `TEXTINPUT(${field["input-type"].toUpperCase()})`;
                }

                return compatibleTypes.includes(fieldType);
            })
            .map(field => ({ label: field.label, value: field.value }));
    }

    fetchFieldsForObject(objectName) {
        try {
            // console.log('Fetching fields for object:', objectName);
            getObjectFields({ objectName: objectName })
                .then((result) => {
                    // console.log('fetchFieldsForObjects after apex:- ',JSON.stringify(result))
                    this.objectFields = result;
                });
            // console.log('this.objectFields fetchFieldsForObject:- ', JSON.stringify(this.objectFields));
        } catch (error) {
            console.error('Error fetching fields:', error);
        }
    }

    // --- Getters for Dynamic UI ---

    get templateButtons() {
        return this.quickReplyButtons.map(btn => ({
            ...btn,
            computedClass: this.selectedTemplateButtonId === btn.id
                ? 'slds-button slds-button_outline-brand slds-button_stretch selected-button'
                : 'slds-button slds-button_outline-brand slds-button_stretch'
        }));
    }

    get isWhatsAppView() {
        return this.selectedAction === 'whatsapp';
    }

    get isEmailView() {
        return this.selectedAction === 'email';
    }

    get whatsappButtonVariant() {
        return this.selectedAction === 'whatsapp' ? 'brand' : 'neutral';
    }

    get emailButtonVariant() {
        return this.selectedAction === 'email' ? 'brand' : 'neutral';
    }

    get createButtonVariant() {
        return this.selectedAction === 'create' ? 'brand' : 'neutral';
    }

    // get scheduleButtonVariant() {
    //     return this.isScheduled === true ? 'brand' : 'neutral';
    // }

    // get immediateButtonVariant() {
    //     return this.isScheduled === true ? 'neutral' : 'brand';
    // }

    get filteredWhatsAppTemplates() {
        const lowerSearchTerm = this.searchTerm.toLowerCase();

        let filtered = [];

        if (this.isWhatsAppView) {
            filtered = this.allWhatsAppTemplates.filter(template =>
                template.Name.toLowerCase().includes(lowerSearchTerm)
            );
        } else if (this.isEmailView) {
            filtered = this.allEmailTemplates.filter(template =>
                template.Name.toLowerCase().includes(lowerSearchTerm)
            );
        }

        return filtered.map(template => ({
            ...template,
            computedClass: this.selectedTemplateId === template.Id
                ? 'slds-p-around_small slds-border_bottom list-item selected-item'
                : 'slds-p-around_small slds-border_bottom list-item'
        }));
    }

    get hasFilteredTemplates() {
        return this.filteredWhatsAppTemplates.length > 0;
    }


    // --- Event Handlers ---

    handleTemplateButtonClick(event) {
        this.selectedTemplateButtonId = event.target.dataset.id;
        // console.log('Selected Template Button:', this.selectedTemplateButtonId);

        if (this.automationPaths[this.selectedTemplateButtonId]) {
            this.selectedTemplateId = this.automationPaths[this.selectedTemplateButtonId].templateId;
            this.selectedAction = this.automationPaths[this.selectedTemplateButtonId].templateType;
        } else {
            this.selectedTemplateId = '';
        }
    }

    handleActionChange(event) {
        this.selectedAction = event.target.value;
        // console.log('Selected Action:', this.selectedAction);
        // Reset specific view states if needed when changing tabs
        this.searchTerm = '';
        this.selectedTemplateId = null;
    }

    // handleSendOptionChange(event) {
    //     this.isScheduled = event.target.value === 'scheduled';
    //     // console.log('Send Option:', this.isScheduled);
    // }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleTemplateSelect(event) {
        this.selectedTemplateId = event.currentTarget.dataset.id;
        // console.log('Selected WhatsApp Template:', this.selectedTemplateId);

        if (this.selectedTemplateButtonId && this.selectedAction) {
            this.automationPaths[this.selectedTemplateButtonId] = {
                templateId: this.selectedTemplateId,
                templateType: this.selectedAction,
            };
        }

        // console.log('Updated automationPaths:', JSON.stringify(this.automationPaths));
    }

    // handleDurationValueChange(event) {
    //     this.durationValue = event.target.value;
    //     // console.log('Selected Duration Value:', this.durationValue);
    // }

    // handleDurationUnitChange(event) {
    //     this.durationUnit = event.target.value;
    //     // console.log('Selected Duration Unit:', this.durationUnit);
    // }

    handleCancel() {
        this.selectedTemplateButtonId = '';
        this.selectedAction = '';
        this.searchTerm = '';
        this.selectedTemplateId = null;
        this.isFlowTemplate = false;
        this.automation = {};
        this.allWhatsAppTemplates = [];
        this.quickReplyButtons = [];
        this.automationPaths = {};
        this.allEmailTemplates = [];
        this.allObjects = [];
        // console.log('Cancel clicked');

        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
                apiName: 'MVWB__Automation_Configuration'
            },
        });
    }

    handleSave() {
        try {
            this.isLoading = true;
            // console.log('saveAutomationPath triggered');
    
            if (!this.isFlowTemplate) {
    
                const atLeastOneButtonHasTemplate = Object.values(this.automationPaths).some(value => value !== null);
    
                if (!atLeastOneButtonHasTemplate) {
                    this.showToast('Error', 'Please select a template for at least one button before saving.', 'error');
                    this.isLoading = false;
                    return;
                }
                console.log('this.automationPaths:', JSON.stringify(this.automationPaths));
                
                const automationPathRecords = Object.entries(this.automationPaths)
                .filter(([button, value]) => value !== null && typeof value === 'object')
                .map(([button, { templateId, templateType }]) => {
                    let actionType = "Send Email";
                    let actionTemplate = null;
                    let actionEmailTemplate = null;
    
                    if (templateType === "whatsapp") {
                        actionType = "Send Message";
                        actionTemplate = templateId;
                    } else {
                        actionEmailTemplate = templateId;
                    }
    
                    return {
                    MVWB__Automation__c: this.recordId,
                    MVWB__Button_Value__c: button,
                    MVWB__Action_Type__c: actionType,
                    MVWB__Action_Template__c: actionTemplate,
                    MVWB__Action_Email_Template__c: actionEmailTemplate
                    };
                });
    
            // console.log('Saving Automation Paths:', JSON.stringify(automationPathRecords));
    
                saveAutomationPaths({ automationPaths: automationPathRecords })
                    .then((result) => {
                        this.showToast('Success', `Automation Paths saved successfully.`, 'success');
                        this.isLoading = false;
                        this[NavigationMixin.Navigate]({
                            type: "standard__navItemPage",
                            attributes: {
                            apiName: 'MVWB__Automation_Configuration'
                            },
                        });
                        this.isLoading = false;
                    })
                    .catch((error) => {
                        this.showToast('Error', `Failed to save automation paths.`, 'error');
                        this.isLoading = false;
                    })
            } else {
                const fields = {};
    
                if (!this.selectedObject) {
                    this.showToast('Error', 'Please select an object.', 'error');
                    return;
                }
    
                // Check for any empty selectedFlowField
                const hasEmptyFlowField = this.chatWindowRows.some(row => !row.selectedFlowField);
                if (hasEmptyFlowField) {
                    this.showToast('Error', 'Please map all fields before saving.', 'error');
                    return;
                }
    
                // Check for duplicate selectedObjectField values
                const selectedObjectFields = new Set();
                let hasDuplicates = false;
    
                for (let row of this.chatWindowRows) {
                    const field = row.selectedObjectField;
                    if (field) {
                        if (selectedObjectFields.has(field)) {
                            hasDuplicates = true;
                            break;
                        }
                        selectedObjectFields.add(field);
                    }
                }
    
                if (hasDuplicates) {
                    this.showToast('Error', 'Each object field must be mapped uniquely.', 'error');
                    this.isLoading = false;
                    return;
                }
    
            fields.MVWB__Automation__c = this.recordId;
            fields.MVWB__Action_Type__c = 'Create a Record';
                // 1. Object Name
            fields.MVWB__Object_Name__c = this.selectedObject;
    
                // 2. Field Mapping
                const mapping = {};
                // this.chatWindowRows.forEach(row => {
                //     if (row.selectedFlowField && row.selectedObjectField) {
                //         mapping[row.selectedFlowField] = row.selectedObjectField;
                //     }
                // });
                this.chatWindowRows.forEach(row => {
                    if (row.selectedFlowField && row.selectedObjectField) {
                        if (!mapping[row.selectedFlowField]) {
                            mapping[row.selectedFlowField] = [];
                        }
                        mapping[row.selectedFlowField].push(row.selectedObjectField);
                    }
                });
    
            fields.MVWB__Field_Mapping__c = JSON.stringify(mapping);
            fields.MVWB__WB_Flow__c = this.FlowId;
    
                if (this.FlowRecordId) {
    
                // console.log('Updating existing record with ID:', this.FlowRecordId);
    
                    fields.Id = this.FlowRecordId;
                    // console.log('Fields to save:', JSON.stringify(fields));
    
                    const updateInput = { fields };
                    updateRecord(updateInput)
                        .then(() => {
                            this.showToast('Success', 'Record updated successfully', 'success');
                            this.isLoading = false;
                            this[NavigationMixin.Navigate]({
                                type: "standard__navItemPage",
                                attributes: {
                                apiName: 'MVWB__Automation_Configuration'
                                },
                            });
                            this.isLoading = false;
                        })
                        .catch(error => {
                            console.error('Error updating record', error);
                            this.showToast('Error', 'Error updating record', 'error');
                            this.isLoading = false;
                        });
                } else {
    
                    // console.log('Creating new record');
                    // console.log('Fields to save:', JSON.stringify(fields));
                const recordInput = { apiName: 'MVWB__Automation_Path__c', fields };
    
                    createRecord(recordInput)
                        .then(result => {
                            // console.log('result = ', JSON.stringify(result));
                            this.showToast('Success', 'Record saved successfully', 'success');
                            this.isLoading = false;
                            this[NavigationMixin.Navigate]({
                                type: "standard__navItemPage",  
                                attributes: {
                                apiName: 'MVWB__Automation_Configuration'
                                },
                            });
                            this.isLoading = false;
                        })
                        .catch(error => {
                            console.error('Error saving record', JSON.stringify(error));
                            this.showToast('Error', 'Error saving record', 'error');
                            this.isLoading = false;
                        });
                }
            }
            this.isLoading = false;
        } catch (error) {
            console.error('Error in handleSave:', error);
            this.showToast('Error', 'An unexpected error occurred while saving.', 'error');
            this.isLoading = false;
        }
    }

    handleObjectChange(event) {
        try {
            this.isEdit = false;
            this.selectedObject = event.target.value;
            // console.log('Selected Object:', this.selectedObject);
            
            getUsedObjectNamesByTemplate({ templateId: this.automation.templateId })
            .then(usedObjects => {
                // console.log('this.templateId:', this.templateId);
                // console.log('Used Objects:', JSON.stringify(usedObjects));
                if (usedObjects.includes(this.selectedObject)) {
                    this.showToast('Error', 'This object is already being used in an automation.', 'error');
                    this.selectedObject = '';
                }

                this.loadRequiredFields();
                this.objectFields = [];
                this.fetchFieldsForObject(this.selectedObject);
            })
            .catch(error => {
                console.error('Error fetching used object names:', JSON.stringify(error));
            });
        } catch (error) {
            console.error('Error in object change : ', error);
        }
    }

    addMappingRow() {
        const newRow = {
            id: `row-${Date.now()}`,
            selectedObject: this.selectedObject,
            selectedObjectField: '',
            selectedObjectFieldType: '',
            isObjectFieldDisabled: false,
            isRequired: false
        };
        this.chatWindowRows = [...this.chatWindowRows, newRow];
    }

    handleObjectFieldChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.detail.value;
        // console.log('Value in handleObjectFieldChange:', value);
        const fieldType = this.objectFields.find(field => field.value === value)?.type || '';
        this.chatWindowRows = this.chatWindowRows.map(row =>
            row.id === rowId ? {
                ...row,
                selectedObjectField: value,
                selectedObjectFieldType: fieldType,
                filteredFlowFields: this.getFilteredFlowFields(fieldType),
                selectedFlowField: ''
            } : row
        );
        // console.log('this.chatWindowRows:', JSON.stringify(this.chatWindowRows));
        // console.log('this.getFilteredFlowFields:', JSON.stringify(this.getFilteredFlowFields(fieldType)));
    }

    handleObjectChangeForChat(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.detail.value;
        this.chatWindowRows = this.chatWindowRows.map(row =>
            row.id === rowId ? { ...row, selectedFlowField: value } : row
        );
        // console.log('this.chatWindowRows in handleObjectChangeForChat:', JSON.stringify(this.chatWindowRows));
    }

    handleDeleteRow(event) {
        const rowId = event.target.dataset.rowId;
        this.chatWindowRows = this.chatWindowRows.filter(row => row.id !== rowId);
    }

    capitalizeFirstLetter(str) {
        if (!str) return str;
        return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
    }

    isFieldRequired(apiName) {
        // console.log('this.requiredFields', JSON.stringify(this.requiredFields));
        if (!this.requiredFields || this.requiredFields.length === 0) {
            return false;
        }

        return this.requiredFields.some(field => field.apiName === apiName);
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