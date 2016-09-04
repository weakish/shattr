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


    N empty file
    D duplicated file
    U unique file
    ? unknown file (without `sha256` xattr, no read permission, etc)


`$SHATTR_COMMAND` is one of:

- `ceylon run io.github.weakish.shattr` if using `Ceylon`;
- `java -jar /path/to/io.github.weakish.shattr-0.2.0.jar` if using `java` directly.

If `PATH_TO_HASHLIST` is not specified,
`shattr` will use `~/.shatagdb-hash-list.txt`.

### Hash list format

`PATH_TO_HASHLIST` is a text file,
containing all SHA256 hashes of known files, one per line.

For example, if using `shatag` with an sqlite3 backend,
`PATH_TO_HASHLIST` can be produced via:

```sh
sqlite3 -noheader -csv ~/.shatagdb "select hash from contents;" > hashlist.csv
```

### Customize output

By default we use a git status style output.
You can change output format style with `--format FORMAT`.
`FORMAT` is one of `git`, `inotifywait`, and `cvs`.
`--format FORMAT` should be specified *before* hash list file.

#### `--format inotifywait`

    EMPTY empty file
    DUMPLICATED duplicatd file
    UNIQUE unique file
    UNKNOWN file (without `sha256` xattr, no read permission, etc)

#### `--format cvs`

Like `--format inotifywait`, but separated with comma `,`, with path name quoted.

    EMPTY,"empty_file.txt"
    UNIQUE,"A file containing spaces and ""double quotes"""

#### `--format yourown`

You need to write a formatting function typed `String(Status, Path)`.
Then register it in command line option parsing code in `run()`.

### Contribute

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

#### Only use `i++` to increase `i`.

`y=i++` and `y=++i` is really confusing to me.

So I prefer to only uses `i++` to increase `i`, e.g. in a while loop.
I think a meaningful evaluated value of `i++` should be `void`
if the a programming language allows `++`.

Same applies to `i--` and `--i`.

#### Prefer functions to classes

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

