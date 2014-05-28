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

@interface SRImageEditorViewController ()
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, strong) UIImage *modifiedImage;
@property (nonatomic, assign) NSInteger lineSize;
@property (weak, nonatomic) IBOutlet UIView *toolsView;
@property (weak, nonatomic) IBOutlet UILabel *lineSizeLabel;
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
    _lineSize = 5;
    [self updateLineSizeLabel];
    _screenshotImageView.image = _originalImage;
    _modifiedImage = _originalImage;
    _currentColor = [UIColor blackColor];
    UIBarButtonItem *nextButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextPressed:)];
    self.navigationItem.rightBarButtonItem = nextButtonItem;
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    _screenshotImageView.frame = CGRectMake(0, 0, _toolsView.frame.origin.x, CGRectGetHeight(self.view.bounds));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    if (CGRectContainsPoint(_screenshotImageView.frame, touchLocation))
    {
        lastPoint = [self pointByApplyingRatio:[touch locationInView:_screenshotImageView]];
    }
}



- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    mouseSwiped = YES;
    CGPoint currentPoint;
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    if (CGRectContainsPoint(_screenshotImageView.frame, touchLocation))
    {
        currentPoint = [self pointByApplyingRatio:[touch locationInView:_screenshotImageView]];
        _modifiedImage = [self imageByDrawingLineBetween:lastPoint and:currentPoint];
        _screenshotImageView.image = _modifiedImage;
    }
    lastPoint = currentPoint;
    mouseMoved++;
    if (mouseMoved == 10) {
        mouseMoved = 0;
    }
}

- (CGPoint)pointByApplyingRatio:(CGPoint)point
{
    CGSize viewSize = _screenshotImageView.frame.size;
    CGSize imageSize = _originalImage.size;
    CGSize ratioSize = CGSizeMake(viewSize.width/imageSize.width, viewSize.height / imageSize.height);
    return CGPointMake(point.x/ratioSize.width, point.y/ratioSize.height);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(!mouseSwiped) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.view];
        if (CGRectContainsPoint(_screenshotImageView.frame, touchLocation)) {
            _modifiedImage = [self imageByDrawingLineBetween:lastPoint and:lastPoint];
            _screenshotImageView.image = _modifiedImage;
        }
    }
}

- (UIImage *)imageByDrawingLineBetween:(CGPoint)startPoint and:(CGPoint)endPoint
{
    UIGraphicsBeginImageContextWithOptions(_originalImage.size, false, 2);
    [_modifiedImage drawInRect:CGRectMake(0, 0, _originalImage.size.width, _originalImage.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), _lineSize);
    [_currentColor setStroke];
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), startPoint.x, startPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), endPoint.x, endPoint.y);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (IBAction)colorButtonPressed:(UIButton *)sender
{
    _currentColor = [sender backgroundColor];
}

- (IBAction)clearPressed:(id)sender
{
    _modifiedImage = _originalImage;
    _screenshotImageView.image = _originalImage;
}

- (void)nextPressed:(id)sender
{
    SRReportViewController *controller = [SRReportViewController composer];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"screenshot.png"];
    [UIImagePNGRepresentation(_screenshotImageView.image) writeToFile:filePath atomically:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)cancelPressed:(id)sender
{
    [[SRReporter reporter] viewControllerDidPressCancel:self];
}


#pragma mark - Line Size
- (void)updateLineSizeLabel
{
    _lineSizeLabel.text = [NSString stringWithFormat:@"%ld", (long)_lineSize];
}

- (IBAction)sizeUpPressed:(id)sender
{
    _lineSize++;
    [self updateLineSizeLabel];
}
- (IBAction)sizeDownPressed:(id)sender
{
    _lineSize = MAX(_lineSize-1, 0);
    [self updateLineSizeLabel];
}
@end
