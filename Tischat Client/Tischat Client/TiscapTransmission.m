//
//  TiscapTransmission.m
//  Tischat Client
//
// This class corresponds directly to its Ruby counterpart.
//

#import "TiscapTransmission.h"
#import "GCDAsyncSocket.h"
#import "MessageDispatch.h"


@implementation TiscapTransmission


+ (void)initialize {
    KnownVerbs = @[ @"/login",
                    @"/users",
                    @"/public",
                    @"/private",
                    @"/close",
                    @"]welcome",
                    @"]usernametaken",
                    @"]connected",
                    @"]disconnected",
                    @"]activeusers",
                    @"]public",
                    @"]private",
                    @"]error",
                    @"]badsyntax"   ];
    
    VerbsWhichTakeData = @[ @"/public",
                            @"]public",
                            @"/private",
                            @"]private"  ];
    
    EOT = [NSString stringWithFormat:@"%c", 0x04];
    
}




+ (TiscapTransmission *)from:(MessageDispatch *)ioHub {
    NSString *command = [ioHub readTo:@"\r\n"];
    if (!command) return nil;
    
    NSArray *components = [command componentsSeparatedByString:@" "];
    
    NSString *verb = [[components objectAtIndex:0] lowercaseString];
    if (![KnownVerbs containsObject:verb])
        return nil;
    
    NSString *argument = [components count] == 2 ?
                             [components objectAtIndex:1] : nil;
    
    NSString *data = nil;
    if ([VerbsWhichTakeData containsObject:verb]) {
        data = [ioHub readTo:EOT];
        if (!data) return nil;
    }
    
    
    return [[self alloc] initWithVerb:verb argument:argument data:data];
}




- (id)initWithVerb:(NSString *)verb argument:(NSString *)argument data:(NSString *)data {
    self = [super init];
    if (!self) return nil;
    
    // Strings have mutable subclasses, and copying them
    // is the surest way of getting the immutable version.
    // It's such a common idiom, copying static strings
    // is extremely efficient.
    
    if (![KnownVerbs containsObject:verb])
        return nil;
    
    _verb = [verb copy];
    _argument = [argument copy];
    _data = [data copy];
    
    return self;
}



- (NSData *)representation {
    NSMutableString *cum = [_verb mutableCopy];
    
    if (_argument)
        [cum appendFormat:@" %@", _argument];
    
    [cum appendString:@"\r\n"];
    
    if (_data)
        [cum appendFormat:@"%@%@", _data, EOT];
    
    return [cum dataUsingEncoding:NSUTF8StringEncoding];
}


- (NSString *)description {
    return [[NSString alloc] initWithData:[self representation]
                                 encoding:NSUTF8StringEncoding  ];
}




@synthesize verb = _verb;
@synthesize argument = _argument;
@synthesize data = _data;



@end
