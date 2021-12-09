use "debug"
use "files"
use "itertools"
use "collections"

type CheckStatus is (Deep | Shallow)
primitive Deep
  fun string(): String => "Deep"
primitive Shallow
  fun string(): String => "Shallow"

actor Main
  var env: Env

  new create(env': Env) =>
    env = env'
    try
      let ltf: LavaTubes = LavaTubes(env.root as AmbientAuth, "day9.full")?
      ltf.displayField()?
      let risk: Array[USize] = ltf.scan()?
      let sorted: Array[USize] = Sort[Array[USize], USize](risk).reverse()

      let score: USize = sorted(0)? * sorted(1)? * sorted(2)?
      env.out.print("Final Score: " + score.string())

    else
      env.err.print("Unable to read and process the lavatubes file")
    end

class Basin
  var field: Array[U8]
  var maxx: USize
  var maxy: USize
  let candidates: Map[USize, None] = Map[USize, None]
  let reviewedfield: Map[USize, CheckStatus] = Map[USize, CheckStatus]
  var score: USize = 0

  new create(field': Array[U8] box, maxx': USize, maxy': USize, xy: (ISize, ISize)) =>
    field = field'.clone()
    maxx = maxx'
    maxy = maxy'
    (let x: ISize, let y: ISize) = xy
    try fourWays(x,y)?  else Debug.out("fourWays failed") end
    while (candidates.size() > 0) do
      for ptr in candidates.keys() do
        (let xx: ISize, let yy: ISize) = indexToXY(ptr)
        try
          fourWays(xx,yy)?
        else
          Debug.out("Very Broken")
        end
      end
    end
    for state in reviewedfield.values() do
      match state
      | let _: Deep => score = score + 1
      | let _: Shallow => None
      end
    end

  fun debug() =>
    for (ptr, state) in reviewedfield.pairs() do
      (let x: ISize, let y: ISize) = indexToXY(ptr)
      Debug.out(x.string() + "," + y.string() + ": " + state.string())
    end

  fun indexToXY(index: USize): (ISize, ISize) =>
    (let y: USize, let x: USize) = index.divrem(maxx)
    (x.isize(),y.isize())

  fun xyToIndex(x: ISize, y: ISize): USize =>
    ((y*maxx.isize())+x).usize()

  fun xyToVal(x: ISize, y: ISize): U8 ? =>
    field(xyToIndex(x,y))?

  fun ref fourWays(x: ISize, y: ISize)? =>
    let topxy: (ISize, ISize) = (x, y-1)
    let botxy: (ISize, ISize) = (x, y+1)
    let lftxy: (ISize, ISize) = (x-1, y)
    let rgtxy: (ISize, ISize) = (x+1, y)
    try
      candidates.remove(xyToIndex(x,y))?
    end
    if (xyToVal(x,y)? == 9) then reviewedfield.insert(xyToIndex(x,y), Shallow) else
      reviewedfield.insert(xyToIndex(x,y), Deep)
      populatePointRV(topxy)
      populatePointRV(botxy)
      populatePointRV(lftxy)
      populatePointRV(rgtxy)
    end

  fun ref populatePointRV(xy: (ISize, ISize)) =>
    (let xxx: ISize, let yyy: ISize) = xy
//    Debug.out("Checking: " + xxx.string() + "," + yyy.string())
    match xy
    | (let x: ISize, let y: ISize) if (x < 0) => return
    | (let x: ISize, let y: ISize) if (y < 0) => return
    | (let x: ISize, let y: ISize) if (x >= maxx.isize()) => return
    | (let x: ISize, let y: ISize) if (y >= maxy.isize()) => return
    | (let x: ISize, let y: ISize) => if reviewedfield.contains(xyToIndex(x,y)) then return else candidates.insert(xyToIndex(x,y), None) end
    end




class LavaTubes
  var maxx: USize = 0
  var maxy: USize = 0
  var field: Array[U8] = Array[U8]

  new create(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by("\n")

    try
      maxx = contentlines(0)?.size()
      for line in contentlines.values() do
        if (line.size() == 0) then continue end
        for chr in line.array().values() do
          field.push(chr - 48)
        end
        maxy = maxy + 1
      end
    end

    for ptr in Range(0,field.size()) do
      (let x: ISize, let y: ISize) = indexToXY(ptr)
      Debug.out(ptr.string() + " " + x.string() + "," + y.string() + " => " + xyToIndex(x,y).string())
    end

  fun scan(): Array[USize] ? =>
    let rv: Array[USize] = []
    for ptr in Range(0, field.size()) do
      let xy: (ISize, ISize) = indexToXY(ptr)
      (let x: ISize, let y: ISize) = xy
      let myvalue: U8 = xyToVal(x,y)?
      if (evaluateXY(xy)) then
        Debug.out("Found One at: " + x.string() + "," + y.string() + "=" + myvalue.string())

        let basin: Basin = Basin(field, maxx, maxy, (x,y))
        rv.push(basin.score)
        Debug.out("Basin size: " + basin.score.string())
      end
    end
    rv

  fun indexToXY(index: USize): (ISize, ISize) =>
    (let y: USize, let x: USize) = index.divrem(maxx)
    (x.isize(),y.isize())

  fun xyToIndex(x: ISize, y: ISize): USize =>
    ((y*maxx.isize())+x).usize()

  fun xyToVal(x: ISize, y: ISize): U8 ? =>
    field(xyToIndex(x,y))?

  fun displayField()? =>
    Debug.out("Debug field:")
    for y in Range(0, maxy) do
      var line: String ref = String
      for x in Range(0, maxx) do
        line = line + xyToVal(x.isize(),y.isize())?.string()
      end
      Debug.out(line)
    end
    Debug.out("Rawr")

  fun evaluateXY(xy: (ISize, ISize)): Bool =>
    (let x: ISize, let y: ISize) = xy
    let s: Array[U8] = lowPoints(x,y)

    try
    let myval: U8 = xyToVal(x,y)?
    var cnt: USize = 0
    for value in s.values() do
      if (myval < value) then cnt = cnt + 1 end
    end
    if (cnt == s.size()) then true else false end
    else false end


  fun lowPoints(x: ISize, y: ISize): Array[U8] =>
    let rv: Array[U8] = []
    let topxy: (ISize, ISize) = (x, y-1)
    let botxy: (ISize, ISize) = (x, y+1)
    let lftxy: (ISize, ISize) = (x-1, y)
    let rgtxy: (ISize, ISize) = (x+1, y)
    populatePointRV(rv, topxy)
    populatePointRV(rv, botxy)
    populatePointRV(rv, lftxy)
    populatePointRV(rv, rgtxy)
    rv

  fun populatePointRV(rv: Array[U8], xy: (ISize, ISize)) =>
    (let xxx: ISize, let yyy: ISize) = xy
//    Debug.out("Checking: " + xxx.string() + "," + yyy.string())
    match xy
    | (let x: ISize, let y: ISize) if (x < 0) => return
    | (let x: ISize, let y: ISize) if (y < 0) => return
    | (let x: ISize, let y: ISize) if (x >= maxx.isize()) => return
    | (let x: ISize, let y: ISize) if (y >= maxy.isize()) => return
    | (let x: ISize, let y: ISize) => try rv.push(xyToVal(x,y)?) end
    end



