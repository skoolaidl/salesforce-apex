@IsTest
private with sharing class ContactSearchTest {
    @IsTest
    private static void testQueryContact() {
        Contact contactSObject = buildContact();
        insert contactSObject;
    }

    @IsTest
    private static void testgetContactsByNameAndPhone_Id() {
        String fullName = 'Jim Smith';
        Contact contactSObject = buildContact();
        insert contactSObject;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = contactSObject.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        ContactSearch.ContactSearchResult result = new ContactSearch().getContactsByNameAndPhone(fullName, contactSObject.Phone);
        System.assertEquals(contactSObject.Id, result.contactObj.contactId);
    }

    @IsTest
    private static void testgetContactsByNameAndPhone_Name() {
        String fullName = 'Jim Smith';
        Contact contactSObject = buildContact();
        insert contactSObject;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = contactSObject.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        ContactSearch.ContactSearchResult result = new ContactSearch().getContactsByNameAndPhone(fullName, contactSObject.Phone);
        System.assertEquals(fullName, result.contactObj.fullName);
    }

    @IsTest
    private static void testgetContactsByNameAndPhone_Phone() {
        String fullName = 'Jim Smith';
        Contact contactSObject = buildContact();
        insert contactSObject;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = contactSObject.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        ContactSearch.ContactSearchResult result = new ContactSearch().getContactsByNameAndPhone(fullName, contactSObject.Phone);
        System.assertEquals(contactSObject.Phone, result.contactObj.Phone);
    }

    private static Contact buildContact() {
        Contact contactSObject = new Schema.Contact();
        contactSObject.FirstName = 'Jim';
        contactSObject.LastName = 'Smith';
        contactSObject.Email = 'Jim@gmail.com';
        contactSObject.Phone = '8888888888';
        return contactSObject;
    }
}