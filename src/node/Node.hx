package node;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import sys.net.Host;
import sys.net.Socket;
class Node {

  public function new() {
  }

  public static function start(nodeName: String, hostIP: String, port: Int): EPMDConnection {
    var socket = new Socket();
    socket.setBlocking(true);
    socket.connect(new Host(hostIP), Constants.EPMD_PORT);
    var sockets = Socket.select([socket], [socket], [socket], 60000);
    var writeSocket: Socket = sockets.write.pop();
    alive(nodeName, port, writeSocket);
    parseResponse(socket);

    return new EPMDSocketConnection(socket, hostIP);
  }

  private static inline function parseResponse(socket: Socket):Void {
    socket.waitForRead();
    var input: Input = socket.input;
    input.bigEndian = true;

    try {
      input.readInt8();
      input.readInt8();
      input.readUInt16();
    } catch(e: Dynamic) {
//      trace(e);
    }
  }

  private static inline function alive(nodeName: String, port: Int, writeSocket: Socket):Void {
    var output: BytesOutput = NodeUtils.get_output(13 + nodeName.length);
    output.writeInt8(Constants.ALIVE2_REQ);
    output.writeUInt16(port);
    output.writeInt8(Constants.PUBLIC_NODE);
    output.writeInt8(Constants.IPV4);
    output.writeUInt16(Constants.HIGHEST_VERSION);
    output.writeUInt16(Constants.LOWEST_VERSION);
    var b: Bytes = Bytes.ofString(nodeName);
    output.writeUInt16(b.length);
    output.write(b);
    output.writeUInt16(0);

    writeSocket.output.write(output.getBytes());
  }

}
