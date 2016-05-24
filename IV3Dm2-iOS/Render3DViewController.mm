//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppDelegate.h"
#import "Render3DViewController.h"
#import "DynamicUIBuilder.h"

#include "IVDA/iOS.h"
#include "Scene/RenderDispatcher.h"
#include "Scene/ScreenInfo.h"
#include "Scene/Scene.h"

@implementation Render3DViewController

@synthesize context = _context;

-(void) setScene:(Scene*)scene
{
    m_scene = scene;
    auto variableMap = m_scene->variableMap();
    if (!variableMap.empty()) {
        UIStackView* stackView = buildStackViewFromVariableMap(variableMap);
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        [self.view addSubview:stackView];
        [stackView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:20.0].active = true;
        [stackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0].active = true;
    }
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
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.context) {
        NSLog(@"Failed to create OpenGLES context");
    }

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

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    m_rendererDispatcher = std::make_unique<RenderDispatcher>([self screenInfo]);
    m_arcBall.SetWindowSize(uint32_t(self.view.bounds.size.width), uint32_t(self.view.bounds.size.height));
}

-(void) reset
{
    m_scene = nullptr;
    glClear(GL_COLOR_BUFFER_BIT);
}

// Drawing
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (m_scene) {
        GLMatrix modelView = m_scene->modelViewMatrix();
        m_rendererDispatcher->setModelView(&modelView);
        m_rendererDispatcher->startDraw();
        m_scene->dispatch(*m_rendererDispatcher);
        m_rendererDispatcher->finishDraw();
    }
    [view bindDrawable];
}

// Interaction
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (m_scene == nullptr) {
        return;
    }
    
    NSUInteger numTouches = [[event allTouches] count];
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
    if (m_scene == nullptr) {
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
        IVDA::Mat4f rotation = m_arcBall.Drag(IVDA::Vec2ui(touchPoint.x, touchPoint.y)).ComputeRotation();
        m_scene->addRotation(rotation);
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
        
        [self translateSceneWith:touchPos1 andWith:touchPos2];
        
        m_touchPos1 = touchPos1;
        m_touchPos2 = touchPos2;
    }
}

- (void) translateSceneWith:(const IVDA::Vec2f&)touchPos1 andWith:(const IVDA::Vec2f&)touchPos2 {
    IVDA::Vec2f c1((m_touchPos1.x + m_touchPos2.x) / 2, (m_touchPos1.y + m_touchPos2.y) / 2);
    IVDA::Vec2f c2((touchPos1.x + touchPos2.x) / 2, (touchPos1.y + touchPos2.y) / 2);
    IVDA::Vec2f translation(c2.x - c1.x, -(c2.y - c1.y));
    m_scene->addTranslation(translation);
}

@end
