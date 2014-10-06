TubePlates
=======
http://tubeplates.github.io

Description
-----------
TubePlates is an app to listen to releases listed on Discogs easily using YouTube

This is how it works:
1. You use the app to find releases you like (by artist,label or name).
2. Each time a playback is requested for a track, the app searches YouTube for it, tries to choose the best result and play it in your browser. If the track isn't found it is skipped and and playback for the next track in the playlist/release is requested.

Points to consider
-----------
* The YouTube results are estimated and therefore not perfect; don't expect them to be correct at all times.
* It doesn't work on default browsers on mobile OSes(iOS,Android) due to restrictions in their video players but it does seem to work on the [Puffin browser](http://www.puffinbrowser.com/download/) which has a free version.

Building
-----------
First you need the following dependencies:
* Grunt
* Bower
* CoffeeScript
* Compass

Then you need to run the following commands inside the project:
```shell
bower install
npm install
grunt build
```
built files then appear under the dist directory
