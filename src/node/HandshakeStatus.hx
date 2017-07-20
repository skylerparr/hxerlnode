package node;
import haxe.io.Bytes;
enum HandshakeStatus {
    OK;
    OK_SIMULTANEOUS;
    NOK;
    NOT_ALLOWED;
    ALIVE;
}