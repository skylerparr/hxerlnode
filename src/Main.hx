package ;
import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Thread;
import node.EPMD;
@IgnoreCover
class Main {
  public static function main() {
    new Main();
  }

  private function new():Void {
    Thread.create(function(): Void {
      var socket: Socket = new Socket();
      socket.bind(new Host("127.0.0.1"), 1337);
      socket.listen(9999);
      trace("socket ready to accept connections");
      var otherSocket: Socket = socket.accept();
      otherSocket.setBlocking(true);
      trace("got other socket");
      try {
        trace(otherSocket);
        otherSocket.waitForRead();
        trace(otherSocket.input.readByte());
        while(true) {
          otherSocket.output.writeByte(119);
          Sys.sleep(1);
        }
      } catch(e: Dynamic) {
        trace(e);
      }
    });

    Sys.sleep(1);
    Thread.create(function(): Void {
      var epmd: EPMD = new EPMD();
      epmd.connect("bar", 1337);
    });

    Thread.readMessage(true);
  }
}
