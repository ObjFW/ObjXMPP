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

#import <ObjFW/ObjFW.h>

@class XMPPJID;

/**
 * \brief A class describing an XMPP Stanza.
 */
@interface XMPPStanza: OFXMLElement
{
/// \cond internal
	XMPPJID *from;
	XMPPJID *to;
	OFString *type;
	OFString *ID;
/// \endcond
}

#ifdef OF_HAVE_PROPERTIES
/// The value of the stanza's from attribute
@property (copy) XMPPJID *from;
/// The value of the stanza's to attribute
@property (copy) XMPPJID *to;
/// The value of the stanza's type attribute
@property (copy) OFString *type;
/// The value of the stanza's id attribute
@property (copy) OFString *ID;
#endif

/**
 * Creates a new autoreleased XMPPStanza with the specified name.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name;

/**
 * Creates a new autoreleased XMPPStanza with the specified name and type.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type;

/**
 * Creates a new autoreleased XMPPStanza with the specified name and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	      ID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPStanza with the specified name, type and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type
	      ID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPStanza from an OFXMLElement.
 *
 * \param element The element to base the XMPPStanza on
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithElement: (OFXMLElement*)element;

/**
 * Initializes an already allocated XMPPStanza with the specified name.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name;

/**
 * Initializes an already allocated XMPPStanza with the specified name and type.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	  type: (OFString*)type;

/**
 * Initializes an already allocated XMPPStanza with the specified name and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	    ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPStanza with the specified name, type
 * and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	  type: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPStanza based on a OFXMLElement
 *
 * \param element The element to base the XMPPStanza on
 * \return A initialized XMPPStanza
 */
- initWithElement: (OFXMLElement*)element;

- (void)setFrom: (XMPPJID*)from;
- (XMPPJID*)from;
- (void)setTo: (XMPPJID*)to;
- (XMPPJID*)to;
- (void)setType: (OFString*)type;
- (OFString*)type;
- (void)setID: (OFString*)ID;
- (OFString*)ID;
@end
