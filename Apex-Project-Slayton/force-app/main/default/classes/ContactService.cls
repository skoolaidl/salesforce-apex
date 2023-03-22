@RestResource(urlMapping='/ContactService/*')

global with sharing class ContactService {

    public class NameAndPhone {
        public String FullName;
        public String Phone;

        public NameAndPhone(String FullName, string Phone) {
            this.FullName = FullName;
            this.Phone = Phone;
        }
    }

    public class ContactModel {
        public Id contactId;
        public NameAndPhone contactDetails;
    }

    public class Error {
        public String errorMessage;
        public String name;
        public String firstName;
        public String lastName;
        public String phone;

        public Error(String errorMessage, String name, String phone) {
            this.errorMessage = errorMessage;
            this.name = name;
            this.phone = phone;
        }
        public Error(String errorMessage, String firstName, String lastName, String phone) {
            this.errorMessage = errorMessage;
            this.firstName = firstName;
            this.lastName = lastName;
            this.phone = phone;
        }
        public Error(String errorMessage) {
            this.errorMessage = errorMessage;
        }
        public Error(){

        }
    }

    global class ContactRequest {
        public String firstName;
        public String lastName;
        public String phone;
    }

    global class postContactResponse {
        public List<Id> contactIds = new List<Id>();
        public List<Error> insufficientContactInformation = new List<Error>();
        public List<Error> existingContacts = new List<Error>();
        public List<Error> insertContactsError = new List<Error>();
        public String heapSize;

        public postContactResponse(List<Id> contactIds, List<Error> insufficientContactInformation, List<Error> existingContacts, List<Error> insertContactsError, String heapSize) {
            this.contactIds = contactIds;
            this.insufficientContactInformation = insufficientContactInformation;
            this.existingContacts = existingContacts;
            this.insertContactsError = insertContactsError;
            this.heapSize = heapSize;
        }

        public postContactResponse() {
        }
    }

    global class getContactResponse {
        public List<Id> contactIds = new List<Id>();
        public List<Error> error = new List<Error>();
        public String cpuTime;

        public getContactResponse(List<Id> contactIds, List<Error> error, String cpuTime) {
            this.contactIds = contactIds;
            this.error = error;
            this.cpuTime = cpuTime;
        }

        public getContactResponse() {
        }
    }

    global class deleteContactResponse {
        public List<Id> contactIds = new List<Id>();
        public List<Error> error = new List<Error>();
        public String queryRows;

        public deleteContactResponse(List<Id> contactIds, List<Error> error, String queryRows) {
            this.contactIds = contactIds;
            this.error = error;
            this.queryRows = queryRows;
        }

        public deleteContactResponse() {
        }
    }

    @HttpPost
    global static postContactResponse PostContacts(Map<String, ContactRequest> contacts) {
        List<Contact> contactsToInsert = new List<Contact>();
        postContactResponse response = new postContactResponse();

        for (String contactId : contacts.keySet()) {
            ContactRequest contact = contacts.get(contactId);

            //String manipulation
            String firstName = contact.firstName.toLowerCase().capitalize();
            String lastName = contact.lastName.toLowerCase().capitalize();
            String fullName = firstName + ' ' + lastName;
            String phone = contact.phone;

            //check to see if contact exists
            ContactSearch.ContactSearchResult existingContact = QueryContact(fullName, phone);

            Boolean missingFirst = String.isBlank(firstName);
            Boolean missingLast = String.isBlank(lastName);
            Boolean missingPhone = String.isBlank(phone);

            if (existingContact.success) {
                Error existingContactError = new Error('Contact_already_exists', existingContact.contactObj.FullName, existingContact.contactObj.Phone);
                response.existingContacts.add(existingContactError);
            } else if (missingFirst || missingLast || missingPhone) {
                Error missingContactInfoError = new Error('Missing_contact_info', missingFirst ? 'missing_contact_first_name' : firstName, missingLast ? 'missing_contact_last_name' : lastName,missingPhone ? 'missing_contact_phone' : phone);
                response.insufficientContactInformation.add(missingContactInfoError);
            } else {
                //Create new contact
                Contact newContact = new Contact();
                newContact.FirstName = firstName;
                newContact.LastName = lastName;
                newContact.Phone = phone;
                contactsToInsert.add(newContact);       
            }
        }
        //Insert + Reinsert
        insertContacts(response, contactsToInsert, true);
        
        response.heapSize = 'Heap size: ' + Limits.getHeapSize() + ' bytes';
        return response;
    }

    @HttpGet
    global static getContactResponse GetContact() {
        RestRequest request = RestContext.request;
        getContactResponse response = new getContactResponse();
        List<NameAndPhone> isolatedContacts = new List<NameAndPhone>();

        //Isolate URIparams & individual contacts to search
        List<String> searchParams = request.params.get('contacts').split(',');
        
        for(String contact: searchParams) {
            // Isolate name/phone for search
            List<String> contactList = contact.split(';');

            //Check for missing contact info
            if (contactList.size() == 3) {
                String contactName = contactList[0] + ' ' + contactList[1];
                String contactPhone = contactList[2];
                NameAndPhone isolatedContact = new NameAndPhone(contactName, contactPhone);                
                isolatedContacts.add(isolatedContact);
            } else {
                Error incompleteContactError = new Error('incomplete_contact_information: ' + contactList);
                response.error.add(incompleteContactError);
            }
        }

        //write reusable code to isolate ID's
        List<ContactSearch.ContactSearchResult> contacts = QueryContacts(isolatedContacts);

        for(ContactSearch.ContactSearchResult contact: contacts) {
            if (contact.success) {
                response.contactIds.add(contact.contactObj.contactId); 
            } else {
                //need to update this so it isn't null
                Error contactSearchError = new Error('Contact_not_found',contactName,contactPhone);
                response.error.add(contactSearchError);
            }
        }
        
        //Include compute time
        response.cpuTime = 'Executed in '+ Limits.getCpuTime() + ' ms';
        return response;
    }

    @HttpDelete
    global static deleteContactResponse DeleteContact(){
        RestRequest request = RestContext.request;
        deleteContactResponse response = new deleteContactResponse();
        List<Id> idsToDelete = new List<Id>();

        //Isolate URIparams & individual contacts to search
        List<String> contactsToSearch = request.params.get('contacts').split(',');
        
        for(String contact: contactsToSearch) {
            // Isolate name/phone for search
            List<String> contactInfo = contact.split(';');

            //Check for missing contact info
            if (contactInfo.size() == 3) {
                String contactName = contactInfo[0] + ' ' + contactInfo[1];
                String contactPhone = contactInfo[2];

                ContactSearch.ContactSearchResult resp = QueryContact(contactName, contactPhone);

                if (resp.success) {
                    //IDs to delete
                    idsToDelete.add(resp.contactObj.contactId);
                } else {
                    Error contactDeleteError = new Error('Contact_not_found',contactName,contactPhone);
                    response.error.add(contactDeleteError);
                }
            } else {
                Error incompleteContactError = new Error('incomplete_contact_information: ' + contactInfo);
                response.error.add(incompleteContactError);
            }
        }

        Database.DeleteResult[] deleteResults = Database.delete (idsToDelete, false);

        for(Database.DeleteResult result: deleteResults) {
            if (result.isSuccess()) {
                response.contactIds.add(result.getId());
            }
        }
        response.queryRows = 'Query rows: ' + Limits.getQueryRows() + ' records';
        return response;
    }

    private static void insertContacts(ContactService.postContactResponse response, List<Contact> contactsToInsert, Boolean isFirstInsert) {
        List<Id> contactIdsAdded = new List<Id>();
        List<Contact> contactsToReinsert = new List<Contact>();

        //Try insert
        Database.SaveResult[] insertResult = Database.insert (contactsToInsert, false);

        //Loop over results
        for(Integer i = 0; i < insertResult.size(); i++) {
            Database.SaveResult result = insertResult[i];
            if (result.isSuccess()) {
                contactIdsAdded.add(result.getId());
            } else {
                if (isFirstInsert) {
                    for(Database.Error error: result.getErrors()) {
                        if (error.getStatusCode() == StatusCode.STRING_TOO_LONG) {
                            contactsToInsert[i].FirstName = contactsToInsert[i].FirstName.length() > 40 ? contactsToInsert[i].FirstName.substring(0, 40) : contactsToInsert[i].FirstName;
                            contactsToInsert[i].LastName = contactsToInsert[i].LastName.length() > 80 ? contactsToInsert[i].LastName.substring(0, 80) : contactsToInsert[i].LastName;

                            //Build list to retry inserts
                            contactsToReinsert.add(contactsToInsert[i]);
                        } else {
                            //complete failure
                            Error insertContactError = new Error('insert_contact_failure', contactsToInsert[i].Name, contactsToInsert[i].Phone);
                            response.insertContactsError.add(insertContactError);
                        }
                    }
                } else {
                    //complete failure
                    Error insertContactError = new Error('insert_contact_failure', contactsToInsert[i].Name, contactsToInsert[i].Phone);
                    response.insertContactsError.add(insertContactError);
                }
            }  
        }
        //Add successful ID's to response
        response.contactIds.addAll(contactIdsAdded);
        if (isFirstInsert & contactsToReinsert.size() > 0) {
            insertContacts(response, contactsToReinsert, false);
        }
        return;
    }

    private static ContactSearch.ContactSearchResult QueryContacts(List<NameAndPhone> contacts) {
        ContactSearch.ContactSearchResult searchResult = ContactApplication.getContactDataAccessor().getContactsByNameAndPhone(contacts);
        return searchResult;
    }
}
