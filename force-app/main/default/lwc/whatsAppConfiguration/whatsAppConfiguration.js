import { LightningElement, track } from 'lwc';
import saveWhatsAppConfiguration from '@salesforce/apex/WhatsAppConfigurationController.saveConfiguration';
import getWhatsAppConfiguration from '@salesforce/apex/WhatsAppConfigurationController.getConfiguration';
import WBConnectLogo from '@salesforce/resourceUrl/WBConnectLogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WhatsAppConfiguration extends LightningElement {
    @track wBAccountIdValue = '';
    @track accessTokenValue = '';
    @track phoneNoIdValue = '';
    @track appIdValue = '';
    @track wBAccountId = '';
    @track accessToken = '';
    @track phoneNoId = '';
    @track appId = '';
    @track WBConnectLogo = WBConnectLogo;
    @track isEditing = false;
    @track isDisabled = true;
    @track isFirstTime = false;

    connectedCallback(){
        getWhatsAppConfiguration()
        .then(result => {
            if (result != null) {
                this.wBAccountIdValue = result.MVWB__Business_Account_Id__c;
                this.accessTokenValue = result.MVWB__Access_Token__c;
                this.phoneNoIdValue = result.MVWB__Phone_Number_Id__c;
                this.appIdValue = result.MVWB__Application_Id__c;
                this.wBAccountId = '*'.repeat(this.wBAccountIdValue.length);
                this.accessToken = '*'.repeat(this.accessTokenValue.length);
                this.phoneNoId = '*'.repeat(this.phoneNoIdValue.length);
                this.appId = '*'.repeat(this.appIdValue.length);
                if(this.wBAccountIdValue != '' && this.accessTokenValue != '' && this.phoneNoIdValue != '' && this.appIdValue != ''){
                    this.isDisabled = true;
                    this.isEditing = false;
                } else {
                    this.isDisabled = false;
                    this.isFirstTime = true;
                    this.isEditing = false;
                }
                    
            }
        }).catch(error => {
            console.error(error);
        })
    }

    handleCancel() {
        this.wBAccountId = '*'.repeat(this.wBAccountIdValue.length);
        this.accessToken = '*'.repeat(this.accessTokenValue.length);
        this.phoneNoId = '*'.repeat(this.phoneNoIdValue.length);
        this.appId = '*'.repeat(this.appIdValue.length);
        this.isEditing = false;
        this.isDisabled = true;
    }
    
    handleEdit(){
        this.wBAccountId = this.wBAccountIdValue;
        this.accessToken = this.accessTokenValue;
        this.phoneNoId = this.phoneNoIdValue
        this.appId = this.appIdValue;
        this.isDisabled = false;
        this.isEditing = true;
    }

    handleInput(event) {
        if(event.target.name == 'WBAccountId'){
            this.wBAccountId = event.target.value;
            this.wBAccountId = this.wBAccountId.replaceAll(' ','');
            this.wBAccountIdValue = this.wBAccountId;
        } if(event.target.name == 'AccessToken'){
            this.accessToken = event.target.value;
            this.accessToken = this.accessToken.replaceAll(' ','');
            this.accessTokenValue = this.accessToken;
        } if(event.target.name == 'PhoneNumberId'){
            this.phoneNoId = event.target.value;
            this.phoneNoId = this.phoneNoId.replaceAll(' ','');
            this.phoneNoIdValue = this.phoneNoId;
        } if(event.target.name == 'WBAppId'){
            this.appId = event.target.value;
            this.appId = this.appId.replaceAll(' ','');
            this.appIdValue = this.appId;
        }
    }

    // Similar handlers for other fields

    handleSave() {
        // Basic validation (add more as needed)
        if (!this.wBAccountId || !this.accessToken || !this.phoneNoId|| !this.appId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Please Enter value for all the Fields',
                    variant: 'Error'
                })
            );
            return;
        }

        // Handle saving logic (e.g., API calls, data storage)
        saveWhatsAppConfiguration({WBAccountId : this.wBAccountId, AppId : this.appId , AccessToken : this.accessToken, PhoneNumberId : this.phoneNoId})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Saved successfully',
                    variant: 'success'
                })
            );
            this.wBAccountId = '*'.repeat(this.wBAccountIdValue.length);
            this.accessToken = '*'.repeat(this.accessTokenValue.length);
            this.phoneNoId = '*'.repeat(this.phoneNoIdValue.length);
            this.appId = '*'.repeat(this.appIdValue.length);
            this.isDisabled = true;
            this.isEditing = false;
            this.isFirstTime = false;
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }

    // Similar handlers for other info icons
}