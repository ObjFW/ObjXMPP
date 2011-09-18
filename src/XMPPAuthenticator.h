/*
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

/**
 * \brief A base class for classes implementing authentication mechanisms
 */
@interface XMPPAuthenticator: OFObject
{
	OFString *authzid;
	OFString *authcid;
	OFString *password;
}

#ifdef OF_HAVE_PROPERTIES
/// The authzid to get authorization for
@property (copy) OFString *authzid;
/// The authcid to authenticate with
@property (copy) OFString *authcid;
/// The password to authenticate with
@property (copy) OFString *password;
#endif

/**
 * Initializes an already allocated XMPPAuthenticator with an authcid
 * and password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \return A initialized XMPPAuthenticator
 */
- initWithAuthcid: (OFString*)authcid
	 password: (OFString*)password;

/**
 * Initializes an already allocated XMPPSCRAMAuthenticator with an authzid,
 * authcid and password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \return A initialized XMPPAuthenticator
 */
- initWithAuthzid: (OFString*)authzid
	  authcid: (OFString*)authcid
	 password: (OFString*)password;

/**
 * \return A OFDataAray containing the initial authentication message
 */
- (OFDataArray*)initialMessage;

/**
 * \param data The continuation data send by the server
 * \return The appropriate response if the data was a challenge, nil otherwise
 */
- (OFDataArray*)continueWithData: (OFDataArray*)data;

- (void)setAuthzid: (OFString*)authzid;
- (OFString*)authzid;
- (void)setAuthcid: (OFString*)authcid;
- (OFString*)authcid;
- (void)setPassword: (OFString*)password;
- (OFString*)password;
@end
