/**
 * @description Invocable Apex class for converting leads to accounts, contacts, and opportunities.
 *              Designed for use in Salesforce Flows with full parameter flexibility.
 * @author Auto-generated
 * @date 2024
 */
public with sharing class LeadConverterInvocable {

    /**
     * @description Input parameters for lead conversion
     */
    public class LeadConvertRequest {
        @InvocableVariable(label='Lead ID' description='The ID of the lead to convert' required=true)
        public Id leadId;

        @InvocableVariable(label='Account ID' description='Existing account ID to merge into (optional - creates new if not provided)')
        public Id accountId;

        @InvocableVariable(label='Contact ID' description='Existing contact ID to merge into (must be associated with the specified account)')
        public Id contactId;

        @InvocableVariable(label='Converted Status' description='Lead status value for converted lead (auto-detects if not provided)')
        public String convertedStatus;

        @InvocableVariable(label='Opportunity Name' description='Name for the new opportunity (defaults to lead company name)')
        public String opportunityName;

        @InvocableVariable(label='Do Not Create Opportunity' description='Set to true to skip opportunity creation')
        public Boolean doNotCreateOpportunity;

        @InvocableVariable(label='Owner ID' description='Owner for new records (defaults to lead owner)')
        public Id ownerId;

        @InvocableVariable(label='Send Notification Email' description='Send email notification to new owner')
        public Boolean sendNotificationEmail;

        @InvocableVariable(label='Overwrite Lead Source' description='Overwrite LeadSource on target contact')
        public Boolean overwriteLeadSource;

        @InvocableVariable(label='Bypass Duplicate Rules' description='Set to true to bypass duplicate detection rules during conversion')
        public Boolean bypassDuplicateRules;
    }

    /**
     * @description Output results from lead conversion
     */
    public class LeadConvertResult {
        @InvocableVariable(label='Opportunity ID' description='The ID of the created or merged opportunity')
        public Id opportunityId;

        @InvocableVariable(label='Account ID' description='The ID of the created or merged account')
        public Id accountId;

        @InvocableVariable(label='Contact ID' description='The ID of the created or merged contact')
        public Id contactId;

        @InvocableVariable(label='Is Success' description='Whether the conversion was successful')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error details if conversion failed')
        public String errorMessage;

        @InvocableVariable(label='Lead ID' description='The original Lead ID (returned on both success and failure)')
        public Id leadId;
    }

    /**
     * @description Converts leads to accounts, contacts, and optionally opportunities
     * @param requests List of LeadConvertRequest objects containing conversion parameters
     * @return List of LeadConvertResult objects containing the results of each conversion
     */
    @InvocableMethod(label='Convert Lead' description='Converts a lead to an account, contact, and optionally an opportunity' category='Lead Management')
    public static List<LeadConvertResult> convertLeads(List<LeadConvertRequest> requests) {
        List<LeadConvertResult> results = new List<LeadConvertResult>();

        // Get the default converted status if not provided
        String defaultConvertedStatus = getDefaultConvertedStatus();

        // Process each conversion request individually to handle DMLOptions per request
        for (LeadConvertRequest request : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();

            // Required field
            lc.setLeadId(request.leadId);

            // Set converted status (use default if not provided)
            String statusToUse = String.isNotBlank(request.convertedStatus)
                ? request.convertedStatus
                : defaultConvertedStatus;
            lc.setConvertedStatus(statusToUse);

            // Optional: Existing account to merge into
            if (request.accountId != null) {
                lc.setAccountId(request.accountId);
            }

            // Optional: Existing contact to merge into
            if (request.contactId != null) {
                lc.setContactId(request.contactId);
            }

            // Optional: Custom opportunity name
            if (String.isNotBlank(request.opportunityName)) {
                lc.setOpportunityName(request.opportunityName);
            }

            // Optional: Skip opportunity creation
            if (request.doNotCreateOpportunity != null && request.doNotCreateOpportunity) {
                lc.setDoNotCreateOpportunity(true);
            }

            // Optional: Set owner for new records
            if (request.ownerId != null) {
                lc.setOwnerId(request.ownerId);
            }

            // Optional: Send notification email
            if (request.sendNotificationEmail != null && request.sendNotificationEmail) {
                lc.setSendNotificationEmail(true);
            }

            // Optional: Overwrite lead source on contact
            if (request.overwriteLeadSource != null && request.overwriteLeadSource) {
                lc.setOverwriteLeadSource(true);
            }

            // Perform the conversion with or without duplicate rule bypass
            Database.LeadConvertResult lcr;
            if (request.bypassDuplicateRules != null && request.bypassDuplicateRules) {
                // Bypass duplicate detection rules
                Database.DMLOptions dmlOptions = new Database.DMLOptions();
                dmlOptions.DuplicateRuleHeader.allowSave = true;
                dmlOptions.DuplicateRuleHeader.runAsCurrentUser = true;
                lcr = Database.convertLead(lc, dmlOptions);
            } else {
                // Standard conversion without bypass
                List<Database.LeadConvertResult> lcrList = Database.convertLead(new List<Database.LeadConvert>{lc}, false);
                lcr = lcrList[0];
            }

            // Process result
            LeadConvertResult result = new LeadConvertResult();
            result.isSuccess = lcr.isSuccess();
            result.leadId = request.leadId; // Always return the original lead ID

            if (lcr.isSuccess()) {
                result.opportunityId = lcr.getOpportunityId();
                result.accountId = lcr.getAccountId();
                result.contactId = lcr.getContactId();
            } else {
                // Collect error messages
                List<String> errorMessages = new List<String>();
                for (Database.Error err : lcr.getErrors()) {
                    errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                result.errorMessage = String.join(errorMessages, '; ');
            }

            results.add(result);
        }

        return results;
    }

    /**
     * @description Gets the default converted status for leads
     * @return The API name of a converted lead status
     */
    private static String getDefaultConvertedStatus() {
        LeadStatus convertedStatus = [
            SELECT ApiName 
            FROM LeadStatus 
            WHERE IsConverted = true 
            LIMIT 1
        ];
        return convertedStatus.ApiName;
    }
}

