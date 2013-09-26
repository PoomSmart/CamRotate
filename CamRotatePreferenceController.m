#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#define isiOS5 (kCFCoreFoundationVersionNumber >= 675.00 && kCFCoreFoundationVersionNumber < 793.00)
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.CamRotate.plist"
#define LoadPlist NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
#define PLIST_PATH @"/Library/PreferenceBundles/CamRotateSettings.bundle/CamRotate.plist"
#define setAvailable(available, spec) [spec setProperty:[NSNumber numberWithBool:available] forKey:@"enabled"];
#define CamRotateIsOn [[dict objectForKey:@"CamRotateEnabled"] boolValue]

#define AddSpecBeforeSpec(spec, afterSpecName) \
if (![self specifierForID:spec.identifier] && [value boolValue]) \
	[self insertSpecifier:spec afterSpecifierID:afterSpecName animated:NO]; \
else \
	[self removeSpecifierID:spec.identifier animated:NO];
	
#define orig 	[self setPreferenceValue:value specifier:spec]; \
		[[NSUserDefaults standardUserDefaults] synchronize];
				
@interface PSListController (CamRotate)
- (void)viewDidUnload;
@end

@interface CamRotatePreferenceController : PSListController {
	PSSpecifier *_camRotateLockSpec;
	PSSpecifier *_orientationSpec;
	PSSpecifier *_syncOrientationSpec;
	PSSpecifier *_rotationStyleSpec;
	PSSpecifier *_spaceSpec;
	PSSpecifier *_unlockVideoUISpec;
	PSSpecifier *_descriptionSpec;
}
@property (nonatomic, retain) PSSpecifier *camRotateLockSpec;
@property (nonatomic, retain) PSSpecifier *orientationSpec;
@property (nonatomic, retain) PSSpecifier *syncOrientationSpec;
@property (nonatomic, retain) PSSpecifier *rotationStyleSpec;
@property (nonatomic, retain) PSSpecifier *spaceSpec;
@property (nonatomic, retain) PSSpecifier *unlockVideoUISpec;
@property (nonatomic, retain) PSSpecifier *descriptionSpec;
@end

@implementation CamRotatePreferenceController

@synthesize camRotateLockSpec = _camRotateLockSpec;
@synthesize orientationSpec = _orientationSpec;
@synthesize syncOrientationSpec = _syncOrientationSpec;
@synthesize rotationStyleSpec = _rotationStyleSpec;
@synthesize spaceSpec = _spaceSpec;
@synthesize unlockVideoUISpec = _unlockVideoUISpec;
@synthesize descriptionSpec = _descriptionSpec;

- (void)viewDidUnload
{
	self.camRotateLockSpec = nil;
	self.orientationSpec = nil;
	self.syncOrientationSpec = nil;
    	self.rotationStyleSpec = nil;
    	self.spaceSpec = nil;
    	self.unlockVideoUISpec = nil;
    	self.descriptionSpec = nil;
    	[super viewDidUnload];
}

- (void)setCamRotate:(id)value specifier:(PSSpecifier *)spec
{
	orig
	LoadPlist
	
	AddSpecBeforeSpec(self.camRotateLockSpec, @"CamRotate")
	
	if ([[dict objectForKey:@"CamRotateLock"] boolValue]) {
		AddSpecBeforeSpec(self.orientationSpec, @"CamRotateLock")
	}
	
	AddSpecBeforeSpec(self.syncOrientationSpec, [self specifierForID:@"OrientationValue"] ? @"OrientationValue" : @"CamRotateLock")
	if (!isiOS5) {
		AddSpecBeforeSpec(self.rotationStyleSpec, @"SyncOrientation")
		AddSpecBeforeSpec(self.spaceSpec, @"RotationStyle")
	} else {
		AddSpecBeforeSpec(self.spaceSpec, @"SyncOrientation")
	}
	AddSpecBeforeSpec(self.unlockVideoUISpec, @"space")
	AddSpecBeforeSpec(self.descriptionSpec, @"UnlockVideoUI")
	
}

- (void)setCamRotateLock:(id)value specifier:(PSSpecifier *)spec
{
	orig

	if (![self specifierForID:@"OrientationValue"])
		[self insertSpecifier:self.orientationSpec afterSpecifierID:@"CamRotateLock" animated:NO];
	else if ([self specifierForID:@"OrientationValue"])
		[self removeSpecifierID:@"OrientationValue" animated:NO];
		
	setAvailable(![value boolValue], self.syncOrientationSpec)
	[self reloadSpecifier:self.syncOrientationSpec animated:NO];
	if (self.rotationStyleSpec) {
		setAvailable(![value boolValue], self.rotationStyleSpec)
		[self reloadSpecifier:self.rotationStyleSpec animated:NO];
	}
	setAvailable(![value boolValue], self.unlockVideoUISpec)
	[self reloadSpecifier:self.unlockVideoUISpec animated:NO];
}

- (void)setSyncOrientation:(id)value specifier:(PSSpecifier *)spec
{
	orig
	setAvailable(![value boolValue], self.camRotateLockSpec)
	[self reloadSpecifier:self.camRotateLockSpec animated:NO];
}

- (void)killCam:(id)value specifier:(PSSpecifier *)spec
{
	orig
	system("killall Camera");
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"CamRotate" target:self]];
		LoadPlist
		
		for (PSSpecifier *spec in specs) {
			if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"CamRotateLock"])
                		self.camRotateLockSpec = spec;
            		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"OrientationValue"])
                		self.orientationSpec = spec;
            		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"SyncOrientation"])
                		self.syncOrientationSpec = spec;
            		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"RotationStyle"])
                		self.rotationStyleSpec = spec;
             		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"space"])
            			self.spaceSpec = spec;
            		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"UnlockVideoUI"])
            			self.unlockVideoUISpec = spec;
            		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"Description"])
            			self.descriptionSpec = spec;
        	}
        
        	// CamRotate
        	if (![[dict objectForKey:@"CamRotateEnabled"] boolValue]) {
        		[specs removeObject:self.camRotateLockSpec];
       			[specs removeObject:self.orientationSpec];
       			[specs removeObject:self.syncOrientationSpec];
       			if (self.rotationStyleSpec)
       				[specs removeObject:self.rotationStyleSpec];
       			[specs removeObject:self.spaceSpec];
       			[specs removeObject:self.unlockVideoUISpec];
       			[specs removeObject:self.descriptionSpec];
       		}
        
        	// CamRotateLock
       		if (![[dict objectForKey:@"CamRotateLock"] boolValue])
       			[specs removeObject:self.orientationSpec];
       	
       		setAvailable(![[dict objectForKey:@"CamRotateLock"] boolValue], self.unlockVideoUISpec)
       		setAvailable(![[dict objectForKey:@"CamRotateLock"] boolValue], self.syncOrientationSpec)
       		setAvailable(![[dict objectForKey:@"SyncOrientation"] boolValue], self.camRotateLockSpec)
		if (self.rotationStyleSpec)
			setAvailable(![[dict objectForKey:@"CamRotateLock"] boolValue], self.rotationStyleSpec)
		
		if (isiOS5)
			[specs removeObject:self.rotationStyleSpec];

		[self reloadSpecifier:self.rotationStyleSpec animated:NO];
        
        	_specifiers = [specs copy];
 	}
	return _specifiers;
}

@end

