//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TabBarViewController.h"

#include "duality/SceneLoader.h"

@implementation TabBarViewController

- (id)init
{
    self = [super init];
    
    [self reinitSceneLoader:nil];
    
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Failed to create OpenGLES context");
    }
    
    m_render3DViewController = [[Render3DViewController alloc] initWithSceneLoader:m_sceneLoader.get()];
    m_render3DViewController.context = context;
    m_render2DViewController = [[Render2DViewController alloc] initWithSceneLoader:m_sceneLoader.get()];
    m_render2DViewController.context = context;
    m_selectSceneViewController = [[SelectSceneViewController alloc] initWithSceneLoader:m_sceneLoader.get()];
    m_settingsViewController = [[SettingsViewController alloc] init];

    [self createNavigationControllers];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reinitSceneLoader:) name:@"ServerAddressChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showErrorAlert:) name:@"ErrorOccured" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearDataCache:) name:@"ClearDataCache" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cachingEnabledChanged:) name:@"CachingEnabledChanged" object:nil];
    
    return self;
}

- (void) createNavigationControllers {
    // Array to contain the view controllers
    NSMutableArray *viewControllersArray = [[NSMutableArray alloc] init];
    UINavigationController* navController;

    navController = [self createNavigationController:m_render3DViewController withTitle:@"3D View"];
    navController.navigationBar.hidden = YES;
    navController.tabBarItem.tag = 0;
    [viewControllersArray addObject:navController];

    navController = [self createNavigationController:m_render2DViewController withTitle:@"2D View"];
    navController.navigationBar.hidden = YES;
    navController.tabBarItem.tag = 1;
    [viewControllersArray addObject:navController];
    
    navController = [self createNavigationController:m_selectSceneViewController withTitle:@"Select Scene"];
    navController.tabBarItem.tag = 2;
    [viewControllersArray addObject:navController];

    navController = [self createNavigationController:m_settingsViewController withTitle:@"Settings"];
    navController.tabBarItem.tag = 3;
    [viewControllersArray addObject:navController];
    
    self.viewControllers = viewControllersArray;
}

- (UINavigationController*) createNavigationController:(UIViewController*)viewController withTitle:(NSString*)title
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    UITabBarItem* tabBarItem  = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(title, @"Title of the tab") image:[UIImage imageNamed:@"data.png"] tag:0];
    navController.tabBarItem = tabBarItem;
    return navController;
}

-(void) reinitSceneLoader:(NSNotification*)notification
{
    try {
        std::string serverIP = [[[NSUserDefaults standardUserDefaults] stringForKey:@"ServerIP"] UTF8String];
        uint16_t serverPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"ServerPort"];
        mocca::net::Endpoint endpoint("tcp.prefixed", serverIP, std::to_string(serverPort));
        if (m_sceneLoader == nullptr) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            mocca::fs::Path documentsDirectory([[paths objectAtIndex:0]UTF8String]);
            m_sceneLoader = std::make_unique<SceneLoader>(endpoint, documentsDirectory + "scenecache");
        } else {
            m_sceneLoader->updateEndpoint(endpoint);
        }
        [m_render3DViewController reset];
        [m_render2DViewController reset];
    }
    catch (const std::exception& err) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

-(void) showErrorAlert:(NSNotification*)notification
{
    NSString* errorText = notification.userInfo[@"Error"];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                            message:errorText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) clearDataCache:(NSNotification*)notification
{
    m_sceneLoader->clearCache();
}

-(void) cachingEnabledChanged:(NSNotification*)notification
{
    m_sceneLoader->setCachingEnabled([[NSUserDefaults standardUserDefaults] boolForKey:@"CachingEnabled"]);
}

@end
