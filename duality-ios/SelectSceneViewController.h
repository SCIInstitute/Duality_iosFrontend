//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "duality/SceneLoader.h"

#include <vector>

@interface SelectSceneViewController : UITableViewController
{
    SceneLoader* m_loader;
    std::vector<SceneMetadata> m_metadata;
    NSString* m_selectedScene;
}

-(id) initWithSceneLoader:(SceneLoader*)loader;

@end

