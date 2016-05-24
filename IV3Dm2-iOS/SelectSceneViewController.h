//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "Scene/SceneMetadata.h"

#include <vector>

@interface SelectSceneViewController : UITableViewController
{
    std::vector<SceneMetadata> m_metadata;
    NSString* m_selectedScene;
}

-(void) setMetadata:(std::vector<SceneMetadata>)metadata;

@end

