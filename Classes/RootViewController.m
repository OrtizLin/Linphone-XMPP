#import "RootViewController.h"
#import "LinphoneAppDelegate.h"
#import "ChatController.h"
#import "XMPPFramework.h"
#import "DDLog.h"
#import "PhoneMainView.h"
#import "MessageEntity.h"
#define kNumViewTag 100
#define kNumLabelTag 101
#define kOnlineTag 102
#define kOfflineTag 103
#define kBusyTag 104
#define kRejectTag 105
#define kAcceptTag 106
#define RequestTag 107
#define AddTag 1
#define SelfButtonClickTag 2
#define EditAliasTag 2
#define ChangePresenceTag 3
#define RemoveTag 5
#define PresenceTag 6
#define AddFriendTag 6
#define PasswordTag 11
#define ReconnectTag 10

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
@interface RootViewController()
@end
@implementation RootViewController{
    int count;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (LinphoneAppDelegate *)appDelegate
{
    return (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
}
#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"chat"
                                                                content:@"RootViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:false
                                                           portraitMode:true];
    }
    return compositeDescription;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   
    if(![[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isConnected]){
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        if(selfUserName !=nil){
            [self refresh];
        }
        
    }
    else{

    [self loadView];
    [self getPersonArray];
    [DataTable reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PresenceNotify:) name:@"Presence" object:nil];
        
    }
   
    
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    
    
    //add hostname account as friend to receive Emergency Messages from iguardian.
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    
    if(selfUserName !=nil){
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        
        XMPPJID *jid = [XMPPJID jidWithString:hostname];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:@" System"];
    }
    
    
    
    
    
}

-(void)loadView{
    
    [self setContainer];
    [self setNavigationBar];
    [self setSelfName];
    [self setSelfButton];
    [self setSelfImage];
    [self setTableView];
    [self setRefreshButton];
    
}

-(void)butClick{
    
    if([[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isConnected]){
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        UIActionSheet *action = [[UIActionSheet alloc]
                                 initWithTitle:selfUserName
                                 delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                 destructiveButtonTitle:nil
                                 otherButtonTitles:NSLocalizedString(@"Change photo",nil),NSLocalizedString(@"Change presence",nil),nil];
        action.tag = SelfButtonClickTag;
        
        if (IS_IPHONE)
        {
            [action showInView:[[UIApplication sharedApplication] keyWindow]];
            
        }
        else{
            [action showInView:self.view];
            
        }
        [action release];
    }
    
}
- (void)setpresence:(UIImage *)mainImage {
    [[self.view viewWithTag:1] removeFromSuperview];
    UIImage* presence =[mainImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    UIImageView * presenceview =[[UIImageView alloc]initWithImage:presence];
    presenceview.frame =CGRectMake(92, 82, 15, 15);
    [presenceview setTag:1];
    [self.view addSubview:presenceview];
}
-(void)setpresencetext:(NSString *)text{
    [[self.view viewWithTag:2] removeFromSuperview];
    UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
    presencetext.backgroundColor = [UIColor clearColor];
    presencetext.font = [UIFont systemFontOfSize:18];
    [presencetext setTag:2];
    presencetext.text =NSLocalizedString(text,nil);
    [self.view addSubview:presencetext];
    
}
-(void)setSelfImage{
//self photo label.
    [[self.view viewWithTag:3] removeFromSuperview];
    XMPPJID *xmppJID=[XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
    XMPPUserCoreDataStorageObject *user = [[[self appDelegate] xmppRosterStorage]
                                           userForJID:xmppJID
                                           xmppStream:[[self appDelegate] xmppStream]
                                           managedObjectContext:[[self appDelegate] managedObjectContext_roster]];
    
    NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:xmppJID];
    if (photoData != nil){
        UIImage *selfimage = [UIImage imageWithData:photoData];
        UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
        imageview.frame = CGRectMake(14,50,50,50);
        imageview.layer.masksToBounds = YES;
        imageview.layer.cornerRadius = 50.00000/ 2.0f;
        [imageview setTag:3];
        [self.view addSubview:imageview];
    }
    else if(user.photo !=nil){
        
        UIImage *selfimage =user.photo;
        UIImageView *imageview =[[UIImageView alloc]initWithImage:selfimage];
        imageview.frame = CGRectMake(14,50,50,50);
        imageview.layer.masksToBounds = YES;
        imageview.layer.cornerRadius = 50.00000/ 2.0f;
        [imageview setTag:3];
        [self.view addSubview:imageview];
    }
    else{
        
        UIImage *selfimage = [[UIImage imageNamed:@"defaultPerson"]stretchableImageWithLeftCapWidth:100 topCapHeight:100];
        UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
        imageview.frame = CGRectMake(14,50,50,50);
        imageview.layer.masksToBounds = YES;
        imageview.layer.cornerRadius = 50.00000/ 2.0f;
        [imageview setTag:3];
        [self.view addSubview:imageview];
    }
  
    

    
}
-(void)setContainer{
    if(IS_IPHONE){
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
        self.view = container;
    }
    else{
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        self.view = container;
    }
}

-(void)setNavigationBar{
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    navBar.tintColor = [UIColor darkGrayColor];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",nil) style:UIBarButtonItemStylePlain target:self action:@selector(addfriend)];
    navItem.leftBarButtonItem = leftButton;
    
    navBar.items = @[ navItem ];
    [self.view addSubview:navBar];
}

-(void)setSelfName{
    UILabel *selfname = [[UILabel alloc]initWithFrame:CGRectMake(91, 41, 280, 50)];
    selfname.backgroundColor = [UIColor clearColor];
    [selfname setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    selfname.text =[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    [self.view addSubview:selfname];
}
-(void)setSelfButton{
    UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    selfbutton.frame = CGRectMake(screenSize.width-190, 61, 280, 30);
    selfbutton.backgroundColor = [UIColor clearColor];
    [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selfbutton];
}
-(void)setTableView{
    if(IS_IPHONE){
        CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
        
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 109, 320, screenHeight-177)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        DataTable.backgroundColor = [ UIColor clearColor];
        UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.jpeg"]];
        [tempImageView setFrame:DataTable.frame];
        DataTable.backgroundView = tempImageView;
        [self.view addSubview:DataTable];
    }
    else{
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 109, 768, 810)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.jpeg"]];
        [tempImageView setFrame:DataTable.frame];
        DataTable.backgroundView = tempImageView;
        [self.view addSubview:DataTable];
    }
}
-(void)getPersonArray{
    [self setpresence:[UIImage imageNamed:@"led_connected"]];
    [self setpresencetext:@"Online"];
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr!=%@",selfUserName];
    
    NSManagedObjectContext *moc = [[self appDelegate] managedObjectContext_roster];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:moc];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setPredicate:predicate];
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:moc
                                                                     sectionNameKeyPath:@"sectionNum"
                                                                              cacheName:nil];
    [fetchedResultsController setDelegate:self];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error])
    {
        DDLogError(@"Error performing fetch: %@", error);
    }
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"sendedMessages.@count>0 and name!=%@",selfUserName];
    NSFetchRequest *fetchRequest1 = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest1 setPredicate:predicate1];
    
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest1 setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest1
                                                               managedObjectContext:[LinphoneAppDelegate sharedAppDelegate].managedObjectContext
                                                                 sectionNameKeyPath:nil cacheName:nil];
    
    fetchResultController.delegate = self;
    [fetchResultController performFetch:NULL];
    personArray = [[NSMutableArray alloc]initWithArray:[fetchResultController fetchedObjects]];
    
}
-(void)setRefreshButton{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    [DataTable addSubview:self.refreshControl];
}


//left button.

-(void)addfriend{
    if(! [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isAuthenticated]){
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
        
        alert.tag = ReconnectTag;
       [alert show];
       [alert release];
    }
    else{
        UIActionSheet *action = [[UIActionSheet alloc]
                                 initWithTitle:NSLocalizedString(@"Buddy",nil)
                                 delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                 destructiveButtonTitle:nil
                                 otherButtonTitles:NSLocalizedString(@"Add with account",nil),nil];
        
        action.tag = AddFriendTag;
        if (IS_IPHONE)
        {
            [action showInView:[[UIApplication sharedApplication] keyWindow]];
            
        }
        else{
            [action showInView:self.view];
            
        }
        [action release];
        
        
    }
}


- (void)getListOfGroups{
    
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    NSRange search = [selfUserName rangeOfString:@"@"];
    
    NSString *hostname = [selfUserName substringFromIndex:search.location+1];
    NSString* server = [@"conference." stringByAppendingFormat:@"%@",hostname]; //or whatever the server address for muc is
    XMPPJID *servrJID = [XMPPJID jidWithString:server];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:servrJID];
    
    [iq addAttributeWithName:@"from" stringValue:selfUserName];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
    [iq addChild:query];
    [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
    
}

- (void)resetField:(NSString *)field forKey:(NSString *)key
{
    
    [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
    
}
- (void)setField:(NSString *)field forKey:(NSString *)key {
    if (field != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
        [[NSUserDefaults standardUserDefaults]synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}
- (void)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);
    
    
    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    
    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    if( !identity || !*identity ) identity = "sip:user@example.com";
    
    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    
    
    if( domain && [domain length] != 0) {
        // when the domain is specified (for external login), take it as the server address
        linphone_proxy_config_set_server_addr(proxyCfg, [domain UTF8String]);
        linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
        
    }
    
    identity = linphone_address_as_string_uri_only(linphoneAddress);
    
    linphone_proxy_config_set_identity(proxyCfg, identity);
    
    
    
    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
                                                    , NULL, [password UTF8String]
                                                    , NULL
                                                    , NULL
                                                    ,linphone_proxy_config_get_domain(proxyCfg));
    
    [self setDefaultSettings:proxyCfg];
    
    [self clearProxyConfig];
    
    linphone_proxy_config_enable_register(proxyCfg, true);
    linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
    
    
    
    
    linphone_core_set_default_proxy(lc, proxyCfg);
    LinphoneTransportType type = LinphoneTransportTcp;
    linphone_address_set_transport(linphoneAddress, type);
    NSString* tname = @"tcp_port";
    linphone_core_set_sip_transports(lc,(__bridge const LCSipTransports *)(tname));
}
- (void)clearProxyConfig {
    linphone_core_clear_proxy_config([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}
- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];
    
    BOOL pushnotification = [lm lpConfigBoolForKey:@"pushnotification_preference"];
    if(pushnotification) {
        [lm addPushTokenToProxyConfig:proxyCfg];
        
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(alertView.tag == AddTag && buttonIndex ==1){
       
        
        if(![[alertView textFieldAtIndex:1].text isEqualToString:@" System"]){
           
                NSString *path = [NSString stringWithFormat:@"%@/Documents/BLACKLIST.plist",NSHomeDirectory()];
                NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
                NSMutableArray *list =[plist objectForKey:@"List"];
                if([list containsObject:[alertView textFieldAtIndex:0].text]){
                    [list removeObject:[alertView textFieldAtIndex:0].text];
                    [plist setValue:list forKey:@"List"];
                    [plist writeToFile:path atomically:YES];
                }
                
                XMPPJID *jid = [XMPPJID jidWithString:[alertView textFieldAtIndex:0].text];
                [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:[alertView textFieldAtIndex:1].text];
                
            
        }
    }
    else if(alertView.tag== EditAliasTag && buttonIndex ==1){
        
        if(![[alertView textFieldAtIndex:0].text isEqualToString:@" System"]){
       
            XMPPJID *jid = [XMPPJID jidWithString:alertView.title];
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:[alertView textFieldAtIndex:0].text];
        }
    }

    
       else if(alertView.tag ==RequestTag){
        if(buttonIndex ==0){
         
            // Reject request.
            
             XMPPJID *jid = [XMPPJID jidWithString:alertView.message];
            
             XMPPPresence *presence = [XMPPPresence presenceWithType:@"unsubscribed" to:[jid bareJID]];
             [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:presence];
            
             
             NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
             [item addAttributeWithName:@"jid" stringValue:[jid bare]];
             [item addAttributeWithName:@"subscription" stringValue:@"remove"];
             
             NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
             [query addChild:item];
             
             XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
             [iq addChild:query];
             
             [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:iq];
            
            NSString *path = [NSString stringWithFormat:@"%@/Documents/BLACKLIST.plist",NSHomeDirectory()];
            NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
            NSMutableArray *list =[plist objectForKey:@"List"];
            [list addObject:alertView.message];
            [plist setValue:list forKey:@"List"];
            [plist writeToFile:path atomically:YES];

            
        }
        else{
            NSLog(@"accept button");
            XMPPJID *jid = [XMPPJID jidWithString:alertView.message];
            


            
            XMPPPresence *presence = [XMPPPresence presenceWithType:@"subscribed" to:jid];
            [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:presence];
            NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
            [item addAttributeWithName:@"jid" stringValue:[jid bare]];
          
            
            NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
            [query addChild:item];
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
            [iq addChild:query];
            
            [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:iq];
            [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:[XMPPPresence presenceWithType:@"subscribe" to:jid]];


        }
    }
    else if(alertView.tag == ReconnectTag &&buttonIndex ==1){
       [[PhoneMainView instance] changeCurrentView:[SettingsViewController compositeViewDescription]];
    }
    else if(alertView.tag ==PasswordTag && buttonIndex ==1){
        
        XMPPPresence *presence = [XMPPPresence presence];
        
        [presence addAttributeWithName:@"to" stringValue:friendentity.jidStr];
        [presence addAttributeWithName:@"type" stringValue:@"unavailable"];
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
        
        NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
           
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage
                                                               jid:friendentity.jid
                                                     dispatchQueue:dispatch_get_main_queue()];
        [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate]xmppStream]];
        [xmppRoom joinRoomUsingNickname:nickname
                                history:nil
                               password:[alertView textFieldAtIndex:0].text];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray2:) name:@"errorArray" object:nil];
        
    }
    else if(alertView.tag ==PresenceTag){
        if(buttonIndex ==1){
            
            XMPPPresence *presence = [XMPPPresence presence];
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
            
            [self setpresence:[UIImage imageNamed:@"led_connected"]];
            [self setpresencetext:@"Online"];
            
        }
        else if(buttonIndex ==2){
            XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
            
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
            
            [self setpresence:[UIImage imageNamed:@"led_disconnected"]];
            [self setpresencetext:@"Offline"];
            
            
        }
        else if(buttonIndex ==3){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"dnd"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Busy"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
          
            [self setpresence:[UIImage imageNamed:@"led_inprogress"]];
            [self setpresencetext:@"Busy"];
           
            
        }
    }
    else if(buttonIndex ==0){
        
        [DataTable reloadData];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //actionsheet ,tag =1 ,button 0  is roomlist, button1 is create room.
 
   if (actionSheet.tag == SelfButtonClickTag && buttonIndex ==0){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [[[[UIApplication sharedApplication].delegate window] rootViewController] presentModalViewController:picker animated:YES];
        
    }
    else if(actionSheet.tag == SelfButtonClickTag &&buttonIndex ==1){
        if (IS_IPHONE)
        {
            UIActionSheet *action = [[UIActionSheet alloc]
                                     initWithTitle:NSLocalizedString(@"Change presence",nil)                                 delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                     destructiveButtonTitle:nil
                                     otherButtonTitles:NSLocalizedString(@"Online",nil),NSLocalizedString(@"Offline",nil),NSLocalizedString(@"Busy",nil),nil];
            action.tag = ChangePresenceTag;
            
            [action showInView:[[UIApplication sharedApplication] keyWindow]];
            [action release];
        }
        else{
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change presence",nil)   message:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Online",nil),NSLocalizedString(@"Offline",nil),NSLocalizedString(@"Busy",nil),nil];
            
            
            
            
            alert.tag = PresenceTag;
            // Pop UIAlertView
            
            [alert show];
            
        }
        
        
    }
       else if(actionSheet.tag == AddFriendTag && buttonIndex ==0){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add friend",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Add",nil), nil];
        
        
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        
        [alert textFieldAtIndex:0].placeholder = @"Example@azblink.com";
        [alert textFieldAtIndex:1].placeholder = NSLocalizedString(@"Alias",nil);
        [alert textFieldAtIndex:1].secureTextEntry = NO;
        alert.tag=AddTag;
        // Pop UIAlertView
        
        [alert show];
        
    }
 
    else if(actionSheet.tag ==RemoveTag && buttonIndex ==0){
        
        XMPPJID *xmppjid = [XMPPJID jidWithString:actionSheet.title];
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unsubscribed" to:[xmppjid bareJID]];
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:presence];
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"jid" stringValue:[xmppjid bare]];
        [item addAttributeWithName:@"subscription" stringValue:@"remove"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
        [iq addChild:query];
        
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:iq];
        
        NSString *path = [NSString stringWithFormat:@"%@/Documents/BLACKLIST.plist",NSHomeDirectory()];
        NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
        NSMutableArray *list =[plist objectForKey:@"List"];
      
          
            [list addObject:actionSheet.title];
            [plist setValue:list forKey:@"List"];
            [plist writeToFile:path atomically:YES];

        
        [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement:iq];
         
    }
    else if(actionSheet.tag ==RemoveTag && buttonIndex ==1){
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessageEntity" inManagedObjectContext:appDelegate.managedObjectContext];
        
        NSPredicate *predicates = [NSPredicate predicateWithFormat:@"sender.name=%@ || receiver.name=%@ ",actionSheet.title,actionSheet.title];
        [fetchRequest setPredicate:predicates];
        [fetchRequest setEntity:entity];
        NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        
        
        for (NSManagedObject *managedObject in items) {
            [appDelegate.managedObjectContext deleteObject:managedObject];
        }
        [appDelegate saveContext];
        
        [DataTable reloadData];
        
        
    }
  
       else if(actionSheet.tag == ChangePresenceTag){
        if(buttonIndex ==2){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"dnd"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Busy"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
           
            
            [self setpresence:[UIImage imageNamed:@"led_inprogress"]];
            [self setpresencetext:@"Busy"];
          
        }
        else if(buttonIndex ==1){
            XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
          
            [self setpresence:[UIImage imageNamed:@"led_disconnected"]];
            [self setpresencetext:@"Offline"];
        }
        else if(buttonIndex ==0){
            
            XMPPPresence *presence = [XMPPPresence presence];
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
              
           
            [self setpresence:[UIImage imageNamed:@"led_connected"]];
            [self setpresencetext:@"Online"];
        }
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (IS_IPHONE)
    {
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        CGSize sacleSize = CGSizeMake(40, 40);
        UIGraphicsBeginImageContextWithOptions(sacleSize, NO, 0.0);
        [chosenImage drawInRect:CGRectMake(0, 0, sacleSize.width, sacleSize.height)];
        
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [[self.view viewWithTag:3] removeFromSuperview];
        UIImageView *imageview = [[UIImageView alloc]initWithImage:chosenImage];
        [imageview setTag:3];
        [self.view addSubview:imageview];
        
        NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:
                                  @"vcard-temp"];
        NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
        NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"
                                                  stringValue:@"image/jpeg"];
        
        
        UIImageJPEGRepresentation(image, 0.7f);
        NSData *dataFromImage =UIImagePNGRepresentation(image);
        NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL"
                                                    stringValue:[dataFromImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        [photoXML addChild:typeXML];
        [photoXML addChild:binvalXML];
        [vCardXML addChild:photoXML];
        XMPPvCardTemp *myvCardTemp = [[[self appDelegate] xmppvCardTempModule]
                                      myvCardTemp];
        if (myvCardTemp) {
            [myvCardTemp setPhoto:dataFromImage];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :myvCardTemp];
        }
        else{
            XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement
                                           :vCardXML];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :newvCardTemp];
        }
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
        
    }
    else{
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        CGSize sacleSize = CGSizeMake(80, 80);
        UIGraphicsBeginImageContextWithOptions(sacleSize, NO, 0.0);
        [chosenImage drawInRect:CGRectMake(0, 0, sacleSize.width, sacleSize.height)];
        
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [[self.view viewWithTag:3] removeFromSuperview];
        UIImageView *imageview = [[UIImageView alloc]initWithImage:chosenImage];
        [imageview setTag:3];
        [self.view addSubview:imageview];
        
        NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:
                                  @"vcard-temp"];
        NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
        NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"
                                                  stringValue:@"image/jpeg"];
        
        
        UIImageJPEGRepresentation(image, 0.7f);
        NSData *dataFromImage =UIImagePNGRepresentation(image);
        NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL"
                                                    stringValue:[dataFromImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        [photoXML addChild:typeXML];
        [photoXML addChild:binvalXML];
        [vCardXML addChild:photoXML];
        XMPPvCardTemp *myvCardTemp = [[[self appDelegate] xmppvCardTempModule]
                                      myvCardTemp];
        if (myvCardTemp) {
            [myvCardTemp setPhoto:dataFromImage];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :myvCardTemp];
        }
        else{
            XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement
                                           :vCardXML];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :newvCardTemp];
        }
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
        
        
    }
}





- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //let tableview can be edit.
    return YES;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    //swip left to delete or modify row.
    switch (index) {
        case 0:
            NSLog(@"button pressed");
            NSIndexPath *cellIndexPath = [DataTable indexPathForCell:cell];
            XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:cellIndexPath];
            
            NSRange tRange = [user.jidStr rangeOfString:@"@conference"];
            if([user.displayName isEqualToString:@" System"]){
               
            }
            else if(tRange.location == NSNotFound){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:user.jidStr   message:NSLocalizedString(@"Enter alias",nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                      otherButtonTitles:NSLocalizedString(@"Edit",nil), nil];
                
                
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                
                
                alert.tag =EditAliasTag;
                // Pop UIAlertView
                
                [alert show];
            }
            break;
        case 1:
        {
            if(! [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isAuthenticated]){
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
                
                
                
                alert.tag = ReconnectTag;
                [alert show];
            }
            else{
            NSIndexPath *cellIndexPath = [DataTable indexPathForCell:cell];
            XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:cellIndexPath];
            NSRange tRange = [user.jidStr rangeOfString:@"@conference"];
            
            if([user.displayName isEqualToString:@" System"]){
               
            }
            else if(tRange.location == NSNotFound){
                UIActionSheet *action = [[UIActionSheet alloc]
                                         initWithTitle:user.jidStr
                                         delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Delete user",nil),NSLocalizedString(@"Delete message history",nil),nil];
                action.tag = RemoveTag;
                if (IS_IPHONE)
                {
                    [action showInView:[[UIApplication sharedApplication] keyWindow]];
                    
                }
                else{
                    [action showInView:self.view];
                    
                }
                [action release];
                
                
            }
            else{
                UIActionSheet *action = [[UIActionSheet alloc]
                                         initWithTitle:user.jidStr
                                         delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Leave conference",nil),NSLocalizedString(@"Destroy conference",nil),nil];
                action.tag = 4;
                if (IS_IPHONE)
                {
                    [action showInView:[[UIApplication sharedApplication] keyWindow]];
                    
                }
                else{
                    [action showInView:self.view];
                    
                }
                [action release];
                
                
                
                
            }
            break;
        }
        default:
            break;
        }
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[self.view viewWithTag:1] removeFromSuperview];
    [[self.view viewWithTag:2] removeFromSuperview];
  
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Presence" object:nil];
    [[[LinphoneAppDelegate sharedAppDelegate]xmppvCardTempModule]removeDelegate:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



-(void)refresh{
 
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream ]disconnect];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppvCardTempModule] removeDelegate:self];
        [[[LinphoneAppDelegate sharedAppDelegate]xmppRosterStorage]clearAllUsersAndResourcesForXMPPStream:[[LinphoneAppDelegate sharedAppDelegate]xmppStream]];
        [[LinphoneAppDelegate sharedAppDelegate] connect];
        
        
        
        
        [DataTable reloadData];
        
        [self updatestate];
        
        [self.refreshControl endRefreshing];
        
    });
}
-(void)updatestate{
    sleep(1);
    if([[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isConnected]){
        
        [self loadView];
        [self getPersonArray];
        [self setpresence:[UIImage imageNamed:@"led_connected"]];
        [self setpresencetext:@"Online"];
        
        
        [DataTable reloadData];
    }
    else{
        [self setpresence:[UIImage imageNamed:@"led_error"]];
        [self setpresencetext:@"Disconnect"];
    }
    [[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription]];
    [[PhoneMainView instance] changeCurrentView:[RootViewController compositeViewDescription]];

}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[PersonEntity class]]) {
        PersonEntity *personEntity = (PersonEntity*)anObject;
        if (type==NSFetchedResultsChangeInsert) {
            [personArray addObject:personEntity];
            
            [DataTable reloadData];
            [self.view addSubview:DataTable];
            
            
        }else if (type==NSFetchedResultsChangeUpdate) {
            
            [DataTable reloadData];
            [self.view addSubview:DataTable];
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
    
    [DataTable reloadData];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewCell helpers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.layer.cornerRadius = 50.00000/ 2.0f;
    
    
    
}
- (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
    // Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
    // We only need to ask the avatar module for a photo, if the roster doesn't have it.
    
    if (user.photo != nil)
    {
        
        CGSize size = {50,50};
        cell.imageView.image =[self imageWithImage:user.photo scaledToSize:size];
        
        
    }
    
    
    else
    {
        NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        NSRange tRange = [user.displayName rangeOfString:@"@conference"];
        
        if (photoData != nil){
            CGSize size = {50,50};
            cell.imageView.image =[self imageWithImage:[UIImage imageWithData:photoData] scaledToSize:size];
            
            
        }
        else if (tRange.location != NSNotFound){
            
            CGSize size = {50,50};
            cell.imageView.image =[self imageWithImage:[UIImage imageNamed:@"conference"] scaledToSize:size];
            
        }
        else if ([user.displayName isEqualToString:@" System"]){
            CGSize size = {50,50};
            cell.imageView.image =[self imageWithImage:[UIImage imageNamed:@"System"] scaledToSize:size];
            user.photo =[self imageWithImage:[UIImage imageNamed:@"System"] scaledToSize:size];
        }
        else{
            
            CGSize size = {50,50};
            cell.imageView.image =[self imageWithImage:[UIImage imageNamed:@"defaultPerson"] scaledToSize:size];
            user.photo =[self imageWithImage:[UIImage imageNamed:@"defaultPerson"] scaledToSize:size];
        }
        
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    NSArray *sections =[fetchedResultsController sections];
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
        int section = [sectionInfo.name intValue];
        switch (section)
        {
            case 0  : return NSLocalizedString(@"Buddy",nil);
           
        }
    }
    
    return @"";
    
    
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    
    
    NSArray *sections = [fetchedResultsController sections];
    
    
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        return sectionInfo.numberOfObjects;
    }
    
    return 0;
    
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SWTableViewCell *cell = [DataTable dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cell"];
        
        UIImage *numImage = [[UIImage imageNamed:@"com_number_single"]stretchableImageWithLeftCapWidth:12 topCapHeight:12];
        UIImageView *numView = [[UIImageView alloc]initWithImage:numImage];
        numView.tag = kNumViewTag;
        [cell.contentView addSubview:numView];
        
        UIImage *onlineImage = [UIImage imageNamed:@"led_connected"];
        UIImageView *onlineView = [[UIImageView alloc]initWithImage:onlineImage];
        onlineView.tag = kOnlineTag;
        [cell.contentView addSubview:onlineView];
        
        UIImage *offlineImage = [UIImage imageNamed:@"led_disconnected"];
        UIImageView *offlineView = [[UIImageView alloc]initWithImage:offlineImage];
        offlineView.tag = kOfflineTag;
        [cell.contentView addSubview:offlineView];
        
        UIImage *busyImage = [UIImage imageNamed:@"led_inprogress"];
        UIImageView *busyView = [[UIImageView alloc]initWithImage:busyImage];
        busyView.tag = kBusyTag;
        [cell.contentView addSubview:busyView];
        
        UIImage *reject = [UIImage imageNamed:@"test_failed.png"];
        UIImageView*rejectView =[[UIImageView alloc]initWithImage:reject];
        rejectView.tag = kRejectTag;
        [cell.contentView addSubview:rejectView];
        
        UIImage *accept = [UIImage imageNamed:@"test_passed.png"];
        UIImageView*acceptView =[[UIImageView alloc]initWithImage:accept];
        acceptView.tag = kAcceptTag;
        [cell.contentView addSubview:acceptView];
        
        
        UILabel *numLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 20, 20, 20)];
        numLabel.backgroundColor = [UIColor clearColor];
        numLabel.font = [UIFont systemFontOfSize:14];
        numLabel.textColor = [UIColor whiteColor];
        numLabel.tag = kNumLabelTag;
        [numView addSubview:numLabel];
        
        
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
        
    }
    
    UIImageView *numView = (UIImageView*)[cell.contentView viewWithTag:kNumViewTag];
    numView.frame = CGRectMake(280,15,30,30);
    UILabel *numLabel = (UILabel*)[numView viewWithTag:kNumLabelTag];
    numLabel.frame = CGRectMake(5,7,20,15);
    
    UIImageView *onlineView = (UIImageView*)[cell.contentView viewWithTag:kOnlineTag];
    UIImageView *offlineView = (UIImageView*)[cell.contentView viewWithTag:kOfflineTag];
    UIImageView *busyView = (UIImageView*)[cell.contentView viewWithTag:kBusyTag];
    UIImageView *rejectView =(UIImageView*)[cell.contentView viewWithTag:kRejectTag];
    UIImageView *acceptView =(UIImageView*)[cell.contentView viewWithTag:kAcceptTag];
   
    if(IS_IPAD){
        onlineView.frame = CGRectMake(120,40,15,15);
        offlineView.frame = CGRectMake(120,40,15,15);
        busyView.frame = CGRectMake(120,40,15,15);
        rejectView.frame = CGRectMake(180, 40, 15, 15);
        acceptView.frame = CGRectMake(200, 40, 15, 15);
        rejectView.hidden =YES;
        acceptView.hidden =YES;
       
    }
    else{
        onlineView.frame = CGRectMake(90,40,15,15);
        offlineView.frame = CGRectMake(90,40,15,15);
        busyView.frame = CGRectMake(90,40,15,15);
        rejectView.frame = CGRectMake(150, 40, 15, 15);
        acceptView.frame = CGRectMake(170, 40, 15, 15);
        rejectView.hidden =YES;
        acceptView.hidden =YES;
    }
    
    
    
    XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:indexPath];
  
    if([user.subscription isEqualToString:@"none"] && ![user.ask isEqualToString:@"subscribe"]){
        
        rejectView.hidden =NO;
        acceptView.hidden =NO;
    }
    
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    friendEntity =[appDelegate fetchPerson:user.jidStr];
    NSArray *sendedMessageArray = [friendEntity.sendedMessages allObjects];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    
    sendedMessageArray = [sendedMessageArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    sendedMessageArray = [sendedMessageArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(flag_readed == %@)", [NSNumber numberWithBool:NO]]];
    
    
    NSString *numStr = [NSString stringWithFormat:@"%lu",(unsigned long)sendedMessageArray.count];
    
    numLabel.text = numStr;
    numLabel.textAlignment = NSTextAlignmentCenter;
    
    NSRange tRange = [user.displayName rangeOfString:@"@conference"];
    if (tRange.location == NSNotFound){
        
        cell.textLabel.text = user.displayName;
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    }
    else {
        NSRange search = [user.displayName  rangeOfString:@"@"];
        
        NSString *room = [user.displayName substringToIndex:search.location];
        
        cell.textLabel.text =[room stringByAppendingString:@"@Conference"];
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    }
    
    NSArray *msg = [friendEntity.sendedMessages allObjects];
    msg = [msg filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(receiver.name== %@)", [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]]];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    msg = [msg sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    MessageEntity *lastMessageEntity = [msg lastObject];
    if(lastMessageEntity.content ==nil){
        cell.detailTextLabel.text =@" ";
        [cell.detailTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    }
    else{
        NSString *detail = [@"       " stringByAppendingString:lastMessageEntity.content];
        cell.detailTextLabel.text = detail;
        [cell.detailTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    }
   
    if(user.section == 0){
        onlineView.hidden =NO;
        busyView.hidden =YES;
        offlineView.hidden =YES;
        cell.textLabel.textColor =[UIColor blackColor];
        if([user.displayName isEqualToString:@" System"]){
            onlineView.hidden =YES;
            cell.textLabel.textColor =[UIColor redColor];
        }
        
    }
    else if(user.section ==1){
        onlineView.hidden =YES;
        busyView.hidden =NO;
        offlineView.hidden =YES;
        cell.textLabel.textColor =[UIColor blackColor];
        
    }
    else if(user.section ==2){
        onlineView.hidden =YES;
        busyView.hidden =YES;
        offlineView.hidden =NO;
        cell.textLabel.textColor =[UIColor blackColor];
        if([user.displayName isEqualToString:@" System"]){
            user.section =0;
        }
        else if([user.subscription isEqualToString:@"none"]){
            [user setSection:3];
        }
    }
    else if(user.section ==3){
        onlineView.hidden =YES;
        busyView.hidden =YES;
        offlineView.hidden =YES;
        cell.textLabel.textColor =[UIColor grayColor];
        if(![user.subscription isEqualToString:@"none"]){
            [user setSection:0];
        }
    }

   
    
    
    if([numStr isEqualToString:@"0"]){
        [numView setHidden:YES];
    }
    else {
        [numView setHidden:NO];
    }
    
   [self configurePhotoForCell:cell user:user];
    
    return cell;
    
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:NSLocalizedString(@"Edit",nil)];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:NSLocalizedString(@"Delete",nil)];
    
    return rightUtilityButtons;
}
-(void)PresenceNotify:(NSNotification *)notif
{
    NSLog(@"Notify is coming...");
    NSXMLElement *queryElement = [NSXMLElement elementWithName: @"query" xmlns: @"jabber:iq:roster"];
    NSXMLElement *iqStanza = [NSXMLElement elementWithName: @"iq"];
    [iqStanza addAttributeWithName: @"type" stringValue: @"get"];
    [iqStanza addChild: queryElement];
    [[[LinphoneAppDelegate sharedAppDelegate]xmppStream] sendElement: iqStanza];

    [DataTable reloadData];
}
-(void)populateArray1:(NSNotification *)notif
{
    
    NSMutableArray *array =[notif object];
    NSArray *password = [array objectAtIndex:7];
    NSString * resultString = [[password valueForKey:@"description"] componentsJoinedByString:@""];
    NSRange tRange = [resultString rangeOfString:@"passwordprotected"];
    if(tRange.location ==NSNotFound){
        XMPPPresence *presence = [XMPPPresence presence];
        
        [presence addAttributeWithName:@"to" stringValue:friendentity.jidStr];
        [presence addAttributeWithName:@"type" stringValue:@"unavailable"];
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
        
        NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        sleep(0.5);
        
        
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
          
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage
                                                               jid:friendentity.jid
                                                     dispatchQueue:dispatch_get_main_queue()];
        [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate]xmppStream]];
        [xmppRoom joinRoomUsingNickname:nickname
                                history:nil
                               password:nil];
        ChatController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatController compositeViewDescription] push:TRUE], ChatController);
        [controller setFriendEn:friendentity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
        
    }
    else{
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:fullroomjid
                                                        message:NSLocalizedString(@"Enter the password",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        
        
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        alert.tag=PasswordTag;
        // Pop UIAlertView
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
        
        [alert show];
        
    }
    
}
-(void)populateArray2:(NSNotification *)notif
{
    
    
    
    NSMutableArray *array =[notif object];
    if(array.count ==0){
        
        count++;
        if(count>3){
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"errorArray" object:nil];
            count =0;
            ChatController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatController compositeViewDescription] push:TRUE], ChatController);
            [controller setFriendEn:friendentity];
        }
    }
    else if(array.count>0){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Incorrect password",nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        
        
        
        
        
        [alert show];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"errorArray" object:nil];
        
        
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    
    XMPPUserCoreDataStorageObject *friendEntity1 = [fetchedResultsController objectAtIndexPath:indexPath];
    if([friendEntity1.subscription isEqualToString:@"none"] && ![friendEntity1.ask isEqualToString:@"subscribe"]){
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Add friend",nil) message:friendEntity1.jidStr delegate:self cancelButtonTitle:NSLocalizedString(@"Decline",nil) otherButtonTitles:NSLocalizedString(@"Accept",nil),  nil];
        
        alert.tag = RequestTag;
        [alert show];
    }
   

    
    else{
    NSRange tRange = [friendEntity1.jidStr rangeOfString:@"@conference"];
    
    if (tRange.location == NSNotFound){
        
        ChatController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatController compositeViewDescription] push:TRUE], ChatController);
        [controller setFriendEn:friendEntity1];
        
        
    }
    else{
        
        
        if(![[[LinphoneAppDelegate sharedAppDelegate]xmppStream]isConnected]){
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
            
            alert.tag = ReconnectTag;
            [alert show];
        }
        else{
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            NSString *roomid =friendEntity1.jidStr;
            
            XMPPJID *servrJID = [XMPPJID jidWithString:roomid];
            XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:servrJID];
            
            [iq addAttributeWithName:@"from" stringValue:selfUserName];
            
            NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
            [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#info"];
            [iq addChild:query];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
            friendentity =friendEntity1;
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray1:) name:@"getRosterArray" object:nil];
            
            
            
            
            
            
            
            
            
        }
    }
    }
    
}


@end
