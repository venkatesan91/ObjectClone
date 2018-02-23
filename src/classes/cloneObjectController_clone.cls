/*****************************************************************************************
Created By : Lister App
Created Date : April 21, 2015
Created Purpose : Clone an object using MetaData API
*****************************************************************************************/
public with sharing class cloneObjectController_clone{
    
    public List<SelectOption> list_Objects {get;set;}
    public String             objectName{get;set;}
    public String cloneObjectName{get;set;}
    
    public cloneObjectController_clone()  
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
                system.debug('get describe ' + item.getDescribe().getLabel() +  ' ' + item.getDescribe().getName()+ ' ' + item.getDescribe());
                if(item.getDescribe().isUndeletable() )
                list_Objects.add(new SelectOption(item.getDescribe().getLocalName().toLowerCase() , item.getDescribe().getLabel() ));  
            }  
        }  
          
    }
     
    /*public cloneObjectController(){
        List<Schema.SObjectType> allObjects = Schema.getGlobalDescribe().Values(); 
        list_Objects = new List<SelectOption>();
        for(Schema.SObjectType obj : allObjects ){
            //system.debug(' describe sobject ' + obj.getDescribe());
            //system.debug('get describe ' + obj.getDescribe().getName()+ ' ' + obj.getDescribe());
            if(obj.getDescribe().isCreateable() && obj.getDescribe().isUndeletable())            
            list_Objects.add(new SelectOption(obj.getDescribe().getName(),obj.getDescribe().getLabel()));
        }

    }*/
    
    public void cloneObjectMetaData(){
        String[] types = new String[]{objectName};
        Schema.DescribeSObjectResult dsor = Schema.describeSObjects(types)[0];
        Map<String,Schema.DescribeFieldResult> finalMap = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();
        //system.debug(objectFields);
        for(String key : objectFields.keySet()){
            system.debug('key: ' + key);
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
            system.debug('Dei work aaidu'+customGetObject.fullName);
            System.debug('customGetObject:'+customGetObject);
            //Need to handle null when no custom fields are there
            /*for(MetadataService.CustomField field : customGetObject.fields){
                System.debug('test1:::'+field.type_x);
                System.debug('test2:::'+field.fullName);
            }*/
            List<MetadataService.CustomField> lstCustomField = new list<MetadataService.CustomField>();
            //set object meta data    
            MetadataService.CustomObject customSetObject = new MetadataService.CustomObject();
            
            //another object instance to filter only custom fields and remove all standard fields as well as Geolocation ** Added by Team venky
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
            List<MetadataService.CustomField> listofRelFields = new List<MetadataService.CustomField>();
            system.debug('$$$'+customGetObject.fullName);
            
            
            updatedCustomSetObject.deploymentStatus = 'Deployed';
            updatedCustomSetObject.sharingModel = 'ReadWrite';
            updatedCustomSetObject.nameField = new MetadataService.CustomField();
            //updatedCustomSetObject.nameField = customGetObject.nameField;//new MetadataService.CustomField();
            updatedCustomSetObject.nameField.type_x = 'Text';
            updatedCustomSetObject.nameField.label = cloneObjectName+ ' Name';
            System.debug('###+'+customGetObject.fields );

            if(customGetObject.fields != null){
                for(MetadataService.CustomField field : customGetObject.fields){
                    System.debug(' ### field ' + field + '--- field type: ' + field.type_x );
                    system.debug('Formula'+field.formula+'*****'+field.formulaTreatBlanksAs);
                    if(field.type_x == 'Lookup' || field.type_x == 'MasterDetail' || field.formula != null){
                        system.debug('RelationshipLabel:'+field.relationshipLabel+'relationshipName:'+field.relationshipName);
                        listofRelFields.add(field);
                    }                                
                    else{
                            if((customGetObject.fullName.contains('__c')) || (field.fullName.contains('__c') && field.type_x != 'Geolocation')) {
                            System.debug('Inside add field');

                            updatedCustomSetObject.fields.add(field);
                        }
                    }
                   
                    
                }
            }
            List<MetadataService.SaveResult> results ;
            System.debug('^^'+customGetObject);

            system.debug('Other fields' + updatedCustomSetObject.fields.size() +'relationship' +listofRelFields.size());
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
            //Added by sriraman
          //  System.debug('^^'+results);
            handleSaveResults(results[0]);
            for(MetadataService.CustomField iterable : listofRelFields){
                if(iterable.formula != null){
                    system.debug('Iterable.formula'+iterable.formula);
                }
                else
                {
                    iterable.FullName = updatedCustomSetObject.fullName+'.'+iterable.FullName;
                    iterable.relationshipLabel = updatedCustomSetObject.label;
                    iterable.relationshipName = updatedCustomSetObject.fullName.replaceAll('__c','');
                }
               
                 system.debug('RelationshipLabel:'+iterable.relationshipLabel+'relationshipName:'+iterable.relationshipName);

                 if(!Test.isRunningTest()){
                //create metaData
                  results = service.createMetadata(new MetadataService.Metadata[] { iterable });
                }else{
                    results = new List<MetadataService.SaveResult>();
                    
                    MetadataService.SaveResult SR  = new MetadataService.SaveResult() ;
                    SR.fullName= 'Test';
                    SR.success = true;
                    results.add(SR);
               
                }

                handleSaveResults(results[0]);
            }
           

        }catch(CalloutException ce){
            System.debug('CalloutException!');
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
    //Added by sriraman
    public static void handleSaveResults(MetadataService.SaveResult saveResult)
    {
        // Nothing to see?
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
                System.debug('messages:'+String.join(messages, ' '));
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,String.join(messages, ' ')); 
                ApexPages.addMessage(errMsg);
                return;   
            }
        }
        if(!saveResult.success){
            //throw new MetadataServiceExamplesException('Request failed with no specified error.');
            System.debug('Request failed with no specified error.');
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error,'Request failed with no specified error.'); 
            ApexPages.addMessage(errMsg);
            return;
        }
    }
}