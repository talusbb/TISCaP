//
//  MessageDispatch.h
//  Tischat Client
//
// Coordinates all interactions with the server.
//

#import <Foundation/Foundation.h>

// The following hard import is required because the
// GCDAsyncSocketDelegate protocol therein is formally adopted.
#import "GCDAsyncSocket.h"

@class TiscapTransmission;
@class ActiveUser;
@class UserList;



@interface MessageDispatch : NSObject <GCDAsyncSocketDelegate> {
    GCDAsyncSocket *_serverSocket;
    BOOL _didWelcome;
    
    // Queues for synchronizing and asynchronizing actions:
    dispatch_queue_t _messageConcurrentQueue;
    dispatch_queue_t _delegatedSerialQueue;
    dispatch_queue_t _dataRetrievalQueue;
    
    // For reading data atomically to a character:
    dispatch_semaphore_t _dataReady;
    NSData *_lastData;
    long _taggles;  // Probably unnecessary.
    
    // The Hub instructs the active users list to update
    // whenever a change comes down. Does not ask
    // AppController to help with the task.
    UserList *_activeUserList;
}

// The singleton accessor.
+ (MessageDispatch *)hub;

// Provides a similar function to my Ruby io+readto category,
// but in the context of a GCDAsyncSocket. See io+readto.rb in
// tischat-server for semantic details---except that this method
// returns nil when a TiscapTransmission could not be created,
// instead of raising an exception.
- (NSString *)readTo:(NSString *)delimiter;

// Send a transmission to the server.
- (void)sendTransmission:(TiscapTransmission *)trans;

// Connect (but don't yet log in) to the server.
// Login can be done by sending the appropriate transmission.
// This method does not block for the connection to be accepted.
- (BOOL)connectToServer:(NSString *)descriptor onPort:(int)port;

// Direct-access getter
// in case shit gets serious.
- (GCDAsyncSocket *)serverSocket;

// Close the connection, nicely or not:
- (void)graceful;
- (void)kill;


@property (readwrite, retain) UserList *userList;

@end
