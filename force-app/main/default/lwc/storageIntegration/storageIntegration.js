/**
 * Component Name: StorageIntegration
 * @description: Used LWC components to handle AWS configuration settings
 * Date: 19/03/2025
 * Created By: Kavya Trivedi
 */
import { LightningElement, track, api } from 'lwc';
import saveConfiguration from '@salesforce/apex/StorageIntegrationConfigController.saveConfiguration';
import getConfiguration from '@salesforce/apex/StorageIntegrationConfigController.getConfiguration';
import deleteRecordByAccessKey from '@salesforce/apex/StorageIntegrationConfigController.deleteRecordByAccessKey';
import checkLicenseUsablility from '@salesforce/apex/PLMSController.checkLicenseUsablility';
import AWS_logo from '@salesforce/resourceUrl/AWS_logo';
import NoData from '@salesforce/resourceUrl/NoData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class StorageIntegration extends LightningElement {

    @api recordId;

    @track accessKeyValue = '';
    @track secretAccessKeyValue = '';

    @track accessKey = '';
    @track secretAccessKey = '';
    @track s3BucketName = '';
    @track s3RegionName = '';
    @track createdDate = '';
    @track lastModifiedDate = '';
    
    @track AWS_logo = AWS_logo;
    @track isEditing = false;
    @track isDisabled = true;
    @track isFirstTime = false;
    @track showLicenseError = false;

    @track showNoData = true;
    AWS_logo = AWS_logo;
    NoData = NoData;

    /** 
    * Method Name: fetchConfiguration
    * @description: fetches configuration details
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    fetchConfiguration() {
        getConfiguration()
            .then(result => {
                if (result) {
                    this.accessKeyValue = result.MVWB__AWS_Access_Key__c || '';
                    this.secretAccessKeyValue = result.MVWB__AWS_Secret_Access_Key__c || '';
                    this.s3BucketNameValue = result.MVWB__S3_Bucket_Name__c || '';
                    this.s3RegionNameValue = result.MVWB__S3_Region_Name__c || '';
    
                    this.accessKey = this.accessKeyValue ? '*'.repeat(this.accessKeyValue.length) : '';
                    this.secretAccessKey = this.secretAccessKeyValue ? '*'.repeat(this.secretAccessKeyValue.length) : '';
                    this.s3BucketName = this.s3BucketNameValue || '';
                    this.s3RegionName = this.s3RegionNameValue || '';

                    this.createdDate = result.CreatedDate ? new Date(result.CreatedDate).toLocaleString() : '';
                    this.lastModifiedDate = result.LastModifiedDate ? new Date(result.LastModifiedDate).toLocaleString() : '';
    
                    this.isDisabled = true;
                    this.isEditing = false;
                    this.showNoData = !(this.accessKeyValue && this.secretAccessKeyValue && this.s3BucketNameValue && this.s3RegionNameValue);
                } else {
                    this.showNoData = true;
                }
            })
            .catch(error => {
                console.error(error);
                this.showNoData = true;
            });
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
            this.fetchConfiguration();
        } catch (error) {
            
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

    /** 
    * Method Name: handleNewClick
    * @description: Enables the form for entering a new AWS configuration
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    handleNewClick() {
        this.showNoData = false;
        this.isEditing = true;
        this.isDisabled = false; 
    }

    get hasDates() {
        return this.createdDate && this.lastModifiedDate;
    }

    /** 
    * Method Name: handleInput
    * @description: Handles user input
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    handleInput(event) {
        if(event.target.name == 'AccessKey'){
            this.accessKey = event.target.value;
            this.accessKey = this.accessKey.replaceAll(' ','');
            this.accessKeyValue = this.accessKey;
        } if(event.target.name == 'SecretAccessKey'){
            this.secretAccessKey = event.target.value;
            this.secretAccessKey = this.secretAccessKey.replaceAll(' ','');
            this.secretAccessKeyValue = this.secretAccessKey;
        } if(event.target.name == 'S3BucketName'){
            this.s3BucketName = event.target.value;
            this.s3BucketName = this.s3BucketName.replaceAll(' ','');
            this.s3BucketNameValue = this.s3BucketName;
        } if(event.target.name == 'S3RegionName'){
            this.s3RegionName = event.target.value;
            this.s3RegionName = this.s3RegionName.replaceAll(' ','');
            this.s3RegionNameValue = this.s3RegionName;
        }
    }
    
    /** 
    * Method Name: handleEdit
    * @description: Populates the input fields with existing configuration values
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    handleEdit(){
        this.accessKey = this.accessKeyValue;
        this.secretAccessKey = this.secretAccessKeyValue;
        this.s3BucketName = this.s3BucketNameValue;
        this.s3RegionName = this.s3RegionNameValue;
        this.isDisabled = false;
        this.isEditing = true;
    }

    /** 
    * Method Name: handleCancel
    * @description: Cancels the editing process and restores the previously saved values
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    handleCancel() {
        this.accessKey = '*'.repeat(this.accessKeyValue.length);
        this.secretAccessKey = '*'.repeat(this.secretAccessKeyValue.length);
        this.isEditing = false;
        this.isDisabled = true;
        this.fetchConfiguration();
    }
    
    /** 
    * Method Name: handleSave
    * @description: Saves the storage configuration details
    * Date: 19/03/2025
    * Created By: Kavya Trivedi 
    */
    handleSave() {

        if (!this.accessKey || !this.secretAccessKey || !this.s3BucketName|| !this.s3RegionName) {
            this.showToast('Success', 'Please Enter value for all the Fields', 'error');
            return;
        }

        saveConfiguration({accessKey : this.accessKey, regionName : this.s3RegionName , secretAccessKey : this.secretAccessKey, bucketName : this.s3BucketName})
        .then(() => {
            this.showToast('Success', 'Saved successfully', 'success');

            this.accessKey = '*'.repeat(this.accessKeyValue.length);
            this.secretAccessKey = '*'.repeat(this.secretAccessKeyValue.length);
            this.isDisabled = true;
            this.isEditing = false;
            this.isFirstTime = false;

            this.fetchConfiguration();
        })
        .catch(error => {
            this.showToast('Error', error.message.body, 'error');
        });
    }

    /** 
    * Method Name: handleDeactivate
    * @description: Deletes the record associated with the access key
    * Date: 19/03/2025
    * Created By: Kavya Trivedi
    */
    async handleDeactivate() {
        try {
            const result = await deleteRecordByAccessKey({ accessKey: this.accessKeyValue });
            this.showToast('Success', 'Record has been deactivated successfully', 'success');
            this.showNoData = true;
            this.fetchConfiguration();
        } catch (error) {
            console.error("Error deleting record:", error);
            this.showToast('Error', 'Failed to deactivate record', 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}