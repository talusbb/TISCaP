//
//  UserList.h
//  Tischat Client
//
// A UserList represents the chat circle of ActiveUsers.
// Like MessageList, it is designed to be instantiated in the nib
// and connected directly to a list (NSOutlineView, in this case).
// 
// And, like MessageList, it is both a model (in containing a list)
// and a controller (in that it provides data source methods).
// It does not, however, update the view when it is changed.
//

#import <Foundation/Foundation.h>
@class ActiveUser;

@interface UserList : NSObject {
    // The active users list is considered to be interface-level,
    // and can only be accessed from the main thread.
    NSArray *_activeUserList;
}

- (ActiveUser *)activeUserNamed:(NSString *)username;
- (void)addUserNamed:(NSString *)username;
- (void)filterUserList:(NSArray *)usernamesToKeep;

// I'm not willing to let this class formally conform to the data source protocols,
// because in the good ol' days they were informal protocols, dammit!
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@property (readwrite, atomic, copy) NSArray *activeUsers;

@end
