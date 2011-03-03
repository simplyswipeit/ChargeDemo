//
//  IFChargeMessageTests.m
//  ChargeDemo
//
//  Created by Ben Acland on 2/10/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//

#import "IFChargeMessageTests.h"


@implementation IFChargeMessageTests

- (void)testAmountFields {
    NSString *testSubtotal  = @"1.00";
    NSString *testTip       = @"0.20";
    NSString *testTax       = @"0.30";
    NSString *testShipping  = @"0.40";
    NSString *testDiscount  = @"1.00";
    NSString *testAmount    = @"2.24";

    // Test that the amount subfields affect the amount as expected
    testRequest_.subtotal = testSubtotal;
    STAssertEqualObjects(testSubtotal, testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", testSubtotal, testRequest_.amount);

    testRequest_.tip = testTip;
    STAssertEqualObjects(@"1.20", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.20", testRequest_.amount);

    testRequest_.tax = testTax;
    STAssertEqualObjects(@"1.50", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.50", testRequest_.amount);

    testRequest_.shipping = testShipping;
    STAssertEqualObjects(@"1.90", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.90", testRequest_.amount);

    testRequest_.discount = testDiscount;
    STAssertEqualObjects(@"0.90", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"0.90", testRequest_.amount);

    // Test that setting the amount overrides the subfields
    testRequest_.amount = testAmount;
    STAssertEqualObjects(testAmount, testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", testAmount, testRequest_.amount);
    STAssertTrue(testRequest_.amountIsSet, @"amountIsSet should be %d at this point, but instead it was %d", YES, testRequest_.amountIsSet);

    // Test un-setting values some nil and empty strings and 0 value floats.
    testRequest_.amount = nil;
    STAssertEqualObjects(@"0.90", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"0.90", testRequest_.amount);
    STAssertFalse(testRequest_.amountIsSet, @"amountIsSet should be %d at this point, but instead it was %d", NO, testRequest_.amountIsSet);

    testRequest_.discount = @"";
    STAssertEqualObjects(@"1.90", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.90", testRequest_.amount);

    testRequest_.shipping = @".0";
    STAssertEqualObjects(@"1.50", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.50", testRequest_.amount);
    
    testRequest_.tax = @"0.0";
    STAssertEqualObjects(@"1.20", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"1.20", testRequest_.amount);

    testRequest_.tip = @"0";
    STAssertEqualObjects(testSubtotal, testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", testSubtotal, testRequest_.amount);

    testRequest_.subtotal = @"00,000.00000"; // jic.
    STAssertEqualObjects(@"0.00", testRequest_.amount, @"Amount should equal '%@' at this point, but it was '%@.'", @"0.00", testRequest_.amount);

    // Test that changing the subfields to a combination adding up to more than 15 digits + decimal raises NSInvalidArgumentException
    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setAmount:) onObject:testRequest_ withMaxFigures:15];

    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setSubtotal:) onObject:testRequest_ withMaxFigures:15];

    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setTip:) onObject:testRequest_ withMaxFigures:15];

    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setTax:) onObject:testRequest_ withMaxFigures:15];

    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setShipping:) onObject:testRequest_ withMaxFigures:15];

    [self resetTestObjects];
    [self testFloatStringSetter:@selector(setDiscount:) onObject:testRequest_ withMaxFigures:15];
}

// Test that the currency defaults to IF_CHARGE_DEFAULT_CURRENCY
- (void)testCurrencyDefault {
    STAssertEqualObjects(IF_CHARGE_DEFAULT_CURRENCY, self.testResponse.currency,
                         @"Property currency should default to '%@,' but instead it was '%@'",
                         IF_CHARGE_DEFAULT_CURRENCY, testResponse_.currency);
}


// BONUS: Test that the currency property enforces ISO 4217

@end
