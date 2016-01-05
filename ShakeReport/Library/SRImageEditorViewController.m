//
//  SRImageEditorViewController.m
//  ShakeReport
//
//  Created by Jeremy Templier on 1/21/14.
//  Copyright (c) 2014 Jayztemplier. All rights reserved.
//

#import "SRImageEditorViewController.h"
#import "SRReportViewController.h"
#import "SRReporter.h"
#import "BSKAnnotationBoxView.h"
#import "BSKAnnotationArrowView.h"
#import "BSKAnnotationBlurView.h"
#import <QuartzCore/QuartzCore.h>
#import "BSKCheckerboardView.h"


#define kGridOverlayOpacity 0.2f
#define kAnnotationToolArrow 0
#define kAnnotationToolBox   1
#define kAnnotationToolBlur  2


UIImage *BSKImageWithDrawing(CGSize size, void (^drawingCommands)())
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    drawingCommands();
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

@interface SRImageEditorViewController () {
    int annotationToolChosen;
    BSKAnnotationView *annotationInProgress;
}
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, strong) UIImage *modifiedImage;
@property (nonatomic, strong) UIView *gridOverlay;
@property (weak, nonatomic) IBOutlet UIButton *arrowButton;
@property (weak, nonatomic) IBOutlet UIButton *boxButton;
@property (weak, nonatomic) IBOutlet UIButton *blurButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *toolsSegmentedControl;
- (IBAction)toolsValueChanged:(id)sender;
@end

@implementation SRImageEditorViewController

+ (id)controllerWithImage:(UIImage *)image
{
    SRImageEditorViewController *controller = [[self alloc] initWithNibName:@"SRImageEditorViewController" bundle:nil];
    controller.originalImage = image;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Screenshot editor";
    [self.navigationController setNavigationBarHidden:YES];
    _screenshotImageView.image = _originalImage;
    _modifiedImage = _originalImage;
    self.currentColor = [UIColor blackColor];
    UIBarButtonItem *nextButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextPressed:)];
    [nextButtonItem setImage:[UIImage imageNamed:@"next21"]];
    UIBarButtonItem *toolsButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tools" style:UIBarButtonItemStyleBordered target:self action:@selector(toolsPressed:)];
    [toolsButtonItem setImage:[UIImage imageNamed:@"painter11"]];
    self.navigationItem.rightBarButtonItems = @[nextButtonItem, toolsButtonItem];
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    [cancelButtonItem setImage:[UIImage imageNamed:@"cancel30"]];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    _screenshotImageView.frame = self.view.bounds;

    self.gridOverlay = [[BSKCheckerboardView alloc] initWithFrame:_screenshotImageView.frame checkerSquareWidth:16.0f];
    _gridOverlay.opaque = NO;
    _gridOverlay.alpha = kGridOverlayOpacity;
    _gridOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _gridOverlay.userInteractionEnabled = NO;
    [self.screenshotImageView addSubview:_gridOverlay];
    [self configureTools];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureTools {
    CGSize arrowIconSize = CGSizeMake(19, 19);
    UIImage *arrowIcon = BSKImageWithDrawing(arrowIconSize, ^{
        [UIColor.blackColor setStroke];
        CGRect arrowRect = CGRectMake(0, 0, arrowIconSize.width, arrowIconSize.height);
        arrowRect = CGRectInset(arrowRect, 1.5f, 1.5f);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(arrowRect.origin.x, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
        [path addLineToPoint:CGPointMake(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
        [path moveToPoint:CGPointMake(arrowRect.origin.x + 0.75f * arrowRect.size.width, arrowRect.origin.y + 0.25f * arrowRect.size.height)];
        [path addLineToPoint:CGPointMake(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
        [path addLineToPoint:CGPointMake(arrowRect.origin.x + 0.75f * arrowRect.size.width, arrowRect.origin.y + 0.75f * arrowRect.size.height)];
        [path stroke];
    });
    
    CGSize boxIconSize = CGSizeMake(19, 19);
    UIImage *boxIcon = BSKImageWithDrawing(boxIconSize, ^{
        [UIColor.blackColor setStroke];
        
        CGRect boxRect = CGRectMake(0, 0, boxIconSize.width, boxIconSize.height);
        boxRect = CGRectInset(boxRect, 2.5f, 2.5f);
        [[UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:4.0f] stroke];
    });
    
    CGSize blurIconSize = CGSizeMake(20, 20);
    UIImage *blurIcon = BSKImageWithDrawing(blurIconSize, ^{
        [UIColor.blackColor setStroke];
        [UIColor.blackColor setFill];
        
        CGRect blurRect = CGRectMake(0, 0, blurIconSize.width, blurIconSize.height);
        blurRect = CGRectInset(blurRect, 2.5f, 2.5f);
        
        [[UIBezierPath bezierPathWithRect:blurRect] stroke];
        
        CGRect quarterRect = CGRectMake(blurRect.origin.x, blurRect.origin.y, blurRect.size.width / 2.0f, blurRect.size.height / 2.0f);
        [[UIBezierPath bezierPathWithRect:quarterRect] fill];
        quarterRect.origin.x += blurRect.size.width / 2.0f;
        quarterRect.origin.y += blurRect.size.width / 2.0f;
        [[UIBezierPath bezierPathWithRect:quarterRect] fill];
    });
    
    arrowIcon.accessibilityLabel = @"Arrow";
    boxIcon.accessibilityLabel   = @"Box";
    boxIcon.accessibilityLabel   = @"Blur";
    
    [_toolsSegmentedControl setImage:arrowIcon forSegmentAtIndex:0];
    [_toolsSegmentedControl setImage:boxIcon forSegmentAtIndex:1];
    [_toolsSegmentedControl setImage:blurIcon forSegmentAtIndex:2];
    [_arrowButton setImage:arrowIcon forState:UIControlStateNormal];
    [_boxButton setImage:boxIcon forState:UIControlStateNormal];
    [_blurButton setImage:blurIcon forState:UIControlStateNormal];
    _arrowButton.tag = kAnnotationToolArrow;
    _boxButton.tag = kAnnotationToolBox;
    _blurButton.tag = kAnnotationToolBlur;
    [_arrowButton addTarget:self action:@selector(toolPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_boxButton addTarget:self action:@selector(toolPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_blurButton addTarget:self action:@selector(toolPressed:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)toolPressed:(UIButton *)sender {
    annotationToolChosen = (int)sender.tag;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1) {
        UITouch *touch = touches.anyObject;
        [self showNavViews:NO];
        if ([touch.view isKindOfClass:BSKAnnotationView.class]) {
            // Resizing or moving an existing annotation
        } else {
            // Creating a new annotation
            CGRect annotationFrame = {[touch locationInView:self.screenshotImageView], CGSizeMake(1, 1)};
            
            BOOL insertBelowCheckerboard = NO;
            
            if (annotationToolChosen == kAnnotationToolBox) {
                annotationInProgress = [[BSKAnnotationBoxView alloc] initWithFrame:annotationFrame];
            } else if (annotationToolChosen == kAnnotationToolArrow) {
                annotationInProgress = [[BSKAnnotationArrowView alloc] initWithFrame:annotationFrame];
            } else if (annotationToolChosen == kAnnotationToolBlur) {
                annotationInProgress = [[BSKAnnotationBlurView alloc] initWithFrame:annotationFrame baseImage:self.screenshotImageView.image];
                insertBelowCheckerboard = YES;
            } else {
                NSAssert1(0, @"Unknown tool %d chosen", annotationToolChosen);
            }
            
            annotationInProgress.annotationStrokeColor = [UIColor blackColor];
            annotationInProgress.annotationFillColor = _currentColor;
            
            if (insertBelowCheckerboard) {
                [self.screenshotImageView insertSubview:annotationInProgress belowSubview:self.gridOverlay];
            } else {
                [self.screenshotImageView addSubview:annotationInProgress];
            }
            annotationInProgress.startedDrawingAtPoint = annotationFrame.origin;
        }
    } else if (annotationInProgress) {
        [annotationInProgress removeFromSuperview];
        annotationInProgress = nil;
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1 && annotationInProgress) {
        UITouch *touch = touches.anyObject;
        CGPoint p1 = [touch locationInView:self.screenshotImageView], p2 = annotationInProgress.startedDrawingAtPoint;
        
        CGRect bounding = CGRectMake(MIN(p1.x, p2.x), MIN(p1.y, p2.y), ABS(p1.x - p2.x), ABS(p1.y - p2.y));
        
        if (bounding.size.height < 40) bounding.size.height = 40;
        if (bounding.size.width < 40) bounding.size.width = 40;
        annotationInProgress.frame = bounding;
        
        if ([annotationInProgress isKindOfClass:[BSKAnnotationArrowView class]]) {
            ((BSKAnnotationArrowView *)annotationInProgress).arrowEnd = p1;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showNavViews:YES];
    if (annotationInProgress) {
        CGSize annotationSize = annotationInProgress.bounds.size;
        if (MIN(annotationSize.width, annotationSize.height) < 5.0f ||
            (annotationSize.width < 32.0f && annotationSize.height < 32.0f)
            ) {
            [annotationInProgress removeFromSuperview];
        } else {
            [annotationInProgress initialScaleDone];
        }
        
        annotationInProgress = nil;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showNavViews:YES];
    if (annotationInProgress) {
        [annotationInProgress removeFromSuperview];
        annotationInProgress = nil;
    }
}

- (void)setCurrentColor:(UIColor *)currentColor {
    _currentColor = currentColor;
    [_toolsSegmentedControl setTintColor:_currentColor];
}

- (IBAction)colorButtonPressed:(UIButton *)sender
{
    self.currentColor = [sender backgroundColor];
}

- (IBAction)clearPressed:(id)sender
{
    _modifiedImage = _originalImage;
    _screenshotImageView.image = _originalImage;
}

- (void)showNavViews:(BOOL)visible {
    self.topToolbar.hidden = !visible;
    self.colorsToolbar.hidden = !visible;
}

- (IBAction)nextPressed:(id)sender
{
    _gridOverlay.hidden = YES;
    [self showNavViews:NO];
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, UIScreen.mainScreen.scale);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *annotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _gridOverlay.hidden = NO;
    [self showNavViews:YES];
    SRReportViewController *controller = [SRReportViewController composer];
    [SRReporter reporter].report.screenshot = annotatedImage;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)cancelPressed:(id)sender
{
    [SRReporter reporter].report.screenshot = nil;
    [[SRReporter reporter] viewControllerDidPressCancel:self];
    [[SRReporter reporter] dismissComposer];
}

- (IBAction)toolsValueChanged:(id)sender {
    annotationToolChosen = (int)_toolsSegmentedControl.selectedSegmentIndex;
}
@end
