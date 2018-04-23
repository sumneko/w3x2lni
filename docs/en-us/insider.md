# Insider

This article it not a manual, it explains how W3x2Lni works instead.

> Full

Besides of `Obj`, `Lni` and `Slk`, W3x2Lni uses a fourth format. We call it `Full`. Every time when W3x2Lni converts a map, it converts the map to `Full` first and then converts it to the target format.

For instance converting a map to `Slk`, the actual process is `Map` -> `Full` -> `Slk`. We call the process of converting from `Map` to `Full`: `Core Frontend`. The process of converting from `Full` to `Obj`/`Lni`/`Slk` is called `Core Backend`.

`Full` is a data format that holds all information necessary, while `Obj`, `Lni`, `Slk` will discard some data accordingly.

## Core Frontend

> Map

`Map` is a map of unknown format. In fact, W3x2Lni does not limit the format of the input map. The input map can hold any data like lni, slk, txt and w3u. All of them will be read by W3x2Lni and converted to `Full`.

> Data storage of a map

W3x2Lni supports 3 types of data storage which are `w3x`, `dir` and `lni`. `w3x` is the most farmiliar MPQ format used by WE and wc3. `dir` is a fully unzipped form of `w3x`. `lni` is a data storage defined by W3x2Lni (note the difference between data storage `lni` and the `Lni` format).

W3x2Lni supports any data storage as input, but will output as certain storage types. They are:

* Obj uses w3x
* Slk uses w3x
* Lni uses lni

> Metadata

Before understanding how data becomes `Full`, you need to know what is `Metadata`. Inside the MPQ of w3x, there are several `xxxmetadata.slk` files. WE generates data in `Obj` format through the rules defined by these `slk` files. But this is not all of the `xxxmetadata.slk` files, `xxxmetadata.slk` also defines the rules of `Slk` format. But it is just a defination, wc3 does not read `Slk` data based on the rules defined by the `xxxmetadata.slk` files. The rules how wc3 reads `Slk` and `Obj` is coded inside wc3.

In short, `Metadata` defines the rules of `Slk` and `Obj` data. The `Metadata` used by WE is the `xxxmetadata.slk` files in the MPQs. The `Metadata` used by wc3 is coded inside wc3. So the `Metadata` of WE and wc3 are not the same one, which could be the cause of various bugs of WE.

So in W3x2Lni, `Full` will use wc3's `Metadata`, because we believe that the ultimate goal of a map is to be runnable in wc3. Only wc3-recognizable data is truly correct and meaningful data. If the data in a map mismatches with wc3's `Metadata`, it will be escaped or ignored (see the warnings and errors in the log).

> Map -> Full

There are 5 steps from `Map` to `Full`:

1. Read slk, obj and lni data respectively
2. Complete obj data
3. Complete lni data
4. Merge obj and slk
5. Merge lni and slk

Regardless of storage format, the obj data and the lni data are almost the same, while slk and full are almost the same. So the process is something like converting obj and lni to full respectively and merging the 3 full data into one.

> Obj/Lni -> Full

Obj data can be treated as a patch. Each object of Obj has a `parent`. This `parent` must be an object in one of the `Slk`s. Each field of the Obj is a different value from one in the `parent`. So the `Obj`/`Lni` -> `Full` process is just copying a `parent` from the `Slk` and applying all the patches.

> Merge Obj/Lni with Slk

After step 2 and 3, the data format of Obj/Lni/Slk are almost the same. We only need to merge all of them together based on their priorities:

1. Lni
2. Obj
3. Slk

## Core Backend

> Metadata

We have discussed what `Metadata` is and `Map` -> `Full` will use wc3's `Metadata`. But in `Core Backend`, `Metadata` is also needed when `Full` is converted into other format. But different `Metadata` will be used based on different target format.

* Obj uses `Metadata` of WE
* Slk uses `Metadata` of wc3
* Lni uses `Metadata` of wc3

W3x2Lni will use wc3's `Metadata` as much as possible, for that is the correct rule. Correct rule is however not necessarily acceptable by WE, this is why W3x2Lni uses WE's `Metadata` in `Obj` format.

This will result in that some of your correct data is ignored or escaped, but not doing this will make these data to be invisible to WE.

How to avoid this? 2 ways:

* Let your WE uses the correct `Metadata`
* Do not use `Obj` format, in other words, do not use WE to edit your data

> Full -> Slk/Obj/Lni

This is basically a reversed process of `Core Frontend`. If you understand how Slk/Obj/Lni is converted to Full, this should be straight forward.
