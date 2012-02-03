/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#import <ObjFW/ObjFW.h>

@class XMPPJID;

/**
 * \brief A class for representing an item in the roster.
 */
@interface XMPPRosterItem: OFObject
{
/// \cond intenral
	XMPPJID *JID;
	OFString *name;
	OFString *subscription;
	OFArray *groups;
/// \endcond
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) XMPPJID *JID;
@property (copy) OFString *name;
@property (copy) OFString *subscription;
@property (copy) OFArray *groups;
#endif

+ rosterItem;
- (void)setJID: (XMPPJID*)JID;
- (XMPPJID*)JID;
- (void)setName: (OFString*)name;
- (OFString*)name;
- (void)setSubscription: (OFString*)subscription;
- (OFString*)subscription;
- (void)setGroups: (OFArray*)groups;
- (OFArray*)groups;
@end
