//
//  ActiveUser.m
//  Tischat Client
// 
// 
// 

#import "ActiveUser.h"

@implementation ActiveUser


- (id)initWithUsername:(NSString *)name {
    
    // I have a perverse adoration
    // for this bizarre boilerplate construct:
    self = [super init];
    if (!self) return nil;
    
    _username = [name copy];
    
    return self;
}


- (NSComparisonResult)compare:(ActiveUser *)otherUser {
    // Localized standard compare
    // is standardized against the comparison used by the Finder.
    
    return [_username localizedStandardCompare:[otherUser username]];
    
}




@synthesize username = _username;
@synthesize conversation = _conversation;

@end
