@IsTest
public with sharing class ContactServiceTest {
    @isTest
    private static void testPostContacts(){
        //Arrange
        ContactService.postContactRequest contact1 = new ContactService.postContactRequest();
        contact1.firstName = 'Jim';
        contact1.lastName = 'fjkejfksjnfkjnrfkjenkjfnekrjnfkernfkjenrfkjnerkjfnekjrnfkejnrfkjenrfkjnerfkjnerkf';
        contact1.phone = '8888888888';

        Map<String, ContactService.postContactRequest> contactById = new Map<String, ContactService.postContactRequest>();
        contactById.put('1', contact1);

        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/ContactService';
        request.httpMethod = 'POST';
        RestContext.request = request;

        //act
        ContactService.postContactResponse postContactResponse = ContactService.PostContacts(contactById);

        //assert
        System.assert(postContactResponse != null);
        System.assertEquals(1, postContactResponse.contactIds.size());
    }

    @isTest
    private static void testgetContactsByNameAndPhone() {
        //arrange
        Contact c1 = buildContact('Jim', 'Smith', 'Jim@test.com', '8888888888');
        insert c1;

        Contact c2 =  buildContact('Leslie', 'Smith', 'Leslie@test.com', '1111111111');
        insert c2;

        Id [] fixedSearchResults= new Id[2];
        fixedSearchResults[0] = c1.Id;
        fixedSearchResults[1] = c2.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        RestRequest request = new RestRequest();
        request.addParameter('contacts', 'Jim;Smith;8888888888,Leslie;Smith;1111111111');
        request.httpMethod = 'GET';
        RestContext.request = request;

        //act
        ContactService.getContactResponse contactResponse = ContactService.GetContact();

        //assert
        System.assert(contactResponse != null);
        System.assertEquals(2, contactResponse.contactIds.size());
        System.assert(contactResponse.contactIds.contains(c1.Id));
        System.assert(contactResponse.contactIds.contains(c2.Id));
    }

    @isTest
    private static void testgetContactsByNameAndPhoneFail() {
        //arrange
        Contact c1 = buildContact('Jim', 'Smith', 'Jim@test.com', '8888888888');
        insert c1;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = c1.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        RestRequest request = new RestRequest();
        request.addParameter('contacts', 'Leslie;Smith;1111111111');
        request.httpMethod = 'GET';
        RestContext.request = request;

        //act
        ContactService.getContactResponse contactResponse = ContactService.GetContact();

        //assert
        System.assert(contactResponse != null);
        System.assertEquals(0, contactResponse.contactIds.size());
        System.assertEquals('Contact_not_found', contactResponse.error[0].errorMessage);
        System.assertEquals('Leslie Smith', contactResponse.error[0].name);
        System.assertEquals('1111111111', contactResponse.error[0].phone);
    }

    @isTest
    private static void testgetContactsByNameAndPhoneFuzzyMatch() {
        //arrange
        Contact c1 = buildContact('Jim', 'Smith', 'Jim@test.com', '8888888888');
        insert c1;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = c1.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        RestRequest request = new RestRequest();
        request.addParameter('contacts', 'Jimmy;Smith;8888888888');
        request.httpMethod = 'GET';
        RestContext.request = request;

        //act
        ContactService.getContactResponse contactResponse = ContactService.GetContact();

        //assert
        System.assert(contactResponse != null);
        System.assert(contactResponse.contactIds.contains(c1.Id));
    }

    @isTest
    private static void testDeleteContact(){
        //arrange
        Contact c1 = buildContact('Jim', 'Smith', 'Jim@test.com', '8888888888');
        insert c1;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = c1.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        RestRequest request = new RestRequest();
        request.addParameter('contacts', 'Jim;Smith;8888888888');
        request.httpMethod = 'Delete';
        RestContext.request = request;

        //act
        ContactService.deleteContactResponse deleteResponse = ContactService.DeleteContact();

        //assert
        System.assert(deleteResponse != null);
        System.assert(deleteResponse.contactIds.contains(c1.Id));
    }

    private static Contact buildContact(String firstName, String lastName, String email, string phoneNumber) {
        Contact contactSObject = new Schema.Contact();
        contactSObject.FirstName = firstName;
        contactSObject.LastName = lastName;
        contactSObject.Email = email;
        contactSObject.Phone = phoneNumber;
        return contactSObject;
    }
}