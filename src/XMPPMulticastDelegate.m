/*
 * Copyright (c) 2012, Jonathan Schleifer <js@webkeks.org>
 *
 * https://heap.zone/objxmpp/
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

#import <ObjFW/ObjFW.h>
#import <ObjFW/OFData.h>

#import "XMPPMulticastDelegate.h"

@implementation XMPPMulticastDelegate
- (instancetype)init
{
	self = [super init];

	@try {
		_delegates = [[OFMutableData alloc]
		    initWithItemSize: sizeof(id)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_delegates release];

	[super dealloc];
}

- (void)addDelegate: (id)delegate
{
	[_delegates addItem: &delegate];
}

- (void)removeDelegate: (id)delegate
{
	id *items = [_delegates items];
	size_t i, count = [_delegates count];

	for (i = 0; i < count; i++) {
		if (items[i] != delegate)
			continue;

		[_delegates removeItemAtIndex: i];
		return;
	}
}

- (bool)broadcastSelector: (SEL)selector
	       withObject: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *currentDelegates = [[_delegates copy] autorelease];
	id *items = [currentDelegates items];
	size_t i, count = [currentDelegates count];
	bool handled = false;

	for (i = 0; i < count; i++) {
		id responder = items[i];

		if (![responder respondsToSelector: selector])
			continue;

		bool (*imp)(id, SEL, id) = (bool(*)(id, SEL, id))
		    [responder methodForSelector: selector];

		handled |= imp(responder, selector, object);
	}

	objc_autoreleasePoolPop(pool);

	return handled;
}

- (bool)broadcastSelector: (SEL)selector
	       withObject: (id)object1
	       withObject: (id)object2
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *currentDelegates = [[_delegates copy] autorelease];
	id *items = [currentDelegates items];
	size_t i, count = [currentDelegates count];
	bool handled = false;

	for (i = 0; i < count; i++) {
		id responder = items[i];

		if (![responder respondsToSelector: selector])
			continue;

		bool (*imp)(id, SEL, id, id) = (bool(*)(id, SEL, id, id))
		    [responder methodForSelector: selector];

		handled |= imp(responder, selector, object1, object2);
	}

	objc_autoreleasePoolPop(pool);

	return handled;
}
@end
