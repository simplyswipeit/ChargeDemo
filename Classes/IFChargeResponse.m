//
// IFChargeRequest.m
// Inner Fence Credit Card Terminal for iPhone
// API 1.0.0
//
// You may license this source code under the MIT License, reproduced
// below.
//
// Copyright (c) 2009 Inner Fence, LLC
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
#import "IFChargeResponse.h"

#import "IFChargeRequest.h"

#ifdef IF_INTERNAL

#import "GTMRegex.h"   // for [NSString -gtm_matchesPattern:]
#import "IFURLUtils.h"

static __inline__ BOOL IFMatchesPattern( NSString* s, NSString* p )
{
    return [s gtm_matchesPattern:p];
}

#else

#import <regex.h>

static BOOL IFMatchesPattern( NSString* nsString, NSString* nsPattern )
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

#endif

#define IF_CHARGE_RESPONSE_FIELD_PATTERNS                     \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"amount",             \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"subtotal",             \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"tip",             \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"tax",             \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"shipping",             \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"discount",             \
    @"^[A-Z]{3}$",                     @"currency",           \
    @"^X*[0-9]{4}$",                   @"redactedCardNumber", \
    @"^[A-Za-z ]{0,20}$",              @"cardType",           \
    @"^[a-z]*$",                       @"responseType",       \
    nil

#define IF_NSINT( n )  ( [NSNumber numberWithInteger:(n)] )

#define IF_CHARGE_RESPONSE_CODE_MAPPING \
    IF_NSINT( kIFChargeResponseCodeApproved ),  @"approved",  \
    IF_NSINT( kIFChargeResponseCodeCancelled ), @"cancelled", \
    IF_NSINT( kIFChargeResponseCodeDeclined ),  @"declined",  \
    IF_NSINT( kIFChargeResponseCodeError ),     @"error",     \
    nil

static NSArray*      _fieldList;
static NSDictionary* _fieldPatterns;
static NSDictionary* _responseCodes;

@interface IFChargeResponse ()

@property (readwrite,copy)   NSString*     amount;
@property (readwrite,copy)   NSString*     subtotal;
@property (readwrite,copy)   NSString*     tip;
@property (readwrite,copy)   NSString*     tax;
@property (readwrite,copy)   NSString*     shipping;
@property (readwrite,copy)   NSString*     discount;
@property (readwrite,copy)   NSString*     cardType;
@property (readwrite,copy)   NSString*     currency;
@property (readwrite,retain) NSDictionary* extraParams;
@property (readwrite,copy)   NSString*     redactedCardNumber;
@property (readwrite,copy)   NSString*     responseType;

- (void) validateFields;
+(NSNumberFormatter*)chargeAmountFormatter;

@end

@implementation IFChargeResponse

@synthesize amount             = _amount;
@synthesize subtotal           = _subtotal;
@synthesize tip                = _tip;
@synthesize tax                = _tax;
@synthesize shipping           = _shipping;
@synthesize discount           = _discount;
@synthesize cardType           = _cardType;
@synthesize currency           = _currency;
@synthesize extraParams        = _extraParams;
@synthesize redactedCardNumber = _redactedCardNumber;
@synthesize responseCode       = _responseCode;
@synthesize responseType       = _responseType;

+ (void)initialize
{
    _fieldPatterns = [[NSDictionary alloc]
                         initWithObjectsAndKeys:IF_CHARGE_RESPONSE_FIELD_PATTERNS];
    _fieldList     = [[[_fieldPatterns allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
    _responseCodes = [[NSDictionary alloc]
                         initWithObjectsAndKeys:IF_CHARGE_RESPONSE_CODE_MAPPING];
}

+ (NSArray*)knownFields
{
    return _fieldList;
}

+ (NSDictionary*)responseCodeMapping
{
    return _responseCodes;
}

- initWithURL:(NSURL*)url
{
    if ( ( self = [super init] ) )
    {
        if ( nil == url )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"URL must not be nil"];
        }

        NSMutableDictionary* queryFields = IFParseQueryParameters( url );

        for ( NSString* field in _fieldList )
        {
            NSString* queryName = [IF_CHARGE_RESPONSE_FIELD_PREFIX
                                      stringByAppendingString:field];
            NSString* value = [queryFields valueForKey:queryName];
            if ( [value length] )
            {
                [self setValue:value forKey:field];

                [queryFields removeObjectForKey:field];
            }
        }

        NSString* expectedNonce = [[NSUserDefaults standardUserDefaults]
                                      objectForKey:IF_CHARGE_NONCE_KEY];
        if ( 0 == [expectedNonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: No outstanding charge responses"];
        }

        NSString* nonce = [queryFields objectForKey:IF_CHARGE_NONCE_KEY];
        if ( 0 == [nonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: Nonce missing from response"];
        }

        if ( ![expectedNonce isEqualToString:nonce] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: Incorrect nonce received"];
        }

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:IF_CHARGE_NONCE_KEY];

        self.extraParams = queryFields;
        [self validateFields];
    }

    return self;
}

- (BOOL)amountSubfieldsAreSet {
    // returns true if any one amount subfield is set
    return (0 != [_subtotal length] ||
            0 != [_tax length] ||
            0 != [_tip length] ||
            0 != [_shipping length] ||
            0 != [_discount length]);
}

- (NSString*)currency
{
    if ( 0 == [_currency length] && (0 != [_amount length] || [self amountSubfieldsAreSet]) )
    {
        return @"USD";
    }
    else
    {
        return _currency;
    }
}

static float floatCheck(float theFloat) {
    // make sure the float value doesn't indicate an overflow.
    if (theFloat == HUGE_VAL || theFloat == -HUGE_VAL)
        [NSException raise:NSInvalidArgumentException
                    format:@"extraParams dictionary keys and values must all be strings"];
    return theFloat;
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
    NSString *dollarString = [[IFChargeResponse chargeAmountFormatter] stringFromNumber:dollarNumber];
    [dollarNumber release];
    
    return dollarString;
}

static NSNumberFormatter *chargeAmountFormatter_;
+(NSNumberFormatter*)chargeAmountFormatter {
    if (!chargeAmountFormatter_) {
        chargeAmountFormatter_ = [[NSNumberFormatter alloc] init];
        [chargeAmountFormatter_ setNumberStyle:NSNumberFormatterCurrencyStyle];
        [chargeAmountFormatter_ setGeneratesDecimalNumbers:YES];
        [chargeAmountFormatter_ setCurrencySymbol:@""];
        [chargeAmountFormatter_ setPerMillSymbol:@""];
    }
    return chargeAmountFormatter_;
}

- (void)validateFields
{
    for ( NSString* field in _fieldList )
    {
        NSString* pattern = [_fieldPatterns objectForKey:field];
        NSAssert1( nil != pattern, @"No regex for field %@", field );

        NSString* value = [self valueForKey:field];

        if ( nil != value && !IFMatchesPattern( value, pattern ) )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: field '%@' is not valid",
                         field];
        }
    }

    NSNumber* responseCode = [_responseCodes valueForKey:_responseType];
    if ( nil == responseCode )
    {
        [NSException raise:NSInvalidArgumentException
                     format:@"Bad URL Request: Unknown response type"];
    }
    _responseCode = [responseCode intValue];

    if ( kIFChargeResponseCodeApproved == _responseCode )
    {
        if ( nil == _amount && ![self amountSubfieldsAreSet] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: missing amount"];
        }
        if ( nil == _redactedCardNumber )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: missing redactedCardNumber"];
        }
    }
    else
    {
        if ( nil != _amount || [self amountSubfieldsAreSet] || nil != _cardType || nil != _currency || nil != _redactedCardNumber )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: failure should not contain transaction info"];
        }
    }
}

- (void)dealloc
{
    [_baseURL release];
    [_amount release];
    [_subtotal release];
    [_tip release];
    [_tax release];
    [_shipping release];
    [_discount release];
    [_cardType release];
    [_currency release];
    [_extraParams release];
    [_redactedCardNumber release];
    [_responseType release];

    [super dealloc];
}

@end
