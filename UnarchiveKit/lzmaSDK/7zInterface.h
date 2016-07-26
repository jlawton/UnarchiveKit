//
//  7zInterface.h
//  UnarchiveKit
//
//  Created by James Lawton on 7/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#ifndef _zInterface_h
#define _zInterface_h

#include "7zTypes.h"
#include "SzArEx_DictCache.h"

EXTERN_C_BEGIN

void SevenZipInit(void);

typedef struct SevenZipFileArchive SevenZipFileArchive;
SevenZipFileArchive * SevenZipFileArchive_Open(const char *path);
void SevenZipFileArchive_Free(SevenZipFileArchive *archive);

UInt32 SevenZipFileArchive_GetFileCount(SevenZipFileArchive *archive);

typedef struct SevenZipFileMetadata {
    Byte *nameUTF16LE;
    size_t nameBytesCount;
    int isDirectory;
    size_t fileSize;
} SevenZipFileMetadata;
SevenZipFileMetadata SevenZipFileMetadata_Init(void);
void SevenZipFileMetadata_Free(SevenZipFileMetadata *metadata);
int SevenZipFileArchive_GetFileMetadata(const SevenZipFileArchive *archive, UInt32 fileIndex, SevenZipFileMetadata *metadata);

SzArEx_DictCache SevenZipExtractCache_Init();
void SevenZipExtractCache_Free(SzArEx_DictCache *cache);

typedef struct SevenZipExtractedBlock {
    Byte *block;
    size_t count;
} SevenZipExtractedBlock;

int SevenZipFileArchive_GetFileMetadata(const SevenZipFileArchive *archive, UInt32 fileIndex, SevenZipFileMetadata *metadata);

int SevenZipFileArchive_Extract(SevenZipFileArchive *archive, UInt32 fileIndex, SzArEx_DictCache *cache, SevenZipExtractedBlock *extracted);

EXTERN_C_END

#endif /* _zInterface_h */
