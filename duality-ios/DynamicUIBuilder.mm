//  Created by David McCann on 5/12/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DynamicUIBuilder.h"

@interface FloatStepper : UIStepper
{
@private
    UILabel* m_label;
    std::string m_objectName;
    FloatVariableInfo m_info;
    std::function<void(std::string, std::string, float)> m_callback;
}
-(id) initWithLabel:(UILabel *)label andObjectName:(const std::string&)objectName andInfo:(const FloatVariableInfo&)info andCallback:(std::function<void (std::string, std::string, float)>)callback;
-(void) stepToValue:(FloatStepper*)stepper;
@end

@implementation FloatStepper

-(id) initWithLabel:(UILabel *)label andObjectName:(const std::string&)objectName andInfo:(const FloatVariableInfo&)info andCallback:(std::function<void (std::string, std::string, float)>)callback
{
    self = [super init];
    m_label = label;
    m_objectName = objectName;
    m_info = info;
    m_callback = callback;
    [self addTarget:self action:@selector(stepToValue:) forControlEvents:UIControlEventValueChanged];
    return self;
}

-(void)stepToValue:(FloatStepper *)stepper
{
    m_label.text = [NSString stringWithFormat:@"%.02f", stepper.value];
    try {
        m_callback(m_objectName, m_info.name, self.value);
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

@end

@interface EnumStepper : UIStepper
{
@private
    UILabel* m_label;
    std::string m_objectName;
    EnumVariableInfo m_info;
    std::function<void(std::string, std::string, std::string)> m_callback;
}
-(id) initWithLabel:(UILabel*)label andObjectName:(const std::string&)objectName andInfo:(const EnumVariableInfo&)info  andCallback:(std::function<void (std::string, std::string, std::string)>)callback;
-(void) stepToValue:(FloatStepper*)stepper;
@end

@implementation EnumStepper

-(id) initWithLabel:(UILabel *)label andObjectName:(const std::string&)objectName andInfo:(const EnumVariableInfo&)info andCallback:(std::function<void (std::string, std::string, std::string)>)callback
{
    self = [super init];
    m_label = label;
    m_objectName = objectName;
    m_info = info;
    m_callback = callback;
    [self addTarget:self action:@selector(stepToValue:) forControlEvents:UIControlEventValueChanged];
    return self;
}

-(void)stepToValue:(FloatStepper *)stepper
{
    std::string value = m_info.values[(int)stepper.value];
    m_label.text = [NSString stringWithUTF8String:value.c_str()];
    try {
        m_callback(m_objectName, m_info.name, value);
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

@end


UIStackView* buildFloatVariableStackView(const std::string& objectName, const FloatVariableInfo& info, std::function<void(std::string, std::string, float)> floatCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentBottom;
    stackView.spacing = 10;
    
    UILabel* nameLabel = [[UILabel alloc] init];
    nameLabel.text = [NSString stringWithUTF8String:info.name.c_str()];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    //[nameLabel.widthAnchor constraintEqualToConstant:120.0].active = true;
    [stackView addArrangedSubview:nameLabel];
    
    UILabel* valueLabel = [[UILabel alloc] init];
    valueLabel.text = [NSString stringWithFormat:@"%.02f", info.defaultValue];
    valueLabel.textAlignment = NSTextAlignment::NSTextAlignmentRight;
    valueLabel.textColor = [UIColor whiteColor];
    valueLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [valueLabel.widthAnchor constraintEqualToConstant:80.0].active = true;
    [stackView addArrangedSubview:valueLabel];
    
    FloatStepper* stepper = [[FloatStepper alloc] initWithLabel:valueLabel andObjectName:objectName andInfo:info andCallback:floatCallback];
    stepper.minimumValue = info.lowerBound;
    stepper.maximumValue = info.upperBound;
    stepper.stepValue = info.stepSize;
    stepper.value = info.defaultValue;
    [stackView addArrangedSubview:stepper];

    [valueLabel.rightAnchor constraintEqualToAnchor:stepper.leftAnchor constant:-20].active = true;
    
    return stackView;
}

UIStackView* buildEnumVariableStackView(const std::string& objectName, const EnumVariableInfo& info, std::function<void(std::string, std::string, std::string)> enumCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentBottom;
    stackView.spacing = 10;
    
    UILabel* nameLabel = [[UILabel alloc] init];
    nameLabel.text = [NSString stringWithUTF8String:info.name.c_str()];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    //[nameLabel.widthAnchor constraintEqualToConstant:120.0].active = true;
    [stackView addArrangedSubview:nameLabel];
    
    UILabel* valueLabel = [[UILabel alloc] init];
    auto valueIndex = std::distance(begin(info.values), std::find(begin(info.values), end(info.values), info.defaultValue));
    NSString* value = [NSString stringWithUTF8String:info.values[valueIndex].c_str()];
    valueLabel.text = value;
    valueLabel.textAlignment = NSTextAlignment::NSTextAlignmentRight;
    valueLabel.textColor = [UIColor whiteColor];
    valueLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [valueLabel.widthAnchor constraintEqualToConstant:80.0].active = true;
    [stackView addArrangedSubview:valueLabel];
    
    EnumStepper* stepper = [[EnumStepper alloc] initWithLabel:valueLabel
                                                andObjectName:objectName
                                                andInfo:info andCallback:enumCallback];
    stepper.minimumValue = 0;
    stepper.maximumValue = info.values.size() - 1;
    stepper.stepValue = 1;
    stepper.value = valueIndex;
    [stackView addArrangedSubview:stepper];
    
    [valueLabel.rightAnchor constraintEqualToAnchor:stepper.leftAnchor constant:-20].active = true;
    
    return stackView;
}

UIStackView* buildObjectStackView(const std::string& name, const VariableInfos& infos, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentLeading;
    stackView.spacing = 5;
    
    UILabel* objectLabel = [[UILabel alloc] init];
    objectLabel.text = [NSString stringWithUTF8String:name.c_str()];
    objectLabel.textColor = [UIColor whiteColor];
    objectLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [stackView addArrangedSubview:objectLabel];
    
    for (size_t i = 0; i < infos.floatInfos.size() + infos.enumInfos.size(); ++i) {
        auto floatIt = std::find_if(begin(infos.floatInfos), end(infos.floatInfos),
                               [i](const FloatVariableInfo& info) { return info.index == i; });
        if (floatIt != end(infos.floatInfos)) {
            UIStackView* variableStackView = buildFloatVariableStackView(name, *floatIt, floatCallback);
            variableStackView.translatesAutoresizingMaskIntoConstraints = false;
            
            
            [stackView addArrangedSubview:variableStackView];
            
            // TEST
            [variableStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;

        } else {
            auto enumIt = std::find_if(begin(infos.enumInfos), end(infos.enumInfos),
                                   [i](const EnumVariableInfo& info) { return info.index == i; });
            assert(enumIt != end(infos.enumInfos));
            UIStackView* variableStackView = buildEnumVariableStackView(name, *enumIt, enumCallback);
            variableStackView.translatesAutoresizingMaskIntoConstraints = false;
            
            [stackView addArrangedSubview:variableStackView];
            
            // TEST
            [variableStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;
        }
    }
    return stackView;
}

UIStackView* buildStackViewFromVariableMap(const VariableInfoMap& infoMap, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentLeading;
    stackView.spacing = 50;
    
    for (const auto& object : infoMap) {
        if (!object.second.floatInfos.empty() || !object.second.enumInfos.empty()) {
            UIStackView* objectStackView = buildObjectStackView(object.first, object.second, floatCallback, enumCallback);
            objectStackView.translatesAutoresizingMaskIntoConstraints = false;
            [stackView addArrangedSubview:objectStackView];
            
            [objectStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;
        }
    }
    return stackView;
}
