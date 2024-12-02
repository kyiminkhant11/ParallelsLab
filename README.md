<div align="center">
   <img src="https://github.com/trueToastedCode/ParallelsLab/assets/44642574/e05554fe-b335-42dc-87d6-7a3780916706" width=128 height=128>
   <h1>Parallels Desktop Crack</h1>
   <div>19.1.1-54734</div>
</div><br><br>

## Disclaimer
The use of software cracks for illegal purposes is strictly prohibited and we encourage the legal purchase and use of the software. By using this software or reading this disclaimer, you acknowledge that you understand the importance of legal software usage and that you will not use software cracks or engage in illegal activities related to software.

## Usage
1. [Install Parallels Desktop (19.1.1-54734)](https://download.parallels.com/desktop/v19/19.1.1-54734/ParallelsDesktop-19.1.1-54734.dmg)<br>
2. Sign out your account
3. Install [Xcode from the App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)<br>
   Open it afterwards and install the default components (iOS and MacOS, which cannot be unchecked)
4. Enable `System Preferences ▸ Privacy & Security ▸ Full Disk Access ▸ Terminal`
5. Clone the respository<br>
   `git clone -b main --depth 1 https://github.com/trueToastedCode/ParallelsLab.git && cd ParallelsLab && git submodule update --init --recursive`
6. Install<br>
   `chmod +x install.sh && chmod +x reset.command && sudo ./install.sh <mode>`<br>
   Note: `<mode>` is a placeholder that needs to be replaced with the actual mode,<br>
   for example `sudo ./install.sh downgrade_vm`<br>
7. Do not open issues, if you haven't read the README

### Mode
- I highly recommend `downgrade_vm`, unless you experience Bugs. But for me, it had already worked perfectly fine.<br>
- Mac VM is not implemented yet, use [this older commit instead](https://github.com/trueToastedCode/ParallelsLab/tree/5525d1faf934a27d0adf8a7e96a4ef2e9a240001).

|Mode|Network|USB|System Integrity Protection (SIP)|Latest Bug Fixes|All Platforms|No additional launcher|Mac VM|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|no_usb|⚠️|❌|✅|✅|✅|✅|❌|
|downgrade_vm|✅|✅|✅|❌|❌|✅|❌|
|no_sip|✅|✅|❌|✅|✅|✅|❌|

#### No USB
The No USB mode relies on closed source for the Dispatcher but uses open source code for the VM, which fixes a Network error, I am not able to reproduce. It uses `com.apple.security.*` entitlements instead of `com.apple.vm.*`. I cannot tell you, if all Network functionality really works, but if you just wan't to open youre Browser, you are good to go with this one. Maybe you are able to reverse engineer this hack 😉

#### Downgrade VM
It downgrades only the VM so the previous hack works again. However on some platforms, this way of downgrading doesn't work, due to signature errors. Use [this older commit instead](https://github.com/trueToastedCode/ParallelsLab/tree/5525d1faf934a27d0adf8a7e96a4ef2e9a240001) and downgrade Parallels Desktop entirely.

#### No System Integrity Protection (SIP)
This method injects code into the framework and therefore no binaries with special entitlements have to be resigned. This only works if you disable SIP and also Library Validation using  `sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true`. This creates security risks, but malware developers rather target whitespread enviroments.

## Donation
<img src="https://github.com/trueToastedCode/ParallelsLab/assets/44642574/8a7a724b-4fed-4f68-8660-e475587d34fd" width=96><br><br>
Do you want to express gratitude for our reverse engineering efforts?

### [[ PayPal ] trueToastedCode](paypal.me/Lennard478)
Involved in versions 18.3 - 19.1.1

### [[ PayPal ] alsyundawy](https://paypal.me/alsyundawy)
Involved in versions 18.0 - 18.1

### [[ GitHub ] QiuChenly](https://github.com/QiuChenly)
Inspired trueToastedCode on dylib-injections in 19.1

## Sidenotes
### [ downgrade_vm ] ⚠ Don't fully quit and reopen Parallels very quickly ⚠
*It's automatically resetting the crack using hooked functions but this may break it*

### [ downgrade_vm ] 🔧 In case your crack stops working 🔧
Reset it using \"reset.command\"

### Issues
[Report issues here](https://github.com/trueToastedCode/ParallelsLab/issues)

### `tool 'xcodebuild' requires Xcode, but active...
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Hosts
You also want to block Parallels Servers.
```
127.0.0.1 download.parallels.com
127.0.0.1 update.parallels.com
127.0.0.1 desktop.parallels.com
127.0.0.1 download.parallels.com.cdn.cloudflare.net
127.0.0.1 update.parallels.com.cdn.cloudflare.net
127.0.0.1 desktop.parallels.com.cdn.cloudflare.net
127.0.0.1 www.parallels.cn
127.0.0.1 www.parallels.com
127.0.0.1 www.parallels.de
127.0.0.1 www.parallels.es
127.0.0.1 www.parallels.fr
127.0.0.1 www.parallels.nl
127.0.0.1 www.parallels.pt
127.0.0.1 www.parallels.ru
127.0.0.1 www.parallelskorea.com
127.0.0.1 reportus.parallels.com
127.0.0.1 parallels.cn
127.0.0.1 parallels.com
127.0.0.1 parallels.de
127.0.0.1 parallels.es
127.0.0.1 parallels.fr
127.0.0.1 parallels.nl
127.0.0.1 parallels.pt
127.0.0.1 parallels.ru
127.0.0.1 parallelskorea.com
127.0.0.1 pax-manager.myparallels.com
127.0.0.1 myparallels.com
127.0.0.1 my.parallels.com
```
Parallels Desktop will uncomment these, therefore one needs to lock the hosts file:<br>
`sudo chflags uchg /etc/hosts && sudo chflags schg /etc/hosts`<br>
Unlock:<br>
`sudo chflags nouchg /etc/hosts && sudo chflags noschg /etc/hosts`
### OS download
You will not be able to download operating systems in the Control Center anymore. Comment these out to get this functionality:
```
# 127.0.0.1 download.parallels.com
# 127.0.0.1 desktop.parallels.com
# 127.0.0.1 download.parallels.com.cdn.cloudflare.net
# 127.0.0.1 desktop.parallels.com.cdn.cloudflare.net
```
<br><br>
<a href="https://www.flaticon.com/free-icons/heart" title="heart icons">Heart icons created by Freepik - Flaticon</a>
