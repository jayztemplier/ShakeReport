//
//  SRModalViewController.m
//  ShakeReport
//
//  Created by Jeremy Templier on 9/21/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRModalViewController.h"

@interface SRModalViewController ()

@end

@implementation SRModalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)backPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
