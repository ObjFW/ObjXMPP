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

#import <ObjFW/OFObject.h>

@class OFDataArray;

/**
 * \brief A class to provide multiple delegates in a single class
 */
@interface XMPPMulticastDelegate: OFObject
{
	OFDataArray *_delegates;
	size_t handlerIndex;
}

/**
 * \brief Adds a delegate which should receive the broadcasts.
 *
 * \param delegate The delegate to add
 */
- (void)addDelegate: (id)delegate;

/**
 * \brief Removes a delegate so it does not receive the broadcasts anymore.
 *
 * \param delegate The delegate to remove
 */
- (void)removeDelegate: (id)delegate;

/**
 * \brief Broadcasts a selector with an object to all registered delegates.
 *
 * \param selector The selector to broadcast
 * \param object The object to broadcast
 */
- (BOOL)broadcastSelector: (SEL)selector
	       withObject: (id)object;

/**
 * \brief Broadcasts a selector with two objects to all registered delegates.
 *
 * \param selector The selector to broadcast
 * \param object1 The first object to broadcast
 * \param object2 The second object to broadcast
 */
- (BOOL)broadcastSelector: (SEL)selector
	       withObject: (id)object1
	       withObject: (id)object2;
@end
