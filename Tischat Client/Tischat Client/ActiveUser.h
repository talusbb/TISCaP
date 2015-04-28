//
//  ActiveUser.h
//  Tischat Client
//
// Represents another user in the chat circle.
// Associates their username with the conversation (if any)
// we're currently having with them.
// 
// Also has a -compare: method for easy sorting (by username).
//


#import <Foundation/Foundation.h>
@class PrivateConversation;

@interface ActiveUser : NSObject {
    NSString *_username;
    __weak PrivateConversation *_conversation;
}

- (id)initWithUsername:(NSString *)name;
- (NSComparisonResult)compare:(ActiveUser *)otherUser;

@property (readonly) NSString *username;
@property (weak, readwrite, atomic) PrivateConversation *conversation;

@end
