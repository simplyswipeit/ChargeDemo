//
//  IFChargeMessage.m
//  ChargeDemo
//
//  Created by Ben Acland on 1/23/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//

#import "IFChargeMessage.h"
NSString *const IFInvalidArgumentLengthException = @"IFInvalidArgumentLengthException";
NSString *const IFDisallowedCharacterException = @"IFDisallowedCharacterException";

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

#ifdef IF_INTERNAL

#import "GTMRegex.h"   // for [NSString -gtm_matchesPattern:]
#import "IFURLUtils.h"

__inline__ BOOL IFMatchesPattern( NSString* s, NSString* p )
{
    return [s gtm_matchesPattern:p];
}

#else

#import <regex.h>

BOOL IFMatchesPattern( NSString* nsString, NSString* nsPattern )
{
    const char* string  = [nsString  cStringUsingEncoding:NSUTF8StringEncoding];
    const char* pattern = [nsPattern cStringUsingEncoding:NSUTF8StringEncoding];

    BOOL matches = NO;
    BOOL compiled = NO;
    int re_error;
    regex_t re;

    re_error = regcomp(
        &re,
        pattern,
        REG_EXTENDED
        | REG_NOSUB    // match only, no captures
    );
    if ( re_error )
    {
        NSLog( @"regcomp error %d", re_error );
        goto Cleanup;
    }
    compiled = YES;

    re_error = regexec(
        &re,
        string,
        0, NULL, // no captures
        0        // no flags
    );
    if ( re_error )
    {
        if ( REG_NOMATCH == re_error )
        {
            NSLog( @"string '%s' does not match pattern '%s'", string, pattern );
        }
        else
        {
            NSLog( @"regexec error %d", re_error );
        }
        goto Cleanup;
    }

    // No error, regex matched, input is valid
    matches = YES;

Cleanup:
    if ( compiled )
    {
        regfree( &re );
    }

    return matches;
}

static NSMutableDictionary* IFParseQueryParameters( NSURL* url )
{
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
    NSString*     queryString = [url query];

    if ( [queryString length] )
    {
        NSArray* queryPairs = [queryString componentsSeparatedByString:@"&"];

        for ( NSString* queryPair in queryPairs )
        {
            NSArray* queryComps = [queryPair componentsSeparatedByString:@"="];
            if ( 2 != [queryComps count] )
            {
                // Only interested in field=value pairs
                continue;
            }

            NSString* decodedField = [[queryComps objectAtIndex:0]
                stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* decodedValue = [[queryComps objectAtIndex:1]
                stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            [dict setObject:decodedValue forKey:decodedField];
        }
    }

    return dict;
}

static float floatCheck(float theFloat) {
    // make sure the float value doesn't indicate an overflow.
    if (theFloat == HUGE_VAL || theFloat == -HUGE_VAL)
        [NSException raise:NSInvalidArgumentException
                    format:@"String could not be converted to a float value."];
    return theFloat;
}


// CFURLCreateStringByAddingPercentEscapes by default leaves legal
// URL characters alone, which is not what we want. So we'll specify
// that all the reserved chars *should* be encoded. This is the same
// as the 'reserved' BNF production from RFC 3986.
#define URI_RESERVED_CHARS @":/?#[]@!$&'()*+,;="

NSString* IFEncodeURIComponent( NSString* s )
{
    CFStringRef encodedValue =
    CFURLCreateStringByAddingPercentEscapes(
                                            kCFAllocatorDefault,
                                            (CFStringRef)s,
                                            NULL,
                                            (CFStringRef)URI_RESERVED_CHARS,
                                            kCFStringEncodingUTF8
                                            );
    
    return [NSMakeCollectable( encodedValue ) autorelease];
}


#endif

@interface IFChargeMessage ()
@property (readwrite,copy) NSString* amount;
@property (readwrite,copy) NSString* subtotal;
@property (readwrite,copy) NSString* tip;
@property (readwrite,copy) NSString* tax;
@property (readwrite,copy) NSString* shipping;
@property (readwrite,copy) NSString* discount;
@property (readwrite,copy) NSString* currency;
@property (readwrite,retain) NSDictionary* extraParams;
@property (readwrite,retain) NSString* nonce;
@property (readwrite,retain) NSString* baseURL;

- (void)checkFloatStringSize:(NSString*)floatString;
@end


@implementation IFChargeMessage
@synthesize subtotal           = _subtotal;
@synthesize tip                = _tip;
@synthesize tax                = _tax;
@synthesize shipping           = _shipping;
@synthesize discount           = _discount;
@synthesize currency           = _currency;
@synthesize nonce              = _nonce;
@synthesize baseURL            = _baseURL;
@synthesize extraParams        = _extraParams;
@synthesize amountIsSet;

static NSNumberFormatter *chargeAmountFormatter_;
+ (void)initialize
{
    chargeAmountFormatter_ = [[NSNumberFormatter alloc] init];
    [chargeAmountFormatter_ setNumberStyle:NSNumberFormatterCurrencyStyle];
    [chargeAmountFormatter_ setGeneratesDecimalNumbers:YES];
    [chargeAmountFormatter_ setCurrencySymbol:@""];
    [chargeAmountFormatter_ setPerMillSymbol:@""];
}

- (id)initWithURL:(NSURL*)url {
    if ((self = [super init]))
    {
        if ( nil == url )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"URL must not be nil"];
        }

        NSMutableDictionary* queryFields = IFParseQueryParameters( url );

        for ( NSString* field in [[self class] knownFields] )
        {
            NSString* queryName = [IF_CHARGE_MESSAGE_FIELD_PREFIX
                                      stringByAppendingString:field];
            NSString* value = [queryFields valueForKey:queryName];
            if ( [value length] )
            {
                [self setValue:value forKey:field];

                [queryFields removeObjectForKey:queryName];
            }
        }

        // extract the nonce here, since you've already unpacked queryFields
        self.nonce = [queryFields objectForKey:IF_CHARGE_NONCE_KEY];

        self.extraParams = queryFields;
    }
    return self;
}

#if TARGET_OS_IPHONE

// Submit the charge message.
- (void)submit
{
    // Submit the URL
    NSURL* url = [self requestURL];
    
    UIApplication* app = [UIApplication sharedApplication];
    
    // On newer OSes, we can query and know for sure if Credit Card
    // Terminal is installed.
    BOOL assuredSuccess = NO;
    if ( [app respondsToSelector:@selector(canOpenURL:)] )
    {
        assuredSuccess = [app canOpenURL:url];
        if ( !assuredSuccess )
        {
            // Assured failure -- early out.
            [self retain]; // ... balances out autorelease in unableToOpenURL;
            [self unableToOpenURL];
            return;
        }
    }
    
    [[UIApplication sharedApplication] openURL:url];
    
    if ( !assuredSuccess )
    {
        // On older OSes, if the openURL succeeds, this app will
        // terminate. We register here to receive a callback in 1
        // second, which will only happen if we don't terminate,
        // meaning the openURL failed.
        [self retain];
        [self performSelector:@selector(unableToOpenURL)
                   withObject:nil
                   afterDelay:1];
    }
}

#endif

- (void)unableToOpenURL {
    // Override and call super in subclasses to handle url opening failure.
    [self autorelease];
}

// Create the appropriate request URL based on the current property
// values.
- (NSURL*)requestURL
{
    if (!_baseURL) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Could not generate request URL: base URL not defined"];
    }
    NSMutableString* urlString = [[NSMutableString alloc] initWithString:_baseURL];
    BOOL first = ([urlString rangeOfString:@"?"].location == NSNotFound);
    
    // First build up the query params
    for ( NSString* field in [[self class] knownFields] )
    {
        if ([field isEqualToString:@"amount"] && !_amount) continue; // don't send amount if it's not set explicitly.

        NSString* value = [self valueForKey:field];
        if ( [value length] )
        {
            [urlString appendFormat:@"%@%@%@=%@",
             first ? @"?" : @"&",
             IF_CHARGE_MESSAGE_FIELD_PREFIX,
             field,
             IFEncodeURIComponent( value )];
            first = NO;
        }
    }
    
    // Convert to NSURL
    NSURL* url = [NSURL URLWithString:urlString];
    [urlString release];
    return url;
}

+ (NSArray*)knownFields {
    // Implement in subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma -
#pragma Amount Fields

double const AMOUNT_FIELD_MAX = 9999999999999.99;
double const AMOUNT_FIELD_MIN = -9999999999999.99;

- (void)checkFloatStringSize:(NSString*)floatString {
    double testVal = [floatString doubleValue];
    
    // make sure the number could be initted
    floatCheck(testVal);
    
    // make sure the nubmer isn't too high or too low
    if (testVal > AMOUNT_FIELD_MAX) {
        [NSException raise:NSInvalidArgumentException format:@"You cannot set amount fields to values higher than %f", AMOUNT_FIELD_MAX];
    } else if (testVal < AMOUNT_FIELD_MIN) {
        [NSException raise:NSInvalidArgumentException format:@"You cannot set amount fields to values lower than %f", AMOUNT_FIELD_MIN];
    }
}

- (BOOL)amountIsSet {
    return (_amount) ? YES : NO;
}

- (void)setAmount:(NSString *)amount {
    [self checkFloatStringSize:amount];
    @synchronized(self) // (readonly,copy)
    {
        if (_amount != amount) {
            [_amount release];
            _amount = [amount copy];
        }
    }
}

- (NSString*)amount {
    NSString *dollarString;

    @synchronized(self) {
        // return the amount if set explicitly
        if (_amount) {
            dollarString = [_amount retain];
        } else {
            // calculate the amount using the subfields
            float sum = 0.f;
            float subtotal__ = floatCheck([self.subtotal floatValue]);
            float tax__      = floatCheck([self.tax      floatValue]);
            float tip__      = floatCheck([self.tip      floatValue]);
            float shipping__ = floatCheck([self.shipping floatValue]);
            float discount__ = floatCheck([self.discount floatValue]);
            sum = subtotal__ + tax__ + tip__ + shipping__ - discount__;
            
            NSNumber *dollarNumber = [[NSNumber alloc] initWithFloat:sum];
            dollarString = [[chargeAmountFormatter_ stringFromNumber:dollarNumber] retain];
            [dollarNumber release];
        }
    }

    return [dollarString autorelease];
}

- (void)setSubtotal:(NSString *)subtotal {
    [self checkFloatStringSize:subtotal];
    setObject_AtomicCopy(_subtotal, subtotal);
}
- (NSString*)subtotal {
    getObject_Atomic(_subtotal);
}

- (void)setTip:(NSString *)tip {
    [self checkFloatStringSize:tip];
    setObject_AtomicCopy(_tip, tip);
}
- (NSString*)tip {
    getObject_Atomic(_tip);
}

- (void)setTax:(NSString *)tax {
    [self checkFloatStringSize:tax];
    setObject_AtomicCopy(_tax, tax);
}
- (NSString*)tax {
    getObject_Atomic(_tax);
}

- (void)setShipping:(NSString *)shipping {
    [self checkFloatStringSize:shipping];
    setObject_AtomicCopy(_shipping, shipping);
}
- (NSString*)shipping {
    getObject_Atomic(_shipping);
}

- (void)setDiscount:(NSString *)discount {
    [self checkFloatStringSize:discount];
    setObject_AtomicCopy(_discount, discount);
}
- (NSString*)discount {
    getObject_Atomic(_discount);
}


- (void)setCurrency:(NSString *)currency {
    [self checkFloatStringSize:currency];
    setObject_AtomicCopy(_currency, currency);
}

- (NSString*)currency {
    id result;
    @synchronized(self) {
        result = (_currency && [_currency length] > 0) ? [_currency retain] : IF_CHARGE_DEFAULT_CURRENCY;
    }
    return [result autorelease];
}

- (void)validateTextArgument:(NSString*)arg withMaxLength:(int)maxLength forbiddenCharacterSets:firstSet, ... {
    // Passing 0 as maxLength prevents length limit testing.
    // Passing nil as firstSet prevents forbidden character testing
    if (maxLength != 0 && [arg length] > maxLength) {
        [NSException raise:IFInvalidArgumentLengthException
                    format:@"Argument '%@' is %d characters too long", arg, [arg length] - maxLength];
    }

    if (firstSet != nil) {
        // merge the character sets
        NSMutableCharacterSet *disallowedCharacterSet = [[firstSet mutableCopy] autorelease];
        va_list argumentList;
        id nextSet;

        va_start(argumentList, firstSet);
        while ((nextSet = va_arg(argumentList, id)))
            [disallowedCharacterSet formUnionWithCharacterSet:nextSet];
        va_end(argumentList);

        // list all of the illegal characters
        NSMutableArray *illegals = [[NSMutableArray alloc] init];
        int argLength = [arg length];
        NSRange searchRange = NSMakeRange(0, argLength);
        NSRange resultRange = [arg rangeOfCharacterFromSet:disallowedCharacterSet options:0 range:searchRange];
        while (resultRange.location != NSNotFound) {
            NSString *illegalSubstring = [arg substringWithRange:resultRange];
            if ([illegals indexOfObject:illegalSubstring] == NSNotFound)
                [illegals addObject:[arg substringWithRange:resultRange]];
            int newLoc = resultRange.location + resultRange.length;
            searchRange = NSMakeRange(newLoc, argLength - newLoc);
            resultRange = [arg rangeOfCharacterFromSet:disallowedCharacterSet options:0 range:searchRange];
        }

        // raise exception if necessary
        if ([illegals count] > 0) {
            [NSException raise:IFDisallowedCharacterException
                        format:@"The text argument contained the following disallowed characters: @%", [illegals autorelease]];
        }

        [illegals release];
    }
}

- (void)validateURLString:(NSString*)testString {
    // Takes a string, sees if it can be turned into an nsurl.
    if (![NSURL URLWithString:testString]) {
        [NSException raise:NSInvalidArgumentException format:@"Could not build url out of string: '%@'", testString];
    }
}

- (void)validateEmailString:(NSString*)testString {
     NSPredicate *emailTestPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]; // x@xxx.xx
    if (![emailTestPredicate evaluateWithObject:testString]) {
        [NSException raise:NSInvalidArgumentException format:@"'%@' doesn't look like an email"];
    }
}

#pragma -
#pragma Memory Management

- (void) dealloc {
    self.amount = nil;
    self.subtotal = nil;
    self.tip = nil;
    self.tax = nil;
    self.shipping = nil;
    self.discount = nil;
    self.currency = nil;
    self.nonce = nil;
    self.baseURL = nil;
    self.extraParams = nil;
    [super dealloc];
}


@end
