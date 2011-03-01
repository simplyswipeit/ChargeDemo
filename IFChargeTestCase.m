//
//  IFChargeTestCase.m
//  ChargeDemo
//
//  Created by Ben Acland on 2/10/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//

#import "IFChargeTestCase.h"

@implementation IFChargeTestCase
@synthesize testRequest=testRequest_;
@synthesize testResponse=testResponse_;

#pragma -
#pragma Setup

- (void)setUp {
    IFChargeRequest *newRequest = [[IFChargeRequest alloc] init];
    newRequest.description = @"Test Request";
    self.testRequest = newRequest;
    [newRequest release];

    IFChargeResponse *newResponse = [[IFChargeResponse alloc] init];
    self.testResponse = newResponse;
    [newResponse release];
}

- (void)tearDown {
    self.testRequest = nil;
    self.testResponse = nil;
}

#pragma -
#pragma Character Sets and String Generators

static NSMutableDictionary *characterListCache_;
NSMutableDictionary * characterListCache() {
    if (!characterListCache_) {
        characterListCache_ = [[NSMutableDictionary alloc] init];
    }
    return characterListCache_;
}

NSArray * charactersInSet(NSCharacterSet *characterSet) {
    if (!characterSet) [NSException raise:NSInvalidArgumentException format:@"You must pass in a non-nil character set"];

    // Check the character list set for an entry whose key is a mutual superset of the passed set.
    NSMutableDictionary *cListCache = characterListCache();
    __block NSArray *characterList = nil;
    [cListCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSCharacterSet *keySet = (NSCharacterSet*)key;
        if ([keySet isSupersetOfSet:characterSet] && [characterSet isSupersetOfSet:keySet]) {
            characterList = (NSArray*)obj;
            *stop = YES;
        }
    }];
    if (characterList) return characterList;

    // If we didn't find a cached string, we'll have to build one - this time.
    NSMutableArray *workingList = [[NSMutableArray alloc] init];
    for (unichar testChar = 0; testChar < 256; testChar++) {
        if ([characterSet characterIsMember:(testChar)]) [workingList addObject:[NSString stringWithCharacters:&testChar length:1]];
    }

    // Make a cache entry and return the string
    [cListCache setObject:workingList forKey:characterSet];
    return [workingList autorelease];
}

NSMutableString * randomStringFromCharacterSet(NSCharacterSet *characterSet, int stringLength) {
    if (!characterSet) [NSException raise:NSInvalidArgumentException format:@"You must pass in a non-nil character set"];

    // Passing a nil set or length < 1 will return an empty string.
    NSMutableString *workingString = [[[NSMutableString alloc] init] autorelease];
    if (!characterSet || stringLength < 1) return workingString;

    // Add random characters from the character set to the string until it's long enough.
    NSArray *characterList = charactersInSet(characterSet);
    if ([characterList count] == 0) [NSException raise:NSInvalidArgumentException format:@"You must pass in a character set containing at least one character"];
    while ([workingString length] < stringLength) {
        [workingString appendString:(NSString*)[characterList objectAtIndex:(arc4random() % [characterList count])]];
    }

    return workingString;
}

// This regular expression, from http://cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html
// is adapted from a version at http://www.regular-expressions.info/email.html, and
// is a complete verification of RFC 2822. I have modified it to allow capital letters.
NSString *const emailRegEx =
@"(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"
@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-"
@"z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5"
@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
@"9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

NSMutableString * randomEmailAddress(BOOL shouldBeValid, int stringLength) {
    if (stringLength < 8) [NSException raise:NSInvalidArgumentException format:@"Minimum random email address stringLength for this method is 8"];
    NSPredicate *emailTestPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]; // x@xxx.xx

    NSString *candidate = nil;
    NSMutableCharacterSet *lcSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    while (!candidate || [emailTestPredicate evaluateWithObject:candidate] != shouldBeValid) { // repeat until we have a candidate that passes or fails as desired
        NSString *name;
        if (shouldBeValid) {
            name = randomStringFromCharacterSet(lcSet, stringLength - 7);
        } else {
            name = randomStringFromCharacterSet([NSCharacterSet symbolCharacterSet], stringLength - 7);
        }
        candidate = [NSString stringWithFormat:@"%@@%@.%@", 
                     name,
                     randomStringFromCharacterSet(lcSet, 3),
                     randomStringFromCharacterSet(lcSet, 2)];
    }

    return [NSMutableString stringWithString:candidate];
}

NSString * randomInvalidURLString(int stringLength) {
    NSString *candidate = @"";
    NSURL *testURL;
    while ((testURL = [NSURL URLWithString:candidate])) { // Will retun non-nil as long as the string conforms to Must conform to RFC 2396.
        candidate = randomStringFromCharacterSet([NSCharacterSet alphanumericCharacterSet], 47);
    }
    return candidate;
}

#pragma -
#pragma Reusable Test Components

- (void)testNoSymbolsTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength {
    [self testTextSetter:setter getter:getter onObject:obj withMaxLength:maxLength forbiddingCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
}

- (void)testNumbersOnlyTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength {
    [self testTextSetter:setter getter:getter onObject:obj withMaxLength:maxLength forbiddingCharacterSets:[NSCharacterSet decimalDigitCharacterSet], nil];
}

- (void)testEmailTextFieldSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength {
    // Test that the object responds to both selectors
    STAssertTrue([obj respondsToSelector:setter], @"Object %@ does not respond to email-address-setting selector %@", obj, NSStringFromSelector(setter));
    STAssertTrue([obj respondsToSelector:getter], @"Object %@ does not respond to email-address-getting selector %@", obj, NSStringFromSelector(getter));

    NSString *testAddress;

    // Test that a valid email address of maximum length may be set
    testAddress = randomEmailAddress(YES, maxLength);
    STAssertNoThrow([obj performSelector:setter withObject:testAddress], @"%@ - '%@' rejected the supposedly acceptable max-length string '%@'", 
                    obj, NSStringFromSelector(setter), testAddress);
    NSString *gotString = (NSString*)[obj performSelector:getter];
    STAssertEqualObjects(testAddress, gotString, @"String changed after setting with %@ and getting with %@, from '%@' to '%@'",
                         NSStringFromSelector(setter), NSStringFromSelector(getter), testAddress, gotString);

    // Test that a valid email address of maximum length +1 may NOT be set,
    // and raises IFInvalidArgumentLengthException
    testAddress = randomEmailAddress(YES, maxLength + 1);
    STAssertThrows([obj performSelector:setter withObject:testAddress], @"Object '%@' should raise %@ when %@ is passed an argument of length greater than %d",
                   obj, IFInvalidArgumentLengthException, NSStringFromSelector(setter), maxLength);
    

    // TODO: Test that an improperly formatted address (per RFC 2822) of valid length
    // may NOT be set, and raises NSInvalidArgumentException
    testAddress = randomEmailAddress(NO, maxLength);
    STAssertThrows([obj performSelector:setter withObject:testAddress], @"Object '%@' should raise %@ when %@ is passed an address not conforming to RFC 2822",
                   obj, NSInvalidArgumentException, NSStringFromSelector(setter), maxLength);
    
}

- (void)testTextSetter:(SEL)setter getter:(SEL)getter onObject:(id)obj withMaxLength:(NSUInteger)maxLength forbiddingCharacterSets:firstSet, ... {
    // Passing 0 as maxLength prevents length limit testing.
    // Passing nil as firstSet prevents forbidden character testing
    BOOL testCharacters = (firstSet != nil);
    BOOL testLength = (maxLength != 0);
    NSUInteger lengthLimit = testLength ? 256 : maxLength;

    // Test that the object responds to both selectors
    STAssertTrue([obj respondsToSelector:setter], @"Object %@ does not respond to text-setting selector %@", obj, NSStringFromSelector(setter));
    STAssertTrue([obj respondsToSelector:getter], @"Object %@ does not respond to text-getting selector %@", obj, NSStringFromSelector(getter));

    // Combine all of the forbidden character sets into one big one.
    NSCharacterSet *disallowedCharacterSet;
    NSCharacterSet *allowedCharacterSet;
    va_list argumentList;
    id nextSet;

    if (testCharacters) {
        NSMutableCharacterSet *cumulativeCharacterSet = [firstSet mutableCopy]; // will be released at end of method
        va_start(argumentList, firstSet);
        while ((nextSet = va_arg(argumentList, id)))
            [cumulativeCharacterSet formUnionWithCharacterSet:nextSet];
        va_end(argumentList);
        disallowedCharacterSet = cumulativeCharacterSet;
        allowedCharacterSet = [disallowedCharacterSet invertedSet];
    } else {
        // If you don't provide any character sets, we default to allowing the
        // alphanumeric set, and faux disallowing everything else. We don't actually
        // run the forbidden character tests.
        allowedCharacterSet = [NSCharacterSet alphanumericCharacterSet];
        disallowedCharacterSet = [[allowedCharacterSet invertedSet] retain]; // retained to balance out end-of-method release
    }

    NSMutableString *testString;

    /*
     * A note about the following:
     * It would be nicer to use STAssertThrowsSpecificNamed below, but it seems
     * to be broken right now - it won't print the error discription. This makes
     * for faster fixing.
     */

    // Test that an allowable string of maximum length can be set
    testString = randomStringFromCharacterSet(allowedCharacterSet, lengthLimit);
    STAssertNoThrow([obj performSelector:setter withObject:testString], @"%@ - '%@' rejected the supposedly acceptable max-length string '%@'", 
                    obj, NSStringFromSelector(setter), testString);
    NSString *gotString = (NSString*)[obj performSelector:getter];
    STAssertEqualObjects(testString, gotString, @"String changed after setting with %@ and getting with %@, from '%@' to '%@'",
                         NSStringFromSelector(setter), NSStringFromSelector(getter), testString, gotString);
    
    // Test that an allowable string of maximum length +1 can NOT be set, and raises IFInvalidArgumentLengthException
    if (testLength) {
        testString = randomStringFromCharacterSet(allowedCharacterSet, lengthLimit+1);
        STAssertThrows([obj performSelector:setter withObject:testString], @"Object '%@' should raise %@ when %@ is passed an argument of length greater than %d",
                       obj, IFInvalidArgumentLengthException, NSStringFromSelector(setter), lengthLimit);
    }
    
    // Test that every allowable character may be set (ie does not raise an exception)
    if (testCharacters) {
        NSMutableArray *unExceptedCharacters = [charactersInSet(allowedCharacterSet) mutableCopy];
        __block NSMutableIndexSet *exceptedIndexes = [[NSMutableIndexSet alloc] init];
        [unExceptedCharacters enumerateObjectsUsingBlock:^(id character, NSUInteger idx, BOOL *stop) {
            @try {
                [obj performSelector:setter withObject:character];
            }
            @catch (NSException *exception) {
                [exceptedIndexes addIndex:idx];
            }
        }];
        [unExceptedCharacters removeObjectsAtIndexes:exceptedIndexes];
        STAssertTrue([exceptedIndexes count] == 0, @"'%@' should'n raise an exception for the following characters: '%@'", obj, unExceptedCharacters);
        [unExceptedCharacters release]; unExceptedCharacters = nil;
        [exceptedIndexes removeAllIndexes];
        
        // Test that every disallowed character may NOT be set, and raises IFDisallowedCharacterException
        unExceptedCharacters = [charactersInSet(disallowedCharacterSet) mutableCopy];
        [unExceptedCharacters enumerateObjectsUsingBlock:^(id character, NSUInteger idx, BOOL *stop) {
            @try {
                [obj performSelector:setter withObject:character];
            }
            @catch (NSException *exception) {
                [exceptedIndexes addIndex:idx];
            }
        }];
        [unExceptedCharacters removeObjectsAtIndexes:exceptedIndexes];
        STAssertTrue([unExceptedCharacters count] == 0, @"'%@' should raise %@ for the following characters: '%@'", obj, IFDisallowedCharacterException, unExceptedCharacters);

        [exceptedIndexes release];
        [unExceptedCharacters release];
    }

    [disallowedCharacterSet release];
}

@end
