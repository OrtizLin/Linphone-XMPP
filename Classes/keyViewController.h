//
//  keyViewController.h
//  linphone
//
//  Created by Mini on 11/24/14.
//
//

#import <UIKit/UIKit.h>

@interface keyViewController : UIViewController<UIDocumentInteractionControllerDelegate>{
CGRect keyboardEndFrame;
}
@property (strong, nonatomic) IBOutlet UITextField *accountTextField;

@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *authimageTextField;
- (IBAction)login:(id)sender;
@property (strong, nonatomic) IBOutlet UIImageView *imageview;
@property (strong, nonatomic) IBOutlet UITextField *url;
@property (retain)UIDocumentInteractionController *documentController;
- (IBAction)send:(id)sender;

@end

