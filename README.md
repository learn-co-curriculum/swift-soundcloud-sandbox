# Soundcloud Sandbox

Let's play around with the Soundcloud API!

## To begin...

1. Make yourself an account on [Soundcloud](https://soundcloud.com). **IMPORTANT:** do not make one by logging in with Facebook or Google! Accounts created like that will not be usable with the log in method we're using. If you want to use an existing account you made in that fashion, you're on your own for figuring out the OAuth flow.
2. Register a new application on the [Soundcloud Developers Site](http://soundcloud.com/you/apps/new). We're going to be sidestepping OAuth, so the redirect URI doesn't matter right now.
3. Set up your project's secrets file. I've included `Secrets.swift.template`. Rename this file to `Secrets.swift` and insert your app's client ID and secret, and your username and password. Don't worry, `Secrets.swift` is ignored from source controll and won't be committed to git. **Make sure you rename the file**, though.
4. Now the project should be good to go! Open up the workspace, run the app, and hit the "Log in" button. You should see "Welcome, <your name>!" in the label on the right of the screen.


## Deeper Dive

In this project there's a class, `SoundcloudAPI`, to make it easier to talk to the API. You can see an example usage in the view controller. Here's an overview of the methods it exposes. Don't worry too much about the details; it's a lot of jiggery-pokery of Alamofire guts.

- The `accessToken` property returns the token used to authenticate requests as the user whose credentials you entered in the secrets file. It is `nil` if the user is not logged in. This value is stored in the keychain, so it will persist between launches of the app.
- The `logInOrRecoverToken` method logs in using the credentials in the secrets file and calls the completion block when it finishes. If an error occurred, the block is called back with a string description of the error. If it succeeds, the block is called back with a `nil` argument. On success, the `accessToken` property is available, and the token is stored in the keychain.
- `logOut` removes the access token from the keychain (if there was one), thereby requiring another call to `logInOrRecoverToken`.
- Finally, `request` functions exactly like [`Alamofire.request`](https://github.com/Alamofire/Alamofire#response-handling), except that it includes the `accessToken` with each request. After calling `logInOrRecoverToken`, you should use `request` to make calls to the Soundcloud API.

Now, check out the [Soundcloud API Docs](https://developers.soundcloud.com/docs/api/reference) for what's possible. Here are some ideas:

### Simple search and playback

Search tracks on Soundcloud with a GET to [`/tracks?q=<query>`](https://developers.soundcloud.com/docs/api/reference#tracks). Use SwiftyJSON to parse the response into models, and display those in a table view. When the user taps a cell in the table view, play back the track.

Here's one way you might stream a track from the API:

- Pluck the `stream_url` out of the JSON response.
- Append `?oauth_token=<your access token>` to the URL. Remember, you can read the access token for a logged in user from `SoundcloudAPI.accessToken`.
- Use the resulting URL to create an `AVPlayer` from the AVFoundation framework. If you don't want to build a UI for the `AVPlayer`, you can use `AVPlayerViewController` from the AVKit framework, like this:

    ```swift
    let trackURL = <track stream URL as described above>
    
    let playerVC = AVPlayerViewController()
    playerVC.player = AVPlayer(URL: trackURL)

    // Then either present it modally:
    self.presentViewController(playerVC, animated: true, completion: nil)
    
    // or push it in a nav controller:
    self.navigationController?.pushViewController(playerVC, animated: true)
    ```

### Artist search

Allow users to search for users, as well as tracks. Build a VC that displays information about a user, including all of that users' tracks.

### Favoriting

Allow users to favorite and unfavorite users and tracks. Check out the docs; this is done with a `PUT` to `/me/favorites/<track or user id>`.
