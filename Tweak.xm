#import <dlfcn.h>
#import "../PS.h"

%ctor
{
	if (isiOS9Up)
		dlopen("/Library/Application Support/CamRotate/CamRotateiOS9.dylib", RTLD_LAZY);
	else if (isiOS8)
		dlopen("/Library/Application Support/CamRotate/CamRotateiOS8.dylib", RTLD_LAZY);
	else if (isiOS7)
		dlopen("/Library/Application Support/CamRotate/CamRotateiOS7.dylib", RTLD_LAZY);
	else if (isiOS56)
		dlopen("/Library/Application Support/CamRotate/CamRotateiOS56.dylib", RTLD_LAZY);
}