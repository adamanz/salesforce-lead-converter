/**
 * @description Test class for LeadConverterInvocable
 *              Provides comprehensive test coverage for all conversion scenarios
 * @author Auto-generated
 * @date 2024
 */
@IsTest
private class LeadConverterInvocableTest {

    /**
     * @description Creates test data for lead conversion tests
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts for merge scenarios
        Account testAccount = new Account(Name = 'Test Account for Lead Conversion');
        insert testAccount;

        // Create test contact associated with the account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'testcontact@example.com'
        );
        insert testContact;

        // Create test user for owner assignment scenarios
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Owner',
            Email = 'testowner@example.com',
            Username = 'testowner' + DateTime.now().getTime() + '@example.com',
            Alias = 'towner',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }

    /**
     * @description Test basic lead conversion with minimal parameters
     */
    @IsTest
    static void testBasicLeadConversion() {
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Acme Corporation',
            Email = 'john.doe@acme.com',
            LeadSource = 'Web'
        );
        insert testLead;

        // Create conversion request with minimal parameters
        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        LeadConverterInvocable.LeadConvertResult result = results[0];
        System.assertEquals(true, result.isSuccess, 'Conversion should be successful');
        System.assertNotEquals(null, result.accountId, 'Account ID should be populated');
        System.assertNotEquals(null, result.contactId, 'Contact ID should be populated');
        System.assertNotEquals(null, result.opportunityId, 'Opportunity ID should be populated');
        System.assertEquals(null, result.errorMessage, 'Error message should be null');

        // Verify the lead is converted
        Lead convertedLead = [SELECT IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be marked as converted');
        System.assertEquals(result.accountId, convertedLead.ConvertedAccountId, 'Account IDs should match');
        System.assertEquals(result.contactId, convertedLead.ConvertedContactId, 'Contact IDs should match');
        System.assertEquals(result.opportunityId, convertedLead.ConvertedOpportunityId, 'Opportunity IDs should match');
    }

    /**
     * @description Test lead conversion with custom opportunity name
     */
    @IsTest
    static void testLeadConversionWithCustomOpportunityName() {
        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Smith Industries',
            Email = 'jane.smith@smithind.com'
        );
        insert testLead;

        String customOppName = 'Custom Opportunity - Q4 Deal';
        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.opportunityName = customOppName;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');

        // Verify opportunity name
        Opportunity opp = [SELECT Name FROM Opportunity WHERE Id = :results[0].opportunityId];
        System.assertEquals(customOppName, opp.Name, 'Opportunity name should match custom name');
    }

    /**
     * @description Test lead conversion without creating opportunity
     */
    @IsTest
    static void testLeadConversionNoOpportunity() {
        Lead testLead = new Lead(
            FirstName = 'Bob',
            LastName = 'Johnson',
            Company = 'Johnson LLC',
            Email = 'bob.johnson@johnsonllc.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.doNotCreateOpportunity = true;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertEquals(null, results[0].opportunityId, 'Opportunity ID should be null');
        System.assertNotEquals(null, results[0].accountId, 'Account ID should be populated');
        System.assertNotEquals(null, results[0].contactId, 'Contact ID should be populated');
    }

    /**
     * @description Test lead conversion merging into existing account
     */
    @IsTest
    static void testLeadConversionWithExistingAccount() {
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Alice',
            LastName = 'Williams',
            Company = 'Williams Co',
            Email = 'alice.williams@williamsco.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.accountId = existingAccount.Id;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertEquals(existingAccount.Id, results[0].accountId, 'Should merge into existing account');
    }

    /**
     * @description Test lead conversion merging into existing account and contact
     */
    @IsTest
    static void testLeadConversionWithExistingAccountAndContact() {
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];
        Contact existingContact = [SELECT Id FROM Contact WHERE AccountId = :existingAccount.Id LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Charlie',
            LastName = 'Brown',
            Company = 'Peanuts Inc',
            Email = 'charlie.brown@peanuts.com',
            LeadSource = 'Partner Referral'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.accountId = existingAccount.Id;
        request.contactId = existingContact.Id;
        request.overwriteLeadSource = true;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertEquals(existingAccount.Id, results[0].accountId, 'Should merge into existing account');
        System.assertEquals(existingContact.Id, results[0].contactId, 'Should merge into existing contact');

        // Verify lead source was overwritten
        Contact updatedContact = [SELECT LeadSource FROM Contact WHERE Id = :existingContact.Id];
        System.assertEquals('Partner Referral', updatedContact.LeadSource, 'LeadSource should be overwritten');
    }

    /**
     * @description Test lead conversion with custom owner
     */
    @IsTest
    static void testLeadConversionWithCustomOwner() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testowner@example.com' LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'David',
            LastName = 'Miller',
            Company = 'Miller Corp',
            Email = 'david.miller@millercorp.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.ownerId = testUser.Id;
        request.sendNotificationEmail = false; // Avoid sending emails in tests

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');

        // Verify owner assignment
        Account newAccount = [SELECT OwnerId FROM Account WHERE Id = :results[0].accountId];
        System.assertEquals(testUser.Id, newAccount.OwnerId, 'Account owner should match specified owner');
    }

    /**
     * @description Test lead conversion with explicit converted status
     */
    @IsTest
    static void testLeadConversionWithExplicitStatus() {
        LeadStatus convertedStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Eve',
            LastName = 'Wilson',
            Company = 'Wilson Enterprises',
            Email = 'eve.wilson@wilsonent.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.convertedStatus = convertedStatus.ApiName;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');

        Lead convertedLead = [SELECT Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(convertedStatus.ApiName, convertedLead.Status, 'Lead status should match converted status');
    }

    /**
     * @description Test bulk lead conversion
     */
    @IsTest
    static void testBulkLeadConversion() {
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'Lead' + i,
                Company = 'Bulk Company ' + i,
                Email = 'bulk.lead' + i + '@example.com'
            ));
        }
        insert testLeads;

        List<LeadConverterInvocable.LeadConvertRequest> requests = new List<LeadConverterInvocable.LeadConvertRequest>();
        for (Lead lead : testLeads) {
            LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
            request.leadId = lead.Id;
            requests.add(request);
        }

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = LeadConverterInvocable.convertLeads(requests);
        Test.stopTest();

        System.assertEquals(10, results.size(), 'Should return 10 results');
        
        Integer successCount = 0;
        for (LeadConverterInvocable.LeadConvertResult result : results) {
            if (result.isSuccess) {
                successCount++;
                System.assertNotEquals(null, result.accountId, 'Account ID should be populated');
                System.assertNotEquals(null, result.contactId, 'Contact ID should be populated');
            }
        }
        System.assertEquals(10, successCount, 'All conversions should be successful');
    }

    /**
     * @description Test lead conversion with all optional parameters set
     */
    @IsTest
    static void testLeadConversionWithAllParameters() {
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testowner@example.com' LIMIT 1];
        LeadStatus convertedStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Frank',
            LastName = 'Garcia',
            Company = 'Garcia Solutions',
            Email = 'frank.garcia@garciasol.com',
            LeadSource = 'Advertisement'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.accountId = existingAccount.Id;
        request.convertedStatus = convertedStatus.ApiName;
        request.opportunityName = 'Full Parameter Test Opp';
        request.doNotCreateOpportunity = false;
        request.ownerId = testUser.Id;
        request.sendNotificationEmail = false;
        request.overwriteLeadSource = false;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertEquals(existingAccount.Id, results[0].accountId, 'Should use existing account');
        System.assertNotEquals(null, results[0].opportunityId, 'Opportunity should be created');

        Opportunity opp = [SELECT Name FROM Opportunity WHERE Id = :results[0].opportunityId];
        System.assertEquals('Full Parameter Test Opp', opp.Name, 'Opportunity name should match');
    }

    /**
     * @description Test lead conversion failure with already converted lead
     */
    @IsTest
    static void testLeadConversionFailure() {
        // Create a lead and convert it first
        Lead testLead = new Lead(
            FirstName = 'Already',
            LastName = 'Converted',
            Company = 'Converted Company'
        );
        insert testLead;

        // Convert it once
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertedStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertedStatus.ApiName);
        Database.convertLead(lc);

        // Now try to convert it again via our invocable - this should fail
        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Conversion should fail for already converted lead');
        System.assertNotEquals(null, results[0].errorMessage, 'Error message should be populated');
    }

    /**
     * @description Test that doNotCreateOpportunity = false still creates opportunity
     */
    @IsTest
    static void testDoNotCreateOpportunityFalse() {
        Lead testLead = new Lead(
            FirstName = 'Grace',
            LastName = 'Lee',
            Company = 'Lee Industries',
            Email = 'grace.lee@leeind.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.doNotCreateOpportunity = false;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertNotEquals(null, results[0].opportunityId, 'Opportunity should be created when doNotCreateOpportunity is false');
    }

    /**
     * @description Test conversion with sendNotificationEmail = true
     */
    @IsTest
    static void testLeadConversionWithNotificationEmail() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testowner@example.com' LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Henry',
            LastName = 'Taylor',
            Company = 'Taylor Tech',
            Email = 'henry.taylor@taylortech.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.ownerId = testUser.Id;
        request.sendNotificationEmail = true;

        Test.startTest();
        // Email sending is automatically disabled in test context
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful even with notification email flag');
    }

    /**
     * @description Test with null optional boolean parameters (cover null checks)
     */
    @IsTest
    static void testNullBooleanParameters() {
        Lead testLead = new Lead(
            FirstName = 'Ivy',
            LastName = 'Chen',
            Company = 'Chen Corp',
            Email = 'ivy.chen@chencorp.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        // Explicitly leave all optional boolean fields as null
        request.doNotCreateOpportunity = null;
        request.sendNotificationEmail = null;
        request.overwriteLeadSource = null;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful with null boolean parameters');
        System.assertNotEquals(null, results[0].opportunityId, 'Opportunity should be created by default');
    }

    /**
     * @description Test empty string for convertedStatus (should use default)
     */
    @IsTest
    static void testEmptyConvertedStatus() {
        Lead testLead = new Lead(
            FirstName = 'Jack',
            LastName = 'White',
            Company = 'White Industries',
            Email = 'jack.white@whiteindustries.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.convertedStatus = ''; // Empty string should trigger default

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results = 
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful with empty converted status');
    }

    /**
     * @description Test that leadId is returned in result for successful conversion
     */
    @IsTest
    static void testLeadIdReturnedOnSuccess() {
        Lead testLead = new Lead(
            FirstName = 'Kevin',
            LastName = 'Brown',
            Company = 'Brown Co',
            Email = 'kevin.brown@brownco.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results =
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful');
        System.assertEquals(testLead.Id, results[0].leadId, 'Lead ID should be returned in result');
    }

    /**
     * @description Test that leadId is returned in result even when conversion fails
     */
    @IsTest
    static void testLeadIdReturnedOnFailure() {
        // Create a lead and convert it first
        Lead testLead = new Lead(
            FirstName = 'Laura',
            LastName = 'Davis',
            Company = 'Davis Inc'
        );
        insert testLead;

        // Convert it once
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertedStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertedStatus.ApiName);
        Database.convertLead(lc);

        // Now try to convert it again via our invocable - this should fail
        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results =
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess, 'Conversion should fail');
        System.assertEquals(testLead.Id, results[0].leadId, 'Lead ID should still be returned even on failure');
    }

    /**
     * @description Test lead conversion with bypass duplicate rules flag set to true
     */
    @IsTest
    static void testLeadConversionWithBypassDuplicateRules() {
        Lead testLead = new Lead(
            FirstName = 'Mike',
            LastName = 'Jones',
            Company = 'Jones LLC',
            Email = 'mike.jones@jonesllc.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.bypassDuplicateRules = true;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results =
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful with bypass duplicate rules');
        System.assertNotEquals(null, results[0].accountId, 'Account ID should be populated');
        System.assertNotEquals(null, results[0].contactId, 'Contact ID should be populated');
        System.assertEquals(testLead.Id, results[0].leadId, 'Lead ID should be returned');
    }

    /**
     * @description Test lead conversion with bypass duplicate rules flag set to false (standard behavior)
     */
    @IsTest
    static void testLeadConversionWithBypassDuplicateRulesFalse() {
        Lead testLead = new Lead(
            FirstName = 'Nancy',
            LastName = 'Smith',
            Company = 'Smith Co',
            Email = 'nancy.smith@smithco.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.bypassDuplicateRules = false;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results =
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful with bypass = false');
        System.assertEquals(testLead.Id, results[0].leadId, 'Lead ID should be returned');
    }

    /**
     * @description Test lead conversion with null bypass duplicate rules flag (should use standard behavior)
     */
    @IsTest
    static void testLeadConversionWithNullBypassDuplicateRules() {
        Lead testLead = new Lead(
            FirstName = 'Oscar',
            LastName = 'Adams',
            Company = 'Adams Corp',
            Email = 'oscar.adams@adamscorp.com'
        );
        insert testLead;

        LeadConverterInvocable.LeadConvertRequest request = new LeadConverterInvocable.LeadConvertRequest();
        request.leadId = testLead.Id;
        request.bypassDuplicateRules = null;

        Test.startTest();
        List<LeadConverterInvocable.LeadConvertResult> results =
            LeadConverterInvocable.convertLeads(new List<LeadConverterInvocable.LeadConvertRequest>{request});
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'Conversion should be successful with null bypass flag');
        System.assertEquals(testLead.Id, results[0].leadId, 'Lead ID should be returned');
    }
}

