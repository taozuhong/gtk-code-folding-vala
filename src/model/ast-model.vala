/*
 * Model for Abstract Syntax Tree
 *
 * Author: Alberto Fanjul <albfan@gnome.org>
 */
public class ASTModel: Gee.ArrayList<ASTItem> {

   public Array<ASTItem> highlighted {get; set; default = new Array<ASTItem>();}
   public bool show_symbols {get; set;}
   public string strategy {get; set;}
   public string style {get; set;}
   public char whitespace {get; set;}
   public int whitespace_count {get; set;}

   public ASTModel () {
      whitespace = ' ';
      whitespace_count = 2;
   }

   public void add_item_from_iter(Gtk.TextIter start, Gtk.TextIter end,
                                  string type, bool fold) {
      add_item(start.get_line (), start.get_line_offset (), end.get_line (),
               end.get_line_offset (), type, fold);
   }

   public void add_item(int start, int start_offset, int end, int end_offset,
                        string type, bool fold) {
      add(new ASTItem(start, start_offset, end, end_offset, type, fold));
   }

   public Array<ASTItem> get_folds(int line) {
      var result = new Array<ASTItem>();
      foreach(ASTItem item in this)
      {
         if (line == item.start || (!item.fold && line == item.end))
         {
            result.append_val(item);
         }
      }
      return result;
   }
}

