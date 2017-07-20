package node;
import cpp.vm.Thread;
import haxe.io.BytesData;
import haxe.crypto.Base64;
import haxe.crypto.Md5;
import haxe.io.BytesInput;
import node.HandshakeConstants;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.BytesOutput;
import sys.net.Host;
import sys.net.Socket;
class ErlangNodeConnection {

    private var nodeSocket: Socket;
    private var fullNodeName: String;
    private var port: Int;

    public function new(fullNodeName: String, name: String, port: Int) {
        this.fullNodeName = fullNodeName;
        this.port = port;
        nodeSocket = new Socket();
        nodeSocket.setBlocking(true);
        nodeSocket.connect(new Host("127.0.0.1"), port);
    }

    public function sendName():Void {
        var sockets = Socket.select([nodeSocket], [nodeSocket], [nodeSocket], 60000);
        var writeSocket: Socket = sockets.write.pop();

        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;

        trace("sending name");
        output.writeString("n");
        output.writeUInt16(HandshakeConstants.VERSION);
        output.writeInt32(flags());
        output.writeString(fullNodeName);

        var bytes: Bytes = output.getBytes();

        var bo: BytesOutput = new BytesOutput();
        bo.bigEndian = true;
        bo.writeUInt16(bytes.length);
        bo.write(bytes);

        writeSocket.output.write(bo.getBytes());

        nodeSocket.waitForRead();
        trace("ready to read");

        var status: HandshakeStatus = parseStatus();
        trace(status);
        switch(status) {
            case HandshakeStatus.OK: continueWithHandshake();
            case HandshakeStatus.OK_SIMULTANEOUS: continueWithHandshake();
            case HandshakeStatus.NOK: return;
            case HandshakeStatus.NOT_ALLOWED: return;
            case HandshakeStatus.ALIVE: return;
        }
    }

    private function continueWithHandshake():Void {
        nodeSocket.input.bigEndian = true;
        var messageLength: Int = nodeSocket.input.readUInt16();
        nodeSocket.input.readString(1);
        nodeSocket.input.readUInt16();
        nodeSocket.input.readInt32();
        var challenge:UInt = nodeSocket.input.readInt32();

        var nodeConnecting: String = nodeSocket.input.readString(messageLength - 1 - 2 - 4 - 4);
        trace(nodeConnecting);

        var hash: Bytes = hash("food", challenge);

        var bo: BytesOutput = new BytesOutput();
        bo.bigEndian = true;
        bo.writeUInt16(16 + 4 + 1);
        bo.writeString("r");
        challenge = Std.random(100000);
        bo.writeInt32(challenge);
        bo.write(hash);

        hash = bo.getBytes();
        nodeSocket.output.write(hash);

        nodeSocket.waitForRead();
        var input: Input = nodeSocket.input;
        try {

        } catch(e: Dynamic) {
            trace(e);
        }
    }

    private inline function parseStatus(): HandshakeStatus {
        var input: Input = nodeSocket.input;
        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        output.writeUInt16(input.readUInt16());
        var bytes = output.getBytes();
        var statusLen = bytes.getUInt16(0);
        var status: String = null;
        try {
            status = input.readString(statusLen).substr(1);
            trace(status);

        } catch(e: Dynamic) {
            trace(e);
        }

        return switch(status) {
            case 'ok': HandshakeStatus.OK;
            case 'ok_simultaneous': HandshakeStatus.OK_SIMULTANEOUS;
            case 'nok': HandshakeStatus.NOK;
            case 'not_allowed': HandshakeStatus.NOT_ALLOWED;
            case 'alive': HandshakeStatus.ALIVE;
            default: HandshakeStatus.NOT_ALLOWED;
        }
    }

    private static inline function flags(): Int {
        var flags: Int = HandshakeConstants.FLAG_PUBLISHED;
        flags |= HandshakeConstants.FLAG_EXTENDED_REFERENCES;
        flags |= HandshakeConstants.FLAG_DIST_MONITOR;
        flags |= HandshakeConstants.FLAG_FUN_TAGS;
        flags |= HandshakeConstants.FLAG_DIST_MONITOR_NAME;
        flags |= HandshakeConstants.FLAG_HIDDEN_ATOM_CACHE;
        flags |= HandshakeConstants.FLAG_NEW_FUN_TAGS;
        flags |= HandshakeConstants.FLAG_EXTENDED_PIDS_PORTS;
        flags |= HandshakeConstants.FLAG_EXPORT_PTR_TAG;
        flags |= HandshakeConstants.FLAG_BIT_BINARIES;
        flags |= HandshakeConstants.FLAG_NEW_FLOATS;
        flags |= HandshakeConstants.FLAG_UNICODE_IO;
        flags |= HandshakeConstants.FLAG_DIST_HDR_ATOM_CACHE;
        flags |= HandshakeConstants.FLAG_SMALL_ATOM_TAGS;
        flags |= HandshakeConstants.FLAG_UTF8_ATOMS;
        flags |= HandshakeConstants.FLAG_MAP_TAG;
        return flags;
    }

    public static function receiveConnect(socket: Socket): Void {
        socket.setBlocking(true);
        trace("got other socket");
        try {
            var sockets = Socket.select([socket], [], [], 60000);
            var readSocket: Socket = sockets.read.pop();
            readSocket.waitForRead();
            var input: Input = readSocket.input;
            input.bigEndian = true;
            var length: Int = input.readUInt16();
            trace(length);
            var action: String = input.readString(1);
            trace(input.readUInt16());
            trace(input.readInt32());
            trace(action);
            trace(input.readString(13));
            switch(action) {
                case 'n': respondConnect(socket);
                default: null;
            }
        } catch(e: Dynamic) {
            trace(e);
        }
    }

    private static inline function hash(cookie: String, challenge: Int): Bytes {
        var bytesOutput = new BytesOutput();
        bytesOutput.bigEndian = true;
        bytesOutput.writeString("food" + challenge);
        return Md5.make(bytesOutput.getBytes());
    }

    private static function respondConnect(socket: Socket): Void {
        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        output.writeUInt16(3);
        output.writeString("sok");

        var challenge: UInt = Std.random(10000);

        output.writeUInt16(1 + 2 + 4 + 4 + "bar@127.0.0.1".length);
        output.writeString("n");
        output.writeUInt16(HandshakeConstants.VERSION);
        output.writeInt32(flags());
        output.writeInt32(challenge);
        output.writeString("bar@127.0.0.1");
        socket.output.write(output.getBytes());

        socket.waitForRead();

        trace("ready to read more");
        var input: Input = socket.input;
        input.bigEndian = true;

        var challenge: UInt = 0;
        var challengeHash: Bytes = null;
        try {
            trace(input.readUInt16());
            trace(input.readString(1));
            challenge = input.readInt32();
            challengeHash = input.read(16);
        } catch(e: Dynamic) {
            trace(e);
        }
        trace(challenge);

        //todo: verify challenge hash
        var output: BytesOutput = new BytesOutput();
        output.bigEndian = true;
        output.writeUInt16(17);
        output.writeString("a");
        output.write(hash("food", challenge));

        socket.output.write(output.getBytes());
    }
}
