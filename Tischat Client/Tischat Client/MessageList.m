//
//  MessageList.m
//  Tischat Client
//
// 
//

#import "MessageList.h"
#import "ActiveUser.h"




// Private class EI_Message
// represents the user/message tuple:

@interface EI_Message : NSObject {
    ActiveUser *_user;
    NSString *_message;
}

- (id)initWithUser:(ActiveUser *)usr message:(NSString *)msg;
- (NSString *)username;

@property (readonly) NSString *message;
@property (readonly) ActiveUser *user;

@end




@implementation EI_Message

- (id)initWithUser:(ActiveUser *)usr message:(NSString *)msg {
    self = [super init];
    if (!self) return nil;
    
    _user = usr;
    _message = [msg copy];
    
    return self;
}

- (NSString *)username {
    return [_user username];
}

@synthesize message = _message;
@synthesize user = _user;

@end









@implementation MessageList

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _messageList = [NSMutableArray arrayWithCapacity:20];
    
    return self;
}




- (void)someone:(ActiveUser *)user said:(NSString *)message {
    EI_Message *newMessage = [[EI_Message alloc] initWithUser:user message:message];
    [_messageList addObject:newMessage];
    
    [primaryTable reloadData];
    [primaryTable scrollRowToVisible:( [primaryTable numberOfRows] - 1 )];
    
}





- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_messageList count];
    
}




- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableColumn == usernameColumn) {
        return [[_messageList objectAtIndex:row] username];
        
    } else if (tableColumn == messageColumn) {
        return [[_messageList objectAtIndex:row] message];
        
    }
    
    return nil;
}





@end







