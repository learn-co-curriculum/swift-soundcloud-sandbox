//
//  ViewController.swift
//  SoundcloudTestApp
//
//  Created by Timothy Clem on 3/21/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


class ViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    
    @IBAction private func buttonTapped(sender: AnyObject) {
        SoundcloudAPI.logInOrRecoverToken({ errorDescription in
            if let errorDescription = errorDescription {
                self.handleLoginError(errorDescription)
                return
            }

            self.fetchUserDetails()
        })
    }

    @IBAction private func logOutButtonTapped(sender: AnyObject) {
        SoundcloudAPI.logOut()
    }

    private func handleLoginError(errorDescription: String) {
        print("womp womp! \(errorDescription)")
    }

    private func fetchUserDetails() {
        print("fetching user details...")

        SoundcloudAPI.request(.GET, "https://api.soundcloud.com/me")
            .validate()
            .responseJSON { response in
                if let userDict = response.result.value as? [String: AnyObject] {
                    let userJSON = JSON(userDict)
                    let userName = userJSON["full_name"].stringValue

                    self.label.text = "Welcome, \(userName)"
                }
                else {
                    print("Something went wrong! \(response.result.error?.localizedDescription)")
                }
            }
    }
}

