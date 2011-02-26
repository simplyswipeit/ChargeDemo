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

@end
