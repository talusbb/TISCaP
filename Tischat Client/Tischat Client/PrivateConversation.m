//
//  EIDocument.m
//  Tischat Client
//
// 
//

#import "PrivateConversation.h"
#import "MessageList.h"
#import "MessageDispatch.h"
#import "TiscapTransmission.h"
#import "ActiveUser.h"
#import "UserList.h"
#import "AppController.h"

@implementation PrivateConversation

- (id)init {
    if (self = [super init]) {
        
        _otherParty = [(AppController *)[NSApp delegate] selectedUser];  // may be nil
        if (!_otherParty || [_otherParty conversation])
            return nil;
        
        [_otherParty setConversation:self];
        
        _myselfParty = [[[MessageDispatch hub] userList] activeUserNamed:[
                                                           (AppController *)[NSApp delegate] loginName
                                                           ]];
        if (!_myselfParty)
            return nil;
        
    }
    return self;
}




- (IBAction)sendMessage:(id)sender {
    ActiveUser *partner = _otherParty;  // iVar is weak, so hold onto it locally.
    
    if (!partner) {
        [[NSAlert alertWithMessageText:@"This chatter disconnected."
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"You may close this window if you're done with the conversation."]
         
         beginSheetModalForWindow:cheeseWindow completionHandler:^(NSModalResponse returnCode) {
             // Don't care.
         }];
        
        return;
    }
    
    [[MessageDispatch hub] sendTransmission:[[TiscapTransmission alloc] initWithVerb:@"/private"
                                                                            argument:[partner username]
                                                                                data:[sender stringValue]]  ];
    
    [privateMessageList someone:_myselfParty said:[sender stringValue]];
    
    [sender setStringValue:@""];
}




- (void)receiveMessage:(NSString *)msg {
    [privateMessageList someone:_otherParty
                           said:msg         ];
    
}













// Standard methods:




- (NSString *)windowNibName
{
    return @"PrivateConversation";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

@end
