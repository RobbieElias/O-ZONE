# O-ZONE - Android and iOS
Arcade game written in Lua using the Solar2D SDK where you have to protect the Earth using a circle O-ZONE.
[Watch gameplay](https://www.youtube.com/watch?v=-4wgz_5KDyQ).

![alt text](https://lh3.googleusercontent.com/JshCB7l-kzxf1sslCcIVyJetM0Pw8gGfZsf_2kndTOOjR26Shi19FNJSQsSysHRXwA8=s80-rw "Logo")

## Download Game
- [Google Play Store](https://play.google.com/store/apps/details?id=com.robbieelias.ozone)
- [iOS App Store](https://apps.apple.com/app/id1477671851)

## Features
- Supports Android and iOS
- 50 unique levels
- Written in Lua
- Uses [Solar2D](https://solar2d.com/) Game Engine (formerly Corona SDK)
- **Google Play Games** and **Game Center** integration
- High score leaderboard
- [Appodeal](https://appodeal.com/) ads integration (interstitial and rewarded ads)
- Consent form implementation for the EU GDPR
- In-App purchase support for removing ads (both Android and iOS)
- Firebase Analytics integration

## Configuration

### Google Play Games ([Documentation](https://docs.coronalabs.com/plugin/gpgs/index.html))
1. Make sure to setup the app in the **Google Play Console**, and make sure it is configured with **Games Service**
2. In `build.settings`, set the Google Play Games AppId (e.g. `googlePlayGamesAppId = "123456789012"`)
3. Create a high score leaderboard in the **Google Play Console** and copy the leaderboard id
4. In `gameServices.lua`, set the leaderboard id on `line 17` (e.g. `leaderboardId = "CgkIntj4kbBKRXOLWS"`)

### iOS Game Center ([Documentation](https://docs.coronalabs.com/plugin/gameNetwork-apple/index.html))
1. Setup Game Center in the App Store Connect console
2. Create a high score leaderboard and copy the id
3. In `gameServices.lua`, set the leaderboard id on `line 21` (e.g. `leaderboardId = "high_score"`)

### Appodeal Ads ([Documentation](https://docs.coronalabs.com/plugin/appodeal/))
1. Configure the app on Appodeal for both Android and iOS (also need to setup AdMob for Appodeal)
2. Copy the App keys for both Android and iOS
3. Set the App Keys in `ads.lua` on `line 23` and `line 25` (e.g. `appKey = "29dj28dj2f63mzb27f92nbcx17f29f20f2f9810m10s02kc9"`)
4. Appodeal shoud setup the apps in AdMob for you. Go in Admob, and copy the application identifiers for both Android and iOS.
5. In `build.settings`, in the Android section, set AdMob the app id (e.g. `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-7323402035723483~2957302052"/>`)
6. In `build.settings`, in the iOS section, set the AdMob app id (e.g. `GADApplicationIdentifier = "ca-app-pub-7323402035723483~2957302053",`)

### Android In-App Purchases ([Documentation](https://docs.coronalabs.com/plugin/google-iap-v3/index.html))
1. Create a remove ads IAP item in the Google Play Console
2. Copy the Base64-encoded license key of your application from the Google Play Console (Services & APIs -> Licensing & in-app billing)
3. In `config.lua`, change the license key to the one you copied (e.g. `key = "KLLIWdKEBisdwbvuC7d2KFMDHUTYATZ7BNTTAHeUINZFSuhNYwWajcnqKEn7qwVp2wJUfeCjkW34JKE33LkEUmz2..."`)
4. In `main.lua`, set the proudct name for the item you created (e.g. `productNames = { apple="com.yourdomain.ozone.remove_ads", google="remove_ads" },`)

### iOS In-App Purchases ([Documentation](https://docs.coronalabs.com/plugin/apple-iap/))
1. Create a remove ads IAP item in the App Store Connect console
2. In `main.lua`, set the proudct name for the item you created (e.g. `productNames = { apple="com.yourdomain.ozone.remove_ads", google="remove_ads" },`)

### Firebase Analytics ([Documentation](https://scotth.tech/plugin-firebaseAnalytics))
1. Setup the firebase project and add platforms for Android and iOS
2. Follow the instructions in the documentation link above s
3. Set the firebase app id in `build.settings` (e.g. `["google_app_id"]= "1:738296057214:android:2034n3saq2low4f6"`)
4. Add the `google-services.json` and `GoogleService-Info.plist` files to the root directory