/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#import <ObjFW/ObjFW.h>

/**
 * \brief A class for easy handling of JIDs.
 */
@interface XMPPJID: OFObject <OFCopying>
{
	OFString *_node, *_domain, *_resource;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The JID's localpart
@property (copy) OFString *node;
/// \brief The JID's domainpart
@property (copy) OFString *domain;
/// \brief The JID's resourcepart
@property (copy) OFString *resource;
#endif

/**
 * \brief Creates a new autoreleased XMPPJID.
 *
 * \return A new autoreleased XMPPJID
 */
+ JID;

/**
 * \brief Creates a new autoreleased XMPPJID from a string.
 *
 * \param string The string to parse into a JID object
 * \return A new autoreleased XMPPJID
 */
+ JIDWithString: (OFString*)string;

/**
 * \brief Initializes an already allocated XMPPJID with a string.
 *
 * \param string The string to parse into a JID object
 * \return A initialized XMPPJID
 */
- initWithString: (OFString*)string;

/**
 * \brief Returns the bare JID.
 *
 * \return An OFString containing the bare JID
 */
- (OFString*)bareJID;

/**
 * \brief Returns the full JID.
 *
 * \return An OFString containing the full JID
 */
- (OFString*)fullJID;

- (void)setNode: (OFString*)node;
- (OFString*)node;
- (void)setDomain: (OFString*)domain;
- (OFString*)domain;
- (void)setResource: (OFString*)resource;
- (OFString*)resource;
@end
