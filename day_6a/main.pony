use "debug"
use "files"
use "collections"

actor Main
  var env: Env
  var fisharray: Array[U8] = []

  new create(env': Env) =>
    env = env'
    try
      populate_lanternfish_from_file(env.root as AmbientAuth, "day-6a-input.smol")?
    else
      env.err.print("Unable to read and process the lanterfish file")
    end

  fun ref populate_lanternfish_from_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by(",")
    try
      for line in contentlines.values() do
        (let num: U8, _) = line.read_int[U8]()?
        fisharray.push(num)
      end
    end

    for day in Range(1, 80+1) do
      process_fish()?
      env.out.print(day.string())
    end
    env.out.print("Population size: " + fisharray.size().string())

  fun ref process_fish()? =>
    for ptr in Range(0, fisharray.size()) do
      let value: U8 = fisharray(ptr)?
      if (value == 0) then
        fisharray.update(ptr, 6)?
        fisharray.push(8)
      else
        fisharray.update(ptr, value -1)?
      end
    end

  fun showfish(day: USize) =>
    env.out.write("After " + day.string() + " day(s): ")
    for f in fisharray.values() do
      env.out.write(f.string() + ",")
    end
    env.out.print("")
