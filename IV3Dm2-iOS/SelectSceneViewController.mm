//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import "SelectSceneViewController.h"

@implementation SelectSceneViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return m_metadata.size();
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    const SceneMetadata& meta = m_metadata[indexPath.row];
    cell.textLabel.text = [NSString stringWithUTF8String:meta.name().c_str()];
    cell.detailTextLabel.text = [NSString stringWithUTF8String:meta.description().c_str()];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    m_selectedScene = [NSString stringWithUTF8String:m_metadata[indexPath.row].name().c_str()];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select Scene";
}

-(void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (m_selectedScene) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectedSceneChanged" object:self userInfo:@{@"name":m_selectedScene}];
    }
    [super viewWillDisappear:animated];
}

-(void) setMetadata:(std::vector<SceneMetadata>)metadata
{
    m_metadata = std::move(metadata);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
