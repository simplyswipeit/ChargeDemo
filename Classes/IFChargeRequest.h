// -*- objc -*-
//
// IFChargeRequest.h
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
#import "IFChargeMessage.h"

extern const int ReturnAppName_MAX_LENGTH;
extern const int ReturnURL_MAX_LENGTH;
extern const int RequestBaseURI_MAX_LENGTH;
extern const int Address_MAX_LENGTH;
extern const int City_MAX_LENGTH;
extern const int Company_MAX_LENGTH;
extern const int Country_MAX_LENGTH;
extern const int Description_MAX_LENGTH;
extern const int Email_MAX_LENGTH;
extern const int FirstName_MAX_LENGTH;
extern const int InvoiceNumber_MAX_LENGTH;
extern const int LastName_MAX_LENGTH;
extern const int Phone_MAX_LENGTH;
extern const int State_MAX_LENGTH;
extern const int Zip_MAX_LENGTH;

@interface IFChargeRequest : IFChargeMessage
{
@private
    NSObject* _delegate;

    NSString* _returnAppName;
    NSString* _returnURL;
    NSString* _requestBaseURI;
    

    NSString* _address;
    NSString* _city;
    NSString* _company;
    NSString* _country;
    NSString* _description;
    NSString* _email;
    NSString* _firstName;
    NSString* _invoiceNumber;
    NSString* _lastName;
    NSString* _phone;
    NSString* _state;
    NSString* _zip;
}

// delegate - Will receive the
// creditCardTerminalNotInstalled calback if the invocation fails.
@property (assign) NSObject* delegate;

// amount - The amount that was charged to the card. This is a string,
// which is a currency value to two decimal places like @"50.00". This
// property will only be set if responseCode is Accepted.
@property (readwrite,copy)   NSString*            amount;

// amount subfields - A breakdown of the amount that was charged to
// the card. These are strings of the same form as the amount property.
// They will only be set if they were set in the IFChargeRequest, the
// amount was not explicitly set, and responseCode is Accepted.
@property (readwrite,copy)   NSString*            subtotal;
@property (readwrite,copy)   NSString*            tip;
@property (readwrite,copy)   NSString*            tax;
@property (readwrite,copy)   NSString*            shipping;
@property (readwrite,copy)   NSString*            discount;

// currency - The ISO 4217 currency code for the transaction
// amount. For example, "USD" for US Dollars. This property will be
// set when amount is set.
@property (readwrite,copy)   NSString*            currency;

//
// Return Parameters - these properties are used to request that
// Credit Card Terminal return to the calling app when the trasaction
// is complete. The returnURL must be specified in order for the user
// to have the option of returning.
//

// returnAppName - Credit card terminal will inform the user that the
// charge request comes from the app named by this parameter. By
// default, the CFBundleDisplayName is used.
@property (copy) NSString* returnAppName;

// returnURL - Credit card terminal will invoke this URL
// when the transaction is complete. Should be a URL that is
// registered to be handled by this app.
@property (copy) NSString* returnURL;

// setReturnURL - this setter is a helper that will take the extra
// parameters passed in the dictionary and encode and include them in
// the returnURL. The parameters from this dictionary will be
// available as the extraParams property on IFChargeResponse when you
// handle the callback URL.
//
// NOTE - The extraParams dictionary must contain only NSString* keys
// and values.
- (void)setReturnURL:(NSString*)url withExtraParams:(NSDictionary*)extraParams;

// requestBaseURI - If not nil, credit card terminal will derive its
// requestURL by appending query params to this, otherwise
// IF_CHARGE_API_BASE_URI will be used.
//
// NOTE - URL should be a string, ending just before but not including the ?.
@property (copy) NSString* requestBaseURI;

//
// Charge Parameters - these properties are used to pre-populate the
// form fields of Credit Card Terminal
//

// address - The customer's billing address.
// Up to 60 characters (no symbols).
@property (copy) NSString* address;

// city - The city of the customer's billing address.
// Up to 40 characters (no symbols).
@property (copy) NSString* city;

// company - The company associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* company;

// country - The country code of the customer's billing address. (E.g. US for USA)
// Up to 60 characters (no symbols).
@property (copy) NSString* country;

// description - The transaction description.
// Up to 255 characters (no symbols).
@property (copy) NSString* description;

// email - The customer's email address.
// Up to 255 characters.
@property (copy) NSString* email;

// firstName - The first name associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* firstName;

// invoiceNumber - The merchant-assigned invoice number.
// Up to 20 characters (no symbols).
@property (copy) NSString* invoiceNumber;

// lastName - The last name associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* lastName;

// phone - The phone number associated with the customer's billing address.
// Up to 25 digits (no letters).
@property (copy) NSString* phone;

// state - The state of the customer's billing address.
// Up to 40 characters (no symbols) or a valid 2-char state code.
@property (copy) NSString* state;

// zip - The ZIP code of the customer's billing address.
// Up to 20 characters (no symbols).
@property (copy) NSString* zip;

// init - designated initializer
- init;

// initWithDelegate: - Specifies the optional delegate when creating
// the object.
- initWithDelegate:(NSObject*)delegate;

@end

@interface NSObject (IFChargeRequestDelegate)

// Implement this on your delegate object in order to perform a custom
// action instead of displaying the default UIAlert if Credit Card
// Terminal cannot be launched.
- (void)creditCardTerminalNotInstalled;

@end

#define IF_CHARGE_API_VERSION  @"1.0.0"
#define IF_CHARGE_API_BASE_URI @"com-innerfence-ccterminal://charge/" IF_CHARGE_API_VERSION @"/"

// These macros define the default message used for the UIAlert when
// Credit Card Terminal is not installed. Override these strings in
// your string table for other languages.
#define IF_CHARGE_NOT_INSTALLED_BUTTON  ( NSLocalizedString( @"OK", nil ) )
#define IF_CHARGE_NOT_INSTALLED_MESSAGE ( NSLocalizedString( \
    @"Install Credit Card Terminal to enable this functionality.", nil \
) )
#define IF_CHARGE_NOT_INSTALLED_TITLE   ( NSLocalizedString( @"Unable to Charge", nil ) )
