//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#include "duality/SceneLoader.h"
#include "src/IVDA/ArcBall.h"
#include "IVDA/Vectors.h"

#include <memory>

class Scene;
class RenderDispatcher2D;

@interface Render2DViewController : GLKViewController
{
@protected
    std::shared_ptr<SceneController2D> m_sceneController;
    NSUInteger m_numFingersDown;
    IVDA::Vec2f m_touchPos1;
    IVDA::Vec2f m_touchPos2;
    UIStackView* m_dynamicUI;
    UISlider* m_sliceSelector;
    UITextView* m_sliceLabel;
    UIButton* m_toggleAxisButton;
}

-(void) setSceneController:(std::shared_ptr<SceneController2D>)controller;
-(void) reset;
-(void) setup;

@property (nonatomic, retain) EAGLContext *context;

@end