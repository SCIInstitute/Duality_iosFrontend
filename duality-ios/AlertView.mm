#import "AlertView.h"

void showErrorAlertView(UIViewController* viewController, const std::exception& err) {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                            message:[NSString stringWithUTF8String:err.what()]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}