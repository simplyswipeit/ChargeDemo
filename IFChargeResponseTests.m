//
//  IFChargeResponseTests.m
//  ChargeDemo
//
//  Created by Ben Acland on 2/10/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//

#import "IFChargeResponseTests.h"


@implementation IFChargeResponseTests

- (void)testChargeRequestInit {
    // Roll up a dummy IFChargeRequest, use it to init a ChargeResponse
    testRequest_.amount = nil;
    testRequest_.subtotal = @"5.00";
    testRequest_.tip = @"1.00";
    testRequest_.tax = @"2.00";
    testRequest_.shipping = @"3.00";
    testRequest_.discount = @"0.50";
    testRequest_.currency = @""; // leave nil or empty to test default behavior
    [testRequest_ setReturnURL:@"com.yourapp.someco://somePath" withExtraParams:[NSDictionary dictionaryWithObjectsAndKeys:@"thingOne", @"keyOne", nil]];
    NSString *testReturnURL = [testRequest_ returnURL]; // set aside for future comparison
    testRequest_.requestBaseURI = @"com.theirapp.someco://chargeme";
    NSString *testCardType = @"__testCardType__";
    NSString *testCardNum = @"1234567890123456";
    IFChargeResponseCode testRespCode = kIFChargeResponseCodeApproved;
    IFChargeResponse *newResp = [[IFChargeResponse alloc] initWithChargeRequest:testRequest_
                                                                   responseCode:testRespCode
                                                                     cardNumber:testCardNum
                                                                       cardType:testCardType];

    // Test that the values were copied correctly. In the future, these might be folded into a more general shared property test.
    STAssertEqualObjects(testRequest_.amount, newResp.amount, 
                         @"Property amount copied incorrectly, from '%@' to '%@'",
                         testRequest_.amount, newResp.amount); // See IFChargeMessageTests for a better test of amount property logic.

    STAssertEqualObjects(testRequest_.subtotal, newResp.subtotal,
                         @"Property subtotal copied incorrectly, from '%@' to '%@'",
                         testRequest_.subtotal, newResp.subtotal);

    STAssertEqualObjects(testRequest_.tip, newResp.tip,
                         @"Property tip copied incorrectly, from '%@' to '%@'",
                         testRequest_.tip, newResp.tip);

    STAssertEqualObjects(testRequest_.tax, newResp.tax,
                         @"Property tax copied incorrectly, from '%@' to '%@'",
                         testRequest_.tax, newResp.tax);

    STAssertEqualObjects(testRequest_.shipping, newResp.shipping,
                         @"Property shipping copied incorrectly, from '%@' to '%@'",
                         testRequest_.shipping, newResp.shipping);

    STAssertEqualObjects(testRequest_.discount, newResp.discount,
                         @"Property discount copied incorrectly, from '%@' to '%@'",
                         testRequest_.discount, newResp.discount);

    STAssertEqualObjects(testRequest_.extraParams, newResp.extraParams,
                         @"Property extraParams copied incorrectly, from '%@' to '%@'",
                         testRequest_.extraParams, newResp.extraParams);

    STAssertEqualObjects(testReturnURL, newResp.baseURL,
                         @"Property baseURL copied incorrectly, from '%@' to '%@'",
                         testReturnURL, newResp.baseURL);

    // Test that the response and card types were set correctly // BONUS: basic card number verification test
    STAssertEquals(testRespCode, newResp.responseCode,    
                   @"Property responseType copied incorrectly, from '%d' to '%d'",
                   testRespCode, newResp.responseCode);

    STAssertEqualObjects(testCardType, newResp.cardType,
                         @"Property cardType copied incorrectly, from '%@' to '%@'",
                         testCardType, newResp.cardType);

    // Test for card masking (all but last four should be IF_CHARGE_CARD_NUMBER_MASK)
    STAssertEquals([testCardNum length], [newResp.redactedCardNumber length],
                   @"Redacted card number should be the same length as the original.\nOld: '%@'\nNew: '%@'",
                   testCardNum, newResp.redactedCardNumber);

    int maskCheckLimit = [testCardNum length] - 4;
    NSRange unmaskedRange = NSMakeRange(maskCheckLimit, 4);
    STAssertEquals([testCardNum compare:[newResp.redactedCardNumber substringWithRange:unmaskedRange] options:NSNumericSearch range:unmaskedRange], NSOrderedSame,
                 @"Last four of redacted card number should be the same as the original.\nOld: '%@'\nNew: '%@'",
                 testCardNum, newResp.redactedCardNumber);

    unichar maskUnichar = [IF_CHARGE_CARD_NUMBER_MASK characterAtIndex:0];
    for (int i=0; i < maskCheckLimit; i++) {
        STAssertEquals([newResp.redactedCardNumber characterAtIndex:i], maskUnichar,
                     @"Character at index %d of redacted card number should be %C but was %C",
                     i, [newResp.redactedCardNumber characterAtIndex:i], maskUnichar);
    }

    // NOTE: We test currency property defaults in IFChargeMessageTests
}

@end
