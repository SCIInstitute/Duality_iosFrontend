//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#include "IVDA/Vectors.h"
#include "IVDA/ArcBall.h"

#include <memory>

class Scene;
class RenderDispatcher2D;

@interface Render2DViewController : GLKViewController
{
@protected
    Scene* m_scene;
    std::unique_ptr<RenderDispatcher2D> m_rendererDispatcher;
    IVDA::Vec2f m_touchPos1;
    IVDA::Vec2f m_touchPos2;
    IVDA::ArcBall m_arcBall;
    UIStackView* m_dynamicUI;
    UISlider* m_sliceSelector;
}

-(void) setScene:(Scene*)scene;
-(void) reset;

@property (nonatomic, retain) EAGLContext *context;

@end