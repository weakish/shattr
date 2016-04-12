import ceylon.interop.java { javaClass }
import java.nio { ByteBuffer }
import java.nio.charset { Charset }
import java.nio.file { Files, Path, Paths }
import java.nio.file.attribute { UserDefinedFileAttributeView }

"Run the module `io.github.weakish.shattr`."
throws (`class AssertionError`, "No command line argument.")
shared void run() {
    if (exists first_arg = process.arguments.first) {
        Path filePath = Paths.get(first_arg);
        print(readSha(filePath));
    } else {
        throw AssertionError("Need to specify file path.");
    }
}

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


