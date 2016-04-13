shattr
========

A [shatag][] clone in Ceylon.

[shatag]: https://bitbucket.org/maugier/shatag

Status
-------

WIP.

Why
----

`shatag -rl` is slow since it needs to query SQL database for every file.
Instead `shattr` reads all SHA-256 checksums in memory.

Installation
--------------

With `ceylon` and `shatag` installed:

1. Clone this repository to a directory, e.g. `opt`.
2. Edit `shattr_repo` to the cloned repository in `shattr`, e.g. `/opt/shattr`.
3. Put `shattr` into PATH.


Usage
------

    shattr PATH_TO_HASHLIST

will print status of files under the current directory.

```
N empty file
D duplicated file
U unique file
? unknown file (without `sha256` xattr, no read permission, etc)
```

If `PATH_TO_HASHLIST` is not specified,
`shattr` will use `~/.shatagdb-hash-list.txt`.

`PATH_TO_HASHLIST` is a text file,
containing all SHA256 hashes of known files, one per line, **sorted**.

`PATH_TO_HASHLIST` had to be produced manually yet.
For example, if using `shatag` with an sqlite3 backend,
`PATH_TO_HASHLIST` can be produced via:

```sh
sqlite3 -noheader -csv ~/.shatagdb "select hash from contents;" > hashlist.csv
```

Note if `shattr` encounter a file without `user.shatag.sha256` file,
it will call `shatag` to write the xattr, nonblockingly.
Thus if `shatag` succeed, `shattr` will check the file on the next run.

License
--------

0BSD.

Todo
----------

To manage file operation history, we can use `git` as a backend,
instead of SQL databases used by `shatag`.

### Choice 1

Use filename as key:

```ceylon
String repo = "~/.local/var/shattr/repo";
String host = "hostname";
String fileName = "``repo``/hostname/path/to/original/file";
```

Content is compatible with git-lfs:

```
version https://git-lfs.github.com/spec/v1
oid sha256:f4ddae8469a15fb96fea5bfb3340526fe415a6cfc5bc6deebf5ae418b407364d
size 21
```

Pros:

Just use ordinal file operations like `mv` and `rm`, etc.

Cons:

1. We need to build separated index of sha256, pointing to `Array<Path>`.

2. A huge number of files will exhaust inodes of file system and slow down git.

    > Scaling to hundreds of thousands of files is not a problem,
    > scaling beyond that and git will start to get slow.

    -- [git-annex wiki](https://git-annex.branchable.com/scalability/)

    I have 1904875 files(and growing).

### Choice 2

Use `sha256` as key:

```Ceylon
String repo = "~/.local/var/shattr/repo";
String fileName = "``repo``/sha256"
```

Content

```
version https://git-lfs.github.com/spec/v1
oid sha256:f4ddae8469a15fb96fea5bfb3340526fe415a6cfc5bc6deebf5ae418b407364d
size 21
paths hostname:/path/to/file;another:/path/to/file
```

We still have `oid` field to conform git-lfs specification.

Cons:

1. Ordinal file operations like `mv` and `rm` does not work
    (unless we implement a FUSE file system).

2. Still a huge number of files.
    I have 1338211 (and growing).

### Option 3

Option 1 + separated repositories for videos, audios, books etc.

Pros:

1. Same as Option 1.

Cons:

1. Same as Option 1, except file numbers.
2. Inter-repository operation is difficult to handle.

### Option 4

Option 2 + separated repositories.

Cons:

Refer to Option 2 and Option 3.

### Option 5

Use one big text file (e.g. csv) to record all meta data, sorted by `sha256`.

Cons:

Same as Option 2 except file number issue becomes file size issue.

### Option 6

Option 5 + separated text files.

Cons:

Refer to Option 2 and Option 3.

### Option 7

Without git, use Java  object persistence, like [Prevayler][].

[Prevayler]:http://prevayler.org/
