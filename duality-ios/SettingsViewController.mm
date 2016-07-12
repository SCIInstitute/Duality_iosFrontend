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
    andSelector:(SEL) selector {
  UITextField *textField = [[UITextField alloc] init];
  textField.textAlignment = NSTextAlignmentRight;
  textField.text = editText;
  [textField addTarget:self action:selector forControlEvents:UIControlEventEditingDidEnd];

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

- (id) initWithSettings:(std::shared_ptr<Settings>)settings {
    self = [super initWithStyle:UITableViewStyleGrouped];
    m_textSettingCells = [[NSMutableArray alloc] init];
    m_settings = settings;
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section {
  return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
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
    NSString* ip = [NSString stringWithUTF8String:m_settings->serverIP().c_str()];
    [m_textSettingCells addObject:[self createTextCell:cell andLabelText:@"Server IP" andEditText:ip andSelector:@selector(serverIPChanged:)]];
    break;
  }
  case 1: {
      NSString* port = [NSString stringWithUTF8String:m_settings->serverPort().c_str()];
      [m_textSettingCells addObject:[self createTextCell:cell andLabelText:@"Server Port" andEditText:port andSelector:@selector(serverPortChanged:)]];
    break;
  }
  case 2: {
    cell.textLabel.text = @"Anatomical Terms";
    UISwitch *sw = [[UISwitch alloc] init];
    [sw setOn:m_settings->anatomicalTerms()];
    [sw addTarget:self action:@selector(anatomicalTermsChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    break;
  }
  case 3: {
      cell.textLabel.text = @"White Background";
      UISwitch *sw = [[UISwitch alloc] init];
      [sw setOn:m_settings->backgroundColor() == std::array<float, 3>{1.0f, 1.0f, 1.0f}];
      [sw addTarget:self action:@selector(backgroundColorChanged:) forControlEvents:UIControlEventValueChanged];
      cell.accessoryView = sw;
      break;
  }
  case 4: {
    cell.textLabel.text = @"Caching Enabled";
    UISwitch *sw = [[UISwitch alloc] init];
      bool o = m_settings->cachingEnabled();
    [sw setOn:o];
    [sw addTarget:self action:@selector(cachingEnabledChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    break;
  }
  case 5: {
    cell.textLabel.text = @"Clear Scene Cache";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Clear Scene Cache" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(clearCache:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = button;
    break;
  }
  default:
    break;
  }

  return cell;
}

- (void)serverIPChanged:(id)sender {
    UITextField* tf = (UITextField *)sender;
    std::string ip = [[tf text] UTF8String];
    m_settings->setServerIP(ip);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerAddressChanged" object:self];
}

- (void)serverPortChanged:(id)sender {
    UITextField* tf = (UITextField *)sender;
    std::string port = [[tf text] UTF8String];
    m_settings->setServerPort(port);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerAddressChanged" object:self];
}

- (void)anatomicalTermsChanged:(id)sender {
  UISwitch* sw = (UISwitch *)sender;
  m_settings->setAnatomicalTerms([sw isOn]);
}

- (void)backgroundColorChanged:(id)sender {
    UISwitch* sw = (UISwitch *)sender;
    if ([sw isOn]) {
        m_settings->setBackgroundColor(std::array<float, 3>{1.0f, 1.0f, 1.0f});
    }
    else {
        m_settings->setBackgroundColor(std::array<float, 3>{0.0f, 0.0f, 0.0f});
    }
}

- (void)cachingEnabledChanged:(id)sender {
  UISwitch* sw = (UISwitch *)sender;
  m_settings->setCachingEnabled([sw isOn]);
}

- (void)clearCache:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearDataCache" object:self];
  [(UIButton*)sender setEnabled:false];
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

- (void)dealloc {
  [m_textSettingCells removeAllObjects];
}

@end