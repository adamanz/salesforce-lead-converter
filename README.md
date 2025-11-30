# Lead Converter Invocable

[![Salesforce API](https://img.shields.io/badge/Salesforce%20API-63.0-blue)](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Apex](https://img.shields.io/badge/Apex-Invocable-blueviolet)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm)

A Salesforce Apex invocable action for converting leads to accounts, contacts, and opportunities. Designed for use in Salesforce Flows with full parameter flexibility.

## Features

- Convert leads with a single action in Flow
- Merge into existing accounts and contacts
- Custom opportunity naming
- Optional opportunity creation skip
- Owner assignment with notification emails
- Bulk conversion support
- Auto-detection of converted status
- Comprehensive error handling
- Bypass duplicate detection rules

## Deployment

### Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) installed
- Authenticated to your target org

### Authenticate to Your Org

```bash
# For production/developer org
sf org login web -a MyOrg

# For sandbox
sf org login web -a MySandbox -r https://test.salesforce.com
```

### Deploy to Org

```bash
# Deploy to default org
sf project deploy start

# Deploy to specific org
sf project deploy start -o MyOrg

# Deploy with verbose output
sf project deploy start -o MyOrg --verbose

# Validate only (no actual deployment)
sf project deploy start -o MyOrg --dry-run
```

### Verify Deployment

```bash
# Run tests to verify
sf apex run test -n LeadConverterInvocableTest -o MyOrg -r human
```

## Using in Flow

### Adding the Action

1. Open **Setup** > **Flows**
2. Create or edit a Flow
3. Add an **Action** element
4. Search for **"Convert Lead"** in the action search
5. Configure the input variables
6. Store the output variables for use in your Flow

### Flow Example

```
[Get Lead Record] → [Convert Lead Action] → [Decision: Is Success?] → [Next Steps]
```

## Input Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `Lead ID` | ID | Yes | The ID of the lead to convert |
| `Account ID` | ID | No | Existing account ID to merge into. Creates new account if not provided |
| `Contact ID` | ID | No | Existing contact ID to merge into. Must be associated with the specified account |
| `Converted Status` | Text | No | Lead status value for converted lead. Auto-detects if not provided |
| `Opportunity Name` | Text | No | Name for the new opportunity. Defaults to lead company name |
| `Do Not Create Opportunity` | Boolean | No | Set to `true` to skip opportunity creation |
| `Owner ID` | ID | No | Owner for new records. Defaults to lead owner |
| `Send Notification Email` | Boolean | No | Send email notification to new owner |
| `Overwrite Lead Source` | Boolean | No | Overwrite LeadSource on target contact when merging |
| `Bypass Duplicate Rules` | Boolean | No | Set to `true` to bypass duplicate detection rules during conversion |

## Output Variables

| Variable | Type | Description |
|----------|------|-------------|
| `Account ID` | ID | The ID of the created or merged account |
| `Contact ID` | ID | The ID of the created or merged contact |
| `Opportunity ID` | ID | The ID of the created opportunity (null if skipped) |
| `Is Success` | Boolean | Whether the conversion was successful |
| `Error Message` | Text | Error details if conversion failed |
| `Lead ID` | ID | The original Lead ID (returned on both success and failure) |

## Usage Examples

### Basic Conversion (Flow)

Only the Lead ID is required. The action will:
- Create a new Account (using Lead's Company name)
- Create a new Contact (using Lead's name and details)
- Create a new Opportunity (using Lead's Company name)
- Auto-detect the converted status

### Merge into Existing Account

Set the `Account ID` to merge the lead into an existing account instead of creating a new one.

### Convert Without Opportunity

Set `Do Not Create Opportunity` = `true` to convert the lead without creating an opportunity.

### Custom Opportunity Name

Set `Opportunity Name` to override the default opportunity naming (which uses the lead's company name).

### Assign to Different Owner

Set `Owner ID` to assign the converted records to a specific user. Enable `Send Notification Email` to notify them.

### Full Merge (Account + Contact)

Provide both `Account ID` and `Contact ID` to merge the lead into existing records. The contact must belong to the specified account. Enable `Overwrite Lead Source` to update the contact's LeadSource field.

### Bypass Duplicate Detection

Set `Bypass Duplicate Rules` = `true` to force conversion even when duplicate detection rules would normally block it. This uses `Database.DMLOptions.DuplicateRuleHeader.allowSave` to bypass the org's duplicate rules.

## Error Handling

The action uses partial success mode, meaning:
- Each lead conversion is independent
- Failed conversions don't block successful ones
- Check `Is Success` output for each result
- `Error Message` contains details for failures

Common error scenarios:
- Lead already converted
- Invalid Account/Contact ID
- Contact not associated with specified Account
- Missing required fields on Lead
- Duplicate detected (use `Bypass Duplicate Rules` to override)

**Note:** The `Lead ID` output is always returned, even when conversion fails. This allows you to identify which lead caused the error in your Flow's error handling path.

## API Version

This package uses Salesforce API version **63.0** (Spring '25).

## File Structure

```
lead-converter/
├── force-app/
│   └── main/
│       └── default/
│           └── classes/
│               ├── LeadConverterInvocable.cls
│               ├── LeadConverterInvocable.cls-meta.xml
│               ├── LeadConverterInvocableTest.cls
│               └── LeadConverterInvocableTest.cls-meta.xml
├── sfdx-project.json
└── README.md
```

## License

MIT
