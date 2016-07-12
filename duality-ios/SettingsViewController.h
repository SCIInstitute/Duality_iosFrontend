//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "duality/Settings.h"

#include <memory>

@class TextSettingCell;

class SceneLoader;

@interface SettingsViewController : UITableViewController
{
    NSMutableArray<TextSettingCell*>* m_textSettingCells;
    std::shared_ptr<Settings> m_settings;
}

- (id) initWithSettings:(std::shared_ptr<Settings>)settings;

@end