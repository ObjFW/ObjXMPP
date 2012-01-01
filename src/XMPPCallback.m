/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPCallback.h"

#ifdef OF_HAVE_BLOCKS
@implementation XMPPBlockCallback
+ callbackWithCallbackBlock: (xmpp_callback_block)callback_
{
	return [[[self alloc] initWithCallbackBlock: callback_] autorelease];
}

- initWithCallbackBlock: (xmpp_callback_block)callback_
{
	self = [super init];

	callback = [callback_ copy];

	return self;
}

- (void)dealloc
{
	[callback release];

	[super dealloc];
}

- (void)runWithIQ: (XMPPIQ*)iq
{
	callback(iq);
}
@end
#endif

@implementation XMPPObjectCallback
+ callbackWithCallbackObject: (id)object_
		    selector: (SEL)selector_
{
	return [[[self alloc] initWithCallbackObject: object_
					    selector: selector_] autorelease];
}

- initWithCallbackObject: (id)object_
		selector: (SEL)selector_
{
	self = [super init];

	// TODO: Retain or follow delegate paradigm?
	object = [object_ retain];
	selector = selector_;

	return self;
}

- (void)dealloc
{
	[object release];

	[super dealloc];
}

- (void)runWithIQ: (XMPPIQ*)iq
{
	[object performSelector: selector
		     withObject: iq];
}
@end
