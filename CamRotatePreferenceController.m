#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "Header.h"

@interface CamRotatePreferenceController : PSListController
@property (nonatomic, retain) PSSpecifier *rotationStyleSpec;
@end

@implementation CamRotatePreferenceController

- (id)readPreferenceValue:(PSSpecifier *)specifier
{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	if (!settings[specifier.properties[@"key"]])
		return specifier.properties[@"default"];
	return settings[specifier.properties[@"key"]];
}
 
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:PREF_PATH atomically:YES];
	CFStringRef post = (CFStringRef)specifier.properties[@"PostNotification"];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), post, NULL, NULL, YES);
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"CamRotate" target:self]];
		
		for (PSSpecifier *spec in specs) {
			NSString *Id = [spec identifier];
			if ([Id isEqualToString:@"RotationStyle"])
				self.rotationStyleSpec = spec;
		}
		if (isiOS5)
			[specs removeObject:self.rotationStyleSpec];
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end

