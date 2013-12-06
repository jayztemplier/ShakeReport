//
//  SRViewController.m
//  ShakeReport
//
//  Created by Jeremy Templier on 5/29/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRViewController.h"

@interface SRViewController ()

@end

@implementation SRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)crashPressed:(id)sender
{
    NSString *nilString;
    //static analyzer find an issue here, but it's an example to make the application crash :)
    NSDictionary* d = @{@"aKey": nilString};
    NSLog(@"%@",d);
}
@end
