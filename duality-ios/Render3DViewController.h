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
    SceneLoader* m_loader;
    std::weak_ptr<SceneController3D> m_sceneController;
    IVDA::Vec2f m_touchPos1;
    IVDA::Vec2f m_touchPos2;
    IVDA::ArcBall m_arcBall;
    UIStackView* m_dynamicUI;
}

-(id) initWithSceneLoader:(SceneLoader*)loader;
-(void) reset;

@property (nonatomic, retain) EAGLContext *context;

@end