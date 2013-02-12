/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPCallback.h"

@implementation XMPPCallback
#ifdef OF_HAVE_BLOCKS
+ callbackWithBlock: (xmpp_callback_block_t)block
{
	return [[(XMPPCallback*)[self alloc] initWithBlock: block] autorelease];
}

- initWithBlock: (xmpp_callback_block_t)block_
{
	self = [super init];

	@try {
		block = [block_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

+ callbackWithTarget: (id)target
	    selector: (SEL)selector
{
	return [[[self alloc] initWithTarget: target
				    selector: selector] autorelease];
}

- initWithTarget: (id)target_
	selector: (SEL)selector_
{
	self = [super init];

	_target = [target_ retain];
	_selector = selector_;

	return self;
}

- (void)dealloc
{
	[_target release];
#ifdef OF_HAVE_BLOCKS
	[block release];
#endif

	[super dealloc];
}

- (void)runWithIQ: (XMPPIQ*)iq
       connection: (XMPPConnection*)connection
{
#ifdef OF_HAVE_BLOCKS
	if (block != NULL)
		block(connection, iq);
	else
#endif
		[_target performSelector: _selector
			      withObject: connection
			      withObject: iq];
}
@end
