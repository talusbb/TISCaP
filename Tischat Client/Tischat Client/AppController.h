//
//  AppController.h
//  Tischat Client
//


// 
// Provides the central application logic.
// Manages the menubar and the main window,
// including mediating login/logout operations
// between the UI and the MessageDispatch Hub.
// 


#import <Foundation/Foundation.h>
@class TiscapTransmission;
@class UserList;
@class MessageList;
@class ActiveUser;


@interface AppController : NSObject <NSApplicationDelegate> {
    // Instance variables for the AppController.
    // IBOutlets connect to the interface.
    
    ActiveUser *_overrideSelectedUser;
    
    IBOutlet UserList *userList;
    
    IBOutlet NSTextField *hostAndPortField;
    IBOutlet NSTextField *usernameField;
    
    IBOutlet NSOutlineView *usernamesView;
    
    IBOutlet MessageList *publicMessageList;
    IBOutlet NSTableView *publicMessageListView;
    IBOutlet NSTextField *publicMessageField;
    
    IBOutlet NSWindow *theMainWindow;
    IBOutlet NSButton *logInOutButton;
}


// Public method declarations.
// IBActions are called by the interface.



//
// Manage connections to the server.
// The interface runs as a four-state machine:
// 
// Logged out  →  Connecting and Logging In  ↓
//  ↑  Logging out     ←     Welcomed (logged in)
// 
// Of course, due to error conditions,
// some of these stages may be skipped over.
// 
- (IBAction)initializeConnection:(id)sender;
- (IBAction)closeConnection:(id)sender;  // nicely
- (IBAction)killConnection:(id)sender;  // angrily
- (void)serverLost:(NSError *)reason;  // Called by MessageDispatch.





//
// Information for login and private messaging:
// 

//
// Get the user currently selected in the active users list.
- (ActiveUser *)selectedUser;

//
// Start a new private conversation with the selected user.
- (IBAction)startPrivateConversation:(id)sender;

//
// Get the name under which we logged in.
- (NSString *)loginName;




//
// Delegate-notification methods:
// Called by MessageDispatch in response to
// action from the server.
// 



//
// Finish the login process from a welcome message from the server.
// Asks for the users list.
- (void)serverDidWelcome:(TiscapTransmission *)transmission;

//
// Called when the requested username was taken.
// Present an error dialog to the user.
- (void)usernameTaken:(TiscapTransmission *)transmission;

//
// Methods called to update the active users list.
- (void)userConnected:(TiscapTransmission *)transmission;
- (void)userDisconnected:(TiscapTransmission *)transmission;
- (void)activeUsersUpdate:(TiscapTransmission *)transmission;




//
// Method called by the main window to send a public message.
// Forward the Transmission along.
- (IBAction)sendPublicMessage:(id)sender;

//
// Called when MessageDispatch Hub receives a public message.
// Post to the message list backing, and signal the interface to update.
- (void)receivePublicMessage:(TiscapTransmission *)transmission;

//
// Called when MessageDispatch Hub receives a private message.
// Identify (or create) the associated PrivateConversation
// and forward the Transmission along.
- (void)receivePrivateMessage:(TiscapTransmission *)transmission;

//
// Called when a TiscapError is received.
// Present to the user.
- (void)receiveError:(TiscapTransmission *)error;


@end
