//
//  MessageList.h
//  Tischat Client
//
// Maintains a list of messages in a conversation:
// 
// Both a model (who said what, and in what order)
// and a controller (instructs a view to update when necessary).
// 
// Designed to be instantiated in a nib and connected directly
// to a table view, this class provides table view data source methods
// and a 'primary table,' which it talks to on updates.
//

#import <Foundation/Foundation.h>
@class ActiveUser;

@interface MessageList : NSObject {
    NSMutableArray *_messageList;
    
    __weak IBOutlet NSTableColumn *usernameColumn;
    __weak IBOutlet NSTableColumn *messageColumn;
    
    __weak IBOutlet NSTableView *primaryTable;
}

// Add a message to the list:
- (void)someone:(ActiveUser *)user said:(NSString *)message;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;


@end
