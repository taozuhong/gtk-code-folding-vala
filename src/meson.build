executable('gtk-code-folding',
  [
    'main.vala',
    'code-folding-source-view.vala',
    'model/ast-model.vala',
    'model/ast-item.vala',
    'view/code-folding-source-gutter-renderer.vala',
    'view/code-folding-window.vala',
  ],
  dependencies: [
    dependency('gee-0.8'),
    dependency('gtk+-3.0'),
    dependency('gtksourceview-4'),
    tree_sitter_dep
  ],
  install: true
)
