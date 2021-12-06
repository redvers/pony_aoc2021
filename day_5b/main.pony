use "debug"
use "files"
use "collections"

actor Main
  var env: Env
  var maxx: USize = 0
  var maxy: USize = 0
  var wmap: Map[String, USize] = Map[String, USize]

  new create(env': Env) =>
    env = env'
    try
      populate_vents_from_file(env.root as AmbientAuth, "day-5a-input.full")?
    else
      env.err.print("Unable to read and process the moves file")
    end

  fun ref populate_vents_from_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by("\n")
    for line in contentlines.values() do
      if (line.size() == 0) then continue end
      let cp: CoordPair = CoordPair(line)
      if (cp.horizontal()) then sum_coords(cp.coords()) end
      if (cp.vertical()) then sum_coords(cp.coords()) end
      if (cp.diagonal()) then sum_coords(cp.coords()) end
      if (cp.maxx > maxx) then maxx = cp.maxx end
      if (cp.maxy > maxy) then maxy = cp.maxy end
    end
    Debug.out("MaxX: " + maxx.string())
    Debug.out("MaxY: " + maxy.string())

    var cnt: USize = 0
    for value in wmap.values() do
      if (value > 1) then cnt = cnt + 1 end
    end
    Debug.out("Cell Count >1: " + cnt.string())

  fun ref sum_coords(coords: Array[(USize, USize)]) =>
    for (x, y) in coords.values() do
      let key: String = x.string() + "," + y.string()
      wmap.upsert(key, 1, {(x,y) => x+y})
    end


  class CoordPair
    var x0: USize = -1
    var x1: USize = -1
    var y0: USize = -1
    var y1: USize = -1
    var maxx: USize = 0
    var maxy: USize = 0

    new create(string: String) =>
    //  Debug.out(string)
      let coordStringArray: Array[String] = string.split_by(" -> ")
      try
        (x0, y0) = extractCoords(coordStringArray(0)?)?
        (x1, y1) = extractCoords(coordStringArray(1)?)?
      else
        Debug.out("Failed to parse line: \"" + string + "\"")
      end

    fun ref extractCoords(str: String): (USize, USize) ? =>
      let coordArray: Array[String] = str.split_by(",")
      (coordArray(0)?, coordArray(1)?)

      (let x: USize, _) = coordArray(0)?.read_int[USize](0)?
      (let y: USize, _) = coordArray(1)?.read_int[USize](0)?
      if (x > maxx) then maxx = x end
      if (y > maxy) then maxy = y end
      (x,y)

    fun horizontal(): Bool =>
      if ((y0 == y1) and (x0 != x1)) then return true end
      false

    fun vertical(): Bool =>
      if ((x0 == x1) and (y0 != y1)) then return true end
      false

    fun point(): Bool =>
      if ((x0 == x1) and (y0 == y1)) then return true end
      false

    fun diagonal(): Bool =>
      if ((x0 != x1) and (y0 != y1)) then return true end
      false

    fun coords(): Array[(USize, USize)] =>
      let rv: Array[(USize, USize)] = []
      if (vertical()) then
        Debug.out("Horizontal: " + x0.string() + "," + y0.string() + "=>" + x1.string() + "," + y1.string())
        let yy0 = if (y0 < y1) then y0 else y1 end
        let yy1 = if (y0 < y1) then y1 else y0 end
        for y in Range(yy0, yy1 + 1) do
          rv.push((x0, y))
          Debug.out(x0.string() + ", " + y.string())
        end
      end
      if (horizontal()) then
        Debug.out("Vertical: " + x0.string() + "," + y0.string() + "=>" + x1.string() + "," + y1.string())
        let xx0 = if (x0 < x1) then x0 else x1 end
        let xx1 = if (x0 < x1) then x1 else x0 end
        for x in Range(xx0, xx1 + 1) do
          rv.push((x, y0))
          Debug.out(x.string() + ", " + y0.string())
        end
      end
      if (diagonal()) then
        Debug.out("Diagonal: " + x0.string() + "," + y0.string() + "=>" + x1.string() + "," + y1.string())
        var xdelta: ISize = x0.isize() - x1.isize()
        var ydelta: ISize = y0.isize() - y1.isize()

        let stepcount: USize = xdelta.abs()

        for step in Range(0, stepcount + 1) do
          let newx: USize = if (xdelta > 0) then x0 - step else x0 + step end
          let newy: USize = if (ydelta > 0) then y0 - step else y0 + step end
          Debug.out("Stepped: " + newx.string() + "," + newy.string())
          rv.push((newx, newy))
        end
      end
      Debug.out("Number of cells populated: " + rv.size().string())
      rv

