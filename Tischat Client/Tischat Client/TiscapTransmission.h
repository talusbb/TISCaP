//
//  TiscapTransmission.h
//  Tischat Client
//
// This class directly corresponds to its Ruby counterpart.
// See tischat-server/library/Transmission.rb
// for semantic and structural discussions.
//

#import <Foundation/Foundation.h>
@class MessageDispatch;

NSArray * KnownVerbs;
NSArray * VerbsWhichTakeData;
NSString * EOT;

@interface TiscapTransmission : NSObject {
    NSString *_verb;
    NSString *_argument;
    NSString *_data;
}

+ (TiscapTransmission *)from:(MessageDispatch *)dispatcher;
- (id)initWithVerb:(NSString *)verb argument:(NSString *)argument data:(NSString *)data;
- (NSData *)representation;

@property (readonly) NSString *verb;
@property (readonly) NSString *argument;
@property (readonly) NSString *data;


@end
