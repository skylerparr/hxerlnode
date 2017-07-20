package ;
import node.ErlangNodeConnection;
import node.EPMDConnection;
import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Thread;
import node.Node;
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
      ErlangNodeConnection.receiveConnect(otherSocket);
    });

    Thread.create(function(): Void {
      var epmdConnection: EPMDConnection = Node.start("bar", "127.0.0.1", 1337);
      var nodes: Map<String, Int> = epmdConnection.getNodes();
      trace(nodes);
      var port = epmdConnection.portPleaseRequest("foo");
      trace(port);
      epmdConnection.connectToNode("bar@127.0.0.1", "foo", port);
    });

    Thread.readMessage(true);
  }
}
