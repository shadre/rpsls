module UX
  PROMPT         = ">> "
  MARGIN         = " " * PROMPT.size
  WHITESPACE     = " " * 5

  def self.clear_screen
    system("cls") || system("clear")
  end

  def self.prompt(*messages)
    messages.each { |msg| puts PROMPT + msg }
  end
end
