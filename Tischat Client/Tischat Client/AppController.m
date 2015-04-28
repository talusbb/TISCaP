//
//  AppController.m
//  Tischat Client
//
//  Created by Taldar Baddley on 2013-12-6.
//  Copyright (c) 2013 Talus. All rights reserved.
//

#import "AppController.h"
#import "TiscapTransmission.h"
#import "MessageDispatch.h"
#import "UserList.h"
#import "MessageList.h"
#import "ActiveUser.h"
#import "PrivateConversation.h"

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    // Connect the MessageDispatch Hub
    // to the user list instantiated in the nib.
    [[MessageDispatch hub] setUserList:userList];
    
    
    
}





- (ActiveUser *)selectedUser {
    
    // If we're in the middle of fooling some object
    // into thinking a different user is selected,
    // go ahead and do the fooling:
    
    if (_overrideSelectedUser)
        return _overrideSelectedUser;
    
    
    // Otherwise, get the selected ActiveUser from the list:
    
    NSInteger selectedRow = [usernamesView selectedRow];
    if (selectedRow < 0) return nil;
    
    return [usernamesView itemAtRow:selectedRow];
}



- (IBAction)startPrivateConversation:(id)sender {
    
    ActiveUser *selectedUser = [self selectedUser];
    if (!selectedUser) {
        NSBeep();
        return;
    }
    
    // If the selected user is already engaged in an active Conversation,
    // bring that conversation to the front.
    
    PrivateConversation *convers = [selectedUser conversation];
    if (convers) {
        [convers showWindows];
        return;
    }
    
    
    // Otherwise, create the Conversation.
    
    // (This is the same mechanism as invoking File: New):
    [NSApp sendAction:@selector(newDocument:) to:nil from:sender];
    
}



- (NSString *)loginName {
    return [usernameField stringValue];
}





- (IBAction)initializeConnection:(id)sender {
    // Currently does not check for illegal username characters, just length.
    // That's a problem that I don't think needs solving right now.
    
    NSString *username = [usernameField stringValue];
    if ([username length] < 1 || [username length] > 16) {
        NSBeep();
        return;
    }
    
    NSString *serverInfo = [hostAndPortField stringValue];
    if ([serverInfo length] < 1) {
        NSBeep();
        return;
    }
    
    // Extract port number from server address,
    // if given:
    
    NSArray *komponents = [serverInfo componentsSeparatedByString:@":"];
    NSString *hostname = [komponents objectAtIndex:0];
    
    int port = 4020;
    if ([komponents count] == 2) {
        NSString *portString = [komponents objectAtIndex:1];
        port = [portString intValue];
    }
    
    
    
    // Make the connection,
    // and queue up a login request.
    // I want to put one right on the heels of the other,
    // for everyone's speed and contentment.
    
    [[MessageDispatch hub] connectToServer:hostname onPort:port];
    
    [[MessageDispatch hub] sendTransmission:[[TiscapTransmission alloc] initWithVerb:@"/login"
                                                                            argument:username
                                                                                data:nil   ]];
    
    // Update the interface to reflect the state change
    // (connecting and logging in)
    
    [logInOutButton setAction:@selector(killConnection:)];
    [logInOutButton setTitle:@"Log Out"];
    
    [hostAndPortField setEnabled:NO];
    [usernameField setEnabled:NO];
    
}



- (IBAction)closeConnection:(id)sender {
    // Send along the request to gracefully disconnect,
    // And update the interface to reflect the state change
    // (logging out)
    
    [[MessageDispatch hub] graceful];
    
    [logInOutButton setAction:@selector(killConnection:)];
    [logInOutButton setTitle:@"Log Out"];
    
    [hostAndPortField setEnabled:NO];
    [usernameField setEnabled:NO];
    
}



- (IBAction)killConnection:(id)sender {
    // Kill the connection!
    // Straight away!
    // 
    // (Allow the disconnection method to update our state machine
    // when the kill actually goes through.)
    
    [[MessageDispatch hub] kill];
    
}













- (void)serverDidWelcome:(TiscapTransmission *)transmission {
    // Accept the welcoming from the server.
    // We now transition the interface to be able to send requests.
    // (the welcomed/logged-in state)
    
    
    // Ask for the active users:
    
    [[MessageDispatch hub] sendTransmission:[[TiscapTransmission alloc] initWithVerb:@"/users"
                                                                            argument:nil data:nil]];
    
    
    [logInOutButton setAction:@selector(closeConnection:)];
    [logInOutButton setTitle:@"Log Out"];
    
    [hostAndPortField setEnabled:NO];
    [hostAndPortField setEnabled:NO];
    
}




- (void)usernameTaken:(TiscapTransmission *)transmission {
    // Present the error.
    
    [[NSAlert alertWithMessageText:@"Username Taken"
                    defaultButton:@"OK"
                  alternateButton:nil
                      otherButton:nil
        informativeTextWithFormat:@"Please choose another."]
     
     beginSheetModalForWindow:theMainWindow completionHandler:^(NSModalResponse returnCode) {
         
         // When done do:
         [usernameField selectText:self];
        
    }];
    
}




- (void)userConnected:(TiscapTransmission *)transmission {
    // The model has been updated.
    // Signal the view to update itself therefrom.
    
    [usernamesView reloadData];
}




- (void)userDisconnected:(TiscapTransmission *)transmission {
    // The model has been updated.
    // Signal the view to update itself therefrom.
    
    [usernamesView reloadData];
}




- (void)activeUsersUpdate:(TiscapTransmission *)transmission {
    // The model has been updated.
    // Signal the view to update itself therefrom.
    
    [usernamesView reloadData];
}



- (IBAction)sendPublicMessage:(id)sender {
    // Construct and pass along the public message transmission.
    
    [[MessageDispatch hub] sendTransmission:[[TiscapTransmission alloc] initWithVerb:@"/public"
                                                                            argument:nil
                                                                                data:[sender stringValue]]  ];
    // Upon success, the server will echo back the message we just sent.
    
    [sender setStringValue:@""];
}




- (void)receivePublicMessage:(TiscapTransmission *)transmission {
    // Update the message list (model-controller).
    // It will instruct its view to refresh.
    
    ActiveUser *associatedUser = [userList activeUserNamed:[transmission argument]];
    [publicMessageList someone:associatedUser said:[transmission data]];
}




- (void)receivePrivateMessage:(TiscapTransmission *)transmission {
    // Find the active conversation
    // associated with the sender of this message,
    // and pass that message along.
    
    // An ActiveUser maintains a weak reference to its active PrivateConversation.
    // If we can find that conversation, we can go directly to it.
    // If not, we must create the conversation, and then proceed as before.
    
    NSString *fromName = [transmission argument];
    NSString *message = [transmission data];
    
    ActiveUser *fromUser = [userList activeUserNamed:fromName];
    if (!fromUser) {
        [self receivePublicMessage:transmission];
        return;
    }
    
    PrivateConversation *targetConversation = [fromUser conversation];
    if (!targetConversation) {
        _overrideSelectedUser = fromUser;
        targetConversation = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES
                                                                                                       error:NULL];
        _overrideSelectedUser = nil;
    }
    
    [targetConversation receiveMessage:message];
}




- (void)receiveError:(TiscapTransmission *)error {
    // Display Dialog.
    
    if ([[error verb] isEqualToString:@"]badsyntax"]) {
        
    } else {
        [[NSAlert alertWithMessageText:@"There is a problem."
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"The server reported: “%@”", [error argument]]
         
         beginSheetModalForWindow:theMainWindow completionHandler:^(NSModalResponse returnCode) {
             
             // When done do:
             // (nothing)
             
         }];
        
    }
    
}





- (void)serverLost:(NSError *)reason {
    
    // The connection to the server was lost,
    // either expectedly or unexpectedly (indicated by the error reason argument).
    // Update the interface to reflect the change in state (logged-out).
    
    [usernamesView reloadData];
    
    if (reason) {
        [[NSAlert alertWithError:reason] beginSheetModalForWindow:theMainWindow completionHandler:^(NSModalResponse returnCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [logInOutButton setAction:@selector(initializeConnection:)];
                [logInOutButton setTitle:@"Log In"];
                
                [hostAndPortField setEnabled:YES];
                [usernameField setEnabled:YES];
                
            });
        }];
        
        
    } else {
        
        [logInOutButton setAction:@selector(initializeConnection:)];
        [logInOutButton setTitle:@"Log In"];
        
        [hostAndPortField setEnabled:YES];
        [usernameField setEnabled:YES];
            
    }
    
}




















@end
