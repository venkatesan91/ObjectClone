@isTest 
    private class TestClasscloneObjectController{
        static testMethod void TestcloneObjectController() {
            Test.startTest();
            Test.setMock(WebServiceMock.class, new WebServiceMockImplClone());
            
            cloneObjectController controller = new cloneObjectController();
            controller.objectName= 'Account';
            controller.cloneObjectName= 'Account Clone754yrtjghkykfgj';
            
            controller.cloneObjectMetaData();
            controller.objectName= 'Account';
            controller.cloneObjectName= 'Accountrgheraghern wsgsr';
            controller.cloneObjectMetaData();
            controller.objectName= 'Account';
            controller.cloneObjectName= 'Account';
            
            controller.cloneObjectMetaData();
            
            
            List<MetadataService.Error> errors = new List<MetadataService.Error>();
            List<MetadataService.SaveResult> results ;
            results = new List<MetadataService.SaveResult>();
            MetadataService.Error err = new MetadataService.Error();
            err.message = 'Test';
            err.statusCode = '200';
            errors.add(err);
            MetadataService.SaveResult SR1   = new MetadataService.SaveResult() ;
            SR1.fullName= 'Test2';
            SR1.errors= errors;
            SR1.success = false;
            results.add(SR1);
           
            cloneObjectController.handleSaveResults(results[0]);
            
            errors = new List<MetadataService.Error>();
            
            results = new List<MetadataService.SaveResult>();
            err = new MetadataService.Error();
            errors.add(err);
            SR1   = new MetadataService.SaveResult() ;
            SR1.fullName= 'Test2';
            SR1.errors= null;
            SR1.success = false;
            results.add(SR1);
            cloneObjectController.handleSaveResults(results[0]);
            
            controller.objectName= 'User';
            controller.cloneObjectName= 'User Clone754yrtjghkykfgj';
            
            controller.cloneObjectMetaData();
            
            Test.stopTest();
        }
}