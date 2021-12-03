use "files"
use "collections"

type Axis is (Horizontal | Vertical)
primitive Horizontal
primitive Vertical

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
    let valuesstr: Array[String] = content.split_by("\n")

    process_lines(env, valuesstr)


  fun process_lines(env: Env, valuesstr: Array[String]) =>
    var counts: Array[ISize] = []

    try
      let bitwidth: USize = valuesstr(0)?.size()
      env.out.print("Bitwidth: " + bitwidth.string())

      for ptr in Range(0, bitwidth) do
        var bitcount: ISize = 0
        for f in valuesstr.values() do
          if (f.at("1", ptr.isize())) then bitcount = bitcount + 1 else bitcount = bitcount -1 end
        end
        counts.push(bitcount)
      end
    end

    var gamma: USize = 0
    try
      for g in Range(0, counts.size()) do
        let col: USize = counts.size() - g - 1
        let num: USize = twopow(col)
        env.out.print(col.string() + " pow: " + num.string() + " count: " + counts(g)?.string())
        if (counts(g)? > 0) then gamma = gamma + num end
      end
    end

    env.out.print("Gamma: " + gamma.string())
    var sigma: USize = twopow(counts.size()) - gamma - 1
    env.out.print("Sigma: " + sigma.string())
    env.out.print("Product: " + (gamma * sigma).string())

  fun twopow(cnt: USize): USize =>
    let two: F64 = 2
    two.pow(cnt.f64()).usize()







    /*
    if (rv0count > 0) then gamma = gamma + 16 end
    if (rv1count > 0) then gamma = gamma + 8 end
    if (rv2count > 0) then gamma = gamma + 4 end
    if (rv3count > 0) then gamma = gamma + 2 end
    if (rv4count > 0) then gamma = gamma + 1 end

    epsilon = 31 - gamma



    env.out.print(rv0count.string())
    env.out.print(rv1count.string())
    env.out.print(rv2count.string())
    env.out.print(rv3count.string())
    env.out.print(rv4count.string())
    env.out.print(gamma.string())
    env.out.print(epsilon.string())
    env.out.print((gamma * epsilon).string())

*/


