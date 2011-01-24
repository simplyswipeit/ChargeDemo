//
//  IFChargeMessage.m
//  ChargeDemo
//
//  Created by Ben Acland on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IFChargeMessage.h"

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
                    format:@"extraParams dictionary keys and values must all be strings"];
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

@end


@implementation IFChargeMessage
@synthesize amount             = _amount;
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
    if (self = [super init])
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

- (BOOL)amountIsSet {
    return (_amount) ? YES : NO;
}

- (NSString*)amount {
    // return the amount if set explicitly
    if (_amount) return _amount;
    
    // calculate the amount using the subfields
    float sum = 0.f;
    float subtotal__ = floatCheck([self.subtotal floatValue]);
    float tax__      = floatCheck([self.tax      floatValue]);
    float tip__      = floatCheck([self.tip      floatValue]);
    float shipping__ = floatCheck([self.shipping floatValue]);
    float discount__ = floatCheck([self.discount floatValue]);
    sum = subtotal__ + tax__ + tip__ + shipping__ - discount__;
    
    NSNumber *dollarNumber = [[NSNumber alloc] initWithFloat:sum];
    NSString *dollarString = [chargeAmountFormatter_ stringFromNumber:dollarNumber];
    [dollarNumber release];
    
    return dollarString;
}

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
