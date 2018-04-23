# 实现原理

本文不是W3x2Lni的使用帮助，只是简单介绍W3x2Lni核心的实现原理。

> Full

除了`Obj`、`Lni`、`Slk`，实际上W3x2Lni还存在第四种地图格式，我们称之为`Full`。将地图转为某一个格式，都是先转为`Full`再转到目标格式。例如将地图转为`Slk`，实际上的流程是 `Map` -> `Full` -> `Slk`。从`Map` -> `Full`的转换过程，我们称之为`Core Frontend`；而从`Full` -> `Obj`/`Lni`/`Slk`我们称之为`Core Backend`。

`Full`实际上即是保留所有信息的一种数据格式，而`Obj`、`Lni`、`Slk`都会因为某种原因忽略掉部分信息。

## Core Frontend

> Map

`Map`指的是一张未知格式的地图。实际上W3x2Lni不会对输入的地图格式做任何的假设，输入的地图可以同时拥有lni、slk、txt、w3u等文件。它们会被W3x2Lni读取并转换为`Full`。

> 地图的储存形式

W3x2Lni支持读取三种的地图的储存形式，分别是`w3x`、`dir`、`lni`。`w3x`即是WE和War3通常使用的mpq格式。`dir`即是将`w3x`完全解压为文件夹的格式。`lni`则是W3x2Lni定义的一种储存形式。(注意，和地图格式`Lni`不是一回事)

W3x2Lni支持任意一种储存形式的地图作为输入，但对于输出，W3x2Lni会使用特定的储存形式。分别对应的是

* Obj 使用 w3x
* Slk 使用 w3x
* Lni 使用 lni

> Metadata

在理解数据如何变为`Full`前，你需要先知道什么是`Metadata`。在War3的mpq里存在几个`xxxmetadata.slk`的文件，WE通过这些文件定义的规则生成`Obj`格式的数据。但这不是`xxxmetadata.slk`文件的全部，`xxxmetadata.slk`还定义了`Slk`格式数据的规则，但只是定义，War3并不会读取这些文件中的规则来访问`Slk`数据。War3访问`Slk`和`Obj`数据的规则是硬编码在War3内部的。

简单来说，`Metadata`定义了`Slk`和`Obj`数据的构成规则。WE的`Metadata`是mpq里的`xxxmetadata.slk`文件。而War3使用的`Metadata`硬编码在War3内部。WE和War3的`Metadata`并非完全一致，这也是诸多WE的bug的来源。

在W3x2Lni中，`Full`格式会使用War3的`Metadata`。因为我们认为地图的最终目标是在War3上正常运行，所以War3认同的数据才是正确和有意义的数据。如果输入地图的某些数据不符合War3的`Metadata`，将会导致数据被转义、忽略等情况(请留意日志中的警告和错误)。

> Map -> Full

从`Map` -> `Full`可以分为5步。

1. 分别读取slk，obj，lni数据
2. 补全obj数据
3. 补全lni数据
4. 合并obj和slk数据
5. 合并lni和slk数据

抛去存储格式，obj和lni的数据形式几乎一样，而slk则是和full几乎一样。所以这个流程可以粗浅地理解为将obj和lni分别都转为full，然后再将三份full的数据合并在一起。

> Obj/Lni -> Full

Obj数据可以简单地理解为一个补丁。Obj的每一个对象都有一个`parent`，这个`parent`一定是某一个`Slk`里的对象，而Obj里这个对象的其它值都是针对`parent`的差异。所以`Obj`/`Lni` -> `Full`的过程则是，从`Slk`复制一份`parent`并应用所有的补丁。

> Obj/Lni和Slk合并

在经过2~3步的处理后，Obj/Lni/Slk的数据格式已经几乎一致了，我们只需要根据优先级将三份数据合并在一起即可。优先级由高到低的次序为

1. Lni
2. Obj
3. Slk

## Core Backend

> Metadata

在`Map` -> `Full`的过程中已经介绍了，什么是`Metadata`，以及`Map` -> `Full`会使用War3的`Metadata`。而在`Core Backend`，当`Full`转为其它格式时也需要使用`Metadata`。不过不同的目标格式会使用不同的`Metadata`。

* Obj 使用WE的`Metadata`
* Slk 使用War3的`Metadata`
* Lni 使用War3的`Metadata`

W3x2Lni会尽可能地使用War3的`Metadata`，因为它是正确的规则。但正确的规则不一定能被WE接受，这就是为什么W3x2Lni会在`Obj`格式中使用WE的`Metadata`。

这样做会导致你的一些正确的数据会被忽略或转义，但不这样做会导致你的WE无法访问到这张地图的这些数据。

如何避免这种情况？两种办法

* 让你的WE使用正确的`Metadata`
* 不要使用`Obj`格式，换句话说，不要使用WE编辑数据。

> Full -> Slk/Obj/Lni

这个实际上只是`Core Frontend`所做事情的逆序，当你理解如何将如何将Slk/Obj/Lni转为Full后，这个也不难明白其实现原理。
