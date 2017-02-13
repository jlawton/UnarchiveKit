//
//  Unrar4iOS.mm
//  Unrar4iOS
//
//  Created by Rogerio Pereira Araujo on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <wchar.h>
#import "Unrar4iOS.h"
#import "RARExtractException.h"
#import "raros.hpp"
#import "dll.hpp"

@interface Unrar4iOS()
-(BOOL)_unrarOpenFile:(NSString*)rarFile inMode:(unsigned int)mode;
-(BOOL)_unrarOpenFile:(NSString*)rarFile inMode:(unsigned int)mode withPassword:(NSString*)password;
-(BOOL)_unrarCloseFile;
@end

@implementation Unrar4iOS
{
    void	 *_rarFile;
    struct	 RARHeaderDataEx *header;
    struct	 RAROpenArchiveDataEx *flags;
    NSString *filename;
    NSString *password;
}

@synthesize filename, password;

int CALLBACK CallbackProc(UINT msg, long UserData, long P1, long P2) {
	UInt8 **buffer;
	
	switch(msg) {
			
		case UCM_CHANGEVOLUME:
			break;
		case UCM_PROCESSDATA:
            if (UserData) {
                buffer = (UInt8 **) UserData;
                memcpy(*buffer, (UInt8 *)P1, P2);
                // advance the buffer ptr, original m_buffer ptr is untouched
                *buffer += P2;
            }
			break;
		case UCM_NEEDPASSWORD:
			break;
	}
	return(0);
}

-(BOOL) unrarOpenFile:(NSString*)rarFile {
    
	return [self unrarOpenFile:rarFile withPassword:nil];
}

-(BOOL) unrarOpenFile:(NSString*)rarFile withPassword:(NSString *)aPassword {
    
	self.filename = rarFile;
    self.password = aPassword;
	return YES;
}

-(BOOL) _unrarOpenFile:(NSString*)rarFile inMode:(unsigned int)mode{
	
    return [self _unrarOpenFile:rarFile inMode:mode withPassword:nil];
}

- (BOOL)_unrarOpenFile:(NSString *)rarFile inMode:(unsigned int)mode withPassword:(NSString *)aPassword {
    
	header = new RARHeaderDataEx;
    bzero(header, sizeof(RARHeaderDataEx));
	flags = new RAROpenArchiveDataEx;
    bzero(flags, sizeof(RAROpenArchiveDataEx));
	
	const char *filenameData = (const char *) [rarFile UTF8String];
	flags->ArcName = new char[strlen(filenameData) + 1];
	strcpy(flags->ArcName, filenameData);
	flags->OpenMode = mode;
	
	_rarFile = RAROpenArchiveEx(flags);
	if (_rarFile == 0 || flags->OpenResult != 0) {
        [self _unrarCloseFile];
		return NO;
    }
	
    if(aPassword != nil) {
        char *_password = (char *) [aPassword UTF8String];
        RARSetPassword(_rarFile, _password);
    }
    
	return YES;
}

-(NSArray<NSString *> *) unrarListFiles {
    return [self unrarListFilesWithDirectories:YES];
}

-(NSArray<NSString *> *) unrarListFilesWithDirectories:(BOOL)includeDirectories {
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    [self enumerateFilesWithDirectories:includeDirectories block:^(NSString *filename, uint64_t length) {
        [files addObject:filename];
    }];
    return files;
}

static inline uint64_t GetFilesize(RARHeaderDataEx *header) {
    return (header->UnpSizeHigh << 32) | header->UnpSize;
}

- (BOOL)enumerateFilesWithDirectories:(BOOL)includeDirectories block:(NS_NOESCAPE void(^)(NSString * _Nonnull filename, uint64_t length))block {
    int RHCode = 0, PFCode = 0;

    if ([self _unrarOpenFile:filename inMode:RAR_OM_LIST_INCSPLIT withPassword:password] == NO)
        return NO;

    while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
        BOOL isDirectory = (header->Flags & 0xe0) == 0xe0;
        if (includeDirectories || !isDirectory) {
            wchar_t *fileNameW = header->FileNameW;
            NSString *_filename = [[[NSString alloc]
                initWithBytes:fileNameW
                length:wcslen(fileNameW) * sizeof(*fileNameW)
                encoding:NSUTF32LittleEndianStringEncoding] autorelease];
            block(_filename, GetFilesize(header));
        }

        if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
            [self _unrarCloseFile];
            return NO;
        }
    }
    
    [self _unrarCloseFile];
    return YES;
}

-(BOOL) unrarFileTo:(NSString*)path overWrite:(BOOL)overwrite {
    int RHCode = 0, PFCode = 0;
    
    NSString *filePath = [path stringByAppendingPathComponent:self.filename];
    
    if (overwrite) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    if ([self _unrarOpenFile:filename inMode:RAR_OM_EXTRACT] == NO)
        return NO;
    
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
        
        if ((PFCode = RARProcessFile(_rarFile, RAR_EXTRACT, (char *)[path UTF8String], NULL)) != 0) {
            [self _unrarCloseFile];
            return NO;
        }
        
    }
    
    [self _unrarCloseFile];
    return YES;
}

-(NSData *) extractStream:(NSString *)aFile {
	int RHCode = 0, PFCode = 0;
	
	if ([self _unrarOpenFile:filename inMode:RAR_OM_EXTRACT withPassword:password] == NO)
        return nil;
	
	size_t length = 0;
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
    wchar_t *fileNameW = header->FileNameW;
    NSString *_filename = [[[NSString alloc] initWithBytes:fileNameW length:wcslen(fileNameW) * sizeof(*fileNameW) encoding:NSUTF32LittleEndianStringEncoding] autorelease];
				
		if ([_filename isEqualToString:aFile]) {
			length = GetFilesize(header);
			break;
		} 
		else {
			if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
				[self _unrarCloseFile];
				return nil;
			}
		}
	}
	
	if (length == 0) { // archived file not found
		[self _unrarCloseFile];
		return nil;
	}
	
	UInt8 *buffer = (UInt8 *)malloc(length * sizeof(UInt8));
	UInt8 *callBackBuffer = buffer;
	
	RARSetCallback(_rarFile, CallbackProc, (long) &callBackBuffer);
	
	PFCode = RARProcessFile(_rarFile, RAR_TEST, NULL, NULL);

    [self _unrarCloseFile];
    if(PFCode == ERAR_MISSING_PASSWORD) {
        RARExtractException *exception = [RARExtractException exceptionWithStatus:RARArchiveProtected];
        @throw exception;           
        return nil;
    }
    if(PFCode == ERAR_BAD_ARCHIVE) {
        RARExtractException *exception = [RARExtractException exceptionWithStatus:RARArchiveInvalid];
        @throw exception;           
        return nil;
    }
    if(PFCode == ERAR_UNKNOWN_FORMAT) {
        RARExtractException *exception = [RARExtractException exceptionWithStatus:RARArchiveBadFormat];
        @throw exception;           
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES];
}

-(BOOL) _unrarCloseFile {
	if (_rarFile)
		RARCloseArchive(_rarFile);
    _rarFile = 0;
    
    if (flags)
        delete flags->ArcName;
	delete flags, flags = 0;
    delete header, header = 0;
	return YES;
}

-(BOOL) unrarCloseFile {
	return YES;
}

-(void) dealloc {
	[filename release];
    [password release];
	[super dealloc];
}

@end
