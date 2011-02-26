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

#define IF_CHARGE_CARD_NUMBER_MASK @"X"

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
@property (readwrite,retain) NSString* baseURL;
@property (readwrite,copy)   NSString*     redactedCardNumber;
@property (readwrite,copy)   NSString*     responseType;
@property (readwrite,assign) IFChargeResponseCode responseCode;

- (void) validateFields;
+(NSNumberFormatter*)chargeAmountFormatter;

@end

@implementation IFChargeResponse
@dynamic amount;
@dynamic subtotal;
@dynamic tip;
@dynamic tax;
@dynamic shipping;
@dynamic discount;
@dynamic currency;
@dynamic nonce;
@dynamic baseURL;
@dynamic extraParams;
@synthesize cardType           = _cardType;
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

- (id)initWithURL:(NSURL*)url
{
    if ( ( self = [super initWithURL:url] ) )
    {
        NSString* expectedNonce = [[NSUserDefaults standardUserDefaults]
                                      objectForKey:IF_CHARGE_NONCE_KEY];
        if ( 0 == [expectedNonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: No outstanding charge responses"];
        }

        if ( 0 == [_nonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                        format:@"Bad URL Request: Nonce missing."];
        }

        if ( ![expectedNonce isEqualToString:self.nonce] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: Incorrect nonce received"];
        }

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:IF_CHARGE_NONCE_KEY];

        [self validateFields];
    }

    return self;
}

// Display a dialog
- (void)unableToOpenURL {
    [super unableToOpenURL]; // releases pre-delay retains.
    [[[[UIAlertView alloc]
       initWithTitle:IF_RESPONSE_CAN_NOT_OPEN_URL_TITLE
       message:IF_RESPONSE_CAN_NOT_OPEN_URL_MESSAGE
       delegate:nil
       cancelButtonTitle:IF_RESPONSE_CAN_NOT_OPEN_URL_BUTTON
       otherButtonTitles:nil
       ] autorelease] show];
}

- (id)initWithChargeRequest:(IFChargeRequest*)request responseCode:(IFChargeResponseCode)responseCode cardNumber:(NSString*)cardNumber cardType:(NSString*)cardType
{
    if (self = [super init]) {
        // TODO: assert that there be a request and response code
        
        if (responseCode == kIFChargeResponseCodeApproved)
        {
            // set the vars
            self.subtotal = request.subtotal;
            self.tip = request.tip;
            self.tax = request.tax;
            self.shipping = request.shipping;
            self.discount = request.discount;
            self.baseURL = request.returnURL;

            // assert that there be a card number
            if (!cardNumber)
            {
                [NSException raise:NSInvalidArgumentException
                             format:@"Could not init with request: did not receive a card number."];
            }

            // redact the card number
            NSMutableString *cNumber = [[NSMutableString alloc] initWithString:cardNumber];
            int ccNumberLength = [cNumber length];
            for (int index = 0; index < ccNumberLength - 4; index++) {
                [cNumber replaceCharactersInRange:( NSRange ){ index, 1 } withString:IF_CHARGE_CARD_NUMBER_MASK];
            }
            self.redactedCardNumber = cNumber;
            [cNumber release];
            
            if (cardType) self.cardType = cardType;
        }
        self.responseCode = responseCode;
        switch (responseCode) {
            case kIFChargeResponseCodeApproved:
                self.responseType = @"approved";
                break;
            case kIFChargeResponseCodeDeclined:
                self.responseType = @"declined";
                break;
            case kIFChargeResponseCodeCancelled:
                self.responseType = @"cancelled";
                break;
            case kIFChargeResponseCodeError:
            default:
                self.responseType = @"error";
                break;
        }
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
    [_cardType release];
    [_redactedCardNumber release];
    [_responseType release];

    [super dealloc];
}

@end
