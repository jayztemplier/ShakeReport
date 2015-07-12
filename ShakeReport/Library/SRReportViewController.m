//
//  SRReportViewController.m
//  New Relic
//
//  Created by Jeremy Templier on 8/16/13.
//  Copyright (c) 2013 particulier. All rights reserved.
//

#import "SRReportViewController.h"
#import "SRReporter.h"
#import "UIImage+ImageEffects.h"

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
    self.navigationItem.leftBarButtonItem = _cancelButton;
    self.title = @"Shake Report";
    
    UIImage *backgroundImage = [SRReporter reporter].report.screenshot;
    backgroundImage = [backgroundImage applyBlurWithRadius:1.f tintColor:[UIColor colorWithWhite:0.600 alpha:0.480] saturationDeltaFactor:1.0 maskImage:nil];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = self.view.bounds;
    [self.view insertSubview:backgroundImageView atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.titleLabel becomeFirstResponder];
}

#pragma mark - Actions
- (IBAction)sendPressed:(id)sender
{
    [SRReporter reporter].report.title = _titleLabel.text;
    [SRReporter reporter].report.message = _messageTextView.text;
    if (_delegate && [_delegate respondsToSelector:@selector(reportControllerDidPressSend:)]) {
        [_delegate reportControllerDidPressSend:self];
    }
}

- (IBAction)cancelPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
//    if (_delegate && [_delegate respondsToSelector:@selector(reportControllerDidPressCancel:)]) {
//        [_delegate reportControllerDidPressCancel:self];
//    }
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
