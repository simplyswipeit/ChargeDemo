//
//  IFChargeTestCase.h
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
#import "IFChargeRequest.h"
#import "IFChargeResponse.h"
#import "IFChargeMessage.h"

extern NSMutableString * randomStringFromCharacterSet(NSCharacterSet *characterSet, int stringLength);
extern NSString * randomInvalidURLString(int stringLength);

@interface IFChargeTestCase : SenTestCase {
    IFChargeRequest *testRequest_;
    IFChargeResponse *testResponse_;
}

@property (nonatomic, retain) IFChargeRequest *testRequest;
@property (nonatomic, retain) IFChargeResponse *testResponse;

// This method takes in an object, a setter selector, and a maximum length, and
// makesu sure that a) in-length, symbolless strings may be set, and b) that
// setting too-long, symbol-including strings raises an exception.
- (void)testNoSymbolsTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength;

// Similar, but for numbers-only fields
- (void)testNumbersOnlyTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength;

// Similar, but for email fields. Tests number range, and valid email format.
- (void)testEmailTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength;

- (void)testTextSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength forbiddingCharacterSets:firstSet, ... NS_REQUIRES_NIL_TERMINATION;

@end
