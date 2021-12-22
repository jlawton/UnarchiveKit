//
//  Unrar4iOS.h
//  Unrar4iOS
//
//  Created by Rogerio Pereira Araujo on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Unrar4iOS : NSObject

@property(nonatomic, retain) NSString* filename;
@property(nonatomic, retain, nullable) NSString* password;

-(BOOL) unrarOpenFile:(NSString*) rarFile;
-(BOOL) unrarOpenFile:(NSString*) rarFile withPassword:(nullable NSString*) aPassword;
-(NSArray<NSString *> *) unrarListFiles;
-(NSArray<NSString *> *) unrarListFilesWithDirectories:(BOOL)includeDirectories;
- (BOOL)enumerateFilesWithDirectories:(BOOL)includeDirectories block:(NS_NOESCAPE void(^)(NSString  * _Nonnull filename, uint64_t length))block;
-(BOOL) unrarFileTo:(NSString*)path overWrite:(BOOL)overwrite;
-(nullable NSData *) extractStream:(NSString *)aFile;
-(BOOL) unrarCloseFile;

@end

NS_ASSUME_NONNULL_END
