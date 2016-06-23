//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import "SettingsViewController.h"

#include "src/duality/DataCache.h"

typedef void(^CallbackBlock)(void);

@interface TextSettingCell : NSObject
{
    NSString* m_key;
    CallbackBlock m_block;
}

-(id) initWithCell:(UITableViewCell*)cell andKey:(NSString*)key andText:(NSString*)text andBlock:(CallbackBlock)block;

@end

@implementation TextSettingCell

-(id) initWithCell:(UITableViewCell *)cell andKey:(NSString *)key andText:(NSString *)text andBlock:(CallbackBlock)block
{
    self = [super init];
    
    m_key = key;
    m_block = block;
    
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:m_key];
    
    UITextField* textField = [[UITextField alloc] init];
    textField.textAlignment = NSTextAlignmentRight;
    textField.text = value;
    [textField addTarget:self action:@selector(textFieldEditingEnded:) forControlEvents:UIControlEventEditingDidEnd];
    
    UILabel * label = [[UILabel alloc] init];
    label.text = text;

    [cell.contentView addSubview:label];
    [cell.contentView addSubview:textField];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [label.leadingAnchor constraintEqualToAnchor:label.superview.layoutMarginsGuide.leadingAnchor].active = YES;
    [textField.trailingAnchor constraintEqualToAnchor:textField.superview.layoutMarginsGuide.trailingAnchor].active = YES;
    [textField.leadingAnchor constraintEqualToAnchor:label.trailingAnchor].active = YES;
    [label.heightAnchor constraintEqualToAnchor:label.superview.heightAnchor].active = YES;
    [textField.heightAnchor constraintEqualToAnchor:textField.superview.heightAnchor].active = YES;
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow + 1 forAxis:UILayoutConstraintAxisVertical];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow + 1 forAxis:UILayoutConstraintAxisHorizontal];
    [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    return self;
}

- (void)textFieldEditingEnded:(id)sender
{
    UITextField* textField = (UITextField*)sender;
    [[NSUserDefaults standardUserDefaults] setValue:textField.text forKey:m_key];
    m_block();
}

@end


@implementation SettingsViewController

- (id) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    m_textSettingCells = [[NSMutableArray alloc] init];
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.row)
    {
        case 0:
        {
            CallbackBlock block = ^{ [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerAddressChanged" object:self]; };
            [m_textSettingCells addObject:[[TextSettingCell alloc] initWithCell:cell
                            andKey:@"ServerIP" andText:@"Server IP" andBlock:block]];
            break;
        }
        case 1:
        {
            CallbackBlock block = ^{ [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerAddressChanged" object:self]; };
            [m_textSettingCells addObject:[[TextSettingCell alloc] initWithCell:cell
                            andKey:@"ServerPort" andText:@"Server Port" andBlock:block]];
            break;
        }
        case 2:
        {
            cell.textLabel.text = @"Anatomical Terms";
            UISwitch* sw = [[UISwitch alloc] init];
            bool tmp = [[NSUserDefaults standardUserDefaults] boolForKey:@"AnatomicalTerms"];
            [sw setOn:tmp];
            [sw addTarget:self action:@selector(anatomicalTermsChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            break;
        }
        case 3:
        {
            cell.textLabel.text = @"Caching Enabled";
            UISwitch* sw = [[UISwitch alloc] init];
            [sw setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"CachingEnabled"]];
            [sw addTarget:self action:@selector(cachingEnabledChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            break;
        }
        case 4:
        {
            cell.textLabel.text = @"Clear Scene Cache";
            UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
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

-(void) anatomicalTermsChanged:(id)sender
{
    UISwitch* sw = (UISwitch*)sender;
    bool anatomicalTerms = [sw isOn];
    [[NSUserDefaults standardUserDefaults] setBool:anatomicalTerms forKey:@"AnatomicalTerms"];
}

-(void) cachingEnabledChanged:(id)sender
{
    UISwitch* sw = (UISwitch*)sender;
    bool cachingEnabled = [sw isOn];
    [[NSUserDefaults standardUserDefaults] setBool:cachingEnabled forKey:@"CachingEnabled"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CachingEnabledChanged" object:self];
}

-(void) clearCache:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearDataCache" object:self];
    [(UIButton*)sender setEnabled:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc
{
    [m_textSettingCells removeAllObjects];
}

@end