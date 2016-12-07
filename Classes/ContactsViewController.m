/* ContactsViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
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

#import "ContactsViewController.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import <AddressBook/ABPerson.h>

@implementation ContactSelection

static ContactSelectionMode sSelectionMode = ContactSelectionModeNone;
static NSString* sAddAddress = nil;
static NSString* sSipFilter = nil;
static BOOL sEnableEmailFilter = FALSE;
static NSString* sNameOrEmailFilter;

+ (void)setSelectionMode:(ContactSelectionMode)selectionMode {
	sSelectionMode = selectionMode;
}

+ (ContactSelectionMode)getSelectionMode {
	return sSelectionMode;
}

+ (void)setAddAddress:(NSString*)address {
	if(sAddAddress != nil) {
		[sAddAddress release];
		sAddAddress= nil;
	}
	if(address != nil) {
		sAddAddress = [address retain];
	}
}

+ (NSString*)getAddAddress {
	return sAddAddress;
}

+ (void)setSipFilter:(NSString*)domain {
	[sSipFilter release];
	sSipFilter = [domain retain];
}

+ (NSString*)getSipFilter {
	return sSipFilter;
}

+ (void)enableEmailFilter:(BOOL)enable {
	sEnableEmailFilter = enable;
}

+ (BOOL)emailFilterEnabled {
	return sEnableEmailFilter;
}

+ (void)setNameOrEmailFilter:(NSString*)fuzzyName {
	[sNameOrEmailFilter release];
	sNameOrEmailFilter = [fuzzyName retain];
    
}

+ (NSString*)getNameOrEmailFilter {
	return sNameOrEmailFilter;
}


@end

@implementation ContactsViewController

@synthesize tableController;
@synthesize tableView;

@synthesize sysViewController;

@synthesize allButton;
@synthesize linphoneButton;
@synthesize backButton;
@synthesize addButton;
@synthesize toolBar;

typedef enum _HistoryView {
	History_All,
	History_Linphone,
	History_Search,
	History_MAX
} HistoryView;


#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:@"ContactsViewController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc {
	[tableController release];
	[tableView release];

	[allButton release];
	[linphoneButton release];
	[backButton release];
	[addButton release];

	[_searchBar release];
	[super dealloc];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if(compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc]	init:@"Contacts"
										content:@"ContactsViewController"
										stateBar:nil
										stateBarEnabled:false
										tabBar:@"UIMainBar"
										tabBarEnabled:true
										fullscreen:false
										landscapeMode:[LinphoneManager runningOnIpad]
										portraitMode:true];
	}
	return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	_searchBar.showsCancelButton = (_searchBar.text.length > 0);

	BOOL use_system = [[LinphoneManager instance] lpConfigBoolForKey:@"use_system_contacts"];
	if( use_system && !self.sysViewController){// use system contacts
		ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
		picker.peoplePickerDelegate = self;
		picker.view.frame = self.view.frame;

		[self.view addSubview:picker.view];

		self.sysViewController = picker;

	} else if( !use_system && !self.tableController ){

		CGRect subViewFrame= self.view.frame;
		// let the toolBar be visible
		subViewFrame.origin.y += self.toolBar.frame.size.height;
		subViewFrame.size.height -= self.toolBar.frame.size.height;

		self.tableController = [[[ContactsTableViewController alloc] init] autorelease];
		self.tableView = [[[UITableView alloc] init] autorelease];

		self.tableController.view = self.tableView;
		self.tableView.frame = subViewFrame;

		self.tableView.dataSource = self.tableController;
		self.tableView.delegate   = self.tableController;

		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
										   UIViewAutoresizingFlexibleWidth |
									   UIViewAutoresizingFlexibleTopMargin |
									UIViewAutoresizingFlexibleBottomMargin |
									  UIViewAutoresizingFlexibleLeftMargin |
									 UIViewAutoresizingFlexibleRightMargin;

		[self.view addSubview:tableView];
		[self update];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if(![FastAddressBook isAuthorized]) {
		UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Address book",nil)
														message:NSLocalizedString(@"You must authorize the application to have access to address book.\n"
																				  "Toggle the application in Settings > Privacy > Contacts",nil)
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
											  otherButtonTitles:nil];
		[error show];
		[error release];
		[[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self changeView:History_All];

	// Set selected+over background: IB lack !
	[linphoneButton setBackgroundImage:[UIImage imageNamed:@"contacts_linphone_selected.png"]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	[linphoneButton setTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
					forState:UIControlStateNormal];

	[LinphoneUtils buttonFixStates:linphoneButton];

	// Set selected+over background: IB lack !
	[allButton setBackgroundImage:[UIImage imageNamed:@"contacts_all_selected.png"]
					forState:(UIControlStateHighlighted | UIControlStateSelected)];

	[LinphoneUtils buttonFixStates:allButton];

	[tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[tableController.tableView setBackgroundView:nil]; // Can't do it in Xib: issue with ios4
}


#pragma mark -

- (void)changeView:(HistoryView)view {
	if(view == History_All) {
		[ContactSelection setSipFilter:nil];
		[ContactSelection enableEmailFilter:FALSE];
		[tableController loadData];
		allButton.selected = FALSE;
	} else {
		allButton.selected = TRUE;
	}

	if(view == History_Linphone) {
		[ContactSelection setSipFilter:[LinphoneManager instance].contactFilter];
		[ContactSelection enableEmailFilter:FALSE];
		[tableController loadData];
		linphoneButton.selected = FALSE;
	} else {
		linphoneButton.selected = TRUE;
	}
}

- (void)update {
	switch ([ContactSelection getSelectionMode]) {
		case ContactSelectionModePhone:
		case ContactSelectionModeMessage:
			[addButton setHidden:TRUE];
			[backButton setHidden:FALSE];
			break;
		default:
			[addButton setHidden:FALSE];
			[backButton setHidden:TRUE];
			break;
	}
	if([ContactSelection getSipFilter]) {
		allButton.selected = true;
		linphoneButton.selected = FALSE;
	} else {
		allButton.selected = FALSE;
		linphoneButton.selected = true;
	}
	[tableController loadData];
}


#pragma mark - Action Functions

- (IBAction)onAllClick:(id)event {
	[self changeView: History_All];
}

- (IBAction)onLinphoneClick:(id)event {
	[self changeView: History_Linphone];
}

- (IBAction)onAddContactClick:(id)event {
	// Go to Contact details view
	ContactDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE], ContactDetailsViewController);
	if(controller != nil) {
		if([ContactSelection getAddAddress] == nil) {
			[controller newContact];
		} else {
			[controller newContact:[ContactSelection getAddAddress]];
		}
	}
}

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] popCurrentView];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	//[self searchBar:searchBar textDidChange:nil];
	[searchBar resignFirstResponder];
}

#pragma mark - ABPeoplePickerDelegate

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	[[PhoneMainView instance] popCurrentView];
	return;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return true;

}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
								property:(ABPropertyID)property
							  identifier:(ABMultiValueIdentifier)identifier {
    

	CFTypeRef multiValue = ABRecordCopyValue(person, property);
	CFIndex valueIdx = ABMultiValueGetIndexForIdentifier(multiValue,identifier);
	NSString *phoneNumber = (NSString *)ABMultiValueCopyValueAtIndex(multiValue, valueIdx);
   
	// Go to dialer view
	DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
	if(controller != nil) {
		[controller call:phoneNumber displayName:[(NSString*)ABRecordCopyCompositeName(person) autorelease]];
	}
	[phoneNumber release];
	CFRelease(multiValue);
	return false;
}




#pragma mark - searchBar delegate


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    [ContactSelection setNameOrEmailFilter:searchText];
    
    [tableController loadData];
    
    NSRange tRange = [searchText rangeOfString:@"@"];
    
    NSScanner* scan = [NSScanner scannerWithString:searchText];
    int val;
    
    if(tableController.tableView.visibleCells == nil || ([tableController.tableView.visibleCells count] == 0 && searchText.length>1) ||tRange.location != NSNotFound||[scan scanInt:&val]) {
      
        
        [tableController loadData2:searchText];
    }
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:FALSE animated:TRUE];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:TRUE animated:TRUE];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];

    
}

- (void)viewDidUnload {
	[self setToolBar:nil];
	[super viewDidUnload];
}
@end
