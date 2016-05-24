//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextSettingCell;

class SceneLoader;

@interface SettingsViewController : UITableViewController
{
    NSMutableArray<TextSettingCell*>* m_textSettingCells;
}

- (id) init;

@end