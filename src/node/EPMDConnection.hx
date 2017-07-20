package node;
interface EPMDConnection {
    function getNodes(): Map<String, Int>;
    function portPleaseRequest(nodeName: String): Int;

    function connectToNode(fullNodeName: String, name: String, port: Int): Void;
}
