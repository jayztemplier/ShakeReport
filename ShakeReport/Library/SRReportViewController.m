//
//  SRReportViewController.m
//  New Relic
//
//  Created by Jeremy Templier on 8/16/13.
//  Copyright (c) 2013 particulier. All rights reserved.
//

#import "SRReportViewController.h"
#import "SRReporter.h"

@interface SRReportViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@end

@implementation SRReportViewController

+ (id)composer
{
    SRReportViewController *controller = [[self alloc] initWithNibName:@"SRReportViewController" bundle:nil];
    controller.delegate = [SRReporter reporter];
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = _sendButton;
    self.title = @"Shake Report";
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

- (IBAction)cancelPressed:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(reportControllerDidPressCancel:)]) {
        [_delegate reportControllerDidPressCancel:self];
    }
}

#pragma mark - Text Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _titleLabel) {
        [_messageTextView becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}
@end
