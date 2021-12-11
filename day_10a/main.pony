use "files"
use "collections"

actor Main
  let env: Env
  var totalscore: USize = 0
  let acscores: Array[USize] = []
  new create(env': Env) =>
    env = env'

    var content: String = ""
    try
      let fp: FilePath = FilePath(env.root as AmbientAuth, "day10.full")?
      let f:  File = File.open(fp)
      content = String.from_iso_array(f.read(f.size()))
    else
      env.err.print("Unable to open file: ")
    end
    let valuesstr: Array[String] = content.split("\n")

    for string in valuesstr.values() do
      (let sc: USize, let ac: USize) = process_line(string)
			totalscore = totalscore + sc

      if (ac > 0) then
				acscores.push(ac)
      end
    end
		env.out.print("Total Score: " + totalscore.string())
    let sorted: Array[USize] = Sort[Array[USize], USize](acscores)

		let ptr: USize = (sorted.size()-1).div(2)
    try env.out.print("Median AC Score: " + acscores(ptr)?.string()) end

  fun process_line(line: String): (USize, USize) =>
    let linemut: String ref = recover ref line.clone() end
    let stack: String ref = recover ref String end

    var topstack: U8 = 0
    var botfeed: U8 = 0

    env.out.print(linemut + "\n")
    var score: USize = 0
    while (linemut.size() > 0) do
     try
      try topstack = stack.at_offset(-1)? end
      match linemut.shift()?
      | let x: U8 if (x == '{') => stack.push(x)
      | let x: U8 if (x == '(') => stack.push(x)
      | let x: U8 if (x == '[') => stack.push(x)
      | let x: U8 if (x == '<') => stack.push(x)

      | let x: U8 if (x == '}') => if (stack.at_offset(-1)? == '{') then stack.pop()? else error end
      | let x: U8 if (x == ')') => if (stack.at_offset(-1)? == '(') then stack.pop()? else error end
      | let x: U8 if (x == ']') => if (stack.at_offset(-1)? == '[') then stack.pop()? else error end
      | let x: U8 if (x == '>') => if (stack.at_offset(-1)? == '<') then stack.pop()? else error end
      end

      try botfeed = linemut.at_offset(0)? end
      env.out.write(stack + " -><- " + linemut + "       " + String.from_array([topstack; botfeed]) + "\n")
     else
       if (botfeed == ')') then score = score + 3 end
       if (botfeed == ']') then score = score + 57 end
       if (botfeed == '}') then score = score + 1197 end
       if (botfeed == '>') then score = score + 25137 end
         env.out.print("Score: " + score.string())
         return (score, 0)
     end
    end
    // Autocomplete section:
		env.out.print("Autocompleting for: " + stack)
    var actotal: USize = 0
    while (stack.size() > 0) do
			try
      match stack.pop()?
			| let x: U8 if (x == '(') => actotal = (actotal * 5) + 1
			| let x: U8 if (x == '[') => actotal = (actotal * 5) + 2
			| let x: U8 if (x == '{') => actotal = (actotal * 5) + 3
			| let x: U8 if (x == '<') => actotal = (actotal * 5) + 4
      end
		  env.out.print("AC Running Total: " + actotal.string())
      end
    end
		env.out.print("Autocomplete Total: " + actotal.string())
    (0,actotal)





