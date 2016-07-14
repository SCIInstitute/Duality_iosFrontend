//  Created by David McCann on 5/12/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DynamicUIBuilder.h"

@interface FloatStepper : UIStepper
{
@private
    UILabel* m_label;
    std::string m_nodeName;
    std::string m_variableName;
    std::function<void(std::string, std::string, float)> m_callback;
}
-(id) initWithLabel:(UILabel *)label andNodeName:(const std::string&)nodeName andVariableName:(const std::string&)variableName andCallback:(std::function<void (std::string, std::string, float)>)callback;
-(void) stepToValue:(FloatStepper*)stepper;
@end

@implementation FloatStepper

-(id) initWithLabel:(UILabel *)label andNodeName:(const std::string&)nodeName andVariableName:(const std::string&)variableName andCallback:(std::function<void (std::string, std::string, float)>)callback
{
    self = [super init];
    m_label = label;
    m_nodeName = nodeName;
    m_variableName = variableName;
    m_callback = callback;
    [self addTarget:self action:@selector(stepToValue:) forControlEvents:UIControlEventValueChanged];
    return self;
}

-(void)stepToValue:(FloatStepper *)stepper
{
    m_label.text = [NSString stringWithFormat:@"%.02f", stepper.value];
    try {
        m_callback(m_nodeName, m_variableName, self.value);
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
    std::string m_nodeName;
    std::string m_variableName;
    std::vector<std::string> m_values;
    std::function<void(std::string, std::string, std::string)> m_callback;
}
-(id) initWithLabel:(UILabel*)label andNodeName:(const std::string&)nodeName andVariableName:(const std::string&)variableName andValues:(const std::vector<std::string>&)values andCallback:(std::function<void (std::string, std::string, std::string)>)callback;
-(void) stepToValue:(FloatStepper*)stepper;
@end

@implementation EnumStepper

-(id) initWithLabel:(UILabel *)label andNodeName:(const std::string&)nodeName andVariableName:(const std::string&)variableName andValues:(const std::vector<std::string>&)values andCallback:(std::function<void (std::string, std::string, std::string)>)callback
{
    self = [super init];
    m_label = label;
    m_nodeName = nodeName;
    m_variableName = variableName;
    m_values = values;
    m_callback = callback;
    [self addTarget:self action:@selector(stepToValue:) forControlEvents:UIControlEventValueChanged];
    return self;
}

-(void)stepToValue:(FloatStepper *)stepper
{
    std::string value = m_values[(int)stepper.value];
    m_label.text = [NSString stringWithUTF8String:value.c_str()];
    try {
        m_callback(m_nodeName, m_variableName, value);
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

@end


UIStackView* buildFloatVariableStackView(const std::string& nodeName, const FloatVariable& var, std::function<void(std::string, std::string, float)> floatCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentBottom;
    stackView.spacing = 10;
    
    UILabel* nameLabel = [[UILabel alloc] init];
    if (!var.label.isNull()) {
        nameLabel.text = [NSString stringWithUTF8String:var.label.get().c_str()];
    } else {
        nameLabel.text = [NSString stringWithUTF8String:var.name.c_str()];
    }
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [stackView addArrangedSubview:nameLabel];
    
    UILabel* valueLabel = [[UILabel alloc] init];
    valueLabel.text = [NSString stringWithFormat:@"%.02f", var.value];
    valueLabel.textAlignment = NSTextAlignment::NSTextAlignmentRight;
    valueLabel.textColor = [UIColor whiteColor];
    valueLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [valueLabel.widthAnchor constraintEqualToConstant:80.0].active = true;
    [stackView addArrangedSubview:valueLabel];
    
    FloatStepper* stepper = [[FloatStepper alloc] initWithLabel:valueLabel andNodeName:nodeName andVariableName:var.name andCallback:floatCallback];
    stepper.minimumValue = var.info.lowerBound;
    stepper.maximumValue = var.info.upperBound;
    stepper.stepValue = var.info.stepSize;
    stepper.value = var.value;
    [stackView addArrangedSubview:stepper];
    [valueLabel.rightAnchor constraintEqualToAnchor:stepper.leftAnchor constant:-20].active = true;
    return stackView;
}

UIStackView* buildEnumVariableStackView(const std::string& nodeName, const EnumVariable& var, std::function<void(std::string, std::string, std::string)> enumCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentBottom;
    stackView.spacing = 10;
    
    UILabel* nameLabel = [[UILabel alloc] init];
    if (!var.label.isNull()) {
        nameLabel.text = [NSString stringWithUTF8String:var.label.get().c_str()];
    } else {
        nameLabel.text = [NSString stringWithUTF8String:var.name.c_str()];
    }
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [stackView addArrangedSubview:nameLabel];
    
    UILabel* valueLabel = [[UILabel alloc] init];
    auto valueIndex = std::distance(begin(var.info.values), std::find(begin(var.info.values), end(var.info.values), var.value));
    NSString* value = [NSString stringWithUTF8String:var.info.values[valueIndex].c_str()];
    valueLabel.text = value;
    valueLabel.textAlignment = NSTextAlignment::NSTextAlignmentRight;
    valueLabel.textColor = [UIColor whiteColor];
    valueLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [valueLabel.widthAnchor constraintEqualToConstant:80.0].active = true;
    [stackView addArrangedSubview:valueLabel];
    
    EnumStepper* stepper = [[EnumStepper alloc] initWithLabel:valueLabel
                                                andNodeName:nodeName
                                                andVariableName:var.name
                                                andValues:var.info.values
                                                andCallback:enumCallback];
    stepper.minimumValue = 0;
    stepper.maximumValue = var.info.values.size() - 1;
    stepper.stepValue = 1;
    stepper.value = valueIndex;
    [stackView addArrangedSubview:stepper];
    [valueLabel.rightAnchor constraintEqualToAnchor:stepper.leftAnchor constant:-20].active = true;
    return stackView;
}

UIStackView* buildObjectStackView(const std::string& name, const Variables& variables, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback)
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
    
    for (size_t i = 0; i < variables.floatVariables.size() + variables.enumVariables.size(); ++i) {
        auto floatIt = std::find_if(begin(variables.floatVariables), end(variables.floatVariables),
                               [i](const FloatVariable& var) { return i == var.info.index; });
        if (floatIt != end(variables.floatVariables)) {
            UIStackView* variableStackView = buildFloatVariableStackView(name, *floatIt, floatCallback);
            variableStackView.translatesAutoresizingMaskIntoConstraints = false;
            [stackView addArrangedSubview:variableStackView];
            [variableStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;
        } else {
            auto enumIt = std::find_if(begin(variables.enumVariables), end(variables.enumVariables),
                                       [i](const EnumVariable& var) { return i == var.info.index; });
            assert(enumIt != end(variables.enumVariables));
            UIStackView* variableStackView = buildEnumVariableStackView(name, *enumIt, enumCallback);
            variableStackView.translatesAutoresizingMaskIntoConstraints = false;
            [stackView addArrangedSubview:variableStackView];
            [variableStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;
        }
    }
    return stackView;
}

UIStackView* buildStackViewFromVariableMap(const VariableMap& variables, std::function<void(std::string, std::string, float)> floatCallback, std::function<void(std::string, std::string, std::string)> enumCallback)
{
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentLeading;
    stackView.spacing = 50;
    
    for (const auto& var : variables) {
        if (!var.second.floatVariables.empty() || !var.second.enumVariables.empty()) {
            UIStackView* objectStackView = buildObjectStackView(var.first, var.second, floatCallback, enumCallback);
            objectStackView.translatesAutoresizingMaskIntoConstraints = false;
            [stackView addArrangedSubview:objectStackView];
            [objectStackView.rightAnchor constraintEqualToAnchor:stackView.rightAnchor].active = true;
        }
    }
    return stackView;
}
