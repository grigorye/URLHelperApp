
[![](https://gitlab.com/grigorye/URLHelperApp/badges/master/pipeline.svg)](https://gitlab.com/grigorye/URLHelperApp/commits/master)

# URLHelperApp

A helper app for script-driven routing of http(s) urls to different applications.

## Why

macOS has quite limited configuration of url "openers" - it's mostly limited to one app per url scheme. So (by default) it can not route an http(s) url to different apps, depening on the url itself.

Some time ago I discovered the concept of user-generated Chrome SSBs/[Epichrome](https://github.com/dmarmor/epichrome) and believe that those are really cool things - I use them daily and they work great. But when opening an url from other app, that is not browser (read: Mail/iMessage/Slack/Messenger and etc.) to benefit from SSBs, we need to route the url accordingly.

URLHelperApp is a possible solution.

## How

URLHelperApp is basically a very simple "url proxy" app. You configure it as default browser/http(s) handler, and adjust the routing using a simple script, that you're free to adjust to your needs yourself. After that, when you try to open an url:

1. URLHelperApp gets the url.
2. URLHelperApp invokes the "routing" script with the url as an argument.
3. The script (currently) outputs the bundle id of the desired app/SSB.
4. URLHelper asks the app with the bundle to open the url.

The routings script (`AppBundleIdentifierForURL`) should be installed in `~/Library/Application Scripts/com.grigorye.URLHelperApp/`. A sample version of the script is installed on attempt to open an url (by default it routes everything to Chrome).

## Alternatives

Before creating this tool I was using [Browser Fairy](https://itunes.apple.com/app/browser-fairy/id483014855?mt=12). Unfortunately it doesn't currently (Oct 2018) work on macOS 10.14 Mojave and I have some problems with it on macOS 10.13. From my experience, URLHelperApp already works more reliably and a bit faster than that app (leaving aside the flexibility).

## Installation

Build it yourself or (preferably) install via Homebrew: 

```
brew tap grigorye/tools
brew cask install url-helper-app
```

## Known limitations/bugs/todos

Please see [Trello](https://trello.com/b/6vqyZoDc).
