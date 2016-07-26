//
//  SzArEx_DictCache.h
//  UnarchiveKit
//
//  Created by James Lawton on 7/26/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#ifndef SzArEx_DictCache_h
#define SzArEx_DictCache_h

#include <stdio.h>

#include "7zTypes.h"

EXTERN_C_BEGIN

typedef struct
{
    /* Ref to malloc implementation */
    ISzAlloc *allocMain;
    /* Default to 0xFFFFFFFF, can have any value before first call (if outBuffer = 0) */
    UInt32 blockIndex;
    /* must be 0 (NULL) before first call for each new archive */
    Byte *outBuffer;
    /* init to 0, can have any value before first call */
    size_t outBufferSize;
    /* byte offset in outBuffer where decoded entry begins */
    size_t entryOffset;
    /* The size in bytes of a specific entry extracted from an archive */
    size_t outSizeProcessed;

    /*  If dictionary memory is being paged to disk and the file is currently open,
     *  then this file pointer if non-NULL. */
    FILE *mapFile;
    size_t mapSize;
} SzArEx_DictCache;

void SzArEx_DictCache_init(SzArEx_DictCache *dictCache, ISzAlloc *allocMain);

void SzArEx_DictCache_free(SzArEx_DictCache *dictCache);

int SzArEx_DictCache_mmap(SzArEx_DictCache *dictCache);

void SzArEx_DictCache_munmap(SzArEx_DictCache *dictCache);

EXTERN_C_END

#endif /* SzArEx_DictCache_h */
