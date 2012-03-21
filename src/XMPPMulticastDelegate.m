/*
 * Copyright (c) 2012, Jonathan Schleifer <js@webkeks.org>
 *
 * https://webkeks.org/git/?p=objxmpp.git
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

#import <ObjFW/OFDataArray.h>

#import "XMPPMulticastDelegate.h"

@implementation XMPPMulticastDelegate
- init
{
	self = [super init];

	@try {
		delegates = [[OFDataArray alloc] initWithItemSize: sizeof(id)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[delegates release];

	[super dealloc];
}

- (void)addDelegate: (id)delegate
{
	[delegates addItem: &delegate];
}

- (void)removeDelegate: (id)delegate
{
	id *cArray = [delegates cArray];
	size_t i, count = [delegates count];

	for (i = 0; i < count; i++) {
		if (cArray[i] == delegate) {
			[delegates removeItemAtIndex: i];
			return;
		}
	}
}

- (BOOL)broadcastSelector: (SEL)selector
	       withObject: (id)object
{
	id *cArray = [delegates cArray];
	size_t i, count = [delegates count];
	BOOL handled = NO;

	for (i = 0; i < count; i++) {
		if (![cArray[i] respondsToSelector: selector])
			continue;

		BOOL (*imp)(id, SEL, id) = (BOOL(*)(id, SEL, id))
		    [cArray[i] methodForSelector: selector];

		handled |= imp(cArray[i], selector, object);
	}

	return handled;
}

- (BOOL)broadcastSelector: (SEL)selector
	       withObject: (id)object1
	       withObject: (id)object2
{
	id *cArray = [delegates cArray];
	size_t i, count = [delegates count];
	BOOL handled = NO;

	for (i = 0; i < count; i++) {
		if (![cArray[i] respondsToSelector: selector])
			continue;

		BOOL (*imp)(id, SEL, id, id) = (BOOL(*)(id, SEL, id, id))
		    [cArray[i] methodForSelector: selector];

		handled |= imp(cArray[i], selector, object1, object2);
	}

	return handled;
}
@end
