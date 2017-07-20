package node;
import haxe.io.BytesOutput;
class NodeUtils {
    public function new() {
    }

    public static inline function get_output(len: Int): BytesOutput {
        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        output.writeUInt16(len);
        return output;
    }
}
