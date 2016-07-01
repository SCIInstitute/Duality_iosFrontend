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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SceneSelected" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:m_selectedScene, @"Name", nil]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select Scene";
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    try {
        m_metadata = m_loader->listMetadata();
    }
    catch(const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
    [self.tableView reloadData];
    if (m_loader->isSceneLoaded()) {
        std::string selectedScene = m_loader->metadata().name();
        auto it = std::find_if(begin(m_metadata), end(m_metadata), [&](const SceneMetadata& m) {
            return m.name() == selectedScene;
        });
        if (it != end(m_metadata)) {
            auto pos = std::distance(begin(m_metadata), it);
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:pos inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
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
