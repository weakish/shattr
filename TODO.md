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

1. We need to build separated index of sha256.

2. A huge number of files will exhaust inodes of file system and slow down git.

    > Scaling to hundreds of thousands of files is not a problem,
    > scaling beyond that and git will start to get slow.

    -- [git-annex wiki](https://git-annex.branchable.com/scalability/)

    I have 1904875 files (and growing).

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

`mv` etc won't work.

### Option 6

Option 5 + separated text files.

Cons:

Refer to Option 2 and Option 3.

### Option 7

Without git, use Java  object persistence, like [Prevayler][].

[Prevayler]:http://prevayler.org/
