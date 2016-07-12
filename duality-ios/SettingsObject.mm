#import <Foundation/Foundation.h>

#import "SettingsObject.h"

std::string SettingsObject::serverIP() const {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:@"ServerIP"] UTF8String];
}

void SettingsObject::setServerIP(const std::string& ip) {
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithUTF8String:ip.c_str()] forKey:@"ServerIP"];
}

std::string SettingsObject::serverPort() const {
    return [[[NSUserDefaults standardUserDefaults] stringForKey:@"ServerPort"] UTF8String];
}

void SettingsObject::setServerPort(const std::string& port) {
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithUTF8String:port.c_str()] forKey:@"ServerPort"];
}

bool SettingsObject::anatomicalTerms() const {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"AnatomicalTerms"];
}

void SettingsObject::setAnatomicalTerms(bool enabled) {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"AnatomicalTerms"];
}

bool SettingsObject::cachingEnabled() const {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"CachingEnabled"];
}

void SettingsObject::setCachingEnabled(bool enabled) {
  [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"CachingEnabled"];
}

std::array<float, 3> SettingsObject::backgroundColor() const {
    NSArray* arr = [[NSUserDefaults standardUserDefaults] arrayForKey:@"BackgroundColor"];
    float r = [(NSNumber*)[arr objectAtIndex:0] floatValue];
    float g = [(NSNumber*)[arr objectAtIndex:1] floatValue];
    float b = [(NSNumber*)[arr objectAtIndex:2] floatValue];
    return {r, g, b};
}

void SettingsObject::setBackgroundColor(const std::array<float, 3>& color) {
    NSNumber* r = [NSNumber numberWithFloat:color[0]];
    NSNumber* g = [NSNumber numberWithFloat:color[1]];
    NSNumber* b = [NSNumber numberWithFloat:color[2]];
    NSArray<NSNumber*>* arr = [NSArray arrayWithObjects:r, g, b, nil];
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"BackgroundColor"];
}
