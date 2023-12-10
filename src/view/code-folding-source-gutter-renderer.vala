/*
 * CodeFoldingSourceGutterRenderer is a gutter renderer for SourceView to show
 * folding blocks
 *
 * Author: Alberto Fanjul <albfan@gnome.org>
 */
public class CodeFoldingSourceGutterRenderer : Gtk.SourceGutterRenderer {

   private double line_width = 1;
   private int max_height_symbols = 18;
   private bool is_theme_dark = false;
   private ASTModel ast_model;

   public CodeFoldingSourceGutterRenderer (ASTModel ast_model) {
      this.ast_model = ast_model;

      size = 16;

      query_activatable.connect((iter, area, event) => {
         return true;
      });
      activate.connect((iter, rect, evt) => {
         var line = iter.get_line();
         bool found = false;

         var view = ((CodeFoldingSourceView)get_view());

         foreach(ASTItem item in ast_model) {
            if (item.foldable && item.fold && line == item.start) {
               item.fold = !item.fold;
               found = true;
            }
         }
         if (!found) {
           foreach(ASTItem item in ast_model) {
              if (item.foldable && !item.fold && (line == item.start || line == item.end)) {
                 item.fold = !item.fold;
                 found = true;
              }
           }
         }
         if (found) { 
             view.refresh_folds ();
             get_view().queue_draw();
         }

      });
   }

   public override void draw (Cairo.Context cr,
                              Gdk.Rectangle background_area,
                              Gdk.Rectangle cell_area,
                              Gtk.TextIter start, Gtk.TextIter end,
                              Gtk.SourceGutterRendererState state) {
      var markers_start = new Gee.ArrayList<int>();
      var markers_end = new Gee.ArrayList<int>();
      var markers_folded = new Gee.ArrayList<int>();
      var line = start.get_line();
      foreach(ASTItem item in ast_model) {
         if (!item.foldable)
             continue;
         markers_start.add(item.start);
         if (item.fold) {
           markers_folded.add(item.start);
         }
         markers_end.add(item.end);
      }

      var highlighted = ast_model.highlighted;

      foreach(ASTItem item in ast_model) {
         if (!item.foldable)
             continue;

         bool highlight = false;
         for (int i = 0; i < highlighted.length ; i++) {
             var h_item = highlighted.index (i);
             highlight = item == h_item;
             if (highlight) {
                 break;
             }
         }
         if (line == item.start) {
            if (item.fold) {
               if (ast_model.style == "Intellij") {
                  draw_fold_closed_pixbuf(cr, cell_area, highlight);
               } else if (ast_model.style == "Atom") {
                  draw_fold_greater_pixbuf(cr, cell_area, highlight);
               }
            } else {
               if (markers_start.contains(line) && markers_end.contains(line)
                   && !highlight) {
                  continue;
               }
               if (ast_model.style == "Intellij") {
                  draw_fold_open_start_pixbuf(cr, cell_area, highlight);
               } else if (ast_model.style == "Atom") {
                  draw_fold_down_pixbuf(cr, cell_area, highlight);
               }
            }
         } else if (line == item.end) {
            if (ast_model.style == "Intellij") {
               if (!item.fold) {
                  draw_fold_open_end_pixbuf(cr, cell_area, highlight);
	       }
            } else if (ast_model.style == "Atom") {
               //Do nothing
            }
         } else if (line > item.start && line < item.end) {
            if (ast_model.style == "Intellij") {
               draw_fold_vert_pixbuf(cr, cell_area, highlight,
                                     markers_start.contains(line),
                                     markers_end.contains(line));
            } else if (ast_model.style == "Atom") {
               //Do nothing
               break;
            }
         }
      }
   }

   public void draw_fold_open_start_pixbuf(Cairo.Context cr,
                                            Gdk.Rectangle rect,
                                            bool highlight) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;
      int excess_height = h;
      h = h <max_height_symbols ? h : max_height_symbols;
      excess_height -= h;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+3 + 0.5, y+5 + 0.5);
      cr.rel_line_to (w-6, 0);
      cr.rel_line_to (0, h - 10);
      cr.rel_line_to (-(w/2)+3, h-12);

      cr.rel_line_to (0, 3 + excess_height);
      cr.rel_move_to (0, -3 - excess_height);

      cr.rel_line_to (-(w/2)+3, -h+12);
      cr.rel_line_to (0, -h+10);

      if (ast_model.show_symbols) {
         cr.move_to (x+5 + 0.5, y + (h/2) + 2 + 0.5);
         cr.rel_line_to (w-10, 0);
      }
      cr.stroke ();
      cr.restore ();
   }

   public void draw_fold_down_pixbuf(Cairo.Context cr, Gdk.Rectangle rect,
                                     bool highlight) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;
      h = h <max_height_symbols ? h : max_height_symbols;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+3 + 0.5, y+1 + 0.5);
      cr.rel_move_to (w-6, 0);
      cr.rel_move_to (0, h - 10);
      cr.rel_line_to (-(w/2)+3, h-12);
      cr.rel_line_to (-(w/2)+3, -h+12);

      cr.stroke ();
      cr.restore ();
   }

   public void config_color(bool is_theme_dark, bool highlight, Cairo.Context cr) {
      if (is_theme_dark) {
         if (highlight) {
            cr.set_source_rgba(0.94, 0.94, 0.94, 1);
         } else {
            cr.set_source_rgba(0.54, 0.54, 0.54, 1);
         }
      } else {
         if (highlight) {
            cr.set_source_rgba(0.66, 0.66, 0.66, 1);
         } else {
            cr.set_source_rgba(0.26, 0.26, 0.26, 1);
         }
      }
   }

   public void draw_fold_vert_pixbuf(Cairo.Context cr, Gdk.Rectangle rect,
                                     bool highlight, bool overlapped_start,
                                     bool overlapped_end) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+(w/2) + 0.5, y - 1 + 0.5);
      if (overlapped_start) {
         cr.rel_line_to (0, h - 14);
      }
      if (overlapped_end) {
         cr.move_to (0 + 0.5, h - 2 + 0.5);
         cr.rel_line_to (0, 5);
      }
      if (!overlapped_start && !overlapped_end) {
         cr.rel_line_to (0, h + 1);
      }
      cr.stroke ();
      cr.restore ();
   }

   public void draw_fold_open_end_pixbuf(Cairo.Context cr, Gdk.Rectangle rect,
                                          bool highlight) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;
      h = h <max_height_symbols ? h : max_height_symbols;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+(w/2) + 0.5, y - 1 + 0.5);
      cr.rel_line_to (0, 4);
      cr.rel_line_to ((w/2)-3, h-12);
      cr.rel_line_to (0, h-10);
      cr.rel_line_to (-w+6, 0);
      cr.rel_line_to (0, -h+10);
      cr.rel_line_to ((w/2)-3, -h+12);

      if (ast_model.show_symbols) {
         cr.move_to (x+5 + 0.5, y+(h/2)+2 + 0.5 );
         cr.rel_line_to (w-10, 0);
      }

      cr.stroke ();
      cr.restore ();
   }

   public void draw_fold_closed_pixbuf(Cairo.Context cr, Gdk.Rectangle rect,
                                     bool highlight) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;
      h = h <max_height_symbols ? h : max_height_symbols;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+3 + 0.5, y+5 + 0.5);
      cr.rel_line_to (w-6, 0);
      cr.rel_line_to (0, h-6);
      cr.rel_line_to (-w+6, 0);
      cr.rel_line_to (0, -h+6);

      if (ast_model.show_symbols) {
         cr.move_to (x + 5 + 0.5, y + (h/2) + 1 + 1.5);
         cr.rel_line_to (w-10, 0);
         cr.move_to (x+(w/2) + 0.5, y + 7 + 0.5);
         cr.rel_line_to (0, h-11);
      }
      cr.stroke ();
      cr.restore ();
   }

   public void draw_fold_greater_pixbuf(Cairo.Context cr, Gdk.Rectangle rect,
                                        bool highlight) {
      cr.save ();
      int x = rect.x;
      int y = rect.y;
      int w = rect.width;
      int h = rect.height;
      h = h <max_height_symbols ? h : max_height_symbols;

      config_color(is_theme_dark, highlight, cr);
      cr.set_line_width(line_width);
      cr.move_to (x+w-8 + 0.5, y+5 + 0.5);
      cr.rel_line_to (4, (h/2)-3);
      cr.rel_line_to (-4, h-12);

      cr.stroke ();
      cr.restore ();
   }
}

