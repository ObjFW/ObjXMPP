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
 * \brief A class describing a presence stanza.
 */
@interface XMPPPresence: XMPPStanza
/**
 * Creates a new autoreleased XMPPPresence.
 *
 * \return A new autoreleased XMPPPresence
 */
+ presence;

/**
 * Creates a new autoreleased XMPPPresence with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPPresence with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithType: (OFString*)type;

/**
 * Creates a new autoreleased XMPPPresence with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithType: (OFString*)type
		ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPPresence.
 *
 * \return A initialized XMPPPresence
 */
- init;

/**
 * Initializes an already allocated XMPPPresence with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPPresence with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type;

/**
 * Initializes an already allocated XMPPPresence with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Adds a show element to the presence stanza.
 *
 * \param show The text content of the show element
 */
- (void)addShow: (OFString*)show;

/**
 * Adds a status element to the presence stanza.
 *
 * \param status The text content of the status element
 */
- (void)addStatus: (OFString*)status;

/**
 * Adds a priority element to the presence stanza.
 *
 * \param priority The text content of the priority element
 */
- (void)addPriority: (int8_t)priority;
@end
