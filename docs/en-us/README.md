# W3x2Lni

> What is this?

W3x2Lni is a wc3 map management tool. It helps you to manage your maps when developing or publishing.

> What can it do?

We defined 3 formats for a wc3 map, and w3x2Lni allows you to convert your maps amongst these 3 formats which are `Lni`, `Obj` and `Slk`.

> Lni

`Lni` is a VCS (like git, svn) friendly format. It looks like a directory. Most binary files in w3x will be converted into plain text files (yes! human-readable) by w3x2Lni which will also organize and categorize these text files.

> Obj

`Obj` is a wc3-readable and WE-readable format. If you want to open your map with WE, convert your map into this format.

> Slk

`Slk` is only readable by wc3 and should be used for final distribution. W3x2Lni enables multiple optimization for this format, including:

* Objects converted to slk
* Removed unreferenced objects
* Removed WE-only files
* Inlined WTS strings
* Compressed mdx
* Removed comments and unncessary white spaces in the script
* Obfuscated variable and function name

> Conversion amongst the 3 formats

Converting from `Obj` to `Lni` and the other way is lossless, you can use it with confidence.

Converting from `Obj` and `Lni` to `Slk` is lossy by default. This action will make your map unreadable by WE, but it guarantees that your map is readable by wc3. You can also turn off most options to make this process kind of lossless. But it's impossible to make it fully lossless technically due to the slk format of wc3.

Converting from `Slk` to `Obj` or `Lni` is also lossless. But you had already lost some data when converted to `Slk`, so do not use `Slk` to manage your map.

> What else should I know?

Due to the complexity of `Slk` and `Obj`, it is your responsibility to read the output result of each conversion. Errors and warnings means that there's something wrong in your map which needs you to fix it manually.
