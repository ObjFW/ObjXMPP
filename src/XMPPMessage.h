/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#import "XMPPStanza.h"

/**
 * \brief A class describing a message stanza.
 */
@interface XMPPMessage: XMPPStanza
#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *body;
#endif

/**
 * Creates a new autoreleased XMPPMessage.
 *
 * \return A new autoreleased XMPPMessage
 */
+ message;

/**
 * Creates a new autoreleased XMPPMessage with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPMessage with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type;

/**
 * Creates a new autoreleased XMPPMessage with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type
	       ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage.
 *
 * \return A initialized XMPPMessage
 */
- init;

/**
 * Initializes an already allocated XMPPMessage with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPMessage
 */
- initWithID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPMessage
 */
- initWithType: (OFString*)type;

/**
 * Initializes an already allocated XMPPMessage with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPMessage
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Sets the text content of the body of the XMPPMessage.
 *
 * \param body The text content of the body element or nil to remove the body
 */
- (void)setBody: (OFString*)body;

/**
 * Returns the text content of the body element of the XMPPMessage.
 *
 * \return The text content of the body element of the XMPPMessage.
 */
- (OFString*)body;
@end
