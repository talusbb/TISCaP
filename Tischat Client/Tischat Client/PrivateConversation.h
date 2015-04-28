//
//  EIDocument.h
//  Tischat Client
//
// A private conversation is an NSDocument,
// which endows it with automatic windowing and instantiation
// behaviors which are quite convenient.
// 
// It connects to the users representing ourself and the other party.
// It receives send-messages from the interface.
//

#import <Cocoa/Cocoa.h>
@class MessageList;
@class ActiveUser;

@interface PrivateConversation : NSDocument {
    __weak ActiveUser *_otherParty;
    ActiveUser *_myselfParty;
    
    IBOutlet MessageList *privateMessageList;
    IBOutlet NSTableView *privateMessageListView;
    
    IBOutlet NSWindow *cheeseWindow;
}

- (IBAction)sendMessage:(id)sender;
- (void)receiveMessage:(NSString *)msg;

@end
