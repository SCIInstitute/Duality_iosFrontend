//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#include "duality/SceneLoader.h"
#include "src/IVDA/ArcBall.h"
#include "IVDA/Vectors.h"

#include <memory>

@interface Render3DViewController : GLKViewController
{
@protected
    std::shared_ptr<SceneController3D> m_sceneController;
    NSUInteger m_numFingersDown;
    IVDA::Vec2f m_touchPos1;
    IVDA::Vec2f m_touchPos2;
    IVDA::ArcBall m_arcBall;
    UIStackView* m_dynamicUI;
    UIProgressView* m_updateProgress;
    bool m_initialized;
}

-(void) setSceneController:(std::shared_ptr<SceneController3D>)controller;
-(void) reset;
-(void) setup;

@property (nonatomic, retain) EAGLContext *context;

@end