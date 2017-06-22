module UXSettings
  PROMPT = ">> "
  MARGIN = " " * PROMPT.size
end

module UI
  require 'io/console'
  include UXSettings

  TERMINATION_CHARS = { "\u0003" => "^C",
                        "\u0004" => "^D",
                        "\u001A" => "^Z" }

  def get_char(args)
    get_input(**args.merge({ char_only: true }))
  end

  def get_string(args)
    get_input(**args)
  end

  def wait_for_any_key(message = PROMPT + "Press ANY KEY to continue")
    puts message
    yield_char
  end

  def yield_char
    char_input = STDIN.getch.downcase

    termination_input = TERMINATION_CHARS[char_input]
    abort("Program aborted (#{termination_input})") if termination_input

    char_input
  end

  private

  def get_input(message:,      invalid_msg: "Invalid input!",
                expected: nil, char_only: false,
                prompt:   "")

    puts prompt + message
    loop do
      input = char_only ? yield_char : gets.strip

      break input unless (expected && !expected.include?(input)) || input.empty?

      puts prompt + invalid_msg
    end
  end
end

module UX
  include UXSettings

  def clear_screen
    system("cls") || system("clear")
  end

  def display_after_loading(loading_text:,     final_text:,
                            loading_char: "■", loading_length: 6,
                            loading_time: 1.2)
    loading_bars = generate_loading_bars(loading_char, loading_length)
    sleep_time   = loading_time / loading_length.to_f
    length_diff  = length_difference((loading_text + loading_bars.last),
                                     final_text)

    loading_bars.each do |loading_bar|
      print loading_text + loading_bar + "\r"
      sleep sleep_time
    end
    puts final_text + whitespace(length_diff)
  end

  def print_in_border(text)
    hr_border = MARGIN + "+" + "=" * (text.length + 2) + "+"

    puts hr_border
    puts MARGIN + "| " + text + " |"
    puts hr_border
  end

  def prompt(*messages)
    messages.each { |msg| puts PROMPT + msg }
  end

  private

  def generate_loading_bars(char, width)
    Array.new(width).map.with_index do |_, idx|
      (char * (idx + 1)).ljust(width)
    end
  end

  def length_difference(first_string, second_string)
    first_string.length - second_string.length
  end

  def whitespace(length)
    length.positive? ? (" " * length) : ""
  end
end

module GameInterface
  extend UI, UX
  include UXSettings

  CHOICE_MSG = MARGIN + "<r> rock <p> paper <s> scissors <l> lizard <o> spock"
  CHOICES    = { "r" => :rock,   "p" => :paper, "s" => :scissors,
                 "l" => :lizard, "o" => :spock }

  def self.choose_move(player)
    valid       = CHOICES.keys
    msg         = "#{player.name}, please choose your move: \n" + CHOICE_MSG
    msg_invalid = "Please choose one of: " + valid.join(", ")

    choice = get_char(message:   msg,    invalid_msg: msg_invalid,
                      prompt:    PROMPT, expected:    valid,
                      char_only: true)
    CHOICES[choice]
  end

  def self.choose_name
    get_string(message: "What's your name?",
               prompt:  PROMPT)
  end

  def self.ask_for_rematch
    get_char(message:   "Do you want to play another match? (y/n)",
             prompt:    PROMPT,
             char_only: true,
             expected:  %w[y n])
  end
end

class RPSLS
  attr_reader :players, :scoreboard, :winner

  def initialize(players:, scoreboard:, points_to_win: 3)
    @players       = players
    @scoreboard    = scoreboard
    @points_to_win = points_to_win
  end

  def play
    GameInterface.clear_screen
    display_welcome_message
    until winner
      next_round
    end
    display_winner
  end

  def add_point(player)
    scoreboard[player] += 1
  end

  private

  attr_reader :points_to_win
  attr_writer :winner

  def check_winner
    found = scoreboard.find { |_player, points| points >= points_to_win }

    self.winner = found.first if found
  end

  def display_welcome_message
    GameInterface.prompt("Welcome to RPSLS Game!",
                         "The first to score #{points_to_win} points wins" \
                         "the game.")
  end

  def display_winner
    GameInterface.prompt("#{winner} wins the game!")
  end

  def next_round
    play_round
    GameInterface.wait_for_any_key
    reload_view
    check_winner
  end

  def play_round
    Round.new(self).play
  end

  def print_score
    GameInterface.print_in_border(scoreboard.to_s)
  end

  def reload_view
    GameInterface.clear_screen
    print_score
  end
end

class Scoreboard
  def initialize(player1, player2)
    @scores = { player1 => 0,
                player2 => 0 }
  end

  def [](player)
    scores[player]
  end

  def []=(player, value)
    scores[player] = value
  end

  def find(ifnone = nil, &block)
    scores.find(ifnone, &block)
  end

  def to_s
    [first, second.reverse].map { |score| score.map(&:to_s).join(" ") }
                           .join(" : ")
  end

  private

  attr_reader :scores

  def data_at(index)
    [scores.keys[index], scores.values[index]]
  end

  def first
    data_at(0)
  end

  def second
    data_at(1)
  end
end

class Round
  def initialize(game)
    @player1, @player2 = game.players
    @scoreboard        = game.scoreboard
    @choices           = {}
  end

  def play
    handle_choices
    check_winner
    handle_result
  end

  private

  attr_reader :player1, :player2
  attr_accessor :winner, :choices, :scoreboard

  def ask_for_choices
    [player1, player2].each { |player| choices[player] = player.choose }
  end

  def check_winner
    player1_choice = choices[player1]
    player2_choice = choices[player2]

    return if player1_choice == player2_choice

    self.winner = player1_choice.beats?(player2_choice) ? player1 : player2
  end

  def display_choices
    puts
    [player1, player2].each do |player|
      name_string   = "#{player}: "
      choice_string = name_string + choices[player].to_s
      if player.is_a?(Computer)
        GameInterface.display_after_loading(loading_text: name_string,
                                            final_text:   choice_string)
      else
        puts choice_string
      end
    end
    puts
  end

  def display_outcome
    outcome_msg = outcome

    return unless outcome_msg

    puts outcome_msg
    puts
  end

  def display_result
    GameInterface.prompt(winner ? "#{winner} wins the round!" : "It's a tie!")
  end

  def handle_choices
    ask_for_choices
    display_choices
  end

  def handle_result
    display_outcome
    update_points
    display_result
  end

  def opposite_player(player)
    player == player1 ? player2 : player1
  end

  def outcome
    return unless winner
    loser = opposite_player(winner)

    choices[winner].outcome(choices[loser])
  end

  def update_points
    scoreboard[winner] += 1 if winner
  end
end

class Player
  attr_reader :name

  def choose
    new_move
  end

  def to_s
    name
  end

  private

  def new_move
    Move.new
  end
end

class Human < Player
  def name
    @name ||= new_name
  end

  private

  attr_writer :name

  def new_move
    Move.new(GameInterface.choose_move(self))
  end

  def new_name
    self.name = GameInterface.choose_name
  end
end

class Computer < Player
  def initialize
    @name = "Computer"
  end
end

class Move
  attr_reader :value

  WINNER = {
    rock:     { scissors: "As it always has, rock crushes scissors",
                lizard:   "Rock crushes lizard" },
    paper:    { rock:     "Paper covers rock",
                spock:    "Paper disproves Spock" },
    scissors: { paper:    "Scissors cuts paper",
                lizard:   "Scissors decapitates lizard" },
    lizard:   { paper:    "Lizard eats paper",
                spock:    "Lizard poisons Spock" },
    spock:    { rock:     "Spock vaporizes rock",
                scissors: "Spock smashes scissors" }
  }

  def initialize(choice = random)
    @value = choice
  end

  def ==(other_move)
    value == other_move.value
  end

  def beats?(other_move)
    WINNER[value].key?(other_move.value)
  end

  def outcome(other_move)
    WINNER[value][other_move.value]
  end

  def random
    self.value = WINNER.keys.sample
  end

  def to_s
    value.to_s
  end

  private

  attr_writer :value
end

module GameHandler
  def self.play
    players = [Human.new, Computer.new]
    loop do
      new_rpsls(players)
      break print_goodbye unless rematch?
    end
  end

  class << self
    private

    def print_goodbye
      GameInterface.prompt("Thanks for playing. Bye!")
    end

    def new_rpsls(players)
      RPSLS.new(players: players, scoreboard: Scoreboard.new(*players))
           .play
    end

    def rematch?
      input = GameInterface.ask_for_rematch.downcase
      input == "y"
    end
  end
end

GameHandler.play
