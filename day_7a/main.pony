use "debug"
use "files"
use "itertools"
use "collections"

actor Main
  var env: Env
  var crabarray: Array[USize] = []
  var min: USize = -1
  var max: USize = 0

  new create(env': Env) =>
    env = env'
    try
      populate_crabs_file(env.root as AmbientAuth, "day7-input.full")?
    else
      env.err.print("Unable to read and process the lanterfish file")
    end

  fun ref populate_crabs_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by(",")
    try
      for line in contentlines.values() do
        (let num: USize, _) = line.read_int[USize]()?
        if (num < min) then min = num end
        if (num > max) then max = num end
        crabarray.push(num)
      end
    end
    showcrab()
    env.out.print("Min: " + min.string())
    env.out.print("Max: " + max.string())

    var minfuel: USize = -1
    for x in Range(min,max) do
      let r: USize = calculate_total(x)
      if (r < minfuel) then minfuel = r end
      env.out.print(r.string() + ": " + x.string())
    end
    env.out.print("Minfuel: " + minfuel.string())


  fun calculate_total(x: USize): USize =>
    var fuel: USize = 0
    for value in crabarray.values() do
      let delta: USize = (x.isize() - value.isize()).abs().usize()
//      env.out.print("Move from " + value.string() + " to " + x.string() + ": " + delta.string() + " fuel")
      fuel = fuel + delta
    end
    fuel


  fun showcrab() =>
    env.out.write("Crabs: ")
    for f in crabarray.values() do
      env.out.write(f.string() + ", ")
    end
    env.out.print("")

