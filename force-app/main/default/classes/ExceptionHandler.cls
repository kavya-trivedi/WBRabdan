/**
* Class Name: ExceptionHandler
* Test Class: Not Needed
* @description: Used for logging the exceptions occurs withing the WBI app
* Created Date: 22 Nov, 2024
* Created By: Kevin Suvagiya
*--------------------------------------------------------------------------------
* Last Modified By: Kevin Suvagiya
* Last Modified Date: 06 Dec, 2024
* Last Modification Description: Removed unnecessary code.
*--------------------------------------------------------------------------------
* Modification History:
* Date Modified - Developer Name - Description
* 25 Nov, 2024  - Kevin Suvagiya - Added a method to link the chat record with the exception
* 27 Nov, 2024  - Kevin Suvagiya - Added a method to create exception for the API and salesforce catch blocks
**/
public with sharing class ExceptionHandler {

    /*
    *********************************************************
    @description     : Method is used to create a exception log record
    @param           : exceptionData - {ExceptionWrapper} - The Wrapper containing all the data to be logged
    @param           : chatId - {String} - Id of the chat, null if not specified
    @return          : none
    ********************************************************
    */
    public static void logException(Map<String, Object> exceptionData) {
        try {
            MVWB__Exception_Log__c exc = new MVWB__Exception_Log__c();
            exc.MVWB__Class_Name__c = (String)exceptionData.get('className');
            exc.MVWB__Method_Name__c = (String)exceptionData.get('methodName');
            exc.MVWB__WB_Chat__c = (String)exceptionData.get('chatId');
            exc.MVWB__Is_API_Exception__c = (Boolean)exceptionData.get('isApiException') != null ? (Boolean)exceptionData.get('isApiException') : false;
            exc.MVWB__Status_Code__c = (Integer)exceptionData.get('statusCode');
            Exception excObj = (Exception)exceptionData.get('exceptionObj');

            if(excObj != null){
                String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
                String dMLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
                String dMLState = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
                String cPUTime = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
                String calloutLimit = '5. Number of callouts used so far / Number allowed: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts();
                String heapSize = '6. Amount of Heap size used so far / Heap usage allowed:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize();
            
                exc.MVWB__Governor_Limit_Used__c = String.format('{0}\n{1}\n{2}\n{3}\n{4}\n{5}',new List<string>{queryLimit, dMLimit, dMLState, cPUTime, calloutLimit, heapSize});
                exc.MVWB__Exception_Message__c = excObj.getMessage();
                exc.MVWB__Exception_Type__c = excObj.getTypeName();
                exc.MVWB__Exception_Line_Number__c = excObj.getLineNumber();
                exc.MVWB__Exception_Stack_Trace__c = excObj.getStackTraceString();
            }
            exc.MVWB__More_Details__c = (String)exceptionData.get('moreDetails');
            exc.MVWB__Response__c = (String)exceptionData.get('apiResponse');

            insert as user exc;
        } catch (Exception e) {
            System.debug('Error in logException: ' + e.getMessage());
        }
    }
}