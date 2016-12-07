/* LinphoneAppDelegate.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <UIKit/UIKit.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import "PersonEntity.h"
#import "XMPPIncomingFileTransfer.h"
#import "LinphoneCoreSettingsStore.h"

@class SettingViewController;
@interface LinphoneAppDelegate : NSObject <UIApplicationDelegate,UIAlertViewDelegate,XMPPRosterDelegate,NSFetchedResultsControllerDelegate,XMPPStreamManagementDelegate,XMPPStreamManagementStorage> {
    XMPPIncomingFileTransfer *xmppincomingfile;
    XMPPStream *xmppStream;
    XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
    XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
    XMPPvCardTempModule *xmppvCardTempModule;
    XMPPvCardAvatarModule *xmppvCardAvatarModule;
    XMPPCapabilities *xmppCapabilities;
    XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    XMPPStreamManagement *xmppStreamManagement;
    XMPPStreamManagementMemoryStorage *xmppStreamStorage;
    NSString *password;
    
    BOOL allowSelfSignedCertificates;
    BOOL allowSSLHostNameMismatch;
    
    BOOL isXmppConnected;
    
    UINavigationController *navigationController;
    SettingViewController *loginViewController;
    UIBarButtonItem *loginButton;
@private
    UIBackgroundTaskIdentifier bgStartId;
    BOOL startedInBackground;
    
    BOOL firstTime;
}
+(LinphoneAppDelegate*)sharedAppDelegate;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (nonatomic, strong, readonly)  NSMutableArray *friendlist;
@property (nonatomic, strong, readonly)  NSMutableArray *array;
@property (nonatomic, strong, readonly)  NSMutableArray *errorarray;
@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

@property (nonatomic, strong, readonly) XMPPStreamManagement *xmppStreamManagement;
@property (nonatomic, strong, readonly) XMPPStreamManagementMemoryStorage *xmppStreamStorage;

@property (nonatomic, strong) IBOutlet SettingViewController *settingViewController;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *loginButton;

@property (nonatomic, strong) IBOutlet UIWindow *windows;
- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

- (BOOL)connect;
- (void)disconnect;


-(PersonEntity*)fetchPerson:(NSString*)userName;
- (void)processRemoteNotification:(NSDictionary*)userInfo;

@property (nonatomic, retain) UIAlertView *waitingIndicator;
@property (nonatomic, retain) NSString *configURL;



@end

