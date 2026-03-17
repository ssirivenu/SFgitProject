/*
*********************************************************
Apex Class Name    : AddressFinderServiceControllerTest
Test Class         : 
Created Date       : September 24, 2025
@description       : This a test class for the AddressFinderServiceController class.
@author            : Surojit Dutta (Merkle)
*********************************************************
*/

@isTest
private class AddressFinderServiceControllerTest {

     @testSetup static void setup() {
        // Create Test users
        Map<String, TestUserFactory.UserSettings> userMap = new Map<String, TestUserFactory.UserSettings>();
        userMap.put('TMAddressFinder', new TestUserFactory.UserSettings('LIC Standard User', 'Territory Manager - Lower North'));
        Map<String, User> createdUsers = TestUserFactory.createUsersWithProfile(userMap);     
    }

    // Mock implementation for both autocomplete and metadata callouts
    private class AddressFinderMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('autocomplete')) {
                // Mock response for getAddressSuggestions
                res.setBody('{"completions": [{"a": "123 Main Street", "pxid": "PX123"}]}');
            } else if (req.getEndpoint().contains('metadata')) {
                // Mock response for getAddressMetadata
                res.setBody(
                    '{' +
                        '"a": "123 Main Street",' +
                        '"postal": "123 Main Street, Suburb, City, 1234",' +
                        '"dpid": "DPID123",' +
                        '"pxid": "PX123",' +
                        '"x": 174.7633,' +
                        '"y": -36.8485,' +
                        '"address_line_1": "123 Main Street",' +
                        '"address_line_2": "Suburb",' +
                        '"postal_line_3": "City",' +
                        '"suburb": "Suburb",' +
                        '"post_suburb": "PostSuburb",' +
                        '"city": "City",' +
                        '"mailtown": "MailTown",' +
                        '"postcode": "1234",' +
                        '"rd_number": "1",' +
                        '"rural": false' +
                    '}'
                );
            } 
            return res;
        }
    }

    //ERROR mock implementation for for both autocomplete and metadata callouts(non-200 response )
    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(500);
            r.setBody('{"error":"Something went wrong"}');
            return r;
        }
    }

    // Test Autocomplete API positive scenario.
    @isTest
    static void testGetAddressSuggestions() {
        Test.setMock(HttpCalloutMock.class, new AddressFinderMock());

        User u = [Select Id from User where FirstName = 'TestTerritoryManagerAddressFinder' AND LastName = 'Territory Manager - Lower North' LIMIT 1];
        Test.startTest();
        System.runAs(u)
        {
            List<Object> suggestions = AddressFinderServiceController.getAddressSuggestions('123 Main');
        

            System.assert(suggestions != null, 'Suggestions should not be null');
            System.assertEquals(1, suggestions.size(), 'There should be one suggestion returned');

            Map<String, Object> suggestion = (Map<String, Object>) suggestions[0];
            System.assertEquals('123 Main Street', suggestion.get('a'), 'Address should match expected value');
            System.assertEquals('PX123', suggestion.get('pxid'), 'PXID should match expected value');
        }
        Test.stopTest();
   
    }

    // Test Metadata  API positive scenario.
    @isTest
    static void testGetAddressMetadata() {
        Test.setMock(HttpCalloutMock.class, new AddressFinderMock());

        User u = [Select Id from User where FirstName = 'TestTerritoryManagerAddressFinder' AND LastName = 'Territory Manager - Lower North' LIMIT 1];
        Test.startTest();
        System.runAs(u)
        {
            AddressResultsWrapper resultPhysical = AddressFinderServiceController.getAddressMetadata('PX123' , 0);
            System.assert(resultPhysical != null, 'Metadata API result should not be null for physical address.');
            System.assertEquals('123 Main Street', resultPhysical.Canonical_Address);
            System.assertEquals('DPID123', resultPhysical.Address_DPID);
            System.assertEquals('PX123', resultPhysical.Address_PXID);
            System.assertEquals(174.7633, resultPhysical.Address_Geocode_x);
            System.assertEquals(-36.8485, resultPhysical.Address_Geocode_y);
            System.assertEquals(true, resultPhysical.Verified_Address);
            System.assertEquals('123 Main Street', resultPhysical.Street_Address);
            System.assertEquals('Suburb', resultPhysical.Street_Address_Line_2);
            System.assertEquals('Suburb', resultPhysical.Suburb);
            System.assertEquals('City', resultPhysical.City);
            System.assertEquals('1234', resultPhysical.Postcode);
            System.assertEquals(1, resultPhysical.RD_Number);
            System.assertEquals(false, resultPhysical.Rural_Address);
            System.assertEquals('New Zealand', resultPhysical.Country);

            AddressResultsWrapper resultPostal = AddressFinderServiceController.getAddressMetadata('PX123' , 1);
            System.assert(resultPostal != null, 'Metadata API result should not be null for postal address.');
            System.assertEquals('123 Main Street', resultPostal.Canonical_Address);
            System.assertEquals('DPID123', resultPostal.Address_DPID);
            System.assertEquals('PX123', resultPostal.Address_PXID);
            System.assertEquals(174.7633, resultPostal.Address_Geocode_x);
            System.assertEquals(-36.8485, resultPostal.Address_Geocode_y);
            System.assertEquals(true, resultPostal.Verified_Address);
            System.assertEquals('123 Main Street', resultPostal.Street_Address);
            System.assertEquals('Suburb, RD 1', resultPostal.Street_Address_Line_2);
            System.assertEquals('PostSuburb', resultPostal.Suburb);
            System.assertEquals('MailTown', resultPostal.City);
            System.assertEquals('1234', resultPostal.Postcode);
            System.assertEquals(1, resultPostal.RD_Number);
            System.assertEquals(false, resultPostal.Rural_Address);
            System.assertEquals('New Zealand', resultPostal.Country);
        }
        Test.stopTest();
    }

    // Test Autocomplete API negative scenario.
    @isTest
    static void testGetAddressSuggestionsError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        User u = [SELECT Id FROM User WHERE FirstName='TestTerritoryManagerAddressFinder' LIMIT 1];

        Test.startTest();
        System.runAs(u) {
            try {
                AddressFinderServiceController.getAddressSuggestions('bad input');
                System.assert(false, 'Exception is not thrown for address finder autocomplete API.');
            } 
            catch (Exception ex) {
                System.assert(ex.getMessage().contains('Error from address finder autocomplete API'), 'Error message did not match the expected failure from address finder autocomplete API.');
            }
        }
        Test.stopTest();
    }

    // Test Metadata API negative scenario.
    @isTest
    static void testGetAddressMetadataError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        User u = [SELECT Id FROM User WHERE FirstName='TestTerritoryManagerAddressFinder' LIMIT 1];

        Test.startTest();
        System.runAs(u) {
            try {
                AddressFinderServiceController.getAddressMetadata('PX_BAD', 0);
                System.assert(false, 'Exception is not thrown for address finder metadata API.');
            } 
            catch (Exception ex) {
                System.assert(ex.getMessage().contains('Error from address finder metadata API'),'Error message did not match the expected failure from address finder metadata API.');
            }
        }
        Test.stopTest();
    }
}