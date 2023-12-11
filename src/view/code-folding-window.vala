/* 
 * CodeFoldingWindow is a window that shows A CodeFoldingView
 *
 * Author: Alberto Fanjul <albfan@gnome.org>
 */

[CCode (cname = "tree_sitter_rust")]
extern unowned TreeSitter.Language? get_language_rust ();
[CCode (cname = "tree_sitter_c")]
extern unowned TreeSitter.Language? get_language_c ();
[CCode (cname = "tree_sitter_javascript")]
extern unowned TreeSitter.Language? get_language_javascript ();
[CCode (cname = "tree_sitter_python")]
extern unowned TreeSitter.Language? get_language_python ();
[CCode (cname = "tree_sitter_ruby")]
extern unowned TreeSitter.Language? get_language_ruby ();
[CCode (cname = "tree_sitter_cpp")]
extern unowned TreeSitter.Language? get_language_cpp ();
[CCode (cname = "tree_sitter_go")]
extern unowned TreeSitter.Language? get_language_go ();
[CCode (cname = "tree_sitter_bash")]
extern unowned TreeSitter.Language? get_language_bash ();
[CCode (cname = "tree_sitter_json")]
extern unowned TreeSitter.Language? get_language_json ();
[CCode (cname = "tree_sitter_php")]
extern unowned TreeSitter.Language? get_language_php ();
[CCode (cname = "tree_sitter_html")]
extern unowned TreeSitter.Language? get_language_html ();
[CCode (cname = "tree_sitter_xml")]
extern unowned TreeSitter.Language? get_language_xml ();
[CCode (cname = "tree_sitter_typescript")]
extern unowned TreeSitter.Language? get_language_typescript ();

public class CodeFoldingWindow : Gtk.Window {
    private const string TITLE = "Source Code Editor";

    private CodeFoldingSourceView source_view;
    private Gtk.SourceLanguageManager language_manager;
    private Gtk.SourceStyleSchemeManager style_manager;
    private Gtk.MenuBar menu_bar;
    private Gtk.SourceFile file;
    private CodeFoldingSourceGutterRenderer code_folding_gutter_renderer;
    private Gtk.TreeStore tree_store;
    private Gtk.TreeIter tree_root;
    private Gtk.ComboBox strategy_combo;
    private Gtk.TreeView tree_view;

    public string? file_path {get; construct set;}

    bool listen_source_changes = true;

    Gtk.SpinButton height_row_button = new Gtk.SpinButton.with_range (0, int.MAX, 10);
    Gtk.CellRendererText cellRenderer = new Gtk.CellRendererText ();
    Gtk.CheckButton check_ellipsize_data = new Gtk.CheckButton.with_label("Ellipsize data");

    public CodeFoldingWindow (string? file_path) {
       Object(file_path: file_path);
    }

    construct {

        title = CodeFoldingWindow.TITLE;
        set_default_size (800, 600);
        window_position = Gtk.WindowPosition.CENTER;

        file = null;
        menu_bar = new Gtk.MenuBar ();

        Gtk.MenuItem item_file = new Gtk.MenuItem.with_label ("File");
        menu_bar.add (item_file);

        Gtk.Menu file_menu = new Gtk.Menu ();
        item_file.set_submenu (file_menu);

        var item_open = new Gtk.ImageMenuItem.with_label ("Open");
        var open_icon = new Gtk.Image.from_icon_name ("document-open",
                                                      Gtk.IconSize.MENU);
        item_open.always_show_image = true;
        item_open.set_image(open_icon);
        file_menu.add (item_open);

        var item_save = new Gtk.ImageMenuItem.with_label ("Save");
        var save_icon = new Gtk.Image.from_icon_name ("document-save",
                                                      Gtk.IconSize.MENU);
        item_save.always_show_image = true;
        item_save.set_image(save_icon);
        file_menu.add (item_save);

        var item_quit = new Gtk.ImageMenuItem.with_label ("Quit");
        var quit_icon = new Gtk.Image.from_icon_name ("application-exit",
                                                      Gtk.IconSize.MENU);
        item_quit.always_show_image = true;
        item_quit.set_image(quit_icon);
        file_menu.add (item_quit);

        tree_store = new Gtk.TreeStore (5,
                                        typeof (string), typeof (string),
                                        typeof (string), typeof (string),
                                        typeof (ASTItem));

        source_view = new CodeFoldingSourceView ();
        source_view.ast_model = new ASTModel ();

        source_view.set_wrap_mode (Gtk.WrapMode.WORD);
        source_view.show_line_numbers = true;
        source_view.show_line_marks = true;
        source_view.show_right_margin = true;

        source_view.motion_notify_event.connect (on_motion_notify_event);
        source_view.buffer.changed.connect (() => {
            if (listen_source_changes)
                fill_model_by_strategy ();
        });
        key_press_event.connect(on_key_press_event);

        var gutter = source_view.get_gutter (Gtk.TextWindowType.LEFT);
        code_folding_gutter_renderer =
           new CodeFoldingSourceGutterRenderer(source_view.ast_model);
        gutter.insert (code_folding_gutter_renderer, 0);

        Gtk.SourceSpaceDrawer space_drawer = source_view.space_drawer;
        space_drawer.enable_matrix = true;
        space_drawer.set_types_for_locations (Gtk.SourceSpaceLocationFlags.ALL,
                    Gtk.SourceSpaceTypeFlags.SPACE
                    | Gtk.SourceSpaceTypeFlags.TAB);
        Gtk.SourceBuffer buffer = (Gtk.SourceBuffer)source_view.buffer;
        buffer.text = "";
        buffer.highlight_matching_brackets = true;
        buffer.create_tag("invisible", "invisible", true);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC,
                                    Gtk.PolicyType.AUTOMATIC);
        scrolled_window.add (source_view);
        scrolled_window.hexpand = true;
        scrolled_window.vexpand = true;

        var grid = new Gtk.Grid ();
        strategy_combo = build_strategy_combo (gutter);
        var style_combo = build_style_combo (gutter);
        var whitespace_combo = build_whitespace_combo (gutter);
        var check_show_symbols = new Gtk.CheckButton.with_label("Show symbols");
        check_show_symbols.tooltip_text = "Show symbols on Intellij fold nodes";
        check_show_symbols.toggled.connect( () => {
           source_view.ast_model.show_symbols = check_show_symbols.active;
           gutter.queue_draw ();
        });
        check_ellipsize_data.tooltip_text = "Ellipsize data showing only 10 first characters";
        check_ellipsize_data.active = true;
        check_ellipsize_data.toggled.connect( () => {
            fill_model_by_strategy();
        });
        style_combo.changed.connect( () => {
           Value val;
           Gtk.TreeIter iter;
           style_combo.get_active_iter (out iter);
           style_combo.get_model ().get_value(iter, 0, out val);
           if (((string)val) == "Intellij") {
              check_show_symbols.show ();
           } else {
              check_show_symbols.hide ();
           }
        });

        height_row_button.value = 40;
        cellRenderer.height = 40;
        height_row_button.value_changed.connect (() => {
            int val = height_row_button.get_value_as_int ();
            cellRenderer.height = val > 0 ? val : -1 ;
            //TODO: Force redraw of tree_view instead of redraw
            //tree_view.queue_draw();
            fill_model_by_strategy ();
        });
        height_row_button.tooltip_text =
           "Height for rows on tree view";

        Gtk.SpinButton whitespace_count_button = new Gtk.SpinButton.with_range (0, int.MAX, 1);
        whitespace_count_button.value = source_view.ast_model.whitespace_count;
        whitespace_count_button.value_changed.connect (() => {
            int val = whitespace_count_button.get_value_as_int ();
            source_view.ast_model.whitespace_count = val;
            fill_model_by_strategy ();
        });
        whitespace_count_button.tooltip_text =
           "Number of characters to detect whitespace by indentation";

        strategy_combo.changed.connect( () => {
           Value val;
           Gtk.TreeIter iter;
           strategy_combo.get_active_iter (out iter);
           strategy_combo.get_model ().get_value(iter, 0, out val);
           if (((string)val) == "Indentation") {
              whitespace_combo.show ();
              whitespace_count_button.show ();
           } else {
              whitespace_combo.hide ();
              whitespace_count_button.hide ();
           }
        });
        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.wide_handle = true;
        paned.position = 600;

        init_tree_model ();
        tree_view = new Gtk.TreeView.with_model (tree_store);
        tree_view.insert_column_with_attributes (-1, "Type",
                                                 cellRenderer,
                                                 "text", 0, null);
        tree_view.insert_column_with_attributes (-1, "Start",
                                                 cellRenderer,
                                                 "text", 1, null);
        tree_view.insert_column_with_attributes (-1, "End",
                                                 cellRenderer,
                                                 "text", 2, null);
        tree_view.insert_column_with_attributes (-1, "Text",
                                                 cellRenderer,
                                                 "text", 3, null);
        tree_view.tooltip_text = "Show AST tree";

        tree_view.cursor_changed.connect(on_cursor_changed);
        tree_view.row_activated.connect ( (path, column) => {
           Gtk.TreeIter iter;
           tree_store.get_iter (out iter, path);
           bool is_root = tree_store.iter_depth (iter) == 0;
           if (tree_view.is_row_expanded (path)) {
              if (is_root) {
                tree_view.collapse_all ();
              } else {
                tree_view.collapse_row (path);
              }
           } else {
              if (is_root) {
                 tree_view.expand_all();
              } else {
                 tree_view.collapse_all ();
                 tree_view.expand_to_path (path);
              }
           }
        });
        var scrolled_tree_window = new Gtk.ScrolledWindow (null, null);
        scrolled_tree_window.set_policy (Gtk.PolicyType.AUTOMATIC,
                                         Gtk.PolicyType.AUTOMATIC);
        scrolled_tree_window.add (tree_view);
        scrolled_tree_window.hexpand = true;
        scrolled_tree_window.vexpand = true;

        paned.add1 (scrolled_window);
        paned.add2 (scrolled_tree_window);

        grid.attach (menu_bar, 0, 0, 1, 1);
        grid.attach (strategy_combo, 0, 1, 1, 1);
        grid.attach (style_combo, 1, 1, 1, 1);
        grid.attach (check_show_symbols, 2, 1, 1, 1);
        grid.attach (whitespace_combo, 3, 1, 1, 1);
        grid.attach (whitespace_count_button, 4, 1, 1, 1);
        grid.attach (height_row_button, 5, 1, 1, 1);
        grid.attach (check_ellipsize_data, 6, 1, 1, 1);
        grid.attach (paned, 0, 2, 7, 1);
        add (grid as Gtk.Widget);
        show_all ();
        whitespace_combo.hide ();
        whitespace_count_button.hide ();

        destroy.connect (Gtk.main_quit);

        item_open.activate.connect (on_open);
        item_save.activate.connect (on_save);
        item_quit.activate.connect (Gtk.main_quit);

        source_view.populate_popup.connect (on_populate_menu);

        if (file_path != null) {
           var file_choosed = GLib.File.new_for_path(file_path);
           load_file(file_choosed);
        }
    }

    public Gtk.TreePath? get_selected_path () {
        var selection = tree_view.get_selection ();
        selection.set_mode (Gtk.SelectionMode.SINGLE);
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        if (!selection.get_selected(out model, out iter)) {
            return null;
        }
        return model.get_path(iter);
    }

    public void on_cursor_changed () {
        var path = get_selected_path ();
        if (path == null) {
           return;
        }
        Gtk.TreeIter iter;
        tree_store.get_iter (out iter, path);
        Value val;
        tree_store.get_value (iter, 4, out val);
        ASTItem ast_item = (ASTItem)val.get_object ();
        if (ast_item == null) {
           return;
        }
        Gtk.TextIter start_iter, end_iter;
        source_view.buffer.get_iter_at_line_offset(out start_iter,
                                                   ast_item.start,
                                                   ast_item.start_offset);
        source_view.buffer.get_iter_at_line_offset(out end_iter, ast_item.end,
                                                   ast_item.end_offset);
        source_view.buffer.select_range(start_iter, end_iter);
    }

    private void init_tree_model () {
       tree_store.clear ();
       tree_store.append (out tree_root, null);
       tree_store.set (tree_root, 0, "AST Tree", -1);
    }

    private bool on_key_press_event(Gtk.Widget widget, Gdk.EventKey event)
    {
       uint keyval = event.keyval;
       bool is_ctrl = (Gdk.ModifierType.CONTROL_MASK & event.state) != 0;
       if (is_ctrl) {
           bool is_alt = (Gdk.ModifierType.MOD1_MASK & event.state) != 0;
           bool is_plus = keyval == Gdk.Key.plus || keyval == Gdk.Key.KP_Add;
           bool is_minus = keyval == Gdk.Key.minus || keyval == Gdk.Key.KP_Subtract;
           bool is_period = keyval == Gdk.Key.period || keyval == Gdk.Key.KP_Separator;
           if (is_alt) {
              if (is_plus) {
                source_view.apply_fold_all (false);
                return true;
              } else if (is_minus) {
                source_view.apply_fold_all (true);
                return true;
              }
           } else if (is_period) {
              source_view.fold_selection ();
              return true;
           } else if (is_plus) {
              source_view.apply_fold_at_cursor (false);
              return true;
           } else if (is_minus) {
              source_view.apply_fold_at_cursor (true);
              return true;
           }
       }
       return false;
    }

    private Gtk.ComboBox build_strategy_combo (Gtk.SourceGutter gutter)
    {
        Gtk.ListStore list_store = new Gtk.ListStore (1, typeof (string));
        Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, 0, "None");
        list_store.append (out iter);
        //TODO: Guess indentation automatically
        list_store.set (iter, 0, "Indentation");
        list_store.append (out iter);
        list_store.set (iter, 0, "Pairs");
        list_store.append (out iter);
        list_store.set (iter, 0, "AST");
        list_store.append (out iter);
        //TODO: Read buffer and find tags
        //list_store.set (iter, 0, "Tags");
        list_store.append (out iter);
        //TODO: Read diff metadata and fold real file hidden lines
        //list_store.set (iter, 0, "Diff");

        Gtk.ComboBox combo = new Gtk.ComboBox.with_model (list_store);
        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        combo.pack_start (renderer, true);
        combo.add_attribute (renderer, "text", 0);

        combo.changed.connect( () => {
           Value val;
           combo.get_active_iter(out iter);
           list_store.get_value(iter, 0, out val);
           source_view.ast_model.strategy = (string)val;
           fill_model_by_strategy();
        });
        combo.active = 0;
        combo.tooltip_text = "Strategy to detect folds";

        return combo;
    }

    private void fill_model_by_strategy () {
       var ast_model = source_view.ast_model;
       clear_fold_model ();
       init_tree_model ();
       if (ast_model.strategy == "Indentation") {
          fill_model_by_indentation ();
       } else if (ast_model.strategy == "Pairs") {
          fill_model_by_pairs ();
       } else if (ast_model.strategy == "None") {
       } else if (ast_model.strategy == "AST") {
          fill_model_by_ast ();
       }
       source_view.refresh_folds();
       var gutter = source_view.get_gutter (Gtk.TextWindowType.LEFT);
       gutter.queue_draw();
    }

    private Gtk.ComboBox build_whitespace_combo (Gtk.SourceGutter gutter)
    {
        Gtk.ListStore list_store = new Gtk.ListStore (1, typeof (string));
        Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, 0, "Space");
        list_store.append (out iter);
        list_store.set (iter, 0, "Tab");

        Gtk.ComboBox combo = new Gtk.ComboBox.with_model (list_store);
        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        combo.pack_start (renderer, true);
        combo.add_attribute (renderer, "text", 0);

        combo.changed.connect( () => {
           Value val;
           combo.get_active_iter(out iter);
           list_store.get_value(iter, 0, out val);
           if (((string)val) == "Space") {
              source_view.ast_model.whitespace = ' ';
           } else {
              source_view.ast_model.whitespace = '	';
           }
           fill_model_by_strategy ();
        });
        combo.active = 0;
        combo.tooltip_text = "Select whitespace for indentation strategy";

        return combo;
    }

    private Gtk.ComboBox build_style_combo (Gtk.SourceGutter gutter)
    {
        Gtk.ListStore list_store = new Gtk.ListStore (1, typeof (string));
        Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, 0, "Intellij");
        list_store.append (out iter);
        list_store.set (iter, 0, "Atom");

        Gtk.ComboBox combo = new Gtk.ComboBox.with_model (list_store);
        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        combo.pack_start (renderer, true);
        combo.add_attribute (renderer, "text", 0);

        combo.changed.connect( () => {
           Value val;
           combo.get_active_iter(out iter);
           list_store.get_value(iter, 0, out val);
           source_view.ast_model.style = (string)val;
           gutter.queue_draw();
        });
        combo.active = 0;
        combo.tooltip_text = "Style of folding symbols on gutter";

        return combo;
    }

    private bool on_motion_notify_event (Gtk.Widget widget, Gdk.EventMotion evt)
    {
       Array<ASTItem> items = new Array<ASTItem>();
       var gutter = source_view.get_gutter(Gtk.TextWindowType.LEFT);
       if (source_view.get_window(Gtk.TextWindowType.LEFT) == evt.window)
       {
          var renderer = gutter.get_renderer_at_pos((int)evt.x, (int)evt.y);
          if (renderer == code_folding_gutter_renderer)
          {
             int x, y;
             source_view.window_to_buffer_coords(Gtk.TextWindowType.LEFT,
                                                 (int)evt.x, (int)evt.y, out x,
                                                 out y);
             Gtk.TextIter iter;
             int trailing;
             source_view.get_iter_at_position(out iter, out trailing, x, y);
             items = source_view.ast_model.get_folds(iter.get_line());
          }
       }
       if (source_view.ast_model.highlighted != items) {
          source_view.ast_model.highlighted = items;
          gutter.queue_draw();
       }
       return false;
    }

    private void fill_model_by_pairs() {
        Gtk.TextIter iter;
        var starts = new Gee.LinkedList<Gtk.TextIter?>();
        source_view.buffer.get_start_iter(out iter);
        while (!iter.is_end()) {
           var car = iter.get_char();
           if (car == '{') {
              starts.offer_head(iter.copy ());
           } else if (car == '}') {
              if (starts.size > 0) {
                 var start = starts.poll_head();
                 source_view.ast_model.add_item_from_iter (start, iter,
                                                           "fold-pair", false);
              }
           }
           iter.forward_char();
        }
    }

    private void clear_fold_model () {
        source_view.ast_model.clear ();
    }

    unowned TreeSitter.Language last_language = null;

    private void fill_model_by_ast() {
        Gtk.SourceBuffer buffer = (Gtk.SourceBuffer)source_view.buffer;
        var language_name = buffer.language.name.down();

        var parser = new TreeSitter.Parser();

        unowned TreeSitter.Language language;
        if (language_name == "c") {
          language = get_language_c();
        } else if (language_name == "json") {
          language = get_language_json();
        } else if (language_name == "rust") {
          language = get_language_rust ();
        } else if (language_name == "javascript") {
          language = get_language_javascript ();
        } else if (language_name == "python") {
          language = get_language_python ();
        } else if (language_name == "ruby") {
          language = get_language_ruby ();
        } else if (language_name == "cpp") {
          language = get_language_cpp ();
        } else if (language_name == "go") {
          language = get_language_go ();
        } else if (language_name == "bash") {
          language = get_language_bash ();
        } else if (language_name == "php") {
          language = get_language_php ();
        } else if (language_name == "html") {
          language = get_language_html ();
        } else if (language_name == "xml") {
          language = get_language_xml ();
        } else if (language_name == "typescript") {
          language = get_language_typescript ();
        } else {
           if (language_name != null) {
               print("Unknow %s language\n", language_name);
               return;
           } else {
               if (last_language != null)
                   language = last_language;
               else {
                   print("Set language manually to fill AST\n");
                   return;
               }
           }
        }
        last_language = language;

        parser.set_language(language);
        var tree = parser.parse_string(null, buffer.text.data);
        var root_node = tree.root_node();

        TreeSitter.TreeCursor tree_cursor =
           new TreeSitter.TreeCursor(root_node);
        var level = 0;
        var child_printed = false;
        Gtk.TreeIter tree_parent = tree_root;
        var last_parents = new Gee.LinkedList<Gtk.TreeIter?>();
        last_parents.offer_head(tree_parent);
        while (true) {
          if (!child_printed && tree_cursor.goto_first_child()) {
            level += 1;
            var node = tree_cursor.current_node();
            last_parents.offer_head(tree_parent);
            tree_parent = create_ast_item (ref node, tree_parent, language_name);
          } else if (tree_cursor.goto_next_sibling()) {
            child_printed = false;
            if (last_parents.size > 0) {
               tree_parent = last_parents.poll_head();
            }
            var node = tree_cursor.current_node();
            last_parents.offer_head(tree_parent);
            tree_parent = create_ast_item (ref node, tree_parent, language_name);
            if (tree_cursor.goto_first_child()) {
              level += 1;
              node = tree_cursor.current_node();
              last_parents.offer_head(tree_parent);
              tree_parent = create_ast_item (ref node, tree_parent, language_name);
            }
          } else {
              if (level > 0) {
                tree_cursor.goto_parent();
                if (last_parents.size > 0) {
                   tree_parent = last_parents.poll_head();
                }
                child_printed = true;
                level -= 1;
              } else {
                break;
              }
          }
        }
        tree_view.expand_all ();
        source_view.refresh_folds();
    }

    private Gtk.TreeIter create_ast_item (ref TreeSitter.Node node,
                                          Gtk.TreeIter parent, string language_name) {
       int start = (int)node.start_point().row;
       int start_offset = (int)node.start_point().column;
       int end = (int)node.end_point().row;
       int end_offset = (int)node.end_point().column;
       string type = node.type ();
       var ast_item = new ASTItem (start, start_offset, end, end_offset, type,
                                   false);
       //TODO Add a factory to customize by language
       bool valid = true;
       if (language_name == "xml") {
          ast_item.foldable = type == "element";
          valid = type != "text";
       }
       if (node.start_point().row != node.end_point().row
           && valid) {
          source_view.ast_model.add (ast_item);
       }
       Gtk.TreeIter child;

       tree_store.append (out child, parent);
       Gtk.TextIter start_iter, end_iter;
       source_view.buffer.get_iter_at_line_offset (out start_iter,
                                                   start,
                                                   start_offset);
       source_view.buffer.get_iter_at_line_offset (out end_iter, end,
                                                   end_offset);
       string text = source_view.buffer.get_text (start_iter, end_iter,
                                                  true);
       if (check_ellipsize_data.active && text.length > 10)
           text = text.substring(0, 10);
       string start_pos = "%d-%d".printf(start, start_offset);
       string end_pos = "%d-%d".printf(end, end_offset);
       tree_store.set (child, 0, type, 3, text, 1, start_pos, 2,
                       end_pos, 4,
                       ast_item, -1);
       return child;
    }

    private void fill_model_by_indentation() {
        var buffer = source_view.buffer;
        Gtk.TextIter start, end;
        var fold_map  = new Gee.HashMap<int, int>();
        int empty_jump = 0;
        string indentation =
           string.nfill(source_view.ast_model.whitespace_count,
                        source_view.ast_model.whitespace);
        for (int i = 0; i < buffer.get_line_count(); i++) {
            buffer.get_iter_at_line(out start, i);
            buffer.get_iter_at_line(out end, i);
            if (!end.ends_line ()) {
               end.forward_to_line_end();
            }
            var line = buffer.get_text(start, end, false);
            int indent = 0;
            if (line.strip ().length == 0) {
               empty_jump++;
               continue;
            }
            while (line.has_prefix(indentation)) {
                indent++;
                line = line [indentation.length:line.length];
            }
            var it = fold_map.map_iterator ();
            for (var has_next = it.next (); has_next; has_next = it.next ()) {
               int current_indent = it.get_key();
               if (current_indent >= indent) {
                   int start_pos = it.get_value();
                   if (start_pos + 1 + empty_jump < i) {
                      source_view.ast_model
                         .add_item (start_pos, 0, i, 0,
                                    "fold-indentation-%d".printf(indent),
                                    false);
                   }
                   it.unset();
               }
            }
            empty_jump = 0;
            if (!fold_map.has_key(indent)) {
               fold_map.set(indent, i);
            }
        }
    }

    void on_open () {
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            "Select a file to edit", this, Gtk.FileChooserAction.OPEN,
            "_Cancel",
            Gtk.ResponseType.CANCEL,
            "_Open",
            Gtk.ResponseType.ACCEPT);
        chooser.set_select_multiple (false);
        chooser.run ();
        chooser.close ();

        if (chooser.get_file () != null) {
            var file_choosed = chooser.get_file ();
            load_file(file_choosed);
        }
    }

    public void load_file(GLib.File file_choosed) {
       string path = file_choosed.get_path();

       Gtk.SourceBuffer buffer = (Gtk.SourceBuffer)source_view.buffer;
       set_syntax(buffer, path);

       file = new Gtk.SourceFile ();
       file.location = file_choosed;
       var file_loader = new Gtk.SourceFileLoader (buffer, file);

       listen_source_changes = false;
       file_loader.load_async.begin (Priority.DEFAULT, null, null, (obj, res) => {
           file_loader.load_async.end(res);
           listen_source_changes = true;
           fill_model_by_strategy ();
       });
    }

    public void set_syntax(Gtk.SourceBuffer buffer, string path) {
       Gtk.SourceLanguageManager lm = new Gtk.SourceLanguageManager();
       string content_type = GLib.ContentType.guess(path, null, null);
       string? mime_type = GLib.ContentType.get_mime_type(content_type);
       Gtk.SourceLanguage lang = lm.guess_language(path, mime_type);
       buffer.set_highlight_syntax(true);
       buffer.set_language(lang);
       if (lang != null) {
          strategy_combo.active = 3;
       }
    }

    void on_save () {
        if (file != null && !file.is_readonly () ) {
            var file_saver =
               new Gtk.SourceFileSaver (source_view.buffer
                                        as Gtk.SourceBuffer, file);
            file_saver.save_async.begin (Priority.DEFAULT, null, null);
        }
    }

    void on_populate_menu (Gtk.Menu menu) {
        Gtk.SourceBuffer source_buffer = source_view.buffer as Gtk.SourceBuffer;

        var language_menu = new Gtk.MenuItem ();
        language_menu.set_label ("Language");

        var submenu = new Gtk.Menu ();
        language_menu.set_submenu (submenu);

        Gtk.RadioMenuItem? item_first =
           new Gtk.RadioMenuItem.with_label (null,
                                             "Normal Text");
        item_first.toggled.connect (() => {
           source_buffer.set_language (null);
        });

        unowned SList<Gtk.RadioMenuItem> group = item_first.get_group ();
        submenu.add (item_first);

        language_manager = Gtk.SourceLanguageManager.get_default ();
        var ids = language_manager.get_language_ids ();
        foreach (var id in ids) {
            var lang = language_manager.get_language (id);
            var item = new Gtk.RadioMenuItem.with_label (group, lang.name);

            submenu.add (item);
            item.toggled.connect (() => {
                source_buffer.set_language (lang);
            });

            if (source_buffer.language != null
                && id == source_buffer.language.id) {
                item.active = true;
            }
        }

        var style_menu = new Gtk.MenuItem ();
        style_menu.set_label ("Scheme");

        submenu = new Gtk.Menu ();
        style_menu.set_submenu (submenu);

        item_first = null;
        group = null;

        // Fill color schemes
        style_manager = Gtk.SourceStyleSchemeManager.get_default ();
        foreach (var id in style_manager.get_scheme_ids()) {
            var scheme = style_manager.get_scheme(id);
            Gtk.RadioMenuItem item = null;
            if (item_first == null) {
               item_first = new Gtk.RadioMenuItem.with_label (null,
                                                              scheme.name);
               group = item_first.get_group ();
               item = item_first;
            } else {
               item = new Gtk.RadioMenuItem.with_label (group, scheme.name);
            }

            submenu.add (item);
            item.toggled.connect (() => {
                source_buffer.style_scheme = scheme;
            });

            if (source_buffer.style_scheme != null
                && id == source_buffer.style_scheme.id) {
                item.active = true;
            }
        }

        menu.add (style_menu);
        menu.add (language_menu);
        menu.show_all ();
    }
}

