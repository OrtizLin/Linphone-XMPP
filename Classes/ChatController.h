//
//  ChatController.h


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersonEntity.h"
#import "UICompositeViewController.h"
#import "XMPPOutgoingFileTransfer.h"
@interface ChatController : UIViewController<UITextViewDelegate,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate,UICompositeViewDelegate,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,XMPPOutgoingFileTransferDelegate>{
    CGRect keyboardEndFrame;
    IBOutlet UIImageView *inputContainer;
    IBOutlet UITableView *DataTable;
    IBOutlet UITextView *inputView;
    IBOutlet UIButton *emailbutton;
    IBOutlet UIButton *locationbutton;
    IBOutlet UIButton *camerabutton;
    CGFloat previousContentHeight;
    PersonEntity *selfEntity;
    PersonEntity *friendEntity;
    NSMutableArray *textArray;
   XMPPUserCoreDataStorageObject *friendEn;
    NSMutableArray *messageArray;
    NSMutableArray *contactArray;
    NSFetchedResultsController *fetchController;
    NSData *photoData;
    BOOL firstTime;
    BOOL secondTime;
    BOOL phone;
    BOOL link;
    BOOL address;
    BOOL location;
    CGFloat timeinterval;
    
}
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic,retain) XMPPUserCoreDataStorageObject *friendEn;
@property (nonatomic, strong) XMPPOutgoingFileTransfer *fileTransfer;

-(void)sendButtonClick:(id)sender;

- (IBAction)back:(id)sender;

- (IBAction)contactbook:(id)sender;


@property (retain, nonatomic) IBOutlet UILabel *displayname;


@end
