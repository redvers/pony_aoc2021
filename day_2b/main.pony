use "files"

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
    let values: Array[(Axis, ISize)] = parse_lines(env, valuesstr)

    let answer: ISize = process_values_list(env, values)
    env.out.print("Final Answer: " + answer.string())

  fun parse_lines(env: Env, valuestr: Array[String]): Array[(Axis, ISize)] =>
    let rv: Array[(Axis, ISize)] = []
    try (let x: ISize, let y: USize) = "forward 7".read_int[ISize](8)? end
    for f in valuestr.values() do
      match f
      | if (f.contains("forward ")) => try (let x: ISize, let y: USize) = f.read_int[ISize](8)? ; rv.push((Horizontal, x)) else env.out.print("ParseFail: " + f) end
      | if (f.contains("down ")) => try (let x: ISize, let y: USize) = f.read_int[ISize](5)? ; rv.push((Vertical, x)) else env.out.print("ParseFail: " + f) end
      | if (f.contains("up ")) => try (let x: ISize, let y: USize) = f.read_int[ISize](3)? ; rv.push((Vertical, x * -1)) else env.out.print("ParseFail: " + f) end
      else
        env.out.print("Didn't parse: \"" + f + "\"")
      end
    end
    env.out.print("Number of processed lines: " + rv.size().string())
    rv

  fun process_values_list(env: Env, values: Array[(Axis, ISize)]): ISize =>
    var horizontal: ISize = 0
    var vertical: ISize = 0
    var aim: ISize = 0

    for (axis, value) in values.values() do
      match axis
      | let x: Horizontal => horizontal = horizontal + value ; vertical = vertical + (value*aim) ; env.out.print("H: " + horizontal.string() + " A: " + aim.string())
      | let s: Vertical   => aim = aim + value ; env.out.print("V: " + vertical.string() + " A: " + aim.string())
      end
    end

    horizontal * vertical
