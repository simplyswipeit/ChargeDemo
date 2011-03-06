//
//  IFChargeMessage.h
//  ChargeDemo
//
//  Created by Ben Acland on 1/23/11.
//  Copyright 2011 ProxyObjects. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern BOOL IFMatchesPattern( NSString* s, NSString* p );
extern NSString* IFEncodeURIComponent( NSString* s );

// Indicates that an argument was longer or shorter than allowed
extern NSString *const IFInvalidArgumentLengthException;

// Indicates that an argument contained a disallowed character
extern NSString *const IFDisallowedCharacterException;

#define IF_CHARGE_MESSAGE_FIELD_PREFIX @"ifcc_"
#define IF_CHARGE_NONCE_KEY @"ifcc_request_nonce"
#define IF_CHARGE_DEFAULT_CURRENCY @"USD"

@interface IFChargeMessage : NSObject {
    NSString* _amount;
    NSString* _subtotal;
    NSString* _tip;
    NSString* _tax;
    NSString* _shipping;
    NSString* _discount;
    NSString* _currency;

    NSDictionary* _extraParams;
    NSString* _nonce;

    NSString* _baseURL;
}

// amount - The amount of the transaction.
// Up to 15 digits with a decimal point. Can be set directly, or by
// setting the amount subfields below. If set directly, all subfield
// values will be ignored, otherwise the getter method will calculate
// the amount using the subfields.
@property (readonly,copy) NSString* amount;

// amountIsSet - Indicates that the amount property has been set
// explicitly, and is overriding the use of any of the amount subfields
// (ie subtotal, tip, etc.).
@property (readonly,assign) BOOL amountIsSet;

// amount subfields - A breakdown of the amount of the transaction.
// These are strings of the same form as the amount property.
@property (readonly,copy) NSString* subtotal;
@property (readonly,copy) NSString* tip;
@property (readonly,copy) NSString* tax;
@property (readonly,copy) NSString* shipping;
@property (readonly,copy) NSString* discount;

// currency - The currency code of the amount. (E.g. USD for US Dollars)
// 3 characters. Defaults to USD.
@property (readonly,copy) NSString* currency;

// extraParams - This dictionary contains any unrecognized query
// parameters that were part of the URL. This should be the same as
// the dictionary passed to setReturnURL:WithExtraPrams: when
// creating the IFChargeRequest. If there are no extra parameters,
// this property will be an empty dictionary.
//
// WARNING - The URL is an attack vector to your iPhone app, just like
// if it were a web app; you must be wary of SQL injection and similar
// malicious data attacks. As such, you will need to validate any
// parameters from the extraParams fields that you will be using. For
// example, if you expect a numeric value, you should ensure the field
// is comprised of digits.
@property (readonly,retain) NSDictionary* extraParams;

@property (readonly,retain) NSString* nonce;

// baseURL - Used internally to set the beginning of requestURL.
// In IFChargeRequest, this value defaults to IF_CHARGE_API_BASE_URI, but can be
// customized externally by setting requestBaseURI. When you init an
// IFChargeResponse using an IFChargeRequest, if the Request has a returnURL set
// then this value will be copied into the Response's baseURL.
@property (readonly,retain) NSString* baseURL;

// initWithURL - Pass the URL that you receive in
// application:handleOpenURL: and the resulting object will have the
// properties set. Any fields that aren't part of the usual message
// will be exposed in the extraParams dictionary for your convenience.
//
// Throws an exception if the input is not a valid charge response URL.
- (id)initWithURL:(NSURL*)url;

// requestURL - Retrieves the URL for the message. If you have special
// requirements around invoking the URL, you can use this instead of
// submit.
- (NSURL*)requestURL;

#if TARGET_OS_IPHONE

// submit - Invokes the URL for this message. For IFChargeRequest, if Credit
// Card Terminal is installed, your app will terminate and Credit Card Terminal
// will run. If not, either creditCardTerminalNotInstalled will be sent to
// the delegate or a default UIAlert will be displayed. For IFChargeResponse,
// if the OS is able to resolve the returnURL, the charge processing
// app will terminate and your app will run again. If not, a default
// UIAlert will be displayed.
- (void)submit;

#endif

// unableToOpenURL - Called when submit fails because the device could
// not find an application to handle the message's requestURL. In
// IFChargeRequest, this method will will try to invoke its delegate's
// creditCardTerminalNotInstalled. If that method is not defined, or if
// unableToOpenURL gets called on an instance of IFChargeResponse, the user
// will be presented with an alert summarizing the issue.
- (void)unableToOpenURL;

+ (NSArray*)knownFields;

@end
