//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Render2DViewController.h"
#import "DynamicUIBuilder.h"

#include "src/IVDA/iOS.h"
#include "src/IVDA/GLInclude.h"
#include "duality/ScreenInfo.h"

@implementation Render2DViewController

@synthesize context = _context;

-(id) initWithSceneLoader:(SceneLoader*)loader
{
    self = [super init];
    m_loader = loader;
    return self;
}

- (ScreenInfo)screenInfo
{
    float scale = iOS::DetectScreenScale();
    float iPad = iOS::DetectIPad() ? 2 : 1;
    float xOffset = 0.0f;
    float yOffset = 0.0f;
    float windowWidth = 1.0f;
    float windowHeight = 1.0f;
    unsigned int width = scale * self.view.bounds.size.width;
    unsigned int height = scale * self.view.bounds.size.height;
    ScreenInfo screenInfo(width, height, xOffset, yOffset,
                          /*m_pSettings->getUseRetinaResolution() ? 1.0 : fScale*/ scale, iPad * scale * 2, windowWidth, windowHeight);
    return screenInfo;
}

- (void)initGL
{
    [EAGLContext setCurrentContext:self.context];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.multipleTouchEnabled = YES;
    
    GL(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
    GL(glClearColor(0.0f, 0.0f, 0.0f, 1.0f));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGL];
    
    m_sliceSelector = [[UISlider alloc] init];
    m_sliceSelector.alpha = 0.8;
    [m_sliceSelector addTarget:self action:@selector(setSlice) forControlEvents:UIControlEventValueChanged];
    m_sliceSelector.backgroundColor = [UIColor clearColor];
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * 0.5);
    m_sliceSelector.transform = trans;
    m_sliceSelector.frame = CGRectMake(self.view.frame.size.width - 60, 50, 50, self.view.frame.size.height - 100);
    
    m_sliceLabel = [[UITextView alloc] init];
    [m_sliceLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [m_sliceLabel setEditable:NO];
    [m_sliceLabel setTextColor:[UIColor whiteColor]];
    [m_sliceLabel setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
    [m_sliceLabel setTextAlignment:NSTextAlignmentCenter];
    [m_sliceLabel setUserInteractionEnabled:NO];
    m_sliceLabel.frame = CGRectMake(self.view.frame.size.width - 180, 174, 120, 40);
    
    m_toggleAxisButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [m_toggleAxisButton addTarget:self action:@selector(toggleAxis) forControlEvents:UIControlEventTouchDown];
    [m_toggleAxisButton setTitleColor:m_toggleAxisButton.tintColor forState:UIControlStateNormal];
    [m_toggleAxisButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
    [m_toggleAxisButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
    m_toggleAxisButton.frame = CGRectMake(self.view.frame.size.width - 180, 50, 120, 40);
    
    [self.view addSubview:m_sliceSelector];
    [self.view addSubview:m_sliceLabel];
    [self.view addSubview:m_toggleAxisButton];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (m_loader->isSceneLoaded()) {
        if (m_sceneController.expired()) {
            m_sceneController = m_loader->sceneController2D();
        }
        m_sceneController.lock()->updateScreenInfo([self screenInfo]);
        auto variableMap = m_sceneController.lock()->variableInfoMap();
        if (!variableMap.empty()) {
            if (m_dynamicUI) {
                [m_dynamicUI removeFromSuperview];
            }
            m_dynamicUI = buildStackViewFromVariableMap(variableMap,
                [=](std::string objectName, std::string variableName, float value) {
                    m_sceneController.lock()->setVariable(objectName, variableName, value);
                },
                [=](std::string objectName, std::string variableName, std::string value) {
                    m_sceneController.lock()->setVariable(objectName, variableName, value);
                });
            m_dynamicUI.translatesAutoresizingMaskIntoConstraints = false;
            [self.view addSubview:m_dynamicUI];
            [m_dynamicUI.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:20.0].active = true;
            [m_dynamicUI.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0].active = true;
        }
        auto minMaxForAxis = m_sceneController.lock()->minMaxForCurrentAxis();
        m_sliceSelector.minimumValue = minMaxForAxis.first;
        m_sliceSelector.maximumValue = minMaxForAxis.second;
        m_sliceSelector.value = m_sceneController.lock()->slice();
        m_sliceLabel.text = [NSString stringWithFormat:@"%.4f", m_sliceSelector.value];
        
        NSString* axisLabel = [NSString stringWithUTF8String:m_sceneController.lock()->labelForCurrentAxis().c_str()];
        [m_toggleAxisButton setTitle:axisLabel forState:UIControlStateNormal];
    }
}

-(void) reset
{
    glClear(GL_COLOR_BUFFER_BIT);
}

-(void) setSlice
{
    std::shared_ptr<SceneController2D>(m_sceneController)->setSlice(m_sliceSelector.value);
    m_sliceLabel.text = [NSString stringWithFormat:@"%.4f", m_sliceSelector.value];
}

-(void) toggleAxis
{
    std::shared_ptr<SceneController2D>(m_sceneController)->toggleAxis();

    // set slice to value that corresponds to the current slider position
    const float oldMin = m_sliceSelector.minimumValue;
    const float oldMax = m_sliceSelector.maximumValue;
    const float oldDistance = oldMax - oldMin;
    const float oldRelValue = m_sliceSelector.value - oldMin;
    const float epsilon = 0.000001f;
    const auto minMaxForAxis = m_sceneController.lock()->minMaxForCurrentAxis();
    const float newDistance = minMaxForAxis.second - minMaxForAxis.first;
    if (std::abs(oldDistance) > epsilon && std::abs(newDistance) > epsilon) {
        const float amount = oldRelValue / oldDistance;
        m_sliceSelector.value = (amount * newDistance) + minMaxForAxis.first;
        m_sliceLabel.text = [NSString stringWithFormat:@"%.4f", m_sliceSelector.value];
    }
    m_sliceSelector.minimumValue = minMaxForAxis.first;
    m_sliceSelector.maximumValue = minMaxForAxis.second;

    NSString* axisLabel = [NSString stringWithUTF8String:m_sceneController.lock()->labelForCurrentAxis().c_str()];
    [m_toggleAxisButton setTitle:axisLabel forState:UIControlStateNormal];
}

// Drawing
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (!m_sceneController.expired()) {
        m_sceneController.lock()->render();
    }
    [view bindDrawable];
}

// Interaction
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (m_sceneController.expired()) {
        return;
    }
    
    NSUInteger numTouches = [[event allTouches] count];
    if (numTouches == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
        m_touchPos1 = IVDA::Vec2f(touchPoint.x/self.view.frame.size.width,
                                  touchPoint.y/self.view.frame.size.height);
    }
    else if (numTouches == 2) {
        NSArray* allTouches = [[event allTouches] allObjects];
        CGPoint touchPoint1 = [[allTouches objectAtIndex:0] locationInView:self.view];
        CGPoint touchPoint2 = [[allTouches objectAtIndex:1] locationInView:self.view];
        m_touchPos1 = IVDA::Vec2f(touchPoint1.x/self.view.frame.size.width,
                                  touchPoint1.y/self.view.frame.size.height);
        m_touchPos2 = IVDA::Vec2f(touchPoint2.x/self.view.frame.size.width,
                                  touchPoint2.y/self.view.frame.size.height);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (m_sceneController.expired()) {
        return;
    }
    
    UITouch* touch = [[event touchesForView:self.view] anyObject];
    CGPoint pos = [touch locationInView:self.view];
    CGPoint prev = [touch previousLocationInView:self.view];
    NSUInteger numTouches = [[event allTouches] count];
    
    if (pos.x == prev.x && pos.y == prev.y && numTouches == 1) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (numTouches == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
        IVDA::Vec2f touchPos(touchPoint.x/self.view.frame.size.width,
                             touchPoint.y/self.view.frame.size.height);
        
        [self transformOneTouch:touchPos];
        
        m_touchPos1 = touchPos;
    }
    else if (numTouches == 2) {
        NSArray* allTouches = [[event allTouches] allObjects];
        CGPoint touchPoint1 = [[allTouches objectAtIndex:0] locationInView:self.view];
        CGPoint touchPoint2 = [[allTouches objectAtIndex:1] locationInView:self.view];
        
        IVDA::Vec2f touchPos1(touchPoint1.x/self.view.frame.size.width,
                              touchPoint1.y/self.view.frame.size.height);
        IVDA::Vec2f touchPos2(touchPoint2.x/self.view.frame.size.width,
                              touchPoint2.y/self.view.frame.size.height);
        
        [self transformTwoTouch:touchPos1 andWith:touchPos2];
        
        m_touchPos1 = touchPos1;
        m_touchPos2 = touchPos2;
    }
}

-(void) transformOneTouch:(const IVDA::Vec2f&)touchPos
{
    IVDA::Vec2f translation(touchPos.x - m_touchPos1.x, -(touchPos.y - m_touchPos1.y));
    m_sceneController.lock()->addTranslation(translation);
    m_touchPos1 = touchPos;
}

- (void) transformTwoTouch:(const IVDA::Vec2f&)touchPos1 andWith:(const IVDA::Vec2f&)touchPos2
{
    IVDA::Vec2f d1(m_touchPos1.x - m_touchPos2.x, m_touchPos1.y - m_touchPos2.y);
    IVDA::Vec2f d2(touchPos1.x - touchPos2.x, touchPos1.y - touchPos2.y);
    float l1 = d1.length();
    float l2 = d2.length();
    m_sceneController.lock()->addZoom(l2-l1);
    
    float angle = 0;
    if (l1 > 0 && l2 > 0) {
        d1 /= l1;
        d2 /= l2;
        angle = atan2(d1.y,d1.x) - atan2(d2.y,d2.x);
    }
    m_sceneController.lock()->addRotation(angle);
}

@end
