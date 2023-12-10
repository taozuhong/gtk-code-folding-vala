# Gtk code folding in vala

Code folding using different algorithms AST trees

![screencast](screencast.webm)

## Compiling
    
    ./fetch-tree-sitter
    meson build
    ninja -C build

## Running

    ./build/gtk-code-folding data/index.html
    ./build/gtk-code-folding data/example.json
    ./build/gtk-code-folding data/main.c

## Credits

- Based on https://gitlab.gnome.org/albfan/gtk-code-folding-python
- Using tree-sitter to create AST trees: https://tree-sitter.github.io/tree-sitter/ 

