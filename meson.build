project('CodeFolding', 'vala', 'c', 'cpp')

tree_sitter_sources = [
  'vendor/tree-sitter/lib/src/lib.c',
  'fixtures/tree-sitter-bash/src/parser.c',
  'fixtures/tree-sitter-bash/src/scanner.cc',
  'fixtures/tree-sitter-cpp/src/parser.c',
  'fixtures/tree-sitter-cpp/src/scanner.cc',
  'fixtures/tree-sitter-c/src/parser.c',
  'fixtures/tree-sitter-go/src/parser.c',
  #'fixtures/tree-sitter-haskell/src/parser.c',
  #'fixtures/tree-sitter-haskell/src/scanner.cc',
  'fixtures/tree-sitter-html/src/parser.c',
  'fixtures/tree-sitter-html/src/scanner.cc',
  'fixtures/tree-sitter-javascript/src/parser.c',
  'fixtures/tree-sitter-javascript/src/scanner.c',
  'fixtures/tree-sitter-json/src/parser.c',
  'fixtures/tree-sitter-php/src/parser.c',
  'fixtures/tree-sitter-php/src/scanner.cc',
  'fixtures/tree-sitter-python/src/parser.c',
  'fixtures/tree-sitter-python/src/scanner.cc',
  'fixtures/tree-sitter-ruby/src/parser.c',
  'fixtures/tree-sitter-ruby/src/scanner.cc',
  'fixtures/tree-sitter-rust/src/parser.c',
  'fixtures/tree-sitter-rust/src/scanner.c',
  'fixtures/tree-sitter-typescript/typescript/src/parser.c',
  'fixtures/tree-sitter-typescript/typescript/src/scanner.c',
  'fixtures/tree-sitter-xml/src/parser.c',
  ]

tree_sitter_lib = static_library('tree-sitter-runtime', tree_sitter_sources, 
  include_directories: [
    include_directories('vendor/tree-sitter/lib/src'), 
    include_directories('vendor/tree-sitter/lib/include'),
    include_directories('vendor/tree-sitter/lib/utf8proc')
    ]
  )

tree_sitter_vapi = meson.get_compiler('vala').find_library('libtreesitter',
                             dirs: join_paths(meson.source_root(), 'vapi'))

tree_sitter_dep = declare_dependency(
	link_with: tree_sitter_lib,
	include_directories: include_directories(join_paths('vendor', 'tree-sitter',
                                                       'lib', 'include')),
	dependencies: tree_sitter_vapi,
)

subdir('src')

