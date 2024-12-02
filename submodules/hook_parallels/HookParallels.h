// HookParallels.h

#ifndef HOOK_PARALLELS_H
#define HOOK_PARALLELS_H

#import <Foundation/Foundation.h>
#import "Utils.h"
#import "../rd_route/rd_route.h"

@interface HookParallels : Utils

- (void)patchDispatcher;
- (void)patchVM;
- (void)patch;

@end

#endif
