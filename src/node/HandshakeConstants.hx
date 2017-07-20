package node;
class HandshakeConstants {
    public static inline var VERSION = 5;
    public static inline var FLAG_PUBLISHED = 1;
    public static inline var FLAG_ATOM_CACHE = 2;
    public static inline var FLAG_EXTENDED_REFERENCES = 4;
    public static inline var FLAG_DIST_MONITOR = 8;
    public static inline var FLAG_FUN_TAGS = 0x10;
    public static inline var FLAG_DIST_MONITOR_NAME = 0x20;
    public static inline var FLAG_HIDDEN_ATOM_CACHE = 0x40;
    public static inline var FLAG_NEW_FUN_TAGS = 0x80;
    public static inline var FLAG_EXTENDED_PIDS_PORTS = 0x100;
    public static inline var FLAG_EXPORT_PTR_TAG = 0x200;
    public static inline var FLAG_BIT_BINARIES = 0x400;
    public static inline var FLAG_NEW_FLOATS = 0x800;
    public static inline var FLAG_UNICODE_IO = 0x1000;
    public static inline var FLAG_DIST_HDR_ATOM_CACHE = 0x2000;
    public static inline var FLAG_SMALL_ATOM_TAGS = 0x4000;
    public static inline var FLAG_UTF8_ATOMS = 0x10000;
    public static inline var FLAG_MAP_TAG = 0x20000;
    
    public function new() {
    }
}
