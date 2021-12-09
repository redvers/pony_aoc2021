use "debug"
use "files"
use "itertools"
use "collections"

actor Main
  var env: Env

  new create(env': Env) =>
    env = env'
    try
      populate_segments_from_file(env.root as AmbientAuth, "day8-input.full")?
    else
      env.err.print("Unable to read and process the lanterfish file")
    end

  fun ref populate_segments_from_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    var counter: USize = 0
    let contentlines: Array[String] ref = content.split_by("\n")
      for line in contentlines.values() do
        if (line.size() == 0) then continue end
        let str: Array[String] = line.split_by(" | ")
        try
          let solver: Solver = Solver(str.apply(0)?)
          let codes: Array[String] = str.apply(1)?.split_by(" ")

          if (codes.size() != 4) then Debug.out("BORKED- not four digits") end
          counter = counter + (1000 * solver.solve(codes(0)?)?.usize())
          counter = counter + (100 * solver.solve(codes(1)?)?.usize())
          counter = counter + (10 * solver.solve(codes(2)?)?.usize())
          counter = counter + (1 * solver.solve(codes(3)?)?.usize())

        end
      end
    env.out.print("Total: " + counter.string())

  class Solver
    var solveMap: Map[String, U8] = Map[String, U8]
    var numMap:   Map[U8, Set[U8]] = Map[U8, Set[U8]]
    var setMap:   Map[String, Set[U8]] = Map[String, Set[U8]]

    new create(solveline: String) =>
      let dictionary: Array[String] = solveline.split_by(" ")
      let len6: Map[String, None] = Map[String, None](10)
      let len5: Map[String, None] = Map[String, None](10)
      for d in dictionary.values() do
        setMap.insert(normalize(d), stringToSet(d))
        if (stringToSet(d).size() == 2) then solveMap.insert(normalize(d), 1) ; numMap.insert(1, stringToSet(d)); continue end
        if (stringToSet(d).size() == 3) then solveMap.insert(normalize(d), 7) ; numMap.insert(7, stringToSet(d)); continue end
        if (stringToSet(d).size() == 4) then solveMap.insert(normalize(d), 4) ; numMap.insert(4, stringToSet(d)); continue end
        if (stringToSet(d).size() == 5) then len5.insert(normalize(d), None); continue end
        if (stringToSet(d).size() == 6) then len6.insert(normalize(d), None); continue end
        if (stringToSet(d).size() == 7) then solveMap.insert(normalize(d), 8) ; numMap.insert(8, stringToSet(d)); continue end
      end

      // To find 2, go through len5 and subtract 4. measure size of len5 after
      for f in len5.keys() do
        try
          if (stringToSet(f).without(numMap(4)?).size() == 3) then
            Debug.out("seg2: " + f)
            numMap.insert(2, stringToSet(f))
            solveMap.insert(f, 2)
            len5.remove(f)?
          end
        else
          Debug.out("Failed to find 2")
        end
      end
      // Now we can resolve 3 & 5:
      for f in len5.keys() do
        try
          if (stringToSet(f).op_or(numMap(2)?).size() == 7) then
            Debug.out("seg5: " + f)
            numMap.insert(5, stringToSet(f))
            solveMap.insert(f, 5)
          else
            Debug.out("seg3: " + f)
            numMap.insert(3, stringToSet(f))
            solveMap.insert(f, 3)
          end
        else
          Debug.out("Failed to find 3")
        end
      end
      // 5 + 1 = 9
      try
        let seg9 = numMap(5)?.op_or(numMap(1)?)
        Debug.out("seg9: " + setToString(seg9))
        numMap.insert(9, seg9)
        solveMap.insert(setToString(seg9), 9)
        len6.remove(setToString(seg9))?
      else
        Debug.out("Failed to resolve 9")
      end
      // len6 - only 0 and 6 left, add 1 and count
      for f in len6.keys() do
        try
          let res: Set[U8] = numMap(1)?.op_or(stringToSet(f))
          if (res.size() == 6) then
            Debug.out("seg0: " + f)
            numMap.insert(0, stringToSet(f))
            solveMap.insert(f, 0)
          else
            Debug.out("seg6: " + f)
            numMap.insert(6, stringToSet(f))
            solveMap.insert(f, 6)
          end
        else
          Debug.out("Failed to find 3")
        end
      end
      for dstr in solveMap.keys() do
        try
          Debug.out("Dictionary: " + dstr + ": " + solveMap(dstr)?.string()) //setToString(numMap(number)?))
        end
      end



    fun stringToSet(string: String): Set[U8] =>
      let rv: Set[U8] = Set[U8](8)
      for chr in string.array().values() do
        rv.set(chr)
      end
      rv

    fun setToString(set: Set[U8]): String =>
      var array: Array[U8] iso = recover iso [] end
      for f in set.values() do
        array.push(f)
      end
      String.from_array(recover val Sort[Array[U8], U8](consume array) end)



    fun solve(foo: String): U8 ? =>
      solveMap(normalize(foo))?

    fun normalize(string: String): String =>
      let sortedarray: Array[U8] val = recover val Sort[Array[U8], U8](string.array().clone()) end
      String.from_array(sortedarray)


/*
 * 0 a,b,c,  e,f,g  1,1,1,0,1,1,1
 * 1     c,    f    0,0,1,0,0,1,0
 * 2 a,  c,d,e,  g  1,0,1,1,1,0,1
 * 3 a,  c,d,  f,g  1,0,1,1,0,1,1
 * 4 b,  c,d,  f    0,1,1,1,0,1,0
 * 5 a,b,  d,  f,g  1,1,0,1,0,1,1
 * 6 a,b,  d,e,f,g  1,1,0,1,1,1,1
 * 7 a,  c,    f    1,0,1,0,0,1,0
 * 8 a,b,c,d,e,f,g  1,1,1,1,1,1,1
 * 9 a,b,c,d,  f,g  1,1,1,1,0,1,1
 */

//a = 0,  2,3,  5,6,7,8,9
//b = 0,      4,5,6,8,  9
//c = 0,1,2,3,4,    7,8,9
//d =     2,3,4,5,6,  8,9
//e = 0,  2,      6,  8
//f = 0,1,  3,4,5,6,7,8,9
//g = 0,  2,3,  5,6,  8,9

