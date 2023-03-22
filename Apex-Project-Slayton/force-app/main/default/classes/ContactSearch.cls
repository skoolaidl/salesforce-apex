global with sharing class ContactSearch implements ContactApplication.ContactDataAccess {

    global class ContactSearchResult {
        public Boolean success;
        public String errorMessage;
        public ContactService.ContactModel contactObjs = new ContactService.ContactModel();

        public ContactSearchResult(Exception ex) {
            this.success = false;
            this.errorMessage = ex.getMessage();
        }
        
        public ContactSearchResult() {
        }
    }

    public ContactSearchResult getContactsByNameAndPhone(List<ContactService.NameAndPhone> contacts) {
        ContactSearchResult result;
        try {
            String nameQueryString;
            List<String> phoneQueryList = new List<String>();

            //create objects to add to SOSL query
            for(ContactService.NameAndPhone contact: contacts) {
                if (nameQueryString.isBlank()) {
                    nameQueryString = contact.FullName;
                } else {
                    nameQueryString += ' OR ' + contact.FullName;
                }
                phoneQueryList.add(contact.Phone);
            }

            //Note: Name will be fuzzy matched, native to SOSL
            List<List<SObject>> contactSObject = [FIND :nameQueryString in Name Fields RETURNING Contact(Id, Name, Phone WHERE Phone in :phoneQueryList)];
            List<Contact> contacts = (List<Contact>) contactSObject[0];
            result = mapContacts(contacts);
        } catch (Exception ex) {
            result = new ContactSearchResult(ex);
        }
        return result;
    }

    private static List<ContactSearchResult> mapContacts(List<Contact> contactSObjects) {
        //create proper result
        for (Contact contactSObject: contactSObjects) {
            ContactSearchResult result = new ContactSearchResult();
            if (contactSObject != null) {
                result.contactObj.contactDetails.FullName = contactSObject.Name;
                result.contactObj.contactId = contactSObject.Id;
                result.contactObj.contactDetails.Phone = contactSObject.Phone;
            }
            result.success = true;
        }
        //should we do a lookup returning missing names/numbers? can search on initial request and see what is missing and add error message.
        return result;
    }
}
