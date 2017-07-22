#import <dlfcn.h>
#import "../PS.h"

%ctor {
    if (isiOS9Up)
        dlopen("/Library/Application Support/CamRotate/CamRotateiOS910.dylib", RTLD_LAZY);
    else if (isiOS7Up)
        dlopen("/Library/Application Support/CamRotate/CamRotateiOS78.dylib", RTLD_LAZY);
#if !__LP64__
    else
        dlopen("/Library/Application Support/CamRotate/CamRotateiOS56.dylib", RTLD_LAZY);
#endif
}
