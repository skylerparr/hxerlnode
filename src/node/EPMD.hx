package node;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import sys.net.Host;
import sys.net.Socket;
class EPMD {
  private static inline var EPMD_PORT: Int = 4369;

  private var socket: Socket;

  public function new() {
  }

  public function connect(nodeName: String, port: Int): Void {
    socket = new Socket();
    socket.setBlocking(true);
    socket.connect(new Host("127.0.0.1"), EPMD_PORT);
    var sockets = Socket.select([socket], [socket], [socket], 60000);
    trace(sockets);
    var writeSocket: Socket = sockets.write.pop();
    trace(writeSocket.peer());
    trace("writing data to socket");
    alive(nodeName, port, writeSocket);
    parseResponse();

    var nameSocket = new Socket();
    nameSocket.setBlocking(true);
    nameSocket.connect(new Host("127.0.0.1"), EPMD_PORT);
    sockets = Socket.select([], [nameSocket], [nameSocket], 60000);
    writeSocket = sockets.write.pop();
    getNames(writeSocket);

    sockets = Socket.select([nameSocket], [], [nameSocket], 60000);
    var map = readNames(sockets.read.pop());
    nameSocket.close();

    var portSocket: Socket = new Socket();
    portSocket.setBlocking(true);
    portSocket.connect(new Host("127.0.0.1"), EPMD_PORT);

    sockets = Socket.select([portSocket], [portSocket], [portSocket], 60000);
    writeSocket = sockets.write.pop();
    portPleaseRequest(writeSocket, "foo");
    sockets = Socket.select([portSocket], [], [portSocket], 60000);
    trace(sockets);
    portResponse(sockets.read.pop());

    trace(map);
    var fooPort = map.get("foo");
    connectToHost(fooPort);
  }

  private function portPleaseRequest(writeSocket: Socket, nodeName: String):Void {
    var output: BytesOutput = new BytesOutput();
    output.bigEndian = true;
    output.writeUInt16(2 + nodeName.length - 1);
    output.writeInt8(122);

    var b: Bytes = Bytes.ofString(nodeName);
    output.write(b);

    writeSocket.output.write(output.getBytes());
  }

  private function portResponse(readSocket:Socket):Void {
    readSocket.setBlocking(true);
    readSocket.waitForRead();
    var input: Input = readSocket.input;
    input.bigEndian = true;

    var output: BytesOutput = new BytesOutput();
    output.bigEndian = true;
    try {
      while(true) {
        output.writeInt8(input.readInt8());
      }
    } catch(e: Dynamic) {
      trace(e);
    }
    var b: Bytes = output.getBytes();
    input = new BytesInput(b);
    input.bigEndian = true;
    trace(input.readInt8());
    trace(input.readInt8());
    trace(input.readUInt16());
    trace(input.readInt8());
    trace(input.readInt8());
    trace(input.readUInt16());
    trace(input.readUInt16());
    var len: Int = input.readUInt16();
    trace(input.readString(len));
    trace(input.readUInt16());
  }

  private function connectToHost(port:Int):Void {

  }

  private function parseResponse():Void {
    socket.waitForRead();
    var input: Input = socket.input;
    input.bigEndian = true;

    try {
      trace(input.readInt8());
      trace(input.readInt8());
      trace(input.readUInt16());
    } catch(e: Dynamic) {
      trace(e);
    }
  }

  private function readNames(readSocket: Socket):Map<String, Int> {
    var input: Input = readSocket.input;
    input.bigEndian = true;

    var output: BytesOutput = new BytesOutput();
    output.bigEndian = true;
    try {
      trace(input.readInt32());
      while(true) {
        output.writeInt8(input.readByte());
      }
    } catch(e: Dynamic) {
      trace(e);
    }
    var bytes: Bytes = output.getBytes();
    var string = bytes.readString(0, bytes.length - 1);

    var hosts: Array<String> = string.split("\n");
    var map: Map<String, Int> = new Map<String, Int>();
    for(host in hosts) {
      var frags: Array<String> = host.split(" ");
      map.set(frags[1], Std.parseInt(frags[4]));
    }

    return map;
  }

  private function getNames(socket:Socket):Void {
    var output: BytesOutput = new BytesOutput();
    output.bigEndian = true;
    output.writeUInt16(1);
    output.writeInt8(110);

    socket.output.write(output.getBytes());
  }

  private function alive(nodeName: String, port: Int, writeSocket: Socket):Void {
    var output: BytesOutput = new BytesOutput();
    output.bigEndian = true;
    output.writeUInt16(13 + nodeName.length);
    output.writeInt8(120);
    output.writeUInt16(port);
    output.writeInt8(77);
    output.writeInt8(0);
    output.writeUInt16(5);
    output.writeUInt16(5);
    var b: Bytes = Bytes.ofString(nodeName);
    output.writeUInt16(b.length);
    output.write(b);
    output.writeUInt16(0);

    writeSocket.output.write(output.getBytes());
  }

}
