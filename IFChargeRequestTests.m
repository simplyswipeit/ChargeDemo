//
//  IFChargeRequestTests.m
//  ChargeDemo
//
//  Created by Ben Acland on 2/10/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//

#import "IFChargeRequestTests.h"


@implementation IFChargeRequestTests

#pragma -
#pragma Acceptable Field Values

- (void)testAddress {
    [self testNoSymbolsTextFieldSetter:@selector(setAddress:) getter:@selector(address) onObject:testRequest_ withMaxLength:60];
}

- (void)testCity {
    [self testNoSymbolsTextFieldSetter:@selector(setCity:) getter:@selector(city) onObject:testRequest_ withMaxLength:40];
}

- (void)testCompany {
    [self testNoSymbolsTextFieldSetter:@selector(setCompany:) getter:@selector(company) onObject:testRequest_ withMaxLength:50];
}

- (void)testCountry {
    [self testNoSymbolsTextFieldSetter:@selector(setCountry:) getter:@selector(country) onObject:testRequest_ withMaxLength:60];
}

- (void)testDescription {
    [self testNoSymbolsTextFieldSetter:@selector(setDescription:) getter:@selector(description) onObject:testRequest_ withMaxLength:255];
}

- (void)testEmail {
    [self testEmailTextFieldSetter:@selector(setEmail:) getter:@selector(email) onObject:testRequest_ withMaxLength:255];
}

- (void)testFirstName {
    [self testNoSymbolsTextFieldSetter:@selector(setFirstName:) getter:@selector(firstName) onObject:testRequest_ withMaxLength:50];
}

- (void)testInvoiceNumber {
    [self testNoSymbolsTextFieldSetter:@selector(setInvoiceNumber:) getter:@selector(invoiceNumber) onObject:testRequest_ withMaxLength:20];
}

- (void)testLastName {
    [self testNoSymbolsTextFieldSetter:@selector(setLastName:) getter:@selector(lastName) onObject:testRequest_ withMaxLength:50];
}

- (void)testPhone {
    [self testNumbersOnlyTextFieldSetter:@selector(setPhone:) getter:@selector(phone) onObject:testRequest_ withMaxLength:25];
}

- (void)testState {
    [self testNoSymbolsTextFieldSetter:@selector(setState:) getter:@selector(state) onObject:testRequest_ withMaxLength:40];
}

- (void)testZip {
    [self testNoSymbolsTextFieldSetter:@selector(setZip:) getter:@selector(zip) onObject:testRequest_ withMaxLength:20];
}

#pragma -
#pragma More Complex Tests

- (void)testReturnAppName {
    // Test that setting returnAppName to some string actually works
    [self testTextSetter:@selector(setReturnAppName:) getter:@selector(returnAppName) onObject:testRequest_ withMaxLength:0 forbiddingCharacterSets:nil];
}

- (void)testReturnURL {
    NSString *validURLString = @"com-innerfence-ChargeDemo://chargeResponse/somePath";
    NSDictionary *validExtras = [NSDictionary dictionaryWithObjectsAndKeys:@"one", @"a", @"two", @"b", @"three", @"c", nil];
    NSDictionary *invalidExtras1 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"a", @"two", @"b", @"three", @"c", nil];
    NSDictionary *invalidExtras2 = [NSDictionary dictionaryWithObjectsAndKeys:@"one", [@"a" dataUsingEncoding:NSUTF8StringEncoding], @"two", @"b", @"three", @"c", nil];

    // Test that you can set extra param keys and retrieve them from the resulting URL
    STAssertNoThrow([testRequest_ setReturnURL:validURLString withExtraParams:validExtras], @"Setting returnURL with extraParams %@ should not raise an exception", validExtras);
    NSArray *retrievedURLStringComponents = [[testRequest_ returnURL] componentsSeparatedByString:@"?"];
    NSString *retrievedBase = [retrievedURLStringComponents objectAtIndex:0];
    NSString *retrievedParams = [retrievedURLStringComponents objectAtIndex:1];
    NSMutableDictionary *retrievedExtras = [[NSMutableDictionary alloc] init];
    [[retrievedParams componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *components = [(NSString*)obj componentsSeparatedByString:@"="];
        [retrievedExtras setObject:[components objectAtIndex:1] forKey:[components objectAtIndex:0]];
    }];
    STAssertTrue([retrievedExtras isEqualToDictionary:validExtras], @"Retrieved extras '%@' should match set extras '%@'", retrievedExtras, validExtras);
    [retrievedExtras release];

    // Test that the everything up to the query of the resulting URL matches the URL you passed in
    STAssertEquals(retrievedBase, validURLString, @"Retrieved URL '%@' should match set url '%@'", retrievedBase, validURLString);

    // Test that you can NOT set extra params using a dictionary including a non-string key or value - should raise NSInvalidArgumentException
    STAssertThrows([testRequest_ setReturnURL:validURLString withExtraParams:invalidExtras1], @"Setting returnURL with extraParams %@ should raise %@", invalidExtras1, NSInvalidArgumentException);
    STAssertThrows([testRequest_ setReturnURL:validURLString withExtraParams:invalidExtras2], @"Setting returnURL with extraParams %@ should raise %@", invalidExtras2, NSInvalidArgumentException);

    // Test that passing in a string that can't be turned into a URL raises NSInvalidArgumentException
    NSString *testString = randomInvalidURLString(47);
    STAssertThrows([testRequest_ setReturnURL:testString withExtraParams:validExtras], 
                   @"Setting returnURL to '%@', or anything that can't be turned into a URL should raise %@", testString, NSInvalidArgumentException);
}

- (void)testRequestBaseURI {
    NSString *validBase = @"swipeit://com.macally.swipeit/";

    // Test that you may set a base URI using a well-formed base
    STAssertNoThrow([testRequest_ setRequestBaseURI:validBase], @"You should be able to set the requestBaseURI to a valid base like %@", validBase);

    // Test that passing in a string that can't be turned into a URL raises NSInvalidArgumentException
    NSString *testString = randomInvalidURLString(47);
    STAssertThrows([testRequest_ setRequestBaseURI:testString], 
                   @"Setting requestBaseURI to '%@', or anything that can't be turned into a URL should raise %@", testString, NSInvalidArgumentException);

    // Test that passing in a string that includes '?' raises NSInvalidArgumentException
    testString = [NSString stringWithFormat:@"%@?a=b", validBase];
    STAssertThrows([testRequest_ setRequestBaseURI:testString], @"Setting the requestBaseURI to anything that includes the character ? should raise %@", NSInvalidArgumentException);
}


- (void)testInitWithDelegate {
    // Test that the delegate gets set
    IFChargeRequest *newRequest = [[IFChargeRequest alloc] initWithDelegate:self];
    STAssertEqualObjects(newRequest.delegate, self, @"Initting an IFChargeRequest with delegate self should set the delegate to self. Instead, it was %@", newRequest.delegate);
}

// TODO: Test url rolling, unrolling
    // TODO: set values, make a URL, init another object from the url - check values

// TODO: Check the attributes of the public properties

@end
