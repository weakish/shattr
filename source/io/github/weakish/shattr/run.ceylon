import ceylon.file { File, Path, Visitor, current, home }
import ceylon.interop.java { javaClass }
import java.lang { JString=String, System }
import java.io { IOException }
import java.nio { ByteBuffer }
import java.nio.charset { Charset }
import java.nio.file {
    FileStore, Files, InvalidPathException, JPath=Path, Paths
}
import java.nio.file.attribute { UserDefinedFileAttributeView }
import java.util { Collections, JList=List }

shared void run() {
    if (isXattrEnabled()) {
            current.visit(visitor);
    } else {
        print("Error: xattr is not enabled.
               Try remount the file system, e.g.

                   sudo mount -o remount,user_xattr MOUNT_POINT");
        System.exit(75); // EX_TEMPFAIL
    }
}

Boolean isXattrEnabled() {
    value filePath = Paths.get(current.string);
    FileStore store = Files.getFileStore(filePath);
    return store.supportsFileAttributeView("user");
}

object visitor extends Visitor() {
    JList<JString>|InvalidPathException|IOException hashList;
    hashList = readHashList();
    file(File f) => reportDuplicated(f.path, hashList);
}

"Read file <hashList> into RAM,
 which contains all SHA-256 hashes, sorted."
JList<JString>|InvalidPathException|IOException readHashList() {
    String defaultPath = "``home``/.shatagdb-hash-list.txt";
    String hashListPath = process.arguments.first else defaultPath;

    JPath hashList;
    try {
        hashList = Paths.get(hashListPath);
    } catch (InvalidPathException e) {
        return e;
    }

    // We have to use `JList<JString>`,
    // because the specific return type of `Files.readAllLines`
    // is platform dependent.
    JList<JString> hashes;
    try {
        hashes = Files.readAllLines(hashList, Charset.defaultCharset());
    } catch (IOException e) {
        return e;
    }

    return hashes;
}

"Report duplicated files.
 Silent on non duplicated files
 and files without `user.shatag.sha256`."
void reportDuplicated(
    Path path,
    JList<JString>|InvalidPathException|IOException hashList) {
    switch (hashList)
    case (is InvalidPathException)  {
            print("Path name of hash list is invalid.");
            System.exit(64); // EX_USAGE
    }
    case (is IOException) {
            print("Cannot read hash list file.");
            System.exit(66); // EX_NOINPUT
    }
    // We use `else` instead of `case (is JList<JString>)`
    // because the Ceylon compiler does not know
    // type of `JList` arguments.
    // JVM erased generic types, thus crippling Ceylon's type system.
    // BTW, `else` is faster because Ceylon compiler
    // does not optimize the unnecessary analysis of the reified type.
    // ([#4410][])
    //
    // [#4410]: https://github.com/ceylon/ceylon/issues/4410
    else {
        if (exists sha256 = readSha(path)) {
            String sha256Empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
            if (sha256 == sha256Empty) {
                print("N ``path``");
            } else if (isDuplicated(sha256, hashList)) {
                print("D ``path``");
            } else {
                print("U ``path``");
            }
        } else {
            print("? ``path``");
        }
    }
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
    UserDefinedFileAttributeView view =
        Files.getFileAttributeView(
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

String? getXattr(String tag, Integer size, UserDefinedFileAttributeView view) {
    ByteBuffer buffer = ByteBuffer.allocate(size);
    view.read(tag, buffer);
    buffer.flip();
    String? sha256 = Charset.defaultCharset().decode(buffer).string;
    return sha256;
}


Boolean isDuplicated(String sha256, JList<JString> hashList) {
    value sha = JString(sha256);
    if (Collections.binarySearch(hashList, sha) >= 0) {
        return true;
    } else {
        return false;
    }
}

