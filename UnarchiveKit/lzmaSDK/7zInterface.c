//
//  7zInterface.c
//  UnarchiveKit
//
//  Created by James Lawton on 7/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#include "7z.h"
#include "7zAlloc.h"
#include "7zCrc.h"
#include "7zFile.h"
#include "7zInterface.h"

struct SevenZipFileArchive {
    CFileInStream fileStream;
    CLookToRead lookStream;
    CSzArEx archive;
};

typedef struct SevenZipFilenameBuffer {
    Byte *utf16LE;
    size_t byteCount;
} SevenZipFilenameBuffer;

SevenZipFilenameBuffer SevenZipFilenameBuffer_Init();
int SevenZipFilenameBuffer_Realloc(SevenZipFilenameBuffer *buffer, size_t length);
void SevenZipFilenameBuffer_Free(SevenZipFilenameBuffer *buffer);

int SevenZipFileArchive_GetFileNameUTF16LE(const SevenZipFileArchive *archive, UInt32 fileIndex, SevenZipFilenameBuffer *buffer);


static ISzAlloc g_defaultAlloc = { .Alloc = SzAlloc, .Free = SzFree };
static ISzAlloc g_tempAlloc = { .Alloc = SzAlloc, .Free = SzFree };

void SevenZipInit(void) {
    CrcGenerateTable();
}

SevenZipFileArchive * SevenZipFileArchive_Open(const char *path) {
    // Allocate
    SevenZipFileArchive *archive = IAlloc_Alloc(&g_defaultAlloc, sizeof(SevenZipFileArchive));
    if (archive == NULL) {
        return NULL;
    }

    // Open file
    FileInStream_CreateVTable(&(archive->fileStream));

    int err = InFile_Open(&(archive->fileStream.file), path);
    if (err) {
        IAlloc_Free(&g_defaultAlloc, archive);
        return NULL;
    }

    // Set up buffered stream
    LookToRead_CreateVTable(&(archive->lookStream), False);

    archive->lookStream.realStream = &(archive->fileStream.s);
    LookToRead_Init(&(archive->lookStream));

    // Initialize archive structure
    SzArEx_Init(&(archive->archive));

    err = SzArEx_Open(&(archive->archive), &(archive->lookStream.s), &g_defaultAlloc, &g_tempAlloc);
    if (err != SZ_OK) {
        SzArEx_Free(&(archive->archive), &g_defaultAlloc);
        return NULL;
    }

    return archive;
}

void SevenZipFileArchive_Free(SevenZipFileArchive *archive) {
    SzArEx_Free(&(archive->archive), &g_defaultAlloc);
    IAlloc_Free(&g_defaultAlloc, archive);
}

UInt32 SevenZipFileArchive_GetFileCount(SevenZipFileArchive *archive) {
    return archive->archive.NumFiles;
}

SevenZipFileMetadata SevenZipFileMetadata_Init() {
    return (SevenZipFileMetadata){ .nameUTF16LE = NULL, .nameBytesCount = 0, .isDirectory = False, .fileSize = 0 };
}

void SevenZipFileMetadata_Free(SevenZipFileMetadata *metadata) {
    if (metadata->nameUTF16LE != NULL) {
        IAlloc_Free(&g_defaultAlloc, metadata->nameUTF16LE);
        metadata->nameUTF16LE = NULL;
        metadata->nameBytesCount = 0;
    }
}

int SevenZipFileArchive_GetFileMetadata(const SevenZipFileArchive *archive, UInt32 fileIndex, SevenZipFileMetadata *metadata) {
    SevenZipFilenameBuffer buffer = SevenZipFilenameBuffer_Init();
    int err = SevenZipFileArchive_GetFileNameUTF16LE(archive, fileIndex, &buffer);
    if (err == SZ_OK) {
        SevenZipFileMetadata_Free(metadata);
        metadata->nameUTF16LE = (Byte *)buffer.utf16LE;
        metadata->nameBytesCount = buffer.byteCount;
    } else {
        return err;
    }

    unsigned isDir = SzArEx_IsDir(&(archive->archive), fileIndex);
    metadata->isDirectory = !!isDir;

    metadata->fileSize = (size_t)SzArEx_GetFileSize(&(archive->archive), fileIndex);

    return SZ_OK;
}

int SevenZipFileArchive_Extract(SevenZipFileArchive *archive, UInt32 fileIndex, SzArEx_DictCache *cache, SevenZipExtractedBlock *extracted) {

    SRes err = SzArEx_Extract(&(archive->archive), &(archive->lookStream.s), fileIndex, cache, &g_defaultAlloc, &g_tempAlloc);
    if (err != SZ_OK) {
        return err;
    }

    if (extracted != NULL) {
        extracted->block = cache->outBuffer + cache->entryOffset;
        extracted->count = cache->outSizeProcessed;
    }

    return SZ_OK;
}

SzArEx_DictCache SevenZipExtractCache_Init() {
    SzArEx_DictCache cache;
    SzArEx_DictCache_init(&cache, &g_defaultAlloc);
    return cache;
}

void SevenZipExtractCache_Free(SzArEx_DictCache *cache) {
    SzArEx_DictCache_free(cache);
}

// -------------------------------------------------- Private filename functions

int SevenZipFileArchive_GetFileNameUTF16LE(const SevenZipFileArchive *archive, UInt32 fileIndex, SevenZipFilenameBuffer *buffer) {
    if (buffer == NULL) {
        return SZ_ERROR_PARAM;
    }

    size_t len = SzArEx_GetFileNameUtf16(&(archive->archive), fileIndex, NULL);
    int err = SevenZipFilenameBuffer_Realloc(buffer, len);
    if (err != SZ_OK) {
        return err;
    }

    SzArEx_GetFileNameUtf16(&(archive->archive), fileIndex, (UInt16 *)buffer->utf16LE);
    return SZ_OK;
}


SevenZipFilenameBuffer SevenZipFilenameBuffer_Init() {
    return (SevenZipFilenameBuffer){
        .utf16LE = NULL,
        .byteCount = 0,
    };
}

int SevenZipFilenameBuffer_Realloc(SevenZipFilenameBuffer *buffer, size_t length) {
    size_t bytesRequired = length * sizeof(UInt16);
    if (bytesRequired > buffer->byteCount) {
        SevenZipFilenameBuffer_Free(buffer);
        buffer->utf16LE = IAlloc_Alloc(&g_defaultAlloc, bytesRequired);
        if (buffer->utf16LE == NULL) {
            buffer->byteCount = 0;
            return SZ_ERROR_MEM;
        }
        buffer->byteCount = bytesRequired;
    }
    return SZ_OK;
}

void SevenZipFilenameBuffer_Free(SevenZipFilenameBuffer *buffer) {
    if (buffer->utf16LE != NULL) {
        IAlloc_Free(&g_defaultAlloc, buffer->utf16LE);
        buffer->utf16LE = NULL;
        buffer->byteCount = 0;
    }
}
