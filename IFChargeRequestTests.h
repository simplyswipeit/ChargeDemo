//
//  IFChargeRequestTests.h
//  ChargeDemo
//
//  Created by Ben Acland on 2/10/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Application unit tests contain unit test code that must be injected into an application to run correctly.
//  Define USE_APPLICATION_UNIT_TEST to 0 if the unit test code is designed to be linked into an independent test executable.

#define USE_APPLICATION_UNIT_TEST 1

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "IFChargeTestCase.h"


@interface IFChargeRequestTests : IFChargeTestCase {
    
}

- (void)testAddress;
- (void)testCity;
- (void)testCompany;
- (void)testCountry;
- (void)testDescription;
- (void)testEmail;
- (void)testFirstName;
- (void)testInvoiceNumber;
- (void)testLastName;
- (void)testPhone;
- (void)testState;
- (void)testZip;


@end
