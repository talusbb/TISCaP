//
//  UserList.m
//  Tischat Client
//
// 
//

#import "UserList.h"
#import "ActiveUser.h"

@implementation UserList



- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _activeUserList = [NSArray array];
    
    
    return self;
}



- (ActiveUser *)activeUserNamed:(NSString *)username {
    NSArray *activeUsers = [self activeUsers];
    NSUInteger userdex = [activeUsers indexOfObjectPassingTest:^BOOL(ActiveUser *usr, NSUInteger idx, BOOL *stop) {
        return [[usr username] isEqual:username];
    }];
    
    if (userdex == NSNotFound) return nil;
    return [activeUsers objectAtIndex:userdex];
}


- (void)addUserNamed:(NSString *)username {
    NSMutableArray *newUserList = [[self activeUsers] mutableCopy];
    
    [newUserList addObject: [[ActiveUser alloc] initWithUsername:username] ];
    [newUserList sortUsingSelector:@selector(compare:)];
    
    [self setActiveUsers:newUserList];  // Makes immutable copy on its own.
}


- (void)filterUserList:(NSArray *)usernamesToKeep {
    NSArray *currentUserList = [self activeUsers];
    
    NSIndexSet *usersToKeep = [currentUserList indexesOfObjectsPassingTest:^BOOL(ActiveUser *usr, NSUInteger idx, BOOL *stop) {
        return [usernamesToKeep containsObject:[usr username]];
    }];
    
    NSMutableArray *workingUserList = [[currentUserList objectsAtIndexes:usersToKeep] mutableCopy];
    for (NSString *username in usernamesToKeep) {
        NSUInteger idex = [workingUserList indexOfObjectPassingTest:^BOOL(ActiveUser *usr, NSUInteger idx, BOOL *stop) {
            return [[usr username] isEqualToString:username];    }];
        if (idex == NSNotFound)
            [workingUserList addObject:[[ActiveUser alloc] initWithUsername:username]];
    }
    
    [self setActiveUsers:workingUserList];
}






- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item) return nil;
    
    return [[self activeUsers] objectAtIndex:index];
    
}




- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
    
}




- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item) return 0;  // Mistakenly asking for non-root node
    
    return [[self activeUsers] count];
    
}




- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    // Right now there's only one table column, so we don't need to check it.
    
    return [item username];
    
}



































@synthesize activeUsers = _activeUserList;

@end
