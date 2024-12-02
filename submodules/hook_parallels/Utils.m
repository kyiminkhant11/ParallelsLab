// HookParallels.m
#import "Utils.h"

@implementation Utils

char* combineStrings(const char* str1, const char* str2) {
    // Calculate the lengths of the input strings
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);

    // Allocate memory for the combined string plus one extra byte for the null terminator
    char* combined = (char*)malloc(len1 + len2 + 1);

    if (combined == NULL) {
        return NULL;
    }

    // Copy the first string to the combined string
    strcpy(combined, str1);

    // Concatenate the second string to the combined string
    strcat(combined, str2);

    return combined;
}

int overwriteFileWithMemBuffer(const char *source, const char *destination) {
    FILE *sourceFile, *destinationFile;

    // Open the source file for binary reading
    sourceFile = fopen(source, "rb");
    if (sourceFile == NULL) {
        return 1;
    }

    // Open the destination file for binary writing (overwriting)
    destinationFile = fopen(destination, "wb");
    if (destinationFile == NULL) {
        fclose(sourceFile);
        return 1;
    }

    // Find the size of the source file
    fseek(sourceFile, 0, SEEK_END);
    long fileSize = ftell(sourceFile);
    fseek(sourceFile, 0, SEEK_SET);

    // Allocate a buffer to hold the entire file
    unsigned char *buffer = (unsigned char *)malloc(fileSize);
    if (buffer == NULL) {
        fclose(sourceFile);
        fclose(destinationFile);
        return 1;
    }

    // Read the entire file into the buffer
    size_t bytesRead = fread(buffer, 1, fileSize, sourceFile);
    fclose(sourceFile);

    // Write the entire buffer to the destination file
    if (bytesRead != fileSize) {
        fclose(destinationFile);
        free(buffer);
        return 1;
    }

    fwrite(buffer, 1, fileSize, destinationFile);

    // Close both files and free the buffer
    fclose(destinationFile);
    free(buffer);
    
    return 0;
}

- (BOOL)compareCurrentAppBundleName:(NSString *)appBundleName {
    return [_appBundleName isEqualToString:appBundleName];
}

- (BOOL)compareCurrentAppCFBundleVersion:(NSString *)appCFBundleVersion {
    return [_appCFBundleVersion isEqualToString:appCFBundleVersion];
}

- (instancetype)init {
    NSLog(@"utils init called!");
    self = [super init];
    if (!self) return NULL;
    NSBundle *app = [NSBundle mainBundle];
    _appBundleName = [app bundleIdentifier];
    _appCFBundleVersion = [app objectForInfoDictionaryKey:@"CFBundleVersion"];
    _baseAddress = @(_dyld_get_image_vmaddr_slide(0));
    return self;
}

@end
