/*
*********************************************************
Apex Class Name    : AddressFinderServiceController
Test Class         : AddressFinderServiceControllerTest
Created Date       : September 24, 2025
@description       : This is class is used for fetching address suggestions and detailed address metadata from the AddressFinder API.
@author            : Surojit Dutta (Merkle)
*********************************************************
*/


public with sharing class AddressFinderServiceController {

    // Named Credential for AddressFinder API
    private static final String NAMED_CREDENTIAL = 'callout:AddressFinderNC';
    private static final String API_FORMAT = '&format=json&ascii=1';

    /**
     * Fetches address suggestions based on user input using the AddressFinder API.
     * 
     * @param input The partial address input string.
     * @return A list of address suggestion objects.
     * @throws CalloutException if the API call fails.
     */
    @AuraEnabled(cacheable=true)
    public static List<Object> getAddressSuggestions(String input) {
        try{
             // Get API configuration from custom metadata
            API_Key_Details__mdt apiDetails = API_Key_Details__mdt.getInstance('Autocomplete');
            String resourcePath = '/' + apiDetails.get('Resource__c');
            String apiKey = '?key=' + apiDetails.get('Key__c');

            // Construct endpoint
            String endpoint = NAMED_CREDENTIAL + resourcePath + apiKey + API_FORMAT + '&q=' + EncodingUtil.urlEncode(input, 'UTF-8');

            // Prepare and send HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');

            Http http = new Http();
            HttpResponse response = http.send(request);

            // Handle response
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> suggestions = (List<Object>) responseMap.get('completions');
                return suggestions;
            } 
            else {
                throw new CalloutException('Error from address finder autocomplete API under getAddressSuggestions method of AddressFinderServiceController class :  - \n\n Requested address input - \n\n' + input + '\n\nResponse status - \n\n' +  response.getStatus() + '\n\nResponse Body - \n\n' + response.getBody());
            }
        }
        catch (Exception ex){
            Logger.error(ex.getMessage(), ex).addTag('Address Finder');
            Logger.saveLog();
            throw ex;
        }   
    }

    /**
     * Fetches detailed address metadata for a given address PXID from the AddressFinder API.
     * 
     * @param input The PXID of the selected address.
     * @param version The version of the address (physical vs postal).
     * @return A wrapped response containing structured address metadata.
     * @throws CalloutException if the API call fails.
     */
    @AuraEnabled(cacheable=true)
    public static AddressResultsWrapper getAddressMetadata(String input, Integer version ) {
        try {
            // Get API configuration from custom metadata
            API_Key_Details__mdt apiDetails = API_Key_Details__mdt.getInstance('Metadata');
            String resourcePath = '/' + apiDetails.get('Resource__c');
            String apiKey = '?key=' + apiDetails.get('Key__c');

            // Construct endpoint
            String endpoint = NAMED_CREDENTIAL + resourcePath + apiKey + API_FORMAT + '&pxid=' + EncodingUtil.urlEncode(input, 'UTF-8');

            // Prepare and send HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');

            Http http = new Http();
            HttpResponse response = http.send(request);

            // Handle response
            if (response.getStatusCode() == 200) {
                Map<String, Object> metadata = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                AddressResultsWrapper result = new AddressResultsWrapper();
                result.Canonical_Address        = (String) metadata.get('a');
                result.Address_DPID             = (String) metadata.get('dpid');
                result.Address_PXID             = (String) metadata.get('pxid');
                result.Address_Geocode_x        = Double.valueOf(metadata.get('x'));
                result.Address_Geocode_y        = Double.valueOf(metadata.get('y'));
                result.Verified_Address         = true;
                result.Street_Address           = (String) metadata.get('address_line_1');
                result.Street_Address_Line_2    = deriveStreetLine2(metadata , version);
                result.Suburb                   = deriveSuburb(metadata , version);
                result.City                     = version == 0 ? (String) metadata.get('city') : version == 1 ? (String) metadata.get('mailtown') : null;
                result.Postcode                 = (String) metadata.get('postcode');
                result.RD_Number                = Integer.valueOf(metadata.get('rd_number'));
                result.Rural_Address            = metadata.get('rural') == null ? false : (Boolean) metadata.get('rural');
                result.Country                  = 'New Zealand';
                result.Address_Source           = 'Addressfinder';
                result.OneOffAddress            = true;
                result.IsManualEntry            = false;
                return result;
            } 
            else {
                throw new CalloutException('Error from address finder metadata API under getAddressMetadata method of AddressFinderServiceController class :  - \n\n Requested pxid input - \n\n' + input + '\n\nResponse status - \n\n' +  response.getStatus() + '\n\nResponse Body - \n\n' + response.getBody());
            }
        }
        catch(Exception ex){
            Logger.setParentLogTransactionId(input.left(36));
            Logger.error(ex.getMessage(), ex).addTag('Address Finder');
            Logger.saveLog();
            throw ex;
        }
    }

    /**
     * Provides a derived street address line 2 based on the version of the address selected (physical vs postal)
     * 
     * @param metadata The metadata of the selected address in address finder metadata call.
     * @param version The version of the address (physical vs postal).
     * @return Derived street address line 2.
     */
    private static String deriveStreetLine2(Map<String, Object> metadata, Integer version) {
        return version == 0 ? (String) metadata.get('address_line_2') : 
            version == 1 && (String) metadata.get('address_line_2') != null && String.isNotBlank((String) metadata.get('address_line_2')) && metadata.get('rd_number') == null && String.isBlank((String) metadata.get('rd_number')) ? (String) metadata.get('address_line_2') :
            version == 1 && (((String) metadata.get('address_line_2') == null || String.isBlank((String) metadata.get('address_line_2'))) && (metadata.get('rd_number') != null && String.isNotBlank((String) metadata.get('rd_number')))) ? 'RD ' + metadata.get('rd_number') : 
            version == 1 && (String) metadata.get('address_line_2') != null && String.isNotBlank((String) metadata.get('address_line_2')) && metadata.get('rd_number') != null && String.isNotBlank((String) metadata.get('rd_number')) ? (String) metadata.get('address_line_2') +', RD ' +  metadata.get('rd_number') : 
            null;
    }

    /**
     * Provides a derived suburb based on the versisadson of the address selected (physical vs postal)
     * 
     * @param metadata The metadata of the selected address in address finder metadata call.
     * @param version The version of the address (physical vs postal).
     * @return Derived suburb.
     */
    private static String deriveSuburb(Map<String, Object> metadata, Integer version) {
        return version == 0 && (String) metadata.get('suburb') != (String) metadata.get('city') ? (String) metadata.get('suburb') : 
            version == 1 ? (String) metadata.get('post_suburb') : 
            null ;
    }
}