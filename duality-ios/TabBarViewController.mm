//  Created by David McCann on 5/4/16.
//  Copyright © 2016 Scientific Computing and Imaging Institute. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TabBarViewController.h"
#import "SettingsObject.h"

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
    
    m_render3DViewController = [[Render3DViewController alloc] init];
    m_render3DViewController.context = context;
    m_render2DViewController = [[Render2DViewController alloc] init];
    m_render2DViewController.context = context;
    m_selectSceneViewController = [[SelectSceneViewController alloc] initWithSceneLoader:m_sceneLoader.get()];
    m_settingsViewController = [[SettingsViewController alloc] initWithSettings:m_sceneLoader->settings()];
    m_webViewController = [SFSafariViewController alloc];
    
    [self createNavigationControllers];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadScene:) name:@"SceneSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reinitSceneLoader:) name:@"ServerAddressChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showErrorAlert:) name:@"ErrorOccured" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearDataCache:) name:@"ClearDataCache" object:nil];
    
    self.delegate = self;
    
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
    
    navController = [self createNavigationController:m_webViewController withTitle:@"WebView"];
    navController.tabBarItem.tag = 4;
    navController.tabBarItem.enabled = false;
    [viewControllersArray addObject:navController];
    
    self.viewControllers = viewControllersArray;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    m_loadingLabel = [[UILabel alloc] init];
    m_loadingLabel.textColor = [UIColor whiteColor];
    m_loadingLabel.text = @"Loading data sets ...";
    m_loadingLabel.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:m_loadingLabel];
    [m_loadingLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20].active = true;
    [m_loadingLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20].active = true;
    [m_loadingLabel.widthAnchor constraintEqualToConstant:200.0].active = true;
    
    m_progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    m_progress.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:m_progress];
    [m_progress.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20].active = true;
    [m_progress.topAnchor constraintEqualToAnchor:m_loadingLabel.bottomAnchor constant:20].active = true;
    [m_progress.widthAnchor constraintEqualToConstant:200.0].active = true;
    
    m_progressLabel = [[UILabel alloc] init];
    m_progressLabel.textColor = [UIColor whiteColor];
    m_progressLabel.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:m_progressLabel];
    [m_progressLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20].active = true;
    [m_progressLabel.topAnchor constraintEqualToAnchor:m_progress.bottomAnchor constant:20].active = true;
    [m_progressLabel.widthAnchor constraintEqualToConstant:200.0].active = true;
    
    [self hideProgressWidgets];
}

-(void) showProgressWidgets
{
    m_loadingLabel.hidden = false;
    m_progress.hidden = false;
    [m_progress setProgress:0.0f animated:false];
    m_progressLabel.hidden = false;
    [m_progressLabel setText:@""];
}

-(void) hideProgressWidgets
{
    m_loadingLabel.hidden = true;
    m_progress.hidden = true;
    m_progressLabel.hidden = true;
}

- (BOOL)tabBarController:(UITabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController
{
    if (((UINavigationController*)viewController).tabBarItem.tag == 0) {
        if (m_sceneLoader->isSceneLoaded()) {
            [m_render3DViewController reset];
            self.tabBar.userInteractionEnabled = false;
            [self showProgressWidgets];
            
            auto controller = m_sceneLoader->sceneController3D(
               [=](int current, int total, const std::string& name) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       float prog = (static_cast<float>(current) / static_cast<float>(total));
                       [m_progress setProgress:prog animated:true];
                       [m_progressLabel setText:[NSString stringWithFormat:@"%s (%d / %d)", name.c_str(), current + 1, total]];
                   });
               });
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                controller->updateDatasets();
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    [m_render3DViewController setSceneController:controller];
                    controller->initializeDatasets();
                    [self hideProgressWidgets];
                    self.tabBar.userInteractionEnabled = true;
                    [m_render3DViewController setup];
                });
            });
        }
        return YES;
    }
    
    if (((UINavigationController*)viewController).tabBarItem.tag == 1) {
        if (m_sceneLoader->isSceneLoaded()) {
            [m_render2DViewController reset];
            self.tabBar.userInteractionEnabled = false;
            [self showProgressWidgets];

            auto controller = m_sceneLoader->sceneController2D(
                 [=](int current, int total, const std::string& name) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         float prog = (static_cast<float>(current) / static_cast<float>(total));
                         [m_progress setProgress:prog animated:true];
                         [m_progressLabel setText:[NSString stringWithFormat:@"%s (%d / %d)", name.c_str(), current + 1, total]];
                     });
                 });
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                controller->updateDatasets();
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [m_render2DViewController setSceneController:controller];
                    controller->initializeDatasets();
                    controller->initializeSliderCalculator();
                    [self hideProgressWidgets];
                    self.tabBar.userInteractionEnabled = true;
                    [m_render2DViewController setup];
                });
            });
        }
        return YES;
    }
    
    if (((UINavigationController*)viewController).tabBarItem.tag == 4) {
        std::string url = m_sceneLoader->webViewURL();
        NSURL* nsurl = [NSURL URLWithString:[NSString stringWithUTF8String:url.data()]];
        m_webViewController = [[SFSafariViewController alloc] initWithURL:nsurl];
        [self presentViewController:m_webViewController animated:true completion:nil];
        return NO;
    }
    
    return YES;
}

- (UINavigationController*) createNavigationController:(UIViewController*)viewController withTitle:(NSString*)title
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    UITabBarItem* tabBarItem  = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(title, @"Title of the tab") image:[UIImage imageNamed:@"data.png"] tag:0];
    navController.tabBarItem = tabBarItem;
    return navController;
}

-(void) loadScene:(NSNotification*)notification
{
    try {
        NSString* scene = notification.userInfo[@"Name"];
        m_sceneLoader->loadScene([scene UTF8String]);
        std::string url = m_sceneLoader->webViewURL();
        UINavigationController* nc = (UINavigationController*)[self.viewControllers objectAtIndex:4];
        if (!url.empty()) {
            NSURL* nsurl = [NSURL URLWithString:[NSString stringWithUTF8String:url.data()]];
            m_webViewController = [[SFSafariViewController alloc] initWithURL:nsurl];
            nc.tabBarItem.enabled = true;
        } else {
            nc.tabBarItem.enabled = false;
        }
    }
    catch (const std::exception& err) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorOccured" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:err.what()], @"Error", nil]];
    }
}

-(void) reinitSceneLoader:(NSNotification*)notification
{
    try {
        if (m_sceneLoader == nullptr) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            mocca::fs::Path documentsDirectory([[paths objectAtIndex:0]UTF8String]);
            m_sceneLoader = std::make_unique<SceneLoader>(documentsDirectory + "scenecache", std::make_shared<SettingsObject>());
        } else {
            m_sceneLoader->updateEndpoint();
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

@end
