import ceylon.file { File, Path, Visitor, current, home }
import ceylon.process { Process, createProcess }
import ceylon.interop.java { javaClass }
import java.lang { JString=String, System }
import java.io { IOException }
import java.nio { ByteBuffer }
import java.nio.charset { Charset }
import java.nio.file { FileStore, Files, Paths }
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
    value hashList = readHashList();
    file(File f) => reportDuplicated(f.path, hashList);
}

"Read file <hashList> into RAM,
 which contains all SHA-256 hashes, sorted."
throws (`class IOException`, "File not found.")
JList<JString> readHashList() {
    String defaultPath = "``home``/.shatagdb-hash-list.txt";
    String hashListPath = process.arguments.first else defaultPath;
    value hashList = Paths.get(hashListPath);
    value hashes = Files.readAllLines(hashList, Charset.defaultCharset());
    return hashes;
}

"Report duplicated files. Silent on non duplicated."
void reportDuplicated(Path path, JList<JString> hashList) {
    if (exists sha256 = readSha(path)) {
        if (exists duplicated = isDuplicated(sha256, hashList)) {
            if (duplicated) {
                print("``path``");
            } else {
                // silent
            }
        } else {
            print("Cannot read hash list file.");
            System.exit(66); // EX_NOINPUT
        }
    } else {
        writeSha(path);
    }
}


"Given a valid file path, read its `user.shatag.sha256` xattr."
String? readSha(Path path) {
    value filePath = Paths.get(path.string);
    UserDefinedFileAttributeView view =
        Files.getFileAttributeView(
            filePath,
            javaClass<UserDefinedFileAttributeView>());
    String tag = "shatag.sha256";
    try {
        Integer viewSize = view.size(tag);
        ByteBuffer buffer = ByteBuffer.allocate(viewSize);
        view.read(tag, buffer);
        buffer.flip();
        String? sha256 = Charset.defaultCharset().decode(buffer).string;
        return sha256;
    } catch (IOException e) {
        return null;
    }
}

"Call `shatag` to write sha256 xattrs. Nonblocking."
void writeSha(Path filePath) {
    suppressWarnings("unusedDeclaration")
    Process shatag = createProcess {
        command = "shatag";
        arguments = ["-t"];
    };
}

Boolean? isDuplicated(String sha256, JList<JString> hashList) {
    try {
        value sha = JString(sha256);
        if (Collections.binarySearch(hashList, sha) >= 0) {
            return true;
        } else {
            return false;
        }
    } catch (IOException e) {
        return null;
    }
}

