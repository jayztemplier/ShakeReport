//
//  SRReportViewController.h
//  New Relic
//
//  Created by Jeremy Templier on 8/16/13.
//  Copyright (c) 2013 particulier. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SRReportViewController;
@protocol SRReportViewControllerDelegate <NSObject>
- (void)reportControllerDidPressSend:(SRReportViewController *)controller;
- (void)reportControllerDidPressCancel:(SRReportViewController *)controller;
@end

@interface SRReportViewController : UIViewController <UITextFieldDelegate>
+ (id)composer;
@property (nonatomic, weak) id<SRReportViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSString *message;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@end
