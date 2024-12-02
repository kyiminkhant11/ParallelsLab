// Utils.h

#ifndef UTILS_H
#define UTILS_H

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

char* combineStrings(const char* str1, const char* str2);
int overwriteFileWithMemBuffer(const char *source, const char *destination);

@interface Utils : NSObject

@property (nonatomic, strong) NSString *appBundleName;
@property (nonatomic, strong) NSString *appCFBundleVersion;
@property (nonatomic, strong) NSValue *baseAddress;

- (BOOL)compareCurrentAppBundleName:(NSString *)bundleName;
- (BOOL)compareCurrentAppCFBundleVersion:(NSString *)cfBundleVersion;

@end

#endif
