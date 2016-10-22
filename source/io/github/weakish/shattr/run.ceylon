import ceylon.buffer.base {
    base16String
}
import ceylon.collection {
    TreeSet
}
import ceylon.file {
    current,
    Path,
    Visitor,
    File,
    home,
    parsePath,
    Nil
}
import ceylon.interop.java {
    javaClass
}
import ceylon.logging {
    Category,
    Logger,
    addLogWriter,
    logger,
    Priority,
    info
}
import de.dlkw.ccrypto.svc {
    sha256
}
import java.io {
    IOException
}
import java.nio {
    ByteBuffer
}
import java.nio.charset {
    Charset
}
import java.nio.file {
    InvalidPathException,
    Paths,
    FileStore,
    Files
}
import java.nio.file.attribute {
    UserDefinedFileAttributeView
}

String? sha256FileHex(Path filePath) {
    value digester = sha256();
    Byte[] sha256sum;
    if (is File file = filePath.resource) {
        try (reader = file.Reader()) {
            // Sector size of file system on my machine: 512 bytes
            // L1 cache size of my CPU: 64 K
            Integer bufferSize = 64 * 1024;
            Integer remainingSize = file.size % bufferSize;
            variable Integer parts = file.size / bufferSize;
            variable Byte[] bytes;
            while (parts > 0) {
                bytes = reader.readBytes(bufferSize);
                digester.update(bytes);
                parts--;
            }
            Byte[] remainder = reader.readBytes(remainingSize);
            sha256sum = digester.digest(remainder);
        }
        return base16String.encode(sha256sum);
    } else {
        return null;
    }
}

"Duplication status."
class Status of blank | duplicated | unique | unknown {
    shared String description;
    shared Character character;
    shared new blank {
        description = "EMPTY";
        character = 'N';
    }
    shared new duplicated {
        description = "DUPLICATED";
        character = 'D';
    }
    shared new unique {
        description = "UNIQUE";
        character = 'U';
    }
    shared new unknown {
        description = "UNKNOWN";
        character = '?';
    }
}
"A function to format output string."
alias Formatter => String(Status, Path);
"A git status style formatter."
String git(Status status, Path path) => "``status.character`` ``path``";
"A inotifywait style formatter."
String inotifywait(Status status, Path path) => "``status.description`` ``path``";

"A cvs formatter."
String cvs(Status status, Path path) {
    String quotedPath = path.string.replace("\"", "\"\"");
    return "``status.description``,\"``quotedPath``\"";
}
variable Formatter formatter = git;
variable String hashListPath = "``home``/.shatagdb-hash-list.txt";

Logger log = logger(`module io.github.weakish.shattr`);
"A simple log writer: `EVENT message`."
shared void writeMuchSimplerLog(Priority priority, Category category, String
    message, Throwable? throwable) {
    Anything(String) printer;
    if (priority <= info) {
        printer = process.writeLine;
    } else {
        printer = process.writeErrorLine;
    }
    printer("``priority.string`` ``message``");
    if (exists throwable) {
        printStackTrace(throwable, print);
    }
}
"A printer function to output result."
void printer(Status status, Path path,
    Formatter formatter = git,
    Anything(String) writer = process.writeLine) {
    writer(formatter(status, path));
}
Boolean isXattrEnabled() {
    value filePath = Paths.get(current.string);
    FileStore store = Files.getFileStore(filePath);
    if (store.supportsFileAttributeView("user")) {
        return true;
    } else {
        // `supportsFileAttributeView` cannot guarantee to give the correct result
        // when the file store is not a local storage device.
        Path mtabPath = parsePath("/etc/mtab");
        if (is File file = mtabPath.resource) {
            try (reader = file.Reader()) {
                while (exists line = reader.readLine()) {
                    if (line.contains(store.name())) {
                        if (line.contains("nouser_xattr")) {
                            return false;
                        } else {
                            // enabled by default on ext3/ext4 for not very old Linux kernels
                            if (line.contains("ext3") || line.contains("ext4")) {
                                return true;
                            } else {
                                if (line.contains("user_xattr")) {
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    }
                }
                return false;
            }
        } else {
            // No `mtab`, probably not on Linux. Unsure. Assume `yes`.
            return true;
        }
    }
}
object visitor extends Visitor() {
    TreeSet<String> hashList = readHashList();
    file(File f) => reportDuplicated(f.path, hashList);
}
"Read file <hashList> into RAM,
 which contains all SHA-256 hashes, sorted."
TreeSet<String> readHashList() {
    value hashes = TreeSet<String>((x, y) => x <=> y);
    switch (file = parsePath(hashListPath).resource)
    case (is File) {
        try (reader = file.Reader()) {
            while (exists line = reader.readLine()) {
                Boolean recordAlreadExists = hashes.add(line);
                if (!recordAlreadExists) {
                    log.warn("Warn: duplicated sha256sum record in hash list!");
                    log.warn(line);
                } else {
                    log.debug("Debug: add sha256sum record:");
                    log.debug(line);
                }
            }
        }
    }
    case (is Nil) {
        throw InvalidPathException(hashListPath, "File does not exist.");
    }
    else {
        throw IOException("Cannot read ``hashListPath``.");
    }
    return hashes;
}
"Report duplicated files.
 Silent on non duplicated files
 and files without `user.shatag.sha256`."
void reportDuplicated(Path path, TreeSet<String> hashList) {
    String sha256Empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    Status status;
    switch (sha256 = readSha(path))
    case (is String) {
        if (sha256 == sha256Empty) {
            status = Status.blank;
        } else if (isDuplicated(sha256, hashList)) {
            status = Status.duplicated;
        } else { status = Status.unique; } }
    else {
        status = Status.unknown;
    }
    printer(status, path, formatter);
}
"Given a valid file path, read its `user.shatag.sha256` xattr."
String? readSha(Path path) {
    UserDefinedFileAttributeView view = getXattrView(path);
    String tag = "shatag.sha256";
    if (exists size = getXattrSize(view, tag)) {
        return getXattr(tag, size, view);
    } else {
        return null;
    }
}
UserDefinedFileAttributeView getXattrView(Path path) {
    value filePath = Paths.get(path.string);
    UserDefinedFileAttributeView view = Files.getFileAttributeView(
        filePath,
        javaClass<UserDefinedFileAttributeView>());
    return view;
}
Integer? getXattrSize(UserDefinedFileAttributeView view, String tag) {
    try {
        return view.size(tag);
    } catch (IOException e) {
        return null;
    }
}
String getXattr(String tag, Integer size, UserDefinedFileAttributeView view) {
    ByteBuffer buffer = ByteBuffer.allocate(size);
    view.read(tag, buffer);
    buffer.flip();
    String sha256 = Charset.defaultCharset().decode(buffer).string;
    return sha256;
}
Boolean isDuplicated(String sha256, TreeSet<String> hashList) {
    return if (hashList.contains(sha256)) then true else false;
}

shared void run() {
    addLogWriter(writeMuchSimplerLog);
    String commandLineUsage
            = "java -jar /path/to/shattr.jar [--format FORMAT] [hash_list_file]";
    String formatDescription
            = "FORMAT is one of `git`, `inotifywait`, and `cvs`.";
    switch (option = process.arguments.first)
    case ("-h" | "--help") {
        print("Usage:
                   ``commandLineUsage``
                   ``formatDescription``");
    }
    case ("--format") {
        switch (format = process.arguments[1])
        case ("git") {
            formatter = git;
        }
        case ("inotifywait") {
            formatter = inotifywait;
        }
        case ("cvs") {
            formatter = cvs;
        }
        else {
            log.fatal(formatDescription);
            System.exit(64);
        }
        hashListPath = process.arguments.last else hashListPath;
    }
    else {
        hashListPath = process.arguments.first else hashListPath;
    }
    if (isXattrEnabled()) {
        try { current.visit(visitor);
        } catch (InvalidPathException e) {
            log.fatal(e.message);
            process.exit(64); // EX_USAGE
        } catch (IOException e) {
            log.fatal(e.message);
            process.exit(66); // EX_NOINPUT
        }
    } else {
        log.fatal("Error: xattr is not enabled.
                   Try remount the file system, e.g.

                   sudo mount -o remount,user_xattr MOUNT_POINT");
        process.exit(75);
    }
}
