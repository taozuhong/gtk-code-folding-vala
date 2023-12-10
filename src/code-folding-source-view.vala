/*
 * CodeFoldingSourceView is a Gtk.SourceView able to fold sections of code.
 * 
 * Author: Alberto Fanjul <albfan@gnome.org>
 */
public class CodeFoldingSourceView : Gtk.SourceView {

   public ASTModel ast_model {get; set;}

   public override void draw_layer (Gtk.TextViewLayer layer, Cairo.Context cr)
   {
      if (layer == Gtk.TextViewLayer.BELOW)
      {
         draw_background (this, cr);
      }
   }

   public void apply_fold_at_cursor(bool fold_state) {
      Gtk.TextIter cursor_iter;
      buffer.get_iter_at_offset (out cursor_iter, buffer.cursor_position);
      ASTItem? selected_item = null;
      int line = cursor_iter.get_line ();
      int offset = cursor_iter.get_line_offset ();
      foreach(ASTItem item in ast_model) {
         if ((item.start < line && line < item.end)
             || (item.start == line && item.start_offset <= offset)
             || (item.end == line && item.end_offset >= offset)) {
            selected_item = item;
         }
      }

      if (selected_item != null) {
         selected_item.fold = fold_state;
         refresh_folds ();
      }
   }

   public void apply_fold_all(bool fold_state) {
      foreach(ASTItem item in ast_model) {
         item.fold = fold_state;
      }
      refresh_folds ();
   }

   public void fold_selection() {
      if (buffer.has_selection) {
         Gtk.TextIter start, end;
         buffer.get_selection_bounds(out start, out end);
         if (start.get_line () != end.get_line ()) {
            ast_model.add_item_from_iter (start, end, "fold-manual", true);
         }
      }
      refresh_folds ();
   }

   public void refresh_folds() {
      foreach(ASTItem item in ast_model) {
         var fold = item.fold;
         Gtk.TextIter start, end;
         buffer.get_iter_at_line (out start, item.start + 1);
         buffer.get_iter_at_line (out end, item.end + 1);
         if (!fold) {
            buffer.remove_tag_by_name("invisible", start, end);
         }
      }

      foreach(ASTItem item in ast_model) {
         var fold = item.fold;
         Gtk.TextIter start, end;
         buffer.get_iter_at_line (out start, item.start + 1);
         buffer.get_iter_at_line (out end, item.end + 1);
         if (fold) {
            buffer.apply_tag_by_name("invisible", start, end);
         }
      }
   }

   private void draw_background (Gtk.TextView widget, Cairo.Context cr)
   {
     Gdk.Rectangle visible_rect;
     Gdk.Rectangle iter_rect;

     if (ast_model.style != "Atom") {
        return;
     }

     cr.save ();

     widget.get_visible_rect (out visible_rect);
     cr.translate (-visible_rect.x, -visible_rect.y);

      cr.set_source_rgb (0.5, 0.5, 0.5);
      Gtk.TextIter iter;

      foreach(ASTItem item in ast_model) {
         var fold = item.fold;
         if (!fold)
            continue;
         buffer.get_iter_at_line (out iter, item.start);
         if (!iter.ends_line ()) {
            iter.forward_to_line_end();
         }
         foreach (Gtk.TextTag tag in iter.get_tags()) {
            if (tag.name == "invisible") {
               return;
            }
         }
         get_iter_location(iter, out iter_rect);
         cr.rectangle(iter_rect.x +4, iter_rect.y+6, 30, 8);
      }
      cr.fill();

     cr.restore ();

   }
}

