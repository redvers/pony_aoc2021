use "debug"
use "collections"

/* Represents a number that's been called */
primitive XX

/* The "Board" actor which represents a bingo game-board and
 * holds all of the logic within.                                    */
actor Board
  /* Actor State:
   *   board:   Stores the current board state as a one-dimensional
   *            array. As the board is uniform I was able to avoid
   *            the use of multi-dimensional arrays.
   *            Either contains a number (USize), or XX.
   *
   *   moves:   The bingo numbers as they're called in order.
   *            NOTE: As they're a val there's only one copy of this
   *            data shared safely across all 1000 actors.
   *
   *   movecnt: This counter increments with every number "called".
   *            The requirement of the exercise will be to find the
   *            actor with the highest and lowest value at the
   *            game's completion.
   *
   *   maintag: The actor I have assigned to coördinate all the
   *            responses.                                           */
  var board: Array[(USize | XX)] = []
  var moves: Array[USize] val
  var movecnt: USize = 0
  var maintag: Main tag


  /* One creation, the Actor is passed an Array[String] which contains
   * its Game Board and the list of numbers that will be called in the
   * game                                                            */
  new create(rawboard: Array[String] iso^, moves': Array[USize] val, maintag': Main tag) =>
    maintag = maintag'
    moves = moves'
    extract_numbers(consume rawboard)

  /* Parses the numbers and populates board: Array[USize]            */
  fun ref extract_numbers(rawboard: Array[String] iso^) =>
    var boardstr: String ref = recover ref "".clone() end
    /* As I'm going into a one-dimensional array, we join all the
     * strings together.  Think Enum.join(array, "") in Elixir       */
    for line in rawboard.values() do
      boardstr = recover ref boardstr + " " + line end
    end

    /* Processes the single string to extract each number and
     * populates board: Array[USize]                                 */
    while (boardstr.size() > 0) do
      if (boardstr.at(" ", 0)) then boardstr.trim_in_place(1, boardstr.size())
        continue // If our first character is a space, we trim it and loop.
      end
      try
        (let value: USize, let number_of_digits: USize) = boardstr.read_int[USize]()?
        board.push(value) // Into the Array[USize] you go!
        boardstr.trim_in_place(number_of_digits, boardstr.size()) // Trim digits
      else
        Debug.out("Numeric parse fail on:" + boardstr)
      end
    end


 /* Playing the Game
  *
  * Each Actor is responsible for its own game board. They play
  * completely independently until they win.  When they win
  * their game, they notify the coördinating Actor (in maintag)
  * that they've completed with their reference (think pid in,
  * Elixir), number of numbers called, and the validation score
  * that adventofcode uses to validate your answers are correct
  *
  * In Elixir we might be tempted instead to have the coördinating
  * actor call each number in turn to each Actor in turn with
  * GenServer.call() and have it return the moment that they won.
  *
  * But all that sychronization creates latency as every actor would
  * be waiting for every other actor to finish before the next
  * number was called.                                               */
  be play_the_game() =>
    for number in moves.values() do
      apply_number(number)
      if (check_horizontal()) then break end // If we win, exit loop
      if (check_vertical())   then break end // If we win, exit loop
      movecnt = movecnt + 1
    end
    /* Send the coördinating Actor our results                       */
    maintag.receive_results(this, movecnt, final_result())


 /* Ticks off the number if it's present.
  * Scans the array and replaces the number with XX if found         */
  fun ref apply_number(number: USize) =>
    var ptr: USize = 0
    while (ptr < board.size()) do
      try
        match board(ptr)?
        | let x: XX => None
        | let x: USize => if (x == number) then board.update(ptr, XX)? end
        end
      end
      ptr = ptr + 1
    end

 /* Calculates the validation result, the product of the remaining
  * numbers and the last number called                               */
  fun final_result(): USize =>
    var sum: USize = 0
    for num in board.values() do
      match num
      | let x: XX => None
      | let x: USize => sum = sum + x
      end
    end
    try
      moves(movecnt)? * sum
    else
      0
    end


 /* Takes an Array and validates if all the items in it are XX       */
  fun check_slice(slice: Array[(USize | XX)]): Bool =>
    var cnt: USize = 0
    for g in slice.values() do
      match g
      | let x: XX => cnt = cnt + 1
      | let x: USize => None
      end
    end
    if (slice.size() == cnt) then true else false end

 /* To check the horizontal, we check_slice with slices of the board */
  fun check_horizontal(): Bool =>
    if (check_slice(board.slice(0,   5))) then return true end
    if (check_slice(board.slice(5,  10))) then return true end
    if (check_slice(board.slice(10, 15))) then return true end
    if (check_slice(board.slice(15, 20))) then return true end
    if (check_slice(board.slice(20, 25))) then return true end
    false

 /* To check the vertical, we check_slice with slices of the board
  * with a step of 5                                                 */
  fun check_vertical(): Bool =>
    if (check_slice(board.slice(0,  board.size(), 5))) then return true end
    if (check_slice(board.slice(1,  board.size(), 5))) then return true end
    if (check_slice(board.slice(2,  board.size(), 5))) then return true end
    if (check_slice(board.slice(3,  board.size(), 5))) then return true end
    if (check_slice(board.slice(4,  board.size(), 5))) then return true end
    false


 /* Provides introspection of the Actor's State.
  *
  * It sends the State in a textual form to the coördinating Actor (maintag)
  * with its own reference (think pid).
  *
  * A separate behaviour in Main will handle this response           */
  be report_status(header: String val) =>
    try
      let resulttxt: String iso = status()?
      maintag.handle_report_status(this, recover iso header.clone() + consume resulttxt end)
    end

 /* Function that returns a textual representation of the Game Board
  * as a String.                                                     */
  fun status(): String iso^ ? =>
    var rv: String iso = recover iso "".clone() end
    let linelen: USize = board.size().f32().sqrt().usize()
    rv.append("Board size: " + board.size().string() + "\n")
    rv.append("Board Dimensions: " + linelen.string() + "x" + linelen.string() + "\n")

    var ptr: USize = 0
    while (ptr < board.size()) do
      match board(ptr)?
      | let x: XX => rv.append("XX")
      | let x: USize => rv.append(x.string())
      end
      if ((ptr + 1).mod(linelen) == 0) then rv.append("\n") else rv.append(" ") end
      ptr = ptr + 1
    end
    consume rv
