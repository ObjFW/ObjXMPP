/*
 * Copyright (c) 2012, 2019, 2021, Jonathan Schleifer <js@nil.im>
 *
 * https://nil.im/objxmpp/
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include <stdlib.h>

#import <ObjFW/OFString.h>
#import <ObjFW/OFArray.h>
#import <ObjFW/OFDictionary.h>
#import <ObjFW/OFNumber.h>
#import <ObjFW/OFData.h>

#import <ObjFW/OFNotImplementedException.h>

#import "XMPPFileStorage.h"

@implementation XMPPFileStorage
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithFile: (OFString *)file
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_file = [file copy];
		@try {
			_data = [[OFData dataWithContentsOfFile: file]
			    .objectByParsingMessagePack copy];
		} @catch (id e) {
			_data = [[OFMutableDictionary alloc] init];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_file release];
	[_data release];

	[super dealloc];
}

- (void)save
{
	[_data.messagePackRepresentation writeToFile: _file];
}

- (void)xmpp_setObject: (id)object
	       forPath: (OFString *)path
{
	OFArray *pathComponents = [path componentsSeparatedByString: @"."];
	OFMutableDictionary *iter = _data;
	size_t i = 0, components = pathComponents.count;

	for (OFString *component in pathComponents) {
		if (i++ == components - 1)
			continue;

		OFMutableDictionary *iter2 = [iter objectForKey: component];

		if (iter2 == nil) {
			iter2 = [OFMutableDictionary dictionary];
			[iter setObject: iter2 forKey: component];
		}

		iter = iter2;
	}

	if (object != nil)
		[iter setObject: object forKey: [pathComponents lastObject]];
	else
		[iter removeObjectForKey: pathComponents.lastObject];
}

- (id)xmpp_objectForPath: (OFString *)path
{
	id object = _data;

	for (OFString *component in [path componentsSeparatedByString: @"."])
		object = [object objectForKey: component];

	return object;
}

- (void)setStringValue: (OFString *)string
	       forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self xmpp_setObject: string forPath: path];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringValueForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *string;

	string = [self xmpp_objectForPath: path];

	objc_autoreleasePoolPop(pool);

	return string;
}

- (void)setBooleanValue: (bool)boolean forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self xmpp_setObject: [OFNumber numberWithBool: boolean] forPath: path];

	objc_autoreleasePoolPop(pool);
}

- (bool)booleanValueForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool boolean;

	boolean = [[self xmpp_objectForPath: path] boolValue];

	objc_autoreleasePoolPop(pool);

	return boolean;
}

- (void)setIntegerValue: (long long)integer forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self xmpp_setObject: [OFNumber numberWithLongLong: integer]
		     forPath: path];

	objc_autoreleasePoolPop(pool);
}

- (long long)integerValueForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	long long integer;

	integer = [[self xmpp_objectForPath: path] longLongValue];

	objc_autoreleasePoolPop(pool);

	return integer;
}

- (void)setArray: (OFArray *)array forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self xmpp_setObject: array forPath: path];

	objc_autoreleasePoolPop(pool);
}

- (OFArray *)arrayForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *array;

	array = [self xmpp_objectForPath: path];

	objc_autoreleasePoolPop(pool);

	return array;
}

- (void)setDictionary: (OFDictionary *)dictionary forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self xmpp_setObject: dictionary forPath: path];

	objc_autoreleasePoolPop(pool);
}

- (OFDictionary *)dictionaryForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *dictionary;

	dictionary = [self xmpp_objectForPath: path];

	objc_autoreleasePoolPop(pool);

	return dictionary;
}
@end
