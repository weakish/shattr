import ceylon.file { Directory, File, Path, Visitor, current, home }
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
    if (exists xattrEnabled = isXattrEnabled()) {
        if (xattrEnabled) {
            current.visit(visitor);
        } else {
            print("Error: xattr is not enabled.
                   Try remount the file system, e.g.

                       sudo mount -o remount,user_xattr MOUNT_POINT");
        }
    } else {
        print("Error: it seems that current working directory is invalid.
               Please try again later.
               If it still does not work, please report a bug.");
        System.exit(75); // EX_TEMPFAIL
    }
}

Boolean? isXattrEnabled() {
    if (is Directory workingDirectory = current.resource) {
        return checkDirectoryXattr(workingDirectory);
    } else {
        // Something terrible happens on the system.
        return null;
    }
}

Boolean? checkDirectoryXattr(Directory directory) {
    // This directory has files as direct children:
    if (exists toCheckFile = directory.files().first) {
        return checkFileXattr(toCheckFile.path);
    } else {
        // The current directory's direct children are all directories.
        for (subdirectory in directory.childDirectories()) {
            checkDirectoryXattr(subdirectory);
        }
        // FIXME What if we encountered an empty directory,
        // or a directory full of symbolic links?
        return null;
    }
}

Boolean checkFileXattr(Path path) {
    value filePath = Paths.get(path.string);
    FileStore store = Files.getFileStore(filePath);
    return store.supportsFileAttributeView("user");
}


object visitor extends Visitor() {
    file(File f) => reportDuplicated(f.path);
}

"Report duplicated files. Silent on non duplicated."
void reportDuplicated(Path path) {
    if (exists sha256 = readSha(path)) {
        if (exists duplicated = isDuplicated(sha256)) {
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
