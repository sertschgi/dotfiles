export def main [] {
  let commands = [
    ["command", "description"]; 
    ["list", "list all available files"], 
    ["install <index: int>", "installs the file into your $env.KICAD_DATA/.."]
  ] 

  print "available commands: " $commands "Note: to install put your files in the ~./Downloads folder"
}

const file_pattern = '^LIB_(.*)\.zip$';

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

export def list [] {
  print "available to install: "
  get_files | extract_name
}

export def install [index: int] {
  if ($env | columns | find "KICAD_DATA" | is-empty) { $env.KICAD_DATA = [$env.HOME ".local/share/kicad/9.0"] | path join }

  # creates a record with path and name columns
  let file = get_files | extract_file | get $index

  let tmp_path = ["/tmp" "ecad"] | path join  
  unzip $file.path -d $tmp_path

  let inner_tmp_path = [$tmp_path $file.name] | path join
  let ki_cad_src = [$inner_tmp_path "KiCad"] | path join
  
  let movements = [ 
    { 
      src: ([$inner_tmp_path "3D" "*.stp"] | path join)
      dest: ([$env.KICAD_DATA "3dmodels"] | path join)
    }
    { 
      src: ([$ki_cad_src "*.kicad_mod"] | path join) 
      dest: ([$env.KICAD_DATA "footprints"] | path join)
    }
    {
      src: ([$ki_cad_src "*.kicad_sym"] | path join) 
      dest: ([$env.KICAD_DATA "symbols"] | path join)
    }
  ]

  $movements | each { |m| mv -vp (glob $m.src).0 $m.dest }

  rm -r $tmp_path
  
  return 
}
