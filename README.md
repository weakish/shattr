shattr
========

A [shatag][] clone in Ceylon.

[shatag]: https://bitbucket.org/maugier/shatag

Status
------

A lot of features unimplemented.
Usable for implemented feature.

Why
----

`shatag -rl` is slow since it needs to query SQL database for every file.
`shattr` reads all SHA-256 checksums in memory instead.

Installation
--------------

### With `Ceylon`

If you have `Ceylon` installed, you can download the `.car` archive (`< 4K`) at
[Releases] and put it into [Ceylon module repository][repo].

### With `java` directly

If you have Java Runtime (7+) installed , but not Ceylon, you can download the fat jar file (`3.2M`).

### Compile manually

Clone this repository and run `ceylon compile`.

Tested with `Ceylon 1.2+`.
May work with older versions.

[Releases]: https://github.com/weakish/shattr/releases
[repo]: http://ceylon-lang.org/documentation/1.2/reference/repository/

Usage
------

    $SHATTR_COMMAND PATH_TO_HASHLIST

will print status of files under the current directory.

```
N empty file
D duplicated file
U unique file
? unknown file (without `sha256` xattr, no read permission, etc)
```

`$SHATTR_COMMAND` is one of:

- `ceylon run io.github.weakish.shattr` if using `Ceylon`;
- `java -jar /path/to/io.github.weakish.shattr-0.2.0.jar` if using `java` directly.

If `PATH_TO_HASHLIST` is not specified,
`shattr` will use `~/.shatagdb-hash-list.txt`.

`PATH_TO_HASHLIST` is a text file,
containing all SHA256 hashes of known files, one per line.

For example, if using `shatag` with an sqlite3 backend,
`PATH_TO_HASHLIST` can be produced via:

```sh
sqlite3 -noheader -csv ~/.shatagdb "select hash from contents;" > hashlist.csv
```

Contribute
----------

Send pull requests at <https://github.com/weakish/shattr>.

### Coding style

#### Prefer `if . then . else .` to `. then . else .`

We feel `A then B else C` is confusing.

Readers may think `A then B else C` is `A ? B : C` in other languages, but they are **not the same**:

1. `A then B else C` is actually `(A then B) else C`:

	 * `A then B` evaluates to `B` if `A` is not `null`, otherwise evaluates to `null`.
	 * `X else Y` evaluates to `X` if `X` is not `null`, otherwise evaluates to `Y`.

2. Thus the type of `B` is `T given T satisfies Object`, i.e. requires to not be `null`.

I think `if (A) then B else C` is much cleaner.

#### Avoid `i++`, `++i`

Compared to `i+=1`, `i++` only saves one character.

`y=i++` and `y=++i` is really confusing to me.

Same applies to `i--` and `--i`.

#### Prefer functions to classes

Currently there is no class declaration in code source.

We prefer to declare classes for new types (or type aliases).

#### Other

If you disagree the above, file an issue.

Send pull requests to add new coding style.

Please do not add formatting style such as `use two spaces` and `closing braces on their own line`.
Formatting style is unlikely to affect readability of code,
and can be auto adjusted via `ceylon format`.

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
