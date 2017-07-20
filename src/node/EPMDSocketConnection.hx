package node;
import node.ErlangNodeConnection;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import sys.net.Host;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.BytesOutput;
import sys.net.Socket;
class EPMDSocketConnection implements EPMDConnection {

    private var socket: Socket;
    private var epmdHost: String;

    public function new(socket: Socket, epmdHost: String) {
        this.socket = socket;
        this.epmdHost = epmdHost;
    }

    public function stop(): Void {
        socket.close();
    }

    public function getNodes(): Map<String, Int> {
        var nameSocket = new Socket();
        nameSocket.setBlocking(true);
        nameSocket.connect(new Host(epmdHost), Constants.EPMD_PORT);
        var sockets = Socket.select([], [nameSocket], [nameSocket], 60000);
        var writeSocket: Socket = sockets.write.pop();
        getNames(writeSocket);

        sockets = Socket.select([nameSocket], [], [nameSocket], 60000);
        var map = readNames(sockets.read.pop());
        nameSocket.close();

        return map;
    }

    private function getNames(socket:Socket):Void {
        var output: BytesOutput = NodeUtils.get_output(1);
        output.writeInt8(Constants.ALL_REGISTERED_NAMES_REQ);

        socket.output.write(output.getBytes());
    }

    private function readNames(readSocket: Socket):Map<String, Int> {
        var input: Input = readSocket.input;
        input.bigEndian = true;

        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        try {
            while(true) {
                output.writeInt8(input.readByte());
            }
        } catch(e: Dynamic) {
        }
        var bytes: Bytes = output.getBytes();
        var string = bytes.getString(0, bytes.length - 1);

        var hosts: Array<String> = string.split("\n");
        var map: Map<String, Int> = new Map<String, Int>();
        for(host in hosts) {
            var frags: Array<String> = host.split(" ");
            map.set(frags[1], Std.parseInt(frags[4]));
        }

        return map;
    }

    public function portPleaseRequest(nodeName: String): Int {
        var portSocket: Socket = new Socket();
        portSocket.setBlocking(true);
        portSocket.connect(new Host(epmdHost), Constants.EPMD_PORT);

        var sockets = Socket.select([portSocket], [portSocket], [portSocket], 60000);
        var writeSocket: Socket = sockets.write.pop();
        requestPorts(writeSocket, nodeName);
        return portResponse(portSocket);
    }

    private function requestPorts(writeSocket: Socket, nodeName: String):Void {
        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        output.writeUInt16(2 + nodeName.length - 1);
        output.writeInt8(122);

        var b: Bytes = Bytes.ofString(nodeName);
        output.write(b);

        writeSocket.output.write(output.getBytes());
    }

    private function portResponse(readSocket:Socket):Int {
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
//            trace(e);
        }
        var b: Bytes = output.getBytes();
        input = new BytesInput(b);
        input.bigEndian = true;
        input.readInt8();
        input.readInt8();
        var port = input.readUInt16();
//        trace(input.readInt8());
//        trace(input.readInt8());
//        trace(input.readUInt16());
//        trace(input.readUInt16());
//        var len: Int = input.readUInt16();
//        trace(input.readString(len));
//        trace(input.readUInt16());

        return port;
    }

    public function connectToNode(fullNodeName: String, name:String, port:Int):Void {
        var connection: ErlangNodeConnection = new ErlangNodeConnection(fullNodeName, name, port);
        connection.sendName();
    }

}
