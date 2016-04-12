import ceylon.interop.java { javaClass }
import java.lang { JString=String }
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
        value sha256 = JString(readBuffer.array());
        print(sha256);
    } else {
        throw AssertionError("Need to specify file path.");
    }
}
