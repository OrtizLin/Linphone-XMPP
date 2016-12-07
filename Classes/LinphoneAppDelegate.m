/* LinphoneAppDelegate.m
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

#import "PhoneMainView.h"
#import "linphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"
#import "RootViewController.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPStreamManagementMemoryStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import <CFNetwork/CFNetwork.h>
#import "ChatController.h"
#import "MessageEntity.h"


#define TAG_CONF_INVITE 5
#define TAG_FRIEND_REQUEST 2
#define TAG_SET_ALIAS 3
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface LinphoneAppDelegate()

- (void)setupStream;
- (void)teardownStream;
- (void)goOnline;
- (void)goOffline;


@end


@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize xmppStreamManagement;
@synthesize xmppStreamStorage;


+(LinphoneAppDelegate*)sharedAppDelegate{
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    return appDelegate;
}

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if(self != nil) {
        self->startedInBackground = FALSE;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    
    [self teardownStream];
}


#pragma mark -


- (void)applicationDidEnterBackground:(UIApplication *)application{
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[LinphoneManager instance] enterBackgroundMode];
    
#if TARGET_IPHONE_SIMULATOR
    DDLogError(@"The iPhone simulator does not process background network traffic. "
               @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    
    if(call){
        
        NSLog(@"phone is calling...");
        
    }
    
    
    
    else{
        
        
        NSLog(@"phone is not calling...");
        if([[[PhoneMainView instance]currentView].content isEqualToString:@"HistoryViewController" ]){
            
        }
        else if([[[PhoneMainView instance]currentView].content isEqualToString:@"HistoryDetailsViewController"]){
            
        }
        else{
        [[LinphoneManager instance]	destroyLibLinphone];
        [[LinphoneManager instance]	startLibLinphone];
        if([[[PhoneMainView instance]currentView].content isEqualToString:@"RootViewController"]){
            
            [[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription]];
            [[PhoneMainView instance] changeCurrentView:[RootViewController compositeViewDescription]];
        }
            
        }
        }
        
    
    
    
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        /* save call context */
        LinphoneManager* instance = [LinphoneManager instance];
        instance->currentCallContextBeforeGoingBackground.call = call;
        instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);
        
        const LinphoneCallParams* params = linphone_call_get_current_params(call);
        if (linphone_call_params_video_enabled(params)) {
            linphone_call_enable_camera(call, false);
        }
    }
    
    if (![[LinphoneManager instance] resignActive]) {
        
    }
    
}
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    
    
    if (allowSelfSignedCertificates)
    {
        [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    }
    
    if (allowSSLHostNameMismatch)
    {
        [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
    }
    else
    {
        // Google does things incorrectly (does not conform to RFC).
        // Because so many people ask questions about this (assume xmpp framework is broken),
        // I've explicitly added code that shows how other xmpp clients "do the right thing"
        // when connecting to a google server (gmail, or google apps for domains).
        
        NSString *expectedCertName = nil;
        
        NSString *serverDomain = xmppStream.hostName;
        NSString *virtualDomain = [xmppStream.myJID domain];
        
        if ([serverDomain isEqualToString:@"talk.google.com"])
        {
            if ([virtualDomain isEqualToString:@"gmail.com"])
            {
                expectedCertName = virtualDomain;
            }
            else
            {
                expectedCertName = serverDomain;
            }
        }
        else if (serverDomain == nil)
        {
            expectedCertName = virtualDomain;
        }
        else
        {
            expectedCertName = serverDomain;
        }
        
        if (expectedCertName)
        {
            [settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
        }
    }
}



- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    
    isXmppConnected = YES;
    
    NSError *error = nil;
    
    if (![[self xmppStream] authenticateWithPassword:password error:&error])
    {
        
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self goOnline];
  

    if(firstTime == 0){
       
        [xmppStream sendElement:[XMPPPresence presence]]; // send available presence
        [xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:0];
        firstTime =true;
        return;
    }
    else{
        
      
        firstTime = false;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:NO];
        
        return;
        
    }

    
    
}
-(void)updateTime:(NSTimer *)timer{
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]disconnect];
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]connect:nil];
}
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    
    //    [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]disconnect];
    //    [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]connect:nil];
    
    
}
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    
    
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    //XEP_0199 ping
    //<iq xmlns="jabber:client" from="azfone.net" to="asuspad7@azfone.net/AzFone" id="276997683" type="get"><ping xmlns="urn:xmpp:ping"></ping></iq>
     
    
    //<iq from='juliet@capulet.lit/balcony' to='capulet.lit' id='s2c1' type='result'/>
    if(iq.isGetIQ){
         for (DDXMLElement *element in iq.children) {
             if([element.xmlns isEqualToString:@"urn:xmpp:ping"]){
                  XMPPIQ *iqs = [XMPPIQ iqWithType:@"result"];
                 [iqs addAttributeWithName:@"from" stringValue:iq.toStr];
                 [iqs addAttributeWithName:@"to" stringValue:iq.fromStr];
                 [iqs addAttributeWithName:@"id" stringValue:iq.elementID];
                 [xmppStream sendElement:iqs];
             }
         }
    }
    _friendlist =[NSMutableArray array];
    _array = [NSMutableArray array];
    _errorarray =[NSMutableArray array];
    
    for (DDXMLElement *element in iq.children) {
        if ([element.name isEqualToString:@"query"]) {
            for (DDXMLElement *item in element.children) {
                if ([item.name isEqualToString:@"item"]) {
                    [_array addObject:item.attributes];
                    [_friendlist addObject:item.attributes];
                    
                }
                else if([item.name isEqualToString:@"feature"]){
                    [_friendlist addObject:item.attributes];
                }
                
                
            }
            
        }
        
    }
    
  
    /* Example:
     
     "ask=\"subscribe\"",
     "subscription=\"none\"",
     "jid=\"gps@azfone.net\""
     
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"arrayFromSecondVC" object:_array];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"getRosterArray" object:_friendlist];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"errorArray" object:_errorarray];
    
    return YES;
    
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    
    NSXMLElement *request = [message elementForName:@"request"];
    
    if(request){
        //Receive message with receipts request.
        
        if([request.xmlns isEqualToString:@"urn:xmpp:receipts"]){
            
            XMPPMessage *msg =[XMPPMessage messageWithType:[[message attributeForName:@"type"] stringValue] to:message.from];
            
            NSXMLElement *recieved = [NSXMLElement elementWithName:@"received" xmlns:@"urn:xmpp:receipts"];
            [recieved addAttributeWithName:@"id" stringValue:[[message attributeForName:@"id"]stringValue]];
            [msg addChild:recieved];
            
            [self.xmppStream sendElement:msg];
            
        }
    }
    
    else{
        
        NSXMLElement *received = [message elementForName:@"received"];
        if (received){
            //get receipts and mark the message with string "hao123".
            if ([received.xmlns isEqualToString:@"urn:xmpp:receipts"]){
                
                NSString *message_id = [[received attributeForName:@"id"] stringValue];
                
                LinphoneAppDelegate *appDelegates = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
                
                NSPredicate *predicates = [NSPredicate predicateWithFormat:@"receipt=%@",message_id];
                
                NSFetchRequest *fetechRequests = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
                
                [fetechRequests setPredicate:predicates];
                
                NSSortDescriptor *sortDescs = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:NO];
                
                [fetechRequests setSortDescriptors:[NSArray arrayWithObject:sortDescs]];
                
                [fetechRequests setFetchLimit:1];
                
                NSFetchedResultsController*ReceiptFectch = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequests
                                                            
                                                                                              managedObjectContext:appDelegates.managedObjectContext
                                                            
                                                                                                sectionNameKeyPath:nil cacheName:nil];
                ReceiptFectch.delegate = self;
                
                [ReceiptFectch performFetch:NULL];
                
                NSArray *contentArrays = [ReceiptFectch fetchedObjects];
                
                if(contentArrays !=nil){
                    
                    MessageEntity*receiptMessage = [contentArrays lastObject];
                    
                    receiptMessage.receipt =@"hao123";
                    
                    [self saveContext];
                    
                }
                
            }
        }
    }
    
    
    NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
    
    NSString *messageLogic= [[message elementsForName:@"myMsgLogic"].firstObject stringValue];
    //if myMsgLogic is equal to device's UUID , and do not save own message to database.
    
    if ([uuidString isEqualToString:messageLogic]) {
        return;
    }
    
    //do not ignore SystemAlert's delay message but conference duplicate message.
    NSXMLElement *delay = [message elementForName:@"delay"];
    NSRange tRange = [message.fromStr rangeOfString:@"@conference"];
    
    if (delay && tRange.location != NSNotFound){
        if([delay.xmlns isEqualToString:@"urn:xmpp:delay"]){
            
            return;
            
        }
        
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
     NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessageEntity" inManagedObjectContext:appDelegate.managedObjectContext];
     NSPredicate *predicates = [NSPredicate predicateWithFormat:@"receipt=%@",[[message attributeForName:@"id"]stringValue]];
                        [fetchRequest setPredicate:predicates];
                        [fetchRequest setEntity:entity];
                    NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
                        if(items.count == 0){
                            
                        }
                        else{
                             return;
                        }

    
    
    
    NSString *body = [[message elementForName:@"body"] stringValue];
    
    NSString *displayName = [[message from]bare];
    
    NSString *roomname = [[message attributeForName:@"from"] stringValue];
    
    NSString *type = [[message attributeForName:@"type"] stringValue];
    
    NSString *image = [[message elementForName:@"photo"] stringValue];
    
    NSString *location = [[message elementForName:@"locations"]stringValue];
    
    if([type isEqualToString:@"error"]){
        
        return;
    }
    
    
    //Show conference invite alert.
    NSXMLElement *received = [message elementForName:@"x"];
    if([type isEqualToString:@"normal"]){
        
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location];
        
        NSRange search1 = [body rangeOfString:hostname];
        
        NSString *invitername = [body substringWithRange:NSMakeRange(0, search1.location)];
        
        
        
        
        NSString *title =[invitername stringByAppendingString:NSLocalizedString(@" invite you to:",nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:displayName
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Decline",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Accept",nil), nil];
        
        
        alertView.tag = TAG_CONF_INVITE;
        [alertView show];
        [alertView release];
    }
    //Show conference invite alert.
    else if([received.xmlns isEqualToString:@"jabber:x:conference"]){
        
        
        
        NSString *conf_jid = [[received attributeForName:@"jid"]stringValue];
        
        
        
        NSString *title =[displayName stringByAppendingString:NSLocalizedString(@" invite you to:",nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:conf_jid
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Decline",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Accept",nil), nil];
        
        
        alertView.tag = TAG_CONF_INVITE;
        [alertView show];
        [alertView release];
    }
    
    //if message is longitude and latitude, do not save to application.
    else if(body != NULL && [location isEqualToString:@"locations"]){
        return;
    }
    
    //save normal message by otis.
    else if (body != NULL) {
        
        //check if sender dosen't exist in roster.
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
        LinphoneAppDelegate *appDelegate = [LinphoneAppDelegate sharedAppDelegate];
        NSArray *fetchedPersonArray = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        NSMutableArray *personArray =[[NSMutableArray alloc]init];
        for(int i =0; i< fetchedPersonArray.count; i++){
//            PersonEntity*person = [fetchedPersonArray objectAtIndex:i];
//            [personArray addObject:person.name];
        }
        
        
    
            XMPPJID *jid = [XMPPJID jidWithString:displayName];
            NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
            [item addAttributeWithName:@"jid" stringValue:[jid bare]];
            NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
            [query addChild:item];
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
            [iq addChild:query];
            
            [xmppStream sendElement:iq];
       
        MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                                                     inManagedObjectContext:self.managedObjectContext];
        messageEntity.content = body;
        messageEntity.roomname =roomname;
        messageEntity.sendDate = [NSDate date];
        PersonEntity *senderUserEntity = [self fetchPerson:displayName];
        messageEntity.sender = senderUserEntity;
        messageEntity.image = image;
        messageEntity.receipt =[[message attributeForName:@"id"]stringValue];
        
        NSString *stamp = [[delay attributeForName:@"stamp"]stringValue];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // ignore +11 and use timezone name instead of seconds from gmt
       
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [dateFormat setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss'Z'"];
        
        NSDate *dte = [dateFormat dateFromString:stamp];
        if(stamp){
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            [dateFormatter setDateFormat:@" ( YYYY-MM-dd ahh:mm )"];
            
            [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
            
            [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
            
            NSString *strDate = [dateFormatter stringFromDate:dte];
            
            [dateFormatter release];
            NSString *strDate2 =[@" | Delay : CST " stringByAppendingString:strDate];
            messageEntity.content =[body stringByAppendingString:strDate2];
        }
        
        
        messageEntity.flag_readed =[NSNumber numberWithBool:NO];
        [senderUserEntity addSendedMessagesObject:messageEntity];
        messageEntity.receiver = [self fetchPerson:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        
        
        [self saveContext];
        
        
        //update badge number.
        [[PhoneMainView instance] updateXMPPNumber];
        
        //application notify in foreground.
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            if([[[PhoneMainView instance]currentView].content isEqualToString:@"RootViewController"]||[[[PhoneMainView instance]currentView].content isEqualToString:@"ChatController"]){
                
                
            }
            else{
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
            
        }
        //application notify in background.
        else
        {
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = @"Ok";
            localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            localNotification.soundName =UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
        
        
    }
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    if([presence.type isEqualToString:@"subscribe"]){
        NSString *path = [NSString stringWithFormat:@"%@/Documents/BLACKLIST.plist",NSHomeDirectory()];
                NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
                NSMutableArray *list =[plist objectForKey:@"List"];
                if([list containsObject:presence.fromStr]){
                    return;
                }
                else{
         NSString *jidStrBare = [presence fromStr];
         XMPPJID *jid = [XMPPJID jidWithString:jidStrBare];
        
        // Add the user to our roster.
        //
        // <iq type="set">
        //   <query xmlns="jabber:iq:roster">
        //     <item jid="bareJID" name="optionalName"/>
        //   </query>
        // </iq>
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"jid" stringValue:[jid bare]];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
        [iq addChild:query];
        
        [xmppStream sendElement:iq];
                    
        }

    }
    else if ([presence.type isEqualToString:@"unsubscribe"]){
        NSLog(@"被刪除好友...");
        
        NSString *jidStrBare = [presence fromStr];
        
        XMPPJID *jid = [XMPPJID jidWithString:jidStrBare];
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unsubscribed" to:[jid bareJID]];
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:presence];
        // Remove the user from our roster.
        // And unsubscribe from presence.
        // And revoke contact's subscription to our presence.
        // ...all in one step
        
        // <iq type="set">
        //   <query xmlns="jabber:iq:roster">
        //     <item jid="bareJID" subscription="remove"/>
        //   </query>
        // </iq>
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"jid" stringValue:[jid bare]];
        [item addAttributeWithName:@"subscription" stringValue:@"remove"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
        [iq addChild:query];
        
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:iq];

    }
    else{
    _errorarray =[NSMutableArray array];

    
    for (DDXMLElement *element in presence.children) {
        
        if([element.name isEqualToString:@"error"]){
            for(DDXMLElement *item in element.children){
                [_errorarray addObject:item];
                
                
            }
            
        }
        
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:@"errorArray" object:_errorarray];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"Presence" object:nil];
    }
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    
    
}



- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    
    if (!isXmppConnected)
    {
        
    }
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
   
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    
    if( startedInBackground ){
        startedInBackground = FALSE;
        [[PhoneMainView instance] startUp];
        [[PhoneMainView instance] updateStatusBar:nil];
    }
    LinphoneManager* instance = [LinphoneManager instance];
    
    [instance becomeActive];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams* params = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
                linphone_call_enable_camera(
                                            call,
                                            instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
        } else if ( linphone_call_get_state(call) == LinphoneCallIncomingReceived ) {
            [[PhoneMainView  instance ] displayIncomingCall:call];
            // in this case, the ringing sound comes from the notification.
            // To stop it we have to do the iOS7 ring fix...
            [self fixRing];
        }
    }
}

- (UIUserNotificationCategory*)getMessageNotificationCategory {
    
    UIMutableUserNotificationAction* reply = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    reply.identifier = @"reply";
    reply.title = NSLocalizedString(@"Reply", nil);
    reply.activationMode = UIUserNotificationActivationModeForeground;
    reply.destructive = NO;
    reply.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* mark_read = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    mark_read.identifier = @"mark_read";
    mark_read.title = NSLocalizedString(@"Mark Read", nil);
    mark_read.activationMode = UIUserNotificationActivationModeBackground;
    mark_read.destructive = NO;
    mark_read.authenticationRequired = NO;
    
    NSArray* localRingActions = @[mark_read, reply];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_msg";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];
    
    return localRingNotifAction;
}

- (UIUserNotificationCategory*)getCallNotificationCategory {
    UIMutableUserNotificationAction* answer = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    answer.identifier = @"answer";
    answer.title = NSLocalizedString(@"Answer", nil);
    answer.activationMode = UIUserNotificationActivationModeForeground;
    answer.destructive = NO;
    answer.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* decline = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    decline.identifier = @"decline";
    decline.title = NSLocalizedString(@"Decline", nil);
    decline.activationMode = UIUserNotificationActivationModeBackground;
    decline.destructive = YES;
    decline.authenticationRequired = NO;
    
    
    NSArray* localRingActions = @[decline, answer];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_call";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];
    
    return localRingNotifAction;
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
  
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    NSFileManager * fm  = [[NSFileManager alloc]init];
       NSString * src =[[NSBundle mainBundle]pathForResource:@"DEVICETOKEN" ofType:@"plist"];
    NSString * dst =[NSString stringWithFormat:@"%@/Documents/DEVICETOKEN.plist",NSHomeDirectory()];
 
    if(![fm fileExistsAtPath:dst]){
        [fm copyItemAtPath:src toPath:dst error:nil];
    }
    
    
    
    // Setup the XMPP stream
  
    [self setupStream];
    
    
    NSString *myJID = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
    NSString *myPassword = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];
    
    [[NSUserDefaults standardUserDefaults]setObject:myJID forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults]setObject:myPassword forKey:kXMPPmyPassword];
    
    
    [[NSUserDefaults standardUserDefaults]synchronize];
    if (![self connect])
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            NSLog(@"did not connect xmpp");
            
            
        });
    }
    
    
    UIApplication* app= [UIApplication sharedApplication];
    UIApplicationState state = app.applicationState;
    
    if( [app respondsToSelector:@selector(registerUserNotificationSettings:)] ){
        /* iOS8 notifications can be actioned! Awesome: */
        UIUserNotificationType notifTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
        
        NSSet* categories = [NSSet setWithObjects:[self getCallNotificationCategory], [self getMessageNotificationCategory], nil];
        UIUserNotificationSettings* userSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:categories];
        [app registerUserNotificationSettings:userSettings];
        [app registerForRemoteNotifications];
    } else {
        NSUInteger notifTypes = UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeNewsstandContentAvailability;
        [app registerForRemoteNotificationTypes:notifTypes];
    }
    
    LinphoneManager* instance = [LinphoneManager instance];
    BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
    BOOL start_at_boot   = [instance lpConfigBoolForKey:@"start_at_boot_preference"];
    
    
    
    
    if (state == UIApplicationStateBackground)
    {
        // we've been woken up directly to background;
        if( !start_at_boot || !background_mode ) {
            // autoboot disabled or no background, and no push: do nothing and wait for a real launch
            /*output a log with NSLog, because the ortp logging system isn't activated yet at this time*/
            NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
            return YES;
        }
        
    }
    bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [LinphoneLogger log:LinphoneLoggerWarning format:@"Background task for application launching expired."];
        [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
    }];
    
    [[LinphoneManager instance]	startLibLinphone];
    // initialize UI
    [self.window makeKeyAndVisible];
    [RootViewManager setupWithPortrait:(PhoneMainView*)self.window.rootViewController];
    [[PhoneMainView instance] startUp];
    [[PhoneMainView instance] updateStatusBar:nil];
    
    
    
    NSDictionary *remoteNotif =[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif){
        [LinphoneLogger log:LinphoneLoggerLog format:@"PushNotification from launch received."];
        [self processRemoteNotification:remoteNotif];
    }
    if (bgStartId!=UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
    
    
    if([application respondsToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge |  UIRemoteNotificationTypeSound)];
    }
    
    
    return YES;
}

- (void)application:(UIApplication *)app  didRegisterForRemoteNotificationsWithDeviceToken: (NSData *)deviceToken
{
        const unsigned *tokenBytes = [deviceToken bytes];
        NSString *iOSDeviceToken =
        [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
         ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
         ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
         ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    
    NSString *path = [NSString stringWithFormat:@"%@/Documents/DEVICETOKEN.plist",NSHomeDirectory()];
    NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
    [plist setValue:iOSDeviceToken forKey:@"token"];
    [plist writeToFile:path atomically:YES];
    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError: (NSError *)err {
    NSLog(@"error %@",err);
}
- (void)applicationWillTerminate:(UIApplication *)application {
   
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    BOOL isSaveSuccess = [[self managedObjectContext] save:&error];
    if (!isSaveSuccess) {
        NSLog(@"save message fail: %@,%@",error,[error userInfo]);
    }
    else {
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ChatDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSString *)applicationDocumentsFileDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        
        return __persistentStoreCoordinator;
    }
    
    NSString *documentPath = [self applicationDocumentsFileDirectory];
    
    NSString *version = @"2";
    NSURL *storeURL = nil;
    NSString *currentFileName = [NSString stringWithFormat:@"ChatDemo%@.sqlite",version];
    NSString *currentFilePath = [documentPath stringByAppendingPathComponent:currentFileName];
    if ([[NSFileManager defaultManager]fileExistsAtPath:currentFilePath]) {
        
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ChatDemo.sqlite"];
    }else {
        
        NSString *resourceFilePath = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"ChatDemo%@",version]
                                                                    ofType:@"sqlite"];
        [[NSFileManager defaultManager]copyItemAtPath:resourceFilePath toPath:currentFilePath error:NULL];
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:currentFileName];
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ChatDemo2.sqlite"];
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        
    }
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        
    }
    
    return __persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
#pragma mark XMPP
-(PersonEntity*)fetchPerson:(NSString*)userName{
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@",userName];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest setPredicate:predicate];
    LinphoneAppDelegate *appDelegate = [LinphoneAppDelegate sharedAppDelegate];
    NSArray *fetchedPersonArray = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    PersonEntity *fetchedPerson = nil;
    if (fetchedPersonArray.count>0) {
        fetchedPerson = [fetchedPersonArray objectAtIndex:0];
    }else {
        fetchedPerson = [NSEntityDescription insertNewObjectForEntityForName:@"PersonEntity"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
        fetchedPerson.name = userName;
        [appDelegate saveContext];
    }
    return fetchedPerson;
}


#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContext_roster
{
    return [xmppRosterStorage mainThreadManagedObjectContext];
    
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
    return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (void)setupStream
{
    NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
    
    // Setup xmpp stream
    //
    // The XMPPStream is the base class for all activity.
    // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
    xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    {
        // Want xmpp to run in the background?
        //
        // P.S. - The simulator doesn't support backgrounding yet.
        //        When you try to set the associated property on the simulator, it simply fails.
        //        And when you background an app on the simulator,
        //        it just queues network traffic til the app is foregrounded again.
        //        We are patiently waiting for a fix from Apple.
        //        If you do enableBackgroundingOnSocket on the simulator,
        //        you will simply see an error message from the xmpp stack when it fails to set the property.
        
        xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    
    // Setup reconnect
    //
    // The XMPPReconnect module monitors for "accidental disconnections" and
    // automatically reconnects the stream for you.
    // There's a bunch more information in the XMPPReconnect header file.
    
    xmppReconnect = [[XMPPReconnect alloc] init];
    [xmppReconnect activate:xmppStream];
    [xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    //     xmppincomingfile =[XMPPIncomingFileTransfer new];
    //
    //    [xmppincomingfile activate:xmppStream];
    //    [xmppincomingfile addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //     xmppincomingfile.autoAcceptFileTransfers=YES;
    // Setup roster
    //
    // The XMPPRoster handles the xmpp protocol stuff related to the roster.
    // The storage for the roster is abstracted.
    // So you can use any storage mechanism you want.
    // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
    // or setup your own using raw SQLite, or create your own storage mechanism.
    // You can do it however you like! It's your application.
    // But you do need to provide the roster with some storage facility.
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    
    xmppRoster.autoFetchRoster = YES;
    xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = NO;
    
    // Setup vCard support
    //
    // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
    // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
    
    xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    
    xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
   
    xmppStreamManagement = [[XMPPStreamManagement alloc] initWithStorage:[XMPPStreamManagementMemoryStorage new]];
    
    // And then configured however you like.
    // This is just an example:
    xmppStreamManagement.autoResume = YES;
    xmppStreamManagement.ackResponseDelay = 0.2;
    
    [xmppStreamManagement automaticallyRequestAcksAfterStanzaCount:3 orTimeout:0.4];
    [xmppStreamManagement automaticallySendAcksAfterStanzaCount:10 orTimeout:5.0];
    
    [xmppStreamManagement activate:xmppStream];
    [xmppStreamManagement addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Setup capabilities
    //
    // The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
    // Basically, when other clients broadcast their presence on the network
    // they include information about what capabilities their client supports (audio, video, file transfer, etc).
    // But as you can imagine, this list starts to get pretty big.
    // This is where the hashing stuff comes into play.
    // Most people running the same version of the same client are going to have the same list of capabilities.
    // So the protocol defines a standardized way to hash the list of capabilities.
    // Clients then broadcast the tiny hash instead of the big list.
    // The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
    // and also persistently storing the hashes so lookups aren't needed in the future.
    //
    // Similarly to the roster, the storage of the module is abstracted.
    // You are strongly encouraged to persist caps information across sessions.
    //
    // The XMPPCapabilitiesCoreDataStorage is an ideal solution.
    // It can also be shared amongst multiple streams to further reduce hash lookups.
    
    //    xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    //    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    //
    //    xmppCapabilities.autoFetchHashedCapabilities = YES;
    //    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
   
    // Activate xmpp modules
    
    [xmppReconnect         activate:xmppStream];
    [xmppRoster            activate:xmppStream];
    [xmppvCardTempModule   activate:xmppStream];
    [xmppvCardAvatarModule activate:xmppStream];
//  [xmppCapabilities      activate:xmppStream];
    
    
    
    // Add ourself as a delegate to anything we may be interested in
    
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
   
    // Optional:
    //
    // Replace me with the proper domain and port.
    // The example below is setup for a typical google talk account.
    //
    // If you don't supply a hostName, then it will be automatically resolved using the JID (below).
    // For example, if you supply a JID like 'user@quack.com/rsrc'
    // then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
    //
    // If you don't specify a hostPort, then the default (5222) will be used.
    
    NSString *xmppdomain = [[LinphoneManager instance] lpConfigStringForKey:@"xmppdomain_preference"];
    [xmppStream setHostName:xmppdomain];
    [xmppStream setHostPort:5222];
    
    
    // You may need to alter these settings depending on the server you're connecting to
    allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
    
}
- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags
{
    NSLog(@"didDetectAccidentalDisconnect:%u",connectionFlags);
}
- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
    NSLog(@"shouldAttemptAutoReconnect:%u",reachabilityFlags);
    return YES;
}
- (void)teardownStream
{
    [xmppStream removeDelegate:self];
    [xmppRoster removeDelegate:self];
   
    
    [xmppReconnect         deactivate];
    [xmppRoster            deactivate];
    [xmppvCardTempModule   deactivate];
    [xmppvCardAvatarModule deactivate];

    //  [xmppCapabilities      deactivate];
    
    [xmppStream disconnect];
    
    xmppStream = nil;
    xmppReconnect = nil;
    xmppRoster = nil;
    xmppRosterStorage = nil;
    xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
    xmppvCardAvatarModule = nil;
    xmppCapabilities = nil;
//    xmppCapabilitiesStorage = nil;
    
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    [[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    
    [[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
    if (![xmppStream isDisconnected]) {
        return YES;
    }
    
    
    
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    NSString *fulljid = [myJID stringByAppendingString:@"/AzFone"];
    
    
    if (myJID == nil || myPassword == nil) {
        return NO;
    }
    
    [xmppStream setMyJID:[XMPPJID jidWithString:fulljid]];
    password = myPassword;
    
    NSError *error = nil;
    if (![xmppStream connect:&error])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                            message:@"See console for error details."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        DDLogError(@"Error connecting: %@", error);
        
        return NO;
    }
    return YES;
}

- (void)disconnect
{
    [self goOffline];
    [xmppStream disconnect];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    // Go to Dialer view
    DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
    if(controller != nil) {
        [controller setAddress:[url host]];
    }
    
    
    return YES;
}

- (void)fixRing{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    }
}

- (void)processRemoteNotification:(NSDictionary*)userInfo{
    if ([LinphoneManager instance].pushNotificationToken==Nil){
        [LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
        return;
    }
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    
    if(aps != nil) {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        if(alert != nil) {
            NSString *loc_key = [alert objectForKey:@"loc-key"];
            /*if we receive a remote notification, it is probably because our TCP background socket was no more working.
             As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
            LinphoneCore *lc = [LinphoneManager getLc];
            if (linphone_core_get_calls(lc)==NULL){ //if there are calls, obviously our TCP socket shall be working
                linphone_core_set_network_reachable(lc, FALSE);
                [LinphoneManager instance].connectivity=none; /*force connectivity to be discovered again*/
                [[LinphoneManager instance] refreshRegisters];
                if(loc_key != nil) {
                    if([loc_key isEqualToString:@"IM_MSG"]) {
                        [[PhoneMainView instance] addInhibitedEvent:kLinphoneTextReceived];
                        [[PhoneMainView instance] changeCurrentView:[RootViewController compositeViewDescription]];
                    } else if([loc_key isEqualToString:@"IC_MSG"]) {
                        //it's a call
                        NSString *callid=[userInfo objectForKey:@"call-id"];
                        if (callid) 
                            [[LinphoneManager instance] enableAutoAnswerForCallId:callid];
                        else
                            [LinphoneLogger log:LinphoneLoggerError format:@"PushNotification: does not have call-id yet, fix it !"];
                        
                        [self fixRing];
                    }
                }
            }
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
    
    [self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom*)findChatRoomForContact:(NSString*)contact {
    MSList* rooms = linphone_core_get_chat_rooms([LinphoneManager getLc]);
    const char* from = [contact UTF8String];
    while (rooms) {
        const LinphoneAddress* room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom*)rooms->data);
        char* room_from = linphone_address_as_string_uri_only(room_from_address);
        if( room_from && strcmp(from, room_from)== 0){
            return rooms->data;
        }
        rooms = rooms->next;
    }
    return NULL;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    Linphone_log(@"%@ - state = %d", NSStringFromSelector(_cmd), application.applicationState);
    
    [self fixRing];
    
    if([notification.userInfo objectForKey:@"callId"] != nil) {
        BOOL auto_answer = TRUE;
        
        // some local notifications have an internal timer to relaunch themselves at specified intervals
        if( [[notification.userInfo objectForKey:@"timer"] intValue] == 1 ){
            [[LinphoneManager instance] cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
            auto_answer = [[LinphoneManager instance] lpConfigBoolForKey:@"autoanswer_notif_preference"];
        }
        if(auto_answer)
        {
            [[LinphoneManager instance] acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];
        }
    }  else if([notification.userInfo objectForKey:@"callLog"] != nil) {
        NSString *callLog = (NSString*)[notification.userInfo objectForKey:@"callLog"];
        // Go to HistoryDetails view
        [[PhoneMainView instance] changeCurrentView:[HistoryViewController compositeViewDescription]];
        HistoryDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[HistoryDetailsViewController compositeViewDescription] push:TRUE], HistoryDetailsViewController);
        if(controller != nil) {
            [controller setCallLogId:callLog];
        }
    }
}

// this method is implemented for iOS7. It is invoked when receiving a push notification for a call and it has "content-available" in the aps section.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
    LinphoneManager* lm = [LinphoneManager instance];
    
    if (lm.pushNotificationToken==Nil){
        [LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
        return;
    }
    
    // save the completion handler for later execution.
    // 2 outcomes:
    // - if a new call/message is received, the completion handler will be called with "NEWDATA"
    // - if nothing happens for 15 seconds, the completion handler will be called with "NODATA"
    lm.silentPushCompletion = completionHandler;
    [NSTimer scheduledTimerWithTimeInterval:15.0 target:lm selector:@selector(silentPushFailed:) userInfo:nil repeats:FALSE];
    
    LinphoneCore *lc=[LinphoneManager getLc];
    // If no call is yet received at this time, then force Linphone to drop the current socket and make new one to register, so that we get
    // a better chance to receive the INVITE.
    if (linphone_core_get_calls(lc)==NULL){
        linphone_core_set_network_reachable(lc, FALSE);
        lm.connectivity=none; /*force connectivity to be discovered again*/
        [lm refreshRegisters];
    }
}



#pragma mark - User notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    if( [[UIDevice currentDevice].systemVersion floatValue] >= 8){
        
        LinphoneCore* lc = [LinphoneManager getLc];
        [LinphoneLogger log:LinphoneLoggerLog format:@"%@", NSStringFromSelector(_cmd)];
        if( [notification.category isEqualToString:@"incoming_call"]) {
            if( [identifier isEqualToString:@"answer"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"decline"] ){
                LinphoneCall* call = linphone_core_get_current_call(lc);
                if( call ) linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
            }
        } else if( [notification.category isEqualToString:@"incoming_msg"] ){
            if( [identifier isEqualToString:@"reply"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"mark_read"] ){
                NSString* from = [notification.userInfo objectForKey:@"from"];
                LinphoneChatRoom* room = linphone_core_get_or_create_chat_room(lc, [from UTF8String]);
                if( room ){
                    linphone_chat_room_mark_as_read(room);
                    [[PhoneMainView instance] updateApplicationBadgeNumber];
                }
            }
        }
    }
    completionHandler();
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    completionHandler();
}

#pragma mark - Remote configuration Functions (URL Handler)


- (void)ConfigurationStateUpdateEvent: (NSNotification*) notif {
    LinphoneConfiguringState state = [[notif.userInfo objectForKey: @"state"] intValue];
    if (state == LinphoneConfiguringSuccessful) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kLinphoneConfiguringStateUpdate
                                                      object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];
        
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success",nil)
                                                        message:NSLocalizedString(@"Remote configuration successfully fetched and applied.",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        [[PhoneMainView instance] startUp];
    }
    if (state == LinphoneConfiguringFailed) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kLinphoneConfiguringStateUpdate
                                                      object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure",nil)
                                                        message:NSLocalizedString(@"Failed configuring from the specified URL." ,nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        
    }
}


- (void) showWaitingIndicator {
    _waitingIndicator = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetching remote configuration...",nil) message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *progress= [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        [_waitingIndicator setValue:progress forKey:@"accessoryView"];
        [progress setColor:[UIColor blackColor]];
    } else {
        [_waitingIndicator addSubview:progress];
    }
    [progress startAnimating];
    [progress release];
    [_waitingIndicator show];
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 1) && (buttonIndex==1))  {
        [self showWaitingIndicator];
        [self attemptRemoteConfiguration];
    }

    else if(alertView.tag ==TAG_SET_ALIAS && (buttonIndex==1)){
        
        NSString *jidstr = alertView.title;
        XMPPJID *jid = [XMPPJID jidWithString:jidstr];
        NSString *nickname = [alertView textFieldAtIndex:0].text;
        if([[alertView textFieldAtIndex:0].text isEqualToString:@" System"]){
            [xmppRoster setNickname:jidstr forUser:jid];
        }
        else{
            [xmppRoster setNickname:nickname forUser:jid];
        }
    }
    
    else if((alertView.tag == TAG_CONF_INVITE) && (buttonIndex ==1)){
        
        NSString *roomid = alertView.message;
        
        NSString *Self_JID = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        NSRange search = [Self_JID rangeOfString:@"@"];
        
        NSString *nickname = [Self_JID substringWithRange:NSMakeRange(0, search.location)];
        
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
            
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:roomid] dispatchQueue:dispatch_get_main_queue()];
        
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
        [xmppRoom joinRoomUsingNickname:nickname history:nil];
        [xmppRoom fetchConfigurationForm];
        [xmppRoom addDelegate:[LinphoneAppDelegate sharedAppDelegate] delegateQueue:dispatch_get_main_queue()];
        NSXMLElement *roomConfigForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
        [xmppRoom configureRoomUsingOptions:roomConfigForm jid:myJid];
        
        [[PhoneMainView instance] changeCurrentView:[RootViewController compositeViewDescription]];
        
    }
    
    
    
}

- (void)attemptRemoteConfiguration {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ConfigurationStateUpdateEvent:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
    linphone_core_set_provisioning_uri([LinphoneManager getLc] , [configURL UTF8String]);
    [[LinphoneManager instance] destroyLibLinphone];
    [[LinphoneManager instance] startLibLinphone];
    
}


@end
