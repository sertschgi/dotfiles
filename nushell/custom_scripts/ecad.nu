const file_pattern = '^LIB_(.*)\.zip$'

def get_files [] {
  ls ~/Downloads | get name
}

def extract_name [] {
  path basename | parse -r $file_pattern | get capture0
}

def extract_file [] {
  mut l = []
  for p in $in {
    let name = $p | extract_name
    if ($name | is-empty) { continue }
    $l = $l | append { path: $p name: $name.0 }
  }
  $l
}

def get_dest [] {
  let name = $in;
  let mappings = [
    [dir ending];
    ["3dmodels" "stp"]
    ["footprints" "kicad_mod"]
    ["symbols" "kicad_sym"]
  ]
  $mappings | each { |m| {dest: ([$env.KICAD_DATA $m.dir $"($name).($m.ending)"] | path join)} }
}

def insert_in_table [name, path, table_name] {
  let table = [$env.KICAD_CONFIG $table_name] | path join
  open $table | lines | insert 149 $"\(lib \(name \"($name)\")\(type \"KiCad\"\)\(uri \"($path)\"\)\(options \"\")\(descr \"\"\))" | save $table
}

def check_installed [] {
  $in | get_dest | each { |p| $p.dest | path exists } | all {}
}

def --env ensure_kicad_data [] {
  if ($env | columns | find "KICAD_DATA" | is-empty) { 
    $env.KICAD_DATA = [$env.HOME ".local/share/kicad/9.0"] | path join 
  } 
}

export def main [] {
  let commands = [
    ["command", "description"]; 
    ["list", "list all available files"], 
    ["install <index: int>", "installs the file into your $env.KICAD_DATA/.."]
  ] 

  print "available commands: " $commands "Note: to install put your files in the ~./Downloads folder"
}

export def list [] {
  ensure_kicad_data

  (get_files | extract_name) | each { |e| { name: $e installed: ($e | check_installed) } }
}

export def install [index: int] {
  ensure_kicad_data

  let file = get_files | extract_file | get $index

  let tmp_path = ["/tmp" "ecad"] | path join  
  let _ = unzip $file.path -d $tmp_path | complete 

  let inner_tmp_path = [$tmp_path $file.name] | path join
  let ki_cad_src = [$inner_tmp_path "KiCad"] | path join
  
  let src = [ 
    [src];
    [([$inner_tmp_path "3D" "*.stp"] | path join)] 
    [([$ki_cad_src "*.kicad_mod"] | path join)] 
    [([$ki_cad_src "*.kicad_sym"] | path join)] 
  ]

  let dest = $file.name | get_dest

  $src | merge $dest | each { |m| mv (glob $m.src).0 $m.dest }


  rm -r $tmp_path
  
  $"installed ($file.name) successfully."
}

export def remove [] {
  $in | get_dest | rm -p $in
}
