/*****************************************************************************************
Created By : Lister App
Created Date : April 21, 2015
Created Purpose : Clone an object using MetaData API
*****************************************************************************************/
public with sharing class cloneObjectController{
    
    public List<SelectOption> list_Objects {get;set;}
    public String             objectName{get;set;}
    public String cloneObjectName{get;set;}
    
    public cloneObjectController()  
    {  
        //Initialize  
        list_Objects = new List<SelectOption>();
          
        //Get only reference to objects  
        for(Schema.SObjectType item : ProcessInstance.TargetObjectId.getDescribe().getReferenceTo())  
        {  
            //Excluding custom setting objects  
            if(!item.getDescribe().CustomSetting)  
            {                  
                //Adding to list  
                if(item.getDescribe().isUndeletable() )
                    list_Objects.add(new SelectOption(item.getDescribe().getLocalName().toLowerCase() , item.getDescribe().getLabel() ));  
            }  
        }  
          
    }   
    
    public void cloneObjectMetaData(){
        String[] types = new String[]{objectName};
        Schema.DescribeSObjectResult dsor = Schema.describeSObjects(types)[0];
        Map<String,Schema.DescribeFieldResult> finalMap = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();
       
        for(String key : objectFields.keySet()){
            Schema.SObjectField field = objectFields.get(key);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(F.getType() == Schema.DisplayType.location){
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,'Object contains geolocation field which is not currently supported, hence this object cannot be cloned'); 
                ApexPages.addMessage(errMsg);
                return;
            }
        }
        try{
            //get object meta data
            MetadataService.MetadataPort service = createService();
            MetadataService.CustomObject customGetObject = new MetadataService.CustomObject();
            customGetObject = (MetadataService.CustomObject) service.readMetadata('CustomObject',new String[] { objectName }).getRecords()[0];
            
            List<MetadataService.CustomField> lstCustomField = new list<MetadataService.CustomField>();
            
            //set object meta data    
            MetadataService.CustomObject customSetObject = new MetadataService.CustomObject();
            
            //another object instance to filter only custom fields and remove all standard fields as well as Geolocation **
            MetadataService.CustomObject updatedCustomSetObject = new MetadataService.CustomObject();
            
            //section to replace all spaces in the name with '_'
            String objectName = cloneObjectName;
            if(objectName.contains(' ')){
                objectName = objectName.replaceAll('(\\s+)','_');
            }                      
            updatedCustomSetObject.label = cloneObjectName;
            updatedCustomSetObject.pluralLabel = cloneObjectName;
            updatedCustomSetObject.fullName = objectName + '__c';
            
            //section to check if the object name mentioned by the user already exists in the org
            List<Schema.SObjectType> allObjects = Schema.getGlobalDescribe().Values();            
            for(Schema.SObjectType obj : allObjects ){                
                if(obj.getDescribe().getName()==updatedCustomSetObject.fullName){
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,'An object already exists with the Name you have specified. Try changing the name and clone the object'); 
                    ApexPages.addMessage(errMsg);
                    return;
                }        
            }  
                      
            updatedCustomSetObject.fields = new List<MetadataService.CustomField>();
            
            
            updatedCustomSetObject.deploymentStatus = 'Deployed';
            updatedCustomSetObject.sharingModel = 'ReadWrite';
            updatedCustomSetObject.nameField = new MetadataService.CustomField();
            //updatedCustomSetObject.nameField = customGetObject.nameField;//new MetadataService.CustomField();
            updatedCustomSetObject.nameField.type_x = 'Text';
            updatedCustomSetObject.nameField.label = cloneObjectName+ ' Name';
            
            if(customGetObject.fields != null){
                for(MetadataService.CustomField field : customGetObject.fields){
                    if(field.type_x == 'Lookup' || field.type_x == 'MasterDetail'){
                        field.relationshipLabel = field.relationshipLabel+'Clone'; 
                        field.relationshipName = field.relationshipName+'Clone';
                    }                                
                    
                    if((customGetObject.fullName.contains('__c')) || (field.fullName.contains('__c') && field.type_x != 'Geolocation')) {
                        updatedCustomSetObject.fields.add(field);
                    }
                    
                }
            }
            List<MetadataService.SaveResult> results ;
            if(!Test.isRunningTest()){
            //create metaData
              results = service.createMetadata(new MetadataService.Metadata[] { updatedCustomSetObject });
            }else{
                results = new List<MetadataService.SaveResult>();
                
                MetadataService.SaveResult SR  = new MetadataService.SaveResult() ;
                SR.fullName= 'Test';
                SR.success = true;
                results.add(SR);
           
            }
         
            handleSaveResults(results[0]);
        }catch(CalloutException ce){                       
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,ce.getMessage()); 
            ApexPages.addMessage(errMsg);
        }catch(Exception e){
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()); 
            ApexPages.addMessage(errMsg);
        }
    }
    public static MetadataService.MetadataPort createService(){ 
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