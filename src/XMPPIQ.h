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

#import "XMPPStanza.h"

/**
 * \brief A class describing an IQ stanza.
 */
@interface XMPPIQ: XMPPStanza
/**
 * \brief Creates a new XMPPIQ with the specified type and ID.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPIQ
 */
+ IQWithType: (OFString*)type
	  ID: (OFString*)ID;

/**
 * \brief Initializes an already allocated XMPPIQ with the specified type and
 *	  ID.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return An initialized XMPPIQ
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * \brief Generates a result IQ for the receiving object.
 *
 * \return A new autoreleased XMPPIQ
 */
- (XMPPIQ*)resultIQ;

/**
 * \brief Generates an error IQ for the receiving object.
 *
 * \param type An error type as defined by RFC 6120
 * \param condition An error condition as defined by RFC 6120
 * \param text A descriptive text
 * \return A new autoreleased XMPPIQ
 */
- (XMPPIQ*)errorIQWithType: (OFString*)type
		 condition: (OFString*)condition
		      text: (OFString*)text;

/**
 * \brief Generates an error IQ for the receiving object.
 *
 * \param type An error type as defined by RFC 6120
 * \param condition A defined conditions from RFC 6120
 * \return A new autoreleased XMPPIQ
 */
- (XMPPIQ*)errorIQWithType: (OFString*)type
		 condition: (OFString*)condition;
@end
