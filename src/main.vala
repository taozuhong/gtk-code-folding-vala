/*
 * CodeFolding is a modified SourceView to show code folding feature but also is
 * support syntax highlights as many code editors.
 *
 * Author: Alberto Fanjul <albfan@gnome.org>
 */
public class CodeFolding {
    public static int main (string[] args) {
        Gtk.init (ref args);

        new CodeFoldingWindow (args[1]);

        Gtk.main ();

        return 0;
    }
}

