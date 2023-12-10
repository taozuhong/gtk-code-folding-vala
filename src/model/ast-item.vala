/*
 * Item for Abstract Syntax tree model
 *
 * Author: Alberto Fanjul <albfan@gnome.org>
 */
public class ASTItem: GLib.Object {
   public int start {get; set;}
   public int start_offset {get; set;}
   public int end {get; set;}
   public int end_offset {get; set;}
   public string node_type {get; set;}
   public bool fold {get; set;}
   public bool foldable {get; set;}

   public ASTItem(int start, int start_offset, int end, int end_offset,
                  string node_type, bool fold) {
      this.start = start;
      this.start_offset = start_offset;
      this.end = end;
      this.end_offset = end_offset;
      this.node_type = node_type;
      this.fold = fold;
      this.foldable = false;
   }
}

