//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "duality/VariableInfo.h"

#include <functional>

UIStackView* buildStackViewFromVariableMap(const VariableInfoMap& infoMap, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback);