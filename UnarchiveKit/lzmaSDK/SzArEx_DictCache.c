//
//  SzArEx_DictCache.c
//  UnarchiveKit
//
//  Created by James Lawton on 7/26/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#include <assert.h>
#include <errno.h>
#include <unistd.h> // ftruncate
#include <sys/mman.h> // mmap

#include "SzArEx_DictCache.h"

void SzArEx_DictCache_init(SzArEx_DictCache *dictCache, ISzAlloc *allocMain)
{
    dictCache->allocMain = allocMain;
    dictCache->blockIndex = 0xFFFFFFFF;
    dictCache->outBuffer = 0;
    dictCache->outBufferSize = 0;
    dictCache->entryOffset = 0;
    dictCache->outSizeProcessed = 0;
    dictCache->mapFile = NULL;
}

void SzArEx_DictCache_free(SzArEx_DictCache *dictCache)
{
    if (dictCache->mapFile) {
        // unmap memory
        SzArEx_DictCache_munmap(dictCache);
        // close file handle (it will be set to NULL in init method)
        fclose(dictCache->mapFile);
    } else if (dictCache->outBuffer != 0) {
        // free memory that was allocated on the heap
        IAlloc_Free(dictCache->allocMain, dictCache->outBuffer);
    }
    SzArEx_DictCache_init(dictCache, dictCache->allocMain);
}

int SzArEx_DictCache_mmap(SzArEx_DictCache *dictCache)
{
    assert(dictCache->mapFile == NULL);

    FILE *mapfile = tmpfile();
    if (mapfile == NULL) {
        return 1;
    }

    // Extend the file size so that it is a known length before mapping.
    size_t mapSize = dictCache->outBufferSize;
    assert(mapSize > 0);

    // Make sure mapSize is in terms of whole pages
    {
        size_t page_size = (size_t)sysconf(_SC_PAGESIZE);
        size_t numPages = mapSize / page_size;
        if ((mapSize % page_size) > 0) {
            numPages += 1;
        }
        mapSize = (numPages * page_size);
    }
    dictCache->mapSize = mapSize;

    // Set the backing file size
    int fd = fileno(mapfile);
    ftruncate(fd, mapSize);

    off_t offset = 0;
    int protection = PROT_READ | PROT_WRITE;
    int flags = MAP_FILE | MAP_SHARED;

    char *mappedData = mmap(NULL, mapSize, protection, flags, fd, offset);

    if (mappedData == MAP_FAILED) {
        int errnoVal = errno;
        int retval = 0;
        // Check for known fatal errors

        if (errnoVal == EACCES) {
            // mmap result EACCES : file not opened for reading or writing
            retval = 1;
        } else if (errnoVal == EBADF) {
            // mmap result EBADF : bad file descriptor
            retval = 1;
        } else if (errnoVal == EINVAL) {
            // mmap result EINVAL
            retval = 1;
        } else if (errnoVal == ENODEV) {
            // mmap result ENODEV : page does not support mapping
            retval = 1;
        } else if (errnoVal == ENXIO) {
            // mmap result ENXIO : invalid addresses
            retval = 1;
        } else if (errnoVal == EOVERFLOW) {
            // mmap result EOVERFLOW : addresses exceed the maximum offset
            retval = 1;
        } else if (errnoVal == ENOMEM) {
            // mmap result ENOMEM : cannot allocate memory
            retval = 2;
        }

        fclose(mapfile);
        return retval;
    }

#ifdef DEBUG
    // We always map at least 1 page of memory, so test basic writing of bytes by
    // writing zero to the first and second bytes in the mapped memory.

    mappedData[0] = 0;
    mappedData[1] = 0;
#endif

    dictCache->mapFile = mapfile;
    dictCache->outBuffer = (void *)mappedData;

    return 0;
}

void SzArEx_DictCache_munmap(SzArEx_DictCache *dictCache)
{
    int result = munmap(dictCache->outBuffer, dictCache->mapSize);
    assert(result == 0);
    dictCache->outBuffer = NULL;
    dictCache->mapSize = 0;
}
