//
//  SRReportViewController.m
//  New Relic
//
//  Created by Jeremy Templier on 8/16/13.
//  Copyright (c) 2013 particulier. All rights reserved.
//

#import "SRReportViewController.h"

@interface SRReportViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@end

@implementation SRReportViewController

+ (id)composer
{
    SRReportViewController *controller = [[self alloc] initWithNibName:@"SRReportViewController" bundle:nil];
    return controller;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.titleLabel becomeFirstResponder];
}

#pragma mark - Accessors
- (NSString *)title
{
    return _titleLabel.text;
}

- (NSString *)message
{
    return _messageTextView.text;
}

#pragma mark - Actions
- (IBAction)sendPressed:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(reportControllerDidPressSend:)]) {
        [_delegate reportControllerDidPressSend:self];
    }
}
@end
