//
//  SRImageEditorViewController.h
//  ShakeReport
//
//  Created by Jeremy Templier on 1/21/14.
//  Copyright (c) 2014 Jayztemplier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SRImageEditorViewController : UIViewController
{
    CGPoint lastPoint;
    
    BOOL mouseSwiped;
    
    int mouseMoved;
    
}
+ (id)controllerWithImage:(UIImage *)image;
- (IBAction)colorButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *screenshotImageView;
@property (strong, nonatomic) UIImage *originalImage;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *colorsToolbar;
@end
