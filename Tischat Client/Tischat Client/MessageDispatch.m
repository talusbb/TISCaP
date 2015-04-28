//
//  MessageDispatch.m
//  Tischat Client
//
// 
//

#import "MessageDispatch.h"
#import "GCDAsyncSocket.h"
#import "TiscapTransmission.h"
#import "AppController.h"
#import "ActiveUser.h"
#import "UserList.h"


// Convenience function
// to asynchronously dispatch a code block to the main thread.
// In Cocoa, the interface expects to only ever be acted upon
// by the main thread. This is how we do that.
static void
MainThreadDo(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}



// Private methods on MessageDispatch,
// via anonymous category!
@interface MessageDispatch ()

//
// Signal that we should start listening,
// asynchronously, to the server.
- (void)listen;

@end



@implementation MessageDispatch

// Singleton hub:
static MessageDispatch *ei_message_dispatch_hub = nil;



+ (void)initialize {
    // This method is guaranteed by the runtime to be called and finished
    // before any other method is allowed to call into
    // the class from the outside.
    // Perfect time for sane, safe singleton initialization.
    
    ei_message_dispatch_hub = [[MessageDispatch alloc] init];
}

+ (MessageDispatch *)hub {
    return ei_message_dispatch_hub;
}




- (id)init {
    self = [super init];
    if (!self) return nil;
    
    // Set up the queueueues!
    
    _messageConcurrentQueue = dispatch_queue_create("com.eightt.Tischat-Client.netconcurrent",
                                                    DISPATCH_QUEUE_CONCURRENT);
    _delegatedSerialQueue   = dispatch_queue_create("com.eightt.Tischat-Client.netserial",
                                                    DISPATCH_QUEUE_SERIAL);
    _dataRetrievalQueue     = dispatch_queue_create("com.eightt.Tischat-Client.dataserial",
                                                    DISPATCH_QUEUE_SERIAL);
    
    
    return self;
}



- (BOOL)connectToServer:(NSString *)descriptor onPort:(int)port {
    __block BOOL weGood = NO;
    
    // Synchronize against other delegate methods in self:
    dispatch_sync(_delegatedSerialQueue, ^{
        
        // Make and establish the server socket.
        
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegatedSerialQueue];
        weGood = [_serverSocket connectToHost:descriptor onPort:port withTimeout:10 error:NULL];
        _didWelcome = NO;
        
        if (!weGood)
            return;  // that is, break from the block.
        
        [self listen];  // async
        
    });
    
    // The server hasn't connected yet (probably).
    // But we can tell if something was utterly wrong with the connection parameters,
    // and we indicate that in the return value.
    return weGood;
}





- (void)listen {
    
    // Concurrent.ly do ...
    dispatch_async(_messageConcurrentQueue, ^{
        
        while (YES) {  @autoreleasepool {
            
            //
            // Get a Transmission from the server,
            // process, rinse, repeat.
            // 
            
            // The circular retain only exists until the queue
            // has processed and exited this block.
            TiscapTransmission *serverSaid = [TiscapTransmission from:self];
            
            // If the connection was interrupted somehow,
            // terminate this listening session.
            if (!serverSaid) break;
            
            NSString *verb = [serverSaid verb];  // known to be lowercased.
            AppController *appController = (AppController *)[NSApp delegate];
            
            // Now it's time to talk to the interface
            // (via the app controller):
            MainThreadDo(^{
                if ([verb isEqualToString:@"]welcome"]) {
                    _didWelcome = YES;
                    [appController serverDidWelcome:serverSaid];
                    
                    
                } else if ([verb isEqualToString:@"]usernametaken"]) {
                    [appController usernameTaken:serverSaid];
                    
                    
                } else if ([verb isEqualToString:@"]connected"]) {
                    NSString *username = [serverSaid argument];
                    
                    // Add the user to the Active Users list, by
                    // creating an ActiveUser object.
                    
                    if (!username) return;
                    if ([_activeUserList activeUserNamed:username]) return;
                    
                    [_activeUserList addUserNamed:username];
                    
                    [appController userConnected:serverSaid];  // notify
                    
                    
                } else if ([verb isEqualToString:@"]disconnected"]) {
                    // Remove the named user from the list.
                    
                    NSString *deadUsername = [serverSaid argument];
                    NSArray *currentUserList = [_activeUserList activeUsers];
                    NSIndexSet *usersToKeep = [currentUserList indexesOfObjectsPassingTest:^BOOL(ActiveUser *usr, NSUInteger idx, BOOL *stop) {
                        return ![[usr username] isEqual:deadUsername];
                    }];
                    
                    [_activeUserList setActiveUsers:[currentUserList objectsAtIndexes:usersToKeep]];
                    
                    [appController userDisconnected:serverSaid];  // notify
                    
                    
                } else if ([verb isEqualToString:@"]activeusers"]) {
                    // Filter the active users list.
                    // Keep the ActiveUser objects where possible,
                    // and make new ones where needed.
                    
                    NSString *providedUserList = [serverSaid argument];
                    if (!providedUserList) return;
                    
                    NSArray *usernames = [providedUserList componentsSeparatedByString:@","];
                    [_activeUserList filterUserList:usernames];
                    
                    [appController activeUsersUpdate:serverSaid];  // notify
                    
                    
                } else if ([verb isEqualToString:@"]public"]) {
                    [appController receivePublicMessage:serverSaid];
                    
                    
                } else if ([verb isEqualToString:@"]private"]) {
                    [appController receivePrivateMessage:serverSaid];
                    
                    
                } else if ([verb isEqualToString:@"]error"] || [verb isEqualToString:@"]badsyntax"]) {
                    [appController receiveError:serverSaid];
                    
                    
                }  // else do nothing.
                
            });  // end main-thread-do
            
            
        }  }  // end auto-release-pooled while
        
        
    });  // end concurrent block
}  // end -listen








- (NSString *)readTo:(NSString *)delimiter {
    // Plan of action:
    // 
    // Enter a block synchronized against other readTo: invocations
    //    or similar.
    // Set up a data-ready semaphore.
    // Instruct the server socket to read the stream up to the delimiter,
    //    knowing that when it's done it will call -socket:didReadData:.
    // Wait for the semaphore.
    // .
    // .
    // .
    // Expect the -socket:didReadData: method to trip our semaphore when the data are ready.
    // Reset conditions, enstringify the data, and return.
    
    
    __block NSData *scrumbles = nil;
    
    dispatch_sync(_dataRetrievalQueue, ^{
        
        _dataReady = dispatch_semaphore_create(0);
        _lastData = nil;
        _taggles++;
        
        [_serverSocket readDataToData:[delimiter dataUsingEncoding:NSUTF8StringEncoding]
                          withTimeout:-1
                                  tag:_taggles];
        
        dispatch_semaphore_wait(_dataReady, DISPATCH_TIME_FOREVER);
        _dataReady = NULL;
        
        scrumbles = _lastData;
        _lastData = nil;
        
        
    });
    
    // Check to see if the stream was interrupted
    // before the data could be completely read:
    if (!scrumbles)
        return nil;
    
    // It's funny that we have to specify UTF-8, considering it's
    // the only text encoding that ever existed.
    NSMutableString *jumbles = [[NSMutableString alloc] initWithData:scrumbles encoding:NSUTF8StringEncoding];
    [jumbles replaceOccurrencesOfString:delimiter
                             withString:@""
                                options:( NSBackwardsSearch | NSAnchoredSearch )
                                  range:NSMakeRange(0, [jumbles length])    ];
    return jumbles;
}




- (void)sendTransmission:(TiscapTransmission *)trans {
    [_serverSocket writeData:[trans representation]
                 withTimeout:20
                         tag:0];
}




- (GCDAsyncSocket *)serverSocket {
    return _serverSocket;
}



- (void)graceful {
    [self sendTransmission:[[TiscapTransmission alloc] initWithVerb:@"/close"
                                                           argument:nil
                                                               data:nil    ]];
    [_serverSocket disconnectAfterWriting];
}



- (void)kill {
    [_serverSocket disconnect];
}









//
// Delegate Methods
// from the server socket.
// 
// See GCDAsyncSocket.h for *really* detailed descriptions
// of exactly what these are supposed to do.
// 






/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock != _serverSocket) return;
    
    // Set the lastData and
    // Signal the dataReady semaphore!
    
    _lastData = data;
    if (_dataReady)
        dispatch_semaphore_signal(_dataReady);
    
}




- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
    // We don't listen for new connections.
    // This method ought never be called.
    // If it is, the new socket will be summarily released
    // and its connection thereby closed.
    
}




- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    // We don't care so much exactly when the connection was established.
    // By the time this method is called, the /login request should already be queued,
    // and the AsyncSocket will send it off ASAP.
    // What we care about is the ]welcome response,
    // which is handled by the -listen method.
    
}




// The following few methods are present for protocol conformance,
// but again, we don't care about them.
// We could care if we wanted to track, for instance, the continued life of the TCP connection.


- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}


- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    
}




- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    
    // We don't timeout reads from the server.
    // It may go for indefinite time without posting anything.
    
    // If this method is called for some reason, let it fail:
    return 0;
}
               
               
               

- (NSTimeInterval) socket:(GCDAsyncSocket *)sock
shouldTimeoutWriteWithTag:(long)tag
                  elapsed:(NSTimeInterval)elapsed
                bytesDone:(NSUInteger)length {
    
    // Bullocks!
    
    // If not the current socket, let it spin off into the sunset...
    if (sock != _serverSocket) return 0;
    
    // Close stream
    dispatch_async(_messageConcurrentQueue, ^{
        // I wouldn't dispatch this, but the documentation
        // promises that this call is synchronous, which makes me suspicious...
        
        [_serverSocket disconnect];
        
        // This causes -socketDidDisconnect: to be called,
        // so we needn't do any extra cleanup here.
    });
    
    return 0;  // Allow timeout to proceed without extension.
}







- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    
    // For peculiar corner cases in the TCProtocol,
    // which are deliberately avoided by GCDAsyncSocket.
    
    // Never called.
    
}




/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (sock != _serverSocket) return;
    
    // Clear out all known users:
    [[self userList] filterUserList:@[]];
    
    // Notify the app controller:
    AppController *appc = (AppController *)[NSApp delegate];
    MainThreadDo(^{  [appc serverLost:err];  });
    
    // Tell any waiting -readTo:'s to snap out of it
    // and return in a harumph.
    if (_dataReady)
        dispatch_semaphore_signal(_dataReady);
    
    // There is no need to clean up _dataReady or _lastData:
    // They are set and unset within the _dataRetrievalQueue, which is never
    // unatomically interrupted. (It gets cleanly interrupted by the above semaphore.)
    
    // Furthermore, the semaphore is signalled only when it exists, within the delegate methods,
    // which are called on the _delegatedSerialQueue... which is serial.
    
    _serverSocket = nil;
    
}




- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    
    // Not applicable to our usage scenario.
    
}











@synthesize userList = _activeUserList;








@end
