import ceylon.process { Process, createProcess }
import ceylon.interop.java { javaClass }
import java.lang { JString=String, System }
import java.io { IOException }
import java.nio { ByteBuffer }
import java.nio.charset { Charset }
import java.nio.file { FileStore, Files, NoSuchFileException, Path, Paths }
import java.nio.file.attribute { UserDefinedFileAttributeView }
import java.util { Collections, JList=List }

"Run the module `io.github.weakish.shattr`."
throws (`class AssertionError`, "No command line argument.")
shared void run() {
    if (exists first_arg = process.arguments.first) {
        Path filePath = Paths.get(first_arg);
        try {
            if (isXattrEnabled(filePath)) {
                if (exists sha256 = readSha(filePath)) {
                    if (exists duplicated = isDuplicated(sha256)) {
                        print(duplicated);
                    } else {
                        print("File `_hashList` not found.");
                        System.exit(66); // EX_NOINPUT
                    }
                } else {
                    writeSha(filePath);
                }
            } else {
                print("Error: xattr is not enabled.
                       Try remount the file system, e.g.

                           sudo mount -o remount,user_xattr MOUNT_POINT");
            }
        } catch(NoSuchFileException e) {
            print("Error: Cannot found file \"``e.file``\".");
            System.exit(66); // EX_NOINPUT
        }
    } else {
        throw AssertionError("Need to specify file path.");
    }
}

Boolean isXattrEnabled(Path filePath) {
    FileStore store = Files.getFileStore(filePath);
    return store.supportsFileAttributeView("user");
}

"Given a valid file path, read its `user.shatag.sha256` xattr."
String? readSha(Path filePath) {
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
        arguments = ["-qrt"];
    };
}

Boolean? isDuplicated(String sha256) {
    try {
        value hashList = readHashList();
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

"Read file `_hashList` into RAM, which contains all SHA-256 hashes, sorted."
throws (`class IOException`, "File not found.")
JList<JString> readHashList() {
    Path hashList = Paths.get("/pool/repos/incubator/shattr/_hashList");
    value hashes = Files.readAllLines(hashList, Charset.defaultCharset());
    return hashes;
}
