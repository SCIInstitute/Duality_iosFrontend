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
    if (m_selectedScene) {
        try {
            m_loader->loadScene(std::string([m_selectedScene UTF8String]));
        }
        catch(const std::exception& err) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select Scene";
}

-(void) viewWillAppear:(BOOL)animated
{
    try {
        m_metadata = m_loader->listMetadata();
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
    [self.tableView reloadData];
}

-(id) initWithSceneLoader:(SceneLoader*)loader
{
    self = [super init];
    m_loader = loader;
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
