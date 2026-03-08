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

def name_from_install_file_path [] {
  path basename | parse -r $INSTALL_FILE_PATTERN | get capture0
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
  serialize_lib_table | save -f path
}


def installed [] {
  $LIBRARIES | items { |n, l| $l.table_name | lib_table_from_name } | reduce {|elt, acc| $acc | merge $elt } 
}

def not_installed [] {
  let files = ls ~/Downloads | get name | name_from_install_file_path
  let installed = installed
  $files | where { |e| $installed.libs | find e | is-empty }
}


def extract_file [] {
  mut l = []
  for p in $in {
    let name = $p | extract_name_from_install_file
    if ($name | is-empty) { continue }
    $l = $l | append { path: $p name: $name.0 }
  }
  $l
}

def dest [] {
  let name = $in;
  let mappings = [
    [dir ending];
    ["3dmodels" "stp"]
    ["footprints" "kicad_mod"]
    ["symbols" "kicad_sym"]
  ]
  $mappings | each { |m| {dest: ([(kicad_data_dir) $m.dir $"($name).($m.ending)"] | path join)} }
}

def insert_in_table [name path table_name] {
  let table_path = [(kicad_config_dir) $table_name] | path join
  let table = open $table_path | lines
  let index =  $table | length | $in - 1
  $table | insert $index $"  \(lib \(name \"($name)\")\(type \"KiCad\"\)\(uri \"($path)\"\)\(options \"\")\(descr \"\"\))" | save -f $table_path
}

export def main [] {
  # let commands = [
  #   ["command", "description"]; 
  #   ["list", "list all available files"], 
  #   ["install <index: int>", "installs the file into your $env.KICAD_DATA/.."]
  # ] 
  #
  # print "available commands: " $commands "Note: to install put your files in the ~./Downloads folder"
}

def list_installed [] {
    print "installed: "
    print (installed | get libs | reject type options uri)
}

def list_not_installed [] {
    print "not installed: "
    print (not_installed | get libs)
}

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
  let file = not_installed | get $index | extract_file

  let tmp_path = ["/tmp" "ecad"] | path join  
  let _ = unzip -o $file.path -d $tmp_path | complete 

  let inner_tmp_path = [$tmp_path $file.name] | path join
  let ki_cad_src = [$inner_tmp_path "KiCad"] | path join

  let dest = $file.name | dest
  
  let src = [ 
    [src];
    [([$inner_tmp_path "3D" "*.stp"] | path join)] 
    [([$ki_cad_src "*.kicad_mod"] | path join)] 
    [([$ki_cad_src "*.kicad_sym"] | path join)] 
  ]
  $src | merge $dest | each { |m| {mv (glob $m.src).0 $m.dest} }

  table_names | merge $dest | each { |t| insert_in_table $file.name $t.dest $t.name }

  rm -r $tmp_path

  $"installed ($file.name) successfully."
}

export def remove [index: int] {
  let installed = installed
  print $installed
  let name = $installed.libs | get $index
  $name
}
