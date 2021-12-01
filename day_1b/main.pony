use "files"

actor Main
  new create(env: Env) =>
    var content: String = ""
    try
      let fp: FilePath = FilePath(env.root as AmbientAuth, "input.txt")?
      let f:  File = File.open(fp)
      content = String.from_iso_array(f.read(f.size()))
    else
      env.err.print("Unable to open file: ")
    end
    let valuesstr: Array[String] = content.split()
    let values: Array[USize] = string_to_usize(env, valuesstr)

    let preproc: Array[USize] = preproc_values_list(env, values)

    let answer: USize = process_values_list(env, preproc)
    env.out.print("Final Answer: " + answer.string())

  fun string_to_usize(env: Env, valuestr: Array[String]): Array[USize] =>
    let rv: Array[USize] = []
    for f in valuestr.values() do
      try rv.push(f.usize()?) else env.out.print("Didn't parse: \"" + f + "\"") end
    end
    rv

  fun process_values_list(env: Env, values: Array[USize]): USize =>
    var prev: USize = USize(-1)
    var count: USize = 0

    for f in values.values() do
      match f
      | if (prev == USize(-1)) => env.out.print(f.string() + " (no comment)")
      | if (f < prev) => env.out.print(f.string() + " (decreased)")
      | if (f > prev) => env.out.print(f.string() + " (increased)") ; count = count + 1
      | if (f == prev) => env.out.print(f.string() + " (nochange)")
      end
      prev = f
    end
    count

  fun preproc_values_list(env: Env, values: Array[USize]): Array[USize] =>
    let rv: Array[USize] = []
    var ptr: USize = 0

    while true do
      try
        let total = values(ptr)? + values(ptr+1)? + values(ptr+2)?
        rv.push(total)
      else
        break
      end
      ptr = ptr + 1
    end
    rv
