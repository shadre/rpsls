class RPSLS
  require_relative 'ux'

  attr_reader :players

  POINTS_TO_WIN    = 5
  # COMPUTER_ADJUSTS = true

  def initialize(players)
    @players = players
  end

  def play
    UX.clear_screen
    display_welcome_message
    loop do
      until winner
        play_round
        print_score
      end
    end
  end

  # def reset_score
  #   players.each { |player| player.reset_score }
  # end

  private

  def display_goodbye_message
    UX.prompt("Thanks for playing. Bye!")
  end

  def display_welcome_message
    UX.prompt("Welcome to RPSLS Game!",
              "The first to score #{POINTS_TO_WIN} points wins the game.")
  end

  def play_round
    Round.new(players).play
  end

  def winner
    players.find { |player| player.points >= POINTS_TO_WIN }
  end
end

def Round
  attr_reader :players

  def initialize(players)
    @players = players
  end

  def ask_for_choices
    players.each { |player| player.choose }
  end
end

class Player
  attr_accessor :points, :history, :choice
  attr_reader :points

  def initialize
    @points = 0
  end

  def add_point
    points += 1
  end

  def add_to_history(choice)
    history << choice
  end

  def history
    history ||= []
  end

  def outcome(opponent)
    choice.outcome(opponent.choice)
  end

  def reset_points
    points = 0
  end

  def to_s
    name
  end

  def draws?(opponent)
    choice == opponent.choice
  end

  def wins?(opponent)
    choice.beats?(opponent.choice)
  end
end

class Human < Player
  attr_reader :name

  def initialize
    super
    @name = nil
  end

  def choose
    #UI.ask_for(:move)
  end

  # def name
  #   name || set_name
  #   # self.name ||= set_name
  # end

  def set_name
    # UI.
  end
end

class Computer < Player
  attr_reader :name

  def initialize
    super
    @name = "Computer"
  end

  def choose
    self.move = Move.new
  end
end

class Move
  attr_accessor :value

  # wrong place?
  CHOICES = { "r" => :rock,   "p" => :paper, "s" => :scissors,
              "l" => :lizard, "o" => :spock }
  WINNER  = {
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

  def initialize(choice = nil)
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
end

module GameHandler
  def self.start_rpsls
    RPSLS.new([Human.new, Computer.new]).play
  end
end

GameHandler.start_rpsls
