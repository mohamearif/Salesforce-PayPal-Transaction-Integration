public with sharing class PayPalDataProcessorQueueable implements Queueable{

    private String accountRecordTypeId {
        get {
            Id accountRecordTypeId = !String.isEmpty(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('AccountRecordTypeDeveloperName').Value__c) ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('AccountRecordTypeDeveloperName').Value__c).getRecordTypeId() : null;
            return accountRecordTypeId;
        }
        set;
    }

    private String contactRecordTypeId {
        get {
            Id contactRecordTypeId = !String.isEmpty(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('ContactRecordTypeDeveloperName').Value__c) ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Salesforce_PayPal_Transaction_Settings__mdt.getInstance('ContactRecordTypeDeveloperName').Value__c).getRecordTypeId() : null;
            return contactRecordTypeId;
        }
        set;
    }

    private Map<String, Integer> accountFieldLengths {get; set;}
    private Map<String, Integer> contactFieldLengths {get; set;}
    private Map<String, Integer> paypalTransactionFieldLengths {get; set;}
    
    public PayPalTransactionData transactionData {get; set;}

    public PayPalDataProcessorQueueable(PayPalTransactionData tData) {
        this.transactionData = tData;
    }

    public void execute(QueueableContext context) {
        try {
            setFieldLengthMaps();
            findAndInsertContactsHouseHoldsPayPalTransactions(transactionData.Transaction_details);
            //chain another paypal export if there are more pages of data
            if(transactionData.page < transactionData.total_pages) {
                System.enqueueJob(new PayPalDataExportQueueable(transactionData.start_datetime, transactionData.end_datetime, transactionData.page+1, transactionData.page_size, transactionData.excludeAccountContactProcessing));
            }
        } catch(Exception ex) {
            errorEmail('PayPalDataProcessorQueueable', ex.getStackTraceString());
        }
    }

    private void findAndInsertContactsHouseHoldsPayPalTransactions(List<PayPalTransactionData.Transaction_details> transactions) {
        set<String> accountIdentifiers = new set<String>();
        set<String> contactIdentifiers = new set<String>();
        set<String> paypalTransactionIdentifiers = new set<String>();
        for (PayPalTransactionData.Transaction_details trans : transactions) {
            accountIdentifiers.add(getAccountIdentifier(trans));
            contactIdentifiers.add(getContactIdentifier(trans));
            paypalTransactionIdentifiers.add(getPayPalTransactionIdentifier(trans));
        }
        Map<String, Account> accountsMap = new Map<String, Account>();
        for (Account a : [SELECT Id, Name, External_Id__c FROM Account WHERE External_Id__c IN :accountIdentifiers]){
            accountsMap.put(a.External_Id__c, a);
        }
        Map<String, Contact> contactsMap = new Map<String, Contact>();
        for (Contact c : [SELECT Id, External_Id__c, AccountId, LastName FROM Contact WHERE External_Id__c IN :contactIdentifiers]){
            contactsMap.put(c.External_Id__c, c);
        }
        Map<String, PayPal_Transaction__c> paypalTransactionssMap = new Map<String, PayPal_Transaction__c>();
        for (PayPal_Transaction__c d : [SELECT Id, Transaction_ID__c FROM PayPal_Transaction__c WHERE Transaction_ID__c IN :paypalTransactionIdentifiers]){
            paypalTransactionssMap.put(d.Transaction_ID__c, d);
        }
        sfWrapper wrapper = new sfWrapper();
        wrapper.households = new Map<String, Account>();
        wrapper.contacts = new Map<String, Contact>();
        wrapper.paypalTransactions = new Map<String, PayPal_Transaction__c>();
        for (PayPalTransactionData.Transaction_details trans : transactions) {
            if (trans.transaction_info.transaction_status == 'S' &  trans.transaction_info.transaction_event_code != 'T0400') { //bringing in only 'S' = successfull transactions into Salesforce and also avoid bringing in General withdrawal from PayPal account. 
                Contact c = new Contact();
                Account a = new Account();
                if (!transactionData.excludeAccountContactProcessing) {
                    if(wrapper.contacts.get(getContactIdentifier(trans)) == null) {
                        if(contactsMap.get(getContactIdentifier(trans)) == null) {
                            c = getContact(trans);
                            if(!String.isEmpty(contactRecordTypeId)) {c.put('RecordTypeId', contactRecordTypeId); }
                            wrapper.contacts.put(getContactIdentifier(trans), c);
                        } else {
                            c =  contactsMap.get(getContactIdentifier(trans));
                        }
                    } else {
                        c = wrapper.contacts.get(getContactIdentifier(trans));
                    }
                    if(wrapper.households.get(getAccountIdentifier(trans)) == null) {
                        if(accountsMap.get(getAccountIdentifier(trans)) == null) {
                            a.Name = leftTrim(c.LastName + '\'s Household', accountFieldLengths.get('Name'));
                            a.External_Id__c = getAccountIdentifier(trans);
                            a = getAccountAddress(a, trans);
                            if(!String.isEmpty(accountRecordTypeId)) {a.put('RecordTypeId', accountRecordTypeId);}
                            wrapper.households.put(getAccountIdentifier(trans), a);
                        } else {
                            a = accountsMap.get(getAccountIdentifier(trans));
                        }
                    } else {
                        a = wrapper.households.get(getAccountIdentifier(trans));
                    }
                }
                if(wrapper.paypalTransactions.get(getPayPalTransactionIdentifier(trans)) == null) {
                    PayPal_Transaction__c d = new PayPal_Transaction__c();
                    if(paypalTransactionssMap.get(getPayPalTransactionIdentifier(trans)) == null) {
                        d = getPayPalTransaction(trans, a, c);
                        wrapper.paypalTransactions.put(getPayPalTransactionIdentifier(trans), d);
                    }
                }
            }
        }
        if(!wrapper.households.values().isEmpty()) {
            List<Account> accounts = new List<Account>();
            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.CREATABLE,  // Specify the access type (CREATABLE for insert).
                wrapper.households.values()  // Pass the list of records.
            );
            accounts = securityDecision.getRecords();
            insert accounts;
        }
        if(!wrapper.contacts.values().isEmpty()) {
            List<Contact> contacts = new List<Contact>();
            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.CREATABLE,  // Specify the access type (CREATABLE for insert).
                wrapper.contacts.values()  // Pass the list of records.
            );
            contacts = securityDecision.getRecords(); 
            insert contacts;
        }
        if(!wrapper.paypalTransactions.values().isEmpty()) {
            List<PayPal_Transaction__c> paypalTransactions = new List<PayPal_Transaction__c>();
            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.CREATABLE,  // Specify the access type (CREATABLE for insert).
                wrapper.paypalTransactions.values()  // Pass the list of records.
            );
            paypalTransactions = securityDecision.getRecords(); 
            insert paypalTransactions;
        }
        
    }

    private Account getAccountAddress(Account a, PayPalTransactionData.Transaction_details trans){
        //mailing
        String ShippingStreet =  !String.isEmpty(trans.shipping_info?.address?.line1) ? trans.shipping_info.address.line1 : '';
        if (!String.isBlank(trans.shipping_info?.address?.line2)) {
            ShippingStreet += ', ';
            ShippingStreet += !String.isEmpty(trans.shipping_info?.address?.line2) ? trans.shipping_info.address.line2 : '';
        } 
        a.ShippingStreet = leftTrim(ShippingStreet, accountFieldLengths.get('ShippingStreet'));
        a.ShippingCity = !String.isEmpty(trans.shipping_info?.address?.city) ? leftTrim(trans.shipping_info.address.city, accountFieldLengths.get('ShippingCity')) : '';
        a.ShippingState = !String.isEmpty(trans.shipping_info?.address?.state) ? leftTrim(trans.shipping_info.address.state, accountFieldLengths.get('ShippingState')) : '';
        a.ShippingCountry = !String.isEmpty(trans.shipping_info?.address?.country_code) ? leftTrim(trans.shipping_info.address.country_code, accountFieldLengths.get('ShippingCountry')) : '';
        a.ShippingPostalCode = !String.isEmpty(trans.shipping_info?.address?.postal_code) ? leftTrim(trans.shipping_info.address.postal_code, accountFieldLengths.get('ShippingPostalCode')) : '';
        //billing 
        String BillingStreet =  !String.isEmpty(trans.payer_info?.address?.line1) ? trans.payer_info.address.line1 : '';
        if (!String.isBlank(trans.payer_info?.address?.line2)) {
            BillingStreet += ', ';
            BillingStreet += !String.isEmpty(trans.payer_info?.address?.line2) ? trans.payer_info.address.line2 : '';
        } 
        a.BillingStreet = leftTrim(BillingStreet, accountFieldLengths.get('BillingStreet'));
        a.BillingCity = !String.isEmpty(trans.payer_info?.address?.city) ? leftTrim(trans.payer_info.address.city, accountFieldLengths.get('BillingCity')) : '';
        a.BillingState = !String.isEmpty(trans.payer_info?.address?.state) ? leftTrim(trans.payer_info.address.state, accountFieldLengths.get('BillingState')) : '';
        a.BillingCountry = !String.isEmpty(trans.payer_info?.address?.country_code) ? leftTrim(trans.payer_info.address.country_code, accountFieldLengths.get('BillingCountry')) : '';
        a.BillingPostalCode = !String.isEmpty(trans.payer_info?.address?.postal_code) ? leftTrim(trans.payer_info.address.postal_code, accountFieldLengths.get('BillingPostalCode')) : '';
        return a;
    }

    private String getContactIdentifier(PayPalTransactionData.Transaction_details trans) {
        //String accountId = getAccountIdentifier(trans);
        String firstName = !String.isEmpty(trans.payer_info?.payer_name?.given_name) ? trans.payer_info?.payer_name.given_name : !String.isEmpty(trans.shipping_info?.name) ? trans.shipping_info.name.split(', ')[0] : '';
        String lastName = !String.isEmpty(trans.payer_info?.payer_name?.surname) ? trans.payer_info.payer_name.surname : (!String.isEmpty(trans.shipping_info?.name) & trans.shipping_info.name.contains(',')) ? trans.shipping_info.name.split(', ')[1] : trans.shipping_info.name;
        //String middleName = trans.payer_info?.payer_name?.middle_name ? trans.payer_info.payer_name.middle_name : '';
        // String addressLine1 =  !String.isEmpty(trans.shipping_info?.address?.line1) ? trans.shipping_info.address.line1 : '';
        // String addressLine2 = !String.isEmpty(trans.shipping_info?.address?.line2) ? trans.shipping_info.address.line2 : '';
        // String city = !String.isEmpty(trans.shipping_info?.address?.city) ? trans.shipping_info.address.city : '';
        // String state = !String.isEmpty(trans.shipping_info?.address?.state) ? trans.shipping_info.address.state : '';
        // String countryCode = !String.isEmpty(trans.shipping_info?.address?.country_code) ? trans.shipping_info.address.country_code : '';
        // String postalCode = !String.isEmpty(trans.shipping_info?.address?.postal_code) ? trans.shipping_info.address.postal_code : '';
        String identifier = firstName + lastName + trans.payer_info.email_address;
        identifier = identifier.length() > 255 ? identifier.substring(0, 244) : identifier;
        return identifier;
    }

    private Contact getContact(PayPalTransactionData.Transaction_details trans) {
        Contact c = new Contact (
            Account = new Account(External_Id__c=getAccountIdentifier(trans)),
            FirstName = !String.isEmpty(trans.payer_info?.payer_name?.given_name) ? trans.payer_info?.payer_name.given_name : !String.isEmpty(trans.shipping_info?.name) ? trans.shipping_info.name.split(', ')[0] : '',
            LastName = !String.isEmpty(trans.payer_info?.payer_name?.surname) ? trans.payer_info.payer_name.surname : (!String.isEmpty(trans.shipping_info?.name) & trans.shipping_info.name.contains(',')) ? trans.shipping_info.name.split(', ')[1] : trans.shipping_info.name,
            //MiddleName = trans.payer_info?.payer_name?.middle_name ? trans.payer_info.payer_name.middle_name : '',
            Email = leftTrim(trans.payer_info.email_address, contactFieldLengths.get('Email')),
            External_Id__c = getContactIdentifier(trans)
        );
        c.FirstName = leftTrim(c.FirstName, contactFieldLengths.get('FirstName'));
        c.LastName = leftTrim(c.LastName, contactFieldLengths.get('LastName'));
        c = getContactAddress(c, trans);
        return c;
    }

    private Contact getContactAddress(Contact c, PayPalTransactionData.Transaction_details trans){
        //mailing
        String MailingStreet =  !String.isEmpty(trans.shipping_info?.address?.line1) ? trans.shipping_info.address.line1 : '';
        if (!String.isBlank(trans.shipping_info?.address?.line2)) {
            MailingStreet += ', ';
            MailingStreet += !String.isEmpty(trans.shipping_info?.address?.line2) ? trans.shipping_info.address.line2 : '';
        } 
        c.MailingStreet = leftTrim(MailingStreet, contactFieldLengths.get('MailingStreet'));
        c.MailingCity = !String.isEmpty(trans.shipping_info?.address?.city) ? leftTrim(trans.shipping_info.address.city, contactFieldLengths.get('MailingCity')) : '';
        c.MailingState = !String.isEmpty(trans.shipping_info?.address?.state) ? leftTrim(trans.shipping_info.address.state, contactFieldLengths.get('MailingState')) : '';
        c.MailingCountry = !String.isEmpty(trans.shipping_info?.address?.country_code) ? leftTrim(trans.shipping_info.address.country_code, contactFieldLengths.get('MailingCountry')) : '';
        c.MailingPostalCode = !String.isEmpty(trans.shipping_info?.address?.postal_code) ? leftTrim(trans.shipping_info.address.postal_code, contactFieldLengths.get('MailingPostalCode')) : '';
        //billing into Other address
        String OtherStreet =  !String.isEmpty(trans.payer_info?.address?.line1) ? trans.payer_info.address.line1 : '';
        if (!String.isBlank(trans.payer_info?.address?.line2)) {
            OtherStreet += ', ';
            OtherStreet += !String.isEmpty(trans.payer_info?.address?.line2) ? trans.payer_info.address.line2 : '';
        } 
        c.OtherStreet = leftTrim(OtherStreet, contactFieldLengths.get('OtherStreet'));
        c.OtherCity = !String.isEmpty(trans.payer_info?.address?.city) ? leftTrim(trans.payer_info.address.city, contactFieldLengths.get('OtherCity')) : '';
        c.OtherState = !String.isEmpty(trans.payer_info?.address?.state) ? leftTrim(trans.payer_info.address.state, contactFieldLengths.get('OtherState')) : '';
        c.OtherCountry = !String.isEmpty(trans.payer_info?.address?.country_code) ? leftTrim(trans.payer_info.address.country_code, contactFieldLengths.get('OtherCountry')) : '';
        c.OtherPostalCode = !String.isEmpty(trans.payer_info?.address?.postal_code) ? leftTrim(trans.payer_info.address.postal_code, contactFieldLengths.get('OtherPostalCode')) : '';
        return c;
    }

    private String getAccountIdentifier(PayPalTransactionData.Transaction_details trans) {
        if(!String.isEmpty(trans.transaction_info.paypal_reference_id) & (!String.isEmpty(trans.transaction_info?.paypal_reference_id_type) & trans.transaction_info?.paypal_reference_id_type == 'TXN')) {
            for (PayPalTransactionData.Transaction_details tran : transactionData.Transaction_details) {
                if(tran.transaction_info.transaction_id == trans.transaction_info.paypal_reference_id) {
                    trans = tran;
                }
            }
        }
        Account a = new Account();
        a = getAccountAddress(a, trans);
        String billingAddress = a.BillingStreet + a.BillingCity + a.BillingState + a.BillingCountry + a.BillingPostalCode;
        String shippingAddress = a.ShippingStreet + a.ShippingCity + a.ShippingState + a.ShippingCountry + a.ShippingPostalCode;
        String identifier = !String.isBlank(shippingAddress) ? shippingAddress : !String.isBlank(billingAddress) ? billingAddress : '';
        identifier = identifier.length() > 255 ? identifier.substring(0, 244) : identifier;
        if (String.isBlank(identifier)) {
            identifier = getContactIdentifier(trans);
        }
        return identifier;
        //return trans.payer_info.account_id;
    }

    private String getPayPalTransactionIdentifier(PayPalTransactionData.Transaction_details trans) {
        String accountId = trans.payer_info.account_id;
        String transactionId = trans.transaction_info.transaction_id;
        String transactionEventCode = trans.transaction_info.transaction_event_code;
        String identifier = accountId + '-' + transactionId + '-' + transactionEventCode + '-' + trans.transaction_info.transaction_amount.value;
        identifier = identifier.length() > 255 ? identifier.substring(0, 244) : identifier;
        return identifier;
    }

    private PayPal_Transaction__c getPayPalTransaction(PayPalTransactionData.Transaction_details trans, Account a, Contact c) {
        PayPal_Transaction__c d = new PayPal_Transaction__c (
            Name = leftTrim(trans.transaction_info.transaction_id, paypalTransactionFieldLengths.get('Name')),
            Transaction_Event_Code__c = leftTrim(trans.transaction_info.transaction_event_code, paypalTransactionFieldLengths.get('Transaction_Event_Code__c')),
            Reference_id__c = !String.isEmpty(trans.transaction_info.paypal_reference_id) ? leftTrim(trans.transaction_info.paypal_reference_id, paypalTransactionFieldLengths.get('Reference_id__c')) : '',
            Reference_Id_Type__c = !String.isEmpty(trans.transaction_info.paypal_reference_id_type) ? leftTrim(trans.transaction_info.paypal_reference_id_type, paypalTransactionFieldLengths.get('Reference_Id_Type__c')) : '',
            Transaction_Subject__c = !String.isEmpty(trans.transaction_info?.transaction_subject) ? leftTrim(trans.transaction_info.transaction_subject, paypalTransactionFieldLengths.get('Transaction_Subject__c')) : '',
            Transaction_Note__c = !String.isEmpty(trans.transaction_info?.transaction_note) ? leftTrim(trans.transaction_info.transaction_note, paypalTransactionFieldLengths.get('Transaction_Note__c')) : '',
            Transaction_ID__c = getPayPalTransactionIdentifier(trans),
            Transaction_Amount__c = Decimal.valueOf(trans.transaction_info.transaction_amount.value),
            Fee_Amount__c = !String.isEmpty(trans.transaction_info?.fee_amount?.value) ? Decimal.valueOf(trans.transaction_info.fee_amount.value) : 0,
            Transaction_Date__c = Date.valueof(trans.transaction_info.transaction_initiation_date),
            Email__c = leftTrim(trans.payer_info.email_address, paypalTransactionFieldLengths.get('Email__c')),
            First_Name__c = !String.isEmpty(trans.payer_info?.payer_name?.given_name) ? trans.payer_info?.payer_name.given_name : !String.isEmpty(trans.shipping_info?.name) ? trans.shipping_info.name.split(', ')[0] : '',
            Last_Name__c = !String.isEmpty(trans.payer_info?.payer_name?.surname) ? trans.payer_info.payer_name.surname : (!String.isEmpty(trans.shipping_info?.name) & trans.shipping_info.name.contains(',')) ? trans.shipping_info.name.split(', ')[1] : trans.shipping_info.name,
            Cart_Info__c = trans.cart_info?.item_details?.size() > 0 ? JSON.serialize(trans.cart_info) : ''
        );
        d.First_Name__c = leftTrim(d.First_Name__c, paypalTransactionFieldLengths.get('First_Name__c'));
        d.Last_Name__c = leftTrim(d.Last_Name__c, paypalTransactionFieldLengths.get('Last_Name__c'));
        d.Cart_Info__c = leftTrim(d.Cart_Info__c, paypalTransactionFieldLengths.get('Cart_Info__c'));
        d = getPayPalTransactionAddress(d, trans);
        //PayPalTransactionData.cart_info cartInfo = (PayPalTransactionData.cart_info)JSON.deserialize(d.Cart_Info__c, PayPalTransactionData.cart_info.class);
        if (!transactionData.excludeAccountContactProcessing) {
            if (a.Id != null) {
                d.Account__c = a.Id;
            } else {
                d.Account__r = new Account( External_Id__c = a.External_Id__c );
            }
            if (c.Id != null) {
                d.Contact__c = c.Id;
            } else {
                d.Contact__r = new Contact( External_Id__c = c.External_Id__c );
            }
        }
        return d;
    }

    private PayPal_Transaction__c getPayPalTransactionAddress(PayPal_Transaction__c d, PayPalTransactionData.Transaction_details trans) {
        String MailingStreet =  !String.isEmpty(trans.shipping_info?.address?.line1) ? trans.shipping_info.address.line1 : '';
        if (!String.isBlank(trans.shipping_info?.address?.line2)) {
            MailingStreet += ', ';
            MailingStreet += !String.isEmpty(trans.shipping_info?.address?.line2) ? trans.shipping_info.address.line2 : '';
        }
        d.Mailing_Address__Street__s = leftTrim(MailingStreet, paypalTransactionFieldLengths.get('Mailing_Address__Street__s'));
        d.Mailing_Address__City__s = !String.isEmpty(trans.shipping_info?.address?.city) ? leftTrim(trans.shipping_info.address.city, paypalTransactionFieldLengths.get('Mailing_Address__City__s')) : '';
        d.Mailing_Address__StateCode__s = !String.isEmpty(trans.shipping_info?.address?.state) ? leftTrim(trans.shipping_info.address.state, paypalTransactionFieldLengths.get('Mailing_Address__StateCode__s')) : '';
        d.Mailing_Address__CountryCode__s = !String.isEmpty(trans.shipping_info?.address?.country_code) ? leftTrim(trans.shipping_info.address.country_code, paypalTransactionFieldLengths.get('Mailing_Address__CountryCode__s')) : '';
        d.Mailing_Address__PostalCode__s = !String.isEmpty(trans.shipping_info?.address?.postal_code) ? leftTrim(trans.shipping_info.address.postal_code, paypalTransactionFieldLengths.get('Mailing_Address__PostalCode__s')) : '';
        String BillingStreet =  !String.isEmpty(trans.payer_info?.address?.line1) ? trans.payer_info.address.line1 : '';
        if (!String.isBlank(trans.payer_info?.address?.line2)) {
            BillingStreet += ', ';
            BillingStreet += !String.isEmpty(trans.payer_info?.address?.line2) ? trans.payer_info.address.line2 : '';
        }
        d.Billing_Address__Street__s = leftTrim(BillingStreet, paypalTransactionFieldLengths.get('Billing_Address__Street__s'));
        d.Billing_Address__City__s = !String.isEmpty(trans.payer_info?.address?.city) ? leftTrim(trans.payer_info.address.city, paypalTransactionFieldLengths.get('Billing_Address__City__s')) : '';
        d.Billing_Address__StateCode__s = !String.isEmpty(trans.payer_info?.address?.state) ? leftTrim(trans.payer_info.address.state, paypalTransactionFieldLengths.get('Billing_Address__StateCode__s')) : '';
        d.Billing_Address__CountryCode__s = !String.isEmpty(trans.payer_info?.address?.country_code) ? leftTrim(trans.payer_info.address.country_code, paypalTransactionFieldLengths.get('Billing_Address__CountryCode__s')) : '';
        d.Billing_Address__PostalCode__s = !String.isEmpty(trans.payer_info?.address?.postal_code) ? leftTrim(trans.payer_info.address.postal_code, paypalTransactionFieldLengths.get('Billing_Address__PostalCode__s')) : '';
        return d;
    }

    private class sfWrapper {
        public Map<String, Account> households {get; set;}
        public Map<String, Contact> contacts {get; set;}
        public Map<String, PayPal_Transaction__c> paypalTransactions {get; set;}
    }

    public static void errorEmail(String context, String errorMessage) {
        // Create a new SingleEmailMessage object
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        // Set the email properties
        email.setToAddresses(new String[] { [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND isActive = True ORDER BY CreatedDate Asc LIMIT 1][0].Email }); // Set the recipient's email address
        email.setSubject(context); // Set the email subject
        email.setPlainTextBody(errorMessage); // Set the plain text body
        // Send the email
        if(!Test.isRunningTest()) {
            Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }

    private String leftTrim(String value, Integer allowedLength) {
        if (!String.isEmpty(value) & value.length() > allowedLength) { value = value.left(allowedLength); }
        return value;
    }

    private void setFieldLengthMaps() {
        accountFieldLengths = new Map<String, Integer>();
        contactFieldLengths = new Map<String, Integer>();
        paypalTransactionFieldLengths = new Map<String, Integer>();
        // Specify the object's API name for which you want to retrieve field lengths
        List<String> objectApiNames = new List<String>();
        objectApiNames.add('Account');
        objectApiNames.add('Contact');
        objectApiNames.add('PayPal_Transaction__c');
        // Describe the object to get its fields and their properties
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String objectApiName : objectApiNames) {
            Schema.SObjectType objectType = gd.get(objectApiName);
            if (objectType != null) {
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
                for (String fieldName : fieldMap.keySet()) {
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    // Check if the field has a length (e.g., for text fields)
                    if (fieldDescribe.isCustom() && fieldDescribe.getLength() != null) {
                        updateFieldLengthMaps(objectApiName, fieldName, fieldDescribe.getLength());
                    }
                }
            }
        }
    }

    private void updateFieldLengthMaps(String objectApiName, String fieldName, Integer fieldLength) {
        if(objectApiName == 'Account') {
            accountFieldLengths.put(fieldName, fieldLength);
        } else if(objectApiName == 'Contact') {
            contactFieldLengths.put(fieldName, fieldLength);
        } else if(objectApiName == 'PayPal_Transaction__c') {
            paypalTransactionFieldLengths.put(fieldName, fieldLength);
        }
    }

}