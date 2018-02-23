public class MetadataUse {
    public static void createObject()
    {
        MetadataService.MetadataPort service = createService();
        MetadataService.CustomObject customObject = new MetadataService.CustomObject();

        customObject.label = 'Test';
        customObject.pluralLabel = 'Tests';
        customObject.nameField = new MetadataService.CustomField();
        customObject.nameField.type_x = 'Text';
        customObject.nameField.label = 'Test Record';
        customObject.deploymentStatus = 'Deployed';
        customObject.sharingModel = 'ReadWrite';
        List<MetadataService.SaveResult> results =      
            service.createMetadata(
                new MetadataService.Metadata[] { customObject });       
        handleSaveResults(results[0]);
    }
    public static MetadataService.MetadataPort createService()
    { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }
    public static void handleSaveResults(MetadataService.SaveResult saveResult){       
        if(saveResult==null || saveResult.success){
            if(saveResult.success){
                ApexPages.Message sucMsg = new ApexPages.Message(ApexPages.Severity.Info,'The object has been cloned successfully'); 
                ApexPages.addMessage(sucMsg);   
            }
            return;
        }      
            
        // Construct error message and throw an exception
        if(saveResult.errors!=null) 
        {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') + 
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' + 
                    ( error.fields!=null && error.fields.size()>0 ? 
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0){
                //throw new MetadataServiceExamplesException(String.join(messages, ' '));
                if(String.join(messages, ' ').contains('That object name is already in use')){
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,'The object name is already in use. Please enter a different name for Clone Object.'); 
                ApexPages.addMessage(errMsg);
                }else{
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,String.join(messages, ' ')); 
                    ApexPages.addMessage(errMsg);
                }
                return;   
            }
        }
        if(!saveResult.success){
            //throw new MetadataServiceExamplesException('Request failed with no specified error.');
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,'Request failed with no specified error.'); 
            ApexPages.addMessage(errMsg);
            return;
        }
    }
   
}