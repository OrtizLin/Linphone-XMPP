//  ChatController.m


#import "AFNetworking.h"
#import "ChatController.h"
#import "MessageEntity.h"
#import "PhoneMainView.h"
#import "LinphoneAppDelegate.h"

#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone

#define kBallonImageViewTag 100
#define kChatContentLabelTag 101
#define kDateLabelTag 102
#define kLoadingViewTag 103
#define sender_name 104
#define sender_photo 105
#define sender_date 106
#define kSendfailViewTag 107
#define kTextViewTag 108
#define kPhotoView 109
#define kReceiptViewTag 110




@implementation ChatController{
    
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    UIView *background;
    
}

#pragma mark - View lifecycle





@synthesize friendEn;

static UICompositeViewDescription *compositeDescription = nil;



+ (UICompositeViewDescription *)compositeViewDescription {
    
    if(compositeDescription == nil) {
        
        compositeDescription = [[UICompositeViewDescription alloc] init:@"ChatRoom"
                                
                                                                content:@"ChatController"
                                
                                                               stateBar:nil
                                
                                                        stateBarEnabled:false
                                
                                                                 tabBar:/*@"UIMainBar"*/nil
                                
                                                          tabBarEnabled:false /*to keep room for chat*/
                                
                                                             fullscreen:false
                                
                                                          landscapeMode:false
                                
                                                           portraitMode:true];
        
        
        
    }
    
    return compositeDescription;
    
}

- (LinphoneAppDelegate *)appDelegate

{
    
    return (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];

    

    timeinterval =86400.0;
    
   
  if(firstTime == true){
        
    
    
        _displayname.text = friendEn.jidStr;
        _displayname.textColor= [UIColor blueColor];
       
//get the latest message.
      
        LinphoneAppDelegate *appDelegates = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        
        NSPredicate *predicates = [NSPredicate predicateWithFormat:@"sender.name=%@ || receiver.name=%@ ",_displayname.text,_displayname.text];
        NSFetchRequest *fetechRequests = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
        
        [fetechRequests setPredicate:predicates];
        NSSortDescriptor *sortDescs = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:NO];
        
        [fetechRequests setSortDescriptors:[NSArray arrayWithObject:sortDescs]];
        
        [fetechRequests setFetchLimit:1];
        
        NSFetchedResultsController*hellofetch = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequests
                                                 
                                                                                   managedObjectContext:appDelegates.managedObjectContext
                                                 
                                                                                     sectionNameKeyPath:nil cacheName:nil];
        hellofetch.delegate = self;
        
        [hellofetch performFetch:NULL];
        
        NSArray *contentArrays = [hellofetch fetchedObjects];
        
        MessageEntity*hoho = [contentArrays lastObject];
        
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        
        NSInteger interval = [zone secondsFromGMTForDate: hoho.sendDate];
        
        NSDate *localDate = [hoho.sendDate  dateByAddingTimeInterval: interval];

     
        
        _displayname.textAlignment = NSTextAlignmentCenter;
      
        
        
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        
        
        selfEntity = [appDelegates fetchPerson:selfUserName];
        
        friendEntity =[appDelegates fetchPerson:friendEn.jidStr];
        
        
                NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
        
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        
                NSString *currenttime = [dateFormat stringFromDate:[NSDate date]];
                NSDate *endDate =[dateFormat dateFromString:currenttime];
        hellofetch.delegate =nil;
        if(localDate == nil){
            NSDate *startDate = [endDate dateByAddingTimeInterval: -timeinterval];
            NSDate *currentDate = [endDate dateByAddingTimeInterval: timeinterval];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender.name=%@ || receiver.name=%@) AND (sendDate >= %@) AND (sendDate <= %@)",_displayname.text,_displayname.text,startDate,currentDate];
            
            NSFetchRequest *fetechRequest = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
            
            [fetechRequest setPredicate:predicate];
            
            NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
            
            [fetechRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
            
            [fetechRequest setFetchBatchSize:50];
            
            
            
            fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequest
                               
                                                                 managedObjectContext:appDelegates.managedObjectContext
                               
                                                                   sectionNameKeyPath:nil cacheName:nil];
            
            
            fetchController.delegate = self;
            
            [fetchController performFetch:NULL];
            
            
            NSArray *contentArray = [fetchController fetchedObjects];
            
            messageArray = [[NSMutableArray alloc]init];
            
            for (NSInteger i=0; i<contentArray.count; i++) {
                
                
                
                MessageEntity *messageEntity = [contentArray objectAtIndex:i];
                
                
                
                NSDate *messageDate = messageEntity.sendDate;
                
                
                
                if (i==0) {
                    
                    
                    
                    [messageArray addObject:messageDate];
                    
                    
                    
                }else {
                    
                    
                    
                    
                    
                    MessageEntity *previousEntity = [contentArray objectAtIndex:i-1];
                    
                    
                    
                    
                    
                    NSTimeInterval timeIntervalBetween = [messageDate timeIntervalSinceDate:previousEntity.sendDate];
                    
                    
                    
                    
                    
                    if (timeIntervalBetween>15*60) {
                        
                        
                        
                        [messageArray addObject:messageDate];
                        
                    }
                }
                [messageArray addObject:messageEntity];
                
            }
        }
        else{
                NSDate *startDate = [localDate dateByAddingTimeInterval: -timeinterval];
                NSDate *currentDate = [endDate dateByAddingTimeInterval: timeinterval];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender.name=%@ || receiver.name=%@) AND (sendDate >= %@) AND (sendDate <= %@)",_displayname.text,_displayname.text,startDate,currentDate];
            
            NSFetchRequest *fetechRequest = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
            
            [fetechRequest setPredicate:predicate];
            
            NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
            
            [fetechRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
            
            [fetechRequest setFetchBatchSize:50];
            
            
            
            fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequest
                               
                                                                 managedObjectContext:appDelegates.managedObjectContext
                               
                                                                   sectionNameKeyPath:nil cacheName:nil];
            
            
            fetchController.delegate = self;
            
            [fetchController performFetch:NULL];
            
            
            NSArray *contentArray = [fetchController fetchedObjects];
            
            messageArray = [[NSMutableArray alloc]init];
            
            for (NSInteger i=0; i<contentArray.count; i++) {
                
                
                
                MessageEntity *messageEntity = [contentArray objectAtIndex:i];
                
                
                
                NSDate *messageDate = messageEntity.sendDate;
                
                
                
                if (i==0) {
                    
                    
                    
                    [messageArray addObject:messageDate];
                    
                    
                    
                }else {
                    
                    
                    
                    
                    
                    MessageEntity *previousEntity = [contentArray objectAtIndex:i-1];
                    
                    
                    
                    
                    
                    NSTimeInterval timeIntervalBetween = [messageDate timeIntervalSinceDate:previousEntity.sendDate];
                    
                    
                    
                    
                    
                    if (timeIntervalBetween>15*60) {
                        
                        
                        
                        [messageArray addObject:messageDate];
                        
                    }
                }
                [messageArray addObject:messageEntity];
                
            }
        }
 

       
        
        
        
        
        [DataTable reloadData];
        
        if (messageArray.count>0) {
            
            [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
             
                             atScrollPosition:UITableViewScrollPositionBottom
             
                                     animated:NO];
            
        }
      
      CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
      CGFloat screenwidth =[UIScreen mainScreen].applicationFrame.size.width;
      
      if (IS_IPHONE){
          
          //locationbutton
          
          locationbutton = [UIButton buttonWithType:UIButtonTypeCustom];
          
          locationbutton.frame = CGRectMake((screenwidth/2)-44, screenHeight-88, 90, 88);
          
          [locationbutton addTarget:self
                             action:@selector(locationButtonClick:)
                   forControlEvents:UIControlEventTouchUpInside];
          
          NSString *geoloc = [[LinphoneManager instance] lpConfigStringForKey:@"geoloc_preference"];
          
          if([geoloc isEqualToString:@"1"]){
              UIImage *btn2Image = [UIImage imageNamed:@"location.png"];
              [locationbutton setImage:btn2Image forState:UIControlStateNormal];
          }
          
          else if([geoloc isEqualToString:@"0"] ||geoloc ==nil){
              UIImage *btn2Image = [UIImage imageNamed:@""];
              [locationbutton setImage:btn2Image forState:UIControlStateNormal];
          }
          
          
          [self.view addSubview:locationbutton];
          
          
          
          //camerabutton
          
          camerabutton = [UIButton buttonWithType:UIButtonTypeCustom];
          
          camerabutton.frame = CGRectMake(10, screenHeight-90, 90, 89);
          
          [camerabutton addTarget:self
           
           action:@selector(cameraButtonClick:)
           
           forControlEvents:UIControlEventTouchUpInside];
          
          NSString *xmppfile = [[LinphoneManager instance] lpConfigStringForKey:@"xmppfile_preference"];
          if([xmppfile isEqualToString:@"1"]){
              UIImage *btn1Image = [UIImage imageNamed:@"camera.png"];
              
              [camerabutton setImage:btn1Image forState:UIControlStateNormal];
          }
          else if([xmppfile isEqualToString:@"0"] ||xmppfile ==nil){
              UIImage *btn1Image = [UIImage imageNamed:@""];
              
              [camerabutton setImage:btn1Image forState:UIControlStateNormal];
          }
          [self.view addSubview:camerabutton];
          
          
          [camerabutton setHidden:YES];
          
          [locationbutton setHidden:YES];
          
          
          
          
          
      }
      
      else{
          
          //locationbutton_ipad
          
          locationbutton = [UIButton buttonWithType:UIButtonTypeCustom];
          
          locationbutton.frame = CGRectMake((screenwidth/2)-44, screenHeight-88, 90, 88);
          
          [locationbutton addTarget:self
                             action:@selector(locationButtonClick:)
                   forControlEvents:UIControlEventTouchUpInside];
          
          NSString *geoloc = [[LinphoneManager instance] lpConfigStringForKey:@"geoloc_preference"];
          if([geoloc isEqualToString:@"1"]){
              UIImage *btn2Image = [UIImage imageNamed:@"location.png"];
              
              [locationbutton setImage:btn2Image forState:UIControlStateNormal];
          }
          else if([geoloc isEqualToString:@"0"] ||geoloc ==nil){
              UIImage *btn2Image = [UIImage imageNamed:@""];
              
              [locationbutton setImage:btn2Image forState:UIControlStateNormal];
          }
          
          [self.view addSubview:locationbutton];
          
          
          
          //camerabutton
          
          camerabutton = [UIButton buttonWithType:UIButtonTypeCustom];
          
          camerabutton.frame = CGRectMake(10, screenHeight-90, 90, 89);
          
          [camerabutton addTarget:self
           
           
           
                           action:@selector(cameraButtonClick:)
           
           
           
                 forControlEvents:UIControlEventTouchUpInside];
          NSString *xmppfile = [[LinphoneManager instance] lpConfigStringForKey:@"xmppfile_preference"];
          
          if([xmppfile isEqualToString:@"1"]){
              UIImage *btn1Image = [UIImage imageNamed:@"camera.png"];
              
              [camerabutton setImage:btn1Image forState:UIControlStateNormal];
          }
          else if([xmppfile isEqualToString:@"0"] ||xmppfile ==nil){
              UIImage *btn1Image = [UIImage imageNamed:@""];
              
              [camerabutton setImage:btn1Image forState:UIControlStateNormal];
          }
          
          
          
          
          [self.view addSubview:camerabutton];
          
          
          [camerabutton setHidden:YES];
          
          [locationbutton setHidden:YES];
          
          
    }

        firstTime = false; //to make viewdidappear just run once by otis.
        
    }
    
    
    
}



-(void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    
    PersonEntity *senderUserEntity = [appDelegate fetchPerson:_displayname.text];
    
    
    NSManagedObjectContext *context = nil;
    
    
    
    id delegate = [[UIApplication sharedApplication] delegate];
    
    
    
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        
        
        
        context = [delegate managedObjectContext];
        
        
        
    }
    
    NSFetchRequest *fetch =[[NSFetchRequest alloc]init];
    
    
    
    NSEntityDescription * entity =[NSEntityDescription entityForName:@"MessageEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    
    
    
    [fetch setEntity:entity];
    
    
    
    NSPredicate *predicate =[NSPredicate  predicateWithFormat:@"sender ==%@ and flag_readed == %@",senderUserEntity,[NSNumber numberWithBool:NO]];
    
    
    
    [fetch setPredicate:predicate];
    
    
    
    NSArray *all = [appDelegate.managedObjectContext executeFetchRequest:fetch error:nil];
    
    
    
    
    
    if(all.count ==0){
        
        
        NSLog(@"no unread message %lu",(unsigned long)all.count);
        
    }
    
    
    
    else if (all.count !=0){
        
        
        
        for(int i =0 ;i<all.count ;i++){
            
            
            
            NSManagedObject *board = all[i];
            
            
            
            [board setValue:[NSNumber numberWithBool:YES] forKey:@"flag_readed"];
            
            
            
            [context save:nil];
            
             [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self userInfo:nil];
            
        }
        
        
        
        
        
        
        
    }
    CGRect inputFrame = inputContainer.frame;
    
    CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
    
    
    
    inputFrame.origin.y = screenHeight-55;
    
    [UIView animateWithDuration:0.2
     
                     animations:^{
                         
                         inputContainer.frame = inputFrame;
                         
                         
                         
                         CGRect tableFrame = DataTable.frame;
                         
                         tableFrame.size.height = inputFrame.origin.y-108;
                         
                         DataTable.frame = tableFrame;
                         
                     }completion:^(BOOL finish){
                         
                         if (messageArray.count>0) {
                             
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                              
                                              atScrollPosition:UITableViewScrollPositionBottom
                              
                                                      animated:YES];
                             
                         }
                         
                         
                         
                     }];
    
    
    
    [camerabutton setHidden:YES];
    
    [locationbutton setHidden:YES];
    
    [emailbutton setHidden:YES];
    
    fetchController.delegate = nil;
    
    firstTime = true; //to make viewdidappear just run once by otis.
    
    
    
}









- (void)viewDidLoad

{
    
    [super viewDidLoad];
    
    
    //pull down refresh.
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    [DataTable addSubview:self.refreshControl];
    
    
    
    firstTime = true; //to make viewdidappear just run once by otis.
    
    [self setUpForDismissKeyboard]; //dissmiss keyboard when touch the screen by otis.
    
    
    
    DataTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    
    // Do any additional setup after loading the view from its nib.
    
    
    
    if (IS_IPHONE)
    
    {
        
        inputContainer.userInteractionEnabled = YES;
        
        
        
        UIImage *chatBgImage = [UIImage imageNamed:@"ChatBar.png"];
        
        
        
        chatBgImage = [chatBgImage stretchableImageWithLeftCapWidth:18 topCapHeight:20];
        
        
        
        inputContainer.image = chatBgImage;
        
        
        
        inputView = [[UITextView alloc]initWithFrame:CGRectMake(40, 10, 220, 30)];
        
        
        
        inputView.delegate = self;
        
        
        
        inputView.backgroundColor = [UIColor clearColor];
        
        
        
        inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        
        
        inputView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        
        
        inputView.showsHorizontalScrollIndicator = NO;
        
        
        
        
        
        
        
        //inputView.returnKeyType = UIReturnKeyNext;
        
        
        
        [inputContainer addSubview:inputView];
        
        
        
        inputView.font = [UIFont systemFontOfSize:16];
        
        
        
        //inputView.contentStretch = uiviewcont
        
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        
        
        sendButton.frame = CGRectMake(270, 5, 40, 45);
        
        [sendButton addTarget:self
         
         
         
                       action:@selector(sendButtonClick:)
         
         
         
             forControlEvents:UIControlEventTouchUpInside];
        
        
        
        [sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        
        
        
        [inputContainer addSubview:sendButton];
        
        //Add "+" button.
        
        UIButton *optionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        
        
        optionButton.frame = CGRectMake(1, 2, 40, 45);
        
        [optionButton addTarget:self
         
         
         
                         action:@selector(optionButtonClick:)
         
         
         
               forControlEvents:UIControlEventTouchUpInside];
        
        
        
        [optionButton setTitle:NSLocalizedString(@"+", nil) forState:UIControlStateNormal];
        
        optionButton.titleLabel.font= [UIFont systemFontOfSize:50];
        
        [inputContainer addSubview:optionButton];
        
        
        
        CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
        
        
        
        CGFloat screenwidth =[UIScreen mainScreen].applicationFrame.size.width;
        
        
        
        //emailbutton
        
        emailbutton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        
        
        emailbutton.frame = CGRectMake(screenwidth-99, screenHeight-90, 90, 89);
        
        [emailbutton addTarget:self
         
         
         
                        action:@selector(emailButtonClick:)
         
         
         
              forControlEvents:UIControlEventTouchUpInside];
        
      
        UIImage *btn3Image = [UIImage imageNamed:@"email.png"];
        [emailbutton setImage:btn3Image forState:UIControlStateNormal];
        
        [self.view addSubview:emailbutton];
        
        [emailbutton setHidden:YES];
        
        
        
    }
    
    else{
        
        inputContainer.userInteractionEnabled = YES;
        
        
        
        UIImage *chatBgImage = [UIImage imageNamed:@"ChatBar.png"];
        
        
        
        chatBgImage = [chatBgImage stretchableImageWithLeftCapWidth:90 topCapHeight:20];
        
        
        
        inputContainer.image = chatBgImage;
        
        
        
        inputView = [[UITextView alloc]initWithFrame:CGRectMake(40, 10, 660, 30)];
        
        
        
        inputView.delegate = self;
        
        
        
        inputView.backgroundColor = [UIColor clearColor];
        
        
        
        inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        
        
        inputView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        
        
        inputView.showsHorizontalScrollIndicator = NO;
        
        
        
        
        
        
        
        //inputView.returnKeyType = UIReturnKeyNext;
        
        
        
        [inputContainer addSubview:inputView];
        
        
        
        inputView.font = [UIFont systemFontOfSize:16];
        
        
        
        //inputView.contentStretch = uiviewcont
        
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        
        
        sendButton.frame = CGRectMake(715, 7, 40, 45);
        
        [sendButton addTarget:self
         
         
         
                       action:@selector(sendButtonClick:)
         
         
         
             forControlEvents:UIControlEventTouchUpInside];
        
        
        
        [sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        
        
        
        [inputContainer addSubview:sendButton];
        
        
        
        //Add "+" button.
        
        UIButton *optionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        
        
        optionButton.frame = CGRectMake(1, 2, 40, 45);
        
        [optionButton addTarget:self
         
         
         
                         action:@selector(optionButtonClick:)
         
         
         
               forControlEvents:UIControlEventTouchUpInside];
        
        
        
        [optionButton setTitle:NSLocalizedString(@"+", nil) forState:UIControlStateNormal];
        
        optionButton.titleLabel.font= [UIFont systemFontOfSize:50];
        
        
        
        [inputContainer addSubview:optionButton];
        
        
        
        CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
        
        
        
        CGFloat screenwidth =[UIScreen mainScreen].applicationFrame.size.width;
        
        
        
        //emailbutton
        
        emailbutton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        
        
        emailbutton.frame = CGRectMake(screenwidth-99, screenHeight-90, 90, 89);
        
        [emailbutton addTarget:self
         
         
         
                        action:@selector(emailButtonClick:)
         
         
         
              forControlEvents:UIControlEventTouchUpInside];
        
       
        //hide email.png by otis.
        UIImage *btn3Image = [UIImage imageNamed:@"email.png"];
        [emailbutton setImage:btn3Image forState:UIControlStateNormal];
        
        [self.view addSubview:emailbutton];
        
        
        
        
        [emailbutton setHidden:YES];
        
        
    }
    
    [[NSNotificationCenter defaultCenter]addObserver:self
     
     
     
                                            selector:@selector(keyboardWillShow:)
     
     
     
                                                name:UIKeyboardWillShowNotification
     
     
     
                                              object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self
     
     
     
                                            selector:@selector(keyboardWillHide:)
     
     
     
                                                name:UIKeyboardWillHideNotification
     
     
     
                                              object:nil];
    
    
    
}



-(void)refresh{
    
    int i;
    int j;

    j =messageArray.count;
    if(j ==0){
    [self.refreshControl endRefreshing];
    }
    else{
    i =timeinterval/86400.0f;
    timeinterval = 86400.0 *(i+1);
    
  
    fetchController.delegate = nil;
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
     NSString *currenttime = [dateFormat stringFromDate:[NSDate date]];
     NSDate *endDate =[dateFormat dateFromString:currenttime];
    

    

    
    NSPredicate *predicates = [NSPredicate predicateWithFormat:@"sender.name=%@ || receiver.name=%@",_displayname.text,_displayname.text];
    NSFetchRequest *fetechRequests = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
    
    [fetechRequests setPredicate:predicates];
    NSSortDescriptor *sortDescs = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:NO];
    
    [fetechRequests setSortDescriptors:[NSArray arrayWithObject:sortDescs]];
    
    [fetechRequests setFetchLimit:j+1];
    
    NSFetchedResultsController*hellofetch = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequests
                                             
                                                                               managedObjectContext:appDelegate.managedObjectContext
                                             
                                                                                 sectionNameKeyPath:nil cacheName:nil];
    hellofetch.delegate = self;
    
    [hellofetch performFetch:NULL];
    
    NSArray *contentArrays = [hellofetch fetchedObjects];
   
    MessageEntity*hoho = [contentArrays lastObject];
    
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    
    NSInteger interval = [zone secondsFromGMTForDate: hoho.sendDate];
    
    NSDate *localDate = [hoho.sendDate  dateByAddingTimeInterval: interval];
   
    if(localDate==nil){
       
        return;
    }
    else{
     hellofetch.delegate =nil;
     NSDate *startDate = [localDate dateByAddingTimeInterval: -timeinterval];
     NSDate *currentDate = [endDate dateByAddingTimeInterval: timeinterval];
     
     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender.name=%@ || receiver.name=%@) AND (sendDate >= %@) AND (sendDate <= %@)",_displayname.text,_displayname.text,startDate,currentDate];
     
     NSFetchRequest *fetechRequest = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
     
     [fetechRequest setPredicate:predicate];
     
     NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
     
     [fetechRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
     
     
     
     [fetechRequest setFetchBatchSize:50];
     
     fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequest
                        
                        
                        
                                                          managedObjectContext:appDelegate.managedObjectContext
                        
                                                            sectionNameKeyPath:nil cacheName:nil];
     
     fetchController.delegate = self;
     
     [fetchController performFetch:NULL];
     
     NSArray *contentArray = [fetchController fetchedObjects];
     
     messageArray = [[NSMutableArray alloc]init];
     
     for (NSInteger i=0; i<contentArray.count; i++) {
         
         MessageEntity *messageEntity = [contentArray objectAtIndex:i];
         
         NSDate *messageDate = messageEntity.sendDate;
         
         if (i==0) {
             
             [messageArray addObject:messageDate];
             
         }else {
             
             MessageEntity *previousEntity = [contentArray objectAtIndex:i-1];
             
             
             
             NSTimeInterval timeIntervalBetween = [messageDate timeIntervalSinceDate:previousEntity.sendDate];
             
             
             
             if (timeIntervalBetween>15*60) {
                 
                 [messageArray addObject:messageDate];
                 
             }
             
         }
         
         [messageArray addObject:messageEntity];
         
     }
     
     [DataTable reloadData];
    if (messageArray.count > 10 && j!=0 && messageArray.count-j>0) {
    
        [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-j inSection:0]
         
                         atScrollPosition:UITableViewScrollPositionTop
         
                                 animated:NO];
        
    }
    else if(messageArray.count > 10 && j==0){
        [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
         
                         atScrollPosition:UITableViewScrollPositionBottom
         
                                 animated:NO];
        
    }
    }
    
    
    [self.refreshControl endRefreshing];
}
}

//dissmiss keyboard when touch the screen by otis.

- (void)setUpForDismissKeyboard {
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    UITapGestureRecognizer *singleTapGR =
    
    [[UITapGestureRecognizer alloc] initWithTarget:self
     
                                            action:@selector(tapAnywhereToDismissKeyboard:)];
    
    NSOperationQueue *mainQuene =[NSOperationQueue mainQueue];
    
    [nc addObserverForName:UIKeyboardWillShowNotification
     
                    object:nil
     
                     queue:mainQuene
     
                usingBlock:^(NSNotification *note){
                    
                    [self.view addGestureRecognizer:singleTapGR];
                    
                }];
    
    [nc addObserverForName:UIKeyboardWillHideNotification
     
                    object:nil
     
                     queue:mainQuene
     
                usingBlock:^(NSNotification *note){
                    
                    [self.view removeGestureRecognizer:singleTapGR];
                    
                }];
    
    
    
}



- (void)tapAnywhereToDismissKeyboard:(UIGestureRecognizer *)gestureRecognizer {
    
    
    
    [self.view endEditing:YES];
    
  
    
    
    
}







- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter]removeObserver:self
     
                                                   name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self
     
                                                   name:UIKeyboardWillHideNotification object:nil];
    
    
    
    [_displayname release];
    
    
    
    [super dealloc];
    
}



#pragma mark keybord

// Prepare to resize for keyboard.

- (void)keyboardWillShow:(NSNotification *)notification

{
    
    
    NSDictionary *userInfo = [notification userInfo];
    
    
    
    NSTimeInterval animationDuration;
    
    UIViewAnimationCurve animationCurve;
    
    
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    
    
    CGRect inputFrame = inputContainer.frame;
    
    
    
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-20;
    
    [UIView animateWithDuration:0
     
                     animations:^{
                         
                         inputContainer.frame = inputFrame;
                         
                         
                         
                         CGRect tableFrame = DataTable.frame;
                         
                         tableFrame.size.height = inputFrame.origin.y-108;
                         
                         DataTable.frame = tableFrame;
                         
                     }completion:^(BOOL finish){
                         
                         if (messageArray.count>0) {
                             
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                              
                                              atScrollPosition:UITableViewScrollPositionBottom
                              
                                                      animated:NO];
                             
                         }
                         
                         
                         
                     }];
    
    [camerabutton setHidden:YES];
    
    [locationbutton setHidden:YES];
    
    
}



// Expand textview on keyboard dismissal

- (void)keyboardWillHide:(NSNotification *)notification

{
    
    //NSLog(@"keyboardWillHide");
    
    NSDictionary *userInfo = [notification userInfo];
    
    
    
    // Get animation info from userInfo
    
    NSTimeInterval animationDuration;
    
    UIViewAnimationCurve animationCurve;
    
    
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    
    
    
    
    CGRect inputFrame = inputContainer.frame;
    
    
    
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-20;
    
    [UIView animateWithDuration:0
     
                     animations:^{
                         
                         inputContainer.frame = inputFrame;
                         
                         
                         
                         CGRect tableFrame = DataTable.frame;
                         
                         tableFrame.size.height = inputFrame.origin.y-108;
                         
                         DataTable.frame = tableFrame;
                         
                     }completion:^(BOOL finish){
                         
                         if (messageArray.count>0) {
                             
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                              
                                              atScrollPosition:UITableViewScrollPositionBottom
                              
                                                      animated:NO];
                             
                         }
                         
                     }];
    
    
    
    [emailbutton setHidden:YES];
    
    [camerabutton setHidden:YES];
    
    [locationbutton setHidden:YES];
    
    
    
}







- (void)textViewDidChange:(UITextView *)textView{
    
    
    if (inputView.contentSize.height< 50 && inputView.contentSize.height>29) {
        
        
        
        
        
    }else {
        
        
        inputView.scrollEnabled = YES;
        
        
        }
    
    
    
}





- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    
    
    
    
    if ([scrollView isKindOfClass:[UITextView class]]) {
        
        if (inputView.contentSize.height<50 && inputView.contentSize.height>29) {
            
            [inputView setContentOffset:CGPointMake(0, 6)];
            
        }
        
    }else {
        
    }
    
}

-(void)getLocation

{
   
    //turn off location button.
    
    location =true;
    
    self->locationManager = [[CLLocationManager alloc] init];
    
    self-> geocoder = [[CLGeocoder alloc] init];
    
    self->locationManager.delegate = self;
    
    locationManager.distanceFilter = 10;
   
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
   
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    
    if ([self->locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        
        [self->locationManager requestWhenInUseAuthorization];
        
    }
    
    [self->locationManager startUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error

{
    
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               
                               initWithTitle:NSLocalizedString(@"This user is not in your contact book",nil)
                               
                               message:NSLocalizedString(@"Add a contact?",nil)
                               
                               delegate:self
                               
                               cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                               
                               otherButtonTitles:NSLocalizedString(@"OK",nil),nil];
    
    
    errorAlert.tag =13;
    [errorAlert show];
    
}



- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations

{
   
    
    
   
    [geocoder reverseGeocodeLocation:[locations lastObject] completionHandler:^(NSArray *placemarks, NSError *error) {
        
        CLPlacemark *placemark = [placemarks lastObject];
       
        NSArray *lines = placemark.addressDictionary[ @"FormattedAddressLines"];
        
        NSString *addressString = [lines componentsJoinedByString:@"\n"];
        if(addressString ==nil){
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            
            
            
            [alert show];
        }
        else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:addressString message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"NO",nil) otherButtonTitles:NSLocalizedString(@"YES",nil),  nil];
       
        alert.tag = 11;
        NSArray *gps =[locations lastObject];
        NSString *gpsstr = [gps description];
        alert.accessibilityValue = gpsstr;
        [alert show];
        }
        
    } ];
    
    
    [self->locationManager stopUpdatingLocation];
    //turn on location button.
    location =false;
    
    
}


- (CLLocationCoordinate2D) geoCodeUsingAddress:(NSString *)addresss
{
    double latitude = 0, longitude = 0;
    
    
    NSString *time = [addresss substringWithRange:NSMakeRange(0, 19)];
    NSString *addresstr = [addresss substringFromIndex:22];
    NSString *addressstr2 = [addresstr substringWithRange:NSMakeRange(0,addresstr.length-1)];
    
    NSString *esc_addr =  [addresstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@", esc_addr];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }
    }

    
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    
    
    NSString *str1 =[time stringByAppendingString:@"|<+"];
    NSString *str2 =[str1 stringByAppendingString:[[NSNumber numberWithDouble:center.latitude] stringValue]];
    NSString *str3 =[str2 stringByAppendingString:@",+"];
    NSString *str4 =[str3 stringByAppendingString:[[NSNumber numberWithDouble:center.longitude]stringValue]];
    NSString *str5 =[str4 stringByAppendingString:@">"];
   
    NSXMLElement *bodys =[NSXMLElement elementWithName:@"body"];
   
    [bodys setStringValue:str5];
    NSXMLElement *messages = [NSXMLElement elementWithName:@"message"];
    NSRange tRanges = [_displayname.text rangeOfString:@"@conference"];
    
    if (tRanges.location == NSNotFound){
        [messages addAttributeWithName:@"type" stringValue:@"chat"];
    }
    else {
        [messages addAttributeWithName:@"type" stringValue:@"groupchat"];
    }
    [messages addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
    [messages addAttributeWithName:@"to" stringValue:_displayname.text];
    
    
    NSXMLElement *xmlns =[NSXMLElement elementWithName:@"locations"];
    [xmlns setXmlns:@"http://azfone.net/locations"];
    NSXMLElement *xmln =[NSXMLElement elementWithName:@"locations"];
    [xmln setStringValue:@"locations"];
    [xmlns addChild:xmln];
    [messages addChild:xmlns];
    [messages addChild:bodys];
    XMPPElementReceipt *receipts;
    [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:messages andGetReceipt:&receipts];
    
    if(addressstr2){
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    NSXMLElement *xmlnss =[NSXMLElement elementWithName:@"geoloc"];
    [xmlnss setXmlns:@"http://jabber.org/protocol/geoloc"];
    [body setStringValue:addressstr2];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
    
    if (tRange.location == NSNotFound){
        [message addAttributeWithName:@"type" stringValue:@"chat"];
    }
    
     else {
       [message addAttributeWithName:@"type" stringValue:@"groupchat"];
         NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
         NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
         [message addChild:myMsgLogic];
        
     }
    NSString *messageID=[[[LinphoneAppDelegate sharedAppDelegate]xmppStream] generateUUID];
    [message addAttributeWithName:@"id" stringValue:messageID];
    
    NSXMLElement *receipts = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
    [message addChild:receipts];
    
    [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
    
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    
    NSRange search = [selfUserName rangeOfString:@"@"];
    
    NSString *hostname = [selfUserName substringFromIndex:search.location+1];
    
    if([hostname isEqualToString:_displayname.text]){
        
        NSLog(@"can't send message to system.");
        
    }
    else{
       [message addAttributeWithName:@"to" stringValue:_displayname.text];
        
        [message addChild:xmlnss];
        [message addChild:body];
        
        NSLog(@"friendEntity.name:%@",_displayname.text);
        
        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        
        MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                        
                                        
                                        
                                                                     inManagedObjectContext:appDelegate.managedObjectContext];
        
        messageEntity.content = addressstr2;
        
        messageEntity.sendDate = [NSDate date];
        
        messageEntity.receipt = messageID;
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
        
        messageEntity.sender = senderUserEntity;
        
        [senderUserEntity addSendedMessagesObject:messageEntity];
        
        messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
        
        [appDelegate saveContext];
        
        
        XMPPElementReceipt *receipt;
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
        
       
        
        if ([receipt wait:20]) {
      
            [self performSelector:@selector(messageSendedDelay:)
             
                       withObject:messageEntity
             
                       afterDelay:0.5];
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message resend success ",nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            
            [alert show];
            
        }else {
            
            NSLog(@"sendedFail");
            
            [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
            
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message resend failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
            
            alert.tag =10;
            [alert show];
            
        }
        [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
         
                         atScrollPosition:UITableViewScrollPositionBottom
         
                                 animated:NO];
    }
    }
    return center;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
   
    if(chosenImage.size.width > chosenImage.size.height && chosenImage.size.width >5000.000000){
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   
                                   initWithTitle:NSLocalizedString(@"Can not send panorama photo!",nil)
                                   
                                   message:nil
                                   
                                   delegate:nil
                                   
                                   cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                   
                                   otherButtonTitles:nil];
        
        [errorAlert show];
    }
    else{
      
    NSString *intStr = [NSString stringWithFormat: @"%ld", (long)chosenImage.hash];

    NSData *imageData =UIImageJPEGRepresentation(chosenImage, 0.01);
    UIGraphicsEndImageContext();
    NSString *myJID = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
    NSRange search = [myJID rangeOfString:@"@"];
    NSString *jid = [myJID substringWithRange:NSMakeRange(0, search.location)];
    NSString *myPassword = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];
    
    NSString *xmppdomain = [[LinphoneManager instance] lpConfigStringForKey:@"xmppdomain_preference"];
    NSString *xmppdoamin2 = [@"http://" stringByAppendingString:xmppdomain];
    NSString *xmppdomain3 = [xmppdoamin2 stringByAppendingString:@":8082/mobilevpn/mobileUpload.php"];
    
    NSString *filename =[intStr stringByAppendingString:@".jpg"];
        
      //save to app document.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:filename];
        [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
        
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:xmppdomain3 parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[jid dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"acct"];
        
        [formData appendPartWithFormData:[myPassword dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"password"];
        
    
        [formData appendPartWithFileData:imageData
                                    name:@"imgFile"
                                fileName:filename mimeType:@"image/jpeg"];
       
   
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *filepath =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
     
        NSString *urlstring =[xmppdoamin2 stringByAppendingString:filepath];
        
        NSURL *url = [NSURL URLWithString:urlstring];
        
        NSString *content = NSLocalizedString(@"  Sent you a photo ! ",nil);
        
        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        
        MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                        
                                        
                                        
                                                                     inManagedObjectContext:appDelegate.managedObjectContext];
        
        
        
        
        
        NSString *newStr =[url absoluteString];
        messageEntity.image = newStr;
        
        messageEntity.content = content;
        
        messageEntity.sendDate = [NSDate date];
        
        NSString *messageID=[[[LinphoneAppDelegate sharedAppDelegate]xmppStream] generateUUID];
        
        messageEntity.receipt = messageID;
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
        
        messageEntity.sender = senderUserEntity;
        
        [senderUserEntity addSendedMessagesObject:messageEntity];
        
        messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
        
        [appDelegate saveContext];
        
        
        // send message to receiver.
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        
        [body setStringValue:content];
        
        NSXMLElement *xmlns =[NSXMLElement elementWithName:@"photo"];
        [xmlns setXmlns:@"http://azfone.net"];
        
        //[xmlns addAttributeWithName:@"url" stringValue:newStr];
        
        NSXMLElement *xmln =[NSXMLElement elementWithName:@"url"];
        
        [xmln setStringValue:newStr];
        
        [xmlns addChild:xmln];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        
        NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
        
        if (tRange.location == NSNotFound){
            
            
            
            [message addAttributeWithName:@"type" stringValue:@"chat"];
            
        }
        
        
        
        else {
            
            
            
            [message addAttributeWithName:@"type" stringValue:@"groupchat"];
            NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
            NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
            [message addChild:myMsgLogic];
            
            
            
        }
       
        
        [message addAttributeWithName:@"id" stringValue:messageID];
        
        NSXMLElement *receiptss = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [message addChild:receiptss];
        
        [message addAttributeWithName:@"id" stringValue:messageID];
        
        [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        
        [message addAttributeWithName:@"to" stringValue:_displayname.text];
        
        //[message addAttributeWithName:@"image" stringValue:newStr];
        
        [message addChild:body];
        
        [message addChild:xmlns];
        
        NSXMLElement *receipts = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [message addChild:receipts];
        
        XMPPElementReceipt *receipt;
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
        
        if ([receipt wait:20]) {
            
            
            
            
            [self performSelector:@selector(messageSendedDelay:)
             
                       withObject:messageEntity
             
                       afterDelay:0.5];
            
        }else {
            
            
            [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
            
            
            
            
            
            
            alert.tag =10;
            [alert show];
            
            
        }
        
        if(picker.view.tag ==2){
            [self getLocation];
                CGRect inputFrame = inputContainer.frame;
                
                CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
                
                inputFrame.origin.y = screenHeight-55;
                
                [UIView animateWithDuration:0.2
                 
                                 animations:^{
                                     
                                     inputContainer.frame = inputFrame;
                                     
                                     
                                     
                                     CGRect tableFrame = DataTable.frame;
                                     
                                     tableFrame.size.height = inputFrame.origin.y-108;
                                     
                                     DataTable.frame = tableFrame;
                                     
                                 }completion:^(BOOL finish){
                                     
                                     if (messageArray.count>0) {
                                         
                                         [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                          
                                                          atScrollPosition:UITableViewScrollPositionBottom
                                          
                                                                  animated:YES];
                                         
                                     }
                                     
                                     
                                 }];
            

        }
        
        [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
         
                         atScrollPosition:UITableViewScrollPositionBottom
         
                                 animated:NO];
        
        
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      
    }];

    
    }
    
  
    
   [picker dismissViewControllerAnimated:YES completion:NULL];


}



-(void)textButtonClick:(id)sender{
    
    
    UIButton *btn = (UIButton *)sender;
   
    NSString *text =btn.titleLabel.text;
    NSString *lastChar = [text substringFromIndex:[text length] - 1];
  
//text: 2016-01-01 12:05:11 + stirng.
//str: text substringFromIndex:22 -> string.
    __block NSString *str = [[NSString alloc]init];
    str = [text substringFromIndex:22];
 
    textArray= [[NSMutableArray alloc]init];
    NSDataDetector *addressDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeAddress error:nil];
    NSDataDetector *phoneDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:nil];
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    
    [phoneDetector enumerateMatchesInString:str options:kNilOptions range:NSMakeRange(0, [str length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSString *phonestr = [str substringWithRange:result.range];
        
      
        [textArray addObject:phonestr];
      
    }];
    
    [linkDetector enumerateMatchesInString:str options:kNilOptions range:NSMakeRange(0, [str length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *linkstr = [str substringWithRange:result.range];
        
        
        [textArray addObject:linkstr];
        
    }];
    
    [addressDetector enumerateMatchesInString:str options:kNilOptions range:NSMakeRange(0, [str length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSString *addresstr = [str substringWithRange:result.range];

       
        [textArray addObject:addresstr];
       
        
    }];
   
    for (id object in textArray) {
        str = [str stringByReplacingOccurrencesOfString:object withString:@""];
    }

  
   
    NSString *newString = [[str componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@" "];
   
    
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    NSArray *parts = [newString componentsSeparatedByCharactersInSet:whitespaces];
    NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
    newString = [filteredArray componentsJoinedByString:@" "];
  
    NSArray *listItems = [newString componentsSeparatedByString:@" "];
   
    [textArray addObjectsFromArray:listItems];
   
    if([lastChar isEqualToString:@" "] && textArray.count!= 0){
     
                    NSString *content = [btn.titleLabel.text substringWithRange:NSMakeRange(22, btn.titleLabel.text.length-23)];
        
                    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
                    [body setStringValue:content];
                    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
                    //need to show the type when send message to other devieces by otis.
                    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                    if (tRange.location == NSNotFound){
                        [message addAttributeWithName:@"type" stringValue:@"chat"];
                    }
                   else {
                        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
                       NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
                       NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
                       [message addChild:myMsgLogic];
                    }
                    [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        
        
                    NSString *messageID=[[[LinphoneAppDelegate sharedAppDelegate]xmppStream] generateUUID];
                    [message addAttributeWithName:@"id" stringValue:messageID];
        
                    NSXMLElement *receipts = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
                    [message addChild:receipts];
        
                    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
                    NSRange search = [selfUserName rangeOfString:@"@"];
        
                    NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        
        
        
                    if([hostname isEqualToString:_displayname.text]){
        
                        NSLog(@"can't send message to system.");
        
                    }
        
                    else{
        
                        [message addAttributeWithName:@"to" stringValue:_displayname.text];
                        [message addChild:body];
                        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        
                        MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
        
        
        
                                                                                     inManagedObjectContext:appDelegate.managedObjectContext];
        
        
        
                        messageEntity.content = content;
                        messageEntity.sendDate = [NSDate date];
        
                        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
                        PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
        
                        messageEntity.sender = senderUserEntity;
        
                        [senderUserEntity addSendedMessagesObject:messageEntity];
        
                        messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
        
                        [appDelegate saveContext];
        
                        XMPPElementReceipt *receipt;
        
                        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
        
                        if ([receipt wait:20]) {
        
                            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message resend success ",nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        
                            [alert show];
                            [self performSelector:@selector(messageSendedDelay:)
        
                                       withObject:messageEntity
        
                                       afterDelay:0.5];
        
                        }else {
        
                            NSLog(@"sendedFail");
        
                            [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
                            
                            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
                            
                             alert.tag =10;
                            [alert show];
                            
                            
                        }
                        
                    }
                    
                

    }
    else if(textArray.count !=0){
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Please select",nil)
                                                                                     message: nil
                                                                                    delegate: self
                                                                           cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                                           otherButtonTitles: nil];
                                      for(NSString *buttonTitle in textArray) {
                                          if(buttonTitle.length>3){
                                          [alert addButtonWithTitle:buttonTitle];
                                          }
                                      }
                                       alert.tag=8;
                                      [alert show];
    }
}




-(void)emailButtonClick:(id)sender{
    NSString *xmppfile = [[LinphoneManager instance] lpConfigStringForKey:@"xmppfile_preference"];
    
    if([xmppfile isEqualToString:@"0"]){
        NSLog(@"server turn off image upload feature.");
    }
    else if (xmppfile ==nil){
        NSLog(@"old version without image upload feature.");
    }
    else{
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        
        picker.delegate = self;
        
        picker.allowsEditing = NO;
        
        //UIImagePickerControllerSourceTypeCamera.
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.view.tag = 2;

        
        [[[[UIApplication sharedApplication].delegate window] rootViewController] presentModalViewController:picker animated:YES];
        
        [camerabutton setHidden:YES];
        
        [locationbutton setHidden:YES];
        
        [emailbutton setHidden:YES];
        
        [self optionButtonClick:sender];
    }
    
}

-(void)locationButtonClick:(id)sender{
    
    NSString *geoloc = [[LinphoneManager instance] lpConfigStringForKey:@"geoloc_preference"];
    
    if([geoloc isEqualToString:@"0"]){
        NSLog(@"server turn off location feature.");
    }
    else if (geoloc ==nil){
        NSLog(@"old version without location feature.");
    }
    else{
    
    if(location ==false){
        [self getLocation];
    
    }
    else{
        NSLog(@"can't tap location button when the location function is still working.");
    }
    
    }
}

-(void)cameraButtonClick:(id)sender{
    NSString *xmppfile = [[LinphoneManager instance] lpConfigStringForKey:@"xmppfile_preference"];
   
    if([xmppfile isEqualToString:@"0"]){
        NSLog(@"server turn off image upload feature.");
    }
    else if (xmppfile ==nil){
        NSLog(@"old version without image upload feature.");
    }
    else{

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
    
    picker.allowsEditing = NO;
    
        //UIImagePickerControllerSourceTypeCamera.
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [[[[UIApplication sharedApplication].delegate window] rootViewController] presentModalViewController:picker animated:YES];
        
    [camerabutton setHidden:YES];
        
    [locationbutton setHidden:YES];
        
    [emailbutton setHidden:YES];
        
    [self optionButtonClick:sender];
}
}


-(void)optionButtonClick:(id)sender{
    
    
    if(secondTime == false){
        [inputView resignFirstResponder];
        CGRect inputFrame = inputContainer.frame;
        
        CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
        
        
        
        inputFrame.origin.y = screenHeight-150;
        
        [UIView animateWithDuration:0.2
         
                         animations:^{
                             
                             inputContainer.frame = inputFrame;
                             
                             
                             
                             CGRect tableFrame = DataTable.frame;
                             
                             tableFrame.size.height = inputFrame.origin.y-108;
                             
                             DataTable.frame = tableFrame;
                             
                         }completion:^(BOOL finish){
                             
                             if (messageArray.count>0) {
                                 
                                 [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                  
                                                  atScrollPosition:UITableViewScrollPositionBottom
                                  
                                                          animated:YES];
                                 
                             }
                             
                             
                             
                         }];
        
        CATransition *animation = [CATransition animation];
        
        animation.type = kCATransitionMoveIn;
        
        animation.duration = 0.4;
        
        [emailbutton.layer addAnimation:animation forKey:nil];
        
        [camerabutton.layer addAnimation:animation forKey:nil];
        
        [locationbutton.layer addAnimation:animation forKey:nil];
        
        
        
        [emailbutton setHidden:NO];
        
        [camerabutton setHidden:NO];
        
        [locationbutton setHidden:NO];
        
        secondTime =true;
        
    }
    
    else{
        
        [inputView resignFirstResponder];
        CGRect inputFrame = inputContainer.frame;
        
        CGFloat screenHeight =[UIScreen mainScreen].applicationFrame.size.height;
        
        
        
        inputFrame.origin.y = screenHeight-55;
        
        [UIView animateWithDuration:0.2
         
                         animations:^{
                             
                             inputContainer.frame = inputFrame;
                             
                             
                             
                             CGRect tableFrame = DataTable.frame;
                             
                             tableFrame.size.height = inputFrame.origin.y-108;
                             
                             DataTable.frame = tableFrame;
                             
                         }completion:^(BOOL finish){
                             
                             if (messageArray.count>0) {
                                 
                                 [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                  
                                                  atScrollPosition:UITableViewScrollPositionBottom
                                  
                                                          animated:YES];
                                 
                             }
                             
                             
                             
                         }];
        
        
        
        [emailbutton setHidden:YES];
        
        [camerabutton setHidden:YES];
        
        [locationbutton setHidden:YES];
        
        secondTime =false;
        
    }
    
}



-(void)sendButtonClick:(id)sender{
    
    
    
    
    
    
    
    
    
    NSString *content = [inputView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(content.length ==0){
        
        
        
        NSLog(@"enter empty message ");
        
    }
    
    else{
        
        
        
        
        
        
        
        
        
        inputView.text = @"";
        
        
        
        
        
        
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        
        
        
        [body setStringValue:content];
        
        
        
        
        
        
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        
        
        
        //need to show the type when send message to other devieces by otis.
        
        
        
        
        
        NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
        
        if (tRange.location == NSNotFound){
            
            
            
            [message addAttributeWithName:@"type" stringValue:@"chat"];
            
        }
        
        
        
        else {
            
            
            
            [message addAttributeWithName:@"type" stringValue:@"groupchat"];
            
            NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
            NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
            [message addChild:myMsgLogic];
            
        }
        
        
        
        
        
        [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        
        
        NSString *messageID=[[[LinphoneAppDelegate sharedAppDelegate]xmppStream] generateUUID];
        [message addAttributeWithName:@"id" stringValue:messageID];
        
        NSXMLElement *receipts = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [message addChild:receipts];
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        
        
        
        if([hostname isEqualToString:_displayname.text]){
            
            NSLog(@"can't send message to system.");
            
        }
        
        else{
            
            
            
            
            
            
            
            
            
            [message addAttributeWithName:@"to" stringValue:_displayname.text];
            
            
            
            [message addChild:body];
            
            
            
            
            
            
            
            
            
            
            LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
            
            
            
            
            
            
            
            MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                            
                                            
                                            
                                                                         inManagedObjectContext:appDelegate.managedObjectContext];
            
            
            
            messageEntity.content = content;
            
            messageEntity.receipt = messageID;
            
            messageEntity.sendDate = [NSDate date];
            
            
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
            PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
            
            
            
            messageEntity.sender = senderUserEntity;
            
            
            
            [senderUserEntity addSendedMessagesObject:messageEntity];
            
            
            
            messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
            
            [appDelegate saveContext];
            
            
            
            XMPPElementReceipt *receipt;
            
            
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
            
            
            if ([receipt wait:20]) {
                
                
               
                
                
                [self performSelector:@selector(messageSendedDelay:)
                 
                           withObject:messageEntity
                 
                           afterDelay:0.5];
                
            }else {
                
                NSLog(@"sendedFail");
                
                [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
                
                
                
                
                
                
                alert.tag =10;
                [alert show];
                
                
            }
            
            [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
             
                             atScrollPosition:UITableViewScrollPositionBottom
             
                                     animated:NO];
            
        }
        
    }
    
    
    
}





-(void)messageSendedDelay:(MessageEntity*)messageEntity{
    
    
    
    messageEntity.flag_sended = [NSNumber numberWithBool:YES];
    
    [[LinphoneAppDelegate sharedAppDelegate] saveContext];
    
}



-(void)animationFinished:(MessageEntity*)messageEntity {
    
    messageEntity.flag_sended =[NSNumber numberWithBool:YES];
    
    messageEntity.content = [messageEntity.content stringByAppendingString:@" "];
    
    
    
    [[LinphoneAppDelegate sharedAppDelegate]saveContext];
    
    
    
}

//back button.

- (IBAction)back:(id)sender {
    
    
    
    
    [[PhoneMainView instance] popCurrentView];
    
    
    
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(alertView.tag ==7){
        if(buttonIndex ==1){
            NSString *dest=NULL;
            
            NSString *tel = alertView.title;
            
            dest = [FastAddressBook normalizeSipURI:[NSString stringWithString:tel]];
            DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
            if(controller != nil) {
                [controller call:dest displayName:dest];
            }
            
        }
        else if(buttonIndex ==2){
            NSString *tel = alertView.title;
            tel = [tel stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
            NSString *urlString = [NSString stringWithFormat: @"tel://%@", tel];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }
    }
    
    
    else if(alertView.tag ==8 ){
        if(buttonIndex != 0){
        NSString *string = [alertView buttonTitleAtIndex:buttonIndex];
        if(string.length <8){
         
                
                NSString *dest=NULL;
                
                NSString *tel = string;
                
                dest = [FastAddressBook normalizeSipURI:[NSString stringWithString:tel]];
                DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
                if(controller != nil) {
                        [controller call:dest displayName:dest];
                }
            
            
        }
        NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber|NSTextCheckingTypeAddress error:nil];
        
        [detector enumerateMatchesInString:string options:kNilOptions range:NSMakeRange(0, [string length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSString *tel =result.phoneNumber;
            NSURL *links =result.URL;
            NSDictionary *addresses = result.addressComponents;
            if(tel !=nil){
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:tel message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"AzFone",nil), NSLocalizedString(@"iPhone",nil), nil];
                
                alert.tag=7;
                
                [alert show];
            }
            else if(addresses !=nil){
                NSString *string2 = [string substringWithRange:(result.range)];
                string2 = [string2 stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
                
                NSString* urlStr = [NSString stringWithFormat:@"http://maps.apple.com/maps?daddr=%@", string2];
                
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
                
            }
            else if (links != nil){
                [[UIApplication sharedApplication] openURL:links];
            }
         
            
            
        }];
        }
        
    }
    else if(alertView.tag ==10 && buttonIndex ==0){
        [[PhoneMainView instance] changeCurrentView:[SettingsViewController compositeViewDescription]];
    }
    else if(alertView.tag ==11 && buttonIndex ==0){
        NSLog(@"turn off location ,%@",alertView.accessibilityValue);
   }
    else if(alertView.tag ==11 && buttonIndex ==1){
        
            NSString * gps = alertView.accessibilityValue;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
            NSString *str1 =[strDate stringByAppendingString:@"|"];
            NSString *str2 = [str1 stringByAppendingString:gps];
            NSRange ran = [str2 rangeOfString:@">"];
            NSString *str3 =[str2 substringToIndex:ran.location+1];
       
        NSXMLElement *bodys =[NSXMLElement elementWithName:@"body"];
       
        [bodys setStringValue:str3];
        NSXMLElement *messages = [NSXMLElement elementWithName:@"message"];
        NSRange tRanges = [_displayname.text rangeOfString:@"@conference"];
        
        if (tRanges.location == NSNotFound){
            [messages addAttributeWithName:@"type" stringValue:@"chat"];
        }
        else {
            [messages addAttributeWithName:@"type" stringValue:@"groupchat"];
            NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
            NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
            [messages addChild:myMsgLogic];
        }
        [messages addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        [messages addAttributeWithName:@"to" stringValue:_displayname.text];
       
        
        NSXMLElement *xmlns =[NSXMLElement elementWithName:@"locations"];
        [xmlns setXmlns:@"http://azfone.net/locations"];
        NSXMLElement *xmln =[NSXMLElement elementWithName:@"locations"];
        [xmln setStringValue:@"locations"];
        [xmlns addChild:xmln];
        [messages addChild:xmlns];
        [messages addChild:bodys];
        XMPPElementReceipt *receipts;
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:messages andGetReceipt:&receipts];
        
//send address.
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        NSXMLElement *xmlnss =[NSXMLElement elementWithName:@"geoloc"];
        [xmlnss setXmlns:@"http://jabber.org/protocol/geoloc"];
        [body setStringValue:alertView.title];
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        
        NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
        
        if (tRange.location == NSNotFound){
            [message addAttributeWithName:@"type" stringValue:@"chat"];
        }
        
        else {
            [message addAttributeWithName:@"type" stringValue:@"groupchat"];
            NSString *uuidString=[UIDevice currentDevice].identifierForVendor.UUIDString;
            NSXMLElement *myMsgLogic=[NSXMLElement elementWithName:@"myMsgLogic" stringValue:uuidString];
            [message addChild:myMsgLogic];
            
        }
        
        
        
        
        [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        
        NSString *messageID=[[[LinphoneAppDelegate sharedAppDelegate]xmppStream] generateUUID];
        [message addAttributeWithName:@"id" stringValue:messageID];
        
        NSXMLElement *receiptss = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [message addChild:receiptss];

        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        
        if([hostname isEqualToString:_displayname.text]){
            
            NSLog(@"can't send message to system.");
            
        }
        else{
            [message addAttributeWithName:@"to" stringValue:_displayname.text];
       
            [message addChild:xmlnss];
            [message addChild:body];
            
           
            
            LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
            
            MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                            
                                            
                                            
                                                                         inManagedObjectContext:appDelegate.managedObjectContext];
            
            messageEntity.content = alertView.title;
            
            messageEntity.receipt = messageID;
            
            messageEntity.sendDate = [NSDate date];
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
            PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
            
            messageEntity.sender = senderUserEntity;
            
            [senderUserEntity addSendedMessagesObject:messageEntity];
            
            messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
            
            [appDelegate saveContext];
            
            
            XMPPElementReceipt *receipt;
            
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
            
            
            
            if ([receipt wait:20]) {
               
                [self performSelector:@selector(messageSendedDelay:)
                 
                           withObject:messageEntity
                 
                           afterDelay:0.5];
           
                
            }else {
                
                NSLog(@"sendedFail");
                
                [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
                
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Suggestion: Click Next, then Click any selected Reconnect option, or return to device Home Page to adjust 3G, 4G, Wifi, VPN Settings ",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Next",nil),  nil];
                
                alert.tag =10;
                [alert show];
                
            }
            
        }
    

        
                
                

    }
    else if(alertView.tag ==13 &&buttonIndex ==1) {
        
        ContactDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE], ContactDetailsViewController);
        if(controller != nil) {
            
            [controller newContactfromXMPP:_displayname.text];
            
        }

    }
    
    
    
    
}




- (IBAction)contactbook:(id)sender {
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    
    contactArray= [[NSMutableArray alloc]init];
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    for (CFIndex i = 0; i < CFArrayGetCount(people); i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef emails =ABRecordCopyValue(person,kABPersonEmailProperty);
        int emailAddress =ABMultiValueGetCount(emails);
        if (emailAddress >0){
            for(CFIndex i =0; i<emailAddress ; i++){
                
                NSString *email = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails ,i));
                [contactArray addObject:email];
                
            }
        }
        
    }
    
    if ( [contactArray containsObject: _displayname.text] ) {
        
        ABAddressBookRef addressBook = ABAddressBookCreate( );
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        for (CFIndex i = 0; i < CFArrayGetCount(people); i++) {
            ABRecordRef person = CFArrayGetValueAtIndex(people, i);
            ABMultiValueRef emails =ABRecordCopyValue(person,kABPersonEmailProperty);
            int emailAddress =ABMultiValueGetCount(emails);
            if (emailAddress >0){
                for(CFIndex i =0; i<emailAddress ; i++){
                    
                    NSString *email = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails ,i));
                    
                    if ([ email rangeOfString:_displayname.text].location !=NSNotFound){
                        ContactDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE], ContactDetailsViewController);
                        if(controller != nil) {
                            if([ContactSelection getSelectionMode] != ContactSelectionModeEdit) {
                                [controller setContact:person];
                                
                            } else {
                                [controller editContact:person address:[ContactSelection getAddAddress]];
                                
                                
                            }
                            break;
                            
                        }
                    }
                }
            }
        }
    }
    
    
    else {
        
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   
                                   initWithTitle:NSLocalizedString(@"This user is not in your contact book",nil)
                                   
                                   message:NSLocalizedString(@"Add a contact?",nil)
                                   
                                   delegate:self
                                   
                                   cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                   
                                   otherButtonTitles:NSLocalizedString(@"OK",nil),nil];
        
        
        errorAlert.tag =13;
        [errorAlert show];
    }
}






//let message in each row can be copy to device pasteboard.

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath



{
//preview image.
    id messageObject = [messageArray objectAtIndex:indexPath.row];
    
    MessageEntity *messageEntity = (MessageEntity*)messageObject;
        
        
        if(messageEntity.image != nil){
           
           CGRect screenBounds = [[UIScreen mainScreen] bounds];
          
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height-20)];
            background = bgView;
            [bgView setBackgroundColor:[UIColor colorWithRed:0.0
                                                       green:0.0
                                                        blue:0.0
                                                       alpha:1.0]];
            [self.view addSubview:bgView];
            [bgView release];
            
            UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,screenBounds.size.width, screenBounds.size.height-20)];
            
            borderView.layer.cornerRadius = 8;
            borderView.layer.masksToBounds = YES;
            
            borderView.layer.borderWidth = 8;
            borderView.layer.borderColor = [[UIColor colorWithRed:0.9
                                                            green:0.9
                                                             blue:0.9
                                                            alpha:0.7]CGColor];
            [borderView setCenter:bgView.center];
            [bgView addSubview:borderView];
            [borderView release];
            
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [closeBtn setImage:[UIImage imageNamed:@"list_delete_over.png"] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
           
            [closeBtn setFrame:CGRectMake(borderView.frame.origin.x+borderView.frame.size.width-25, borderView.frame.origin.y-6, 26, 27)];
            [bgView addSubview:closeBtn];
            
            

//file transfer show full image by otis.
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            if([messageEntity.sender.name isEqualToString:selfUserName]){
                NSString *fullfilename = messageEntity.image;
                NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                UIImage *img = [UIImage imageWithContentsOfFile:path];
                if(img.size.height>img.size.width){
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height-20)];
                [borderView addSubview:imgView];
                [imgView release];
                [imgView setCenter:bgView.center];
                imgView.image= img;
                }
                else{
                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height/3)];
                    [borderView addSubview:imgView];
                    [imgView release];
                    [imgView setCenter:bgView.center];
                    imgView.image= img;
                }
               
            }else{
            
            NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
            AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
            requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
            
            [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                UIImage *img =responseObject;
                if(img.size.height>img.size.width){
                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height-20)];
                    [borderView addSubview:imgView];
                    [imgView release];
                    [imgView setCenter:bgView.center];
                    imgView.image= img;
                }
                else{
                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height/3)];
                    [borderView addSubview:imgView];
                    [imgView release];
                    [imgView setCenter:bgView.center];
                    imgView.image= img;
                }
                UIButton *DownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [DownloadButton setImage:[UIImage imageNamed:@"save.png"] forState:UIControlStateNormal];
               
                [DownloadButton addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchUpInside];
                DownloadButton.accessibilityValue=messageEntity.image;
                [DownloadButton setFrame:CGRectMake(borderView.frame.origin.x+borderView.frame.size.width-59, screenBounds.size.height-59, 60, 40)];
                [bgView addSubview:DownloadButton];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                UIImage *img =[UIImage imageNamed:@"noimage.png"];
                if(img.size.height>img.size.width){
                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height-20)];
                    [borderView addSubview:imgView];
                    [imgView release];
                    [imgView setCenter:bgView.center];
                    imgView.image= img;
                }
                else{
                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height/3)];
                    [borderView addSubview:imgView];
                    [imgView release];
                    [imgView setCenter:bgView.center];
                    imgView.image= img;
                }
                
                }];
            
            [requestOperation start];
            }
//file transfer show full image by otis.
            
            
            [self shakeToShow:borderView];
        
            
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            [UIView beginAnimations:nil context:context];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:2.6];
            [self.view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
            [UIView setAnimationDelegate:bgView];
            
            
            [UIView commitAnimations];

            
        return NO;
        
        }
    
        else{
    
        return YES;
        
        }
}



- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender



{
    

   
    return (action == @selector(copy:));
   

    
    
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender



{
    
    
    if (action == @selector(copy:)) {
        
        id messageObject = [messageArray objectAtIndex:indexPath.row];
        
        
        
        if ([messageObject isKindOfClass:[MessageEntity class]]) {
            
            
            
            MessageEntity *messageEntity = (MessageEntity*)messageObject;
            
            
            
            [UIPasteboard generalPasteboard].string = messageEntity.content;
            
        }
        
        
        
    }
   
    
}







-(void)close {
    [background removeFromSuperview];
}
-(void)save:(id)sender{
    
    
    NSString *fullfilename = [sender accessibilityValue];
    NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    UIImage *image= [UIImage imageWithContentsOfFile:path];
    if(image != nil){
        // correct image
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
       
    [background removeFromSuperview];
        UIAlertView *successAlert = [[UIAlertView alloc]
                                   
                                   initWithTitle:NSLocalizedString(@"Save Success!",nil)
                                   
                                   message:nil
                                   
                                   delegate:nil
                                   
                                   cancelButtonTitle:NSLocalizedString(@"confirm",nil)
                                   
                                   otherButtonTitles:nil];
        
        [successAlert show];
    }
    else{
    [background removeFromSuperview];
    }
}
- (void) shakeToShow:(UIView*)aView{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.5;
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    [aView.layer addAnimation:animation forKey:nil];
}



-(void)dismissButtonClick{
    
    [inputView resignFirstResponder];
    
}



#pragma mark chat


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    
    if ([anObject isKindOfClass:[MessageEntity class]]&&type==NSFetchedResultsChangeInsert) {
        
        MessageEntity *messageEntity = (MessageEntity*)anObject;
        
        NSIndexPath *dateIndexPath = nil;
      
        
        
        if (messageArray.count>0) {
            
            
            
            MessageEntity *previousEntity = [messageArray objectAtIndex:messageArray.count-1];
            
            
            
            NSTimeInterval timeIntervalBetween = [messageEntity.sendDate timeIntervalSinceDate:previousEntity.sendDate];
            
            
            
            if (timeIntervalBetween>15*60) {
                
                [messageArray addObject:messageEntity.sendDate];
                
                dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
                
            }
            
        }else {
            
            
            
            [messageArray addObject:messageEntity.sendDate];
            
            dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
            
        }
        
        [messageArray addObject:anObject];
        
        
        
        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
        
        
        
        NSMutableArray *indexPathArray = [NSMutableArray array];
        
        if (dateIndexPath!=nil) {
            
            [indexPathArray addObject:dateIndexPath];
            
        }
        
        [indexPathArray addObject:insertIndexPath];
        
        [DataTable insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
        
       
        
        [DataTable scrollToRowAtIndexPath:insertIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }else if (type==NSFetchedResultsChangeUpdate) {
        
        NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:[messageArray indexOfObject:anObject] inSection:0];
        
        [DataTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:messageIndexPath]
         
                         withRowAnimation:UITableViewRowAnimationFade];
       
    }
    
}



#pragma mark tableview



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    


    return messageArray.count;
    
    
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    
    CGFloat rowHeight = 0;
    
    id messageObject = [messageArray objectAtIndex:indexPath.row];
      MessageEntity *messageEntity = (MessageEntity*)messageObject;
 
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    
    if ([messageObject isKindOfClass:[MessageEntity class]]) {
        
        if(![messageEntity.sender.name isEqualToString:selfUserName] && ![messageEntity.receiver.name isEqualToString:selfUserName]){
            rowHeight = 0.000001f;
        }
      
        else if(messageEntity.image != nil && messageEntity.roomname ==nil){
            

                    rowHeight =230.423965;
           
        }
        else if (messageEntity.image !=nil && messageEntity.roomname !=nil){
            NSRange range = [messageEntity.roomname rangeOfString:@"/"];
            if(range.location != NSNotFound){
              

                    rowHeight =230.423965;
                
            }
           
        }
       
        else if(messageEntity.roomname !=nil){
            NSRange range = [messageEntity.roomname rangeOfString:@"/"];
            NSRange tRange = [_displayname.text rangeOfString:@"@conference"];

            if(range.location != NSNotFound){
          
            
                NSString *msg = [messageEntity.content stringByAppendingString:@"\n displayname"];
                
                CGRect contentSize = [msg boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                      
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                      
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                      
                                                       context:nil];
                
                rowHeight = contentSize.size.height+30;
            

            }
            
            else if(range.location == NSNotFound && tRange.location ==NSNotFound ){
                NSString *msg = [messageEntity.content stringByAppendingString:@"\n displayname"];
                
                CGRect contentSize = [msg boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                      
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                      
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                      
                                                       context:nil];
                
                rowHeight = contentSize.size.height+30;
            }
        }
        else{
            NSString *msg = [messageEntity.content stringByAppendingString:@"\n displayname"];
            
            CGRect contentSize = [msg boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                  
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                  
                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                  
                                                   context:nil];
            
            rowHeight = contentSize.size.height+30;
        }
        
        
        
    }else if ([messageObject isKindOfClass:[NSDate class]]) {
        
        
        
        rowHeight = 30;
        
    }
    
    
    return rowHeight;
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
        UITableViewCell *cell = nil;
    
        NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
    
//if not in conference ,don't hide self message.
    
if (tRange.location == NSNotFound){
        
          id messageObject = [messageArray objectAtIndex:indexPath.row];
       
        if ([messageObject isKindOfClass:[MessageEntity class]]) {
            
            MessageEntity *messageEntity = (MessageEntity*)messageObject;
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        if ([messageEntity.sender.name isEqualToString:selfUserName] && [messageEntity.receiver.name isEqualToString:_displayname.text]) {
                
                //sender is self ,insert message in right cell.
            
            UITableViewCell *rightCell = [DataTable dequeueReusableCellWithIdentifier:@"rightCell"];
                
                if (rightCell==nil) {
                    
                    
                    
                    rightCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                 
                                                      reuseIdentifier:@"rightCell"];
                    
                    rightCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
               //photo
                    
                    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectZero];
                        
                    photoView.tag = kPhotoView;
                        
                    [rightCell.contentView addSubview:photoView];
                    
                    
               //ballonImage
                   
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGreen"]resizableImageWithCapInsets:UIEdgeInsetsMake(19, 8, 8, 16)];
                    
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    
                    ballonImageView.image = ballonImageRight;
                    
                    ballonImageView.tag = kBallonImageViewTag;
                    
                    [rightCell.contentView addSubview:ballonImageView];
                    
                    
              //contentlabel
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    
                    contentLabel.backgroundColor = [UIColor clearColor];
                    
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    
                    contentLabel.numberOfLines = NSIntegerMax;
                    
                    contentLabel.tag = kChatContentLabelTag;
                    
                    [rightCell.contentView addSubview:contentLabel];
                    
                    
              //loadingview
                    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    
                    loadingView.tag = kLoadingViewTag;
                    
                    [rightCell.contentView addSubview:loadingView];
                    
                    
                    
              //send date label
                    
                    UILabel *date =[[UILabel alloc]init];
                    
                    date.tag =sender_date;
                    
                    date.font =[UIFont systemFontOfSize:11];
                    
                    [rightCell.contentView addSubview:date];
                    
              //send fail image
                    
                    UIImageView *sendfailview = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    UIImage *sendfailimage = [UIImage imageNamed:@"list_delete_default"];
                    
                    sendfailview.image = sendfailimage;
                    
                    sendfailview.tag = kSendfailViewTag;
                    
                    [rightCell.contentView addSubview:sendfailview];
                    
              //right cell xep-0184
                    
                    UIImageView *receiptview = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    receiptview.tag = kReceiptViewTag;
                    
                    [rightCell.contentView addSubview:receiptview];
                    
              //right cell text button
                    
                    UIButton * textbutton =[[UIButton alloc]init];
                    textbutton =[UIButton buttonWithType:UIButtonTypeCustom];
                    textbutton.tag =kTextViewTag;
                    [rightCell.contentView addSubview:textbutton];
                    
                   }
                
        if(IS_IPHONE)
                    
                {
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                                                             context:nil];
                    
                    //xep-0184
                    
                    if([messageEntity.receipt isEqualToString:@"hao123"]){
                   
                        UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                        CGRect receiptframe =CGRectMake(270-contentSize.size.width, contentSize.size.height-5, 15, 15);
                        UIImage *receiptimage = [UIImage imageNamed:@"form_valid"];
                        
                        receiptview.image = receiptimage;
                        
                        
                        receiptview.frame = receiptframe;
                        
                        receiptview.hidden =NO;
                      
                    }
                    else{
                        UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                        
                        CGRect receiptframe =CGRectMake(270-contentSize.size.width, contentSize.size.height-10, 15, 15);
                        UIImage *receiptimage = [UIImage imageNamed:@""];
                        
                        receiptview.image = receiptimage;
                        receiptview.frame = receiptframe;
                        
                        receiptview.hidden =YES;
                    }
                    
                    
                   
                if(messageEntity.image !=nil){
                        
                        
                    //sendfail image
                        
                UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                        
                CGRect sendfailframe = CGRectMake(277-contentSize.size.width, 13, 20, 20);
                        
                sendfailview.frame = sendfailframe;
                                                
                sendfailview.hidden =YES;
                    
                  
                        
                 //hide ballonimage
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                        ballonImageView.hidden = YES;
                        
                 //show Photo
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                    
                    
                         photoView.image =[UIImage imageNamed:@"noimage.png"];
                 //check if image is exist by otis.
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                if(fileExists ==true){
                   
                        photoView.image =[UIImage imageWithContentsOfFile:path];
                    
                    if(photoView.image == nil){
                        photoView.image =[UIImage imageNamed:@"noimage.png"];
                    }
                              }
                  else{
                      
                        NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                           
                            
                           
                            UIImage *image = [UIImage imageWithContentsOfFile:path];
                            photoView.image = image;;
                            
                            
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }];
                       
                        [requestOperation start];
                        }
                //check if image is exist by otis.
                        
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                    if(photoView.image.size.height>photoView.image.size.width){
                       
                        
                            UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                            CGRect receiptframe =CGRectMake(300-contentSize.size.width, contentSize.size.height+150, 15, 15);
                            receiptview.frame = receiptframe;
                            receiptview.hidden =NO;
                        
                        
                        CGRect photoFrame = CGRectMake(320-contentSize.size.width, 5, 130, 200);
                        photoView.frame = photoFrame;
                        
                //date label
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-65, contentSize.size.height+75, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-43, contentSize.size.height+75, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                    }
                    else{
                        CGRect photoFrame = CGRectMake(250-contentSize.size.width, 5, 200, 130);
                        photoView.frame = photoFrame;
                        
                            UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                            CGRect receiptframe =CGRectMake(220-contentSize.size.width, contentSize.size.height+85, 15, 15);
                            receiptview.frame = receiptframe;
                            receiptview.hidden =NO;
                        
                        
                        //date label
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-125, contentSize.size.height+10, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-103, contentSize.size.height+10, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                    }
                        photoView.hidden=NO;
                    
                //content
                        UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                        
                        CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                        
                        contentLabel.frame = contentFrame;
                        
                        contentLabel.text = @"";
                    

                        
                   
                    }
                else{
                        
                        CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                              
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              
                                                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                              
                                                                                 context:nil];
                        
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                         ballonImageView.hidden=NO;
                        
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                        
                        CGRect photoFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        photoView.frame = photoFrame;
                        photoView.hidden=YES;
                    
                    
                    
                    
                    
                    
                    
                    
                    UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                    
                    CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    
                    contentLabel.frame = contentFrame;
                   
                    contentLabel.text = messageEntity.content;
                  
                    
                    
                    
                    
                    
                    
                    //sendfail image
                    
                    UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                    
                    CGRect sendfailframe = CGRectMake(277-contentSize.size.width, 13, 20, 20);
                    
                    sendfailview.frame = sendfailframe;
                    
                    NSString *lastChar = [contentLabel.text substringFromIndex:[contentLabel.text length] - 1];
                    
                    
                    //text button
                    
                    UIButton *textbutton =(UIButton*)[rightCell.contentView viewWithTag:kTextViewTag];
                    
                    CGRect textframe =CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    
                    textbutton.frame =textframe;
                    
                    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc]init];
                    [dateFormatters setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSString *timestr = [dateFormatters stringFromDate:messageEntity.sendDate];
                   
                    NSString *str1 = [timestr stringByAppendingString:@"   "];
                    NSString *str2 = [str1 stringByAppendingString:contentLabel.text];
                    textbutton.titleLabel.text =str2;
                    
                    textbutton.titleLabel.hidden =YES;
                    
                    [textbutton addTarget:self
                     
                                   action:@selector(textButtonClick:)
                     
                         forControlEvents:UIControlEventTouchUpInside];
                    
                    
                    
                   
                    
                    
                    if([lastChar isEqualToString:@" "]){
                        
                        //send failure red text.
                        
                        contentLabel.textColor =[UIColor redColor];
                        
                        //hide date label when send failure.
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        date.text = @"";
                        
                        //show send failure image.
                        
                        
                        [sendfailview setHidden:NO];
                        
                        
                    }
                    
                    else{
                        
                        [sendfailview setHidden:YES];
                        
                        contentLabel.textColor =[UIColor blackColor];
                        
                        //sender date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-78, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-56, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        
                        
                    }
                    
                    UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                    
                    
                    
                    loadingView.center = CGPointMake(280-contentSize.size.width, 25);
                    
                    
                    
                    if ([messageEntity.flag_sended boolValue]) {
                        
                        
                        
                        [loadingView stopAnimating];
                        
                    }
                    
                    
                    
                    else {
                        
                        
                        
                        [loadingView startAnimating];
                        
                        
                        
                    }
                        
                    }
                    
                }
                
            else
            
            {
                CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                      
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      
                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                      
                                                                         context:nil];
                
                //xep-0184
                
                if([messageEntity.receipt isEqualToString:@"hao123"]){
                    
                    UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                    CGRect receiptframe =CGRectMake(730-contentSize.size.width, contentSize.size.height-10, 15, 15);
                    UIImage *receiptimage = [UIImage imageNamed:@"form_valid"];
                    
                    receiptview.image = receiptimage;
                    
                    
                    receiptview.frame = receiptframe;
                    
                    receiptview.hidden =NO;
                }
                else{
                    UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                    
                    CGRect receiptframe =CGRectMake(730-contentSize.size.width, contentSize.size.height-10, 15, 15);
                    UIImage *receiptimage = [UIImage imageNamed:@""];
                    
                    receiptview.image = receiptimage;
                    
                    receiptview.frame = receiptframe;
                    
                    receiptview.hidden =YES;
                }
                
                
                if(messageEntity.image !=nil){
                    
                //sendfail image
                    
                    UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                    
                    CGRect sendfailframe = CGRectMake(277-contentSize.size.width, 13, 20, 20);
                    
                    sendfailview.frame = sendfailframe;
                    
                    sendfailview.hidden =YES;
                //hide ballonimage
                     UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                     CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                    
                    ballonImageView.frame = ballonFrame;
                    ballonImageView.hidden = YES;
                    
                //show Photo
                    UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                    
                    
                    photoView.image =[UIImage imageNamed:@"noimage.png"];
              //check if image is exist by otis.
                    NSString *fullfilename = messageEntity.image;
                    NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                    if(fileExists ==true){
                        photoView.image =[UIImage imageWithContentsOfFile:path];
                        if(photoView.image == nil){
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }
                        
                    }
                    else{   
                        
                        
                        NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                            UIImage *image = [UIImage imageWithContentsOfFile:path];
                            photoView.image = image;;
                            
                           
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            NSLog(@"Image error: %@", error);
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }];
                        
                        [requestOperation start];
                    }
         //check if image is exist by otis.
                    photoView.layer.cornerRadius = 8;
                    photoView.layer.masksToBounds = YES;
                    if(photoView.image.size.height>photoView.image.size.width){
                    CGRect photoFrame = CGRectMake(760-contentSize.size.width,5, 130, 200);
                    photoView.frame =photoFrame;
                        UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                        CGRect receiptframe =CGRectMake(730-contentSize.size.width, contentSize.size.height+150, 15, 15);
                        receiptview.frame = receiptframe;
                        receiptview.hidden =NO;
                        
                        //date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height+80, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height+80, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                    }
                    else{
                        CGRect photoFrame = CGRectMake(690-contentSize.size.width,5, 200, 130);
                        photoView.frame =photoFrame;
                        UIImageView *receiptview = (UIImageView*)[rightCell.contentView viewWithTag:kReceiptViewTag];
                        CGRect receiptframe =CGRectMake(660-contentSize.size.width, contentSize.size.height+85, 15, 15);
                        receiptview.frame = receiptframe;
                        receiptview.hidden =NO;
                      
                        //date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-143, contentSize.size.height+15, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-121, contentSize.size.height+15, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                    }
                    photoView.hidden=NO;
                    
                    
                    
                //content
                    UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                    CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    
                    contentLabel.frame = contentFrame;
                    
                    contentLabel.text = @"";
               
               
                    
                }
                else{
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                                                             context:nil];
                    
            //ballon image
                    UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                    
                    ballonImageView.frame = ballonFrame;
                    ballonImageView.hidden=NO;
                  
                    
                    
                    
                    
            //hide photo view
                    UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                    
                    CGRect photoFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                    
                    photoView.frame = photoFrame;
                    photoView.hidden=YES;
                    
                    
                    
                    
                    
                    
                    UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                    CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    
                    contentLabel.frame = contentFrame;
                    
                    contentLabel.text =  messageEntity.content;
      
                    
                   
            //sendfailimage
                    
                    UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                    
                    CGRect sendfailframe = CGRectMake(727-contentSize.size.width, 13, 20, 20);
                    
                    sendfailview.frame = sendfailframe;
                    
                    NSString *lastChar = [contentLabel.text substringFromIndex:[contentLabel.text length] - 1];
                    
                    
                    
                    //text button
                    
                    UIButton *textbutton =(UIButton*)[rightCell.contentView viewWithTag:kTextViewTag];
                    
                    CGRect textframe =CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    
                    textbutton.frame =textframe;
                    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc]init];
                    [dateFormatters setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSString *timestr = [dateFormatters stringFromDate:messageEntity.sendDate];
                   
                    NSString *str1 = [timestr stringByAppendingString:@"   "];
                    NSString *str2 = [str1 stringByAppendingString:contentLabel.text];
                    
                    textbutton.titleLabel.text =str2;
                    
                    textbutton.titleLabel.hidden =YES;
                    
                    [textbutton addTarget:self
                     
                                   action:@selector(textButtonClick:)
                     
                         forControlEvents:UIControlEventTouchUpInside];
                    
                    
                    
                    
                 if([lastChar isEqualToString:@" "]){
                        
                        //send failure red text.
                        
                        contentLabel.textColor =[UIColor redColor];
                        
                        //hide date label when send failure.
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        date.text = @"";
                        
                        //show send failure image.
                        
                        [sendfailview setHidden:NO];
                        
                    }
                    
                    else{
                        
                        [sendfailview setHidden:YES];
                        
                        contentLabel.textColor =[UIColor blackColor];
                        
                        
                        
                        //sender date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        
                        
                    }
                    
                    UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                    
                    
                    
                    loadingView.center = CGPointMake(730-contentSize.size.width, 25);
                    
                    
                    
                    if ([messageEntity.flag_sended boolValue]) {
                        
                        
                        
                        [loadingView stopAnimating];
                        
                    }
                    
                    
                    
                    else {
                        
                        
                        
                        [loadingView startAnimating];
                        
                    }
                    
                    
                }
                }
                
                
                
                cell = rightCell;
                
                
                
            }
            
            else if([messageEntity.sender.name isEqualToString:_displayname.text] && [messageEntity.receiver.name isEqualToString:selfUserName]){
                
                // message
                
                
                
                UITableViewCell *leftCell = [DataTable dequeueReusableCellWithIdentifier:@"leftCell"];
                
                if (leftCell==nil) {
                    
                    leftCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"leftCell"];
                    
                    
                    
                    leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    //photo
                    leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    photoView.tag = kPhotoView;
                    
                    [leftCell.contentView addSubview:photoView];

                    
                    //left ballonimage
                    
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGray"]resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 16.0f, 8.0f, 8.0f)];
                    
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    ballonImageView.image = ballonImageRight;
                    
                    ballonImageView.tag = kBallonImageViewTag;
                    
                    [leftCell.contentView addSubview:ballonImageView];
                    
                    //message label
                    
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    
                    contentLabel.backgroundColor = [UIColor clearColor];
                    
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    
                    contentLabel.numberOfLines = NSIntegerMax;
                    
                    contentLabel.tag = kChatContentLabelTag;
                    
                    [leftCell.contentView addSubview:contentLabel];
                    
                    
                    
                    //sender name label
                    
                    UILabel *name =[[UILabel alloc]init];
                    
                    name.tag = sender_name;
                    
                    name.font = [UIFont systemFontOfSize:11];
                    
                    [leftCell.contentView addSubview:name];
                    
                    
                    
                    //sender photoimage
                    
                    UIImageView *photo = [[UIImageView alloc] init];
                    
                    photo.frame = CGRectMake(3, 0, 35, 35);
                    photo.contentMode = UIViewContentModeScaleAspectFit;
                    photo.layer.masksToBounds = YES;
                    photo.layer.cornerRadius = photo.frame.size.width / 2.0f;
                    photo.tag = sender_photo;
                    
                    [leftCell.contentView addSubview:photo];
                    
                    
                    
                    //sender date label
                    
                    UILabel *date =[[UILabel alloc]init];
                    
                    date.tag =sender_date;
                    
                    date.font =[UIFont systemFontOfSize:11];
                    
                    [leftCell.contentView addSubview:date];
                    
                    
                    
                    //left cell text button
                    UIButton * textbutton =[[UIButton alloc]init];
                    textbutton =[UIButton buttonWithType:UIButtonTypeCustom];
                    textbutton.tag =kTextViewTag;
                    [leftCell.contentView addSubview:textbutton];
                    
                    
                    
                    
                    
                    
                }
                
                if( messageEntity.image !=nil){
                    
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                          
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                          
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                          
                                          
                                                                             context:nil];
                    
                 //show Photo
                    UIImageView *photoView = (UIImageView*)[leftCell.contentView viewWithTag:kPhotoView];
                    photoView.image =[UIImage imageNamed:@"noimage.png"];
                    
                 //check if image is exist by otis.
                    UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
                    CGRect dataFrame =CGRectMake(120.0000+63, contentSize.size.height+90, 200, 200);
                    date.frame =dataFrame;
                    NSString *fullfilename = messageEntity.image;
                    NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                    if(fileExists ==true){
                        photoView.image =[UIImage imageWithContentsOfFile:path];
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                        if(photoView.image.size.height>photoView.image.size.width){
                            //left cell image portrait.
                        CGRect photosFrame = CGRectMake(45, 25, 130, 200);
                        photoView.frame = photosFrame;
                           
                           
                        }
                        else{
                            //left cell image landscape.
                            CGRect photosFrame = CGRectMake(45, 25, 200, 130);
                            photoView.frame = photosFrame;
                            CGRect dataFrame =CGRectMake(190.0000+63, contentSize.size.height+25, 200, 200);
                            
                            date.frame =dataFrame;
                        }
                        photoView.hidden=NO;
                        if(photoView.image == nil){
                            //left cell image portrait.
                            CGRect photosFrame = CGRectMake(45, 25, 130, 200);
                            photoView.frame = photosFrame;
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                            
                        }
                    }
                    else{
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                        CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                        photoView.frame = photosFrame;
                        photoView.hidden=NO;
                        
                        NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                            
                            UIImage *image = [UIImage imageWithContentsOfFile:path];
                            photoView.image = image;
                            if(photoView.image.size.width>photoView.image.size.height){
                                //left cell image landscape.
                                CGRect photosFrame = CGRectMake(45, 25, 200, 130);
                                photoView.frame = photosFrame;
                                CGRect dataFrame =CGRectMake(190.0000+63, contentSize.size.height+25, 200, 200);
                                
                                date.frame =dataFrame;
                            }
                            
                            
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }];
                        
                        [requestOperation start];
                    }

              //check if image is exist by otis.
                
                    
                 
                    //left ballonimage
                    
                    UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                    CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
                    
                    ballonImageView.frame = ballonFrame;
                    ballonImageView.hidden = YES;
                    
                    //sender photoimage
                    
                    UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
                    
                    CGRect photoFrame= CGRectMake(3, 0, 35, 35);
                    
                    photo.frame =photoFrame;
            
                    
                    
                    
                    
                    if (photoData != nil){
                        
                        
                        
                        photo.image =[UIImage imageWithData:photoData];
                        
                    }
                    
                    else if(friendEn.photo!= nil){
                        
                        photo.image = friendEn.photo;
                        
                    }
                    else{
                        
                        if([friendEn.displayName isEqualToString:@" System"]){
                            
                            photo.image = [UIImage imageNamed:@"System"];
                            
                        }
                        
                        else{
                            
                            photo.image = [UIImage imageNamed:@"defaultPerson"];
                            
                        }
                        
                    }
                    
                    //message label
                    UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
                    CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                    contentLabel.frame = contentFrame;
                    contentLabel.text =@"";
                    
                    //sender name label
                    UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
                    CGRect nameFrame = CGRectMake(45, -43, 200, 100);
                    name.frame = nameFrame;
                    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                    if (tRange.location == NSNotFound){
                        name.text =friendEn.displayName;
                    }
                    else{
                        NSRange search = [messageEntity.roomname rangeOfString:@"/"];
                        if(search.location !=NSNotFound){
                        NSString *subString = [messageEntity.roomname substringFromIndex:search.location+1];
                        
                        name.text =subString;
                        }
                        
                    }
                    //sender date label
                    
                    
                    if(messageEntity.image == nil){
                       
                    CGRect dataFrame =CGRectMake(contentSize.size.width+63, contentSize.size.height+90, 200, 200);
                    
                    date.frame =dataFrame;
                        
                    }
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    [dateFormatter setDateFormat:@"ahh:mm"];
                    
                    [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                    
                    [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                    
                    NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                    
                    [dateFormatter release];
                    
                    date.text = strDate;
                    
                    cell = leftCell;
                
                }
                else{
                    
                    //show Photo
                    UIImageView *photoView = (UIImageView*)[leftCell.contentView viewWithTag:kPhotoView];
                    
                    CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                    
                    photoView.frame = photosFrame;
                    photoView.hidden=YES;
                
                    //sender photoimage
                
                UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
                
                CGRect photoFrame= CGRectMake(3, 0, 35, 35);
                
                photo.frame =photoFrame;
                    

                
                
                if (photoData != nil){
                    
                   photo.image =[UIImage imageWithData:photoData];
                    
                }
                
                else if(friendEn.photo!= nil){
                    
                    photo.image = friendEn.photo;
                    
                }
                 else{
                    
                    if([friendEn.displayName isEqualToString:@" System"]){
                        
                        photo.image = [UIImage imageNamed:@"System"];
                        
                    }
                    
                    else{
                        
                        photo.image = [UIImage imageNamed:@"defaultPerson"];
                        
                    }
                    
                }
                
                
                CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                      
                                      
                                      
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      
                                      
                                      
                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                      
                                      
                                      
                                                                         context:nil];
                //left ballonimage
                
                UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
                
                
                CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
                
                ballonImageView.frame = ballonFrame;
                
                ballonImageView.hidden=NO;
                
                
                
                
                
                
                
                
                
                //message label
                
                
                
                UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
                
                
                
                CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                
                
                
                contentLabel.frame = contentFrame;
                
                
                NSString *content = [messageEntity.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                contentLabel.text =content;
                
                
                
                //text button
                
                UIButton *textbutton =(UIButton*)[leftCell.contentView viewWithTag:kTextViewTag];
                
                CGRect textframe =CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                
                textbutton.frame =textframe;
                    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc]init];
                    [dateFormatters setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSString *timestr = [dateFormatters stringFromDate:messageEntity.sendDate];
                   
                    NSString *str1 = [timestr stringByAppendingString:@"   "];
                    NSString *str2 = [str1 stringByAppendingString:contentLabel.text];
                textbutton.titleLabel.text =str2;
                
                textbutton.titleLabel.hidden =YES;
                
                [textbutton addTarget:self
                 
                               action:@selector(textButtonClick:)
                 
                     forControlEvents:UIControlEventTouchUpInside];
                
                
                
                //sender name label
                
                
                
                UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
                CGRect nameFrame = CGRectMake(45, -43, 200, 100);
                name.frame = nameFrame;
                NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                if (tRange.location == NSNotFound){
                   name.text =friendEn.displayName;
                 }
                else{
                 NSRange search = [messageEntity.roomname rangeOfString:@"/"];
                    if(search.location !=NSNotFound){
                        NSString *subString = [messageEntity.roomname substringFromIndex:search.location+1];
                        
                        name.text =subString;
                    }
                    
                 }
                
                
                
                
                
                
                
                //sender date label
                
                
                
                UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
                
                CGRect dataFrame =CGRectMake(contentSize.size.width+60, contentSize.size.height-77, 200, 200);
                
                date.frame =dataFrame;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                
                [dateFormatter setDateFormat:@"ahh:mm"];
                
                [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                
                [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                
                NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                
                [dateFormatter release];
                
                date.text = strDate;
                
                cell = leftCell;
                
              }
            }
            
            
            
        }else if ([messageObject isKindOfClass:[NSDate class]]) {
            
            if (IS_IPHONE)
                
            {
                
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                
                if (dateCell==nil) {
                    
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                
                                                     reuseIdentifier:@"dateCell"];
                    
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 5, 160, 20)];
                    
                    dateLabel.backgroundColor = [UIColor clearColor];
                    
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    
                    dateLabel.textColor = [UIColor lightGrayColor];
                    
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    
                    dateLabel.tag = kDateLabelTag;
                    
                    [dateCell.contentView addSubview:dateLabel];
                    
                }
                
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                
                NSDate *messageSendDate = (NSDate*)messageObject;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                
                cell = dateCell;
                
                
                
            }
            
            else{
                
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                
                if (dateCell==nil) {
                    
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                
                                                     reuseIdentifier:@"dateCell"];
                    
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(300, 5, 160, 20)];
                    
                    dateLabel.backgroundColor = [UIColor clearColor];
                    
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    
                    dateLabel.textColor = [UIColor lightGrayColor];
                    
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    
                    dateLabel.tag = kDateLabelTag;
                    
                    [dateCell.contentView addSubview:dateLabel];
                    
                }
                
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                
                NSDate *messageSendDate = (NSDate*)messageObject;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                
                cell = dateCell;
                
                
                
            }
            
        }
        
        
        
        if (cell==nil) {
            
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                    
                                         reuseIdentifier:@"cell"];
            
        }
        
        
        
    }
    
    //if conference,hide self's message.
    
    else{
        
        id messageObject = [messageArray objectAtIndex:indexPath.row];
        
        
        
        if ([messageObject isKindOfClass:[MessageEntity class]]) {
            
            
            
            MessageEntity *messageEntity = (MessageEntity*)messageObject;
            
            
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
         
            
            NSRange search = [messageEntity.roomname rangeOfString:@"/"];
            
            
            if(search.location !=NSNotFound){
            NSString *subString = [messageEntity.roomname substringFromIndex:search.location+1];
            
            if([selfUserName isEqualToString:subString]){
                
                 //otis hide double message when groupchat.
              
              
            }
            
            
            else if ([messageEntity.sender.name isEqualToString:selfUserName])
             
             {
                
                //sender is self ,insert message in right cell.
                
                UITableViewCell *rightCell = [DataTable dequeueReusableCellWithIdentifier:@"rightCell"];
                
                if (rightCell==nil) {
                    
                    
                    
                    rightCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                 
                                                      reuseIdentifier:@"rightCell"];
                    
                    
                    
                    rightCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                    
                //conference right cell photo
                    
                    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    photoView.tag = kPhotoView;
                    
                    [rightCell.contentView addSubview:photoView];
                    
                //conference right cell ballonimage.
                    
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGreen"]resizableImageWithCapInsets:UIEdgeInsetsMake(19, 8, 8, 16)];
                    
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    ballonImageView.image = ballonImageRight;
                    
                    ballonImageView.tag = kBallonImageViewTag;
                    
                    [rightCell.contentView addSubview:ballonImageView];
                    
                    
               //conference right cell content label.
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    
                    contentLabel.backgroundColor = [UIColor clearColor];
                    
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    
                    contentLabel.numberOfLines = NSIntegerMax;
                    
                    contentLabel.tag = kChatContentLabelTag;
                    
                    [rightCell.contentView addSubview:contentLabel];
                    
                    
              //conference right cell loadingview.
                    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    
                    loadingView.tag = kLoadingViewTag;
                    
                    [rightCell.contentView addSubview:loadingView];
                    
                    
                    
             //conference right cell send date label.
                    
                    UILabel *date =[[UILabel alloc]init];
                    
                    date.tag =sender_date;
                    
                    date.font =[UIFont systemFontOfSize:11];
                    
                    [rightCell.contentView addSubview:date];
                    
                 
                    
                    
                }
                
                if (IS_IPHONE)
                    
                {
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                                                             context:nil];
                    
                    if(messageEntity.image !=nil){
                        //hide ballonimage
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                        ballonImageView.hidden=YES;
                        
                        //show Photo
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                        
                        
                        photoView.image =[UIImage imageNamed:@"noimage.png"];
                        
                        //check if image is exist by otis.
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                        if(fileExists ==true){
                            
                            photoView.image =[UIImage imageWithContentsOfFile:path];
                            if(photoView.image == nil){
                                photoView.image =[UIImage imageNamed:@"noimage.png"];
                            }
                        }
                        else{
                            NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                            NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                            AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                            requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                            NSString *fullfilename = messageEntity.image;
                            NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                            requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                            [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                                
                                
                                UIImage *image = [UIImage imageWithContentsOfFile:path];
                                photoView.image = image;;
                                
                                
                                
                            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                
                                photoView.image =[UIImage imageNamed:@"noimage.png"];
                            }];
                            
                            [requestOperation start];
                        }
                        //check if image is exist by otis.
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                        if(photoView.image.size.height>photoView.image.size.width){
                        CGRect photoFrame = CGRectMake(320-contentSize.size.width, 5, 130, 200);
                        photoView.frame = photoFrame;
                        }
                        else{
                            CGRect photoFrame = CGRectMake(250-contentSize.size.width, 5, 200, 130);
                            photoView.frame = photoFrame;
                        }
                        photoView.hidden=NO;
                        
                        //content
                        UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                        
                        CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                        
                        contentLabel.frame = contentFrame;
                        
                        contentLabel.text = @"";
                        
                        //date label
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-55, contentSize.size.height+75, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-33, contentSize.size.height+75, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }

                    
                    }
                    
                    else{
                        CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                              
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              
                                                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                              
                                                                                 context:nil];
                        
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                        ballonImageView.hidden=NO;
                        
                        //conference hide phototview set hidden.
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                        
                        CGRect photoFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        photoView.frame = photoFrame;
                        photoView.hidden=YES;
                        
                        UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                        
                        CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                        
                        contentLabel.frame = contentFrame;
                        
                        contentLabel.text = messageEntity.content;
                        
                        
                        UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                        
                        loadingView.center = CGPointMake(280-contentSize.size.width, 25);
                        if ([messageEntity.flag_sended boolValue]) {
                            
                            [loadingView stopAnimating];
                            
                        }
                        
                        
                        
                        else {
                            
                            [loadingView startAnimating];
                            
                           }
                        //sender date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        
                    }
                    
                    
                   }
                
                else{ //is_ipad
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                                                             context:nil];
                    
                    if(messageEntity.image !=nil){
                        //hide ballonimage
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        
                        CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                        ballonImageView.hidden = YES;
                        
                        //show Photo
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                        
                        
                        photoView.image =[UIImage imageNamed:@"noimage.png"];
                        //check if image is exist by otis.
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                        if(fileExists ==true){
                            photoView.image =[UIImage imageWithContentsOfFile:path];
                            if(photoView.image == nil){
                                photoView.image =[UIImage imageNamed:@"noimage.png"];
                            }
                        }
                        else{
                            
                            
                            NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                            NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                            AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                            requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                            
                            NSString *fullfilename = messageEntity.image;
                            NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                            requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                            [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                               
                                UIImage *image = [UIImage imageWithContentsOfFile:path];
                                photoView.image = image;;
                                
                            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                NSLog(@"Image error: %@", error);
                                photoView.image =[UIImage imageNamed:@"noimage.png"];
                            }];
                            
                            [requestOperation start];
                        }
                        //check if image is exist by otis.
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                        if(photoView.image.size.height>photoView.image.size.width){
                            CGRect photoFrame = CGRectMake(760-contentSize.size.width,5, 130, 200);
                            photoView.frame =photoFrame;
                        }
                        else{
                            CGRect photoFrame = CGRectMake(690-contentSize.size.width,5, 200, 130);
                            photoView.frame =photoFrame;
                        }
                            photoView.hidden=NO;
                        //content
                        UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                        CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                        
                        contentLabel.frame = contentFrame;
                        
                        contentLabel.text = @"";
                        //date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height+80, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height+80, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                     }
                    
                    else{
                        CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                              
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              
                                                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                              
                                                                                 context:nil];
                        //ballon image
                        UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                        
                        CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        ballonImageView.frame = ballonFrame;
                        ballonImageView.hidden=NO;
                        
                        //hide photo view
                        UIImageView *photoView = (UIImageView*)[rightCell.contentView viewWithTag:kPhotoView];
                        
                        CGRect photoFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                        
                        photoView.frame = photoFrame;
                        photoView.hidden=YES;
                        
                        UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                        CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                        
                        contentLabel.frame = contentFrame;
                        
                        contentLabel.text =  messageEntity.content;
                        
                        UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                        loadingView.center = CGPointMake(730-contentSize.size.width, 25);
                        
                        if ([messageEntity.flag_sended boolValue]) {
                            
                            [loadingView stopAnimating];
                            
                        }
                        
                        else {
                            
                            [loadingView startAnimating];
                            
                            
                        }
                        
                        //sender date label
                        
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        
                        
                        [dateFormatter release];
                        
                        
                        
                        date.text = strDate;
                        
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        
                        if(date.text.length>5){
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }
                        
                        else{
                            
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                            
                            date.frame =dataFrame;
                            
                        }

                    }
                    
                    
                }
                
                cell = rightCell;
                
                
                
            }
            
           
            
            else{
                
                //left message
                
                
                
                UITableViewCell *leftCell = [DataTable dequeueReusableCellWithIdentifier:@"leftCell"];
                
                if (leftCell==nil) {
                    
                    leftCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"leftCell"];
                    
                    
                    
                    leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    
                    //left conference photo
                    leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    photoView.tag = kPhotoView;
                    
                    [leftCell.contentView addSubview:photoView];
                    
                    //left ballonimage
                    
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGray"]resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 16.0f, 8.0f, 8.0f)];
                    
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    
                    ballonImageView.image = ballonImageRight;
                    
                    ballonImageView.tag = kBallonImageViewTag;
                    
                    [leftCell.contentView addSubview:ballonImageView];
                    
                    //message label
                    
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    
                    contentLabel.backgroundColor = [UIColor clearColor];
                    
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    
                    contentLabel.numberOfLines = NSIntegerMax;
                    
                    contentLabel.tag = kChatContentLabelTag;
                    
                    [leftCell.contentView addSubview:contentLabel];
                    
                    
                    
                    //sender name label
                    
                    UILabel *name =[[UILabel alloc]init];
                    
                    name.tag = sender_name;
                    
                    name.font = [UIFont systemFontOfSize:11];
                    
                    [leftCell.contentView addSubview:name];
                    
                    
                    
                    //sender photoimage
                    
                    UIImageView *photo = [[UIImageView alloc] init];
                    
                    photo.frame = CGRectMake(3, 0, 35, 35);
                    photo.contentMode = UIViewContentModeScaleAspectFit;
                    photo.layer.masksToBounds = YES;
                    photo.layer.cornerRadius = photo.frame.size.width / 2.0f;
                    photo.tag = sender_photo;
                    
                    [leftCell.contentView addSubview:photo];
                    
                    
                    
                    //sender date label
                    
                    UILabel *date =[[UILabel alloc]init];
                    
                    date.tag =sender_date;
                    
                    date.font =[UIFont systemFontOfSize:11];
                    
                    [leftCell.contentView addSubview:date];
                    
                 
                    
                    
                }
                if( messageEntity.image !=nil){
                //left conference image.
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                          
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                          
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                          
                                          
                                                                             context:nil];
                    //sender photoimage
                    
                    UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
                    
                    CGRect photoFrame= CGRectMake(3, 0, 35, 35);
                    
                    photo.frame =photoFrame;
                    
                    
                    
                    
                    
                    if (photoData != nil){
                        
                        
                        
                        photo.image =[UIImage imageWithData:photoData];
                        
                    }
                    
                    else if(friendEn.photo!= nil){
                        
                        photo.image = friendEn.photo;
                        
                    }
                    else{
                        
                        if([friendEn.displayName isEqualToString:@" System"]){
                            
                            photo.image = [UIImage imageNamed:@"System"];
                            
                        }
                        
                        else{
                            
                            photo.image = [UIImage imageNamed:@"defaultPerson"];
                            
                        }
                        
                    }

                    //show Photo
                    UIImageView *photoView = (UIImageView*)[leftCell.contentView viewWithTag:kPhotoView];
                    photoView.image =[UIImage imageNamed:@"noimage.png"];
                   
                    //check if image is exist by otis.
                    UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
                    CGRect dataFrame =CGRectMake(120.0000+63, contentSize.size.height+90, 200, 200);
                    
                    date.frame =dataFrame;
                    
                    NSString *fullfilename = messageEntity.image;
                    NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                    if(fileExists ==true){
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                       
                        
                        photoView.hidden=NO;
                        photoView.image =[UIImage imageWithContentsOfFile:path];
                        if(photoView.image.size.height>photoView.image.size.width){
                            //left cell image portrait.
                            CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                            photoView.frame = photosFrame;
                            
                        }
                        else{
                            //left cell image landscape.
                            CGRect photosFrame = CGRectMake(45, 25, 200, 130);
                            photoView.frame = photosFrame;
                            CGRect dataFrame =CGRectMake(190.0000+63, contentSize.size.height+25, 200, 200);
                            
                            date.frame =dataFrame;
                        }
                        if(photoView.image == nil){
                            //left cell image portrait.
                            CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                            photoView.frame = photosFrame;
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }
                    }
                    else{
                        photoView.layer.cornerRadius = 8;
                        photoView.layer.masksToBounds = YES;
                        CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                        photoView.frame = photosFrame;
                      
                        photoView.hidden=NO;
                        
                        NSURL *url  = [NSURL URLWithString:[messageEntity.image stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
                        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
                        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
                        NSString *fullfilename = messageEntity.image;
                        NSString *filename = [fullfilename substringWithRange:NSMakeRange(fullfilename.length-13, 13)];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
                        requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
                        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                          
                            UIImage *image = [UIImage imageWithContentsOfFile:path];
                            photoView.image = image;;
                            if(photoView.image.size.width>photoView.image.size.height){
                        //left cell image landscape.
                                CGRect photosFrame = CGRectMake(45, 25, 200, 130);
                                photoView.frame = photosFrame;
                                CGRect dataFrame =CGRectMake(190.0000+63, contentSize.size.height+25, 200, 200);
                                
                                date.frame =dataFrame;
                            }
                            
                            
                            
                            
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                            photoView.image =[UIImage imageNamed:@"noimage.png"];
                        }];
                        
                        [requestOperation start];
                    }
                    
                    //check if image is exist by otis.
                   
                    
                    //left ballonimage
                    
                    UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                    CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
                    
                    ballonImageView.frame = ballonFrame;
                    ballonImageView.hidden = YES;
                    
                    //message label
                    UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
                    CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                    contentLabel.frame = contentFrame;
                    contentLabel.text =@"";
                    
                    //sender name label
                    UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
                    CGRect nameFrame = CGRectMake(45, -43, 200, 100);
                    name.frame = nameFrame;
                    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                    if (tRange.location == NSNotFound){
                        name.text =friendEn.displayName;
                    }
                    else{
                        NSRange search = [messageEntity.roomname rangeOfString:@"/"];
                        
                        if(search.location !=NSNotFound){
                            NSString *subString = [messageEntity.roomname substringFromIndex:search.location+1];
                            
                            name.text =subString;
                        }
                        
                    }
                    
                    
                    
                    if(messageEntity.image != nil){
                     
                        CGRect dataFrame =CGRectMake(contentSize.size.width+63, contentSize.size.height+90, 200, 200);
                        
                        date.frame =dataFrame;
                    }
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    [dateFormatter setDateFormat:@"ahh:mm"];
                    
                    [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                    
                    [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                    
                    NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                    
                    [dateFormatter release];
                    
                    date.text = strDate;
                    
                    cell = leftCell;
                
                }
                
                
               
                else{
                    //conference left hide Photo
                    UIImageView *photoView = (UIImageView*)[leftCell.contentView viewWithTag:kPhotoView];
                    
                    CGRect photosFrame = CGRectMake(45, 15, 130, 200);
                    
                    photoView.frame = photosFrame;
                    photoView.hidden=YES;
                    
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          
                                          
                                          
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          
                                          
                                          
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                          
                                          
                                          
                                                                             context:nil];
                    //sender photoimage
                    
                    UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
                    
                    CGRect photoFrame= CGRectMake(3, 0, 35, 35);
                    
                    photo.frame =photoFrame;
                    
                    
                    
           
                    
                    if (photoData != nil){
                        
                        
                        
                        photo.image =[UIImage imageWithData:photoData];
                        
                    }
                    
                    else if(friendEn.photo!= nil){
                        
                        photo.image = friendEn.photo;
                        
                    }
                    else{
                        
                        if([friendEn.displayName isEqualToString:@" System"]){
                            
                            photo.image = [UIImage imageNamed:@"System"];
                            
                        }
                        
                        else{
                            
                            photo.image = [UIImage imageNamed:@"defaultPerson"];
                            
                        }
                        
                    }

                    
                    //left ballonimage
                    
                    UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                    CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
                    
                    ballonImageView.frame = ballonFrame;
                    
                    ballonImageView.hidden=NO;
                    
                    //message label
                    
                    
                    
                    UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
                    
                    
                    
                    CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                    
                    
                    
                    contentLabel.frame = contentFrame;
                    
                    
                    NSString *content = [messageEntity.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    contentLabel.text =content;
                    //sender name label
                    
                    
                    
                    UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
                    CGRect nameFrame = CGRectMake(45, -43, 200, 100);
                    name.frame = nameFrame;
                    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                    if (tRange.location == NSNotFound){
                        name.text =friendEn.displayName;
                    }
                    else{
                        NSRange search = [messageEntity.roomname rangeOfString:@"/"];
                        if(search.location !=NSNotFound){
                            NSString *subString = [messageEntity.roomname substringFromIndex:search.location+1];
                            
                            name.text =subString;
                        }
                        
                    }
                    
                    //sender date label
                    
                    
                    
                    UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
                    
                    CGRect dataFrame =CGRectMake(contentSize.size.width+60, contentSize.size.height-77, 200, 200);
                    
                    date.frame =dataFrame;
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    
                    [dateFormatter setDateFormat:@"ahh:mm"];
                    
                    [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                    
                    [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                    
                    NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                    
                    [dateFormatter release];
                    
                    date.text = strDate;
                    
                    cell = leftCell;



                    
                }
                
                
            }
           
            
            }
            
            
        }
        
        else if ([messageObject isKindOfClass:[NSDate class]]) {
            
            if (IS_IPHONE)
                
            {
                
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                
                if (dateCell==nil) {
                    
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                
                                                     reuseIdentifier:@"dateCell"];
                    
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 5, 160, 20)];
                    
                    dateLabel.backgroundColor = [UIColor clearColor];
                    
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    
                    dateLabel.textColor = [UIColor lightGrayColor];
                    
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    
                    dateLabel.tag = kDateLabelTag;
                    
                    [dateCell.contentView addSubview:dateLabel];
                    
                }
                
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                
                NSDate *messageSendDate = (NSDate*)messageObject;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                
                cell = dateCell;
                
                
                
            }
            
            else{
                
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                
                if (dateCell==nil) {
                    
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                
                                                     reuseIdentifier:@"dateCell"];
                    
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(300, 5, 160, 20)];
                    
                    dateLabel.backgroundColor = [UIColor clearColor];
                    
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    
                    dateLabel.textColor = [UIColor lightGrayColor];
                    
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    
                    dateLabel.tag = kDateLabelTag;
                    
                    [dateCell.contentView addSubview:dateLabel];
                    
                }
                
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                
                NSDate *messageSendDate = (NSDate*)messageObject;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                
                cell = dateCell;
                
                
                
            }
            
        }
        
        
        
        if (cell==nil) {
            
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                    
                                         reuseIdentifier:@"cell"];
            
        }
        
    }
    
    return cell;
    
    
    
}



@end

