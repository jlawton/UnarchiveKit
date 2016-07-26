//
//  SzArEx_DictCache.c
//  UnarchiveKit
//
//  Created by James Lawton on 7/26/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#include "SzArEx_DictCache.h"

void SzArEx_DictCache_init(SzArEx_DictCache *dictCache, ISzAlloc *allocMain)
{
    dictCache->allocMain = allocMain;
    dictCache->blockIndex = 0xFFFFFFFF;
    dictCache->outBuffer = 0;
    dictCache->outBufferSize = 0;
    dictCache->entryOffset = 0;
    dictCache->outSizeProcessed = 0;
}

void SzArEx_DictCache_free(SzArEx_DictCache *dictCache)
{
    if (dictCache->outBuffer != 0) {
        IAlloc_Free(dictCache->allocMain, dictCache->outBuffer);
    }
    SzArEx_DictCache_init(dictCache, dictCache->allocMain);
}
