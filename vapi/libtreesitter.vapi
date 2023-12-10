[CCode (cheader_filename = "tree_sitter/api.h")]
namespace TreeSitter {

  [CCode (cname = "TREE_SITTER_LANGUAGE_VERSION")]
  public const int VERSION;

  [CCode (cname = "TSInputEncoding", cprefix = "TSInputEncoding", has_type_id = false)]
  public enum InputEncoding {
    UTF8,
    UTF16
  }

  [CCode (cname = "TSSymbolType", cprefix = "TSSymbolType", has_type_id = false)]
  public enum SymbolType {
    Regular,
    Anonymous,
    Auxiliary
  }

  [CCode (cname = "TSLogType", cprefix = "TSLogType", has_type_id = false)]
  public enum LogType {
    Parse,
    Lex
  }

  [SimpleType]
  [CCode (cname = "TSSymbol", has_type_id = false)]
  public struct Symbol : uint16 {
  }

  [CCode (cname = "TSLanguage")]
  [Compact]
  public class Language {
    uint32 version;
    uint32 symbol_count;
    uint32 alias_count;
    uint32 token_count;
    uint32 external_token_count;
    //const char **symbol_names;
  //const TSSymbolMetadata *symbol_metadata;
  //const uint16 *parse_table;
  //const TSParseActionEntry *parse_actions;
  //const TSLexMode *lex_modes;
  //const TSSymbol *alias_sequences;
  uint16 max_alias_sequence_length;
  //bool (*lex_fn)(TSLexer *, TSStateId);
  //bool (*keyword_lex_fn)(TSLexer *, TSStateId);
  //Symbol keyword_capture_token;
/*
  struct {
    const bool *states;
    const TSSymbol *symbol_map;
    void *(*create)();
    void (*destroy)(void *);
    bool (*scan)(void *, TSLexer *, const bool *symbol_whitelist);
    unsigned (*serialize)(void *, char *);
    void (*deserialize)(void *, const char *, unsigned);
  } external_scanner;
  */
    [CCode (cname = "ts_language_symbol_count")]
    public uint32 get_symbol_count ();

    [CCode (cname = "ts_language_symbol_name")]
    public unowned string get_symbol_name (Symbol symbol);

    [CCode (cname = "ts_language_symbol_for_name")]
    public Symbol symbol_for_name (string name);

    [CCode (cname = "ts_language_symbol_type")]
    public SymbolType get_symbol_type (Symbol symbol);

    [CCode (cname = "ts_language_version")]
    public uint32 get_version ();
  }

  [CCode (cname = "TSParser", free_function = "ts_parser_delete")]
  [Compact]
  public class Parser {
      [CCode (cname = "ts_parser_new")]
      public Parser ();

      [CCode (cname = "ts_parser_language")]
      public unowned Language get_language ();

      [CCode (cname = "ts_parser_set_language")]
      public bool set_language (Language language);

      [CCode (cname = "ts_parser_parse_string")]
      public Tree parse_string (Tree? tree, [CCode (array_length_type = "uint32_t")] uint8[] source);
  }

  [CCode (cname = "TSTree", free_function = "ts_tree_delete")]
  [Compact]
  public class Tree {
      [CCode (cname = "ts_tree_root_node")]
      public Node root_node ();
  }

  [SimpleType]
  [CCode (cname = "TSPoint", has_type_id = false)]
  public struct Point {
    uint32 row;
    uint32 column;
  }

  [CCode (cname = "TSRange", has_type_id = false)]
  public struct Range {
    Point start_point;
    Point end_point;
    uint32 start_byte;
    uint32 end_byte;
  }

  [CCode (cname = "TSInput", has_type_id = false)]
  public struct Input {
    void *payload;
    //const char *(*read)(void *payload, uint32 byte_index, Point position, uint32 *bytes_read);
    InputEncoding encoding;
  }

  [CCode (cname = "TSLogger", has_type_id = false)]
  public struct Logger {
    void *payload;
    //void (*log)(void *payload, TSLogType, const char *);
  }

  [CCode (cname = "TSInputEdit", has_type_id = false)]
  public struct InputEdit {
    uint32 start_byte;
    uint32 old_end_byte;
    uint32 new_end_byte;
    Point start_point;
    Point old_end_point;
    Point new_end_point;
  }

  [SimpleType]
  [CCode (cname = "TSNode", has_type_id = false)]
  public struct Node {

    [CCode (cname = "ts_node_type")]
    public unowned string type ();

    [CCode (cname = "ts_node_string")]
    public string to_str ();

    [CCode (cname = "ts_node_start_point")]
    public Point start_point ();

    [CCode (cname = "ts_node_end_point")]
    public Point end_point ();

    [CCode (cname = "ts_node_start_byte")]
    public uint32 start_byte ();

    [CCode (cname = "ts_node_end_byte")]
    public uint32 end_byte ();

  }

  [CCode (cname = "TSTreeCursor", free_function = "ts_tree_cursor_delete", has_type_id = false)]
  [Compact]
  public class TreeCursor {
    //const void *tree;
    //const void *id;
    uint32 context[2];

    [CCode (cname = "ts_tree_cursor_new")]
    public TreeCursor (Node node);

    [CCode (cname = "ts_tree_cursor_goto_next_sibling")]
    public bool goto_next_sibling ();

    [CCode (cname = "ts_tree_cursor_goto_first_child")]
    public bool goto_first_child ();

    [CCode (cname = "ts_tree_cursor_current_node")]
    public Node current_node ();

    [CCode (cname = "ts_tree_cursor_goto_parent")]
    public Node goto_parent ();
 }
}

/*

TSLogger ts_parser_logger(const TSParser *);
void ts_parser_set_logger(TSParser *, TSLogger);
void ts_parser_print_dot_graphs(TSParser *, FILE *);
void ts_parser_halt_on_error(TSParser *, bool);
TSTree *ts_parser_parse(TSParser *, const TSTree *, TSInput);
bool ts_parser_enabled(const TSParser *);
void ts_parser_set_enabled(TSParser *, bool);
size_t ts_parser_operation_limit(const TSParser *);
void ts_parser_set_operation_limit(TSParser *, size_t);
void ts_parser_reset(TSParser *);
void ts_parser_set_included_ranges(TSParser *, const TSRange *, uint32_t);
const TSRange *ts_parser_included_ranges(const TSParser *, uint32_t *);

TSTree *ts_tree_copy(const TSTree *);
void ts_tree_edit(TSTree *, const TSInputEdit *);
TSRange *ts_tree_get_changed_ranges(const TSTree *, const TSTree *, uint32_t *);
void ts_tree_print_dot_graph(const TSTree *, FILE *);
const TSLanguage *ts_tree_language(const TSTree *);

TSSymbol ts_node_symbol(TSNode);
char *ts_node_string(TSNode);
bool ts_node_eq(TSNode, TSNode);
bool ts_node_is_null(TSNode);
bool ts_node_is_named(TSNode);
bool ts_node_is_missing(TSNode);
bool ts_node_has_changes(TSNode);
bool ts_node_has_error(TSNode);
TSNode ts_node_parent(TSNode);
TSNode ts_node_child(TSNode, uint32_t);
TSNode ts_node_named_child(TSNode, uint32_t);
uint32_t ts_node_child_count(TSNode);
uint32_t ts_node_named_child_count(TSNode);
TSNode ts_node_next_sibling(TSNode);
TSNode ts_node_next_named_sibling(TSNode);
TSNode ts_node_prev_sibling(TSNode);
TSNode ts_node_prev_named_sibling(TSNode);
TSNode ts_node_first_child_for_byte(TSNode, uint32_t);
TSNode ts_node_first_named_child_for_byte(TSNode, uint32_t);
TSNode ts_node_descendant_for_byte_range(TSNode, uint32_t, uint32_t);
TSNode ts_node_named_descendant_for_byte_range(TSNode, uint32_t, uint32_t);
TSNode ts_node_descendant_for_point_range(TSNode, TSPoint, TSPoint);
TSNode ts_node_named_descendant_for_point_range(TSNode, TSPoint, TSPoint);
void ts_node_edit(TSNode *, const TSInputEdit *);

void ts_tree_cursor_delete(TSTreeCursor *);
void ts_tree_cursor_reset(TSTreeCursor *, TSNode);
int64_t ts_tree_cursor_goto_first_child_for_byte(TSTreeCursor *, uint32_t);

*/
