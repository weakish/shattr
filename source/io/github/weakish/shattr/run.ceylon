import ceylon.interop.java { javaClass }
import java.lang { System }
import java.nio { ByteBuffer }
import java.nio.charset { Charset }
import java.nio.file { Files, NoSuchFileException, Path, Paths }
import java.nio.file.attribute { UserDefinedFileAttributeView }

"Run the module `io.github.weakish.shattr`."
throws (`class AssertionError`, "No command line argument.")
shared void run() {
    if (exists first_arg = process.arguments.first) {
        Path filePath = Paths.get(first_arg);
        try {
            print(readSha(filePath));
        } catch(NoSuchFileException e) {
            print("Error: Cannot found file \"``e.file``\".");
            System.exit(66); // EX_NOINPUT
        }
    } else {
        throw AssertionError("Need to specify file path.");
    }
}

throws (`class NoSuchFileException`)
String? readSha(Path filePath) {
    UserDefinedFileAttributeView view =
        Files.getFileAttributeView(
            filePath,
            javaClass<UserDefinedFileAttributeView>());
    String tag = "shatag.sha256";
    ByteBuffer buffer = ByteBuffer.allocate(view.size(tag));
    view.read(tag, buffer);
    buffer.flip();
    String? sha256 = Charset.defaultCharset().decode(buffer).string;
    return sha256;
}


