//  Created by David McCann on 5/9/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "duality/InputVariable.h"

#include <functional>

UIStackView* buildStackViewFromVariableMap(const VariableMap& variables, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback, std::function<void(std::string, bool)> nodeEnabledCallback);