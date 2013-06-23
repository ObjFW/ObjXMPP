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
 * \brief A class describing a presence stanza.
 */
@interface XMPPPresence: XMPPStanza <OFComparing>
{
	OFString *_status, *_show, *_priority;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *status;
@property (copy) OFString *show;
@property (copy) OFNumber *priority;
#endif

/**
 * \brief Creates a new autoreleased XMPPPresence.
 *
 * \return A new autoreleased XMPPPresence
 */
+ (instancetype)presence;

/**
 * \brief Creates a new autoreleased XMPPPresence with the specified ID.
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ (instancetype)presenceWithID: (OFString*)ID;

/**
 * \brief Creates a new autoreleased XMPPPresence with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPPresence
 */
+ (instancetype)presenceWithType: (OFString*)type;

/**
 * \brief Creates a new autoreleased XMPPPresence with the specified type and
 *	  ID.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ (instancetype)presenceWithType: (OFString*)type
			      ID: (OFString*)ID;

/**
 * \brief Initializes an already allocated XMPPPresence with the specified ID.
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithID: (OFString*)ID;

/**
 * \brief Initializes an already allocated XMPPPresence with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type;

/**
 * \brief Initializes an already allocated XMPPPresence with the specified type
 *	  and ID.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * \brief Sets/Adds the show element of the presence stanza.
 *
 * \param show The text content of the show element
 */
- (void)setShow: (OFString*)show;

/**
 * \brief Returns the text content of the show element of the presence stanza.
 *
 * \return The text content of the show element of the presence stanza.
 */
- (OFString*)show;

/**
 * \brief Sets/Adds the status element of the presence stanza.
 *
 * \param status The text content of the status element
 */
- (void)setStatus: (OFString*)status;

/**
 * \brief Returns the text content of the status element of the presence stanza.
 *
 * \return The text content of the status element of the presence stanza.
 */
- (OFString*)status;

/**
 * \brief Sets/Adds the priority element of the presence stanza.
 *
 * \param priority The numeric content of the priority element
 */
- (void)setPriority: (OFNumber*)priority;

/**
 * \brief Returns the numeric content of the priority element of the presence
 *	  stanza.
 *
 * \return The numeric content of the priority element of the presence stanza.
 */
- (OFNumber*)priority;
@end
