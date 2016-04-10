import ceylon.interop.java { javaClass }
import java.nio { ByteBuffer }
import java.nio.file { Files, Path, Paths }
import java.nio.file.attribute { UserDefinedFileAttributeView }

"Run the module `io.github.weakish.shattr`."
throws (`class AssertionError`, "No command line argument.")
shared void run() {
    String? first_arg = process.arguments.first;
    if (exists first_arg) {
        Path filePath = Paths.get(first_arg);
        UserDefinedFileAttributeView view =
            Files.getFileAttributeView(
                filePath,
                javaClass<UserDefinedFileAttributeView>());
        String tag = "shatag.sha256";
        ByteBuffer readBuffer = ByteBuffer.allocate(view.size(tag));
        view.read(tag, readBuffer);
        readBuffer.flip();
    } else {
        throw AssertionError("Need to specify file path.");
    }
}
