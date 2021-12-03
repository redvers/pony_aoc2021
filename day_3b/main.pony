use "files"
use "collections"

type Axis is (Horizontal | Vertical)
primitive Horizontal
primitive Vertical

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'
    var content: String = ""
    try
      let fp: FilePath = FilePath(env.root as AmbientAuth, "input.txt")?
      let f:  File = File.open(fp)
      content = String.from_iso_array(f.read(f.size()))
    else
      env.err.print("Unable to open file: ")
    end
    let valuesstr: Array[String] = content.split_by("\n")

    var index: USize = 0
    var res: Array[String] = valuesstr
    while index < 20 do // sanity check
      res = process_lines("1", res, index)
      index = index + 1
      if (res.size() < 2) then break end
    end

    var o2: String = ""
    var co2: String = ""
    try
      o2 = res(0)?
    end

    res = valuesstr
    index = 0
    while index < 10 do // sanity check
      res = process_lines("0", res, index)
      index = index + 1
      if (res.size() < 2) then break end
    end

    try
      co2 = res(0)?
    end
    let o2val: USize = binary_to_dec(o2)
    let co2val: USize = binary_to_dec(co2)

    env.out.print("\n")
    env.out.print("     O₂: " + o2 + ": " + o2val.string())
    env.out.print("    CO₂: " + co2 + ": " + co2val.string())
    env.out.print("Product: " + (o2val * co2val).string())


  fun binary_to_dec(str: String): USize =>
      var rv: USize = 0
      for g in Range(0, str.size()) do
        let col: USize = str.size() - g - 1
        let num: USize = twopow(col)
        if (str.at("1", g.isize())) then rv = rv + num end
      end
      rv

  fun twopow(cnt: USize): USize =>
    let two: F64 = 2
    two.pow(cnt.f64()).usize()


  fun process_lines(checkstr: String, valuesstr: Array[String], index: USize): Array[String] =>
    var counts: Array[ISize] = []
    var rv: Array[String] = []

    var bitcount: ISize = 0
    for f in valuesstr.values() do
      if (f.at(checkstr, index.isize())) then bitcount = bitcount + 1 else bitcount = bitcount -1 end
    end

    let criteria: String =
      match bitcount
      | if bitcount == 0 => checkstr
      | if (bitcount > 0) => "1"
      | if (bitcount < 0) => "0"
      else
        "0" // Will never happen™
      end
    env.out.print("")

    for f in valuesstr.values() do
      if (f.at(criteria, index.isize())) then rv.push(f); env.out.print(index.string() + " -> Selected: " + f) end
    end
    rv


