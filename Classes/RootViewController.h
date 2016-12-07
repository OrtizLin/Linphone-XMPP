#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersonEntity.h"
#import "SWTableViewCell.h"
#import "UICompositeViewController.h"

@interface RootViewController : UIViewController <UITableViewDelegate,NSFetchedResultsControllerDelegate,UITableViewDataSource,UIAlertViewDelegate,UIActionSheetDelegate,SWTableViewCellDelegate,UICompositeViewDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    NSFetchedResultsController *fetchResultController;
	NSFetchedResultsController *fetchedResultsController;
    PersonEntity *friendEntity;
    NSMutableArray *personArray;
    UITableView *DataTable;
    UITableView *test;
    NSMutableArray *textLabel_MArray;
    NSString *fullroomjid;
    XMPPUserCoreDataStorageObject *friendentity;
}
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end
