//
//  MainViewController.m
//  InAppSettingsKitSampleApp
//  http://www.inappsettingskit.com
//
//  Copyright (c) 2009-2010:
//  Luc Vandal, Edovia Inc., http://www.edovia.com
//  Ortwin Gentz, FutureTap GmbH, http://www.futuretap.com
//  All rights reserved.
// 
//  It is appreciated but not required that you give credit to Luc Vandal and Ortwin Gentz, 
//  as the original authors of this code. You can give credit in a blog post, a tweet or on 
//  a info page of your app. Also, the original authors appreciate letting them know if you use this code.
//
//  This code is licensed under the BSD license that is available at: http://www.opensource.org/licenses/bsd-license.php
//

#import "MainViewController.h"

#import <MessageUI/MessageUI.h>

#import <InAppSettingsKit/IASKSettingsReader.h>
#import <InAppSettingsKit/IASKAppSettingsViewController.h>

#import "CustomViewCell.h"

@interface MainViewController()<UIPopoverControllerDelegate>
- (void)settingDidChange:(NSNotification*)notification;

@property (nonatomic) UIPopoverController* currentPopoverController;

@end

@implementation MainViewController

@synthesize appSettingsViewController, tabAppSettingsViewController;

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        appSettingsViewController.cellLayoutMarginsFollowReadableWidth = NO;
		appSettingsViewController.delegate = self;
		BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
		appSettingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
	}
	return appSettingsViewController;
}

- (IBAction)showSettingsPush:(id)sender {
	//[viewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
	// But we encourage you no to uncomment. Thank you!
	self.appSettingsViewController.showDoneButton = NO;
	self.appSettingsViewController.navigationItem.rightBarButtonItem = nil;
	[self.navigationController pushViewController:self.appSettingsViewController animated:YES];
}

- (IBAction)showSettingsModal:(id)sender {
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
    //[viewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
    // But we encourage you not to uncomment. Thank you!
    self.appSettingsViewController.showDoneButton = YES;
	[self presentViewController:aNavController animated:YES completion:nil];
}

- (void)showSettingsPopover:(id)sender {
	if(self.currentPopoverController) {
    [self dismissCurrentPopover];
		return;
	}
  
	self.appSettingsViewController.showDoneButton = NO;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
	UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navController];
	popover.delegate = self;
	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
	self.currentPopoverController = popover;
}

#pragma mark - View Lifecycle
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if(self.currentPopoverController) {
		[self dismissCurrentPopover];
	}
}

- (void) dismissCurrentPopover {
	[self.currentPopoverController dismissPopoverAnimated:YES];
	self.currentPopoverController = nil;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];


	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
	self.tabAppSettingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showSettingsPopover:)];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	IASKAppSettingsViewController *settingsViewController = (id)((UINavigationController*)segue.destinationViewController).topViewController;
	settingsViewController.delegate = self;

	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
	settingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
	
	// your code here to reconfigure the app for changed settings
}

// optional delegate method for handling mail sending result
- (BOOL)settingsViewController:(id<IASKViewController>)settingsViewController
shouldPresentMailComposeViewController:(MFMailComposeViewController*)mailComposeViewController
				  forSpecifier:(IASKSpecifier*) specifier {
	if ([specifier.key isEqualToString:@"mail_dynamic_subject"]) {
		[mailComposeViewController setSubject:NSDate.date.description];
	}
	return YES;
}

- (void)settingsViewController:(id<IASKViewController>)settingsViewController mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
       
    if ( error != nil ) {
        // handle error here
    }
    
    if ( result == MFMailComposeResultSent ) {
        // your code here to handle this result
    }
    else if ( result == MFMailComposeResultCancelled ) {
        // ...
    }
    else if ( result == MFMailComposeResultSaved ) {
        // ...
    }
    else if ( result == MFMailComposeResultFailed ) {
        // ...
    }
}
- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewController
                        tableView:(UITableView *)tableView
        heightForHeaderForSection:(NSInteger)section {
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
	NSString *headerImageName = [settingsViewController.settingsReader headerSpecifierForSection:section].headerImageName;
    if ([key isEqualToString:@"IASKLogo"]) {
        return [UIImage imageNamed:@"Icon.png"].size.height + 25;
	}
	else if (headerImageName != nil) {
		return [UIImage imageNamed:headerImageName].size.height + 10;
	}
	else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
        return 55.f;
    }
    return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController
                         tableView:(UITableView *)tableView 
           viewForHeaderForSection:(NSInteger)section {
	
	NSString *headerImageName = [settingsViewController.settingsReader headerSpecifierForSection:section].headerImageName;
	
	if (headerImageName != nil) {
		UIImage *image = [UIImage imageNamed:headerImageName];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, image.size.width, image.size.height)];
		imageView.image = image;
		imageView.contentMode = UIViewContentModeCenter;
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, image.size.height + 10)];
		view.backgroundColor = [UIColor clearColor];
		[view addSubview:imageView];
		return view;
	}
	
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:@"IASKLogo"]) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon.png"]];
        imageView.contentMode = UIViewContentModeCenter;
        return imageView;
    } else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor redColor];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.numberOfLines = 0;
        label.font = [UIFont boldSystemFontOfSize:16.f];
        
        //figure out the title from settingsbundle
        label.text = [settingsViewController.settingsReader titleForSection:section];
        
        return label;
    }
	return nil;
}

- (NSString *)settingsViewController:(id<IASKViewController>)settingsViewController tableView:(UITableView *)tableView titleForHeaderForSection:(NSInteger)section {
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:@"CUSTOM_HEADER_FOOTER"]) {
        return @"Custom header title";
    }
    return nil;
}

- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewController
                        tableView:(UITableView *)tableView
        heightForFooterForSection:(NSInteger)section {
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:@"IASKLogo"]) {
        return [UIImage imageNamed:@"Icon.png"].size.height + 25;
    }
    return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController
                         tableView:(UITableView *)tableView
           viewForFooterForSection:(NSInteger)section {
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:@"IASKLogo"]) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon.png"]];
        imageView.contentMode = UIViewContentModeCenter;
        return imageView;
    }
    return nil;
}

- (NSString *)settingsViewController:(id<IASKViewController>)settingsViewController tableView:(UITableView *)tableView titleForFooterForSection:(NSInteger)section {
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:@"CUSTOM_HEADER_FOOTER"]) {
        return @"Custom footer title";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"customCell"]) {
		return 44*3;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
	CustomViewCell *cell = (CustomViewCell*)[tableView dequeueReusableCellWithIdentifier:specifier.key];
	
	if (!cell) {
		cell = (CustomViewCell*)[[[NSBundle mainBundle] loadNibNamed:@"CustomViewCell" 
															   owner:self 
															 options:nil] objectAtIndex:0];
	}
	cell.textView.text= [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] != nil ? 
	 [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] : [specifier defaultStringValue];
	cell.textView.delegate = self;
	[cell setNeedsLayout];
	return cell;
}

- (NSArray *)settingsViewController:(IASKAppSettingsViewController*)sender valuesForSpecifier:(IASKSpecifier *)specifier {
	if ([specifier.key isEqualToString:@"countryCode"]) {
		return [NSLocale ISOCountryCodes];
	}
	return nil;
}

- (NSArray *)settingsViewController:(IASKAppSettingsViewController*)sender titlesForSpecifier:(IASKSpecifier *)specifier {
	if ([specifier.key isEqualToString:@"countryCode"]) {
		NSMutableArray *countryNames = NSMutableArray.array;
		for (NSString *countryCode in [NSLocale ISOCountryCodes]) {
			[countryNames addObject:(id)[NSLocale.currentLocale displayNameForKey:NSLocaleCountryCode value:countryCode]];
		}
		return countryNames;
	}
	return nil;
}


#pragma mark kIASKAppSettingChanged notification
- (void)settingDidChange:(NSNotification*)notification {
	if ([notification.userInfo.allKeys.firstObject isEqual:@"AutoConnect"]) {
		IASKAppSettingsViewController *activeController = notification.object;
		BOOL enabled = (BOOL)[[notification.userInfo objectForKey:@"AutoConnect"] intValue];
		[activeController setHiddenKeys:enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil] animated:YES];
	}
}

#pragma mark UITextViewDelegate (for CustomViewCell)
- (void)textViewDidChange:(UITextView *)textView {
    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"customCell"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:self userInfo:@{@"customCell" : textView.text}];
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.currentPopoverController = nil;
}

#pragma mark -
- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"ButtonDemoAction1"]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Demo Action 1 called" message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"InAppSettingsKit") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}]];
		[sender presentViewController:alert animated:YES completion:nil];
	} else if ([specifier.key isEqualToString:@"ButtonDemoAction2"]) {
		NSString *newTitle = [[[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] isEqualToString:@"Logout"] ? @"Login" : @"Logout";
		[[NSUserDefaults standardUserDefaults] setObject:newTitle forKey:specifier.key];
	}
}

@end
