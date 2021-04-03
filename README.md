# Solus Grocery Store

Some unofficial 3rd party packages for Solus OS. The idea of setting up such a repository is inspired by [prateekmedia's work](https://github.com/prateekmedia/Solus-3rdParty). A big shout-out to you if you're seeing this :)

I typically update these packages once a month, and will work on some aesthetic improvements later.

## Disclaimer

These packages are **not official**, they are neither supported nor endorsed by the official Solus devs. Do not ask for help in Solus's (or any other) help forum, instead create an issue [here](https://github.com/GZGavinZhao/solus-grocery-store/issues). 

I do **NOT** have the source code for any of the software. The installation files are created by simply decompressing official the .deb installation file and copying/assigning its contents to the right location(s) your Solus system.

## Installation Instructions

### Microsoft Edge (dev)

```
$ sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/GZGavinZhao/solus-grocery-store/main/msedge-dev/microsoft-edge-dev/pspec.xml && sudo eopkg it microsoft-edge-dev*.eopkg && sudo rm microsoft-edge-dev*.eopkg
```
**NOTE:** In order to use the latest sign-in and sync support for version 91.0.831.1 and above, after installation you might need to manually type `edge://flags` in the address bar, then search for and enable the "MSA sign in" experiment.

### 搜狗拼音(sogoupinyin)

```
$ sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/GZGavinZhao/solus-grocery-store/main/sogoupinyin/sogoupinyin/pspec.xml && sudo eopkg it microsoft-edge-dev*.eopkg && sudo rm microsoft-edge-dev*.eopkg
```
**NOTE:** `Fcitx` might somehow replace the default input methods/engines on your computer, like `ibus`. They will still be there, but the only thing you can type will be plain English. If you don't really care about other input methods (or perhaps you know the solution to this problem), then ignore this message.

## Known Issues

### 搜狗拼音(sogoupinyin)

`Fcitx`和`ibus`似乎仍然存在互相干扰的问题……例如，尽管能正常打字/切换中英文，terminal中输入`fcitx`时会显示如下错误：
```
(WARN-7334 dbusstuff.c:248) DBus Service Already Exists
(ERROR-7334 instance.c:443) Exiting.
```
同样，在开启`fcitx`后，存在

还请有能力的大神指点一二！

总结一句话：能用，但强迫症患者表示很淦。

The interference between `Fcitx` and `ibus` has been a headache for me. It does work normally, but still gives weird warning messages when running `fcitx` in the terminal:
```
(WARN-7334 dbusstuff.c:248) DBus Service Already Exists
(ERROR-7334 instance.c:443) Exiting.
```
If it doesn't even work,