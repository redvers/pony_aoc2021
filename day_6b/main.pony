use "debug"
use "files"
use "collections"

actor Main
  var env: Env
  var fishcount: Array[USize] = Array[USize].init(0, 9)

  new create(env': Env) =>
    env = env'
    try
      populate_lanternfish_from_file(env.root as AmbientAuth, "day-6a-input.full")?
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
        (let num: USize, _) = line.read_int[USize]()?
        env.out.print("Read: " + num.string())
        let cnt: USize = fishcount(num)?
        fishcount.update(num, cnt + 1)?
      end
    end
    showcounts(0)

    try
    for cnt in Range(1, 256+1) do
      let rv: Array[USize] = process_fish()?
      fishcount = rv
      showcounts(cnt)
    end
    else
      env.out.print("Something failed")
    end

  fun process_fish(): Array[USize] ? =>
    let rv: Array[USize] = Array[USize].init(0, 9)
    rv.update(7, fishcount(8)?)?
    rv.update(6, fishcount(7)? + fishcount(0)?)?
    rv.update(5, fishcount(6)?)?
    rv.update(4, fishcount(5)?)?
    rv.update(3, fishcount(4)?)?
    rv.update(2, fishcount(3)?)?
    rv.update(1, fishcount(2)?)?
    rv.update(0, fishcount(1)?)?
    rv.update(8, fishcount(0)?)?
    rv

  fun showcounts(day: USize) =>
    var total: USize = 0
    env.out.write("Day# " + day.string() + ": ")
    for cnt in Range(0, fishcount.size()) do
      try
        total = total + fishcount(cnt)?
        env.out.write("[" + cnt.string() + "]" + fishcount(cnt)?.string() + ", ")
      else
        env.out.print("Don't seem to be able to print a result - odd?")
      end
    end
    env.out.print(" => " + total.string())
