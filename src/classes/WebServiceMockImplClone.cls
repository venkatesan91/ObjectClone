@IsTest
global class WebServiceMockImplClone implements WebServiceMock {
  public void doInvoke(
    Object stub,
    Object request, 
    Map<String, Object> response,
    String endpoint, 
    String soapAction, 
    String requestName,
    String responseNS, 
    String responseName, 
    String responseType) {
       
        if(request instanceof MetadataService.readMetadata_element){
          MetadataService.readMetadata_element requestReadMetadata_element  = (MetadataService.readMetadata_element) request;
          
         
          if (requestReadMetadata_element.type_x == 'CustomObject') { 
             MetadataService.readCustomObjectResponse_element mockRes = new MetadataService.readCustomObjectResponse_element();
             mockRes.result = new MetaDataService.ReadCustomObjectResult();
             List<MetadataService.CustomObject> ListCustomObject = new List<MetadataService.CustomObject>();
             MetadataService.CustomObject NewCustomObject = createCustomObjects();
             ListCustomObject.add(NewCustomObject );
             mockRes.result.records= ListCustomObject;
             response.put('response_x', mockRes);
          }
          else if (requestReadMetadata_element.type_x == 'CustomField') { 
            
             MetadataService.readCustomFieldResponse_element mockRes = new MetadataService.readCustomFieldResponse_element();
             mockRes.result = new MetaDataService.ReadCustomfieldResult();
             List<MetadataService.CustomField> ListCustomField= new List<MetadataService.CustomField>();
             MetadataService.CustomField NewCustomField = createCustomFields();
             ListCustomField.add(NewCustomField );
             mockRes.result.records= ListCustomField;
             response.put('response_x', mockRes);
            
            
            
            }
          
      
       
    
       return;
   }
   }
   
   
   public static MetadataService.CustomObject createCustomObjects(){
        MetadataService.MetadataPort service = createService();
        MetadataService.CustomObject customObject = new MetadataService.CustomObject();
        customObject.fullName = 'Test__c';
        customObject.label = 'Test';
        customObject.pluralLabel = 'Tests';
        customObject.nameField = new MetadataService.CustomField();
        customObject.nameField.fullName= 'Text';
        customObject.nameField.type_x = 'Text';
        customObject.nameField.label = 'Test Record';
        customObject.deploymentStatus = 'Deployed';
        customObject.sharingModel = 'ReadWrite';
        List<MetadataService.CustomField > Listfields = new List<MetadataService.CustomField >();
        MetadataService.CustomField customFieldTemp = new MetadataService.CustomField();
        customFieldTemp = createCustomFields();
        Listfields.add(customFieldTemp);
       // customObject.fields.add(customFieldTemp);
       customObject.fields = Listfields;
        return customObject;
    }
    
    public static MetadataService.MetadataPort createService()
    { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }
    public static MetadataService.CustomField createCustomFields()
    {
        MetadataService.MetadataPort service = createService();     
        MetadataService.CustomField customField = new MetadataService.CustomField();
        customField.fullName = 'Test__c.LookupField__c';
        customField.label = 'Lookup Field';
        customField.type_x = 'Lookup';
        customField.relationshipLabel = 'Tests';
        customField.relationshipName = 'Tests';
        customField.referenceTo = 'Test__c';
        
        return customField;
    }
    public static void handleSaveResults(MetadataService.SaveResult saveResult)
    {
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
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
            if(messages.size()>0)
                throw new MetadataServiceExamplesException(String.join(messages, ' '));
        }
        if(!saveResult.success)
            throw new MetadataServiceExamplesException('Request failed with no specified error.');
    }
    public class MetadataServiceExamplesException extends Exception { }
    /*
    public MetadataService.SaveResult[] createMetadata(MetadataService.Metadata[] metadata) {
            MetadataService.createMetadata_element request_x = new MetadataService.createMetadata_element();
            request_x.metadata = metadata;
            MetadataService.createMetadataResponse_element response_x;
            String endpoint_x = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/33.0';
            Map<String, MetadataService.createMetadataResponse_element> response_map_x = new Map<String, MetadataService.createMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'http://soap.sforce.com/2006/04/metadata',
              'createMetadata',
              'http://soap.sforce.com/2006/04/metadata',
              'createMetadataResponse',
              'MetadataService.createMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
    */
}