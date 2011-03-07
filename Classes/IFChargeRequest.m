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
#import "IFChargeRequest.h"

#include <stdlib.h>

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define IF_CHARGE_REQUEST_FIELD_LIST \
    @"returnAppName", \
    @"returnURL", \
    @"address", \
    @"amount", \
    @"subtotal", \
    @"tip", \
    @"tax", \
    @"shipping", \
    @"discount", \
    @"city", \
    @"company", \
    @"country", \
    @"currency", \
    @"description", \
    @"email", \
    @"firstName", \
    @"invoiceNumber", \
    @"lastName", \
    @"phone", \
    @"state", \
    @"zip", \
    nil


static NSArray* _fieldList;

const int ReturnAppName_MAX_LENGTH  = 0; // 0 -> no max.
const int ReturnURL_MAX_LENGTH      = 0; // 0 -> no max.
const int RequestBaseURI_MAX_LENGTH = 0; // 0 -> no max.
const int Address_MAX_LENGTH        = 60;
const int City_MAX_LENGTH           = 40;
const int Company_MAX_LENGTH        = 50;
const int Country_MAX_LENGTH        = 60;
const int Description_MAX_LENGTH    = 255;
const int Email_MAX_LENGTH          = 255;
const int FirstName_MAX_LENGTH      = 50;
const int InvoiceNumber_MAX_LENGTH  = 20;
const int LastName_MAX_LENGTH       = 50;
const int Phone_MAX_LENGTH          = 25;
const int State_MAX_LENGTH          = 40;
const int Zip_MAX_LENGTH            = 20;

// Base64 isn't provided in Cocoa Touch, and I don't want to depend on
// an external Base64 library, so instead of base64 encoding a random
// value, I'll instead choose (web safe) base64-characters at random.
static const NSUInteger kNonceLength = 27; // same size as base64-encoded SHA1 seems good
static const long kNonceAlphabetMask = 0x3f;
static char _nonceAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

@interface IFChargeRequest ()

- (NSString*)createAndStoreNonce;

@property (readwrite,retain) NSDictionary* extraParams;
@property (readwrite,retain) NSString* nonce;
@property (readwrite,retain) NSString* baseURL;
@end

@implementation IFChargeRequest
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
@synthesize delegate       = _delegate;
@synthesize returnAppName  = _returnAppName;
@synthesize returnURL      = _returnURL;
@synthesize requestBaseURI = _requestBaseURI;
@synthesize address        = _address;
@synthesize city           = _city;
@synthesize company        = _company;
@synthesize country        = _country;
@synthesize description    = _description;
@synthesize email          = _email;
@synthesize firstName      = _firstName;
@synthesize invoiceNumber  = _invoiceNumber;
@synthesize lastName       = _lastName;
@synthesize phone          = _phone;
@synthesize state          = _state;
@synthesize zip            = _zip;

+ (void)initialize
{
    _fieldList = [[NSArray alloc] initWithObjects:IF_CHARGE_REQUEST_FIELD_LIST];
}

+ (NSArray*)knownFields
{
    return _fieldList;
}

// Designated constructor
- init
{
    if ( ( self = [super init] ) )
    {
        self.returnAppName = [[NSBundle mainBundle]
            objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    }
    return self;
}

- initWithDelegate:(NSObject*)delegate
{
    if ( ( self = [self init] ) )
    {
        self.delegate = delegate;
    }
    return self;
}

- (NSString*)createAndStoreNonce
{
    NSMutableString* nonceString = [[[NSMutableString alloc] initWithCapacity:kNonceLength] autorelease];
    for ( NSUInteger i = 0; i < kNonceLength; i++ )
    {
        [nonceString appendFormat:@"%c", _nonceAlphabet[ ( arc4random() & kNonceAlphabetMask ) ]];
    }

    [[NSUserDefaults standardUserDefaults] setObject:nonceString forKey:IF_CHARGE_NONCE_KEY];

    return nonceString;
}

// If there's a delegate, invoke -creditCardTerminalNotInstalled on it;
// otherwise, display a default dialog.
- (void)creditCardTerminalNotInstalled
{
    if ( _delegate )
    {
        [_delegate creditCardTerminalNotInstalled];
    }
#if TARGET_OS_IPHONE
    else
    {
        [[[[UIAlertView alloc]
            initWithTitle:IF_CHARGE_NOT_INSTALLED_TITLE
            message:IF_CHARGE_NOT_INSTALLED_MESSAGE
            delegate:nil
            cancelButtonTitle:IF_CHARGE_NOT_INSTALLED_BUTTON
            otherButtonTitles:nil
        ] autorelease] show];
    }
#endif
}

// Create the appropriate request URL based on the current property
// values. 
- (NSURL*)requestURL
{
    self.baseURL = (_requestBaseURI) ? _requestBaseURI : IF_CHARGE_API_BASE_URI;
    return [super requestURL];
}

- (void)setReturnURL:(NSString*)url withExtraParams:(NSDictionary*)extraParams
{
    BOOL hasQuery = 0 != [[[NSURL URLWithString:url] query] length];

    NSMutableString* urlString = [[NSMutableString alloc] initWithString:url];
    BOOL first = YES;

    // TODO - actually, to prevent tampering, etc, we should probably
    // just shove this dictionary into NSUserDefaults instead of
    // including it on the URL.

    for ( NSObject* keyObject in [extraParams allKeys] )
    {
        NSObject* valueObject = [extraParams objectForKey:keyObject];

        if ( ![keyObject isKindOfClass:[NSString class]] ||
             ![valueObject isKindOfClass:[NSString class]] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"extraParams dictionary keys and values must all be strings"];
        }

        NSString* field = (NSString*)keyObject;
        NSString* value = (NSString*)valueObject;
        if ( [value length] )
        {
            [urlString appendFormat:@"%@%@=%@",
                       ( first && !hasQuery ) ? @"?" : @"&",
                       field,
                       IFEncodeURIComponent( value )];
            first = NO;
        }
    }

    self.returnURL = urlString;
    [urlString release];
}

#if TARGET_OS_IPHONE

// Submit the charge request. The current application will terminate
// and Credit Card Terminal will launch with the specified fields
// pre-filled.
- (void)submit
{
    // Create a nonce
    if ( [_returnURL length] )
    {
        self.returnURL = [_returnURL stringByAppendingFormat:@"%@%@=%@",
            [[[NSURL URLWithString:_returnURL] query] length] ? @"&" : @"?",
            IF_CHARGE_NONCE_KEY,
            IFEncodeURIComponent( [self createAndStoreNonce] )
        ];
    }

    [super submit];
}

#endif

- (void)unableToOpenURL {
    [self creditCardTerminalNotInstalled];
    [super unableToOpenURL]; // releases self.
}

#pragma -
#pragma Atomic Getters/Setters

- (void)setReturnAppName:(NSString *)returnAppName {
    [self validateTextArgument:returnAppName withMaxLength:ReturnAppName_MAX_LENGTH forbiddenCharacterSets: nil];
    setObject_AtomicCopy(_returnAppName, returnAppName);
}
- (NSString*)returnAppName {
    getObject_Atomic(_returnAppName);
}

- (void)setReturnURL:(NSString *)returnURL {
    [self validateURLString:returnURL];
    setObject_AtomicCopy(_returnURL, returnURL);
}
- (NSString*)returnURL {
    getObject_Atomic(_returnURL);
}

- (void)setRequestBaseURI:(NSString *)requestBaseURI {
    [self validateURLString:requestBaseURI];
    if ([requestBaseURI rangeOfString:@"?"].location != NSNotFound) {
        [NSException raise:NSInvalidArgumentException
                    format:@"requestBaseURI may not include the character '?'"];
    }
    setObject_AtomicCopy(_requestBaseURI, requestBaseURI);
}
- (NSString*)requestBaseURI {
    getObject_Atomic(_requestBaseURI);
}

- (void)setAddress:(NSString *)address {
    [self validateTextArgument:address withMaxLength:Address_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_address, address);
}
- (NSString*)address {
    getObject_Atomic(_address);
}

- (void)setCity:(NSString *)city {
    [self validateTextArgument:city withMaxLength:City_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_city, city);
}
- (NSString*)city {
    getObject_Atomic(_city);
}

- (void)setCompany:(NSString *)company {
    [self validateTextArgument:company withMaxLength:Company_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_company, company);
}
- (NSString*)company {
    getObject_Atomic(_company);
}

- (void)setCountry:(NSString *)country {
    [self validateTextArgument:country withMaxLength:Country_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_country, country);
}
- (NSString*)country {
    getObject_Atomic(_country);
}

- (void)setDescription:(NSString *)description {
    [self validateTextArgument:description withMaxLength:Description_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_description, description);
}
- (NSString*)description {
    getObject_Atomic(_description);
}

- (void)setEmail:(NSString *)email {
    [self validateTextArgument:email withMaxLength:Email_MAX_LENGTH forbiddenCharacterSets:nil];
    [self validateEmailString:email];
    setObject_AtomicCopy(_email, email);
}
- (NSString*)email {
    getObject_Atomic(_email);
}

- (void)setFirstName:(NSString *)firstName {
    [self validateTextArgument:firstName withMaxLength:FirstName_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_firstName, firstName);
}
- (NSString*)firstName {
    getObject_Atomic(_firstName);
}

- (void)setInvoiceNumber:(NSString *)invoiceNumber {
    [self validateTextArgument:invoiceNumber withMaxLength:InvoiceNumber_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_invoiceNumber, invoiceNumber);
}
- (NSString*)invoiceNumber {
    getObject_Atomic(_invoiceNumber);
}

- (void)setLastName:(NSString *)lastName {
    [self validateTextArgument:lastName withMaxLength:LastName_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_lastName, lastName);
}
- (NSString*)lastName {
    getObject_Atomic(_lastName);
}

- (void)setPhone:(NSString *)phone {
    [self validateTextArgument:phone withMaxLength:Phone_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet decimalDigitCharacterSet], nil];
    setObject_AtomicCopy(_phone, phone);
}
- (NSString*)phone {
    getObject_Atomic(_phone);
}

- (void)setState:(NSString *)state {
    [self validateTextArgument:state withMaxLength:State_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_state, state);
}
- (NSString*)state {
    getObject_Atomic(_state);
}

- (void)setZip:(NSString *)zip {
    [self validateTextArgument:zip withMaxLength:Zip_MAX_LENGTH forbiddenCharacterSets:[NSCharacterSet symbolCharacterSet], nil];
    setObject_AtomicCopy(_zip, zip);
}
- (NSString*)zip {
    getObject_Atomic(_zip);
}


#pragma -
#pragma Memory Management

- (void)dealloc
{
    _delegate = nil;

    [_returnAppName release];
    [_returnURL release];
    [_requestBaseURI release];

    [_address release];
    [_city release];
    [_company release];
    [_country release];
    [_description release];
    [_email release];
    [_firstName release];
    [_invoiceNumber release];
    [_lastName release];
    [_phone release];
    [_state release];
    [_zip release];

    [super dealloc];
}

@end
