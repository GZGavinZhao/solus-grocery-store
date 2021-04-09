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

### 网易云音乐(NetEase Cloud Music)

```
$ sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/GZGavinZhao/solus-grocery-store/main/netease-cloud-music/ncm/pspec.xml && sudo eopkg it netease-cloud-music-1.2.1-1-1-x86_64.eopkg && sudo rm netease-cloud-music-1.2.1-1-1-x86_64.eopkg
```
**NOTE:** This should work flawlessly, but it's possible that I am missing some dependencies. If you can't start it, execute `netease-cloud-music` and create an issue [here](https://github.com/GZGavinZhao/solus-grocery-store/issues) with the warning/error messages, if any.

### 搜狗拼音(sogoupinyin)

```
$ sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/GZGavinZhao/solus-grocery-store/main/sogoupinyin/sogoupinyin/pspec.xml && sudo eopkg it sogoupinyin-2.4.0.3469-1-1-x86_64.eopkg && sudo rm sogoupinyin-2.4.0.3469-1-1-x86_64.eopkg
```
**注意事项：** 安装后需要重启。`Fcitx`和`ibus`貌似不能同时使用，在未删掉期间若切换输入法可能会出现系统卡死的现象，唯一的解决办法就是强制重启……所以一定要保存好东西。若无法使用请参考[这篇文章](https://manjaro.org.cn/bbs/topic/manjaro%E4%B8%AD%E6%96%87%E8%BE%93%E5%85%A5%E6%B3%95%EF%BC%88fcitxgooglepinyin%E7%9A%84%E9%85%8D%E7%BD%AE%E9%97%AE%E9%A2%98)

**NOTE:** Reboot after installing. When you use `Fcitx`, it seems that you can't use any input methods from `ibus` (e.g. the once you set up in system settings). You can switch to them, but they can only output plain English. If you can't use it, refer to [this article](https://manjaro.org.cn/bbs/topic/manjaro%E4%B8%AD%E6%96%87%E8%BE%93%E5%85%A5%E6%B3%95%EF%BC%88fcitxgooglepinyin%E7%9A%84%E9%85%8D%E7%BD%AE%E9%97%AE%E9%A2%98).

## Known Issues

### 搜狗拼音(sogoupinyin)

总结：能用，但很不稳定。建议先开`Fcitx`自带的拼音输入法以防万一，同时参考安装指南中的文章。

`Fcitx`和`ibus`似乎仍然存在互相干扰的问题……例如，尽管能正常打字/切换中英文，terminal中输入`fcitx`时会显示如下错误：
```
(WARN-7334 dbusstuff.c:248) DBus Service Already Exists
(ERROR-7334 instance.c:443) Exiting.
```
同时，搜狗拼音经常会“诈尸”。有时候它能用，有时候它自己就消失了。还请有能力的大神指点一二！

The interference between `Fcitx` and `ibus` has been a headache for me. It does work normally, but still gives weird warning messages when running `fcitx` in the terminal:
```
(WARN-7334 dbusstuff.c:248) DBus Service Already Exists
(ERROR-7334 instance.c:443) Exiting.
```
Please open an issue if you know how might it be resolved. Any help is appreciated!