use "debug"
use "files"
use "collections"

actor Main
  var env: Env
  var result: USize = 0

  new create(env': Env) =>
    env = env'

    let map: Map[String, Array[String]] iso = parse_input()
    let startnode: Node = Node.create(consume map, this, "start", recover val [] end, this)
    startnode.run()

  be close(closedChild: (Node|Main)) =>
    Debug.out("Main has closed debug")

  be collateresults(str: String) =>
		result = result + 1
    env.out.print(result.string() + ": " + str)

  fun parse_input(): Map[String, Array[String]] iso^ =>
    let input: String =
    """
ax-end
xq-GF
end-xq
im-wg
ax-ie
start-ws
ie-ws
CV-start
ng-wg
ng-ie
GF-ng
ng-av
CV-end
ie-GF
CV-ie
im-xq
start-GF
GF-ws
wg-LY
CV-ws
im-CV
CV-wg
    """

    let rv: Map[String, Array[String]] iso = recover iso
      let x = Map[String, Array[String]]
      let lines: Array[String] = input.split("\n")
      for line in lines.values() do
				try
          let t: Array[String] = line.split("-")
          let ov: Array[String] = x.get_or_else(t(0)?, [])
          ov.push(t(1)?)
          x.update(t(0)?, ov)

          let ovv: Array[String] = x.get_or_else(t(1)?, [])
          ovv.push(t(0)?)
          x.update(t(1)?, ovv)
				end
      end
      x
    end
    consume rv


actor Node
  let myname: String
  let children: MapIs[Node, String] = MapIs[Node, String]
  let parent: (Node|Main)
  var path: Array[String] val
  let map: Map[String, Array[String]] val
  let main: Main

  new create(map': Map[String, Array[String]] val, parent': (Node|Main), myname': String, path': Array[String] val, main': Main) =>
    main = main'
    map = map'
    myname = myname'
    parent = parent'

    let temppath: Array[String] iso = recover iso Array[String] end
    for node in path'.values() do
      temppath.push(node)
    end
    temppath.push(myname)
    path = consume temppath

  be run() =>
    if (myname == "end") then main.collateresults(",".join(path.values())) end
    let pathset: Set[String] = to_setString(path)

    let spawnmes: Array[String] = []
    try
      for nextStepMaybe in map(myname)?.values() do
        if (is_small(nextStepMaybe) and pathset.contains(nextStepMaybe)) then
          None
        else
          spawnmes.push(nextStepMaybe)
        end
      end
    end
    for spawnme in spawnmes.values() do
      children.insert(Node.create(map, this, spawnme, path, main), spawnme)
    end
    for runme in children.keys() do
      runme.run()
    end

    if (children.size() == 0) then
      parent.close(this)
    end

  be close(completedChild: Node) =>
    try children.remove(completedChild)? end
    if (children.size() == 0) then
      parent.close(this)
    end

  fun is_small(node: String): Bool =>
    (node.lower() == node)

  fun to_setString(inarray: Array[String] val): Set[String] =>
    let rv: Set[String] = Set[String]
    for str in inarray.values() do
      rv.set(str)
    end
    rv

