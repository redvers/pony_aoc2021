use "debug"
use "files"
use "collections"

/* See https://adventofcode.com/2021/day/4 for more information      */
actor Main
  /* Actor State:
   *   env:    Contains the Environment which is needed to read files,
   *           print to the screen, etc…
   *
   *   boards: A Map that contains references to all of the Bingo
   *           game board Actors (Board), the number of numbers
   *           that were called before it won, and it's checksum.
   *
   *           It is keyed on digestof Board, as Pony can't use
   *           objects as keys in a Map.
   *
   *   moves:  A ReadOnly Array of Numbers which represents all of
   *           the numbers called in the game in the correct order.
   *
   *   rcnt:   A count of all of the Game Over notifications that
   *           this coördinating Actor has received. Once this
   *           number is equal to the number of Actors in flight,
   *           we know we have all results.                          */
  var env: Env
  var boards: Map[USize, (Board, USize, USize)] = Map[USize, (Board, USize, USize)]
  var moves: Array[USize] val = []
  var rcnt: USize = 0

  /* We:
   *    a. Parse moves file, populate moves.
   *    b. Parse boards file, create all the Board actors.
   *    c. Loop through the Array of boards and instruct them all to
   *       start playing their game.
   *    d. Wait for the results to come in                           */
  new create(env': Env) =>
    env = env'
    try
      populate_moves_from_file(env.root as AmbientAuth, "moves.txt-full")?
    else
      env.err.print("Unable to read and process the moves file")
    end
    try
      populate_boards_from_file(env.root as AmbientAuth, "boards.txt-full")?
    else
      env.err.print("Unable to read and process the moves file")
    end
    run_games()

  /* a. Parse moves file, populate moves.                            */
  fun ref populate_moves_from_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)

    /* We chose val as we're going to be sending the final Array[USize]
     * to every Actor.  It has to be val.                            */
    let content: String val = String.from_iso_array(f.read(f.size()))
    moves = extract_moves(content)

  /* Splits the String of moves by the "," delimeter, converts them
   * into USize numbers and pushes them onto an Array[USize] val     */
  fun extract_moves(content: String val): Array[USize] val =>
    let rv: Array[USize] iso = []
    for numberstr in content.split_by(",").values() do
      try
        (let value: USize, _) = numberstr.read_int[USize]()?
        rv.push(value)
      end
    end
    recover val rv end

  /*    b. Parse boards file, create all the Board actors.           */
  fun ref populate_boards_from_file(auth: AmbientAuth, filename: String)? =>
    let fp: FilePath = FilePath(auth, filename)?
    let f:  File = File.open(fp)
    let content: String = String.from_iso_array(f.read(f.size()))
    let contentlines: Array[String] ref = content.split_by("\n")
    split_into_boards(contentlines)


  /* Takes the contents of the boards file and repeatedly calls
   * extract_board() until the contentlines array is empty.
   *
   * (extract_board() mutates the contentlines array)
   *
   * For every board that extract_board detects, a new Board Actor
   * is spawned and its reference and digest is stored in boards     */
  fun ref split_into_boards(contentlines: Array[String] ref) =>
    while (contentlines.size() > 0) do
      let rawboard: Array[String] iso = extract_board(contentlines)
      let board: Board = Board(consume rawboard, moves, this)
      boards.insert(digestof board, (board, 0, 0))
    end

  /* Reads a line at a time from contentlines, consuming each in turn
   * and pushing it onto the return value array.
   *
   * Once a blank line is detected, the array is returned and
   * control of the mutated contentlines is returned to the caller   */
  fun extract_board(contentlines: Array[String]): Array[String] iso^ =>
    let rv: Array[String] iso = recover iso [] end

    while (contentlines.size() > 0) do
      try
        let g: String = contentlines.shift()?
        if (g == "") then return rv end
        rv.push(g)
      end
    end
    consume rv

  /* Call the play_the_game() behaviour on every Board Actor         */
  fun ref run_games() =>
    for (digest, (game, score, checksum)) in boards.pairs() do
      game.play_the_game()
    end

  /* When each Board Actor completes its game, it sends the results
   * to this Actor in the role of a coördinator. Each result updates
   * the board Map with the results and a count of the replies is
   * incremented.
   *
   * Once the number of received results equals the number of Actors
   * in the Map, we know that we have results from all the Actors
   * and can process it for the highest and lowest scores            */
  be receive_results(boardtag: Board, score: USize, checksum: USize) =>
    boards.update(digestof boardtag, (boardtag, score, checksum))
    rcnt = rcnt + 1
    if (boards.size() == rcnt) then
      findresults()
    end


  /* The adventofcode requirement is to find the Game Boards which
   * took the most and the least number of moves to win.
   *
   * We iterate over the Map and keep a running tally of the highest
   * and lowest scores and associated digest of the Actor.
   *
   * From that digest, we can look up the checksum result          */

  fun findresults() =>
    var smallfinal: USize = 0 ; var smallestscore: USize = -1
    var largefinal: USize = 0 ; var largestscore:  USize = 0
    for (digest, (board, score, checksum)) in boards.pairs() do
      if (score < smallestscore) then smallestscore = score ; smallfinal = digest end
      if (score >  largestscore) then  largestscore = score ; largefinal = digest end
    end

    try
      /* Get the reference (pid) for the winning Actors from the Map */
      (let boarda: Board,_,_) = boards(smallfinal)?
      (let boardb: Board,_,_) = boards(largefinal)?

      /* Send a message to each actor requesting a textual
       * representation of their Game State.
       *
       * Note: As we can't guarantee the order in which the results
       *       will return back, we just send a textual prefix so
       *       we can identify which is which in the output          */
      boarda.report_status("---===+++ Winning +++===---\n")
      boardb.report_status("---===+++ Losing +++===---\n")
    end

  /* This behaviour handles the response to the Board.report_status()
   * behaviour. The board returns its own reference (pid) so we can
   * look up the correct checksum to go with the board.
   *
   * We display the board, the checksum, and exit.                   */
  be handle_report_status(board: Board, resulttxt: String iso^) =>
    try
      (_,_,let checksum: USize) = boards.apply(digestof board)?
      env.out.print("\n")
      env.out.print(consume resulttxt)
      env.out.print("Final Score: " + checksum.string())
      env.out.print("\n")
    end


