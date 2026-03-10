const INSTALL_FILE_PATTERN = '^LIB_(.*)\.zip$'
const TABLE_SERDE = {
  ser: {
    items: {
      version: '  (version {version})' 
      libs: '  (lib (name "{name}")(type "{type}")(uri "{uri}")(options "{options}")(descr "{descr}"))',
    }
  }
  de: {
    wrap: '\((\S+)\n((?:.*\n)*)\)'
    items: '\((lib *\(name *"(.*)"\)\(type *"(.*)"\)\(uri *"(.*)"\)\(options *"(.*)"\) *\(descr *"(.*)"\))|(version (\d+))\) *\n *'
  }
}
const LIBRARIES = {
  models: { table_name: "design-block-lib-table" }
  footprints: { table_name: "fp-lib-table" }
  symbols: { table_name: "sym-lib-table" }
}

def kicad_config_dir [] {
  if ($env | columns | find "KICAD_CONFIG" | is-empty) { 
    return ([$env.HOME ".config/kicad/9.0"] | path join)
  } 
  $env.KICAD_CONFIG
}

def kicad_data_dir [] {
  if ($env | columns | find "KICAD_DATA" | is-empty) { 
    return ([$env.HOME ".local/share/kicad/9.0"] | path join)
  }
  $env.KICAD_DATA
}

def lib_table_path [] {
  [(kicad_config_dir) $in] | path join
}

export def deserialize_lib_table [] {
  let wrap = $in | parse -r $TABLE_SERDE.de.wrap 
  let items = $wrap.capture1 | parse -r $TABLE_SERDE.de.items
  let name = $wrap.capture0 | get 0
  let version = $items | get capture7 | where $it != null | get 0
  let libs = $items | reject capture0 capture6 capture7 | rename name type uri options descr | where $it.name != null
  {
    name: $name
    version: $version
    libs: $libs
  }
}

export def serialize_lib_table [] {
  let libs = $in.libs | format pattern $TABLE_SERDE.ser.items.libs
  let version = $in | select version | format pattern $TABLE_SERDE.ser.items.version
  let items = $version | append $libs | to text
  $"\(($in.name)\n($items)\)"
}

export def lib_table_from_name [] {
  let $ltp = $in | lib_table_path
  $ltp | open | deserialize_lib_table | insert path $ltp
}

def save_lib_table [] {
  let path = $in.path
  print $"saving ($path)"
  $in | serialize_lib_table | save -f $path
}

def add_if_contains_elt_name [elt] {
  $in | each { |e| if ($in.name == $e.name) { return } }
  append $elt
}

def tables [] {
  $LIBRARIES | items { |n, l| $l.table_name | lib_table_from_name }
}

def libs [] {
  reduce {|table, libs| $libs | add_if_contains_elt_name $table.libs } 
}

def installed [] {
  tables | libs
}

def name_from_install_file_path [] {
  path basename | parse -r $INSTALL_FILE_PATTERN | get capture0
}


def name_with_path [] {
  let path = $in
  let name = ($in | name_from_install_file_path)
  if ($name | is-not-empty) {
    return {name: $name.0 path: $path}
  }
}

def not_installed_in [] {
  let libs = $in
  let files = ls -f ([$env.HOME "Downloads"] | path join) | get name | each { |e| $e | name_with_path } 
  $files | where { |e| $e.name not-in $libs.name }
}

def not_installed [] {
  installed | not_installed_in
}


def dest [] {
  let name = $in;
  [
    [dir ending];
    ["3dmodels" "stp"]
    ["footprints" "kicad_mod"]
    ["symbols" "kicad_sym"]
  ] | each { |m| {dest: ([(kicad_data_dir) $m.dir $"($name).($m.ending)"] | path join)} }
}

def insert_in_table [name path table_name] {
  let table_path = [(kicad_config_dir) $table_name] | path join
  let table = open $table_path | lines
  let index =  $table | length | $in - 1
  $table | insert $index $"  \(lib \(name \"($name)\")\(type \"KiCad\"\)\(uri \"($path)\"\)\(options \"\")\(descr \"\"\))" | save -f $table_path
}

def list_installed [] {
    print "installed: "
    print (installed | reject type options uri)
}

def list_not_installed [] {
    print "not installed: "
    print (not_installed)
}

export def main [] { }

export def list [ --installed (-i) --not_installed (-n) ] {
  if not $installed and not $not_installed {
    list_installed
    list_not_installed
    return
  }

  if $installed {
    list_installed
    return
  }

  if $not_installed {
    list_not_installed
    return
  }

  return
}

export def install [index: int] {
  let tables = tables
  let file = $tables | libs | not_installed_in | get $index

  let tmp_path = ["/tmp" "ecad"] | path join  
  let _ = unzip -o $file.path -d $tmp_path | complete 

  let inner_tmp_path = [$tmp_path $file.name] | path join
  let ki_cad_src = [$inner_tmp_path "KiCad"] | path join

  let dest = $file.name | dest
  
  [ 
    ([$inner_tmp_path "3D" "*.stp"] | path join) 
    ([$ki_cad_src "*.kicad_mod"] | path join) 
    ([$ki_cad_src "*.kicad_sym"] | path join) 
  ] | each { |p| glob $p | get 0 } | wrap src | merge $dest | each { |m| print $"moving ($m.src) to ($m.dest)"; mv $m.src $m.dest }

  $tables | merge $dest | each { |td|
    $td | update libs ($in.libs | append { name: $file.name uri: $td.dest type: "KiCad" descr: null options: null}) | reject dest |  save_lib_table 
  }

  rm -r $tmp_path

  $"installed ($file.name) successfully."
}

export def remove [index: int] {
  let tables = tables
  let libs = $tables | libs 
  let name = $libs | get $index | get name
  let paths = $name | dest | get dest

  $paths | each { |p| print $"removing ($p)"; rm $p  }
  $tables | each { |t| $t | update libs ($t.libs | where $it.name != $name) | save_lib_table } 

  $"removed ($name) successfully."
}
