/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2016, Jonathan Schleifer <js@heap.zone>
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

/*!
 * @brief A base class for classes implementing authentication mechanisms
 */
@interface XMPPAuthenticator: OFObject
{
	OFString *_authzid, *_authcid, *_password;
}

/*!
 * The authzid to get authorization for.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *authzid;

/*!
 * The authcid to authenticate with.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *authcid;

/*!
 * The password to authenticate with.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *password;

/*!
 * @brief Initializes an already allocated XMPPAuthenticator with an authcid
 *	  and password.
 *
 * @param authcid The authcid to authenticate with
 * @param password The password to authenticate with
 * @return A initialized XMPPAuthenticator
 */
- (instancetype)initWithAuthcid: (nullable OFString *)authcid
		       password: (nullable OFString *)password;

/*!
 * @brief Initializes an already allocated XMPPSCRAMAuthenticator with an
 *	  authzid, authcid and password.
 *
 * @param authzid The authzid to get authorization for
 * @param authcid The authcid to authenticate with
 * @param password The password to authenticate with
 * @return A initialized XMPPAuthenticator
 */
- (instancetype)initWithAuthzid: (nullable OFString *)authzid
			authcid: (nullable OFString *)authcid
		       password: (nullable OFString *)password
    OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Returns OFData containing the initial authentication message.
 *
 * @return An OFDataAray containing the initial authentication message
 */
- (nullable OFData *)initialMessage;

/*!
 * @brief Continue authentication with the specified data.
 *
 * @param data The continuation data send by the server
 * @return The appropriate response if the data was a challenge, nil otherwise
 */
- (nullable OFData *)continueWithData: (OFData *)data;
@end

OF_ASSUME_NONNULL_END
