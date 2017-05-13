/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@class XMPPConnection;
@class XMPPIQ;

#ifdef OF_HAVE_BLOCKS
typedef void (^xmpp_callback_block_t)(XMPPConnection *_Nonnull,
    XMPPIQ *_Nonnull);
#endif

@interface XMPPCallback: OFObject
{
	id _target;
	SEL _selector;
#ifdef OF_HAVE_BLOCKS
	xmpp_callback_block_t _block;
#endif
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)callbackWithBlock: (xmpp_callback_block_t)callback;
- initWithBlock: (xmpp_callback_block_t)callback;
#endif

+ (instancetype)callbackWithTarget: (id)target
			  selector: (SEL)selector;
- initWithTarget: (id)target
	selector: (SEL)selector;

- (void)runWithIQ: (XMPPIQ *)iq
       connection: (XMPPConnection *)connection;
@end

OF_ASSUME_NONNULL_END
