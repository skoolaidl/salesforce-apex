@IsTest
private with sharing class ContactApplicationTest {
    private class ContactDataServiceMock implements ContactApplication.ContactDataAccess {
        public ContactSearch.ContactSearchResult getContactByNameAndPhone(String contactName, String contactPhone){
            ContactSearch.ContactSearchResult result = new ContactSearch.ContactSearchResult();
            result.success = true;
            result.contactObj.FullName = 'Jim Barnes';
            result.contactObj.contactId = '003Dn000009HABfIAO';
            result.contactObj.Phone = '8888888888';
            return result;
        }
    }

    @IsTest
    private static void testGetContactAccessor(){
        ContactApplication.contactDataAccessor = new ContactDataServiceMock();
        ContactApplication.ContactDataAccess contactService = ContactApplication.getContactDataAccessor();
        ContactSearch.ContactSearchResult result = contactService.getContactByNameAndPhone('Jim Barnes', '8888888888');
        System.assertEquals(result.contactObj.contactId, '003Dn000009HABfIAO');
    }
}
