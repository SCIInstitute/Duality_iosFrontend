//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "duality/Settings.h"

#include <memory>

class SceneLoader;

@interface SettingsViewController : UITableViewController
{
    std::shared_ptr<Settings> m_settings;
    UITextField* m_rField;
    UITextField* m_gField;
    UITextField* m_bField;
}

- (id) initWithSettings:(std::shared_ptr<Settings>)settings;

@end