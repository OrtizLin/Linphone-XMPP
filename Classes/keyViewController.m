//
//  keyViewController.m
//  linphone
//
//  Created by Mini on 11/24/14.
//
//
#import "PhoneMainView.h"
#import "keyViewController.h"
#import "AFNetworking.h"
@interface keyViewController ()
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
@end

@implementation keyViewController
@synthesize documentController;
- (void)viewDidLoad {
    [super viewDidLoad];
    _authimageTextField.keyboardType = UIKeyboardTypeNumberPad;
    // Do any additional setup after loading the view, typically from a nib.
    
    
     [self setUpForDismissKeyboard]; //dissmiss keyboard when touch the screen by otis.
    
    
    NSString *string = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
    
    NSString *password = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];

    NSString *wanip = [[LinphoneManager instance] lpConfigStringForKey:@"wanip_preference"];
    
    NSRange search = [string rangeOfString:@"@"];
    NSString *username = [string substringToIndex:search.location];
  

    if(username != nil && password !=nil && wanip != nil){
        
        NSURL *url =[NSURL URLWithString:wanip];
        NSString *str = [url absoluteString];
        
        NSURL *url1 =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/authimage.php"]];
        
        NSURLRequest * request = [[NSURLRequest alloc]initWithURL:url1 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3];                         //check out the image url with timeoutinterval:3 sec.
        NSURLResponse * respones = nil;
        NSError * error = nil;
        NSData * reviced = [NSURLConnection sendSynchronousRequest:request returningResponse:&respones  error:&error];
        UIImage * urlImage = [[UIImage alloc]initWithData:reviced];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:urlImage];
        imageView.frame = CGRectMake(27.0, 191.0, urlImage.size.width, urlImage.size.height);
        [self.view addSubview:imageView];
    
         _accountTextField.text = username;
         _passwordTextField.text = password;
        _passwordTextField.secureTextEntry = YES;
        
        _url.text = wanip;
    }
    
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (IBAction)send:(id)sender {
    
    NSURL *url =[NSURL URLWithString:self.url.text];
    NSString *str = [url absoluteString];
    
    NSURL *url1 =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/authimage.php"]];
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:url1 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3];                         //check out the image url with timeoutinterval:3 sec.
    NSURLResponse * respones = nil;
    NSError * error = nil;
    NSData * reviced = [NSURLConnection sendSynchronousRequest:request returningResponse:&respones  error:&error];
    UIImage * urlImage = [[UIImage alloc]initWithData:reviced];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:urlImage];
    imageView.frame = CGRectMake(27.0, 191.0, urlImage.size.width, urlImage.size.height);
    [self.view addSubview:imageView];
    
    
    if(urlImage == nil){    // if there are wrong image url , alert and reset ip.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid IP", @"Title of AlertView")
                                                        message:@"Please Reset IP"
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"confirm", @"Cancel Button Title")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (IBAction)login:(id)sender {
    
    NSString *url2 =_url.text;
    NSString *acct = _accountTextField.text;
    NSString *password = _passwordTextField.text;
    NSString *authimage = _authimageTextField.text;
    NSString *lowercase = [acct lowercaseString];
    NSString *test =@""; //to test if there are no IPaddress,alert show.
    if([url2 isEqualToString:test]){
        NSLog(@"invalid ipaddress");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid IP", @"Title of AlertView")
                                                        message:@"Set IP Address First"
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"confirm", @"Cancel Button Title")
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    else{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURL *url =[NSURL URLWithString:self.url.text];
    NSString *str = [url absoluteString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL
                                                                        
                                                                        URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/mobileKey.php"]]
                                    
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    
                                                       timeoutInterval:60.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"acct=%@&password=%@&authimage=%@",lowercase,password,authimage];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
                                              {
                                                  NSString * file = [str stringByAppendingString:@"_"];
                                                  NSString * file2 = [file stringByAppendingString:lowercase];
                                                  NSString * filename = [file2  stringByAppendingString:@".ovpn"];
                                                 
                                                  NSString *documentPath = [self applicationDocumentsFileDirectory];
                                                  NSString *currentFilePath = [documentPath stringByAppendingPathComponent:filename];
                                                  if ([[NSFileManager defaultManager]fileExistsAtPath:currentFilePath]) {
                                                      BOOL success = [[NSFileManager defaultManager] removeItemAtPath:currentFilePath error:nil];
                                                      if (success) {
                                                          NSLog(@"file deleted ");
                                                      }
                                                  }
                                                 
                                                  
                                                  NSURL *documentsDirectoryPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
                                                  
                                                  NSString *nameofovpn = @"ovpn";
                                                  NSRange rangeofovpn =[[response suggestedFilename]rangeOfString:nameofovpn];
                                                  if(rangeofovpn.location ==NSNotFound){
                                                      return [documentsDirectoryPath URLByAppendingPathComponent:[response suggestedFilename]];
                                                  }
                                                  else{
                                                      
                                                      return [documentsDirectoryPath URLByAppendingPathComponent:filename];
                                                  }
                                               
                                              } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                
                                                  
                                                  
                                                  NSString * urlStr = [filePath absoluteString];
                                                  NSString *string2 = @"mobileKey";
                                                  
                                                  NSRange range = [urlStr rangeOfString:string2];
                                                  if(range.location != NSNotFound){                        //the file is not equal to "client.ovpn" ,alert and reset account or password.
                                                     
                                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account or Password is Wrong!", @"Title of AlertView")
                                                                                                      message:@"Please Checkout Account and Password"
                                                                                                     delegate:self
                                                                                            cancelButtonTitle:NSLocalizedString(@"confirm", @"Cancel Button Title")
                                                                                            otherButtonTitles:nil];
                                                      [alert show];
                                                      self.authimageTextField.text =nil;
                                                  }
                                                  else{
                                                      
                                                      NSURL *url =[NSURL URLWithString:self.url.text];
                                                      NSString *str = [url absoluteString];
                                                      NSString *path = [NSString stringWithFormat:@"%@/Documents/DEVICETOKEN.plist",NSHomeDirectory()];
                                                      NSMutableDictionary *plist =[NSMutableDictionary dictionaryWithContentsOfFile:path];
                                                      NSString *token =[plist objectForKey:@"token"];
                                                      NSString *ext = [[LinphoneManager instance] lpConfigStringForKey:@"username_preference"];
                                                      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL
                                                                                                                          
                                                                                                                          URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/tkUpload.php"]]
                                                                                      
                                                                                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                      
                                                                                                         timeoutInterval:60.0];
                                                      
                                                      [request setHTTPMethod:@"POST"];
                                                      NSLog(@"http post value %@ %@ %@ %@ ",lowercase,password,ext,token);
                                                      NSString *postString = [NSString stringWithFormat:@"acct=%@&password=%@&ext=%@&token=%@",lowercase,password,ext,token];
                                                      [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
                                                      NSURLResponse * respones = nil;
                                                      NSError * error = nil;
                                                      NSData * received = [NSURLConnection sendSynchronousRequest:request returningResponse:&respones  error:&error];
                                                     
                                                    [self presentDocumentWithURL2:filePath];

                                                  }
                                                  
                                              }];
    [downloadTask resume];
    
    
    }
    
    
}

- (NSString *)applicationDocumentsFileDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
- (void)presentDocumentWithURL2:(NSURL*)url {
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
    self.documentController.delegate = self;
    [self.documentController presentOpenInMenuFromRect:CGRectMake(self.view.frame.size.width/2 - 49/2, self.view.frame.size.height-49, 49, 49)  inView:self.view animated:YES];
}
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



@end
