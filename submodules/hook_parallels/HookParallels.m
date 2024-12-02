// HookParallels.m
#import "HookParallels.h"

@implementation HookParallels

#if defined(__aarch64__)
    const unsigned char opcodesRet1[] = {0x20, 0x00, 0x80, 0xd2, 0xc0, 0x03, 0x5f, 0xd6},
                        opcodesRet0[] = {0x00, 0x00, 0x80, 0xd2, 0xc0, 0x03, 0x5f, 0xd6},
                        opcodesBranch0x10[] = {0x04, 0x00, 0x00, 0x14},
                        opcodesBranch0xC[] = {0x03, 0x00, 0x00, 0x14};

    const size_t opcodesRetNSize = 8,
                 opcodesBranchSize = 4;
#else
    const unsigned char opcodesRet1[] = {0x6a, 0x01, 0x58, 0xc3},
                        opcodesRet0[] = {0x6a, 0x00, 0x58, 0xc3},
                        opcodesJump0xA[] = {0xeb, 0x08},
                        opcodesJump0x17[] = {0xeb, 0x15};

    const size_t opcodesRetNSize = 4,
                 opcodesJumpSize = 2;
#endif

#ifdef VM_54729
const char *pdfmDispDst = "/Applications/Parallels Desktop.app/Contents/MacOS/Parallels Service.app/Contents/MacOS/prl_disp_service",
           *pdfmDispPatchSuffix = "_patched",
           *pdfmDispBcupSuffix = "_bcup";

void*(*originalDispatcherCoreHook)(void*) = NULL;

void* dispatcherCoreHook(void *arg) {
    char *pdfmDispDstBcup = combineStrings(pdfmDispDst, pdfmDispBcupSuffix);
    int status = overwriteFileWithMemBuffer(pdfmDispDstBcup, pdfmDispDst);
    free(pdfmDispDstBcup);
    if (status)
        NSLog(@"[bad_prl_service] [disp] restore original dispatcher failed with status %d", status);

    void *result = originalDispatcherCoreHook(arg);

    char *pdfmDispDstPatch = combineStrings(pdfmDispDst, pdfmDispPatchSuffix);
    status = overwriteFileWithMemBuffer(pdfmDispDstPatch, pdfmDispDst);
    free(pdfmDispDstPatch);
    if (status)
        NSLog(@"[bad_prl_service] [disp] restore patched dispatcher failed with status %d", status);

    return result;
}
#endif

- (void)patchDispatcher {
    intptr_t baseAddress;
    [self.baseAddress getValue:&baseAddress];

    int kr;

    #ifdef VM_54729
        // hook core
        intptr_t coreAddress;
        #if defined(__aarch64__)
            coreAddress = baseAddress + 0x1001BD244;
        #else
            coreAddress = baseAddress + 0x1001AA660;
        #endif
        kr = rd_route((void *)coreAddress, dispatcherCoreHook, (void **)&originalDispatcherCoreHook);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x%lx - \"hook core\" failed with status %d", baseAddress, kr);
    #endif

    #if defined(__aarch64__)
        // bypass license public key loading error
        kr = patch_memory((void *)(baseAddress + 0x10035A90C), opcodesBranchSize, (uint8_t *)&opcodesBranch0x10);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x10035A90C - \"bypass license public key loading error\" failed with status %d", kr);

        // partly bypass license info loading error
        kr = patch_memory((void *)(baseAddress + 0x10035A950), opcodesBranchSize, (uint8_t *)&opcodesBranch0xC);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x10035A950 - \"partly bypass license info loading error\" failed with status %d", kr);

        // bypass license signature check
        kr = patch_memory((void *)(baseAddress + 0x1005CAD84), opcodesRetNSize, (uint8_t *)&opcodesRet1);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x1005CAD84 - \"bypass license signature check\" failed with status %d", kr);
    #else
        // bypass license public key loading error
        kr = patch_memory((void *)(baseAddress + 0x100336B95), opcodesJumpSize, (uint8_t *)&opcodesJump0x17);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x100336B95 - \"bypass license public key loading error\" failed with status %d", kr);
        
        // partly bypass license info loading error
        kr = patch_memory((void *)(baseAddress + 0x100336BDE), opcodesJumpSize, (uint8_t *)&opcodesJump0xA);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x10035A950 - \"partly bypass license info loading error\" failed with status %d", kr);
        
        // bypass license signature check
        kr = patch_memory((void *)(baseAddress + 0x100596F30), opcodesRetNSize, (uint8_t *)&opcodesRet1);
        if (kr)
            NSLog(@"[bad_prl_service] [disp] patch at 0x1005CAD84 - \"bypass license signature check\" failed with status %d", kr);
    #endif
}

- (void)patchVM {
    #ifndef VM_54729
        intptr_t baseAddress;
        [self.baseAddress getValue:&baseAddress];

        int kr;

        #if defined(__aarch64__)
            // bypass license signature check
            kr = patch_memory((void *)(baseAddress + 0x1000EE9F8), opcodesRetNSize, (uint8_t *)&opcodesRet1);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x1000EE9F8 - \"bypass license signature check\" failed with status %d", kr);
            
            // bypass dispatcher codesign check (1)
            kr = patch_memory((void *)(baseAddress + 0x10095F69C), opcodesRetNSize, (uint8_t *)&opcodesRet0);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x10095F69C - \"bypass dispatcher codesign check (1)\" failed with status %d", kr);
            
            // bypass dispatcher codesign check (2)
            kr = patch_memory((void *)(baseAddress + 0x10095F814), opcodesRetNSize, (uint8_t *)&opcodesRet0);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x10095F814 - \"bypass dispatcher codesign check (2)\" failed with status %d", kr);
        #else
            // bypass license signature check
            kr = patch_memory((void *)(baseAddress + 0x1000FAFD0), opcodesRetNSize, (uint8_t *)&opcodesRet1);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x1000FAFD0 - \"bypass license signature check\" failed with status %d", kr);
            
            // bypass dispatcher codesign check (1)
            kr = patch_memory((void *)(baseAddress + 0x100A72820), opcodesRetNSize, (uint8_t *)&opcodesRet0);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x100A72820 - \"bypass dispatcher codesign check (1)\" failed with status %d", kr);
            
            // bypass dispatcher codesign check (2)
            kr = patch_memory((void *)(baseAddress + 0x100A72980), opcodesRetNSize, (uint8_t *)&opcodesRet0);
            if (kr)
                NSLog(@"[bad_prl_service] [vm] patch at 0x100A72980 - \"bypass dispatcher codesign check (2)\" failed with status %d", kr);
        #endif
    #endif
}

- (void)patch {
    if ([self compareCurrentAppBundleName:@"com.parallels.desktop.dispatcher"])
        [self patchDispatcher];
    else if ([self compareCurrentAppBundleName:@"com.parallels.vm"])
        [self patchVM];
}

+ (void)load {
    HookParallels *hookParallels = [[HookParallels alloc] init];
    [hookParallels patch];
}

@end
