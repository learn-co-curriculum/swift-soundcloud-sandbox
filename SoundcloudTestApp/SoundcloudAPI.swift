//
//  SoundcloudAuth.swift
//  SoundcloudTestApp
//
//  Created by Timothy Clem on 3/21/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import Alamofire
import KeychainAccess


class SoundcloudAPI {
    private static let keychainServiceID = "com.flatironschool.soundcloudsample"
    private static let keychainAccessTokenKey = "access_token"

    private static let keychain = Keychain(service: keychainServiceID)


    /**
     Returns the OAuth access token for the logged-in user, or nil if there isn't one.
     */
    static var accessToken:String? {
        set {
            keychain[keychainAccessTokenKey] = newValue
        }

        get {
            return keychain[keychainAccessTokenKey]
        }
    }


    /**
     Removes any existing access token from the keychain.
     */
    static func logOut()
    {
        do {
            try keychain.remove(keychainAccessTokenKey)
        }
        catch {
            print("Error removing access token: \(error). Ignoring...")
        }
    }


    /**
     Logs in to Soundcloud using the credentials in the Secrets file, or recovers existing credentials from the keychain if they exist.

     - parameter completionHandler: This block is called when the process completes. If login failed, the `errorDescription` argument will be a string describing what went wrong. If the login succeeded, `errorDescription` will be `nil`, and you can use the `request` method to make authenticated requests.
     */
    static func logInOrRecoverToken(completionHandler:(errorDescription:String?) -> ()) {
        if self.accessToken != nil {
            print("Found an existing token")

            NSOperationQueue.mainQueue().addOperationWithBlock {
                completionHandler(errorDescription: nil)
            }

            return
        }

        let authParams = [
            "grant_type": "password",
            "username": SoundcloudUsername,
            "password": SoundcloudPassword,
            "client_id": SoundcloudClientID,
            "client_secret": SoundcloudClientSecret
        ]

        Alamofire.request(.POST, "https://api.soundcloud.com/oauth2/token", parameters: authParams)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success(let jsonObject):
                    if let jsonDict = jsonObject as? NSDictionary,
                       let accessToken = jsonDict["access_token"] as? String
                    {
                        print("Got an access token!")
                        self.accessToken = accessToken

                        completionHandler(errorDescription: nil)
                    }
                    else {
                        print("Unexpected JSON response from login: \(jsonObject)")
                        completionHandler(errorDescription: "Invalid server response")
                    }

                case .Failure(let error):
                    print("Login error: \(error)")
                    completionHandler(errorDescription: error.localizedDescription)
                }
        }
    }


    /**
     Makes an authenticated request to the Soudcloud API using the given options. Call `logInOrRecoverToken` before calling this to ensure the authentication process has finished.
     
     This method always appends the `oauth_token` and `client_id` to the URL's query parameters.
     
     - seealso: Arguments and usage are exactly the same as `Alamofire.request`.
     */
    static func request(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding = .URL,
        headers: [String: String]? = nil)
        -> Request
    {
        return Manager.sharedInstance.request(
            method,
            URLString,
            parameters: parameters ?? [:],  // For some reason AF likes to crash with no parameters? WTF?
            encoding: authedEncodingBasedOnEncoding(encoding),
            headers: headers
        )
    }


    /**
     Soundcloud demands that we do all requests with `oauth_token` (and sometimes the `client_id`) in the query string of the URL, even for POSTs and PUTs. AF doesn't support that (it's pretty non-standard), so I baked my own `ParameterEncoding` for it, that shells out to another encoding to do the real work and then appends the query string. Fun!
     */
    private static func authedEncodingBasedOnEncoding(baseEncoding: ParameterEncoding) -> ParameterEncoding
    {
        return ParameterEncoding.Custom { (requestConvertible, params) in
            let (urlRequest, error) = baseEncoding.encode(requestConvertible, parameters: params)

            if error != nil {
                return (urlRequest, error)
            }

            let clientIDItem = NSURLQueryItem(name: "client_id", value: SoundcloudClientID)
            urlRequest.URL = urlByAddingQueryItem(clientIDItem, toURL: urlRequest.URL!)

            if let accessToken = accessToken {
                let oauthItem = NSURLQueryItem(name: "oauth_token", value: accessToken)
                urlRequest.URL = urlByAddingQueryItem(oauthItem, toURL: urlRequest.URL!)

                return (urlRequest, error)
            }
            else {
                print("Trying to use SoundcloudAPI.request, but there's no accessToken! This request will not be authenticated. Call logInOrRecoverToken first!")

                return (urlRequest, error)
            }
        }
    }

    private static func urlByAddingQueryItem(item:NSURLQueryItem, toURL url:NSURL) -> NSURL
    {
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        var newQueryItems = [item]

        if let queryItems = urlComponents.queryItems {
            newQueryItems.appendContentsOf(queryItems)
        }

        urlComponents.queryItems = newQueryItems

        return urlComponents.URL!
    }
}

