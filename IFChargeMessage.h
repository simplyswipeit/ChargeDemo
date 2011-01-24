//
//  IFChargeMessage.h
//  ChargeDemo
//
//  Created by Ben Acland on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

extern BOOL IFMatchesPattern( NSString* s, NSString* p );
extern NSString* IFEncodeURIComponent( NSString* s );

#define IF_CHARGE_MESSAGE_FIELD_PREFIX @"ifcc_"
#define IF_CHARGE_NONCE_KEY @"ifcc_request_nonce"

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
@property (readonly,assign) BOOL amountIsSet;        // TODO: doco

// amount subfields - A breakdown of the amount of the transaction.
// These are strings of the same form as the amount property.
@property (readonly,copy) NSString* subtotal;
@property (readonly,copy) NSString* tip;
@property (readonly,copy) NSString* tax;
@property (readonly,copy) NSString* shipping;
@property (readonly,copy) NSString* discount;

// currency - The currency code of the amount. (E.g. USD for US Dollars)
// 3 characters.
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

@property (readonly,retain) NSString* baseURL; // TODO: doco

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

// submit - Invokes the URL for this message. If Credit Card Terminal       // TODO: update doco
// is installed, your app will terminate and Credit Card Terminal will
// run. If not, either creditCardTerminalNotInstalled will be sent to
// the delegate or a default UIAlert will be displayed.
- (void)submit;

#endif

- (void)unableToOpenURL; // TODO: doco

+ (NSArray*)knownFields;

@end
