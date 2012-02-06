/*
 * Copyright (c) 2012, Jonathan Schleifer <js@webkeks.org>
 *
 * https://webkeks.org/hg/objxmpp/
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import <ObjFW/OFString.h>
#import <ObjFW/OFArray.h>
#import <ObjFW/OFDictionary.h>
#import <ObjFW/OFNumber.h>
#import <ObjFW/OFAutoreleasePool.h>

#import <ObjFW/OFNotImplementedException.h>

#import "XMPPJSONFileStorage.h"

@implementation XMPPJSONFileStorage
- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithFile: (OFString*)file_
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [OFAutoreleasePool new];

		file = [file_ copy];
		@try {
			data = [[[OFString stringWithContentsOfFile:
			    file] JSONValue] retain];
		} @catch (id e) {
			data = [OFMutableDictionary new];
		}

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[file release];
	[data release];

	[super dealloc];
}

- (void)save
{
	[[data JSONRepresentation] writeToFile: file];
}

- (void)XMPP_setObject: (id)object
	       forPath: (OFString*)path
{
	OFArray *pathComponents = [path componentsSeparatedByString: @"."];
	OFMutableDictionary *iter = data;
	OFEnumerator *enumerator = [pathComponents objectEnumerator];
	OFString *component;
	size_t i = 0, components = [pathComponents count];

	while ((component = [enumerator nextObject]) != nil) {
		if (i++ == components - 1)
			continue;

		OFMutableDictionary *iter2 = [iter objectForKey: component];

		if (iter2 == nil) {
			iter2 = [OFMutableDictionary dictionary];
			[iter setObject: iter2
				 forKey: component];
		}

		iter = iter2;
	}

	if (object != nil)
		[iter setObject: object
			 forKey: [pathComponents lastObject]];
	else
		[iter removeObjectForKey: [pathComponents lastObject]];
}

- (id)XMPP_objectForPath: (OFString*)path
{
	OFArray *pathComponents = [path componentsSeparatedByString: @"."];
	OFEnumerator *enumerator = [pathComponents objectEnumerator];
	OFString *component;
	id object = data;

	while ((component = [enumerator nextObject]) != nil)
		object = [object objectForKey: component];

	return object;
}

- (void)setStringValue: (OFString*)string
	       forPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];

	[self XMPP_setObject: string
		     forPath: path];

	[pool release];
}

- (OFString*)stringValueForPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	OFString *string;

	string = [self XMPP_objectForPath: path];

	[pool release];

	return string;
}

- (void)setBooleanValue: (BOOL)boolean
		forPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];

	[self XMPP_setObject: [OFNumber numberWithBool: boolean]
		     forPath: path];

	[pool release];
}

- (BOOL)booleanValueForPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	BOOL boolean;

	boolean = [[self XMPP_objectForPath: path] boolValue];

	[pool release];

	return boolean;
}

- (void)setIntegerValue: (intmax_t)integer
		forPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];

	[self XMPP_setObject: [OFNumber numberWithIntMax: integer]
		     forPath: path];

	[pool release];
}

- (intmax_t)integerValueForPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	intmax_t integer;

	integer = [[self XMPP_objectForPath: path] intMaxValue];

	[pool release];

	return integer;
}

- (void)setArray: (OFArray*)array
	 forPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];

	[self XMPP_setObject: array
		     forPath: path];

	[pool release];
}

- (OFArray*)arrayForPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	OFArray *array;

	array = [self XMPP_objectForPath: path];

	[pool release];

	return array;
}

- (void)setDictionary: (OFDictionary*)dictionary
	      forPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];

	[self XMPP_setObject: dictionary
		     forPath: path];

	[pool release];
}

- (OFDictionary*)dictionaryForPath: (OFString*)path
{
	OFAutoreleasePool *pool = [OFAutoreleasePool new];
	OFDictionary *dictionary;

	dictionary = [self XMPP_objectForPath: path];

	[pool release];

	return dictionary;
}
@end
