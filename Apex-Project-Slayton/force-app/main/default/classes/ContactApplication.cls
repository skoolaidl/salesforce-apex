public with sharing class ContactApplication {

    public interface ContactDataAccess {
        List<ContactSearch.ContactSearchResult> getContactsByNameAndPhone(List<ContactService.NameAndPhone> contacts);
    }

    @TestVisible
    private static ContactDataAccess contactDataAccessor;

    public static ContactDataAccess getContactDataAccessor() {
        if (contactDataAccessor == null) {
            contactDataAccessor = new ContactSearch();
        }
        return contactDataAccessor;
    }
}
