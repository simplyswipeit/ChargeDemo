// -*- objc -*-
//
// IFChargeResponse.h
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
#import <UIKit/UIKit.h>
#import "IFChargeMessage.h"
#import "IFChargeRequest.h"

typedef enum {
    // Approved - The card was approved and charged.
    kIFChargeResponseCodeApproved,

    // Cancelled - The user pressed the "Done" button in Credit Card
    // Terminal before performing a transaction.
    kIFChargeResponseCodeCancelled,

    // Declined - The card was declined. This is a very specific
    // response indicating that the card is not authorized for the
    // requested charge. Other issues such as expired card, improper
    // AVS, etc, all yield the "Error" code.
    kIFChargeResponseCodeDeclined,

    // Error - The user attempted to process the transaction, but the
    // card was not charged. This could be anything from a network
    // error to an expired card. The specific error was presented to
    // the user in Credit Card Terminal, and they chose to return to
    // your program rather than edit and retry the transaction.
    kIFChargeResponseCodeError
} IFChargeResponseCode;

@interface IFChargeResponse : IFChargeMessage
{
@private
    NSString*            _cardType;

    NSString*            _redactedCardNumber;
    IFChargeResponseCode _responseCode;
    NSString*            _responseType;
}

// cardType - The type of card that was charged. This will be
// something like "Visa", "MasterCard", "American Express", or
// "Discover". This property will only be set if responseCode is
// Accepted. In the case that the card type is unknown, this property
// will be nil.
@property (readonly,copy)   NSString*            cardType;

// redactedCardNumber - This string is the credit card number with all
// but the last four digits replaced by 'X'. This property will only
// be set if responseCode is Accepted.
@property (readonly,copy)   NSString*            redactedCardNumber;

// responseCode - One of the IFChargeResponseCode enum values.
@property (readonly,assign) IFChargeResponseCode responseCode;

// initWithChargeRequest - Copies values from the request to a new
// response and redacts the provided card number. If the response code
// is kIFChargeResponseCodeApproved, then the card number must be set.
- (id)initWithChargeRequest:(IFChargeRequest*)request responseCode:(IFChargeResponseCode)responseCode cardNumber:(NSString*)cardNumber cardType:(NSString*)cardType;

+ (NSDictionary*)responseCodeMapping;

@end


// These macros define the default message used for the UIAlert when
// Credit Card Terminal is not installed. Override these strings in
// your string table for other languages.
#define IF_RESPONSE_CAN_NOT_OPEN_URL_BUTTON  ( NSLocalizedString( @"OK", nil ) )
#define IF_RESPONSE_CAN_NOT_OPEN_URL_MESSAGE ( NSLocalizedString( \
@"The system could not match the URL provided to any installed application.", nil \
) )
#define IF_RESPONSE_CAN_NOT_OPEN_URL_TITLE   ( NSLocalizedString( @"Unable to return to application.", nil ) )

#define IF_CHARGE_CARD_NUMBER_MASK @"X"

#define IF_CHARGE_DEFAULT_CURRENCY @"USD"