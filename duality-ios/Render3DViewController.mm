//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Render3DViewController.h"
#import "DynamicUIBuilder.h"

#include "duality/ScreenInfo.h"
#include "src/IVDA/GLInclude.h" // FIXME: move file
#include "src/IVDA/iOS.h" // FIXME: move file

@implementation Render3DViewController

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
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    try {
        if (m_loader->isSceneLoaded()) {
            if (m_sceneController.expired()) {
                m_sceneController = m_loader->sceneController3D();
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
                    });            m_dynamicUI.translatesAutoresizingMaskIntoConstraints = false;
                [self.view addSubview:m_dynamicUI];
                [m_dynamicUI.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:20.0].active = true;
                [m_dynamicUI.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0].active = true;
            }
        }
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    m_arcBall.SetWindowSize(uint32_t(self.view.bounds.size.width), uint32_t(self.view.bounds.size.height));
}

-(void) reset
{
    glClear(GL_COLOR_BUFFER_BIT);
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
    if (m_numFingersDown > numTouches) {
        // this prevents the scene from "jumping" when a two-finger action was performed and one finger is lifted
        return;
    }
    
    if (numTouches == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
        m_arcBall.Click(IVDA::Vec2ui(touchPoint.x, touchPoint.y));
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
    if (m_numFingersDown > numTouches) {
        // this prevents the scene from "jumping" when a two-finger action was performed and one finger is lifted
        return;
    }

    if (pos.x == prev.x && pos.y == prev.y && numTouches == 1) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (numTouches == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
        IVDA::Mat4f rotation = m_arcBall.Drag(IVDA::Vec2ui(touchPoint.x, touchPoint.y)).ComputeRotation();
        m_sceneController.lock()->addRotation(rotation);
        m_arcBall.Click(IVDA::Vec2ui(touchPoint.x, touchPoint.y));
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

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    m_numFingersDown = [[event allTouches] count];
}

- (void) transformTwoTouch:(const IVDA::Vec2f&)touchPos1 andWith:(const IVDA::Vec2f&)touchPos2 {
    IVDA::Vec2f c1((m_touchPos1.x + m_touchPos2.x) / 2, (m_touchPos1.y + m_touchPos2.y) / 2);
    IVDA::Vec2f c2((touchPos1.x + touchPos2.x) / 2, (touchPos1.y + touchPos2.y) / 2);
    IVDA::Vec2f translation(c2.x - c1.x, -(c2.y - c1.y));
    m_sceneController.lock()->addTranslation(translation);
    
    IVDA::Vec2f d1(m_touchPos1.x - m_touchPos2.x, m_touchPos1.y - m_touchPos2.y);
    IVDA::Vec2f d2(touchPos1.x - touchPos2.x, touchPos1.y - touchPos2.y);
    float l1 = d1.length();
    float l2 = d2.length();
    m_sceneController.lock()->addZoom(l2-l1);
}

@end
