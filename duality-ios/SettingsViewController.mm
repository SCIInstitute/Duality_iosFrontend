//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights
//  reserved.
//

#import "SettingsObject.h"
#import "SettingsViewController.h"

#include "src/duality/DataCache.h"

@implementation SettingsViewController

- (id)createTextCell:(UITableViewCell *)cell
        andLabelText:(NSString *)labelText
         andEditText:(NSString *)editText
         andSelector:(SEL)selector {
  UITextField *textField = [[UITextField alloc] init];
  textField.textAlignment = NSTextAlignmentRight;
  textField.text = editText;
  [textField addTarget:self
                action:selector
      forControlEvents:UIControlEventEditingDidEnd];

  UILabel *label = [[UILabel alloc] init];
  label.text = labelText;

  [cell.contentView addSubview:label];
  [cell.contentView addSubview:textField];

  label.translatesAutoresizingMaskIntoConstraints = NO;
  textField.translatesAutoresizingMaskIntoConstraints = NO;
  [label.leadingAnchor
      constraintEqualToAnchor:label.superview.layoutMarginsGuide.leadingAnchor]
      .active = YES;
  [textField.trailingAnchor
      constraintEqualToAnchor:textField.superview.layoutMarginsGuide
                                  .trailingAnchor]
      .active = YES;
  [textField.leadingAnchor constraintEqualToAnchor:label.trailingAnchor]
      .active = YES;
  [label.heightAnchor constraintEqualToAnchor:label.superview.heightAnchor]
      .active = YES;
  [textField.heightAnchor
      constraintEqualToAnchor:textField.superview.heightAnchor]
      .active = YES;
  [label setContentHuggingPriority:UILayoutPriorityDefaultLow + 1
                           forAxis:UILayoutConstraintAxisVertical];
  [label setContentHuggingPriority:UILayoutPriorityDefaultLow + 1
                           forAxis:UILayoutConstraintAxisHorizontal];
  [textField setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisVertical];
  [textField setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];

  return self;
}

- (id)createRGBCell:(UITableViewCell *)cell andSelector:(SEL)selector {
  m_rField = [[UITextField alloc] init];
  m_gField = [[UITextField alloc] init];
  m_bField = [[UITextField alloc] init];

  [m_rField addTarget:self
                action:selector
      forControlEvents:UIControlEventEditingDidEnd];
  [m_gField addTarget:self
                action:selector
      forControlEvents:UIControlEventEditingDidEnd];
  [m_bField addTarget:self
                action:selector
      forControlEvents:UIControlEventEditingDidEnd];

  UILabel *label = [[UILabel alloc] init];
  label.text = @"RGB";
  m_rField.text = @"1.0";
  m_gField.text = @"1.0";
  m_bField.text = @"1.0";

  [cell.contentView addSubview:label];
  [cell.contentView addSubview:m_rField];
  [cell.contentView addSubview:m_gField];
  [cell.contentView addSubview:m_bField];

  label.translatesAutoresizingMaskIntoConstraints = NO;
  m_rField.translatesAutoresizingMaskIntoConstraints = NO;
  m_gField.translatesAutoresizingMaskIntoConstraints = NO;
  m_bField.translatesAutoresizingMaskIntoConstraints = NO;

  [m_rField.leadingAnchor constraintEqualToAnchor:label.trailingAnchor
                                         constant:20]
      .active = YES;
  [m_gField.leadingAnchor constraintEqualToAnchor:m_rField.trailingAnchor
                                         constant:10]
      .active = YES;
  [m_bField.leadingAnchor constraintEqualToAnchor:m_gField.trailingAnchor
                                         constant:10]
      .active = YES;
  [m_bField.trailingAnchor
      constraintEqualToAnchor:m_bField.superview.layoutMarginsGuide
                                  .trailingAnchor]
      .active = YES;

  [label.heightAnchor constraintEqualToAnchor:label.superview.heightAnchor]
      .active = YES;
  [m_rField.heightAnchor
      constraintEqualToAnchor:m_rField.superview.heightAnchor]
      .active = YES;
  [m_gField.heightAnchor
      constraintEqualToAnchor:m_gField.superview.heightAnchor]
      .active = YES;
  [m_bField.heightAnchor
      constraintEqualToAnchor:m_bField.superview.heightAnchor]
      .active = YES;

  [m_rField.widthAnchor constraintEqualToConstant:50].active = YES;
  [m_gField.widthAnchor constraintEqualToConstant:50].active = YES;
  [m_bField.widthAnchor constraintEqualToConstant:50].active = YES;

  return self;
}

- (id)initWithSettings:(std::shared_ptr<Settings>)settings {
  self = [super initWithStyle:UITableViewStyleGrouped];
  m_settings = settings;
  m_rField = nil;
  m_gField = nil;
  m_bField = nil;
  return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:CellIdentifier];
  } else {
    for (UIView *v in cell.contentView.subviews) {
      [v removeFromSuperview];
    }
    cell.textLabel.text = nil;
    cell.textLabel.enabled = true;
    cell.userInteractionEnabled = true;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  switch (indexPath.row) {
  case 0: {
    NSString *ip =
        [NSString stringWithUTF8String:m_settings->serverIP().c_str()];
    [self createTextCell:cell
            andLabelText:@"Server IP"
             andEditText:ip
             andSelector:@selector(serverIPChanged:)];
    break;
  }
  case 1: {
    NSString *port =
        [NSString stringWithUTF8String:m_settings->serverPort().c_str()];
    [self createTextCell:cell
            andLabelText:@"Server Port"
             andEditText:port
             andSelector:@selector(serverPortChanged:)];
    break;
  }
  case 2: {
    cell.textLabel.text = @"Anatomical Terms";
    UISwitch *sw = [[UISwitch alloc] init];
    [sw setOn:m_settings->anatomicalTerms()];
    [sw addTarget:self
                  action:@selector(anatomicalTermsChanged:)
        forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    break;
  }
  case 3: {
    cell.textLabel.text = @"Background Color";
    [self createRGBCell:cell andSelector:@selector(backgroundColorChanged:)];
    float r = m_settings->backgroundColor()[0];
    float g = m_settings->backgroundColor()[1];
    float b = m_settings->backgroundColor()[2];
    m_rField.text = [NSString stringWithFormat:@"%.1f", r];
    m_gField.text = [NSString stringWithFormat:@"%.1f", g];
    m_bField.text = [NSString stringWithFormat:@"%.1f", b];
    break;
  }
  case 4: {
    cell.textLabel.text = @"Use Slice Indices";
    UISwitch *sw = [[UISwitch alloc] init];
    [sw setOn:m_settings->useSliceIndices()];
    [sw addTarget:self
                  action:@selector(useSliceIndicesChanged:)
        forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    break;
  }
  case 5: {
    cell.textLabel.text = @"Caching Enabled";
    UISwitch *sw = [[UISwitch alloc] init];
    bool o = m_settings->cachingEnabled();
    [sw setOn:o];
    [sw addTarget:self
                  action:@selector(cachingEnabledChanged:)
        forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    break;
  }
  case 6: {
    cell.textLabel.text = @"Clear Scene Cache";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Clear Scene Cache" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self
                  action:@selector(clearCache:)
        forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = button;
    break;
  }
  default:
    break;
  }

  return cell;
}

- (void)serverIPChanged:(id)sender {
  UITextField *tf = (UITextField *)sender;
  std::string ip = [[tf text] UTF8String];
  m_settings->setServerIP(ip);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"ServerAddressChanged"
                    object:self];
}

- (void)serverPortChanged:(id)sender {
  UITextField *tf = (UITextField *)sender;
  std::string port = [[tf text] UTF8String];
  m_settings->setServerPort(port);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"ServerAddressChanged"
                    object:self];
}

- (void)anatomicalTermsChanged:(id)sender {
  UISwitch *sw = (UISwitch *)sender;
  m_settings->setAnatomicalTerms([sw isOn]);
}

- (void)useSliceIndicesChanged:(id)sender {
  UISwitch *sw = (UISwitch *)sender;
  m_settings->setUseSliceIndices([sw isOn]);
}

- (void)backgroundColorChanged:(id)sender {
  try {
      float r = std::stof([m_rField.text UTF8String]);
      float g = std::stof([m_gField.text UTF8String]);
      float b = std::stof([m_bField.text UTF8String]);
      m_settings->setBackgroundColor(std::array<float, 3>{r, g, b});
  }
  catch (const std::exception &err) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
  }
}

- (void)cachingEnabledChanged:(id)sender {
  UISwitch *sw = (UISwitch *)sender;
  m_settings->setCachingEnabled([sw isOn]);
}

- (void)clearCache:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearDataCache"
                                                      object:self];
  [(UIButton *)sender setEnabled:false];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Settings";
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end