use "files"
use "collections"

actor Main
  var env: Env

  new create(env': Env) =>
    env = env'
    try
      let docto: DumboOcto = DumboOcto(env, env.root as AmbientAuth, "day11.full")?
      env.out.print("Generation: 0")
      docto.displayField()
      for cnt in Range(1, 1000+1) do
        env.out.print("Generation: " + cnt.string())
			  docto.step()?
        docto.displayField()
        env.out.print("")
      end
    else
      env.err.print("Unable to read and process the lavatubes file")
    end

class DumboOcto
  let env: Env
  var flashcount: USize = 0
  var field: Array[Array[U8]] = Array[Array[U8]]

  new create(env': Env, auth: AmbientAuth, filename: String)? =>
    env = env'
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    let content: String val = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by("\n")

    for line in contentlines.values() do
      if (line.size() == 0) then continue end
      let linearray: Array[U8] = []
      for chr in line.array().values() do
        linearray.push(chr - 48)
      end
      field.push(linearray)
    end

  fun ref step()? =>
    increment_all()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    check_flash()?
    drain_flashers()?
    all_zeros()?

	fun ref all_zeros()? =>
    var tot: USize = 0
		for yptr in Range(0, field.size()) do
			for xptr in Range(0, field(yptr)?.size()) do
				tot = tot + field(yptr)?(xptr)?.usize()
			end
		end
    if (tot == 0) then env.out.print("SYNCRONIZED FLASH") ; error end

	fun ref check_flash()? =>
		for yptr in Range(0, field.size()) do
			for xptr in Range(0, field(yptr)?.size()) do
				if (field(yptr)?(xptr)? > 9) then
          bump_neighbors(yptr, xptr)
        end
			end
		end

  fun ref bump_neighbors(yptr: USize, xptr: USize) =>
    try bump_neighbor(yptr + 1, xptr - 1)? end
    try bump_neighbor(yptr + 1, xptr    )? end
    try bump_neighbor(yptr + 1, xptr + 1)? end
    try bump_neighbor(yptr    , xptr - 1)? end
    try field(yptr)?.update(xptr, 0)? end
    try bump_neighbor(yptr    , xptr + 1)? end
    try bump_neighbor(yptr - 1, xptr - 1)? end
    try bump_neighbor(yptr - 1, xptr    )? end
    try bump_neighbor(yptr - 1, xptr + 1)? end
    flashcount = flashcount + 1

  fun ref bump_neighbor(yptr: USize, xptr: USize)? =>
    let oldval: U8 = field(yptr)?(xptr)?
    if (oldval != 0) then
      field(yptr)?.update(xptr, oldval + 1)?
    end

	fun ref drain_flashers()? =>
		for yptr in Range(0, field.size()) do
			for xptr in Range(0, field(yptr)?.size()) do
				let oldval: U8 = field(yptr)?(xptr)?
        if (oldval > 9) then field(yptr)?.update(xptr, 0)? end
			end
		end

	fun ref increment_all()? =>
		for yptr in Range(0, field.size()) do
			for xptr in Range(0, field(yptr)?.size()) do
				let oldval: U8 = field(yptr)?(xptr)?
				field(yptr)?.update(xptr, oldval + 1)?
			end
		end

  fun displayField() =>
    for y in field.values() do
      for x in y.values() do
        if (x > 9) then
          env.out.write("X")
        else
          env.out.write(x.string())
        end
      end
      env.out.print("               Flash Count: " + flashcount.string())
    end

